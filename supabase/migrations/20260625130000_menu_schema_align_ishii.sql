-- =============================================================================
-- 20260625130000_menu_schema_align_ishii.sql
--
-- Align the menu schema with the structure described in
-- docs/member_status/Ishii/2026-06-24.md § VI.1 (Full Menu Data Sync) and
-- the data in `thực đơn.txt` — a 2-level hierarchy (category → subcategory
-- → item) with `color`, `unit`, and `price_display` fields.
--
-- What we had before this migration:
--   - menu_categories: id, branch_id, name, sort_order, is_active, metadata
--   - menu_items:     id, branch_id, category_id, name, description, price,
--                     cost, image_url, tags, nutrition, metadata
--   - NO menu_subcategories table
--   - NO color on categories, NO unit / price_display on items
--
-- What we add (all idempotent):
--   1. menu_categories.color   text  (yellow / pink per Ishii spec)
--   2. menu_items.unit          text  (Vé / Phần / Ly / Lon / BỊCH / ...)
--   3. menu_items.price_display text  (1.380K / 250K / ...)
--   4. menu_subcategories       new table (2-level hierarchy)
--   5. menu_items.subcategory_id fk   (item can be under subcategory, nullable)
--
-- Migration is fully reversible:
--   DROP TABLE IF EXISTS public.menu_subcategories;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS subcategory_id;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS price_display;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS unit;
--   ALTER TABLE public.menu_categories DROP COLUMN IF EXISTS color;
-- =============================================================================

-- 1. menu_categories.color
ALTER TABLE public.menu_categories
  ADD COLUMN IF NOT EXISTS color text;

COMMENT ON COLUMN public.menu_categories.color IS
  'UI badge color for the category. Used by POS to render the yellow/pink row grouping per Ishii 2026-06-24 §VI.1.';

-- 2. menu_items.unit
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS unit text;

COMMENT ON COLUMN public.menu_items.unit IS
  'Display unit for the item (Vé / Phần / Ly / Lon / BỊCH / cái / hộp / đôi / chai / lọ / gram).';

-- 3. menu_items.price_display
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS price_display text;

COMMENT ON COLUMN public.menu_items.price_display IS
  'Pre-formatted price string for UI (e.g. "1.380K", "250K", "50K/100g"). NOT used for math — see price column.';

-- 4. menu_subcategories table
CREATE TABLE IF NOT EXISTS public.menu_subcategories (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid        NOT NULL REFERENCES public.menu_categories(id) ON DELETE CASCADE,
  branch_id   uuid        REFERENCES public.branches(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  sort_order  integer     NOT NULL DEFAULT 0,
  is_active   boolean     NOT NULL DEFAULT true,
  metadata    jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menu_subcategories_category
  ON public.menu_subcategories (category_id, sort_order)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_menu_subcategories_branch
  ON public.menu_subcategories (branch_id)
  WHERE is_active = true;

COMMENT ON TABLE public.menu_subcategories IS
  'Sub-categories inside a category. Used by ReceptionOrderView buffet discount engine and AdminFloorsView zone grouping. Per Ishii 2026-06-24 §VI.1.';

-- 5. menu_items.subcategory_id
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS subcategory_id uuid
    REFERENCES public.menu_subcategories(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_menu_items_subcategory
  ON public.menu_items (subcategory_id)
  WHERE subcategory_id IS NOT NULL;

COMMENT ON COLUMN public.menu_items.subcategory_id IS
  'Optional subcategory. NULL means the item is directly under its category (no subcategory).';

-- 6. updated_at trigger for menu_subcategories
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS trg_menu_subcategories_updated_at ON public.menu_subcategories;
CREATE TRIGGER trg_menu_subcategories_updated_at
  BEFORE UPDATE ON public.menu_subcategories
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_set_updated_at();
