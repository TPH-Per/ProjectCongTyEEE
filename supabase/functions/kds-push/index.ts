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

    // 1. Lấy items + table info
    const { data: items } = await admin
      .from('order_items')
      .select(`
        id, name_snapshot, quantity, note, modifiers, status, created_at,
        order:orders(order_number, table_id, branch_id, tables(code, zone_id))
      `)
      .in('id', body.itemIds)
    if (!items?.length) throw new Error('No items')

    // Branch ownership check — admin bypasses; everyone else must own the order.
    const orderBranchId = (items[0] as any).order?.branch_id
    if (profile.role !== 'admin' && profile.branch_id !== orderBranchId) {
      throw new AuthError('Order thuộc chi nhánh khác — bạn không có quyền push KDS', 403)
    }

    // 2. Update status → Preparing
    await admin
      .from('order_items')
      .update({ status: 'Preparing' })
      .in('id', body.itemIds)

    // 3. Push to KDS websocket (or just queue in notifications table)
    for (const item of items) {
      await admin.from('notifications').insert({
        branch_id: orderBranchId,
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
