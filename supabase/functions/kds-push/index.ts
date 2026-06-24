// supabase/functions/kds-push/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { getAdminClient, requireUser } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface KdsPayload {
  orderId: string
  itemIds: string[]   // order_items.id cần đẩy
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: KdsPayload = await req.json()

    // 1. Lấy items + table info
    const { data: items } = await admin
      .from('order_items')
      .select(`
        id, name_snapshot, quantity, note, modifiers, status, created_at,
        order:orders(order_number, table_id, tables(code, zone_id))
      `)
      .in('id', body.itemIds)
    if (!items?.length) throw new Error('No items')

    // 2. Update status → Preparing
    await admin
      .from('order_items')
      .update({ status: 'Preparing' })
      .in('id', body.itemIds)

    // 3. Push to KDS websocket (or just queue in notifications table)
    for (const item of items) {
      await admin.from('notifications').insert({
        branch_id: user.app_metadata?.branch_id,
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
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})