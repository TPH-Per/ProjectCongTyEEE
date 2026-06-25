// supabase/functions/_shared/auth.ts
//
// Shared auth helpers for all Edge Functions. Every protected function
// MUST go through `requireAppUser(req, allowedRoles?)` instead of rolling
// its own `supabase.auth.getUser()` dance — otherwise we get inconsistent
// role/branch enforcement and "logged-in user + service-role = god mode"
// bugs that RLS can't catch (because service_role bypasses RLS by design).
//
// Contract:
//
//   const { user, profile, supabase, admin } = await requireAppUser(req, {
//     roles: ['manager', 'admin'],
//     resourceBranchId: order?.branch_id,   // optional cross-check
//   });
//
//   if (profile.branch_id !== resource.branch_id) throw forbidden();
//
// `profile` is the row from `public.users` (id, email, role, branch_id,
// is_active, full_name). Reading authorization from there — not from
// `user.user_metadata` or top-level JWT claims — keeps the source of
// truth in one place.

import { createClient, type SupabaseClient, type User } from 'https://esm.sh/@supabase/supabase-js@2'

export type AppRole = 'admin' | 'manager' | 'reception' | 'staff' | 'kitchen'

export interface AppProfile {
  id: string
  email: string
  full_name: string | null
  role: AppRole
  branch_id: string | null
  is_active: boolean
}

export interface RequireAppUserOptions {
  /** Whitelist of roles allowed through. Omit to allow any logged-in active user. */
  roles?: AppRole[]
  /**
   * If provided, the function asserts that `profile.branch_id` matches this
   * value. Admins bypass the check (they supervise across branches).
   */
  resourceBranchId?: string | null
}

export interface RequireAppUserResult {
  /** The Supabase auth user (id, email, app_metadata, …). */
  user: User
  /** The matching row from `public.users` — the auth source of truth. */
  profile: AppProfile
  /** Supabase client scoped to the caller's JWT (RLS-respecting). */
  supabase: SupabaseClient
  /** Service-role client (bypasses RLS — use for cross-table lookups only). */
  admin: SupabaseClient
}

/** Thrown by requireAppUser on any auth failure. Caller should map to 401/403. */
export class AuthError extends Error {
  readonly status: 401 | 403
  constructor(message: string, status: 401 | 403) {
    super(message)
    this.name = 'AuthError'
    this.status = status
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supabase client factories
// ─────────────────────────────────────────────────────────────────────────────

export function getSupabaseClient(req: Request): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: {
          Authorization: req.headers.get('Authorization')!,
        },
      },
    },
  )
}

export function getAdminClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// JWT context stamping (so DB-side helpers can read our claims)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Stamp `request.jwt.claims` on the admin client's connection so DB helpers
 * (current_branch_id, current_user_role, has_role RLS, audit triggers that
 * read current_branch_id) see the right user/branch during this request.
 *
 * `is_local: false` = session-wide; safe because the admin client's connection
 * is short-lived (one session per request).
 *
 * Without this, the `write_audit` trigger on table_assignments / orders /
 * invoices / payments / shifts inserts `branch_id = NULL` into audit_events,
 * which fails the NOT NULL constraint and the whole function returns 400.
 */
export async function setJwtContext(
  admin: SupabaseClient,
  userId: string,
  appMetadata: Record<string, unknown> | undefined,
  branchIdFallback?: string | null,
): Promise<void> {
  const claims = {
    sub: userId,
    role: 'authenticated',
    aud: 'authenticated',
    // Important: put role + branch_id under app_metadata, where the SQL
    // helpers actually read them. The hook writes there too — keep them in
    // sync so a JWT minted by the hook and a JWT stamped by this function
    // look the same to current_branch_id() / current_user_role().
    app_metadata: {
      ...(appMetadata ?? {}),
      branch_id: (appMetadata as any)?.branch_id ?? branchIdFallback ?? null,
    },
    user_metadata: {},
  }
  await admin.rpc('set_config', {
    setting_name: 'request.jwt.claims',
    setting_value: JSON.stringify(claims),
    is_local: false,
  })
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth helpers — the only entry points Edge Functions should use
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Verify the caller's JWT, load their `public.users` profile, and assert
 * they are active + have one of the allowed roles + (optionally) match
 * the resource branch. Throws `AuthError` on any failure; the caller's
 * try/catch should turn that into a 401/403 response.
 */
export async function requireAppUser(
  req: Request,
  options: RequireAppUserOptions = {},
): Promise<RequireAppUserResult> {
  const supabase = getSupabaseClient(req)

  // 1. Verify JWT. `getUser()` re-fetches from GoTrue so a stolen JWT
  //    that's been revoked can't pass.
  const { data: userData, error: userErr } = await supabase.auth.getUser()
  if (userErr || !userData?.user) {
    throw new AuthError('Unauthorized', 401)
  }
  const user = userData.user

  // 2. Load profile from public.users. We use the admin client because
  //    RLS on `public.users` may filter rows by branch_id, and we need
  //    the row for the caller themselves — which is allowed under RLS,
  //    but using admin avoids any policy drift between this function
  //    and the active policy set.
  const admin = getAdminClient()
  const { data: profileRow, error: profileErr } = await admin
    .from('users')
    .select('id, email, full_name, role, branch_id, is_active')
    .eq('id', user.id)
    .maybeSingle()

  if (profileErr) {
    throw new AuthError(`Profile lookup failed: ${profileErr.message}`, 403)
  }
  if (!profileRow) {
    throw new AuthError('Tài khoản chưa có hồ sơ trong hệ thống (liên hệ admin)', 403)
  }
  if (profileRow.is_active === false) {
    throw new AuthError('Tài khoản đã bị vô hiệu hoá', 403)
  }
  const profile = profileRow as AppProfile

  // 3. Role whitelist (case-insensitive against our enum).
  if (options.roles && options.roles.length > 0) {
    const normalizedRole = String(profile.role).toLowerCase() as AppRole
    if (!options.roles.includes(normalizedRole)) {
      throw new AuthError(
        `Forbidden: cần vai trò ${options.roles.join('/')}, hiện tại là '${profile.role}'`,
        403,
      )
    }
  }

  // 4. Resource-branch match. Admins bypass (they supervise across branches).
  if (
    options.resourceBranchId !== undefined &&
    options.resourceBranchId !== null &&
    profile.role !== 'admin'
  ) {
    if (!profile.branch_id) {
      throw new AuthError('Tài khoản chưa gán chi nhánh', 403)
    }
    if (profile.branch_id !== options.resourceBranchId) {
      throw new AuthError(
        'Forbidden: resource thuộc chi nhánh khác với tài khoản của bạn',
        403,
      )
    }
  }

  // 5. Stamp JWT context so DB helpers / audit triggers see the right claims.
  await setJwtContext(admin, user.id, user.app_metadata, profile.branch_id)

  return { user, profile, supabase, admin }
}

/**
 * Legacy entry point — just verifies the JWT, returns the auth user.
 * Kept for any function that doesn't need the full profile lookup.
 * Prefer `requireAppUser` everywhere.
 */
export async function requireUser(req: Request) {
  const supabase = getSupabaseClient(req)
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) throw new AuthError('Unauthorized', 401)
  return { supabase, user }
}
