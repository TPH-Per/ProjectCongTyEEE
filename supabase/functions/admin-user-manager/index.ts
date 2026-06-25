import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Verify requesting user is admin
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) throw new Error('Unauthorized')

    const { data: userProfile } = await supabaseClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (userProfile?.role !== 'admin' && userProfile?.role !== 'manager') {
      throw new Error('Forbidden: Only admins/managers can perform this action')
    }

    // Use Service Role Key for Admin operations
    const adminAuthClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body = await req.json()
    const { action, payload } = body

    if (action === 'create_user') {
      const { email, password, full_name, role, branch_id } = payload

      // 1. Create auth user
      const { data: authData, error: authError } = await adminAuthClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      })

      if (authError) throw authError

      // 2. Create public.users record
      const { error: dbError } = await adminAuthClient
        .from('users')
        .insert({
          id: authData.user.id,
          email,
          full_name,
          role,
          branch_id,
          is_active: true
        })

      if (dbError) {
        // Rollback auth user
        await adminAuthClient.auth.admin.deleteUser(authData.user.id)
        throw dbError
      }

      return new Response(JSON.stringify({ user: authData.user }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    if (action === 'update_user') {
      const { userId, role, branch_id, is_active } = payload
      
      const { error: dbError } = await adminAuthClient
        .from('users')
        .update({ role, branch_id, is_active })
        .eq('id', userId)

      if (dbError) throw dbError

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    if (action === 'reset_password') {
      const { userId, password } = payload
      
      const { error: authError } = await adminAuthClient.auth.admin.updateUserById(
        userId,
        { password: password }
      )

      if (authError) throw authError

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    throw new Error('Invalid action')

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
