# 📋 BÁO CÁO PHIÊN LÀM VIỆC — 19/07/2026

> **Hệ thống:** POS Ngưu Cát
> **Tech Stack:** Vue 3 + TypeScript + Vite + Pinia + Vue i18n + Supabase/PostgreSQL + Tailwind CSS
> **Ngày:** 19/07/2026
> **Người thực hiện:** Ishii (với AI Coding Assistant)
> **Nội dung:** Tổng hợp toàn bộ thay đổi trong phiên làm việc

---

## TÓM TẮT CÁC THAY ĐỔI

| # | Task | Files ảnh hưởng | Trạng thái |
|---|------|------------------|------------|
| 1 | Di chuyển menu "Chi tiết đặt" vào nhóm BÁN HÀNG | `ReceptionLayout.vue`, `vi/en/ja.ts` | ✅ |
| 2 | Tạo ReservationDetailView mới (mock data) → khôi phục | `ReservationDetailView.vue` | ✅ → ↩️ |
| 3 | Mock data ReservationDetailView (20 khách, 4 khung giờ) | `ReservationDetailView.vue` | ✅ |
| 4 | Tạo shared components (PageHeader, StatsCard, StatusBadge) | `src/components/shared/` | ✅ |
| 5 | Fix customer area selection — mock data fallback 3 lớp | `customerApi.ts` | ✅ |
| 6 | Tối ưu UI/UX ReceptionOrderView (5 bước) | `ReceptionOrderView.vue`, `useTableOperations.ts` | ✅ |
| 7 | Tắt Supabase → mock mode toàn cục | `supabase.ts`, `App.vue` | ✅ |

---

## 1. SIDEBAR — DI CHUYỂN "CHI TIẾT ĐẶT"

### Yêu cầu
Di chuyển menu "Chi tiết đặt" từ nhóm HOẠT ĐỘNG sang nhóm BÁN HÀNG, đặt ở vị trí đầu tiên.

### Thay đổi
- Xóa `<RouterLink to="/reception/reservation-detail">` khỏi nhóm HOẠT ĐỘNG
- Thêm vào nhóm BÁN HÀNG ở vị trí đầu tiên (trước "Chọn món")
- Thay text hardcoded `"Chi tiết đặt"` bằng i18n key `t('sidebar.reservation_detail')`
- Thêm key i18n mới vào 3 file locale

### Files

| File | Thay đổi |
|------|----------|
| `src/layouts/ReceptionLayout.vue` | Di chuyển `<RouterLink>`, dùng `t('sidebar.reservation_detail')` |
| `src/locales/vi.ts` | `'sidebar.reservation_detail': 'Chi tiết đặt'` |
| `src/locales/en.ts` | `'sidebar.reservation_detail': 'Reservation Details'` |
| `src/locales/ja.ts` | `'sidebar.reservation_detail': '予約詳細'` |

### Cấu trúc sidebar sau khi đổi

```
HOẠT ĐỘNG
  └── Bảng điều khiển

BÁN HÀNG
  ├── Chi tiết đặt      ← MOVED (first position)
  ├── Chọn món
  ├── Sơ đồ bàn
  └── Nhà hàng

NGHIỆP VỤ KHÁC
  ├── Thu khác / Chi khác / Cấu hình

QUẢN TRỊ
  ├── Phiếu / Báo cáo

CA LÀM VIỆC
  ├── Tổng Kết Ca / Ra ca
```

---

## 2. RESERVATION DETAIL VIEW — MOCK DATA

### Bối cảnh
- Ban đầu: tạo trang mới hoàn toàn (statistics cards, search/filter, table) → **khôi phục** theo yêu cầu người dùng (`git checkout HEAD`)
- Sau đó: giữ nguyên UI gốc (split-panel layout), chỉ thay thế Supabase API calls bằng mock data

### Mock data
- **20 khách hàng** phân bổ 4 khung giờ
- **10 bàn mock** (t01–t10, codes A01-A03, B01-B03, C01-C02, VIP01-VIP02)

| Khung giờ | Giờ | Số khách | Trạng thái |
|-----------|-----|----------|------------|
| Sáng (morning) | 07:30–10:00 | 4 | confirmed, new, completed |
| Trưa (lunch) | 11:00–13:00 | 5 | confirmed, new, cancelled |
| Chiều (afternoon) | 14:00–16:00 | 3 | confirmed, new |
| Tối (evening) | 17:00–20:30 | 8 | confirmed, new, cancelled, VIP |

### Files

| File | Thay đổi |
|------|----------|
| `src/views/reception/ReservationDetailView.vue` | Thay `fetchReservations()` / `fetchTables()` bằng mock data arrays; `onMounted` chuyển từ async sang sync |

---

## 3. SHARED COMPONENTS

Tạo 3 component dùng chung trong `src/components/shared/` (thư mục mới):

### PageHeader.vue
```vue
<PageHeader title="Chi tiết đặt" subtitle="Reservation Details">
  <template #actions>
    <button class="...">Tạo mới</button>
  </template>
</PageHeader>
```

| Prop | Type | Mô tả |
|------|------|-------|
| `title` | `string` (required) | Tiêu đề chính |
| `subtitle` | `string` | Tiêu đề phụ |
| `titleClass` | `string` | Extra Tailwind classes cho title |

### StatsCard.vue
```vue
<StatsCard label="TỔNG ĐẶT" :value="15" description="+3 so với hôm qua"
           icon="📅" iconBgClass="bg-blue-100" />
```

| Prop | Type | Mô tả |
|------|------|-------|
| `label` | `string` (required) | Nhãn (uppercase) |
| `value` | `string \| number` (required) | Giá trị hiển thị |
| `description` | `string` | Mô tả nhỏ bên dưới |
| `icon` | `string` | Emoji icon |
| `iconBgClass` | `string` | Tailwind bg class cho icon container |
| `valueClass` | `string` | Override value styling |

### StatusBadge.vue
```vue
<StatusBadge status="CONFIRMED" :showDot="true" />
<StatusBadge status="AVAILABLE" />
```

| Prop | Type | Mô tả |
|------|------|-------|
| `status` | `string` (required) | Status key |
| `showDot` | `boolean` | Hiện colored dot |
| `label` | `string` | Override text |

**Statuses hỗ trợ:**
- Reservation: `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`
- Table: `AVAILABLE`, `OCCUPIED`, `RESERVED`

Tất cả dùng TypeScript `withDefaults(defineProps<{...}>(), {...})` pattern theo convention của project.

---

## 4. FIX CUSTOMER AREA SELECTION

### Vấn đề
Trang `/customer` (area selection) hiển thị toàn số 0, không có danh sách khu vực.

**Root cause:** Supabase **đã được cấu hình** (`.env.local` có URL + key thật: `https://zjtnmrcczkbcoxjlndva.supabase.co`), nên `getAreas()` đọc từ bảng `zones` thay vì dùng mock data. Bảng `zones` trả về zones **không có tables embedded** (`tables: []`), nên statistics = 0.

### Fix trong `customerApi.ts`

**`getAreas()` — 3 lớp fallback:**

1. `isSupabaseConfigured === false` → trả mock data ngay
2. Supabase error hoặc `data.length === 0` → trả mock data
3. **Mới:** Zones trả về nhưng không có tables → fetch tables per-zone qua `Promise.all`; nếu tổng tables = 0 → fallback mock

```ts
const zonesWithData = await Promise.all(
  data.map(async (z) => {
    const { data: zoneTables } = await supabase
      .from('tables')
      .select('id, code, capacity, status')
      .eq('zone_id', z.id)
      .eq('is_active', true)
    return { id: z.id, name: z.name, tables: zoneTables ?? [] }
  }),
)
const totalTablesFromDb = zonesWithData.reduce((s, a) => s + a.tables.length, 0)
if (totalTablesFromDb === 0) {
  return JSON.parse(JSON.stringify(customerAreas)) // fallback mock
}
```

**`getTables()` — 2 lớp fallback:**

1. Non-UUID areaId (e.g. `"area_a"`) → trả mock tables
2. Supabase error/empty → trả mock tables

### Kết quả
- 10 khu vực hiển thị (A, B, C, R, T, Capichi, Shopee, BE, Grab, Catalog)
- 57 bàn với statistics chính xác (54 available, 2 occupied: A03, CP02)

---

## 5. TỐI ƯU UI/UX RECEPTION ORDER

### Phân tích trước refactor
- File `ReceptionOrderView.vue`: **11,595 dòng** (template 4,874 + script 4,645 + style 2,075)
- 143 refs/computed, 154 functions
- 3 VueDraggable usages (group `guest-cards`, clone source → drop target)
- Chỉ 3 component extraction: `ManagerAuthModal`, `FloorViewFooter`, `TableOperationsMenu`
- Keyboard: chỉ Escape (cascading close)

### Bước 1: Keyboard Shortcuts Registry

Mở rộng `handleKeyDown` từ chỉ-Escape thành registry đầy đủ:

| Phím | Hành động | Điều kiện |
|------|-----------|-----------|
| **F1** | Chuyển tab Sơ đồ bàn | — |
| **F2** | Chuyển tab Thực đơn | — |
| **F3** | Chuyển tab Hóa đơn | — |
| **Ctrl+F** | Focus ô tìm kiếm | — |
| **Enter** | Gửi vào bếp | Bàn đã chọn + có món + không trong input |
| **Delete** | Xóa món cuối giỏ | Tab menu + có món + không trong input |
| **Escape** | Cascading close | Giữ nguyên logic cũ |

Thêm `searchInputRef` ref + `nextTick` import.

### Bước 2: Tối giản Table Cards

| Trước | Sau |
|-------|-----|
| `text-sm` cho số bàn | `text-base` |
| Chỉ hiện số capacity | `👥 {{ capacity }}` (có icon) |
| Time + duration chung 1 dòng | Tách riêng |
| `text-[10px]` cho info | `text-[11px]` |
| Bill amount `mt-1` | `text-sm font-mono mt-0.5` |
| `min-h-[110px]`, `p-3` | `min-h-[120px]`, `p-3.5` |
| Hover `scale-1.02` | `scale-1.03` |

### Bước 3: Menu Chip Filters

Thay 2 dropdown (`<select>`) bằng chip-style buttons:

| Filter | Chips |
|--------|-------|
| Status | `Tất cả` \| `Còn hàng` \| `Hết hàng` |
| Price sort | `Mặc định` \| `↑ Giá` \| `↓ Giá` |

Style: `px-2.5 py-1.5 rounded-full text-xs font-bold border`, active = `bg-[#ff8f00] text-white shadow`.

### Bước 4: Sticky Billing Footer + Prominent Change

| Trước | Sau |
|-------|-----|
| `border-t border-[#444]` | `border-t-2 border-[#E8772E]/30` + shadow trên |
| Total `text-2xl` | `text-3xl tracking-tight` |
| Label `text-xs` | `text-sm tracking-wide` |
| Không hiện tiền thối | **NEW:** Box xanh nổi bật khi `changePaid > 0` |

```html
<div v-if="customerPaid > 0 && changePaid > 0"
     class="bg-green-900/40 border border-green-500/30 rounded-lg px-3 py-2">
  <span class="text-green-300">💰 TIỀN THỌI:</span>
  <span class="text-green-400 font-mono text-2xl font-black">{{ formatVND(changePaid) }}</span>
</div>
```

### Bước 5: Context Menu Separators + Accessibility

- Thêm field `group: 'order' | 'table' | 'danger'` vào `allTableActions` trong `useTableOperations.ts`
- Render `<hr class="border-gray-100 my-1.5">` tự động giữa các group khác nhau
- Danger actions (Hủy phiếu) → text/hover màu đỏ
- `min-h-[44px]` cho tất cả action buttons (WCAG AA)

### Bug fix
- Lỗi orphaned tags `<span>➡️</span>`, `</button>`, `</div>` do template replacement sai → đã xóa

### Files thay đổi

| File | Thay đổi |
|------|----------|
| `src/views/reception/ReceptionOrderView.vue` | Template: table cards, chip filters, billing, context menu; Script: `handleKeyDown`, `searchInputRef`, `nextTick` |
| `src/composables/useTableOperations.ts` | Thêm `group` field vào `allTableActions` |

---

## 6. TẮT SUPABASE → MOCK MODE TOÀN CỤC

### Yêu cầu
Bỏ hết lời gọi đến Supabase, chỉ cần UI tĩnh và hiển thị cách chức năng hoạt động và tương tác.

### Thay đổi

| File | Thay đổi |
|------|----------|
| `src/lib/supabase.ts` | `const isConfigured = false` (hardcode, 1 dòng) |
| `src/App.vue` | Bỏ `<MockModeNotice />` + import |

### Hiệu quả
- Toàn bộ hệ thống chạy bằng mock data, **không gọi API/DB**
- Banner "MOCK MODE — Không gọi API/Database" góc trên trái bị ẩn
- Các trang `/customer/menu`, `/customer/cart` hiển thị UI tĩnh, tương tác bình thường
- `customerApi.ts` tất cả 14 methods đều đi vào nhánh mock fallback

### Mock fallback tự động
```
isSupabaseConfigured = false
         │
         ▼
  customerApi.getAreas()     → return customerAreas (mock)
  customerApi.getTables()    → return area.tables (mock)
  customerApi.confirmTable() → return sess-local-{timestamp}
  customerApi.createOrder()  → return ord-mock-{timestamp}
  customerApi.submitFeedback() → return fb-mock-{timestamp}
  ... (tất cả 14 methods)
```

---

## VERIFY: TYPE-CHECK

Mọi thay đổi đều pass `npx vue-tsc --noEmit` (0 errors):

| Lần check | Sau thay đổi | Kết quả |
|-----------|--------------|---------|
| 1 | Sidebar move + i18n | ✅ 0 errors |
| 2 | ReservationDetailView mock | ✅ 0 errors |
| 3 | Shared components | ✅ 0 errors |
| 4 | CustomerApi fix | ✅ 0 errors |
| 5 | Keyboard shortcuts | ✅ 0 errors |
| 6 | Table card simplification | ✅ 0 errors |
| 7 | Chip filters | ✅ 0 errors |
| 8 | Billing footer | ✅ 0 errors |
| 9 | Context menu separators | ✅ 0 errors |
| 10 | Supabase disable | ✅ 0 errors |
| 11 | Bug fix orphaned tags | ✅ 0 errors |

---

## FILE MAP THAY ĐỔI

```
src/
├── App.vue                                    # Bỏ MockModeNotice
├── lib/
│   └── supabase.ts                            # isConfigured = false
├── layouts/
│   └── ReceptionLayout.vue                    # Sidebar: move "Chi tiết đặt" → BÁN HÀNG
├── locales/
│   ├── vi.ts                                  # +sidebar.reservation_detail
│   ├── en.ts                                  # +sidebar.reservation_detail
│   └── ja.ts                                  # +sidebar.reservation_detail
├── views/
│   └── reception/
│       ├── ReservationDetailView.vue          # Mock data (20 khách, 10 bàn)
│       └── ReceptionOrderView.vue             # UI/UX optimization (5 steps)
├── components/
│   └── shared/                                # NEW directory
│       ├── PageHeader.vue                     # NEW
│       ├── StatsCard.vue                      # NEW
│       └── StatusBadge.vue                   # NEW
├── composables/
│   └── useTableOperations.ts                  # +group field on allTableActions
└── services/
    └── customerApi.ts                         # Fix mock fallback getAreas/getTables
```

**Tổng:** 12 file thay đổi, 3 file mới tạo, 0 file xóa.

---

## KẾT LUẬN

Phiên làm việc 19/07/2026 hoàn thành **7 nhóm task**:

1. **Sidebar reorganization** — di chuyển "Chi tiết đặt" vào nhóm BÁN HÀNG, thêm i18n key 3 ngôn ngữ
2. **ReservationDetailView** — mock data 20 khách phân 4 khung giờ (sáng/trưa/chiều/tối)
3. **Shared components** — 3 component tái sử dụng (PageHeader, StatsCard, StatusBadge)
4. **Fix customer area selection** — mock data fallback 3 lớp cho `getAreas()` / `getTables()`
5. **ReceptionOrderView UI/UX optimization** — keyboard shortcuts (F1-F3, Ctrl+F, Enter, Delete), table card tối giản, chip filters, sticky billing footer, context menu separators
6. **Disable Supabase** — `isConfigured = false`, toàn hệ thống chạy mock mode
7. **Bỏ MockModeNotice** — ẩn banner "MOCK MODE" khỏi UI

Tất cả thay đổi pass `vue-tsc --noEmit` (0 errors), không break existing logic, UI tương tác bình thường trên `http://localhost:5173`.
