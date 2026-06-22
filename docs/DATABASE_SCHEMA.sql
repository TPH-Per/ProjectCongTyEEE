-- =============================================================================
-- NGƯU CÁT — Restaurant POS Database Schema
-- Target: PostgreSQL 15+ (Supabase Pro, $25/mo)
-- Scope:  POS for NguuCat branches (order · payment · table mgmt · basic reports)
-- Version: 1.0 (2026-06-22)
-- =============================================================================
--
-- DESIGN CRITERIA (the ONLY rule that matters)
-- --------------------------------------------
-- Every table is EITHER a HIGH-consistency table (FK-enforced relational)
-- OR a LOW-consistency table (stored as a table, but with NO foreign keys —
-- behaving like a NoSQL document collection you can still SELECT / JOIN).
--
--   HIGH-consistency tables   — money, identity, booking graph, the core chain
--                               order → invoice → payment, reservation → table.
--                               Foreign keys + CHECKs + UNIQUE constraints
--                               are MANDATORY.  Wrong data = lost money.
--
--   LOW-consistency tables    — event/fact streams, settings, notifications,
--                               audit, anything that should survive deletion
--                               of related entities.  NO foreign keys at all
--                               (only branch_id as a plain uuid for tenancy).
--                               Wrong data = missing log, not lost money.
--
-- MULTI-TENANCY
-- -------------
-- Every table carries `branch_id` so a single Supabase project can host many
-- branches and RLS can scope by branch.  RLS policies use the helper
-- `public.current_branch_id()` rather than subqueries in every policy.
--
-- MONEY
-- -----
-- All monetary columns are `numeric(14,2)` — NEVER `float`.  Subtotal/VAT/total
-- are STORED (not just computed) so reconciliation reports match the receipt.
-- Every amount > 0 has a CHECK constraint.
--
-- HOW TO ADD A NEW FEATURE
-- ------------------------
--   * Needs referential integrity?  → new HIGH-consistency table with FKs.
--   * Needs flexible per-row data?  → JSONB column on an existing table.
--   * Needs an audit/event trail?    → write a row to `audit_events`.
--   * Needs a notification?          → write a row to `notifications`.
--   * Needs a per-branch config?     → write a row to `branch_settings`.
--   * Needs a per-row state on a HIGH table? → JSONB column on that table.
--
-- =============================================================================

-- =============================================================================
-- 0. Extensions
-- =============================================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- =============================================================================
-- 1. ENUM Types
-- =============================================================================
create type user_role         as enum ('admin', 'manager', 'reception', 'staff', 'kitchen');
create type table_status      as enum ('available', 'reserved', 'occupied', 'maintenance');
create type reservation_status as enum ('Pending', 'Arrived', 'Dining', 'Completed', 'Cancelled');
create type order_status      as enum ('Pending', 'Preparing', 'Served', 'Paid', 'Cancelled');
create type invoice_status    as enum ('draft', 'issued', 'paid', 'cancelled', 'refunded');
create type payment_method    as enum ('cash', 'card', 'transfer', 'voucher', 'other');
create type shift_status      as enum ('open', 'closed');
create type package_type      as enum ('buffet', 'set', 'drink', 'other');
create type revenue_type      as enum ('lunch', 'dinner', 'wine', 'delivery', 'other');
create type voucher_type      as enum ('percent', 'amount');

-- =============================================================================
-- 2. Helper functions for RLS
-- =============================================================================
-- These make every RLS policy a one-liner:
--   using (branch_id = public.current_branch_id())
-- -----------------------------------------------------------------------

create or replace function public.current_user_id()
returns uuid language sql stable security definer set search_path = public, auth as $$
  select auth.uid()
$$;

create or replace function public.current_branch_id()
returns uuid language sql stable security definer set search_path = public, auth as $$
  select branch_id from public.users where id = auth.uid()
$$;

create or replace function public.has_role(roles user_role[])
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and role = any(roles)
  )
$$;

-- =============================================================================
-- 3. HIGH-consistency tables (FK-enforced)
-- =============================================================================
-- These form the core POS data graph.  CASCADE / RESTRICT are chosen carefully:
--   * branches → CASCADE on users/zones/tables  (a deleted branch takes its data)
--   * customers → RESTRICT on reservations/orders (can't lose history of guests)
--   * menu_items → RESTRICT on order_items      (can't break historical orders)
--   * orders → CASCADE on order_items, RESTRICT on invoice (must issue invoice
--                                                      before deleting order)
-- =============================================================================

-- 3.1 BRANCHES -----------------------------------------------------------------
create table public.branches (
  id          uuid primary key default uuid_generate_v4(),
  code        text not null unique,                 -- 'B001'
  name        text not null,                        -- 'Ngưu Cát Quận 1'
  address     text,
  phone       text,
  timezone    text not null default 'Asia/Ho_Chi_Minh',
  currency    text not null default 'VND',
  vat_rate    numeric(5,4) not null default 0.08,   -- VN F&B is 8% (corrected from 0.10)
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 3.2 USERS --------------------------------------------------------------------
-- Mirrors auth.users; one row per staff account.
create table public.users (
  id           uuid primary key references auth.users(id) on delete cascade,
  branch_id    uuid references public.branches(id) on delete set null,
  full_name    text not null,
  email        text not null unique,
  phone        text,
  role         user_role not null default 'staff',
  is_active    boolean not null default true,
  preferences  jsonb not null default '{}'::jsonb,  -- {theme, lang, notif toggles}
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index users_branch_idx on public.users (branch_id);

-- 3.3 ZONES --------------------------------------------------------------------
create table public.zones (
  id          uuid primary key default uuid_generate_v4(),
  branch_id   uuid not null references public.branches(id) on delete cascade,
  name        text not null,                        -- 'Khu VIP', 'Sân vườn'
  color       text,
  sort_order  int not null default 0,
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,   -- flexible zone config
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index zones_branch_idx on public.zones (branch_id);

-- 3.4 TABLES -------------------------------------------------------------------
create table public.tables (
  id          uuid primary key default uuid_generate_v4(),
  branch_id   uuid not null references public.branches(id) on delete cascade,
  zone_id     uuid not null references public.zones(id) on delete restrict,
  code        text not null,                        -- 'A01', 'VIP02'
  capacity    int not null check (capacity > 0),
  shape       text check (shape in ('round','square','rectangle')),
  pos_x       numeric(10,2) not null default 0,
  pos_y       numeric(10,2) not null default 0,
  status      table_status not null default 'available',
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,   -- {qr_token, table_label, notes}
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (branch_id, code)
);
create index tables_branch_zone_idx on public.tables (branch_id, zone_id);

-- 3.5 CUSTOMERS ----------------------------------------------------------------
create table public.customers (
  id             uuid primary key default uuid_generate_v4(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  name           text not null,
  phone          text,
  email          text,
  total_visits   int not null default 0,
  total_spent    numeric(14,2) not null default 0,
  last_visit_at  timestamptz,
  is_vip         boolean not null default false,
  -- JSONB-friendly fields (low consistency but kept inline for query speed)
  tags           jsonb not null default '[]'::jsonb,  -- ['VIP','allergies-seafood']
  preferences    jsonb not null default '{}'::jsonb,  -- {table:'window', lang:'ja'}
  -- Demographics: captured by staff when opening a table.
  -- Query examples:
  --   gender breakdown:    select metadata->>'gender' as g, count(*) from customers group by 1
  --   age distribution:    select metadata->>'age_bucket' as a, count(*) from customers group by 1
  --   nationality:         select metadata->>'nationality' as n, count(*) from customers group by 1
  demographics   jsonb not null default '{}'::jsonb,  -- {gender, age_bucket, nationality}
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index customers_branch_phone_idx on public.customers (branch_id, phone);
create index customers_branch_email_idx on public.customers (branch_id, email);
create index customers_vip_idx          on public.customers (branch_id) where is_vip;
create index customers_tags_gin         on public.customers using gin (tags);

-- 3.6 MENU_CATEGORIES ----------------------------------------------------------
create table public.menu_categories (
  id          uuid primary key default uuid_generate_v4(),
  branch_id   uuid not null references public.branches(id) on delete cascade,
  name        text not null,                        -- 'Buffet', 'Set Lunch'
  sort_order  int not null default 0,
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index menu_categories_branch_idx on public.menu_categories (branch_id);

-- 3.7 MENU_ITEMS ---------------------------------------------------------------
-- PRICE = selling price (used by order_items snapshot).
-- COST  = raw-material cost for COGS / margin reporting (ManagerCOGSView).
-- Both are HIGH-consistency numbers because they feed financial reports.
-- cost is nullable because not every item has a tracked cost.
create table public.menu_items (
  id           uuid primary key default uuid_generate_v4(),
  branch_id    uuid not null references public.branches(id) on delete cascade,
  category_id  uuid not null references public.menu_categories(id) on delete restrict,
  name         text not null,
  description  text,
  price        numeric(12,2) not null check (price >= 0),
  cost         numeric(12,2) check (cost is null or cost >= 0),  -- ADDED P0.1
  unit         text not null default 'Phần',
  image_url    text,
  is_available boolean not null default true,
  -- JSONB-friendly fields
  modifiers    jsonb not null default '[]'::jsonb,  -- [{name, options:[{label,price_delta}]}]
  tags         jsonb not null default '[]'::jsonb,  -- ['spicy','jp-import']
  nutrition    jsonb not null default '{}'::jsonb,  -- {calories, allergens:[]}
  metadata     jsonb not null default '{}'::jsonb,  -- {vip_only, package_filter_hint}
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index menu_items_branch_cat_idx on public.menu_items (branch_id, category_id) where is_available;
create index menu_items_modifiers_gin  on public.menu_items using gin (modifiers);
create index menu_items_tags_gin       on public.menu_items using gin (tags);

-- 3.7b PACKAGES (Set Biz 1200k, Buffet Wagyu 1380k, Drink A) -------------------
-- Packages (buffet/set/drink) are first-class entities — NOT just menu_items
-- because they carry:
--   * item_limit     (e.g. "3/10 món" per table)
--   * duration_minutes (buffet time window)
--   * their own price independent of included items
-- Items belonging to a package live in `package_items` (M:N).
create table public.packages (
  id               uuid primary key default uuid_generate_v4(),
  branch_id        uuid not null references public.branches(id) on delete cascade,
  name             text not null,                    -- 'Set Biz 1200k'
  type             package_type not null,            -- buffet | set | drink | other
  price            numeric(12,2) not null check (price >= 0),
  item_limit       int check (item_limit is null or item_limit > 0),
  duration_minutes int check (duration_minutes is null or duration_minutes > 0),
  image_url        text,
  is_active        boolean not null default true,
  metadata         jsonb not null default '{}'::jsonb, -- {flow_mode:'one_way'|'free', notes}
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index packages_branch_type_idx on public.packages (branch_id, type) where is_active;

create table public.package_items (
  package_id   uuid not null references public.packages(id) on delete cascade,
  menu_item_id uuid not null references public.menu_items(id) on delete restrict,
  sort_order   int not null default 0,
  -- Snapshot of the per-item price for accounting; the price in menu_items
  -- may change but package_items keeps the value at the moment the package
  -- was created / the item was added.
  unit_price   numeric(12,2) check (unit_price is null or unit_price >= 0),
  is_included  boolean not null default true,        -- false = paid add-on
  created_at   timestamptz not null default now(),
  primary key (package_id, menu_item_id)
);
create index package_items_menu_idx on public.package_items (menu_item_id);

-- 3.8 RESERVATIONS -------------------------------------------------------------
-- The booking is the entry point to POS flow (you can only order for a seated
-- reservation).  customer_snapshot freezes name/phone at booking time.
create table public.reservations (
  id               uuid primary key default uuid_generate_v4(),
  branch_id        uuid not null references public.branches(id) on delete cascade,
  customer_id      uuid not null references public.customers(id) on delete restrict,
  booking_code     text not null,                    -- 'SF_00001729'
  reservation_date date not null,
  reservation_time time not null,
  guests           int not null check (guests > 0),
  status           reservation_status not null default 'Pending',
  source           text,                             -- 'Hotline', 'App', 'Walk-in'
  type             text,                             -- 'Gia đình', 'Tiệc đôi'
  -- SNAPSHOT (denormalized on write) — survives later customer changes
  customer_snapshot jsonb not null default '{}'::jsonb,  -- {name, phone, email}
  -- JSONB-friendly fields
  notes            jsonb not null default '{}'::jsonb,    -- {internal, request, allergies}
  occasion         text,
  decorations      jsonb not null default '{}'::jsonb,    -- {flowers, cake, banner}
  transport        text,
  children_count   int not null default 0,
  expected_end     time,
  metadata         jsonb not null default '{}'::jsonb,
  -- Audit timestamps per status
  created_by       uuid references public.users(id) on delete set null,
  arrived_at       timestamptz,
  seated_at        timestamptz,
  completed_at     timestamptz,
  cancelled_at     timestamptz,
  cancel_reason    text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (branch_id, booking_code)
);
create index reservations_branch_date_idx   on public.reservations (branch_id, reservation_date);
create index reservations_branch_status_idx on public.reservations (branch_id, status);
create index reservations_customer_idx      on public.reservations (customer_id);

-- 3.9 TABLE_ASSIGNMENTS --------------------------------------------------------
-- Which tables are currently seating which reservation/order.
-- `released_at IS NULL` = "this table is taken right now".
-- metadata carries the package + flow mode + staff notes (kept in JSONB
-- because each seating is one-of-a-kind and not aggregated).
create table public.table_assignments (
  id             uuid primary key default uuid_generate_v4(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  reservation_id uuid references public.reservations(id) on delete cascade,  -- nullable for walk-in
  table_id       uuid not null references public.tables(id) on delete restrict,
  assigned_at    timestamptz not null default now(),
  released_at    timestamptz,
  assigned_by    uuid references public.users(id) on delete set null,
  -- Seating context (LOW consistency, but typed for fast filtering):
  -- {package_id, package_name_snapshot, party_size, demographics_capture,
  --  flow_mode:'one_way'|'free', guest_profile:{m,f,children,age_bucket}}
  -- Tablet order "3/10 món" reads from this row to know the limit + flow.
  metadata       jsonb not null default '{}'::jsonb,
  unique (reservation_id, table_id)
);
create index table_assignments_open_idx        on public.table_assignments (table_id) where released_at is null;
create index table_assignments_reservation_idx on public.table_assignments (reservation_id);
create index table_assignments_branch_meta_gin on public.table_assignments using gin (metadata);

-- 3.10 ORDERS ------------------------------------------------------------------
-- One reservation (or one walk-in) can have many orders (separate courses,
-- split bills).  All money math starts here.
-- table_id is denormalized for hot-path Tablet queries ("3/10 món this table")
-- — it is OPTIONAL because orders may exist before seating (e.g. pre-order).
create table public.orders (
  id              uuid primary key default uuid_generate_v4(),
  branch_id       uuid not null references public.branches(id) on delete cascade,
  reservation_id  uuid references public.reservations(id) on delete set null,
  table_id        uuid references public.tables(id) on delete set null,   -- ADDED P0.5
  customer_id     uuid references public.customers(id) on delete set null,
  order_number    text not null,
  status          order_status not null default 'Pending',
  -- Money columns (all stored, not just computed)
  subtotal        numeric(14,2) not null default 0 check (subtotal >= 0),
  vat_rate        numeric(5,4)  not null default 0.08,                       -- CHANGED P0.2 (was 0.10)
  vat             numeric(14,2) not null default 0 check (vat >= 0),
  discount        numeric(14,2) not null default 0 check (discount >= 0),
  total           numeric(14,2) not null default 0 check (total >= 0),
  notes           jsonb not null default '{}'::jsonb,
  created_by      uuid references public.users(id) on delete set null,
  served_by       uuid references public.users(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (branch_id, order_number)
);
create index orders_branch_idx      on public.orders (branch_id, created_at desc);
create index orders_reservation_idx on public.orders (reservation_id);
create index orders_table_idx       on public.orders (table_id) where status not in ('Paid','Cancelled');
create index orders_status_idx      on public.orders (branch_id, status);

-- 3.11 ORDER_ITEMS -------------------------------------------------------------
-- name_snapshot + unit_price freeze the menu item at order time.
-- unit_cost freezes the COGS-side number at order time too.
-- modifiers is the actual choice the customer made (each row has different shape).
create table public.order_items (
  id             uuid primary key default uuid_generate_v4(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  order_id       uuid not null references public.orders(id) on delete cascade,
  menu_item_id   uuid not null references public.menu_items(id) on delete restrict,
  name_snapshot  text not null,
  unit_price     numeric(12,2) not null check (unit_price >= 0),
  unit_cost      numeric(12,2) check (unit_cost is null or unit_cost >= 0),  -- ADDED P0 (COGS snapshot)
  quantity       numeric(10,2) not null check (quantity > 0),
  line_total     numeric(14,2) not null check (line_total >= 0),
  status         order_status not null default 'Pending',
  -- JSONB-friendly fields
  modifiers      jsonb not null default '[]'::jsonb,    -- chosen add-ons
  note           text,                                    -- 'rare', 'extra spicy'
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index order_items_order_idx     on public.order_items (order_id);
create index order_items_menu_idx      on public.order_items (menu_item_id);
create index order_items_modifiers_gin on public.order_items using gin (modifiers);

-- 3.12 INVOICES ----------------------------------------------------------------
-- 1:1 with orders.  customer_snapshot for printed receipts.
-- tax_code + customer_company + customer_address are typed columns for VN
-- "hóa đơn đỏ" — required by Nghị định 123/2020, must be indexable and
-- validatable as a 10/13-digit MST.
create table public.invoices (
  id                uuid primary key default uuid_generate_v4(),
  branch_id         uuid not null references public.branches(id) on delete cascade,
  order_id          uuid not null references public.orders(id) on delete restrict,
  invoice_number    text not null,
  status            invoice_status not null default 'draft',
  subtotal          numeric(14,2) not null default 0,
  vat               numeric(14,2) not null default 0,
  discount          numeric(14,2) not null default 0,
  total             numeric(14,2) not null default 0,
  -- ADDED P0.3 — typed fields for VN red-invoice (must be indexable / validatable)
  tax_code          text,                                -- MST 10/13 digits
  customer_company  text,                                -- legal company name on the invoice
  customer_address  text,
  customer_snapshot jsonb not null default '{}'::jsonb,  -- {name, phone, email, tax_code, ...}
  notes             jsonb not null default '{}'::jsonb,
  metadata          jsonb not null default '{}'::jsonb,  -- {serial, template, xml_url, cuc_thue_status}
  issued_at         timestamptz,
  issued_by         uuid references public.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (branch_id, invoice_number)
);
create index invoices_branch_idx  on public.invoices (branch_id, created_at desc);
create index invoices_order_idx   on public.invoices (order_id);
create index invoices_status_idx  on public.invoices (branch_id, status);
create index invoices_tax_code_idx on public.invoices (branch_id, tax_code) where tax_code is not null;

-- 3.13 PAYMENTS ----------------------------------------------------------------
-- Many-to-one with invoices: split payments supported (e.g. half cash, half card).
-- shift_id: link to the cashier shift envelope — required for ReceptionCloseShift
-- to sum revenue by shift without a brittle created_at BETWEEN join.
-- revenue_type: typed column for the "dinner/lunch/wine/delivery" report.
create table public.payments (
  id               uuid primary key default uuid_generate_v4(),
  branch_id        uuid not null references public.branches(id) on delete cascade,
  invoice_id       uuid not null references public.invoices(id) on delete restrict,
  shift_id         uuid references public.shifts(id) on delete set null,  -- ADDED P0.4
  method           payment_method not null,
  revenue_type     revenue_type not null default 'other',                 -- ADDED P0.4
  amount           numeric(14,2) not null check (amount > 0),
  received_amount  numeric(14,2),
  change_amount    numeric(14,2) default 0,
  reference        text,                                -- card last4, transfer ref
  metadata         jsonb not null default '{}'::jsonb,  -- gateway response, voucher_code, …
  paid_at          timestamptz not null default now(),
  received_by      uuid references public.users(id) on delete set null,
  created_at       timestamptz not null default now()
);
create index payments_invoice_idx on public.payments (invoice_id);
create index payments_branch_idx  on public.payments (branch_id, paid_at desc);
create index payments_shift_idx   on public.payments (branch_id, shift_id);
create index payments_revenue_idx on public.payments (branch_id, revenue_type, paid_at desc);

-- 3.14 VOUCHERS ----------------------------------------------------------------
-- A voucher is a first-class HIGH entity because misuse = lost money:
-- code is unique per branch, valid_until is enforced, max_uses limits abuse.
create table public.vouchers (
  id          uuid primary key default uuid_generate_v4(),
  branch_id   uuid not null references public.branches(id) on delete cascade,
  code        text not null,                          -- 'TET2026', printed/scanned
  type        voucher_type not null,                  -- percent | amount
  value       numeric(12,2) not null check (value > 0),  -- 10 (% off) or 50000 (VND off)
  valid_from  date,
  valid_until date,
  max_uses    int check (max_uses is null or max_uses > 0),
  used_count  int not null default 0 check (used_count >= 0),
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,    -- {min_order, applicable_categories, notes}
  created_by  uuid references public.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (branch_id, code)
);
create index vouchers_branch_active_idx on public.vouchers (branch_id) where is_active;

-- 3.15 VOUCHER_REDEMPTIONS -----------------------------------------------------
-- One row per invoice that used a voucher.  Audit trail of who redeemed what.
create table public.voucher_redemptions (
  id           uuid primary key default uuid_generate_v4(),
  branch_id    uuid not null references public.branches(id) on delete cascade,
  voucher_id   uuid not null references public.vouchers(id) on delete restrict,
  invoice_id   uuid not null references public.invoices(id) on delete restrict,
  discount_amount numeric(14,2) not null check (discount_amount > 0),
  redeemed_at  timestamptz not null default now(),
  redeemed_by  uuid references public.users(id) on delete set null,
  unique (voucher_id, invoice_id)
);
create index voucher_redemptions_invoice_idx on public.voucher_redemptions (invoice_id);
create index voucher_redemptions_branch_idx  on public.voucher_redemptions (branch_id, redeemed_at desc);

-- 3.16 DEPOSITS ----------------------------------------------------------------
-- Money taken at booking time (VIP reservations).  Not yet an invoice.
create table public.deposits (
  id             uuid primary key default uuid_generate_v4(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  amount         numeric(14,2) not null check (amount > 0),
  method         payment_method not null,
  received_by    uuid references public.users(id) on delete set null,
  reference      text,
  received_at    timestamptz not null default now(),
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);
create index deposits_reservation_idx on public.deposits (reservation_id);
create index deposits_branch_idx      on public.deposits (branch_id, received_at desc);

-- 3.17 SHIFTS ------------------------------------------------------------------
-- Cashier shift envelope: opening cash → closing reconciliation.
create table public.shifts (
  id              uuid primary key default uuid_generate_v4(),
  branch_id       uuid not null references public.branches(id) on delete cascade,
  user_id         uuid not null references public.users(id) on delete restrict,
  status          shift_status not null default 'open',
  opened_at       timestamptz not null default now(),
  closed_at       timestamptz,
  opening_cash    numeric(14,2) not null default 0,
  closing_cash    numeric(14,2),
  expected_cash   numeric(14,2),
  cash_difference numeric(14,2),
  notes           jsonb not null default '{}'::jsonb,    -- {handover_notes, incidents, …}
  metadata        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index shifts_branch_user_idx on public.shifts (branch_id, user_id, opened_at desc);
create index shifts_status_idx      on public.shifts (branch_id, status);

-- 3.18 KPI_TARGETS -------------------------------------------------------------
-- AdminKPIView configures targets per metric per period.  NULL branch_id
-- means group-wide target; specific branch_id overrides.
create table public.kpi_targets (
  id            uuid primary key default uuid_generate_v4(),
  branch_id     uuid references public.branches(id) on delete cascade,  -- NULL = group
  metric_key    text not null,                       -- 'revenue' | 'guests' | 'cogs_ratio' | 'reservation_fill' | 'avg_check'
  target_value  numeric(14,2) not null,
  period_start  date not null,
  period_end    date not null,
  scope         text not null default 'branch' check (scope in ('branch','group')),
  notes         jsonb not null default '{}'::jsonb,
  created_by    uuid references public.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (branch_id, metric_key, period_start),
  check (period_end >= period_start)
);
create index kpi_targets_period_idx on public.kpi_targets (period_start, period_end);
create index kpi_targets_branch_idx  on public.kpi_targets (branch_id, metric_key);

-- 3.19 MARKETING_COSTS ---------------------------------------------------------
-- Per-channel ad spend ledger.  Combined with revenue (or reservation count)
-- captured in audit_events.payload, this drives CPA & ROI.
create table public.marketing_costs (
  id            uuid primary key default uuid_generate_v4(),
  branch_id     uuid not null references public.branches(id) on delete cascade,
  channel       text not null,                       -- 'facebook' | 'tiktok' | 'google' | 'zalo' | 'other'
  period_start  date not null,
  period_end    date not null,
  amount        numeric(14,2) not null check (amount >= 0),
  notes         text,
  metadata      jsonb not null default '{}'::jsonb,   -- {campaign_code, vendor, invoice_url}
  created_by    uuid references public.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (branch_id, channel, period_start),
  check (period_end >= period_start)
);
create index marketing_costs_branch_period_idx
  on public.marketing_costs (branch_id, period_start, period_end);
create index marketing_costs_channel_idx
  on public.marketing_costs (branch_id, channel, period_start desc);


-- =============================================================================
-- 4. LOW-consistency tables  (NO foreign keys — NoSQL-style flexible tables)
-- =============================================================================
-- These are append-only event/fact stores.  You can SELECT / aggregate / even
-- JOIN, but the database will NOT block writes when related entities disappear
-- — which is what we want for audit trails and notifications.
--
-- branch_id is kept as a plain uuid (NOT an FK) so:
--   * we can record events before the branch_id is "verified" by a join
--   * if a branch is soft-deleted, history still queries
--   * writes are faster (no FK check)
-- Multi-tenancy is enforced by RLS only.
-- =============================================================================

-- 4.1 AUDIT_EVENTS -------------------------------------------------------------
-- Generic audit trail.  Every mutation appends a row here.
-- payload JSONB lets us record the exact diff without bloating the schema.
-- actor_id, entity_id, reservation_id, order_id, invoice_id are PLAIN UUIDs
-- (no FK) — audit must survive deletion of related entities.
create table public.audit_events (
  id             uuid primary key default uuid_generate_v4(),
  branch_id      uuid not null,
  actor_id       uuid,                                -- plain uuid, no FK
  action         text not null,                       -- 'reservation.created', 'table.assigned', 'table.checkout_requested', 'customer.crm_captured'
  entity_type    text,                                -- 'reservation'|'order'|'invoice'|'table'|'user'|'voucher'
  entity_id      uuid,                                -- plain uuid, no FK
  reservation_id uuid,                                -- context shortcut, no FK
  order_id       uuid,                                -- context shortcut, no FK
  invoice_id     uuid,                                -- context shortcut, no FK
  payload        jsonb not null default '{}'::jsonb,  -- {from, to, fields_changed, marketing_channel, media_consent, …}
  ip_address     inet,
  user_agent     text,
  created_at     timestamptz not null default now()
);
create index audit_events_branch_created_idx on public.audit_events (branch_id, created_at desc);
create index audit_events_actor_idx           on public.audit_events (actor_id, created_at desc);
create index audit_events_entity_idx          on public.audit_events (entity_type, entity_id);
create index audit_events_payload_gin         on public.audit_events using gin (payload);
-- Append-only: no updated_at (you don't update audit, you append a new event).

-- 4.2 NOTIFICATIONS ------------------------------------------------------------
-- Outgoing notifications.  variables JSONB drives the template engine.
-- No FKs — notification history should survive deletion of users/customers.
create table public.notifications (
  id            uuid primary key default uuid_generate_v4(),
  branch_id     uuid not null,
  channel       text not null,                        -- 'email'|'sms'|'push'|'zalo'
  recipient     text not null,                        -- email / phone / device id
  template      text not null,                        -- 'booking_confirmed', 'receipt', …
  variables     jsonb not null default '{}'::jsonb,   -- {name, time, table, total}
  status        text not null default 'pending',      -- 'pending'|'sent'|'failed'
  sent_at       timestamptz,
  error_message text,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);
create index notifications_branch_status_idx on public.notifications (branch_id, status);
create index notifications_pending_idx      on public.notifications (created_at) where status = 'pending';
-- Append-only.

-- 4.3 BRANCH_SETTINGS ----------------------------------------------------------
-- Per-branch key-value configuration.  Replaces scattered `branches.metadata`
-- so we can add new config keys without ever touching the branches row.
-- No FK to branches — value lives independently; a soft-deleted branch's
-- settings still query.
create table public.branch_settings (
  id          uuid primary key default uuid_generate_v4(),
  branch_id   uuid not null,
  key         text not null,                          -- 'operating_hours', 'tax_id', 'logo_url', 'default_locale', 'report_segments'
  value       jsonb not null,                         -- arbitrary JSON
  value_type  text not null default 'string',         -- 'string'|'number'|'boolean'|'json'|'array'
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (branch_id, key)
);
create index branch_settings_branch_idx on public.branch_settings (branch_id) where is_active;

-- 4.4 SYSTEM_EVENTS ------------------------------------------------------------
-- Generic catch-all event log (analytics, login attempts, errors, page views).
-- Distinct from audit_events: this is for the app, not for compliance.
create table public.system_events (
  id         uuid primary key default uuid_generate_v4(),
  branch_id  uuid,
  type       text not null,                            -- 'login','page_view','error','feature_used'
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index system_events_branch_created_idx on public.system_events (branch_id, created_at desc);
create index system_events_type_idx           on public.system_events (type, created_at desc);
create index system_events_payload_gin        on public.system_events using gin (payload);
-- Append-only.


-- =============================================================================
-- 5. updated_at trigger (HIGH tables only — LOW tables are append-only)
-- =============================================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end$$;

do $$
declare t text;
begin
  foreach t in array array[
    'branches','users','zones','tables','customers',
    'menu_categories','menu_items','packages',
    'reservations','orders','order_items','invoices',
    'vouchers','shifts','kpi_targets','marketing_costs',
    'branch_settings'
  ] loop
    execute format(
      'drop trigger if exists trg_set_updated_at on public.%I;
       create trigger trg_set_updated_at before update on public.%I
         for each row execute function public.set_updated_at();',
      t, t);
  end loop;
end$$;

-- =============================================================================
-- 6. RLS scaffold
-- =============================================================================
-- Every table has RLS enabled.  Use the helper `public.current_branch_id()`
-- to scope by branch in every policy.  Examples below; add per-role policies
-- as the feature requires.
-- -----------------------------------------------------------------------

-- HIGH-consistency tables
alter table public.branches          enable row level security;
alter table public.users             enable row level security;
alter table public.zones             enable row level security;
alter table public.tables            enable row level security;
alter table public.customers         enable row level security;
alter table public.menu_categories   enable row level security;
alter table public.menu_items        enable row level security;
alter table public.packages          enable row level security;
alter table public.package_items     enable row level security;
alter table public.reservations      enable row level security;
alter table public.table_assignments enable row level security;
alter table public.orders            enable row level security;
alter table public.order_items       enable row level security;
alter table public.invoices          enable row level security;
alter table public.payments          enable row level security;
alter table public.vouchers          enable row level security;
alter table public.voucher_redemptions enable row level security;
alter table public.deposits          enable row level security;
alter table public.shifts            enable row level security;
alter table public.kpi_targets       enable row level security;
alter table public.marketing_costs   enable row level security;

-- LOW-consistency tables
alter table public.audit_events      enable row level security;
alter table public.notifications     enable row level security;
alter table public.branch_settings   enable row level security;
alter table public.system_events     enable row level security;

-- ----- Example policies (replicate / adjust per role) -------------------------

-- Admin: full access everywhere
create policy "admin all on branches" on public.branches
  for all using (public.has_role(array['admin']::user_role[])) with check (public.has_role(array['admin']::user_role[]));

-- Manager: read all branches, full access to their own
create policy "manager read branches" on public.branches
  for select using (public.has_role(array['admin','manager']::user_role[]));

-- Staff: only their own branch
create policy "staff read own branch" on public.branches
  for select using (id = public.current_branch_id());

-- Reservations: scoped by branch
create policy "branch read reservations" on public.reservations
  for select using (branch_id = public.current_branch_id());
create policy "branch write reservations" on public.reservations
  for insert with check (branch_id = public.current_branch_id());
create policy "branch update reservations" on public.reservations
  for update using (branch_id = public.current_branch_id()) with check (branch_id = public.current_branch_id());

-- Orders / order_items / invoices / payments / deposits: same pattern as reservations
-- (replicate the three policies above for each of those tables)

-- Tables: branch-scoped
create policy "branch read tables" on public.tables
  for select using (branch_id = public.current_branch_id());
create policy "branch write tables" on public.tables
  for insert with check (branch_id = public.current_branch_id());
create policy "branch update tables" on public.tables
  for update using (branch_id = public.current_branch_id()) with check (branch_id = public.current_branch_id());

-- Packages: branch-scoped
create policy "branch read packages" on public.packages
  for select using (branch_id = public.current_branch_id());
create policy "branch write packages" on public.packages
  for insert with check (branch_id = public.current_branch_id());
create policy "branch update packages" on public.packages
  for update using (branch_id = public.current_branch_id()) with check (branch_id = public.current_branch_id());

-- Vouchers: branch-scoped, manager+ only for write
create policy "branch read vouchers" on public.vouchers
  for select using (branch_id = public.current_branch_id());
create policy "manager write vouchers" on public.vouchers
  for all using (public.has_role(array['admin','manager']::user_role[]) and branch_id = public.current_branch_id());

-- KPI targets: branch-scoped
create policy "branch read kpi" on public.kpi_targets
  for select using (branch_id is null or branch_id = public.current_branch_id());
create policy "admin write kpi" on public.kpi_targets
  for all using (public.has_role(array['admin','manager']::user_role[]));

-- Marketing costs: branch-scoped, manager+ only
create policy "branch read marketing" on public.marketing_costs
  for select using (branch_id = public.current_branch_id());
create policy "manager write marketing" on public.marketing_costs
  for all using (public.has_role(array['admin','manager']::user_role[]) and branch_id = public.current_branch_id());

-- LOW tables: branch-scoped read, anyone signed-in can write their branch
create policy "branch read audit" on public.audit_events
  for select using (branch_id = public.current_branch_id());
create policy "branch write audit" on public.audit_events
  for insert with check (branch_id = public.current_branch_id());

create policy "branch read notifications" on public.notifications
  for select using (branch_id = public.current_branch_id());
create policy "branch write notifications" on public.notifications
  for insert with check (branch_id = public.current_branch_id());

create policy "branch read settings" on public.branch_settings
  for select using (branch_id = public.current_branch_id());
create policy "manager write settings" on public.branch_settings
  for all using (public.has_role(array['admin','manager']::user_role[]));

create policy "branch read system_events" on public.system_events
  for select using (branch_id = public.current_branch_id());
create policy "branch write system_events" on public.system_events
  for insert with check (branch_id = public.current_branch_id());

-- =============================================================================
-- 7. Realtime publication (Supabase)
-- =============================================================================
-- Subscribe to volatile multi-user tables only.  Filter by branch_id on the
-- client to save connection slots.
--
-- alter publication supabase_realtime add table public.reservations;
-- alter publication supabase_realtime add table public.tables;
-- alter publication supabase_realtime add table public.table_assignments;
-- alter publication supabase_realtime add table public.orders;
-- alter publication supabase_realtime add table public.order_items;
-- alter publication supabase_realtime add table public.notifications;

-- =============================================================================
-- 8. Auth.users → public.users trigger (Supabase Auth integration)
-- =============================================================================
-- Mirrors every new auth.users row into public.users.  Adjust the default
-- role/branch as needed.
--
-- create or replace function public.handle_new_auth_user()
-- returns trigger language plpgsql security definer set search_path = public, auth as $$
-- begin
--   insert into public.users (id, email, full_name, role)
--   values (
--     new.id,
--     new.email,
--     coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
--     coalesce((new.raw_user_meta_data->>'role')::user_role, 'staff')
--   )
--   on conflict (id) do nothing;
--   return new;
-- end$$;
--
-- drop trigger if exists on_auth_user_created on auth.users;
-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute function public.handle_new_auth_user();
