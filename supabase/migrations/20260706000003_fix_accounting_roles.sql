-- =============================================================================
-- 20260706000003_fix_accounting_roles.sql
-- Fix JWT claim reading for accounting roles
-- =============================================================================

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  -- Whitelist the role claim against the user_role enum BEFORE casting
  SELECT coalesce(
    case
      when coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           ) in (
             'admin','manager','reception','staff','kitchen',
             'customer','procurement','procurement_manager','procurement_staff',
             'accounting','accounting_manager','crm_manager','marketing','bod','tablet'
           )
      then (coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           )::public.user_role)
    end,
    (select role from public.users where id = auth.uid())
  );
$$;

CREATE OR REPLACE FUNCTION public.is_accounting_manager()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.current_user_role() IN ('admin', 'accounting_manager');
$$;

CREATE OR REPLACE FUNCTION public.is_accountant()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.current_user_role() IN ('admin', 'manager', 'accounting', 'accounting_manager');
$$;
