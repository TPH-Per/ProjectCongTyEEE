# GRAND DESIGN CHI TIẾT (HỆ THỐNG QUẢN LÝ F&B / F&B管理システム)
Bản thiết kế phân rã cấp độ Use-Case (UC) cho 6 phân quyền (Roles) trong hệ thống MVP.
MVPシステムにおける6つの権限（ロール）のユースケース（UC）レベルの詳細設計です。

| Phân quyền / 権限 | Mã UC | Chức năng chi tiết (Tiếng Việt) | 機能詳細 (Tiếng Nhật) |
| :--- | :--- | :--- | :--- |
| **1. Khách Hàng**<br>*(Customer)*<br><br>Người dùng trực tiếp tương tác tại bàn.<br>*(テーブルで直接操作するユーザー)* | **UC 1.1** | Sử dụng trực tiếp Tablet tại bàn để chọn món. | テーブルのタブレットを直接使用して注文する。 |
| | **UC 1.2** | Xem Menu điện tử đa ngôn ngữ & xem thông tin thành phần/dị ứng. | 多言語の電子メニューと成分・アレルギー情報を閲覧する。 |
| | **UC 1.3** | Chọn món, tùy chỉnh (ít đá, không cay) và thêm vào giỏ hàng. | 料理を選択し、カスタマイズ（氷少なめ、辛さ抜き等）してカートに追加する。 |
| | **UC 1.4** | Xác nhận Order để gửi thông tin trực tiếp xuống màn hình Bếp. | オーダーを確定し、キッチン画面に直接情報を送信する。 |
| | **UC 1.5** | Gọi phục vụ (thêm nước, xin khăn) hoặc bấm yêu cầu tính tiền. | ウェイターを呼ぶ（水やタオルの追加）、またはお会計をリクエストする。 |
| **2. Tiền Sảnh / Lễ Tân**<br>*(Hall / Reception)*<br><br>Nhân viên điều phối và thu ngân.<br>*(フロアの案内およびレジ担当スタッフ)* | **UC 2.1** | Quản lý sơ đồ bàn trực quan (Bàn trống, Đang phục vụ, Chờ dọn). | 視覚的なテーブル配置図の管理（空席、接客中、片付け待ち）。 |
| | **UC 2.2** | Nhận thông báo (Push) ngay lập tức khi khách gọi phục vụ từ Tablet. | お客様のタブレットからの呼び出し（Push）通知を即座に受信する。 |
| | **UC 2.3** | Can thiệp sửa Order (Hủy món, đổi món, thêm món) nếu khách yêu cầu. | お客様の要望に応じてオーダーを修正する（キャンセル、変更、追加）。 |
| | **UC 2.4** | Thao tác ghép bàn (Merge) hoặc tách Bill (Split) khi khách đi đông. | 大人数のお客様向けにテーブルの結合（マージ）や伝票の分割を行う。 |
| | **UC 2.5** | Áp dụng Voucher, thẻ thành viên, hoặc các chiến dịch giảm giá. | クーポン、メンバーズカード、または割引キャンペーンを適用する。 |
| | **UC 2.6** | Nhận thanh toán (Tiền mặt/Thẻ/Chuyển khoản) và In Bill chính thức. | 支払い（現金/カード/振込）を受け付け、正式なビル（伝票）を印刷する。 |
| **3. Bếp**<br>*(Kitchen)*<br><br>Nhân viên chế biến.<br>*(調理担当スタッフ)* | **UC 3.1** | Hiển thị danh sách món (KDS) theo thời gian thực từ lúc khách đặt. | 注文時からリアルタイムで料理リスト（KDS）を表示する。 |
| | **UC 3.2** | Phân loại hiển thị theo trạm (Bếp Nóng, Bếp Lạnh, Quầy Bar). | ステーション別（ホットキッチン、コールドキッチン、バー）に分類表示する。 |
| | **UC 3.3** | Cảnh báo đổi màu (Cam/Đỏ) nếu món ăn chờ quá thời gian quy định (vd: 15p). | 規定の待ち時間（例：15分）を超えた場合に警告色（オレンジ/赤）で表示する。 |
| | **UC 3.4** | Bấm cập nhật trạng thái "Đã xong" để báo Sảnh lên món. | 「調理完了」ステータスを押して、ホールスタッフに配膳を通知する。 |
| | **UC 3.5** | Thông báo hết nguyên liệu (Sold out) để đồng bộ làm mờ món trên Menu. | 品切れ（Sold out）を通知し、メニュー上の料理を非表示（グレーアウト）にする。 |
| **4. Mua Hàng & Kho**<br>*(Purchasing)*<br><br>Quản lý vật tư đầu vào.<br>*(資材・仕入れ管理)* | **UC 4.1** | Tiếp nhận Phiếu giao hàng (Goods Receipt) hằng ngày từ Nhà cung cấp. | サプライヤーからの毎日の納品伝票（Goods Receipt）を受け付ける。 |
| | **UC 4.2** | Upload (tải lên) hình ảnh hoặc file PDF chứng từ scan để lưu trữ. | 保管用に証憑の写真またはPDFファイルをアップロード（スキャン）する。 |
| | **UC 4.3** | Nhập tay chi tiết Hàng hóa, Số lượng thực nhận và Đơn giá vào Form. | フォームに商品詳細、実際の受領数量、および単価を手入力する。 |
| | **UC 4.4** | Bấm lưu để hệ thống tự động cộng dồn số lượng vào Tồn kho (Inventory). | 保存ボタンを押して、在庫（Inventory）数量を自動的に加算（更新）する。 |
| | **UC 4.5** | Lập Phiếu kiểm kê định kỳ, đối chiếu số liệu tồn kho thực tế và hệ thống. | 定期棚卸し伝票を作成し、実際の在庫とシステムデータを照合する。 |
| **5. Kế Toán**<br>*(Accounting)*<br><br>Xử lý thuế & dòng tiền.<br>*(税務・資金処理)* | **UC 5.1** | Lọc danh sách Bill đã thanh toán trong ngày/tháng để xuất Hóa đơn đỏ. | 当日/当月の支払い済みビルをフィルタリングし、レッドインボイス（VAT）を発行する。 |
| | **UC 5.2** | Nhập thông tin Mã số thuế, Tên công ty để phát hành Hóa đơn VAT (Valid). | 納税者番号と会社名を入力し、有効（Valid）なVATインボイスを発行する。 |
| | **UC 5.3** | Chức năng "Sửa/Thay thế": Khóa hóa đơn cũ (Updated) và tạo hóa đơn mới. | 「修正・代替」機能：古いインボイスをロック（Updated）し、新規作成する。 |
| | **UC 5.4** | Tra cứu lịch sử Hóa đơn: Một Bill có thể lưu trữ nhiều hóa đơn (do lịch sử sửa đổi) nhưng chỉ có duy nhất 1 hóa đơn hợp lệ (Valid). | インボイス履歴の照会：1つのビルに複数のインボイス（修正履歴により）を保存できるが、有効な（Valid）インボイスは常に1つのみとする。 |
| | **UC 5.5** | Xuất báo cáo Doanh thu (VAT/Non-VAT) và báo cáo công nợ Nhà cung cấp. | 売上レポート（VAT/非VAT）およびサプライヤーの買掛金レポートを出力する。 |
| **6. CRM (Chăm sóc Khách hàng)**<br>*(Customer Care)*<br><br>Khảo sát trực tiếp tại bàn.<br>*(テーブルでの直接アンケート)* | **UC 6.1** | Xem danh sách bàn đang phục vụ (Serving) để tiếp cận khách hàng. | 接客中（Serving）のテーブルリストを確認し、お客様にアプローチする。 |
| | **UC 6.2** | Khảo sát thông tin: Nguồn biết đến nhà hàng (nền tảng nào) và lý do đến. | 情報収集：どのプラットフォームでレストランを知ったか、来店の理由。 |
| | **UC 6.3** | Thu thập phản hồi: Ghi nhận cảm nhận của khách và các điểm cần cải thiện. | フィードバック収集：お客様の感想や改善すべき点を記録する。 |
| | **UC 6.4** | Lưu trữ: Gắn trực tiếp thông tin khảo sát vào Bill hiện tại của bàn đó. | データ保存：収集したアンケート情報を該当テーブルの現在のビルに直接紐付ける。 |
| **7. Admin / Owner**<br>*(Quản trị cấp cao)*<br><br>Quản lý toàn hệ thống.<br>*(全システム管理)*<br>**※ Cần Kato-san xác nhận / 加藤さんの確認が必要です** | **UC 7.1** | Executive Dashboard: Xem tổng quan Lợi nhuận, Doanh thu, Điểm hòa vốn. | エグゼクティブダッシュボード：利益、売上、損益分岐点の概要を閲覧する。 |
| | **UC 7.2** | Thiết lập thông số cốt lõi: Phí dịch vụ (Service Charge), Thuế (VAT Tax). | コアパラメータの設定：サービス料（Service Charge）、税金（VAT Tax）。 |
| | **UC 7.3** | Quản lý Tài khoản: Tạo mới, Khóa, Phân quyền chi tiết cho nhân viên. | アカウント管理：従業員の新規作成、ロック、および詳細な権限の割り当て。 |
| | **UC 7.4** | Quản trị Marketing: Thiết lập mã giảm giá (Voucher) và thời gian áp dụng. | マーケティング管理：割引コード（バウチャー）と適用期間の設定。 |
| | **UC 7.5** | Lịch sử Kiểm toán (Audit Log): Giám sát thao tác Hủy Bill, Sửa hóa đơn. | 監査ログ（Audit Log）：ビルのキャンセルやインボイス修正の操作を監視する。 |
