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

    // 1. Resolve customer & reservation
    let customerId: string
    let customerSnapshot: any
    let finalResvId = body.reservationId

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

      // Create reservation for walk-in
      const { data: newResv, error: resvErr } = await admin
        .from('reservations')
        .insert({
          branch_id: branchId,
          customer_id: customerId,
          customer_snapshot: customerSnapshot,
          guests: body.walkIn.guests,
          status: 'Dining',
          source: 'walk_in',
          table_id: body.tableIds[0],
        })
        .select('id')
        .single()
      if (resvErr) throw resvErr
      finalResvId = newResv!.id
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

    // 4. Update tables.status = occupied and metadata (filter by branch)
    const tableMetadata = {
      ...packageMeta,
      flow_mode: body.flowMode,
      party_size: body.partySize,
      demographics_capture: body.partySize,
      reservation_id: finalResvId,
      assigned_by: user.id,
      assigned_at: new Date().toISOString()
    }

    await admin
      .from('tables')
      .update({ status: 'occupied', metadata: tableMetadata })
      .in('id', body.tableIds)
      .eq('branch_id', branchId)

    // 5. Write `table_assignments` rows so the seating shows up in the same
    //    discoverable path as seated reservations. CRM survey, KDS tablet
    //    limit, and dashboard all query this table; without it walk-in
    //    guests effectively "don't exist" once seated.
    //    Unique constraint is (reservation_id, table_id) — for walk-ins we
    //    just created the reservation in step 1.5 above, so this is safe to
    //    upsert idempotently.
    const assignmentRows = body.tableIds.map((tableId) => ({
      branch_id: branchId,
      reservation_id: finalResvId,
      table_id: tableId,
      assigned_by: user.id,
      metadata: tableMetadata,
    }))
    const { error: assignErr } = await admin
      .from('table_assignments')
      .upsert(assignmentRows, { onConflict: 'reservation_id,table_id', ignoreDuplicates: true })
    if (assignErr) throw assignErr

    // 5.5 Realtime notification for the reception panel. The dashboard
    // subscribes via useRealtime on `notifications` and bumps the new
    // walk-in into the notification list. Best-effort — never block the
    // seating flow on this.
    try {
      const { data: tablesForCode } = await admin
        .from('tables')
        .select('id, code')
        .in('id', body.tableIds)
      const codes = (tablesForCode ?? []).map((t) => t.code).join(', ')
      await admin.from('notifications').insert({
        branch_id: branchId,
        channel: 'reception-panel',
        recipient: 'reception',
        template: 'new_seated',
        variables: {
          table_ids: body.tableIds,
          table_codes: codes,
          reservation_id: finalResvId,
          customer_name: customerName ?? null,
          party_size: body.partySize,
          message: `${codes ? `Bàn ${codes}` : 'Bàn'} vừa nhận khách.`,
        },
        status: 'sent',
        sent_at: new Date().toISOString(),
        metadata: { source: 'check-in', reservation_id: finalResvId },
      })
    } catch (notifErr) {
      console.warn('[check-in] notification insert failed:', notifErr)
    }

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
        reservationId: finalResvId,
        package: packageMeta,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    const status = e.name === 'AuthError' ? e.status : (e.status || 400)
    return new Response(
      JSON.stringify({ error: e.message ?? 'Internal error', errorName: e.name }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})