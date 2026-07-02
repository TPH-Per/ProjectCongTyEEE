# Hall + Customer Task Status

| Phân hệ (モジュール) | Chức năng (機能) | Trạng thái (ステータス) | Ghi chú (備考) |
| --- | --- | --- | --- |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xem menu điện tử đa ngôn ngữ<br>(多言語メニュー表示) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã bọc RPC `customer_list_menu_categories`, `customer_list_menu_items`; UI tablet dùng RPC. Cần E2E sau khi build nền sạch. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xem thông tin thành phần/dị ứng<br>(成分・アレルギー情報表示) | ⏳ Chờ xử lý<br>(未対応) | RPC đã trả `ingredients`, `nutrition`, `tags`, nhưng UI chưa có màn chi tiết thành phần/dị ứng rõ ràng. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Chọn món, tùy chỉnh, thêm vào giỏ<br>(商品選択・カスタマイズ・カート追加) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Cart cơ bản theo quantity đã có. Modifier/note nâng cao chưa mở rộng. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xác nhận order gửi xuống hệ thống<br>(注文確定・送信) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã bọc RPC `customer_submit_table_order`; backend tự lấy giá từ DB và chống double submit bằng idempotency. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Gọi phục vụ / yêu cầu tính tiền<br>(スタッフ呼出・会計依頼) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã bọc RPC `create_service_request`; `REQUEST_BILL` chỉ tạo request cho Hall, không checkout trực tiếp. |
| Tiền sảnh / Hall<br>(ホール) | Quản lý sơ đồ bàn<br>(テーブル管理) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã có `hall_list_tables`, `get_floor_plan`; UI Hall/staff dùng table RPC. |
| Tiền sảnh / Hall<br>(ホール) | Quản lý đặt chỗ / khách đến<br>(予約・来店管理) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã thêm RPC list/stats/status tối thiểu. Chưa redesign reservation/check-in nâng cao. |
| Tiền sảnh / Hall<br>(ホール) | Nhận thông báo từ tablet<br>(タブレット通知受信) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Dashboard/service queue đọc `hall_list_service_requests`; realtime hiện vẫn dựa vào bảng `service_requests`. |
| Tiền sảnh / Hall<br>(ホール) | Xử lý yêu cầu phục vụ<br>(接客リクエスト処理) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Đã có `hall_ack_service_request`, `hall_complete_service_request`; status mapping OPEN/IN_PROGRESS/RESOLVED. |
| Tiền sảnh / Hall<br>(ホール) | Theo dõi order của bàn<br>(テーブル注文管理) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | `hall_list_tables` trả active order; checkout summary đọc active order/items qua RPC. |
| Tiền sảnh / Hall<br>(ホール) | Sửa / hủy / thêm order item<br>(注文修正・取消・追加) | ⏳ Chờ xử lý<br>(未対応) | Chưa implement vì cần rule kitchen/bill/audit. Tránh sửa trực tiếp gây sai bill. |
| Tiền sảnh / Hall<br>(ホール) | Ghép bàn<br>(テーブル結合) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Chưa đủ session/order model cho merge an toàn. Không làm nửa vời bằng cách đổi `table_id`. |
| Tiền sảnh / Hall<br>(ホール) | Tách bill<br>(会計分割) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Chưa có schema/rule split theo item/quantity/share. Không cho nhập tay tổng tiền. |
| Tiền sảnh / Hall<br>(ホール) | Áp voucher / discount<br>(クーポン・割引適用) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Giữ flow voucher hiện có; chưa thiết kế permission/rule engine và cần audit checkout kỹ hơn. |
| Tiền sảnh + Kế toán<br>(ホール + 会計) | Chốt bill / checkout thành doanh thu<br>(会計・売上確定処理) | 🧪 Đã implement, cần E2E<br>(実装済み・E2E要確認) | Tạm tính qua `hall_get_checkout_summary`, finalize qua `process_checkout`. Build/E2E còn bị block bởi lỗi cũ ngoài scope. |
