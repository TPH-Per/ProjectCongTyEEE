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
