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

CREATE OR REPLACE FUNCTION public.current_user_role() RETURNS text AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::jsonb ->> 'role',
    (SELECT role::text FROM public.users WHERE id = auth.uid())
  );
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION public.has_role(roles user_role[]) RETURNS boolean AS $$
  SELECT public.current_user_role() = ANY(roles::text[]);
$$ LANGUAGE sql STABLE;

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
