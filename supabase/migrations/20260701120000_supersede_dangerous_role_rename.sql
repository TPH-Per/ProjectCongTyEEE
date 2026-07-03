-- =================================================================================
-- MIGRATION: Supersede dangerous role rename from 20260701093424_rename_user_roles.sql
--
-- Lý do:
--   origin/main có migration `20260701093424_rename_user_roles.sql` chạy TRƯỚC
--   (alphabetical sort: 'rename_user_roles' < 'rename_user_role_values') và thực
--   hiện các thay đổi KHÔNG MONG MUỐN:
--     1. RENAME 'admin'           -> 'superadmin'
--     2. RENAME 'accounting'      -> 'accountant'
--     3. RENAME 'procurement'     -> 'procurement_manager'
--     4. ADD VALUE 'procurement_staff', 'crm_manager', 'marketing'
--     5. UPDATE auth.users.raw_user_meta_data (SECURITY SMELL — custom-access-token
--        hook đọc role từ raw_app_meta_data, KHÔNG phải raw_user_meta_data)
--
--   Theo quyết định của project owner ngày 2026-07-02, hệ thống chỉ giữ 8 role:
--     admin, manager, reception, staff, kitchen, purchasing, accounting, customer
--   (Xem: docs/member_status/Phu/phu_update/PROJECT_RISK_REGISTER_20260702.md)
--
-- Migration này chạy SAU (timestamp 20260701120000) để revert lại các rename xấu,
-- trả enum về đúng 8-role model. Các value 'procurement_staff', 'crm_manager',
-- 'marketing' được GIỮ trong enum (PostgreSQL không hỗ trợ DROP VALUE trực tiếp)
-- nhưng KHÔNG ĐƯỢC SỬ DỤNG ở bất kỳ RPC/RLS/policy nào.
--
-- Idempotency: tất cả RENAME đều wrap trong DO block kiểm tra pg_enum trước khi
-- rename, nên migration này an toàn chạy nhiều lần hoặc chạy khi state đã đúng.
-- =================================================================================

DO $$
DECLARE
  has_superadmin          boolean;
  has_accountant          boolean;
  has_procurement_manager boolean;
  has_admin               boolean;
  has_accounting          boolean;
  has_procurement         boolean;
BEGIN
  -- Kiểm tra giá trị hiện có trong enum
  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'superadmin')
    INTO has_superadmin;

  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'accountant')
    INTO has_accountant;

  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'procurement_manager')
    INTO has_procurement_manager;

  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'admin')
    INTO has_admin;

  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'accounting')
    INTO has_accounting;

  SELECT EXISTS (SELECT 1 FROM pg_enum e
                 JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'user_role' AND e.enumlabel = 'procurement')
    INTO has_procurement;

  -- Revert 1: superadmin -> admin (chỉ khi superadmin tồn tại và admin chưa có)
  IF has_superadmin AND NOT has_admin THEN
    ALTER TYPE public.user_role RENAME VALUE 'superadmin' TO 'admin';
    RAISE NOTICE '[supersede] Renamed superadmin -> admin';
  END IF;

  -- Revert 2: accountant -> accounting (chỉ khi accountant tồn tại và accounting chưa có)
  IF has_accountant AND NOT has_accounting THEN
    ALTER TYPE public.user_role RENAME VALUE 'accountant' TO 'accounting';
    RAISE NOTICE '[supersede] Renamed accountant -> accounting';
  END IF;

  -- Revert 3: procurement_manager -> procurement (chỉ khi procurement_manager tồn tại và procurement chưa có)
  IF has_procurement_manager AND NOT has_procurement THEN
    ALTER TYPE public.user_role RENAME VALUE 'procurement_manager' TO 'procurement';
    RAISE NOTICE '[supersede] Renamed procurement_manager -> procurement';
  END IF;
END
$$;

-- Cập nhật auth.users.raw_app_meta_data (KHÔNG phải raw_user_meta_data) nếu
-- migration xấu trước đó đã làm hỏng. Dùng raw_app_meta_data đúng theo rule
-- custom-access-token hook đọc từ đây.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'raw_app_meta_data'
  ) THEN
    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
      COALESCE(raw_app_meta_data, '{}'::jsonb),
      '{role}',
      '"admin"'
    )
    WHERE raw_app_meta_data->>'role' = 'superadmin';

    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
      COALESCE(raw_app_meta_data, '{}'::jsonb),
      '{role}',
      '"accounting"'
    )
    WHERE raw_app_meta_data->>'role' = 'accountant';

    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
      COALESCE(raw_app_meta_data, '{}'::jsonb),
      '{role}',
      '"procurement"'
    )
    WHERE raw_app_meta_data->>'role' = 'procurement_manager';
  END IF;
END
$$;