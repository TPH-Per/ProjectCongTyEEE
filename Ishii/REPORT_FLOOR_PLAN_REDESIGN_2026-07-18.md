# BÁO CÁO: TÁI THIẾT KẾ GIAO DIỆN SƠ ĐỒ BÀN (NO-SCROLL)
# フロアプラン画面リデザイン報告書（スクロール不要レイアウト）

> **Người lập / 作成者**: Codely CLI (AI Assistant)
> **Ngày lập / 作成日**: 18/07/2026
> **URL mục tiêu / 対象URL**: `http://localhost:5173/reception/floors`
> **File chỉnh sửa / 修正ファイル**: `src/views/admin/AdminFloorsView.vue`

---

## 1. Mục tiêu ／ 目的

**Việt**: Tái thiết kế giao diện Sơ đồ bàn & Đặt chỗ (`/reception/floors`) để hiển thị TẤT CẢ thông tin trên 1 màn hình không cần scroll, tối ưu cho màn hình desktop 1920×1080.

**日本語**: フロアプラン画面（`/reception/floors`）をスクロール不要で全情報を1画面に表示するようリデザイン。デスクトップ 1920×1080 に最適化。

### Yêu cầu chính ／ 主要要件

| # | Yêu cầu ／ 要件 | Trạng thái ／ ステータス |
|---|---|---|
| 1 | Không cần scroll — tất cả fit trong 1 màn hình ／ スクロール不要 — 全画面収容 | ✅ Hoàn thành ／ 完了 |
| 2 | Compact layout — tận dụng tối đa không gian ／ コンパクトレイアウト — スペース最大活用 | ✅ Hoàn thành ／ 完了 |
| 3 | Thông tin đầy đủ — Tables, Calendar, Reservation, Zone Summary, Footer ／ 全情報表示 | ✅ Hoàn thành ／ 完了 |
| 4 | Giữ nguyên toàn bộ logic nghiệp vụ ／ 業務ロジック完全保持 | ✅ Hoàn thành ／ 完了 |

---

## 2. Phân tích trước khi sửa ／ 修正前の分析

### 2.1 File mục tiêu ／ 対象ファイル

**Việt**: Route `/reception/floors` sử dụng component `AdminFloorsView.vue` (file 3595 dòng), dùng chung cho cả `/admin/floors` và `/reception/floors`.

**日本語**: ルート `/reception/floors` は `AdminFloorsView.vue`（3595行）を使用。`/admin/floors` と `/reception/floors` の両方で共通利用。

### 2.2 Vấn đề trước khi sửa ／ 修正前の問題点

| Vấn đề ／ 問題 | Mô tả ／ 説明 |
|---|---|
| **Scroll dọc bắt buộc** ／ **縦スクロール必須** | Root container dùng `min-h-screen` + `pb-28` (padding lớn để chừa chỗ cho fixed bar) ／ ルートが `min-h-screen` + `pb-28` を使用し縦スクロール必須 |
| **Fixed bottom action bar** ／ **固定フッターバー** | Action bar dùng `fixed bottom-0 left-64`, che nội dung, cần padding để bù trừ ／ アクションバーが `fixed` で内容を隠し、パディングで補正が必要 |
| **Card kích thước lớn** ／ **カードサイズ大** | Table cards `h-24` (96px), grid chỉ 4 cột, gap `3` (12px) — lãng phí không gian ／ テーブルカード `h-24`（96px）、4列のみ、ギャップ12px — スペース無駄遣い |
| **Border radius lớn** �／ **角丸过大** | Nhiều phần dùng `rounded-3xl` (24px) + `p-4` — chiếm nhiều không gian thừa ／ 多くの箇所で `rounded-3xl`（24px）+ `p-4` を使用 — 余分なスペース消費 |
| **Calendar/Reservation** | `min-h-[580px]` cố định + `max-h-[300px]` cho list — không linh hoạt ／ 固定 `min-h-[580px]` + リスト `max-h-[300px]` — 柔軟性なし |

### 2.3 Logic cần bảo toàn ／ 保持すべきロジック

**Việt**: File chứa logic nghiệp vụ phức tạp, tất cả phải được giữ nguyên:
- Tải dữ liệu Supabase (tables, reservations, customers)
- Simulated time (chế độ admin) / real-time clock (chế độ reception)
- 9 modals: Table Details, Create/Edit Booking, Quick Open, Quick Arrived, Booking Details, Assign Table, Create Table, Edit Table, Maintenance
- Realtime watchers (orders, order_items)
- Zone filtering, shift filtering, search
- RPC `hall_get_checkout_totals` cho live bill total
- Mock login support

**日本語**: 以下の複雑な業務ロジックをすべて保持：
- Supabaseデータ取得（テーブル、予約、顧客）
- シミュレート時間（adminモード）／ リアルタイム時計（receptionモード）
- 9つのモーダル：テーブル詳細、予約作成/編集、クイックオープン、クイック到着、予約詳細、テーブル割当、テーブル作成、テーブル編集、メンテナンス
- リアルタイム監視（orders、order_items）
- ゾーン絞り込み、シフト絞り込み、検索
- RPC `hall_get_checkout_totals` によるリアルタイム請求額
- モックログイン対応

---

## 3. Chi tiết thay đổi ／ 修正詳細

### 3.1 Bảng tổng hợp thay đổi ／ 変更一覧表

| Khu vực ／ エリア | Trước ／ 修正前 | Sau ／ 修正後 | Mục đích �／ 目的 |
|---|---|---|---|
| **Root container** | `min-h-screen` + `pb-28` + `gap-4` | `h-full` + `overflow-hidden` + `gap-1.5` | Loại bỏ scroll, fill viewport ／ スクロール廃止、画面全体に収容 |
| **Header** | `text-2xl` + `pb-3` + `gap-2` | `text-lg` + `pb-1.5` + `gap-1.5` | Giảm chiều cao header ／ ヘッダー高さ削減 |
| **Status Legend** | `px-2.5 py-1` + `rounded-xl` | `px-2 py-0.5` + `rounded-lg` | Badge nhỏ gọn hơn ／ バッジコンパクト化 |
| **Time Simulation** | `rounded-2xl p-3 gap-4` | `rounded-xl p-2 gap-2` | Panel gọn hơn ／ パネル縮小 |
| **Zone Nav Bar** | `rounded-2xl p-2 gap-3` | `rounded-xl p-1.5 gap-2` | Toolbar gọn hơn ／ ツールバー縮小 |
| **Main Grid** | `grid-cols-10 gap-4 items-start` | `grid-cols-10 gap-2 flex-1 min-h-0 overflow-hidden` | Fill không gian, nội bộ scroll ／ 領域全体活用、内部スクロール |
| **Table Grid** | `grid-cols-4` + `gap-3` + `h-24` | `grid-cols-5` + `gap-2` + `h-[80px]` | Thêm 1 cột, card nhỏ hơn ／ 1列追加、カード縮小 |
| **Table Card** | `rounded-xl p-3` + `text-base` | `rounded-lg p-1.5` + `text-sm` | Card compact ／ カードコンパクト化 |
| **Right Panel** | `rounded-3xl p-4 min-h-[580px]` | `rounded-xl p-2.5 flex-1 overflow-hidden` | Co giãn theo viewport ／ ビューポート追従 |
| **Calendar** | `rounded-xl p-2.5` + `h-6` cells | `rounded-lg p-1.5` + `h-5` cells | Calendar gọn hơn ／ カレンダー縮小 |
| **Reservation List** | `max-h-[300px]` cố định | `flex-1 min-h-0` (co giãn) | Tự động fill không gian ／ 自動フィル |
| **Reservation Card** | `rounded-xl p-3 gap-1.5` | `rounded-lg p-2 gap-1` | Card đặt bàn gọn hơn ／ 予約カード縮小 |
| **Zone Summary** | `rounded-3xl p-4 gap-2.5` | `rounded-xl p-2 gap-1.5` | Summary bar gọn hơn ／ サマリー縮小 |
| **Action Bar** | `fixed bottom-0 left-64 py-3.5 px-6` | `border-t py-1.5 px-3 shrink-0` | Chuyển từ fixed → flex footer ／ 固定→フレックスフッター |
| **Action Buttons** | `flex-1 py-2.5 text-xs rounded-xl` | `px-2.5 py-1.5 text-[10px] rounded-lg` | Nút nhỏ gọn, không giãn full ／ ボタン縮小 |

### 3.2 Các thay đổi chi tiết ／ 詳細変更内容

#### 3.2.1 Root Container — Loại bỏ scroll

**Việt**: Đổi từ `min-h-screen` (chiều cao tối thiểu = màn hình, gây scroll khi nội dung dài) sang `h-full` (chiều cao = viewport cha) + `overflow-hidden` (ẩn scroll ngoài cùng). Nội dung bên trong dùng flex column, các vùng cần scroll riêng sẽ tự xử lý.

**日本語**: `min-h-screen`（最小高さ=画面、内容が長いとスクロール発生）から `h-full`（親ビューポートと同じ高さ）+ `overflow-hidden`（外側スクロール非表示）に変更。内部はフレックスカラム、スクロールが必要な領域は個別処理。

```html
<!-- Before -->
<div class="p-4 max-w-[1600px] mx-auto flex flex-col gap-4 pb-28 min-h-screen">

<!-- After -->
<div class="h-full flex flex-col gap-1.5 overflow-hidden">
```

#### 3.2.2 Main Content — Flex-1 + Internal Scroll

**Việt**: Grid chính đổi từ `items-start` (không fill) sang `flex-1 min-h-0 overflow-hidden` (fill không gian còn lại, nội bộ tự scroll). Bảng bàn và panel phải đều dùng `flex-1` để co giãn.

**日本語**: メイングリッドを `items-start` から `flex-1 min-h-0 overflow-hidden` に変更。テーブルグリッドと右パネル共に `flex-1` で伸縮。

#### 3.2.3 Action Bar — Fixed → Flex Footer

**Việt**: Đây là thay đổi quan trọng nhất. Trước đây action bar dùng `fixed bottom-0 left-64` (vị trí cố định, che nội dung, cần `pb-28` padding để bù). Giờ đổi thành flex footer bình thường với `shrink-0`, tự nhiên nằm cuối flex column, không che nội dung, không cần padding bù trừ.

**日本語**: 最も重要な変更。アクションバーを `fixed bottom-0 left-64`（固定位置、内容を隠す、`pb-28` で補正必要）から通常のフレックスフッター `shrink-0` に変更。自然にフレックスカラム末尾に配置、内容を隠さず、補正パディング不要。

#### 3.2.4 Table Cards — Tăng mật độ

**Việt**: Tăng từ 4 cột lên 5 cột (hiển thị thêm bàn mỗi hàng), giảm chiều cao card từ 96px → 80px, giảm gap từ 12px → 8px, giảm padding từ 12px → 6px. Kết quả: ~25% nhiều bàn hơn hiển thị cùng lúc.

**日本語**: 4列から5列に増加（1行の表示卓数アップ）、カード高さ 96px→80px、ギャップ 12px→8px、パディング 12px→6px。結果：同時表示卓数約25%アップ。

---

## 4. Kết quả kiểm chứng ／ 検証結果

### 4.1 Type-check

```
Command: npx vue-tsc --noEmit
Result: Exit code 0 — No errors
```

**Việt**: Kiểm tra kiểu dữ liệu TypeScript pass, không có lỗi.

**日本語**: TypeScript型チェック合格、エラーなし。

### 4.2 Screenshot kiểm tra layout ／ スクリーンショット検証

**Việt**: Chụp screenshot tại viewport 1920×1080, xác nhận:
- ✅ Tất cả section hiển thị trong 1 màn hình (header, table grid, calendar, reservation list, zone summary, action bar)
- ✅ Không cần scroll
- ✅ Không có text bị cắt (sau khi tăng card height từ 72px → 80px)
- ✅ Action bar (Đón Khách, Khai Bàn, Đặt Bàn) hiển thị đầy đủ
- ✅ Zone summary dashboard hiển thị đầy đủ 10+ khu vực

**日本語**: 1920×1080ビューポートでスクリーンショット撮影、確認事項：
- ✅ 全セクション1画面表示（ヘッダー、テーブルグリッド、カレンダー、予約リスト、ゾーンサマリー、アクションバー）
- ✅ スクロール不要
- ✅ テキスト切り抜けなし（カード高さ 72px→80px に修正後）
- ✅ アクションバー（お客様出迎え、テーブル開設、予約）完全表示
- ✅ ゾーンサマリーダッシュボード10+エリア完全表示

### 4.3 Logic bảo toàn ／ ロジック保持確認

| Logic ／ ロジック | Trạng thái ／ ステータス |
|---|---|
| Supabase data loading ／ Supabaseデータ取得 | ✅ Không thay đổi ／ 変更なし |
| 9 modals (Table, Booking, Quick Open, v.v.) ／ 9モーダル | ✅ Không thay đổi ／ 変更なし |
| Simulated time (admin) / Real-time clock (reception) ／ シミュレート時間 | ✅ Không thay đổi ／ 変更なし |
| Realtime watchers (orders, order_items) ／ リアルタイム監視 | ✅ Không thay đổi ／ 変更なし |
| Zone/shift/search filtering ／ ゾーン/シフト/検索絞り込み | ✅ Không thay đổi ／ 変更なし |
| RPC hall_get_checkout_totals ／ RPC請求額取得 | ✅ Không thay đổi ／ 変更なし |
| Edit mode (create/edit/delete/lock tables) ／ 編集モード | ✅ Không thay đổi ／ 変更なし |
| Mock login support ／ モックログイン対応 | ✅ Không thay đổi ／ 変更なし |

---

## 5. Kích thước tối thiểu hỗ trợ ／ サポート最小サイズ

| Thiết bị ／ デバイス | Kích thước ／ サイズ | Trạng thái ／ ステータス |
|---|---|---|
| Desktop (tối ưu) ／ デスクトップ（最適） | 1920×1080 | ✅ Fit hoàn toàn ／ 完全収容 |
| Laptop ／ ラップトップ | 1366×768 | ⚠️ Có scroll nhẹ ở table grid ／ テーブルグリッドに軽微スクロール |
| Tablet Landscape ／ タブレット横 | 1024×768 | ⚠️ Scroll cần thiết ／ スクロール必要 |

**Việt**: Tối ưu nhất cho màn hình 1920×1080 (màn hình lễ tân tiêu chuẩn). Màn hình nhỏ hơn sẽ có scroll nhẹ trong vùng table grid (đã có overflow-y-auto nội bộ).

**日本語**: 1920×1080（標準受付モニター）に最適。より小さい画面ではテーブルグリッド内で軽微なスクロールあり（内部 `overflow-y-auto` 設定済み）。

---

## 6. Rủi ro & Lưu ý ／ リスクと注意事項

### 6.1 Rủi ro ／ リスク

| Rủi ro ／ リスク | Mức độ ／ レベル | Giải pháp ／ 対策 |
|---|---|---|
| Reservation list dài (nhiều đặt bàn) ／ 予約リスト長大 | Thấp ／ 低 | Đã có `overflow-y-auto` nội bộ ／ 内部 `overflow-y-auto` 設置済み |
| Zone summary quá nhiều khu vực ／ ゾーンサマリー多数 | Thấp ／ 低 | Grid tự wrap, dùng `grid-cols-11` max ／ グリッド自動折返し |
| Màn hình nhỏ (<1366px) ／ 小画面 | Trung bình ／ 中 | Table grid có scroll nội bộ ／ テーブルグリッド内部スクロール |

### 6.2 Lưu ý ／ 注意事項

**Việt**:
- Tất cả thay đổi chỉ nằm trong phần `<template>`, không động vào `<script setup>` — đảm bảo logic 100% giữ nguyên.
- File `AdminFloorsView.vue` dùng chung cho `/admin/floors` và `/reception/floors`. Layout mới áp dụng cho cả 2 route.
- Mode simulation (chỉ hiển thị ở `/admin/floors`) vẫn hoạt động bình thường.

**日本語**:
- すべての変更は `<template>` 内のみ。`<script setup>` は完全保持 — ロジック100%維持。
- `AdminFloorsView.vue` は `/admin/floors` と `/reception/floors` で共通利用。新レイアウトは両ルートに適用。
- シミュレーションモード（`/admin/floors` のみ表示）は正常動作。

---

## 7. Kết luận ／ 結論

**Việt**: Đã hoàn thành tái thiết kế giao diện Sơ đồ bàn (`/reception/floors`) theo yêu cầu: **không cần scroll, compact, đầy đủ thông tin**. Toàn bộ logic nghiệp vụ được bảo toàn 100%. Layout tối ưu cho màn hình 1920×1080. Type-check pass, screenshot xác nhận layout đúng.

**日本語**: フロアプラン画面（`/reception/floors`）のリデザインを完了：**スクロール不要、コンパクト、全情報表示**。業務ロジック100%保持。1920×1080に最適化。型チェック合格、スクリーンショットでレイアウト確認済み。

---

*Báo cáo lập bởi Codely CLI — 18/07/2026*
*報告書作成：Codely CLI — 2026/07/18*
