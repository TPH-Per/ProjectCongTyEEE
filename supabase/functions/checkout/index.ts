// supabase/functions/checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

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
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: CheckoutPayload = await req.json()

    // 1. Lấy order + items
    const { data: order } = await admin
      .from('orders')
      .select('id, branch_id, table_id, reservation_id, status, subtotal, vat, total, discount')
      .eq('id', body.orderId)
      .single()
    if (!order) throw new Error('Order not found')
    if (order.status === 'Paid' || order.status === 'Cancelled') {
      throw new Error('Order đã thanh toán')
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

    // 4. Tạo invoice
    const { data: customer } = await admin
      .from('customers')
      .select('id, name, phone, email, tax_code')
      .eq('id', body.customerId ?? order.reservation_id ?? '')
      .maybeSingle()

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

    // 5. Tạo payments
    const { data: openShift } = await admin
      .from('shifts')
      .select('id')
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
    }

    // 7. Update order → Paid
    await admin
      .from('orders')
      .update({
        status: 'Paid',
        discount: Number(order.discount) + voucherDiscount,
        total: finalTotal,
      })
      .eq('id', order.id)

    // 8. Release table_assignments
    if (order.table_id) {
      await admin
        .from('table_assignments')
        .update({ released_at: new Date().toISOString() })
        .eq('table_id', order.table_id)
        .is('released_at', null)
      await admin
        .from('tables')
        .update({ status: 'available' })
        .eq('id', order.table_id)
    }

    // 9. Update reservation → Completed
    if (order.reservation_id) {
      await admin
        .from('reservations')
        .update({ status: 'Completed', completed_at: new Date().toISOString() })
        .eq('id', order.reservation_id)
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
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})