# Mô tả trang Dashboard Lễ tân (/reception/dashboard)

**Ngày tạo:** 31/07/2026  
**URL:** `http://localhost:5173/reception/dashboard`  
**File source chính:** `src/views/reception/ReceptionDashboardView.vue`  
**Layout:** `src/layouts/ReceptionLayout.vue`

---

## 1. Tổng quan bố cục

Trang Dashboard Lễ tân sử dụng layout 2 cột chính:

- **Sidebar bên trái** (width: 256px / `w-64`): Thanh điều hướng dọc, nền trắng, có border-right và shadow nhẹ.
- **Main content bên phải** (flex-1): Chứa header trên cùng và vùng nội dung cuộn được (`overflow-auto`, padding `p-6`).

Nền tổng thể: `bg-gray-50` (xám nhạt).  
Nền nội dung dashboard: `bg-[#FAF3E8]` (kem/nâu rất nhạt) với chữ màu `#3D2817` (nâu đậm).  
Font: `font-sans` (mặc định), số liệu dùng `font-mono`.

---

## 2. Sidebar điều hướng (ReceptionLayout.vue)

Sidebar chia thành các nhóm, mỗi nhóm có tiêu đề uppercase `text-[11px]` font-extrabold text-gray-500:

### 2.1. Logo
- Phía trên cùng: TextLogo (component `TextLogo`).

### 2.2. Nhóm "Hoạt động" (Activity)
| Icon | Tên mục | Route |
|------|---------|-------|
| LayoutDashboard | Dashboard | `/reception/dashboard` |

### 2.3. Nhóm "Bán hàng" (Sales)
| Icon | Tên mục | Route |
|------|---------|-------|
| Calendar | Chi tiết đặt bàn | `/reception/reservation-detail` |
| Utensils | Gọi món | `/reception/order` |
| Grid | Sơ đồ tầng | `/reception/floors` |
| Store | Nhà hàng | `/reception/order` |

### 2.4. Nhóm "Nghiệp vụ khác" (Other Services)
| Icon | Tên mục | Loại |
|------|---------|------|
| BadgePlus | Thu khác | Button → mở modal |
| BadgeMinus | Chi khác | Button → `/reception/other-expense` |
| SettingsIcon | Cấu hình | Button → mở modal |

### 2.5. Nhóm "Quản trị" (Management)
| Icon | Tên mục | Route |
|------|---------|-------|
| Receipt | Phiếu | `/reception/reports` |
| BarChart3 | Báo cáo | `/reception/revenue-overview` |
| Coffee | Quản lý menu | `/reception/menu-management` |

### 2.6. Nhóm "Ca làm việc" (Shift)
| Icon | Tên mục | Route |
|------|---------|-------|
| LockOpen | Mở ca | `/reception/shift-summary?action=open` |
| ClipboardList | Tổng kết ca | `/reception/shift-summary` |
| LogOut | Ra ca | `/reception/close-shift` |

### 2.7. User Profile (cuối sidebar)
- Card nền `bg-gray-100` bo góc, hiển thị avatar (sticker), tên người dùng (`profile?.full_name`), và role label.
- Click vào mở dropdown với tùy chọn "Đăng xuất" (icon logout, text-red-600).

---

## 3. Header (ReceptionLayout.vue)

- Chiều cao `h-16`, nền trắng, border-bottom, shadow-sm.
- **Bên trái:** Tiêu đề trang (font-bold text-xl). Khi ở dashboard: hiển thị `t('reception.title.dashboard')`.
- **Bên phải:**
  - Branch label (text-sm font-semibold text-gray-500, ẩn trên màn hình nhỏ).
  - LanguageSwitcher component (chuyển đổi VI/JA/EN).
  - Avatar người dùng (w-8 h-8 rounded-full).

---

## 4. Widget Ngày/Giờ (phía trên nội dung dashboard)

Card nền trắng, bo góc `rounded-2xl`, padding `p-6`, border cam nhạt (`border-[#E8772E]/10`), shadow-sm.

- **Bên trái:**
  - Icon Clock trong khung `bg-[#E8772E]/10` bo góc `rounded-xl`, màu cam `#E8772E`, kích thước `w-8 h-8`.
  - Giờ hiện tại: `text-3xl font-black font-mono` — cập nhật mỗi giây, định dạng `HH:mm:ss` (24h).
  - Ngày hiện tại: `text-sm font-bold text-gray-500` — định dạng `Thứ X, DD tháng MM, YYYY` (tiếng Việt).

- **Bên phải:**
  - Ô Chi nhánh: nền `bg-gray-100`, border, label "CHI NHÁNH" uppercase `text-[10px]`, giá trị tên chi nhánh (lấy từ DB `branches.name`).
  - Ô Hệ thống: nền `bg-green-50`, border xanh, label "HỆ THỐNG", giá trị "Đã kết nối" với chấm tròn xanh pulse.

---

## 5. Banner Trạng thái Ca làm việc

Hiển thị một trong hai trạng thái:

### 5.1. Khi có ca đang mở (`activeShift` tồn tại)
- Nền `bg-green-50`, border-2 xanh `border-green-200`, bo góc `rounded-xl`, shadow-sm.
- Chấm tròn xanh pulse + text:
  - Label: "CA ĐANG MỞ" (uppercase, xanh-700, `text-xs font-bold`).
  - Nội dung: "Bắt đầu lúc **HH:mm** — Số dư đầu ca: **XXXđ**".
- **Nút bên phải:**
  - "Chi tiết ca" (RouterLink → `/reception/close-shift`, nền xanh-600, text trắng, `text-xs font-bold`).
  - "Đóng ca" (button, nền đỏ-600, text trắng, mở `CloseShiftModal`).

### 5.2. Khi không có ca mở
- Nền `bg-yellow-50`, border-2 vàng `border-yellow-200`.
- Chấm tròn vàng pulse + text:
  - Label: "CHƯA MỞ CA".
  - Nội dung: "Vui lòng mở ca để bắt đầu".
- **Nút:** "Mở ca" (nền vàng-600, text trắng, mở `OpenShiftModal`).

---

## 6. Lưới nội dung chính (Grid 4 cột)

Bố cục: `grid grid-cols-1 lg:grid-cols-4 gap-6`.
- Cột 1–3 (`lg:col-span-3`): Nội dung chính.
- Cột 4 (`lg:col-span-1`): Bảng thông báo (notifications panel).

---

## 7. 4 Thẻ thống kê (Stat Cards) — Cột 1–3

Grid `grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4`. Mỗi card: nền trắng, border cam nhạt, `rounded-2xl p-5 shadow-sm`, hover effect (`hover:shadow-md hover:scale-[1.02]`), có `cursor-pointer` scroll đến section tương ứng.

### Card 1: Bàn đang sử dụng
- Label: "BÀN ĐANG SỬ DỤNG" (`text-xs font-bold text-gray-500 uppercase`).
- Số: `diningTables.length` — `text-3xl font-black text-[#E8772E]`.
- Sub: "+2 so với giờ trước" (xanh-600, icon TrendingUp).
- Icon: Utensils trong khung `w-12 h-12 rounded-2xl bg-[#E8772E]/10`.
- Click → scroll đến `#active-tables-section`.

### Card 2: Chờ thanh toán
- Label: "CHỜ THANH TOÁN".
- Số: `pendingPaymentsCount` — `text-3xl font-black text-red-600`.
- Sub: "Tạm tính: XXXđ" (đỏ-500).
- Icon: CreditCard trong khung đỏ nhạt `bg-red-50`, border đỏ.
- Click → scroll đến `#active-tables-section`.

### Card 3: Đặt bàn hôm nay
- Label: "ĐẶT BÀN HÔM NAY".
- Số: `reservations.length` — `text-3xl font-black text-blue-600`.
- Sub: "Sắp tới: X đặt bàn" (xanh dương-500).
- Icon: Calendar trong khung xanh dương nhạt.
- Click → scroll đến `#reservations-section`.

### Card 4: Doanh thu hôm nay
- Label: "DOANH THU HÔM NAY".
- Số: `dashboardExtraStats.totalRevenue` (15.750.000đ) — `text-2xl font-black text-green-600`.
- Sub: "AOV: 1.250.000đ · 87 khách" (xám-500).
- Icon: Wallet trong khung xanh lá nhạt.
- Click → scroll đến `#revenue-chart-section`.

---

## 8. Nút Thao tác nhanh (Quick Actions)

Card nền trắng, `rounded-2xl p-6 shadow-sm`.
- Tiêu đề: "THAO TÁC NHANH" với icon Briefcase cam.
- Grid `grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3`.

| # | Icon | Label | Màu nút | Hành động |
|---|------|-------|---------|-----------|
| 1 | Utensils | Nhà hàng | Cam `#E8772E` | → `/reception/order` |
| 2 | BadgePlus | Thu khác | Xanh lá `#4CAF50` | Mở modal Thu khác |
| 3 | BadgeMinus | Chi khác | Đỏ `#F44336` | → `/reception/other-expense` |
| 4 | Settings | Cấu hình | Tím `#9C27B0` | Mở modal Cấu hình |
| 5 | Receipt | Phiếu | Vàng `#FF9800` | → `/reception/reports` |
| 6 | BarChart3 | Báo cáo | Cam nhạt `#FFB74D` | → `/reception/revenue-overview` |
| 7 | LogOut | Ra ca | Tím `#8E24AA` | Xác nhận Swal → `/reception/close-shift` |

Mỗi nút: `min-h-[110px]`, icon tròn `w-10 h-10` nền màu đặc chữ trắng, label `text-xs font-bold`, hover scale 1.05.

---

## 9. Tổng kết Ca hiện tại (Shift Summary)

Card nền trắng, `rounded-2xl p-6 shadow-sm`.
- Tiêu đề: "TỔNG KẾT CA HIỆN TẠI" với icon Clock tím `#8E24AA`.
- Badge bên phải: chỉ báo ca (Ca sáng / Ca chiều / Ca tối) nền tím `bg-purple-100 text-purple-700`.

Khi có ca mở, hiển thị grid 4 cột (`grid-cols-2 md:grid-cols-4`):

| Trường | Nội dung | Màu |
|--------|----------|-----|
| Giờ bắt đầu | `formatDateTime(activeShift.opened_at)` — `HH:mm` | Xám nền `bg-gray-50` |
| Số dư đầu ca | `opening_cash` dạng `XXXđ` font-mono | Xám nền `bg-gray-50` |
| Doanh thu hiện tại | `shiftRevenue` dạng `XXXđ` font-mono | Xanh `bg-green-50 border-green-200` |
| Đơn đã xử lý | `shiftOrdersCount` + " đơn" | Xanh dương `bg-blue-50 border-blue-200` |

Khi không có ca: text "Không có ca nào đang hoạt động".

---

## 10. Biểu đồ Doanh thu 7 ngày + Món bán chạy

Grid `grid-cols-1 lg:grid-cols-3 gap-6` (id: `revenue-chart-section`).

### 10.1. Biểu đồ doanh thu (2 cột)
- Card nền trắng, `rounded-2xl p-6 shadow-sm`.
- Tiêu đề: "DOANH THU 7 NGÀY GẦN NHẤT" với icon TrendingUp cam.
- Badge: "Tổng: XXXđ" nền xanh `bg-green-100 text-green-700`.
- Biểu đồ đường (Chart.js `type: 'line'`) chiều cao `h-64`:
  - Đường màu cam `#E8772E`, fill `rgba(232,119,46,0.08)`, tension 0.35.
  - Điểm (points): nền cam, viền trắng, radius 4, hover radius 6.
  - Trục X: ngày `DD/MM` (vi-VN), font size 10, màu xám.
  - Trục Y: định dạng rút gọn (VD: `15tr`), grid `#f3f4f6`.
  - Tooltip: "Doanh thu (đ): XXXđ".
- Dữ liệu mock (7 ngày 13/07–19/07/2026):
  - 13/07: 12.500.000đ (45 đơn)
  - 14/07: 15.800.000đ (52 đơn)
  - 15/07: 14.200.000đ (48 đơn)
  - 16/07: 18.900.000đ (61 đơn)
  - 17/07: 22.100.000đ (73 đơn)
  - 18/07: 19.500.000đ (65 đơn)
  - 19/07: 15.750.000đ (52 đơn)

### 10.2. Món bán chạy (1 cột)
- Card nền trắng, `rounded-2xl p-6 shadow-sm`.
- Tiêu đề: "MÓN BÁN CHẠY" với icon Award cam.
- Danh sách dọc (`space-y-3`), mỗi item:
  - Số thứ tự trong khung `w-7 h-7 rounded-lg`:
    - Huy chương Vàng (#1): `bg-yellow-100 text-yellow-700`
    - Huy chương Bạc (#2): `bg-gray-200 text-gray-600`
    - Huy chương Đồng (#3): `bg-orange-100 text-orange-700`
    - Các hạng khác: `bg-gray-100 text-gray-400`
  - Tên món (`text-xs font-bold truncate`) + số suất + doanh thu (`text-[10px] text-gray-500`).
- Dữ liệu mock (top 5):
  1. Vé Người Lớn 1380 — 45 suất · 62.100.000đ
  2. Set Lunch Bò Cao Cấp — 28 suất · 8.372.000đ
  3. Nước ngọt uống không giới hạn — 67 suất · 5.360.000đ
  4. Set Tiệc Chiều Đãi Deluxe — 15 suất · 8.985.000đ
  5. Salad Cá Ngừ — 32 suất · 4.000.000đ

---

## 11. Bảng Danh sách Bàn đang phục vụ (Active Tables)

Section (id: `active-tables-section`): Card nền trắng, `rounded-2xl shadow-sm overflow-hidden`.
- Header: nền `bg-gray-50`, tiêu đề "DANH SÁCH BÀN ĐANG PHỤC VỤ" với icon Utensils cam, badge số lượng bàn (nền cam nhạt `bg-[#E8772E]/10 text-[#E8772E]`).
- Bảng (`overflow-x-auto`):

| Cột | Header | Nội dung |
|-----|--------|----------|
| Bàn | "BÀN" | Mã bàn trong khung `w-10 h-10 rounded-xl bg-orange-100`, font-black |
| Khách | "KHÁCH" | `getTableGuests(table)` + " người", font-bold |
| Thời gian ngồi | "GIỜ NHẬN BÀN" | Badge màu theo thời gian: <30ph xanh, 30–60ph vàng, >60ph đỏ |
| Món đã gọi | "MÓN ĐÃ GỌI" | `getTableItemsCount` + " món" (hoặc "Đang tải...") |
| Tổng tiền | "TỔNG TIỀN" (right-align) | `getTableTotal` dạng `XXXđ`, font-black (hoặc "Đang tải...") |
| Hành động | "HÀNH ĐỘNG" (center) | 2 nút: "Xem" (xám, icon Eye → `/reception/order`) + "Thanh toán" (cam `#E8772E` → `/reception/checkout/{id}`) |

- Khi không có bàn: row colspan=6, text "Không có bàn nào đang hoạt động".

---

## 12. Bảng Đặt bàn hôm nay (Reservations)

Section (id: `reservations-section`): Card nền trắng, `rounded-2xl shadow-sm overflow-hidden`.
- Header: nền `bg-gray-50`, tiêu đề "ĐẶT BÀN HÔM NAY" với icon Calendar xanh dương, badge số lượng (nền `bg-blue-100 text-blue-700`).
- Bảng:

| Cột | Header | Nội dung |
|-----|--------|----------|
| Mã đặt chỗ | "MÃ ĐẶT CHỖ" | `booking_code` font-mono font-bold (hoặc "—") |
| Khách | "KHÁCH / SỐ ĐIỆN THOẠI" | Tên khách (bold) + SĐT (xám, nhỏ) — lấy từ `customer_snapshot` |
| Giờ đặt | "GIỜ ĐẶT" | `reservation_time` slice(0,5) font-mono (hoặc "—") |
| Số người | "SỐ NGƯỜI" | `guests` + " người" |
| Trạng thái | "TRẠNG THÁI" | Badge bo tròn theo status (xem bảng màu bên dưới) |
| Hành động | "HÀNH ĐỘNG" (center) | "Chi tiết" (xanh dương) + "Xác nhận" (xanh lá, chỉ khi Pending) + "Hủy" (đỏ, chỉ khi Pending) |

- Trạng thái đặt bàn và màu badge:
  - Pending → "Chờ nhận bàn" (vàng)
  - Arrived → "Đã đến" (xanh dương)
  - Dining → "Đang dùng bữa" (xanh lá)
  - Completed → "Hoàn thành" (xám)
  - Cancelled → "Đã hủy" (đỏ)
- Khi không có đặt bàn: row colspan=6, text "Không có đặt bàn nào hôm nay".

---

## 13. Bảng Thông báo (Notifications Panel) — Cột 4

Panel sticky `top-6`, chiều cao `h-[calc(100vh-12rem)]`, nền trắng, `rounded-2xl shadow-sm overflow-hidden flex flex-col`.

### 13.1. Header
- Nền `bg-gray-50`, border-bottom.
- Icon Bell cam `w-5 h-5` với badge đỏ pulse hiển thị số thông báo chưa đọc (`unreadCount`).
- Tiêu đề: "THÔNG BÁO" (`font-extrabold text-sm`).
- Nút "Xem thêm..." / "Thu gọn" (toggle `showAllNotifications`).

### 13.2. Danh sách thông báo
- Vùng cuộn `flex-1 overflow-y-auto`, divide-y.
- Mỗi item:
  - Nếu chưa đọc: nền cam nhạt `bg-orange-50/30`, border cam, có chấm tròn cam `bg-[#E8772E]` ở góc trên phải.
  - Nếu đã đọc: nền trắng, border xám.
  - **Type badge:** uppercase `text-[10px] font-extrabold` với border:
    - Hết hàng (out_of_stock): đỏ
    - Sắp hết (low_stock): vàng
    - Đặt bàn (booking): xanh dương
    - Thanh toán (payment): xanh lá
  - **Priority badge** (nếu high): "KHẨN CẤP" nền đỏ `bg-red-100 text-red-700`.
  - **Tiêu đề:** `text-xs font-extrabold`, line-clamp-2.
  - **Nội dung:** `text-[11px] text-gray-500`, line-clamp-3.
  - **Footer:** Thời gian (font-mono, icon Clock nhỏ) + nút "Đọc" (nếu chưa đọc).
- Mặc định hiển thị 5 thông báo, bấm "Xem thêm..." để xem tất cả.
- Khi không có thông báo: "Không có thông báo".

### 13.3. Mock notifications (local)
4 thông báo mock được thêm vào danh sách:
1. [Hết hàng] "Thông báo hết hàng" — Dạ dày bò (tổ ong) sốt tare — Khẩn cấp — 11:37
2. [Hết hàng] "Thông báo hết hàng" — Dạ dày bò (tổ ong) sốt miso cay — Khẩn cấp — 11:37
3. [Sắp hết] "Có thể bán" — Dorayaki Kem Trứng — Đã đọc — 11:37
4. [Hết hàng] "Thông báo hết hàng" — Dorayaki Kem Trứng — 11:01

### 13.4. Tính năng âm thanh
- Khi có thông báo mới chưa đọc với priority `high`, hệ thống phát âm thanh double-beep (Web Audio API: nốt C5 → E5, mỗi beep 150ms).
- Tự động refresh thông báo mỗi 30 giây.

---

## 14. Modal Mở ca (OpenShiftModal)

Component riêng `src/components/reception/OpenShiftModal.vue`.
- Props: `is-open`, `cashier-name`, `loading`.
- Events: `close`, `confirm(openingCash: number)`.
- Mở khi click nút "Mở ca" trên banner vàng.

---

## 15. Modal Đóng ca (CloseShiftModal)

Component riêng `src/components/reception/CloseShiftModal.vue`.
- Props: `is-open`, `shift-start-time`, `system-expected-cash`, `card-revenue`, `transfer-revenue`, `loading`.
- Events: `close`, `confirm({ actualCash, notes, managerPin? })`.
- Mở khi click nút "Đóng ca" trên banner xanh.
- Sau khi đóng ca thành công: hiển thị Swal với chênh lệch tiền mặt (actualCash - expectedCash).

---

## 16. Modal Thu khác (Other Income)

Modal toàn màn hình `fixed inset-0 bg-black/60 backdrop-blur-sm`, nội dung `max-w-[600px]`.
- **Header:** Nền xanh đậm `#1a5276`, text trắng, tiêu đề "THU KHÁC".
- **Creator Info:** Nền `#f5f5f5`, 2 cột:
  - Người tạo: "Dương Thị Mộng"
  - Ngày lập: input text (mặc định "02/07/2026 15:08:41")
- **Form:**
  - Đối tượng (*) — text input + nút "..." (auto-fill "Khách vãng lai")
  - Loại thu (*) — select: Thu Khác / Tiền đặt cọc / Hoàn tiền
  - Khoản thu (*) — select: Rút tiền dư / Điều chỉnh / Khác
  - Tiền thu (*) — input số, nền hồng nhạt `bg-[#FFF0F0]`, border đỏ, font-mono right-align
  - Lý do — text input
  - Số chứng từ — text input (placeholder "Hệ thống tự động phát sinh")
  - Mã đặt chỗ — text input
  - Tiền mặt — checkbox
- **Footer:** 3 nút:
  - "Lưu và in" (xanh lá `#4CAF50`)
  - "Lưu" (vàng `#FF9800`)
  - "Bỏ qua" (đỏ `#F44336`)

---

## 17. Modal Cấu hình (Settings)

Modal toàn màn hình, nội dung `max-w-[500px]`.
- **Header:** Nền `#1a5276`, text trắng, tiêu đề "CẤU HÌNH".
- **Form:**
  - Tên đăng nhập — text input (mặc định "mo")
  - Mật khẩu — password input
- **Footer:** 2 nút:
  - "Xác nhận" (xanh teal `#4DB6AC`)
  - "Bỏ qua" (đỏ `#E57373`)

---

## 18. Tính năng Realtime

Dashboard订阅 Supabase realtime cho các bảng:
- `tables` — cập nhật danh sách bàn
- `reservations` — cập nhật danh sách đặt bàn
- `notifications` — cập nhật thông báo
- `orders` — cập nhật tổng tiền từng bàn
- `order_items` — cập nhật tổng tiền từng bàn

Khi có thay đổi, tự động gọi lại `fetchAll()` để refresh toàn bộ dữ liệu.

---

## 19. Bảng màu thiết kế (Color Scheme)

| Màu | Hex | Sử dụng |
|-----|-----|---------|
| Cam chính | `#E8772E` | Logo, icon, accent, border nhạt, nút chính |
| Nâu đậm | `#3D2817` | Text chính |
| Kem/nâu nhạt | `#FAF3E8` | Nền dashboard |
| Xanh lá | `#4CAF50` | Thành công, doanh thu, nút lưu |
| Đỏ | `#F44336` | Lỗi, cảnh báo, nút hủy |
| Vàng | `#FF9800` | Cảnh báo, chờ xử lý |
| Xanh dương | `#3B82F6` | Đặt bàn, thông tin |
| Tím | `#9C27B0` / `#8E24AA` | Cấu hình, ca làm việc |
| Xanh teal | `#4DB6AC` | Xác nhận |
| Xanh đậm | `#1a5276` | Header modal |

---

## 20. Công nghệ sử dụng

- **Framework:** Vue 3 (Composition API, `<script setup>`)
- **UI:** Tailwind CSS + lucide-vue-next (icons)
- **Biểu đồ:** Chart.js (line chart)
- **Backend:** Supabase (Postgres RPC: `hall_list_tables`, `hall_list_reservations_by_date`, `hall_get_checkout_totals`)
- **State:** Pinia (`shiftStore`), composables (`useAuth`, `useBranch`, `useReservation`, `useNotification`, `useRealtime`)
- **i18n:** vue-i18n (VI / JA / EN)
- **Thông báo UI:** SweetAlert2 (Swal)
- **Realtime:** Supabase Realtime (watchTable)
