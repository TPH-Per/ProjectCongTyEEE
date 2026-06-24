// supabase/functions/add-order-item/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

interface AddItemPayload {
  orderId: string
  menuItemId: string
  quantity: number
  note?: string
  modifiers?: any[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: AddItemPayload = await req.json()

    // 1. Lấy order + menu_item song song (table_assignment cần order.table_id nên phải lấy sau)
    const [orderRes, menuRes] = await Promise.all([
      admin.from('orders').select('id, status, table_id, branch_id').eq('id', body.orderId).single(),
      admin.from('menu_items').select('id, name, price, cost, is_available, category_id').eq('id', body.menuItemId).single(),
    ])

    const order = orderRes.data
    const menu = menuRes.data
    if (!order || !menu) throw new Error('Order hoặc menu item không tồn tại')
    if (order.status === 'Paid' || order.status === 'Cancelled') throw new Error('Order đã đóng')
    if (!menu.is_available) throw new Error('Món tạm hết')

    // 2. Lấy table_assignment theo table_id
    const { data: assignment } = await admin
      .from('table_assignments')
      .select('id, metadata, released_at')
      .eq('table_id', order.table_id!)
      .is('released_at', null)
      .order('assigned_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    // 3. Validate item_limit (nếu có)
    const itemLimit = assignment?.metadata?.item_limit
    if (itemLimit) {
      const { count } = await admin
        .from('order_items')
        .select('id', { count: 'exact', head: true })
        .eq('order_id', body.orderId)
      if ((count ?? 0) >= itemLimit) {
        throw new Error(`Đã đạt giới hạn ${itemLimit} món cho gói này`)
      }
    }

    // 4. Validate locked category (nếu flow_mode = one_way)
    const flowMode = assignment?.metadata?.flow_mode
    if (flowMode === 'one_way') {
      // Lấy category của menu_item vừa chọn
      const { data: category } = await admin
        .from('menu_items')
        .select('category_id, menu_categories(name)')
        .eq('id', body.menuItemId)
        .single()
      // Lấy món đầu tiên đã order để xác định category hiện tại
      const { data: firstItem } = await admin
        .from('order_items')
        .select('menu_item_id, menu_items(category_id, menu_categories(name))')
        .eq('order_id', body.orderId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle()
      if (firstItem && firstItem.menu_items?.category_id !== category?.category_id) {
        throw new Error('Luồng 1 chiều: không thể chọn món khác danh mục hiện tại')
      }
    }

    // 5. Insert order_item
    const lineTotal = menu.price * body.quantity
    const { data: created, error } = await admin
      .from('order_items')
      .insert({
        branch_id: order.branch_id,
        order_id: body.orderId,
        menu_item_id: menu.id,
        name_snapshot: menu.name,
        unit_price: menu.price,
        unit_cost: menu.cost,         // snapshot cost
        quantity: body.quantity,
        line_total: lineTotal,
        modifiers: body.modifiers ?? [],
        note: body.note,
      })
      .select()
      .single()
    if (error) throw error

    // 6. Recalculate order totals
    const { data: allItems } = await admin
      .from('order_items')
      .select('line_total, status')
      .eq('order_id', body.orderId)

    const subtotal = (allItems ?? []).reduce((s, it) => s + Number(it.line_total), 0)
    const { data: orderRow } = await admin
      .from('orders')
      .select('vat_rate, discount')
      .eq('id', body.orderId)
      .single()
    const vat = subtotal * Number(orderRow?.vat_rate ?? 0.08)
    const total = subtotal + vat - Number(orderRow?.discount ?? 0)

    await admin
      .from('orders')
      .update({ subtotal, vat, total })
      .eq('id', body.orderId)

    return new Response(
      JSON.stringify({ ok: true, item: created, subtotal, vat, total }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})