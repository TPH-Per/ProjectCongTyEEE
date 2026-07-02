# Hall + Customer Updated Plan

## 1. Mục tiêu phase

Phase này chuẩn hóa phần Customer Tablet và Hall/Reception theo hướng Strict RPC API:

- Customer tablet chỉ xem menu, chọn món, gửi order, gọi phục vụ, yêu cầu tính tiền.
- Hall xem bàn, nhận yêu cầu từ tablet, gửi order thay khách khi cần, xem tạm tính và checkout.
- Checkout vẫn là boundary Hall -> Accounting, không đưa logic Accounting sâu vào phase này.
- Không trộn CRM survey vào Hall phase. CRM vẫn là module riêng.

## 2. Discovery hiện tại

Codebase hiện dùng Vue 3, Composition API, Tailwind, Supabase client và PostgreSQL migrations trong `supabase/migrations`.

Các phần liên quan đã đọc/kiểm tra:

- Tablet/customer views: `src/views/tablet/*`, `src/views/customer/*`.
- Hall/reception views: `src/views/hall/*`, `src/views/reception/*`, `src/views/staff/*`.
- Composables: `useTablet`, `useMenu`, `useTable`, `useReservation`, `useServiceRequest`, `useCheckout`.
- Database/RPC: migrations trong `supabase/migrations`, đặc biệt các function `submit_tablet_order`, `process_checkout`, `get_floor_plan`, reservation/voucher/CRM functions.
- Docs hiện có trong `phu_updated`.

Kết quả discovery:

- `/tablet` là flow tablet gần DB thật nhất, nhưng trước đó còn gọi direct query/Edge Function ở một số điểm.
- `/customer` là flow mock/in-memory cũ, còn lỗi type/build riêng và chưa được đưa vào scope sửa chính.
- Hall/Reception đang trộn RPC, Edge Function và direct query.
- Checkout đã có `process_checkout`, phase này không rewrite function checkout chính, chỉ thêm RPC tạm tính để frontend không tự ghép nhiều bảng.
- Service request đã có bảng `service_requests`, nhưng thiếu RPC chuẩn để customer tạo và Hall xử lý.
- Floor plan RPC cũ có điểm lệch schema (`table_number` trong khi bảng dùng `code`), đã được thay bằng function tương thích hơn.

## 3. Quyết định thiết kế

- Tạo migration mới `20260702083325_hall_customer_rpc.sql` để gom các RPC Hall/Customer baseline.
- Không tạo hệ thống merge table, split bill, voucher engine, kitchen workflow mới vì chưa đủ nền và nằm ngoài scope tối thiểu.
- Không tin giá/tổng tiền từ frontend. Order RPC đọc `menu_items.price` trong DB và tự tính `line_total`, `subtotal`.
- Dùng `tablet_order_submissions` làm idempotency guard chống double click tạo duplicate order.
- Dùng status hiện có của `service_requests`: `OPEN` = pending, `IN_PROGRESS` = acknowledged, `RESOLVED` = completed.
- Tablet hiện theo mô hình project hiện tại là authenticated branch-bound tablet/staff context, chưa mở anonymous public tablet.

## 4. Những gì đã sửa

- Thêm RPC đọc menu cho tablet: `customer_list_menu_categories`, `customer_list_menu_items`.
- Thêm RPC nội dung tablet/session: `customer_get_tablet_content`, `customer_activate_tablet_session`, `customer_set_tablet_language`.
- Thêm RPC gửi order: `customer_submit_table_order`, `hall_submit_table_order`.
- Thêm RPC service request: `create_service_request`, `hall_list_service_requests`, `hall_ack_service_request`, `hall_complete_service_request`.
- Thêm RPC Hall table/floor/checkout: `hall_list_tables`, `hall_list_packages`, `get_floor_plan`, `hall_get_checkout_summary`, `hall_get_active_shift`.
- Thêm RPC reservation tối thiểu cho Hall: `hall_list_reservations_by_date`, `get_reservation_stats`, `hall_update_reservation_status`, `confirm_reservation`, `seat_reservation`.
- Chuyển các flow chính của tablet/Hall sang gọi RPC thay vì direct table query/Edge Function cũ.
- Reception dashboard hiển thị thêm service request từ tablet, gồm yêu cầu tính tiền.
- Checkout view đọc bill tạm tính qua `hall_get_checkout_summary`, sau đó vẫn gọi `process_checkout`.

## 5. Những gì chưa sửa

- `/customer` mock flow cũ chưa được chuẩn hóa vì không phải flow tablet DB chính.
- Admin menu upsert vẫn còn direct query trong `useMenu.upsertItem`; đây là maintenance/admin CRUD, chưa thuộc Hall/Tablet sensitive flow phase này.
- Reception close shift vẫn còn direct query `payments`/`shifts`; đây là shift/accounting boundary, cần phase riêng.
- Sửa/hủy order item nâng cao chưa implement vì cần rule kitchen/bill/audit rõ hơn.
- Ghép bàn và tách bill chưa implement để tránh làm nửa vời gây lẫn order/session.
- Voucher/discount chỉ giữ flow hiện tại; chưa xây rule engine hoặc permission matrix mới.
- Ingredients/allergy data đã được expose qua menu RPC nhưng UI tablet chưa có màn chi tiết thành phần/dị ứng hoàn chỉnh.

## 6. Rủi ro còn lại

- Build toàn project hiện fail do lỗi cũ ngoài scope: duplicate locale keys, thiếu methods ở Accounting/BOD/Purchasing composables, lỗi mock `/customer`, lỗi `src/views/hall/CheckoutView.vue`.
- Chưa chạy được E2E browser do build chưa sạch toàn repo.
- Tablet public/anonymous access chưa được thiết kế; hiện dùng authenticated Supabase session theo convention hiện tại.
- `process_checkout` vẫn là function checkout chính; phase này không thay đổi sâu Accounting handoff.

## 7. Future TODO

- Tách phase sửa build nền của repo trước khi E2E.
- Chuẩn hóa `/customer` mock hoặc quyết định bỏ/ẩn nếu `/tablet` là flow chính.
- Viết RPC riêng cho close shift/payment summary.
- Thiết kế order modification với status lock, cancel reason, audit trail.
- Thiết kế merge table dựa trên session/order model, không đổi `table_id` thô.
- Thiết kế split bill theo item/quantity/share.
- Hoàn thiện UI chi tiết ingredients/allergy cho tablet.
- Rà soát voucher/discount permission và Accounting posting trong phase Checkout/Accounting.
