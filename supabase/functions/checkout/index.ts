// supabase/functions/checkout/index.ts
//
// ⚠️ DEPRECATED — kept as a forwarding shim only.
//
// The cashier UI (src/composables/useCheckout.ts) calls the
// `process_checkout` SQL RPC directly. This Edge Function used to implement
// checkout in TypeScript with its own invoice + voucher math, but that path
// drifted from the DB (status enum mismatch: 'paid' vs 'VALID/UPDATED',
// service charge was never persisted, voucher discount silently dropped,
// `increment_customer_stats` RPC didn't exist, etc.).
//
// All logic now lives in the `process_checkout` RPC. This file is preserved
// so old callers / curl scripts don't 404. Anything hitting this endpoint
// gets forwarded to the canonical RPC via the admin client.
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface LegacyCheckoutPayload {
  orderId: string
  revenueType?: 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
  customerId?: string
  voucherCode?: string
  taxCode?: string
  customerCompany?: string
  customerAddress?: string
  payments?: unknown
  notes?: string
  // Modern callers may also pass:
  paymentMethod?: string
  paymentRef?: string
  pointsToRedeem?: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { profile, admin } = await requireAppUser(req, {
      roles: ['reception', 'manager', 'admin'],
    })
    const body: LegacyCheckoutPayload = await req.json()

    if (!body.orderId) throw new AuthError('orderId là bắt buộc', 400)
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.orderId)) throw new AuthError('orderId không phải UUID', 400)

    // Resolve the order's branch so we can forward the call correctly.
    const { data: order } = await admin
      .from('orders')
      .select('id, branch_id, customer_id')
      .eq('id', body.orderId)
      .maybeSingle()
    if (!order) throw new AuthError('Order not found', 404)

    console.warn(
      '[DEPRECATED] supabase/functions/checkout called directly — forwarding to process_checkout RPC. ' +
      'Please update your caller to use the RPC instead.',
    )

    const paymentMethod = (body.paymentMethod ?? 'CASH').toUpperCase()
    const { data, error } = await admin.rpc('process_checkout', {
      p_order_id: order.id,
      p_branch_id: order.branch_id,
      p_cashier_id: profile.id,
      p_payment_method: paymentMethod,
      p_voucher_code: body.voucherCode ?? null,
      p_points_to_use: body.pointsToRedeem ?? 0,
    })
    if (error) throw error

    return new Response(
      JSON.stringify({ ok: true, ...(data as Record<string, unknown>) }),
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