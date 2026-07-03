-- =================================================================================
-- MIGRATION: Add missing roles to user_role enum
--
-- Thêm 2 giá trị vào enum public.user_role (do ban đầu thiếu):
--   * 'procurement' — TÊM TẠM THỜI, sẽ được đổi thành 'procurement_manager'
--     trong migration 20260701093424.
--   * 'customer'    — giữ nguyên tên cuối cùng.
--
-- Lưu ý Postgres:
--   ALTER TYPE ... ADD VALUE không thể sử dụng giá trị mới trong cùng
--   transaction; vì vậy các migration liên quan (đổi tên, UPDATE) phải nằm
--   trong file riêng chạy ở transaction kế tiếp.
-- =================================================================================

DO $$ BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'procurement';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'customer';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
