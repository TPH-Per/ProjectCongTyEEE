# Tài Liệu Đánh Giá Kiến Trúc Database (Supabase / PostgreSQL)
**Dự án:** NguuCat POS & Management System

Tài liệu này cung cấp cái nhìn tổng quan về kiến trúc dữ liệu, mô hình phân quyền bảo mật (RLS) và các chiến lược xử lý đồng thời (Concurrency) để chuyên gia hệ thống (System/Database Architect) đánh giá.

---

## 1. Mô hình bảo mật và phân quyền (Authentication & Authorization)
Hệ thống sử dụng cơ chế **Custom JWT Hook** kết hợp **Row Level Security (RLS)** của PostgreSQL để đảm bảo an toàn dữ liệu trên môi trường Cloud (Supabase).

* **7 Roles nghiệp vụ:** `admin`, `manager`, `cashier`, `kitchen`, `waitstaff`, `accounting`, `procurement`.
* **Cơ chế hoạt động:** 
  - Thay vì join bảng Users liên tục, hệ thống hook vào chu kỳ tạo JWT token của Supabase Auth để nhúng mảng `app_metadata.user_roles` và `app_metadata.branch_id`.
  - Các hàm tiện ích: `public.has_role()` và `public.current_branch_id()` đọc trực tiếp từ JWT.
* **RLS Policies:** Tất cả các bảng nghiệp vụ (orders, bills, inventory...) đều bật RLS. 
  - Policy cơ bản: `branch_id = public.current_branch_id() OR public.has_role(ARRAY['admin']::user_role[])`.
  - Quyền Admin tự do xuyên suốt (Tenant-bypass) để xem báo cáo chuỗi.

---

## 2. Luồng nghiệp vụ cốt lõi (Core Business Flows)

### A. Quy trình Bán hàng & Thanh toán (Sales & Checkout)
Hệ thống tuân thủ nghiêm ngặt nguyên tắc **1 Source of Truth** về tài chính:
* **`orders`:** Quản lý món đang phục vụ tại bàn (có khoá advisory lock chống race-condition 2 nhân viên cùng mở 1 bàn).
* **`bills`:** Khi thu ngân chốt đơn (checkout), order được chuyển thành Bill. Bill chứa tổng tiền (`subtotal`, `grand_total`).
* **`invoices`:** Hoá đơn thuế/tài chính. Hệ thống đảm bảo 1 Bill chỉ có **duy nhất 1 Invoice hợp lệ** thông qua Partial Unique Index (`idx_one_valid_invoice_per_bill`).
* **`payments`:** Ghi nhận các khoản thanh toán thực tế (Cash, Card, Transfer), được map chặt với `invoice_id`.

### B. Quản lý Kho & Mua hàng (Procurement & Inventory)
Thiết kế tập trung (Unified Inventory) thay vì tách rời:
* **`suppliers`:** Danh mục nhà cung cấp.
* **`ingredients`:** Từ điển nguyên vật liệu chung toàn hệ thống (không gán branch).
* **`inventory_stock`:** Số lượng tồn kho thực tế của từng nguyên liệu, gắn với `branch_id`.
* **`inventory_transactions`:** Sổ cái theo dõi xuất/nhập/kiểm kê.

### C. Menu & Quản lý món ăn
* Cấu trúc phân cấp: `menu_categories` -> `menu_subcategories` -> `menu_items`.
* **Performance Opt:** Cột `ingredients` trên `menu_items` được thiết kế dạng **JSONB** để hiển thị UI trên App khách hàng (Tablet) mà không cần join bảng, giúp tối ưu hiệu năng đọc.

### D. CRM & Khảo sát khách hàng
* **`customer_visit_notes`:** Bảng thu thập feedback định tính trực tiếp từ tablet tại bàn (Ghi nhận nguồn khách, dịp ăn uống, mức độ hài lòng, note cải thiện).

---

## 3. Các điểm kỹ thuật tối ưu & chống lỗi (Hardening)
Hệ thống đã trải qua quá trình audit và hardening nghiêm ngặt:

1. **Chống N+1 Query (Performance):** 
   - Thay vì client phải gọi hàng chục query để lấy danh sách bàn, zone, và order hiện tại. Hệ thống sử dụng RPC `get_floor_plan` và `get_bill_details` trả thẳng về cấu trúc phân cấp **JSONB**.
2. **Chống Race-Condition (Concurrency):** 
   - Sử dụng Transaction Lock (`pg_advisory_xact_lock`) khi submit order từ Tablet khách hàng để tránh duplicate order.
   - Partial Unique Indexes (VD: `CREATE UNIQUE INDEX one_open_kitchen_shift_per_user ON kitchen_shifts (user_id) WHERE status = 'OPEN'`).
3. **Bảo mật RPC (SECURITY DEFINER):**
   - Tất cả các Function (RPC) liên quan đến ghi nhận doanh thu hoặc tồn kho đều dùng `SECURITY DEFINER` và `SET search_path = public, auth`.
   - Có cơ chế check cứng: `IF p_branch_id IS DISTINCT FROM public.current_branch_id() AND NOT admin THEN RAISE EXCEPTION`.
   - Mặc định `REVOKE EXECUTE ON FUNCTION FROM public`, chỉ cấp quyền cho `authenticated`.

---

## 4. Tệp SQL đính kèm để chuyên gia xem
Toàn bộ mã nguồn SQL bao gồm cả Schema Base, Triggers, RLS và các Functions đã được gộp lại thành một file duy nhất:
👉 **`full_schema_for_expert_review.sql`** (Nằm trong thư mục root của project `noMoreF2TECH`).

Chuyên gia có thể mở file này để đọc code DDL và PL/pgSQL từ trên xuống dưới một cách mạch lạc.
