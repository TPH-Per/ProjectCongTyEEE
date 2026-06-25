// supabase/functions/kds-push/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface KdsPayload {
  orderId: string
  itemIds: string[]   // order_items.id cần đẩy
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Staff (after taking order) / reception / manager push to KDS.
    // Kitchen role is also allowed so they can re-push if needed.
    const { profile, admin } = await requireAppUser(req, {
      roles: ['staff', 'reception', 'manager', 'admin', 'kitchen'],
    })
    const body: KdsPayload = await req.json()

    // Validate payload — orderId is now actually used (was declared but ignored).
    if (!body.orderId) throw new AuthError('orderId là bắt buộc', 400)
    if (!Array.isArray(body.itemIds) || body.itemIds.length === 0) {
      throw new AuthError('itemIds phải là mảng không rỗng', 400)
    }
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.orderId)) throw new AuthError('orderId không phải UUID', 400)
    for (const iid of body.itemIds) {
      if (!uuidRe.test(iid)) throw new AuthError(`itemId không phải UUID: '${iid}'`, 400)
    }

    // 1. Load the order first — establishes the branch ownership baseline.
    const { data: order, error: orderErr } = await admin
      .from('orders')
      .select('id, branch_id, status')
      .eq('id', body.orderId)
      .maybeSingle()
    if (orderErr) throw orderErr
    if (!order) throw new AuthError('Order không tồn tại', 404)
    if (profile.role !== 'admin' && profile.branch_id !== order.branch_id) {
      throw new AuthError('Order thuộc chi nhánh khác — bạn không có quyền push KDS', 403)
    }

    // 2. Load items, filtered by BOTH id AND order_id (so a caller can't slip
    //    in items from another order, even by guessing ids). Count check
    //    ensures all requested items were found AND belong to this order.
    const { data: items } = await admin
      .from('order_items')
      .select(`
        id, order_id, name_snapshot, quantity, note, modifiers, status, created_at,
        order:orders!inner(order_number, table_id, branch_id, tables(code, zone_id))
      `)
      .in('id', body.itemIds)
      .eq('order_id', body.orderId)
    if (!items || items.length !== body.itemIds.length) {
      throw new AuthError(
        `Một hoặc nhiều itemId không tồn tại trong order ${body.orderId}`,
        404,
      )
    }
    // Every item must belong to our branch (defence in depth — admin bypasses).
    for (const it of items) {
      if (profile.role !== 'admin' && (it as any).order?.branch_id !== order.branch_id) {
        throw new AuthError('Item thuộc order chi nhánh khác', 403)
      }
    }

    // 3. Update status → Preparing. Filter by order_id as well so we never
    //    accidentally flip an item from a DIFFERENT order even if some
    //    stray id slipped past validation.
    await admin
      .from('order_items')
      .update({ status: 'Preparing' })
      .in('id', body.itemIds)
      .eq('order_id', body.orderId)

    // 3. Push to KDS websocket (or just queue in notifications table)
    //    Use the validated order.branch_id — NOT a derived field — so the
    //    notification always lands in the correct branch.
    for (const item of items) {
      await admin.from('notifications').insert({
        branch_id: order.branch_id,
        channel: 'kds',
        recipient: 'kitchen-display',
        template: 'new_order_item',
        variables: {
          order_number: (item as any).order?.order_number,
          table_code: (item as any).order?.tables?.code,
          zone: (item as any).order?.tables?.zone_id,
          item_name: item.name_snapshot,
          quantity: item.quantity,
          note: item.note,
          modifiers: item.modifiers,
          sent_at: new Date().toISOString(),
        },
        status: 'pending',
      })
    }

    return new Response(
      JSON.stringify({ ok: true, sent: items.length }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    const status = e instanceof AuthError ? e.status : 400
    return new Response(
      JSON.stringify({ error: e.message }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
