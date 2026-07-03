-- =============================================================================
-- PATCH hall_get_checkout_summary → hall_get_checkout_totals
-- Date: 2026-07-03
--
-- The previous hall_get_checkout_summary returned order/items but NOT the totals
-- the cashier needs to see. Cashier had to recompute in JS using
-- vatPct=10/serviceChargePct=5 which disagreed with DB's branches.vat_rate (8%)
-- and a hardcoded 1000 VND/point. The cashier preview could differ from the
-- actual billed amount by hundreds of thousands of VND.
--
-- This new RPC returns the same breakdown process_checkout will compute, so the
-- preview is byte-identical to the eventual bill. The cashier sees the truth.
--
-- Backward-compat: hall_get_checkout_summary is kept (returns order/items only).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.hall_get_checkout_totals(
  p_branch_id    uuid,
  p_table_id     uuid,
  p_order_id     uuid DEFAULT NULL,
  p_voucher_code text DEFAULT NULL,
  p_points_to_use int DEFAULT 0,
  p_customer_id  uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
  v_order record;
  v_subtotal numeric(14,2) := 0;
  v_voucher_discount numeric(14,2) := 0;
  v_voucher_validate jsonb;
  v_points_discount numeric(14,2) := 0;
  v_vnd_per_point numeric(10,2);
  v_total_discount numeric(14,2);
  v_tier_discount numeric(14,2) := 0;
  v_net_before_tax numeric(14,2);
  v_service_charge_percent numeric(5,2) := 5.00;
  v_service_charge_amount numeric(14,2) := 0;
  v_vat_rate numeric(5,4);
  v_vat_amount numeric(14,2) := 0;
  v_grand_total numeric(14,2) := 0;
  v_items jsonb;
  v_table jsonb;
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  -- Resolve order for this table (or by p_order_id if provided).
  IF p_order_id IS NOT NULL THEN
    SELECT o.*, b.vat_rate INTO v_order
    FROM public.orders o
    JOIN public.branches b ON b.id = o.branch_id
    WHERE o.id = p_order_id
      AND o.branch_id = p_branch_id;
  ELSE
    SELECT o.*, b.vat_rate INTO v_order
    FROM public.orders o
    JOIN public.branches b ON b.id = o.branch_id
    WHERE o.table_id = p_table_id
      AND o.branch_id = p_branch_id
      AND o.status IN ('Pending','Preparing','Served')
    ORDER BY o.created_at DESC
    LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'NO_ACTIVE_ORDER_FOR_TABLE');
  END IF;

  -- Subtotal = sum of non-cancelled order lines
  SELECT COALESCE(SUM(oi.line_total), 0) INTO v_subtotal
  FROM public.order_items oi
  WHERE oi.order_id = v_order.id
    AND oi.status != 'Cancelled';

  v_vat_rate := COALESCE(v_order.vat_rate, 0.08);

  -- Tier discount from membership tier (auto-applied at the time of checkout)
  IF p_customer_id IS NOT NULL THEN
    SELECT COALESCE(mt.discount_percent, 0) INTO v_tier_discount
    FROM public.customers c
    LEFT JOIN public.membership_tiers mt
      ON mt.min_spent <= COALESCE(c.total_spent, 0)
     AND (mt.branch_id = c.branch_id OR mt.branch_id IS NULL)
    WHERE c.id = p_customer_id
      AND c.branch_id = p_branch_id
    ORDER BY mt.min_spent DESC
    LIMIT 1;

    v_tier_discount := ROUND(v_subtotal * (v_tier_discount / 100), 0);
  END IF;

  -- Voucher (same validation as process_checkout)
  IF p_voucher_code IS NOT NULL AND btrim(p_voucher_code) <> '' THEN
    v_voucher_validate := public.validate_voucher(
      p_voucher_code, p_branch_id, v_subtotal, p_customer_id
    );
    IF COALESCE((v_voucher_validate->>'valid')::boolean, false) = true THEN
      v_voucher_discount := COALESCE((v_voucher_validate->>'discount_amount')::numeric, 0);
    END IF;
    -- If invalid, v_voucher_discount stays 0; frontend already validated and
    -- would not call with an invalid code, but defence-in-depth.
  END IF;

  -- Points → VND via loyalty rules
  IF p_points_to_use > 0 THEN
    SELECT COALESCE(
      (SELECT vnd_per_point FROM public.loyalty_rules
        WHERE (branch_id = p_branch_id OR branch_id IS NULL)
          AND is_active = true
        ORDER BY branch_id NULLS LAST
        LIMIT 1),
      1000
    ) INTO v_vnd_per_point;
    v_points_discount := ROUND(p_points_to_use * v_vnd_per_point, 0);
  END IF;

  v_total_discount := v_tier_discount + v_voucher_discount + v_points_discount;
  v_net_before_tax := GREATEST(0, v_subtotal - v_total_discount);

  v_service_charge_amount := ROUND(v_net_before_tax * v_service_charge_percent / 100, 0);
  v_vat_amount := ROUND((v_net_before_tax + v_service_charge_amount) * v_vat_rate, 0);
  v_grand_total := v_net_before_tax + v_service_charge_amount + v_vat_amount;

  -- Snapshot for receipt UI (table context + line items)
  SELECT jsonb_build_object('id', t.id, 'code', t.code, 'capacity', t.capacity)
    INTO v_table FROM public.tables t WHERE t.id = v_order.table_id;

  SELECT COALESCE(jsonb_agg(row_to_json(oi)), '[]'::jsonb) INTO v_items
  FROM (
    SELECT id, menu_item_id, name_snapshot, quantity, unit_price, unit_cost, line_total
    FROM public.order_items
    WHERE order_id = v_order.id AND status != 'Cancelled'
    ORDER BY created_at
  ) oi;

  RETURN jsonb_build_object(
    'ok', true,
    'order', jsonb_build_object(
      'id', v_order.id,
      'guest_count', v_order.guest_count,
      'subtotal', v_order.subtotal,
      'status', v_order.status,
      'reservation_id', v_order.reservation_id
    ),
    'table', v_table,
    'items', v_items,
    'totals', jsonb_build_object(
      'subtotal', v_subtotal,
      'tier_discount', v_tier_discount,
      'voucher_discount', v_voucher_discount,
      'points_discount', v_points_discount,
      'total_discount', v_total_discount,
      'net_before_tax', v_net_before_tax,
      'service_charge_percent', v_service_charge_percent,
      'service_charge_amount', v_service_charge_amount,
      'vat_rate', v_vat_rate,
      'vat_amount', v_vat_amount,
      'grand_total', v_grand_total
    ),
    'voucher_valid', v_voucher_discount > 0
       OR (p_voucher_code IS NULL)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_get_checkout_totals(uuid,uuid,uuid,text,int,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_get_checkout_totals(uuid,uuid,uuid,text,int,uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.hall_get_checkout_totals(uuid,uuid,uuid,text,int,uuid) IS
  'Returns the order/items snapshot + the EXACT totals breakdown that '
  'process_checkout will compute. The cashier preview is byte-identical to '
  'the eventual bill.';