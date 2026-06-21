QUT Vietnam JSC | Kế hoạch tự phát triển POS NguuCat / NguuCat POS自社開発計画書内訳 / 社内検討用

KẾ HOẠCH TỰ PHÁT TRIỂN POS – NGUU CAT (Đa chi nhánh)
NguuCat (牛Cat) 多店舗 POS自社開発計画書
Kế hoạch sơ bộ kèm lộ trình / 簡易計画書（ロードマップ付き）

1. Tổng quan / 概要

Mục / 項目	Nội dung / 内容
Đối tượng kinh doanh / 対象事業	
Hệ thống nhà hàng nướng NguuCat (đa chi nhánh) tại Việt Nam


NguuCat (牛Cat) 焼肉店の多店舗（Vietnam国内）

Hiện trạng / 現状	
Đang sử dụng POS của nhà cung cấp F2Tech


Vendor POS「F2Tech」を使用中

Mục tiêu / 目的	
Giảm sự phụ thuộc vào F2Tech, tự phát triển POS bằng kỹ sư nội bộ (3 người) để tăng tính linh hoạt về chi phí, tùy biến và kết nối dữ liệu


F2Tech 依存からの脱却。コスト・カスタマイズ自由度・データ連携の柔軟性を確保するため、自社エンジニア（3名）でPOSを自社開発する

Cơ cấu nhân sự / 体制	
3 kỹ sư nội bộ (giả định toàn thời gian; cần xác nhận phân công vai trò)


社内エンジニア3名（専任体制を想定。要：役割分担の確定）

Phạm vi áp dụng / 対象範囲	
Không bao gồm đa thương hiệu / toàn tập đoàn. Chỉ áp dụng cho các chi nhánh NguuCat


マルチブランド/グループ全体は対象外。NguuCat多店舗のみ

Mốc quan trọng nhất / 最重要マイルストーン	
31/07/2026: Vận hành thử nghiệm (test) tại 1 chi nhánh (kiểm tra thực tế với dữ liệu vận hành thật)


2026年7月31日：単店舗でのテスト稼働（パイロット店舗1店にて実運用データでの動作確認）

※ Kế hoạch này được xây dựng với hiểu rằng "triển khai 1 chi nhánh cuối tháng 7" nghĩa là vận hành thử nghiệm (test run) tại chi nhánh thí điểm. Nếu hiểu khác, vui lòng phản hồi. / 「7月末一単店舗導入」は、特定パイロット店舗における本番データでのテスト稼働を指すという理解で計画を作成しています。異なる場合はご指摘ください。

2. Mục tiêu và Phạm vi / 目的とスコープ

2.1 Mục tiêu / 目的
• Giảm chi phí phụ thuộc vào phí license / phí hàng tháng của POS nhà cung cấp (F2Tech)
Vendor POS（F2Tech）のライセンス費・月額費用への依存を低減する
• Cho phép tùy biến chức năng phù hợp với đặc thù vận hành nhà hàng nướng (gọi món theo set, quản lý bếp than trên bàn, tần suất gọi thêm cao)
焼肉店特有の運用（コース注文、卓上炭火管理、追加注文の頻度など）に合わせた機能カスタマイズを可能にする
• Quản lý tập trung dữ liệu doanh thu và khách hàng của các chi nhánh trên hạ tầng riêng, phục vụ phân tích và ra quyết định kinh doanh
多店舗の売上・顧客データを自社基盤で一元管理し、分析・経営判断に活用できる状態にする

2.2 Phạm vi (của kế hoạch lần này) / スコープ（今回計画の範囲）
• Trong phạm vi: Chức năng POS cho các chi nhánh NguuCat (gọi món, thanh toán, quản lý bàn, báo cáo cơ bản)
対象：NguuCat多店舗のPOS機能（オーダー、会計、テーブル管理、基本レポート）

2.3 5 rủi ro dự kiến / 想定する5つのリスクRủi ro / リスクHướng xử lý (đề xuất) / 対応方針（案）Khó khăn khi 3 người vừa phát triển vừa vận hành3名体制での開発・運用の両立が困難Tập trung vào MVP (chức năng tối thiểu cần thiết), bổ sung chức năng theo từng giai đoạnMVP（必要最小機能）に絞り込み、機能追加は段階リリースとするDi chuyển dữ liệu từ F2Tech phức tạp hơn dự kiếnF2Techからのデータ移行が想定より複雑Ưu tiên hàng đầu khảo sát API / khả năng xuất dữ liệu của F2Tech ngay trong giai đoạn xác định yêu cầu要件定義フェーズでF2TechのAPI/エクスポート仕様を最優先で調査するNhân viên hiện trường (sảnh/bếp) cần thời gian làm quen vận hành mới現場（ホール・厨房）の操作習熟に時間がかかるBố trí giai đoạn vận hành song song tối thiểu 2 tuần tại chi nhánh thí điểm, lặp lại khảo sát hiện trườngパイロット店舗で2週間以上の並行稼働期間を設け、現場ヒアリングを反復するThời gian đến 31/07 (bao gồm xác định yêu cầu) khá ngắn7/31までの期間が要件定義含め短いĐịnh nghĩa "vận hành thử nghiệm" là PoC với chức năng hạn chế; việc đánh giá vận hành chính thức sẽ thực hiện riêngテスト稼働の定義を「限定機能でのPoC」とし、本稼働判定は別途設けるThiếu sót yêu cầu về thanh toán/kế toán (hóa đơn, thuế)決済・会計（レシート、税務）要件の不備Xác nhận bắt buộc các yêu cầu về hóa đơn/biên lai tại Việt Nam trong giai đoạn xác định yêu cầuベトナム国内のレシート・インボイス要件を要件定義工程で必ず確認する3. Cơ cấu triển khai / 推進体制Giả định cơ cấu 3 kỹ sư nội bộ, phân công vai trò dự kiến như sau (sẽ xác định sau khi chọn nhân sự). / 社内エンジニア3名体制を前提とし、以下の役割分担を想定する（人選確定後に確定）。Vai trò / 役割Số lượng / 人数Công việc chính / 主なタスクPM / Phụ trách xác định yêu cầuPM/要件定義リード1 người / 1名Khảo sát POS hiện tại, khảo sát người dùng, lập tài liệu yêu cầu, quản lý tiến độ現状POS調査、ユーザーヒアリング、要件定義書の作成、進行管理Phát triển Backendバックエンド開発1 người / 1名Thiết kế API/DB, di chuyển dữ liệu F2Tech, logic thanh toán/kế toánAPI・DB設計、F2Techデータ移行、決済・会計ロジックFrontend / Liên kết hiện trườngフロントエンド/現場連携1 người / 1名Giao diện POS (gọi món/thanh toán), hỗ trợ test hiện trường, tài liệu đào tạoPOS UI（オーダー・会計画面）、現場テスト対応、トレーニング資料作成※ Giả định 3 người kiêm nhiệm nhiều việc; khuyến nghị toàn bộ tham gia giai đoạn xác định yêu cầu dưới sự dẫn dắt của PM. / 3名は兼任を前提とし、要件定義フェーズはPM主導で全員参加を推奨します。


Lộ trình triển khai (đến 31/07/2026)
Kế hoạch bao gồm 5 giai đoạn chính từ ngày 17/06/2026 đến ngày 31/07/2026:

Giai đoạn 1 (17/06–26/06): Xác định yêu cầu

Khảo sát chức năng và cấu trúc dữ liệu POS F2Tech hiện tại.

Phỏng vấn người dùng tại hiện trường (sảnh, thu ngân, bếp, quản lý) để xác định các điểm thiếu sót.

Lập tài liệu xác định yêu cầu.

Giai đoạn 2 (27/06–03/07): Thiết kế cơ bản

Thiết kế màn hình (gọi món, thanh toán, quản lý bàn).

Thiết kế cơ sở dữ liệu (DB).

Xác định phương án di chuyển dữ liệu từ F2Tech.

Giai đoạn 3 (04/07–17/07): Phát triển (MVP)

Triển khai các chức năng gọi món, thanh toán, xuất hóa đơn/biên lai và báo cáo doanh thu cơ bản.

Giai đoạn 4 (18/07–24/07): Kiểm thử nội bộ

Thực hiện kiểm thử tích hợp, kiểm thử quy trình từ lúc gọi món đến thanh toán, và sửa lỗi.

Giai đoạn 5 (25/07–31/07): Triển khai thí điểm

Vận hành song song với F2Tech tại 1 chi nhánh thí điểm.

Đào tạo nhân viên hiện trường và đánh giá quá trình vận hành thử nghiệm.

Lưu ý: Lịch trình này được thiết kế ngược từ ngày 31/07. Khuyến nghị nên xem xét lại kế hoạch vào ngày 26/06 tùy thuộc vào độ sâu của giai đoạn xác định yêu cầu.

Chi tiết giai đoạn xác định yêu cầu
Các công việc cụ thể trong giai đoạn xác định yêu cầu bao gồm:

Rà soát toàn bộ danh sách các chức năng hiện đang dùng của F2Tech (gọi món, thanh toán, thành viên, báo cáo, kết nối thanh toán, v.v.).

Xác định khả năng xuất dữ liệu hoặc tích hợp API (dữ liệu doanh thu, danh mục sản phẩm, dữ liệu khách hàng).

Kiểm tra cấu hình phần cứng hiện tại (máy POS, máy in, két tiền) xem có thể tiếp tục sử dụng hay không.

Xác nhận các điều kiện hợp đồng (điều kiện hủy, thời gian lưu trữ dữ liệu, thời điểm kết thúc hỗ trợ).

QUT Vietnam JSC | Kế hoạch tự phát triển POS NguuCat / NguuCat POS自社開発計画書内訳 / 社内検討用

5.2 Khảo sát người dùng (điểm thiếu sót của POS hiện tại) / ユーザーヒアリング（現POSの不足点）
Đối tượng khảo sát / ヒアリング対象	Điểm cần xác nhận (ví dụ) / 確認したいポイント（例）
Quản lý chi nhánh / 店長／店舗マネージャー	Khó khăn khi tổng hợp doanh thu/chốt ca, khó so sánh giữa nhiều chi nhánh, các mục báo cáo còn thiếu / 売上集計・締め作業の課題、複数店舗比較のしづらさ、レポートの不足項目
Nhân viên sảnh (phụ trách gọi món) / ホールスタッフ（オーダー担当）	Sự bất tiện khi nhập món, khả năng vận hành khi gọi set/gọi thêm, khó khăn trong quản lý bàn / オーダー入力の手間、コース・追加注文時の操作性、卓管理のしづらさ
Nhân viên thu ngân/thanh toán / レジ／会計担当	Tốc độ xử lý thanh toán, tính linh hoạt khi áp dụng giảm giá/coupon, vấn đề khi xuất hóa đơn / 会計処理スピード、割引・クーポン対応の柔軟性、レシート発行の課題
Nhân viên bếp / 厨房スタッフ	Độ rõ ràng của phiếu order, có liên kết tình trạng nấu hay không, độ trễ vào giờ cao điểm / オーダー票の見やすさ、調理状況連携の有無、ピーク時の遅延
※ Khuyến nghị thực hiện khảo sát tại ít nhất 1-2 chi nhánh, ghi nhận cả định lượng (thời gian vận hành, số lỗi...) và định tính (khó khăn thực tế). / ヒアリングは最低1～2店舗で実施し、定量（操作時間・エラー件数等）と定性（困りごと）の両面で記録することを推奨します。

6. Hành động tiếp theo (1 tuần tới) / 次のアクション（直近1週間）
① Xác định người phụ trách xác định yêu cầu, thu thập hợp đồng/tài liệu kỹ thuật với F2Tech / ①要件定義リードを決定し、F2Techとの契約書・仕様資料を収集する

② Xác định danh sách chi nhánh/đối tượng phỏng vấn / ②ヒアリング対象店舗・対象者リストを確定する

③ Lập bảng câu hỏi khảo sát (cụ thể hóa dựa trên bảng tại mục 5.2) / ③ヒアリング項目シートを作成する（5.2の表をベースに具体化）

④ Đặt lịch họp rà soát tài liệu xác định yêu cầu vào ngày 26/06 / ④6/26時点での要件定義書レビュー会議をカレンダーに設定する

Tài liệu này là kế hoạch sơ bộ cho giai đoạn khảo sát ban đầu. Khuyến nghị rà soát lại lịch trình chi tiết và nguồn lực cần thiết cho các giai đoạn phát triển (3)(4)(5) sau khi có kết quả của giai đoạn xác định yêu cầu. / 本書は初期検討用の簡易計画書です。要件定義フェーズの結果を踏まえ、開発工程(3)(4)(5)の詳細スケジュールおよび必要リソースの見直しを行うことを推奨します。

7. Billing/Cost

Supabase 月額運用コストレポート

1. Tổng quan về các gói chi phí cơ bản (Base Pricing Overview) 1. 基本プランの概要

Gói Free (Miễn phí): $0/tháng. Phù hợp cho dự án thử nghiệm. Bao gồm 500MB Database, 1GB Storage, và 50.000 MAU (Người dùng hoạt động hàng tháng). 無料プラン：月額0ドル。テストプロジェクトに最適です。データベース500MB、ストレージ1GB、50,000 MAU（月間アクティブユーザー数）が含まれます。

Gói Pro: $25/tháng. Dành cho môi trường thực tế (production). Bao gồm 8GB Database, 100GB Storage, 100.000 MAU. Được tặng kèm $10 tín dụng (credit) để trả phí máy chủ. Proプラン：月額25ドル。本番環境（プロダクション）向けです。データベース8GB、ストレージ100GB、100,000 MAUが含まれます。サーバー費用に使える10ドルのクレジットが付与されます。