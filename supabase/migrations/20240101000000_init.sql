-- ============================================================================
-- NGUU CAT POS -- DATABASE V6 SIMPLIFIED
-- Target: Supabase PostgreSQL 17
-- Scope: greenfield storage schema for one company, multiple branches
--
-- This file contains storage, structural constraints, indexes, RLS, grants and
-- the atomic command/RPC boundary required for split bill, payment, refund and
-- debt. It does not contain UI workflow, state-machine triggers or provider I/O.
--
-- IMPORTANT:
--   1. This is a greenfield source of truth, not an in-place migration.
--   2. Test on a disposable local/staging database before any cutover.
--   3. JWT authorization expects role_codes[] and branch_id in app_metadata.
-- ============================================================================

begin;

create extension if not exists pgcrypto with schema extensions;

create schema if not exists app_private;
revoke all on schema app_private from public;

-- ============================================================================
-- A. BRANCH, AUTH, AUDIT AND INTEGRATION
-- ============================================================================

create table public.branches (
  branch_id uuid primary key default gen_random_uuid(),
  branch_code text not null,
  branch_name text not null,
  address text,
  phone text,
  timezone text not null default 'Asia/Ho_Chi_Minh',
  tax_code text,
  settings jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branches_branch_code_key unique (branch_code),
  constraint branches_settings_object_check
    check (jsonb_typeof(settings) = 'object')
);

create table public.profiles (
  profile_id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null,
  phone text,
  email text,
  preferences jsonb not null default '{}'::jsonb,
  account_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_account_status_check
    check (account_status in ('active', 'locked', 'disabled')),
  constraint profiles_preferences_object_check
    check (jsonb_typeof(preferences) = 'object')
);

create unique index profiles_email_key
  on public.profiles (lower(email))
  where email is not null;

create table public.roles (
  role_id uuid primary key default gen_random_uuid(),
  role_code text not null,
  role_name text not null,
  is_active boolean not null default true,
  constraint roles_role_code_key unique (role_code),
  constraint roles_role_code_format_check
    check (role_code ~ '^[a-z][a-z0-9_]*$')
);

create table public.staff_assignments (
  staff_assignment_id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(profile_id) on delete restrict,
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  role_id uuid not null references public.roles(role_id) on delete restrict,
  approval_pin_hash text,
  is_active boolean not null default true,
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  constraint staff_assignments_branch_scope_key
    unique (branch_id, staff_assignment_id),
  constraint staff_assignments_period_check
    check (ended_at is null or ended_at >= assigned_at)
);

create unique index staff_assignments_one_active_role_per_branch
  on public.staff_assignments (profile_id, branch_id, role_id)
  where is_active and ended_at is null;

create table public.audit_logs (
  audit_log_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  actor_profile_id uuid references public.profiles(profile_id) on delete set null,
  actor_role_codes_snapshot text[] not null,
  action_code text not null,
  target_type text not null,
  target_id uuid,
  detail jsonb not null default '{}'::jsonb,
  correlation_id uuid,
  created_at timestamptz not null default now(),
  constraint audit_logs_branch_scope_key unique (branch_id, audit_log_id),
  constraint audit_logs_role_snapshot_check
    check (cardinality(actor_role_codes_snapshot) > 0),
  constraint audit_logs_detail_object_check
    check (jsonb_typeof(detail) = 'object')
);

create or replace function app_private.prevent_audit_log_mutation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'audit_logs is append-only';
end;
$$;

revoke all on function app_private.prevent_audit_log_mutation() from public;

create trigger audit_logs_append_only
before update or delete on public.audit_logs
for each row execute function app_private.prevent_audit_log_mutation();

create table public.notifications (
  notification_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  target_profile_id uuid references public.profiles(profile_id) on delete set null,
  notification_type text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_branch_scope_key unique (branch_id, notification_id),
  constraint notifications_payload_object_check
    check (jsonb_typeof(payload) = 'object')
);

create table public.outbox_jobs (
  outbox_job_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  job_type text not null,
  reference_type text not null,
  reference_id uuid,
  payload jsonb not null,
  status text not null default 'pending',
  idempotency_key text,
  attempt_count integer not null default 0,
  next_attempt_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint outbox_jobs_branch_scope_key unique (branch_id, outbox_job_id),
  constraint outbox_jobs_status_check
    check (status in ('pending', 'processing', 'completed', 'failed')),
  constraint outbox_jobs_attempt_count_check check (attempt_count >= 0),
  constraint outbox_jobs_payload_object_check
    check (jsonb_typeof(payload) = 'object')
);

create unique index outbox_jobs_idempotency_key
  on public.outbox_jobs (branch_id, idempotency_key)
  where idempotency_key is not null;

-- ============================================================================
-- B. SHIFT
-- ============================================================================

create table public.shifts (
  shift_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  opened_by_profile_id uuid not null references public.profiles(profile_id) on delete restrict,
  closed_by_profile_id uuid references public.profiles(profile_id) on delete restrict,
  opening_cash_vnd bigint not null default 0,
  expected_cash_vnd bigint,
  counted_cash_vnd bigint,
  variance_cash_vnd bigint,
  expected_bank_vnd bigint,
  counted_bank_vnd bigint,
  note text,
  status text not null default 'open',
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  reconciled_at timestamptz,
  created_at timestamptz not null default now(),
  constraint shifts_branch_scope_key unique (branch_id, shift_id),
  constraint shifts_status_check
    check (status in ('open', 'closed', 'reconciled')),
  constraint shifts_money_check check (
    opening_cash_vnd >= 0
    and (expected_cash_vnd is null or expected_cash_vnd >= 0)
    and (counted_cash_vnd is null or counted_cash_vnd >= 0)
    and (expected_bank_vnd is null or expected_bank_vnd >= 0)
    and (counted_bank_vnd is null or counted_bank_vnd >= 0)
  ),
  constraint shifts_time_check
    check (closed_at is null or closed_at >= opened_at)
);

create unique index shifts_one_open_per_branch
  on public.shifts (branch_id)
  where status = 'open';

-- ============================================================================
-- C. HALL, RESERVATION AND CRM
-- ============================================================================

create table public.areas (
  area_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  area_code text not null,
  area_name text not null,
  sort_order integer not null default 0,
  layout_config jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  constraint areas_branch_scope_key unique (branch_id, area_id),
  constraint areas_code_key unique (branch_id, area_code),
  constraint areas_layout_config_object_check
    check (jsonb_typeof(layout_config) = 'object')
);

create table public.dining_tables (
  dining_table_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  area_id uuid not null,
  table_code text not null,
  table_name text,
  capacity integer not null,
  position_x numeric(12,3) not null default 0,
  position_y numeric(12,3) not null default 0,
  width numeric(12,3) not null default 1,
  height numeric(12,3) not null default 1,
  availability_status text not null default 'available',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dining_tables_branch_scope_key unique (branch_id, dining_table_id),
  constraint dining_tables_code_key unique (branch_id, table_code),
  constraint dining_tables_area_fk
    foreign key (branch_id, area_id)
    references public.areas(branch_id, area_id) on delete restrict,
  constraint dining_tables_capacity_check check (capacity > 0),
  constraint dining_tables_size_check check (width > 0 and height > 0),
  constraint dining_tables_availability_status_check
    check (availability_status in ('available', 'cleaning', 'maintenance'))
);

create table public.customers (
  customer_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  full_name text,
  normalized_phone text,
  email text,
  birthday date,
  source_channel text,
  profile_data jsonb not null default '{}'::jsonb,
  note text,
  is_active boolean not null default true,
  anonymized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customers_branch_scope_key unique (branch_id, customer_id),
  constraint customers_identity_check
    check (full_name is not null or normalized_phone is not null or anonymized_at is not null),
  constraint customers_profile_data_object_check
    check (jsonb_typeof(profile_data) = 'object')
);

create unique index customers_phone_key
  on public.customers (branch_id, normalized_phone)
  where normalized_phone is not null and anonymized_at is null;

create table public.reservations (
  reservation_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  customer_id uuid,
  guest_name_snapshot text not null,
  phone_snapshot text,
  guest_count integer not null,
  reserved_from timestamptz not null,
  reserved_to timestamptz not null,
  source_channel text,
  source_reference text,
  deposit_amount_vnd bigint not null default 0,
  deposit_method text,
  deposit_status text not null default 'none',
  status text not null default 'new',
  extra_data jsonb not null default '{}'::jsonb,
  note text,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reservations_branch_scope_key unique (branch_id, reservation_id),
  constraint reservations_customer_fk
    foreign key (branch_id, customer_id)
    references public.customers(branch_id, customer_id) on delete restrict,
  constraint reservations_guest_count_check check (guest_count > 0),
  constraint reservations_time_check check (reserved_to > reserved_from),
  constraint reservations_deposit_amount_check check (deposit_amount_vnd >= 0),
  constraint reservations_deposit_status_check
    check (deposit_status in ('none', 'pending', 'paid', 'refunded', 'forfeited', 'applied')),
  constraint reservations_status_check
    check (status in (
      'waiting', 'new', 'confirmed', 'arrived', 'checked_in',
      'completed', 'cancelled', 'no_show'
    )),
  constraint reservations_extra_data_object_check
    check (jsonb_typeof(extra_data) = 'object')
);

create table public.reservation_tables (
  reservation_table_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  reservation_id uuid not null,
  dining_table_id uuid not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  constraint reservation_tables_branch_scope_key
    unique (branch_id, reservation_table_id),
  constraint reservation_tables_reservation_key
    unique (reservation_id, dining_table_id),
  constraint reservation_tables_reservation_fk
    foreign key (branch_id, reservation_id)
    references public.reservations(branch_id, reservation_id) on delete restrict,
  constraint reservation_tables_table_fk
    foreign key (branch_id, dining_table_id)
    references public.dining_tables(branch_id, dining_table_id) on delete restrict
);

create unique index reservation_tables_one_primary
  on public.reservation_tables (reservation_id)
  where is_primary;

create table public.menu_categories (
  menu_category_id uuid primary key default gen_random_uuid(),
  owner_branch_id uuid references public.branches(branch_id) on delete restrict,
  category_code text not null,
  category_name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index menu_categories_company_code_key
  on public.menu_categories (category_code)
  where owner_branch_id is null;

create unique index menu_categories_branch_code_key
  on public.menu_categories (owner_branch_id, category_code)
  where owner_branch_id is not null;

create table public.menu_items (
  menu_item_id uuid primary key default gen_random_uuid(),
  owner_branch_id uuid references public.branches(branch_id) on delete restrict,
  menu_category_id uuid not null references public.menu_categories(menu_category_id) on delete restrict,
  item_code text not null,
  item_name text not null,
  item_type text not null,
  unit_name text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint menu_items_type_check
    check (item_type in ('food', 'drink', 'buffet_package', 'set_menu', 'topping'))
);

create unique index menu_items_company_code_key
  on public.menu_items (item_code)
  where owner_branch_id is null;

create unique index menu_items_branch_code_key
  on public.menu_items (owner_branch_id, item_code)
  where owner_branch_id is not null;

create table public.branch_menu_items (
  branch_menu_item_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  menu_item_id uuid not null references public.menu_items(menu_item_id) on delete restrict,
  local_name text,
  base_price_vnd bigint not null default 0,
  vat_rate numeric(7,4) not null default 0,
  availability_status text not null default 'available',
  display_config jsonb not null default '{}'::jsonb,
  modifier_config jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branch_menu_items_branch_scope_key
    unique (branch_id, branch_menu_item_id),
  constraint branch_menu_items_item_key unique (branch_id, menu_item_id),
  constraint branch_menu_items_price_check check (base_price_vnd >= 0),
  constraint branch_menu_items_vat_rate_check check (vat_rate between 0 and 100),
  constraint branch_menu_items_availability_status_check
    check (availability_status in ('available', 'out_of_stock', 'hidden')),
  constraint branch_menu_items_display_config_object_check
    check (jsonb_typeof(display_config) = 'object'),
  constraint branch_menu_items_modifier_config_object_check
    check (jsonb_typeof(modifier_config) = 'object')
);

create table public.dining_sessions (
  dining_session_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  reservation_id uuid,
  customer_id uuid,
  guest_count integer not null,
  service_mode text not null,
  language_code text not null default 'vi',
  service_config jsonb not null default '{}'::jsonb,
  course_locked_at timestamptz,
  service_ends_at timestamptz,
  qr_token_hash text,
  qr_expires_at timestamptz,
  status text not null default 'open',
  opened_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dining_sessions_branch_scope_key unique (branch_id, dining_session_id),
  constraint dining_sessions_reservation_fk
    foreign key (branch_id, reservation_id)
    references public.reservations(branch_id, reservation_id) on delete restrict,
  constraint dining_sessions_customer_fk
    foreign key (branch_id, customer_id)
    references public.customers(branch_id, customer_id) on delete restrict,
  constraint dining_sessions_reservation_key unique (reservation_id),
  constraint dining_sessions_guest_count_check check (guest_count > 0),
  constraint dining_sessions_service_mode_check
    check (service_mode in ('buffet', 'set_menu')),
  constraint dining_sessions_status_check
    check (status in ('open', 'ordering', 'checkout_requested', 'closed', 'cancelled')),
  constraint dining_sessions_service_time_check
    check (
      service_ends_at is null
      or (course_locked_at is not null and service_ends_at > course_locked_at)
    ),
  constraint dining_sessions_close_time_check
    check (closed_at is null or closed_at >= opened_at),
  constraint dining_sessions_qr_expiry_check
    check (qr_expires_at is null or qr_expires_at >= opened_at),
  constraint dining_sessions_service_config_object_check
    check (jsonb_typeof(service_config) = 'object')
);

create table public.session_guests (
  session_guest_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  dining_session_id uuid not null,
  guest_no integer not null,
  guest_label text,
  guest_type text not null default 'adult',
  package_branch_menu_item_id uuid not null,
  package_name_snapshot text not null,
  package_price_vnd_snapshot bigint not null,
  vat_rate_snapshot numeric(7,4) not null default 0,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint session_guests_branch_scope_key unique (branch_id, session_guest_id),
  constraint session_guests_number_key unique (dining_session_id, guest_no),
  constraint session_guests_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint session_guests_package_fk
    foreign key (branch_id, package_branch_menu_item_id)
    references public.branch_menu_items(branch_id, branch_menu_item_id) on delete restrict,
  constraint session_guests_guest_no_check check (guest_no > 0),
  constraint session_guests_guest_type_check
    check (guest_type in ('adult', 'child')),
  constraint session_guests_price_check check (
    package_price_vnd_snapshot >= 0 and vat_rate_snapshot between 0 and 100
  ),
  constraint session_guests_status_check
    check (status in ('active', 'cancelled'))
);

create table public.session_tables (
  session_table_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  dining_session_id uuid not null,
  dining_table_id uuid not null,
  is_primary boolean not null default false,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  constraint session_tables_branch_scope_key unique (branch_id, session_table_id),
  constraint session_tables_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint session_tables_table_fk
    foreign key (branch_id, dining_table_id)
    references public.dining_tables(branch_id, dining_table_id) on delete restrict,
  constraint session_tables_period_check
    check (left_at is null or left_at >= joined_at)
);

create unique index session_tables_one_active_session_per_table
  on public.session_tables (dining_table_id)
  where left_at is null;

create unique index session_tables_one_primary_table
  on public.session_tables (dining_session_id)
  where left_at is null and is_primary;

create table public.service_requests (
  service_request_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  dining_session_id uuid not null,
  request_type text not null,
  note text,
  status text not null default 'pending',
  requested_at timestamptz not null default now(),
  handled_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  handled_at timestamptz,
  constraint service_requests_branch_scope_key unique (branch_id, service_request_id),
  constraint service_requests_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint service_requests_type_check
    check (request_type in ('call_staff', 'add_charcoal', 'water', 'checkout', 'other')),
  constraint service_requests_status_check
    check (status in ('pending', 'accepted', 'completed', 'cancelled')),
  constraint service_requests_handled_time_check
    check (handled_at is null or handled_at >= requested_at)
);

create table public.customer_feedbacks (
  customer_feedback_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  customer_id uuid,
  dining_session_id uuid not null,
  rating integer not null,
  comment text,
  survey_data jsonb not null default '{}'::jsonb,
  photo_consent boolean,
  google_review_requested_at timestamptz,
  created_at timestamptz not null default now(),
  constraint customer_feedbacks_branch_scope_key
    unique (branch_id, customer_feedback_id),
  constraint customer_feedbacks_customer_fk
    foreign key (branch_id, customer_id)
    references public.customers(branch_id, customer_id) on delete restrict,
  constraint customer_feedbacks_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint customer_feedbacks_rating_check check (rating between 1 and 5),
  constraint customer_feedbacks_survey_data_object_check
    check (jsonb_typeof(survey_data) = 'object')
);

-- ============================================================================
-- D. BUFFET, BOM AND INVENTORY
-- ============================================================================

create table public.package_details (
  package_detail_id uuid primary key default gen_random_uuid(),
  package_menu_item_id uuid not null references public.menu_items(menu_item_id) on delete restrict,
  included_menu_item_id uuid not null references public.menu_items(menu_item_id) on delete restrict,
  detail_no integer not null,
  included_quantity_per_guest numeric(14,3),
  max_quantity_per_order numeric(14,3),
  is_unlimited boolean not null default false,
  created_at timestamptz not null default now(),
  constraint package_details_item_key
    unique (package_menu_item_id, included_menu_item_id),
  constraint package_details_order_key
    unique (package_menu_item_id, detail_no),
  constraint package_details_not_self_check
    check (package_menu_item_id <> included_menu_item_id),
  constraint package_details_detail_no_check check (detail_no > 0),
  constraint package_details_quantity_check check (
    (is_unlimited and included_quantity_per_guest is null)
    or (
      not is_unlimited
      and included_quantity_per_guest is not null
      and included_quantity_per_guest > 0
    )
  ),
  constraint package_details_max_order_check
    check (max_quantity_per_order is null or max_quantity_per_order > 0)
);

create table public.ingredients (
  ingredient_id uuid primary key default gen_random_uuid(),
  owner_branch_id uuid references public.branches(branch_id) on delete restrict,
  ingredient_code text not null,
  ingredient_name text not null,
  base_unit text not null,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ingredients_base_unit_check
    check (base_unit in ('kg', 'g', 'l', 'ml', 'pcs')),
  constraint ingredients_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create unique index ingredients_company_code_key
  on public.ingredients (ingredient_code)
  where owner_branch_id is null;

create unique index ingredients_branch_code_key
  on public.ingredients (owner_branch_id, ingredient_code)
  where owner_branch_id is not null;

create table public.branch_ingredients (
  branch_ingredient_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  ingredient_id uuid not null references public.ingredients(ingredient_id) on delete restrict,
  minimum_stock numeric(18,6) not null default 0,
  default_cost_vnd bigint not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branch_ingredients_branch_scope_key
    unique (branch_id, branch_ingredient_id),
  constraint branch_ingredients_item_key unique (branch_id, ingredient_id),
  constraint branch_ingredients_minimum_stock_check check (minimum_stock >= 0),
  constraint branch_ingredients_default_cost_check check (default_cost_vnd >= 0)
);

create table public.bom_details (
  bom_detail_id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(menu_item_id) on delete restrict,
  ingredient_id uuid not null references public.ingredients(ingredient_id) on delete restrict,
  detail_no integer not null,
  quantity_in_base_unit numeric(18,6) not null,
  waste_rate numeric(7,4) not null default 0,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bom_details_ingredient_key unique (menu_item_id, ingredient_id),
  constraint bom_details_order_key unique (menu_item_id, detail_no),
  constraint bom_details_detail_no_check check (detail_no > 0),
  constraint bom_details_quantity_check check (quantity_in_base_unit > 0),
  constraint bom_details_waste_rate_check check (waste_rate between 0 and 100)
);

create table public.inventory_transactions (
  inventory_transaction_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  branch_ingredient_id uuid not null,
  transaction_type text not null,
  quantity_delta numeric(18,6) not null,
  unit_cost_vnd bigint,
  reference_type text,
  reference_id uuid,
  idempotency_key text,
  note text,
  evidence jsonb not null default '{}'::jsonb,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint inventory_transactions_branch_scope_key
    unique (branch_id, inventory_transaction_id),
  constraint inventory_transactions_ingredient_fk
    foreign key (branch_id, branch_ingredient_id)
    references public.branch_ingredients(branch_id, branch_ingredient_id) on delete restrict,
  constraint inventory_transactions_type_check
    check (transaction_type in ('receipt', 'sale_usage', 'adjustment', 'waste', 'return')),
  constraint inventory_transactions_quantity_check check (quantity_delta <> 0),
  constraint inventory_transactions_cost_check
    check (unit_cost_vnd is null or unit_cost_vnd >= 0),
  constraint inventory_transactions_reference_check check (
    (reference_type is null and reference_id is null)
    or (reference_type is not null and reference_id is not null)
  ),
  constraint inventory_transactions_evidence_object_check
    check (jsonb_typeof(evidence) = 'object')
);

create unique index inventory_transactions_idempotency_key
  on public.inventory_transactions (branch_id, idempotency_key)
  where idempotency_key is not null;

-- ============================================================================
-- E. ORDER AND KITCHEN
-- ============================================================================

create table public.orders (
  order_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  dining_session_id uuid not null,
  shift_id uuid,
  order_number text not null,
  order_source text not null,
  status text not null default 'draft',
  note text,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  submitted_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_branch_scope_key unique (branch_id, order_id),
  constraint orders_number_key unique (branch_id, order_number),
  constraint orders_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint orders_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint orders_source_check
    check (order_source in ('reception', 'hall', 'tablet')),
  constraint orders_status_check
    check (status in ('draft', 'submitted', 'preparing', 'served', 'completed', 'cancelled')),
  constraint orders_submit_time_check
    check (submitted_at is null or submitted_at >= created_at),
  constraint orders_complete_time_check
    check (
      completed_at is null
      or (submitted_at is not null and completed_at >= submitted_at)
    )
);

create table public.order_details (
  order_detail_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  order_id uuid not null,
  detail_no integer not null,
  branch_menu_item_id uuid not null,
  item_name_snapshot text not null,
  quantity numeric(14,3) not null,
  chargeable_quantity numeric(14,3) not null,
  unit_price_vnd_snapshot bigint not null,
  vat_rate_snapshot numeric(7,4) not null,
  detail_total_vnd bigint not null,
  kitchen_status text not null default 'new',
  modifiers jsonb not null default '{}'::jsonb,
  note text,
  cancelled_quantity numeric(14,3) not null default 0,
  cancellation_reason text,
  cancelled_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  approved_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_details_branch_scope_key unique (branch_id, order_detail_id),
  constraint order_details_order_key unique (order_id, detail_no),
  constraint order_details_order_fk
    foreign key (branch_id, order_id)
    references public.orders(branch_id, order_id) on delete restrict,
  constraint order_details_menu_item_fk
    foreign key (branch_id, branch_menu_item_id)
    references public.branch_menu_items(branch_id, branch_menu_item_id) on delete restrict,
  constraint order_details_detail_no_check check (detail_no > 0),
  constraint order_details_quantity_check check (
    quantity > 0
    and chargeable_quantity >= 0
    and chargeable_quantity <= quantity
    and cancelled_quantity >= 0
    and cancelled_quantity <= quantity
  ),
  constraint order_details_money_check check (
    unit_price_vnd_snapshot >= 0
    and detail_total_vnd >= 0
    and vat_rate_snapshot between 0 and 100
  ),
  constraint order_details_kitchen_status_check
    check (kitchen_status in ('new', 'sent', 'preparing', 'ready', 'served', 'cancelled')),
  constraint order_details_cancellation_check check (
    (cancelled_quantity = 0 and cancelled_at is null)
    or (
      cancelled_quantity > 0
      and cancelled_at is not null
      and cancellation_reason is not null
      and cancelled_by_profile_id is not null
    )
  ),
  constraint order_details_modifiers_object_check
    check (jsonb_typeof(modifiers) = 'object')
);

-- ============================================================================
-- F. BILLING, PAYMENT, VAT, DEBT AND EXPENSE
-- ============================================================================

create table public.vouchers (
  voucher_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  voucher_code text not null,
  voucher_name text not null,
  discount_type text not null,
  discount_value numeric(14,4) not null,
  max_discount_vnd bigint,
  minimum_bill_vnd bigint not null default 0,
  usage_limit integer,
  valid_from timestamptz not null,
  valid_to timestamptz not null,
  conditions jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vouchers_branch_scope_key unique (branch_id, voucher_id),
  constraint vouchers_code_key unique (branch_id, voucher_code),
  constraint vouchers_type_check
    check (discount_type in ('percent', 'fixed_amount')),
  constraint vouchers_value_check check (
    (discount_type = 'percent' and discount_value > 0 and discount_value <= 100)
    or (discount_type = 'fixed_amount' and discount_value > 0)
  ),
  constraint vouchers_money_check check (
    minimum_bill_vnd >= 0
    and (max_discount_vnd is null or max_discount_vnd > 0)
  ),
  constraint vouchers_usage_limit_check
    check (usage_limit is null or usage_limit > 0),
  constraint vouchers_period_check check (valid_to > valid_from),
  constraint vouchers_conditions_object_check
    check (jsonb_typeof(conditions) = 'object')
);

create table public.bills (
  bill_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  dining_session_id uuid not null,
  shift_id uuid,
  customer_id uuid,
  voucher_id uuid,
  bill_number text not null,
  subtotal_vnd bigint not null default 0,
  discount_vnd bigint not null default 0,
  service_charge_vnd bigint not null default 0,
  vat_vnd bigint not null default 0,
  deposit_applied_vnd bigint not null default 0,
  grand_total_vnd bigint not null default 0,
  paid_total_vnd bigint not null default 0,
  debt_total_vnd bigint not null default 0,
  status text not null default 'open',
  cashier_profile_id uuid references public.profiles(profile_id) on delete set null,
  note text,
  issued_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bills_branch_scope_key unique (branch_id, bill_id),
  constraint bills_number_key unique (branch_id, bill_number),
  constraint bills_session_fk
    foreign key (branch_id, dining_session_id)
    references public.dining_sessions(branch_id, dining_session_id) on delete restrict,
  constraint bills_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint bills_customer_fk
    foreign key (branch_id, customer_id)
    references public.customers(branch_id, customer_id) on delete restrict,
  constraint bills_voucher_fk
    foreign key (branch_id, voucher_id)
    references public.vouchers(branch_id, voucher_id) on delete restrict,
  constraint bills_money_check check (
    subtotal_vnd >= 0
    and discount_vnd >= 0
    and service_charge_vnd >= 0
    and vat_vnd >= 0
    and deposit_applied_vnd >= 0
    and grand_total_vnd >= 0
    and paid_total_vnd >= 0
    and debt_total_vnd >= 0
    and discount_vnd <= subtotal_vnd + service_charge_vnd
    and deposit_applied_vnd <= grand_total_vnd
  ),
  constraint bills_status_check
    check (status in ('open', 'partially_paid', 'paid', 'debt', 'void')),
  constraint bills_close_time_check
    check (closed_at is null or closed_at >= created_at)
);

create table public.bill_details (
  bill_detail_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  bill_id uuid not null,
  detail_no integer not null,
  order_detail_id uuid,
  session_guest_id uuid,
  item_name_snapshot text not null,
  quantity numeric(14,3) not null,
  unit_price_vnd bigint not null,
  discount_vnd bigint not null default 0,
  vat_rate numeric(7,4) not null,
  vat_vnd bigint not null default 0,
  detail_total_vnd bigint not null,
  created_at timestamptz not null default now(),
  constraint bill_details_branch_scope_key unique (branch_id, bill_detail_id),
  constraint bill_details_order_key unique (bill_id, detail_no),
  constraint bill_details_bill_fk
    foreign key (branch_id, bill_id)
    references public.bills(branch_id, bill_id) on delete restrict,
  constraint bill_details_order_detail_fk
    foreign key (branch_id, order_detail_id)
    references public.order_details(branch_id, order_detail_id) on delete restrict,
  constraint bill_details_session_guest_fk
    foreign key (branch_id, session_guest_id)
    references public.session_guests(branch_id, session_guest_id) on delete restrict,
  constraint bill_details_source_check
    check (num_nonnulls(order_detail_id, session_guest_id) = 1),
  constraint bill_details_detail_no_check check (detail_no > 0),
  constraint bill_details_quantity_check check (quantity > 0),
  constraint bill_details_money_check check (
    unit_price_vnd >= 0
    and discount_vnd >= 0
    and vat_rate between 0 and 100
    and vat_vnd >= 0
    and detail_total_vnd >= 0
  )
);

create table public.payment_intents (
  payment_intent_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  bill_id uuid,
  reservation_id uuid,
  shift_id uuid,
  payment_method text not null,
  amount_vnd bigint not null,
  status text not null default 'pending',
  idempotency_key text not null,
  provider text,
  provider_intent_reference text,
  qr_payload text,
  expires_at timestamptz,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  succeeded_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_intents_branch_scope_key unique (branch_id, payment_intent_id),
  constraint payment_intents_bill_fk
    foreign key (branch_id, bill_id)
    references public.bills(branch_id, bill_id) on delete restrict,
  constraint payment_intents_reservation_fk
    foreign key (branch_id, reservation_id)
    references public.reservations(branch_id, reservation_id) on delete restrict,
  constraint payment_intents_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint payment_intents_target_check
    check (num_nonnulls(bill_id, reservation_id) = 1),
  constraint payment_intents_method_check
    check (payment_method in ('card', 'vietqr')),
  constraint payment_intents_amount_check check (amount_vnd > 0),
  constraint payment_intents_status_check
    check (status in ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'expired')),
  constraint payment_intents_lifecycle_check check (
    (status = 'succeeded' and succeeded_at is not null and cancelled_at is null)
    or (status = 'cancelled' and cancelled_at is not null and succeeded_at is null)
    or status in ('pending', 'processing', 'failed', 'expired')
  ),
  constraint payment_intents_expiry_check
    check (expires_at is null or expires_at > created_at),
  constraint payment_intents_idempotency_key unique (branch_id, idempotency_key)
);

create table public.payment_attempts (
  payment_attempt_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  payment_intent_id uuid not null,
  attempt_no integer not null,
  status text not null,
  provider_reference text,
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  failure_code text,
  failure_message text,
  attempted_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint payment_attempts_branch_scope_key unique (branch_id, payment_attempt_id),
  constraint payment_attempts_number_key unique (payment_intent_id, attempt_no),
  constraint payment_attempts_intent_fk
    foreign key (branch_id, payment_intent_id)
    references public.payment_intents(branch_id, payment_intent_id) on delete restrict,
  constraint payment_attempts_attempt_no_check check (attempt_no > 0),
  constraint payment_attempts_status_check
    check (status in ('started', 'succeeded', 'failed', 'cancelled')),
  constraint payment_attempts_completed_check check (
    (status = 'started' and completed_at is null)
    or (status <> 'started' and completed_at is not null)
  ),
  constraint payment_attempts_request_object_check
    check (jsonb_typeof(request_payload) = 'object'),
  constraint payment_attempts_response_object_check
    check (jsonb_typeof(response_payload) = 'object')
);

create unique index payment_attempts_provider_reference_key
  on public.payment_attempts (branch_id, provider_reference)
  where provider_reference is not null;

create table public.payments (
  payment_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  bill_id uuid,
  reservation_id uuid,
  payment_intent_id uuid,
  shift_id uuid,
  related_payment_id uuid,
  transaction_type text not null,
  payment_method text not null,
  amount_vnd bigint not null,
  provider_reference text,
  idempotency_key text,
  received_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  paid_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint payments_branch_scope_key unique (branch_id, payment_id),
  constraint payments_bill_fk
    foreign key (branch_id, bill_id)
    references public.bills(branch_id, bill_id) on delete restrict,
  constraint payments_reservation_fk
    foreign key (branch_id, reservation_id)
    references public.reservations(branch_id, reservation_id) on delete restrict,
  constraint payments_intent_fk
    foreign key (branch_id, payment_intent_id)
    references public.payment_intents(branch_id, payment_intent_id) on delete restrict,
  constraint payments_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint payments_related_payment_fk
    foreign key (branch_id, related_payment_id)
    references public.payments(branch_id, payment_id) on delete restrict,
  constraint payments_target_check check (num_nonnulls(bill_id, reservation_id) = 1),
  constraint payments_type_check
    check (transaction_type in ('payment', 'refund')),
  constraint payments_method_check
    check (payment_method in ('cash', 'card', 'vietqr', 'bank_transfer')),
  constraint payments_amount_check check (amount_vnd > 0),
  constraint payments_refund_check check (
    (transaction_type = 'payment' and related_payment_id is null)
    or (transaction_type = 'refund' and related_payment_id is not null)
  ),
  constraint payments_intent_method_check check (
    transaction_type = 'refund'
    or (payment_method = 'cash' and payment_intent_id is null)
    or (payment_method in ('card', 'vietqr') and payment_intent_id is not null)
    or (payment_method = 'bank_transfer' and payment_intent_id is null)
  ),
  constraint payments_not_self_check
    check (related_payment_id is null or related_payment_id <> payment_id),
  constraint payments_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create unique index payments_idempotency_key
  on public.payments (branch_id, idempotency_key)
  where idempotency_key is not null;

create unique index payments_provider_reference_key
  on public.payments (branch_id, provider_reference)
  where provider_reference is not null;

create unique index payments_one_capture_per_intent
  on public.payments (payment_intent_id)
  where payment_intent_id is not null and transaction_type = 'payment';

create table public.invoices (
  invoice_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  bill_id uuid not null,
  related_invoice_id uuid,
  invoice_type text not null default 'original',
  invoice_number text,
  provider text,
  provider_status text not null default 'pending',
  buyer_snapshot jsonb not null,
  provider_payload jsonb not null default '{}'::jsonb,
  provider_response jsonb not null default '{}'::jsonb,
  lookup_url text,
  issued_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoices_branch_scope_key unique (branch_id, invoice_id),
  constraint invoices_bill_fk
    foreign key (branch_id, bill_id)
    references public.bills(branch_id, bill_id) on delete restrict,
  constraint invoices_related_invoice_fk
    foreign key (branch_id, related_invoice_id)
    references public.invoices(branch_id, invoice_id) on delete restrict,
  constraint invoices_type_check
    check (invoice_type in ('original', 'adjustment', 'replacement', 'cancellation')),
  constraint invoices_provider_status_check
    check (provider_status in ('pending', 'submitted', 'issued', 'failed', 'cancelled')),
  constraint invoices_not_self_check
    check (related_invoice_id is null or related_invoice_id <> invoice_id),
  constraint invoices_buyer_snapshot_object_check
    check (jsonb_typeof(buyer_snapshot) = 'object'),
  constraint invoices_provider_payload_object_check
    check (jsonb_typeof(provider_payload) = 'object'),
  constraint invoices_provider_response_object_check
    check (jsonb_typeof(provider_response) = 'object')
);

create unique index invoices_number_key
  on public.invoices (branch_id, invoice_number)
  where invoice_number is not null;

create unique index invoices_one_original_per_bill
  on public.invoices (bill_id)
  where invoice_type = 'original';

create table public.customer_debt_transactions (
  customer_debt_transaction_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  customer_id uuid not null,
  bill_id uuid,
  payment_id uuid,
  transaction_type text not null,
  amount_vnd bigint not null,
  due_date date,
  note text,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  created_at timestamptz not null default now(),
  constraint customer_debt_transactions_branch_scope_key
    unique (branch_id, customer_debt_transaction_id),
  constraint customer_debt_transactions_customer_fk
    foreign key (branch_id, customer_id)
    references public.customers(branch_id, customer_id) on delete restrict,
  constraint customer_debt_transactions_bill_fk
    foreign key (branch_id, bill_id)
    references public.bills(branch_id, bill_id) on delete restrict,
  constraint customer_debt_transactions_payment_fk
    foreign key (branch_id, payment_id)
    references public.payments(branch_id, payment_id) on delete restrict,
  constraint customer_debt_transactions_type_check
    check (transaction_type in ('debt', 'collection', 'writeoff', 'adjustment')),
  constraint customer_debt_transactions_amount_check check (amount_vnd > 0),
  constraint customer_debt_transactions_source_check check (
    (transaction_type = 'debt' and bill_id is not null)
    or (transaction_type = 'collection' and payment_id is not null)
    or transaction_type in ('writeoff', 'adjustment')
  )
);

create table public.cash_expenses (
  cash_expense_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  shift_id uuid,
  expense_code text not null,
  expense_category text not null,
  amount_vnd bigint not null,
  description text not null,
  status text not null default 'draft',
  evidence jsonb not null default '{}'::jsonb,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  approved_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cash_expenses_branch_scope_key unique (branch_id, cash_expense_id),
  constraint cash_expenses_code_key unique (branch_id, expense_code),
  constraint cash_expenses_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint cash_expenses_amount_check check (amount_vnd > 0),
  constraint cash_expenses_status_check
    check (status in ('draft', 'approved', 'paid', 'cancelled')),
  constraint cash_expenses_paid_check
    check ((status = 'paid' and paid_at is not null) or status <> 'paid'),
  constraint cash_expenses_evidence_object_check
    check (jsonb_typeof(evidence) = 'object')
);

-- ============================================================================
-- G. PROCUREMENT AND SUPPLIER DEBT
-- ============================================================================

create table public.suppliers (
  supplier_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  supplier_code text not null,
  supplier_name text not null,
  phone text,
  email text,
  contact_name text,
  address text,
  tax_code text,
  payment_terms_days integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint suppliers_branch_scope_key unique (branch_id, supplier_id),
  constraint suppliers_code_key unique (branch_id, supplier_code),
  constraint suppliers_payment_terms_check
    check (payment_terms_days between 0 and 365),
  constraint suppliers_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.purchase_requisitions (
  purchase_requisition_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  requisition_number text not null,
  reason text not null,
  needed_date date,
  status text not null default 'draft',
  requested_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  approved_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint purchase_requisitions_branch_scope_key
    unique (branch_id, purchase_requisition_id),
  constraint purchase_requisitions_number_key
    unique (branch_id, requisition_number),
  constraint purchase_requisitions_status_check
    check (status in ('draft', 'pending', 'approved', 'rejected', 'converted', 'cancelled')),
  constraint purchase_requisitions_approval_check check (
    (status in ('approved', 'converted') and approved_by_profile_id is not null and approved_at is not null)
    or status not in ('approved', 'converted')
  )
);

create table public.purchase_requisition_details (
  purchase_requisition_detail_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  purchase_requisition_id uuid not null,
  detail_no integer not null,
  branch_ingredient_id uuid not null,
  requested_quantity numeric(18,6) not null,
  estimated_unit_cost_vnd bigint,
  note text,
  constraint purchase_requisition_details_branch_scope_key
    unique (branch_id, purchase_requisition_detail_id),
  constraint purchase_requisition_details_order_key
    unique (purchase_requisition_id, detail_no),
  constraint purchase_requisition_details_requisition_fk
    foreign key (branch_id, purchase_requisition_id)
    references public.purchase_requisitions(branch_id, purchase_requisition_id)
    on delete restrict,
  constraint purchase_requisition_details_ingredient_fk
    foreign key (branch_id, branch_ingredient_id)
    references public.branch_ingredients(branch_id, branch_ingredient_id) on delete restrict,
  constraint purchase_requisition_details_detail_no_check check (detail_no > 0),
  constraint purchase_requisition_details_quantity_check check (requested_quantity > 0),
  constraint purchase_requisition_details_cost_check
    check (estimated_unit_cost_vnd is null or estimated_unit_cost_vnd >= 0)
);

create table public.purchase_orders (
  purchase_order_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  purchase_requisition_id uuid,
  supplier_id uuid not null,
  purchase_order_number text not null,
  order_date date not null default current_date,
  expected_date date,
  status text not null default 'draft',
  total_vnd bigint not null default 0,
  note text,
  created_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint purchase_orders_branch_scope_key unique (branch_id, purchase_order_id),
  constraint purchase_orders_number_key unique (branch_id, purchase_order_number),
  constraint purchase_orders_requisition_fk
    foreign key (branch_id, purchase_requisition_id)
    references public.purchase_requisitions(branch_id, purchase_requisition_id)
    on delete restrict,
  constraint purchase_orders_supplier_fk
    foreign key (branch_id, supplier_id)
    references public.suppliers(branch_id, supplier_id) on delete restrict,
  constraint purchase_orders_status_check
    check (status in ('draft', 'ordered', 'partially_received', 'received', 'cancelled')),
  constraint purchase_orders_total_check check (total_vnd >= 0),
  constraint purchase_orders_expected_date_check
    check (expected_date is null or expected_date >= order_date)
);

create table public.purchase_order_details (
  purchase_order_detail_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  purchase_order_id uuid not null,
  detail_no integer not null,
  branch_ingredient_id uuid not null,
  ingredient_name_snapshot text not null,
  ordered_quantity numeric(18,6) not null,
  unit_cost_vnd bigint not null,
  detail_total_vnd bigint not null,
  note text,
  constraint purchase_order_details_branch_scope_key
    unique (branch_id, purchase_order_detail_id),
  constraint purchase_order_details_order_key
    unique (purchase_order_id, detail_no),
  constraint purchase_order_details_order_fk
    foreign key (branch_id, purchase_order_id)
    references public.purchase_orders(branch_id, purchase_order_id) on delete restrict,
  constraint purchase_order_details_ingredient_fk
    foreign key (branch_id, branch_ingredient_id)
    references public.branch_ingredients(branch_id, branch_ingredient_id) on delete restrict,
  constraint purchase_order_details_detail_no_check check (detail_no > 0),
  constraint purchase_order_details_quantity_check check (ordered_quantity > 0),
  constraint purchase_order_details_money_check
    check (unit_cost_vnd >= 0 and detail_total_vnd >= 0)
);

create table public.goods_receipts (
  goods_receipt_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  purchase_order_id uuid,
  supplier_id uuid not null,
  receipt_number text not null,
  supplier_document_number text,
  status text not null default 'draft',
  total_vnd bigint not null default 0,
  evidence jsonb not null default '{}'::jsonb,
  received_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  received_at timestamptz not null default now(),
  posted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint goods_receipts_branch_scope_key unique (branch_id, goods_receipt_id),
  constraint goods_receipts_number_key unique (branch_id, receipt_number),
  constraint goods_receipts_order_fk
    foreign key (branch_id, purchase_order_id)
    references public.purchase_orders(branch_id, purchase_order_id) on delete restrict,
  constraint goods_receipts_supplier_fk
    foreign key (branch_id, supplier_id)
    references public.suppliers(branch_id, supplier_id) on delete restrict,
  constraint goods_receipts_status_check
    check (status in ('draft', 'posted', 'cancelled')),
  constraint goods_receipts_total_check check (total_vnd >= 0),
  constraint goods_receipts_posted_check
    check ((status = 'posted' and posted_at is not null) or status <> 'posted'),
  constraint goods_receipts_evidence_object_check
    check (jsonb_typeof(evidence) = 'object')
);

create table public.goods_receipt_details (
  goods_receipt_detail_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  goods_receipt_id uuid not null,
  purchase_order_detail_id uuid,
  detail_no integer not null,
  branch_ingredient_id uuid not null,
  ingredient_name_snapshot text not null,
  received_quantity numeric(18,6) not null,
  unit_cost_vnd bigint not null,
  detail_total_vnd bigint not null,
  expiry_date date,
  note text,
  constraint goods_receipt_details_branch_scope_key
    unique (branch_id, goods_receipt_detail_id),
  constraint goods_receipt_details_order_key
    unique (goods_receipt_id, detail_no),
  constraint goods_receipt_details_receipt_fk
    foreign key (branch_id, goods_receipt_id)
    references public.goods_receipts(branch_id, goods_receipt_id) on delete restrict,
  constraint goods_receipt_details_order_detail_fk
    foreign key (branch_id, purchase_order_detail_id)
    references public.purchase_order_details(branch_id, purchase_order_detail_id)
    on delete restrict,
  constraint goods_receipt_details_ingredient_fk
    foreign key (branch_id, branch_ingredient_id)
    references public.branch_ingredients(branch_id, branch_ingredient_id) on delete restrict,
  constraint goods_receipt_details_detail_no_check check (detail_no > 0),
  constraint goods_receipt_details_quantity_check check (received_quantity > 0),
  constraint goods_receipt_details_money_check
    check (unit_cost_vnd >= 0 and detail_total_vnd >= 0)
);

create table public.supplier_payables (
  supplier_payable_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  supplier_id uuid not null,
  goods_receipt_id uuid not null,
  original_amount_vnd bigint not null,
  paid_amount_vnd bigint not null default 0,
  due_date date,
  status text not null default 'unpaid',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supplier_payables_branch_scope_key
    unique (branch_id, supplier_payable_id),
  constraint supplier_payables_receipt_key unique (goods_receipt_id),
  constraint supplier_payables_supplier_fk
    foreign key (branch_id, supplier_id)
    references public.suppliers(branch_id, supplier_id) on delete restrict,
  constraint supplier_payables_receipt_fk
    foreign key (branch_id, goods_receipt_id)
    references public.goods_receipts(branch_id, goods_receipt_id) on delete restrict,
  constraint supplier_payables_money_check check (
    original_amount_vnd > 0
    and paid_amount_vnd >= 0
    and paid_amount_vnd <= original_amount_vnd
  ),
  constraint supplier_payables_status_check
    check (status in ('unpaid', 'partial', 'paid', 'void'))
);

create table public.supplier_payments (
  supplier_payment_id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  supplier_payable_id uuid not null,
  supplier_id uuid not null,
  shift_id uuid,
  amount_vnd bigint not null,
  payment_method text not null,
  payment_reference text,
  idempotency_key text,
  paid_by_profile_id uuid references public.profiles(profile_id) on delete set null,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint supplier_payments_branch_scope_key
    unique (branch_id, supplier_payment_id),
  constraint supplier_payments_payable_fk
    foreign key (branch_id, supplier_payable_id)
    references public.supplier_payables(branch_id, supplier_payable_id) on delete restrict,
  constraint supplier_payments_supplier_fk
    foreign key (branch_id, supplier_id)
    references public.suppliers(branch_id, supplier_id) on delete restrict,
  constraint supplier_payments_shift_fk
    foreign key (branch_id, shift_id)
    references public.shifts(branch_id, shift_id) on delete restrict,
  constraint supplier_payments_amount_check check (amount_vnd > 0),
  constraint supplier_payments_method_check
    check (payment_method in ('cash', 'bank_transfer'))
);

create unique index supplier_payments_idempotency_key
  on public.supplier_payments (branch_id, idempotency_key)
  where idempotency_key is not null;

-- ============================================================================
-- H. CROSS-TABLE MASTER SCOPE INTEGRITY
-- These triggers enforce ownership/referential scope, not business workflow.
-- ============================================================================

create or replace function app_private.enforce_master_scope()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_parent_owner uuid;
  v_other_owner uuid;
begin
  if tg_op = 'UPDATE'
     and tg_table_name in ('menu_categories', 'menu_items', 'ingredients') then
    if new.owner_branch_id is distinct from old.owner_branch_id then
      raise exception 'master owner_branch_id is immutable'
        using errcode = '23514';
    end if;
  end if;

  if tg_table_name = 'menu_items' then
    select owner_branch_id into v_parent_owner
    from public.menu_categories
    where menu_category_id = new.menu_category_id;
    if v_parent_owner is not null
       and new.owner_branch_id is distinct from v_parent_owner then
      raise exception 'menu item and category have incompatible scope'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'branch_menu_items' then
    select owner_branch_id into v_parent_owner
    from public.menu_items where menu_item_id = new.menu_item_id;
    if v_parent_owner is not null and v_parent_owner <> new.branch_id then
      raise exception 'branch cannot configure another branch menu item'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'branch_ingredients' then
    select owner_branch_id into v_parent_owner
    from public.ingredients where ingredient_id = new.ingredient_id;
    if v_parent_owner is not null and v_parent_owner <> new.branch_id then
      raise exception 'branch cannot configure another branch ingredient'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'package_details' then
    select owner_branch_id into v_parent_owner
    from public.menu_items where menu_item_id = new.package_menu_item_id;
    select owner_branch_id into v_other_owner
    from public.menu_items where menu_item_id = new.included_menu_item_id;
    if (v_parent_owner is null and v_other_owner is not null)
       or (v_parent_owner is not null
           and v_other_owner is not null
           and v_parent_owner <> v_other_owner) then
      raise exception 'package detail has incompatible master scope'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'bom_details' then
    select owner_branch_id into v_parent_owner
    from public.menu_items where menu_item_id = new.menu_item_id;
    select owner_branch_id into v_other_owner
    from public.ingredients where ingredient_id = new.ingredient_id;
    if (v_parent_owner is null and v_other_owner is not null)
       or (v_parent_owner is not null
           and v_other_owner is not null
           and v_parent_owner <> v_other_owner) then
      raise exception 'BOM detail has incompatible master scope'
        using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create or replace function app_private.enforce_session_guest_package()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_service_mode text;
  v_item_type text;
begin
  select service_mode into v_service_mode
  from public.dining_sessions
  where dining_session_id = new.dining_session_id
    and branch_id = new.branch_id;
  select item.item_type into v_item_type
  from public.branch_menu_items as branch_item
  join public.menu_items as item on item.menu_item_id = branch_item.menu_item_id
  where branch_item.branch_menu_item_id = new.package_branch_menu_item_id
    and branch_item.branch_id = new.branch_id;
  if (v_service_mode = 'buffet' and v_item_type <> 'buffet_package')
     or (v_service_mode = 'set_menu' and v_item_type <> 'set_menu') then
    raise exception 'guest package does not match dining session mode'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function app_private.enforce_master_scope() from public;
revoke all on function app_private.enforce_session_guest_package() from public;

create trigger menu_categories_owner_immutable
before update on public.menu_categories
for each row execute function app_private.enforce_master_scope();
create trigger menu_items_scope_integrity
before insert or update on public.menu_items
for each row execute function app_private.enforce_master_scope();
create trigger ingredients_owner_immutable
before update on public.ingredients
for each row execute function app_private.enforce_master_scope();
create trigger branch_menu_items_scope_integrity
before insert or update on public.branch_menu_items
for each row execute function app_private.enforce_master_scope();
create trigger branch_ingredients_scope_integrity
before insert or update on public.branch_ingredients
for each row execute function app_private.enforce_master_scope();
create trigger package_details_scope_integrity
before insert or update on public.package_details
for each row execute function app_private.enforce_master_scope();
create trigger bom_details_scope_integrity
before insert or update on public.bom_details
for each row execute function app_private.enforce_master_scope();
create trigger session_guests_package_integrity
before insert or update on public.session_guests
for each row execute function app_private.enforce_session_guest_package();

-- ============================================================================
-- I. FOREIGN-KEY AND OPERATIONAL INDEXES
-- PostgreSQL does not automatically index referencing FK columns.
-- ============================================================================

create index staff_assignments_role_idx
  on public.staff_assignments (role_id);
create index staff_assignments_branch_active_idx
  on public.staff_assignments (branch_id, is_active);

create index audit_logs_actor_idx
  on public.audit_logs (actor_profile_id) where actor_profile_id is not null;
create index audit_logs_target_idx
  on public.audit_logs (branch_id, target_type, target_id, created_at desc);
create index audit_logs_correlation_idx
  on public.audit_logs (correlation_id) where correlation_id is not null;

create index notifications_target_unread_idx
  on public.notifications (target_profile_id, created_at desc)
  where read_at is null;
create index outbox_jobs_pending_idx
  on public.outbox_jobs (branch_id, next_attempt_at, created_at)
  where status in ('pending', 'failed');

create index shifts_opened_by_idx on public.shifts (opened_by_profile_id);
create index shifts_closed_by_idx
  on public.shifts (closed_by_profile_id) where closed_by_profile_id is not null;
create index shifts_branch_time_idx
  on public.shifts (branch_id, opened_at desc);

create index dining_tables_area_idx
  on public.dining_tables (branch_id, area_id);
create index customers_email_idx
  on public.customers (branch_id, lower(email)) where email is not null;
create index reservations_customer_idx
  on public.reservations (branch_id, customer_id, reserved_from desc)
  where customer_id is not null;
create index reservations_status_time_idx
  on public.reservations (branch_id, status, reserved_from);
create index reservations_created_by_idx
  on public.reservations (created_by_profile_id)
  where created_by_profile_id is not null;

create index reservation_tables_reservation_idx
  on public.reservation_tables (branch_id, reservation_id);
create index reservation_tables_table_idx
  on public.reservation_tables (branch_id, dining_table_id);
create index menu_categories_owner_idx
  on public.menu_categories (owner_branch_id) where owner_branch_id is not null;
create index menu_items_category_idx
  on public.menu_items (menu_category_id, is_active);
create index menu_items_owner_idx
  on public.menu_items (owner_branch_id) where owner_branch_id is not null;
create index branch_menu_items_item_idx
  on public.branch_menu_items (menu_item_id);
create index branch_menu_items_branch_active_idx
  on public.branch_menu_items (branch_id, is_active, availability_status);
create index dining_sessions_customer_idx
  on public.dining_sessions (branch_id, customer_id, opened_at desc)
  where customer_id is not null;
create index dining_sessions_reservation_idx
  on public.dining_sessions (branch_id, reservation_id)
  where reservation_id is not null;
create index dining_sessions_opened_by_idx
  on public.dining_sessions (opened_by_profile_id)
  where opened_by_profile_id is not null;
create index dining_sessions_status_idx
  on public.dining_sessions (branch_id, status, opened_at desc);
create index session_guests_session_idx
  on public.session_guests (branch_id, dining_session_id, guest_no);
create index session_guests_package_idx
  on public.session_guests (branch_id, package_branch_menu_item_id);
create index session_tables_session_idx
  on public.session_tables (branch_id, dining_session_id, joined_at);
create index session_tables_table_history_idx
  on public.session_tables (branch_id, dining_table_id, joined_at desc);
create index service_requests_session_idx
  on public.service_requests (branch_id, dining_session_id, status, requested_at);
create index service_requests_handler_idx
  on public.service_requests (handled_by_profile_id)
  where handled_by_profile_id is not null;
create index customer_feedbacks_customer_idx
  on public.customer_feedbacks (branch_id, customer_id, created_at desc)
  where customer_id is not null;
create index customer_feedbacks_session_idx
  on public.customer_feedbacks (branch_id, dining_session_id);

create index package_details_included_item_idx
  on public.package_details (included_menu_item_id);
create index package_details_package_idx
  on public.package_details (package_menu_item_id);
create index ingredients_owner_idx
  on public.ingredients (owner_branch_id) where owner_branch_id is not null;
create index branch_ingredients_item_idx
  on public.branch_ingredients (ingredient_id);
create index branch_ingredients_branch_active_idx
  on public.branch_ingredients (branch_id, is_active);
create index bom_details_ingredient_idx
  on public.bom_details (ingredient_id);
create index bom_details_menu_item_idx
  on public.bom_details (menu_item_id);
create index inventory_transactions_ingredient_time_idx
  on public.inventory_transactions (branch_id, branch_ingredient_id, occurred_at desc);
create index inventory_transactions_reference_idx
  on public.inventory_transactions (reference_type, reference_id)
  where reference_id is not null;
create index inventory_transactions_creator_idx
  on public.inventory_transactions (created_by_profile_id)
  where created_by_profile_id is not null;

create index orders_session_idx
  on public.orders (branch_id, dining_session_id, created_at);
create index orders_shift_idx
  on public.orders (branch_id, shift_id) where shift_id is not null;
create index orders_creator_idx
  on public.orders (created_by_profile_id)
  where created_by_profile_id is not null;
create index order_details_menu_item_idx
  on public.order_details (branch_id, branch_menu_item_id, created_at desc);
create index order_details_order_idx
  on public.order_details (branch_id, order_id, detail_no);
create index order_details_cancelled_by_idx
  on public.order_details (cancelled_by_profile_id)
  where cancelled_by_profile_id is not null;
create index order_details_approved_by_idx
  on public.order_details (approved_by_profile_id)
  where approved_by_profile_id is not null;

create index bills_session_idx
  on public.bills (branch_id, dining_session_id, created_at desc);
create index bills_shift_idx
  on public.bills (branch_id, shift_id, created_at desc)
  where shift_id is not null;
create index bills_customer_idx
  on public.bills (branch_id, customer_id, created_at desc)
  where customer_id is not null;
create index bills_voucher_idx
  on public.bills (branch_id, voucher_id) where voucher_id is not null;
create index bills_cashier_idx
  on public.bills (cashier_profile_id) where cashier_profile_id is not null;
create index bill_details_order_detail_idx
  on public.bill_details (branch_id, order_detail_id);
create index bill_details_session_guest_idx
  on public.bill_details (branch_id, session_guest_id)
  where session_guest_id is not null;
create index bill_details_bill_idx
  on public.bill_details (branch_id, bill_id, detail_no);
create index payment_intents_bill_idx
  on public.payment_intents (branch_id, bill_id, created_at desc)
  where bill_id is not null;
create index payment_intents_reservation_idx
  on public.payment_intents (branch_id, reservation_id, created_at desc)
  where reservation_id is not null;
create index payment_intents_shift_idx
  on public.payment_intents (branch_id, shift_id)
  where shift_id is not null;
create index payment_intents_creator_idx
  on public.payment_intents (created_by_profile_id)
  where created_by_profile_id is not null;
create index payment_attempts_intent_idx
  on public.payment_attempts (branch_id, payment_intent_id, attempt_no);
create index payments_bill_time_idx
  on public.payments (branch_id, bill_id, paid_at)
  where bill_id is not null;
create index payments_reservation_time_idx
  on public.payments (branch_id, reservation_id, paid_at)
  where reservation_id is not null;
create index payments_shift_time_idx
  on public.payments (branch_id, shift_id, paid_at)
  where shift_id is not null;
create index payments_related_payment_idx
  on public.payments (branch_id, related_payment_id)
  where related_payment_id is not null;
create index payments_receiver_idx
  on public.payments (received_by_profile_id)
  where received_by_profile_id is not null;
create index payments_intent_idx
  on public.payments (branch_id, payment_intent_id)
  where payment_intent_id is not null;
create index invoices_bill_idx on public.invoices (branch_id, bill_id);
create index invoices_related_idx
  on public.invoices (branch_id, related_invoice_id)
  where related_invoice_id is not null;
create index customer_debt_customer_time_idx
  on public.customer_debt_transactions (branch_id, customer_id, created_at desc);
create index customer_debt_bill_idx
  on public.customer_debt_transactions (branch_id, bill_id)
  where bill_id is not null;
create index customer_debt_payment_idx
  on public.customer_debt_transactions (branch_id, payment_id)
  where payment_id is not null;
create index customer_debt_created_by_idx
  on public.customer_debt_transactions (created_by_profile_id)
  where created_by_profile_id is not null;
create index cash_expenses_shift_idx
  on public.cash_expenses (branch_id, shift_id) where shift_id is not null;
create index cash_expenses_created_by_idx
  on public.cash_expenses (created_by_profile_id)
  where created_by_profile_id is not null;
create index cash_expenses_approved_by_idx
  on public.cash_expenses (approved_by_profile_id)
  where approved_by_profile_id is not null;

create index purchase_requisitions_requester_idx
  on public.purchase_requisitions (requested_by_profile_id)
  where requested_by_profile_id is not null;
create index purchase_requisitions_approver_idx
  on public.purchase_requisitions (approved_by_profile_id)
  where approved_by_profile_id is not null;
create index purchase_requisition_details_ingredient_idx
  on public.purchase_requisition_details (branch_id, branch_ingredient_id);
create index purchase_requisition_details_requisition_idx
  on public.purchase_requisition_details (
    branch_id,
    purchase_requisition_id,
    detail_no
  );
create index purchase_orders_requisition_idx
  on public.purchase_orders (branch_id, purchase_requisition_id)
  where purchase_requisition_id is not null;
create index purchase_orders_supplier_idx
  on public.purchase_orders (branch_id, supplier_id, order_date desc);
create index purchase_orders_creator_idx
  on public.purchase_orders (created_by_profile_id)
  where created_by_profile_id is not null;
create index purchase_order_details_ingredient_idx
  on public.purchase_order_details (branch_id, branch_ingredient_id);
create index purchase_order_details_order_idx
  on public.purchase_order_details (branch_id, purchase_order_id, detail_no);
create index goods_receipts_order_idx
  on public.goods_receipts (branch_id, purchase_order_id)
  where purchase_order_id is not null;
create index goods_receipts_supplier_idx
  on public.goods_receipts (branch_id, supplier_id, received_at desc);
create index goods_receipts_receiver_idx
  on public.goods_receipts (received_by_profile_id)
  where received_by_profile_id is not null;
create index goods_receipt_details_order_detail_idx
  on public.goods_receipt_details (branch_id, purchase_order_detail_id)
  where purchase_order_detail_id is not null;
create index goods_receipt_details_receipt_idx
  on public.goods_receipt_details (branch_id, goods_receipt_id, detail_no);
create index goods_receipt_details_ingredient_idx
  on public.goods_receipt_details (branch_id, branch_ingredient_id);
create index supplier_payables_supplier_idx
  on public.supplier_payables (branch_id, supplier_id, status, due_date);
create index supplier_payables_receipt_idx
  on public.supplier_payables (branch_id, goods_receipt_id);
create index supplier_payments_payable_idx
  on public.supplier_payments (branch_id, supplier_payable_id, paid_at);
create index supplier_payments_supplier_idx
  on public.supplier_payments (branch_id, supplier_id, paid_at desc);
create index supplier_payments_shift_idx
  on public.supplier_payments (branch_id, shift_id)
  where shift_id is not null;
create index supplier_payments_paid_by_idx
  on public.supplier_payments (paid_by_profile_id)
  where paid_by_profile_id is not null;

-- ============================================================================
-- J. JWT CLAIM HELPERS
-- These are authorization helpers only, not business workflow.
-- Claims are stored in trusted app_metadata.
-- ============================================================================

create or replace function app_private.jwt_role_codes()
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    array(
      select jsonb_array_elements_text(
        coalesce(auth.jwt() -> 'app_metadata' -> 'role_codes', '[]'::jsonb)
      )
    ),
    array[]::text[]
  );
$$;

create or replace function app_private.jwt_branch_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select nullif(
    coalesce(auth.jwt() -> 'app_metadata' ->> 'branch_id', ''),
    ''
  )::uuid;
$$;

create or replace function app_private.can_read_branch(
  requested_branch_id uuid,
  allowed_roles text[]
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    'superadmin' = any(app_private.jwt_role_codes())
    or (
      requested_branch_id = app_private.jwt_branch_id()
      and app_private.jwt_role_codes() && allowed_roles
    );
$$;

create or replace function app_private.require_branch_role(
  requested_branch_id uuid,
  allowed_roles text[]
)
returns void
language plpgsql
stable
security invoker
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if not app_private.can_read_branch(requested_branch_id, allowed_roles) then
    raise exception 'insufficient role for branch' using errcode = '42501';
  end if;
end;
$$;

create or replace function app_private.append_audit(
  p_branch_id uuid,
  p_action_code text,
  p_target_type text,
  p_target_id uuid,
  p_detail jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_audit_log_id uuid;
begin
  insert into public.audit_logs (
    branch_id, actor_profile_id, actor_role_codes_snapshot, action_code,
    target_type, target_id, detail
  ) values (
    p_branch_id, (select auth.uid()), app_private.jwt_role_codes(),
    p_action_code, p_target_type, p_target_id, p_detail
  ) returning audit_log_id into v_audit_log_id;
  return v_audit_log_id;
end;
$$;

revoke all on function app_private.jwt_role_codes() from public;
revoke all on function app_private.jwt_branch_id() from public;
revoke all on function app_private.can_read_branch(uuid, text[]) from public;
revoke all on function app_private.require_branch_role(uuid, text[]) from public;
revoke all on function app_private.append_audit(uuid, text, text, uuid, jsonb)
  from public;

grant usage on schema app_private to authenticated;
grant execute on function app_private.jwt_role_codes() to authenticated;
grant execute on function app_private.jwt_branch_id() to authenticated;
grant execute on function app_private.can_read_branch(uuid, text[]) to authenticated;
grant execute on function app_private.require_branch_role(uuid, text[]) to authenticated;

-- ============================================================================
-- K. ATOMIC COMMAND/RPC BOUNDARY
-- Provider network calls happen outside the database. These commands only
-- validate and commit local facts atomically after the provider response.
-- ============================================================================

create or replace function public.command_assign_reservation_tables(
  p_reservation_id uuid,
  p_dining_table_ids uuid[],
  p_primary_dining_table_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation public.reservations%rowtype;
  v_table_id uuid;
  v_expected integer;
begin
  select * into v_reservation
  from public.reservations
  where reservation_id = p_reservation_id
    and status in ('waiting', 'new', 'confirmed', 'arrived')
  for update;
  if not found then raise exception 'active reservation not found'; end if;
  perform app_private.require_branch_role(
    v_reservation.branch_id, array['manager','reception']::text[]
  );
  v_expected := coalesce(cardinality(p_dining_table_ids), 0);
  if v_expected <> (
    select count(distinct value) from unnest(coalesce(p_dining_table_ids, array[]::uuid[])) as value
  ) then
    raise exception 'duplicate dining table id';
  end if;
  if p_primary_dining_table_id is not null
     and not (
       p_primary_dining_table_id =
       any(coalesce(p_dining_table_ids, array[]::uuid[]))
     ) then
    raise exception 'primary table must be in p_dining_table_ids';
  end if;

  perform 1
  from public.dining_tables
  where branch_id = v_reservation.branch_id
    and dining_table_id = any(coalesce(p_dining_table_ids, array[]::uuid[]))
    and is_active
  order by dining_table_id
  for update;
  if (
    select count(*) from public.dining_tables
    where branch_id = v_reservation.branch_id
      and dining_table_id = any(coalesce(p_dining_table_ids, array[]::uuid[]))
      and is_active
  ) <> v_expected then
    raise exception 'one or more dining tables are invalid for branch';
  end if;
  if exists (
    select 1
    from public.reservation_tables as allocation
    join public.reservations as other_reservation
      on other_reservation.reservation_id = allocation.reservation_id
     and other_reservation.branch_id = allocation.branch_id
    where allocation.branch_id = v_reservation.branch_id
      and allocation.dining_table_id =
          any(coalesce(p_dining_table_ids, array[]::uuid[]))
      and allocation.reservation_id <> p_reservation_id
      and other_reservation.status in ('new', 'confirmed', 'arrived')
      and other_reservation.reserved_from < v_reservation.reserved_to
      and v_reservation.reserved_from < other_reservation.reserved_to
  ) then
    raise exception 'one or more dining tables overlap another reservation';
  end if;

  delete from public.reservation_tables
  where reservation_id = p_reservation_id;
  foreach v_table_id in array coalesce(p_dining_table_ids, array[]::uuid[])
  loop
    insert into public.reservation_tables (
      branch_id, reservation_id, dining_table_id, is_primary
    ) values (
      v_reservation.branch_id, p_reservation_id, v_table_id,
      v_table_id = p_primary_dining_table_id
    );
  end loop;
  insert into public.audit_logs (
    branch_id, actor_profile_id, actor_role_codes_snapshot, action_code,
    target_type, target_id, detail
  ) values (
    v_reservation.branch_id, (select auth.uid()), app_private.jwt_role_codes(),
    'reservation.tables_assigned', 'reservation', p_reservation_id,
    jsonb_build_object(
      'dining_table_ids', p_dining_table_ids,
      'primary_dining_table_id', p_primary_dining_table_id
    )
  );
end;
$$;

create or replace function public.command_create_split_bill(
  p_dining_session_id uuid,
  p_shift_id uuid,
  p_bill_number text,
  p_lines jsonb,
  p_customer_id uuid default null,
  p_voucher_id uuid default null,
  p_service_charge_vnd bigint default 0,
  p_deposit_applied_vnd bigint default 0,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_bill_id uuid := gen_random_uuid();
  v_line jsonb;
  v_source_type text;
  v_source_id uuid;
  v_quantity numeric(14,3);
  v_line_discount bigint;
  v_item_name text;
  v_unit_price bigint;
  v_vat_rate numeric(7,4);
  v_available numeric(14,3);
  v_allocated numeric(14,3);
  v_line_base bigint;
  v_line_vat bigint;
  v_subtotal bigint := 0;
  v_discount bigint := 0;
  v_vat bigint := 0;
  v_detail_no integer := 0;
begin
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then
    raise exception 'p_lines must be a non-empty JSON array';
  end if;
  if nullif(btrim(p_bill_number), '') is null then
    raise exception 'bill number is required';
  end if;
  if p_service_charge_vnd < 0 or p_deposit_applied_vnd < 0 then
    raise exception 'service charge and deposit must be non-negative';
  end if;

  select dining_session.branch_id
  into v_branch_id
  from public.dining_sessions as dining_session
  where dining_session.dining_session_id = p_dining_session_id
    and dining_session.status in ('open', 'ordering', 'checkout_requested')
  for update;

  if v_branch_id is null then
    raise exception 'active dining session not found';
  end if;
  perform app_private.require_branch_role(
    v_branch_id,
    array['manager', 'reception', 'accounting']::text[]
  );
  if not exists (
    select 1 from public.shifts
    where shift_id = p_shift_id and branch_id = v_branch_id and status = 'open'
  ) then
    raise exception 'the branch has no matching open cashier shift';
  end if;
  if p_customer_id is not null and not exists (
    select 1 from public.customers
    where customer_id = p_customer_id and branch_id = v_branch_id
  ) then
    raise exception 'customer does not belong to branch';
  end if;
  if p_voucher_id is not null and not exists (
    select 1 from public.vouchers
    where voucher_id = p_voucher_id
      and branch_id = v_branch_id
      and is_active
      and now() >= valid_from and now() < valid_to
  ) then
    raise exception 'voucher is not valid for branch';
  end if;

  insert into public.bills (
    bill_id, branch_id, dining_session_id, shift_id, customer_id, voucher_id,
    bill_number, cashier_profile_id, note
  ) values (
    v_bill_id, v_branch_id, p_dining_session_id, p_shift_id, p_customer_id,
    p_voucher_id, p_bill_number, (select auth.uid()), p_note
  );

  for v_line in select value from jsonb_array_elements(p_lines)
  loop
    v_detail_no := v_detail_no + 1;
    v_source_type := v_line ->> 'source_type';
    v_source_id := (v_line ->> 'source_id')::uuid;
    v_quantity := (v_line ->> 'quantity')::numeric;
    v_line_discount := coalesce((v_line ->> 'discount_vnd')::bigint, 0);
    if v_quantity <= 0 or v_line_discount < 0 then
      raise exception 'invalid quantity or line discount at detail %', v_detail_no;
    end if;

    if v_source_type = 'order_detail' then
      select detail.item_name_snapshot, detail.unit_price_vnd_snapshot,
             detail.vat_rate_snapshot,
             greatest(detail.chargeable_quantity - detail.cancelled_quantity, 0)
      into v_item_name, v_unit_price, v_vat_rate, v_available
      from public.order_details as detail
      join public.orders as order_header
        on order_header.order_id = detail.order_id
       and order_header.branch_id = detail.branch_id
      where detail.order_detail_id = v_source_id
        and detail.branch_id = v_branch_id
        and order_header.dining_session_id = p_dining_session_id
        and detail.kitchen_status <> 'cancelled'
      for update of detail;

      if not found then
        raise exception 'order detail % is not billable', v_source_id;
      end if;
      select coalesce(sum(detail.quantity), 0)
      into v_allocated
      from public.bill_details as detail
      join public.bills as bill
        on bill.bill_id = detail.bill_id and bill.branch_id = detail.branch_id
      where detail.order_detail_id = v_source_id and bill.status <> 'void';
      if v_allocated + v_quantity > v_available then
        raise exception 'order detail % is over-allocated', v_source_id;
      end if;
    elsif v_source_type = 'session_guest' then
      if v_quantity <> 1 then
        raise exception 'a session guest must be billed with quantity 1';
      end if;
      select guest.package_name_snapshot, guest.package_price_vnd_snapshot,
             guest.vat_rate_snapshot, 1::numeric
      into v_item_name, v_unit_price, v_vat_rate, v_available
      from public.session_guests as guest
      where guest.session_guest_id = v_source_id
        and guest.branch_id = v_branch_id
        and guest.dining_session_id = p_dining_session_id
        and guest.status = 'active'
      for update;

      if not found then
        raise exception 'active session guest % not found', v_source_id;
      end if;
      select coalesce(sum(detail.quantity), 0)
      into v_allocated
      from public.bill_details as detail
      join public.bills as bill
        on bill.bill_id = detail.bill_id and bill.branch_id = detail.branch_id
      where detail.session_guest_id = v_source_id and bill.status <> 'void';
      if v_allocated + v_quantity > 1 then
        raise exception 'session guest % is already allocated', v_source_id;
      end if;
    else
      raise exception 'unsupported source_type at detail %', v_detail_no;
    end if;

    v_line_base := round(v_quantity * v_unit_price);
    if v_line_discount > v_line_base then
      raise exception 'discount exceeds line value at detail %', v_detail_no;
    end if;
    v_line_vat := round((v_line_base - v_line_discount) * v_vat_rate / 100);
    insert into public.bill_details (
      branch_id, bill_id, detail_no, order_detail_id, session_guest_id,
      item_name_snapshot, quantity, unit_price_vnd, discount_vnd,
      vat_rate, vat_vnd, detail_total_vnd
    ) values (
      v_branch_id, v_bill_id, v_detail_no,
      case when v_source_type = 'order_detail' then v_source_id end,
      case when v_source_type = 'session_guest' then v_source_id end,
      v_item_name, v_quantity, v_unit_price, v_line_discount,
      v_vat_rate, v_line_vat, v_line_base - v_line_discount + v_line_vat
    );
    v_subtotal := v_subtotal + v_line_base;
    v_discount := v_discount + v_line_discount;
    v_vat := v_vat + v_line_vat;
  end loop;

  if p_deposit_applied_vnd > v_subtotal - v_discount + p_service_charge_vnd + v_vat then
    raise exception 'deposit exceeds bill value';
  end if;
  update public.bills
  set subtotal_vnd = v_subtotal,
      discount_vnd = v_discount,
      service_charge_vnd = p_service_charge_vnd,
      vat_vnd = v_vat,
      deposit_applied_vnd = p_deposit_applied_vnd,
      grand_total_vnd =
        v_subtotal - v_discount + p_service_charge_vnd + v_vat
        - p_deposit_applied_vnd,
      issued_at = now(),
      updated_at = now()
  where bill_id = v_bill_id;

  insert into public.audit_logs (
    branch_id, actor_profile_id, actor_role_codes_snapshot, action_code,
    target_type, target_id, detail
  ) values (
    v_branch_id, (select auth.uid()), app_private.jwt_role_codes(),
    'bill.created', 'bill', v_bill_id,
    jsonb_build_object('dining_session_id', p_dining_session_id)
  );
  return v_bill_id;
end;
$$;

create or replace function public.command_record_cash_payment(
  p_amount_vnd bigint,
  p_idempotency_key text,
  p_bill_id uuid default null,
  p_reservation_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_shift_id uuid;
  v_payment_id uuid;
  v_due bigint;
  v_target_status text;
  v_existing public.payments%rowtype;
begin
  if p_amount_vnd <= 0 or num_nonnulls(p_bill_id, p_reservation_id) <> 1 then
    raise exception 'positive amount and exactly one target are required';
  end if;
  if nullif(btrim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required';
  end if;
  if p_bill_id is not null then
    select branch_id, shift_id, grand_total_vnd - paid_total_vnd, status
    into v_branch_id, v_shift_id, v_due, v_target_status
    from public.bills
    where bill_id = p_bill_id
    for update;
  else
    select branch_id into v_branch_id
    from public.reservations where reservation_id = p_reservation_id for update;
  end if;
  if v_branch_id is null then raise exception 'payment target not found'; end if;
  perform app_private.require_branch_role(v_branch_id, array['manager','reception']::text[]);
  perform pg_advisory_xact_lock(
    hashtextextended(v_branch_id::text || ':' || p_idempotency_key, 0)
  );
  select * into v_existing
  from public.payments
  where branch_id = v_branch_id and idempotency_key = p_idempotency_key;
  if found then
    if v_existing.transaction_type <> 'payment'
       or v_existing.payment_method <> 'cash'
       or v_existing.amount_vnd <> p_amount_vnd
       or v_existing.bill_id is distinct from p_bill_id
       or v_existing.reservation_id is distinct from p_reservation_id then
      raise exception 'idempotency key was used with different cash payment data';
    end if;
    return v_existing.payment_id;
  end if;
  if p_bill_id is not null then
    if v_target_status not in ('open', 'partially_paid', 'debt')
       or p_amount_vnd > v_due then
      raise exception 'bill not payable or amount exceeds outstanding';
    end if;
  else
    select shift_id into v_shift_id
    from public.shifts where branch_id = v_branch_id and status = 'open' for update;
    if v_shift_id is null then
      raise exception 'open cashier shift not found';
    end if;
  end if;

  insert into public.payments (
    branch_id, bill_id, reservation_id, shift_id, transaction_type,
    payment_method, amount_vnd, idempotency_key, received_by_profile_id
  ) values (
    v_branch_id, p_bill_id, p_reservation_id, v_shift_id, 'payment',
    'cash', p_amount_vnd, p_idempotency_key, (select auth.uid())
  ) returning payment_id into v_payment_id;

  if p_bill_id is not null then
    update public.bills
    set paid_total_vnd = paid_total_vnd + p_amount_vnd,
        debt_total_vnd = greatest(debt_total_vnd - p_amount_vnd, 0),
        status = case
          when paid_total_vnd + p_amount_vnd >= grand_total_vnd then 'paid'
          else 'partially_paid'
        end,
        closed_at = case
          when paid_total_vnd + p_amount_vnd >= grand_total_vnd then now()
          else closed_at
        end,
        updated_at = now()
    where bill_id = p_bill_id;
  else
    update public.reservations
    set deposit_amount_vnd = deposit_amount_vnd + p_amount_vnd,
        deposit_method = 'cash', deposit_status = 'paid', updated_at = now()
    where reservation_id = p_reservation_id;
  end if;
  perform app_private.append_audit(
    v_branch_id, 'payment.cash_recorded', 'payment', v_payment_id,
    jsonb_build_object('amount_vnd', p_amount_vnd)
  );
  return v_payment_id;
end;
$$;

create or replace function public.command_create_payment_intent(
  p_amount_vnd bigint,
  p_payment_method text,
  p_idempotency_key text,
  p_bill_id uuid default null,
  p_reservation_id uuid default null,
  p_provider text default null,
  p_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_shift_id uuid;
  v_due bigint;
  v_target_status text;
  v_intent_id uuid;
  v_existing public.payment_intents%rowtype;
begin
  if p_amount_vnd <= 0
     or p_payment_method not in ('card', 'vietqr')
     or num_nonnulls(p_bill_id, p_reservation_id) <> 1 then
    raise exception 'invalid electronic payment intent';
  end if;
  if nullif(btrim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required';
  end if;
  if p_bill_id is not null then
    select branch_id, shift_id, grand_total_vnd - paid_total_vnd, status
    into v_branch_id, v_shift_id, v_due, v_target_status
    from public.bills
    where bill_id = p_bill_id
    for update;
  else
    select branch_id into v_branch_id
    from public.reservations where reservation_id = p_reservation_id for update;
  end if;
  if v_branch_id is null then raise exception 'payment target not found'; end if;
  perform app_private.require_branch_role(v_branch_id, array['manager','reception']::text[]);
  perform pg_advisory_xact_lock(
    hashtextextended(v_branch_id::text || ':' || p_idempotency_key, 0)
  );
  select * into v_existing
  from public.payment_intents
  where branch_id = v_branch_id and idempotency_key = p_idempotency_key;
  if found then
    if v_existing.amount_vnd <> p_amount_vnd
       or v_existing.payment_method <> p_payment_method
       or v_existing.bill_id is distinct from p_bill_id
       or v_existing.reservation_id is distinct from p_reservation_id then
      raise exception 'idempotency key was used with different intent data';
    end if;
    return v_existing.payment_intent_id;
  end if;
  if p_bill_id is not null then
    if v_target_status not in ('open', 'partially_paid', 'debt')
       or p_amount_vnd > v_due then
      raise exception 'bill not payable or amount exceeds outstanding';
    end if;
  else
    select shift_id into v_shift_id
    from public.shifts where branch_id = v_branch_id and status = 'open' for update;
    if v_shift_id is null then
      raise exception 'open cashier shift not found';
    end if;
  end if;

  insert into public.payment_intents (
    branch_id, bill_id, reservation_id, shift_id, payment_method, amount_vnd,
    idempotency_key, provider, expires_at, created_by_profile_id
  ) values (
    v_branch_id, p_bill_id, p_reservation_id, v_shift_id, p_payment_method,
    p_amount_vnd, p_idempotency_key, p_provider, p_expires_at, (select auth.uid())
  ) returning payment_intent_id into v_intent_id;
  perform app_private.append_audit(
    v_branch_id, 'payment_intent.created', 'payment_intent', v_intent_id,
    jsonb_build_object('amount_vnd', p_amount_vnd, 'method', p_payment_method)
  );
  return v_intent_id;
end;
$$;

create or replace function public.command_record_payment_attempt(
  p_payment_intent_id uuid,
  p_status text,
  p_provider_reference text default null,
  p_request_payload jsonb default '{}'::jsonb,
  p_response_payload jsonb default '{}'::jsonb,
  p_failure_code text default null,
  p_failure_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_intent public.payment_intents%rowtype;
  v_attempt_id uuid;
  v_attempt_no integer;
begin
  if p_status not in ('succeeded', 'failed', 'cancelled') then
    raise exception 'terminal attempt status required';
  end if;
  select * into v_intent
  from public.payment_intents
  where payment_intent_id = p_payment_intent_id
  for update;
  if not found then
    raise exception 'payment intent not found';
  end if;
  perform app_private.require_branch_role(
    v_intent.branch_id, array['manager','reception']::text[]
  );
  if p_provider_reference is not null then
    select payment_attempt_id into v_attempt_id
    from public.payment_attempts
    where branch_id = v_intent.branch_id
      and provider_reference = p_provider_reference;
    if v_attempt_id is not null then
      if not exists (
        select 1 from public.payment_attempts
        where payment_attempt_id = v_attempt_id
          and payment_intent_id = p_payment_intent_id
          and status = p_status
      ) then
        raise exception 'provider reference was used by another attempt';
      end if;
      return v_attempt_id;
    end if;
  end if;
  if v_intent.status not in ('pending', 'processing', 'failed') then
    raise exception 'payment intent is not actionable';
  end if;
  select coalesce(max(attempt_no), 0) + 1 into v_attempt_no
  from public.payment_attempts where payment_intent_id = p_payment_intent_id;

  insert into public.payment_attempts (
    branch_id, payment_intent_id, attempt_no, status, provider_reference,
    request_payload, response_payload, failure_code, failure_message, completed_at
  ) values (
    v_intent.branch_id, p_payment_intent_id, v_attempt_no, p_status,
    p_provider_reference, p_request_payload, p_response_payload,
    p_failure_code, p_failure_message, now()
  ) returning payment_attempt_id into v_attempt_id;

  update public.payment_intents
  set status = p_status,
      provider_intent_reference =
        coalesce(provider_intent_reference, p_provider_reference),
      succeeded_at = case when p_status = 'succeeded' then now() end,
      cancelled_at = case when p_status = 'cancelled' then now() end,
      updated_at = now()
  where payment_intent_id = p_payment_intent_id;

  if p_status = 'succeeded' then
    if v_intent.bill_id is not null then
      perform 1 from public.bills where bill_id = v_intent.bill_id for update;
      if not found or (
        select grand_total_vnd - paid_total_vnd
        from public.bills where bill_id = v_intent.bill_id
      ) < v_intent.amount_vnd then
        raise exception 'bill outstanding changed before capture';
      end if;
    else
      perform 1 from public.reservations
      where reservation_id = v_intent.reservation_id for update;
    end if;

    insert into public.payments (
      branch_id, bill_id, reservation_id, payment_intent_id, shift_id,
      transaction_type, payment_method, amount_vnd, provider_reference,
      idempotency_key, received_by_profile_id
    ) values (
      v_intent.branch_id, v_intent.bill_id, v_intent.reservation_id,
      v_intent.payment_intent_id, v_intent.shift_id, 'payment',
      v_intent.payment_method, v_intent.amount_vnd, p_provider_reference,
      'intent:' || v_intent.payment_intent_id::text, (select auth.uid())
    );
    if v_intent.bill_id is not null then
      update public.bills
      set paid_total_vnd = paid_total_vnd + v_intent.amount_vnd,
          debt_total_vnd = greatest(debt_total_vnd - v_intent.amount_vnd, 0),
          status = case
            when paid_total_vnd + v_intent.amount_vnd >= grand_total_vnd then 'paid'
            else 'partially_paid'
          end,
          closed_at = case
            when paid_total_vnd + v_intent.amount_vnd >= grand_total_vnd then now()
            else closed_at
          end,
          updated_at = now()
      where bill_id = v_intent.bill_id;
    else
      update public.reservations
      set deposit_amount_vnd = deposit_amount_vnd + v_intent.amount_vnd,
          deposit_method = v_intent.payment_method,
          deposit_status = 'paid', updated_at = now()
      where reservation_id = v_intent.reservation_id;
    end if;
  end if;
  perform app_private.append_audit(
    v_intent.branch_id, 'payment_attempt.recorded',
    'payment_attempt', v_attempt_id,
    jsonb_build_object('status', p_status, 'payment_intent_id', p_payment_intent_id)
  );
  return v_attempt_id;
end;
$$;

create or replace function public.command_refund_payment(
  p_payment_id uuid,
  p_amount_vnd bigint,
  p_idempotency_key text,
  p_provider_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_original public.payments%rowtype;
  v_refunded bigint;
  v_refund_id uuid;
  v_existing public.payments%rowtype;
begin
  if p_amount_vnd <= 0 then raise exception 'refund amount must be positive'; end if;
  if nullif(btrim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required';
  end if;
  select * into v_original from public.payments
  where payment_id = p_payment_id and transaction_type = 'payment'
  for update;
  if not found then raise exception 'original payment not found'; end if;
  perform app_private.require_branch_role(
    v_original.branch_id, array['manager','accounting']::text[]
  );
  perform pg_advisory_xact_lock(
    hashtextextended(v_original.branch_id::text || ':' || p_idempotency_key, 0)
  );
  select * into v_existing
  from public.payments
  where branch_id = v_original.branch_id and idempotency_key = p_idempotency_key;
  if found then
    if v_existing.transaction_type <> 'refund'
       or v_existing.related_payment_id is distinct from p_payment_id
       or v_existing.amount_vnd <> p_amount_vnd then
      raise exception 'idempotency key was used with different refund data';
    end if;
    return v_existing.payment_id;
  end if;
  select coalesce(sum(amount_vnd), 0) into v_refunded
  from public.payments
  where related_payment_id = p_payment_id and transaction_type = 'refund';
  if v_refunded + p_amount_vnd > v_original.amount_vnd then
    raise exception 'refund exceeds captured payment';
  end if;

  insert into public.payments (
    branch_id, bill_id, reservation_id, shift_id, related_payment_id,
    transaction_type, payment_method, amount_vnd, provider_reference,
    idempotency_key, received_by_profile_id
  ) values (
    v_original.branch_id, v_original.bill_id, v_original.reservation_id,
    v_original.shift_id, p_payment_id, 'refund', v_original.payment_method,
    p_amount_vnd, p_provider_reference, p_idempotency_key, (select auth.uid())
  ) returning payment_id into v_refund_id;

  if v_original.bill_id is not null then
    perform 1 from public.bills where bill_id = v_original.bill_id for update;
    update public.bills
    set paid_total_vnd = greatest(paid_total_vnd - p_amount_vnd, 0),
        status = case
          when greatest(paid_total_vnd - p_amount_vnd, 0) = 0 then 'open'
          else 'partially_paid'
        end,
        closed_at = null, updated_at = now()
    where bill_id = v_original.bill_id;
  else
    perform 1 from public.reservations
    where reservation_id = v_original.reservation_id for update;
    update public.reservations
    set deposit_amount_vnd = greatest(deposit_amount_vnd - p_amount_vnd, 0),
        deposit_status = case
          when greatest(deposit_amount_vnd - p_amount_vnd, 0) = 0
          then 'refunded' else 'paid'
        end,
        updated_at = now()
    where reservation_id = v_original.reservation_id;
  end if;
  perform app_private.append_audit(
    v_original.branch_id, 'payment.refunded', 'payment', v_refund_id,
    jsonb_build_object('original_payment_id', p_payment_id, 'amount_vnd', p_amount_vnd)
  );
  return v_refund_id;
end;
$$;

create or replace function public.command_open_customer_debt(
  p_bill_id uuid,
  p_due_date date default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bill public.bills%rowtype;
  v_debt_id uuid;
  v_amount bigint;
begin
  select * into v_bill from public.bills
  where bill_id = p_bill_id and status in ('open', 'partially_paid')
  for update;
  if not found or v_bill.customer_id is null then
    raise exception 'bill must be payable and have a customer';
  end if;
  perform app_private.require_branch_role(
    v_bill.branch_id, array['manager','reception','accounting']::text[]
  );
  v_amount := v_bill.grand_total_vnd - v_bill.paid_total_vnd;
  if v_amount <= 0 then raise exception 'bill has no outstanding amount'; end if;
  insert into public.customer_debt_transactions (
    branch_id, customer_id, bill_id, transaction_type, amount_vnd,
    due_date, note, created_by_profile_id
  ) values (
    v_bill.branch_id, v_bill.customer_id, p_bill_id, 'debt', v_amount,
    p_due_date, p_note, (select auth.uid())
  ) returning customer_debt_transaction_id into v_debt_id;
  update public.bills
  set debt_total_vnd = v_amount, status = 'debt', closed_at = now(), updated_at = now()
  where bill_id = p_bill_id;
  perform app_private.append_audit(
    v_bill.branch_id, 'customer_debt.opened',
    'customer_debt_transaction', v_debt_id,
    jsonb_build_object('bill_id', p_bill_id, 'amount_vnd', v_amount)
  );
  return v_debt_id;
end;
$$;

create or replace function public.command_collect_customer_debt(
  p_bill_id uuid,
  p_amount_vnd bigint,
  p_payment_method text,
  p_idempotency_key text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bill public.bills%rowtype;
  v_payment_id uuid;
  v_existing public.payments%rowtype;
begin
  if p_amount_vnd <= 0 or p_payment_method not in ('cash', 'bank_transfer') then
    raise exception 'invalid debt collection';
  end if;
  if nullif(btrim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required';
  end if;
  select * into v_bill from public.bills
  where bill_id = p_bill_id for update;
  if not found then raise exception 'bill not found'; end if;
  perform app_private.require_branch_role(
    v_bill.branch_id, array['manager','reception','accounting']::text[]
  );
  perform pg_advisory_xact_lock(
    hashtextextended(v_bill.branch_id::text || ':' || p_idempotency_key, 0)
  );
  select * into v_existing
  from public.payments
  where branch_id = v_bill.branch_id and idempotency_key = p_idempotency_key;
  if found then
    if v_existing.transaction_type <> 'payment'
       or v_existing.bill_id is distinct from p_bill_id
       or v_existing.amount_vnd <> p_amount_vnd
       or v_existing.payment_method <> p_payment_method then
      raise exception 'idempotency key was used with different collection data';
    end if;
    return v_existing.payment_id;
  end if;
  if v_bill.status <> 'debt' or p_amount_vnd > v_bill.debt_total_vnd then
    raise exception 'bill is not debt or collection exceeds debt';
  end if;
  insert into public.payments (
    branch_id, bill_id, shift_id, transaction_type, payment_method,
    amount_vnd, idempotency_key, received_by_profile_id
  ) values (
    v_bill.branch_id, p_bill_id, v_bill.shift_id, 'payment', p_payment_method,
    p_amount_vnd, p_idempotency_key, (select auth.uid())
  ) returning payment_id into v_payment_id;
  insert into public.customer_debt_transactions (
    branch_id, customer_id, bill_id, payment_id, transaction_type,
    amount_vnd, created_by_profile_id
  ) values (
    v_bill.branch_id, v_bill.customer_id, p_bill_id, v_payment_id,
    'collection', p_amount_vnd, (select auth.uid())
  );
  update public.bills
  set paid_total_vnd = paid_total_vnd + p_amount_vnd,
      debt_total_vnd = debt_total_vnd - p_amount_vnd,
      status = case when debt_total_vnd = p_amount_vnd then 'paid' else 'debt' end,
      updated_at = now()
  where bill_id = p_bill_id;
  perform app_private.append_audit(
    v_bill.branch_id, 'customer_debt.collected', 'payment', v_payment_id,
    jsonb_build_object('bill_id', p_bill_id, 'amount_vnd', p_amount_vnd)
  );
  return v_payment_id;
end;
$$;

revoke all on function public.command_create_split_bill(
  uuid, uuid, text, jsonb, uuid, uuid, bigint, bigint, text
) from public, anon;
revoke all on function public.command_assign_reservation_tables(
  uuid, uuid[], uuid
) from public, anon;
revoke all on function public.command_record_cash_payment(
  bigint, text, uuid, uuid
) from public, anon;
revoke all on function public.command_create_payment_intent(
  bigint, text, text, uuid, uuid, text, timestamptz
) from public, anon;
revoke all on function public.command_record_payment_attempt(
  uuid, text, text, jsonb, jsonb, text, text
) from public, anon;
revoke all on function public.command_refund_payment(
  uuid, bigint, text, text
) from public, anon;
revoke all on function public.command_open_customer_debt(
  uuid, date, text
) from public, anon;
revoke all on function public.command_collect_customer_debt(
  uuid, bigint, text, text
) from public, anon;

grant execute on function public.command_create_split_bill(
  uuid, uuid, text, jsonb, uuid, uuid, bigint, bigint, text
) to authenticated;
grant execute on function public.command_assign_reservation_tables(
  uuid, uuid[], uuid
) to authenticated;
grant execute on function public.command_record_cash_payment(
  bigint, text, uuid, uuid
) to authenticated;
grant execute on function public.command_create_payment_intent(
  bigint, text, text, uuid, uuid, text, timestamptz
) to authenticated;
grant execute on function public.command_record_payment_attempt(
  uuid, text, text, jsonb, jsonb, text, text
) to authenticated;
grant execute on function public.command_refund_payment(
  uuid, bigint, text, text
) to authenticated;
grant execute on function public.command_open_customer_debt(
  uuid, date, text
) to authenticated;
grant execute on function public.command_collect_customer_debt(
  uuid, bigint, text, text
) to authenticated;

-- ============================================================================
-- L. ROW LEVEL SECURITY
-- No direct client table access is granted. RLS remains enabled/forced as
-- defense in depth for future query RPCs that choose SECURITY INVOKER.
-- ============================================================================

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'branches', 'profiles', 'roles', 'staff_assignments', 'audit_logs',
    'notifications', 'outbox_jobs', 'shifts', 'areas', 'dining_tables',
    'customers', 'reservations', 'reservation_tables', 'dining_sessions',
    'session_guests', 'session_tables', 'service_requests',
    'customer_feedbacks', 'menu_categories', 'menu_items', 'branch_menu_items',
    'package_details', 'ingredients', 'branch_ingredients', 'bom_details',
    'inventory_transactions', 'orders', 'order_details', 'bills',
    'bill_details', 'payment_intents', 'payment_attempts', 'payments',
    'vouchers', 'invoices',
    'customer_debt_transactions', 'cash_expenses', 'suppliers',
    'purchase_requisitions', 'purchase_requisition_details',
    'purchase_orders', 'purchase_order_details', 'goods_receipts',
    'goods_receipt_details', 'supplier_payables', 'supplier_payments'
  ]
  loop
    execute format(
      'alter table public.%I enable row level security',
      table_name
    );
    execute format(
      'alter table public.%I force row level security',
      table_name
    );
  end loop;
end;
$$;

create policy branches_read
on public.branches
for select
to authenticated
using (
  branch_id = (select app_private.jwt_branch_id())
  or (select app_private.jwt_role_codes()) @> array['superadmin']::text[]
);

create policy profiles_read_self
on public.profiles
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or (select app_private.jwt_role_codes()) @> array['superadmin']::text[]
);

create policy roles_read
on public.roles
for select
to authenticated
using (true);

create policy staff_assignments_read
on public.staff_assignments
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or (select app_private.can_read_branch(
    branch_id,
    array['manager']::text[]
  ))
);

create policy audit_logs_read
on public.audit_logs
for select
to authenticated
using (
  (select app_private.can_read_branch(
    branch_id,
    array['manager', 'accounting']::text[]
  ))
);

create policy notifications_read
on public.notifications
for select
to authenticated
using (
  target_profile_id = (select auth.uid())
  or (select app_private.can_read_branch(
    branch_id,
    array['manager']::text[]
  ))
);

-- Auth Hook support. The hook itself is intentionally not defined here because
-- the application must first decide how a multi-branch user selects the active
-- assignment represented by the token.
create policy profiles_auth_admin_read
on public.profiles
for select
to supabase_auth_admin
using (true);

create policy roles_auth_admin_read
on public.roles
for select
to supabase_auth_admin
using (true);

create policy staff_assignments_auth_admin_read
on public.staff_assignments
for select
to supabase_auth_admin
using (true);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'areas', 'dining_tables', 'reservations', 'reservation_tables',
    'dining_sessions', 'session_guests', 'session_tables', 'service_requests',
    'branch_menu_items', 'orders', 'order_details'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using '
      || '((select app_private.can_read_branch('
      || 'branch_id, array[''manager'',''reception'',''hall'',''kitchen'']::text[])))',
      table_name || '_operations_read',
      table_name
    );
  end loop;
end;
$$;

create policy menu_categories_read
on public.menu_categories for select to authenticated
using (
  owner_branch_id is null
  or (select app_private.can_read_branch(
    owner_branch_id, array['manager','reception','hall','kitchen']::text[]
  ))
);

create policy menu_items_read
on public.menu_items for select to authenticated
using (
  owner_branch_id is null
  or (select app_private.can_read_branch(
    owner_branch_id, array['manager','reception','hall','kitchen']::text[]
  ))
);

create policy ingredients_read
on public.ingredients for select to authenticated
using (
  owner_branch_id is null
  or (select app_private.can_read_branch(
    owner_branch_id,
    array['manager','kitchen','procurement','accounting']::text[]
  ))
);

create policy package_details_read
on public.package_details for select to authenticated using (true);

create policy bom_details_read
on public.bom_details for select to authenticated using (true);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'customers', 'customer_feedbacks'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using '
      || '((select app_private.can_read_branch('
      || 'branch_id, array[''manager'',''reception'',''crm'']::text[])))',
      table_name || '_crm_read',
      table_name
    );
  end loop;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'branch_ingredients', 'inventory_transactions'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using '
      || '((select app_private.can_read_branch('
      || 'branch_id, array[''manager'',''kitchen'',''procurement'',''accounting'']::text[])))',
      table_name || '_inventory_read',
      table_name
    );
  end loop;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'shifts', 'bills', 'bill_details', 'payment_intents', 'payment_attempts',
    'payments', 'vouchers', 'invoices',
    'customer_debt_transactions', 'cash_expenses'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using '
      || '((select app_private.can_read_branch('
      || 'branch_id, array[''manager'',''reception'',''accounting'']::text[])))',
      table_name || '_finance_read',
      table_name
    );
  end loop;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'suppliers', 'purchase_requisitions', 'purchase_requisition_details',
    'purchase_orders', 'purchase_order_details', 'goods_receipts',
    'goods_receipt_details', 'supplier_payables', 'supplier_payments'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using '
      || '((select app_private.can_read_branch('
      || 'branch_id, array[''manager'',''procurement'',''accounting'']::text[])))',
      table_name || '_supply_read',
      table_name
    );
  end loop;
end;
$$;

-- outbox_jobs has RLS but intentionally no client policy.

-- ============================================================================
-- M. EXPLICIT DATA API GRANTS
-- Database-as-API: authenticated clients execute RPCs, never query tables
-- directly. service_role is reserved for trusted server operations.
-- ============================================================================

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'branches', 'profiles', 'roles', 'staff_assignments', 'audit_logs',
    'notifications', 'outbox_jobs', 'shifts', 'areas', 'dining_tables',
    'customers', 'reservations', 'reservation_tables', 'dining_sessions',
    'session_guests', 'session_tables', 'service_requests',
    'customer_feedbacks', 'menu_categories', 'menu_items', 'branch_menu_items',
    'package_details', 'ingredients', 'branch_ingredients', 'bom_details',
    'inventory_transactions', 'orders', 'order_details', 'bills',
    'bill_details', 'payment_intents', 'payment_attempts', 'payments',
    'vouchers', 'invoices',
    'customer_debt_transactions', 'cash_expenses', 'suppliers',
    'purchase_requisitions', 'purchase_requisition_details',
    'purchase_orders', 'purchase_order_details', 'goods_receipts',
    'goods_receipt_details', 'supplier_payables', 'supplier_payments'
  ]
  loop
    execute format(
      'revoke all on table public.%I from public, anon, authenticated',
      table_name
    );
    execute format(
      'grant all on table public.%I to service_role',
      table_name
    );
  end loop;
end;
$$;

grant usage on schema public to authenticated;

-- audit_logs remains append-only even for service_role.
revoke update, delete, truncate on public.audit_logs from service_role;

grant usage on schema public to supabase_auth_admin;
grant select on table
  public.profiles,
  public.roles,
  public.staff_assignments
to supabase_auth_admin;

commit;
