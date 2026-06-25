// supabase/functions/request-checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface Payload { tableId: string }

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Tablet / staff / reception / manager can request checkout.
    // Branch_id comes from the profile, never from user_metadata.
    const { user, profile, admin } = await requireAppUser(req)
    const body: Payload = await req.json()
    const branchId = profile.branch_id
    if (!branchId) throw new AuthError('Tài khoản chưa gán chi nhánh', 403)

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

    return new Response(
      JSON.stringify({ ok: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    const status = e instanceof AuthError ? e.status : 400
    return new Response(JSON.stringify({ error: e.message }), { status, headers: corsHeaders })
  }
})
