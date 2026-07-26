# Supabase Bridge Updates - Customer App

Tài liệu này ghi chú lại các cập nhật và xử lý lỗi ở phía Client (Customer App) khi tích hợp trực tiếp với Supabase Backend (Supabase Bridge).

## Các API Functions đã được cập nhật

### 1. `createSession`
- **Tình trạng cũ**: Truyền `branchId` và `tableId` là mock strings (ví dụ `branch_2`, `B03`), dẫn đến lỗi `400 Bad Request` (`invalid input syntax for type uuid`) từ Supabase RPC.
- **Cập nhật**: Đã bổ sung cơ chế xác thực UUID (`/^[0-9a-f-]{36}$/i.test()`) cho `branchId` và `tableId`. Nếu không phải UUID hợp lệ, hàm sẽ chặn request tới backend và fallback trả về local mock session ngay lập tức.

### 2. `selectTable`
- **Tình trạng cũ**: Truyền trực tiếp `tableId` dạng mock (`B03`) vào bảng `dining_tables` trên Supabase, gây lỗi `400 Bad Request`.
- **Cập nhật**: Tương tự như `createSession`, đã thêm regex validate UUID cho `tableId`. Nếu không hợp lệ, hệ thống dùng mock data thay vì thực hiện RPC.

### 3. `getOrderHistory`
- **Tình trạng cũ**: Truy vấn bị lỗi do schema Supabase dùng bảng `order_details` thay vì `order_items` và các tên cột bị lệch (ví dụ `unit_price` thành `unit_price_vnd_snapshot`, `name_snapshot` thành `item_name_snapshot`).
- **Cập nhật**:
  - Viết lại câu query Supabase: `.select('order_id, ..., order_details(order_detail_id, branch_menu_item_id, item_name_snapshot, unit_price_vnd_snapshot, quantity, detail_total_vnd, kitchen_status, note)')`.
  - Cập nhật mapper `rowToOrder` để map các cột trả về sang định dạng UI yêu cầu, tính toán lại đúng giá `subtotal` và `total`.

### 4. Các API lấy danh mục (getPackages, getAreas)
- **Tình trạng cũ**: Lỗi 400 vì cố truyền mock `branchId` vào truy vấn database.
- **Cập nhật**: Đã thêm logic kiểm tra `branchId` bằng regex UUID. Tự động fallback về mock template khi chạy trên local không có schema thật cho chi nhánh giả lập.

## Cấu hình Môi trường (.env)
- Đổi `VITE_SUPABASE_URL` từ `127.0.0.1` sang `localhost` để khắc phục lỗi `net::ERR_CONNECTION_REFUSED` khi gọi Supabase Local Emulator trên Docker Desktop của Windows.
