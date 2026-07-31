# 📋 TỔNG HỢP NGHIỆP VỤ HỆ THỐNG POS NGƯU CÁT

**Ngày:** Thứ Năm, 30/07/2026  
**Dự án:** POS Ngưu Cát (Vue 3 + TypeScript + Supabase + Pinia + Tailwind CSS)  
**Phạm vi:** Tổng hợp toàn bộ nghiệp vụ từ thư mục `src/`

---

## MỤC LỤC

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Kiến trúc & Công nghệ](#2-kiến-trúc--công-nghệ)
3. [Domain Model & Cơ sở dữ liệu](#3-domain-model--cơ-sở-dữ-liệu)
4. [Module Lễ tân (Reception / POS)](#4-module-lễ-tân-reception--pos)
5. [Module Bếp (Kitchen)](#5-module-bếp-kitchen)
6. [Module Khách hàng (Customer Self-Service)](#6-module-khách-hàng-customer-self-service)
7. [Module Thu mua (Purchasing)](#7-module-thu-mua-purchasing)
8. [Module Kế toán (Accounting)](#8-module-kế-toán-accounting)
9. [Module CRM](#9-module-crm)
10. [Module Marketing](#10-module-marketing)
11. [Module Quản trị (Admin / Manager / Superadmin)](#11-module-quản-trị-admin--manager--superadmin)
12. [Module Ban Giám Đốc (BOD)](#12-module-ban-giám-đốc-bod)
13. [Module Sảnh (Hall) & Nhân viên (Staff)](#13-module-sảnh-hall--nhân-viên-staff)
14. [Business Rules Engine](#14-business-rules-engine)
15. [Quy trình nghiệp vụ chính](#15-quy-trình-nghiệp-vụ-chính)
16. [Hệ thống đa ngôn ngữ (i18n)](#16-hệ-thống-đa-ngôn-ngữ-i18n)
17. [Design System](#17-design-system)
18. [Ghi chú kiến trúc](#18-ghi-chú-kiến-trúc)

---

## 1. TỔNG QUAN HỆ THỐNG

**POS Ngưu Cát** là giải pháp quản lý nhà hàng BBQ buffet toàn diện cho chuỗi nhà hàng Nhật Bản (Ushiyoshi/Yakiniku). Hệ thống phục vụ toàn bộ vòng đời vận hành nhà hàng: từ tiếp khách, gọi món, phục vụ, thanh toán, đến quản lý bếp, kho, thu mua, kế toán, CRM và marketing.

### 1.1 Vai trò người dùng (16+ roles)

| Role | Mô tả | Modules truy cập |
|------|-------|-----------------|
| `superadmin` | Siêu quản trị (đa tenant) | Tất cả modules |
| `admin` | Quản trị hệ thống | admin, manager, reception, staff, hall, kitchen, purchasing, accounting, crm, marketing, bod, tablet |
| `manager` | Quản lý chi nhánh | manager, reception, staff, hall |
| `reception` | Lễ tân / Thu ngân (POS chính) | reception, hall |
| `staff` | Nhân viên phục vụ | staff, hall |
| `hall` | Quản lý sảnh | hall |
| `kitchen` | Bếp (KDS) | kitchen |
| `purchasing` | Thu mua | purchasing |
| `accounting` | Kế toán | accounting |
| `crm` | Chăm sóc khách hàng | crm |
| `marketing` | Marketing | marketing |
| `bod` | Ban giám đốc | bod |
| `customer` | Khách hàng (tablet tự phục vụ) | customer |
| `tablet` | Máy tính bảng | tablet |

### 1.2 Đặc điểm chính

- **3 ngôn ngữ:** 🇻🇳 Việt / 🇬🇧 Anh / 🇯🇵 Nhật
- **Dual-mode:** Khi Supabase chưa cấu hình → tự fallback sang mock data + localStorage
- **RPC-Only:** Truy cập DB qua `supabase.rpc()` thay vì query trực tiếp
- **Dark theme POS** + **Dark wood customer** — hai giao diện riêng biệt
- **Realtime:** Supabase Realtime subscriptions (đang phát triển)

---

## 2. KIẾN TRÚC & CÔNG NGHỆ

### 2.1 Tech Stack

| Lớp | Công nghệ |
|-----|-----------|
| **UI Framework** | Vue 3.5 (Composition API, `<script setup>`) |
| **Ngôn ngữ** | TypeScript 5.4 |
| **Build** | Vite 8.0 |
| **State** | Pinia 3.0 |
| **Routing** | Vue Router 4.3 |
| **i18n** | vue-i18n 9.14 |
| **Backend** | Supabase (PostgreSQL + Auth + Realtime) |
| **CSS** | Tailwind CSS 3.4 + tailwindcss-animate |
| **Icons** | lucide-vue-next |
| **Charts** | Chart.js 4.5, D3.js 7.9 |
| **Diagrams** | Mermaid 11.16 |
| **Alerts** | SweetAlert2 11.26 |
| **Dates** | date-fns 3.6 |
| **Validation** | Zod 3.22 |
| **Drag & Drop** | vue-draggable-plus 0.6 |
| **OCR** | Tesseract.js 7.0 |
| **Testing** | Playwright 1.61 |

### 2.2 Cấu trúc thư mục `src/`

```
src/
├── api/              # API endpoints (procurement.api.ts)
├── components/       # UI components (customer/, reception/, shared/, requisition/)
├── composables/      # Business logic (47 composables)
├── data/             # Reference data (menuData, customerAreaData, mock-data)
├── design-system/    # Design tokens (colors, requisitionTokens)
├── helpers/          # Helpers (i18n.ts)
├── layouts/          # 14 layouts theo role
├── lib/              # Library/integration code
├── locales/          # i18n: vi.ts, en.ts, ja.ts
├── router/           # index.ts + hall.ts
├── services/         # customerApi.ts
├── stores/           # 11 Pinia stores
├── styles/           # globals.css, styles.css, orderingScreen.css
├── types/            # database.ts, models.ts, customer.ts
├── utils/            # packageRules.ts, route.ts, ...
├── views/            # 14 module directories + 4 top-level views
├── App.vue
├── main.ts
└── env.d.ts
```

### 2.3 Routing & Layout

| Prefix | Layout | Module |
|--------|--------|--------|
| `/login` | — | Đăng nhập |
| `/select-branch` | — | Chọn chi nhánh |
| `/admin` | AdminLayout | Quản trị hệ thống |
| `/hall` | HallDashboard | Quản lý sảnh |
| `/kitchen` | KitchenLayout | Bếp (KDS) |
| `/purchasing` | PurchasingLayout | Thu mua |
| `/accounting` | AccountingLayout | Kế toán |
| `/tablet` | TabletLayout | Máy tính bảng khách |
| `/superadmin` | SuperadminLayout | Siêu quản trị |
| `/manager` | ManagerLayout | Quản lý chi nhánh |
| `/reception` | ReceptionLayout | Lễ tân (POS chính) |
| `/crm` | CRMLayout | CRM |
| `/staff` | StaffLayout | Nhân viên |
| `/customer` | CustomerLayout | Khách hàng (self-service) |

Route guard dựa trên `ROUTE_ROLES` map — mỗi role chỉ truy cập được các module được phép.

### 2.4 Xác thực (Auth)

- **`useAuth.ts`** — state xác thực trung tâm (singleton pattern, module-scoped refs)
- Hỗ trợ: Supabase Auth (thật) + Mock Auth (dev mode)
- `useAuth().init()` gọi trong `main.ts` để bootstrap session
- `getHomeRouteForRole()` / `getFallbackRouteForRole()` điều hướng theo role

---

## 3. DOMAIN MODEL & CƠ SỞ DỮ LIỆU

### 3.1 Sơ đồ thực thể (Entity Relationship)

```
Branch (Chi nhánh)
  ├── User (Nhân viên) → Role (Vai trò)
  ├── Table (Bàn) → Zone/Area (Khu vực)
  ├── MenuCategory → MenuSubCategory → MenuItem
  ├── Package (Gói buffet) → PackageItem → MenuItem
  ├── Reservation (Đặt bàn) → Customer
  ├── Order (Đơn hàng) → OrderItem → MenuItem
  │   └── Bill (Hóa đơn) → Payment (Thanh toán)
  ├── Invoice (Hóa đơn đỏ) → AppliedVoucher
  ├── CrmSurvey (Khảo sát CRM) → Customer
  ├── Shift (Ca làm việc) → Payment
  ├── Voucher (Phiếu giảm giá)
  ├── Customer (Khách hàng)
  ├── AuditEvent (Nhật ký kiểm toán)
  └── BranchSetting (Cấu hình chi nhánh)
```

### 3.2 Bảng数据库 chính

| Bảng | Mô tả | Trường nổi bật |
|------|-------|----------------|
| `branches` | Chi nhánh | branch_id, name, address |
| `users` | Người dùng | email, role, branch_id |
| `tables` | Bàn | table_code, area, status, capacity |
| `customers` | Khách hàng | name, phone, zalo, tags, marketing_consent |
| `menu_categories` | Danh mục menu | name (i18n), display_order |
| `menu_subcategories` | Danh mục con | category_id, name (i18n) |
| `menu_items` | Món ăn | name (i18n), price, category_id, is_active |
| `packages` | Gói buffet | type, price, items[] |
| `package_items` | Món trong gói | package_id, menu_item_id, config |
| `reservations` | Đặt bàn | customer_id, table_id, time, status |
| `orders` | Đơn hàng | table_id, session_id, status, subtotal, total |
| `order_items` | Món trong đơn | order_id, menu_item_id, qty, price, status |
| `bills` | Hóa đơn | order_id, total, service_charge, vat |
| `payments` | Thanh toán | bill_id, method, amount |
| `invoices` | Hóa đơn đỏ | tax_code, company, amount |
| `crm_surveys` | Khảo sát CRM | table_id, customer_id, status |
| `shifts` | Ca làm việc | opening_cash, closing_cash, status |
| `vouchers` | Voucher | type, value, valid_until |
| `audit_events` | Nhật ký audit | user_id, action, entity, timestamp |
| `notifications` | Thông báo | branch_id, type, payload |
| `branch_settings` | Cấu hình chi nhánh | key, value (JSONB) |
| `system_events` | Sự kiện hệ thống | type, payload |
| `bod_approvals` | Phê duyệt BOD | type, status, requester_id |

### 3.3 Enums

| Enum | Giá trị |
|------|---------|
| `UserRole` | superadmin, admin, manager, reception, staff, hall, kitchen, purchasing, accounting, crm, marketing, bod, customer, tablet, ... |
| `TableStatus` | available, reserved, arrived, serving, occupied |
| `ReservationStatus` | pending, confirmed, seated, completed, cancelled |
| `OrderStatus` | draft, confirmed, cooking, served, completed, cancelled |
| `OrderItemStatus` | Pending, Preparing, Served, Cancelled |
| `PaymentMethod` | cash, card, transfer, other |
| `ShiftStatus` | open, closed |
| `PackageType` | 1390, 1150, 680, 490, 380, kids, lau, 550jp, drink, ... |
| `RevenueType` | food, beverage, service, other |
| `VoucherType` | percent, fixed, buy_x_get_y |
| `CrmSurveyStatus` | not_started, assigned, in_progress, completed, skipped, customer_refused, expired, late_submitted |
| `InvoiceStatus` | draft, issued, cancelled, paid |

### 3.4 JSONB interfaces

| Interface | Mô tả |
|-----------|-------|
| `I18nString` | `{ vi, en, ja }` — chuỗi đa ngôn ngữ |
| `CustomerPreferences` | Tùy chọn khách hàng |
| `PackageItemConfig` | Cấu hình món trong gói (eligible, surcharge, etc.) |
| `AppliedVoucher` | Voucher đã áp dụng |
| `TaxInfo` | Thông tin thuế |
| `ShiftNotes` | Ghi chú ca |
| `BookingInfo` | Thông tin đặt bàn |

---

## 4. MODULE LỄ TÂN (RECEPTION / POS)

Là module POS chính — trung tâm vận hành nhà hàng. Quản lý sơ đồ bàn, gọi món, thanh toán, ca làm việc.

### 4.1 Pinia Store: `restaurantStore.ts`

| Entity | Mô tả |
|--------|-------|
| `TableInfo` | Thông tin bàn (code, area, status, capacity) |
| `AreaInfo` | Thông tin khu vực |
| `Booking` | Thông tin đặt bàn |
| `CartItem` | Món trong giỏ hàng |
| `TableOrder` | Đơn hàng tạm thời theo bàn |

**10 khu vực:** A (chính), B (VIP), C (ban công), R (phòng riêng), T (sân thượng), Capichi, Shopee, BE, Grab, Catalog — tổng 57 bàn.

**Trạng thái bàn:** Available (trống), Reserved (đã đặt), Arrived (đã đến), Serving (đang phục vụ).

**Business rules:**
- Mỗi bàn có một `TableOrder` riêng
- Mã đơn hàng tự sinh: `SF_0000XXXX`
- Hỗ trợ thêm/sửa/xóa món trong giỏ

### 4.2 Pinia Store: `receptionStore.ts`

| Entity | Mô tả |
|--------|-------|
| `ReceptionReservation` | Đặt bàn lễ tân |
| `ActiveSession` | Phiên phục vụ đang hoạt động |

**Reservation statuses:** `PENDING → CONFIRMED → SEATED → COMPLETED | CANCELLED`

**Time slots:** morning (trước 11h), lunch (11–14h), afternoon (14–17h), evening (sau 17h)

**Meal types:** LUNCH / DINNER

**Business rules:** Chuẩn hóa trạng thái từ nhiều nguồn (DB, view cũ) về 5 trạng thái canonical; tự động phân khu giờ; hỗ trợ gán bàn (`assignTable`) và giải phóng bàn (`releaseTable`).

### 4.3 Pinia Store: `shiftStore.ts`

**Quản lý ca làm việc (mở ca / đóng ca):**

| Hành động | Logic |
|-----------|-------|
| Mở ca | Ghi nhận `opening_cash`, tự động tạo mock payments |
| Đóng ca | `expected_cash = opening_cash + cash_revenue`, so sánh với `closing_cash` thực tế → `cash_difference` |
| PIN Manager | Cần PIN nếu `|variance| > 100.000 VND` (`VARIANCE_PIN_THRESHOLD`) |

**Revenue breakdown:** cash, card, transfer, other.

### 4.4 Views & Components

| View | Route | Chức năng |
|------|-------|-----------|
| `ReceptionDashboardView` | `/reception/dashboard` | Dashboard tổng quan: ca làm việc, bàn đang phục vụ, đặt bàn hôm nay, thông báo |
| `ReceptionOrderView` | `/reception/order` | Gọi món POS — chọn bàn, chọn món theo danh mục, giỏ hàng, gửi bếp, in bill, quản lý course/packages |
| `ReceptionFloorsView` | `/reception/floors` | Sơ đồ bàn (drag & drop, xếp bàn) |
| `ReceptionCheckoutView` | `/reception/checkout/:id` | Thanh toán — tìm khách, chọn loại doanh thu, voucher, nhiều phương thức |
| `ReceptionCloseShiftView` | `/reception/close-shift` | Đóng ca — đối soát tiền mặt, xuất CSV |
| `ShiftSummaryView` | `/reception/shift-summary` | Tổng kết ca — 4 overview cards, bảng doanh thu theo phương thức |
| `ShiftHandoverView` | `/reception/shift-handover` | Bàn giao ca |
| `ReportsView` | `/reception/reports` | Báo cáo |
| `RevenueOverviewView` | `/reception/revenue-overview` | Tổng quan doanh thu |
| `InventoryView` | `/reception/inventory` | Tồn kho tức thời |
| `ProcessItemsView` | `/reception/process-items` | Xử lý món |
| `MenuManagementView` | `/reception/menu-management` | Quản lý thực đơn |
| `OtherExpenseView` | `/reception/other-expense` | Chi khác |
| `ReservationDetailView` | `/reception/reservation-detail` | Chi tiết đặt bàn |

**Components:** `OpenShiftModal`, `CloseShiftModal`, `ManagerAuthModal`, `PaymentMethodSelector`, `QuickLockBar`, `QuickLockToggle`, `SidebarNavigation`, `TableOperationsMenu`, `CancelOrderModal`, `FloorViewFooter`, `HamburgerMenu`, `OrderManagementModal`.

### 4.5 POS Order View — 4 tab chính

| Tab | Mô tả |
|-----|-------|
| **Sơ đồ bàn** (`table_map`) | Timeline slider 11:00–22:00, grid bàn drag-and-drop, hiển thị trạng thái (trống/đang phục vụ/đã đặt/conflict) |
| **Thực đơn** (`menu`) | Bộ lọc nhanh (⭐🔥🕒) + nâng cao, grid món ăn, modal chi tiết món |
| **Hóa đơn** (`invoice`) | 3 cột: danh sách món + chi tiết thanh toán + bàn phím số. 7 phương thức thanh toán |
| **Chưa xử lý** (`pending`) | Danh sách đơn chờ |

### 4.6 Context Menu — 6 thao tác bàn

Double-click bàn → popup tại vị trí chuột:

| Thao tác | Điều kiện |
|----------|-----------|
| 📝 Chọn món | Luôn hiển thị |
| 🔁 Chuyển bàn | Bàn có khách |
| 🔗 Ghép phiếu | Bàn có khách |
| ✂️ Tách phiếu | Bàn có khách |
| 🍽️ Tách món | Bàn có khách |
| ❌ Hủy phiếu | Bàn có khách (cần PIN `1234` + gõ "HỦY") |

### 4.7 Quy tắc tính tiền

```
Total = (Subtotal + Subtotal × 5%) × 1.08
        ─────────────────────────  ─────
         Subtotal + Phí PV 5%       VAT 8%
```

---

## 5. MODULE BẾP (KITCHEN)

### 5.1 Pinia Store: `kitchen.ts`

| Entity | Mô tả |
|--------|-------|
| `GrillRequest` | Yêu cầu thay vỉ nướng |
| `PrepTask` | Nhiệm vụ chuẩn bị bếp |
| `Requisition` | Phiếu yêu cầu xuất kho |
| `RequisitionItem` | Món trong phiếu yêu cầu |
| `HandoverLog` / `HandoverLogItem` | Nhật ký bàn giao ca |
| `InventoryItem` | Tồn kho bếp |
| `AuditLog` | Nhật ký kiểm toán |

### 5.2 Requisition Workflow

```
Tạo phiếu yêu cầu → Chờ duyệt → Đề xuất thay thế → Duyệt & Xuất kho → Bếp trưởng ký nhận → Cập nhật COGS
```

**Trạng thái:** `pending → substitute_proposed → approved → delivered | rejected`

### 5.3 Handover Workflow (Bàn giao ca bếp)

```
Bếp ra (outgoing)
  → Kiểm kê nguyên liệu
  → Ghi nhiệt độ tủ lạnh/tủ đông
  → Bếp vào (incoming) ký nhận
```

### 5.4 Tồn kho bếp

- **KitchenStock** (tồn bếp) vs **MainStock** (tồn kho tổng)
- `minKitchenStock` — ngưỡng cảnh báo
- Tự động cập nhật stock khi xuất kho
- Tạo audit log cho mọi thay đổi trạng thái
- COGS tracking

### 5.5 Views & Components

| View | Route | Chức năng |
|------|-------|-----------|
| `KitchenKDSView` | `/kitchen/kds` | Kitchen Display System — xem đơn từ bếp |
| `KitchenExpoView` | `/kitchen/expo` | Màn hình Expo (xuất món, QC) |
| `KitchenHandoverView` | `/kitchen/handover` | Bàn giao ca bếp (3 bước) |
| `KitchenInventoryView` | `/kitchen/inventory` | Kiểm kê nguyên liệu bếp |
| `KitchenRequisitionView` | `/kitchen/requisition` | Yêu cầu xuất kho |

**Components requisition:** `RequisitionForm`, `RequisitionList`, `RequisitionDetail`, `RequisitionStatusBadge`, `RequisitionTimeline`, `RequisitionToolbar`, `RequisitionItemForm`.

---

## 6. MODULE KHÁCH HÀNG (CUSTOMER SELF-SERVICE)

Giao diện tablet tự phục vụ tại bàn — khách tự đặt món, yêu cầu dịch vụ, thanh toán, đánh giá.

### 6.1 Pinia Store: `customerStore.ts`

| Entity | Mô tả |
|--------|-------|
| `CustomerSession` | Phiên khách hàng tại bàn |
| `CartItem` | Món trong giỏ |
| `Order` | Đơn hàng |
| `ServiceRequest` | Yêu cầu dịch vụ |
| `Feedback` | Phản hồi khách hàng |

### 6.2 API: `customerApi.ts`

| Method | Mô tả |
|--------|-------|
| `authenticateStaff(passcode)` | Xác thực mã NV (6 ký tự) |
| `getBranches()` / `getAreas()` / `getTables(areaId)` | Lấy chi nhánh / khu vực / bàn |
| `selectTable()` / `releaseTable()` | Quản lý session bàn |
| `createSession()` | Tạo phiên khách hàng |
| `getPackages()` / `getMenu()` / `getRawMenuItems()` / `getMenuTemplate()` | Load menu (DB UUID + mock structure) |
| `createOrder(order)` | Tạo đơn → Supabase RPC (validate → activate session → flip table → insert order + items → tính subtotal/VAT → emit notification → auto-create CRM survey) |
| `updateOrder()` / `getOrderStatus()` / `getOrderHistory()` | Quản lý đơn hàng |
| `submitServiceRequest()` / `updateServiceRequest()` | Yêu cầu dịch vụ |
| `requestPayment()` / `requestInvoice()` | Yêu cầu thanh toán / hóa đơn đỏ |
| `updateCrmInfo()` | Cập nhật thông tin CRM |
| `submitFeedback()` | Gửi đánh giá |
| `updateLanguage()` | Đổi ngôn ngữ tablet |
| `subscribeToTableUpdates()` / `subscribeToServiceRequests()` / `subscribeToOrderUpdates()` | Realtime subscriptions |

### 6.3 Flow tổng quan

```
Passcode (6 số) → Chọn chi nhánh → Chọn khu vực → Chọn bàn (timeout 60s)
    → Chọn gói buffet → Xem menu → Thêm vào giỏ → Xác nhận đơn → Gửi bếp
        → Lịch sử đơn hàng
        → Yêu cầu dịch vụ (gọi NV, thêm than, nước, vỉ nướng, etc.)
        → Yêu cầu thanh toán
        → Đánh giá (5 sao + 6 tiêu chí)
        → Kết thúc phiên (QR + countdown 30s) → Về Passcode
```

### 6.4 10 màn hình chính

| # | Màn hình | Route | Mô tả |
|---|----------|-------|-------|
| 1 | Passcode | `/customer` | Nhập mã 6 số NV để mở khóa tablet |
| 2 | Chọn chi nhánh | `/customer` | Grid chi nhánh |
| 3 | Chọn khu vực | `/customer` | Grid 2 cột (A, B, VIP...) |
| 4 | Chọn bàn | `/customer` | Grid 4-5 cột, timeout 60s |
| 5 | Menu chính | `/customer/menu` | Sidebar danh mục + grid món + FAB gọi phục vụ |
| 6 | Giỏ hàng | `/customer/cart` | Danh sách món + billing summary + đặt món |
| 7 | Lịch sử order | `/customer/orders` | Danh sách order + bill settlement |
| 8 | Yêu cầu phục vụ | `/customer/service` | 9 nút: khăn, chén, gia vị, đá, thay vỉ, thay than, tính tiền, gọi NV, khác |
| 9 | Đánh giá | `/customer/feedback` | 5 sao + 6 tiêu chí + góp ý |
| 10 | Kết thúc phiên | — | Thank you + QR + countdown 30s |

### 6.5 Loại yêu cầu dịch vụ

| Loại | Mô tả |
|------|-------|
| `call_staff` | Gọi nhân viên |
| `add_charcoal` | Thêm than |
| `water` | Nước |
| `checkout` | Tính tiền |
| `tissue` | Khăn |
| `bowl` | Chén bát |
| `sauce` | Gia vị |
| `ice` | Đá |
| `grill_change` | Thay vỉ nướng |
| `charcoal_change` | Thay than |
| `request_bill` | Yêu cầu bill |
| `call_waiter` | Gọi phục vụ |

### 6.6 Business rules

- Passcode staff 6 ký tự (mock: 123456/654321)
- Menu template được deep-clone và remap ID từ DB (UUID thật)
- Validation UUID cho cart items trước khi gửi đơn
- Service charge = 5%, VAT = 8%
- Timeout 60s chọn bàn (BR-08) → giải phóng, quay về chọn khu
- Yêu cầu session active để truy cập menu/cart/orders (BR-09)
- Rating 1-5 sao (BR-35), chọn ít nhất 1 tiêu chí (BR-36)
- Persist orders vào localStorage để khôi phục phiên

### 6.7 Components (24 components)

`AreaGrid`, `BottomCartBar`, `BranchGrid`, `CartBar`, `CartItem`, `CategoryTabs`, `CrmInfoModal`, `CustomerDetailDrawer`, `FeedbackCriteria`, `InvoiceRequestModal`, `MenuCategoryBar`, `MenuItemCard`, `MenuItemDetailModal`, `MenuSubcategoryBar`, `OrderTrackingModal`, `PackageSelector`, `PasscodeInput`, `ServiceRequestGrid`, `StarRating`, `TableGrid`, `TierBadge`, `SelectArea`, `SelectBranch`, `SelectTable`.

---

## 7. MODULE THU MUA (PURCHASING)

### 7.1 API: `procurement.api.ts`

| Method | Mô tả |
|--------|-------|
| `getSuppliers()` | Danh sách nhà cung cấp |
| `getIngredients()` | Danh sách nguyên liệu |
| `getGoodsReceipts()` | Phiếu nhập kho |
| `getRequisitions()` | Yêu cầu mua hàng |
| `getCurrentStock()` | Tồn kho hiện tại |
| `getInventoryTransactions()` | Giao dịch kho |
| `getIngredientStats()` | Thống kê nguyên liệu |
| `createRequisition()` | Tạo yêu cầu mua hàng |
| `approveRequisition()` | Duyệt yêu cầu |
| `saveIngredient()` | Lưu nguyên liệu |
| `recordInventoryTx()` | Ghi giao dịch kho |
| `purchaseItem()` | Mua hàng |
| `discardItem()` | Hủy bỏ hàng |
| `adjustStockLogic()` | Điều chỉnh tồn kho |

### 7.2 Transaction types

| Loại | Mô tả |
|------|-------|
| `IN` | Nhập kho |
| `OUT` | Xuất kho |
| `ADJUST` | Điều chỉnh |
| `PURCHASE` | Mua hàng |

### 7.3 Views

| View | Chức năng |
|------|-----------|
| `PurchasingDashboardView` | Dashboard thu mua |
| `POCreateView` | Tạo đơn đặt hàng |
| `POListView` | Danh sách đơn đặt hàng |
| `PurchaseOrdersView` | Đơn mua hàng |
| `IngredientsManagerView` | Quản lý nguyên liệu |
| `SupplierManagerView` | Quản lý nhà cung cấp |
| `RequisitionsView` | Yêu cầu mua hàng |
| `RequisitionListView` | Danh sách yêu cầu |
| `GoodsReceiptView` | Nhập kho |
| `ReceiptsManagerView` | Quản lý phiếu nhập |
| `InventoryAuditView` | Kiểm kê kho |
| `DailyReceiptView` | Nhập kho hàng ngày |

### 7.4 Business rules

- Mỗi giao dịch kho ghi lại `unit_cost`, `supplier`, `notes`
- Yêu cầu mua hàng có thể kèm báo giá từ nhiều nhà cung cấp
- Hỗ trợ ABC analysis, expiry tracking, stocktake

---

## 8. MODULE KẾ TOÁN (ACCOUNTING)

### 8.1 Views

| View | Chức năng |
|------|-----------|
| `AccountingDashboardView` | Dashboard kế toán |
| `FinancialDashboardView` | Tài chính tổng quan |
| `CashFlowView` | Dòng tiền |
| `APPayablesView` | Phải trả nhà cung cấp |
| `PLReportView` | Báo cáo lợi nhuận & lỗ |
| `InvoiceManagerView` | Quản lý hóa đơn |
| `TaxExportView` | Xuất thuế |
| `TaxRecordsView` | Hồ sơ thuế |
| `InventoryValuationView` | Định giá tồn kho |

### 8.2 Composables

- `useAccounting` / `useAccountingModule` — logic kế toán
- `useTaxInvoice` — hóa đơn thuế
- `useReport` — báo cáo

---

## 9. MODULE CRM

### 9.1 Pinia Store: `crmStore.ts`

| Entity | Mô tả |
|--------|-------|
| `CrmServingTable` | Bàn đang phục vụ (cần khảo sát) |
| `CrmSurveyInput` | Dữ liệu khảo sát (name, phone, zalo, marketing consent, tags, visit reason, feedback) |
| `CrmDashboardStats` | Thống kê dashboard |
| `CrmSurveyStatus` | Trạng thái khảo sát |

**Survey statuses:** `not_started → assigned → in_progress → completed | skipped | customer_refused | expired | late_submitted`

**Dashboard stats:** total_customers, new_customers_this_month, repeater_customers, vip_customers, avg_spent_per_customer

### 9.2 Views

| View | Chức năng |
|------|-----------|
| `CRMDashboardView` | Dashboard CRM |
| `CRMServingTablesView` | Bàn đang phục vụ (cần khảo sát) |
| `CustomerDetailView` | Chi tiết khách hàng |
| `CustomerListView` | Danh sách khách hàng |
| `CustomerFeedbackView` | Phản hồi khách hàng |
| `FeedbackManagerView` | Quản lý phản hồi |
| `VoucherManagerView` | Quản lý voucher |

---

## 10. MODULE MARKETING

### 10.1 Views

| View | Chức năng |
|------|-----------|
| `MarketingDashboardView` | Dashboard marketing |
| `CampaignsView` | Chiến dịch marketing |
| `CampaignListView` | Danh sách chiến dịch |
| `CampaignAnalyticsView` | Phân tích chiến dịch |

### 10.2 Composables

- `useMarketing` — quản lý marketing
- `useCampaign` — chiến dịch marketing

---

## 11. MODULE QUẢN TRỊ (ADMIN / MANAGER / SUPERADMIN)

### 11.1 Admin

| View | Chức năng |
|------|-----------|
| `AdminDashboardView` | Dashboard quản trị |
| `AdminAccountsView` | Quản lý tài khoản người dùng |
| `AdminMenusView` | Quản lý thực đơn (categories, items) |
| `AdminFloorsView` | Quản lý sơ đồ bàn |
| `AdminKPIView` | Quản lý chỉ tiêu KPI/KGI |
| `AdminAuditView` | Nhật ký kiểm toán |
| `AdminVoucherView` | Quản lý voucher/giảm giá |
| `SelectBranchView` | Chọn chi nhánh làm việc |

### 11.2 Manager

| View | Chức năng |
|------|-----------|
| `ManagerDashboardView` | Dashboard quản lý |
| `ManagerRevenueView` | Doanh thu |
| `ManagerCOGSView` | Giá vốn hàng bán (COGS) |
| `ManagerMarketingView` | Marketing |
| `ManagerCRMView` | CRM |
| `ManagerInventoryView` | Tồn kho |
| `ManagerMembershipView` | Quản lý hội viên |
| `ManagerVoucherView` | Quản lý voucher |

### 11.3 Superadmin

| View | Chức năng |
|------|-----------|
| `SuperadminDashboardView` | Dashboard siêu quản trị |
| `SuperadminBrandsView` | Quản lý thương hiệu (đa tenant) |
| `SuperadminIntegrationsView` | Tích hợp bên thứ 3 (payment, delivery) |

### 11.4 Pinia Store: `menuManagementStore.ts`

**Quản lý thực đơn (CRUD categories, subcategories, items):**

| Rule | Mô tả |
|------|-------|
| Soft-delete | `is_active = false` thay vì xóa cứng |
| Copy item | Tự động thêm "(Bản sao)" và "-COPY" |
| Xóa category | Không cho xóa category/subcategory còn item con |
| Realtime broadcast | Event `menu:item-status-changed` cho POS |
| Bulk lock/unlock | Toggle sold-out hàng loạt |
| Reorder | Kéo thả sắp xếp categories/subcategories |

---

## 12. MODULE BAN GIÁM ĐỐC (BOD)

| View | Chức năng |
|------|-----------|
| `BODDashboardView` | Dashboard BOD |
| `HQDashboardView` | Dashboard tổng công ty (HQ) |
| `BranchPerformanceView` | Hiệu suất chi nhánh |
| `BODApprovalsView` | Phê duyệt |
| `AuditLogsView` | Nhật ký kiểm toán |
| `SystemConfigView` | Cấu hình hệ thống |

**Composable:** `useBOD` — dữ liệu tổng công ty, phê duyệt, audit.

---

## 13. MODULE SẢNH (HALL) & NHÂN VIÊN (STAFF)

### 13.1 Hall (Sảnh)

**Pinia Store: `hallStore.ts`** — quản lý sảnh/hội trường.

| View | Chức năng |
|------|-----------|
| `HallDashboard` | Dashboard sảnh |
| `ActiveTablesView` | Bàn đang phục vụ |
| `FloorPlanView` | Sơ đồ bàn |
| `OrderMenuView` | Gọi món |
| `CheckoutView` | Thanh toán |
| `ServiceQueueView` | Hàng đợi dịch vụ |
| `ReservationCalendar` | Lịch đặt bàn |
| `ReservationManagerView` | Quản lý đặt bàn |
| `ReservationDetail` | Chi tiết đặt bàn |

**Views:** Calendar, Detail, Floor Plan, Order Menu.
**Business rules:** Phân tích time slot từ giờ; lọc bàn khả dụng; tích hợp `useReservation`, `useTable`, `useMenu`.

### 13.2 Staff (Nhân viên)

| View | Chức năng |
|------|-----------|
| `StaffFloorPlanView` | Sơ đồ bàn |
| `StaffOpenTableView` | Mở bàn mới |
| `StaffActiveTablesView` | Bàn đang phục vụ |
| `StaffInDiningCRMView` | CRM tại bàn |

### 13.3 Tablet (Máy tính bảng)

| View | Chức năng |
|------|-----------|
| `TabletIdleView` | Màn hình chờ (touch to start) |
| `TabletLanguageView` | Chọn ngôn ngữ |
| `TabletOrderView` | Gọi món |
| `TabletCheckoutView` | Thanh toán |

---

## 14. BUSINESS RULES ENGINE

### 14.1 Package Tier System (Buffet)

File: `src/utils/packageRules.ts` — engine tính tiền dùng chung cho cả Customer tablet và Reception POS.

| Tier | Giá | Eligibility |
|------|-----|-------------|
| **1390** | 1.390K | Top tier — tất cả categories |
| **1150** | 1.150K | Loại trừ wagyu |
| **680** | 680K | Loại trừ wagyu + premium beef |
| **490/380** | 490K/380K | Chỉ "safe" subcategories (pork, chicken, soft_drink, tea, appetizer, salad, rice, noodle, soup, dessert) — không beef, không alcohol |
| **kids** | — | Chỉ KIDS / egg / fries / dessert |
| **lau** | — | Buffet lẩu (hotpot dishes + drinks + veggies) |
| **550jp** | 550JP | Set bento / sashimi / tempura / miso |
| **drink** | — | SET DRINK-only |

### 14.2 Pricing Rules

| Rule | Mô tả |
|------|-------|
| **Surcharge items** (khac-phi) | Luôn tính phí, không bao giờ free trong package |
| **Lunch 50% discount** | Items có "lunch" trong tên được giảm 50% |
| **Service charge** | 5% × subtotal |
| **VAT** | 8% × (subtotal + service charge) |
| **In-package items** | Giá = 0 khi thuộc gói buffet đã chọn |
| **Engine** | `computeTotals()` — đồng nhất customer & cashier |

### 14.3 Business Rules tổng hợp

| Mã | Mô tả | Áp dụng |
|----|-------|---------|
| BR-08 | Timeout 60s chọn bàn → giải phóng, quay về chọn khu | Customer |
| BR-09 | Yêu cầu session active để truy cập menu/cart/orders | Customer |
| BR-23 | Group món theo trạm bếp: `hot`, `meat`, `salad` | Customer |
| BR-27 | Format kitchen ticket text | Customer |
| BR-28 | Tăng `printedCount` kitchen ticket | Customer |
| BR-35 | Rating 1-5 sao | Customer |
| BR-36 | Chọn ít nhất 1 tiêu chí đánh giá | Customer |
| R-PIN | Hủy order Reception cần PIN Manager (`1234`) + gõ "HỦY" | Reception |
| R-Discount | Giảm giá cần lý do + PIN Manager | Reception |
| Shift-PIN | Đóng ca lệch > 100K cần PIN Manager | Reception |

### 14.4 Dữ liệu tham chiếu

**Menu Template (`menuData.ts`):** ~100+ món ăn, 10+ categories/subcategories:
- Buffet (8 subcategories: 1390, 1150, 680, 490, 380, DRINK, A la carte, 550JP, Lẩu)
- Set Lunch, Set Tiệc Chiêu Đãi, Set Tiệc Chiêu Đãi JP, Set Vietravel
- Thức Ăn (16 subcategories: Wagyu, Beef Tongue, Beef, Nội Tạng, Thịt Heo, Thịt Gà, Grill a la carte, A la carte, Khai Vị, Xà Lách, Cơm, Mì, Súp, Tráng Miệng, Sốt, Lẩu Sukiyaki)
- Thức Uống, Thức Uống Có Cồn

**Khu vực (`customerAreaData.ts`):** 10 khu vực, 57 bàn tổng cộng.

---

## 15. QUY TRÌNH NGHIỆP VỤ CHÍNH

### 15.1 Walk-in Customer (Khách vãng lai)

```
Chọn bàn → Mở phiên → Chọn gói buffet → Gọi món → Gửi bếp
    → Yêu cầu dịch vụ (nếu cần) → Thanh toán → Phản hồi
```

### 15.2 Reservation (Đặt bàn)

```
Đặt bàn → Xác nhận (PENDING → CONFIRMED) → Xếp bàn (assignTable)
    → Check-in (CONFIRMED → SEATED) → Phục vụ → Thanh toán
    → Hoàn tất (SEATED → COMPLETED)
```

### 15.3 Kitchen Requisition (Xuất kho bếp)

```
Tạo yêu cầu (pending) → Duyệt / Đề xuất thay thế (substitute_proposed)
    → Duyệt & Xuất kho (approved → delivered) → Bếp trưởng ký nhận
    → Cập nhật COGS
```

### 15.4 Shift Management (Quản lý ca)

```
Mở ca (nhập opening_cash) → Phục vụ / Thu tiền trong ca
    → Đóng ca (đối soát: expected_cash vs closing_cash)
    → Nếu |variance| > 100K → cần PIN Manager
    → Ghi chú bắt buộc khi lệch
```

### 15.5 CRM Survey (Khảo sát tại bàn)

```
Staff chọn bàn (not_started → assigned) → Bắt đầu survey (→ in_progress)
    → Thu thập info khách (name, phone, zalo, tags, visit reason, feedback)
    → Hoàn tất (→ completed)
    → Hoặc: skip / customer_refused / expired / late_submitted
```

### 15.6 Procurement (Thu mua)

```
Tạo yêu cầu mua → Nhận báo giá từ nhiều NCC → Phê duyệt
    → Đặt hàng → Nhập kho (IN) → Ghi nhận giao dịch kho
    → Có thể: ADJUST (điều chỉnh) / OUT (xuất) / PURCHASE (mua)
```

### 15.7 Kitchen Handover (Bàn giao ca bếp)

```
Bếp ra (outgoing) → Kiểm kê nguyên liệu → Ghi nhiệt độ tủ lạnh/tủ đông
    → Bếp vào (incoming) ký nhận
```

### 15.8 Order Flow (Customer Tablet → Bếp)

```
Customer Tablet                    Bếp (KDS)
┌──────────────────┐              ┌──────────────────┐
│ Chọn món → Giỏ   │              │                  │
│ → Xác nhận đơn   │──→ DB ──────→│ KDS hiển thị đơn │
│ → createOrder()  │   (RPC)      │ → Expo QC        │
│ → emit notif      │              │ → Served         │
└──────────────────┘              └──────────────────┘
```

**Lưu ý kiến trúc:** Hiện tại order từ customer tablet chưa realtime flow vào Reception — cần bổ sung Supabase Realtime subscription hoặc polling.

---

## 16. HỆ THỐNG ĐA NGÔN NGỮ (i18n)

### 16.1 Ngôn ngữ hỗ trợ

| Code | Ngôn ngữ | File | Số dòng |
|------|----------|------|---------|
| `vi` | 🇻🇳 Việt | `src/locales/vi.ts` | ~3.731 dòng |
| `en` | 🇬🇧 Anh | `src/locales/en.ts` | ~3.648 dòng |
| `ja` | 🇯🇵 Nhật | `src/locales/ja.ts` | ~3.664 dòng |

### 16.2 Modules có i18n

Hall, Checkout, Service, Reservation, Purchasing, Accounting, Campaigns, BOD, Feedback, Inventory, Requisition, Shift, Tablet, Branch, Integration, CRM, Reception, Dashboard, Common, Admin (Accounts/Audit/Floors/KPI/Menus), Kitchen (Handover/Inventory/Expo/KDS), Customer.

### 16.3 Kiến trúc i18n

**3 lớp phân giải dịch:**

1. Flat key lookup (e.g. `auto_nguu_cat`)
2. Nested key qua vue-i18n `t()`
3. Fallback dictionary từ `useLanguageStore`

`setApplicationLanguage()` đồng bộ Pinia store + vue-i18n + `<html lang>`.
`useI18nStore` (Pinia) quản lý locale với localStorage persistence.

---

## 17. DESIGN SYSTEM

### 17.1 Theme — Reception (Dark POS)

| Màu | Hex | Sử dụng |
|-----|-----|---------|
| Nền chính | `#1e1e1e` / `#2d2d2d` / `#3a3a3a` | Dark POS theme |
| Accent cam | `#ff8f00` / `#E8772E` | Nút, highlight, brand |
| Xanh lá | `#27ae60` | Bàn trống |
| Đỏ nâu | `#c0392b` | Bàn có khách |
| Vàng | `#f1c40f` | Bàn đã đặt |

### 17.2 Theme — Customer (Dark Wood)

| Màu | Hex | Sử dụng |
|-----|-----|---------|
| Wood dark | `#3D2817` | Background |
| Wood darker | `#1a110a` | Header bar |
| Orange | `#E8772E` / `#ff9800` | Accent, nút, giá |
| Red | `#C62828` | Grand total, xóa |
| Green | `#4CAF50` | Món free, success |

### 17.3 Theme — Global (globals.css)

| Token | Giá trị |
|-------|---------|
| Background | `#0d0d0f` |
| Cards | `#141417` |
| Primary | Amber-500 (hsl 38 92% 50%) |
| Border radius | 12px (`--radius`) |
| Font primary | Nunito |
| Font brand | Cormorant Garamond (serif) |

### 17.4 Kawaii UI Library (styles.css)

| Token | Giá trị |
|-------|---------|
| Primary | `#FF7B89` (salmon) |
| Primary dark | `#FF5A6E` |
| Navy | `#2C3E50` |
| Cream | `#FFF5F7` |

**Components:** `.k-btn`, `.k-card`, `.k-pill`, `.k-counter`, `.k-options`, `.k-date`, `.k-toast`, `.k-modal`, `.k-table`, `.k-tabs`, `.k-avatar`, `.k-chip`, `.k-skeleton`, `.k-divider`.

### 17.5 Button Variants (7 types)

| Variant | Màu | Sử dụng |
|---------|-----|---------|
| `primary` | Blue | Navigation chính |
| `secondary` | Purple | Expo QC |
| `warning` | Orange | Grill/charcoal request |
| `success` | Green | HACCP |
| `danger` | Red | 86'd items |
| `neutral` | Gray | Hide panel |
| `urgent` | Dark red (pulse) | Delayed alerts |

### 17.6 Design Tokens (`design-system/`)

| File | Nội dung |
|------|----------|
| `colors.ts` | `BUTTON_COLORS` (6 variants × 3 shades + gradient), `BADGE_COLORS` |
| `requisitionTokens.ts` | `REQUISITION_COLORS` (priority, status, surfaces, gradients), `REQUISITION_TYPOGRAPHY`, `REQUISITION_SPACING` |

### 17.7 POS-specific CSS (`orderingScreen.css`)

| Class | Mô tả |
|-------|-------|
| `.sidebar-pos` | 240px fixed sidebar |
| `.header-pos` | 60px header |
| `.main-content-pos` | Grid layout (45%/55% split) |
| `.card-pos`, `.btn-pos`, `.badge-pos`, `.chip-pos`, `.input-pos`, `.menu-card-pos` | POS components |

---

## 18. GHI CHÚ KIẾN TRÚC

### 18.1 State Management (Pinia — 11 stores)

| Store | File | Trách nhiệm |
|-------|------|-------------|
| `restaurantStore` | `restaurantStore.ts` | Sơ đồ bàn, đặt bàn, giỏ hàng POS |
| `receptionStore` | `receptionStore.ts` | Đặt bàn lễ tân, phiên phục vụ |
| `customerStore` | `customerStore.ts` | Phiên khách hàng, giỏ hàng, đơn hàng |
| `hallStore` | `hallStore.ts` | Sảnh/hội trường |
| `kitchen` | `kitchen.ts` | Bếp, tồn kho bếp, requisition, handover |
| `crmStore` | `crmStore.ts` | CRM khảo sát |
| `menuManagementStore` | `menuManagementStore.ts` | CRUD thực đơn |
| `shiftStore` | `shiftStore.ts` | Ca làm việc |
| `i18n` | `i18n.ts` | Locale management |
| `useLanguageStore` | `useLanguageStore.ts` | Dict-based translation |

### 18.2 Composables (47 composables)

| Nhóm | Composables |
|------|-------------|
| **Operations** | `useOrder`, `useTable`, `useTableOperations`, `useMenu`, `useShift`, `useReceptionSync`, `useCheckIn`, `useCheckout` |
| **CRM/Membership** | `useCRM`, `useCustomer`, `useCustomerSession`, `useMembership`, `useVoucher`, `useFeedback`, `useServiceRequest` |
| **Kitchen** | `useKDS`, `useKitchenShift` |
| **Inventory** | `useInventory`, `useRequisition`, `usePurchaseOrder`, `usePurchasing` |
| **Finance** | `useAccounting`, `useAccountingModule`, `useReport`, `useTaxInvoice` |
| **Management** | `useAuth`, `useBranch`, `useBusinessRules`, `useKPI`, `useBOD`, `useCampaign`, `useMarketing` |
| **Technical** | `useRealtime`, `useNotification`, `useTablet`, `useUnsavedGuard`, `useUserSticker`, `useAudit`, `useOCR`, `useIntegrations` |

### 18.3 Dual-mode Operation

```
                    ┌── Supabase configured?
                    │
                YES ─┴─ NO
                │       │
    supabase.rpc()   Mock data
    Real DB           localStorage
    Realtime subs     In-memory
```

Khi Supabase chưa cấu hình (env vars missing), toàn bộ hệ thống fallback sang mock data + localStorage, cho phép dev UI mà không cần backend.

### 18.4 Per-Server Printing Architecture

File: `perserver_printing_architecture.md` — thiết kế in phân tán cho bếp:
- Supabase Realtime Pub/Sub + Local Print Queue
- PerSever Node.js server tại mỗi chi nhánh
- Đảm bảo in kitchen ticket ngay cả khi mạng chậm

### 18.5 Khoảng cách cần khắc phục

| Vấn đề | Chi tiết |
|--------|----------|
| **Realtime sync** | Order từ Customer tablet chưa tự xuất hiện ở Reception — cần Supabase Realtime subscription |
| **DB integration** | Hầu hết in-memory (mock), chỉ `hall_cancel_order_or_item` có RPC backend |
| **Transfer/merge** | Chỉ sửa `restaurantStore` trong RAM, không ghi DB |

---

## TỔNG KẾT

Hệ thống POS Ngưu Cát là giải pháp quản lý nhà hàng BBQ buffet toàn diện với **14 module** phục vụ toàn bộ vòng đời vận hành:

| # | Module | Vai trò |
|---|--------|---------|
| 1 | Reception (POS) | Lễ tân, gọi món, thanh toán, ca làm việc |
| 2 | Customer Self-Service | Tablet tự đặt món tại bàn |
| 3 | Kitchen (KDS) | Hiển thị đơn bếp, xuất món, bàn giao ca |
| 4 | Purchasing | Thu mua, nhà cung cấp, nhập kho |
| 5 | Accounting | Kế toán, P&L, thuế, dòng tiền |
| 6 | CRM | Khảo sát khách hàng, feedback, voucher |
| 7 | Marketing | Chiến dịch, phân tích |
| 8 | Admin | Tài khoản, menu, KPI, audit, voucher |
| 9 | Manager | Dashboard, doanh thu, COGS, CRM, kho |
| 10 | BOD | Dashboard HQ, hiệu suất chi nhánh, phê duyệt |
| 11 | Superadmin | Đa tenant, thương hiệu, tích hợp |
| 12 | Hall | Sảnh, đặt bàn, sơ đồ |
| 13 | Staff | Phục vụ, mở bàn, CRM tại bàn |
| 14 | Tablet | Tablet idle/order/checkout |

**Tech stack:** Vue 3 + TypeScript + Supabase/PostgreSQL + Pinia + Tailwind CSS + vue-i18n (VI/EN/JA).

**Trạng thái hiện tại:** UI hoàn thiện ~95%, DB integration đang phát triển (chủ yếu mock mode), realtime sync đang cần bổ sung.
