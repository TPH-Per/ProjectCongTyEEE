// supabase/functions/export-shift-csv/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Manager / admin only — exporting the full shift ledger is sensitive.
    const { profile, admin } = await requireAppUser(req, {
      roles: ['manager', 'admin'],
    })
    const url = new URL(req.url)
    const shiftId = url.searchParams.get('shiftId')
    if (!shiftId) throw new Error('shiftId required')

    // Verify shift exists and is in caller's branch (admin bypasses).
    const { data: shift } = await admin
      .from('shifts')
      .select('id, branch_id')
      .eq('id', shiftId)
      .maybeSingle()
    if (!shift) throw new Error('Shift not found')
    if (profile.role !== 'admin' && profile.branch_id !== shift.branch_id) {
      throw new AuthError('Shift thuộc chi nhánh khác — bạn không có quyền export', 403)
    }

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
    const status = e instanceof AuthError ? e.status : 400
    return new Response(
      JSON.stringify({ error: e.message }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
