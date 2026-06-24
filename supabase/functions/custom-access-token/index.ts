import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const payload = await req.json()
  const userId = payload.user_id
  const claims = payload.claims ?? {}

  if (!userId) {
    return new Response(JSON.stringify({ error: 'user_id required' }), { status: 400 })
  }

  // Admin client để bypass RLS
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  const { data: user } = await supabaseAdmin
    .from('users')
    .select('role, branch_id')
    .eq('id', userId)
    .single()

  return new Response(
    JSON.stringify({
      ...claims,
      role: user?.role ?? 'staff',
      branch_id: user?.branch_id,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})