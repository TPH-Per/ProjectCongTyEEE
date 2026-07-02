# CRM Task Status

| Phân hệ (モジュール) | Chức năng (機能) | Trạng thái (ステータス) | Ghi chú (備考) |
| --- | --- | --- | --- |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Xem danh sách bàn đang phục vụ<br>(接客中テーブル一覧取得) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_list_serving_tables`; lấy bàn đang phục vụ theo active order/session, không lấy survey cũ theo `table_id`. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Hiển thị trạng thái khảo sát của từng bàn<br>(テーブル別アンケート状態表示) | ✅ Hoàn thành<br>(完了) | Đã hiển thị các trạng thái `not_started`, `assigned`, `in_progress`, `completed`, `skipped`, `customer_refused`, `expired`, `late_submitted` trên màn `/crm/serving-tables`. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Bắt đầu / tiếp tục khảo sát tại bàn<br>(テーブルアンケート開始・継続) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_mark_survey_in_progress`; survey được gắn với `order_id` / `table_assignment_id`, không định danh chính bằng `table_id`. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Gửi khảo sát tại bàn<br>(テーブルアンケート送信) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_submit_table_survey`; lưu nguồn khách, lý do đến, feedback, điểm cần cải thiện, note, tags và thông tin khách nếu có. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Ghi nhận khách từ chối khảo sát<br>(アンケート拒否記録) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_refuse_table_survey`; trạng thái `customer_refused` không bị xem là chưa hỏi. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Bỏ qua khảo sát<br>(アンケートスキップ記録) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_skip_table_survey`; trạng thái `skipped` không bị xem là chưa hỏi. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Tự động hết hạn survey cũ<br>(古いアンケートの期限切れ処理) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_expire_old_surveys`; survey `assigned` / `in_progress` của order đã đóng sẽ thành `expired`, không dính vào lượt khách mới. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Chống trùng khảo sát cho cùng lượt ăn<br>(同一セッションの重複アンケート防止) | ✅ Hoàn thành<br>(完了) | Đã tạo unique index theo `order_id` và `table_assignment_id` cho survey active; không tạo unique theo `table_id`. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Link khảo sát vào bill khi checkout<br>(会計時のアンケート・請求書連携) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_link_surveys_to_bill` và gọi trong `process_checkout`; checkout không bắt buộc phải có CRM survey. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Guest DB từ survey nếu khách tự nguyện cung cấp thông tin<br>(任意入力による顧客DB更新) | ✅ Hoàn thành<br>(完了) | `crm_submit_table_survey` có normalize phone bằng `crm_normalize_phone`, match/update/create `customers` khi có số điện thoại; nếu không có SĐT thì survey vẫn lưu bình thường. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Lấy danh sách feedback khách hàng<br>(顧客フィードバック一覧取得) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_list_customer_feedback`; CRM feedback view đi qua RPC thay vì query bảng trực tiếp. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Lấy danh sách yêu cầu/dịch vụ liên quan CRM<br>(サービスリクエスト一覧取得) | ✅ Hoàn thành<br>(完了) | Đã bọc RPC `crm_list_service_requests`; phục vụ màn CRM/staff liên quan phản hồi và yêu cầu khách. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Bảo mật dữ liệu CRM theo chi nhánh<br>(支店別CRMデータアクセス制御) | ✅ Hoàn thành<br>(完了) | Đã bật RLS cho `crm_surveys` và dùng `crm_assert_branch_access` trong RPC; không mở public access. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Màn CRM Serving Tables<br>(CRM接客中テーブル画面) | ✅ Hoàn thành<br>(完了) | Đã thêm route `/crm/serving-tables`; giao diện hỗ trợ xem bàn, start/continue survey, submit, refused, skipped. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Tự động enrich Guest DB không cần CRM hỏi SĐT<br>(電話番号を聞かない顧客DB自動補完) | ⏳ Chờ xử lý<br>(未対応) | Cần làm ở phase sau; hiện đã ghi backlog trong `CRM_FUTURE_TODO.md`. Không nên ép CRM staff hỏi SĐT tại bàn. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Gắn customer profile tự động vào lượt ăn hiện tại<br>(顧客プロフィールと現在セッションの自動紐付け) | ⏳ Chờ xử lý<br>(未対応) | Cần bổ sung logic để active order/session có `customer_id` khi hệ thống đã xác định được khách; survey vẫn hoạt động nếu `customer_id` null. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Badge UI cho trạng thái Guest DB match<br>(顧客DB照合状態バッジ表示) | ⏳ Chờ xử lý<br>(未対応) | Cần thêm badge như `Guest matched`, `No guest profile`, `Provisional profile` trên `/crm/serving-tables` sau khi có logic match khách. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Dashboard phân tích Marketing từ CRM<br>(CRMマーケティング分析ダッシュボード) | ⏳ Chờ xử lý<br>(未対応) | Cần làm sau khi dữ liệu Guest DB ổn định; phân tích theo source, visit reason, feedback, tags, repeat visit và spend. |
| CRM / Chăm sóc khách hàng<br>(顧客ケア・CRM) | Gộp/tránh trùng customer profile<br>(顧客プロフィール重複管理) | ⏳ Chờ xử lý<br>(未対応) | Cần công cụ merge/deduplicate sau này; hiện đã tránh duplicate cơ bản bằng `normalized_phone` khi survey có SĐT. |

## Business Note

Trọng tâm hiện tại của CRM đã hoàn thành là khảo sát tại bàn theo đúng lượt ăn hiện tại và link survey vào bill. Phần Guest DB dài hạn đã có nền tảng, nhưng logic tự động bổ sung hồ sơ khách mà không cần CRM hỏi số điện thoại vẫn là việc cần làm sau.
