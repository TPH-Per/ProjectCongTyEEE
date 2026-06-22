# SUPABASE_FUNCTIONS.md — Edge Functions cho 7 logic nghiệp vụ

> Edge Functions chạy Deno trên Supabase. Dùng cho logic cần server-side: in hóa đơn, đẩy KDS, xuất CSV, gọi cổng thuế VN, validate tiền.

## 1. Setup Edge Functions

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH
npm i -g supabase
supabase login
supabase link --project-ref <project-ref>
mkdir -p supabase\functions
```

Mỗi function trong `supabase/functions/<name>/index.ts`.

## 2. Convention chung cho mọi function

```ts
// supabase/functions/_shared/cors.ts
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-selected-branch',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}
```

```ts
// supabase/functions/_shared/auth.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export function getSupabaseClient(req: Request) {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: {
          Authorization: req.headers.get('Authorization')!,
        },
      },
    },
  )
}

export function getAdminClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  )
}

export async function requireUser(req: Request) {
  const supabase = getSupabaseClient(req)
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) throw new Error('Unauthorized')
  return { supabase, user }
}
```

## 3. Function: `check-in`

Check-in khách: set `reservations.status = 'Arrived'`, tạo `table_assignments`.

### 3.1. Tạo function

```bash
supabase functions new check-in
```

### 3.2. Code `supabase/functions/check-in/index.ts`

```ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

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

    // Lấy branch_id từ JWT claim
    const branchId = user.app_metadata?.branch_id ?? user.user_metadata?.branch_id
    if (!branchId) throw new Error('User chưa gán branch_id')

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
```

### 3.3. Deploy + test

```bash
supabase functions deploy check-in --no-verify-jwt
```

Test qua curl:

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/check-in \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "reservationId": "abc-...",
    "tableIds": ["uuid-1", "uuid-2"],
    "partySize": {"male":2,"female":1,"children":0,"ageBucket":"30-40"},
    "packageId": "uuid-pkg",
    "flowMode": "one_way"
  }'
```

### 3.4. Gọi từ Vue

```ts
// src/composables/useCheckIn.ts
import { supabase } from '@/lib/supabase'

export function useCheckIn() {
  async function checkIn(payload: any) {
    const { data, error } = await supabase.functions.invoke('check-in', { body: payload })
    if (error) throw error
    return data
  }
  return { checkIn }
}
```

## 4. Function: `add-order-item`

Thêm món vào order, validate item_limit (gói buffet), kiểm tra locked category.

```ts
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
```

## 5. Function: `checkout`

Tính tổng, apply voucher, tạo invoice + payments, đóng bàn.

```ts
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
```

Tạo helper RPC để tăng customer stats:

```sql
create or replace function public.increment_customer_stats(
  p_customer_id uuid, p_total_spent numeric
)
returns void language sql security definer as $$
  update public.customers
  set total_visits = total_visits + 1,
      total_spent = total_spent + p_total_spent,
      last_visit_at = now()
  where id = p_customer_id;
$$;
```

## 6. Function: `close-shift`

Tổng kết ca, xuất CSV, đóng shift.

```ts
// supabase/functions/close-shift/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

interface CloseShiftPayload {
  shiftId: string
  closingCash: number
  notes?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: CloseShiftPayload = await req.json()

    // 1. Lấy shift
    const { data: shift } = await admin
      .from('shifts')
      .select('id, branch_id, user_id, status, opening_cash')
      .eq('id', body.shiftId)
      .single()
    if (!shift) throw new Error('Shift not found')
    if (shift.status !== 'open') throw new Error('Shift đã đóng')

    // 2. Tính expected_cash (cash payments trong ca)
    const { data: cashPayments } = await admin
      .from('payments')
      .select('amount, received_amount, change_amount')
      .eq('shift_id', shift.id)
      .eq('method', 'cash')

    const expectedCash = Number(shift.opening_cash) + (cashPayments ?? []).reduce(
      (s, p) => s + Number(p.amount), 0
    )

    const cashDifference = body.closingCash - expectedCash

    // 3. Update shift → closed
    await admin
      .from('shifts')
      .update({
        status: 'closed',
        closed_at: new Date().toISOString(),
        closing_cash: body.closingCash,
        expected_cash: expectedCash,
        cash_difference: cashDifference,
        notes: { handover_notes: body.notes ?? '' },
      })
      .eq('id', shift.id)

    // 4. Aggregate revenue by type
    const { data: revenueBreakdown } = await admin
      .from('payments')
      .select('revenue_type, amount')
      .eq('shift_id', shift.id)

    const summary: Record<string, { count: number; total: number }> = {}
    for (const p of revenueBreakdown ?? []) {
      const r = p.revenue_type ?? 'other'
      summary[r] = summary[r] ?? { count: 0, total: 0 }
      summary[r].count++
      summary[r].total += Number(p.amount)
    }

    return new Response(
      JSON.stringify({
        ok: true,
        shift: { id: shift.id, closed_at: new Date().toISOString() },
        summary,
        expectedCash,
        closingCash: body.closingCash,
        cashDifference,
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
```

## 7. Function: `export-shift-csv`

Xuất CSV chi tiết ca (gọi từ `ReceptionCloseShiftView`).

```ts
// supabase/functions/export-shift-csv/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const url = new URL(req.url)
    const shiftId = url.searchParams.get('shiftId')
    if (!shiftId) throw new Error('shiftId required')

    // Lấy chi tiết payments trong ca
    const { data: payments } = await admin
      .from('payments')
      .select(`
        id, method, amount, received_amount, change_amount, paid_at, revenue_type,
        invoices(invoice_number, customer_snapshot, tax_code, total),
        orders(order_number, table_id, tables(code))
      `)
      .eq('shift_id', shiftId)
      .order('paid_at')

    // Tạo CSV
    const header = 'Time,Invoice,Table,Customer,Phone,RevenueType,Method,Amount,Received,Change,TaxCode,Total\n'
    const rows = (payments ?? []).map((p: any) => [
      new Date(p.paid_at).toLocaleString('vi-VN'),
      p.invoices?.invoice_number ?? '',
      p.orders?.tables?.code ?? '',
      p.invoices?.customer_snapshot?.name ?? '',
      p.invoices?.customer_snapshot?.phone ?? '',
      p.revenue_type,
      p.method,
      p.amount,
      p.received_amount ?? '',
      p.change_amount ?? '',
      p.invoices?.tax_code ?? '',
      p.invoices?.total ?? '',
    ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','))

    const csv = header + rows.join('\n')

    return new Response(csv, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="shift-${shiftId}.csv"`,
      },
    })
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), { status: 400, headers: corsHeaders })
  }
})
```

## 8. Function: `kds-push`

Khi khách bấm "Gửi Bếp" trên Tablet → đẩy order_item mới sang KDS display (màn hình bếp).

```ts
// supabase/functions/kds-push/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

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
```

## 9. Function: `issue-tax-invoice`

Gửi hóa đơn đỏ VN lên cổng thuế điện tử (VNPT / Viettel / MISA).

```ts
// supabase/functions/issue-tax-invoice/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

interface TaxInvoicePayload {
  invoiceId: string
  taxCode: string          // MST người mua
  customerCompany: string
  customerAddress: string
  customerEmail?: string   // gửi HĐ điện tử
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: TaxInvoicePayload = await req.json()

    // 1. Validate MST format (10 hoặc 13 số)
    if (!/^\d{10}(-\d{3})?$/.test(body.taxCode)) {
      throw new Error('MST không hợp lệ (phải 10 hoặc 13 số)')
    }

    // 2. Lấy invoice + order items
    const { data: invoice } = await admin
      .from('invoices')
      .select(`
        id, invoice_number, subtotal, vat, discount, total, branch_id,
        order:orders(
          id, order_number, table_id, reservation_id,
          order_items(name_snapshot, quantity, unit_price, line_total)
        )
      `)
      .eq('id', body.invoiceId)
      .single()
    if (!invoice) throw new Error('Invoice not found')

    // 3. Build XML theo chuẩn Nghị định 123/2020
    const xml = buildVNInvoiceXML({
      invoiceNumber: invoice.invoice_number,
      taxCode: body.taxCode,
      customerCompany: body.customerCompany,
      customerAddress: body.customerAddress,
      items: (invoice as any).order.order_items,
      subtotal: invoice.subtotal,
      vat: invoice.vat,
      total: invoice.total,
    })

    // 4. Gọi cổng thuế (VNPT example)
    const vtApiKey = Deno.env.get('VT_API_KEY')!
    const vtApiUrl = Deno.env.get('VT_API_URL') ?? 'https://api.vntax.vn/v1/invoices'
    const resp = await fetch(vtApiUrl, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${vtApiKey}`, 'Content-Type': 'application/xml' },
      body: xml,
    })
    if (!resp.ok) {
      const err = await resp.text()
      throw new Error(`VT API error: ${err}`)
    }
    const result = await resp.json()

    // 5. Update invoice metadata
    await admin
      .from('invoices')
      .update({
        tax_code: body.taxCode,
        customer_company: body.customerCompany,
        customer_address: body.customerAddress,
        metadata: {
          ...(invoice as any).metadata,
          vt_invoice_id: result.id,
          vt_serial: result.serial,
          vt_number: result.number,
          vt_status: result.status,
          vt_xml_url: result.view_url,
          issued_at: new Date().toISOString(),
        },
      })
      .eq('id', invoice.id)

    // 6. Lưu PDF vào storage (nếu cần)
    if (result.pdf_url) {
      const { data: upload } = await admin.storage
        .from('invoices')
        .upload(`${invoice.branch_id}/${invoice.invoice_number}.pdf`, await fetch(result.pdf_url).then(r => r.blob()), {
          contentType: 'application/pdf',
        })
      if (upload) {
        await admin.from('invoices').update({
          metadata: { ...(invoice as any).metadata, pdf_path: upload.path },
        }).eq('id', invoice.id)
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        invoiceNumber: invoice.invoice_number,
        vtNumber: result.number,
        vtStatus: result.status,
        viewUrl: result.view_url,
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

function buildVNInvoiceXML(data: any): string {
  // Format XML theo Nghị định 123/2020
  return `<?xml version="1.0" encoding="UTF-8"?>
<Invoice>
  <InvoiceNumber>${data.invoiceNumber}</InvoiceNumber>
  <Buyer>
    <TaxCode>${data.taxCode}</TaxCode>
    <Name>${escapeXml(data.customerCompany)}</Name>
    <Address>${escapeXml(data.customerAddress)}</Address>
  </Buyer>
  <Items>
    ${data.items.map((it: any, i: number) => `
    <Item>
      <LineNumber>${i + 1}</LineNumber>
      <Name>${escapeXml(it.name_snapshot)}</Name>
      <Quantity>${it.quantity}</Quantity>
      <UnitPrice>${it.unit_price}</UnitPrice>
      <LineTotal>${it.line_total}</LineTotal>
    </Item>`).join('')}
  </Items>
  <SubTotal>${data.subtotal}</SubTotal>
  <VAT>${data.vat}</VAT>
  <Total>${data.total}</Total>
</Invoice>`
}

function escapeXml(s: string): string {
  return String(s).replace(/[<>&'"]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c]!))
}
```

## 10. Function: `request-checkout`

Tablet bấm "Yêu cầu thanh toán" → insert audit_event + notification.

```ts
// supabase/functions/request-checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders, getAdminClient, requireUser } from '../_shared/auth.ts'

interface Payload { tableId: string }

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user } = await requireUser(req)
    const admin = getAdminClient()
    const body: Payload = await req.json()
    const branchId = user.app_metadata?.branch_id

    // 1. Insert audit event
    await admin.from('audit_events').insert({
      branch_id: branchId,
      actor_id: user.id,
      action: 'table.checkout_requested',
      entity_type: 'table',
      entity_id: body.tableId,
      payload: {
        table_id: body.tableId,
        requested_at: new Date().toISOString(),
      },
    })

    // 2. Push notification cho reception
    await admin.from('notifications').insert({
      branch_id: branchId,
      channel: 'reception-panel',
      recipient: 'all-reception',
      template: 'checkout_request',
      variables: { table_id: body.tableId },
      status: 'pending',
    })

    return new Response(JSON.stringify({ ok: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), { status: 400, headers: corsHeaders })
  }
})
```

## 11. Deploy tất cả

```bash
cd supabase\functions
for f in check-in add-order-item checkout close-shift export-shift-csv kds-push issue-tax-invoice request-checkout custom-access-token; do
  supabase functions deploy $f
done
```

## 12. Set secrets

```bash
supabase secrets set VT_API_KEY=your-vnpt-api-key
supabase secrets set VT_API_URL=https://api.vntax.vn/v1/invoices
```

## 13. Test tổng hợp (postman/curl)

```bash
# Login → lấy token
TOKEN=$(curl -s -X POST https://<ref>.supabase.co/auth/v1/token?grant_type=password \
  -H "apikey: <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"email":"staff@nguucat.vn","password":"test1234"}' | jq -r .access_token)

# Test check-in
curl -X POST https://<ref>.supabase.co/functions/v1/check-in \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @test-checkin.json

# Test checkout
curl -X POST https://<ref>.supabase.co/functions/v1/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @test-checkout.json
```

## 14. Checklist

- [ ] 9 Edge Functions deploy thành công
- [ ] Secrets set cho VT API
- [ ] Test check-in end-to-end (reservation → table → order)
- [ ] Test checkout end-to-end (order → invoice → payment → table released)
- [ ] Test close-shift (cash difference chính xác)
- [ ] Test issue-tax-invoice (gọi VT API thành công)
- [ ] Test export-shift-csv (file CSV tải về đúng format)
- [ ] Test kds-push (notification được insert)

→ Tiếp theo: đọc `SUPABASE_IMPLEMENTATION.md` để wire SQL queries + Vue components cho từng view.
