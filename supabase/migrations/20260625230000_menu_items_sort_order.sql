-- =============================================================================
-- 20260625230000_menu_items_sort_order.sql
--
-- The original 20260623000000_setup.sql defines `sort_order` on
-- `menu_categories` and `package_items` but NOT on `menu_items`. Ishii's
-- menu data file (`docs/member_status/Ishii/thực đơn.txt`) and the
-- ReceptionOrderView POS both expect items to have a stable display order
-- within their category / subcategory.
--
-- This migration adds `menu_items.sort_order` as a default-zero, indexed
-- integer. Idempotent — uses ADD COLUMN IF NOT EXISTS and CREATE INDEX IF
-- NOT EXISTS.
--
-- After the column exists, AdminMenusView can ORDER BY sort_order, and
-- future drag-to-reorder UI on the back-office can write to it.
-- =============================================================================

ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_menu_items_branch_cat_sort
  ON public.menu_items (branch_id, category_id, subcategory_id, sort_order)
  WHERE is_available = true;

COMMENT ON COLUMN public.menu_items.sort_order IS
  'Display order within category (or subcategory if set). Lower = earlier. Defaults to 0 (insertion order). Added in 20260625230000_menu_items_sort_order.sql.';

-- Trigger: keep the updated_at column fresh on any UPDATE (in case the
-- column is later moved to a dedicated column). The set_updated_at
-- function is created by 20260623000000_setup.sql.
DROP TRIGGER IF EXISTS trg_menu_items_set_updated_at ON public.menu_items;
CREATE TRIGGER trg_menu_items_set_updated_at
  BEFORE UPDATE ON public.menu_items
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Reload PostgREST schema cache so the new column becomes visible to
-- supabase-js without a manual restart.
NOTIFY pgrst, 'reload schema';