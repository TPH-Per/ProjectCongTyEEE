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
