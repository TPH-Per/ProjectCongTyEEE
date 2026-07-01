-- =============================================================================
-- 20260625200200_auth_trigger_no_metadata_decisions.sql
--
-- Senior security review (2026-06-25):
--
-- The handle_new_auth_user() trigger was reading role and branch_id out of
-- auth.users.raw_user_meta_data. raw_user_meta_data is the same source as
-- user_metadata — set on the auth.users row and editable by the user via
-- auth.updateUser() (when called via the anon-key client). Reading role /
-- branch_id from there means a signed-in user can self-promote to admin
-- and set their own branch. That violates the senior security rule
-- "never use user_metadata / raw_user_meta_data for authorization or
-- branch/role decisions".
--
-- The previous trigger ALSO created a race: admin-user-manager calls
-- auth.admin.createUser() (trigger fires, inserts with role from
-- raw_user_meta_data — usually NULL → defaulted to 'staff'), THEN tries
-- to INSERT into public.users with the real role/branch_id. The second
-- INSERT hit the primary-key UNIQUE constraint and the trigger's
-- `on conflict do nothing` silently dropped the intended role.
--
-- This migration rewrites the trigger to:
--
--   1. Only mirror identity (id, email, full_name) from raw_user_meta_data.
--      full_name is the only field it's reasonable to read there because
--      it isn't used for authorization — it's just a display label.
--   2. NOT derive role or branch_id from raw_user_meta_data. They default
--      to NULL/''staff'' and MUST be set explicitly by an admin-controlled
--      path (the admin-user-manager Edge Function, or a manual UPDATE).
--
-- admin-user-manager is updated separately to handle the case where the
-- trigger already inserted a default row: it now uses UPSERT so the
-- caller-supplied role/branch_id always wins.
--
-- Idempotent: `create or replace`. Safe to re-run.
-- =============================================================================

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_full_name text;
begin
  -- full_name is the ONLY field we read from raw_user_meta_data — and
  -- only because it isn't used for authorization, only as a display
  -- label. Fallback to the local-part of the email so the row is never
  -- fully empty.
  v_full_name := coalesce(
    nullif(new.raw_user_meta_data->>'full_name', ''),
    split_part(new.email, '@', 1)
  );

  -- role defaults to 'staff' (the safest least-privilege choice) and
  -- branch_id defaults to NULL. Both MUST be set by an admin-controlled
  -- operation before this account can do anything privileged — the
  -- RLS policies key on current_user_role() / current_branch_id()
  -- and both return NULL/safe values until then.
  insert into public.users (id, email, full_name, role, branch_id, is_active)
  values (new.id, new.email, v_full_name, 'staff'::public.user_role, null, true)
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Permissions: only Supabase Auth internals may invoke directly. `auth` is a
-- schema, not a database role; local shadow databases provide
-- `supabase_auth_admin` for GoTrue/Auth-owned operations.
revoke execute on function public.handle_new_auth_user() from public;
grant execute on function public.handle_new_auth_user() to supabase_auth_admin;
