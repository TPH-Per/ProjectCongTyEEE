-- =============================================================================
-- 20260624000000_fix_current_user_role_anon.sql
-- Fix: current_user_role() crashes on anon requests with "invalid input value
-- for enum user_role: 'anon'". This breaks every anon PostgREST request that
-- touches an RLS-protected table.
--
-- Root cause: the function did `(... ->> 'role')::user_role` directly. For
-- anon / authenticated PostgREST roles, the JWT `role` claim is 'anon' or
-- 'authenticated' — not in our user_role enum — so the cast raises SQLSTATE
-- 22P02 before coalesce() can fall back to the public.users lookup.
--
-- Fix: whitelist the JWT role against the enum values before casting. If the
-- claim isn't a valid user_role, return NULL and let coalesce() fall through.
-- =============================================================================

create or replace function public.current_user_role()
returns user_role language sql stable security definer set search_path = public, auth as $$
  select coalesce(
    case
      when (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')
           in ('admin','manager','reception','staff','kitchen')
      then ((nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')::user_role)
    end,
    (select role from public.users where id = auth.uid())
  )
$$;

-- Also harden has_role() against the same enum cast edge case (it currently
-- calls the same bare ::user_role cast). Even with current_user_role() fixed,
-- has_role() might be called from contexts that haven't been migrated yet.
create or replace function public.has_role(roles user_role[])
returns boolean language sql stable security definer set search_path = public, auth as $$
  select case
    when (select public.current_user_role()) is null then false
    else (select public.current_user_role()) = any(roles)
  end
$$;
