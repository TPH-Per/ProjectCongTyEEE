# Hall + Customer Flow

## 1. Customer xem menu

1. Tablet có `branch_id`, `table_id` và active tablet session.
2. UI `/tablet/order` gọi:
   - `customer_list_menu_categories`
   - `customer_list_menu_items`
3. Backend chỉ trả menu item active/available trong branch hợp lệ.
4. Menu item trả kèm `price`, `description`, `modifiers`, `tags`, `nutrition`, `ingredients`.

Hiện tại UI hiển thị menu cơ bản. Thành phần/dị ứng đã có dữ liệu trong RPC nhưng chưa có màn chi tiết riêng.

## 2. Customer chọn món và cart

1. Khách tăng/giảm số lượng món trên tablet.
2. Cart trong frontend chỉ giữ `menu_item_id` và `quantity`.
3. Frontend không gửi tổng tiền làm nguồn sự thật.
4. Khi gửi order, RPC đọc lại giá từ `menu_items` trong DB.

Rule hiện tại:

- Quantity phải > 0 và <= 99.
- Menu item phải active/available.
- Note/modifiers gửi dạng tối thiểu nếu UI có.

## 3. Customer xác nhận order

1. Customer bấm send to kitchen.
2. UI gọi `customer_submit_table_order`.
3. RPC validate:
   - branch access
   - table tồn tại và đang `occupied`
   - tablet session active, đúng table/branch
   - item hợp lệ
4. RPC tìm active order của bàn hoặc tạo order mới.
5. RPC insert `order_items`, tính `line_total`, tính lại `orders.subtotal/total`.
6. RPC lưu `tablet_sessions.order_id`.
7. `tablet_order_submissions` chống double click bằng `idempotency_key`.

Expected:

- Không duplicate order nếu submit lại cùng key.
- Không tin giá/tổng tiền từ frontend.
- Customer không ghi bill/payment.

## 4. Customer gọi phục vụ

1. Customer bấm hỗ trợ.
2. UI gọi `create_service_request` với type `CALL_WAITER`.
3. RPC validate branch/table/session nếu có.
4. RPC tạo request `OPEN`.
5. Nếu cùng table/type/order đang `OPEN` hoặc `IN_PROGRESS`, RPC trả request cũ với `deduped = true`.
6. Hall đọc bằng `hall_list_service_requests`.

Mapping status:

- `OPEN` = pending.
- `IN_PROGRESS` = acknowledged.
- `RESOLVED` = completed.

## 5. Customer yêu cầu tính tiền

1. Customer bấm request payment.
2. UI gọi `create_service_request` với type `REQUEST_BILL`, priority `URGENT`.
3. RPC tạo service request `OPEN`.
4. Nếu có tablet session, RPC chuyển session sang `CHECKOUT_REQUESTED`.
5. Reception dashboard thấy request và Hall mở checkout.

Customer không được tự tạo bill chính thức.

## 6. Hall xem sơ đồ bàn

1. Hall UI gọi `hall_list_tables` hoặc `get_floor_plan`.
2. RPC trả table status, zone, active order, số request đang mở.
3. Table status vẫn dựa vào schema hiện tại: `available`, `occupied`, `reserved`, `cleaning`.
4. Không nhập text tự do để đổi trạng thái trong flow đã chỉnh.

## 7. Hall nhận và xử lý service request

1. Dashboard/service queue gọi `hall_list_service_requests`.
2. Hall bấm nhận xử lý -> `hall_ack_service_request`.
3. Hall xử lý xong -> `hall_complete_service_request`.
4. Request được chuyển:
   - `OPEN` -> `IN_PROGRESS` -> `RESOLVED`

## 8. Hall gọi món/phục vụ

1. Reception order view build cart/menu hiện có.
2. Khi gửi xuống hệ thống, UI gọi `hall_submit_table_order`.
3. RPC validate staff/reception/manager/admin role.
4. RPC tự đọc giá DB và insert order items.
5. Không dùng Edge Function/direct insert order item trong flow này nữa.

## 9. Hall sửa order

Chưa implement trong phase này.

Lý do: sửa/hủy món ảnh hưởng Kitchen và bill. Cần rule rõ:

- Món chưa xử lý có thể sửa.
- Món đã làm/xong/phục vụ không sửa trực tiếp.
- Cần cancel reason/audit.

Đưa vào future TODO.

## 10. Ghép bàn

Chưa implement.

Yêu cầu tương lai: ghép bàn phải đi theo session/order model, không đổi `table_id` thô làm mất lịch sử.

## 11. Tách bill

Chưa implement.

Yêu cầu tương lai: tách bill theo item/quantity/share, không nhập tay tổng tiền.

## 12. Checkout Hall -> Accounting

1. Reception checkout gọi `hall_get_checkout_summary`.
2. RPC tìm active order theo table/order, trả items và summary.
3. Summary được tính từ `order_items.line_total`, `orders.discount`, `orders.vat_rate`.
4. Khi thanh toán, UI gọi `process_checkout` hiện có qua `useCheckout`.
5. Checkout không phụ thuộc CRM survey.
6. CRM survey link bill đã được xử lý riêng trong CRM phase trước.

Điểm chưa đụng sâu:

- Accounting ledger chuyên sâu.
- Voucher engine/discount permission nâng cao.
- Refund/void.
