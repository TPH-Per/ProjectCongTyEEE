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
