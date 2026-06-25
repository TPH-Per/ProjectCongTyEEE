-- =============================================================================
-- 20260625130002_menu_items_add_is_active.sql
--
-- The original 20260623000000_setup.sql did not include `is_active` on
-- public.menu_items (it was only on menu_categories / packages / tables).
-- The Ishii 2026-06-24 §VI.1 menu spec + the ReceptionOrderView buffet
-- filter engine both expect an availability flag.
--
-- Adding it as a default-true nullable column (NOT NULL with default
-- avoids breaking existing rows). Idempotent: ADD COLUMN IF NOT EXISTS.
-- =============================================================================

ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.menu_items.is_active IS
  'Visibility flag. ReceptionOrderView filters by is_active = true to render the orderable grid.';
