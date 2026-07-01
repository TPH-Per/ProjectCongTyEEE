# 💰 Phân Tích Chi Phí Vận Hành NGƯU CÁT — 25 USD/tháng
# 💰 NGƯU CÁT 運用コスト分析 — 月額 25 USD

> **Mục đích / 目的**: Giải thích tại sao dự án này hoàn toàn có thể vận hành ổn định với ngân sách chỉ **25 USD/tháng** trên Supabase Pro + Vercel Free Tier.
>
> このドキュメントは、Supabase Pro と Vercel Free プランで **月額 25 USD** という低予算で NGƯU CÁT プロジェクトを安定運用できる理由を説明するものです。

---

## 🇻🇳 Phần A — Tiếng Việt

### A1. Bối cảnh dự án

NGƯU CÁT là hệ thống quản lý nhà hàng (POS + booking + CRM + KPI) phục vụ 5 role:
- Admin / Manager / Reception (thu ngân) — Desktop
- Staff (nhân viên phục vụ) — Mobile
- Customer (khách tại bàn) — Tablet

**Quy mô dự kiến:**
- 1–3 chi nhánh ở giai đoạn đầu
- Khoảng 30–60 bàn / chi nhánh
- 50–200 lượt đặt bàn / ngày / chi nhánh
- 1–3 tablet / bàn (chỉ dùng khi khách ngồi)
- ~10–20 nhân viên / chi nhánh

### A2. Các hạng mục chi phí hàng tháng

| Hạng mục | Nhà cung cấp | Plan | Chi phí |
|---|---|---|---|
| **Database + Auth + Realtime + Storage** | Supabase | Pro | **25 USD/tháng** |
| **Hosting Frontend (Vue 3 SPA)** | Vercel | Hobby (Free) | 0 USD |
| **Domain** (tùy chọn) | Cloudflare | — | 10–12 USD/năm (~1 USD/tháng) |
| **Email SMTP** (gửi HĐ đỏ, thông báo) | Resend | Free tier (3,000 email/tháng) | 0 USD |
| **Tổng** | | | **~26 USD/tháng** |

> **Lưu ý quan trọng:** Ngân sách **25 USD/tháng** mà bạn đề cập là phí **Supabase Pro** (25 USD là mức cố định của Supabase Pro). Phần còn lại gần như miễn phí nếu đi đúng cách.

### A3. Tại sao Supabase Pro 25 USD là đủ?

#### 1. Supabase Pro bao gồm gì?

| Tài nguyên | Giới hạn Pro | Dự kiến dùng thực tế |
|---|---|---|
| **Database size** | 8 GB | ~500 MB – 2 GB (sau 6–12 tháng) |
| **Storage (ảnh menu, avatar)** | 100 GB | ~5–10 GB |
| **Bandwidth (Egress)** | 250 GB/tháng | ~10–30 GB/tháng |
| **Monthly Active Users** | 100,000 MAU | ~500–2,000 MAU |
| **Realtime connections** | 500 đồng thời | ~50–100 đồng thời |
| **Auth (Email/Password + OAuth)** | Không giới hạn | ~20 tài khoản nhân viên + khách QR |
| **Edge Functions** | 500,000 lời gọi/tháng | Dùng cho webhook báo cáo thuế |

#### 2. Tại sao quota này DƯ SỨC cho nhà hàng 1–3 chi nhánh?

**Phân tích từng tài nguyên:**

**a) Database (8 GB):**
- 1 reservation trung bình ~2 KB → 200 đặt/ngày × 30 ngày = 6,000 records/tháng = ~12 MB
- 1 order ~3 KB → ~600 orders/tháng/chi nhánh = ~2 MB
- Customer, table, menu: dữ liệu tĩnh, không phình
- Audit log: 10,000 records/tháng × 1 KB = 10 MB
- **Tổng dùng thực tế: 50–200 MB/năm → dùng thoải mái trong 5–10 năm**

**b) Realtime (500 connections):**
- Ngữ cảnh: 1 chi nhánh có 30 bàn → tối đa 30 tablet + 5 nhân viên mobile + 2–3 desktop = ~40 connections đỉnh điểm
- 3 chi nhánh dùng chung 1 project → ~120 connections đỉnh điểm
- **Dùng 24% quota → OK**

**c) Bandwidth (250 GB/tháng):**
- Mỗi tablet gọi món: ~50 KB/lần × 50 lần/ngày = 2.5 MB/tablet/ngày
- 30 tablet × 2.5 MB = 75 MB/ngày × 30 = ~2.25 GB/tháng
- Admin/Manager dashboard queries: ~5 GB/tháng
- Realtime subscription: ~2 GB/tháng
- **Tổng: ~10–15 GB/tháng → dùng 6% quota**

**d) Storage (100 GB):**
- Ảnh món ăn: ~50 món × 200 KB = 10 MB (lưu 1 lần, dùng mãi)
- Avatar nhân viên: 20 người × 100 KB = 2 MB
- Backup tự động của Supabase: ~200 MB
- **Tổng: ~500 MB – 2 GB → dùng 2% quota**

### A4. Tại sao Vercel Free Tier là đủ?

Vercel Hobby (Free) bao gồm:
- 100 GB bandwidth/tháng
- Unlimited static requests
- Serverless function execution: 100 GB-hours
- Auto SSL, CDN global

**Phân tích:**
- Frontend là Vue 3 SPA (Vite build) → chủ yếu là static HTML/CSS/JS
- Bundle size: ~500 KB (gzipped)
- 1,000 lượt truy cập/ngày × 500 KB = 500 MB/ngày × 30 = 15 GB/tháng
- **Dùng 15% quota → OK**

### A5. Các chi phí ẩn cần tránh

| Sai lầm phổ biến | Tác động chi phí | Cách tránh |
|---|---|---|
| Dùng Supabase Edge Function để làm việc có thể làm trên client | Tốn function calls không cần thiết | Tính toán aggregate đơn giản → dùng Postgres View + RLS |
| Upload ảnh gốc (5 MB) thay vì nén | Tốn bandwidth + storage | Nén ảnh xuống <500 KB trước khi upload, dùng `image-transform` của Supabase Storage |
| Subscribe Realtime không filter | Tốn connection slots | Subscribe theo `branchId` cụ thể, không subscribe toàn bộ table |
| Không dùng RLS, query trực tiếp `select *` | Tốn bandwidth vì trả về dữ liệu thừa | Bật RLS + dùng `select('id, name, status')` |
| Gọi API quá nhiều lần thay vì batch | Tốn request quota | Aggregate trong SQL View, frontend gọi 1 lần |

### A6. Khi nào cần scale lên plan cao hơn?

**Dấu hiệu cần upgrade Supabase Pro → Team (599 USD/tháng):**
- Database > 6 GB
- MAU > 80,000
- Realtime connections > 400 đồng thợi thời điểm
- Bandwidth > 200 GB/tháng

**Dấu hiệu cần tách DB riêng cho mỗi chi nhánh:**
- Trên 10 chi nhánh
- Mỗi chi nhánh có lưu lượng độc lập lớn

→ **Giai đoạn 1–3 chi nhánh (1–2 năm đầu): KHÔNG cần scale, 25 USD/tháng là dư sức.**

### A7. Kết luận

✅ **Supabase Pro 25 USD/tháng** đáp ứng đủ cho 1–3 chi nhánh vì:
- Database 8 GB gấp 40 lần nhu cầu thực tế
- Realtime 500 connections gấp 4 lần nhu cầu cao điểm
- Bandwidth 250 GB gấp 15 lần nhu cầu
- Storage 100 GB gấp 50 lần nhu cầu

✅ **Vercel Free Tier** đủ cho frontend Vue 3 SPA vì:
- Bandwidth 100 GB gấp 6 lần nhu cầu
- Auto CDN, SSL, scaling miễn phí

✅ **Tổng chi phí hosting: ~26 USD/tháng**, hoàn toàn nằm trong ngân sách 25 USD Supabase Pro + vài USD phụ phí.

---

## 🇯🇵 Phần B — 日本語

### B1. プロジェクトの背景

NGƯU CÁT は、5 つのロールに対応するレストラン管理システム（POS + 予約 + CRM + KPI）です:
- Admin / Manager / Reception（レジ） — デスクトップ
- Staff（ウェイター） — モバイル
- Customer（来店客） — タブレット

**想定規模:**
- 初期段階で 1〜3 店舗
- 1 店舗あたり 30〜60 テーブル
- 1 日 1 店舗あたり 50〜200 件の予約
- 1 テーブル 1〜3 タブレット（着席時のみ使用）
- 1 店舗あたり 10〜20 名のスタッフ

### B2. 月額コスト内訳

| 項目 | プロバイダー | プラン | 費用 |
|---|---|---|---|
| **データベース + 認証 + リアルタイム + ストレージ** | Supabase | Pro | **25 USD/月** |
| **フロントエンドホスティング（Vue 3 SPA）** | Vercel | Hobby（無料） | 0 USD |
| **ドメイン**（オプション） | Cloudflare | — | 10〜12 USD/年（約 1 USD/月） |
| **メール SMTP**（適格請求書、通知） | Resend | 無料枠（3,000 通/月） | 0 USD |
| **合計** | | | **約 26 USD/月** |

> **重要なポイント:** 月額 25 USD は **Supabase Pro の固定料金** です。残り 1 USD はドメイン代の目安です。

### B3. なぜ Supabase Pro 25 USD で十分なのか？

#### 1. Supabase Pro の内容

| リソース | Pro の上限 | 実際の使用見込み |
|---|---|---|
| **データベース容量** | 8 GB | 6〜12 ヶ月で 500 MB 〜 2 GB |
| **ストレージ（メニュー画像、アバター）** | 100 GB | 約 5〜10 GB |
| **帯域幅（Egress）** | 250 GB/月 | 約 10〜30 GB/月 |
| **月間アクティブユーザー（MAU）** | 100,000 MAU | 約 500〜2,000 MAU |
| **同時リアルタイム接続** | 500 | ピーク時 50〜100 |
| **認証（メール/パスワード + OAuth）** | 無制限 | スタッフ約 20 アカウント + QR ゲスト |
| **Edge Functions** | 500,000 呼び出し/月 | 税務レポート Webhook 用 |

#### 2. なぜ 1〜3 店舗に十分な量なのか

**リソースごとの分析:**

**a) データベース（8 GB）:**
- 1 予約平均 2 KB → 1 日 200 件 × 30 日 = 月 6,000 件 = 約 12 MB
- 1 注文 3 KB → 1 店舗月 600 件 = 約 2 MB
- 顧客、テーブル、メニュー: 静的データで肥大化なし
- 監査ログ: 月 10,000 件 × 1 KB = 10 MB
- **実使用量合計: 年 50〜200 MB → 5〜10 年快適に使用可能**

**b) リアルタイム（500 接続）:**
- 文脈: 1 店舗 30 テーブル → 最大 30 タブレット + 5 モバイルスタッフ + 2〜3 デスクトップ = ピーク約 40 接続
- 3 店舗で 1 プロジェクト共有 → ピーク約 120 接続
- **Quota の 24% 使用 → OK**

**c) 帯域幅（250 GB/月）:**
- タブレット 1 台あたり注文: 約 50 KB/回 × 1 日 50 回 = 2.5 MB/タブレット/日
- 30 タブレット × 2.5 MB = 75 MB/日 × 30 = 約 2.25 GB/月
- Admin/Manager ダッシュボードクエリ: 約 5 GB/月
- リアルタイム購読: 約 2 GB/月
- **合計: 約 10〜15 GB/月 → Quota の 6% 使用**

**d) ストレージ（100 GB）:**
- メニュー画像: 50 品 × 200 KB = 10 MB（1 回保存で永続使用）
- スタッフアバター: 20 名 × 100 KB = 2 MB
- Supabase 自動バックアップ: 約 200 MB
- **合計: 約 500 MB 〜 2 GB → Quota の 2% 使用**

### B4. なぜ Vercel Free Tier で十分なのか

Vercel Hobby（無料）に含まれるもの:
- 100 GB 帯域幅/月
- 無制限の静的リクエスト
- Serverless Function 実行: 100 GB-hours
- 自動 SSL、グローバル CDN

**分析:**
- フロントエンドは Vue 3 SPA（Vite ビルド）→ 主に静的 HTML/CSS/JS
- バンドルサイズ: 約 500 KB（gzip 圧縮後）
- 1 日 1,000 アクセス × 500 KB = 500 MB/日 × 30 = 15 GB/月
- **Quota の 15% 使用 → OK**

### B5. 避けるべき隠れたコスト

| よくある間違い | コストへの影響 | 回避方法 |
|---|---|---|
| クライアントで可能な処理に Supabase Edge Function を使う | 不要な Function 呼び出し | 単純な集計は Postgres View + RLS で行う |
| 元画像（5 MB）をそのままアップロード | 帯域幅とストレージを浪費 | アップロード前に 500 KB 以下に圧縮、Supabase Storage の `image-transform` を利用 |
| フィルタなしの Realtime 購読 | 接続スロットを浪費 | テーブル全体ではなく、特定の `branchId` で購読 |
| RLS を使わず `select *` で直接クエリ | 余分なデータで帯域幅を浪費 | RLS を有効化し、`select('id, name, status')` で必要な列だけ取得 |
| バッチ処理せず API を何度も呼ぶ | リクエスト Quota を浪費 | SQL View で集計し、フロントエンドは 1 回だけ呼び出す |

### B6. いつ上位プランにスケールアップすべきか

**Supabase Pro → Team（599 USD/月）へのアップグレードのサイン:**
- データベース使用量が 6 GB を超える
- MAU が 80,000 を超える
- ピーク時のリアルタイム接続が 400 を超える
- 帯域幅が月 200 GB を超える

**店舗ごとに DB を分離すべきサイン:**
- 10 店舗以上
- 各店舗が独立した大規模トラフィックを持つ

→ **1〜3 店舗段階（初期 1〜2 年）: スケール不要、月額 25 USD で余裕。**

### B7. 結論

✅ **Supabase Pro 月額 25 USD** が 1〜3 店舗に十分な理由:
- データベース 8 GB は実需要の 40 倍
- リアルタイム 500 接続はピーク需要の 4 倍
- 帯域幅 250 GB は需要の 15 倍
- ストレージ 100 GB は需要の 50 倍

✅ **Vercel Free Tier** が Vue 3 SPA フロントエンドに十分な理由:
- 帯域幅 100 GB は需要の 6 倍
- 自動 CDN、SSL、スケーリングが無料

✅ **ホスティング合計コスト: 月額約 26 USD** — Supabase Pro 25 USD + 少額の追加料金で予算内に収まる。

---

## 🇻🇳🇯🇵 Phần C — Bảng so sánh nhanh / 早見表

| Hạng mục / 項目 | Quota | Nhu cầu | Tỷ lệ dùng / 使用率 |
|---|---|---|---|
| Database / データベース | 8 GB | ~200 MB/năm | **2.5%** |
| Realtime / リアルタイム | 500 conn | ~120 conn | **24%** |
| Bandwidth / 帯域幅 | 250 GB/tháng | ~15 GB/tháng | **6%** |
| Storage / ストレージ | 100 GB | ~2 GB | **2%** |
| MAU | 100,000 | ~2,000 | **2%** |

→ **Trung bình dùng ~7% quota → còn dư 93% để scale / 平均使用率 7% → 残り 93% でスケール可能**

---

## 📌 Khuyến nghị triển khai / 実装の推奨事項

### 🇻🇳 Tiếng Việt
1. **Bắt đầu với Supabase Pro** (25 USD/tháng) — KHÔNG cần Team plan ở giai đoạn đầu
2. **Bật RLS ngay từ đầu** cho mọi bảng — tiết kiệm chi phí audit sau này
3. **Dùng Postgres View** cho các báo cáo phức tạp thay vì query nhiều bảng
4. **Realtime subscribe có filter** — không subscribe toàn bộ table
5. **Nén ảnh trước khi upload** lên Storage
6. **Tái sử dụng query layer** — cache kết quả ở client khi có thể

### 🇯🇵 日本語
1. **Supabase Pro（25 USD/月）から開始** — 初期段階では Team プランは不要
2. **最初からすべてのテーブルで RLS を有効化** — 後の監査コストを節約
3. **複雑なレポートは複数テーブルをクエリせず Postgres View を使用**
4. **Realtime 購読はフィルタ付き** — テーブル全体を購読しない
5. **Storage にアップロードする前に画像を圧縮**
6. **クエリ層を再利用** — 可能な場合はクライアント側で結果をキャッシュ

---

> **Tác giả / 作成者**: NGƯU CÁT Dev Team  
> **Cập nhật lần cuối / 最終更新日**: 2026-06-20  
> **Ngân sách tham chiếu / 参考予算**: 25 USD/tháng (Supabase Pro)
