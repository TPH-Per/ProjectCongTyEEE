# 📋 TỔNG HỢP UI & FLOW MÀN HÌNH KHÁCH HÀNG (/customer)

> **URL:** `http://localhost:5173/customer`  
> **Ngày tạo:** 19/07/2026  
> **Tech Stack:** Vue 3 + TypeScript + Vite + Pinia + Vue i18n + Supabase/PostgreSQL  
> **Layout:** `src/layouts/CustomerLayout.vue`  
> **Theme:** Dark wood (#3D2817 / #1a110a / #2a1b10), accent cam (#E8772E / #ff9800), đỏ (#C62828)

---

## 🗺️ SƠ ĐỒ TỔNG QUAN FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CUSTOMER SELF-SERVICE FLOW                      │
└─────────────────────────────────────────────────────────────────────┘

  [Trang /customer]
         │
         ▼
  ┌──────────────┐     Sai passcode      ┌──────────────────┐
  │ 1. PASSCODE  │ ──────────────────▶   │ Hiển thị lỗi     │
  │ (6 số)       │                       │ "Mã passcode      │
  │ Nhập mã NV   │                       │ không chính xác!" │
  └──────┬───────┘                       └──────────────────┘
         │ Đúng passcode
         ▼
  ┌──────────────┐
  │ 2. CHỌN KHU  │  Grid 2 cột các khu vực (A, B, VIP...)
  │ VỰC (Area)   │  Nút "Quay lại" / "Khóa lại"
  └──────┬───────┘
         │ Chọn 1 khu vực
         ▼
  ┌──────────────┐     Timeout 60s      ┌──────────────────┐
  │ 3. CHỌN BÀN  │ ──────────────────▶  │ Quay về chọn khu │
  │ (Table)      │   (BR-08)            │ vực, giải phóng  │
  │ Grid 4-5 cột │                      │bàn               │
  └──────┬───────┘
         │ Chọn bàn + "Xác nhận"
         ▼
  ┌──────────────┐
  │ 4. MENU CHÍNH│  ◄──── Header bar (logo, search, cart, tracking,
  │ (CustomerMenu)│       service, profile, exit, language)
  └──────┬───────┘
         │
         ├─── Thêm món (nút + / click card → modal chi tiết)
         ├─── Xem giỏ hàng ──────────▶ [5. CART] ── Đặt món ──▶ [6. ORDER HISTORY]
         ├─── Gọi phục vụ (FAB) ────▶ [7. SERVICE REQUEST]
         ├─── Theo dõi món ─────────▶ [8. ORDER TRACKING MODAL]
         ├─── Yêu cầu thanh toán ───▶ (từ Order History)
         └─── Thoát bàn ────────────▶ Swal confirm → clear session → về Passcode
                                         │
                               (Sau thanh toán)
                                         ▼
                                  [9. FEEDBACK] ──▶ [10. SESSION END]
```

---

## 1️⃣ MÀN HÌNH CHÍNH — CUSTOMERHOME (Passcode → Area → Table)

**File:** `src/views/customer/CustomerHome.vue`  
**Route:** `/customer` (name: `CustomerHome`)  
**Component con:** `PasscodeInput`, `SelectArea`, `SelectTable`, `SessionEnd`

### Flow 4 bước (step state machine)

| Step | Component | Mô tả |
|------|-----------|-------|
| `passcode` | `PasscodeInput.vue` | Nhập mã 6 số để mở khóa thiết bị |
| `area` | `SelectArea.vue` + `AreaGrid.vue` | Chọn khu vực bàn |
| `table` | `SelectTable.vue` + `TableGrid.vue` | Chọn bàn cụ thể + xác nhận |
| `session_ended` | `SessionEnd.vue` | Màn hình kết thúc phiên |

### 1.1. Passcode Input (`PasscodeInput.vue`)

**UI:**
- Card tối (`#161616`) bo góc 3xl, có hiệu ứng blur trang trí
- Logo 🐂 + tiêu đề "NGƯU CÁT POS" + subtitle "Xác thực nhân viên"
- 6 dots hiển thị số ký tự đã nhập (đổi sang vàng khi đã填)
- Bàn phím ảo 3×4: số 1-9, nút "Xóa", số 0, nút "Xác nhận"
- Nút "Quay lại" (góc trái trên) → chuyển về `/tablet/idle`
- Error message hiển thị ở dưới (shake animation)

**Flow:**
1. Khách/nhân viên nhập 6 số trên bàn phím ảo
2. Nhấn "Xác nhận" → emit `submit(passcode)`
3. `CustomerHome` gọi `store.authenticateStaff(code)`
4. **Thành công:** load areas → chuyển step `area`
5. **Thất bại:** hiển thị "Mã passcode không chính xác!" + xóa input + shake

### 1.2. Select Area (`SelectArea.vue` + `AreaGrid.vue`)

**UI:**
- Header: nút "Quay lại" + tiêu đề "Chọn khu vực" + nút "Khóa lại" (góc phải trên)
- Grid 2 cột, mỗi khu vực là 1 card:
  - Icon emoji theo area id (🅰️, 🅱️, 🍷 VIP, 🍽️ default...)
  - Tên khu vực (font trắng, bold)
  - Text "Mở danh sách bàn"
  - Glow effect khi được chọn (vàng)
- Background đen gradient

**Flow:**
1. Click 1 khu vực → emit `select(areaId)`
2. `CustomerHome` set `selectedAreaId`, gọi `store.loadTables(areaId)`
3. Chuyển step `table`

### 1.3. Select Table (`SelectTable.vue` + `TableGrid.vue`)

**UI:**
- Header: nút "Quay lại" + tiêu đề "Chọn bàn - {area}" + nút "Khóa lại"
- Grid 4-5 cột các nút bàn:
  - Label "BÀN" + icon 🔒 (nếu không available)
  - Số bàn lớn (vd: A01) — font trắng bold
  - Sức chứa 👥 + dot status (xanh=trống, vàng=đang chọn, đỏ=có khách)
- **Trạng thái bàn:**
  - `available` (xanh): có thể chọn
  - `selecting` (vàng): đang được chọn (chưa confirm)
  - `occupied` (đỏ, mờ, disabled): có khách
- Chú thích (legend) ở dưới: Trống / Đang chọn / Có khách
- Nút "Xác nhận" (vàng, disabled khi chưa chọn bàn)

**Flow:**
1. Click bàn available → `store.selectTable(tableId)` → bàn đổi sang `selecting`
2. **BR-08 Timeout:** Bắt đầu đếm 60 giây. Nếu hết thời gian → giải phóng bàn, quay về step `area`, thông báo "Hết thời gian chọn bàn"
3. Click "Xác nhận" → `store.confirmTable()`:
   - Tạo `CustomerSession` mới (id, tableId, tableNumber, areaId, areaName, staffId, startedAt, status='active')
   - Lưu vào localStorage (`nguucat_customer_session`, `nguucat_customer_auth`, `nguucat_customer_table`)
   - Chuyển hướng → `CustomerMenu`

---

## 2️⃣ CUSTOMER LAYOUT — KHUNG CHUNG

**File:** `src/layouts/CustomerLayout.vue`

### 2.1. Hai chế độ hiển thị

| Điều kiện | Hiển thị |
|-----------|----------|
| `session` tồn tại | **Active Session Layout** — Header bar + RouterView |
| `session` null | **Inactive Session Layout** — Background đen, chỉ hiển thị RouterView (cho passcode/area/table) |

### 2.2. Header Bar (60px) — Khi có session

```
┌──────────────────────────────────────────────────────────────────────┐
│ 🌸 NGƯU CÁT  │  [🔍 Tìm kiếm...]  │  [A05]  │ 🛒(3) 📋(2) 🔔(1) 👤 🚪 │ 🇻🇳🇬🇧🇯🇵 │
└──────────────────────────────────────────────────────────────────────┘
```

| Element | Mô tả |
|---------|-------|
| **Logo 🌸 NGƯU CÁT** | Click → về `CustomerMenu` |
| **Search bar** | `v-model` trực tiếp với `store.searchQuery`, placeholder "Tìm kiếm..." |
| **Table badge** | Hiển thị `session.tableNumber` (vd: A05), màu cam, bold |
| **🛒 Cart button** | Badge đỏ hiển thị `cartItemCount`, click → `CustomerCart` |
| **📋 Tracking button** | Badge vàng hiển thị `pendingItemsCount` (món chưa served), click → mở `OrderTrackingModal` |
| **🔔 Service button** | Badge vàng hiển thị `activeServiceRequests.length`, click → `ServiceRequest` |
| **👤 Profile button** | Click → `OrderHistory` |
| **🚪 Exit button** | Click → Swal confirm "Xác nhận thoát bàn?" → `clearSession()` → về passcode |
| **Language flags** | 🇻🇳 🇬🇧 🇯🇵 — chuyển ngôn ngữ vi/en/ja |

### 2.3. Toast Notifications

- Fixed bottom-right, z-50
- 4 loại: `success` (✓ xanh), `error` (✗ đỏ), `warning` (⚠ vàng), `info` (xám)
- Tự động biến mất sau 4 giây
- Animation fade + slide

### 2.4. Order Tracking Modal

- Component: `OrderTrackingModal.vue`
- Mở khi click nút 📋 trong header
- Chi tiết tại [mục 8](#8️⃣-order-tracking-modal)

### 2.5. Session Recovery & Redirect Logic

```typescript
// onMounted: Nếu không có session và không phải CustomerHome → redirect về CustomerHome
// Cho phép truy cập trực tiếp CustomerCart để test UI
if (!store.session && route.name !== 'CustomerHome' && route.path.startsWith('/customer') && !allowDirectAccess) {
  router.push({ name: 'CustomerHome' });
}

// watch(session): Khi session bị xóa → redirect về CustomerHome (trừ khi đang ở SessionEnd/CustomerCart)
```

---

## 3️⃣ MENU CHÍNH — CustomerMenu

**File:** `src/views/customer/CustomerMenu.vue`  
**Route:** `/customer/menu` (name: `CustomerMenu`)  
**Layout:** Sidebar (260px) + Main area (flex-1)

### 3.1. Sidebar — Danh mục món

```
┌─────────────┐
│ DANH MỤC MÓN│  ← Section title (hồng #e91e63)
│             │
│ [ Buffet  ] │  ← Nút danh mục (hồng #b56576)
│ [ Thịt nướng]│    Active: đỏ #c62828 + border trắng
│ [ Hải sản ] │
│ [ Lẩu     ] │
│ [ Rau/Salad] │
│ [ Cơm/Mì  ] │
│ [ Đồ uống ] │
│ [ Tráng miệng]│
│ [ Khác    ] │
└─────────────┘
```

- **Menu categories:** Lấy từ `store.menuData`, lọc theo `color === 'pink'` + buffet category
- Click danh mục → `selectCategory(cat)` → reset subcategory về "Tất cả"

### 3.2. Main Area — Nội dung danh mục

**Package Banner (chỉ cho buffet):**
- Hiển thị khi category id starts with `buffet-` (không phải drink/alacarte)
- Gradient amber, icon 👑, tên gói, giá gói (vd: 1.390.000đ)
- Nút "Chọn gói này" / "✓ Đã chọn gói" (disabled khi đã có trong giỏ)
- Click → `addSetToCart(cat)` — thêm "Vé buffet" (item đầu tiên của subcategory đầu tiên)

**Category Header:**
- Tên danh mục (28px, bold) + item count ("{count} món")

**Items Grid:**
- Grid responsive: `repeat(auto-fill, minmax(285px, 1fr))`
- Mỗi item là `MenuItemCard` — chi tiết tại [3.4](#34-menuitemcard)

**Empty State:**
- Icon 🍽️ + "Không có món nào" / "Chọn danh mục để xem món"

### 3.3. Fixed Bottom Container

**CartBar** (nếu `cartItemCount > 0`):
- Fixed bottom, trên CategoryTabs
- Hiển thị: 🛒 "Giỏ hàng của bạn" | "{count} món" | "Tổng: {total}K/M"
- Nút "Xem giỏ hàng" (cam gradient) → `goToCart()`

**CategoryTabs** (nếu có subcategories):
- Tab "Tất cả ({totalItems})" + các subcategory tabs
- Active: cam gradient
- Select tab → lọc items theo subcategory
- Khi vào buffet subcategory → tự động add set ticket nếu chưa có

### 3.4. MenuItemCard

**File:** `src/components/customer/MenuItemCard.vue`

```
┌─────────────────────────┐
│     [Gradient BG]       │  ← 140px height, emoji lớn 64px (float animation)
│         🥩              │
│              [Trong gói] │  ← Badge xanh nếu price === 0
├─────────────────────────┤
│ Wagyu Thăn Ngoại A5     │  ← Tên món (2 dòng max)
│ 100G                    │  ← Đơn vị
│ ─────────────────────── │
│ 680K           (+)      │  ← Giá (cam) + nút thêm tròn (cam)
└─────────────────────────┘
```

- **Emoji:** Tự động chọn theo tên món (bò→🥩, heo→🐖, tôm→🦐, bia→🍺, v.v.)
- **Gradient:** Tự động theo loại món (đỏ cho bò, xanh biển cho hải sản, xanh lá cho rau...)
- **Price display:**
  - `price === 0`: "0K" (xanh #4CAF50) + badge "Trong gói"
  - `price > 0`: `price_display` (cam #ff9800)
- **Interactions:**
  - Click card → `openDetail(item)` → mở `MenuItemDetailModal`
  - Click nút (+) → `handleQuickAdd` → thêm nhanh 1 món (không mở modal) + animation ✓ xanh

### 3.5. Floating Action Button — Gọi phục vụ

- Fixed bottom-right (bottom-24, right-6)
- Nút tròn 56px, cam (#E8772E), icon chuông 🔔
- Animation bounce + hover rotate 12°
- Click → `goToServiceRequest()` → route `ServiceRequest`

### 3.6. Package Pricing Rules

- **Trong gói buffet:** `price = 0` (hiển thị "0K (Trong gói)")
- **Lunch 50%:** Giảm 50% giá, `price_display = "{half}đ (Lunch 50%)"`
- Engine: `@/utils/packageRules` → `applyPackage()` + `calculateItemUnitPrice()`
- Shared với cashier → đảm bảo đồng nhất giá

---

## 4️⃣ MENU ITEM DETAIL MODAL

**File:** `src/components/customer/MenuItemDetailModal.vue`  
**Trigger:** Click vào `MenuItemCard`  
**Teleport:** `body` (z-index 9999)

### UI Layout

```
┌──────────────────────────────────────────────────────────────┐
│ [← Back]                              [Giỏ (3)]              │  ← Header
├────────────────────────┬─────────────────────────────────────┤
│                        │ Wagyu Thăn Ngoại A5                 │
│   [Main Image]         │ 680K (hoặc "0K (Trong gói buffet)") │
│        🥩              │                                     │
│        (1/4)           │ ┌─ MÔ TẢ ─────────────────────┐    │
│                        │ │ Thịt bò vân mỡ cẩm thạch... │    │
│                        │ └─────────────────────────────┘    │
│ [Thumb1][Thumb2]       │                                     │
│ [Thumb3][Thumb4]       │ [🚫 Dị ứng] [🔥 Độ cay] [⏱️ Thời gian]│
│                        │  Không đậu   Nhẹ       8-10 phút    │
├────────────────────────┴─────────────────────────────────────┤
│ SỐ LƯỢNG        GHI CHÚ CHO BẾP                              │
│ [-]  1  [+]     [VD: Không hành, ít cay...]                  │
│                                                              │
│ [              THÊM VÀO GIỎ HÀNG              ]              │
└──────────────────────────────────────────────────────────────┘
```

**Thumbnails (4 ảnh):**
1. Tổng quan — emoji chính của món
2. Chế biến — 🔥/🍋/🔪 tùy loại
3. Nguyên liệu — 🌾
4. Trình bày — 👨‍🍳

**Flow:**
1. Click card → modal mở, reset state (qty=1, note='', thumb=0)
2. Chọn thumbnail → đổi main image
3. Tăng/giảm số lượng (min 1)
4. Nhập ghi chú cho bếp
5. Click "THÊM VÀO GIỎ HÀNG" → emit `add(item, quantity, note)`
6. `CustomerMenu.confirmDetailAdd()`:
   - Nếu đã có trong giỏ → update quantity + ghi đè note
   - Nếu chưa → `store.addToCart(item, quantity)` + set note
   - `syncCart()` + notification "Đã thêm {qty} x {name} vào giỏ hàng"
7. Đóng modal

---

## 5️⃣ GIỎ HÀNG — CustomerCart

**File:** `src/views/customer/CustomerCart.vue`  
**Route:** `/customer/cart` (name: `CustomerCart`)  
**Component con:** `CartItem.vue`

### 5.1. Header

```
┌──────────────────────────────────────────────────────────────────┐
│ [←] Giỏ hàng của bạn                    [Xóa đã chọn (2)] [Xóa toàn bộ] │
│     Rà soát lại số lượng và ghi chú trước khi chuyển vào bếp     │
└──────────────────────────────────────────────────────────────────┘
```

- Nút back (tròn) → `backToMenu()`
- Nút "Xóa đã chọn ({count})" — chỉ hiện khi có item được check
- Nút "Xóa toàn bộ"

### 5.2. Empty State

```
┌─────────────────────┐
│         🧺          │
│ Giỏ hàng trống      │
│ Hãy thêm món...     │
│ [  Thêm món ăn  ]   │  ← Nút cam → backToMenu
│ [🧪 Nạp dữ liệu test]│  ← Nút dashed (dev/test)
│ ⚠ Chưa có phiên...  │  ← Hint (nếu !hasSession)
└─────────────────────┘
```

**Seed Test Data (dev):**
- Nút "🧪 Nạp dữ liệu test (10 món)" → `seedTestData()`
- Tạo mock session (`sess-mock-*`) + 10 CartItem với UUID hợp lệ
- Cho phép test UI cart mà không cần backend

### 5.3. Non-Empty State (2 cột)

**Left Column — Item List:**
```
☑ Chọn tất cả (10 món)

┌──────────────────────────────────────────────────────┐
│ ☑ [🥩] Wagyu Thăn Ngoại A5        [-] 2 [+] [🗑]    │
│      680K × 2 = 1.360.000đ                           │
│      Ghi chú: [Không hành, chín kỹ...]              │
├──────────────────────────────────────────────────────┤
│ ☑ [🦐] Tôm Hấp Hành Gừng         [-] 1 [+] [🗑]    │
│      180K × 1 = 180.000đ                             │
│      Ghi chú: [...]                                  │
└──────────────────────────────────────────────────────┘
```

**CartItem.vue:**
- Checkbox multi-select (trái)
- Emoji + gradient image (52px)
- Tên món, giá × số lượng = thành tiền
- Input ghi chú (inline, placeholder "Không hành, chín kỹ...")
- Nút [-] [+] điều chỉnh số lượng (nút + màu cam)
- Nút xóa 🗑 (đỏ khi hover)
- Nếu quantity về 0 → tự xóa item

**Right Column — Billing Summary + Actions:**
```
┌─────────────────────────────┐
│ 📊 Chi tiết thanh toán      │
│ ─────────────────────────── │
│ Tổng số món:        10 món  │
│ Tổng số lượng:     20 phần  │
│ Tiền món tạm tính:  4.040.000đ │
│ Phí dịch vụ (5%):     202.000đ │
│ Thuế VAT (8%):        339.360đ │
│ ─────────────────────────── │
│ Tạm tính (gồm VAT...): 4.581.360đ │  ← Grand total (cam, 18px)
└─────────────────────────────┘

[  Thêm món  ] [  Đặt món  ]
```

### 5.4. Submit Order Flow

```typescript
async function submitOrder() {
  // 1. Kiểm tra giỏ trống
  // 2. Validate UUID (chỉ live mode)
  //    - Nếu có món không hợp lệ → Swal với 3 option:
  //      a) "Xóa món lỗi" → removeInvalidCartItems()
  //      b) "Tải lại thực đơn" → store.loadMenu()
  //      c) "Hủy" → return
  // 3. submitting = true (hiện spinner)
  // 4. Tạo order:
  //    - Mock mode: simulate (delay 800ms, tạo order local)
  //    - Live mode: store.confirmOrder() → Supabase RPC
  // 5. BR-23: Group kitchen tickets (hot/meat/salad)
  // 6. BR-27/BR28: Simulate in kitchen tickets
  // 7. Swal "Đặt món thành công!" → redirect OrderHistory
  // 8. Catch: Swal "Lỗi đặt món"
}
```

**Business Rules liên quan:**
- **BR-23:** Group món theo trạm bếp (hot, meat, salad)
- **BR-27:** Format kitchen ticket text
- **BR-28:** Tăng printed count

---

## 6️⃣ LỊCH SỬ ĐẶT MÓN — OrderHistory

**File:** `src/views/customer/OrderHistory.vue`  
**Route:** `/customer/orders` (name: `OrderHistory`)

### 6.1. Header

- Tiêu đề "Lịch sử gọi món" + subtitle
- Badge "Tổng gọi: {count} món"

### 6.2. Layout 2 cột (khi có orders)

**Left — Order List (nền wood #3D2817):**

```
┌─────────────────────────────────────────────┐ ← Card trắng
│ Mã Order: A1B2C3D4        14:30  [ĐANG NẤU] │
│ ─────────────────────────────────────────── │
│ [2] Wagyu Thăn Ngoại A5          1.360.000đ │
│     ✎ Không hành                            │
│ [1] Tôm Hấp Hành Gừng              180.000đ │
└─────────────────────────────────────────────┘
```

- Mỗi order là 1 card trắng, bo góc 2xl
- **Order ID:** 8 ký tự cuối, uppercase, màu cam
- **Time:** `createdAt` → format HH:mm theo locale
- **Status badge:**
  - `confirmed`: amber "ĐÃ NHẬN"
  - `cooking`: blue "ĐANG NẤU" (animate-pulse)
  - `served`: emerald "ĐÃ PHỤC VỤ"
  - `completed`/`paid`: purple "ĐÃ XONG"/"ĐÃ THANH TOÁN"
- Mỗi item: quantity badge + tên + ghi chú (✎ cam) + thành tiền (đỏ #C62828)

**Empty State:** Icon 🥩 + "Chưa gọi món nào"

**Right — Bill Settlement (nền xám #F5F5F5, text tối):**
```
┌───────────────────────────────┐
│ 🧾 Hóa đơn tạm tính tại bàn   │
│ ───────────────────────────── │
│ Tổng tiền món:     4.040.000đ │
│ Phí dịch vụ (5%):    202.000đ │
│ Thuế VAT (8%):       339.360đ │
│ ───────────────────────────── │
│ Tổng cộng:         4.581.360đ │ ← Đỏ #C62828, 18px
│                               │
│ ℹ Để tiến hành thanh toán... │ ← Hint box
│                               │
│ [📋 Yêu cầu hóa đơn VAT]      │
│ [💵 Yêu Cầu Thanh Toán]       │
└───────────────────────────────┘
```

### 6.3. Payment Flow

**"Yêu Cầu Thanh Toán":**
1. Swal confirm "Gửi yêu cầu thanh toán?"
2. Confirm → `store.requestPayment()`:
   - Gọi API → set `session.status = 'waiting_payment'`
   - Notification "Đã gửi yêu cầu thanh toán"
3. Redirect → `CustomerMenu` (không phải Feedback)
4. Nút thanh toán chuyển sang "Chờ phục vụ thanh toán..." (disabled, xám)

**"Yêu cầu hóa đơn VAT":**
1. Swal confirm "Yêu cầu hóa đơn đỏ?"
2. Confirm → `store.requestInvoice()` → notification "Đã gửi yêu cầu xuất hóa đơn đỏ"

---

## 7️⃣ YÊU CẦU PHỤC VỤ — ServiceRequest

**File:** `src/views/customer/ServiceRequest.vue`  
**Route:** `/customer/service` (name: `ServiceRequest`)

### 7.1. Header (80px)

- Icon 🔔 + "Yêu cầu phục vụ" + subtitle
- Border bottom cam (#E8772E)

### 7.2. Layout 2 cột (không scroll)

**Left — Options Grid (3×3 = 9 nút):**

| 🧻 Khăn giấy | 🥣 Chén bát | 🧂 Gia vị |
|---|---|---|
| 🧊 Thêm đá | 🍳 Thay vỉ | 🪵 Thay than |
| **💵 Tính tiền** | **🙋‍♂️ Gọi NV** | ✍️ Khác |

- Card trắng, bo góc 16px, shadow
- 2 nút highlight (Tính tiền, Gọi NV): gradient cam
- Hover: lift + border cam
- Click → `store.submitServiceRequest(type, '')`

**Right — Request Log Sidebar (400px, nền sáng):**
```
┌──────────────────────────────────┐
│ 📋 NHẬT KÝ YÊU CẦU          [3] │ ← Header cam gradient
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │ 🧻 Lấy khăn giấy    [Đã gửi] │ │
│ │ 🕐 14:30:25                  │ │
│ │              [✕ Hủy yêu cầu] │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 💵 Thanh toán hóa đơn[Chờ nhận]│ │
│ │ 🕐 14:31:10      (pulse)      │ │
│ └──────────────────────────────┘ │
│           + 1 yêu cầu khác       │ ← Nếu > 5 requests
└──────────────────────────────────┘
```

- Hiển thị tối đa 5 requests mới nhất
- **Status badges:**
  - `created`/`waiting`: cam "Đã gửi"/"Chờ nhận" (waiting có pulse)
  - `accepted`/`processing`: xanh dương "Đã nhận"/"Đang xử lý"
  - `completed`: xanh lá "Hoàn thành"
  - `cancelled`: xám "Đã hủy"
- Nút "✕ Hủy yêu cầu" — chỉ hiện khi status là `created` hoặc `waiting`
- **Empty state:** 📭 "Chưa có yêu cầu nào"

### 7.3. 9 Loại yêu cầu (ServiceRequestType)

| Type | Emoji | Label VI |
|------|-------|----------|
| `tissue` | 🧻 | Khăn giấy |
| `bowl` | 🥣 | Chén bát |
| `sauce` | 🧂 | Gia vị |
| `ice` | 🧊 | Thêm đá |
| `grill_change` | 🍳 | Thay vỉ |
| `charcoal_change` | 🪵 | Thay than |
| `request_bill` | 💵 | Tính tiền |
| `call_waiter` | 🙋‍♂️ | Gọi NV |
| `other` | ✍️ | Khác |

---

## 8️⃣ ORDER TRACKING MODAL

**File:** `src/components/customer/OrderTrackingModal.vue`  
**Trigger:** Nút 📋 trong header bar  
**Style:** Glassmorphism (backdrop blur, dark gradient)

### UI Layout

```
┌──────────────────────────────────────────────────────────┐
│ 📋 Theo dõi món ăn        Bàn A05 • 8 món        [×]    │
├──────────────────────────────────────────────────────────┤
│  ✅ 3 Đã phục vụ   🍲 2 Đang chế biến   ⏳ 3 Chờ xử lý   │ ← Status cards
├──────────────────────────────────────────────────────────┤
│ Đã phục vụ   ████████████████░░░░  38%                   │ ← Progress bars
│ Đang chế biến ████████░░░░░░░░░░░░  25%                   │
│ Chờ xử lý    ████████████░░░░░░░░░  37%                   │
├──────────────────────────────────────────────────────────┤
│ [Tất cả (8)] [Đã phục vụ (3)] [Đang chế biến (2)] [Chờ (3)]│ ← Filter tabs
├──────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Wagyu Thăn Ngoại A5                    [ĐANG CHẾ BIẾN]│ │
│ │ SL: 2  •  Đặt lúc 14:30                              │ │
│ │ ████████████████░░░░░░░░  66%                        │ │
│ │                                                       │ │
│ │  ✓─────✓─────○                                        │ │
│ │ Đã đặt  Đang chế biến  Đã phục vụ                    │ │ ← Timeline
│ │ 14:30   14:35         --:--                          │ │
│ └──────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│ [          Làm mới          ] [          Đóng          ] │
└──────────────────────────────────────────────────────────┘
```

**Status mapping từ order.status:**
- `cooking` → `preparing` (66%)
- `served`/`completed` → `served` (100%)
- Other → `pending` (33%)

**Timeline 3 bước:** Đã đặt → Đang chế biến → Đã phục vụ

---

## 9️⃣ ĐÁNH GIÁ — Feedback

**File:** `src/views/customer/Feedback.vue` + `FeedbackPopup.vue`  
**Route:** `/customer/feedback` (name: `Feedback`)

### Flow 2 sub-state

```
[Feedback Form] ──submit/skip──▶ [Goodbye / SessionEnd]
```

### FeedbackPopup UI (card trắng)

```
┌──────────────────────────────────────────┐
│                        [Bỏ qua]          │
│         Đánh Giá Trải Nghiệm             │
│   Đóng góp của bạn giúp Ngưu Cát...     │
│ ──────────────────────────────────────── │
│           ⭐ ⭐ ⭐ ⭐ ⭐                   │ ← Star rating (5 sao)
│         Rất hài lòng! 😍                 │
│ ──────────────────────────────────────── │
│   Bạn hài lòng nhất về điều gì?         │
│  [🥩 Chất lượng món ăn] [⚡ Tốc độ PV]   │
│  [✨ Vệ sinh sạch sẽ]  [😊 Thái độ NV]   │
│  [🏷️ Giá cả hợp lý]   [🛋️ Không gian]   │
│ ──────────────────────────────────────── │
│  GÓP Ý CHI TIẾT (Tùy chọn)              │
│  [Nhập ý kiến đóng góp...]              │
│ ──────────────────────────────────────── │
│              [Bỏ qua]  [Xác nhận]        │
└──────────────────────────────────────────┘
```

**StarRating.vue:**
- 5 SVG sao (48px), hover scale 125%
- Label động theo rating: 😞 Rất không hài lòng → 😍 Rất hài lòng
- Click → set rating

**FeedbackCriteria.vue:**
- 6 tiêu chí (grid 2-3 cột):
  - `food_quality` 🥩 Chất lượng món ăn
  - `service_time` ⚡ Tốc độ phục vụ
  - `hygiene` ✨ Vệ sinh sạch sẽ
  - `staff_attitude` 😊 Thái độ nhân viên
  - `pricing` 🏷️ Giá cả hợp lý
  - `space` 🛋️ Không gian ấm cúng
- Multi-select, toggle on/off
- BR-36: Phải chọn ít nhất 1 tiêu chí

**Submit validation:** `rating >= 1 && criteria.length >= 1`

**Flow:**
1. Submit → `store.submitFeedback({rating, criteria, comment})`
2. `finalizeAndExit()` → `store.endSession()` (release table)
3. Chuyển subView `goodbye` → hiển thị `SessionEnd`

---

## 🔟 KẾT THÚC PHIÊN — SessionEnd

**File:** `src/views/customer/SessionEnd.vue`

### UI

```
┌──────────────────────────────────────┐
│                 🌸                    │
│           NGƯU CÁT                    │
│      Cảm ơn bạn đã dùng bữa!          │
│      Hẹn gặp lại bạn lần sau          │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ MÃ HÓA ĐƠN        #INV-20260719-XXXX │  │ ← White panel
│  │ ────────────────────────────── │  │
│  │ Tổng thanh toán:     4.581.360đ│  │ ← Đỏ #C62828
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │         [QR Code SVG]          │  │ ← Mock QR
│  │    QUÉT QR ĐÁNH GIÁ GOOGLE     │  │
│  └────────────────────────────────┘  │
│                                      │
│  ● Màn hình sẽ tự động reset sau     │ ← Countdown 30s
│    30 giây...                        │   (pulse dot)
│                                      │
│       Quay về chính (Nhân viên)      │ ← Override button
└──────────────────────────────────────┘
```

- **Invoice number:** `#INV-{YYYYMMDD}-{last 4 chars of session id}`
- **Total:** Tính từ `store.orders` (subtotal + 5% service + 8% VAT)
- **QR Code:** Mock SVG (không phải QR thật)
- **Countdown:** 30 giây → tự động `endSessionNow()`
- **Override:** Click "Quay về chính" → `clearSession()` → emit `done` → về `CustomerHome`

---

## 🔄 DATA FLOW & STATE MANAGEMENT

### Pinia Store: `customerStore.ts`

```typescript
state: {
  session: CustomerSession | null,
  isAuthenticated: boolean,        // unlocked by staff passcode
  areas: Area[],
  selectedAreaId: string | null,
  tables: Table[],
  selectedTable: Table | null,
  menuData: MenuCategory[],
  selectedCategory: MenuCategory | null,
  selectedSubcategory: SubCategory | null,
  cart: CartItem[],
  orders: Order[],
  serviceRequests: ServiceRequest[],
  feedback: Feedback | null,
  notifications: Notification[],
  searchQuery: string,
  currentLanguage: 'vi' | 'en' | 'ja'
}

getters: {
  cartTotal,           // Σ price × quantity (sau package rules)
  cartItemCount,       // Σ quantity
  serviceCharge,       // cartTotal × 5%
  vat,                 // (cartTotal + serviceCharge) × 8%
  grandTotal,          // cartTotal + serviceCharge + vat
  activeServiceRequests,
  orderHistory
}
```

### Session Persistence (useCustomerSession composable)

- **localStorage keys:**
  - `nguucat_customer_session` — JSON session object
  - `nguucat_customer_auth` — 'true'
  - `nguucat_customer_table` — JSON table object
- **restoreSessionFromLocalStorage()** — gọi trong `CustomerLayout` onMounted
- **clearSession()** — xóa localStorage + reset store
- **syncCart()** — đồng bộ cart vào localStorage

### API Layer: `customerApi.ts`

| Method | Mô tả |
|--------|-------|
| `authenticateStaff(passcode)` | Xác thực mã nhân viên |
| `getAreas()` | Lấy danh sách khu vực |
| `getTables(areaId)` | Lấy danh sách bàn theo khu vực |
| `selectTable(tableId)` | Đánh dấu bàn đang chọn |
| `confirmTable(session)` | Tạo session mới |
| `getRawMenuItems()` | Lấy menu items từ DB (UUID) |
| `getMenuTemplate()` | Lấy template menu (mock structure) |
| `submitServiceRequest(req)` | Gửi yêu cầu phục vụ |
| `updateServiceRequest(id, status)` | Cập nhật trạng thái request |
| `createOrder(order)` | Tạo đơn hàng → Supabase RPC |
| `getOrderHistory(sessionId)` | Lấy lịch sử đơn hàng |
| `requestPayment(sessionId)` | Yêu cầu thanh toán |
| `requestInvoice(sessionId)` | Yêu cầu hóa đơn đỏ |
| `submitFeedback(feedback)` | Gửi đánh giá |
| `releaseTable(sessionId)` | Giải phóng bàn |

### Menu Loading Strategy

```
1. getRawMenuItems() → DB rows (UUID, price, price_display)
2. getMenuTemplate() → Mock structure (categories → subcategories → items)
3. Deep clone template
4. Walk each item, match by name → substitute id/price/price_display
5. If no DB match → mark is_available = false
6. Result: menuData with real UUIDs + correct pricing
```

---

## 📐 BUSINESS RULES

| Rule | Mô tả |
|------|-------|
| **BR-08** | Timeout 60s khi chọn bàn. Nếu idle → giải phóng bàn, quay về chọn khu vực |
| **BR-09** | Yêu cầu session active để truy cập menu, cart, orders, service, feedback |
| **BR-23** | Group món theo trạm bếp: `hot`, `meat`, `salad` |
| **BR-27** | Format kitchen ticket text (table number + items) |
| **BR-28** | Tăng `printedCount` cho kitchen ticket |
| **BR-35** | Rating 1-5 sao |
| **BR-36** | Phải chọn ít nhất 1 tiêu chí đánh giá |
| **BR-37/38** | Logic xử lý feedback trong store |

### Pricing Rules (packageRules.ts)

| Rule | Mô tả |
|------|-------|
| **Package pricing** | Món trong gói buffet → `price = 0`, display "0K (Trong gói)" |
| **Lunch 50%** | Giảm 50% giá món, display "{half}đ (Lunch 50%)" |
| **Service charge** | 5% × subtotal |
| **VAT** | 8% × (subtotal + service charge) |
| **computeTotals()** | Shared engine — đồng nhất giữa customer và cashier |

---

## 🌐 I18N — ĐA NGÔN NGỮ

- **3 ngôn ngữ:** 🇻🇳 Tiếng Việt, 🇬🇧 English, 🇯🇵 日本語
- **Files:** `src/locales/vi.ts`, `en.ts`, `ja.ts`
- **Chuyển đổi:** Click flag trong header → `setApplicationLanguage(lang)`
- **Notification:** "Đã chuyển sang ngôn ngữ: {lang}"
- **Price/Time format:** Theo locale (vi-VN, en-US, ja-JP)

---

## 🎨 DESIGN SYSTEM

### Colors

| Màu | Hex | Sử dụng |
|-----|-----|---------|
| Wood dark | `#3D2817` | Background chính |
| Wood darker | `#1a110a` | Header bar |
| Wood medium | `#2a1b10` | Cards, inputs |
| Border | `#2d1e12` / `#442c19` | Borders |
| Orange | `#E8772E` / `#ff9800` | Accent, buttons, prices |
| Red | `#C62828` | Grand total, delete |
| Green | `#4CAF50` | Free items, success |
| Amber | `#f59e0b` | Warnings, pending |
| Blue | `#60a5fa` | Preparing status |
| Emerald | `#4ade80` | Served status |

### Typography

- **Font:** Sans-serif (Inter), serif cho tiêu đề (Playfair Display)
- **Brand:** "NGƯU CÁT" — uppercase, tracking-widest, amber-500
- **Prices:** Bold, cam hoặc đỏ

### Animations

- `fade-scale` — transition giữa các step
- `shake` — error passcode
- `pulse` — pending badges, cooking status
- `float` — emoji trên MenuItemCard
- `bounce` — FAB gọi phục vụ
- `shine` — progress bar trong tracking modal

---

## 📁 FILE MAP — CUSTOMER MODULE

```
src/
├── layouts/
│   └── CustomerLayout.vue              # Khung chung (header, notifications, tracking modal)
├── views/customer/
│   ├── CustomerHome.vue                # Step machine: passcode → area → table
│   ├── SelectArea.vue                  # Chọn khu vực
│   ├── SelectTable.vue                 # Chọn bàn
│   ├── CustomerMenu.vue                # Menu chính (sidebar + grid + FAB)
│   ├── CustomerCart.vue                # Giỏ hàng + billing + đặt món
│   ├── OrderHistory.vue                # Lịch sử order + bill settlement
│   ├── ServiceRequest.vue              # 9 nút yêu cầu + log sidebar
│   ├── Feedback.vue                    # Wrapper: feedback form → session end
│   ├── FeedbackPopup.vue               # Form đánh giá (sao + criteria + comment)
│   └── SessionEnd.vue                  # Thank you + invoice + QR + countdown
├── components/customer/
│   ├── PasscodeInput.vue               # Bàn phím 6 số
│   ├── AreaGrid.vue                    # Grid chọn khu vực
│   ├── TableGrid.vue                   # Grid chọn bàn + legend
│   ├── MenuItemCard.vue                # Card món ăn (emoji, giá, nút +)
│   ├── MenuItemDetailModal.vue         # Modal chi tiết món (gallery, info, add)
│   ├── CategoryTabs.vue                # Tabs subcategory
│   ├── CartBar.vue                     # Bar giỏ hàng floating
│   ├── CartItem.vue                    # Line item trong giỏ (checkbox, qty, note)
│   ├── OrderTrackingModal.vue          # Modal theo dõi trạng thái món
│   ├── StarRating.vue                  # 5 sao đánh giá
│   ├── FeedbackCriteria.vue            # 6 tiêu chí đánh giá
│   ├── ServiceRequestGrid.vue          # (unused — inline trong ServiceRequest)
│   ├── CustomerDetailDrawer.vue        # (CRM — không thuộc customer flow)
│   ├── BottomCartBar.vue               # (alternative cart bar)
│   ├── MenuCategoryBar.vue             # (alternative category bar)
│   ├── MenuSubcategoryBar.vue          # (alternative subcategory bar)
│   └── TierBadge.vue                   # Badge hạng thành viên
├── stores/
│   └── customerStore.ts                # Pinia store (state + actions + getters)
├── composables/
│   ├── useCustomer.ts                  # Composable customer helpers
│   └── useCustomerSession.ts           # Session persistence (localStorage)
├── services/
│   └── customerApi.ts                  # API layer (Supabase RPC)
├── types/
│   └── customer.ts                     # TypeScript interfaces
└── locales/
    ├── vi.ts                           # Tiếng Việt
    ├── en.ts                           # English
    └── ja.ts                           # 日本語
```

---

## 📌 TÓM TẮT FLOW KHÁCH HÀNG

```
Passcode → Chọn Khu Vực → Chọn Bàn → Menu → Thêm Món → Giỏ Hàng → Đặt Món
                                                                    │
                                                                    ▼
                                                          Lịch Sử Order
                                                           │        │
                                  ┌────────────────────────┘        │
                                  ▼                                  ▼
                          Yêu Cầu Thanh Toán                Theo Dõi Món
                                  │                        (pending→preparing→served)
                                  ▼
                            Feedback (sao + tiêu chí)
                                  │
                                  ▼
                            Session End (QR + countdown 30s)
                                  │
                                  ▼
                            Về Passcode (phiên mới)
```

**Toàn bộ flow không yêu cầu đăng nhập khách hàng** — chỉ cần mã nhân viên để mở khóa thiết bị. Khách tự thao tác đặt món, theo dõi, yêu cầu phục vụ, thanh toán, và đánh giá trên tablet tại bàn.
