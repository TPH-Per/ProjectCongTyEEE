# Báo cáo phiên làm việc — 21/07/2026 (Menu Management Module)

**Thành viên:** Ishii  
**Ngày:** Thứ Ba, 21/07/2026  
**Dự án:** POS Ngưu Cát (Vue 3 + TypeScript + Supabase + Pinia + Tailwind CSS)

---

## Tổng quan

Phiên làm việc tập trung xây dựng và mở rộng module **Quản lý Món** (Menu Management) cho phân hệ Reception.

| # | Công việc | Trạng thái |
|---|-----------|------------|
| 1 | Mô tả sidebar UI của `/reception` | ✅ Hoàn thành |
| 2 | Thêm link "Quản lý món" vào sidebar + đăng ký route | ✅ Hoàn thành |
| 3 | Thêm tính năng "Sao chép từ món có sẵn" | ✅ Hoàn thành |
| 4 | Thêm nút Back, View-All, PIN Protection, TEMP category | ✅ Hoàn thành |

---

## 1. Mô tả sidebar UI của `/reception`

### Mô tả

Research và mô tả cấu trúc sidebar trong `ReceptionLayout.vue` — layout cố định bên trái (w-64), gồm 5 nhóm menu.

### Cấu trúc sidebar phát hiện

| Nhóm | Items | Active-class |
|------|-------|-------------|
| HOẠT ĐỘNG | Bảng điều khiển | Đỏ (`bg-red-50 text-red-600`) |
| BÁN HÀNG | Chi tiết đặt, Chọn món, Sơ đồ bàn, Nhà hàng | Đỏ |
| NGHIỆP VỤ KHÁC | Thu khác, Chi khác, Cấu hình | Xám |
| QUẢN TRỊ | Phiếu, Báo cáo | Cam (`bg-orange-50 text-[#E8772E]`) |
| Ca làm việc | Tổng Kết Ca, Ra ca | Đỏ |

Footer: User profile card (avatar, tên, role) + dropdown "Đăng xuất".

### Files đọc

- `src/layouts/ReceptionLayout.vue`
- `src/components/reception/SidebarNavigation.vue` (component drawer riêng, không dùng trong layout)
- `src/locales/vi.ts`, `en.ts`, `ja.ts` (i18n keys)

---

## 2. Thêm "Quản lý món" vào sidebar + đăng ký route

### Bối cảnh

User cung cấp giải pháp toàn diện: cập nhật sidebar + chiến lược chia Module Quản lý Món thành 4 Phase. Khám phá codebase phát hiện module đã tồn tại đầy đủ:

| File | Trạng thái |
|------|-----------|
| `src/data/mockMenuData.ts` | ✅ 4 categories, 14 subcategories, 24 items, kitchen printers, tax/button options |
| `src/stores/menuManagementStore.ts` | ✅ Setup Store đầy đủ CRUD, soft-delete, copyItem, toggleSoldOut, broadcast event |
| `src/views/reception/MenuManagementView.vue` | ✅ 3-pane layout (Tree / Data Grid / Form 3 tabs) |
| `src/components/ToggleSwitch.vue` | ✅ Đã tồn tại |
| i18n `sidebar.menu_management` | ✅ Có trong vi/en/ja |

**Chỉ thiếu:** sidebar link + route registration.

### Files sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/layouts/ReceptionLayout.vue` | **Sửa** | Thêm `Coffee` icon import + `<RouterLink>` vào nhóm QUẢN TRỊ |
| `src/router/index.ts` | **Sửa** | Thêm child route `menu-management` |

### Chi tiết

**ReceptionLayout.vue:**
- Import `Coffee` từ `lucide-vue-next`
- Thêm `<RouterLink to="/reception/menu-management">` sau mục "Báo cáo"
- `active-class`: cam `bg-orange-50 text-[#E8772E]` — đồng nhất với các mục quản trị khác
- Label: `t('sidebar.menu_management')` (i18n key đã có sẵn)

**router/index.ts:**
- Route: `{ path: "menu-management", name: "reception-menu-management", component: MenuManagementView }`
- Meta: `{ requiresAuth: true, title: "Quản lý Món", fullscreen: true }`
- `MenuManagementView` đã được import sẵn ở đầu file

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~23s)

---

## 3. Thêm tính năng "Sao chép từ món có sẵn"

### Mô tả

Thêm ô chọn nhanh ở đầu form (chế độ "Thêm món" only) — chọn món có sẵn để tự động điền form, giảm thời gian nhập liệu.

### Thích nghi kiến trúc

Code mẫu dựa trên component khác (`MenuItemsManagement.vue` với modal). Component thực tế là `MenuManagementView.vue` — dùng form 3-pane (không modal). Thích nghi toàn bộ logic:

| Code mẫu | Thực tế |
|----------|---------|
| `showModal` / `editingItem` | `formMode` (`'create' \| 'edit' \| null'`) |
| `formData` là ref | `formData` là reactive object |
| `menuItems.value` | `store.items` + `store.getItemById()` |
| Modal HTML | Form ở cột phải (3-pane layout) |

### Files sửa

| File | Hành động |
|------|-----------|
| `src/views/reception/MenuManagementView.vue` | **Sửa** — 8 edits |

### Chi tiết thay đổi

**Template:**
- Khung màu xanh nhạt (`bg-blue-50 border-blue-200`) ở đầu form body, chỉ hiện khi `formMode === 'create'`
- Icon `Lightbulb` + label "Sao chép từ món có sẵn"
- `<select>` chọn món từ `store.items` + nút "Xóa" bên cạnh
- Option hiển thị: `{item.name} ({category.name})`

**Script:**
- Import `nextTick` từ vue + `Lightbulb` từ lucide-vue-next
- `templateItemId` ref — lưu ID món được chọn làm template
- `watch(templateItemId)` — khi chọn món:
  1. Deep-clone source item vào `formData`
  2. Reset `id = ''`, thêm `(Bản sao)` vào tên, `-COPY` vào SKU, xóa barcode
  3. Set `is_active = true`, `is_sold_out = false`
  4. Dùng `nextTick` khôi phục `sub_category_id` (bị watcher `category_id` reset)
- `clearTemplate()` — reset template + form về trắng, giữ pre-fill category từ selection hiện tại
- `startCreate()`, `startEdit()`, `cancelForm()` — thêm `templateItemId = ''` để reset

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~11s)

---

## 4. PIN Protection, Back Button, View-All, TEMP Category

### Mô tả

Thêm 4 tính năng vào `MenuManagementView.vue`:
1. Nút "Quay lại" dashboard
2. Toggle "Xem tất cả" món
3. PIN Manager cho CRUD (Save + Delete)
4. Danh mục tạm thời "chưa phân loại"

### Thích nghi kiến trúc

Code mẫu dùng modal + `@headlessui/vue` (không có trong project). Project đã có `ManagerAuthModal.vue` (dark theme, 6-digit PIN pad, reason dropdown, keyboard support). Tái sử dụng component này.

### Files sửa

| File | Hành động |
|------|-----------|
| `src/views/reception/MenuManagementView.vue` | **Sửa** — ~15 edits |

### 4.1. Nút "Quay lại" + "Xem tất cả"

**Header:**
- Nút "Quay lại" (icon `ArrowLeft`) → `router.push('/reception/dashboard')`
- Nút "Xem tất cả" (icon `LayoutGrid`) — toggle `showAllItems` ref
  - **ON**: Middle pane hiển thị tất cả món, thêm 2 cột **Danh mục** + **Danh mục con** (badge xanh/tím)
  - **OFF**: Lọc theo category đang chọn (hành vi gốc)
- Stats strip (đang bán / hết hàng / đã khóa / tổng) chuyển sang bên phải cạnh nút toggle

**Middle pane:**
- `filteredItems` computed: khi `showAllItems = true` → trả tất cả `store.items`; else giữ logic cũ
- Thêm cột header + body cell có điều kiện `v-if="showAllItems"`:
  - Cột Danh mục: badge xanh `bg-blue-100 text-blue-700` + icon category
  - Cột Danh mục con: badge tím `bg-purple-100 text-purple-700` hoặc `—`
- Nút "Thêm món" enable khi `showAllItems || selectedCategoryId` (thay vì chỉ `selectedCategoryId`)
- Empty state: thêm nhánh `showAllItems` riêng

### 4.2. PIN Protection (ManagerAuthModal)

**Import & state:**
- Import `ManagerAuthModal` từ `@/components/reception/ManagerAuthModal.vue`
- `showPinModal` ref, `pinAction` ref (`'save' | 'delete' | null`), `pendingDeleteId` ref

**Save flow:**
1. `saveForm()` — validate (name, category) → set `pinAction = 'save'` → `showPinModal = true`
2. `handlePinConfirm()` — đóng modal → gọi `doSave()`
3. `doSave()` — resolve TEMP category (nếu có) → `store.addItem()` hoặc `store.updateItem()` → toast → `cancelForm()`

**Delete flow:**
1. `handleDeleteItem()` — Swal confirm → set `pendingDeleteId` + `pinAction = 'delete'` → `showPinModal = true`
2. `handlePinConfirm()` — đóng modal → gọi `doDelete()`
3. `doDelete()` — `store.softDeleteItem()` → toast → `cancelForm()` nếu đang edit

**Template:**
- `<ManagerAuthModal>` ở cuối template, `v-if="showPinModal"`
- Props: `actionType` (`'VOID_ITEM'` cho xóa, `'EDIT_PRICE'` cho save), `targetName`
- Events: `@confirm="handlePinConfirm"`, `@close="showPinModal = false"`

### 4.3. Danh mục tạm thời (TEMP)

**Form category dropdown:**
- Thêm option `<option value="__temp__">📎 Danh mục chưa phân loại</option>` cuối danh sách
- Khi chọn `__temp__`: hiển thị ô input vàng nhạt (`bg-amber-50 border-amber-200`) để đề xuất tên danh mục mới
- `suggestedCategoryName` ref — lưu tên đề xuất

**`resolveTempCategory()` — xử lý khi save:**
1. Nếu có tên đề xuất → tìm category trùng tên (case-insensitive) → dùng luôn
2. Không tìm thấy → tạo category mới (`store.addCategory` với icon `📎`, color `#6B7280`)
3. Để trống → fallback về `cat-other` ("Khác")

**Reset:**
- `startCreate()`, `cancelForm()`, `clearTemplate()` — thêm `suggestedCategoryName = ''`

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~28s)

---

## Danh sách file tạo/sửa tổng hợp

| File | Hành động | Công việc |
|------|-----------|-----------|
| `src/layouts/ReceptionLayout.vue` | Sửa | Thêm sidebar link "Quản lý món" |
| `src/router/index.ts` | Sửa | Đăng ký route `/reception/menu-management` |
| `src/views/reception/MenuManagementView.vue` | Sửa | Copy template + Back/ViewAll/PIN/TEMP |

**Tất cả file đã tồn tại sẵn (không tạo mới):**
- `src/data/mockMenuData.ts` — 4 categories, 14 subcategories, 24 items
- `src/stores/menuManagementStore.ts` — Setup Store đầy đủ CRUD
- `src/components/reception/ManagerAuthModal.vue` — PIN modal dark theme
- `src/components/ToggleSwitch.vue` — Toggle switch component

---

## Ghi chú kỹ thuật

- **Không tạo file mới** — toàn bộ module (data, store, view) đã tồn tại, chỉ wire-up sidebar + route + mở rộng tính năng
- **Tái sử dụng `ManagerAuthModal`** thay vì tạo component PIN mới — dark theme, 6-digit PIN pad, keyboard support, reason dropdown
- **Không cài `@headlessui/vue`** — project dùng Vue `<Transition>` built-in + SweetAlert2
- **`nextTick`** để khôi phục `sub_category_id` sau khi watcher `category_id` reset
- **TEMP category resolution** — 3 tầng: tìm trùng tên → tạo mới → fallback `cat-other`
- Type-check và build đều pass clean sau mỗi batch thay đổi
