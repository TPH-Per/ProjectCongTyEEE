-- ==============================================================================
-- DATABASE SCHEMA: NguuCat POS (Optimized & High Consistency vs JSONB)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'reception', 'staff', 'kitchen');
CREATE TYPE table_status AS ENUM ('available', 'reserved', 'occupied', 'maintenance', 'needs_cleaning');
CREATE TYPE reservation_status AS ENUM ('Pending', 'Arrived', 'Dining', 'Completed', 'Cancelled');
CREATE TYPE order_status AS ENUM ('Pending', 'Preparing', 'Served', 'Paid', 'Cancelled');
CREATE TYPE invoice_status AS ENUM ('draft', 'issued', 'paid', 'cancelled', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'transfer', 'voucher', 'other');
CREATE TYPE shift_status AS ENUM ('open', 'closed');
CREATE TYPE package_type AS ENUM ('buffet', 'set', 'drink', 'other');
CREATE TYPE revenue_type AS ENUM ('lunch', 'dinner', 'wine', 'delivery', 'other');
CREATE TYPE voucher_type AS ENUM ('percent', 'amount');

-- 3. HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION public.current_user_id() RETURNS uuid AS $$
  SELECT auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION public.current_branch_id() RETURNS uuid AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::jsonb ->> 'branch_id')::uuid,
    (SELECT branch_id FROM public.users WHERE id = auth.uid())
  );
$$ LANGUAGE sql STABLE;

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

-- 4. CORE HIGH-CONSISTENCY TABLES

-- 4.1. BRANCHES (Tenant ID)
CREATE TABLE public.branches (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  address text,
  phone text,
  timezone text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  currency text NOT NULL DEFAULT 'VND',
  vat_rate numeric(5,4) NOT NULL DEFAULT 0.08,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4.2. USERS (Employees)
CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES public.branches(id) ON DELETE SET NULL,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  role user_role NOT NULL DEFAULT 'staff',
  is_active boolean NOT NULL DEFAULT true,
  preferences jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX users_branch_idx ON public.users(branch_id);

-- 4.3. TABLES (Physical tables, zones folded into 'zone' text column)
CREATE TABLE public.tables (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  zone text NOT NULL DEFAULT 'Main',
  code text NOT NULL,
  capacity int NOT NULL CHECK (capacity > 0),
  shape text CHECK (shape IN ('round','square','rectangle')),
  pos_x numeric(10,2) NOT NULL DEFAULT 0,
  pos_y numeric(10,2) NOT NULL DEFAULT 0,
  status table_status NOT NULL DEFAULT 'available',
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, code)
);
CREATE INDEX tables_branch_zone_idx ON public.tables(branch_id, zone);

-- 4.4. CUSTOMERS
CREATE TABLE public.customers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  email text,
  total_visits int NOT NULL DEFAULT 0,
  total_spent numeric(14,2) NOT NULL DEFAULT 0,
  last_visit_at timestamptz,
  is_vip boolean NOT NULL DEFAULT false,
  tags jsonb NOT NULL DEFAULT '[]',
  preferences jsonb NOT NULL DEFAULT '{}',
  demographics jsonb NOT NULL DEFAULT '{}',
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX customers_branch_phone_idx ON public.customers(branch_id, phone);
CREATE INDEX customers_vip_idx ON public.customers(branch_id) WHERE is_vip;
CREATE INDEX customers_tags_gin ON public.customers USING GIN (tags);

-- 4.5. MENU ITEMS (Categories folded into 'category' text column)
-- i18n_name & i18n_description hold translations {"vi": "Bò Wagyu", "en": "Wagyu Beef", "ja": "和牛"}
CREATE TABLE public.menu_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  category text NOT NULL DEFAULT 'General',
  name text NOT NULL,
  i18n_name jsonb NOT NULL DEFAULT '{"vi":"","en":"","ja":""}',
  description text,
  i18n_description jsonb NOT NULL DEFAULT '{"vi":"","en":"","ja":""}',
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  cost numeric(12,2) CHECK (cost IS NULL OR cost >= 0),
  unit text NOT NULL DEFAULT 'Phần',
  image_url text,
  is_available boolean NOT NULL DEFAULT true,
  modifiers jsonb NOT NULL DEFAULT '[]',
  tags jsonb NOT NULL DEFAULT '[]',
  nutrition jsonb NOT NULL DEFAULT '{}',
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX menu_items_branch_cat_idx ON public.menu_items(branch_id, category) WHERE is_available;
CREATE INDEX menu_items_tags_gin ON public.menu_items USING GIN (tags);

-- 4.6. PACKAGES (Buffet/Set items included as JSONB array)
CREATE TABLE public.packages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name text NOT NULL,
  i18n_name jsonb NOT NULL DEFAULT '{"vi":"","en":"","ja":""}',
  type package_type NOT NULL,
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  item_limit int CHECK (item_limit IS NULL OR item_limit > 0),
  duration_minutes int CHECK (duration_minutes IS NULL OR duration_minutes > 0),
  image_url text,
  is_active boolean NOT NULL DEFAULT true,
  items_included jsonb NOT NULL DEFAULT '[]', -- JSONB array of { menu_item_id, limit }
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX packages_branch_type_idx ON public.packages(branch_id, type) WHERE is_active;

-- 4.7. RESERVATIONS (Combines Reservation, TableSession, and TableAssignment)
CREATE TABLE public.reservations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES public.customers(id) ON DELETE RESTRICT,
  table_id uuid REFERENCES public.tables(id) ON DELETE SET NULL,
  booking_code text NOT NULL,
  reservation_date date NOT NULL,
  reservation_time time NOT NULL,
  guests int NOT NULL CHECK (guests > 0),
  children_count int NOT NULL DEFAULT 0,
  status reservation_status NOT NULL DEFAULT 'Pending',
  source text,
  customer_snapshot jsonb NOT NULL DEFAULT '{}',
  booking_info jsonb NOT NULL DEFAULT '{}',
  survey_results jsonb NOT NULL DEFAULT '{}',
  course_id uuid REFERENCES public.packages(id) ON DELETE SET NULL,
  drink_group text,
  qr_token text,
  qr_expires_at timestamptz,
  timer_started_at timestamptz,
  expected_end_at timestamptz,
  arrived_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, booking_code)
);
CREATE INDEX reservations_branch_date_idx ON public.reservations(branch_id, reservation_date);
CREATE INDEX reservations_branch_status_idx ON public.reservations(branch_id, status);
CREATE INDEX reservations_table_active_idx ON public.reservations(table_id) WHERE status IN ('Arrived', 'Dining');

-- 4.8. ORDERS (Batching of order rounds for KDS)
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  reservation_id uuid NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  order_number text NOT NULL,
  status order_status NOT NULL DEFAULT 'Pending',
  subtotal numeric(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  vat_rate numeric(5,4) NOT NULL DEFAULT 0.08,
  vat numeric(14,2) NOT NULL DEFAULT 0 CHECK (vat >= 0),
  total numeric(14,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  notes jsonb NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, order_number)
);
CREATE INDEX orders_branch_idx ON public.orders(branch_id, created_at DESC);
CREATE INDEX orders_reservation_idx ON public.orders(reservation_id);

-- 4.9. ORDER ITEMS
CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_item_id uuid NOT NULL REFERENCES public.menu_items(id) ON DELETE RESTRICT,
  name_snapshot text NOT NULL,
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  unit_cost numeric(12,2) CHECK (unit_cost IS NULL OR unit_cost >= 0),
  quantity numeric(10,2) NOT NULL CHECK (quantity > 0),
  line_total numeric(14,2) NOT NULL CHECK (line_total >= 0),
  status order_status NOT NULL DEFAULT 'Pending',
  modifiers jsonb NOT NULL DEFAULT '[]',
  note text,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX order_items_order_idx ON public.order_items(order_id);
CREATE INDEX order_items_kds_idx ON public.order_items(branch_id, status) WHERE status IN ('Pending', 'Preparing');

-- 4.10. INVOICES (Billing, VAT, Vouchers folded in)
CREATE TABLE public.invoices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  reservation_id uuid NOT NULL REFERENCES public.reservations(id) ON DELETE RESTRICT,
  invoice_number text NOT NULL,
  status invoice_status NOT NULL DEFAULT 'draft',
  subtotal numeric(14,2) NOT NULL DEFAULT 0,
  vat numeric(14,2) NOT NULL DEFAULT 0,
  discount numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  tax_info jsonb NOT NULL DEFAULT '{}', -- stores tax_code, company_name, etc.
  applied_vouchers jsonb NOT NULL DEFAULT '[]', -- stores { voucher_id, code, discount_amount }
  customer_snapshot jsonb NOT NULL DEFAULT '{}',
  notes jsonb NOT NULL DEFAULT '{}',
  metadata jsonb NOT NULL DEFAULT '{}',
  issued_at timestamptz,
  issued_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, invoice_number)
);
CREATE INDEX invoices_branch_idx ON public.invoices(branch_id);
CREATE INDEX invoices_reservation_idx ON public.invoices(reservation_id);

-- 4.11. SHIFTS
CREATE TABLE public.shifts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  status shift_status NOT NULL DEFAULT 'open',
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  opening_cash numeric(14,2) NOT NULL DEFAULT 0,
  closing_cash numeric(14,2),
  expected_cash numeric(14,2),
  cash_difference numeric(14,2),
  notes jsonb NOT NULL DEFAULT '{}',
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX shifts_branch_user_idx ON public.shifts(branch_id, user_id, opened_at DESC);

-- 4.12. PAYMENTS
CREATE TABLE public.payments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE RESTRICT,
  shift_id uuid REFERENCES public.shifts(id) ON DELETE SET NULL,
  method payment_method NOT NULL,
  revenue_type revenue_type NOT NULL DEFAULT 'other',
  amount numeric(14,2) NOT NULL CHECK (amount > 0),
  received_amount numeric(14,2),
  change_amount numeric(14,2) DEFAULT 0,
  reference text,
  metadata jsonb NOT NULL DEFAULT '{}',
  paid_at timestamptz NOT NULL DEFAULT now(),
  received_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX payments_invoice_idx ON public.payments(invoice_id);
CREATE INDEX payments_shift_idx ON public.payments(shift_id);
CREATE INDEX payments_revenue_idx ON public.payments(branch_id, revenue_type, paid_at DESC);

-- 4.13. VOUCHERS
CREATE TABLE public.vouchers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  code text NOT NULL,
  type voucher_type NOT NULL,
  value numeric(12,2) NOT NULL CHECK (value > 0),
  valid_from date,
  valid_until date,
  max_uses int CHECK (max_uses IS NULL OR max_uses > 0),
  used_count int NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, code)
);
CREATE INDEX vouchers_branch_active_idx ON public.vouchers(branch_id) WHERE is_active;

-- 5. LOW-CONSISTENCY & JSONB TABLES (No foreign keys)

-- 5.1. AUDIT EVENTS
CREATE TABLE public.audit_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL,
  actor_id uuid,
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  payload jsonb NOT NULL DEFAULT '{}',
  ip_address inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_events_branch_created_idx ON public.audit_events USING BRIN (branch_id, created_at);
CREATE INDEX audit_events_payload_gin ON public.audit_events USING GIN (payload);

-- 5.2. NOTIFICATIONS
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL,
  channel text NOT NULL,
  recipient text NOT NULL,
  template text NOT NULL,
  variables jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'pending',
  sent_at timestamptz,
  error_message text,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_pending_idx ON public.notifications(created_at) WHERE status = 'pending';

-- 5.3. BRANCH SETTINGS (Handles KPI, Marketing, Waitlist, generic config via JSONB)
CREATE TABLE public.branch_settings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid NOT NULL,
  key text NOT NULL,
  value jsonb NOT NULL,
  value_type text NOT NULL DEFAULT 'string',
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id, key)
);
CREATE INDEX branch_settings_branch_idx ON public.branch_settings(branch_id) WHERE is_active;

-- 5.4. SYSTEM EVENTS
CREATE TABLE public.system_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id uuid,
  type text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX system_events_created_idx ON public.system_events USING BRIN (created_at);

-- 6. TRIGGERS (Auto updated_at)
CREATE TRIGGER set_updated_at_branches BEFORE UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_users BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_tables BEFORE UPDATE ON public.tables FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_customers BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_menu_items BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_packages BEFORE UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_reservations BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_orders BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_order_items BEFORE UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_invoices BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_vouchers BEFORE UPDATE ON public.vouchers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_shifts BEFORE UPDATE ON public.shifts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER set_updated_at_branch_settings BEFORE UPDATE ON public.branch_settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 7. AUTOVACUUM OPTIMIZATION FOR HOT TABLES
ALTER TABLE public.reservations SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE public.order_items SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE public.tables SET (autovacuum_vacuum_scale_factor = 0.05);

-- 8. RLS ENABLING (All tables)
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_events ENABLE ROW LEVEL SECURITY;

-- Additional granular RLS policies and audit triggers should be applied in the migration script.
