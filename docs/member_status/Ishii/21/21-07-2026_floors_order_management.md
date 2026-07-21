# Báo cáo phiên làm việc — 21/07/2026 (Sơ đồ bàn & Quản lý Order)

**Thành viên:** Ishii  
**Ngày:** Thứ Ba, 21/07/2026  
**Dự án:** POS Ngưu Cát (Vue 3 + TypeScript + Supabase + Pinia + Tailwind CSS)

---

## Tổng quan

Phiên làm việc gồm 2 công việc chính:

| # | Công việc | Trạng thái |
|---|-----------|------------|
| 1 | Tạo trang Sơ đồ bàn mới (3-column + Drag & Drop + Timeline) | ✅ Hoàn thành |
| 2 | Thêm chức năng Quản lý Order với xác thực PIN Manager | ✅ Hoàn thành |

---

## 1. Tạo trang Sơ đồ bàn mới — ReceptionFloorsView

### Mô tả

Thay thế trang `/reception/floors` (trước đó dùng chung `AdminFloorsView.vue`) bằng component mới `ReceptionFloorsView.vue` — bố cục 3 cột hiện đại với drag & drop, timeline slider, và tô màu thông minh.

### Quyết định kiến trúc

Hỏi user → chọn các phương án:

| Câu hỏi | Quyết định |
|---------|------------|
| Approach | Tạo file mới riêng (`ReceptionFloorsView.vue`), tách khỏi `AdminFloorsView.vue` |
| Timeline | Hiển thị timeline ở `/reception/floors` (bật) |
| Data source | Reservations chưa gán bàn (real Supabase, không mock) |

### Files tạo/sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/views/reception/ReceptionFloorsView.vue` | **Tạo mới** | Component 3-column layout (~1970 dòng) |
| `src/router/index.ts` | **Sửa** | Đổi route `/reception/floors` sang lazy-import component mới |
| `src/locales/vi.ts` | **Sửa** | Thêm 12 key i18n `reception_floors.*` |
| `src/locales/en.ts` | **Sửa** | Thêm 12 key i18n `reception_floors.*` |
| `src/locales/ja.ts` | **Sửa** | Thêm 12 key i18n `reception_floors.*` |

### Tính năng implement

#### Bố cục 3 cột

| Cột | Chiều rộng | Nội dung |
|-----|-----------|----------|
| Trái | `lg:col-span-3` | Danh sách khách chờ xếp bàn (draggable cards) |
| Giữa | `lg:col-span-6` | Sơ đồ bàn (droppable zones) + Timeline slider |
| Phải | `lg:col-span-3` | Lịch + Bộ lọc ca + Tổng quan khu |

#### Timeline Slider

- Range: 11:00 → 22:00 (660–1320 phút), step 30 phút
- Hiển thị thời gian hiện tại + nút "Đặt lại"
- `checkConflicts()` — quét bookings, mark bàn có xung đột lịch (badge `⚠️ Đã đặt`)
- `inputTimelineTime` — input type=time đồng bộ 2 chiều với slider

#### Drag & Drop

- **Kéo đúng:** Bàn hợp lệ → viền cam (`ring-4`), overlay "+ Thả vào đây"
- **Kéo sai:** Bàn đang phục vụ / có xung đột → shake animation 0.4s + toast cảnh báo
- `handleDrop()` — cập nhật booking + table status, gọi `receptionAssignTable()` từ `useReceptionSync`
- Validation: kiểm tra sức chứa bàn trước khi gán

#### Tô màu thông minh (Table Color Coding)

| Trạng thái | Màu | Mô tả |
|------------|-----|-------|
| `Available` | Emerald | Trống / Sẵn sàng |
| `Reserved` | Amber | Đặt trước |
| `Arrived` | Blue | Đã đến |
| `Serving` | Rose | Đang phục vụ |
| `Maintenance` | Yellow | Bảo trì |
| Conflict (timeline) | Orange | Xung đột lịch (đè lên màu gốc) |

#### Modals (4 modal, port từ AdminFloorsView)

1. **Table Details** — đổi trạng thái, live bill (`hall_get_checkout_totals` RPC), duration ticker
2. **Create Booking** — customer info, time, guests, table assignment, quick tags
3. **Quick Open (Walk-in)** — chọn bàn trống + tên khách → mở phục vụ
4. **Quick Check-in** — chọn booking Waiting → mark Arrived

#### Footer

- Đồng hồ hệ thống (1s khi modal mở, 30s khi idle)
- Thống kê bàn/ghế trống, tổng hẹn, check-in, chờ bàn
- 3 nút hành động: Hiện tại, Đón Khách Đến, Khai Bàn Nhanh, + Đặt Bàn

#### Reuse composables

- `useAuth` — branchId, profile
- `useCheckout` — `previewTableSummary`, `clearTableCache`
- `useRealtime` — `watchTable` (orders, order_items)
- `useUnsavedGuard` — dirty check cho table modal, quick open modal
- `useReceptionSync` — shared reservation state (sync với ReservationDetailView)

#### Bug fix trong phiên

1. **`Cannot access 'selectedTableForModal' before initialization`** — `watch()` và `watchTable()` tham chiếu `selectedTableForModal` trước khi khai báo → di chuyển xuống sau `const selectedTableForModal`
2. **`zone.name` → `zone.value`** — TypeScript error trong template `v-for` key (zone object dùng `label`/`value`, không phải `name`)

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~29s)
- Screenshot Playwright — ✅ 3-column layout render đúng, timeline slider hiện, footer đầy đủ

---

## 2. Thêm chức năng Quản lý Order với xác thực PIN Manager

### Mô tả

Thêm nút "Quản lý Order" vào trang `/reception/order`, mở UI toàn màn hình hiển thị tất cả order, cho phép hủy order với xác thực PIN Manager (6 số).

### Files tạo/sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/components/reception/OrderManagementModal.vue` | **Tạo mới** | Full-screen modal dark theme (~280 dòng) |
| `src/views/reception/ReceptionOrderView.vue` | **Sửa** | Import + tích hợp modal, thêm state, cancel logic |

### Tính năng implement

#### OrderManagementModal.vue

- **Header** — title "Quản lý Order", tổng order count, nút "Làm mới"
- **Filters** — search (mã order, bàn, khách) + dropdown trạng thái (Pending/Preparing/Served/Paid/Cancelled)
- **Order cards** — grid 3 cột, mỗi card hiển thị:
  - Mã order (`order_number`)
  - Bàn (`tables.code` qua Supabase join)
  - Danh sách items (quantity × name + line_total)
  - Tổng tiền (format VND)
  - Status badge (màu theo trạng thái)
  - Thời gian tạo
- **Nút "Hủy Order"** — chỉ hiển thị cho orders chưa Cancelled/Paid
- **Empty state** — icon 📭 + "Không tìm thấy order nào"
- **Data loading** — Supabase query: `orders` + `order_items` + `tables` join, limit 200, sort by `created_at` desc

#### Tích hợp vào ReceptionOrderView.vue

- Thêm nút "📋 Quản lý Order" vào more-dropdown menu (☰ → ⋮)
- `showOrderManagement` ref + `orderManagementRef` (cho reload)
- `handleCancelOrder(order)` — luồng hủy:
  1. Gọi `requestManagerAuth("CANCEL_BILL", order.order_number, callback)`
  2. `ManagerAuthModal` hiện lên (PIN 6 số + dropdown lý do)
  3. Manager nhập PIN + chọn lý do → callback:
     - `supabase.from('orders').update({ status: 'Cancelled', notes: ... })`
     - Toast success → `orderManagementRef.loadOrders()` reload danh sách
  4. Lỗi → toast error

#### Reuse ManagerAuthModal (đã có sẵn)

Không tạo modal PIN mới — dùng `ManagerAuthModal.vue` hiện có (dark theme, PIN pad 6 chấm, dropdown 8 lý do, keyboard vật lý). Component này đã được dùng cho:
- Hủy món trong `ReceptionOrderView.vue`
- Hủy phiếu trong `ReservationDetailView.vue`
- Void/Cancel trong `ReportsView.vue`

### Verification

- `vite build` — ✅ pass (built in ~29s)
- Screenshot Playwright — ✅ modal mở full-screen, header + search + filter + empty state hiển thị đúng

---

## Danh sách file tạo/sửa tổng hợp

| File | Hành động | Công việc |
|------|-----------|-----------|
| `src/views/reception/ReceptionFloorsView.vue` | Tạo mới | Sơ đồ bàn 3-column |
| `src/components/reception/OrderManagementModal.vue` | Tạo mới | Quản lý Order modal |
| `src/router/index.ts` | Sửa | Lazy-import ReceptionFloorsView |
| `src/views/reception/ReceptionOrderView.vue` | Sửa | Tích hợp OrderManagementModal |
| `src/locales/vi.ts` | Sửa | 12 key i18n `reception_floors.*` |
| `src/locales/en.ts` | Sửa | 12 key i18n `reception_floors.*` |
| `src/locales/ja.ts` | Sửa | 12 key i18n `reception_floors.*` |

---

## i18n keys mới

| Key | vi | en | ja |
|-----|----|----|-----|
| `reception_floors.waiting_title` | Khách chờ xếp bàn | Waiting for table | テーブル待ち |
| `reception_floors.drag_hint` | Kéo thả vào bàn trống | Drag to empty table | 空席にドラッグ |
| `reception_floors.drag_handle` | ⋮⋮ Kéo | ⋮⋮ Drag | ⋮⋮ ドラッグ |
| `reception_floors.timeline_label` | Xem lịch theo giờ | View by time | 時間別表示 |
| `reception_floors.drop_here` | + Thả vào đây | + Drop here | + ドロップ |
| `reception_floors.conflict_badge` | ⚠️ Đã đặt | ⚠️ Booked | ⚠️ 予約済 |
| `reception_floors.reset` | Đặt lại | Reset | リセット |
| `reception_floors.all_assigned` | ✅ Tất cả khách đã được xếp bàn | ✅ All customers assigned | ✅ 全員割り当て済み |
| `reception_floors.invalid_drop` | Không thể xếp bàn... | Cannot assign... | 割り当て不可... |
| `reception_floors.assign_success` | Đã xếp bàn thành công | Table assigned successfully | テーブル割り当て成功 |
| `reception_floors.zone_summary` | Tổng quan ca theo khu | Shift overview by zone | ゾーン別シフト概要 |

---

## Ghi chú kỹ thuật

- **Không cài thêm dependency mới** — dùng toàn bộ composables, components có sẵn
- **Tuân thủ convention** — dark theme (order page), light theme (floors page), SweetAlert2, Tailwind CSS, i18n 3 ngôn ngữ
- **`/admin/floors` không bị ảnh hưởng** — vẫn dùng `AdminFloorsView.vue` như cũ
- **`ManagerAuthModal` reused** — không tạo modal PIN mới, dùng pattern `requestManagerAuth` + callback có sẵn
- **Supabase join query** — `orders` → `tables(code)` + `order_items(id, name_snapshot, quantity, line_total)` trong 1 query
- **Realtime watchers** — `watchTable('orders')` + `watchTable('order_items')` invalidate bill cache khi có thay đổi
- Type-check và build đều pass clean
