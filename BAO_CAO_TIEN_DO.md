# 8. Báo cáo tiến độ 2 tuần vừa qua (過去2週間の進捗報告)

**Quy mô đội dự án / チーム構成 (Team Size):** 3 người (3名)
- **Ishii**: Phân tích nghiệp vụ (Business Analyst) & Logic nghiệp vụ (Business Logic)
- **Per & Phu**: Xây dựng hệ thống Backend, Cấu trúc dữ liệu & Lập trình Frontend (Backend/Frontend Development)

---

### 8.1. Nghiệp vụ đã khảo sát (調査済みの業務要件)
Trong 2 tuần qua, đội ngũ BA (Ishii) đã tiến hành khảo sát và chuẩn hóa các luồng nghiệp vụ phức tạp của mô hình F&B cao cấp:
- **Mô hình kinh doanh nhà hàng Yakiniku cao cấp:** Khảo sát quy trình phục vụ từ lúc khách hàng đặt bàn, Check-in, khai bàn cho đến khi gọi món (hỗ trợ cả 3 luồng: A la carte, Buffet, và Set Menu). 
  > *高級焼肉レストランモデルの調査: 予約からチェックイン、テーブル開設、注文（アラカルト、ビュッフェ、セットメニュー）までの接客プロセス。*
- **Quy trình vận hành Bếp & Kho:** Thiết kế luồng phối hợp giữa các trạm bếp (KDS), trạm điều phối món (Expo), quản lý tồn kho nguyên vật liệu và quy trình xuất/nhập hàng (Requisition).
  > *厨房および在庫運用プロセス: KDSステーション、配膳 (Expo) 間の連携、食材の在庫管理および発注要求プロセスの設計。*
- **Chính sách chăm sóc khách hàng:** Khảo sát logic phân hạng thành viên (Membership), phát hành và áp dụng mã giảm giá (Voucher).
  > *顧客管理ポリシー: 会員ランク (Membership) ロジックの構築と割引クーポン (Voucher) 適用フローの調査。*
- **Quản lý ca làm việc (Shift Management):** Xây dựng quy trình mở/đóng ca, kiểm đếm tiền mặt và báo cáo chênh lệch doanh thu.
  > *シフト管理: シフトの開始・終了、現金精算、および売上差異報告のプロセス構築。*

---

### 8.2. Các chức năng đã xây dựng (Đạt tiến độ ~50% - Đang chờ kiểm thử)
*(構築済みの機能 - 進捗約50%・テスト待ち)*

**Lưu ý quan trọng:** Hệ thống hiện đang trong giai đoạn ghép nối giao diện (UI) và logic cơ sở dữ liệu. **Chưa có tính năng nào được kiểm thử (testing) toàn diện**, do đó hầu hết các luồng nghiệp vụ hiện tại vẫn chưa thể hoạt động trơn tru 100% trên thực tế và có thể phát sinh lỗi trong quá trình sử dụng.
> *重要事項: システムは現在UIとDBロジックの統合段階にあります。包括的なテストを実施していないため、現時点では実運用で100%スムーズに稼働するわけではなく、使用中にバグが発生する可能性があります。*

- **Cơ sở dữ liệu cốt lõi (Core Database System):** Đã thiết lập cấu trúc bảng Supabase, các hàm RPC và RLS. Tuy nhiên, tính chính xác của dữ liệu trả về cần phải được kiểm thử thêm.
  > *コアデータベース: Supabaseのテーブル、RPC関数、RLSを構築済みですが、データの正確性は追加テストが必要です。*
- **Kiến trúc đa ngôn ngữ (Localization):** Xây dựng thành công cơ sở hạ tầng đa ngôn ngữ (Việt, Anh, Nhật) với Pinia & Vue-i18n. Đã đưa hơn 400 khóa ngôn ngữ vào mã nguồn.
  > *多言語アーキテクチャ: PiniaとVue-i18nによる多言語基盤（ベトナム語、英語、日本語）を構築し、400以上の翻訳キーをソースコードに組み込みました。*
- **Phân hệ Lễ tân & Bếp (Reception & Kitchen Modules):** Đã dựng xong giao diện và nối logic cơ bản cho Sơ đồ bàn, Dashboard, KDS, Kho. Tuy nhiên, dữ liệu liên thông (ví dụ: từ màn hình Order bắn sang KDS của Bếp) chưa được kiểm chứng hoạt động nối tiếp end-to-end.
  > *受付および厨房モジュール: フロアマップ、ダッシュボード、KDS、在庫のUI構築と基本ロジックの統合が完了。ただし、各部署間のデータ連携（例：注文からKDSへの送信）のエンドツーエンドの動作確認は未完了です。*
- **Triển khai (Deployment):** Đã thiết lập tự động hóa và đẩy mã nguồn thành công lên môi trường Firebase Hosting (*nguucat-qvn.web.app*).
  > *展開 (Deployment): Firebase Hostingへの自動デプロイ環境を構築し、成功しました。*

---

### 8.3. Những công việc và chức năng sẽ phát triển sắp tới (今後の開発および作業予定)
- **Kiểm thử toàn diện & Xử lý lỗi (Testing & Bug Fixing - Ưu tiên hàng đầu):** Tiến hành rà soát lỗi (QA), thực hiện Unit Test và E2E Test để đảm bảo các luồng chức năng (từ order đến thanh toán) phải chạy xuyên suốt và không xảy ra lỗi.
  > *包括的なテストとバグ修正 (最優先): QAを実施し、ユニットテストおよびE2Eテストを通じて、注文から決済までのフローがエラーなくスムーズに稼働することを保証する。*
- **Kích hoạt Luồng Hội viên & Voucher (Membership & Voucher):** Chạy migration dữ liệu và đưa hệ thống tích điểm, tính toán giảm giá tự động vào luồng thanh toán (Checkout).
  > *会員・クーポンフローの有効化: DBマイグレーションを実行し、ポイント付与や自動割引計算を決済 (Checkout) フローに組み込む。*
- **Tích hợp hệ thống bên thứ 3 (Third-party Integrations):** Triển khai API kết nối phần mềm quản lý kho KiotViet và hệ thống ERP.
  > *サードパーティ連携: KiotViet在庫管理ソフトウェアおよびERPシステムと接続するためのAPIの実装。*
- **Hoàn thiện Báo cáo (Analytics Dashboard):** Tiếp tục xây dựng Dashboard thống kê KGI/KPI và COGS dành riêng cho Ban quản trị.
  > *分析ダッシュボードの完成: 経営陣向けのKPI/KGIおよびCOGS (売上原価) 統計ダッシュボードの構築を継続する。*
