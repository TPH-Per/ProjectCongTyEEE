# BÁO CÁO TIẾN ĐỘ DỰ ÁN POS NGƯU CÁT — Tuần 3 (17/06 → 21/06/2026)
# NguuCat POS 進捗レポート — 第3週（2026/06/17 → 2026/06/21）

> **Người nhận / 報告先**: Ban lãnh đạo QUT Vietnam JSC ／ QUTベトナム社 経営層
> **Người lập / 作成者**: Ishii-san (PM + Xác định yêu cầu + Frontend) ／ 石井さん（PM＋要件定義＋フロントエンド）
> **Ngày lập / 作成日**: 21/06/2026
> **Mốc mục tiêu / 目標マイルストーン**: 31/07/2026 — Vận hành thử nghiệm tại 1 chi nhánh ／ 2026年7月31日 — 1店舗でのテスト稼働

---

## 0. Phân công nhân sự ／ 役割分担

| Vai trò ／ 役割 | Phụ trách ／ 担当 | Công việc chính ／ 主なタスク |
|---|---|---|
| PM / Xác định yêu cầu / Frontend<br>PM／要件定義／フロントエンド | **Ishii-san ／ 石井さん** | Khảo sát POS F2Tech, phỏng vấn 3 team, lập tài liệu yêu cầu, quản lý tiến độ, giao diện POS (gọi món/thanh toán), hỗ trợ test hiện trường, tài liệu đào tạo ／ F2Tech POS調査、3チームヒアリング、要件定義書作成、進行管理、POS UI（オーダー・会計画面）、現場テスト対応、トレーニング資料作成 |
| Backend<br>バックエンド | **Per & Phu** | Thiết kế API/DB, di chuyển dữ liệu F2Tech, logic thanh toán/kế toán, RLS policies, Supabase Realtime ／ API・DB設計、F2Techデータ移行、決済・会計ロジック、RLSポリシー、Supabase Realtime |

---

## 1. Tổng quan tiến độ ／ 進捗サマリー

| Giai đoạn ／ フェーズ | Thời gian ／ 期間 | Trạng thái ／ ステータス | Hoàn thành ／ 完了率 |
|---|---|---|---|
| 1. Xác định yêu cầu ／ 要件定義 | 17/06 → 26/06 | 🟡 Đang làm ／ 実施中 | ~70% |
| 2. Thiết kế cơ bản ／ 基本設計 | 27/06 → 03/07 | 🟢 Làm sớm ／ 前倒し着手 | ~40% |
| 3. Phát triển MVP ／ MVP開発 | 04/07 → 17/07 | ⚪ Chưa bắt đầu ／ 未着手 | 0% |
| 4. Kiểm thử nội bộ ／ 内部テスト | 18/07 → 24/07 | ⚪ Chưa bắt đầu ／ 未着手 | 0% |
| 5. Triển khai thí điểm ／ パイロット導入 | 25/07 → 31/07 | ⚪ Chưa bắt đầu ／ 未着手 | 0% |

**Tổng tiến độ dự án ／ プロジェクト全体進捗**: ước tính 35% ／ 約35%

---

## 2. Mục đã hoàn thành trong tuần (theo Plan) ／ 今週完了した項目（計画通り）

### 2.1 Giai đoạn 1 — Xác định yêu cầu ／ フェーズ1 — 要件定義

**Việt**: Xây dựng xong bộ giao diện prototype 26 màn hình cho 5 vai trò (Admin, Manager, Reception, Staff, Tablet).
**日本語**: 5つの役割（Admin、Manager、Reception、Staff、Tablet）向けに26画面のUIプロトタイプを完成。

**Việt**: Hoàn thành hệ thống đa ngôn ngữ (Tiếng Việt / Tiếng Nhật) với vue-i18n.
**日本語**: vue-i18nによる多言語システム（ベトナム語／日本語）を完成。

**Việt**: Chuẩn hóa dữ liệu mẫu (`mock-data.ts`) khớp với 100% các trường nghiệp vụ mà UI cần đọc.
**日本語**: UIが必要とする業務フィールド100%と一致するようにサンプルデータ（`mock-data.ts`）を標準化。

**Việt**: Khảo sát và lập tài liệu phân tích nghiệp vụ nhà hàng nướng (`BUSINESS_ANALYSIS.md`, 19KB).
**日本語**: 焼肉店業務の分析ドキュメント（`BUSINESS_ANALYSIS.md`、19KB）を作成。

### 2.2 Giai đoạn 2 — Thiết kế cơ bản (làm sớm hơn lịch) ／ フェーズ2 — 基本設計（予定より前倒し）

**Việt**: Hoàn thành thiết kế cơ sở dữ liệu PostgreSQL — 19 bảng (15 bảng ràng buộc chặt + 4 bảng linh hoạt) tuân theo nguyên tắc "chỗ nào cần tính nhất quán cao thì dùng FK, chỗ nào linh hoạt thì dùng JSONB".
**日本語**: PostgreSQLデータベース設計を完成 — 「高整合性が必要な箇所はFK、柔軟性が必要な箇所はJSONB」という原則に従い、19テーブル（高制約15 + 柔軟4）を設計。

**Việt**: Viết tài liệu lý giải thiết kế DB (`DATABASE_DESIGN.md`, 16KB) kèm ma trận phủ sóng 26 view và hướng dẫn mở rộng khi thêm tính năng mới.
**日本語**: データベース設計の根拠ドキュメント（`DATABASE_DESIGN.md`、16KB）を作成。26画面の対応表と、機能追加時の拡張ガイドを含む。

**Việt**: Rà soát và xác nhận schema phủ họa 100% nghiệp vụ trong phạm vi POS (đặt bàn, gọi món, thanh toán, quản lý bàn, báo cáo cơ bản).
**日本語**: POS範囲（予約、オーダー、会計、テーブル管理、基本レポート）の業務100%をスキーマが網羅していることを検証済み。

### 2.3 Billing / Vận hành ／ 課金・運用

**Việt**: Xác nhận ngân sách hạ tầng: **25 USD/tháng (Supabase Pro)** là đủ cho 5 chi nhánh, có thể triển khai POS ở 5 chi nhánh **hoàn toàn miễn phí** (Frontend Vercel Free + Supabase Pro $25 + Domain ~$1).
**日本語**: インフラ予算を確認：**月額25 USD（Supabase Pro）** で5店舗分を運用可能。POSソフトを5店舗に**完全無料**で展開可能（Vercel無料枠 + Supabase Pro $25 + ドメイン約$1）。

**Việt**: Phân tích quota Supabase Pro (8GB DB, 100GB Storage, 500 realtime connections, 100K MAU) chứng minh dư sức cho 1–5 chi nhánh / 30–60 bàn / 200 lượt đặt/ngày.
**日本語**: Supabase Pro枠（DB 8GB、Storage 100GB、Realtime 500接続、MAU 10万）の分析により、1〜5店舗／卓数30〜60／予約200件/日の規模で十分余裕があることを確認。

---

## 3. Mục đang làm (theo Plan) ／ 現在進行中の項目（計画通り）

### 3.1 Xác nhận lại yêu cầu với 3 team (ưu tiên tuần này) ／ 3チームへの要件再確認（今週の優先事項）

> ⚠️ **Cảnh báo / 注意**: Đây là việc bắt buộc theo mục 6.1 "Hành động tiếp theo" của Plan, cần hoàn thành trước 26/06 để khóa phạm vi.
> ⚠️ これは計画書6.1「次のアクション」に必須の作業であり、26/06までにスコープを確定する必要がある。

**Việt**: **Lễ tân / Tiếp tân** — Xác nhận: luồng check-in, gán bàn, xử lý walk-in (khách không đặt trước), quy trình khóa giờ khi khách đến muộn.
**日本語**: **受付チーム** — 確認事項：チェックインの流れ、卓割り当て、ウォークイン処理、遅刻時の時間ロック手順。

**Việt**: **Phục vụ / Bếp** — Xác nhận: cách nhập món theo set/buffet, cảnh báo món hết, đồng bộ trạng thái món với bếp (KDS), tần suất gọi thêm món.
**日本語**: **ホール／厨房チーム** — 確認事項：セット／ビュッフェの入力方法、品切れアラート、厨房モニター（KDS）連携、追加オーダーの頻度。

**Việt**: **Thu ngân / Quản lý** — Xác nhận: yêu cầu hóa đơn đỏ VN (mẫu, số seri, mã số thuế), chính sách giảm giá/coupon, quy trình đóng ca, xuất báo cáo thuế.
**日本語**: **レジ／マネージャー** — 確認事項：ベトナム赤伝票の要件（様式・連番・税番号）、割引／クーポンポリシー、締め作業、税申告用レポート出力。

### 3.2 Mở rộng schema cho nghiệp vụ mới ／ 新業務向けのスキーマ拡張

**Việt**: Đang bổ sung các trường thiếu đã phát hiện qua khảo sát UI: mã số thuế khách hàng, seri hóa đơn đỏ VN, KPI target cho AdminKPIView, công thức định lượng nguyên liệu (BOM) cho báo cáo COGS. (Per & Phu)
**日本語**: UI調査で判明した不足フィールドを追加中：顧客の税番号、ベトナム赤伝票の連番、AdminKPIView用のKPI目標、COGSレポート用のレシピBOM。（Per ＆ Phu）

**Việt**: Đang viết RLS policies đầy đủ cho 19 bảng (hiện chỉ có 1 policy mẫu) và kích hoạt Supabase Realtime publication cho các bảng cần realtime. (Per & Phu)
**日本語**: 19テーブル分の完全なRLSポリシーを作成中（現状はサンプル1本のみ）。Supabase Realtimeパブリケーションも有効化予定。（Per ＆ Phu）

---

## 4. Mục dự kiến làm tuần sau (23/06 → 27/06) ／ 来週実施予定の項目（6/23 → 6/27）

### 4.1 Hoàn tất Giai đoạn 1 ／ フェーズ1の完了

**Việt**: Hoàn thành khảo sát 3 team và đối chiếu vào tài liệu yêu cầu (`REQUIREMENTS.md` — sẽ tạo mới). (Ishii-san)
**日本語**: 3チームへのヒアリングを完了し、要件定義書（`REQUIREMENTS.md` — 新規作成）に反映。（石井さん）

**Việt**: Tổ chức buổi review tài liệu yêu cầu vào **26/06** (đúng theo lịch Plan mục 6.④). (Ishii-san chủ trì)
**日本語**: **6/26** に要件定義書レビュー会議を開催（計画書6.④に従う）。（石井さん主催）

**Việt**: Khảo sát khả năng xuất dữ liệu / API của F2Tech (ưu tiên hàng đầu theo rủi ro §2.3 của Plan). (Ishii-san phối hợp Per & Phu)
**日本語**: F2Techのデータエクスポート／API能力を調査（計画書2.3のリスク対応として最優先）。（石井さん、Per・Phuと連携）

### 4.2 Bắt đầu Giai đoạn 2 ／ フェーズ2の開始

**Việt**: Cài đặt `@supabase/supabase-js` và thay thế `mock-data.ts` bằng data layer thật (Supabase client + RLS). (Per & Phu)
**日本語**: `@supabase/supabase-js`を導入し、`mock-data.ts`を実データレイヤー（Supabaseクライアント + RLS）に置換。（Per ＆ Phu）

**Việt**: Hoàn thiện RLS policies cho 5 role, viết script seed data để chạy thử trên 1 chi nhánh mẫu. (Per & Phu)
**日本語**: 5ロール分のRLSポリシーを完成させ、1店舗分のシードデータ投入スクリプトを作成。（Per ＆ Phu）

**Việt**: Verify cấu hình phần cứng hiện tại (máy POS, máy in hóa đơn, két tiền) — mục §5.1 của Plan.
**日本語**: 既存ハードウェア（POS端末、レシートプリンタ、金庫）の構成確認 — 計画書5.1の項目。

---

## 5. Rủi ro & Cảnh báo ／ リスクと警告

**Việt**: ⚠️ Rủi ro cao: Nếu không hoàn thành khảo sát 3 team trước 26/06, Giai đoạn 2 sẽ phải thiết kế lại nhiều lần.
**日本語**: ⚠️ 高リスク：6/26までに3チームヒアリングが完了しない場合、フェーズ2で何度も再設計が発生する。

**Việt**: ⚠️ Rủi ro trung bình: Yêu cầu hóa đơn đỏ VN có thể phức tạp hơn dự kiến (Pháp luật Việt Nam — Nghị định 123/2020). Cần xác nhận sớm với kế toán.
**日本語**: ⚠️ 中リスク：ベトナム赤伝票の要件は予想より複雑な可能性あり（ベトナム法令 — 政令123/2020）。経理部門に早期確認が必要。

**Việt**: ✅ Giảm thiểu: Schema DB đã thiết kế xong sớm nên rủi ro "thiết kế lại" đã giảm đáng kể so với kế hoạch ban đầu.
**日本語**: ✅ 緩和策：DBスキーマを前倒しで完成済みのため、「再設計」リスクは当初計画より大幅に低下。

---

## 6. Đề xuất quyết định ／ 意思決定のお願い

**Việt**: Phê duyệt lịch phỏng vấn 3 team trong tuần 23–25/06 và cho phép Ishii-san đặt lịch trước với từng team.
**日本語**: 6/23〜25の3チームヒアリング日程の承認、および石井さんによる各チームへの事前アポイント許可をお願いします。

**Việt**: Chỉ định nhân sự cụ thể cho 3 vai trò theo mục 3 của Plan, để phân công nhiệm vụ tuần sau. → **Đã xác nhận: Ishii-san (PM + Xác định yêu cầu + Frontend), Per & Phu (Backend).**
**日本語**: 計画書3の3役割に具体的な人員を任命し、来週のタスク分担を可能にしてください。→ **確認済み：石井さん（PM＋要件定義＋フロントエンド）、Per ＆ Phu（バックエンド）。**

**Việt**: Xác nhận ngân sách 25 USD/tháng cho 5 chi nhánh đã được phê duyệt để chốt hạ tầng.
**日本語**: 5店舗向け月額25 USDの予算承認（インフラ確定のため）。

---

## 7. Phụ lục — Tài liệu tham chiếu ／ 付録 — 参考ドキュメント

| Tài liệu ／ ドキュメント | Mô tả ／ 説明 |
|---|---|
| `plan.md` | Kế hoạch tổng thể từ QUT Vietnam ／ QUTベトナム 全体計画書 |
| `docs/DATABASE_SCHEMA.sql` | Schema DB PostgreSQL ／ PostgreSQLスキーマ |
| `docs/DATABASE_DESIGN.md` | Lý giải thiết kế DB + ma trận phủ sóng ／ DB設計根拠＋カバレッジマトリクス |
| `docs/COST_ANALYSIS.md` | Phân tích chi phí 25 USD/tháng ／ 月額25 USDコスト分析 |
| `docs/BUSINESS_ANALYSIS.md` | Phân tích nghiệp vụ nhà hàng ／ 焼肉店業務分析 |
| `docs/DATABASE_SCHEMA_REVIEW.md` | Báo cáo rà soát schema ／ スキーマレビュー報告書 |
| `src/views/` | 26 màn hình prototype ／ 26画面のプロトタイプ |
| `src/lib/mock-data.ts` | Dữ liệu mẫu chuẩn schema ／ スキーマ準拠のサンプルデータ |

---

**Báo cáo kết thúc ／ レポート終了**
**Người lập / 作成者**: Ishii-san (PM + Xác định yêu cầu + Frontend) ／ 石井さん（PM＋要件定義＋フロントエンド）
**Ngày / 日付**: 2026-06-21
