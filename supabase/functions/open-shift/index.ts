// supabase/functions/open-shift/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface OpenShiftPayload {
  branchId: string
  openingCash: number
  notes?: Record<string, unknown>
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user, profile, admin } = await requireAppUser(req, {
      roles: ['reception', 'manager', 'admin'],
    })
    const body: OpenShiftPayload = await req.json()

    if (!body.branchId) throw new AuthError('branchId là bắt buộc', 400)
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.branchId)) throw new AuthError('branchId không phải UUID', 400)
    if (!Number.isFinite(body.openingCash) || body.openingCash < 0) {
      throw new AuthError('openingCash phải ≥ 0', 400)
    }

    if (profile.role !== 'admin' && profile.branch_id !== body.branchId) {
      throw new AuthError('Branch mismatch', 403)
    }

    const { data, error } = await admin.rpc('shift_open', {
      p_branch_id: body.branchId,
      p_opening_cash: body.openingCash,
      p_notes: body.notes ?? {},
    })
    if (error) throw error

    return new Response(
      JSON.stringify(data),
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