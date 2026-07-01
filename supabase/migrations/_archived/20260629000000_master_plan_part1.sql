-- ==============================================================================
-- MASTER PLAN - PART 1: DATABASE MIGRATIONS (NEW ROLES, TABLES, PATCHES)
-- ==============================================================================

-- 1. PATCH EXISTING TABLES
ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS subtotal_before_discount  numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_voucher_amount   numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_points_amount    numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_tier_amount      numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_before_tax            numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS service_charge_percent    numeric(5,2)  DEFAULT 5,
  ADD COLUMN IF NOT EXISTS service_charge_amount     numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vat_percent               numeric(5,2)  DEFAULT 10,
  ADD COLUMN IF NOT EXISTS grand_total               numeric(14,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_method            text CHECK (payment_method IN ('CASH','CARD','ZALOPAY','MOMO','VNPAY','POINTS_ONLY','MIXED')),
  ADD COLUMN IF NOT EXISTS payment_reference         text,
  ADD COLUMN IF NOT EXISTS cashier_id                uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS printed_at                timestamptz,
  ADD COLUMN IF NOT EXISTS is_void                   boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS void_reason               text,
  ADD COLUMN IF NOT EXISTS voided_by                 uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS voided_at                 timestamptz;

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS order_type       text DEFAULT 'A_LA_CARTE' CHECK (order_type IN ('BUFFET','A_LA_CARTE')),
  ADD COLUMN IF NOT EXISTS guest_count      int DEFAULT 1,
  ADD COLUMN IF NOT EXISTS order_source     text DEFAULT 'TABLET' CHECK (order_source IN ('TABLET','STAFF','APP','PHONE')),
  ADD COLUMN IF NOT EXISTS buffet_package_id uuid, -- references public.packages(id)
  ADD COLUMN IF NOT EXISTS completed_at     timestamptz,
  ADD COLUMN IF NOT EXISTS cancelled_at     timestamptz,
  ADD COLUMN IF NOT EXISTS cancel_reason    text;

-- 2. SEQUENCES
CREATE SEQUENCE IF NOT EXISTS po_seq START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS req_seq START 1 INCREMENT 1 NO CYCLE;

-- 3. INVENTORY & KITCHEN (Plan 1 Missing Tables)
CREATE TABLE IF NOT EXISTS public.ingredient_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   uuid REFERENCES public.branches(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ingredients (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid REFERENCES public.branches(id) ON DELETE CASCADE,
  category_id     uuid REFERENCES public.ingredient_categories(id),
  name            text NOT NULL,
  sku             text,
  unit            text NOT NULL, -- e.g., kg, gram, lít, hộp
  cost_per_unit   numeric(14,2) DEFAULT 0,
  min_stock_level numeric(12,3) DEFAULT 0,
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.inventory_stock (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
  quantity      numeric(12,3) NOT NULL DEFAULT 0,
  updated_at    timestamptz DEFAULT now(),
  UNIQUE(branch_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id),
  type          text NOT NULL CHECK (type IN ('IN','OUT','ADJUST','WASTE','RETURN')),
  quantity      numeric(12,3) NOT NULL,
  balance_after numeric(12,3) NOT NULL,
  reference_id  uuid, -- order_id, po_id, requisition_id
  notes         text,
  created_by    uuid REFERENCES auth.users(id),
  created_at    timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.requisitions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  req_number       text NOT NULL, -- REQ-YYYY-NNNNN
  status           text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','PROCESSED')),
  requested_by     uuid REFERENCES auth.users(id),
  approved_by      uuid REFERENCES auth.users(id),
  notes            text,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.requisition_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requisition_id    uuid NOT NULL REFERENCES public.requisitions(id) ON DELETE CASCADE,
  ingredient_id     uuid NOT NULL REFERENCES public.ingredients(id),
  requested_qty     numeric(12,3) NOT NULL,
  approved_qty      numeric(12,3)
);

CREATE TABLE IF NOT EXISTS public.kitchen_shifts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  opened_by    uuid NOT NULL REFERENCES auth.users(id),
  closed_by    uuid REFERENCES auth.users(id),
  opened_at    timestamptz NOT NULL DEFAULT now(),
  closed_at    timestamptz,
  status       text NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','CLOSED')),
  notes        text
);

-- 4. TABLET (Plan 1 Missing Tables)
CREATE TABLE IF NOT EXISTS public.tablet_content (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   uuid REFERENCES public.branches(id) ON DELETE CASCADE,
  type        text NOT NULL CHECK (type IN ('CAROUSEL','PROMO','VIDEO')),
  image_url   text,
  video_url   text,
  title       text,
  is_active   boolean DEFAULT true,
  sort_order  int DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tablet_sessions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id      uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  table_id       uuid NOT NULL REFERENCES public.tables(id),
  reservation_id uuid REFERENCES public.reservations(id),
  customer_id    uuid REFERENCES public.customers(id),
  status         text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','IDLE','CHECKOUT_REQUESTED','ENDED')),
  language       text DEFAULT 'vi',
  started_at     timestamptz NOT NULL DEFAULT now(),
  ended_at       timestamptz
);

-- 5. NEW ROLES TABLES
CREATE TABLE IF NOT EXISTS public.service_requests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id),
  table_id     uuid NOT NULL REFERENCES public.tables(id),
  order_id     uuid REFERENCES public.orders(id),
  type         text NOT NULL CHECK (type IN ('CALL_WAITER','REQUEST_BILL','REQUEST_CONDIMENT','COMPLAINT','OTHER')),
  status       text NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED')),
  message      text,
  priority     text DEFAULT 'NORMAL' CHECK (priority IN ('NORMAL','URGENT')),
  resolved_by  uuid REFERENCES auth.users(id),
  resolved_at  timestamptz,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.purchase_orders (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id              uuid NOT NULL REFERENCES public.branches(id),
  po_number              text NOT NULL,
  source_requisition_id  uuid REFERENCES public.requisitions(id),
  status                 text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','SUBMITTED','CONFIRMED_BY_SUPPLIER','PARTIAL','RECEIVED','CANCELLED')),
  ordered_by             uuid NOT NULL REFERENCES auth.users(id),
  expected_delivery_date date,
  actual_delivery_date   date,
  subtotal               numeric(14,2) DEFAULT 0,
  tax_amount             numeric(14,2) DEFAULT 0,
  total_amount           numeric(14,2) DEFAULT 0,
  payment_status         text DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID','PARTIALLY_PAID','PAID')),
  notes                  text,
  metadata               jsonb DEFAULT '{}',
  created_at             timestamptz DEFAULT now(),
  updated_at             timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.purchase_order_items (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id    uuid NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
  ingredient_id        uuid NOT NULL REFERENCES public.ingredients(id),
  ordered_quantity     numeric(12,3) NOT NULL,
  unit                 text NOT NULL,
  unit_price           numeric(12,2) NOT NULL DEFAULT 0,
  total_price          numeric(14,2) GENERATED ALWAYS AS (ordered_quantity * unit_price) STORED,
  received_quantity    numeric(12,3) DEFAULT 0,
  is_fully_received    boolean DEFAULT false
);

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
  vat_rate         numeric(5,2)  DEFAULT 10,
  vat_amount       numeric(16,2) DEFAULT 0,
  other_tax        numeric(16,2) DEFAULT 0,
  total_tax        numeric(16,2) DEFAULT 0,
  expense_total    numeric(16,2) DEFAULT 0,
  gross_profit     numeric(16,2) DEFAULT 0,
  status           text DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','FINALIZED','SUBMITTED')),
  finalized_by     uuid REFERENCES auth.users(id),
  finalized_at     timestamptz,
  notes            text,
  created_at       timestamptz DEFAULT now(),
  UNIQUE (branch_id, period_type, period_start)
);

CREATE TABLE IF NOT EXISTS public.campaigns (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id                uuid REFERENCES public.branches(id),
  name                     text NOT NULL,
  description              text,
  type                     text NOT NULL CHECK (type IN ('SEASONAL','LOYALTY','FLASH','REFERRAL','BIRTHDAY','GRAND_OPENING')),
  status                   text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','PENDING_APPROVAL','APPROVED','ACTIVE','PAUSED','ENDED','REJECTED')),
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
  created_at               timestamptz DEFAULT now(),
  updated_at               timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.campaign_vouchers (
  campaign_id  uuid NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  voucher_id   uuid NOT NULL REFERENCES public.vouchers(id),
  PRIMARY KEY (campaign_id, voucher_id)
);

CREATE TABLE IF NOT EXISTS public.bod_approvals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type   text NOT NULL CHECK (entity_type IN ('CAMPAIGN','BUDGET','PROMOTION','POLICY')),
  entity_id     uuid NOT NULL,
  title         text,
  submitted_by  uuid NOT NULL REFERENCES auth.users(id),
  submitted_at  timestamptz DEFAULT now(),
  status        text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED')),
  reviewed_by   uuid REFERENCES auth.users(id),
  reviewed_at   timestamptz,
  review_note   text,
  metadata      jsonb DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.budgets (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  period_type      text NOT NULL CHECK (period_type IN ('MONTHLY','QUARTERLY','ANNUAL')),
  period_start     date NOT NULL,
  period_end       date NOT NULL,
  department       text NOT NULL CHECK (department IN ('KITCHEN','MARKETING','OPERATIONS','PURCHASING','HR','IT','OTHER')),
  allocated_amount numeric(14,2) NOT NULL DEFAULT 0,
  spent_amount     numeric(14,2) DEFAULT 0,
  approved_by      uuid REFERENCES auth.users(id),
  notes            text,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now(),
  UNIQUE (branch_id, department, period_type, period_start)
);

CREATE TABLE IF NOT EXISTS public.customer_feedback (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  order_id         uuid REFERENCES public.orders(id),
  customer_id      uuid REFERENCES public.customers(id),
  table_id         uuid REFERENCES public.tables(id),
  overall_rating   int NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
  food_rating      int CHECK (food_rating BETWEEN 1 AND 5),
  service_rating   int CHECK (service_rating BETWEEN 1 AND 5),
  ambiance_rating  int CHECK (ambiance_rating BETWEEN 1 AND 5),
  comment          text,
  tags             jsonb DEFAULT '[]',
  source           text DEFAULT 'TABLET' CHECK (source IN ('TABLET','QR_CODE','STAFF_ENTRY','APP')),
  is_public        boolean DEFAULT false,
  staff_response   text,
  responded_by     uuid REFERENCES auth.users(id),
  responded_at     timestamptz,
  created_at       timestamptz DEFAULT now()
);

-- Note: RLS policies would be created here if needed.
