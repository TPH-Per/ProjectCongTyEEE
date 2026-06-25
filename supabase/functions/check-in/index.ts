import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { getAdminClient, requireUser, setJwtContext } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface CheckInPayload {
  reservationId?: string              // có sẵn reservation
  walkIn?: {                          // walk-in không reservation
    customerName: string
    customerPhone?: string
    guests: number
    notes?: string
  }
  tableIds: string[]                  // 1 hoặc nhiều bàn
  partySize: { male: number; female: number; children: number; ageBucket: string; gender?: 'male'|'female'|'mixed'; nationality?: 'local'|'foreign' }
  packageId?: string                  // Set Biz / Buffet / etc.
  flowMode: 'one_way' | 'free'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { supabase, user } = await requireUser(req)
    const admin = getAdminClient()
    const body: CheckInPayload = await req.json()

    // Lấy branch_id từ JWT claim (hook sẽ set sau khi đăng ký).
    // Fallback: query DB nếu hook chưa đăng ký — dùng admin client (bypass RLS) nên an toàn.
    let branchId = user.app_metadata?.branch_id ?? user.user_metadata?.branch_id
    if (!branchId) {
      const { data: profile } = await admin
        .from('users')
        .select('branch_id')
        .eq('id', user.id)
        .maybeSingle()
      branchId = profile?.branch_id
    }
    if (!branchId) throw new Error('User chưa gán branch_id (cả JWT và DB đều rỗng)')

    // Stamp the JWT claims into the Postgres session so DB helpers
    // (current_branch_id, current_user_role, has_role RLS, write_audit
    // trigger) see the right user/branch. Without this the audit trigger
    // inserts branch_id=NULL into audit_events and the request 400s.
    await setJwtContext(admin, user.id, user.app_metadata)

    // 1. Resolve customer
    let customerId: string
    let customerSnapshot: any

    if (body.reservationId) {
      // Có reservation → lấy customer_id sẵn
      const { data: resv } = await admin
        .from('reservations')
        .select('customer_id, customer_snapshot, guests, status')
        .eq('id', body.reservationId)
        .single()
      if (!resv) throw new Error('Reservation not found')
      if (resv.status !== 'Pending') throw new Error('Reservation đã được xử lý')

      customerId = resv.customer_id
      customerSnapshot = resv.customer_snapshot

      // Update reservation → Arrived
      await admin
        .from('reservations')
        .update({ status: 'Arrived', arrived_at: new Date().toISOString() })
        .eq('id', body.reservationId)
    } else {
      // Walk-in: tìm customer theo phone hoặc tạo mới
      if (!body.walkIn) throw new Error('walkIn required when no reservationId')
      const { data: existing } = await admin
        .from('customers')
        .select('id, total_visits, total_spent')
        .eq('branch_id', branchId)
        .eq('phone', body.walkIn.customerPhone ?? '')
        .maybeSingle()

      if (existing) {
        customerId = existing.id
        customerSnapshot = { name: 'Walk-in', phone: body.walkIn.customerPhone }
        await admin
          .from('customers')
          .update({ total_visits: existing.total_visits + 1, last_visit_at: new Date().toISOString() })
          .eq('id', customerId)
      } else {
        const { data: created, error } = await admin
          .from('customers')
          .insert({
            branch_id: branchId,
            name: body.walkIn.customerName,
            phone: body.walkIn.customerPhone,
            demographics: { age_bucket: body.partySize.ageBucket },
          })
          .select('id')
          .single()
        if (error) throw error
        customerId = created!.id
        customerSnapshot = { name: body.walkIn.customerName, phone: body.walkIn.customerPhone }
      }
    }

    // 2. Validate tables available
    const { data: tables } = await admin
      .from('tables')
      .select('id, code, status, capacity')
      .in('id', body.tableIds)

    if (!tables || tables.length !== body.tableIds.length) throw new Error('Tables not found')
    for (const t of tables) {
      if (t.status === 'occupied' || t.status === 'maintenance') {
        throw new Error(`Bàn ${t.code} không khả dụng`)
      }
    }

    // 3. Resolve package metadata (snapshot)
    let packageMeta: any = {}
    if (body.packageId) {
      const { data: pkg } = await admin
        .from('packages')
        .select('id, name, type, price, item_limit, duration_minutes, metadata')
        .eq('id', body.packageId)
        .single()
      if (!pkg) throw new Error('Package not found')
      packageMeta = {
        package_id: pkg.id,
        package_name_snapshot: pkg.name,
        package_type: pkg.type,
        item_limit: pkg.item_limit,
        duration_minutes: pkg.duration_minutes,
      }
    }

    // 4. Tạo table_assignments
    const assignments = body.tableIds.map((tableId) => ({
      branch_id: branchId,
      reservation_id: body.reservationId ?? null,
      table_id: tableId,
      assigned_by: user.id,
      metadata: {
        ...packageMeta,
        flow_mode: body.flowMode,
        party_size: body.partySize,
        demographics_capture: body.partySize, // {male, female, children, age_bucket, gender, nationality}
      },
    }))

    const { data: createdAssignments, error: assignErr } = await admin
      .from('table_assignments')
      .insert(assignments)
      .select('id, table_id')
    if (assignErr) throw assignErr

    // 5. Update tables.status = occupied
    await admin
      .from('tables')
      .update({ status: 'occupied' })
      .in('id', body.tableIds)

    // 6. Nếu có reservation → update status = Dining
    if (body.reservationId) {
      await admin
        .from('reservations')
        .update({ status: 'Dining', seated_at: new Date().toISOString() })
        .eq('id', body.reservationId)
    }

    // 7. Trả về
    return new Response(
      JSON.stringify({
        ok: true,
        customerId,
        assignments: createdAssignments,
        package: packageMeta,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    return new Response(
      JSON.stringify({ error: e.message ?? 'Internal error' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})