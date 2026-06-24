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