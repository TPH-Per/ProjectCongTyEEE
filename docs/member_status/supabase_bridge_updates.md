# Supabase Bridge Updates - Customer App

Tài liệu này ghi chú lại các cập nhật và xử lý lỗi ở phía Client (Customer App) khi tích hợp trực tiếp với Supabase Backend (Supabase Bridge) và các thay đổi schema chi tiết cần lưu ý.

## Thay đổi về Database Schema (Thực tế vs Thiết kế cũ)

Dựa trên quá trình map dữ liệu frontend với backend, schema hiện tại đã được chuẩn hóa chặt chẽ hơn:

### 1. Bảng Order (Đơn hàng)
- Bảng chi tiết đổi từ `order_items` thành `order_details`.
- Cột lưu giá trị tĩnh đổi từ `unit_price`, `name_snapshot`, `line_total` thành `unit_price_vnd_snapshot`, `item_name_snapshot`, `detail_total_vnd`.
- Khóa ngoại đổi tên: `id` thành `order_detail_id`, `menu_item_id` thành `branch_menu_item_id`.
- Trạng thái thay đổi từ `status` thành `kitchen_status`.

### 2. Bảng Thông tin (Branches, Areas, Tables)
Các bảng này áp dụng quy tắc đặt tên tiền tố chặt chẽ thay vì `id`, `name`, `code` chung chung:
- **branches**: Dùng `branch_id`, `branch_name`, `branch_code`.
- **areas**: Dùng `area_id`, `area_name`, `area_code`.
- **dining_tables**: Dùng `dining_table_id`, `table_code`, và đổi `status` thành `availability_status`.

### 3. Ràng buộc UUID
Tất cả Primary Key / Foreign Key phải tuân thủ chuẩn `UUID`. Truyền chuỗi dạng `B03` hay `branch_2` sẽ bị chặn (lỗi 400 Bad Request).

---

## Các API Functions đã được cập nhật

### 1. `createSession`
- **Tình trạng cũ**: Truyền `branchId` và `tableId` là mock strings dẫn đến lỗi `400 Bad Request` (`invalid input syntax for type uuid`).
- **Cập nhật**: Đã bổ sung cơ chế xác thực UUID (`/^[0-9a-f-]{36}$/i.test()`). Nếu không hợp lệ, fallback trả về local mock session ngay lập tức thay vì gọi RPC backend.

### 2. `selectTable`
- **Tình trạng cũ**: Truyền trực tiếp `tableId` dạng mock (`B03`) vào bảng `dining_tables` gây lỗi 400.
- **Cập nhật**: Thêm regex validate UUID cho `tableId`. Nếu không hợp lệ, hệ thống dùng mock data thay vì thực hiện RPC.

### 3. `getOrderHistory`
- **Cập nhật**: Viết lại câu query dùng `order_details` thay cho `order_items`. Sửa lại mapper `rowToOrder` để map các cột đúng chuẩn UI (sử dụng `item_name_snapshot`, `unit_price_vnd_snapshot`, tính lại total).

### 4. `getPackages`, `getAreas`
- **Cập nhật**: Thêm logic kiểm tra `branchId` bằng regex UUID để tự động fallback về mock template, tránh lỗi schema giả lập trên local.

## Cấu hình Môi trường
- Đổi `VITE_SUPABASE_URL` từ `127.0.0.1` sang `localhost` để khắc phục lỗi `net::ERR_CONNECTION_REFUSED` khi gọi Supabase Local Emulator trên Windows.
