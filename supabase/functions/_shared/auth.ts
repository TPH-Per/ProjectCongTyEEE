// supabase/functions/_shared/auth.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export function getSupabaseClient(req: Request) {
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

export function getAdminClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  )
}

/**
 * Set the Postgres session config `request.jwt.claims` to the user's JWT
 * payload. Many DB helpers (`current_branch_id()`, `current_user_role()`,
 * `has_role()` RLS policies, audit triggers that read `current_branch_id()`)
 * look up the calling user from `request.jwt.claims`.
 *
 * Edge Functions run with the service role, which has NO auth context of
 * its own — `auth.uid()` returns NULL and `current_setting('request.jwt.claims', true)`
 * returns empty. So we have to stamp the claims manually before any insert/
 * update that fires a trigger reading those helpers.
 *
 * `is_local: false` = session-wide (the admin client's connection is short-lived,
 * one session per request — so session-scoped is safe).
 *
 * Without this, the `write_audit` trigger on table_assignments / orders /
 * invoices / payments / shifts inserts `branch_id = NULL` into audit_events,
 * which fails the NOT NULL constraint and the entire function returns 400.
 */
export async function setJwtContext(
  admin: ReturnType<typeof getAdminClient>,
  userId: string,
  appMetadata: Record<string, unknown> | undefined,
): Promise<void> {
  const claims = {
    sub: userId,
    role: 'authenticated',
    aud: 'authenticated',
    app_metadata: appMetadata ?? {},
    user_metadata: {},
  }
  await admin.rpc('set_config', {
    setting_name: 'request.jwt.claims',
    setting_value: JSON.stringify(claims),
    is_local: false,
  })
}

export async function requireUser(req: Request) {
  const supabase = getSupabaseClient(req)
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) throw new Error('Unauthorized')
  return { supabase, user }
}