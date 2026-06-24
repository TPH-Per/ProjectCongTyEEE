// supabase/functions/request-checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { getAdminClient, requireUser } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

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