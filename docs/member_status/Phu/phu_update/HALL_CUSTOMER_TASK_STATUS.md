# Hall + Customer Task Status

| Phân hệ (モジュール) | Chức năng (機能) | Trạng thái (ステータス) | Ghi chú (備考) |
| --- | --- | --- | --- |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xem menu điện tử đa ngôn ngữ<br>(多言語メニュー表示) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `/tablet` đọc menu qua RPC. Full E2E với seeded tablet context đang skipped. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xem thành phần/dị ứng<br>(成分・アレルギー情報表示) | ⏳ Chờ xử lý<br>(未対応) | RPC trả `ingredients`, `nutrition`, `tags`, nhưng UI chi tiết chưa hoàn chỉnh. Không bịa allergy data giả. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Chọn món, tùy chỉnh, thêm vào giỏ<br>(商品選択・カスタマイズ・カート追加) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | Cart cơ bản theo quantity đã có. Modifier/note nâng cao chưa đầy đủ. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Xác nhận order<br>(注文確定) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `customer_submit_table_order` đọc giá từ DB và có idempotency. Full DB assertion E2E chưa chạy. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Gọi phục vụ<br>(スタッフ呼出) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `create_service_request` tạo `CALL_WAITER`; E2E seeded session chưa chạy. |
| Khách hàng / Tablet<br>(顧客・タブレット) | Yêu cầu tính tiền<br>(会計依頼) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `TabletCheckoutView` và footer request tạo `REQUEST_BILL`; không checkout trực tiếp. |
| Tiền sảnh / Hall<br>(ホール) | Quản lý sơ đồ bàn<br>(テーブル管理) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `hall_list_tables`, `get_floor_plan`; E2E auth/fixture chưa chạy. |
| Tiền sảnh / Hall<br>(ホール) | Quản lý đặt chỗ / seat guest<br>(予約・来店管理) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | Reservation RPC tối thiểu có. Chưa có full check-in/seat guest E2E. |
| Tiền sảnh / Hall<br>(ホール) | Nhận thông báo từ tablet<br>(タブレット通知受信) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | `hall_list_service_requests`; request queue full E2E skipped. |
| Tiền sảnh / Hall<br>(ホール) | Xử lý yêu cầu phục vụ<br>(接客リクエスト処理) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | Ack/complete RPC có. Customer không tự resolve. |
| Tiền sảnh / Hall<br>(ホール) | Theo dõi order<br>(テーブル注文管理) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | Hall/KDS đọc active orders, KDS mock auto-load đã bỏ. |
| Tiền sảnh / Hall<br>(ホール) | Sửa/hủy/thêm order item<br>(注文修正・取消・追加) | ⏳ Chờ xử lý<br>(未対応) | Chưa implement vì cần kitchen/bill lock rule và audit. |
| Tiền sảnh / Hall<br>(ホール) | Ghép bàn<br>(テーブル結合) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Chưa đủ session/order model an toàn. Không đổi `table_id` thô. |
| Tiền sảnh / Hall<br>(ホール) | Tách bill<br>(会計分割) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Chưa có schema/rule split theo item/quantity/share. |
| Tiền sảnh / Hall<br>(ホール) | Áp voucher/discount<br>(クーポン・割引適用) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | Flow hiện có còn partial; cần permission/rule audit. |
| Tiền sảnh + Kế toán<br>(ホール + 会計) | Checkout thành doanh thu<br>(会計・売上確定処理) | ⚠️ Cần xem xét kỹ<br>(要詳細設計) | `hall_get_checkout_summary` có; final `process_checkout` cần E2E/accounting audit. |
| CRM<br>(顧客ケア・CRM) | Regression survey tại bàn<br>(テーブルアンケート回帰確認) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | Build/migration pass; CRM E2E skipped do thiếu seeded active order/CRM auth. |
| CRM<br>(顧客ケア・CRM) | Link survey vào bill khi checkout<br>(会計時アンケート請求書連携) | 🧪 Đã implement, cần E2E thêm<br>(実装済み・E2E要確認) | RPC/link logic có; cần checkout E2E xác nhận trên DB thật. |
