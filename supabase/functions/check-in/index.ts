import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
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
    // requireAppUser: verifies JWT, loads the public.users profile, asserts
    // the caller is active, and stamps JWT context for DB helpers/audit
    // triggers. branch_id comes from the profile (the source of truth) —
    // never from user_metadata.
    const { user, profile, admin } = await requireAppUser(req, {
      roles: ['staff', 'manager', 'admin', 'reception'],
    })
    const branchId = profile.branch_id
    if (!branchId) throw new Error('Tài khoản chưa được gán chi nhánh')
    const body: CheckInPayload = await req.json()

    // Validate basic payload shape.
    if (!Array.isArray(body.tableIds) || body.tableIds.length === 0) {
      throw new AuthError('tableIds phải là mảng UUID không rỗng', 400)
    }
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    for (const tid of body.tableIds) {
      if (!uuidRe.test(tid)) throw new AuthError(`tableId không phải UUID: '${tid}'`, 400)
    }
    if (body.reservationId && !uuidRe.test(body.reservationId)) {
      throw new AuthError(`reservationId không phải UUID`, 400)
    }
    if (body.packageId && !uuidRe.test(body.packageId)) {
      throw new AuthError(`packageId không phải UUID`, 400)
    }

    // 1. Resolve customer
    let customerId: string
    let customerSnapshot: any

    if (body.reservationId) {
      // Có reservation → lấy customer_id sẵn. BRANCH CHECK: the reservation
      // must belong to the caller's branch (admin bypasses).
      const { data: resv } = await admin
        .from('reservations')
        .select('id, branch_id, customer_id, customer_snapshot, guests, status')
        .eq('id', body.reservationId)
        .single()
      if (!resv) throw new Error('Reservation not found')
      if (profile.role !== 'admin' && resv.branch_id !== branchId) {
        throw new AuthError('Reservation thuộc chi nhánh khác', 403)
      }
      if (resv.status !== 'Pending') throw new Error('Reservation đã được xử lý')

      customerId = resv.customer_id
      customerSnapshot = resv.customer_snapshot

      // Update reservation → Arrived (filter by branch too — defence in depth)
      await admin
        .from('reservations')
        .update({ status: 'Arrived', arrived_at: new Date().toISOString() })
        .eq('id', body.reservationId)
        .eq('branch_id', resv.branch_id)
    } else {
      // Walk-in: tìm customer theo phone hoặc tạo mới
      if (!body.walkIn) throw new Error('walkIn required when no reservationId')
      const { data: existing } = await admin
        .from('customers')
        .select('id, branch_id, total_visits, total_spent')
        .eq('branch_id', branchId)
        .eq('phone', body.walkIn.customerPhone ?? '')
        .maybeSingle()

      if (existing) {
        // Cross-check: the customer we found must be in our branch.
        if (existing.branch_id !== branchId) {
          throw new AuthError('Customer thuộc chi nhánh khác', 403)
        }
        customerId = existing.id
        customerSnapshot = { name: 'Walk-in', phone: body.walkIn.customerPhone }
        await admin
          .from('customers')
          .update({ total_visits: existing.total_visits + 1, last_visit_at: new Date().toISOString() })
          .eq('id', customerId)
          .eq('branch_id', branchId)
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

    // 2. Validate tables available AND in our branch
    const { data: tables } = await admin
      .from('tables')
      .select('id, branch_id, code, status, capacity')
      .in('id', body.tableIds)

    if (!tables || tables.length !== body.tableIds.length) {
      throw new Error('Tables not found')
    }
    for (const t of tables) {
      // Cross-branch table → reject (admin bypasses)
      if (profile.role !== 'admin' && t.branch_id !== branchId) {
        throw new AuthError(`Bàn ${t.code} thuộc chi nhánh khác`, 403)
      }
      if (t.status === 'occupied' || t.status === 'maintenance') {
        throw new Error(`Bàn ${t.code} không khả dụng`)
      }
    }

    // 3. Resolve package metadata (snapshot) AND verify branch
    let packageMeta: any = {}
    if (body.packageId) {
      const { data: pkg } = await admin
        .from('packages')
        .select('id, branch_id, name, type, price, item_limit, duration_minutes, metadata')
        .eq('id', body.packageId)
        .maybeSingle()
      if (!pkg) throw new Error('Package not found')
      if (profile.role !== 'admin' && pkg.branch_id !== branchId) {
        throw new AuthError('Package thuộc chi nhánh khác', 403)
      }
      packageMeta = {
        package_id: pkg.id,
        package_name_snapshot: pkg.name,
        package_type: pkg.type,
        item_limit: pkg.item_limit,
        duration_minutes: pkg.duration_minutes,
      }
    }

    // 4. Tạo table_assignments (branch_id explicit)
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

    // 5. Update tables.status = occupied (filter by branch — defence in depth)
    await admin
      .from('tables')
      .update({ status: 'occupied' })
      .in('id', body.tableIds)
      .eq('branch_id', branchId)

    // 6. Nếu có reservation → update status = Dining (filter by branch)
    if (body.reservationId) {
      await admin
        .from('reservations')
        .update({ status: 'Dining', seated_at: new Date().toISOString() })
        .eq('id', body.reservationId)
        .eq('branch_id', branchId)
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
    const status = e instanceof AuthError ? e.status : 400
    return new Response(
      JSON.stringify({ error: e.message ?? 'Internal error' }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})