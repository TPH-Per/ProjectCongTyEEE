// supabase/functions/close-shift/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface CloseShiftPayload {
  shiftId: string
  closingCash: number
  notes?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Only reception / manager / admin can close shifts. Staff shouldn't be
    // able to (they have no business with the shift ledger).
    const { user, profile, admin } = await requireAppUser(req, {
      roles: ['reception', 'manager', 'admin'],
    })
    const body: CloseShiftPayload = await req.json()

    // 1. Lấy shift
    const { data: shift } = await admin
      .from('shifts')
      .select('id, branch_id, user_id, status, opening_cash')
      .eq('id', body.shiftId)
      .single()
    if (!shift) throw new Error('Shift not found')
    if (shift.status !== 'open') throw new Error('Shift đã đóng')

    // Branch ownership (admin bypasses)
    if (profile.role !== 'admin' && profile.branch_id !== shift.branch_id) {
      throw new AuthError('Shift thuộc chi nhánh khác — bạn không có quyền đóng', 403)
    }

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
        closed_by: user.id,
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
    const status = e instanceof AuthError ? e.status : 400
    return new Response(
      JSON.stringify({ error: e.message }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
