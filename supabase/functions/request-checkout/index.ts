// supabase/functions/request-checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface Payload { tableId: string }

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Tablet / staff / reception / manager can request checkout.
    // Branch_id is sourced from the validated TABLE, not the profile —
    // an admin acting on behalf of a different branch should record the
    // event under that branch's audit log.
    const { user, profile, admin } = await requireAppUser(req)
    const body: Payload = await req.json()

    if (!body.tableId) throw new AuthError('tableId là bắt buộc', 400)
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.tableId)) throw new AuthError('tableId không phải UUID', 400)

    // 1. Load + validate the table. Reject cross-branch (admin bypasses).
    const { data: table } = await admin
      .from('tables')
      .select('id, branch_id, code, status')
      .eq('id', body.tableId)
      .maybeSingle()
    if (!table) throw new AuthError('Table không tồn tại', 404)
    if (profile.role !== 'admin' && table.branch_id !== profile.branch_id) {
      throw new AuthError('Table thuộc chi nhánh khác', 403)
    }
    // Notification + audit go under the TABLE's branch, so cross-branch
    // admin actions are recorded against the right branch's audit log.
    const branchId = table.branch_id

    // 2. Insert audit event
    await admin.from('audit_events').insert({
      branch_id: branchId,
      actor_id: user.id,
      action: 'table.checkout_requested',
      entity_type: 'table',
      entity_id: body.tableId,
      payload: {
        table_id: body.tableId,
        table_code: table.code,
        requested_at: new Date().toISOString(),
      },
    })

    // 3. Push notification cho reception
    await admin.from('notifications').insert({
      branch_id: branchId,
      channel: 'reception-panel',
      recipient: 'all-reception',
      template: 'checkout_request',
      variables: { table_id: body.tableId, table_code: table.code },
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
