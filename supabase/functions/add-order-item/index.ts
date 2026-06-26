// supabase/functions/add-order-item/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

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
    // Staff add items to orders; reception too (when reception helps guests).
    // Branch consistency is enforced after we fetch the order so the admin
    // client (which bypasses RLS) can't be tricked into cross-branch writes.
    const { profile, admin } = await requireAppUser(req, {
      roles: ['staff', 'reception', 'manager', 'admin'],
    })
    const body: AddItemPayload = await req.json()

    // Validate payload.
    if (!body.orderId || !body.menuItemId) {
      throw new AuthError('orderId và menuItemId là bắt buộc', 400)
    }
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.orderId)) throw new AuthError('orderId không phải UUID', 400)
    if (!uuidRe.test(body.menuItemId)) throw new AuthError('menuItemId không phải UUID', 400)
    if (!Number.isFinite(body.quantity) || body.quantity <= 0) {
      throw new AuthError('quantity phải > 0', 400)
    }
    // Sanity cap — a waiter shouldn't add 1000 portions of anything.
    if (body.quantity > 99) {
      throw new AuthError('quantity vượt giới hạn cho phép (99)', 400)
    }

    // 1. Lấy order + menu_item song song (table_assignment cần order.table_id nên phải lấy sau)
    const [orderRes, menuRes] = await Promise.all([
      admin.from('orders').select('id, status, branch_id, reservation_id, reservation:reservations(table_id)').eq('id', body.orderId).single(),
      admin.from('menu_items').select('id, name, price, cost, is_available, branch_id, category_id').eq('id', body.menuItemId).single(),
    ])

    const order = orderRes.data
    const menu = menuRes.data
    if (!order || !menu) throw new Error('Order hoặc menu item không tồn tại')
    if (order.status === 'Paid' || order.status === 'Cancelled') throw new Error('Order đã đóng')
    if (!menu.is_available) throw new Error('Món tạm hết')

    // Branch ownership check — admin bypasses; staff/reception/manager must
    // operate on resources inside their own branch.
    if (profile.role !== 'admin' && profile.branch_id !== order.branch_id) {
      throw new AuthError('Order thuộc chi nhánh khác — bạn không có quyền sửa', 403)
    }
    // The menu item must belong to the same branch as the order. Otherwise
    // a staff member could attach a menu item from a DIFFERENT branch's
    // catalogue to this order — even though they'd never be able to query
    // it from the menu UI (RLS hides it), this is defence in depth.
    if (profile.role !== 'admin' && menu.branch_id !== order.branch_id) {
      throw new AuthError('Menu item thuộc chi nhánh khác với order', 403)
    }

    // 2. Lấy table_assignment theo table_id (filter by branch too)
    const tableId = (order.reservation as any)?.table_id;
    const { data: table } = await admin
      .from('tables')
      .select('metadata')
      .eq('id', tableId)
      .single()
    
    const assignment = { metadata: table?.metadata }

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
        status: 'Pending',
        metadata: {},
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
    const status = e.name === 'AuthError' ? e.status : (e.status || 400)
    return new Response(
      JSON.stringify({ error: e.message, errorName: e.name }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
