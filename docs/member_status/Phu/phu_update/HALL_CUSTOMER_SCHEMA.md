# Hall + Customer Schema / RPC

## 1. Migration thêm mới

`supabase/migrations/20260702083325_hall_customer_rpc.sql`

Migration này là additive, không drop bảng/cột cũ.

## 2. Field/table mới

### `tablet_sessions`

Thêm:

- `order_id uuid references public.orders(id) on delete set null`
- `last_activity_at timestamptz not null default now()`

Mục đích:

- Gắn tablet session với order đang phục vụ khi customer gửi món.
- Theo dõi hoạt động cuối của session.

### `tablet_order_submissions`

Bảng idempotency guard:

- `id uuid primary key`
- `branch_id uuid`
- `table_id uuid`
- `session_id uuid`
- `idempotency_key text`
- `order_id uuid`
- `result jsonb`
- `created_at timestamptz`

Constraint:

- `UNIQUE (branch_id, table_id, idempotency_key)`

Mục đích:

- Chống double click/submit lại tạo duplicate order.

RLS:

- Enabled.
- Authenticated user chỉ xem/sửa theo branch hoặc admin.

## 3. Helper function

### `hall_customer_assert_branch_access(p_branch_id uuid)`

Kiểm tra:

- `p_branch_id` không null.
- User là admin hoặc `p_branch_id = current_branch_id()`.

Function dùng `SECURITY DEFINER` và `SET search_path = public, auth`.

## 4. Customer / Tablet RPC

### `customer_list_menu_categories(p_branch_id uuid default null)`

Trả menu categories active theo branch.

### `customer_list_menu_items(p_branch_id uuid default null, p_category_id uuid default null)`

Trả menu items active/available theo branch/category.

Không trả menu inactive/unavailable.

### `customer_get_tablet_content(p_branch_id uuid)`

Trả nội dung tablet active trong branch.

### `customer_activate_tablet_session(p_branch_id uuid, p_table_id uuid)`

Validate:

- branch access.
- table tồn tại, active.
- table status phải `occupied` hoặc `reserved`.

Tạo hoặc reuse active tablet session.

### `customer_set_tablet_language(p_session_id uuid, p_language text)`

Validate language nằm trong `vi`, `en`, `ja`.

### `customer_submit_table_order(...)`

Input:

- `p_branch_id`
- `p_table_id`
- `p_session_id`
- `p_items jsonb`
- `p_idempotency_key`

Validate:

- table đang `occupied`.
- tablet session active đúng table/branch.
- item array không rỗng.
- quantity > 0 và <= 99.
- menu item active/available.

Quan trọng:

- Không tin giá/tổng tiền frontend.
- Tự lấy `menu_items.price`.
- Tự insert `order_items`.
- Tự tính lại `orders.subtotal/total`.
- Dùng `tablet_order_submissions` để chống duplicate.

## 5. Hall RPC

### `hall_submit_table_order(...)`

Hall/reception gửi order thay khách.

Validate:

- branch access.
- role thuộc `admin`, `manager`, `reception`, `staff`.
- table đang `occupied`.
- menu item active/available.
- không tin giá/tổng tiền frontend.

### `hall_list_tables(p_branch_id uuid default null)`

Trả:

- table id/code/zone/status/capacity.
- active order của bàn nếu có.
- số service request đang mở.

### `get_floor_plan(p_branch_id uuid default null)`

RPC floor plan được replace để dùng đúng schema `tables.code`, trả theo zone/table.

### `hall_list_packages(p_branch_id uuid default null)`

Trả packages active theo branch.

### `hall_get_checkout_summary(p_branch_id uuid, p_table_id uuid default null, p_order_id uuid default null)`

Tính tạm tính từ DB:

- `subtotal` từ `order_items.line_total` không cancelled.
- `discount` từ `orders.discount`.
- `vat` từ `orders.vat_rate`.
- `grand_total = max(0, subtotal - discount) + vat`.

Không nhận grand total từ frontend.

### `hall_get_active_shift(p_branch_id uuid)`

Trả active shift đang `open` trong branch.

## 6. Service Request RPC

### `create_service_request(...)`

Type hợp lệ:

- `CALL_WAITER`
- `REQUEST_BILL`
- `REQUEST_CONDIMENT`
- `COMPLAINT`
- `OTHER`

Priority hợp lệ:

- `NORMAL`
- `URGENT`

Status mapping:

- `OPEN` = pending.
- `IN_PROGRESS` = acknowledged.
- `RESOLVED` = completed.

RPC dedupe request cùng table/type/order còn mở để tránh spam.

### `hall_list_service_requests(...)`

Hall đọc request theo status list.

### `hall_ack_service_request(p_request_id uuid)`

Chuyển request sang `IN_PROGRESS`.

### `hall_complete_service_request(p_request_id uuid)`

Chuyển request sang `RESOLVED`, set `resolved_by`, `resolved_at`.

## 7. Reservation RPC tối thiểu

### `hall_list_reservations_by_date(p_branch_id uuid, p_date date)`

Hall đọc reservation theo ngày/branch.

### `get_reservation_stats(p_date date)`

Tổng hợp reservation stats trong current branch.

### `hall_update_reservation_status(...)`

Update status tối thiểu:

- `Pending`
- `Arrived`
- `Dining`
- `Completed`
- `Cancelled`

Khi `Dining` và có `table_id`, table chuyển `occupied` nếu đang `available` hoặc `reserved`.

### `confirm_reservation(...)` / `seat_reservation(...)`

Wrapper cho UI cũ.

## 8. Security / RLS

- Tất cả function mới revoke public execute và grant authenticated.
- Function có `SECURITY DEFINER` đều set `search_path`.
- Function nhạy cảm dùng `hall_customer_assert_branch_access`.
- Không mở anonymous public RPC trong phase này.
- Tablet hiện dùng authenticated branch-bound context theo convention project.

## 9. Frontend direct write còn lại

Đã chuyển các flow chính Hall/Tablet sang RPC.

Còn lại ngoài scope:

- `useMenu.upsertItem` direct upsert `menu_items` cho admin menu maintenance.
- `ReceptionCloseShiftView` direct query `payments`/`shifts`, cần phase shift/accounting riêng.

## 10. Lý do không làm thêm schema lớn

Không thêm merge table/split bill/order audit schema trong phase này vì chưa đủ rule nghiệp vụ và dễ phá checkout/kitchen. Các phần này được ghi vào future TODO.
