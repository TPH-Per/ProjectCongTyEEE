-- =============================================================================
-- PATCH process_checkout: stamp payments.shift_id + release table_assignments
-- Date: 2026-07-03
--
-- Two follow-up fixes to the 20260703020000 patch:
--
--   1. payments.shift_id was never set, so `close-shift` aggregations returned
--      empty payment lists and the "expected cash" was always equal to
--      `opening_cash`. Now we look up the cashier's currently-open shift
--      in the same transaction and stamp it on the new `payments` row.
--      If the cashier has no open shift (e.g. legacy unshifted flow), we
--      stamp NULL and log a warning so the manager can investigate.
--
--   2. table_assignments.released_at was never set on payment completion.
--      This left zombie rows pointing at the table, which broke the
--      `crm_list_serving_tables` LATERAL join (`WHERE released_at IS NULL`).
--      We now release all open assignments for the order's table in the
--      same transaction.
--
-- Idempotent: CREATE OR REPLACE — safe to re-apply.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.process_checkout(
  p_order_id       uuid,
  p_branch_id      uuid,
  p_cashier_id     uuid,
  p_payment_method text,
  p_voucher_code   text DEFAULT NULL,
  p_points_to_use  int DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order record;
  v_reservation record;
  v_customer_id uuid;
  v_bill_id uuid;
  v_invoice_id uuid;
  v_bill_code text;
  v_invoice_number text;
  v_subtotal numeric(14,2);
  v_voucher_discount numeric(14,2) := 0;
  v_voucher_id uuid;
  v_voucher_validate jsonb;
  v_points_discount numeric(14,2) := 0;
  v_vnd_per_point numeric(10,2);
  v_total_discount numeric(14,2);
  v_net_before_tax numeric(14,2);
  v_vat_rate numeric(5,4);
  v_vat_amount numeric(14,2);
  v_service_charge_percent numeric(5,2) := 5.00;  -- match frontend 5%
  v_service_charge_amount numeric(14,2) := 0;
  v_grand_total numeric(14,2);
  v_payment_method public.payment_method;
  v_linked_surveys int := 0;
  -- NEW (2026-07-03 patch):
  v_open_shift_id uuid;
  v_no_open_shift_warning text;
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  v_payment_method := CASE upper(COALESCE(p_payment_method, 'other'))
    WHEN 'CASH' THEN 'cash'::public.payment_method
    WHEN 'CARD' THEN 'card'::public.payment_method
    WHEN 'TRANSFER' THEN 'transfer'::public.payment_method
    WHEN 'VOUCHER' THEN 'voucher'::public.payment_method
    WHEN 'MOMO' THEN 'transfer'::public.payment_method
    WHEN 'ZALOPAY' THEN 'transfer'::public.payment_method
    WHEN 'VNPAY' THEN 'transfer'::public.payment_method
    ELSE 'other'::public.payment_method
  END;

  SELECT o.*, b.vat_rate INTO v_order
  FROM public.orders o
  JOIN public.branches b ON b.id = o.branch_id
  WHERE o.id = p_order_id
    AND o.branch_id = p_branch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found for this branch';
  END IF;

  IF v_order.status IN ('Paid','Cancelled') THEN
    RAISE EXCEPTION 'Order is already % - cannot checkout again', v_order.status;
  END IF;

  -- Resolve customer via reservation.
  v_customer_id := NULL;
  IF v_order.reservation_id IS NOT NULL THEN
    SELECT customer_id INTO v_customer_id
    FROM public.reservations
    WHERE id = v_order.reservation_id
      AND branch_id = p_branch_id;
  END IF;

  -- Resolve the cashier's currently-open shift (NEW).
  -- We stamp `shift_id` on every payment row so `close-shift` can
  -- aggregate by shift. If the cashier never opened a shift today,
  -- the payment still goes through with `shift_id = NULL` and a
  -- warning is returned so the caller (manager dashboard) can flag it.
  v_no_open_shift_warning := NULL;
  SELECT id INTO v_open_shift_id
  FROM public.shifts
  WHERE user_id = p_cashier_id
    AND branch_id = p_branch_id
    AND status = 'open'
  ORDER BY opened_at DESC
  LIMIT 1;
  IF v_open_shift_id IS NULL THEN
    v_no_open_shift_warning := 'cashier has no open shift; payment stamped with shift_id=NULL';
    RAISE WARNING '[process_checkout] % (cashier=% branch=%)',
      v_no_open_shift_warning, p_cashier_id, p_branch_id;
  END IF;

  -- Subtotal: read orders.subtotal (already excludes cancelled items, since
  -- add-order-item now filters status != 'Cancelled' on every recalc).
  v_subtotal := COALESCE(v_order.subtotal, 0);
  v_vat_rate := COALESCE(v_order.vat_rate, 0.08);

  -- A. Voucher
  IF p_voucher_code IS NOT NULL AND btrim(p_voucher_code) <> '' THEN
    v_voucher_validate := public.validate_voucher(
      p_voucher_code,
      p_branch_id,
      v_subtotal,
      v_customer_id
    );
    IF COALESCE((v_voucher_validate->>'valid')::boolean, false) = false THEN
      RAISE EXCEPTION 'VOUCHER_INVALID: %', COALESCE(v_voucher_validate->>'error', 'unknown')
        USING ERRCODE = '22023';
    END IF;
    v_voucher_id := (v_voucher_validate->>'voucher_id')::uuid;
    v_voucher_discount := COALESCE((v_voucher_validate->>'discount_amount')::numeric, 0);
  END IF;

  -- B. Points → VND
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

  v_total_discount := v_voucher_discount + v_points_discount;
  v_net_before_tax := GREATEST(0, v_subtotal - v_total_discount);
  v_service_charge_amount := ROUND(v_net_before_tax * v_service_charge_percent / 100, 0);
  v_vat_amount := ROUND((v_net_before_tax + v_service_charge_amount) * v_vat_rate, 0);
  v_grand_total := v_net_before_tax + v_service_charge_amount + v_vat_amount;

  v_bill_code := 'BILL-' || to_char(now(), 'YYMMDD-HH24MISS') || '-'
              || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.bills (
    branch_id, bill_code, order_id, table_id, cashier_id,
    sub_total, discount_total,
    vat_8_amount, vat_10_amount,
    service_charge_percent, service_charge_amount,
    grand_total, payment_method, status
  ) VALUES (
    p_branch_id, v_bill_code, p_order_id, v_order.table_id, p_cashier_id,
    v_subtotal, v_total_discount,
    CASE WHEN v_vat_rate <= 0.085 THEN v_vat_amount ELSE 0 END,
    CASE WHEN v_vat_rate > 0.085 THEN v_vat_amount ELSE 0 END,
    v_service_charge_percent, v_service_charge_amount,
    v_grand_total, v_payment_method::text, 'PAID'
  )
  RETURNING id INTO v_bill_id;

  INSERT INTO public.bill_items (
    bill_id, menu_item_id, name_snapshot, quantity,
    unit_price, unit_cost, line_total
  )
  SELECT
    v_bill_id, oi.menu_item_id, oi.name_snapshot, oi.quantity,
    oi.unit_price, oi.unit_cost, oi.line_total
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id
    AND oi.status != 'Cancelled';

  v_invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.invoices (
    branch_id, bill_id, invoice_symbol, invoice_number, issue_date,
    total_goods_amount, total_tax_amount, grand_total, status, created_by
  ) VALUES (
    p_branch_id, v_bill_id, 'AA/24E', v_invoice_number, CURRENT_DATE,
    v_net_before_tax, v_vat_amount, v_grand_total, 'VALID', p_cashier_id
  )
  RETURNING id INTO v_invoice_id;

  -- Payment row now stamped with `shift_id` (NEW).
  INSERT INTO public.payments (
    branch_id, invoice_id, method, revenue_type,
    amount, received_amount, change_amount, received_by,
    shift_id
  ) VALUES (
    p_branch_id, v_invoice_id, v_payment_method, 'other',
    v_grand_total, v_grand_total, 0, p_cashier_id,
    v_open_shift_id
  );

  IF v_voucher_id IS NOT NULL THEN
    PERFORM public.redeem_voucher(
      v_voucher_id, v_invoice_id, p_branch_id, v_subtotal, v_customer_id
    );
  END IF;

  v_linked_surveys := public.crm_link_surveys_to_bill(p_order_id, v_bill_id);

  UPDATE public.orders
  SET status = 'Paid', vat = v_vat_amount, discount = v_total_discount, total = v_grand_total
  WHERE id = p_order_id;

  -- Release the table + the open table_assignment (NEW).
  IF v_order.table_id IS NOT NULL THEN
    UPDATE public.tables
    SET status = 'available'
    WHERE id = v_order.table_id;

    UPDATE public.table_assignments
    SET released_at = now()
    WHERE table_id = v_order.table_id
      AND released_at IS NULL;
  END IF;

  IF v_customer_id IS NOT NULL THEN
    UPDATE public.customers
    SET total_visits = total_visits + 1,
        total_spent  = total_spent + v_grand_total,
        last_visit_at = now(),
        updated_at = now()
    WHERE id = v_customer_id AND branch_id = p_branch_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'bill_id', v_bill_id,
    'invoice_id', v_invoice_id,
    'invoice_number', v_invoice_number,
    'subtotal', v_subtotal,
    'discount_total', v_total_discount,
    'voucher_discount', v_voucher_discount,
    'points_discount', v_points_discount,
    'service_charge_amount', v_service_charge_amount,
    'vat_amount', v_vat_amount,
    'grand_total', v_grand_total,
    'linked_crm_surveys', v_linked_surveys,
    'shift_id', v_open_shift_id,
    'no_open_shift_warning', v_no_open_shift_warning
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,text,text,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,text,text,int) TO authenticated;

COMMENT ON FUNCTION public.process_checkout(uuid,uuid,uuid,text,text,int) IS
  'Atomic checkout: applies voucher (via validate_voucher + redeem_voucher), '
  'persists 5% service charge, VAT, updates customer stats, links CRM surveys, '
  'releases table + table_assignments. Stamps payments.shift_id from the '
  'cashier''s currently-open shift (NULL if none). Returns the full bill '
  'breakdown plus a `no_open_shift_warning` when the cashier never opened '
  'a shift.';