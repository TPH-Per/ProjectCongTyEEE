-- =============================================================================
-- 20260625080844_auth_hook_custom_access_token.sql
--
-- Postgres function backing the Supabase Auth "Custom Access Token" hook.
--
-- The hook fires on every issued access token (login + refresh) and lets us
-- inject extra `app_metadata` claims into the JWT. We use it to copy the
-- user's `role` and `branch_id` from the `public.users` row into the token,
-- so RLS policies that key on `auth.jwt() -> 'app_metadata' -> 'role'`
-- (and the `current_user_role()` / `current_branch_id()` helpers that read
-- those claims first before falling back to a DB lookup) don't have to hit
-- `public.users` on every request.
--
-- The function MUST have signature `(event jsonb) returns jsonb` and be
-- `STABLE` (not VOLATILE) so Supabase can cache the plan. See
-- https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook
--
-- After this migration is applied, the function will appear in the
-- "Database Function" picker on
--   Dashboard → Authentication → Hooks → Custom Access Token → Type
-- along with the alternative "Edge Function" option (we deployed
-- `supabase/functions/custom-access-token` for that path too — pick ONE).
--
-- The migration is idempotent (`create or replace`) so re-running it after
-- the hook is already wired up is safe.
-- =============================================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = public, auth
as $$
declare
  claims       jsonb;
  app_meta     jsonb;
  v_user_id    uuid;
  v_role       public.user_role;
  v_branch_id  uuid;
begin
  -- The hook payload always carries `user_id` (the auth.users.id of the
  -- user being signed in). Bail out cleanly if it's somehow missing —
  -- Supabase expects the original `event` back in that case.
  v_user_id := (event ->> 'user_id')::uuid;
  if v_user_id is null then
    return event;
  end if;

  -- Pull the role + branch_id straight from the profile row.
  -- SECURITY INVOKER (default) is fine here: the function runs as
  -- supabase_auth_admin, which has the right grants on public.users.
  select role, branch_id
    into v_role, v_branch_id
    from public.users
   where id = v_user_id;

  -- Always start from the existing claims. Don't clobber anything
  -- Supabase already set (aud, exp, iat, sub, email, …).
  claims   := coalesce(event -> 'claims', '{}'::jsonb);
  app_meta := coalesce(claims -> 'app_metadata', '{}'::jsonb);

  if v_role is not null then
    app_meta := app_meta || jsonb_build_object('role', v_role::text);
  end if;

  if v_branch_id is not null then
    app_meta := app_meta || jsonb_build_object('branch_id', v_branch_id::text);
  end if;

  claims := jsonb_set(claims, '{app_metadata}', app_meta);
  return jsonb_set(event, '{claims}', claims);
end;
$$;

-- =============================================================================
-- Grants — this is the part the Supabase docs gloss over.
--
-- Postgres grants EXECUTE to PUBLIC by default for every new function, which
-- would make this hook callable by `anon` / `authenticated` clients. The
-- supabase_auth_admin role is the only one that should be able to invoke it
-- (it's the role Supabase uses to run auth hooks server-side).
-- =============================================================================

revoke execute on function public.custom_access_token_hook(jsonb)
  from public, anon, authenticated;

grant execute on function public.custom_access_token_hook(jsonb)
  to supabase_auth_admin;
