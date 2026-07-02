-- =================================================================================
-- MIGRATION: User role enum — simplified model (no-op)
--
-- Ban đầu file này đổi tên admin→superadmin, accounting→accountant,
-- procurement→procurement_manager và thêm procurement_staff/crm_manager/marketing.
-- Cũng có UPDATE auth.users SET raw_user_meta_data (đã được xác định là security
-- smell vì custom-access-token hook đọc role từ raw_app_meta_data).
--
-- Theo quyết định của project owner ngày 2026-07-02, hệ thống chỉ giữ mô hình
-- role đơn giản (7 giá trị):
--   * admin, manager, reception, staff, kitchen   (từ setup.sql ban đầu)
--   * procurement, customer                       (từ migration 20260701000005)
--
-- File này vì vậy trở thành NO-OP. Timestamp được giữ để khớp với lịch sử
-- migration đã apply trên remote DB.
-- =================================================================================

SELECT 1;
