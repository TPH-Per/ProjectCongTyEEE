// supabase/functions/checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface CheckoutPayload {
  orderId: string
  revenueType: 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
  customerId?: string
  voucherCode?: string
  taxCode?: string            // MST nếu xuất hóa đơn đỏ
  customerCompany?: string
  customerAddress?: string
  payments: Array<{
    method: 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
    amount: number
    receivedAmount?: number    // tiền khách đưa (cash)
    reference?: string
  }>
  notes?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    // Checkout is the most sensitive write path (creates invoice, payment,
    // updates order, releases table). Restrict to reception/manager/admin.
    // Branch ownership is enforced after we read the order (so the admin
    // client's RLS-bypass can't leak cross-branch data).
    const { user, profile, admin } = await requireAppUser(req, {
      roles: ['reception', 'manager', 'admin'],
    })
    const body: CheckoutPayload = await req.json()

    // Validate payload.
    if (!body.orderId) throw new AuthError('orderId là bắt buộc', 400)
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.orderId)) throw new AuthError('orderId không phải UUID', 400)
    if (!Array.isArray(body.payments) || body.payments.length === 0) {
      throw new AuthError('payments phải là mảng không rỗng', 400)
    }
    const validMethods = ['cash', 'card', 'transfer', 'voucher', 'other']
    for (const p of body.payments) {
      if (!validMethods.includes(p.method)) {
        throw new AuthError(`Payment method không hợp lệ: '${p.method}'`, 400)
      }
      if (!Number.isFinite(p.amount) || p.amount <= 0) {
        throw new AuthError('payment.amount phải > 0', 400)
      }
      if (p.receivedAmount !== undefined && (!Number.isFinite(p.receivedAmount) || p.receivedAmount < 0)) {
        throw new AuthError('payment.receivedAmount không hợp lệ', 400)
      }
    }

    // 1. Lấy order + items
    //    IMPORTANT: `table_id` MUST be selected — the table-release branch
    //    (step 8 below) calls `order.table_id` and would fail silently if
    //    it were missing from the SELECT.
    const { data: order } = await admin
      .from('orders')
      .select('id, branch_id, reservation_id, table_id, status, subtotal, vat, total, discount')
      .eq('id', body.orderId)
      .single()
    if (!order) throw new Error('Order not found')
    if (order.status === 'Paid' || order.status === 'Cancelled') {
      throw new Error('Order đã thanh toán')
    }

    // Branch ownership: admin bypasses; everyone else must match.
    if (profile.role !== 'admin' && profile.branch_id !== order.branch_id) {
      throw new AuthError('Order thuộc chi nhánh khác — bạn không có quyền thanh toán', 403)
    }

    // 2. Validate voucher (nếu có)
    let voucher: any = null
    let voucherDiscount = 0
    if (body.voucherCode) {
      const { data: v } = await admin
        .from('vouchers')
        .select('id, code, type, value, max_uses, used_count, valid_from, valid_until, is_active')
        .eq('branch_id', order.branch_id)
        .eq('code', body.voucherCode.toUpperCase())
        .eq('is_active', true)
        .maybeSingle()
      if (!v) throw new Error('Voucher không tồn tại')
      if (v.max_uses && v.used_count >= v.max_uses) throw new Error('Voucher đã hết lượt')
      const today = new Date().toISOString().split('T')[0]
      if (v.valid_from && v.valid_from > today) throw new Error('Voucher chưa đến ngày dùng')
      if (v.valid_until && v.valid_until < today) throw new Error('Voucher đã hết hạn')

      voucher = v
      const subtotal = Number(order.subtotal)
      voucherDiscount = v.type === 'percent' ? subtotal * (v.value / 100) : v.value
    }

    const finalTotal = Number(order.total) - voucherDiscount
    if (finalTotal < 0) throw new Error('Discount vượt quá tổng bill')

    // 3. Validate tổng payment = finalTotal
    const paidAmount = body.payments.reduce((s, p) => s + p.amount, 0)
    if (Math.abs(paidAmount - finalTotal) > 1) {
      throw new Error(`Tổng thanh toán ${paidAmount} ≠ tổng bill ${finalTotal}`)
    }

    // 4. Tạo invoice — customer must belong to the same branch as the order
    //    (if a customerId is provided).
    let customer: any = null
    if (body.customerId) {
      if (!uuidRe.test(body.customerId)) {
        throw new AuthError('customerId không phải UUID', 400)
      }
      const { data: c } = await admin
        .from('customers')
        .select('id, branch_id, name, phone, email, tax_code')
        .eq('id', body.customerId)
        .maybeSingle()
      if (!c) throw new AuthError('Customer không tồn tại', 404)
      if (profile.role !== 'admin' && c.branch_id !== order.branch_id) {
        throw new AuthError('Customer thuộc chi nhánh khác với order', 403)
      }
      customer = c
    } else {
      // Fallback: try to find a customer via the reservation.
      const { data: c } = await admin
        .from('customers')
        .select('id, branch_id, name, phone, email, tax_code')
        .eq('id', order.reservation_id ?? '')
        .maybeSingle()
      // Only use this customer if it's in our branch. Otherwise treat as walk-in.
      if (c && (profile.role === 'admin' || c.branch_id === order.branch_id)) {
        customer = c
      }
    }

    const invoiceNumber = `INV-${Date.now()}-${order.branch_id.slice(0, 4)}`
    const { data: invoice, error: invErr } = await admin
      .from('invoices')
      .insert({
        branch_id: order.branch_id,
        order_id: order.id,
        invoice_number: invoiceNumber,
        status: 'paid',
        subtotal: order.subtotal,
        vat: order.vat,
        discount: Number(order.discount) + voucherDiscount,
        total: finalTotal,
        tax_code: body.taxCode ?? customer?.tax_code,
        customer_company: body.customerCompany,
        customer_address: body.customerAddress,
        customer_snapshot: customer ?? { name: 'Walk-in' },
        issued_at: new Date().toISOString(),
        issued_by: user.id,
        metadata: { notes: body.notes },
      })
      .select()
      .single()
    if (invErr) throw invErr

    // 5. Tạo payments — open shift must belong to our branch (defence in depth)
    const { data: openShift } = await admin
      .from('shifts')
      .select('id, branch_id')
      .eq('branch_id', order.branch_id)
      .eq('user_id', user.id)
      .eq('status', 'open')
      .maybeSingle()

    const paymentRows = body.payments.map((p) => ({
      branch_id: order.branch_id,
      invoice_id: invoice.id,
      shift_id: openShift?.id ?? null,
      method: p.method,
      revenue_type: body.revenueType,
      amount: p.amount,
      received_amount: p.receivedAmount,
      change_amount: p.receivedAmount ? p.receivedAmount - p.amount : 0,
      reference: p.reference,
      received_by: user.id,
    }))

    const { error: payErr } = await admin.from('payments').insert(paymentRows)
    if (payErr) throw payErr

    // 6. Ghi voucher_redemption (nếu có)
    if (voucher) {
      await admin.from('voucher_redemptions').insert({
        branch_id: order.branch_id,
        voucher_id: voucher.id,
        invoice_id: invoice.id,
        discount_amount: voucherDiscount,
        redeemed_by: user.id,
      })
      await admin
        .from('vouchers')
        .update({ used_count: voucher.used_count + 1 })
        .eq('id', voucher.id)
        .eq('branch_id', order.branch_id)
    }

    // 7. Update order → Paid (filter by branch — defence in depth)
    await admin
      .from('orders')
      .update({
        status: 'Paid',
        discount: Number(order.discount) + voucherDiscount,
        total: finalTotal,
      })
      .eq('id', order.id)
      .eq('branch_id', order.branch_id)

    // 8. Release table_assignments (filter by branch + table)
    if (order.table_id) {
      await admin
        .from('table_assignments')
        .update({ released_at: new Date().toISOString() })
        .eq('table_id', order.table_id)
        .eq('branch_id', order.branch_id)
        .is('released_at', null)
      await admin
        .from('tables')
        .update({ status: 'available' })
        .eq('id', order.table_id)
        .eq('branch_id', order.branch_id)
    }

    // 9. Update reservation → Completed (filter by branch)
    if (order.reservation_id) {
      await admin
        .from('reservations')
        .update({ status: 'Completed', completed_at: new Date().toISOString() })
        .eq('id', order.reservation_id)
        .eq('branch_id', order.branch_id)
    }

    // 10. Update customer stats
    if (customer) {
      await admin.rpc('increment_customer_stats', {
        p_customer_id: customer.id,
        p_total_spent: finalTotal,
      })
    }

    return new Response(
      JSON.stringify({
        ok: true,
        invoiceId: invoice.id,
        invoiceNumber,
        total: finalTotal,
        change: paymentRows[0]?.change_amount ?? 0,
      }),
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
