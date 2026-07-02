// supabase/functions/admin-user-manager/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAppUser, AuthError, type AppRole } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

/**
 * Admin user-management endpoint.
 *
 * Authorization model (per business logic):
 *
 *   action=create_user   → admin OR manager (manager can only create staff/
 *                          reception for their own branch; cannot create admin
 *                          or another manager or cross-branch accounts)
 *   action=update_user   → admin for role/branch changes.
 *                          admin + manager for is_active/branch_id (manager
 *                          limited to their own branch and cannot escalate
 *                          another account to admin).
 *   action=reset_password→ admin only.
 */

const ADMIN_OR_MANAGER: AppRole[] = ['superadmin', 'manager']

function getAdminAuthClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } },
  )
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify caller is at least a manager. Specific actions re-check below.
    const { profile: caller, admin } = await requireAppUser(req, {
      roles: ADMIN_OR_MANAGER,
    })
    const body = await req.json()
    const { action, payload } = body

    const supabaseAdmin = admin

    if (action === 'create_user') {
      // Managers cannot create admin or manager accounts.
      if (caller.role !== 'superadmin' && payload.role !== 'staff' && payload.role !== 'reception') {
        throw new AuthError('Manager chỉ được tạo tài khoản staff/reception', 403)
      }
      // Managers can only assign users to their own branch.
      if (caller.role !== 'superadmin' && payload.branch_id !== caller.branch_id) {
        throw new AuthError('Manager chỉ được tạo tài khoản cho chi nhánh của mình', 403)
      }

      const { email, password, full_name, role, branch_id } = payload

      // Validate inputs that the SQL CHECK constraints would otherwise
      // catch with a less friendly error.
      const validRoles = ['superadmin', 'manager', 'reception', 'staff', 'procurement_manager', 'procurement_staff', 'accountant', 'crm_manager', 'marketing']
      if (!validRoles.includes(role)) {
        throw new AuthError(`Role không hợp lệ: '${role}'`, 400)
      }
      // branch_id must be a UUID when provided.
      if (branch_id !== undefined && branch_id !== null && branch_id !== '') {
        if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(branch_id)) {
          throw new AuthError(`branch_id không phải UUID hợp lệ: '${branch_id}'`, 400)
        }
      }

      // 1. Create auth user — the handle_new_auth_user trigger fires here
      //    and inserts a default public.users row (role='staff', branch_id=NULL).
      const adminAuthClient = getAdminAuthClient()
      const { data: authData, error: authError } = await adminAuthClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      })

      if (authError) throw authError

      // 2. UPSERT the real role / branch_id / full_name. We can't use plain
      //    INSERT because the trigger already inserted a row (with the
      //    defaults 'staff'/NULL). UPSERT guarantees the caller's values
      //    win — even if the trigger pre-inserted, even if the row was
      //    partially created by another path (Dashboard signup).
      const { error: dbError } = await supabaseAdmin
        .from('users')
        .upsert(
          {
            id: authData.user.id,
            email,
            full_name: full_name ?? null,
            role,
            branch_id: branch_id || null,
            is_active: true,
          },
          { onConflict: 'id' },
        )

      if (dbError) {
        // Rollback auth user on DB upsert failure
        await adminAuthClient.auth.admin.deleteUser(authData.user.id)
        throw dbError
      }

      // 3. Audit log
      await supabaseAdmin.from('audit_events').insert({
        branch_id: caller.branch_id,
        actor_id: caller.id,
        action: 'user.created',
        entity_type: 'user',
        entity_id: authData.user.id,
        payload: { email, role, branch_id, created_by_role: caller.role },
      })

      return new Response(
        JSON.stringify({ user: { id: authData.user.id, email } }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
      )
    }

    if (action === 'update_user') {
      const { userId, role, branch_id, is_active, full_name } = payload

      // Load target so we can decide permission.
      const { data: target } = await supabaseAdmin
        .from('users')
        .select('id, email, role, branch_id, is_active')
        .eq('id', userId)
        .maybeSingle()
      if (!target) throw new AuthError('User không tồn tại', 404)

      // ── Authorization rules for update_user ───────────────────────
      const isSensitiveChange =
        (role !== undefined && role !== target.role) ||
        (branch_id !== undefined && branch_id !== target.branch_id)

      // Changing role / branch on an admin → only admin can do it.
      if (isSensitiveChange && target.role === 'superadmin' && caller.role !== 'superadmin') {
        throw new AuthError('Chỉ admin mới được đổi role/branch của admin khác', 403)
      }
      // Promoting anyone TO admin → admin only.
      if (role === 'superadmin' && caller.role !== 'superadmin') {
        throw new AuthError('Chỉ admin mới được phong admin', 403)
      }
      // Manager: can only touch users in their own branch (and cannot
      // promote anyone to admin or another manager).
      if (caller.role !== 'superadmin') {
        if (target.branch_id !== caller.branch_id) {
          throw new AuthError('Manager chỉ được sửa user thuộc chi nhánh của mình', 403)
        }
        if (role === 'manager' || role === 'superadmin') {
          throw new AuthError('Manager không được phong manager/admin', 403)
        }
        if (branch_id !== undefined && branch_id !== caller.branch_id) {
          throw new AuthError('Manager không được chuyển user sang chi nhánh khác', 403)
        }
      }

      const update: Record<string, unknown> = {}
      if (role !== undefined) update.role = role
      if (branch_id !== undefined) update.branch_id = branch_id === '' ? null : branch_id
      if (is_active !== undefined) update.is_active = is_active
      if (full_name !== undefined) update.full_name = full_name

      // Validate role if it's being changed.
      if (role !== undefined) {
        const validRoles = ['superadmin', 'manager', 'reception', 'staff', 'procurement_manager', 'procurement_staff', 'accountant', 'crm_manager', 'marketing']
        if (!validRoles.includes(role)) {
          throw new AuthError(`Role không hợp lệ: '${role}'`, 400)
        }
      }
      // Validate branch_id format if being changed.
      if (branch_id !== undefined && branch_id !== null && branch_id !== '') {
        if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(branch_id)) {
          throw new AuthError(`branch_id không phải UUID hợp lệ: '${branch_id}'`, 400)
        }
      }

      const { error: dbError } = await supabaseAdmin
        .from('users')
        .update(update)
        .eq('id', userId)
      if (dbError) throw dbError

      // Audit branch_id: the TARGET user's branch after the change (not the
      // caller's branch). This way, an admin acting on a different branch's
      // user records the action under that branch's audit log — which is
      // where the security team will be looking when investigating.
      const newBranchId = (branch_id !== undefined ? branch_id : target.branch_id) ?? null
      await supabaseAdmin.from('audit_events').insert({
        branch_id: newBranchId,
        actor_id: caller.id,
        action: 'user.updated',
        entity_type: 'user',
        entity_id: userId,
        payload: { changes: update, updated_by_role: caller.role, target_email: target.email },
      })

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
      )
    }

    if (action === 'reset_password') {
      // Reset password is admin-only.
      if (caller.role !== 'superadmin') {
        throw new AuthError('Chỉ admin mới được reset mật khẩu', 403)
      }
      const { userId, password } = payload

      const adminAuthClient = getAdminAuthClient()
      const { data: target } = await supabaseAdmin
        .from('users')
        .select('id, email, role')
        .eq('id', userId)
        .maybeSingle()
      if (!target) throw new AuthError('User không tồn tại', 404)

      const { error: authError } = await adminAuthClient.auth.admin.updateUserById(
        userId,
        { password },
      )
      if (authError) throw authError

      await supabaseAdmin.from('audit_events').insert({
        branch_id: caller.branch_id,
        actor_id: caller.id,
        action: 'user.password_reset',
        entity_type: 'user',
        entity_id: userId,
        payload: { target_email: target.email, target_role: target.role },
      })

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
      )
    }

    throw new AuthError('Invalid action', 400)
  } catch (error: any) {
    const status = error.name === 'AuthError' ? error.status : (error.status || 400)
    return new Response(
      JSON.stringify({ error: error.message, errorName: error.name }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status,
      },
    )
  }
})
