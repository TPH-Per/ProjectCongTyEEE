-- =============================================================================
-- 20260625100000_hook_exception_guard.sql
--
-- The hook we created in 20260625080844 had no EXCEPTION handler. If anything
-- inside the body throws — an RLS surprise, an unexpected NULL cast, a race
-- during the auth.users → public.users join — GoTrue's HTTP call returns
-- `unexpected_failure` (HTTP 500) and the user CANNOT log in at all.
--
-- This migration:
--   1. Replaces the hook body with an EXCEPTION-guarded variant. On any error
--      we return the ORIGINAL event unchanged so login still succeeds (just
--      without the extra role/branch_id claims — RLS fallback in DB functions
--      `current_user_role()` / `current_branch_id()` already covers that path).
--   2. Explicitly grants SELECT on public.users to supabase_auth_admin so the
--      SELECT inside the hook never hits an RLS wall, even on older Supabase
--      versions where supabase_auth_admin didn't bypass RLS by default.
--   3. Adds `hook_version` to app_metadata so we can verify in the JWT that
--      the hook actually fired (look for "hook_version": "2026-06-25").
--
-- Idempotent: `create or replace` + `grant ... on conflict do nothing`.
-- =============================================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  claims       jsonb;
  app_meta     jsonb;
  v_user_id    uuid;
  v_role       public.user_role;
  v_branch_id  uuid;
begin
  -- The hook payload always carries `user_id`. Bail out cleanly if missing.
  v_user_id := (event ->> 'user_id')::uuid;
  if v_user_id is null then
    return event;
  end if;

  -- SECURITY DEFINER + explicit grant (below) ensure this SELECT is not
  -- blocked by RLS on public.users.
  select role, branch_id
    into v_role, v_branch_id
    from public.users
   where id = v_user_id;

  -- Preserve existing claims. Don't clobber anything Supabase already set.
  claims   := coalesce(event -> 'claims', '{}'::jsonb);
  app_meta := coalesce(claims -> 'app_metadata', '{}'::jsonb);

  -- Stamp a hook version so we can verify the hook fired by inspecting JWT.
  app_meta := app_meta || jsonb_build_object('hook_version', '2026-06-25');

  if v_role is not null then
    app_meta := app_meta || jsonb_build_object('role', v_role::text);
  end if;

  if v_branch_id is not null then
    app_meta := app_meta || jsonb_build_object('branch_id', v_branch_id::text);
  end if;

  claims := jsonb_set(claims, '{app_metadata}', app_meta);
  return jsonb_set(event, '{claims}', claims);

-- ── Safety net ───────────────────────────────────────────────────────────
-- If anything inside the body throws (RLS surprise, NULL cast, race), we
-- return the ORIGINAL event untouched. Login will still succeed; the user
-- just won't have the extra role/branch_id in this JWT. The DB-side
-- `current_user_role()` / `current_branch_id()` helpers fall back to a
-- `public.users` lookup, so RLS-protected queries still work correctly.
exception
  when others then
    return event;
end;
$$;

-- Permissions: only supabase_auth_admin (the role GoTrue uses) may invoke.
revoke execute on function public.custom_access_token_hook(jsonb)
  from public, anon, authenticated;

grant execute on function public.custom_access_token_hook(jsonb)
  to supabase_auth_admin;

-- Explicit grant so the SECURITY DEFINER body can SELECT from public.users
-- without hitting RLS even on older Supabase versions.
grant select on public.users to supabase_auth_admin;