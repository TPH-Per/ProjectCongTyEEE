-- =============================================================================
-- 20260625220000_menu_subcategories_rls_grants_and_reload.sql
--
-- Closes three small gaps that surfaced after the Ishii menu sync:
--
--   (1) `menu_subcategories` was created by 20260625130000_menu_schema_align_ishii.sql
--       but never received RLS policies or grants. Without grants, PostgREST
--       returns 403 (PGRST301) for `authenticated` users even though RLS would
--       allow the row.
--
--   (2) `package_items` has SELECT/INSERT/UPDATE/DELETE grants for
--       `authenticated` in 20260625200100_explicit_table_grants.sql but those
--       grant clauses were NOT included (only `packages` was). Front-end code
--       that JOINs through package_items therefore hits "permission denied"
--       and the whole AdminMenusView page falls back to its error toast.
--
--   (3) Defensive ADD COLUMN IF NOT EXISTS for `package_items.is_active`. The
--       column is already defined in 20260623000000_setup.sql line 355, but
--       some PostgREST schema-cache reloads after long-uptime have been
--       observed to intermittently drop the column from `pg_attribute` cache
--       during in-place migrations. Re-asserting it here is idempotent and
--       cheap.
--
-- After applying, we issue `NOTIFY pgrst, 'reload schema'` so the PostgREST
-- container picks up the new RLS policies / columns without needing a manual
-- restart.
--
-- Idempotent — every statement is guarded by IF NOT EXISTS / IF EXISTS.
-- =============================================================================

-- 1. Defensive column re-assert for package_items.is_active
ALTER TABLE public.package_items
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS package_items_is_active_idx
  ON public.package_items (package_id) WHERE is_active = true;

COMMENT ON COLUMN public.package_items.is_active IS
  'Per-package-menu-item enable flag. Defined in 20260623000000_setup.sql; re-asserted here for PostgREST schema-cache resilience.';

-- 2. Enable RLS + add policies for menu_subcategories
ALTER TABLE public.menu_subcategories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "menu_subcategories_branch_read" ON public.menu_subcategories;
CREATE POLICY "menu_subcategories_branch_read" ON public.menu_subcategories
  FOR SELECT USING (branch_id = public.current_branch_id());

DROP POLICY IF EXISTS "menu_subcategories_branch_write" ON public.menu_subcategories;
CREATE POLICY "menu_subcategories_branch_write" ON public.menu_subcategories
  FOR ALL
    USING (branch_id = public.current_branch_id())
    WITH CHECK (branch_id = public.current_branch_id());

-- 3. Grants — auth + anon patterns from 20260625200100, now extended to
--    menu_subcategories + package_items.

-- anon (tablet / public menu preview)
GRANT SELECT ON public.menu_subcategories TO anon;
GRANT SELECT ON public.packages          TO anon;
GRANT SELECT ON public.package_items     TO anon;

-- authenticated (admin / manager / staff back-office)
GRANT SELECT ON public.menu_subcategories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.menu_subcategories TO authenticated;

GRANT SELECT ON public.package_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.package_items TO authenticated;

-- service_role already has full access via the "all tables in schema public"
-- grant in 20260625200100_explicit_table_grants.sql — no change needed.

-- 4. Reload PostgREST schema so it picks up the new policies / columns.
--    Supabase PostgREST listens on channel 'pgrst' for this NOTIFY; sending
--    'reload schema' triggers an immediate reload (no need to restart).
NOTIFY pgrst, 'reload schema';