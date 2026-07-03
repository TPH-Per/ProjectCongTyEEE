-- =================================================================================
-- MIGRATION: Revert user_role enum to simplified 8-role model
--
-- Bối cảnh
-- --------
-- Migration 20260701093424 (đã apply trên remote trước đó) đã:
--   * RENAME admin       → superadmin
--   * RENAME accounting  → accountant
--   * RENAME procurement → procurement_manager
--   * ADD VALUE: procurement_staff, crm_manager, marketing
--
-- Theo quyết định project owner ngày 2026-07-02, hệ thống chỉ giữ 8 role:
--   admin, manager, reception, staff, kitchen, procurement, customer, accounting
--
-- Hành động
-- ---------
-- 1. Đổi tên ngược 3 value đã rename về tên gốc.
-- 2. "Drop" 3 value thừa bằng cách RENAME thành _unused_* (Postgres không có
--    native DROP VALUE cho enum). Việc rename đảm bảo enum ordinal ổn định
--    (các cast hiện hữu không bị invalid) và không policy/RPC nào reference
--    các value _unused_ này.
-- 3. NOTIFY PostgREST reload schema để supabase-js nhận enum mới ngay.
--
-- ⚠️ CAVEATS — cần biết khi apply
-- ------------------------------
-- 1. Migration này idempotent (dùng DO block check pg_enum trước khi
--    rename). Trên local DB (đã được đồng bộ simple model) các block DO
--    sẽ no-op. Trên remote (đang ở model cũ) sẽ revert về simple model.
-- 2. Nếu có user có role = superadmin/accountant/procurement_manager
--    trong auth.users.raw_app_meta_data, sau migration này custom-access-
--    token hook sẽ fail khi user đó đăng nhập (cast enum không tìm thấy
--    value). Hiện project chỉ dùng 1 admin nên impact thấp; nếu muốn
--    sync hàng loạt xem docs/SUPABASE_AUTH_TODO.md.
-- 3. Không UPDATE auth.users ở đây để tránh security smell cũ
--    (ghi raw_user_meta_data) — JWT hook đọc từ raw_app_meta_data nên
--    cần migration riêng.
-- =================================================================================

-- 1. Revert renames (idempotent: chỉ rename nếu value cũ tồn tại)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'superadmin'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'superadmin' TO 'admin';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'accountant'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'accountant' TO 'accounting';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'procurement_manager'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'procurement_manager' TO 'procurement';
  END IF;
END $$;

-- 2. "Drop" 3 role thừa bằng rename _unused_* (Postgres không DROP VALUE native)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'procurement_staff'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'procurement_staff' TO '_unused_procurement_staff';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'crm_manager'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'crm_manager' TO '_unused_crm_manager';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'user_role'
      AND n.nspname = 'public'
      AND e.enumlabel = 'marketing'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'marketing' TO '_unused_marketing';
  END IF;
END $$;

-- 3. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
