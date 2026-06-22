# NguuCat POS — Database Schema Coverage Review

**File:** `docs/DATABASE_SCHEMA.sql` (571 lines, 30KB, PostgreSQL 15+ / Supabase target)
**Scope (lần này):** Chức năng POS cho các chi nhánh NguuCat — gọi món, thanh toán, quản lý bàn, báo cáo cơ bản.
**Out of scope (đã xác nhận):** Đa thương hiệu, tích hợp toàn tập đoàn, tích hợp sâu HR / quản lý kho.

---

## TL;DR

| Khu vực chức năng | Mức bao phủ | Ghi chú |
| --- | --- | --- |
| Reservation / Đặt bàn | ✅ Đầy đủ | reservations, table_assignments, deposits |
| Quản lý bàn (table management) | ✅ Đầy đủ | tables, table_status enum, table_assignments.released_at |
| Gọi món (ordering) | ✅ Đầy đủ | orders, order_items, snapshot giá + modifiers JSONB |
| Thanh toán (payment / split bill) | ✅ Đầy đủ | payments (n-1 invoice), payment_method enum |
| Hóa đơn / hóa đơn đỏ | ⚠️ Có dữ liệu nhưng **thiếu VAT/customer tax code chuẩn VN** | invoices có customer_snapshot JSONB, thiếu tax_code có cấu trúc |
| Ca làm việc / đóng ca | ✅ Đầy đủ | shifts (open/close, opening/closing cash, diff) |
| Báo cáo doanh thu (revenue) | ✅ Truy vấn được | invoices + payments + orders, có index (branch, created_at desc) |
| Báo cáo COGS / giá vốn | ❌ **THIẾU** bảng công thức định lượng | inventory_items có nhưng không liên kết ngược về menu_items |
| Báo cáo Marketing / kênh | ⚠️ Phải dùng JSONB `metadata` trên reservations.notes | Không có cột marketing_channel chuẩn |
| Báo cáo CRM / khách quen | ✅ Đầy đủ | customers + tags JSONB + is_vip + visits đếm từ reservations |
| Tồn kho / xuất bếp | ⚠️ Một nửa | inventory_items + inventory_txns có, nhưng công thức định lượng món (recipe/BOM) **thiếu** |
| Audit log | ✅ Có bảng `audit_events` | AdminAuditView hiện đang placeholder |
| KPI / KGI target | ❌ **THIẾU** bảng `kpi_targets` | AdminKPIView là placeholder, không thể lưu chỉ tiêu |
| Multi-tenant | ✅ branch_id ở mọi bảng nghiệp vụ | 19/19 bảng operational đều có `branch_id NOT NULL` |
| RLS / Auth | 🟡 Có scaffold, chưa có policy thực tế | 19/19 bảng đã `enable row level security`, chỉ có 1 policy mẫu |
| Realtime (Supabase) | 🟡 Có comment gợi ý | Chưa `alter publication supabase_realtime add table ...` |

---

## 1. Kiến trúc & nguyên tắc thiết kế (đã tốt)

- **Multi-tenant từ ngày 1**: `branch_id NOT NULL` trên 19/19 bảng operational, FK `branches(id)` cascade đúng chỗ.
- **Hybrid relational + JSONB**: 2 tầng — quan hệ chặt cho tiền/đặt bàn/audit, JSONB cho dữ liệu linh hoạt (modifiers, tags, decorations, notes).
- **Snapshot fields**: `order_items.name_snapshot`, `order_items.unit_price`, `invoices.customer_snapshot` — đóng băng giá trị tại thời điểm ghi, giữ báo cáo lịch sử chính xác khi menu/giá thay đổi.
- **FK discipline**: `ON DELETE CASCADE` cho owned children, `ON DELETE RESTRICT` cho FK không được phép mất âm thầm (e.g. payments.invoice_id), `ON DELETE SET NULL` cho audit-creator (audit_events.user_id).
- **Index chiến lược**:
  - Partial index trên `is_vip`, `is_available`, `released_at IS NULL` → truy vấn dashboard nhanh.
  - GIN index trên JSONB (`reservations.notes`, `menu_items.modifiers/tags`, `order_items.modifiers`, `customers.tags`, `audit_events.payload`) → search linh hoạt.
  - Composite index `(branch_id, created_at desc)` trên orders/invoices/payments/deposits → mọi báo cáo theo thời gian đều đi nhanh.
- **`updated_at` trigger**: gắn cho 13 bảng chính.
- **Enum**: 8 enum (`reservation_status`, `table_status`, `order_status`, `invoice_status`, `payment_method`, `user_role`, `shift_status`, `inventory_txn_type`) — đủ dùng cho UI hiện tại.

---

## 2. Đối chiếu từng view nghiệp vụ trong UI

> So sánh 24 view hiện có trong `src/router/index.ts` với schema.

### 2.1 Reservation flow (đặt bàn → check-in → gán bàn)

| View | Cần dữ liệu | Có trong schema? |
| --- | --- | --- |
| ReceptionDashboardView | reservations hôm nay, trạng thái `Pending/Arrived/Dining` | ✅ `reservations(reservation_date, status)` + index `(branch_id, status)` |
| ReservationCreateView | tạo reservation, optional deposit | ✅ `reservations` + `deposits(method, amount)` |
| TableAssignmentView | gán reservation ↔ tables | ✅ `table_assignments(reservation_id, table_id, released_at)` |

### 2.2 Bàn / sơ đồ tầng (floor plan)

| View | Cần dữ liệu | Có trong schema? |
| --- | --- | --- |
| StaffFloorPlanView | list bàn + zone, trạng thái `available/occupied/reserved/maintenance` | ✅ `tables(zone_id, status)` + `zones` |
| StaffOpenTableView | walk-in không reservation | ✅ `orders(branch_id, reservation_id NULLABLE)` |
| ActiveTablesView | các bàn đang có khách | ✅ partial index `table_assignments(table_id) WHERE released_at IS NULL` |

### 2.3 Tablet gọi món (TabletOrderView)

| Yêu cầu | Schema? |
| --- | --- |
| Giới hạn "3 / 10 món" per bàn | ⚠️ Có thể đếm `order_items` qua `orders.order_id`, **NHƯNG** orders chỉ link tới `reservation_id`, không trực tiếp `table_id`. Phải join: `tables → table_assignments → reservations → orders → order_items`. |
| Danh mục món theo category | ✅ `menu_categories(sort_order)` + `menu_items(category_id, is_available)` |
| Snapshot giá (giá gói vs giá lẻ) | ✅ `order_items.name_snapshot + unit_price + modifiers JSONB` |
| Locked category (gói Drink A) | ✅ `menu_categories.metadata` JSONB |

### 2.4 Thanh toán / hóa đơn (ReceptionCheckoutView, TabletCheckoutView)

| Yêu cầu | Schema? |
| --- | --- |
| Member lookup by phone | ✅ `customers(branch_id, phone)` + index `(branch_id, phone)` |
| Repeater/VIP tag | ✅ `customers.is_vip` + `customers.tags JSONB` |
| Phân loại doanh thu (Dinner/Lunch/Wine/Delivery) | ⚠️ Có thể lưu trong `invoices.notes` hoặc `payments.metadata` JSONB. **Chưa có cột chuẩn `revenue_type`** — dễ sai khi báo cáo. |
| Voucher giảm giá | ⚠️ `orders.discount` + `invoices.discount` có sẵn, nhưng **không có bảng `vouchers`** để quản lý mã, hạn dùng, điều kiện, số lượt dùng. |
| VAT 8% | ⚠️ `orders.vat_rate` mặc định 0.10 (10%), **không phải 8%** của nhà hàng ăn uống VN. Cần default lại 0.08 hoặc làm constant. |
| Split bill (nhiều payment / invoice) | ✅ `payments(invoice_id)` many-to-one. Một invoice có thể có nhiều payment rows. |
| Hóa đơn đỏ (xuất cho cục thuế VN) | ⚠️ `invoices.customer_snapshot` có `tax_code` (trong JSONB), **thiếu cột có cấu trúc `tax_code text`** để index và validate định dạng MST (10/13 số). |
| In hóa đơn & đóng bàn | ✅ `invoices.status` + `table_assignments.released_at` |

### 2.5 Đóng ca (ReceptionCloseShiftView)

| Yêu cầu | Schema? |
| --- | --- |
| Open / close shift với opening_cash / closing_cash | ✅ `shifts(opened_at, closed_at, opening_cash, closing_cash, expected_cash, cash_difference)` |
| Doanh thu theo loại hình trong ca | ⚠️ Có thể aggregate `payments(branch_id, paid_at) WHERE shift_id = ...`, **NHƯNG `payments.shift_id` chưa tồn tại** trong schema. Phải join qua `received_by user_id` + `created_at between shifts.opened_at and shifts.closed_at`. |
| Lịch sử thanh toán trong ca (12 bàn) | ✅ query `payments` + `invoices` + `reservations` |
| Lịch sử ca (ghi chú bàn giao) | ✅ `shifts.notes JSONB` |

### 2.6 Báo cáo doanh thu (ManagerRevenueView)

| Yêu cầu | Schema? |
| --- | --- |
| Doanh thu theo ngày/tuần/tháng | ✅ `payments(branch_id, paid_at)` + index `(branch_id, paid_at desc)` |
| Doanh thu theo loại | ⚠️ Phải nhặt từ `payments.metadata->>'revenue_type'` — JSONB, không enforce |
| So sánh chi nhánh | ✅ mọi query đều có `branch_id` |

### 2.7 Báo cáo giá vốn (ManagerCOGSView) — **KHUYẾT THIẾT**

| Yêu cầu | Schema? |
| --- | --- |
| `cost` per món | ❌ `menu_items` **không có cột `cost`** (cost_of_goods). UI hiển thị giá cost nhưng schema không lưu. |
| `unitCOGS` | ❌ dẫn xuất từ công thức định lượng (recipe/BOM) mà **không có bảng `recipe_items`**. |
| `totalCOGS` = unitCOGS × quantity đã bán | ⚠️ Có thể tính từ `order_items.quantity`, nhưng không biết giá cost từng đơn vị. |
| COGS ratio cảnh báo (>50%) | ⚠️ Phải dẫn xuất runtime, không có snapshot. |

**Thiếu:**
- `menu_items.cost numeric(12,2)` — giá cost snapshot cho từng món.
- Bảng `recipe_items(menu_item_id, inventory_item_id, quantity, unit)` — BOM/định lượng (vd. 1 phần Wagyu cần 0.25kg thăn ngoại).
- (Tùy chọn) `order_items.unit_cost` snapshot để tính COGS chính xác tại thời điểm bán.

### 2.8 Báo cáo Marketing (ManagerMarketingView)

| Yêu cầu | Schema? |
| --- | --- |
| Kênh marketing (Google Map / Facebook / TikTok / Zalo OA / Người quen) | ⚠️ Không có cột `marketing_channel` chuẩn. Có thể lưu trong `reservations.notes` JSONB hoặc `audit_events.payload` JSONB. |
| Cost per channel (FB Ads, TikTok Ads…) | ❌ Không có bảng `marketing_costs(channel, period, amount)`. |
| CPA (cost per acquisition) | ⚠️ Phải dẫn xuất runtime. |

**Thiếu:**
- Bảng `marketing_costs(branch_id, channel, period_start, period_end, amount)` — để biết chi phí quảng cáo.
- (Tùy chọn) `reservations.marketing_channel text` hoặc JSONB path chuẩn — để group revenue theo kênh.

### 2.9 Báo cáo CRM (ManagerCRMView)

| Yêu cầu | Schema? |
| --- | --- |
| Khách quen / VIP / tags | ✅ `customers(is_vip, tags JSONB)` |
| Số lần đến | ✅ đếm `reservations WHERE customer_id = X` |
| Lịch sử order | ✅ join `reservations → orders → invoices` |

### 2.10 Báo cáo tồn kho (ManagerInventoryView)

| Yêu cầu | Schema? |
| --- | --- |
| Tồn đầu / xuất bếp / tồn cuối | ✅ `inventory_items.quantity` (snapshot) + `inventory_txns(txn_type, quantity)` |
| Cảnh báo tồn thấp | ✅ partial index `(branch_id, quantity) WHERE is_active` + `inventory_items.min_quantity` |
| Xuất hóa đơn đỏ | ⚠️ `invoices.customer_snapshot.tax_code` JSONB, **không có cột `tax_code` có cấu trúc**. |
| Gửi dữ liệu Cục Thuế | ⚠️ Cần thêm bảng `tax_invoices(branch_id, invoice_id, xml_payload, sent_at, status)` hoặc `invoices.tax_serial text` cho hóa đơn điện tử VN. |

### 2.11 KPI / KGI (AdminKPIView) — **KHUYẾT THIẾT**

UI hiện tại là placeholder ("đang được phát triển"), nhưng tên bảng nghiệp vụ `kpi_targets` chưa có. Cần:
- `kpi_targets(id, branch_id NULLABLE for group-level, metric_key text, target_value numeric, period_start, period_end, scope text)` — lưu chỉ tiêu theo tháng/quý/năm.

### 2.12 Audit log (AdminAuditView) — **CÓ BẢNG, UI PLACEHOLDER**

UI là placeholder, nhưng `audit_events(id, branch_id, user_id, action, entity_type, entity_id, payload JSONB, ip_address, created_at)` đã sẵn sàng. Chỉ cần viết query.

---

## 3. Thiếu / cần bổ sung (theo thứ tự ưu tiên)

### 🔴 P0 — Block báo cáo cốt lõi

1. **`menu_items.cost numeric(12,2)`** — giá cost snapshot cho từng món (ManagerCOGSView phụ thuộc).
2. **Bảng `recipe_items` (recipe/BOM)** — `id, branch_id, menu_item_id, inventory_item_id, quantity numeric, unit text, created_at, unique(menu_item_id, inventory_item_id)`. Cho phép tính COGS đúng theo định lượng thực tế.
3. **Bảng `kpi_targets`** — lưu chỉ tiêu kinh doanh cho AdminKPIView.
4. **`payments.shift_id uuid REFERENCES shifts(id) ON DELETE SET NULL`** — quan trọng cho ReceptionCloseShiftView (doanh thu trong ca) và tránh join phức tạp.
5. **`invoices.tax_code text`** — cột có cấu trúc (không chỉ trong JSONB) để lập hóa đơn đỏ VN, validate MST, index lookup.
6. **`orders.vat_rate default 0.08`** — nhà hàng ăn uống VN chịu VAT 8%, không phải 10%. Hoặc đổi thành `numeric(5,4) not null default 0.08`.

### 🟡 P1 — Cải thiện độ chính xác báo cáo

7. **`reservations.marketing_channel text`** (hoặc định nghĩa JSONB path chuẩn trong `notes`) — để báo cáo ManagerMarketingView.
8. **Bảng `marketing_costs(branch_id, channel, period_start, period_end, amount, metadata JSONB)`** — chi phí quảng cáo.
9. **`payments.revenue_type text`** (hoặc định nghĩa JSONB path chuẩn trong `metadata`) — để báo cáo ManagerRevenueView nhóm doanh thu theo Dinner/Lunch/Wine/Delivery.
10. **`menu_items.is_package boolean`** + bảng `packages` — để hỗ trợ "Set Biz 1200k" / "Premium Buffet 1380k" / "Drink A" như TabletOrderView đang hiển thị. Hiện tại menu_items chỉ là món lẻ, không có khái niệm gói/combo.
11. **`orders.table_id uuid REFERENCES tables(id) ON DELETE SET NULL`** — link trực tiếp order ↔ table, tránh phải join 4 bảng khi đếm món trên bàn.

### 🟢 P2 — Voucher & loyalty

12. **Bảng `vouchers(id, branch_id, code unique, type, value, valid_from, valid_until, max_uses, used_count, status)`** + `voucher_redemptions(voucher_id, invoice_id, used_at)`.
13. **`customers.loyalty_points int default 0`** + `loyalty_txns(customer_id, delta, reason, ref_invoice_id)` — nếu muốn tích điểm.

### 🔵 P3 — Hóa đơn điện tử VN (e-invoice)

14. **Bảng `tax_invoices(id, branch_id, invoice_id, serial text, number text, xml_payload text, sent_at, status, cuc_thue_status text)`** — cho phép gửi lên Cục Thuế theo Nghị định 123/2020.

---

## 4. Khuyến nghị cấu trúc

### 4.1 Bổ sung ngay (ít xâm lấn)

```sql
-- (P0.1) Giá cost món
alter table public.menu_items
  add column if not exists cost numeric(12,2) not null default 0 check (cost >= 0);

-- (P0.6) VAT 8% cho nhà hàng
alter table public.orders
  alter column vat_rate set default 0.0800;

-- (P0.5) Tax code có cấu trúc trên invoices
alter table public.invoices
  add column if not exists tax_code text,
  add column if not exists customer_company text,
  add column if not exists customer_address text;
create index if not exists invoices_tax_code_idx on public.invoices (branch_id, tax_code);

-- (P0.4) Shift link trên payments
alter table public.payments
  add column if not exists shift_id uuid references public.shifts(id) on delete set null;
create index if not exists payments_shift_idx on public.payments (branch_id, shift_id);
```

### 4.2 Bảng mới (P0)

```sql
-- (P0.2) Recipe / BOM — định lượng nguyên liệu cho từng món
create table public.recipe_items (
  id                uuid primary key default uuid_generate_v4(),
  branch_id         uuid not null references public.branches(id) on delete cascade,
  menu_item_id      uuid not null references public.menu_items(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity          numeric(12,4) not null check (quantity > 0),
  unit              text not null,                       -- 'kg', 'chai'
  metadata          jsonb not null default '{}'::jsonb,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (menu_item_id, inventory_item_id)
);
create index recipe_items_menu_idx    on public.recipe_items (menu_item_id);
create index recipe_items_inventory_idx on public.recipe_items (inventory_item_id);

-- (P0.3) KPI / KGI targets
create table public.kpi_targets (
  id           uuid primary key default uuid_generate_v4(),
  branch_id    uuid references public.branches(id) on delete cascade,  -- NULL = group-level
  metric_key   text not null,                   -- 'revenue', 'guests', 'cogs_ratio', 'reservation_fill'
  target_value numeric(14,2) not null,
  period_start date not null,
  period_end   date not null,
  scope        text not null default 'branch',  -- 'branch' | 'group'
  notes        jsonb not null default '{}'::jsonb,
  created_by   uuid references public.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (branch_id, metric_key, period_start)
);
create index kpi_targets_period_idx on public.kpi_targets (period_start, period_end);
```

### 4.3 Bảng mới (P1)

```sql
-- Marketing cost theo kênh theo kỳ
create table public.marketing_costs (
  id           uuid primary key default uuid_generate_v4(),
  branch_id    uuid not null references public.branches(id) on delete cascade,
  channel      text not null,                   -- 'facebook', 'tiktok', 'google', 'zalo', 'other'
  period_start date not null,
  period_end   date not null,
  amount       numeric(14,2) not null check (amount >= 0),
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  unique (branch_id, channel, period_start)
);
create index marketing_costs_branch_period_idx
  on public.marketing_costs (branch_id, period_start, period_end);
```

---

## 5. RLS / Auth / Realtime — chưa hoàn thiện

- ✅ RLS đã bật trên 19/19 bảng operational.
- ❌ Chỉ có 1 policy mẫu (cho `branches`). Cần viết policy per role per table.
- ❌ Realtime publication chưa được add table nào (chỉ có comment). Cho UX realtime:
  - reservations (ReceptionDashboard cập nhật live)
  - tables (StaffFloorPlan cập nhật trạng thái bàn)
  - orders + order_items (bếp thấy order mới)
  - table_assignments (nhân viên thấy bàn vừa được gán)
- ❌ Trigger `handle_new_auth_user()` đang trong comment, chưa active. Sau khi enable Supabase Auth, cần bật để mirror `auth.users → public.users`.

---

## 6. Kết luận

**Schema hiện tại bao quát ~80% chức năng POS trong scope.**

- ✅ Reservation + table assignment + ordering + split-payment + shift + audit: **đầy đủ, đúng pattern.**
- ⚠️ Báo cáo doanh thu & inventory: **chạy được nhưng còn dùng JSONB lỏng** cho revenue_type, marketing_channel — chấp nhận được giai đoạn đầu nhưng cần chuẩn hóa.
- ❌ COGS / KPI / Voucher / Marketing cost: **thiếu bảng**, các view hiện tại (ManagerCOGSView, AdminKPIView) sẽ không thực sự chạy được khi wire data — vẫn đang là mock.

**Khuyến nghị:** Trước khi code backend, bổ sung theo thứ tự P0 ở mục 3. Đặc biệt:
1. `menu_items.cost` (1 dòng ALTER).
2. `payments.shift_id` (1 FK + 1 index).
3. Bảng `recipe_items` (BOM).
4. Bảng `kpi_targets`.
5. `orders.vat_rate default 0.08`.
6. `invoices.tax_code text`.

Tổng cộng ~6 thay đổi nhỏ, không phá vỡ multi-tenant hay JSONB pattern hiện tại. Có thể ship thêm trong cùng migration `0002_pos_p0_additions.sql`.