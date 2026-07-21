# 📋 MÔ TẢ TOÀN BỘ LUỒNG UI `/reception/order`

> **URL:** `http://localhost:5173/reception/order`
> **Ngày tạo:** 19/07/2026
> **Tech Stack:** Vue 3 + TypeScript + Vite + Pinia + Vue i18n + Supabase/PostgreSQL
> **File chính:** `src/views/reception/ReceptionOrderView.vue` (~11,600 dòng)
> **Composable:** `src/composables/useTableOperations.ts`
> **Theme:** Dark POS (#1e1e1e / #2d2d2d / #3a3a3a), accent cam (#ff8f00)

---

## 1. BỐI CẢNH & RÀNG BUỘC

- **Đối tượng sử dụng:** Lễ tân / Thu ngân / Phục vụ
- **Dữ liệu:** Sử dụng Mock Data (Static UI). Không gọi API thực tế đến Backend/Database. Mọi thao tác (thêm, sửa, xóa, chuyển bàn) đều cập nhật trạng thái trong bộ nhớ (reactive state) và giả lập độ trễ (delay)
- **Design System:** Sử dụng Tailwind CSS, màu chủ đạo là Cam (#ff8f00), bo góc (rounded-xl), shadow-md, hiệu ứng hover mượt mà

---

## 2. BỐ CỤC GIAO DIỆN (LAYOUT STRUCTURE)

```
┌──────────────────────────────────────────────────────────────────┐
│  HEADER: Tabs + Cashier Info + Clock + Search + Notifications    │
├──────────────┬───────────────────────────────────────────────────┤
│              │                                                   │
│  LEFT PANEL  │              MAIN AREA                            │
│  (320px)     │     (thay đổi theo activeMainTab)                  │
│              │                                                   │
│  - Khách chờ │  [Sơ đồ bàn] / [Thực đơn] / [Hóa đơn] / [Chưa XL] │
│  - Giỏ hàng  │                                                   │
│  - Nhóm order│                                                   │
│              │                                                   │
├──────────────┴───────────────────────────────────────────────────┤
│  FOOTER: Sơ đồ | Menu | Phiếu | Danh sách | Gửi đi               │
└──────────────────────────────────────────────────────────────────┘
```

### 2.1. Header (dòng 64–264)

| Thành phần | Chi tiết |
|-----------|----------|
| Tab điều hướng | `invoice` (Phiếu), `menu` (Chi tiết + badge số món), `pending` (Chưa xử lý + badge đỏ), `table_map` (Sơ đồ bàn) |
| Cashier info | Tên thu ngân, ngày giờ, ca làm việc |
| Search | Tìm bàn / khách (toggle input) |
| More menu | Thu nhập khác, Cài đặt, Phím tắt, Trợ giúp, Giới thiệu, Đăng xuất |
| Notifications | 🔔 với badge đỏ (99+) |

### 2.2. Left Panel (dòng 267–918)

Thay đổi nội dung theo `activeMainTab`:

| Khi activeMainTab = | Nội dung Left Panel |
|---------------------|---------------------|
| `table_map` / `table_list` | **Khách chờ xếp bàn** — danh sách reservation chưa xếp bàn, hỗ trợ drag-and-drop (VueDraggable) kéo thả lên bàn |
| `menu` | **Giỏ hàng / Order panel** — header (mã bàn, tên khách), danh sách món (+/− số lượng), bảng tính tiền (tạm tính, giảm giá, phí phục vụ 5%, VAT 8%, tổng cộng), nút "Gửi đi" |
| `invoice` | **Nhóm order** — view theo bếp/giao hàng, header nhóm (datetime/mã/khách), checkbox chọn món, thời gian chờ, số lần in |

### 2.3. Footer (dòng 880–918)

- Nút điều hướng nhanh: Sơ đồ, Menu, Phiếu, Danh sách bàn
- Nút "Gửi đi" (sendToKitchen) — gửi món vào bếp

---

## 3. CÁC TAB CHÍNH (`activeMainTab`)

### 3.1. Tab Sơ đồ bàn (`table_map`) — dòng 924–1140

#### Timeline Slider

- Thanh trượt thời gian: 11:00 – 22:00 (660–1320 phút)
- Presets: Trưa (11:30–13:30), Tối (18:00–21:00)
- Hiển thị số bàn khả dụng / xung đột trong khung giờ

#### Grid bàn

- Layout: `grid-cols-2 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8`
- Mỗi ô bàn: hỗ trợ drag-and-drop khách từ Left Panel

#### Trạng thái bàn & màu sắc

| Trạng thái | CSS Class | Màu | Ý nghĩa |
|-----------|-----------|-----|---------|
| `Available` | `bg-[#145a32]/30 border-[#27ae60]` | Xanh lá | Bàn trống |
| `Serving` / `Arrived` | `bg-[#78281f]/40 border-[#c0392b]` | Đỏ nâu | Có khách, có order |
| `Reserved` | `bg-[#7d6608]/40 border-[#f1c40f]` | Vàng | Đã đặt trước |
| Conflict (reservation) | `bg-[#7e5109]/40 border-[#d35400]` | Cam | Trùng giờ đặt |

#### Thông tin hiển thị trên ô bàn

- Mã bàn (A01, B02...)
- Sức chứa (👥 4)
- Tên khách (khi có order)
- Giờ check-in + thời gian ngồi
- Tổng tiền tạm tính (khi có order)
- "Trống" (khi bàn trống)
- Thông tin reservation (khi conflict)

#### Tương tác

| Hành động | Handler | Kết quả |
|-----------|---------|---------|
| Click 1 lần | `handleTableClick(table)` | Chọn bàn, load order. Nếu đang ở selection mode → chọn bàn đích |
| Click 2 lần | `handleTableDoubleClick(table, $event)` | Mở Context Menu tại vị trí chuột |

---

### 3.2. Tab Thực đơn (`menu`) — dòng 1374–1634

#### Bộ lọc nhanh

- ⭐ Yêu thích (Favorites)
- 🔥 Phổ biến (Popular)
- 🕒 Gần đây (Recent)

#### Bộ lọc nâng cao

- Tình trạng: Tất cả / Còn món / Hết món
- Giá: Không / Tăng dần / Giảm dần
- Tìm kiếm: Input text

#### Grid món ăn

- Card: Tên (VN + JP), giá, đơn vị
- Viền cam + badge số lượng khi đã có trong giỏ
- ⭐ Đánh dấu yêu thích

#### Danh mục

- Hàng chính: Buffet, Set Lunch, Thức ăn, Thức uống... (nút màu)
- Hàng phụ: Danh mục con (nút cam)

#### Modal chi tiết món (dòng 2640–3500)

- Món đơn: Hình ảnh, tên, mã, đơn vị, số lượng, VAT/PPV, ghi chú, phân loại
- Món phức tạp (có option groups): Tab chọn tùy chọn với min/max constraint, ghi chú từng option
- Nút "Thêm vào giỏ" → `saveDetailPanelQty()` → thêm vào `activeOrder.items`

---

### 3.3. Tab Hóa đơn (`invoice`) — dòng 1636–2527

Bố cục 3 cột:

```
┌──────────────┬──────────────────────┬───────────────┐
│ Cột 1 (30%)  │ Cột 2 (45%)          │ Cột 3 (25%)   │
│ Danh sách món│ Chi tiết thanh toán   │ Bàn phím số   │
│              │                       │               │
│ - Tên món    │ - Tiền hàng           │ 500   1.000   │
│ - Đơn giá    │ - Phí phục vụ (sửa)   │ 2.000 5.000   │
│ - VAT 8%     │ - Giảm giá món        │ 10k   20k     │
│ - Thành tiền │ - Giảm giá phiếu      │ 50k   100k    │
│              │ - TTDB                │ 200k  500k    │
│              │ - VAT tổng            │ [Chấp nhận]   │
│              │ - Khách đưa           │               │
│              │ - Tiền thừa           │               │
├──────────────┴──────────────────────┴───────────────┤
│ 💵Tiền mặt │ 💳Chuyển khoản │ 🎟️Voucher │ 🏷️Coupon │
│ 💰Cọc │ 🧧Giảm giá │ 👑VIP Card                      │
├──────────────────────────────────────────────────────┤
│ [Lịch sử] [Giao hàng] [In tạm] [In hóa đơn]         │
│ [💵 THANH TOÁN]                                      │
└──────────────────────────────────────────────────────┘
```

#### Phương thức thanh toán

| Nút | Icon | Loại |
|-----|------|------|
| Tiền mặt | 💵 | Cash |
| Chuyển khoản | 💳 | Bank transfer |
| Voucher | 🎟️ | Voucher |
| Coupon | 🏷️ | Coupon |
| Cọc | 💰 | Deposit |
| Giảm giá | 🧧 | Discount (cần lý do + PIN quản lý) |
| VIP Card | 👑 | VIP card |

#### Hành động cuối

- **Lịch sử**: Xem lịch sử order của bàn
- **Giao hàng**: Chuyển sang flow delivery
- **In tạm tính**: In bill tạm
- **In hóa đơn**: In hóa đơn chính thức
- **Thanh toán**: Hoàn tất → bàn về "Trống", clear giỏ hàng

---

### 3.4. Tab Chưa xử lý (`pending`) — dòng 2530–2598

Hiển thị danh sách đơn hàng chờ xử lý (badge đỏ = số lượng).

#### Mock data hiện tại

| Mã đơn | Bàn | Khách | Món | Tổng |
|--------|-----|-------|-----|------|
| CN3126070200014 | A04 | Trần Văn An | Mì udon, Cơm Bibimbap | 342,000đ |
| CN3126070200015 | A08 | Nguyễn Thị Bình | Lunch Set Bò (2) | 518,000đ |
| CN3126070200016 | B02 | Lê Văn Cường | Oyakodon, Pepsi | 159,000đ |

- Click "Xử lý" → `handleProcessPending(order)` → chọn bàn + chuyển tab Menu

---

## 4. CONTEXT MENU — 6 THAO TÁC BÀN

Kích hoạt: Double-click bàn → popup tại vị trí chuột

```
┌──────────────────────────────────┐
│  Bàn A03 — Nguyễn Văn A          │
│  ⚡ Thao tác                     │
├──────────────────────────────────┤
│ 📝 Chọn món      (select_items)  │ ← Luôn hiển thị
│ 🔁 Chuyển bàn    (transfer)      │ ← Chỉ khi bàn CÓ khách
│ 🔗 Ghép phiếu     (merge)        │ ← Chỉ khi bàn CÓ khách
│ ✂️ Tách phiếu     (split-order)  │ ← Chỉ khi bàn CÓ khách
│ 🍽️ Tách món      (split-item)    │ ← Chỉ khi bàn CÓ khách
│ ❌ Hủy phiếu      (cancel)       │ ← Chỉ khi bàn CÓ khách
└──────────────────────────────────┘
```

> Bàn **trống** → chỉ hiện nút "Chọn món"

---

## 5. SELECTION MODE FLOW (Chuyển bàn / Ghép / Tách)

### State machine

```typescript
selectionMode: "none" | "transfer" | "merge" | "split-order" | "split-item"
sourceTableCode: string  // mã bàn nguồn
```

### Flow chung

```
1. Double-click bàn A03 → Context Menu
2. Chọn "Chuyển bàn"
   ├─ selectionMode = "transfer"
   ├─ sourceTableCode = "A03"
   └─ Toast: "Chọn bàn đích"

3. Click bàn A05 (bàn trống)
   ├─ Kiểm tra validTargetTables:
   │   - Transfer → chỉ bàn Available
   │   - Merge → chỉ bàn đang có khách
   │   - Split → bất kỳ bàn nào
   └─ Popup SweetAlert2: "Chuyển A03 → A05?"

4. Xác nhận → thực thi (in-memory) → exitSelectionMode()
```

### Visual feedback trong selection mode

| Vai trò | Hiệu ứng |
|---------|----------|
| Bàn nguồn | Viền đỏ pulsing + badge "Nguồn" |
| Bàn đích hợp lệ | Viền xanh bouncing + badge "Chọn" |
| Bàn không hợp lệ | Mờ 30% opacity |

### Chi tiết từng thao tác

#### 5.1. Chuyển bàn (Transfer)

- **Đích hợp lệ**: Bàn `Available` (trống)
- **Thực thi**: Toàn bộ order chuyển sang bàn mới, bàn cũ về "Trống"
- **State**: In-memory (`restaurantStore`)

#### 5.2. Ghép phiếu (Merge)

- **Đích hợp lệ**: Bàn đang có khách (có items)
- **Thực thi**: Gộp items của 2 bàn thành 1 order chung

#### 5.3. Tách phiếu (Split Order)

- **Đích hợp lệ**: Bất kỳ bàn nào (thường là bàn trống)
- **Thực thi**: Chuyển toàn bộ order sang bàn mới

#### 5.4. Tách món (Split Item)

- **Đích hợp lệ**: Bất kỳ bàn nào
- **Modal**: Danh sách items của bàn nguồn → checkbox chọn món → slider số lượng tách
- **Thực thi**: Tạo items mới (ID có suffix `-split-`) ở bàn đích, giảm số lượng ở bàn nguồn

#### 5.5. Hủy phiếu (Cancel)

- **Yêu cầu**: Nhập text "HỦY" + PIN Quản lý (mock: `1234`)
- **DB integration**: Gọi `supabase.rpc("hall_cancel_order_or_item")` (thao tác duy nhất có backend)
- **Kết quả**: Xóa toàn bộ order, giải phóng bàn

---

## 6. LUỒNG GỌI MÓN & GIỎ HÀNG

```
1. Chọn bàn → tab "Chi tiết" (badge đỏ = tổng số món)
2. Left panel hiện giỏ hàng:

   ┌─────────────────────────────┐
   │ Bàn: A03  |  Khách: _______ │
   ├─────────────────────────────┤
   │ Mì udon        2x   85.000  │
   │ Cơm Bibimbap   1x  120.000  │
   │ [+] [-]       [🗑️]          │
   ├─────────────────────────────┤
   │ Tạm tính:         290.000đ  │
   │ Phụ thu (5%):      14.500đ  │
   │ VAT (8%):          24.360đ  │
   │ TỔNG:             328.860đ  │
   ├─────────────────────────────┤
   │ [Gửi đi] → bếp              │
   └─────────────────────────────┘

3. Click món trong grid → mở Modal chi tiết:
   - Số lượng, ghi chú, VAT/PPV
   - Nhóm tùy chọn (topping, size...)
   - [Thêm vào giỏ]

4. Nút "Gửi đi" → sendToKitchen():
   - Thêm items vào orderGroups (tab invoice)
   - Toast xác nhận
```

---

## 7. QUY TẮC NGHIỆP VỤ & VALIDATION

| # | Quy tắc | Chi tiết |
|---|---------|----------|
| 1 | Không gọi món nếu chưa chọn bàn | Tab Menu disabled / cảnh báo |
| 2 | Tách món/Chuyển bàn: chỉ chọn bàn Available | Bàn không hợp lệ → mờ 30% + không click được |
| 3 | Ghép phiếu: chỉ chọn bàn đang có khách | validTargetTables filters by status |
| 4 | Hủy order: bắt buộc PIN Manager | Mock PIN: `1234`, phải gõ "HỦY" |
| 5 | Tính tiền | `Total = (Subtotal + Subtotal * 0.05) * 1.08` (Service 5% + VAT 8%) |
| 6 | Giảm giá: cần lý do + PIN | Discount yêu cầu manager auth |

---

## 8. QUẢN LÝ TRẠNG THÁI (STATE MANAGEMENT)

### Biến state chính

```typescript
// ReceptionOrderView.vue
activeMainTab: ref<"table_map" | "table_list" | "menu" | "invoice" | "pending">
activeOrder: reactive<{ tableCode, customerName, items[], subtotal, total }>
tableSearchQuery: ref<string>
selectedStartTime: ref<number>  // timeline slider (660-1320 min)

// useTableOperations.ts (composable)
selectionMode: ref<"none" | "transfer" | "merge" | "split-order" | "split-item">
sourceTableCode: ref<string>
showTableContextMenu: ref<boolean>
selectedTableForAction: ref<any>
contextMenuPosition: ref<{ x, y }>
```

### Dữ liệu mock

| State | Nguồn | Ghi chú |
|-------|-------|---------|
| `pendingOrders` | Hardcoded (dòng 5803–5833) | 3 đơn: A04, A08, B02 |
| `mockUnassignedReservations` | Hardcoded (dòng 8544–8638) | 5 reservation chưa xếp bàn |
| Tables | `fetchDbTables()` → `listTables()` | Nếu DB trống → `populateMockDbTables()` |
| Reservations | `fetchTodayReservations()` → `listReservations()` | Fetch 1 lần khi mount |

---

## 9. ⚠️ VẤN ĐỀ KIẾN TRÚC HIỆN TẠI

### Khách order từ tablet KHÔNG flow vào Reception

```
Customer Tablet (/customer)          Reception (/reception/order)
┌──────────────────────┐            ┌──────────────────────┐
│ Chọn bàn → Gọi món   │            │ pendingOrders =      │
│ → confirmOrder()      │            │   [MOCK A04, A08,    │
│ → supabase.rpc(       │───────❌───│    B02]              │
│   create_self_service │  KHÔNG    │                      │
│   _order)             │  KẾT NỐI  │ fetchDbTables() →    │
│                       │           │   chỉ load 1 lần      │
│ Order vào DB ✓        │           │                      │
│                       │           │ Reception KHÔNG thấy  │
└──────────────────────┘            └──────────────────────┘
```

| Vấn đề | Chi tiết |
|--------|----------|
| Không có realtime | Không có `supabase.channel()` nào. Order từ customer không tự xuất hiện |
| `pendingOrders` là mock | 3 đơn "chưa xử lý" hardcoded, không đọc từ DB |
| Không poll | Không có `setInterval` fetch orders mới |
| Transfer/merge in-memory | Chỉ sửa `restaurantStore` trong RAM, không ghi DB |
| Chỉ cancel có DB | `supabase.rpc("hall_cancel_order_or_item")` — duy nhất |

### Flow đúng cần có

```
Customer Tablet                     Reception
┌──────────────────────┐            ┌──────────────────────┐
│ confirmOrder()       │            │ Realtime subscription │
│ → RPC insert order   │──→ DB ────→│ .on('INSERT', orders) │
│                       │            │ → toast "Đơn mới!"   │
│                       │            │ → pendingOrders.push │
│                       │            │ → table đổi màu đỏ   │
└──────────────────────┘            └──────────────────────┘
```

---

## 10. THAM CHIẾU DÒNG CODE

| Thành phần | Dòng | File |
|-----------|------|------|
| Header / Tabs | 64–264 | ReceptionOrderView.vue |
| Left Panel | 267–918 | ReceptionOrderView.vue |
| Footer | 880–918 | ReceptionOrderView.vue |
| Table Map | 924–1140 | ReceptionOrderView.vue |
| Menu Tab | 1374–1634 | ReceptionOrderView.vue |
| Invoice Tab | 1636–2527 | ReceptionOrderView.vue |
| Pending Tab | 2530–2598 | ReceptionOrderView.vue |
| Item Detail Modal | 2640–3500 | ReceptionOrderView.vue |
| Destructure composable | 4905–4960 | ReceptionOrderView.vue |
| Mock pending orders | 5803–5833 | ReceptionOrderView.vue |
| Table status colors | 8836 | ReceptionOrderView.vue |
| Mock reservations | 8544–8638 | ReceptionOrderView.vue |
| Selection mode logic | 87–340 | useTableOperations.ts |
| Context menu actions | 103–170 | useTableOperations.ts |
| Transfer/Merge/Split exec | 180–570 | useTableOperations.ts |
| Cancel exec | 570–680 | useTableOperations.ts |
