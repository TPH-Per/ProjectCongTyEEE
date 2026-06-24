# PROJECT_OVERVIEW.md — NGƯU CÁT POS

> File tổng quan dự án dành cho AI Agent / lập trình viên mới vào dự án.
> Đọc file này **trước khi** bắt đầu bất kỳ task nào.

---

## 1. Tổng quan dự án

### 1.1. Dự án này là gì?

**NGƯU CÁT POS** (tiếng Nhật: 牛吉 予約管理) là **frontend SPA đa vai trò** cho hệ thống POS (Point of Sale) + quản lý đặt bàn của chuỗi nhà hàng nướng NguuCat tại Việt Nam.

- **Tên repo/package**: `restaurant-booking-ui`
- **Version**: `0.1.0`
- **Loại**: Frontend SPA (Vue 3 + TypeScript + Vite), kết nối Supabase (Postgres + Auth + Realtime + Edge Functions).
- **Giao diện**: Theme "Kawaii Cute" với palette salmon pink + cream + navy. Hỗ trợ 3 ngôn ngữ: Tiếng Việt (mặc định), Tiếng Nhật, Tiếng Anh.

### 1.2. Mục đích chính

Thay thế POS thuê ngoài (F2Tech) bằng hệ thống tự phát triển để:

1. **Giảm chi phí license hàng tháng** và không lệ thuộc nhà cung cấp.
2. **Tùy biến chức năng** phù hợp với nhà hàng nướng (gọi món theo set, quản lý bếp than trên bàn, gọi món thêm nhiều lần).
3. **Quản lý tập trung dữ liệu** doanh thu, khách hàng, KPI của nhiều chi nhánh trên một hạ tầng (multi-tenant theo `branch_id`).
4. **Đáp ứng nghiệp vụ Việt Nam**: Hóa đơn đỏ, MST, VAT 8% (đúng theo Nghị định 123/2020), tiếng Việt/Nhật cho khách.

### 1.3. Dự án giải quyết vấn đề nào?

- Hệ thống POS hiện tại (F2Tech) không cho phép tùy biến sâu và không tích hợp tốt với hạ tầng dữ liệu nội bộ.
- Cần một hệ thống multi-role (Admin / Manager / Reception / Staff / Kitchen / Tablet) chạy trên desktop, mobile, tablet.
- Cần quản lý booking + order + checkout + hóa đơn đỏ VN + KPI + CRM trong một nền tảng duy nhất.
- Cần realtime cập nhật trạng thái bàn, đơn hàng, đặt bàn giữa các thiết bị (Postgres Changes qua Supabase Realtime).

### 1.4. Đối tượng phục vụ

- **Nội bộ NguuCat**: 3 kỹ sư phát triển (theo `plan.md`), nhân viên vận hành nhà hàng.
- **Khách hàng cuối**: Khách đặt bàn / khách walk-in tại bàn (dùng tablet).
- **Đối tác/khách hàng doanh nghiệp** cần xuất hóa đơn đỏ (tax invoice).

### 1.5. Giai đoạn hiện tại

- **Đang phát triển (in development)**, đã có proof-of-concept về UI cho tất cả 7 portal.
- Backend đã có schema PostgreSQL đầy đủ (`supabase/migrations/20260623000000_setup.sql`) và 9 Edge Functions đang ở trạng thái code sẵn sàng (chưa được verify trên production).
- Đã có mock data (`src/lib/mock-data.ts`) cho phép chạy demo frontend độc lập.
- Mốc quan trọng theo `plan.md`: **Vận hành thử nghiệm tại 1 chi nhánh vào 31/07/2026**.

> **Chưa xác định rõ**: Dự án đã ở production thật chưa, có bao nhiêu chi nhánh đang chạy thử nghiệm.

---

## 2. Đối tượng sử dụng

Hệ thống có **5 vai trò (roles)** chính thức + 2 vai trò quản trị (Admin/Superadmin), phân chia theo URL prefix:

| Role | Path | Thiết bị | Trách nhiệm chính |
|------|------|----------|------------------|
| **Admin** | `/admin/*` | Desktop | Quản trị hệ thống: tài khoản, menu, sơ đồ bàn, KPI, audit log |
| **Superadmin** | `/superadmin/*` | Desktop | Quản trị cấp tập đoàn: brands, integrations, dashboard đa chi nhánh |
| **Manager** | `/manager/*` | Desktop | Báo cáo doanh thu, COGS, marketing, CRM, tồn kho |
| **Reception (Cashier)** | `/reception/*` | Desktop POS | Đặt bàn, check-in, checkout, đóng ca |
| **Staff (Waiter)** | `/staff/*` | Mobile | Sơ đồ bàn, mở bàn, CRM tại bàn, bàn đang phục vụ |
| **Kitchen** | `/kitchen/*` | Display (KDS) | Kitchen Display System — đẩy món, theo dõi chế biến |
| **Customer (Guest)** | `/tablet/*` | Tablet | Order tại bàn, thanh toán, chọn ngôn ngữ |

Mỗi role có **layout riêng** (`src/layouts/*`) và **router guard** chặn truy cập chéo trong `src/router/index.ts` (`ROUTE_ROLES`). Admin có thể impersonate vào bất kỳ portal nào.

---

## 3. Phạm vi dự án

### 3.1. Phạm vi hiện tại (đã có trong source code)

**Frontend (đã triển khai UI):**
- 27 view trải đều cho 7 portal, mỗi view đã có layout, sidebar, i18n.
- Pinia store i18n (`useI18nStore`) với 3 locale (vi/ja/en).
- vue-router với route guards theo role.
- Composables cho mọi domain nghiệp vụ: `useAuth`, `useBranch`, `useReservation`, `useOrder`, `useCheckout`, `useCheckIn`, `useCustomer`, `useTable`, `useMenu`, `useShift`, `useTaxInvoice`, `useKDS`, `useKPI`, `useMarketing`, `useInventory`, `useNotification`, `useReport`, `useAudit`, `useRealtime`.
- TailwindCSS với theme "kawaii" + utility classes custom (`kawaii-card`, `kawaii-btn-primary`, ...).
- Theme fonts: Nunito + Noto Sans JP.

**Backend (schema & Edge Functions đã viết):**
- PostgreSQL schema 23 bảng (19 HIGH-consistency + 4 LOW-consistency), 10 enum types, indexes, RLS policies, triggers audit, function `revenue_by_hour()`.
- 9 Supabase Edge Functions: `check-in`, `add-order-item`, `checkout`, `close-shift`, `export-shift-csv`, `issue-tax-invoice`, `kds-push`, `request-checkout`, `custom-access-token`.
- Realtime publication cho: `reservations`, `tables`, `table_assignments`, `orders`, `order_items`, `notifications`, `audit_events`.
- Seed data: 2 chi nhánh (`B001`, `B002`), 5 zones, 5 bàn mẫu, 5 danh mục menu, 5 món, 3 packages, 3 KPI targets.

**Testing:**
- 1 file Playwright E2E test (`e2e/auth.spec.ts`) cho trang login.

**Documentation:**
- `docs/` chứa ~5,000+ dòng tài liệu: DATABASE_DESIGN, DATABASE_SCHEMA.sql, DATABASE_SCHEMA_REVIEW, SUPABASE_SETUP, SUPABASE_AUTH, SUPABASE_FUNCTIONS, SUPABASE_REALTIME, API_IMPLEMENTATION_GUIDE, EXECUTION_PLAYBOOK, TESTING_VERIFICATION_GUIDE, COST_ANALYSIS, WEEKLY_REPORT.
- File phân tích nghiệp vụ: `BUSINESS_ANALYSIS.md`, `RESTAURANT_SYSTEM_ANALYSIS.md`.

### 3.2. Phần có vẻ đang phát triển dở

- **Mock data còn dùng kèm DB thật**: `src/lib/mock-data.ts` vẫn còn, nhưng các composables đã chuyển sang gọi Supabase. Một số view cũ ở root (`TimelineView.vue`, `ListView.vue`, `FloorPlanView.vue`) có thể chưa được kết nối đầy đủ với Supabase.
- **`useInventory`**: Hiện chỉ là placeholder đọc `branch_settings.inventory.low_stock`, **chưa có bảng `inventory_items` thật** trong schema (ghi chú trong code: "the placeholder implementation returns [] until the inventory module is wired into the schema").
- **`useReport`**: `todayHeadline()` ước lượng `covers = orders * 2` (placeholder, chưa có view aggregate thật).
- **Edge Functions**: Có file code nhưng **chưa được deploy/verify** trên Supabase thật (theo ghi chú trong `supabase/functions/_shared/`).
- **Tests**: Mới chỉ có 1 file E2E cho login; chưa có unit test cho composables.

### 3.3. Phần chưa có bằng chứng rõ ràng

- **Triển khai thật trên production**: Chưa có file `.env.example` template chuẩn trong repo (chỉ có hướng dẫn trong `docs/SUPABASE_SETUP.md`).
- **CI/CD**: Không tìm thấy `.github/workflows` hay file cấu hình CI.
- **Email template / SMS provider**: Đề cập trong `docs/SUPABASE_SETUP.md` (Resend) nhưng chưa có code tích hợp.
- **Payment gateway**: `payments.method` enum đã có (`cash | card | transfer | voucher | other`) nhưng chưa có tích hợp Stripe/VNPay/MoMo thật.
- **Tax authority integration (VT_API_KEY)**: Edge Function `issue-tax-invoice` đã viết nhưng chưa rõ provider VN cụ thể nào (VNPT/Tax24/MISA).
- **Hard-delete vs soft-delete**: Có trường `is_active` trên nhiều bảng nhưng chưa có quy trình cleanup rõ ràng.

### 3.4. Phần cần xác minh thêm

- Tình trạng test trên chi nhánh thí điểm (`plan.md` nói đến 31/07/2026).
- Số lượng chi nhánh thật đang vận hành và dữ liệu đã migrate từ F2Tech chưa.
- Có bao nhiêu user/role thật đang dùng hệ thống.
- Có dùng thêm 3rd-party service nào ngoài Supabase + Vercel không.

---

## 4. Công nghệ sử dụng

### 4.1. Frontend

| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| Vue 3 | `^3.5.34` | Framework UI chính (Composition API + `<script setup>`) |
| TypeScript | `^5.4.3` | Type-safety; `vue-tsc` strict, `noUnusedLocals`, `noUnusedParameters` |
| Vite | `^8.0.12` | Bundler + dev server |
| vue-router | `^4.3.0` | Routing SPA với 5 portal trees |
| Pinia | `^3.0.4` | State management (i18n store) |
| vue-i18n | `^9.14.5` | Đa ngôn ngữ vi/ja/en |
| TailwindCSS | `^3.4.1` | Styling + theme "kawaii" |
| tailwindcss-animate | `^1.0.7` | Animation utilities |
| lucide-vue-next | `^0.363.0` | Icons |
| date-fns | `^3.6.0` | Format/parse ngày giờ |
| clsx + tailwind-merge | `^2.1.0` / `^2.2.2` | Utility `cn()` merge class |
| zod | `^3.22.4` | Schema validation |
| @supabase/supabase-js | `^2.108.2` | Supabase client (DB + Auth + Realtime + Functions) |

### 4.2. Backend (BaaS)

- **Supabase** (Pro $25/tháng): Postgres 15+, Auth, Realtime, Edge Functions (Deno), Storage.
- **PostgreSQL 15+** với extensions: `uuid-ossp`, `pgcrypto`.
- **Supabase Edge Functions** (Deno runtime): 9 functions (xem mục 6).

### 4.3. Database

- **PostgreSQL** (multi-tenant theo `branch_id`).
- 23 bảng (19 HIGH-consistency + 4 LOW-consistency).
- Row Level Security (RLS) enabled trên tất cả bảng, dùng helper functions `current_user_id()`, `current_branch_id()`, `has_role()`.
- Realtime publication cho 7 bảng (xem `docs/SUPABASE_SETUP.md`).
- Audit triggers tự động ghi vào `audit_events` cho mọi mutation trên các bảng quan trọng.

### 4.4. Authentication

- **Supabase Auth** (Email + Password + Magic Link).
- JWT-based; session lưu ở `localStorage` (`storageKey` mặc định của supabase-js).
- `useAuth` composable quản lý session + profile, router guard check `isAuthenticated` + role.
- Custom Access Token hook (`supabase/functions/custom-access-token`) để inject `branch_id`/`role` vào JWT claims (xem `docs/SUPABASE_AUTH.md`).

### 4.5. API

- **Supabase auto-generated REST API** cho mọi bảng (PostgREST).
- **Supabase Edge Functions** cho các nghiệp vụ đặc biệt cần server-side logic (check-in, checkout, issue-tax-invoice, kds-push, ...).
- Helper `src/utils/edge.ts` (`callEdgeFunction<TReq, TRes>`) gọi Edge Function với session hiện tại.

### 4.6. Deployment

- **Frontend**: Vercel (Hobby/Free tier).
- **Backend**: Supabase Pro (`$25/month`, region Singapore).
- Domain dự kiến: `pos.nguucat.vn`.
- Build command: `npm run build` (`vue-tsc -b && vite build`).
- Output: `dist/`.

### 4.7. Testing

- **Playwright** (`^1.61.0`) cho E2E test (chỉ có 1 spec: `e2e/auth.spec.ts`).
- Hiện **chưa có** unit test cho composables hay component test.

### 4.8. Package manager & Build tool

- **npm** (có `package-lock.json`).
- **Vite 8** (bundler), **vue-tsc** (type-check).
- **PostCSS** + **autoprefixer** cho Tailwind.

---

## 5. Cấu trúc thư mục

```
ProjectCongTyEEE/
├── PROJECT_OVERVIEW.md          ← file này
├── README.md                    ← README chính
├── BUSINESS_ANALYSIS.md         ← phân tích nghiệp vụ
├── RESTAURANT_SYSTEM_ANALYSIS.md ← phân tích hệ thống
├── plan.md                      ← kế hoạch phát triển (đến 31/07/2026)
│
├── index.html                   ← HTML shell (font Nunito + Noto Sans JP)
├── package.json                 ← scripts: dev / build / preview
├── vite.config.ts               ← alias `@` → `./src`
├── tsconfig.json / .app / .node ← TS references
├── tailwind.config.ts           ← kawaii palette + custom utilities
├── postcss.config.cjs
├── playwright.config.ts         ← E2E config (chromium only)
├── .gitignore
│
├── src/                         ← Frontend SPA
│   ├── main.ts                  ← createApp + Pinia + router + i18n + useAuth init
│   ├── App.vue                  ← chỉ chứa <RouterView />
│   │
│   ├── router/index.ts          ← 7 portal route trees + guards
│   ├── stores/i18n.ts           ← Pinia store cho locale (vi/ja/en)
│   ├── locales/                 ← vi.ts, ja.ts, en.ts, index.ts (vue-i18n)
│   ├── lib/
│   │   ├── supabase.ts          ← singleton Supabase client
│   │   ├── mock-data.ts         ← mock data cho demo (legacy)
│   │   └── utils.ts             ← cn() clsx + tailwind-merge
│   ├── utils/edge.ts            ← callEdgeFunction<TReq, TRes> helper
│   ├── types/
│   │   ├── database.ts          ← TS types cho 23 bảng Supabase
│   │   └── models.ts            ← re-export + UI enums
│   │
│   ├── composables/             ← business logic (mỗi file 1 domain)
│   │   ├── useAuth.ts           ← session + profile + role
│   │   ├── useBranch.ts         ← active branch selector
│   │   ├── useReservation.ts    ← CRUD reservation
│   │   ├── useOrder.ts          ← add order item (Edge Function)
│   │   ├── useCheckout.ts       ← checkout (Edge Function)
│   │   ├── useCheckIn.ts        ← check-in (Edge Function)
│   │   ├── useCustomer.ts       ← search/upsert customer
│   │   ├── useTable.ts          ← zones + tables
│   │   ├── useMenu.ts           ← categories + items + packages
│   │   ├── useShift.ts          ← close shift + export CSV
│   │   ├── useTaxInvoice.ts     ← issue tax invoice (Edge Function)
│   │   ├── useKDS.ts            ← push to kitchen display
│   │   ├── useKPI.ts            ← KPI targets CRUD
│   │   ├── useMarketing.ts      ← marketing costs CRUD
│   │   ├── useInventory.ts      ← inventory (placeholder)
│   │   ├── useNotification.ts   ← notifications
│   │   ├── useReport.ts         ← aggregate reporting RPC
│   │   ├── useAudit.ts          ← audit events
│   │   └── useRealtime.ts       ← Postgres Changes subscription
│   │
│   ├── layouts/                 ← 1 layout cho mỗi portal
│   │   ├── DashboardLayout.vue  ← legacy wrapper
│   │   ├── AdminLayout.vue
│   │   ├── ManagerLayout.vue
│   │   ├── ReceptionLayout.vue
│   │   ├── StaffLayout.vue
│   │   ├── TabletLayout.vue
│   │   ├── KitchenLayout.vue
│   │   └── SuperadminLayout.vue
│   │
│   ├── views/                   ← 27 views
│   │   ├── LoginView.vue
│   │   ├── TimelineView.vue     ← legacy, chưa kết nối DB
│   │   ├── ListView.vue         ← legacy
│   │   ├── FloorPlanView.vue    ← legacy
│   │   ├── admin/               ← Dashboard, Accounts, Menus, Floors, KPI, Audit
│   │   ├── manager/             ← Dashboard, Revenue, COGS, Marketing, CRM, Inventory
│   │   ├── reception/           ← Dashboard, Checkout, CloseShift
│   │   ├── staff/               ← FloorPlan, OpenTable, InDiningCRM, ActiveTables
│   │   ├── tablet/              ← Idle, Language, Order, Checkout
│   │   ├── kitchen/             ← KDS
│   │   └── superadmin/          ← Dashboard, Brands, Integrations
│   │
│   └── styles/
│       ├── globals.css          ← Tailwind layers + kawaii CSS vars
│       └── styles.css
│
├── supabase/                    ← Supabase backend
│   ├── migrations/
│   │   └── 20260623000000_setup.sql   ← schema 23 bảng + RLS + triggers + seed
│   └── functions/
│       ├── _shared/auth.ts             ← helpers (cors, getAdminClient, requireUser)
│       ├── _shared/cors.ts
│       ├── check-in/index.ts
│       ├── add-order-item/index.ts
│       ├── checkout/index.ts
│       ├── close-shift/index.ts
│       ├── export-shift-csv/index.ts
│       ├── issue-tax-invoice/index.ts
│       ├── kds-push/index.ts
│       ├── request-checkout/index.ts
│       └── custom-access-token/index.ts
│
├── e2e/
│   └── auth.spec.ts             ← Playwright E2E cho /login
│
├── docs/                        ← ~5,000 dòng tài liệu (VI/JA)
│   ├── README.md                ← index cho agent mới
│   ├── DATABASE_DESIGN.md
│   ├── DATABASE_SCHEMA.sql      ← mirror file migration
│   ├── DATABASE_SCHEMA_REVIEW.md
│   ├── SUPABASE_SETUP.md
│   ├── SUPABASE_AUTH.md
│   ├── SUPABASE_FUNCTIONS.md
│   ├── SUPABASE_REALTIME.md
│   ├── API_IMPLEMENTATION_GUIDE.md  ← ★ WHAT: view → API mapping
│   ├── EXECUTION_PLAYBOOK.md        ← ★ HOW: 7 phases
│   ├── TESTING_VERIFICATION_GUIDE.md ← ★ TEST scripts
│   ├── COST_ANALYSIS.md
│   ├── WEEKLY_REPORT_2026-06-21.md
│   ├── business process/        ← file nghiệp vụ bổ sung
│   └── *.xlsx / *.csv / *.pdf   ← file tham khảo (POS checklist, OrderFlowChart)
│
├── .agents/                     ← agent metadata
├── extract_functions.py         ← script hỗ trợ (legacy)
├── playwright-report/           ← output Playwright
├── test-results/                ← output Playwright
├── skills-lock.json             ← lock cho agent skills (supabase)
└── package-lock.json
```

---

## 6. Các chức năng chính

| # | Chức năng / Module | Mục đích | File chính | Trạng thái |
|---|---------------------|----------|------------|------------|
| 1 | **Authentication** | Đăng nhập/đăng xuất, session, profile fetch từ `public.users` | `composables/useAuth.ts`, `views/LoginView.vue`, `router/index.ts` (guard) | ✅ Đã code, chưa verify trên prod |
| 2 | **Branch management** | Selector chi nhánh (admin override qua localStorage, các role khác dùng `users.branch_id`) | `composables/useBranch.ts` | ✅ Đã code |
| 3 | **Reservation (đặt bàn)** | CRUD reservation theo ngày, theo khách hàng, theo status | `composables/useReservation.ts`, `views/manager/ManagerDashboardView.vue` | ✅ Đã code |
| 4 | **Check-in (walk-in + reservation)** | Tạo/gán bàn, capture demographics, cập nhật status → Arrived/Dining | `composables/useCheckIn.ts`, `supabase/functions/check-in/` | ✅ Đã code |
| 5 | **Order / gọi món** | Thêm món vào order, snapshot giá, push xuống KDS | `composables/useOrder.ts`, `supabase/functions/add-order-item/` | ✅ Đã code |
| 6 | **Checkout / thanh toán** | Tạo invoice, nhiều payment methods (cash/card/transfer/voucher), split bill | `composables/useCheckout.ts`, `supabase/functions/checkout/` | ✅ Đã code |
| 7 | **Tax invoice (hóa đơn đỏ VN)** | Xuất hóa đơn điện tử qua cổng thuế VN (MST 10/13 số, công ty, địa chỉ) | `composables/useTaxInvoice.ts`, `supabase/functions/issue-tax-invoice/` | ✅ Đã code, chưa rõ provider cụ thể |
| 8 | **Shift / ca thu ngân** | Mở/đóng ca, đối chiếu tiền mặt, xuất CSV | `composables/useShift.ts`, `supabase/functions/close-shift/`, `export-shift-csv/` | ✅ Đã code |
| 9 | **Menu / Packages** | CRUD categories, items, packages (set/buffet/drink) | `composables/useMenu.ts`, `views/admin/AdminMenusView.vue` | ✅ Đã code |
| 10 | **Tables / Zones (sơ đồ bàn)** | Quản lý zones, bàn (vị trí pos_x/pos_y, capacity, status) | `composables/useTable.ts`, `views/admin/AdminFloorsView.vue`, `views/staff/StaffFloorPlanView.vue` | ✅ Đã code |
| 11 | **KDS (Kitchen Display)** | Đẩy order_item xuống bếp theo station (hot/cold/bar) | `composables/useKDS.ts`, `supabase/functions/kds-push/`, `views/kitchen/KitchenKDSView.vue` | ✅ Đã code |
| 12 | **KPI / Targets** | Cấu hình target theo period (daily/weekly/monthly) | `composables/useKPI.ts`, `views/admin/AdminKPIView.vue` | ✅ Đã code |
| 13 | **CRM / Customer** | Tìm theo SĐT, danh sách VIP, demographics | `composables/useCustomer.ts`, `views/manager/ManagerCRMView.vue`, `views/staff/StaffInDiningCRMView.vue` | ✅ Đã code |
| 14 | **Marketing costs** | Chi phí marketing theo channel × period, tính CPA/ROI | `composables/useMarketing.ts`, `views/manager/ManagerMarketingView.vue` | ✅ Đã code |
| 15 | **Revenue / COGS reports** | Aggregate báo cáo doanh thu theo giờ, giá vốn | `composables/useReport.ts`, RPC `revenue_by_hour()`, `views/manager/ManagerRevenueView.vue`, `ManagerCOGSView.vue` | ⚠️ Partial: một số ước lượng (covers = orders*2) là placeholder |
| 16 | **Inventory** | Cảnh báo tồn kho thấp | `composables/useInventory.ts`, `views/manager/ManagerInventoryView.vue` | ⚠️ Placeholder: chưa có bảng inventory_items |
| 17 | **Notifications** | Notification feed theo role | `composables/useNotification.ts` | ✅ Đã code |
| 18 | **Audit log** | Xem audit events, lọc theo entity | `composables/useAudit.ts`, `views/admin/AdminAuditView.vue` | ✅ Đã code (DB tự ghi qua triggers) |
| 19 | **Realtime updates** | Subscribe Postgres Changes cho 7 bảng | `composables/useRealtime.ts` | ✅ Đã code |
| 20 | **i18n (vi/ja/en)** | Đổi ngôn ngữ, persist qua localStorage, sync `<html lang>` | `stores/i18n.ts`, `locales/*` | ✅ Đã code |

---

## 7. Luồng hoạt động tổng quát

### 7.1. Stack tổng quan

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Vue 3 SPA)                        │
│                                                                      │
│   Layout (theo role)  →  Views (27)  →  Composables (18)            │
│                                              │                       │
│                                              ├── supabase.from()    │
│                                              │     (PostgREST)       │
│                                              │                       │
│                                              └── callEdgeFunction()  │
│                                                   (Deno runtime)    │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                │ HTTPS + WebSocket
                                │
┌────────────────────────────────▼────────────────────────────────────┐
│                          SUPABASE PRO                                │
│                                                                      │
│   PostgreSQL 15+   Auth   Realtime   Edge Functions   Storage       │
│   (23 tables)      (JWT)  (WS)       (9 functions)   (buckets)      │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                        Multi-tenant data
                   (branch_id trên mọi bảng)
```

### 7.2. Luồng điển hình: Khách đặt bàn → Ăn → Thanh toán

1. **Reception tạo reservation** (`useReservation.create()`):
   - Insert row vào `reservations` với status `Pending`.
   - Snapshot thông tin khách vào `customer_snapshot`.
2. **Reception check-in** khi khách đến (`useCheckIn.checkIn()` → Edge Function `check-in`):
   - Cập nhật `reservations.status = 'Arrived'`, ghi `arrived_at`.
   - Insert row `table_assignments` (mapping bàn ↔ reservation ↔ table).
   - Có thể capture demographics vào `metadata`.
3. **Staff / Tablet gọi món** (`useOrder.addItem()` → Edge Function `add-order-item`):
   - Insert `orders` (nếu chưa có) + `order_items` với `name_snapshot`, `unit_price`, `unit_cost`.
   - Push xuống KDS qua Edge Function `kds-push` để bếp nhận.
4. **Reception checkout** (`useCheckout.checkout()` → Edge Function `checkout`):
   - Tính lại `subtotal / vat / total`, áp voucher (nếu có).
   - Tạo `invoices` + nhiều `payments` (split bill support).
   - Cập nhật `tables.status = 'available'` khi `table_assignments.released_at`.
   - Cập nhật `customers.total_visits`, `customers.total_spent`.
5. **Manager xem báo cáo** (`useReport.revenueByHour()` → RPC `revenue_by_hour()`):
   - Đọc từ `payments` aggregate theo `paid_at`.

### 7.3. Realtime

- `useRealtime.watchTable(table, event, callback, filter)` subscribe Postgres Changes.
- Filter mặc định: `branch_id=eq.<activeBranchId>` để tiết kiệm connection slots.
- Channels được dedupe theo tên để nhiều component dùng chung 1 websocket.

### 7.4. Auth & Routing

1. `main.ts` gọi `useAuth().init()` → fetch session + profile từ `public.users`.
2. `router.beforeEach`:
   - Đợi `useAuth().loading === false`.
   - Route không `requiresAuth: false` (chỉ `/login`) phải có `isAuthenticated`.
   - Check `ROUTE_ROLES[prefix]` → nếu role không thuộc → redirect về `manager-dashboard`.
3. Sau khi login thành công → push `home` (router resolves về `/manager/dashboard` theo mặc định).

### 7.5. Multi-tenancy

- Mọi bảng HIGH-consistency có `branch_id`.
- `useBranch().activeBranchId` trả về branch đang chọn (admin override qua localStorage, role khác dùng `users.branch_id`).
- RLS policies scope theo `public.current_branch_id()`.

---

## 8. Cách chạy dự án

> **Lưu ý**: Tất cả lệnh dưới đây được lấy từ `package.json`, `playwright.config.ts`, `docs/SUPABASE_SETUP.md`. **Không tự ý thêm lệnh** nếu chưa có bằng chứng.

### 8.1. Cài đặt dependencies

```bash
npm install
```

### 8.2. Cấu hình biến môi trường

Tạo file `.env.local` ở root (đã có trong `.gitignore`):

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=<anon-public-key>
# Alias fallback:
# VITE_SUPABASE_ANON_KEY=<anon-public-key>
```

> File `.env.example` chưa có trong repo — cần tự tạo nếu muốn chuẩn hóa.

### 8.3. Chạy dev (frontend)

```bash
npm run dev
# Mặc định chạy ở http://localhost:5173
```

### 8.4. Build production

```bash
npm run build
# Tương đương: vue-tsc -b && vite build
# Output: dist/
```

### 8.5. Preview build

```bash
npm run preview
```

### 8.6. Chạy E2E test (Playwright)

```bash
# Cần dev server đang chạy (Playwright tự bật nếu chưa có, xem playwright.config.ts)
npx playwright test
```

> Hiện chỉ có 1 file test: `e2e/auth.spec.ts`.

### 8.7. Chạy database / migrations

Cách thực hiện theo `docs/SUPABASE_SETUP.md`:
1. Tạo project Supabase (region Singapore, plan Pro).
2. Vào **SQL Editor** → paste nộiài `supabase/migrations/20260623000000_setup.sql` → **Run**.
3. Bật Realtime publication (đã có sẵn trong file migration).
4. Bật trigger `auth.users → public.users` (snippet trong `docs/SUPABASE_SETUP.md`).
5. Tạo Storage buckets: `menu-images` (public), `customer-photos` (private), `invoices`, `audit-attachments`.

### 8.8. Deploy Edge Functions

```bash
supabase login
supabase link --project-ref <project-ref>
supabase functions deploy check-in
supabase functions deploy checkout
supabase functions deploy add-order-item
# ... 6 functions còn lại
supabase secrets set VT_API_KEY=xxx
supabase secrets set PRINT_AGENT_URL=xxx
supabase secrets set KDS_WS_URL=xxx
```

### 8.9. Lệnh thường dùng khi dev

```bash
# Type-check nhanh
npx vue-tsc -b

# Xem DB types
npx supabase gen types typescript --project-id <ref> --schema public > src/types/database.ts
```

---

## 9. Quy tắc làm việc dành cho AI Agent

### 9.1. Trước khi sửa code

- **Luôn đọc `PROJECT_OVERVIEW.md`** (file này) trước.
- Đọc kỹ các file liên quan đến task trước khi chỉnh sửa.
- Không sửa code khi chưa hiểu luồng hoạt động.
- Không tự ý đổi kiến trúc nếu task không yêu cầu.
- Không xóa code cũ nếu chưa chắc chắn nó không còn được dùng. Đặc biệt với `mock-data.ts`, `TimelineView.vue`, `ListView.vue`, `FloorPlanView.vue` (root) — chúng là legacy/demo, chỉ xóa khi có lệnh rõ.
- Không tự ý đổi tên file, tên hàm, tên biến public API nếu không cần thiết.
- Nếu có nhiều cách làm, ưu tiên cách ít ảnh hưởng đến phần còn lại.
- Nếu task mơ hồ, tự phân tích phạm vi hợp lý và **ghi rõ giả định** trước khi làm.

### 9.2. Trong khi sửa code

- Giữ code rõ ràng, dễ đọc, dễ bảo trì. Match với style hiện có (Composition API + `<script setup>` + TypeScript).
- **Không hard-code** secret, API key, password, token. Dùng biến môi trường.
- **Không tự ý đổi format response API** của Edge Functions — các composable đang dựa vào shape cũ.
- **Không tự ý đổi database schema** (`supabase/migrations/*.sql`) nếu task không yêu cầu. Mọi thay đổi schema cần tạo migration mới, không sửa file cũ.
- Khi thêm logic mới, đặt đúng tầng:
  - **UI** (`.vue`) chỉ chứa template + reactive state + gọi composable.
  - **Composable** (`src/composables/*.ts`) chứa business logic giao tiếp DB/Edge Function.
  - **Edge Function** (`supabase/functions/*/index.ts`) chứa logic phía server cần bypass RLS/admin client.
- **Không format toàn bộ project** nếu task chỉ yêu cầu sửa một phần nhỏ.
- **Không thêm dependency mới** nếu chưa thật sự cần thiết. Nếu cần, phải hỏi user trước.
- **Không tự ý đổi Tailwind config / `globals.css`** — theme "kawaii" đã được đồng bộ giữa nhiều view.

### 9.3. Sau khi sửa code

Agent **bắt buộc** tự kiểm tra lại:
- Code có chạy đúng mục tiêu task không?
- Có làm hỏng chức năng cũ không?
- Có lỗi cú pháp / type không? (`vue-tsc -b`)
- Có cần update tài liệu (`docs/` hoặc `PROJECT_OVERVIEW.md`) không?
- Có case lỗi nào chưa xử lý không?
- Có đoạn code nào có thể viết gọn/rõ/an toàn hơn không?
- Có ảnh hưởng đến API, database, UI hoặc flow cũ không?

Nếu phát hiện điểm chưa tốt, **tự sửa lại trước khi báo hoàn thành**.

---

## 10. Quy trình làm việc chuẩn cho agent

1. Đọc `PROJECT_OVERVIEW.md` (file này).
2. Đọc `docs/README.md` để biết thứ tự tài liệu cần đọc tiếp theo.
3. Xác định task ảnh hưởng đến phần nào của dự án (frontend / composable / Edge Function / DB / docs).
4. Đọc các file liên quan (ưu tiên file trong `docs/` tương ứng — ví dụ sửa Edge Function thì đọc `SUPABASE_FUNCTIONS.md`).
5. Lập kế hoạch sửa ngắn gọn (trong phần trả lời, không cần file riêng).
6. Thực hiện chỉnh sửa.
7. Kiểm tra lại bằng lệnh phù hợp:
   ```bash
   npx vue-tsc -b                  # type-check frontend
   npm run build                   # full build
   npx playwright test             # E2E (nếu chạm UI)
   ```
8. Tự review kết quả (theo checklist ở mục 9.3).
9. Sửa lại nếu phát hiện vấn đề.
10. Báo cáo ngắn gọn:
    - Đã sửa gì
    - Sửa ở file nào
    - Đã kiểm tra bằng cách nào
    - Còn rủi ro / điểm cần xác minh không

---

## 11. Nguyên tắc sử dụng Git/GitHub cho AI Agent

### 11.1. Trước khi sửa code

Luôn chạy:
```bash
git status
```

Nếu working tree không sạch:
- Phân biệt rõ file nào do user/dev khác tạo, file nào do agent tạo trước đó, file nào conflict.
- **Không tự ý ghi đè** thay đổi có sẵn nếu chưa chắc đó là phần mình được phép sửa.
- Báo rõ trước khi tiếp tục: file nào đang bị thay đổi, có ảnh hưởng đến task không, agent sẽ chỉnh sửa file nào.

### 11.2. Branch làm việc

- **Không sửa trực tiếp trên `main`** trừ khi user yêu cầu rõ.
- Branch chính: `main` (theo `git status` ban đầu).
- Tạo branch mới trước khi sửa:
  ```bash
  git checkout -b feature/ten-task-ngan-gon
  git checkout -b fix/ten-task-ngan-gon
  git checkout -b docs/update-readme
  git checkout -b refactor/ten-module
  ```
- **Không đặt** tên branch mơ hồ như `test`, `update`, `fix`, `new`, `abc`.

### 11.3. Pull code mới nhất

```bash
git remote -v
git pull
```

> **Không pull** nếu working tree đang có thay đổi chưa commit (gây conflict).

### 11.4. Quy tắc commit

- **Chỉ commit khi user yêu cầu** hoặc task yêu cầu rõ ràng.
- Trước khi commit:
  ```bash
  git status
  git diff
  ```
- **Chỉ commit những file liên quan** trực tiếp đến task.
- **Không commit**: `node_modules/`, `dist/`, `.env`, `*.log`, file IDE, file OS.
- Commit message tốt:
  ```
  docs: add project overview for agents
  fix: handle login error response
  feat: add user management page
  refactor: simplify product service logic
  ```
- Commit message **không tốt**: `update`, `fix bug`, `done`, `change code`, `final`.

### 11.5. Quy tắc push lên GitHub

- **Tuyệt đối không tự ý push** nếu user chưa cho phép.
- **Không push force** trong mọi trường hợp.
- **Không push lên branch chính** (`main`, `master`, `production`, `staging`, `develop`) nếu chưa có quyết định rõ từ user.
- Trước khi push phải báo:
  - Branch hiện tại là gì
  - Sẽ push lên remote nào
  - Có bao nhiêu commit mới
  - Có file nhạy cảm nào bị commit không

### 11.6. Quy tắc Pull Request

Nếu dùng PR workflow:
- Tiêu đề rõ ràng
- Mô tả: đã sửa gì, lý do sửa, file bị ảnh hưởng, cách kiểm tra, rủi ro còn lại

Mẫu mô tả PR:

```md
## Summary
- Added/updated project overview documentation
- Documented project structure, tech stack, and agent workflow

## Changes
- Created `PROJECT_OVERVIEW.md`
- Added Git/GitHub working rules for AI agents

## Testing
- Reviewed generated documentation manually
- No source code logic was changed

## Risks
- Some project details may need verification if not clear from source code
```

### 11.7. Những lệnh Git nguy hiểm cần hỏi xác nhận trước

Agent **bắt buộc** hỏi xác nhận trước khi chạy:

```bash
git reset --hard
git clean -fd
git clean -fdx
git checkout -- .
git restore .
git rebase
git rebase --abort
git merge
git merge --abort
git push --force
git push -f
git branch -D
git tag -d
```

Cũng phải hỏi trước khi:
- Xóa branch
- Ghi đè lịch sử commit
- Rebase branch
- Merge branch lớn
- Xóa toàn bộ thay đổi local
- Xóa file chưa được commit
- Thay đổi remote URL
- Push lên branch chính
- Sửa file cấu hình CI/CD
- Sửa GitHub Actions
- Sửa file deploy

### 11.8. Bảo vệ file nhạy cảm

Agent **không được commit** các file:
```
.env
.env.local
.env.production
.env.development
*.pem
*.key
id_rsa
credentials.json
service-account.json
```

Nếu phát hiện file nhạy cảm đang chuẩn bị commit → **dừng lại và báo cho user**.

Nếu cần cung cấp mẫu biến môi trường, dùng `.env.example` (chỉ ghi key, không ghi value thật):

```env
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

### 11.9. Khi gặp conflict

1. Xác định file bị conflict.
2. Đọc kỹ cả hai phần.
3. Giải thích nguyên nhân conflict (nếu có thể).
4. Chỉ sửa khi hiểu rõ.
5. Sau khi sửa, chạy kiểm tra lại (`npm run build`, `vue-tsc -b`, ...).
6. Báo rõ đã resolve conflict ở file nào.

**Không xóa conflict marker một cách máy móc** nếu chưa hiểu nội dung.

### 11.10. Không phá lịch sử làm việc của user

Tôn trọng thay đổi hiện có. Không tự ý chạy `reset --hard`, `checkout .`, `restore .`, `clean -fd`. Nếu cần, **phải hỏi xác nhận trước** và giải thích hậu quả.

### 11.11. Báo cáo Git sau khi hoàn thành

Sau khi xong task, báo cáo:
- Đang ở branch nào
- Đã chỉnh sửa file nào
- Có commit chưa + commit hash (nếu có)
- Có push chưa
- Working tree còn sạch hay còn thay đổi
- Có file nào cần user kiểm tra thêm không

Ví dụ:
```
Đã hoàn thành task.

Branch hiện tại: docs/project-overview
File đã sửa:
- PROJECT_OVERVIEW.md

Kiểm tra đã thực hiện:
- Đã đọc lại nội dung file
- Không thay đổi source code
- Không chạy build vì chỉ sửa tài liệu

Git:
- Chưa commit
- Chưa push
- Working tree còn thay đổi ở PROJECT_OVERVIEW.md
```

---

## 12. Quy tắc tự động quyền / YOLO mode

Ngay cả khi chạy ở chế độ tự động / YOLO mode, agent **vẫn phải** tuân thủ giới hạn sau.

### 12.1. Được phép tự làm (không cần hỏi)

- Đọc file, tìm kiếm trong source code.
- Tạo file tài liệu mới (markdown).
- Cập nhật file markdown liên quan đến task.
- Chạy lệnh kiểm tra an toàn:
  ```bash
  git status
  git diff
  npm run build
  npx playwright test
  npx vue-tsc -b
  ```

### 12.2. Phải hỏi xác nhận trước khi

- Xóa file / thư mục
- Ghi đè file lớn
- Thay đổi kiến trúc dự án
- Cài package mới (`npm install <pkg>`)
- Chạy migration database (chạy SQL trên Supabase)
- Sửa file `.env`
- Commit code
- Push code
- Force push
- Merge / rebase branch
- Chạy lệnh có `rm`, `sudo`, `chmod`, `chown`
- Chạy script không rõ tác dụng
- Thay đổi cấu hình deploy / CI/CD

---

## 13. Các điểm chưa rõ / cần xác minh

| # | Điểm cần xác minh | Ghi chú |
|---|--------------------|---------|
| 1 | Database production dùng gì, đã provision chưa | Có schema nhưng chưa biết project Supabase nào đang chạy |
| 2 | File `.env.example` chuẩn | **Chưa có** trong repo. Cần tạo |
| 3 | Unit test cho composables / components | **Chưa có**, chỉ có 1 file Playwright cho login |
| 4 | Quy trình deploy chính thức | Tài liệu nói dùng Vercel + Supabase Pro, chưa thấy GitHub Actions / CI |
| 5 | Phân quyền chi tiết cho từng role (read/write từng bảng) | Đã có RLS trong DB nhưng frontend chỉ check role prefix qua `ROUTE_ROLES` |
| 6 | Branch workflow của team (GitFlow? trunk-based?) | **Chưa rõ**, repo hiện chỉ có `main` |
| 7 | Quy tắc commit / PR / review của team | **Chưa có tài liệu nội bộ** (Pull Request template, Issue template) |
| 8 | Provider thuế điện tử VN cụ thể | `issue-tax-invoice` Edge Function có sẵn nhưng `VT_API_KEY` chưa biết là của nhà cung cấp nào (VNPT/Tax24/MISA/Viettel) |
| 9 | Đã migrate dữ liệu từ F2Tech chưa | `plan.md` nói đến 31/07/2026 nhưng repo chưa có script migration |
| 10 | Test trên chi nhánh thí điểm thực tế | Chưa có bằng chứng trong code |
| 11 | Tích hợp payment gateway (VNPay/MoMo/...) | `payments.method` enum đã có `card | transfer` nhưng chưa có code tích hợp |
| 12 | Tích hợp printer (máy in hóa đơn) | `PRINT_AGENT_URL` được nhắc nhưng chưa có code |
| 13 | Module Inventory thật | `useInventory` đang là placeholder; chưa có bảng `inventory_items` |
| 14 | Module Report nâng cao (covers, hourly density, ABC analysis) | `useReport.todayHeadline` ước lượng `covers = orders * 2` |
| 15 | Các view legacy ở root (`TimelineView`, `ListView`, `FloorPlanView`) | Còn dùng `mock-data.ts`; chưa rõ có kết nối Supabase chưa |

---

## 14. Đề xuất cải thiện tài liệu / dự án

### 14.1. Tài liệu

1. **Tạo `.env.example`** ở root với các key mẫu (không commit value thật).
2. **Bổ sung `CONTRIBUTING.md`** mô tả quy tắc commit + PR cho team.
3. **Bổ sung `ARCHITECTURE.md`** với sơ đồ kiến trúc tổng thể (frontend ↔ Supabase ↔ Edge Functions ↔ storage).
4. **Bổ sung Pull Request template** (`.github/PULL_REQUEST_TEMPLATE.md`).
5. **Bổ sung Issue template** (`.github/ISSUE_TEMPLATE/`).
6. **Bổ sung `DEPLOYMENT.md`** mô tả quy trình deploy chi tiết (Vercel + Supabase CLI + secrets).
7. **Bổ sung `RUNBOOK.md`** cho operations (rollback, debug production, hotfix).
8. **Bổ sung CHANGELOG.md** để track version.

### 14.2. Dự án

1. **Chuẩn hóa cấu trúc thư mục**:
   - Quyết định giữ hay bỏ `mock-data.ts` + 3 view legacy ở root.
   - Gom view theo role vào đúng thư mục (đã làm một phần).
2. **Bổ sung test**:
   - Unit test cho composables (`useReservation`, `useCheckout`, ...).
   - Component test cho view quan trọng.
   - E2E flow cho happy path (đặt bàn → check-in → order → checkout).
3. **Bổ sung CI**:
   - GitHub Actions: `npm run build`, `npx vue-tsc -b`, `npx playwright test`.
   - Tự động type-check mỗi PR.
4. **Bổ sung comment** cho logic phức tạp:
   - `useRealtime` (refCount logic).
   - `useBranch` (admin override).
   - RLS policies trong migration.
5. **Hoàn thiện module Inventory**:
   - Tạo bảng `inventory_items` + RLS + trigger.
   - Wire `useInventory.listLowStock` thật.
6. **Hoàn thiện Report**:
   - Thay `covers = orders * 2` bằng aggregate thật (đếm `guests` từ `reservations`).
   - Thêm views aggregate: hourly density, ABC analysis, channel ROI.
7. **Hoàn thiện Realtime mapping**:
   - Đảm bảo mỗi view có đúng subscription cần thiết (xem `docs/SUPABASE_REALTIME.md`).
8. **Bổ sung seed data script** (idempotent) để test trên local Supabase.
9. **Tạo storage buckets RLS policies** rõ ràng.
10. **Bổ sung error boundary** cho Vue components.

---

## 15. Yêu cầu quan trọng

- **Không được bịa thông tin.** Mọi mô tả trong file này đều có bằng chứng từ source code hoặc file cấu hình. Nếu chưa chắc, đã ghi rõ "chưa xác định" / "cần xác minh".
- **Không tự ý sửa logic source code** khi nhiệm vụ chỉ là tạo tài liệu.
- **Không xóa file hiện có.**
- **Không tự ý commit / push** nếu user chưa yêu cầu.
- **Không force push** trong mọi trường hợp.
- Nếu file `PROJECT_OVERVIEW.md` đã tồn tại, **cập nhật** thay vì ghi đè toàn bộ một cách thiếu kiểm soát.
- Sau khi tạo xong, **tự đọc lại** file để kiểm tra thiếu sót.
- Cuối cùng, báo cáo lại ngắn gọn cho user theo mẫu ở mục 11.11.

---

## Phụ lục A — Thứ tự đọc tài liệu gợi ý cho agent mới

```
1. PROJECT_OVERVIEW.md              ← file này
2. README.md                        ← mô tả ngắn + scripts
3. BUSINESS_ANALYSIS.md             ← hiểu nghiệp vụ
4. docs/README.md                   ← index docs/
5. docs/DATABASE_DESIGN.md          ← kiến trúc DB
6. docs/DATABASE_SCHEMA.sql         ← schema đầy đủ
7. docs/SUPABASE_SETUP.md           ← setup Supabase
8. docs/SUPABASE_AUTH.md            ← auth + RLS
9. docs/SUPABASE_FUNCTIONS.md       ← 9 Edge Functions
10. docs/SUPABASE_REALTIME.md       ← realtime subscription
11. docs/API_IMPLEMENTATION_GUIDE.md ← WHAT: view → API mapping
12. docs/EXECUTION_PLAYBOOK.md       ← HOW: 7 phases
13. docs/TESTING_VERIFICATION_GUIDE.md ← TEST scripts
```

## Phụ lục B — Bản đồ route ↔ role ↔ layout

| Path | Role được phép | Layout | Views |
|------|---------------|--------|-------|
| `/login` | (public) | — | LoginView |
| `/` | (redirect → `/manager/dashboard`) | — | — |
| `/admin/*` | `admin` | AdminLayout | dashboard, accounts, menus, floors, kpi, audit |
| `/superadmin/*` | `admin` (impersonate) | SuperadminLayout | dashboard, brands, integrations |
| `/manager/*` | `admin`, `manager` | ManagerLayout | dashboard, revenue, cogs, marketing, crm, inventory |
| `/reception/*` | `admin`, `manager`, `reception` | ReceptionLayout | dashboard, checkout/:id, close-shift |
| `/staff/*` | `admin`, `manager`, `staff` | StaffLayout | floor-plan, active-tables, table/:id/open, table/:id/crm |
| `/kitchen/*` | `admin`, `kitchen` | KitchenLayout | kds |
| `/tablet/*` | `admin`, `manager`, `reception`, `staff` | TabletLayout | idle, language, order, checkout |

Xem chi tiết trong `src/router/index.ts` (constants `ROUTE_ROLES`).