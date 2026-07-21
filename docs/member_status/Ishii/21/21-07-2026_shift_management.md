# Báo cáo phiên làm việc — 21/07/2026 (Module Quản lý Ca)

**Thành viên:** Ishii  
**Ngày:** Thứ Ba, 21/07/2026  
**Dự án:** POS Ngưu Cát (Vue 3 + TypeScript + Supabase + Pinia + Tailwind CSS)

---

## Tổng quan

Xây dựng module Quản lý Ca làm việc (Shift Management) với 3 chức năng: Mở ca, Tổng kết ca, Đóng ca & Đối soát. Sử dụng mock data để test UI mà không cần API.

| # | Công việc | Trạng thái |
|---|-----------|------------|
| 1 | Tạo OpenShiftModal + CloseShiftModal + tích hợp Dashboard | ✅ |
| 2 | Tạo Pinia shiftStore + ShiftSummaryView + Manager PIN | ✅ |
| 3 | Sửa sidebar (3 mục rõ ràng) + Edge Function fallback | ✅ |
| 4 | Rewrite shiftStore mock data — bỏ API, dùng localStorage | ✅ |

---

## 1. Tạo modals Mở ca & Đóng ca (Task UI-3.1 + UI-3.2)

### Files tạo/sửa

| File | Hành động |
|------|-----------|
| `src/components/reception/OpenShiftModal.vue` | **Tạo mới** — Modal mở ca: input tiền đầu ca, validation, loading state |
| `src/components/reception/CloseShiftModal.vue` | **Tạo mới** — Modal đóng ca: bảng đối soát 3 phần, tính variance, đổi màu, bắt buộc ghi chú khi lệch |
| `src/views/reception/ReceptionDashboardView.vue` | **Sửa** — Tích hợp 2 modals, thay SweetAlert2 dialog, thêm computed revenue breakdown |

### Điểm khác so với prompt gốc

Prompt dùng `@headlessui/vue` (chưa cài), JS, inline SVG, `alert()`. Điều chỉnh theo convention: TypeScript, Vue `<Transition>`, `lucide-vue-next`, SweetAlert2, `useLanguageStore` i18n, màu brand `#E8772E`/`#1a5276`.

---

## 2. Pinia store + ShiftSummaryView + Manager PIN

### Files tạo/sửa

| File | Hành động |
|------|-----------|
| `src/stores/shiftStore.ts` | **Tạo mới** — Pinia store (Composition API): `currentShift`, `shiftPayments`, computed breakdown (cash/card/transfer/total/expectedCash), actions open/close/refresh |
| `src/views/reception/ShiftSummaryView.vue` | **Tạo mới** — Trang tổng kết: 4 overview cards, bảng doanh thu theo phương thức với %, 3 stats cards, nút "Đóng ca & Đối soát" |
| `src/components/reception/CloseShiftModal.vue` | **Sửa** — Thêm Manager PIN keypad (4 số) khi `|variance| > 100.000đ`, disable nút đóng ca cho đến khi PIN verified |
| `src/router/index.ts` | **Sửa** — Thêm route `/reception/shift-summary` |
| `src/layouts/ReceptionLayout.vue` | **Sửa** — Thêm sidebar link "Tổng kết ca" + import `ClipboardList` icon |
| `src/stores/useLanguageStore.ts` | **Sửa** — Thêm i18n keys `sidebar.shift`, `sidebar.shift_summary`, `sidebar.close_shift` (vi/en) |

---

## 3. Sửa sidebar + Edge Function fallback

### Vấn đề

Sidebar có 2 mục trùng (close_shift + exit_shift đều đi `/reception/close-shift`), không có "Mở ca", `exit_shift` trỏ `/shift/end` không tồn tại. Edge Function `open-shift` fail khi gọi.

### Fix sidebar — 3 mục rõ ràng

| Mục | Icon | Route |
|-----|------|-------|
| Mở ca | LockOpen | `/reception/shift-summary?action=open` |
| Tổng kết ca | ClipboardList | `/reception/shift-summary` |
| Ra ca | LogOut | `/reception/close-shift` |

### Fix Edge Function

`useShift.ts` — `openShift()` thêm fallback: thử Edge Function → nếu fail, thử `supabase.rpc('shift_open')` trực tiếp. `closeShift()` — error handling cải thiện cho business errors + network errors.

### Auto-open modal

`ShiftSummaryView.vue` — `watch` route query `?action=open`, tự động mở `OpenShiftModal` khi chưa có ca.

---

## 4. Rewrite shiftStore — mock data, không gọi API

### Vấn đề

Edge Function không khả dụng trong môi trường dev local → lỗi khi mở ca.

### Giải pháp

Rewrite `shiftStore.ts` hoàn toàn mock: không import `useShift` hay `supabase`. Dùng `localStorage` persist shift state.

### Mock data khi mở ca

7 payments: 4 cash (880k), 2 card (925k), 1 transfer (300k) → total 2.105.000đ. Expected cash = opening_cash + 880.000đ.

### Dashboard thay đổi

`ReceptionDashboardView.vue` — `activeShift`/`shiftPayments` chuyển từ `ref` sang `computed` từ `shiftStore`. `fetchActiveShift`/`fetchShiftPayments` delegate to store. `handleOpenShiftConfirm`/`handleCloseShiftConfirm` dùng `shiftStore.openShift()`/`closeShift()`. Bỏ `hall_get_active_shift` RPC khỏi `fetchAll()`.

---

## Danh sách file tổng hợp

| File | Hành động |
|------|-----------|
| `src/stores/shiftStore.ts` | Tạo mới → Rewrite (mock) |
| `src/components/reception/OpenShiftModal.vue` | Tạo mới |
| `src/components/reception/CloseShiftModal.vue` | Tạo mới → Enhance (Manager PIN) |
| `src/views/reception/ShiftSummaryView.vue` | Tạo mới |
| `src/views/reception/ReceptionDashboardView.vue` | Sửa (tích hợp modals + dùng shiftStore) |
| `src/layouts/ReceptionLayout.vue` | Sửa (sidebar 3 mục + import icons) |
| `src/router/index.ts` | Sửa (thêm route shift-summary) |
| `src/stores/useLanguageStore.ts` | Sửa (i18n keys vi/en) |
| `src/composables/useShift.ts` | Sửa (RPC fallback — không dùng khi mock mode) |

---

## Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors) sau mỗi thay đổi
- `vite build` — ✅ pass (~15s)

---

## Luồng test

1. Sidebar **Mở ca** → modal mở → nhập 5.000.000 → tạo mock shift (localStorage)
2. Dashboard hiện "Ca đang mở" + shift summary có 7 payments
3. **Tổng kết ca** → bảng doanh thu chi tiết + stats
4. **Đóng ca** (modal) → nhập actual cash → variance tính tự động → đổi màu → ghi chú bắt buộc nếu lệch → Manager PIN nếu > 100k
5. **Ra ca** → `/reception/close-shift` (trang kiểm đếm chi tiết mệnh giá)
6. F5 → shift vẫn giữ (localStorage)
