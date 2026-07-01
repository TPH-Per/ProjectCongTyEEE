-- ==========================================
-- FILE: 20260623000000_setup.sql
-- ==========================================
-- ===================== BASE SCHEMA =====================
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
-- 2. CORE TABLES — branches + users
--    These MUST exist before the RLS helper functions (section 3) so that
--    current_branch_id() / has_role() / current_user_role() can reference them.
-- =============================================================================

-- 2.1 BRANCHES -----------------------------------------------------------------
create table public.branches (
  id          uuid primary key default gen_random_uuid(),
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

-- 2.2 USERS --------------------------------------------------------------------
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

-- =============================================================================
-- 3. Helper functions for RLS
--    Defined AFTER branches + users so the function bodies can reference them.
--    All functions are SECURITY DEFINER with a pinned search_path so a hostile
--    caller cannot poison the schema search order.  They also prefer the JWT
--    claim (set by Supabase auth middleware / custom-access-token hook) and
--    fall back to a DB lookup on public.users.
-- -----------------------------------------------------------------------

create or replace function public.current_user_id()
returns uuid language sql stable security definer set search_path = public, auth as $$
  select auth.uid()
$$;

create or replace function public.current_branch_id()
returns uuid language sql stable security definer set search_path = public, auth as $$
  -- Prefer JWT claim (set by Supabase auth middleware), fall back to DB lookup
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'branch_id',
    (select branch_id::text from public.users where id = auth.uid())
  )::uuid
$$;

create or replace function public.has_role(roles user_role[])
returns boolean language sql stable security definer set search_path = public, auth as $$
  select coalesce(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')::user_role = any(roles),
    exists (select 1 from public.users where id = auth.uid() and role = any(roles))
  )
$$;

create or replace function public.current_user_role()
returns user_role language sql stable security definer set search_path = public, auth as $$
  -- Whitelist the JWT `role` claim against the user_role enum before casting.
  -- PostgREST's anon/authenticator/authenticated roles are not in our enum,
  -- and a bare ::user_role cast on 'anon' raises 22P02 and breaks every
  -- anon request that touches an RLS-protected table.
  select coalesce(
    case
      when (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')
           in ('admin','manager','reception','staff','kitchen')
      then ((nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')::user_role)
    end,
    (select role from public.users where id = auth.uid())
  )
$$;

-- =============================================================================
-- 3.5 Auth integration — mirror auth.users → public.users
-- =============================================================================
-- When Supabase Auth creates an account (Dashboard, Admin API, signUp endpoint),
-- this trigger inserts a matching row in public.users.  The role / branch_id /
-- full_name are derived from auth.users.raw_user_meta_data:
--
--   raw_user_meta_data->>'role'      cast to user_role (whitelist, default 'staff')
--   raw_user_meta_data->>'branch_id' cast to uuid (NULL if missing/invalid)
--   raw_user_meta_data->>'full_name' default = local-part of email
--
-- SECURITY DEFINER so the trigger runs as the function owner and bypasses the
-- "users_self_read"/"users_admin_all" RLS policies on public.users.  search_path
-- is pinned to prevent schema-search-path attacks.
--
-- Once this trigger is in place, admin/manager/reception/staff accounts created
-- via Dashboard are automatically mirrored — no manual INSERT into public.users
-- required.  The UPDATE statements in section 11 will then take effect to assign
-- the correct role + branch_id for each seeded user.
-- -----------------------------------------------------------------------

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public, auth as $$
declare
  v_role      user_role;
  v_full_name text;
  v_branch_id uuid;
begin
  -- Whitelist the role to prevent enum cast errors if raw_user_meta_data
  -- contains an unexpected role string (e.g. from a misconfigured signup form).
  v_role := case new.raw_user_meta_data->>'role'
    when 'admin'     then 'admin'::user_role
    when 'manager'   then 'manager'::user_role
    when 'reception' then 'reception'::user_role
    when 'staff'     then 'staff'::user_role
    when 'kitchen'   then 'kitchen'::user_role
    else                  'staff'::user_role
  end;

  v_full_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    split_part(new.email, '@', 1)
  );

  -- Safely parse branch_id: NULL if missing, empty string, or not a valid UUID.
  begin
    v_branch_id := nullif(new.raw_user_meta_data->>'branch_id', '')::uuid;
  exception when invalid_text_representation then
    v_branch_id := null;
  end;

  insert into public.users (id, email, full_name, role, branch_id)
  values (new.id, new.email, v_full_name, v_role, v_branch_id)
  on conflict (id) do nothing;

  return new;
end$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- =============================================================================
-- 4. HIGH-consistency tables (FK-enforced)
--    Order matters for foreign-key targets: every table a later table references
--    must already exist.  Notable ordering constraint: `shifts` must be defined
--    BEFORE `payments` because `payments.shift_id` references `public.shifts(id)`.
-- =============================================================================

-- 4.1 ZONES --------------------------------------------------------------------
create table public.zones (
  id          uuid primary key default gen_random_uuid(),
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

-- 4.2 TABLES -------------------------------------------------------------------
create table public.tables (
  id          uuid primary key default gen_random_uuid(),
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

-- 4.3 CUSTOMERS ----------------------------------------------------------------
create table public.customers (
  id             uuid primary key default gen_random_uuid(),
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

-- 4.4 MENU_CATEGORIES ----------------------------------------------------------
create table public.menu_categories (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null references public.branches(id) on delete cascade,
  name        text not null,                        -- 'Buffet', 'Set Lunch'
  sort_order  int not null default 0,
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index menu_categories_branch_idx on public.menu_categories (branch_id);

-- 4.5 MENU_ITEMS ---------------------------------------------------------------
-- PRICE = selling price (used by order_items snapshot).
-- COST  = raw-material cost for COGS / margin reporting (ManagerCOGSView).
-- Both are HIGH-consistency numbers because they feed financial reports.
-- cost is nullable because not every item has a tracked cost.
create table public.menu_items (
  id           uuid primary key default gen_random_uuid(),
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

-- 4.6 PACKAGES (Set Biz 1200k, Buffet Wagyu 1380k, Drink A) -------------------
-- Packages (buffet/set/drink) are first-class entities — NOT just menu_items
-- because they carry:
--   * item_limit     (e.g. "3/10 món" per table)
--   * duration_minutes (buffet time window)
--   * their own price independent of included items
-- Items belonging to a package live in `package_items` (M:N).
create table public.packages (
  id               uuid primary key default gen_random_uuid(),
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
  id           uuid primary key default gen_random_uuid(),
  package_id   uuid not null references public.packages(id) on delete cascade,
  menu_item_id uuid not null references public.menu_items(id) on delete restrict,
  item_limit   int check (item_limit is null or item_limit > 0),
  sort_order   int not null default 0,
  is_active    boolean not null default true,
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (package_id, menu_item_id)
);
create index package_items_package_idx on public.package_items (package_id, sort_order) where is_active;
create index package_items_menu_item_idx on public.package_items (menu_item_id);

CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- (public.branches is already defined in section 2.1 above — the duplicate
-- `CREATE TABLE public.branches` block previously lived here but has been
-- removed to keep the migration idempotent. Keeping a single definition also
-- avoids the inconsistency between gen_random_uuid() (line 76) and the older
-- uuid_generate_v4() that the duplicate used.)

-- 4.7 SHIFTS ------------------------------------------------------------------
-- Cashier shift envelope: opening cash → closing reconciliation.
-- Defined BEFORE payments because payments.shift_id references this table.
create table public.shifts (
  id              uuid primary key default gen_random_uuid(),
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

-- 4.8 RESERVATIONS -------------------------------------------------------------
-- The booking is the entry point to POS flow (you can only order for a seated
-- reservation).  customer_snapshot freezes name/phone at booking time.
create table public.reservations (
  id               uuid primary key default gen_random_uuid(),
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

-- 4.9 TABLE_ASSIGNMENTS --------------------------------------------------------
-- Which tables are currently seating which reservation/order.
-- `released_at IS NULL` = "this table is taken right now".
-- metadata carries the package + flow mode + staff notes (kept in JSONB
-- because each seating is one-of-a-kind and not aggregated).
create table public.table_assignments (
  id             uuid primary key default gen_random_uuid(),
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

-- 4.10 ORDERS ------------------------------------------------------------------
-- One reservation (or one walk-in) can have many orders (separate courses,
-- split bills).  All money math starts here.
-- table_id is denormalized for hot-path Tablet queries ("3/10 món this table")
-- — it is OPTIONAL because orders may exist before seating (e.g. pre-order).
create table public.orders (
  id              uuid primary key default gen_random_uuid(),
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

-- 4.11 ORDER_ITEMS -------------------------------------------------------------
-- name_snapshot + unit_price freeze the menu item at order time.
-- unit_cost freezes the COGS-side number at order time too.
-- modifiers is the actual choice the customer made (each row has different shape).
create table public.order_items (
  id             uuid primary key default gen_random_uuid(),
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

-- 4.12 INVOICES ----------------------------------------------------------------
-- 1:1 with orders.  customer_snapshot for printed receipts.
-- tax_code + customer_company + customer_address are typed columns for VN
-- "hóa đơn đỏ" — required by Nghị định 123/2020, must be indexable and
-- validatable as a 10/13-digit MST.
create table public.invoices (
  id                uuid primary key default gen_random_uuid(),
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

-- 4.13 PAYMENTS ----------------------------------------------------------------
-- Many-to-one with invoices: split payments supported (e.g. half cash, half card).
-- shift_id: link to the cashier shift envelope — required for ReceptionCloseShift
-- to sum revenue by shift without a brittle created_at BETWEEN join.
-- revenue_type: typed column for the "dinner/lunch/wine/delivery" report.
create table public.payments (
  id               uuid primary key default gen_random_uuid(),
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

-- 4.14 VOUCHERS ----------------------------------------------------------------
-- A voucher is a first-class HIGH entity because misuse = lost money:
-- code is unique per branch, valid_until is enforced, max_uses limits abuse.
create table public.vouchers (
  id          uuid primary key default gen_random_uuid(),
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

-- 4.15 VOUCHER_REDEMPTIONS -----------------------------------------------------
-- One row per invoice that used a voucher.  Audit trail of who redeemed what.
create table public.voucher_redemptions (
  id           uuid primary key default gen_random_uuid(),
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

-- 4.16 DEPOSITS ----------------------------------------------------------------
-- Money taken at booking time (VIP reservations).  Not yet an invoice.
create table public.deposits (
  id             uuid primary key default gen_random_uuid(),
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

-- 4.17 KPI_TARGETS -------------------------------------------------------------
-- AdminKPIView configures targets per metric per period.  NULL branch_id
-- means group-wide target; specific branch_id overrides.
-- scope: 'branch' (specific branch target) or 'group' (group-wide override).
create table public.kpi_targets (
  id            uuid primary key default gen_random_uuid(),
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

-- 4.18 MARKETING_COSTS ---------------------------------------------------------
-- Per-channel ad spend ledger.  Combined with revenue (or reservation count)
-- captured in audit_events.payload, this drives CPA & ROI.
create table public.marketing_costs (
  id            uuid primary key default gen_random_uuid(),
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
-- 5. LOW-consistency tables  (NO foreign keys — NoSQL-style flexible tables)
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

-- 5.1 AUDIT_EVENTS -------------------------------------------------------------
-- Generic audit trail.  Every mutation appends a row here.
-- payload JSONB lets us record the exact diff without bloating the schema.
-- actor_id, entity_id, reservation_id, order_id, invoice_id are PLAIN UUIDs
-- (no FK) — audit must survive deletion of related entities.
create table public.audit_events (
  id             uuid primary key default gen_random_uuid(),
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

-- 5.2 NOTIFICATIONS ------------------------------------------------------------
-- Outgoing notifications.  variables JSONB drives the template engine.
-- No FKs — notification history should survive deletion of users/customers.
create table public.notifications (
  id            uuid primary key default gen_random_uuid(),
  branch_id     uuid not null,
  channel       text not null,                        -- 'email'|'sms'|'push'|'zalo'
  recipient     text not null,                        -- email / phone / device id
  template      text not null,                        -- 'booking_confirmed', 'receipt', …
  variables     jsonb not null default '{}'::jsonb,   -- {name, time, table, total}
  status        text not null default 'pending',      -- 'pending'|'sent'|'failed'
  sent_at       timestamptz,
  error_message text,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);
create index notifications_branch_status_idx on public.notifications (branch_id, status);
create index notifications_pending_idx      on public.notifications (created_at) where status = 'pending';
-- Append-only.

-- 5.3 BRANCH_SETTINGS ----------------------------------------------------------
-- Per-branch key-value configuration.  Replaces scattered `branches.metadata`
-- so we can add new config keys without ever touching the branches row.
-- No FK to branches — value lives independently; a soft-deleted branch's
-- settings still query.
create table public.branch_settings (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null,
  key         text not null,                          -- 'operating_hours', 'tax_id', 'logo_url', 'default_locale', 'report_segments'
  value       jsonb not null,                         -- arbitrary JSON
  value_type  text not null default 'string',         -- 'string'|'number'|'boolean'|'json'|'array'
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, key)
);
create index branch_settings_branch_idx on public.branch_settings (branch_id) where is_active;

-- 5.4 SYSTEM_EVENTS ------------------------------------------------------------
-- Generic catch-all event log (analytics, login attempts, errors, page views).
-- Distinct from audit_events: this is for the app, not for compliance.
create table public.system_events (
  id         uuid primary key default gen_random_uuid(),
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
-- 6. updated_at trigger (HIGH tables only — LOW tables are append-only)
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
    'menu_categories','menu_items','packages','package_items',
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
-- 7. RLS — enable on every table + ONE consolidated policy set per table
-- =============================================================================
-- Every table has RLS enabled.  Use the helper `public.current_branch_id()`
-- and `public.has_role()` to scope by branch in every policy.
--
-- Policy-name convention: `<table>_branch_read` (SELECT) and
-- `<table>_branch_write` / `<table>_admin_write` (ALL or per-action).
-- Names are unique per table — no duplicates.
-- -----------------------------------------------------------------------

-- 7.1 ENABLE RLS on every table ----------------------------------------------
alter table public.branches          enable row level security;
alter table public.users             enable row level security;
alter table public.zones             enable row level security;
alter table public.tables            enable row level security;
alter table public.customers         enable row level security;
alter table public.menu_categories   enable row level security;
alter table public.menu_items        enable row level security;
alter table public.packages          enable row level security;
alter table public.package_items     enable row level security;
alter table public.shifts            enable row level security;
alter table public.reservations      enable row level security;
alter table public.table_assignments enable row level security;
alter table public.orders            enable row level security;
alter table public.order_items       enable row level security;
alter table public.invoices          enable row level security;
alter table public.payments          enable row level security;
alter table public.vouchers          enable row level security;
alter table public.voucher_redemptions enable row level security;
alter table public.deposits          enable row level security;
alter table public.kpi_targets       enable row level security;
alter table public.marketing_costs   enable row level security;
alter table public.audit_events      enable row level security;
alter table public.notifications     enable row level security;
alter table public.branch_settings   enable row level security;
alter table public.system_events     enable row level security;

-- 7.2 POLICIES (consolidated — one set per table) ---------------------------

-- ----- branches -----
create policy "branches_admin_all" on public.branches
  for all using (public.has_role(array['admin']::user_role[]))
            with check (public.has_role(array['admin']::user_role[]));

create policy "branches_branch_read" on public.branches
  for select using (
    public.has_role(array['admin','manager']::user_role[])
    or id = public.current_branch_id()
  );

-- ----- users -----
create policy "users_self_read" on public.users
  for select using (id = auth.uid() or public.has_role(array['admin','manager']::user_role[]));

create policy "users_admin_all" on public.users
  for all using (public.has_role(array['admin']::user_role[]));

-- ----- zones -----
create policy "zones_branch_read" on public.zones
  for select using (branch_id = public.current_branch_id());

create policy "zones_branch_write" on public.zones
  for all using (branch_id = public.current_branch_id());

-- ----- tables -----
create policy "tables_branch_read" on public.tables
  for select using (branch_id = public.current_branch_id());

create policy "tables_branch_write" on public.tables
  for all using (branch_id = public.current_branch_id());

-- ----- customers -----
create policy "customers_branch_read" on public.customers
  for select using (branch_id = public.current_branch_id());

create policy "customers_branch_write" on public.customers
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- menu_categories -----
create policy "menu_categories_branch_read" on public.menu_categories
  for select using (branch_id = public.current_branch_id());

create policy "menu_categories_branch_write" on public.menu_categories
  for all using (branch_id = public.current_branch_id());

-- ----- menu_items -----
create policy "menu_items_branch_read" on public.menu_items
  for select using (branch_id = public.current_branch_id());

create policy "menu_items_branch_write" on public.menu_items
  for all using (branch_id = public.current_branch_id());

-- ----- packages -----
create policy "packages_branch_read" on public.packages
  for select using (branch_id = public.current_branch_id());

create policy "packages_branch_write" on public.packages
  for all using (branch_id = public.current_branch_id());

-- ----- package_items (derive branch via parent package) -----
create policy "package_items_branch_read" on public.package_items
  for select using (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ));

create policy "package_items_branch_write" on public.package_items
  for all using (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ));

-- ----- shifts -----
create policy "shifts_branch_read" on public.shifts
  for select using (branch_id = public.current_branch_id());

create policy "shifts_branch_write" on public.shifts
  for all using (
    branch_id = public.current_branch_id()
    and (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  );

-- ----- reservations -----
create policy "reservations_branch_read" on public.reservations
  for select using (branch_id = public.current_branch_id());

create policy "reservations_branch_insert" on public.reservations
  for insert with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

create policy "reservations_branch_update" on public.reservations
  for update using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  ) with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- table_assignments -----
create policy "table_assignments_branch_read" on public.table_assignments
  for select using (branch_id = public.current_branch_id());

create policy "table_assignments_branch_write" on public.table_assignments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- orders -----
create policy "orders_branch_read" on public.orders
  for select using (branch_id = public.current_branch_id());

create policy "orders_branch_write" on public.orders
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- order_items -----
create policy "order_items_branch_read" on public.order_items
  for select using (branch_id = public.current_branch_id());

create policy "order_items_branch_write" on public.order_items
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  );

-- ----- invoices -----
create policy "invoices_branch_read" on public.invoices
  for select using (branch_id = public.current_branch_id());

create policy "invoices_branch_write" on public.invoices
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- payments -----
create policy "payments_branch_read" on public.payments
  for select using (branch_id = public.current_branch_id());

create policy "payments_branch_write" on public.payments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- vouchers -----
create policy "vouchers_branch_read" on public.vouchers
  for select using (branch_id = public.current_branch_id() and is_active);

create policy "vouchers_admin_write" on public.vouchers
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- voucher_redemptions -----
create policy "voucher_redemptions_branch_read" on public.voucher_redemptions
  for select using (branch_id = public.current_branch_id());

create policy "voucher_redemptions_branch_insert" on public.voucher_redemptions
  for insert with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- deposits -----
create policy "deposits_branch_read" on public.deposits
  for select using (branch_id = public.current_branch_id());

create policy "deposits_branch_write" on public.deposits
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- kpi_targets -----
create policy "kpi_targets_branch_read" on public.kpi_targets
  for select using (branch_id is null or branch_id = public.current_branch_id());

create policy "kpi_targets_admin_write" on public.kpi_targets
  for all using (public.has_role(array['admin','manager']::user_role[]));

-- ----- marketing_costs -----
create policy "marketing_costs_branch_read" on public.marketing_costs
  for select using (branch_id = public.current_branch_id());

create policy "marketing_costs_admin_write" on public.marketing_costs
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- branch_settings -----
create policy "branch_settings_branch_read" on public.branch_settings
  for select using (branch_id = public.current_branch_id() and is_active);

create policy "branch_settings_admin_write" on public.branch_settings
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- audit_events -----
create policy "audit_events_branch_read" on public.audit_events
  for select using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

create policy "audit_events_branch_insert" on public.audit_events
  for insert with check (branch_id = public.current_branch_id());

-- ----- notifications -----
create policy "notifications_branch_read" on public.notifications
  for select using (branch_id = public.current_branch_id());

create policy "notifications_branch_insert" on public.notifications
  for insert with check (branch_id = public.current_branch_id());

-- ----- system_events -----
create policy "system_events_branch_read" on public.system_events
  for select using (branch_id = public.current_branch_id());

create policy "system_events_branch_insert" on public.system_events
  for insert with check (branch_id = public.current_branch_id());


-- =============================================================================
-- 8. write_audit() trigger function + audit triggers
-- =============================================================================
-- SECURITY DEFINER so the trigger can insert into audit_events regardless of
-- the calling user's INSERT policy on audit_events.  search_path is pinned to
-- prevent schema-search-path attacks.
-- -----------------------------------------------------------------------

create or replace function public.write_audit()
returns trigger language plpgsql security definer set search_path = public, auth as $$
declare
  v_action text;
  v_payload jsonb;
  v_actor uuid := auth.uid();
  v_branch uuid := public.current_branch_id();
  v_entity_id uuid;
begin
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
    v_entity_id := NEW.id;
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
    v_entity_id := NEW.id;
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
    v_entity_id := OLD.id;
  end if;

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], v_entity_id, v_payload);

  return coalesce(NEW, OLD);
end$$;

-- Attach audit triggers to money/booking tables
create trigger trg_audit_reservations after insert or update or delete on public.reservations
  for each row execute function public.write_audit('reservation');
create trigger trg_audit_orders after insert or update or delete on public.orders
  for each row execute function public.write_audit('order');
create trigger trg_audit_order_items after insert or update or delete on public.order_items
  for each row execute function public.write_audit('order_item');
create trigger trg_audit_payments after insert or update or delete on public.payments
  for each row execute function public.write_audit('payment');
create trigger trg_audit_invoices after insert or update or delete on public.invoices
  for each row execute function public.write_audit('invoice');
create trigger trg_audit_table_assignments after insert or update or delete on public.table_assignments
  for each row execute function public.write_audit('table_assignment');
create trigger trg_audit_shifts after insert or update or delete on public.shifts
  for each row execute function public.write_audit('shift');

-- =============================================================================
-- 9. revenue_by_hour helper function
-- =============================================================================

create or replace function public.revenue_by_hour(p_branch_id uuid, p_date date)
returns table(hour_bucket int, total numeric) language sql stable as $$
  select extract(hour from p.paid_at)::int as hour_bucket, sum(p.amount) as total
  from public.payments p
  where p.branch_id = p_branch_id
    and p.paid_at::date = p_date
  group by 1 order by 1;
$$;

-- =============================================================================
-- 10. Realtime publication (Supabase)
-- =============================================================================
-- Subscribe to volatile multi-user tables only.  Filter by branch_id on the
-- client to save connection slots.
-- -----------------------------------------------------------------------

alter publication supabase_realtime add table public.reservations;
alter publication supabase_realtime add table public.tables;
alter publication supabase_realtime add table public.table_assignments;
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_items;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.audit_events;

-- =============================================================================
-- 11. Seed data
-- =============================================================================
-- NOTE: The UPDATE statements for public.users silently no-op if the matching
-- auth.users row does not exist.  That is the expected behaviour on first
-- deploy: create the auth.users accounts via Supabase Dashboard / Edge
-- Function / Admin API BEFORE running this migration (or re-run the UPDATEs
-- after creating the accounts).

-- 11.1 BRANCHES ----------------------------------------------------------------
insert into public.branches (id, name, code, address, phone, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Ngưu Cát Quận 1', 'B001', '123 Nguyễn Huệ, Q1, TP.HCM', '028-1234-5678', true),
  ('b1000000-0000-0000-0000-000000000002', 'Ngưu Cát Phú Nhuận', 'B002', '456 Phan Xích Long, Phú Nhuận', '028-8765-4321', true);

-- 11.2 ZONES (B001) -----------------------------------------------------------
insert into public.zones (branch_id, name, sort_order) values
  ('b1000000-0000-0000-0000-000000000001', 'Khu A - VIP', 1),
  ('b1000000-0000-0000-0000-000000000001', 'Khu B - Sân Vườn', 2),
  ('b1000000-0000-0000-0000-000000000001', 'Khu C - Tầng 2', 3),
  ('b1000000-0000-0000-0000-000000000001', 'Khu R - Phòng Riêng', 4),
  ('b1000000-0000-0000-0000-000000000001', 'Khu T - Terrace', 5);

-- 11.3 TABLES (B001, zones A & B) --------------------------------------------
insert into public.tables (branch_id, zone_id, code, capacity, status) values
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A01', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A02', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A03', 6, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu B - Sân Vườn' limit 1), 'B01', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu B - Sân Vườn' limit 1), 'B02', 8, 'available');

-- 11.4 MENU CATEGORIES (B001) ------------------------------------------------
insert into public.menu_categories (branch_id, name, sort_order, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Thịt Bò', 1, true),
  ('b1000000-0000-0000-0000-000000000001', 'Hải Sản', 2, true),
  ('b1000000-0000-0000-0000-000000000001', 'Rau Củ & Nấm', 3, true),
  ('b1000000-0000-0000-0000-000000000001', 'Đồ Uống', 4, true),
  ('b1000000-0000-0000-0000-000000000001', 'Tráng Miệng', 5, true);

-- 11.5 MENU ITEMS (B001, sample) --------------------------------------------
insert into public.menu_items (branch_id, category_id, name, price, cost, is_available) values
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Thăn Ngoại Wagyu A5', 500000, 180000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Lưỡi Bò Thượng Hạng', 400000, 120000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Dẻ Sườn Bò', 380000, 95000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Rau Củ & Nấm' limit 1), 'Nấm Nhật Kiểu', 120000, 25000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Đồ Uống' limit 1), 'Rượu Sake Chín', 800000, 450000, true);

-- 11.6 PACKAGES (B001) -------------------------------------------------------
insert into public.packages (branch_id, name, type, price, item_limit, duration_minutes, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Set Biz Trưa', 'set', 350000, 5, 90, true),
  ('b1000000-0000-0000-0000-000000000001', 'Premium Buffet', 'buffet', 1380000, 20, 120, true),
  ('b1000000-0000-0000-0000-000000000001', 'Drink A', 'drink', 690000, 10, 120, true);

-- 11.7 KPI TARGETS (B001, scope='branch' to satisfy CHECK constraint) -------
-- The CHECK constraint on kpi_targets.scope only allows 'branch' or 'group'.
-- The period granularity (daily/weekly/monthly) is encoded in metric_key.
insert into public.kpi_targets (branch_id, metric_key, target_value, period_start, period_end, scope) values
  ('b1000000-0000-0000-0000-000000000001', 'revenue_daily',   15000000,  '2026-06-01', '2026-06-30', 'branch'),
  ('b1000000-0000-0000-0000-000000000001', 'revenue_weekly',   90000000,  '2026-06-01', '2026-06-30', 'branch'),
  ('b1000000-0000-0000-0000-000000000001', 'revenue_monthly', 360000000,  '2026-06-01', '2026-06-30', 'branch');

-- 11.8 USERS — role/branch assignment (no-op if auth.users rows absent) -----
-- Run AFTER creating the matching auth.users rows in Supabase Auth Dashboard.
update public.users
   set role = 'admin',
       branch_id = (select id from public.branches where code = 'B001'),
       full_name = 'System Admin',
       phone = '+84-xxx'
 where email = 'admin@nguucat.vn';

update public.users
   set role = 'manager',
       branch_id = (select id from public.branches where code = 'B001')
 where email = 'manager.q1@nguucat.vn';

update public.users
   set role = 'reception',
       branch_id = (select id from public.branches where code = 'B001')
 where email = 'reception.q1@nguucat.vn';

update public.users
   set role = 'staff',
       branch_id = (select id from public.branches where code = 'B001')
 where email = 'staff.q1@nguucat.vn';


-- ==========================================
-- FILE: 20260624000000_fix_current_user_role_anon.sql
-- ==========================================
-- =============================================================================
-- 20260624000000_fix_current_user_role_anon.sql
-- Fix: current_user_role() crashes on anon requests with "invalid input value
-- for enum user_role: 'anon'". This breaks every anon PostgREST request that
-- touches an RLS-protected table.
--
-- Root cause: the function did `(... ->> 'role')::user_role` directly. For
-- anon / authenticated PostgREST roles, the JWT `role` claim is 'anon' or
-- 'authenticated' — not in our user_role enum — so the cast raises SQLSTATE
-- 22P02 before coalesce() can fall back to the public.users lookup.
--
-- Fix: whitelist the JWT role against the enum values before casting. If the
-- claim isn't a valid user_role, return NULL and let coalesce() fall through.
-- =============================================================================

create or replace function public.current_user_role()
returns user_role language sql stable security definer set search_path = public, auth as $$
  select coalesce(
    case
      when (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')
           in ('admin','manager','reception','staff','kitchen')
      then ((nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')::user_role)
    end,
    (select role from public.users where id = auth.uid())
  )
$$;

-- Also harden has_role() against the same enum cast edge case (it currently
-- calls the same bare ::user_role cast). Even with current_user_role() fixed,
-- has_role() might be called from contexts that haven't been migrated yet.
create or replace function public.has_role(roles user_role[])
returns boolean language sql stable security definer set search_path = public, auth as $$
  select case
    when (select public.current_user_role()) is null then false
    else (select public.current_user_role()) = any(roles)
  end
$$;


-- ==========================================
-- FILE: 20260625080844_auth_hook_custom_access_token.sql
-- ==========================================
-- =============================================================================
-- 20260625080844_auth_hook_custom_access_token.sql
--
-- Postgres function backing the Supabase Auth "Custom Access Token" hook.
--
-- The hook fires on every issued access token (login + refresh) and lets us
-- inject extra `app_metadata` claims into the JWT. We use it to copy the
-- user's `role` and `branch_id` from the `public.users` row into the token,
-- so RLS policies that key on `auth.jwt() -> 'app_metadata' -> 'role'`
-- (and the `current_user_role()` / `current_branch_id()` helpers that read
-- those claims first before falling back to a DB lookup) don't have to hit
-- `public.users` on every request.
--
-- The function MUST have signature `(event jsonb) returns jsonb` and be
-- `STABLE` (not VOLATILE) so Supabase can cache the plan. See
-- https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook
--
-- After this migration is applied, the function will appear in the
-- "Database Function" picker on
--   Dashboard → Authentication → Hooks → Custom Access Token → Type
-- along with the alternative "Edge Function" option (we deployed
-- `supabase/functions/custom-access-token` for that path too — pick ONE).
--
-- The migration is idempotent (`create or replace`) so re-running it after
-- the hook is already wired up is safe.
-- =============================================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = public, auth
as $$
declare
  claims       jsonb;
  app_meta     jsonb;
  v_user_id    uuid;
  v_role       public.user_role;
  v_branch_id  uuid;
begin
  -- The hook payload always carries `user_id` (the auth.users.id of the
  -- user being signed in). Bail out cleanly if it's somehow missing —
  -- Supabase expects the original `event` back in that case.
  v_user_id := (event ->> 'user_id')::uuid;
  if v_user_id is null then
    return event;
  end if;

  -- Pull the role + branch_id straight from the profile row.
  -- SECURITY INVOKER (default) is fine here: the function runs as
  -- supabase_auth_admin, which has the right grants on public.users.
  select role, branch_id
    into v_role, v_branch_id
    from public.users
   where id = v_user_id;

  -- Always start from the existing claims. Don't clobber anything
  -- Supabase already set (aud, exp, iat, sub, email, …).
  claims   := coalesce(event -> 'claims', '{}'::jsonb);
  app_meta := coalesce(claims -> 'app_metadata', '{}'::jsonb);

  if v_role is not null then
    app_meta := app_meta || jsonb_build_object('role', v_role::text);
  end if;

  if v_branch_id is not null then
    app_meta := app_meta || jsonb_build_object('branch_id', v_branch_id::text);
  end if;

  claims := jsonb_set(claims, '{app_metadata}', app_meta);
  return jsonb_set(event, '{claims}', claims);
end;
$$;

-- =============================================================================
-- Grants — this is the part the Supabase docs gloss over.
--
-- Postgres grants EXECUTE to PUBLIC by default for every new function, which
-- would make this hook callable by `anon` / `authenticated` clients. The
-- supabase_auth_admin role is the only one that should be able to invoke it
-- (it's the role Supabase uses to run auth hooks server-side).
-- =============================================================================

revoke execute on function public.custom_access_token_hook(jsonb)
  from public, anon, authenticated;

grant execute on function public.custom_access_token_hook(jsonb)
  to supabase_auth_admin;


-- ==========================================
-- FILE: 20260625100000_hook_exception_guard.sql
-- ==========================================
-- =============================================================================
-- 20260625100000_hook_exception_guard.sql
--
-- The hook we created in 20260625080844 had no EXCEPTION handler. If anything
-- inside the body throws — an RLS surprise, an unexpected NULL cast, a race
-- during the auth.users → public.users join — GoTrue's HTTP call returns
-- `unexpected_failure` (HTTP 500) and the user CANNOT log in at all.
--
-- This migration:
--   1. Replaces the hook body with an EXCEPTION-guarded variant. On any error
--      we return the ORIGINAL event unchanged so login still succeeds (just
--      without the extra role/branch_id claims — RLS fallback in DB functions
--      `current_user_role()` / `current_branch_id()` already covers that path).
--   2. Explicitly grants SELECT on public.users to supabase_auth_admin so the
--      SELECT inside the hook never hits an RLS wall, even on older Supabase
--      versions where supabase_auth_admin didn't bypass RLS by default.
--   3. Adds `hook_version` to app_metadata so we can verify in the JWT that
--      the hook actually fired (look for "hook_version": "2026-06-25").
--
-- Idempotent: `create or replace` + `grant ... on conflict do nothing`.
-- =============================================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  claims       jsonb;
  app_meta     jsonb;
  v_user_id    uuid;
  v_role       public.user_role;
  v_branch_id  uuid;
begin
  -- The hook payload always carries `user_id`. Bail out cleanly if missing.
  v_user_id := (event ->> 'user_id')::uuid;
  if v_user_id is null then
    return event;
  end if;

  -- SECURITY DEFINER + explicit grant (below) ensure this SELECT is not
  -- blocked by RLS on public.users.
  select role, branch_id
    into v_role, v_branch_id
    from public.users
   where id = v_user_id;

  -- Preserve existing claims. Don't clobber anything Supabase already set.
  claims   := coalesce(event -> 'claims', '{}'::jsonb);
  app_meta := coalesce(claims -> 'app_metadata', '{}'::jsonb);

  -- Stamp a hook version so we can verify the hook fired by inspecting JWT.
  app_meta := app_meta || jsonb_build_object('hook_version', '2026-06-25');

  if v_role is not null then
    app_meta := app_meta || jsonb_build_object('role', v_role::text);
  end if;

  if v_branch_id is not null then
    app_meta := app_meta || jsonb_build_object('branch_id', v_branch_id::text);
  end if;

  claims := jsonb_set(claims, '{app_metadata}', app_meta);
  return jsonb_set(event, '{claims}', claims);

-- ── Safety net ───────────────────────────────────────────────────────────
-- If anything inside the body throws (RLS surprise, NULL cast, race), we
-- return the ORIGINAL event untouched. Login will still succeed; the user
-- just won't have the extra role/branch_id in this JWT. The DB-side
-- `current_user_role()` / `current_branch_id()` helpers fall back to a
-- `public.users` lookup, so RLS-protected queries still work correctly.
exception
  when others then
    return event;
end;
$$;

-- Permissions: only supabase_auth_admin (the role GoTrue uses) may invoke.
revoke execute on function public.custom_access_token_hook(jsonb)
  from public, anon, authenticated;

grant execute on function public.custom_access_token_hook(jsonb)
  to supabase_auth_admin;

-- Explicit grant so the SECURITY DEFINER body can SELECT from public.users
-- without hitting RLS even on older Supabase versions.
grant select on public.users to supabase_auth_admin;

-- ==========================================
-- FILE: 20260625110000_write_audit_use_new_branch.sql
-- ==========================================
-- =============================================================================
-- 20260625110000_write_audit_use_new_branch.sql
--
-- The `write_audit` trigger on table_assignments / orders / order_items /
-- payments / invoices / shifts / reservations reads branch_id via
-- `public.current_branch_id()`. That helper depends on either:
--   (a) `request.jwt.claims` being set on the session, or
--   (b) `auth.uid()` returning a real user.
--
-- Edge Functions run with the service role — NEITHER is available:
--   - `request.jwt.claims` is empty (no JWT context)
--   - `auth.uid()` is NULL (no authenticated user)
--
-- We tried to fix this in check-in by calling `set_config('request.jwt.claims', ...)`
-- before inserts, but PostgREST connection pooling means that RPC runs on a
-- different connection than the subsequent INSERT — the config is gone.
--
-- Better fix: the row being inserted ALREADY carries branch_id (every audited
-- table in this schema does). Read it straight from NEW instead of relying on
-- session config. This works for every caller (Edge Function, RLS user, admin).
--
-- Fallback order: NEW.branch_id → current_branch_id() → NULL (will fail the
-- NOT NULL audit_events constraint, which is the correct behavior — caller
-- MUST provide branch_id on the row).
-- =============================================================================

create or replace function public.write_audit()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_action text;
  v_payload jsonb;
  v_actor uuid := auth.uid();
  v_branch uuid;
  v_entity_id uuid;
begin
  -- Prefer the branch_id from the row being inserted/updated/deleted.
  -- Falls back to the session helper for tables that may not have branch_id.
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
    v_entity_id := NEW.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (NEW.branch_id)::uuid end),
      public.current_branch_id()
    );
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
    v_entity_id := NEW.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (NEW.branch_id)::uuid end),
      public.current_branch_id()
    );
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
    v_entity_id := OLD.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (OLD.branch_id)::uuid end),
      public.current_branch_id()
    );
  end if;

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], v_entity_id, v_payload);

  return coalesce(NEW, OLD);
end;
$$;

-- ==========================================
-- FILE: 20260625120000_write_audit_singular_fix.sql
-- ==========================================
-- =============================================================================
-- 20260625120000_write_audit_singular_fix.sql
--
-- Previous fix (20260625110000) checked `TG_ARGV[0] in ('table_assignments', ...)`
-- (plural). The actual trigger definition on table_assignments is
-- `EXECUTE FUNCTION write_audit('table_assignment')` (singular). So the
-- CASE returned NULL and the audit row got NULL branch_id.
--
-- The cleanest fix: just try NEW.branch_id (cast to uuid) UNCONDITIONALLY.
-- Every audited table in this schema carries branch_id:
--   - table_assignments, orders, order_items, payments, invoices, shifts,
--     reservations, customers, tables
-- If a future table is audited that doesn't have branch_id, the cast will
-- error and the trigger will fail loudly — better than silently inserting
-- NULL.
-- =============================================================================

create or replace function public.write_audit()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_action text;
  v_payload jsonb;
  v_actor uuid := auth.uid();
  v_branch uuid;
  v_entity_id uuid;
  v_row jsonb;
begin
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
    v_entity_id := NEW.id;
    v_row := to_jsonb(NEW);
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
    v_entity_id := NEW.id;
    v_row := to_jsonb(NEW);
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
    v_entity_id := OLD.id;
    v_row := to_jsonb(OLD);
  end if;

  -- Always prefer the branch_id from the row itself. This is set by the
  -- application (check-in / order-create / etc.) and is the most reliable
  -- source. Fall back to the session helper only if the row has no
  -- branch_id at all (shouldn't happen for any audited table, but keeps
  -- the trigger robust for future ones).
  v_branch := coalesce(
    (v_row ->> 'branch_id')::uuid,
    public.current_branch_id()
  );

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], v_entity_id, v_payload);

  return coalesce(NEW, OLD);
end;
$$;

-- ==========================================
-- FILE: 20260625130000_menu_schema_align_ishii.sql
-- ==========================================
-- =============================================================================
-- 20260625130000_menu_schema_align_ishii.sql
--
-- Align the menu schema with the structure described in
-- docs/member_status/Ishii/2026-06-24.md § VI.1 (Full Menu Data Sync) and
-- the data in `thực đơn.txt` — a 2-level hierarchy (category → subcategory
-- → item) with `color`, `unit`, and `price_display` fields.
--
-- What we had before this migration:
--   - menu_categories: id, branch_id, name, sort_order, is_active, metadata
--   - menu_items:     id, branch_id, category_id, name, description, price,
--                     cost, image_url, tags, nutrition, metadata
--   - NO menu_subcategories table
--   - NO color on categories, NO unit / price_display on items
--
-- What we add (all idempotent):
--   1. menu_categories.color   text  (yellow / pink per Ishii spec)
--   2. menu_items.unit          text  (Vé / Phần / Ly / Lon / BỊCH / ...)
--   3. menu_items.price_display text  (1.380K / 250K / ...)
--   4. menu_subcategories       new table (2-level hierarchy)
--   5. menu_items.subcategory_id fk   (item can be under subcategory, nullable)
--
-- Migration is fully reversible:
--   DROP TABLE IF EXISTS public.menu_subcategories;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS subcategory_id;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS price_display;
--   ALTER TABLE public.menu_items DROP COLUMN IF EXISTS unit;
--   ALTER TABLE public.menu_categories DROP COLUMN IF EXISTS color;
-- =============================================================================

-- 1. menu_categories.color
ALTER TABLE public.menu_categories
  ADD COLUMN IF NOT EXISTS color text;

COMMENT ON COLUMN public.menu_categories.color IS
  'UI badge color for the category. Used by POS to render the yellow/pink row grouping per Ishii 2026-06-24 §VI.1.';

-- 2. menu_items.unit
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS unit text;

COMMENT ON COLUMN public.menu_items.unit IS
  'Display unit for the item (Vé / Phần / Ly / Lon / BỊCH / cái / hộp / đôi / chai / lọ / gram).';

-- 3. menu_items.price_display
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS price_display text;

COMMENT ON COLUMN public.menu_items.price_display IS
  'Pre-formatted price string for UI (e.g. "1.380K", "250K", "50K/100g"). NOT used for math — see price column.';

-- 4. menu_subcategories table
CREATE TABLE IF NOT EXISTS public.menu_subcategories (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid        NOT NULL REFERENCES public.menu_categories(id) ON DELETE CASCADE,
  branch_id   uuid        REFERENCES public.branches(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  sort_order  integer     NOT NULL DEFAULT 0,
  is_active   boolean     NOT NULL DEFAULT true,
  metadata    jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menu_subcategories_category
  ON public.menu_subcategories (category_id, sort_order)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_menu_subcategories_branch
  ON public.menu_subcategories (branch_id)
  WHERE is_active = true;

COMMENT ON TABLE public.menu_subcategories IS
  'Sub-categories inside a category. Used by ReceptionOrderView buffet discount engine and AdminFloorsView zone grouping. Per Ishii 2026-06-24 §VI.1.';

-- 5. menu_items.subcategory_id
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS subcategory_id uuid
    REFERENCES public.menu_subcategories(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_menu_items_subcategory
  ON public.menu_items (subcategory_id)
  WHERE subcategory_id IS NOT NULL;

COMMENT ON COLUMN public.menu_items.subcategory_id IS
  'Optional subcategory. NULL means the item is directly under its category (no subcategory).';

-- 6. updated_at trigger for menu_subcategories
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS trg_menu_subcategories_updated_at ON public.menu_subcategories;
CREATE TRIGGER trg_menu_subcategories_updated_at
  BEFORE UPDATE ON public.menu_subcategories
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_set_updated_at();


-- ==========================================
-- FILE: 20260625130001_menu_items_add_is_active.sql
-- ==========================================
-- =============================================================================
-- 20260625130002_menu_items_add_is_active.sql
--
-- The original 20260623000000_setup.sql did not include `is_active` on
-- public.menu_items (it was only on menu_categories / packages / tables).
-- The Ishii 2026-06-24 §VI.1 menu spec + the ReceptionOrderView buffet
-- filter engine both expect an availability flag.
--
-- Adding it as a default-true nullable column (NOT NULL with default
-- avoids breaking existing rows). Idempotent: ADD COLUMN IF NOT EXISTS.
-- =============================================================================

ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.menu_items.is_active IS
  'Visibility flag. ReceptionOrderView filters by is_active = true to render the orderable grid.';


-- ==========================================
-- FILE: 20260625130003_seed_menu_from_ishii.sql
-- ==========================================
-- =============================================================================
-- AUTO-GENERATED from docs/member_status/Ishii/thực đơn.txt
-- Source: Ishii's menuData.ts (700+ items across 12 categories, 16 subcategories)
-- Generated at: 2026-06-25T10:57:24.308Z
-- DO NOT EDIT BY HAND — regenerate via scripts/_archive/per-onetime/parse_menu_to_sql.js
--
-- Idempotent: every insert uses ON CONFLICT DO NOTHING against a deterministic
-- UUID (uuidFor) so re-running the migration does not duplicate rows.
-- =============================================================================
BEGIN;

-- 1. Categories (12)
-- ----------------------------------------------------------------------------
INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7c9dfe17-9184-5d75-b6f3-d6ad00ab31ae', 'b1000000-0000-0000-0000-000000000001', 'SET 1390', 100, true, '{"fe_id":"set_1390"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_1390 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0ecac5f4-5a21-53de-9b08-08ad24b8f61e', 'b1000000-0000-0000-0000-000000000001', '7c9dfe17-9184-5d75-b6f3-d6ad00ab31ae', 'Vé Người Lớn 1380', 1380000, 'Vé', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set1390_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('a6b3068d-868e-5b45-88e2-acafe1cbdf04', 'b1000000-0000-0000-0000-000000000001', 'SET 1150', 101, true, '{"fe_id":"set_1150"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_1150 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('baedab6a-f939-56d5-a65a-d11cbfb36879', 'b1000000-0000-0000-0000-000000000001', 'a6b3068d-868e-5b45-88e2-acafe1cbdf04', 'Vé Người Lớn 1150', 1150000, 'Vé', '1.150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set1150_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('d3e9aa63-ceda-5e23-8ac0-50d78d3f6213', 'b1000000-0000-0000-0000-000000000001', 'SET 680', 102, true, '{"fe_id":"set_680"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_680 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('85f74311-fd9f-5c67-aac5-3d8a4ed15a5e', 'b1000000-0000-0000-0000-000000000001', 'd3e9aa63-ceda-5e23-8ac0-50d78d3f6213', 'Vé Người Lớn 680', 680000, 'Vé', '680K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set680_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('9babff3d-469b-5f89-88c4-48691adb5b96', 'b1000000-0000-0000-0000-000000000001', 'SET 490', 103, true, '{"fe_id":"set_490"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_490 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('03fa9ce7-5cb7-513a-bf32-26b166b2544c', 'b1000000-0000-0000-0000-000000000001', '9babff3d-469b-5f89-88c4-48691adb5b96', 'Vé Người Lớn 490', 490000, 'Vé', '490K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set490_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7634202c-09be-5e7b-b0f8-0c0d72e952c6', 'b1000000-0000-0000-0000-000000000001', 'SET 380', 104, true, '{"fe_id":"set_380"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_380 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d53e04d9-c8ac-5b58-8bf4-e6bf3f6776e5', 'b1000000-0000-0000-0000-000000000001', '7634202c-09be-5e7b-b0f8-0c0d72e952c6', 'Vé Người Lớn 380', 380000, 'Vé', '380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set380_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('4f502a03-94ab-598c-9e75-a7b193c21d01', 'b1000000-0000-0000-0000-000000000001', 'SET DRINK', 105, true, '{"fe_id":"set_drink"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_drink (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('547e71c2-cfad-5022-a9b5-0c306d17d504', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'BUFFET NƯỚC GÓI 250 (JP)', 227273, 'Vé', '227,273K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_buffet_250jp","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f74026b8-2460-5f5a-ad9c-022bb34bdd06', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Nước ngọt uống không giới hạn', 80000, 'Vé', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_unlimited_soft","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e9de840f-27f1-5b1b-a769-62a9fd182a4a', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Rượu bia uống không giới hạn trong 2 giờ', 250000, 'Vé', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_alcohol_2h_250","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8f52aa2b-e5c1-554b-8f9a-567ad3b6c565', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Rượu bia cao cấp uống không giới hạn', 350000, 'Vé', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_alcohol_2h_350","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('c80f8d49-30ac-576c-9b41-d4efaae26852', 'b1000000-0000-0000-0000-000000000001', 'A la carte', 106, true, '{"fe_id":"a_la_carte"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category a_la_carte (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('345d4d7e-570c-58c1-bdaf-9a6fc2ad1e32', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'A la carte', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('54f39dd7-5142-584a-9cff-07ef84813003', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET LUNCH', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lunch_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('df994aa3-37e6-5ac5-85db-d29b34d96c8d', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET TIỆC CHIÊU ĐÃI VN', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiec_cd_vn_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b5694927-4c39-520e-b778-4c0025b22636', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET TIỆC CHIÊU ĐÃI JP', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiec_cd_jp_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('71ef4d58-6968-588a-aa7f-c2338eb51ad7', 'b1000000-0000-0000-0000-000000000001', 'Set 550JP', 107, true, '{"fe_id":"set_550jp"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_550jp (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d51a16bd-dac5-568c-a670-7cedd84c53e7', 'b1000000-0000-0000-0000-000000000001', '71ef4d58-6968-588a-aa7f-c2338eb51ad7', 'SET 550 (JP)', 509259, 'Vé', '509,259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set550jp_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('c656c3b6-1db1-52b9-83e0-fa03ead8bf7c', 'b1000000-0000-0000-0000-000000000001', 'Buffet Lẩu', 108, true, '{"fe_id":"buffet_lau"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category buffet_lau (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('612229f3-ce09-50fe-8d48-c336134ce56f', 'b1000000-0000-0000-0000-000000000001', 'c656c3b6-1db1-52b9-83e0-fa03ead8bf7c', 'Set Lẩu 250', 250000, 'Vé', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lau_250_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'BUFFET', 109, true, '{"fe_id":"buffet"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category buffet
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('e23dee91-afff-58c8-8d99-eb013f91b858', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 1390', 0, true, '{"fe_id":"buffet_1390"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4e5a299b-cae2-521a-b8f9-132a54621ad2', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 1150', 1, true, '{"fe_id":"buffet_1150"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('fae964ff-c179-5c96-a2f5-05e1750fdc7a', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 680', 2, true, '{"fe_id":"buffet_680"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('c093cfcb-18ee-5ca7-9c8e-004b9fb07d78', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 490', 3, true, '{"fe_id":"buffet_490"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('7ea2ad16-e1d4-5b84-89db-ea75585b6b48', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 380', 4, true, '{"fe_id":"buffet_380"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_1390
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('61c0cff6-6db7-54cf-b249-9b260a396383', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'e23dee91-afff-58c8-8d99-eb013f91b858', 'Vé Người Lớn 1380', 1380000, 'Vé', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf1390_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_1150
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('21c8e252-3e3d-5895-9f44-4a2e74c6d663', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', '4e5a299b-cae2-521a-b8f9-132a54621ad2', 'Vé Người Lớn 1150', 1150000, 'Vé', '1.150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf1150_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_680
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('af6c9d5b-50b2-5b2c-84f3-c3f6b3303827', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'fae964ff-c179-5c96-a2f5-05e1750fdc7a', 'Vé Người Lớn 680', 680000, 'Vé', '680K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf680_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_490
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ffb57568-0e67-542c-be34-2d4ae2318304', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'c093cfcb-18ee-5ca7-9c8e-004b9fb07d78', 'Vé Người Lớn 490', 490000, 'Vé', '490K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf490_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_380
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3672fb96-eedc-585c-af1a-8e321c36fdca', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', '7ea2ad16-e1d4-5b84-89db-ea75585b6b48', 'Vé Người Lớn 380', 380000, 'Vé', '380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf380_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('9b038804-81d2-56c0-a139-0b5d9008e88c', 'b1000000-0000-0000-0000-000000000001', 'Set Lunch', 110, true, '{"fe_id":"set_lunch"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_lunch (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a5901473-93ea-50d2-a384-33db3ebf113a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm Bibimbap - Lunch Menu', 99000, 'Phần', '99K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_bibimbap","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f73da03c-ea89-5d79-a62e-d29be352293a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm Cà Ri Ushiyoshi - Lunch', 89000, 'Phần', '89K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_cary","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('55aea1bc-e4a0-5182-af9d-037ba6db10a1', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm gà Nanban Nhật Bản - Lunch', 179000, 'Phần', '179K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_nanban","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0fe0022c-a0ac-59b0-bba6-af577810d082', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Cơm thịt heo kim chi', 129000, 'Phần', '129K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_kimchi_pork","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('daa20abc-650b-54a7-a123-2425d651aff2', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Cơm thịt heo kim chi phủ trứng', 139000, 'Phần', '139K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_kimchi_pork_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('98a37efc-c4b6-526f-b671-bd2f3a45a497', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Bò Cao Cấp', 259000, 'Phần', '259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_beef_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('246e3c74-944e-5608-87a8-75a9a52ce724', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Cơm Gà Cay Ngọt', 109000, 'Phần', '109K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_chicken_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e45b84fe-6ad8-5094-bcb7-10ac819eeb91', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Heo Tổng Hợp', 169000, 'Phần', '169K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_pork_mix","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('48504cc4-7f82-5375-bbbd-e2a523c1dc47', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Nướng Healthy', 199000, 'Phần', '199K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_healthy_grill","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a19e9e55-4f71-54dc-940e-a42f2703dbf5', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Nướng Thập Cẩm (Heo & Gà)', 149000, 'Phần', '149K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_grill_mix_pork_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f15c3492-e13a-56fc-8842-fddac9dac17f', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Nướng Thập Cẩm (Heo & Bò)', 189000, 'Phần', '189K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_grill_mix_pork_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('226b3df4-9604-55e8-bcf6-caeba5e874d9', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Oyakodon (Cơm Gà & Trứng)', 119000, 'Phần', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_oyakodon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c5bff9c9-7cae-5310-82c3-1f3e196ecf1a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Wagyu Thượng Hạng', 450000, 'Phần', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_wagyu_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5415fb8f-f703-58f1-b062-e6c84d533cba', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Wagyu Tuyển Chọn', 325000, 'Phần', '325K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_wagyu_select","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e37652b2-a0f9-5559-9c16-c98f9a4a1294', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì Chua Cay Kiểu Á Đông - Lunch', 179000, 'Phần', '179K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_spicy_noodle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8783e51b-a94b-540f-a478-df42e9266bd0', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì Udon Kim Chi - Lunch', 149000, 'Phần', '149K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_udon_kimchi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f7840ea-35ac-59d0-abb7-763bddaeca16', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì udon xào cùng thịt bò - Lunch', 129000, 'Phần', '129K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_udon_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cea23768-ef2d-53f9-a096-444b75f9f4cf', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Sét Chiên Thập Cẩm Và Cơm Kiểu Nhật - Lunch', 189000, 'Phần', '189K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_mix_rice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cc3a28fb-50ed-5a7f-b949-3f22e238e40f', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Sét trưa Hamburger - Lunch', 99000, 'Phần', '99K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_hamburger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('daa60310-5b8f-535e-afa7-2a76ee13bad3', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Tôm Tempura - Lunch', 40000, 'Phần', '40K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_tempura_shrimp","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('85a41020-069e-5ea5-a31f-a327390926df', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cá Ngân chiên giòn', 45000, 'Phần', '45K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_fish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6f43093-1c23-549e-b674-bd297245c3a7', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Gà Chiên Nhật Bản - Lunch', 35000, 'Phần', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'b1000000-0000-0000-0000-000000000001', 'SET TIỆC CHIÊU ĐÃI', 111, true, '{"fe_id":"set_tiec_chieu_dai"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_tiec_chieu_dai (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c5a88e47-9cca-537d-8d77-4e7b594fd05b', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET1-Drink Tiệc Chiêu Đãi', 250000, 'Phần', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set1_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b84d739d-0287-5f16-b649-cad5677adb9e', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET1-Tiệc Chiêu Đãi', 450000, 'Phần', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set1","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('975c4986-3a98-5615-bc52-d7c543a44d8a', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET2-Drink Tiệc Chiêu Đãi', 350000, 'Phần', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set2_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a3a368bb-78a8-5124-aff2-ca703722451d', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET2-Tiệc Chiêu Đãi', 550000, 'Phần', '550K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('eb314f31-cea3-56e7-95a2-a1067f09739f', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET3-Drink Tiệc Chiêu Đãi', 350000, 'Phần', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set3_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('35b8322c-48da-5f31-be67-0a306376f023', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET3-Tiệc Chiêu Đãi', 850000, 'Phần', '850K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set3","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('5e494b08-881a-54eb-a020-d023548575e9', 'b1000000-0000-0000-0000-000000000001', 'SET TIỆC CHIÊU ĐÃI (JP)', 112, true, '{"fe_id":"set_tiec_chieu_dai_jp"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_tiec_chieu_dai_jp (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b59d4f55-f2bc-5087-939c-70d63787bd75', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET DRINK 250K', 227273, 'Vé', '227,273K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_drink_250","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('603ad4e9-cde1-593d-b406-04a90ca6322d', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET DRINK 350K', 318182, 'Vé', '318,182K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_drink_350","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('da855d88-e8e8-5074-8877-e7cd8e1938cb', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 001', 416667, 'Vé', '416,667K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_001","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('80dc2677-d718-533b-ad14-c353baf03a0f', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 002', 509259, 'Vé', '509,259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_002","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('83880232-4946-5b3b-b66c-8675c4b67ac5', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 003', 787037, 'Vé', '787,037K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_003","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b2fa1a11-7618-5e4a-bbe6-597135ab2fa6', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET TIỆC GUMA', 1310185, 'Vé', '1.310,185K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_guma","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7f62963d-d216-520b-ab21-ae39a27002d7', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET TIỆC NAGASAKI', 1032407, 'Vé', '1.032,407K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_nagasaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('5232db90-7f64-5d7a-8e2b-f311ca7f9305', 'b1000000-0000-0000-0000-000000000001', 'SET Vietravel', 113, true, '{"fe_id":"set_vietravel"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_vietravel (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c4449640-b3d5-5013-85d8-b6cbfa84c45a', 'b1000000-0000-0000-0000-000000000001', '5232db90-7f64-5d7a-8e2b-f311ca7f9305', 'SET TIỆC Vietravel D Course', 500000, 'Vé', '500K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"vietravel_d_course","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thức Ăn', 114, true, '{"fe_id":"thuc_an"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_an
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Wagyu', 0, true, '{"fe_id":"wagyu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('6942ff59-4096-5848-b299-0a32045ad325', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Beef tongue', 1, true, '{"fe_id":"beef_tongue"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('c3899596-122a-5c93-a20b-225120f2f2ff', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Beef', 2, true, '{"fe_id":"beef"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('b7bcbe61-7027-5e59-81c5-c53649c4a055', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Nội Tạng', 3, true, '{"fe_id":"offal"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thịt Heo', 4, true, '{"fe_id":"pork"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thịt Gà', 5, true, '{"fe_id":"chicken"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Grill a la carte', 6, true, '{"fe_id":"grill_alacarte"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'A la carte', 7, true, '{"fe_id":"alacarte"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ebf8cf7e-8ab7-5062-8049-4231a674e094', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Khai Vị', 8, true, '{"fe_id":"appetizer"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('550c50e2-ee85-5ded-aebb-12ea7a66143d', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Xà Lách', 9, true, '{"fe_id":"salad"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0b8f0878-f117-5356-9ca3-febce150d9bd', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Cơm', 10, true, '{"fe_id":"rice"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('3c8fe227-2183-5b31-9a6e-4532411d1c60', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Mì các loại', 11, true, '{"fe_id":"noodle"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Súp', 12, true, '{"fe_id":"soup"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Tráng Miệng', 13, true, '{"fe_id":"dessert"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Sốt', 14, true, '{"fe_id":"sauce"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ca82c088-92a3-53e8-a709-3a77bc673ff9', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Lẩu Sukiyaki', 15, true, '{"fe_id":"sukiyaki"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory wagyu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c16268df-580b-5c06-bdaf-aac42fa58502', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Sườn Wagyu Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_ribs","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3a84780b-99ed-5cf0-89fb-600b77bfdc91', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thăn Ngoại Wagyu Chọn Lọc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_sirloin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9d172055-fbbf-5c34-86d4-f17a65c41b7d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thăn Lưng Wagyu Chọn Lọc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_back","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b1aca5a6-afd2-51ae-a3e4-041fc4470e6e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Sườn Ngắn Wagyu Nướng Kiểu Shabu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_short_ribs_shabu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9373f6ae-5f15-532a-9b70-4ef10223c0b4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lõi Vai Wagyu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_shoulder","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8233459f-32a6-5de0-b84d-63d86c1fd354', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lưỡi bò cắt dày', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_tongue_thick_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6695a94-275b-53f0-976d-29cc168af312', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lưỡi bò cắt dày', 170000, 'Phần', '170K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_tongue_thick","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c3c75e97-9bb3-5800-9b77-24a8fbf0fc23', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thịt đỏ Wagyu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_red_meat","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beef_tongue
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9a140b66-2cdb-567b-b5a7-2e1bc7e0f0d3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Cắt Mỏng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_thin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('621be4d3-c84a-538d-a85d-2c445ccd0ca2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Xốt Muối Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2db8e967-f0c2-561d-a39d-f15c9e89fa50', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Hoa', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_flower","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beef
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8359729e-e39a-55f1-9463-058338a10529', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab2e34a5-ec36-5d6b-b3de-df507055c072', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab1e819e-e27c-53c1-9321-6459fa48a041', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('45c4f5d6-9579-5cfb-aa0e-11a864512982', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('70a8207a-84fc-52f7-a9d2-e40dca212f82', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2dccd15d-4e65-588e-b816-637745e5d554', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4ad632fd-9c30-5925-9409-7da11ca96f5a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f540ffcd-b9f2-5eb7-b1a2-6f283bb7e910', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4a070db3-65e8-5a87-8875-b52062e1df36', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('22b295d5-fe10-524a-8293-c5acf348a9a6', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Thăn Lưng Ushiyoshi Cao Cấp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_sirloin_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('39abd938-f254-55cf-8b01-30218674d985', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Thăn Lưng Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_sirloin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b015fdb2-b278-58a2-996c-dcb5682d220f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Ushiyoshi Cao Cấp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('011e6b3b-6ea7-5f36-acf1-e95db95cd8c6', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Ushiyoshi Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('212a973a-b6f3-5aa8-b8f3-c5fc0fced322', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Ushiyoshi)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('02c545a1-a7f5-5425-8c91-a3b47a426b03', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Sukiyaki)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_sukiyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9d664a1-1af3-50b2-98dd-039398a47016', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Xốt Muối Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a7186f04-6bb3-5b91-b11f-c682ac9a01af', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('73953959-4f42-5d00-a846-e3a9bc1fc549', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1aa40947-cdce-569b-bc24-41c3065d0d55', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Ushiyoshi)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_ushiyoshi2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b3c05685-8bec-5bc7-87ec-f21b99a7d0b8', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Miso Cay)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('94d92750-8713-58e4-969f-f0f7647297ad', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Sukiyaki)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_sukiyaki2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bcedd790-0172-5adc-8a45-30525956155e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Nguyên Tảng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_whole","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0a867ed0-9034-5111-8504-4e845707f9be', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Diềm Thăn Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_flap","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory offal
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('285f4b12-68f1-564c-920a-1dd45e6bca6f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Đặc Trưng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_special","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c1e6c6b6-0bc2-5632-8c8a-79b14768ed60', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Đặc Trưng 1', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_special_1","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ce28ebfe-03fe-58f0-bfb4-17ce6fd4cdcd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Non Ushiyoshi Xốt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_young_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dd491c0f-9cf0-5502-b55e-8d243da5d81c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Già Ushiyoshi Xốt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_old_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d27edf99-92fc-57fe-9e2b-bc11533099fd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Gan Bò Xốt Đặc Biệt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_liver_special","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('56a8b477-1433-580a-9c2e-348355da74ff', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Non Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_young_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9b3b9ff1-35d3-5ede-bb16-7c7f66205eec', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Già Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_old_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7871b65a-e480-5a4a-aee6-5fd360a8a90c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Gan Bò Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_liver_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d7d80532-1331-528d-8864-91109134d988', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt miso cay', 50000, 'Phần', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5f948c02-a40d-58f3-a302-9d42c9b7f021', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt miso cay', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_miso_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a869031f-2b7a-5f9a-9e8f-513b7c86aa32', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt tare', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_tare","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory pork
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a2c9aa20-6a43-528e-a66b-3c3352b97376', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7287a0fa-afb4-513f-bb63-7950089c62e2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('845da15a-89c7-57d8-af70-e408fdab5a2d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('67e0b863-2d7b-5358-a8e4-e5ca0e919bd2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2c73063f-1705-5aca-948e-8e2b55721705', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ff62bd7c-fb05-5e4e-b4c2-a6f11e18fcb2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Ướp Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory chicken
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c9023045-5785-50e5-a193-aa662198d9ca', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Đùi Gà Vị Muối', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_thigh_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8df54667-0f5f-57e6-aa4b-aa6f5b9a36c7', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Đùi Gà Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_thigh_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bd142585-42bd-585b-8b5f-6575414dc4db', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cổ Gà Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_neck_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('aeea8da6-5f3a-531d-9f20-eebb1862d787', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cổ Gà Ướp Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_neck_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('854fe4d6-6f53-575a-9a77-c44d4546d7ac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cánh Gà Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_wing_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('721ca4cc-3907-5e72-9d1c-1727af6c7041', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cánh Gà Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_wing_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory grill_alacarte
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7fe692f9-f777-5366-96dd-f2080ca4109b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Trứng gà', 120000, 'Phần', '120K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('66de4629-0da2-5514-8b06-52685f730f63', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Rau Củ Nướng Thập Cẩm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_vegetables","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4e5b1ee5-2928-5994-8828-a90b6060decb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Tôm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_shrimp","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8562bcc3-c6c4-5d86-a98f-7bcc857a1d47', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Bạch Tuộc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_octopus","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1e8a598a-9d0f-5d45-98b1-dff96ce65db4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Hải Sản Nướng Giấy Bạc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_seafood_foil","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8e2d1fe8-1240-5a4f-947d-ce644aff1294', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Bắp Nướng Bơ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_corn","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7ca292b5-c422-5331-997e-43363f66bbda', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Khoai Tây Nướng Bơ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_potato","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('05c021f6-1f20-57dd-bebc-c4c7fa65197e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Tỏi Nướng Giấy Bạc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory alacarte
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('68c2fda3-42ae-5072-9973-957cf2c5f597', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cá Ngân Chiên Giòn', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_fish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e0a0342c-0485-5fd8-af67-b2a28790be72', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Tôm Tempura', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_tempura","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3de823b5-9dfe-5243-8bd3-00e6fde7a6fb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Chả Cá Nhật Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fish_cake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fade93d6-3308-5d6c-92d2-8a724a4fb53c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cua Lột Chiên Giòn', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_crab","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0150e57e-9937-52f6-a52b-8423c9cca2e7', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Râu Sò Điệp Trộn Tiêu Tứ Xuyên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_scallop","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('32dc4952-1fa4-52ff-a4d4-6e3db6ce3d96', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cá Trứng Chiên Giòn', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_fish_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a537848d-f271-57c2-b262-5ddc39649a20', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Trứng Hấp Kiểu Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_steamed_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('952a24a6-521c-5d05-ae7c-d8d5d89a1729', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Gà Chiên Nhật Bản', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7e257e6a-be9e-5d3e-b337-54972a3697c3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cánh Gà Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_wing","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9ad80cd-303e-5293-988a-adbdbfdbc172', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Khoai Tây Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fries","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4ea4854d-f247-5b68-aa9d-8140cc9d5646', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Bánh Bạch Tuộc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_takoyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fa280acd-d762-56a6-8010-0e04bd688281', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Bánh Xèo Nhật Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_okonomiyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1ab7958a-e04c-5da2-8e31-2076c27680da', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Há Cảo Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_gyoza","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('77471825-c4ab-5d2e-9169-75af43b65ebe', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Hamburger', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_hamburger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4e088d70-293f-554f-b74d-921902a5fe07', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Trứng Cuộn Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_rolled_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('47be26cc-f1b9-5fc6-9964-a52c506cfe5d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Set Trẻ Em', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_kids_set","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ee06974e-64e4-5328-9cfc-1fe7a83d4c8f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Sushi Bò Wagyu Áp Lửa Hồng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_wagyu_sushi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory appetizer
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4aa87ec7-d159-59f2-9676-38817cf78d63', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Đậu Nành Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('413bd0aa-4317-5f4a-957d-78364c5101ff', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Dưa Leo Trộn Kiểu Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_cucumber","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('becfb846-ff86-572b-af14-e8eac78ff49b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Tổng Hợp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_mix","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a73b0ee3-237b-5008-b6f1-7f92d3d49150', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Cải Thảo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_cabbage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('11f7c01b-23d8-5f80-9b62-86ce5d037760', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Dưa Leo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_cucumber","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f87fe7e6-53bb-551b-a570-fd3c1dd759bb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Củ Cải', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_radish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2d3b85f1-ef05-5cd8-bc69-a4a0e8a026a3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Rau Trộn Hàn Quốc (Tổng Hợp)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_korean_salad","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory salad
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ebde1e52-1571-5529-a20d-f584ecaeb2b1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Ushiyoshi', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e3b8e4ca-28b5-526a-9710-95f9543b7bcf', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Đậu Hũ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('809fa7ce-0d02-577f-8526-c50b0f0cd0db', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Caesar', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_caesar","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('395708a7-0e7e-53f6-b018-16473cd59e89', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Xà lách', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_lettuce","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory rice
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5bef6819-8d63-5e7b-88ef-c3a6f95f0e1e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Bibimbap Thố Đá', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_bibimbap_stone","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2102c2e5-1bf9-5d7a-8071-ac21c80625f1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Bibimbap Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_bibimbap_mini","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('23dbf27e-a18f-57f2-b633-f344fc2877ab', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Chiên Tỏi Thố Đá', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_fried_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5fa3ec07-ce18-5090-ab37-7fb66d0a0052', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Canh Cơm Hàn Quốc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_korean_soup","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1997ee7d-70d0-5cc2-8c52-a34c4bb61079', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Chiên Kimchi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_fried_kimchi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c230201b-a97d-5350-a04e-56d642a08641', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Gân Bò Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_beef_tendon_mini","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4d0f6e8e-260e-5120-a3a6-177ad30d9953', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cà Ri Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_curry","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d0b61419-054f-5775-84f5-ce804580db13', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Ăn Kèm Yakiniku', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_yakiniku","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d13e07a2-ed6e-5111-9851-5fadcca317bf', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Trắng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_white","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory noodle
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f2d793a1-04ab-52ae-af25-9cc81b54fbb0', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Udon Lạnh Goto', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_udon_cold","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1a6a0f93-69f7-527d-ae07-b43d37694c49', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Udon Bò', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_udon_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0f37292a-1d03-5690-9c52-edad9f6dedfd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Xương Ống Hầm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_bone_soup","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab525a39-5e16-50c9-a2bb-02305a1d7e16', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Ramen Xào Bò', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_ramen_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9c63f5e-4045-5256-849c-d0f5a070a6e0', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Ramen Xào Hải Sản', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_ramen_seafood","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0885f096-e4e7-5992-ac69-717c1b6801ab', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Súp Mala Cay Tê', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_mala","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory soup
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('339b040a-d7d4-59a3-96c7-75ffed4928ac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp mala cay tê', 145000, 'Phần', '145K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_mala","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c1912f28-5af7-5b87-9b24-35461bfa8b08', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Phở', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_pho","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('be3d92cf-11dd-5526-86dd-04396f8c99f2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Rong Biển', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_seaweed","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2eba74c5-c873-551c-a678-099e685103b2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Nghêu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_clam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('228a13e5-91b9-524b-8861-c06ace2461c4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Nghêu Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_clam_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('307b0bf0-a965-531e-8c0f-fd89716f488b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('84632bea-e71d-5159-a4f2-c1aa7d4c8d91', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Chua Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_sour_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory dessert
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7a015f09-ab68-564d-a796-15ccd1c0091a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8afc01e9-b29a-5b68-8988-c6845f6de07b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani Sốt Dâu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla_strawberry","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fb42ab70-89b3-5eb2-a93e-bd55502dff21', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani Sốt Socola', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla_chocolate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f5341af-8f57-5faf-85fb-64c6762cbfb3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Matcha', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_matcha","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9aa73e55-e219-566f-a324-d263a757e20c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Chanh Yuzu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_yuzu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49698d2f-ce3f-5689-b55a-a542e8fcb6b4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Nho', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_grape","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('664e3243-4835-5bec-96a2-bde8855a0c28', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Bông Lan Phô Mai Trứng Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_cheesecake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8de1af0f-cb42-57bd-add9-df269457f5c1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Cá Nhân Đậu Đỏ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_fish_cake_bean","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6d28378e-6ba4-521d-8efa-df5d2d89f742', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Cá Nhân Kem Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_fish_cake_cream","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8c1af3fd-6924-5a89-8810-baaa383f6270', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Dorayaki Đậu Đỏ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_dorayaki_bean","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6e0cbe7d-29ca-54fe-95a6-21f6fd0de966', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Dorayaki Kem Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_dorayaki_cream","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a7fe0ca4-7d4d-5359-b301-16b9309e4357', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Su Kem', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_cream_puff","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d0a70d5f-1150-5a8c-941c-c677fff09876', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Chuối Nướng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_banana","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('972bfef8-b033-5542-a889-22d4e55079c5', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Gateau Sô-cô-la', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_chocolate_gateau","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory sauce
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('83eb8390-504f-52d7-a811-5e5d7732dbe8', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'Xốt Bơ Tỏi Xì Dầu', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sauce_butter_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('16c7e74d-1bf0-52fa-bd24-be55812e281e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'Xốt Phô Mai Nóng Chảy', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sauce_cheese","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory sukiyaki
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cbfb66b8-6c9d-5242-b112-f019138947ef', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đĩa rau thập cẩm (Phần cho 2 người)', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f898a1ec-f87f-54c3-83d3-788aee617428', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đĩa rau thập cẩm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bb7c209e-29fd-5570-aa2b-b3f7932a832f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Mì Udon', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_udon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('556f9176-d50f-5ed6-b91b-e3cfca146395', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm đùi gà', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_eryngii","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('95d5645d-bf7d-51d9-b1aa-5865cdd81fdd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm hương', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_shiitake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('445381f4-33b0-5617-a71c-5cd679a4cf18', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm kim châm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_enoki_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ebb63232-0abd-5347-8241-46fd95dc4b54', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Rau củ và nấm thập cẩm (Phần cho 2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_mix_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9fdb972a-99d5-57dc-a40f-7551ce0794f1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Rau củ và nấm thập cẩm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_mix_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('80f70ee0-b059-51f4-9a41-5e3349ed4e21', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Trứng gà', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b5a18469-159d-5c8a-a52b-c1779232deac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Các loại nấm (Phần cho 2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_mushroom_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('68240bab-2d9d-51b2-bb42-15b43f117589', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Các loại nấm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_mushroom_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ec204c25-42c7-5843-8ca2-73fa6054a725', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cải thảo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_cabbage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9c1cf90-aa7e-5829-ac6f-5b468b504d98', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cải thìa', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_bok_choy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3f78102c-6420-5cfd-bc10-f3dba49b01dc', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cơm trắng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_rice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f0a20c04-4e6f-5fff-8140-c9bf06ab139a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đậu hũ chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_fried_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d3b19c89-97e3-5a3d-95b8-e99b01e07b8a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đậu hũ non', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_silken_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6b0e89c2-0523-58f5-975a-1c65bdf3bf6f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Thịt bò dùng cho lẩu Shabu-Shabu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('04c96cc8-0d47-5912-999e-398a3aa2329c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nước lẩu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_broth","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Thức Uống', 115, true, '{"fe_id":"thuc_uong"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_uong
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('96ceb6f0-22fb-5415-81d6-430112cc279d', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Soft drink', 0, true, '{"fe_id":"soft_drink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'NON ALCOHOLIC', 1, true, '{"fe_id":"non_alcoholic"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('d56d911a-f8d3-5701-ae7d-e320aa2a0bb7', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Tea', 2, true, '{"fe_id":"tea"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('acf426e4-de38-543e-a56d-90e930969619', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Đồ uống – Set', 3, true, '{"fe_id":"drink_set"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory soft_drink
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('544421c1-b60d-52e2-a248-d0b999f2ca72', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Đào', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_peach_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('534bb1e9-fdec-54a0-88f3-7ce552c4e8b5', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Vải', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_lychee_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fecb2d65-a3f6-580b-b3c0-0cc7882026bd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Cam', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_orange_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ae484f76-f3fb-5079-b309-b28500433657', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Ép Táo', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_apple_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ff2ead0a-e848-55a0-9cd9-c9f96ada0584', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Ép Trái Cây Tổng Hợp', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_mixed_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5ab14b61-0f54-5306-af61-ddc22323d588', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Coca-Cola', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_coca","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4daa7511-7ccc-50c9-8417-d8a5a5a385d8', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Trân Châu', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_bubble_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a5ad02a7-691d-5bb6-9455-f4fe2a2e57d5', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Coca-Cola Zero', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_coca_zero","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('116adc3f-1806-5876-a426-7302695d7bec', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Thái Xanh', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_thai_green_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cd9248ec-6528-5261-a0e8-0d661d3c78bb', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', '7UP', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_7up","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ac97f456-3f6d-5eb2-82c2-8bc72c8685fa', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Thái Đỏ', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_thai_red_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('caa41a0b-7bd6-5e78-a6d0-fd6932f86ca9', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Soda', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7ef8edbf-bf28-5701-84e3-799916f7cbdd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Lài', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_jasmine_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('56e33116-9236-5f67-93e4-2734dbbbece9', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Suối', 25000, 'Chai', '25K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_water","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory non_alcoholic
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('adf43cdc-1509-5e8d-8d2f-f81d084d9b55', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Nước chanh xanh biển', 80000, 'Ly', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_green_lemon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5449a3ec-c7e2-5e4a-9763-19ac6f11057b', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Chanh Vải', 78000, 'Ly', '78K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_lychee","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f25ae630-675c-5e77-8332-1fa426672b17', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Cassis Nho', 108000, 'Ly', '108K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_cassis","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f8ef6ff-f88b-5e7c-8299-212a6bd3d6e7', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Dứa Chanh Dây', 78000, 'Ly', '78K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_pineapple","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory tea
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('206e190d-2f8a-5dfb-a56c-40586d37394f', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Xanh Nhật Bản', 80000, 'Ly', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_green_japan","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('decff9b9-ccb2-510a-a6f1-7dd21e864809', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Đào', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('697a6b15-a18d-5ef0-b266-b84d2fc4f512', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Vải', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_lychee","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory drink_set
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e4a673d7-04c0-501e-a4a7-abc31d83585c', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', '7UP', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_7up","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7a1bce5e-1c32-5b89-9c25-f5d5773d4a9d', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Coca-Cola', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_coca","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e422fa9c-5302-56bc-9ff5-9896fcfdebfd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Coca-Cola Zero', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_coca_zero","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5482b8f9-4d38-5ffe-8bc0-20e16b5c76b2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Cam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_orange","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c58196de-3276-5d0f-9958-3795b3c6b864', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Ép Táo', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_apple","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('92f0dce5-2baa-58f5-b792-ebaa7d41fc30', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Ép Trái Cây Tổng Hợp', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_mixed_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c94cfa9d-9ddf-5ff2-81e8-e05d60ec34a2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Suối', 0, 'Chai', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_water","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2d607663-9702-5080-910f-f6b9f8cc7c39', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Lài', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_jasmine_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('20b092c2-7124-50f9-bd31-dd62f50e37fe', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Soda', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('de7fcfa7-d983-59b3-97a6-b7bd8f589d8d', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Thái Đỏ', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_thai_red","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('13fee4fd-0abf-5194-9f13-12ef6008d4b2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Thái Xanh', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_thai_green","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('afd7474c-e7db-5696-a168-c7aef4f81dc6', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Trân Châu', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_bubble_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Thức Uống Có Cồn', 116, true, '{"fe_id":"thuc_uong_co_con"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_uong_co_con
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4c88869f-e3e9-5b45-be56-6b624fad3182', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Bia', 0, true, '{"fe_id":"beer"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Whisky', 1, true, '{"fe_id":"whisky"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Shochu', 2, true, '{"fe_id":"shochu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('52790926-f71b-5e3a-b7fd-6a128737a3c0', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Nihonshuu', 3, true, '{"fe_id":"nihonshuu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('f182c2e3-67b8-5757-b6af-95e7567fed21', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Wine', 4, true, '{"fe_id":"wine"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('6edb3670-30bb-5398-9485-87cf86cb2a6a', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Đồ uống có cồn – Set', 5, true, '{"fe_id":"alcohol_set"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beer
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8c0f33aa-4293-5709-8f8d-fe794cd80722', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4c88869f-e3e9-5b45-be56-6b624fad3182', 'Bia Tươi Sapporo', 178000, 'Ly', '178K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beer_sapporo","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5fd1782b-4043-5b4a-b922-ea42bd05b1aa', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4c88869f-e3e9-5b45-be56-6b624fad3182', 'Bia Tiger', 55000, 'Lon', '55K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beer_tiger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory whisky
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f51416e5-92ca-5625-967f-1a8792382f09', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'Rượu Jim Beam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"whisky_jim_beam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6cef9f6-77fa-5117-a398-d04dea5c6ade', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'Rượu Suntory Kaku', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"whisky_suntory","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory shochu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d796dd6f-4373-5a14-8f09-edf736f09b66', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Kuro Kurishima Bottle', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_kuro_kirishima_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49a186b6-87ca-57a9-a265-259095e2daa7', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Sâm Cau Việt Nam', 1000000, 'Lọ', '1.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_sam_cau","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5257b5c8-ba94-5a4b-87f0-dbf23e6b5c13', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Lemon Soda', 90000, 'Ly', '90K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_lemon_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8400de4a-6986-5c2c-add2-b56858186e1a', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Mơ', 86000, 'Ly', '86K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_plum","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dcba0d42-d121-52b6-83dc-99631f466e88', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Chuhai Đào Fukushima', 119000, 'Ly', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_chuhai_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('52ec327a-9f17-5da5-b0fc-b0ea6a19a862', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Chuhai Quýt Arita', 119000, 'Ly', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_chuhai_tangerine","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a81a7dc1-24e8-5bc7-b8a1-215f2c8207a3', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu iichiko', 98000, 'Ly', '98K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_iichiko","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('847a9359-6036-5662-a894-7a08caccfdbe', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Kuro Kirishima', 98000, 'Ly', '98K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_kuro_kirishima_glass","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory nihonshuu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ae3fb2f9-cef5-5a43-bdc0-4c430c13ecae', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Awayuki Sparkling Sake', 450000, 'Chai', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_awayuki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('43c6d95f-06e5-527e-ab40-6e534019c8da', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Kijuro (喜十郎)', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_kijuro","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('762003b3-4367-55b1-bc89-16861af98628', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Dassai (獺祭)', 890000, 'Chai', '890K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_dassai","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('33713e7a-3033-521d-82c4-b38f6c13e63b', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Nabeshima (鍋島)', 2000000, 'Chai', '2.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_nabeshima","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory wine
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f0a98b7a-5abe-5f43-ba92-d823fd806099', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Mussel Bay (chai)', 880000, 'Chai', '880K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_mussel_bay_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('64259f3a-fd36-5deb-aa80-f57c8de3c41e', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Mussel Bay/white', 150000, 'Ly', '150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_mussel_bay_white","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0b64f762-046d-51bb-8b16-f72b28814c99', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Michel Lynch (chai)', 880000, 'Chai', '880K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_michel_lynch_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5afe42e6-a0da-51ec-9f72-424cdb13cea7', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Michel Lynch/red', 150000, 'Ly', '150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_michel_lynch_red","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0f5cfe34-9763-5751-a296-1369de65b818', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Champagne Bollinger Special Cuvée', 4000000, 'Chai', '4.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_bollinger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0e719943-f4ac-52c1-b467-e07cc8862315', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Parallèle 45 Côtes du Rhône PJA/white', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_parallel_45","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bb7816b5-18f8-5398-a965-f01b78a8b1bf', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Chablis – Courtault Michelet/white', 2300000, 'Chai', '2.300K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_chablis","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c87d5306-644c-5623-a895-24e2b15c1e8b', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Logan Weemala/red', 1180000, 'Chai', '1.180K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_logan","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('41a82df1-b864-536d-9e7c-c6acffdfc8ca', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'La Posta Fazzio/red', 1380000, 'Chai', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_la_posta","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bc18f965-8032-5fc2-a3ca-86239e2788ac', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Château Haut-Cadet Saint-Émilion Grand Cru/red', 2500000, 'Chai', '2.500K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_haut_cadet","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d74bc353-efa2-5799-b92d-d7b7cffa6691', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Côte de Nuits Villages – Lou Dumont/red', 3800000, 'Chai', '3.800K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_cote_nuits","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory alcohol_set
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dd0942aa-7ae1-58be-b3fe-e56348fe3b26', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu iichiko', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_iichiko","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f5b7bc4a-e888-5301-95ac-f275629db1b5', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Jim Beam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_jim_beam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1bc3b983-5c14-5547-ab16-99d1aed964cc', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Suntory Kaku', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_suntory","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f1616018-f27f-5cdb-98a2-b08390a8e03c', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Chuhai Đào Fukushima', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_chuhai_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8e844212-f595-5f6b-9ed9-ec13addf8d0e', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Chuhai Quýt Arita', 0, 'Lọ', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_chuhai_tangerine","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('50af49c2-a738-5617-a973-b2f2f0225a01', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Lemon Soda Liqueur', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lemon_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b6b3f2ab-c43b-51d4-8771-91df649080d6', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Mơ', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_plum","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6d121514-f493-56cb-b011-c63953adba03', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Bia Tiger', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2034d9d2-5435-507b-b94d-d547d134274a', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Bia Tươi Sapporo', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_sapporo","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d3bd9778-36eb-5aaf-9ba0-a78392592252', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Kuro Kirishima', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_kuro_kirishima","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Khác', 117, true, '{"fe_id":"khac"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category khac
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0e336964-491c-5c77-87ee-b02be449443a', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Phục vụ', 0, true, '{"fe_id":"service"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Gia Vị', 1, true, '{"fe_id":"condiment"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('980e540c-2ab7-546b-8eff-e4b70d367afc', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'PHÍ PHỤ THU', 2, true, '{"fe_id":"surcharge"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory service
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('881ec138-de8b-5a24-9386-15c902347004', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Chén', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_bowl","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ccdf50e1-4a7a-52e7-9040-d719ee7987ec', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Đĩa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d8eff0e0-1bc2-591b-82c5-a72a4b95d41e', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Đĩa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_plate_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('32752b39-3129-50b5-aa44-6e679c40d76d', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Khăn giấy lau', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tissue","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2f4be945-d9cf-5463-ab16-964ce17448d0', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Khăn giấy lau', 0, 'hộp', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tissue_box","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cd33c2cf-a7dc-5e9e-b933-ae0ffa0fe938', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kéo', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_scissors","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e7a31d03-cb54-5a87-a71f-06681a59a2aa', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kéo', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_scissors_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c4cb8fb2-1a88-549c-b6a7-4e3d2aebaae3', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kẹp Gắp', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tongs","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cee85c91-8dc8-5632-addc-ebd0a6e0d98c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kẹp Gắp', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tongs_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f6dc9659-e2c5-50ac-b01e-67e233897c0a', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muôi Múc Canh', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_ladle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f250fe45-1b58-53cc-a670-c3e090629a77', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muôi Múc Canh', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_ladle_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1013d22f-b325-5fe4-a90f-28b201f32201', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muỗng', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f2ba48bb-1eb8-5073-9a2e-45da92e6467b', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Thìa Desert', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_dessert_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9d7c2c8f-53dd-5eeb-87b3-23bbcc44ba8c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Thìa Desert', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_dessert_spoon_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('50cca2a9-80f4-5faa-8e06-eb494215f686', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Nĩa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_fork","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3fe7c404-3bb5-5f85-9431-74e03e549f19', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Nĩa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_fork_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6755873-93f3-501b-9f21-1153e2bfb639', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Tạp dề giấy', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_apron","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49e5c399-6f64-5a43-8af4-74a35c467117', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Đũa', 0, 'đôi', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_chopsticks","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6cb6cd8a-f23a-5838-9b69-82c1fdaa0c25', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Đũa', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_chopsticks_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d020ba4e-67bc-5535-a451-92f227eae901', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Khăn', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_towel","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1e5e3d55-e3e4-51cf-94ce-df85b97b6568', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Khăn', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_towel_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dacb9617-d60c-5c49-ae45-c95ccef20bce', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Than', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_charcoal","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e9e9deef-9da7-5f0c-b576-448a81b744e9', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Than', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_charcoal_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0146fb04-eac5-5147-8a19-107b5ab21e2b', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Vỉ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_grill_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b9eb11fd-ccf0-5f73-91ab-f3e91eb8fc0d', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Vỉ', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_grill_plate_piece","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9a47fc7d-8292-51ac-ae95-04271b4e6b2e', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thêm Đĩa (Đĩa Thường)', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_extra_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c258d5a0-8721-5150-a1f1-c40fd9ce7b2a', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thêm Đĩa (Đĩa Thường)', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_extra_plate_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('15d68dd6-0c46-57b9-8aa9-8d94eb6564e4', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thìa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2a590433-2108-5b98-90f5-cbaa62a1beb5', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thìa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_spoon_piece","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory condiment
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('db98c6b8-59f8-512f-8b0d-1f2ace494189', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Chanh', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_lemon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9861bab9-2bf8-5d42-8f72-4067ee2690da', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Hành lá nhỏ', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_green_onion","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b09892e9-ba6a-55e9-ae5e-7f1d8e2958fd', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Mù Tạt', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_mustard","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('506e4c35-f858-5174-91ad-6bd331e825a3', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Muối', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fb298968-6cbb-5152-91c0-d2db9b89c677', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Ớt Xắt', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_chili","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8a460eb7-c1bb-5dab-a275-80949a9a4a27', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Sốt chấm', 0, 'Đĩa', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_dipping_sauce","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a8548ae7-84fc-5f59-8429-3d8d6c55afc5', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Sốt chấm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_dipping_sauce_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4bab8f0a-cd72-5646-a2d9-1d7332950296', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Tỏi Băm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory surcharge
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c04d21e5-a79b-5787-b7d1-10c4e052631c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '980e540c-2ab7-546b-8eff-e4b70d367afc', 'Phí phụ thu mang rượu', 400000, 'Chai', '400K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"surcharge_corkage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('99c36f6e-5f76-516e-9a2c-ba021e92b5bc', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '980e540c-2ab7-546b-8eff-e4b70d367afc', 'Phí phụ thu thức ăn thừa', 500, 'gram', '50K/100g', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"surcharge_leftover","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- Verification query (commented out — run manually to confirm):
-- SELECT count(*) AS categories FROM public.menu_categories;
-- SELECT count(*) AS subcategories FROM public.menu_subcategories;
-- SELECT count(*) AS items FROM public.menu_items;

-- ==========================================
-- FILE: 20260625200000_fix_jwt_helpers_read_app_metadata.sql
-- ==========================================
-- =============================================================================
-- 20260625200000_fix_jwt_helpers_read_app_metadata.sql
--
-- Bug audit (senior full-stack review 2026-06-25):
--
-- The custom_access_token_hook (20260625080844 / 20260625100000) writes the
-- `role` and `branch_id` into `claims.app_metadata` — that's the only place
-- Supabase signs into the JWT. But the SQL helpers `current_branch_id()`,
-- `current_user_role()`, and `has_role()` were reading the top-level
-- `claims->>'role'` / `claims->>'branch_id'`. Those keys never exist, so
-- every helper was silently returning NULL → RLS saw "no branch match" →
-- the audit trigger inserted branch_id=NULL → 400 on every write.
--
-- This migration rewrites the three helpers to read
--   claims -> 'app_metadata' ->> 'role'
--   claims -> 'app_metadata' ->> 'branch_id'
-- (with a back-compat fallback to the top-level key for older JWTs that may
-- still be in circulation from before the hook was wired up), then falls
-- back to a `public.users` lookup so RLS keeps working when the hook is
-- temporarily broken or hasn't fired yet.
--
-- Idempotent: `create or replace`. Safe to re-run.
-- =============================================================================

create or replace function public.current_branch_id()
returns uuid
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Prefer JWT claim (set by the custom_access_token_hook), fall back to DB.
  -- Order:
  --   1. claims.app_metadata.branch_id      (new — what the hook actually writes)
  --   2. claims.branch_id                   (legacy, in case old JWT still in flight)
  --   3. public.users.branch_id             (final fallback)
  select coalesce(
    nullif(
      coalesce(
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'branch_id'),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'branch_id')
      ),
      ''
    )::uuid,
    (select branch_id from public.users where id = auth.uid())
  );
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Whitelist the role claim against the user_role enum BEFORE casting, to
  -- avoid 22P02 when the JWT carries a PostgREST role like 'anon' /
  -- 'authenticated' / 'service_role' (those are not in our enum).
  select coalesce(
    case
      when coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           ) in ('admin','manager','reception','staff','kitchen')
      then (coalesce(
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role'),
             (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
           )::public.user_role)
    end,
    (select role from public.users where id = auth.uid())
  );
$$;

create or replace function public.has_role(roles public.user_role[])
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  -- Delegate to current_user_role() so the whitelist logic stays in one place.
  select case
    when (select public.current_user_role()) is null then false
    else (select public.current_user_role()) = any(roles)
  end;
$$;

-- =============================================================================
-- Grants — these helpers are called from RLS policies and triggers, which
-- run as the table owner. They need to be executable by the relevant DB roles.
-- =============================================================================

revoke execute on function public.current_branch_id()    from public;
revoke execute on function public.current_user_role()    from public;
revoke execute on function public.has_role(public.user_role[]) from public;

grant execute on function public.current_branch_id()    to anon, authenticated, service_role;
grant execute on function public.current_user_role()    to anon, authenticated, service_role;
grant execute on function public.has_role(public.user_role[]) to anon, authenticated, service_role;


-- ==========================================
-- FILE: 20260625200100_explicit_table_grants.sql
-- ==========================================
-- =============================================================================
-- 20260625200100_explicit_table_grants.sql
--
-- As of 2026-05-30, new Supabase projects no longer auto-grant table access
-- to `anon` / `authenticated` / `service_role`. Tables come locked down by
-- default and you have to opt in explicitly. Without these grants, every
-- supabase-js query from the frontend returns 403 (PGRST301) even when RLS
-- would otherwise allow the row.
--
-- This migration grants the access patterns the Vue app actually needs:
--   anon            → SELECT only on the few tables the tablet menu uses
--                     (menu_categories, menu_items, branches)
--   authenticated   → CRUD on the rest, except audit_events / users which
--                     are write-protected (only service_role / triggers write)
--   service_role    → full CRUD on everything (used by Edge Functions with
--                     the service-role key)
--
-- RLS stays enabled everywhere. Grants control WHO CAN ISSUE the query;
-- RLS controls WHICH ROWS they see. They're complementary, not redundant.
--
-- Idempotent — `grant ... to ...` is a no-op if the grant already exists.
-- =============================================================================

-- ─── anon (guest tablet, unauthenticated) ────────────────────────────────────
-- Tablet reads menu + branch info without logging in.
grant select on public.menu_categories to anon;
grant select on public.menu_items     to anon;
grant select on public.branches       to anon;

-- ─── authenticated (logged-in staff) ────────────────────────────────────────
-- Read-only reference data
grant select on public.branches,
                public.branch_settings,
                public.menu_categories,
                public.menu_items,
                public.packages,
                public.tables,
                public.users
            to authenticated;

-- Operational CRUD
grant select, insert, update, delete on public.customers         to authenticated;
grant select, insert, update, delete on public.reservations      to authenticated;
grant select, insert, update, delete on public.orders            to authenticated;
grant select, insert, update, delete on public.order_items       to authenticated;
grant select, insert, update, delete on public.payments          to authenticated;
grant select, insert, update, delete on public.invoices          to authenticated;
grant select, insert, update, delete on public.shifts            to authenticated;
grant select, insert, update, delete on public.table_assignments to authenticated;
grant select, insert, update, delete on public.notifications     to authenticated;

-- audit_events is INSERT-ONLY from authenticated (RLS USING with check),
-- but the practical pattern is that the audit TRIGGER inserts on their
-- behalf — so we only need the trigger to have access (it runs as table
-- owner) and admins/managers to read. Leave the grant select-only.
grant select on public.audit_events to authenticated;

-- ─── service_role (Edge Functions) ──────────────────────────────────────────
-- Edge Functions use the service-role key and need unrestricted access.
-- RLS is bypassed for service_role by design.
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;


-- ==========================================
-- FILE: 20260625200200_auth_trigger_no_metadata_decisions.sql
-- ==========================================
-- =============================================================================
-- 20260625200200_auth_trigger_no_metadata_decisions.sql
--
-- Senior security review (2026-06-25):
--
-- The handle_new_auth_user() trigger was reading role and branch_id out of
-- auth.users.raw_user_meta_data. raw_user_meta_data is the same source as
-- user_metadata — set on the auth.users row and editable by the user via
-- auth.updateUser() (when called via the anon-key client). Reading role /
-- branch_id from there means a signed-in user can self-promote to admin
-- and set their own branch. That violates the senior security rule
-- "never use user_metadata / raw_user_meta_data for authorization or
-- branch/role decisions".
--
-- The previous trigger ALSO created a race: admin-user-manager calls
-- auth.admin.createUser() (trigger fires, inserts with role from
-- raw_user_meta_data — usually NULL → defaulted to 'staff'), THEN tries
-- to INSERT into public.users with the real role/branch_id. The second
-- INSERT hit the primary-key UNIQUE constraint and the trigger's
-- `on conflict do nothing` silently dropped the intended role.
--
-- This migration rewrites the trigger to:
--
--   1. Only mirror identity (id, email, full_name) from raw_user_meta_data.
--      full_name is the only field it's reasonable to read there because
--      it isn't used for authorization — it's just a display label.
--   2. NOT derive role or branch_id from raw_user_meta_data. They default
--      to NULL/''staff'' and MUST be set explicitly by an admin-controlled
--      path (the admin-user-manager Edge Function, or a manual UPDATE).
--
-- admin-user-manager is updated separately to handle the case where the
-- trigger already inserted a default row: it now uses UPSERT so the
-- caller-supplied role/branch_id always wins.
--
-- Idempotent: `create or replace`. Safe to re-run.
-- =============================================================================

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_full_name text;
begin
  -- full_name is the ONLY field we read from raw_user_meta_data — and
  -- only because it isn't used for authorization, only as a display
  -- label. Fallback to the local-part of the email so the row is never
  -- fully empty.
  v_full_name := coalesce(
    nullif(new.raw_user_meta_data->>'full_name', ''),
    split_part(new.email, '@', 1)
  );

  -- role defaults to 'staff' (the safest least-privilege choice) and
  -- branch_id defaults to NULL. Both MUST be set by an admin-controlled
  -- operation before this account can do anything privileged — the
  -- RLS policies key on current_user_role() / current_branch_id()
  -- and both return NULL/safe values until then.
  insert into public.users (id, email, full_name, role, branch_id, is_active)
  values (new.id, new.email, v_full_name, 'staff'::public.user_role, null, true)
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Permissions: only Supabase Auth internals may invoke directly. `auth` is a
-- schema, not a database role; local shadow databases provide
-- `supabase_auth_admin` for GoTrue/Auth-owned operations.
revoke execute on function public.handle_new_auth_user() from public;
grant execute on function public.handle_new_auth_user() to supabase_auth_admin;


-- ==========================================
-- FILE: 20260625200300_rls_add_with_check_clauses.sql
-- ==========================================
-- =============================================================================
-- 20260625200300_rls_add_with_check_clauses.sql
--
-- Senior security review (2026-06-25):
--
-- Every `*_branch_write` policy in 20260623000000_setup.sql uses
--   for all using (branch_id = public.current_branch_id() and …)
-- without a WITH CHECK clause. Postgres semantics:
--
--   * SELECT  → USING applies (you see only matching rows)
--   * INSERT  → no constraint at all (you can insert ANY branch_id!)
--   * UPDATE  → USING applies to the OLD row (so you can only target rows
--               in your branch) BUT there's no check on the NEW row, so
--               you can SET branch_id = 'other-branch' on your own row
--               and effectively move it cross-branch.
--   * DELETE  → USING applies (you can only delete your branch's rows)
--
-- The USING clause is necessary but NOT sufficient for write paths. This
-- migration drops every *_branch_write / *_admin_write policy and recreates
-- them as separate per-command policies with explicit WITH CHECK.
--
-- Defence-in-depth rule we follow:
--   SELECT  → USING matches branch_id
--   INSERT  → WITH CHECK branch_id = current_branch_id() AND role allowed
--   UPDATE  → USING branch_id = current_branch_id() AND role allowed
--             WITH CHECK branch_id = current_branch_id() AND role allowed
--   DELETE  → USING branch_id = current_branch_id() AND role allowed
--
-- Idempotent: drop-if-exists + create. Safe to re-run.
-- =============================================================================

-- Helper: drop policy if it exists (Postgres has no IF EXISTS for policies
-- before 15, but we can wrap in DO blocks). Use DO for safety.
do $$
declare
  pol record;
begin
  for pol in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and policyname in (
        'users_admin_all',
        'zones_branch_write',
        'tables_branch_write',
        'customers_branch_write',
        'menu_categories_branch_write',
        'menu_items_branch_write',
        'packages_branch_write',
        'package_items_branch_write',
        'shifts_branch_write',
        'table_assignments_branch_write',
        'orders_branch_write',
        'order_items_branch_write',
        'invoices_branch_write',
        'payments_branch_write',
        'vouchers_admin_write',
        'deposits_branch_write',
        'kpi_targets_admin_write',
        'marketing_costs_admin_write',
        'branch_settings_admin_write'
      )
  loop
    execute format('drop policy %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end$$;

-- ----- users (admin only) -----
create policy "users_admin_all" on public.users
  for all using (public.has_role(array['admin']::user_role[]))
            with check (public.has_role(array['admin']::user_role[]));

-- ----- zones -----
create policy "zones_branch_write" on public.zones
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- tables -----
create policy "tables_branch_write" on public.tables
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- customers -----
create policy "customers_branch_write" on public.customers
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- menu_categories -----
create policy "menu_categories_branch_write" on public.menu_categories
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- menu_items -----
create policy "menu_items_branch_write" on public.menu_items
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- packages -----
create policy "packages_branch_write" on public.packages
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- package_items (derive branch via parent package) -----
create policy "package_items_branch_write" on public.package_items
  for all using (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ))
  with check (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ));

-- ----- shifts -----
create policy "shifts_branch_write" on public.shifts
  for all using (
    branch_id = public.current_branch_id()
    and (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  )
  with check (
    branch_id = public.current_branch_id()
    and (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  );

-- ----- table_assignments -----
create policy "table_assignments_branch_write" on public.table_assignments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- orders -----
create policy "orders_branch_write" on public.orders
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- order_items -----
create policy "order_items_branch_write" on public.order_items
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  );

-- ----- invoices -----
create policy "invoices_branch_write" on public.invoices
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- payments -----
create policy "payments_branch_write" on public.payments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- vouchers (admin/manager write) -----
create policy "vouchers_admin_write" on public.vouchers
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- deposits -----
create policy "deposits_branch_write" on public.deposits
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- kpi_targets (admin/manager write) -----
create policy "kpi_targets_admin_write" on public.kpi_targets
  for all using (public.has_role(array['admin','manager']::user_role[]))
            with check (public.has_role(array['admin','manager']::user_role[]));

-- ----- marketing_costs (admin/manager write) -----
create policy "marketing_costs_admin_write" on public.marketing_costs
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- branch_settings (admin/manager write) -----
create policy "branch_settings_admin_write" on public.branch_settings
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );


-- ==========================================
-- FILE: 20260625210000_seed_zones_and_tables_full.sql
-- ==========================================
-- =============================================================================
-- 20260625210000_seed_zones_and_tables_full.sql
--
-- Seed a full restaurant floor plan (zones + tables) for both B001
-- (Ngưu Cát Quận 1) and B002 (Ngưu Cát Phú Nhuận).
--
-- Original seed (20260623000000_setup.sql §11.2-11.3) only created 5 zones
-- (with the " - VIP / Sân Vườn / Tầng 2 / Phòng Riêng / Terrace" suffixes)
-- and 5 tables for B001 (3 in Khu A, 2 in Khu B) and zero zones/tables for
-- B002. The AdminFloorsView UI is built around a 10-zone, ~57-table layout
-- (Khu A, B, C, R, T + 5 delivery-app zones: Capichi, Shopee, BE, Grab,
-- Catalog — short display names that match the Pinia store's mock data).
--
-- This migration is idempotent:
--   * zones: insert only if (branch_id, name) doesn't already exist
--   * tables: on conflict (branch_id, code) do nothing
--
-- Notes:
--   * zone.color uses Tailwind hex so AdminFloorsView's zone dropdown chips
--     and the optional canvas-based FloorPlanView render the same hue.
--   * table.shape is one of ('round','square','rectangle') per the schema
--     check constraint. VIP rooms = round, banquet = rectangle, ban công =
--     square, delivery 'bàn' = square (capacity 1).
--   * pos_x / pos_y are seeded so the optional canvas floor plan renders
--     sensibly. AdminFloorsView uses CSS grid so these are only consumed
--     if you switch to absolute positioning later.
--   * status defaults to 'available'; an admin can flip a table to
--     'maintenance' via the existing AdminFloorsView edit-mode UI.
-- =============================================================================

-- ----- Zones for B001 -----
insert into public.zones (branch_id, name, color, sort_order, is_active)
select b.id, z.name, z.color, z.sort_order, true
from public.branches b
cross join (values
  ('Khu A',           '#F59E0B', 1),
  ('Khu B',           '#A855F7', 2),
  ('Khu C',           '#10B981', 3),
  ('Khu R',           '#EF4444', 4),
  ('Khu T',           '#3B82F6', 5),
  ('Khu Capichi',     '#EC4899', 6),
  ('Khu Shopee',      '#F97316', 7),
  ('Khu BE',          '#06B6D4', 8),
  ('Khu Grab',        '#22C55E', 9),
  ('Khu Catalog',     '#6B7280', 10)
) as z(name, color, sort_order)
where b.code = 'B001'
  and not exists (
    select 1 from public.zones zx
    where zx.branch_id = b.id and zx.name = z.name
  );

-- ----- Zones for B002 -----
insert into public.zones (branch_id, name, color, sort_order, is_active)
select b.id, z.name, z.color, z.sort_order, true
from public.branches b
cross join (values
  ('Khu A',           '#F59E0B', 1),
  ('Khu B',           '#A855F7', 2),
  ('Khu C',           '#10B981', 3),
  ('Khu R',           '#EF4444', 4),
  ('Khu T',           '#3B82F6', 5),
  ('Khu Capichi',     '#EC4899', 6),
  ('Khu Shopee',      '#F97316', 7),
  ('Khu BE',          '#06B6D4', 8),
  ('Khu Grab',        '#22C55E', 9),
  ('Khu Catalog',     '#6B7280', 10)
) as z(name, color, sort_order)
where b.code = 'B002'
  and not exists (
    select 1 from public.zones zx
    where zx.branch_id = b.id and zx.name = z.name
  );

-- ----- Tables for B001 -----
-- Resolve zone_id by (branch_id, zone.name) so the insert is robust to
-- the zones table's auto-generated PKs.
with
  z as (
    select z.id, z.branch_id, z.name
    from public.zones z
    join public.branches b on b.id = z.branch_id and b.code = 'B001'
  )
insert into public.tables (branch_id, zone_id, code, capacity, shape, pos_x, pos_y, status, is_active)
select
  z.branch_id,
  z.id,
  t.code, t.capacity, t.shape, t.pos_x, t.pos_y, 'available', true
from z, (values
  -- Khu A (9 bàn, 4-8 khách) - "Khu chính trong nhà"
  ('Khu A', 'A01', 4, 'round',     1,  1),
  ('Khu A', 'A02', 4, 'round',     2,  1),
  ('Khu A', 'A03', 6, 'round',     3,  1),
  ('Khu A', 'A04', 6, 'round',     4,  1),
  ('Khu A', 'A05', 4, 'round',     1,  2),
  ('Khu A', 'A06', 4, 'round',     2,  2),
  ('Khu A', 'A07', 4, 'round',     3,  2),
  ('Khu A', 'A08', 8, 'rectangle', 4,  2),
  ('Khu A', 'A09', 4, 'round',     1,  3),
  -- Khu B (3 bàn VIP, 8-10 khách) - "Khu VIP trong nhà"
  ('Khu B', 'B01', 10, 'round',    1,  1),
  ('Khu B', 'B02', 8,  'round',    2,  1),
  ('Khu B', 'B03', 10, 'round',    3,  1),
  -- Khu C (8 bàn, 2-4 khách) - "Ban công ngoài trời"
  ('Khu C', 'C01', 2, 'square', 1, 1),
  ('Khu C', 'C02', 2, 'square', 2, 1),
  ('Khu C', 'C03', 4, 'square', 3, 1),
  ('Khu C', 'C04', 4, 'square', 4, 1),
  ('Khu C', 'C05', 2, 'square', 1, 2),
  ('Khu C', 'C06', 4, 'square', 2, 2),
  ('Khu C', 'C07', 2, 'square', 3, 2),
  ('Khu C', 'C08', 4, 'square', 4, 2),
  -- Khu R (8 phòng riêng, 6-12 khách)
  ('Khu R', 'R01', 6,  'round',     1, 1),
  ('Khu R', 'R02', 6,  'round',     2, 1),
  ('Khu R', 'R03', 6,  'round',     3, 1),
  ('Khu R', 'R04', 6,  'round',     4, 1),
  ('Khu R', 'R05', 8,  'round',     1, 2),
  ('Khu R', 'R06', 6,  'round',     2, 2),
  ('Khu R', 'R07', 6,  'round',     3, 2),
  ('Khu R', 'R08', 12, 'rectangle', 4, 2),
  -- Khu T (8 bàn, 4 khách) - "Sân thượng ngắm cảnh"
  ('Khu T', 'T01', 4, 'square', 1, 1),
  ('Khu T', 'T02', 4, 'square', 2, 1),
  ('Khu T', 'T03', 4, 'square', 3, 1),
  ('Khu T', 'T04', 4, 'square', 4, 1),
  ('Khu T', 'T05', 4, 'square', 1, 2),
  ('Khu T', 'T06', 4, 'square', 2, 2),
  ('Khu T', 'T07', 4, 'square', 3, 2),
  ('Khu T', 'T08', 4, 'square', 4, 2),
  -- Khu Capichi (5 đơn, capacity 1)
  ('Khu Capichi', 'CP01', 1, 'square', 1, 1),
  ('Khu Capichi', 'CP02', 1, 'square', 2, 1),
  ('Khu Capichi', 'CP03', 1, 'square', 3, 1),
  ('Khu Capichi', 'CP04', 1, 'square', 4, 1),
  ('Khu Capichi', 'CP05', 1, 'square', 1, 2),
  -- Khu Shopee
  ('Khu Shopee', 'Shopee01', 1, 'square', 1, 1),
  ('Khu Shopee', 'Shopee02', 1, 'square', 2, 1),
  ('Khu Shopee', 'Shopee03', 1, 'square', 3, 1),
  ('Khu Shopee', 'Shopee04', 1, 'square', 4, 1),
  ('Khu Shopee', 'Shopee05', 1, 'square', 1, 2),
  -- Khu BE
  ('Khu BE', 'BE01', 1, 'square', 1, 1),
  ('Khu BE', 'BE02', 1, 'square', 2, 1),
  ('Khu BE', 'BE03', 1, 'square', 3, 1),
  ('Khu BE', 'BE04', 1, 'square', 4, 1),
  ('Khu BE', 'BE05', 1, 'square', 1, 2),
  -- Khu Grab
  ('Khu Grab', 'Grab01', 1, 'square', 1, 1),
  ('Khu Grab', 'Grab02', 1, 'square', 2, 1),
  ('Khu Grab', 'Grab03', 1, 'square', 3, 1),
  ('Khu Grab', 'Grab04', 1, 'square', 4, 1),
  ('Khu Grab', 'Grab05', 1, 'square', 1, 2),
  -- Khu Catalog (take-away ảo)
  ('Khu Catalog', 'Catalog', 1, 'square', 1, 1)
) as t(zone_name, code, capacity, shape, pos_x, pos_y)
where z.name = t.zone_name
on conflict (branch_id, code) do nothing;

-- ----- Tables for B002 (same layout, codes prefixed P-) -----
with
  z as (
    select z.id, z.branch_id, z.name
    from public.zones z
    join public.branches b on b.id = z.branch_id and b.code = 'B002'
  )
insert into public.tables (branch_id, zone_id, code, capacity, shape, pos_x, pos_y, status, is_active)
select
  z.branch_id,
  z.id,
  t.code, t.capacity, t.shape, t.pos_x, t.pos_y, 'available', true
from z, (values
  -- Khu A
  ('Khu A', 'PA01', 4, 'round',     1,  1),
  ('Khu A', 'PA02', 4, 'round',     2,  1),
  ('Khu A', 'PA03', 6, 'round',     3,  1),
  ('Khu A', 'PA04', 6, 'round',     4,  1),
  ('Khu A', 'PA05', 4, 'round',     1,  2),
  ('Khu A', 'PA06', 4, 'round',     2,  2),
  ('Khu A', 'PA07', 4, 'round',     3,  2),
  ('Khu A', 'PA08', 8, 'rectangle', 4,  2),
  ('Khu A', 'PA09', 4, 'round',     1,  3),
  -- Khu B
  ('Khu B', 'PB01', 10, 'round',    1,  1),
  ('Khu B', 'PB02', 8,  'round',    2,  1),
  ('Khu B', 'PB03', 10, 'round',    3,  1),
  -- Khu C
  ('Khu C', 'PC01', 2, 'square', 1, 1),
  ('Khu C', 'PC02', 2, 'square', 2, 1),
  ('Khu C', 'PC03', 4, 'square', 3, 1),
  ('Khu C', 'PC04', 4, 'square', 4, 1),
  ('Khu C', 'PC05', 2, 'square', 1, 2),
  ('Khu C', 'PC06', 4, 'square', 2, 2),
  ('Khu C', 'PC07', 2, 'square', 3, 2),
  ('Khu C', 'PC08', 4, 'square', 4, 2),
  -- Khu R
  ('Khu R', 'PR01', 6,  'round',     1, 1),
  ('Khu R', 'PR02', 6,  'round',     2, 1),
  ('Khu R', 'PR03', 6,  'round',     3, 1),
  ('Khu R', 'PR04', 6,  'round',     4, 1),
  ('Khu R', 'PR05', 8,  'round',     1, 2),
  ('Khu R', 'PR06', 6,  'round',     2, 2),
  ('Khu R', 'PR07', 6,  'round',     3, 2),
  ('Khu R', 'PR08', 12, 'rectangle', 4, 2),
  -- Khu T
  ('Khu T', 'PT01', 4, 'square', 1, 1),
  ('Khu T', 'PT02', 4, 'square', 2, 1),
  ('Khu T', 'PT03', 4, 'square', 3, 1),
  ('Khu T', 'PT04', 4, 'square', 4, 1),
  ('Khu T', 'PT05', 4, 'square', 1, 2),
  ('Khu T', 'PT06', 4, 'square', 2, 2),
  ('Khu T', 'PT07', 4, 'square', 3, 2),
  ('Khu T', 'PT08', 4, 'square', 4, 2),
  -- Delivery zones for B002
  ('Khu Capichi', 'PCP01', 1, 'square', 1, 1),
  ('Khu Capichi', 'PCP02', 1, 'square', 2, 1),
  ('Khu Capichi', 'PCP03', 1, 'square', 3, 1),
  ('Khu Capichi', 'PCP04', 1, 'square', 4, 1),
  ('Khu Capichi', 'PCP05', 1, 'square', 1, 2),
  ('Khu Shopee', 'PSh01', 1, 'square', 1, 1),
  ('Khu Shopee', 'PSh02', 1, 'square', 2, 1),
  ('Khu Shopee', 'PSh03', 1, 'square', 3, 1),
  ('Khu Shopee', 'PSh04', 1, 'square', 4, 1),
  ('Khu Shopee', 'PSh05', 1, 'square', 1, 2),
  ('Khu BE', 'PBE01', 1, 'square', 1, 1),
  ('Khu BE', 'PBE02', 1, 'square', 2, 1),
  ('Khu BE', 'PBE03', 1, 'square', 3, 1),
  ('Khu BE', 'PBE04', 1, 'square', 4, 1),
  ('Khu BE', 'PBE05', 1, 'square', 1, 2),
  ('Khu Grab', 'PGr01', 1, 'square', 1, 1),
  ('Khu Grab', 'PGr02', 1, 'square', 2, 1),
  ('Khu Grab', 'PGr03', 1, 'square', 3, 1),
  ('Khu Grab', 'PGr04', 1, 'square', 4, 1),
  ('Khu Grab', 'PGr05', 1, 'square', 1, 2),
  ('Khu Catalog', 'PCatalog', 1, 'square', 1, 1)
) as t(zone_name, code, capacity, shape, pos_x, pos_y)
where z.name = t.zone_name
on conflict (branch_id, code) do nothing;

-- ==========================================
-- FILE: 20260625220000_menu_subcategories_rls_grants_and_reload.sql
-- ==========================================
-- =============================================================================
-- 20260625220000_menu_subcategories_rls_grants_and_reload.sql
--
-- Closes three small gaps that surfaced after the Ishii menu sync:
--
--   (1) `menu_subcategories` was created by 20260625130000_menu_schema_align_ishii.sql
--       but never received RLS policies or grants. Without grants, PostgREST
--       returns 403 (PGRST301) for `authenticated` users even though RLS would
--       allow the row.
--
--   (2) `package_items` has SELECT/INSERT/UPDATE/DELETE grants for
--       `authenticated` in 20260625200100_explicit_table_grants.sql but those
--       grant clauses were NOT included (only `packages` was). Front-end code
--       that JOINs through package_items therefore hits "permission denied"
--       and the whole AdminMenusView page falls back to its error toast.
--
--   (3) Defensive ADD COLUMN IF NOT EXISTS for `package_items.is_active`. The
--       column is already defined in 20260623000000_setup.sql line 355, but
--       some PostgREST schema-cache reloads after long-uptime have been
--       observed to intermittently drop the column from `pg_attribute` cache
--       during in-place migrations. Re-asserting it here is idempotent and
--       cheap.
--
-- After applying, we issue `NOTIFY pgrst, 'reload schema'` so the PostgREST
-- container picks up the new RLS policies / columns without needing a manual
-- restart.
--
-- Idempotent — every statement is guarded by IF NOT EXISTS / IF EXISTS.
-- =============================================================================

-- 1. Defensive column re-assert for package_items.is_active
ALTER TABLE public.package_items
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS package_items_is_active_idx
  ON public.package_items (package_id) WHERE is_active = true;

COMMENT ON COLUMN public.package_items.is_active IS
  'Per-package-menu-item enable flag. Defined in 20260623000000_setup.sql; re-asserted here for PostgREST schema-cache resilience.';

-- 2. Enable RLS + add policies for menu_subcategories
ALTER TABLE public.menu_subcategories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "menu_subcategories_branch_read" ON public.menu_subcategories;
CREATE POLICY "menu_subcategories_branch_read" ON public.menu_subcategories
  FOR SELECT USING (branch_id = public.current_branch_id());

DROP POLICY IF EXISTS "menu_subcategories_branch_write" ON public.menu_subcategories;
CREATE POLICY "menu_subcategories_branch_write" ON public.menu_subcategories
  FOR ALL
    USING (branch_id = public.current_branch_id())
    WITH CHECK (branch_id = public.current_branch_id());

-- 3. Grants — auth + anon patterns from 20260625200100, now extended to
--    menu_subcategories + package_items.

-- anon (tablet / public menu preview)
GRANT SELECT ON public.menu_subcategories TO anon;
GRANT SELECT ON public.packages          TO anon;
GRANT SELECT ON public.package_items     TO anon;

-- authenticated (admin / manager / staff back-office)
GRANT SELECT ON public.menu_subcategories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.menu_subcategories TO authenticated;

GRANT SELECT ON public.package_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.package_items TO authenticated;

-- service_role already has full access via the "all tables in schema public"
-- grant in 20260625200100_explicit_table_grants.sql — no change needed.

-- 4. Reload PostgREST schema so it picks up the new policies / columns.
--    Supabase PostgREST listens on channel 'pgrst' for this NOTIFY; sending
--    'reload schema' triggers an immediate reload (no need to restart).
NOTIFY pgrst, 'reload schema';

-- ==========================================
-- FILE: 20260625230000_menu_items_sort_order.sql
-- ==========================================
-- =============================================================================
-- 20260625230000_menu_items_sort_order.sql
--
-- The original 20260623000000_setup.sql defines `sort_order` on
-- `menu_categories` and `package_items` but NOT on `menu_items`. Ishii's
-- menu data file (`docs/member_status/Ishii/thực đơn.txt`) and the
-- ReceptionOrderView POS both expect items to have a stable display order
-- within their category / subcategory.
--
-- This migration adds `menu_items.sort_order` as a default-zero, indexed
-- integer. Idempotent — uses ADD COLUMN IF NOT EXISTS and CREATE INDEX IF
-- NOT EXISTS.
--
-- After the column exists, AdminMenusView can ORDER BY sort_order, and
-- future drag-to-reorder UI on the back-office can write to it.
-- =============================================================================

ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_menu_items_branch_cat_sort
  ON public.menu_items (branch_id, category_id, subcategory_id, sort_order)
  WHERE is_available = true;

COMMENT ON COLUMN public.menu_items.sort_order IS
  'Display order within category (or subcategory if set). Lower = earlier. Defaults to 0 (insertion order). Added in 20260625230000_menu_items_sort_order.sql.';

-- Trigger: keep the updated_at column fresh on any UPDATE (in case the
-- column is later moved to a dedicated column). The set_updated_at
-- function is created by 20260623000000_setup.sql.
DROP TRIGGER IF EXISTS trg_menu_items_set_updated_at ON public.menu_items;
CREATE TRIGGER trg_menu_items_set_updated_at
  BEFORE UPDATE ON public.menu_items
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Reload PostgREST schema cache so the new column becomes visible to
-- supabase-js without a manual restart.
NOTIFY pgrst, 'reload schema';

-- ==========================================
-- FILE: 20260628065943_voucher_membership.sql
-- ==========================================
-- ==========================================
-- MODULE A: Vouchers
-- ==========================================

-- A.1 Patch vouchers table and create voucher_usages
ALTER TABLE public.vouchers
  ADD COLUMN IF NOT EXISTS min_order_value          numeric(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_discount_amount      numeric(12,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS customer_id              uuid REFERENCES public.customers(id) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS usage_limit_per_customer int DEFAULT 1,
  ADD COLUMN IF NOT EXISTS description_vi           text,
  ADD COLUMN IF NOT EXISTS description_en           text,
  ADD COLUMN IF NOT EXISTS description_ja           text,
  ADD COLUMN IF NOT EXISTS is_deleted               boolean DEFAULT false;

-- Unique constraint on branch + upper(code) for un-deleted vouchers
CREATE UNIQUE INDEX IF NOT EXISTS idx_vouchers_code_branch 
  ON public.vouchers (branch_id, UPPER(code)) 
  WHERE is_deleted = false;

CREATE TABLE IF NOT EXISTS public.voucher_usages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id      uuid NOT NULL REFERENCES public.vouchers(id),
  invoice_id      uuid NOT NULL REFERENCES public.invoices(id),
  customer_id     uuid REFERENCES public.customers(id),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  discount_amount numeric(12,2) NOT NULL,
  created_at      timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.voucher_usages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmin/Admin/Manager can read voucher usages"
  ON public.voucher_usages FOR SELECT
  USING (
    public.current_user_role() IN ('admin','manager')
    AND (
      branch_id = public.current_branch_id()
      OR public.current_user_role() = 'admin'
    )
  );

CREATE POLICY "System can insert voucher usages"
  ON public.voucher_usages FOR INSERT
  WITH CHECK (
    public.current_user_role() IN ('manager','admin')
  );

-- A.2 RPC Functions
CREATE OR REPLACE FUNCTION public.validate_voucher(
  p_code          text,
  p_branch_id     uuid,
  p_order_total   numeric,
  p_customer_id   uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_voucher   public.vouchers%ROWTYPE;
  v_used_by   int;
  v_discount  numeric(12,2);
BEGIN
  -- Case-insensitive code lookup
  SELECT * INTO v_voucher
    FROM public.vouchers
   WHERE UPPER(code) = UPPER(p_code)
     AND (branch_id = p_branch_id OR branch_id IS NULL)
     AND is_deleted = false
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_FOUND');
  END IF;

  IF NOT v_voucher.is_active THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_INACTIVE');
  END IF;

  IF v_voucher.valid_from IS NOT NULL AND now() < v_voucher.valid_from THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_YET_VALID');
  END IF;

  IF v_voucher.valid_until IS NOT NULL AND now() > v_voucher.valid_until THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_EXPIRED');
  END IF;

  IF v_voucher.max_uses IS NOT NULL AND v_voucher.used_count >= v_voucher.max_uses THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_EXHAUSTED');
  END IF;

  IF p_order_total < COALESCE(v_voucher.min_order_value, 0) THEN
    RETURN jsonb_build_object(
      'valid', false, 'error', 'ORDER_BELOW_MINIMUM',
      'min_order_value', v_voucher.min_order_value
    );
  END IF;

  -- Personalized voucher check
  IF v_voucher.customer_id IS NOT NULL AND v_voucher.customer_id != p_customer_id THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_FOR_YOU');
  END IF;

  -- Per-customer usage limit check
  IF p_customer_id IS NOT NULL AND v_voucher.usage_limit_per_customer IS NOT NULL THEN
    SELECT COUNT(*) INTO v_used_by
      FROM public.voucher_usages
     WHERE voucher_id = v_voucher.id AND customer_id = p_customer_id;

    IF v_used_by >= v_voucher.usage_limit_per_customer THEN
      RETURN jsonb_build_object('valid', false, 'error', 'CUSTOMER_USAGE_LIMIT_REACHED');
    END IF;
  END IF;

  -- Calculate actual discount
  IF v_voucher.type = 'percent' THEN
    v_discount := ROUND(p_order_total * v_voucher.value / 100, 0);
    -- Apply cap if configured
    IF v_voucher.max_discount_amount IS NOT NULL THEN
      v_discount := LEAST(v_discount, v_voucher.max_discount_amount);
    END IF;
  ELSE
    v_discount := LEAST(v_voucher.value, p_order_total); -- cannot discount more than total
  END IF;

  RETURN jsonb_build_object(
    'valid',            true,
    'voucher_id',       v_voucher.id,
    'code',             v_voucher.code,
    'type',             v_voucher.type,
    'discount_amount',  v_discount,
    'description_vi',   v_voucher.description_vi,
    'description_en',   v_voucher.description_en,
    'description_ja',   v_voucher.description_ja
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_voucher(
  p_voucher_id    uuid,
  p_invoice_id    uuid,
  p_branch_id     uuid,
  p_order_total   numeric,
  p_customer_id   uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_voucher        public.vouchers%ROWTYPE;
  v_discount       numeric(12,2);
  v_rows_updated   int;
BEGIN
  -- Atomic increment with guard — prevents race condition (two cashiers redeeming same code)
  UPDATE public.vouchers SET
    used_count = used_count + 1,
    updated_at = now()
  WHERE id = p_voucher_id
    AND is_active = true
    AND is_deleted = false
    AND (max_uses IS NULL OR used_count < max_uses)
    AND (valid_until IS NULL OR valid_until > now())
  RETURNING * INTO v_voucher;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  IF v_rows_updated = 0 THEN
    -- Voucher was exhausted or deactivated between validate and redeem
    RAISE EXCEPTION 'VOUCHER_NO_LONGER_VALID: Voucher % could not be redeemed',
      p_voucher_id USING ERRCODE = 'P0010';
  END IF;

  -- Calculate discount (same logic as validate_voucher)
  IF v_voucher.type = 'percent' THEN
    v_discount := ROUND(p_order_total * v_voucher.value / 100, 0);
    IF v_voucher.max_discount_amount IS NOT NULL THEN
      v_discount := LEAST(v_discount, v_voucher.max_discount_amount);
    END IF;
  ELSE
    v_discount := LEAST(v_voucher.value, p_order_total);
  END IF;

  -- Record the usage for analytics & per-customer limit tracking
  INSERT INTO public.voucher_usages (
    voucher_id, invoice_id, customer_id, branch_id, discount_amount
  ) VALUES (
    p_voucher_id, p_invoice_id, p_customer_id, p_branch_id, v_discount
  );

  RETURN jsonb_build_object(
    'success',          true,
    'discount_amount',  v_discount,
    'code',             v_voucher.code,
    'new_used_count',   v_voucher.used_count
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_voucher_stats(p_branch_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'total_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_deleted = false),
    'active_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_active = true
         AND is_deleted = false
         AND (valid_until IS NULL OR valid_until > now())),
    'expired_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_deleted = false
         AND valid_until < now()),
    'total_discount_given',
      (SELECT COALESCE(SUM(discount_amount), 0)
       FROM public.voucher_usages WHERE branch_id = p_branch_id),
    'total_redemptions',
      (SELECT COUNT(*) FROM public.voucher_usages WHERE branch_id = p_branch_id),
    'most_used_code',
      (SELECT code FROM public.vouchers v
       WHERE v.branch_id = p_branch_id
       ORDER BY v.used_count DESC LIMIT 1)
  );
$$;

-- ==========================================
-- MODULE B: Membership / Loyalty System
-- ==========================================

-- B.1 Database Schema
CREATE TABLE IF NOT EXISTS public.membership_tiers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id         uuid REFERENCES public.branches(id),
  -- NULL = applies to all branches (global tier)
  name_vi           text NOT NULL,
  name_en           text,
  name_ja           text,
  min_spent         numeric(14,0) NOT NULL DEFAULT 0,
  -- customers with total_spent >= this value qualify for this tier
  discount_percent  numeric(5,2) DEFAULT 0,
  -- auto-applied bill discount for this tier (e.g. 5.00 = 5%)
  points_multiplier numeric(4,2) DEFAULT 1.0,
  -- earn multiplier (Gold members earn 1.5x points)
  color             text DEFAULT '#C9A85C',
  -- hex color for badge UI
  icon_name         text DEFAULT 'star',
  -- lucide icon name for the badge
  sort_order        int NOT NULL DEFAULT 0,
  -- display order; ALSO used to determine rank (higher = better)
  created_at        timestamptz DEFAULT now()
);

-- Seed default tiers (agent must run this after table creation)
INSERT INTO public.membership_tiers
  (name_vi, name_en, name_ja, min_spent, discount_percent, points_multiplier, color, icon_name, sort_order)
VALUES
  ('Đồng',       'Bronze',   'ブロンズ', 0,          0,   1.0,  '#CD7F32', 'award',   1),
  ('Bạc',        'Silver',   'シルバー',  2000000,    3,   1.2,  '#C0C0C0', 'shield',  2),
  ('Vàng',       'Gold',     'ゴールド',  5000000,    5,   1.5,  '#C9A85C', 'star',    3),
  ('Kim Cương',  'Diamond',  'ダイヤ',   10000000,   10,  2.0,  '#B9F2FF', 'gem',     4)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.loyalty_rules (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id           uuid REFERENCES public.branches(id),
  -- NULL = global rule, branch-specific overrides global
  points_per_vnd      numeric(10,4) DEFAULT 0.001,
  -- 0.001 = 1 point per 1,000 VND spent
  vnd_per_point       numeric(10,2) DEFAULT 1000,
  -- 1,000 VND discount per 1 point redeemed
  min_redeem_points   int DEFAULT 100,
  -- minimum points needed to redeem
  max_redeem_percent  numeric(5,2) DEFAULT 50,
  -- max % of bill that can be paid with points (e.g. 50 = max 50% off)
  is_active           boolean DEFAULT true,
  updated_at          timestamptz DEFAULT now()
);

-- Seed default global rule
INSERT INTO public.loyalty_rules (branch_id, points_per_vnd, vnd_per_point, min_redeem_points)
VALUES (NULL, 0.001, 1000, 100)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id    uuid NOT NULL REFERENCES public.customers(id),
  branch_id      uuid NOT NULL REFERENCES public.branches(id),
  type           text NOT NULL CHECK (type IN ('EARN','REDEEM','EXPIRE','ADJUST_ADD','ADJUST_SUB')),
  points         int NOT NULL,
  -- ALWAYS POSITIVE. Sign determined by type (REDEEM/EXPIRE/ADJUST_SUB reduce balance).
  balance_after  int NOT NULL,
  -- snapshot of current_points AFTER this transaction (for audit/reconstruction)
  order_id       uuid REFERENCES public.orders(id) DEFAULT NULL,
  description    text,
  created_by     uuid REFERENCES auth.users(id) DEFAULT NULL,
  created_at     timestamptz DEFAULT now()
);

CREATE INDEX idx_loyalty_tx_customer ON public.loyalty_transactions(customer_id, created_at DESC);
CREATE INDEX idx_loyalty_tx_branch ON public.loyalty_transactions(branch_id, created_at DESC);

-- Patch `customers` table
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS current_points   int DEFAULT 0,
  -- spendable balance right now
  ADD COLUMN IF NOT EXISTS lifetime_points  int DEFAULT 0,
  -- total ever earned (never decremented, used for tier calculation)
  ADD COLUMN IF NOT EXISTS tier_id          uuid REFERENCES public.membership_tiers(id) DEFAULT NULL;
  -- FK resolved after membership_tiers created

-- Index for tier-based queries
CREATE INDEX IF NOT EXISTS idx_customers_tier ON public.customers(tier_id);
CREATE INDEX IF NOT EXISTS idx_customers_branch_spent ON public.customers(branch_id, total_spent DESC);


-- B.2 RPC Functions
CREATE OR REPLACE FUNCTION public.get_customer_with_loyalty(
  p_customer_id uuid
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_customer  public.customers%ROWTYPE;
  v_tier      public.membership_tiers%ROWTYPE;
  v_next_tier public.membership_tiers%ROWTYPE;
  v_rule      public.loyalty_rules%ROWTYPE;
  v_txs       jsonb;
BEGIN
  SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND' USING ERRCODE = 'P0020';
  END IF;

  -- Current tier
  SELECT * INTO v_tier FROM public.membership_tiers WHERE id = v_customer.tier_id;

  -- Next tier (the next tier above current, sorted by min_spent)
  SELECT * INTO v_next_tier
    FROM public.membership_tiers
   WHERE (branch_id = v_customer.branch_id OR branch_id IS NULL)
     AND min_spent > v_customer.total_spent
   ORDER BY min_spent ASC LIMIT 1;

  -- Loyalty rule (branch-specific, fall back to global)
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = v_customer.branch_id OR branch_id IS NULL)
     AND is_active = true
   ORDER BY branch_id DESC NULLS LAST -- branch-specific first
   LIMIT 1;

  -- Recent transactions (last 20)
  SELECT jsonb_agg(t ORDER BY t.created_at DESC)
    INTO v_txs
    FROM (
      SELECT id, type, points, balance_after, description, created_at
        FROM public.loyalty_transactions
       WHERE customer_id = p_customer_id
       ORDER BY created_at DESC
       LIMIT 20
    ) t;

  RETURN jsonb_build_object(
    'customer',          row_to_json(v_customer),
    'tier',              row_to_json(v_tier),
    'next_tier',         row_to_json(v_next_tier),
    'spent_to_next_tier',
      CASE WHEN v_next_tier.id IS NOT NULL
           THEN v_next_tier.min_spent - v_customer.total_spent
           ELSE NULL END,
    'loyalty_rule',      row_to_json(v_rule),
    'recent_transactions', COALESCE(v_txs, '[]'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.earn_points_for_order(
  p_customer_id  uuid,
  p_branch_id    uuid,
  p_order_id     uuid,
  p_order_amount numeric
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rule         public.loyalty_rules%ROWTYPE;
  v_customer     public.customers%ROWTYPE;
  v_points_earn  int;
  v_new_points   int;
  v_new_lifetime int;
  v_new_tier_id  uuid;
  v_multiplier   numeric := 1.0;
BEGIN
  -- Fetch loyalty rule (branch > global fallback)
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = p_branch_id OR branch_id IS NULL) AND is_active = true
   ORDER BY branch_id DESC NULLS LAST LIMIT 1;

  -- Lock customer row to prevent race with concurrent checkout
  SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  -- Get current tier multiplier
  IF v_customer.tier_id IS NOT NULL THEN
    SELECT points_multiplier INTO v_multiplier
      FROM public.membership_tiers WHERE id = v_customer.tier_id;
  END IF;

  -- Calculate earned points
  v_points_earn  := FLOOR(p_order_amount * COALESCE(v_rule.points_per_vnd, 0.001) * v_multiplier);
  v_new_points   := v_customer.current_points + v_points_earn;
  v_new_lifetime := v_customer.lifetime_points + v_points_earn;

  -- Check for tier upgrade based on total_spent (already updated by checkout flow)
  SELECT id INTO v_new_tier_id
    FROM public.membership_tiers
   WHERE (branch_id = p_branch_id OR branch_id IS NULL)
     AND min_spent <= v_customer.total_spent
   ORDER BY min_spent DESC LIMIT 1;

  -- Update customer
  UPDATE public.customers SET
    current_points  = v_new_points,
    lifetime_points = v_new_lifetime,
    tier_id         = v_new_tier_id,
    updated_at      = now()
  WHERE id = p_customer_id;

  -- Insert loyalty transaction
  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, order_id, description
  ) VALUES (
    p_customer_id, p_branch_id, 'EARN', v_points_earn, v_new_points,
    p_order_id,
    'Tích điểm từ đơn hàng ' || p_order_id::text
  );

  RETURN jsonb_build_object(
    'points_earned',   v_points_earn,
    'new_balance',     v_new_points,
    'tier_upgraded',   (v_new_tier_id IS DISTINCT FROM v_customer.tier_id),
    'new_tier_id',     v_new_tier_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_points(
  p_customer_id   uuid,
  p_branch_id     uuid,
  p_points        int,    -- points to redeem (must be positive)
  p_order_id      uuid DEFAULT NULL,
  p_description   text  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rule          public.loyalty_rules%ROWTYPE;
  v_current_pts   int;
  v_new_balance   int;
  v_discount_vnd  numeric(12,2);
BEGIN
  -- Fetch rule
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = p_branch_id OR branch_id IS NULL) AND is_active = true
   ORDER BY branch_id DESC NULLS LAST LIMIT 1;

  IF p_points < COALESCE(v_rule.min_redeem_points, 100) THEN
    RAISE EXCEPTION 'BELOW_MIN_REDEEM: Minimum % points required, got %',
      v_rule.min_redeem_points, p_points USING ERRCODE = 'P0021';
  END IF;

  -- Lock customer row to prevent concurrent deduction
  SELECT current_points INTO v_current_pts
    FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  IF v_current_pts < p_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS: Has %, needs %',
      v_current_pts, p_points USING ERRCODE = 'P0022';
  END IF;

  v_new_balance := v_current_pts - p_points;

  UPDATE public.customers SET
    current_points = v_new_balance,
    updated_at = now()
  WHERE id = p_customer_id;

  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, order_id, description
  ) VALUES (
    p_customer_id, p_branch_id, 'REDEEM', p_points, v_new_balance,
    p_order_id, COALESCE(p_description, 'Đổi điểm lấy ưu đãi')
  );

  v_discount_vnd := p_points * COALESCE(v_rule.vnd_per_point, 1000);

  RETURN jsonb_build_object(
    'success',         true,
    'points_redeemed', p_points,
    'new_balance',     v_new_balance,
    'discount_vnd',    v_discount_vnd
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.adjust_points(
  p_customer_id  uuid,
  p_branch_id    uuid,
  p_type         text,    -- 'ADJUST_ADD' | 'ADJUST_SUB'
  p_points       int,     -- always positive
  p_reason       text,
  p_admin_id     uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current  int;
  v_new_bal  int;
BEGIN
  SELECT current_points INTO v_current
    FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  IF p_type = 'ADJUST_SUB' AND v_current < p_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS' USING ERRCODE = 'P0022';
  END IF;

  v_new_bal := CASE p_type
    WHEN 'ADJUST_ADD' THEN v_current + p_points
    WHEN 'ADJUST_SUB' THEN v_current - p_points
  END;

  UPDATE public.customers SET
    current_points = v_new_bal,
    lifetime_points = CASE WHEN p_type = 'ADJUST_ADD'
      THEN lifetime_points + p_points ELSE lifetime_points END,
    updated_at = now()
  WHERE id = p_customer_id;

  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, description, created_by
  ) VALUES (
    p_customer_id, p_branch_id, p_type, p_points, v_new_bal, p_reason, p_admin_id
  );

  RETURN jsonb_build_object('new_balance', v_new_bal);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_crm_dashboard_stats(p_branch_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    -- Customer counts
    'total_customers',
      (SELECT COUNT(*) FROM public.customers WHERE branch_id = p_branch_id),
    'new_customers_this_month',
      (SELECT COUNT(*) FROM public.customers
       WHERE branch_id = p_branch_id
         AND created_at >= date_trunc('month', now())),
    'repeater_customers',
      (SELECT COUNT(*) FROM public.customers
       WHERE branch_id = p_branch_id AND total_visits > 1),
    'vip_customers',
      (SELECT COUNT(*) FROM public.customers c
       JOIN public.membership_tiers t ON t.id = c.tier_id
       WHERE c.branch_id = p_branch_id AND t.sort_order >= 3),
    -- Spending
    'avg_spent_per_customer',
      (SELECT ROUND(AVG(total_spent), 0) FROM public.customers
       WHERE branch_id = p_branch_id AND total_spent > 0),
    'total_revenue_from_members',
      (SELECT COALESCE(SUM(total_spent), 0) FROM public.customers
       WHERE branch_id = p_branch_id),
    -- Tier distribution (for pie chart)
    'tier_distribution',
      (SELECT jsonb_agg(jsonb_build_object(
        'tier_id',   sub.id,
        'name_vi',   sub.name_vi,
        'name_en',   sub.name_en,
        'name_ja',   sub.name_ja,
        'color',     sub.color,
        'count',     sub.cnt
       ) ORDER BY sub.sort_order)
       FROM (
         SELECT t.id, t.name_vi, t.name_en, t.name_ja, t.color, t.sort_order, COUNT(c.id) as cnt
         FROM public.membership_tiers t
         LEFT JOIN public.customers c ON c.tier_id = t.id AND c.branch_id = p_branch_id
         WHERE t.branch_id = p_branch_id OR t.branch_id IS NULL
         GROUP BY t.id, t.name_vi, t.name_en, t.name_ja, t.color, t.sort_order
       ) sub),
    -- Loyalty
    'total_points_in_circulation',
      (SELECT COALESCE(SUM(current_points), 0) FROM public.customers
       WHERE branch_id = p_branch_id),
    'total_points_redeemed',
      (SELECT COALESCE(SUM(points), 0) FROM public.loyalty_transactions
       WHERE branch_id = p_branch_id AND type = 'REDEEM'),
    -- Top 5 customers by spending
    'top_customers',
      (SELECT jsonb_agg(jsonb_build_object(
        'id',           c.id,
        'name',         c.name,
        'phone',        c.phone,
        'total_spent',  c.total_spent,
        'total_visits', c.total_visits,
        'current_points', c.current_points,
        'tier_name',    c.name_vi,
        'tier_color',   c.color
       ) ORDER BY c.total_spent DESC)
       FROM (
         SELECT c.*, t.name_vi, t.color
           FROM public.customers c
           LEFT JOIN public.membership_tiers t ON t.id = c.tier_id
          WHERE c.branch_id = p_branch_id
          ORDER BY c.total_spent DESC
          LIMIT 5
       ) c)
  );
$$;

CREATE OR REPLACE FUNCTION public.list_customers_with_tier(
  p_branch_id   uuid,
  p_search      text   DEFAULT NULL,
  p_tier_id     uuid   DEFAULT NULL,
  p_limit       int    DEFAULT 30,
  p_offset      int    DEFAULT 0,
  p_sort_by     text   DEFAULT 'total_spent',
  p_sort_dir    text   DEFAULT 'desc'
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_customers  jsonb;
  v_total      int;
BEGIN
  SELECT COUNT(*) INTO v_total
    FROM public.customers c
   WHERE c.branch_id = p_branch_id
     AND (p_tier_id IS NULL OR c.tier_id = p_tier_id)
     AND (p_search IS NULL
          OR c.name  ILIKE '%' || p_search || '%'
          OR c.phone ILIKE '%' || p_search || '%'
          OR c.email ILIKE '%' || p_search || '%');

  SELECT jsonb_agg(row) INTO v_customers FROM (
    SELECT
      c.id, c.name, c.phone, c.email,
      c.total_visits, c.total_spent, c.last_visit_at,
      c.current_points, c.lifetime_points,
      c.tags, c.is_vip, c.created_at,
      jsonb_build_object(
        'id',       t.id,
        'name_vi',  t.name_vi,
        'name_en',  t.name_en,
        'name_ja',  t.name_ja,
        'color',    t.color,
        'icon_name',t.icon_name,
        'discount_percent', t.discount_percent
      ) AS tier
    FROM public.customers c
    LEFT JOIN public.membership_tiers t ON t.id = c.tier_id
    WHERE c.branch_id = p_branch_id
      AND (p_tier_id IS NULL OR c.tier_id = p_tier_id)
      AND (p_search IS NULL
           OR c.name  ILIKE '%' || p_search || '%'
           OR c.phone ILIKE '%' || p_search || '%'
           OR c.email ILIKE '%' || p_search || '%')
    ORDER BY
      CASE WHEN p_sort_by = 'total_spent'   AND p_sort_dir = 'desc' THEN c.total_spent   END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'total_visits'  AND p_sort_dir = 'desc' THEN c.total_visits  END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'current_points'AND p_sort_dir = 'desc' THEN c.current_points END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'last_visit_at' AND p_sort_dir = 'desc' THEN c.last_visit_at END DESC NULLS LAST,
      c.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) row;

  RETURN jsonb_build_object(
    'customers', COALESCE(v_customers, '[]'),
    'total',     v_total,
    'limit',     p_limit,
    'offset',    p_offset
  );
END;
$$;


-- ==========================================
-- FILE: 20260701000000_schema_hardening_v2.sql
-- ==========================================
-- ==============================================================================
-- SCHEMA HARDENING v2 — NGƯU CÁT POS
-- Replaces (supersedes):
--   20260629000000_master_plan_part1.sql
--   20260629000001_master_plan_part2_rpc.sql
--   20260629000002_master_plan_part2_rpc_extended.sql
--   20260629000003_mvp_revised_plan.sql
--   20260629000004_mvp_procurement.sql
--
-- Fix Priority:
--   (1) Deploy-breaking bugs — DROP CASCADE, wrong column refs, duplicate triggers/policies
--   (2) Security — EXECUTE permissions, branch self-check inside SECURITY DEFINER RPCs
--   (3) RLS completeness — enable + admin-bypass on all missing tables
--   (4) Structural — suppliers table, unify dual inventory, race-condition indexes
--   (5) Executive dashboard rewritten with branch breakdown
-- ==============================================================================

-- ==============================================================================
-- PART 0: GUARD — Idempotent helpers
-- ==============================================================================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    RAISE EXCEPTION 'Base schema (20260623000000_setup.sql) must run first';
  END IF;
END $$;

-- ==============================================================================
-- PART 1: NEW ENUM VALUES
-- (Add only if not exists — safe to re-run)
-- ==============================================================================
DO $$ BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'purchasing';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'accounting';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'crm';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ==============================================================================
-- PART 2: PATCH EXISTING TABLES (idempotent via IF NOT EXISTS / IF EXISTS)
-- ==============================================================================

-- 2.1 Patch orders (add new columns introduced by Master Plan)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS order_type         text DEFAULT 'A_LA_CARTE'
    CHECK (order_type IN ('BUFFET','A_LA_CARTE')),
  ADD COLUMN IF NOT EXISTS guest_count        int DEFAULT 1,
  ADD COLUMN IF NOT EXISTS order_source       text DEFAULT 'TABLET'
    CHECK (order_source IN ('TABLET','STAFF','APP','PHONE')),
  ADD COLUMN IF NOT EXISTS buffet_package_id  uuid,
  ADD COLUMN IF NOT EXISTS completed_at       timestamptz,
  ADD COLUMN IF NOT EXISTS cancelled_at       timestamptz,
  ADD COLUMN IF NOT EXISTS cancel_reason      text;

-- ==============================================================================
-- PART 3: BILLS & INVOICES — correct architecture
-- FIX (1): The old migrations did DROP TABLE invoices CASCADE which silently
--          removed FK constraints on payments/voucher_usages. We drop carefully
--          and rebuild in the correct order.
-- ==============================================================================

-- Step 3a: Remove old broken tables ONLY if they exist (in reverse dep order)
DROP TABLE IF EXISTS public.bill_items   CASCADE;
DROP TABLE IF EXISTS public.bills        CASCADE;
-- NOTE: invoices is dropped + recreated below with correct structure

-- Step 3b: Drop the old invoices table which had wrong columns
--          (order_id, subtotal, vat, discount, total) from base schema vs
--          new design (bill_id, invoice_symbol, ...). We must rebuild it.
DROP TABLE IF EXISTS public.invoices CASCADE;

-- Step 3c: Create BILLS (POS snapshot — immutable after print)
CREATE TABLE IF NOT EXISTS public.bills (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  bill_code       text NOT NULL,
  order_id        uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  table_id        uuid REFERENCES public.tables(id)  ON DELETE SET NULL,
  shift_id        uuid, -- FK added after shifts table exists
  cashier_id      uuid REFERENCES auth.users(id),
  waiter_id       uuid REFERENCES auth.users(id),
  time_in         timestamptz,
  time_out        timestamptz,
  print_count     int DEFAULT 1,
  sub_total       numeric(14,2) NOT NULL CHECK (sub_total >= 0),
  service_charge_percent numeric(5,2) DEFAULT 0,
  service_charge_amount  numeric(14,2) DEFAULT 0,
  discount_total  numeric(14,2) DEFAULT 0,
  vat_8_amount    numeric(14,2) DEFAULT 0,
  vat_10_amount   numeric(14,2) DEFAULT 0,
  grand_total     numeric(14,2) NOT NULL CHECK (grand_total >= 0),
  payment_method  text,
  payment_detail  jsonb DEFAULT '{}',
  status          text NOT NULL DEFAULT 'OPEN'
    CHECK (status IN ('OPEN','PRINTED','PAID','VOID')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, bill_code)
);
CREATE INDEX IF NOT EXISTS bills_branch_idx  ON public.bills (branch_id);
CREATE INDEX IF NOT EXISTS bills_order_idx   ON public.bills (order_id);
CREATE INDEX IF NOT EXISTS bills_table_idx   ON public.bills (table_id);

-- Step 3d: Create BILL_ITEMS (immutable line-item snapshot)
CREATE TABLE IF NOT EXISTS public.bill_items (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id        uuid NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  menu_item_id   uuid REFERENCES public.menu_items(id) ON DELETE SET NULL,
  name_snapshot  text NOT NULL,
  quantity       numeric(12,2) NOT NULL CHECK (quantity > 0),
  unit_price     numeric(14,2) NOT NULL CHECK (unit_price >= 0),
  unit_cost      numeric(14,2) DEFAULT 0,
  line_total     numeric(14,2) NOT NULL CHECK (line_total >= 0)
);

-- Step 3e: Rebuild INVOICES with correct columns (bill-based, tax flow)
CREATE TABLE IF NOT EXISTS public.invoices (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id           uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  bill_id             uuid NOT NULL REFERENCES public.bills(id) ON DELETE RESTRICT,
  invoice_symbol      text NOT NULL,
  invoice_number      text NOT NULL,
  issue_date          date NOT NULL DEFAULT CURRENT_DATE,
  buyer_name          text DEFAULT 'Người mua không lấy hoá đơn',
  buyer_company       text,
  buyer_tax_code      text,
  buyer_address       text,
  payment_method_code text DEFAULT 'KTT',
  total_goods_amount  numeric(14,2) NOT NULL DEFAULT 0,
  total_tax_amount    numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  tax_breakdown       jsonb DEFAULT '{}',
  status              text NOT NULL DEFAULT 'VALID'
    CHECK (status IN ('VALID','UPDATED','VOID')),
  is_signed           boolean DEFAULT false,
  signature_date      timestamptz,
  created_by          uuid REFERENCES auth.users(id),
  created_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, invoice_symbol, invoice_number)
);
CREATE INDEX IF NOT EXISTS invoices_branch_idx ON public.invoices (branch_id);
CREATE INDEX IF NOT EXISTS invoices_bill_idx   ON public.invoices (bill_id);

-- FIX (1): One VALID invoice per bill (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_valid_invoice_per_bill
  ON public.invoices (bill_id)
  WHERE status = 'VALID';

-- Step 3f: Restore FK on voucher_usages (was silently dropped by CASCADE)
--          voucher_usages.invoice_id now references the new invoices table
ALTER TABLE public.voucher_usages
  DROP CONSTRAINT IF EXISTS voucher_usages_invoice_id_fkey;
ALTER TABLE public.voucher_usages
  ADD CONSTRAINT voucher_usages_invoice_id_fkey
  FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);

-- Step 3g: Rebuild payments.invoice_id FK
ALTER TABLE public.payments
  DROP CONSTRAINT IF EXISTS payments_invoice_id_fkey;
ALTER TABLE public.payments
  ADD CONSTRAINT payments_invoice_id_fkey
  FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);

-- ==============================================================================
-- PART 4: SEQUENCES
-- ==============================================================================
CREATE SEQUENCE IF NOT EXISTS po_seq  START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS req_seq START 1 INCREMENT 1 NO CYCLE;

-- ==============================================================================
-- PART 5: NEW TABLES (all with RLS enabled, branch-scoped)
-- ==============================================================================

-- 5.1 SUPPLIERS (was completely missing — SupplierManagerView had nothing)
CREATE TABLE IF NOT EXISTS public.suppliers (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name            text NOT NULL,
  tax_code        text,
  contact_name    text,
  contact_phone   text,
  contact_email   text,
  address         text,
  payment_terms   text DEFAULT 'NET30'
    CHECK (payment_terms IN ('CASH','NET7','NET14','NET30','NET60')),
  notes           text,
  is_active       boolean NOT NULL DEFAULT true,
  metadata        jsonb NOT NULL DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

-- 5.2 INGREDIENTS (unified inventory — keep this one, retire inventory_items)
CREATE TABLE IF NOT EXISTS public.ingredients (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  category_id     uuid, -- FK to ingredient_categories (nullable for flexibility)
  code            text NOT NULL,
  name            text NOT NULL,
  unit            text NOT NULL,
  cost_per_unit   numeric(14,2) DEFAULT 0,
  min_stock_level numeric(12,3) DEFAULT 0,
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, code)
);
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- 5.3 INGREDIENT CATEGORIES
CREATE TABLE IF NOT EXISTS public.ingredient_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   uuid REFERENCES public.branches(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ingredient_categories ENABLE ROW LEVEL SECURITY;

-- Add FK from ingredients to ingredient_categories now that both exist
ALTER TABLE public.ingredients
  ADD COLUMN IF NOT EXISTS -- only if upgrading existing schema
  dummy_check text; -- no-op, handled by DROP below
ALTER TABLE public.ingredients DROP COLUMN IF EXISTS dummy_check;

-- 5.4 INVENTORY STOCK LEDGER (single source of truth)
CREATE TABLE IF NOT EXISTS public.inventory_stock (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
  quantity      numeric(12,3) NOT NULL DEFAULT 0,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, ingredient_id)
);
ALTER TABLE public.inventory_stock ENABLE ROW LEVEL SECURITY;

-- 5.5 INVENTORY TRANSACTIONS (ledger — never deleted)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id),
  type          text NOT NULL CHECK (type IN ('IN','OUT','ADJUST','WASTE','RETURN')),
  quantity      numeric(12,3) NOT NULL,
  balance_after numeric(12,3) NOT NULL,
  reference_id  uuid,   -- order_id / po_id / requisition_id
  reference_type text,  -- 'ORDER','PURCHASE_ORDER','REQUISITION','MANUAL'
  notes         text,
  created_by    uuid REFERENCES auth.users(id),
  created_at    timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- 5.6 REQUISITIONS (Kitchen → Purchasing requests)
CREATE TABLE IF NOT EXISTS public.requisitions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  req_number       text NOT NULL,
  status           text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING','APPROVED','REJECTED','PROCESSED')),
  requested_by     uuid REFERENCES auth.users(id),
  approved_by      uuid REFERENCES auth.users(id),
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.requisitions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.requisition_items (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requisition_id uuid NOT NULL REFERENCES public.requisitions(id) ON DELETE CASCADE,
  ingredient_id  uuid NOT NULL REFERENCES public.ingredients(id),
  requested_qty  numeric(12,3) NOT NULL,
  approved_qty   numeric(12,3)
);
ALTER TABLE public.requisition_items ENABLE ROW LEVEL SECURITY;

-- 5.7 PURCHASE ORDERS (Purchasing → Suppliers)
CREATE TABLE IF NOT EXISTS public.purchase_orders (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id              uuid NOT NULL REFERENCES public.branches(id),
  po_number              text NOT NULL,
  supplier_id            uuid REFERENCES public.suppliers(id),
  source_requisition_id  uuid REFERENCES public.requisitions(id),
  status                 text NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','SUBMITTED','CONFIRMED_BY_SUPPLIER','PARTIAL','RECEIVED','CANCELLED')),
  ordered_by             uuid NOT NULL REFERENCES auth.users(id),
  expected_delivery_date date,
  actual_delivery_date   date,
  subtotal               numeric(14,2) DEFAULT 0,
  tax_amount             numeric(14,2) DEFAULT 0,
  total_amount           numeric(14,2) DEFAULT 0,
  payment_status         text DEFAULT 'UNPAID'
    CHECK (payment_status IN ('UNPAID','PARTIALLY_PAID','PAID')),
  notes                  text,
  metadata               jsonb DEFAULT '{}',
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.purchase_order_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id uuid NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
  ingredient_id     uuid NOT NULL REFERENCES public.ingredients(id),
  ordered_quantity  numeric(12,3) NOT NULL,
  unit              text NOT NULL,
  unit_price        numeric(12,2) NOT NULL DEFAULT 0,
  total_price       numeric(14,2) GENERATED ALWAYS AS (ordered_quantity * unit_price) STORED,
  received_quantity numeric(12,3) DEFAULT 0,
  is_fully_received boolean DEFAULT false
);
ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;

-- 5.8 GOODS RECEIPTS (simpler receipt scan, links to supplier + PO)
CREATE TABLE IF NOT EXISTS public.goods_receipts (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id      uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  receipt_code   text NOT NULL,
  supplier_id    uuid REFERENCES public.suppliers(id),
  purchase_order_id uuid REFERENCES public.purchase_orders(id),
  scan_image_url text,
  total_amount   numeric(14,2) DEFAULT 0,
  created_by     uuid REFERENCES auth.users(id),
  status         text DEFAULT 'COMPLETED'
    CHECK (status IN ('PENDING','COMPLETED','CANCELLED')),
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, receipt_code)
);
ALTER TABLE public.goods_receipts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.goods_receipt_items (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id   uuid NOT NULL REFERENCES public.goods_receipts(id) ON DELETE CASCADE,
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id),
  quantity     numeric(12,3) NOT NULL CHECK (quantity > 0),
  unit_price   numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  total_price  numeric(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);
ALTER TABLE public.goods_receipt_items ENABLE ROW LEVEL SECURITY;

-- 5.9 FINANCIAL TRANSACTIONS (Accounting — expenses only, NOT revenue)
CREATE TABLE IF NOT EXISTS public.financial_transactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  transaction_type text NOT NULL CHECK (transaction_type IN ('INCOME','EXPENSE')),
  category         text NOT NULL,
  amount           numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_method   text NOT NULL,
  reference_id     uuid,
  reference_type   text,
  notes            text,
  recorded_by      uuid REFERENCES auth.users(id),
  transaction_date timestamptz NOT NULL DEFAULT now(),
  metadata         jsonb NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;

-- 5.10 TAX RECORDS
CREATE TABLE IF NOT EXISTS public.tax_records (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  period_type      text NOT NULL CHECK (period_type IN ('DAILY','MONTHLY','QUARTERLY')),
  period_start     date NOT NULL,
  period_end       date NOT NULL,
  gross_revenue    numeric(16,2) DEFAULT 0,
  discount_total   numeric(16,2) DEFAULT 0,
  net_revenue      numeric(16,2) DEFAULT 0,
  service_charge   numeric(16,2) DEFAULT 0,
  vat_rate         numeric(5,2)  DEFAULT 8,
  vat_amount       numeric(16,2) DEFAULT 0,
  other_tax        numeric(16,2) DEFAULT 0,
  total_tax        numeric(16,2) DEFAULT 0,
  expense_total    numeric(16,2) DEFAULT 0,
  gross_profit     numeric(16,2) DEFAULT 0,
  status           text DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','FINALIZED','SUBMITTED')),
  finalized_by     uuid REFERENCES auth.users(id),
  finalized_at     timestamptz,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, period_type, period_start)
);
ALTER TABLE public.tax_records ENABLE ROW LEVEL SECURITY;

-- 5.11 KITCHEN SHIFTS
CREATE TABLE IF NOT EXISTS public.kitchen_shifts (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id  uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  opened_by  uuid NOT NULL REFERENCES auth.users(id),
  closed_by  uuid REFERENCES auth.users(id),
  opened_at  timestamptz NOT NULL DEFAULT now(),
  closed_at  timestamptz,
  status     text NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','CLOSED')),
  notes      text
);
ALTER TABLE public.kitchen_shifts ENABLE ROW LEVEL SECURITY;

-- FIX (4): Race-condition guard — only 1 open kitchen shift per user per branch
CREATE UNIQUE INDEX IF NOT EXISTS one_open_kitchen_shift_per_user
  ON public.kitchen_shifts (branch_id, opened_by)
  WHERE status = 'OPEN';

-- 5.12 TABLET CONTENT
CREATE TABLE IF NOT EXISTS public.tablet_content (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   uuid REFERENCES public.branches(id) ON DELETE CASCADE,
  type        text NOT NULL CHECK (type IN ('CAROUSEL','PROMO','VIDEO')),
  image_url   text,
  video_url   text,
  title       text,
  is_active   boolean DEFAULT true,
  sort_order  int DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.tablet_content ENABLE ROW LEVEL SECURITY;

-- 5.13 TABLET SESSIONS
CREATE TABLE IF NOT EXISTS public.tablet_sessions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id      uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  table_id       uuid NOT NULL REFERENCES public.tables(id),
  reservation_id uuid REFERENCES public.reservations(id),
  customer_id    uuid REFERENCES public.customers(id),
  status         text NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','IDLE','CHECKOUT_REQUESTED','ENDED')),
  language       text DEFAULT 'vi',
  started_at     timestamptz NOT NULL DEFAULT now(),
  ended_at       timestamptz
);
ALTER TABLE public.tablet_sessions ENABLE ROW LEVEL SECURITY;

-- 5.14 SERVICE REQUESTS (Call waiter / Request bill)
CREATE TABLE IF NOT EXISTS public.service_requests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id),
  table_id     uuid NOT NULL REFERENCES public.tables(id),
  order_id     uuid REFERENCES public.orders(id),
  type         text NOT NULL
    CHECK (type IN ('CALL_WAITER','REQUEST_BILL','REQUEST_CONDIMENT','COMPLAINT','OTHER')),
  status       text NOT NULL DEFAULT 'OPEN'
    CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED')),
  message      text,
  priority     text DEFAULT 'NORMAL' CHECK (priority IN ('NORMAL','URGENT')),
  resolved_by  uuid REFERENCES auth.users(id),
  resolved_at  timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

-- 5.15 CAMPAIGNS & BOD APPROVALS
CREATE TABLE IF NOT EXISTS public.campaigns (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id                uuid REFERENCES public.branches(id),
  name                     text NOT NULL,
  description              text,
  type                     text NOT NULL
    CHECK (type IN ('SEASONAL','LOYALTY','FLASH','REFERRAL','BIRTHDAY','GRAND_OPENING')),
  status                   text NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','PENDING_APPROVAL','APPROVED','ACTIVE','PAUSED','ENDED','REJECTED')),
  start_date               date,
  end_date                 date,
  budget                   numeric(14,2) DEFAULT 0,
  actual_spend             numeric(14,2) DEFAULT 0,
  target_segment           jsonb DEFAULT '{}',
  expected_revenue_impact  numeric(14,2),
  actual_revenue_impact    numeric(14,2),
  created_by               uuid NOT NULL REFERENCES auth.users(id),
  approved_by              uuid REFERENCES auth.users(id),
  approved_at              timestamptz,
  rejection_reason         text,
  metadata                 jsonb DEFAULT '{}',
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.campaign_vouchers (
  campaign_id uuid NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  voucher_id  uuid NOT NULL REFERENCES public.vouchers(id),
  PRIMARY KEY (campaign_id, voucher_id)
);
ALTER TABLE public.campaign_vouchers ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.bod_approvals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type   text NOT NULL CHECK (entity_type IN ('CAMPAIGN','BUDGET','PROMOTION','POLICY')),
  entity_id     uuid NOT NULL,
  title         text,
  submitted_by  uuid NOT NULL REFERENCES auth.users(id),
  submitted_at  timestamptz NOT NULL DEFAULT now(),
  status        text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING','APPROVED','REJECTED')),
  reviewed_by   uuid REFERENCES auth.users(id),
  reviewed_at   timestamptz,
  review_note   text,
  metadata      jsonb DEFAULT '{}'
);
ALTER TABLE public.bod_approvals ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.budgets (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  period_type      text NOT NULL CHECK (period_type IN ('MONTHLY','QUARTERLY','ANNUAL')),
  period_start     date NOT NULL,
  period_end       date NOT NULL,
  department       text NOT NULL
    CHECK (department IN ('KITCHEN','MARKETING','OPERATIONS','PURCHASING','HR','IT','OTHER')),
  allocated_amount numeric(14,2) NOT NULL DEFAULT 0,
  spent_amount     numeric(14,2) DEFAULT 0,
  approved_by      uuid REFERENCES auth.users(id),
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, department, period_type, period_start)
);
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

-- 5.16 CUSTOMER FEEDBACK
CREATE TABLE IF NOT EXISTS public.customer_feedback (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  bill_id         uuid REFERENCES public.bills(id),
  order_id        uuid REFERENCES public.orders(id),
  customer_id     uuid REFERENCES public.customers(id),
  table_id        uuid REFERENCES public.tables(id),
  overall_rating  int NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
  food_rating     int CHECK (food_rating BETWEEN 1 AND 5),
  service_rating  int CHECK (service_rating BETWEEN 1 AND 5),
  ambiance_rating int CHECK (ambiance_rating BETWEEN 1 AND 5),
  comment         text,
  tags            jsonb DEFAULT '[]',
  source          text DEFAULT 'TABLET'
    CHECK (source IN ('TABLET','QR_CODE','STAFF_ENTRY','APP')),
  is_public       boolean DEFAULT false,
  staff_response  text,
  responded_by    uuid REFERENCES auth.users(id),
  responded_at    timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.customer_feedback ENABLE ROW LEVEL SECURITY;

-- 5.17 CUSTOMER VISIT NOTES (CRM in-dining survey — LOW-consistency, no FKs except branch)
-- Tracks: how they discovered us, reason for visit, impressions
CREATE TABLE IF NOT EXISTS public.customer_visit_notes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL,                    -- intentionally no FK (LOW-consistency)
  bill_id       uuid,                             -- bill at time of capture
  customer_id   uuid,                             -- optional link to known customer
  table_id      uuid,                             -- which table they were at
  channel       text,   -- 'INSTAGRAM','FACEBOOK','GOOGLE','ZOMATO','FRIEND','WALK_IN','OTHER'
  occasion      text,   -- 'DATE','FAMILY','BUSINESS','BIRTHDAY','ANNIVERSARY','OTHER'
  notes         jsonb DEFAULT '{}',              -- {impressions, improvement_points, wishes}
  captured_by   uuid,                            -- staff who did the survey
  captured_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.customer_visit_notes ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- PART 6: RACE-CONDITION SAFETY INDEXES
-- FIX (4): Guard "1 open order per table", "1 open shift per user"
-- ==============================================================================

-- One active order per table
CREATE UNIQUE INDEX IF NOT EXISTS one_open_order_per_table
  ON public.orders (table_id)
  WHERE table_id IS NOT NULL
    AND status IN ('Pending','Preparing','Served');

-- One open shift per user per branch (already exists above for kitchen_shifts;
-- replicate for front-of-house shifts table if present)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='shifts' AND table_schema='public') THEN
    EXECUTE $i$
      CREATE UNIQUE INDEX IF NOT EXISTS one_open_shift_per_user
        ON public.shifts (branch_id, user_id)
        WHERE status = 'open';
    $i$;
  END IF;
END $$;

-- ==============================================================================
-- PART 7: RLS POLICIES
-- FIX (2C + 5): Enable RLS + admin-bypass on all branch-scoped tables
-- Pattern: "branch_read" always includes has_role(['admin']) bypass
-- ==============================================================================

-- Helper macro used in all policies below:
-- USING (branch_id = current_branch_id() OR has_role(ARRAY['admin']::user_role[]))

-- 7.1 bills
CREATE POLICY "bills_branch_access" ON public.bills
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.2 bill_items (via bills join)
CREATE POLICY "bill_items_branch_access" ON public.bill_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.bills b
    WHERE b.id = bill_id
      AND (b.branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]))
  ));

-- 7.3 invoices
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "invoices_branch_access" ON public.invoices
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.4 suppliers
CREATE POLICY "suppliers_branch_access" ON public.suppliers
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.5 ingredients
CREATE POLICY "ingredients_branch_access" ON public.ingredients
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.6 ingredient_categories
CREATE POLICY "ingredient_categories_branch_access" ON public.ingredient_categories
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR branch_id IS NULL
      OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.7 inventory_stock
CREATE POLICY "inventory_stock_branch_access" ON public.inventory_stock
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.8 inventory_transactions (append-only in practice)
CREATE POLICY "inventory_transactions_branch_read" ON public.inventory_transactions
  FOR SELECT
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]));
CREATE POLICY "inventory_transactions_branch_insert" ON public.inventory_transactions
  FOR INSERT
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.9 requisitions
CREATE POLICY "requisitions_branch_access" ON public.requisitions
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.10 requisition_items (via requisitions join)
CREATE POLICY "requisition_items_branch_access" ON public.requisition_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.requisitions r
    WHERE r.id = requisition_id
      AND (r.branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]))
  ));

-- 7.11 purchase_orders
CREATE POLICY "purchase_orders_branch_access" ON public.purchase_orders
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.12 purchase_order_items (via purchase_orders join)
CREATE POLICY "purchase_order_items_branch_access" ON public.purchase_order_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.purchase_orders po
    WHERE po.id = purchase_order_id
      AND (po.branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]))
  ));

-- 7.13 goods_receipts
CREATE POLICY "goods_receipts_branch_access" ON public.goods_receipts
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.14 goods_receipt_items (via goods_receipts join)
CREATE POLICY "goods_receipt_items_branch_access" ON public.goods_receipt_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.goods_receipts gr
    WHERE gr.id = receipt_id
      AND (gr.branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]))
  ));

-- 7.15 financial_transactions
CREATE POLICY "financial_transactions_branch_access" ON public.financial_transactions
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.16 tax_records
CREATE POLICY "tax_records_branch_access" ON public.tax_records
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.17 kitchen_shifts
CREATE POLICY "kitchen_shifts_branch_access" ON public.kitchen_shifts
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.18 tablet_content (anon readable for tablet idle screen)
CREATE POLICY "tablet_content_anon_read" ON public.tablet_content
  FOR SELECT USING (is_active = true);
CREATE POLICY "tablet_content_staff_manage" ON public.tablet_content
  FOR ALL
  USING (public.has_role(ARRAY['admin','manager']::user_role[]))
  WITH CHECK (public.has_role(ARRAY['admin','manager']::user_role[]));

-- 7.19 tablet_sessions
CREATE POLICY "tablet_sessions_branch_access" ON public.tablet_sessions
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.20 service_requests
CREATE POLICY "service_requests_branch_access" ON public.service_requests
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.21 campaigns
CREATE POLICY "campaigns_branch_access" ON public.campaigns
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR branch_id IS NULL
      OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.22 campaign_vouchers (via campaigns)
CREATE POLICY "campaign_vouchers_access" ON public.campaign_vouchers
  FOR ALL
  USING (public.has_role(ARRAY['admin','manager']::user_role[]));

-- 7.23 bod_approvals (admin-only)
CREATE POLICY "bod_approvals_admin_access" ON public.bod_approvals
  FOR ALL
  USING (public.has_role(ARRAY['admin']::user_role[]));

-- 7.24 budgets
CREATE POLICY "budgets_branch_access" ON public.budgets
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.25 customer_feedback
CREATE POLICY "customer_feedback_branch_access" ON public.customer_feedback
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- 7.26 customer_visit_notes (CRM staff write, admin read all)
CREATE POLICY "customer_visit_notes_write" ON public.customer_visit_notes
  FOR INSERT
  WITH CHECK (branch_id = public.current_branch_id());
CREATE POLICY "customer_visit_notes_read" ON public.customer_visit_notes
  FOR SELECT
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]));

-- FIX (5): Add admin-bypass to existing base schema policies that lacked it
-- Drop and re-create the policies that need admin-bypass added

DO $$
DECLARE
  pol TEXT;
BEGIN
  -- orders
  FOR pol IN SELECT policyname FROM pg_policies
    WHERE tablename = 'orders' AND schemaname = 'public'
      AND policyname LIKE '%branch%'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.orders', pol);
  END LOOP;
END $$;

CREATE POLICY "orders_branch_access" ON public.orders
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

DO $$
DECLARE
  pol TEXT;
BEGIN
  -- payments
  FOR pol IN SELECT policyname FROM pg_policies
    WHERE tablename = 'payments' AND schemaname = 'public'
      AND policyname LIKE '%branch%'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.payments', pol);
  END LOOP;
END $$;

CREATE POLICY "payments_branch_access" ON public.payments
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

DO $$
DECLARE
  pol TEXT;
BEGIN
  -- reservations
  FOR pol IN SELECT policyname FROM pg_policies
    WHERE tablename = 'reservations' AND schemaname = 'public'
      AND policyname LIKE '%branch%'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.reservations', pol);
  END LOOP;
END $$;

CREATE POLICY "reservations_branch_access" ON public.reservations
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[]))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.has_role(ARRAY['admin']::user_role[]));

-- ==============================================================================
-- PART 8: RPC FUNCTIONS — SECURITY HARDENED
-- FIX (2A+2B): All RPCs now:
--   (a) check branch match inside function (not trusting caller's p_branch_id)
--   (b) set search_path = public, auth
--   (c) have REVOKE from PUBLIC + GRANT to authenticated
-- ==============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.1 submit_tablet_order
-- FIX: wrong column names (base_price→price, cogs→cost)
-- FIX: race condition — add advisory lock before check-then-insert
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.submit_tablet_order(
  p_branch_id  uuid,
  p_table_id   uuid,
  p_session_id uuid,
  p_items      jsonb  -- Array of { menu_item_id, quantity, modifiers, note }
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order_id     uuid;
  v_order_number text;
  v_item         record;
  v_menu_item    record;
  v_line_total   numeric(14,2);
BEGIN
  -- Branch self-check (FIX 2B)
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  -- Advisory lock on table_id to prevent race "check-then-insert" (FIX 4)
  PERFORM pg_advisory_xact_lock(hashtext(p_table_id::text));

  -- Find active order for this table or create new
  SELECT id INTO v_order_id
  FROM public.orders
  WHERE table_id = p_table_id
    AND status IN ('Pending','Preparing','Served')
  FOR UPDATE;

  IF NOT FOUND THEN
    v_order_number := 'ORD-' || to_char(now(), 'YYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);
    INSERT INTO public.orders (branch_id, table_id, order_number, status)
    VALUES (p_branch_id, p_table_id, v_order_number, 'Pending')
    RETURNING id INTO v_order_id;
  END IF;

  -- Insert items using correct column names (price, cost — not base_price, cogs)
  FOR v_item IN
    SELECT * FROM jsonb_to_recordset(p_items)
    AS x(menu_item_id uuid, quantity numeric, modifiers jsonb, note text)
  LOOP
    SELECT name, price, cost INTO v_menu_item
    FROM public.menu_items
    WHERE id = v_item.menu_item_id AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu item % not found or inactive', v_item.menu_item_id;
    END IF;

    v_line_total := v_item.quantity * v_menu_item.price;

    INSERT INTO public.order_items (
      branch_id, order_id, menu_item_id,
      name_snapshot, unit_price, unit_cost,
      quantity, line_total, status, modifiers, note
    ) VALUES (
      p_branch_id, v_order_id, v_item.menu_item_id,
      v_menu_item.name, v_menu_item.price, v_menu_item.cost,
      v_item.quantity, v_line_total, 'Pending',
      v_item.modifiers, v_item.note
    );
  END LOOP;

  -- Recalculate order subtotal/total
  UPDATE public.orders
  SET
    subtotal = (SELECT COALESCE(SUM(line_total), 0) FROM public.order_items
                WHERE order_id = v_order_id AND status != 'Cancelled'),
    total    = (SELECT COALESCE(SUM(line_total), 0) FROM public.order_items
                WHERE order_id = v_order_id AND status != 'Cancelled')
  WHERE id = v_order_id;

  RETURN jsonb_build_object('success', true, 'order_id', v_order_id);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.submit_tablet_order(uuid,uuid,uuid,jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.submit_tablet_order(uuid,uuid,uuid,jsonb) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.2 update_kitchen_ticket
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_kitchen_ticket(
  p_item_id    uuid,
  p_new_status public.order_status,
  p_staff_id   uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_current_status public.order_status;
BEGIN
  SELECT status INTO v_current_status
  FROM public.order_items
  WHERE id = p_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Item not found';
  END IF;

  UPDATE public.order_items
  SET status = p_new_status, updated_at = now()
  WHERE id = p_item_id;

  RETURN jsonb_build_object('success', true, 'item_id', p_item_id, 'new_status', p_new_status);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.update_kitchen_ticket(uuid,public.order_status,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.update_kitchen_ticket(uuid,public.order_status,uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.3 process_checkout
-- FIX: was inserting into old invoices schema (order_id, subtotal, vat, discount, total)
--      now inserts into bills + creates a VALID invoice row
-- FIX 2B: added branch self-check
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.process_checkout(
  p_order_id      uuid,
  p_branch_id     uuid,
  p_cashier_id    uuid,
  p_payment_method public.payment_method,
  p_voucher_code  text    DEFAULT NULL,
  p_points_to_use int     DEFAULT 0
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order           record;
  v_bill_id         uuid;
  v_invoice_id      uuid;
  v_bill_code       text;
  v_invoice_number  text;
  v_subtotal        numeric(14,2);
  v_voucher_discount numeric(14,2) := 0;
  v_points_discount  numeric(14,2) := 0;
  v_total_discount   numeric(14,2);
  v_vat_rate         numeric(5,4);
  v_vat_amount       numeric(14,2);
  v_grand_total      numeric(14,2);
  v_item            record;
BEGIN
  -- Branch self-check (FIX 2B)
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  -- 1. Lock order row
  SELECT o.*, b.vat_rate INTO v_order
  FROM public.orders o
  JOIN public.branches b ON b.id = o.branch_id
  WHERE o.id = p_order_id AND o.branch_id = p_branch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found for this branch';
  END IF;

  IF v_order.status IN ('Paid','Cancelled') THEN
    RAISE EXCEPTION 'Order is already % — cannot checkout again', v_order.status;
  END IF;

  v_subtotal := COALESCE(v_order.subtotal, 0);
  v_vat_rate := COALESCE(v_order.vat_rate, 0.08);

  -- 2. Points discount
  IF p_points_to_use > 0 THEN
    v_points_discount := p_points_to_use * 1000;  -- 1 pt = 1,000 VND
  END IF;

  v_total_discount := v_voucher_discount + v_points_discount;
  v_grand_total    := GREATEST(0, (v_subtotal - v_total_discount) * (1 + v_vat_rate));
  v_vat_amount     := v_grand_total - GREATEST(0, v_subtotal - v_total_discount);

  -- 3. Create BILL (snapshot)
  v_bill_code := 'BILL-' || to_char(now(), 'YYMMDD-HH24MISS') || '-'
              || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.bills (
    branch_id, bill_code, order_id, table_id,
    cashier_id, sub_total, discount_total,
    vat_8_amount, grand_total, payment_method, status
  ) VALUES (
    p_branch_id, v_bill_code, p_order_id, v_order.table_id,
    p_cashier_id, v_subtotal, v_total_discount,
    v_vat_amount, v_grand_total, p_payment_method::text, 'PAID'
  ) RETURNING id INTO v_bill_id;

  -- 4. Snapshot bill items from order_items
  INSERT INTO public.bill_items (bill_id, menu_item_id, name_snapshot, quantity, unit_price, unit_cost, line_total)
  SELECT v_bill_id, oi.menu_item_id, oi.name_snapshot, oi.quantity, oi.unit_price, oi.unit_cost, oi.line_total
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id AND oi.status != 'Cancelled';

  -- 5. Create initial VALID invoice
  v_invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.invoices (
    branch_id, bill_id, invoice_symbol, invoice_number,
    issue_date, total_goods_amount, total_tax_amount, grand_total,
    status, created_by
  ) VALUES (
    p_branch_id, v_bill_id, 'AA/24E', v_invoice_number,
    CURRENT_DATE, v_subtotal - v_total_discount, v_vat_amount, v_grand_total,
    'VALID', p_cashier_id
  ) RETURNING id INTO v_invoice_id;

  -- 6. Record payment
  INSERT INTO public.payments (
    branch_id, invoice_id, method, revenue_type,
    amount, received_amount, change_amount, received_by
  ) VALUES (
    p_branch_id, v_invoice_id, p_payment_method, 'other',
    v_grand_total, v_grand_total, 0, p_cashier_id
  );

  -- 7. Mark order Paid
  UPDATE public.orders
  SET status = 'Paid', vat = v_vat_amount, discount = v_total_discount, total = v_grand_total
  WHERE id = p_order_id;

  -- 8. Free the table
  IF v_order.table_id IS NOT NULL THEN
    UPDATE public.tables SET status = 'available' WHERE id = v_order.table_id;
  END IF;

  RETURN jsonb_build_object(
    'success',        true,
    'bill_id',        v_bill_id,
    'invoice_id',     v_invoice_id,
    'invoice_number', v_invoice_number,
    'grand_total',    v_grand_total
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,public.payment_method,text,int) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,public.payment_method,text,int) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.4 replace_invoice (anti-race, FOR UPDATE)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.replace_invoice(
  p_bill_id             uuid,
  p_new_invoice_symbol  text,
  p_new_invoice_number  text,
  p_buyer_tax_code      text,
  p_buyer_company       text,
  p_buyer_name          text DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_old_id   uuid;
  v_new_id   uuid;
  v_branch_id uuid;
BEGIN
  -- Lock current VALID invoice
  SELECT i.id, i.branch_id INTO v_old_id, v_branch_id
  FROM public.invoices i
  WHERE i.bill_id = p_bill_id AND i.status = 'VALID'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No VALID invoice found for bill %', p_bill_id;
  END IF;

  -- Branch check
  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  -- Retire old invoice
  UPDATE public.invoices SET status = 'UPDATED' WHERE id = v_old_id;

  -- Create new VALID invoice
  INSERT INTO public.invoices (
    branch_id, bill_id, invoice_symbol, invoice_number, issue_date,
    buyer_name, buyer_company, buyer_tax_code, status, created_by
  )
  SELECT
    v_branch_id, p_bill_id, p_new_invoice_symbol, p_new_invoice_number, CURRENT_DATE,
    COALESCE(p_buyer_name, old.buyer_name), p_buyer_company, p_buyer_tax_code,
    'VALID', public.current_user_id()
  FROM public.invoices old WHERE old.id = v_old_id
  RETURNING id INTO v_new_id;

  RETURN v_new_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.replace_invoice(uuid,text,text,text,text,text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.replace_invoice(uuid,text,text,text,text,text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.5 void_invoice
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.void_invoice(p_bill_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_invoice_id uuid;
  v_branch_id  uuid;
BEGIN
  SELECT i.id, i.branch_id INTO v_invoice_id, v_branch_id
  FROM public.invoices i
  WHERE i.bill_id = p_bill_id AND i.status = 'VALID'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No VALID invoice to void for bill %', p_bill_id;
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  UPDATE public.invoices SET status = 'VOID' WHERE id = v_invoice_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.void_invoice(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.void_invoice(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.6 submit_goods_receipt
-- FIX: now links to suppliers + ingredients (not inventory_items)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.submit_goods_receipt(
  p_branch_id       uuid,
  p_receipt_code    text,
  p_supplier_id     uuid,
  p_purchase_order_id uuid DEFAULT NULL,
  p_scan_image_url  text  DEFAULT NULL,
  p_items           jsonb  DEFAULT '[]'
  -- Array of { ingredient_id, quantity, unit_price }
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_receipt_id  uuid;
  v_item        jsonb;
  v_total       numeric(14,2) := 0;
  v_qty         numeric(12,3);
  v_price       numeric(12,2);
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  INSERT INTO public.goods_receipts (
    branch_id, receipt_code, supplier_id, purchase_order_id,
    scan_image_url, status, created_by
  ) VALUES (
    p_branch_id, p_receipt_code, p_supplier_id, p_purchase_order_id,
    p_scan_image_url, 'COMPLETED', public.current_user_id()
  ) RETURNING id INTO v_receipt_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_qty   := (v_item->>'quantity')::numeric;
    v_price := (v_item->>'unit_price')::numeric;

    INSERT INTO public.goods_receipt_items (receipt_id, ingredient_id, quantity, unit_price)
    VALUES (v_receipt_id, (v_item->>'ingredient_id')::uuid, v_qty, v_price);

    -- Atomic increment (safe under concurrency — no FOR UPDATE needed)
    INSERT INTO public.inventory_stock (branch_id, ingredient_id, quantity)
    VALUES (p_branch_id, (v_item->>'ingredient_id')::uuid, v_qty)
    ON CONFLICT (branch_id, ingredient_id)
    DO UPDATE SET quantity   = inventory_stock.quantity + EXCLUDED.quantity,
                  updated_at = now();

    -- Audit ledger
    INSERT INTO public.inventory_transactions (
      branch_id, ingredient_id, type, quantity,
      balance_after, reference_id, reference_type, created_by
    )
    SELECT p_branch_id, (v_item->>'ingredient_id')::uuid, 'IN', v_qty,
           quantity, v_receipt_id, 'GOODS_RECEIPT', public.current_user_id()
    FROM public.inventory_stock
    WHERE branch_id = p_branch_id AND ingredient_id = (v_item->>'ingredient_id')::uuid;

    v_total := v_total + (v_qty * v_price);
  END LOOP;

  UPDATE public.goods_receipts SET total_amount = v_total WHERE id = v_receipt_id;

  RETURN v_receipt_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.submit_goods_receipt(uuid,text,uuid,uuid,text,jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.submit_goods_receipt(uuid,text,uuid,uuid,text,jsonb) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.7 create_purchase_order (FIX: uses ingredients, not inventory_items)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_purchase_order(
  p_branch_id       uuid,
  p_ordered_by      uuid,
  p_supplier_id     uuid   DEFAULT NULL,
  p_requisition_id  uuid   DEFAULT NULL,
  p_items           jsonb  DEFAULT '[]'
  -- Array of { ingredient_id, quantity, unit, unit_price }
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_po_id     uuid;
  v_po_number text;
  v_item      record;
  v_subtotal  numeric(14,2) := 0;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  v_po_number := 'PO-' || to_char(now(), 'YYMMDD') || '-'
              || nextval('po_seq')::text;

  INSERT INTO public.purchase_orders (
    branch_id, po_number, supplier_id, source_requisition_id, status, ordered_by
  ) VALUES (
    p_branch_id, v_po_number, p_supplier_id, p_requisition_id, 'DRAFT', p_ordered_by
  ) RETURNING id INTO v_po_id;

  FOR v_item IN
    SELECT * FROM jsonb_to_recordset(p_items)
    AS x(ingredient_id uuid, quantity numeric, unit text, unit_price numeric)
  LOOP
    INSERT INTO public.purchase_order_items (
      purchase_order_id, ingredient_id, ordered_quantity, unit, unit_price
    ) VALUES (
      v_po_id, v_item.ingredient_id, v_item.quantity, v_item.unit, v_item.unit_price
    );
    v_subtotal := v_subtotal + (v_item.quantity * v_item.unit_price);
  END LOOP;

  UPDATE public.purchase_orders
  SET subtotal = v_subtotal, total_amount = v_subtotal
  WHERE id = v_po_id;

  RETURN jsonb_build_object('success', true, 'po_id', v_po_id, 'po_number', v_po_number);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.create_purchase_order(uuid,uuid,uuid,uuid,jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.create_purchase_order(uuid,uuid,uuid,uuid,jsonb) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.8 record_expense_payment (FIX: correct transaction_type enum value)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_expense_payment(
  p_branch_id  uuid,
  p_po_id      uuid,
  p_amount     numeric,
  p_method     text,
  p_recorded_by uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_po record;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_po FROM public.purchase_orders WHERE id = p_po_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Purchase order not found'; END IF;

  INSERT INTO public.financial_transactions (
    branch_id, transaction_type, category,
    amount, payment_method, reference_id, reference_type, recorded_by
  ) VALUES (
    p_branch_id, 'EXPENSE', 'SUPPLIER_PAYMENT',
    p_amount, p_method, p_po_id, 'PURCHASE_ORDER', p_recorded_by
  );

  UPDATE public.purchase_orders
  SET payment_status = CASE
        WHEN p_amount >= total_amount THEN 'PAID'
        ELSE 'PARTIALLY_PAID'
      END,
      updated_at = now()
  WHERE id = p_po_id;

  RETURN jsonb_build_object('success', true, 'po_id', p_po_id);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.record_expense_payment(uuid,uuid,numeric,text,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.record_expense_payment(uuid,uuid,numeric,text,uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.9 record_customer_feedback
-- FIX: column name was "rating" → correct name is "overall_rating"
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_customer_feedback(
  p_bill_id       uuid,
  p_overall_rating int,
  p_food_rating    int     DEFAULT NULL,
  p_service_rating int     DEFAULT NULL,
  p_comment        text    DEFAULT NULL,
  p_customer_id    uuid    DEFAULT NULL,
  p_source         text    DEFAULT 'TABLET'
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_feedback_id uuid;
  v_branch_id   uuid;
  v_order_id    uuid;
  v_table_id    uuid;
BEGIN
  SELECT b.branch_id, b.order_id, b.table_id INTO v_branch_id, v_order_id, v_table_id
  FROM public.bills b
  WHERE b.id = p_bill_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Bill not found'; END IF;

  INSERT INTO public.customer_feedback (
    branch_id, bill_id, order_id, customer_id, table_id,
    overall_rating, food_rating, service_rating, comment, source
  ) VALUES (
    v_branch_id, p_bill_id, v_order_id, p_customer_id, v_table_id,
    p_overall_rating, p_food_rating, p_service_rating, p_comment, p_source
  ) RETURNING id INTO v_feedback_id;

  RETURN v_feedback_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.record_customer_feedback(uuid,int,int,int,text,uuid,text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.record_customer_feedback(uuid,int,int,int,text,uuid,text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.10 record_visit_note (CRM in-dining survey)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_visit_note(
  p_branch_id   uuid,
  p_bill_id     uuid,
  p_table_id    uuid,
  p_channel     text    DEFAULT NULL,
  p_occasion    text    DEFAULT NULL,
  p_notes       jsonb   DEFAULT '{}',
  p_customer_id uuid    DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_note_id uuid;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  INSERT INTO public.customer_visit_notes (
    branch_id, bill_id, table_id, customer_id, channel, occasion, notes, captured_by
  ) VALUES (
    p_branch_id, p_bill_id, p_table_id, p_customer_id,
    p_channel, p_occasion, p_notes, public.current_user_id()
  ) RETURNING id INTO v_note_id;

  RETURN v_note_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.record_visit_note(uuid,uuid,uuid,text,text,jsonb,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.record_visit_note(uuid,uuid,uuid,text,text,jsonb,uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.11 create_reservation
-- FIX: wrong columns (guest_name, guest_phone, guest_count → customer_id, booking_code etc)
--      Also: status enum was 'PENDING' not 'Pending'; notes is text not jsonb
-- NOTE: reservations schema uses (branch_id, customer_id, reservation_date, guests)
--       For walk-in / phone bookings, we accept guest info and optionally create/link customer
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_reservation(
  p_branch_id       uuid,
  p_guest_name      text,
  p_guest_phone     text,
  p_reservation_time timestamptz,
  p_guests          int,
  p_notes           text DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_res_id      uuid;
  v_booking_code text;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  v_booking_code := 'RES-' || to_char(p_reservation_time, 'MMDD') || '-'
                 || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.reservations (
    branch_id, booking_code, reservation_date, guests, status,
    notes, guest_name, guest_phone
  ) VALUES (
    p_branch_id, v_booking_code, p_reservation_time::date, p_guests, 'Pending',
    p_notes, p_guest_name, p_guest_phone
  ) RETURNING id INTO v_res_id;

  RETURN v_res_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.create_reservation(uuid,text,text,timestamptz,int,text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.create_reservation(uuid,text,text,timestamptz,int,text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.12 get_revenue_report (FIX: reads from bills/payments, not financial_transactions.REVENUE)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_revenue_report(
  p_branch_id  uuid DEFAULT NULL,
  p_start_date date DEFAULT CURRENT_DATE,
  p_end_date   date DEFAULT CURRENT_DATE
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t)) INTO v_result
  FROM (
    SELECT
      b.branch_id,
      br.name                                  AS branch_name,
      COUNT(DISTINCT bi.id)                    AS bill_count,
      COALESCE(SUM(bi.grand_total), 0)         AS total_revenue,
      COALESCE(SUM(bi.vat_8_amount), 0)
        + COALESCE(SUM(bi.vat_10_amount), 0)   AS total_vat,
      COALESCE(SUM(bi.discount_total), 0)      AS total_discount
    FROM public.bills bi
    JOIN public.branches b  ON b.id = bi.branch_id
    JOIN public.branches br ON br.id = bi.branch_id
    WHERE bi.status = 'PAID'
      AND bi.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_branch_id IS NULL OR bi.branch_id = p_branch_id)
      AND (
        bi.branch_id = public.current_branch_id()
        OR public.has_role(ARRAY['admin']::user_role[])
      )
    GROUP BY b.branch_id, br.name
    ORDER BY total_revenue DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_revenue_report(uuid,date,date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_revenue_report(uuid,date,date) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.13 get_executive_dashboard
-- FIX (5): now returns per-branch breakdown, not single global number
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_executive_dashboard(
  p_period_start date DEFAULT (date_trunc('month', CURRENT_DATE))::date,
  p_period_end   date DEFAULT CURRENT_DATE
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- Admin can see all branches; others see only their own branch
  SELECT jsonb_build_object(
    'period_start',    p_period_start,
    'period_end',      p_period_end,
    'generated_at',    now(),
    'branches',        branches_data,
    'totals',          totals_data,
    'active_campaigns', active_campaigns_count
  ) INTO v_result
  FROM (
    SELECT
      jsonb_agg(jsonb_build_object(
        'branch_id',       br.id,
        'branch_name',     br.name,
        'bill_count',      COALESCE(bdata.bill_count, 0),
        'revenue',         COALESCE(bdata.revenue, 0),
        'vat_collected',   COALESCE(bdata.vat_collected, 0),
        'discount_total',  COALESCE(bdata.discount_total, 0),
        'expense_total',   COALESCE(edata.expense_total, 0),
        'gross_profit',    COALESCE(bdata.revenue, 0) - COALESCE(edata.expense_total, 0)
      ) ORDER BY COALESCE(bdata.revenue, 0) DESC) AS branches_data,

      jsonb_build_object(
        'total_revenue',  COALESCE(SUM(bdata.revenue), 0),
        'total_expense',  COALESCE(SUM(edata.expense_total), 0),
        'gross_profit',   COALESCE(SUM(bdata.revenue), 0) - COALESCE(SUM(edata.expense_total), 0)
      ) AS totals_data,

      (SELECT COUNT(*) FROM public.campaigns WHERE status = 'ACTIVE') AS active_campaigns_count

    FROM public.branches br
    LEFT JOIN (
      SELECT
        branch_id,
        COUNT(*) AS bill_count,
        SUM(grand_total)   AS revenue,
        SUM(vat_8_amount + vat_10_amount) AS vat_collected,
        SUM(discount_total) AS discount_total
      FROM public.bills
      WHERE status = 'PAID'
        AND created_at::date BETWEEN p_period_start AND p_period_end
      GROUP BY branch_id
    ) bdata ON bdata.branch_id = br.id
    LEFT JOIN (
      SELECT branch_id, SUM(amount) AS expense_total
      FROM public.financial_transactions
      WHERE transaction_type = 'EXPENSE'
        AND transaction_date::date BETWEEN p_period_start AND p_period_end
      GROUP BY branch_id
    ) edata ON edata.branch_id = br.id
    WHERE br.is_active = true
      AND (
        br.id = public.current_branch_id()
        OR public.has_role(ARRAY['admin']::user_role[])
      )
  ) subq;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_executive_dashboard(date,date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_executive_dashboard(date,date) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.14 generate_tax_record
-- FIX: wrong column names (total_revenue→gross_revenue, vat_collected→vat_amount)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.generate_tax_record(
  p_branch_id    uuid,
  p_period_type  text,
  p_period_start date,
  p_period_end   date
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_gross_revenue numeric(16,2);
  v_vat_amount    numeric(16,2);
  v_discount      numeric(16,2);
  v_expense       numeric(16,2);
  v_tax_id        uuid;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  SELECT
    COALESCE(SUM(grand_total), 0),
    COALESCE(SUM(vat_8_amount + vat_10_amount), 0),
    COALESCE(SUM(discount_total), 0)
  INTO v_gross_revenue, v_vat_amount, v_discount
  FROM public.bills
  WHERE branch_id = p_branch_id
    AND status = 'PAID'
    AND created_at::date BETWEEN p_period_start AND p_period_end;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense
  FROM public.financial_transactions
  WHERE branch_id = p_branch_id
    AND transaction_type = 'EXPENSE'
    AND transaction_date::date BETWEEN p_period_start AND p_period_end;

  INSERT INTO public.tax_records (
    branch_id, period_type, period_start, period_end,
    gross_revenue, discount_total, net_revenue,
    vat_amount, expense_total, gross_profit, status
  ) VALUES (
    p_branch_id, p_period_type, p_period_start, p_period_end,
    v_gross_revenue, v_discount, v_gross_revenue - v_discount,
    v_vat_amount, v_expense, v_gross_revenue - v_discount - v_expense, 'DRAFT'
  )
  ON CONFLICT (branch_id, period_type, period_start)
  DO UPDATE SET
    gross_revenue  = EXCLUDED.gross_revenue,
    discount_total = EXCLUDED.discount_total,
    net_revenue    = EXCLUDED.net_revenue,
    vat_amount     = EXCLUDED.vat_amount,
    expense_total  = EXCLUDED.expense_total,
    gross_profit   = EXCLUDED.gross_profit,
    status         = 'DRAFT'
  RETURNING id INTO v_tax_id;

  RETURN v_tax_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.15 approve_reject_campaign
-- FIX: wrong column names (target_type→entity_type, target_id→entity_id,
--       approver_id→reviewed_by, notes→review_note)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.approve_reject_campaign(
  p_campaign_id uuid,
  p_is_approved  boolean,
  p_approver_id  uuid,
  p_review_note  text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: only admin can approve/reject campaigns' USING ERRCODE = '28000';
  END IF;

  UPDATE public.campaigns
  SET
    status        = CASE WHEN p_is_approved THEN 'APPROVED' ELSE 'REJECTED' END,
    approved_by   = CASE WHEN p_is_approved THEN p_approver_id ELSE NULL END,
    approved_at   = CASE WHEN p_is_approved THEN now() ELSE NULL END,
    rejection_reason = CASE WHEN NOT p_is_approved THEN p_review_note ELSE NULL END,
    updated_at    = now()
  WHERE id = p_campaign_id;

  INSERT INTO public.bod_approvals (
    entity_type, entity_id, title, submitted_by,
    status, reviewed_by, reviewed_at, review_note
  ) VALUES (
    'CAMPAIGN', p_campaign_id, 'Campaign approval',
    p_approver_id,
    CASE WHEN p_is_approved THEN 'APPROVED' ELSE 'REJECTED' END,
    p_approver_id, now(), p_review_note
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.approve_reject_campaign(uuid,boolean,uuid,text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.approve_reject_campaign(uuid,boolean,uuid,text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.16 get_floor_plan (avoid N+1 — single RPC returns zones+tables+active orders)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_floor_plan(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result    jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());

  SELECT jsonb_agg(
    jsonb_build_object(
      'zone_id',    z.id,
      'zone_name',  z.name,
      'sort_order', z.sort_order,
      'tables',     COALESCE(tdata.tables, '[]')
    ) ORDER BY z.sort_order
  ) INTO v_result
  FROM public.zones z
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id',           t.id,
        'table_number', t.table_number,
        'capacity',     t.capacity,
        'status',       t.status,
        'active_order', odata.order_info
      ) ORDER BY t.table_number
    ) AS tables
    FROM public.tables t
    LEFT JOIN LATERAL (
      SELECT jsonb_build_object(
        'order_id',    o.id,
        'order_number',o.order_number,
        'status',      o.status,
        'guest_count', o.guest_count,
        'subtotal',    o.subtotal
      ) AS order_info
      FROM public.orders o
      WHERE o.table_id = t.id
        AND o.status IN ('Pending','Preparing','Served')
      LIMIT 1
    ) odata ON true
    WHERE t.zone_id = z.id AND t.branch_id = v_branch_id
  ) tdata ON true
  WHERE z.branch_id = v_branch_id;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_floor_plan(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_floor_plan(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8.17 get_bill_details (single RPC — avoid N+1 for checkout view)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_bill_details(p_bill_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'bill',      row_to_json(b),
    'items',     COALESCE(items.data, '[]'),
    'invoice',   row_to_json(inv),
    'payments',  COALESCE(pays.data, '[]')
  ) INTO v_result
  FROM public.bills b
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(bi)) AS data
    FROM public.bill_items bi WHERE bi.bill_id = b.id
  ) items ON true
  LEFT JOIN public.invoices inv
    ON inv.bill_id = b.id AND inv.status = 'VALID'
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(p)) AS data
    FROM public.payments p WHERE p.invoice_id = inv.id
  ) pays ON true
  WHERE b.id = p_bill_id
    AND (
      b.branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::user_role[])
    );

  RETURN v_result;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_bill_details(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_bill_details(uuid) TO authenticated;

-- ==============================================================================
-- PART 9: REALTIME (safe to re-run — ADD TABLE is idempotent on PG15+)
-- ==============================================================================
DO $$
BEGIN
  -- bills
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'bills'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bills;
  END IF;
  -- service_requests
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'service_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_requests;
  END IF;
END $$;

-- ==============================================================================
-- END OF MIGRATION
-- ==============================================================================


-- ==========================================
-- FILE: 20260701000001_menu_items_ingredients.sql
-- ==========================================
-- Thêm cột JSONB vào menu_items để lưu thông tin nguyên liệu hiển thị cho khách hàng
-- Yêu cầu: Đơn giản, dùng cho UI đọc, không mapping relational với bảng ingredients trong kho.

ALTER TABLE public.menu_items
ADD COLUMN IF NOT EXISTS ingredients jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.menu_items.ingredients IS 'Mảng JSON chứa tên các nguyên liệu để hiển thị cho khách (VD: ["Thịt bò", "Hành tây"]). Không liên kết tự động với kho.';


-- ==========================================
-- FILE: seed.sql
-- ==========================================
-- ==============================================================================
-- PART 2: RLS POLICIES & SEED DATA
-- ==============================================================================

-- RLS POLICIES

-- Branches
CREATE POLICY "admin_all_branches" ON public.branches FOR ALL USING (public.has_role(ARRAY['admin']::user_role[]));
CREATE POLICY "manager_read_branches" ON public.branches FOR SELECT USING (public.has_role(ARRAY['admin', 'manager']::user_role[]));
CREATE POLICY "staff_read_branch" ON public.branches FOR SELECT USING (id = public.current_branch_id());

-- Users
CREATE POLICY "users_read_self_or_admin" ON public.users FOR SELECT USING (id = public.current_user_id() OR public.has_role(ARRAY['admin', 'manager']::user_role[]));
CREATE POLICY "users_admin_write" ON public.users FOR ALL USING (public.has_role(ARRAY['admin']::user_role[]));

-- Tables
CREATE POLICY "tables_branch_read" ON public.tables FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "tables_branch_write" ON public.tables FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Customers
CREATE POLICY "customers_branch_read" ON public.customers FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "customers_branch_write" ON public.customers FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Menu Items
CREATE POLICY "menu_branch_read" ON public.menu_items FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "menu_branch_write" ON public.menu_items FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Packages
CREATE POLICY "packages_branch_read" ON public.packages FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "packages_branch_write" ON public.packages FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Reservations (Sessions)
CREATE POLICY "reservations_branch_read" ON public.reservations FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "reservations_branch_write" ON public.reservations FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception', 'staff']::user_role[]));

-- Orders
CREATE POLICY "orders_branch_read" ON public.orders FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "orders_branch_write" ON public.orders FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception', 'staff']::user_role[]));

-- Order Items
CREATE POLICY "order_items_branch_read" ON public.order_items FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "order_items_branch_write" ON public.order_items FOR ALL USING (branch_id = public.current_branch_id());

-- Invoices
CREATE POLICY "invoices_branch_read" ON public.invoices FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "invoices_branch_write" ON public.invoices FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Payments
CREATE POLICY "payments_branch_read" ON public.payments FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "payments_branch_write" ON public.payments FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Vouchers
CREATE POLICY "vouchers_branch_read" ON public.vouchers FOR SELECT USING (branch_id = public.current_branch_id() AND is_active = true);
CREATE POLICY "vouchers_branch_write" ON public.vouchers FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Shifts
CREATE POLICY "shifts_branch_read" ON public.shifts FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "shifts_branch_write" ON public.shifts FOR ALL USING (branch_id = public.current_branch_id() AND (user_id = public.current_user_id() OR public.has_role(ARRAY['admin', 'manager']::user_role[])));

-- Branch Settings
CREATE POLICY "settings_branch_read" ON public.branch_settings FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "settings_branch_write" ON public.branch_settings FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Audit Events
CREATE POLICY "audit_branch_read" ON public.audit_events FOR SELECT USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));
CREATE POLICY "audit_branch_write" ON public.audit_events FOR INSERT WITH CHECK (branch_id = public.current_branch_id());

-- Notifications
CREATE POLICY "notifications_branch_read" ON public.notifications FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "notifications_branch_write" ON public.notifications FOR ALL USING (branch_id = public.current_branch_id());

-- System Events
CREATE POLICY "system_events_branch_read" ON public.system_events FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "system_events_branch_write" ON public.system_events FOR INSERT WITH CHECK (branch_id = public.current_branch_id());


-- AUDIT LOGGING TRIGGER

CREATE OR REPLACE FUNCTION public.write_audit() RETURNS trigger AS $$
DECLARE
  v_action text;
  v_payload jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := TG_TABLE_NAME || '_created';
    v_payload := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'UPDATE' THEN
    v_action := TG_TABLE_NAME || '_updated';
    v_payload := jsonb_build_object('old', row_to_json(OLD)::jsonb, 'new', row_to_json(NEW)::jsonb);
  ELSIF TG_OP = 'DELETE' THEN
    v_action := TG_TABLE_NAME || '_deleted';
    v_payload := row_to_json(OLD)::jsonb;
  END IF;

  INSERT INTO public.audit_events (branch_id, actor_id, action, entity_type, entity_id, payload)
  VALUES (
    COALESCE((v_payload->>'branch_id')::uuid, public.current_branch_id()),
    public.current_user_id(),
    v_action,
    TG_TABLE_NAME,
    COALESCE((v_payload->>'id')::uuid, NULL),
    v_payload
  );

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_reservations AFTER INSERT OR UPDATE OR DELETE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_orders AFTER INSERT OR UPDATE OR DELETE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_order_items AFTER INSERT OR UPDATE OR DELETE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_payments AFTER INSERT OR UPDATE OR DELETE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_invoices AFTER INSERT OR UPDATE OR DELETE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_shifts AFTER INSERT OR UPDATE OR DELETE ON public.shifts FOR EACH ROW EXECUTE FUNCTION public.write_audit();

-- REVENUE REPORTING RPC
CREATE OR REPLACE FUNCTION public.revenue_by_hour(p_branch_id uuid, p_date date)
RETURNS TABLE (hour_of_day int, total_revenue numeric, order_count int) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(HOUR FROM created_at)::int AS hour_of_day,
    SUM(total) AS total_revenue,
    COUNT(id)::int AS order_count
  FROM public.orders
  WHERE branch_id = p_branch_id
    AND DATE(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_date
    AND status IN ('Served', 'Paid')
  GROUP BY EXTRACT(HOUR FROM created_at)
  ORDER BY hour_of_day;
END;
$$ LANGUAGE plpgsql STABLE;

-- REALTIME CONFIGURATION
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_events;

-- SEED DATA
INSERT INTO public.branches (id, code, name, address, phone, timezone, currency, vat_rate, is_active) VALUES
('b1000000-0000-0000-0000-000000000001', 'B001', 'Ngưu Cát Quận 1', '123 Lê Lợi, Q1, HCM', '0901234567', 'Asia/Ho_Chi_Minh', 'VND', 0.08, true),
('b2000000-0000-0000-0000-000000000002', 'B002', 'Ngưu Cát Phú Nhuận', '456 Phan Xích Long, PN, HCM', '0901234568', 'Asia/Ho_Chi_Minh', 'VND', 0.08, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.tables (id, branch_id, zone, code, capacity, pos_x, pos_y) VALUES
('t1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'VIP', 'A01', 4, 100, 100),
('t1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'VIP', 'A02', 4, 200, 100),
('t1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Main', 'B01', 2, 100, 200),
('t1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Main', 'B02', 6, 200, 200),
('t1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'Outdoor', 'C01', 4, 300, 200)
ON CONFLICT DO NOTHING;

INSERT INTO public.menu_items (id, branch_id, category, name, price, cost, i18n_name) VALUES
('m1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Beef', 'Wagyu A5', 500000, 200000, '{"vi": "Bò Wagyu A5", "en": "Wagyu A5 Beef", "ja": "和牛A5"}'),
('m1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Beef', 'Thăn ngoại bò Mỹ', 200000, 80000, '{"vi": "Thăn ngoại bò Mỹ", "en": "US Striploin", "ja": "USサーロイン"}'),
('m1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Side', 'Salad rau củ', 50000, 15000, '{"vi": "Salad rau củ", "en": "Vegetable Salad", "ja": "野菜サラダ"}'),
('m1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Drink', 'Coca Cola', 30000, 10000, '{"vi": "Coca Cola", "en": "Coca Cola", "ja": "コカ・コーラ"}'),
('m1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'Drink', 'Soju', 100000, 40000, '{"vi": "Rượu Soju", "en": "Soju", "ja": "焼酎"}')
ON CONFLICT DO NOTHING;

INSERT INTO public.packages (id, branch_id, name, type, price, items_included, i18n_name) VALUES
('p1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Buffet Standard', 'buffet', 380000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000002", "limit": null}, {"menu_item_id": "m1000000-0000-0000-0000-000000000003", "limit": null}]', '{"vi": "Buffet Tiêu chuẩn", "en": "Standard Buffet", "ja": "スタンダードビュッフェ"}'),
('p1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Buffet Premium', 'buffet', 680000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000001", "limit": 2}, {"menu_item_id": "m1000000-0000-0000-0000-000000000002", "limit": null}]', '{"vi": "Buffet Cao cấp", "en": "Premium Buffet", "ja": "プレミアムビュッフェ"}'),
('p1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Drink Package A', 'drink', 150000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000004", "limit": null}]', '{"vi": "Gói Nước A", "en": "Drink Package A", "ja": "ドリンクパックA"}')
ON CONFLICT DO NOTHING;

-- KPI/Marketing settings moved to branch_settings
INSERT INTO public.branch_settings (branch_id, key, value) VALUES
('b1000000-0000-0000-0000-000000000001', 'kpi.revenue.daily', '{"target_value": 50000000, "period_start": "2026-06-01", "period_end": "2026-12-31"}'),
('b1000000-0000-0000-0000-000000000001', 'kpi.guest_count.daily', '{"target_value": 150, "period_start": "2026-06-01", "period_end": "2026-12-31"}'),
('b1000000-0000-0000-0000-000000000001', 'marketing.facebook_ads', '{"amount": 10000000, "period_start": "2026-06-01", "period_end": "2026-06-30"}')
ON CONFLICT DO NOTHING;



-- ==========================================
-- FILE: 20260701000002_tax_records_accounting_rls.sql
-- ==========================================
-- Siết chặt quyền truy cập bảng tax_records 
-- Chỉ cho phép role 'accounting' và 'admin' được chỉnh sửa (Thêm/Sửa/Xóa).
-- Role 'manager' chỉ được xem (SELECT).
-- Các role khác (thu ngân, bếp, phục vụ) KHÔNG được truy cập.

-- 1. Xóa policy lỏng lẻo cũ
DROP POLICY IF EXISTS "tax_records_branch_access" ON public.tax_records;

-- 2. Policy cho quyền XEM (SELECT): admin, accounting, manager
CREATE POLICY "tax_records_select" ON public.tax_records
  FOR SELECT
  USING (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting', 'manager']::user_role[])
    )
  );

-- 3. Policy cho quyền GHI (INSERT, UPDATE, DELETE): CHỈ admin và accounting
CREATE POLICY "tax_records_modify" ON public.tax_records
  FOR ALL
  USING (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting']::user_role[])
    )
  )
  WITH CHECK (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting']::user_role[])
    )
  );

-- 4. Vá lại hàm RPC generate_tax_record để chặn các role không phận sự gọi hàm
CREATE OR REPLACE FUNCTION public.generate_tax_record(
  p_branch_id    uuid,
  p_period_type  text,
  p_period_start date,
  p_period_end   date
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_gross_revenue numeric(16,2);
  v_vat_amount    numeric(16,2);
  v_discount      numeric(16,2);
  v_expense       numeric(16,2);
  v_tax_id        uuid;
BEGIN
  -- CHẶN NGAY nếu không phải admin hoặc accounting
  IF NOT public.has_role(ARRAY['admin', 'accounting']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: only admin or accounting can generate tax records' USING ERRCODE = '28000';
  END IF;

  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  SELECT
    COALESCE(SUM(grand_total), 0),
    COALESCE(SUM(vat_8_amount + vat_10_amount), 0),
    COALESCE(SUM(discount_total), 0)
  INTO v_gross_revenue, v_vat_amount, v_discount
  FROM public.bills
  WHERE branch_id = p_branch_id
    AND status = 'PAID'
    AND created_at::date BETWEEN p_period_start AND p_period_end;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense
  FROM public.financial_transactions
  WHERE branch_id = p_branch_id
    AND transaction_type = 'EXPENSE'
    AND transaction_date::date BETWEEN p_period_start AND p_period_end;

  INSERT INTO public.tax_records (
    branch_id, period_type, period_start, period_end,
    gross_revenue, discount_total, net_revenue,
    vat_amount, expense_total, gross_profit, status
  ) VALUES (
    p_branch_id, p_period_type, p_period_start, p_period_end,
    v_gross_revenue, v_discount, v_gross_revenue - v_discount,
    v_vat_amount, v_expense, v_gross_revenue - v_discount - v_expense, 'DRAFT'
  )
  ON CONFLICT (branch_id, period_type, period_start)
  DO UPDATE SET
    gross_revenue  = EXCLUDED.gross_revenue,
    discount_total = EXCLUDED.discount_total,
    net_revenue    = EXCLUDED.net_revenue,
    vat_amount     = EXCLUDED.vat_amount,
    expense_total  = EXCLUDED.expense_total,
    gross_profit   = EXCLUDED.gross_profit,
    status         = 'DRAFT'
  RETURNING id INTO v_tax_id;

  RETURN v_tax_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) TO authenticated;

