-- =============================================================================
-- 20260625200000_fix_jwt_helpers_read_app_metadata.sql
--
-- Bug audit (senior full-stack review 2026-06-25):
--
-- The custom_access_token_hook (20260625080844 / 20260625100000) writes the
-- `role` and `branch_id` into `claims.app_metadata` — that's the only place
-- Supabase signs into the JWT. But the SQL helpers `current_branch_id()`,
-- `current_user_role()`, and `has_role()` were reading the top-level
-- `claims->>'role'` / `claims->>'branch_id'`. Those keys never exist, so
-- every helper was silently returning NULL → RLS saw "no branch match" →
-- the audit trigger inserted branch_id=NULL → 400 on every write.
--
-- This migration rewrites the three helpers to read
--   claims -> 'app_metadata' ->> 'role'
--   claims -> 'app_metadata' ->> 'branch_id'
-- (with a back-compat fallback to the top-level key for older JWTs that may
-- still be in circulation from before the hook was wired up), then falls
-- back to a `public.users` lookup so RLS keeps working when the hook is
-- temporarily broken or hasn't fired yet.
--
-- Idempotent: `create or replace`. Safe to re-run.
-- =============================================================================

create or replace function public.current_branch_id()
returns uuid
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Prefer JWT claim (set by the custom_access_token_hook), fall back to DB.
  -- Order:
  --   1. claims.app_metadata.branch_id      (new — what the hook actually writes)
  --   2. claims.branch_id                   (legacy, in case old JWT still in flight)
  --   3. public.users.branch_id             (final fallback)
  select coalesce(
    nullif(
      coalesce(
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'branch_id'),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'branch_id')
      ),
      ''
    )::uuid,
    (select branch_id from public.users where id = auth.uid())
  );
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Whitelist the role claim against the user_role enum BEFORE casting, to
  -- avoid 22P02 when the JWT carries a PostgREST role like 'anon' /
  -- 'authenticated' / 'service_role' (those are not in our enum).
  select coalesce(
    case
      when coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           ) in ('admin','manager','reception','staff','kitchen')
      then (coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           )::public.user_role)
    end,
    (select role from public.users where id = auth.uid())
  );
$$;

create or replace function public.has_role(roles public.user_role[])
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Delegate to current_user_role() so the whitelist logic stays in one place.
  select case
    when (select public.current_user_role()) is null then false
    else (select public.current_user_role()) = any(roles)
  end;
$$;

-- =============================================================================
-- Grants — these helpers are called from RLS policies and triggers, which
-- run as the table owner. They need to be executable by the relevant DB roles.
-- =============================================================================

revoke execute on function public.current_branch_id()    from public;
revoke execute on function public.current_user_role()    from public;
revoke execute on function public.has_role(public.user_role[]) from public;

grant execute on function public.current_branch_id()    to anon, authenticated, service_role;
grant execute on function public.current_user_role()    to anon, authenticated, service_role;
grant execute on function public.has_role(public.user_role[]) to anon, authenticated, service_role;
