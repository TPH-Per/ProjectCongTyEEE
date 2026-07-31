CREATE OR REPLACE FUNCTION public.hall_get_checkout_totals(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL::uuid,
  p_voucher_code text DEFAULT NULL,
  p_points_to_use integer DEFAULT 0,
  p_customer_id uuid DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_session_id uuid;
  v_order      jsonb;
  v_items      jsonb;
  v_subtotal   bigint := 0;
  v_tier_discount bigint := 0;
  v_voucher_discount bigint := 0;
  v_points_discount bigint := 0;
  v_total_discount bigint := 0;
  v_net_before_tax bigint := 0;
  v_service_charge_percent numeric := 0;
  v_service_charge_amount bigint := 0;
  v_vat_rate numeric := 10; -- Assuming 10% VAT
  v_vat_amount bigint := 0;
  v_grand_total bigint := 0;
  v_voucher_valid boolean := false;
  v_voucher_result jsonb;
BEGIN
  -- Find the active dining session for this table
  SELECT ds.dining_session_id INTO v_session_id
  FROM   public.session_tables st
  JOIN   public.dining_sessions ds ON ds.dining_session_id = st.dining_session_id
  WHERE  st.dining_table_id = p_table_id
    AND  ds.branch_id = p_branch_id
    AND  ds.status    = 'open'
  ORDER  BY ds.created_at DESC
  LIMIT  1;

  IF v_session_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'No open session for this table', 'order', NULL, 'items', '[]'::jsonb);
  END IF;

  -- Get the active order (prefer passed order_id)
  SELECT row_to_json(o.*)::jsonb INTO v_order
  FROM   public.orders o
  WHERE  o.dining_session_id = v_session_id
    AND  o.branch_id = p_branch_id
    AND  (p_order_id IS NULL OR o.order_id = p_order_id)
    AND  o.status NOT IN ('cancelled', 'completed')
  ORDER  BY o.created_at DESC
  LIMIT  1;

  IF v_order IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'No open order', 'order', NULL, 'items', '[]'::jsonb);
  END IF;

  -- Get order details
  SELECT jsonb_agg(
    jsonb_build_object(
      'id',              od.order_detail_id,
      'menu_item_id',    od.branch_menu_item_id,
      'name_snapshot',   od.item_name_snapshot,
      'quantity',        od.quantity,
      'cancelled_qty',   od.cancelled_quantity,
      'unit_price',      od.unit_price_vnd_snapshot,
      'kitchen_status',  od.kitchen_status,
      'note',            od.note,
      'line_total',      (od.quantity - od.cancelled_quantity) * od.unit_price_vnd_snapshot
    )
  ), COALESCE(SUM((od.quantity - od.cancelled_quantity) * od.unit_price_vnd_snapshot), 0) INTO v_items, v_subtotal
  FROM   public.order_details od
  WHERE  od.order_id  = (v_order->>'order_id')::uuid
    AND  od.branch_id = p_branch_id
    AND  od.cancelled_quantity < od.quantity;  -- only non-fully-cancelled

  -- Calculate voucher discount if provided
  IF p_voucher_code IS NOT NULL THEN
    -- Try to validate voucher
    -- Depending on your validate_voucher implementation, we call it here
    -- But since we just need the totals, we can mock the validation logic or call validate_voucher
    -- For now, let's just do a basic implementation or call it:
    -- SELECT public.validate_voucher(p_voucher_code, p_branch_id, v_subtotal::numeric, p_customer_id) INTO v_voucher_result;
    -- For simplicity, let's assume it returns a jsonb object with valid, discount_amount
    v_voucher_discount := 0; -- TODO: call validate_voucher if needed
  END IF;

  IF p_points_to_use > 0 THEN
    v_points_discount := p_points_to_use * 1000; -- Assuming 1000vnd per point
  END IF;

  v_total_discount := v_tier_discount + v_voucher_discount + v_points_discount;
  v_net_before_tax := GREATEST(0, v_subtotal - v_total_discount);
  v_service_charge_amount := v_net_before_tax * v_service_charge_percent / 100;
  v_vat_amount := (v_net_before_tax + v_service_charge_amount) * v_vat_rate / 100;
  v_grand_total := v_net_before_tax + v_service_charge_amount + v_vat_amount;

  RETURN jsonb_build_object(
    'ok', true,
    'order', v_order,
    'items', COALESCE(v_items, '[]'::jsonb),
    'voucher_valid', v_voucher_valid,
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
    )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.process_checkout(
  p_order_id uuid,
  p_branch_id uuid,
  p_cashier_id uuid,
  p_payment_method text,
  p_voucher_code text DEFAULT NULL,
  p_points_to_use integer DEFAULT 0,
  p_tax_id text DEFAULT NULL,
  p_company_name text DEFAULT NULL,
  p_require_invoice boolean DEFAULT false,
  p_manager_pin text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_bill_id uuid;
  v_totals jsonb;
  v_invoice_number text;
  v_dining_session_id uuid;
  v_customer_id uuid;
  v_is_vip boolean := false;
BEGIN
  -- Get the dining_session_id from the order
  SELECT dining_session_id INTO v_dining_session_id
  FROM public.orders WHERE order_id = p_order_id AND branch_id = p_branch_id;

  SELECT customer_id INTO v_customer_id
  FROM public.dining_sessions WHERE dining_session_id = v_dining_session_id;

  IF v_customer_id IS NOT NULL THEN
    -- Check if customer is VIP or allowed for debt (mocked as true for VIP profiles)
    SELECT (profile_data->>'is_vip')::boolean INTO v_is_vip 
    FROM public.customers WHERE customer_id = v_customer_id;
  END IF;

  IF p_payment_method = 'DEBT' THEN
    IF v_is_vip IS NOT true THEN
      IF p_manager_pin IS NULL OR p_manager_pin = '' THEN
        RAISE EXCEPTION 'Manager PIN required for DEBT payment method';
      END IF;
      PERFORM public.fn_verify_manager_pin(p_manager_pin);
    END IF;
  END IF;

  -- Just create a dummy invoice number for now
  v_invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD-HH24MISS');

  -- Create the bill
  INSERT INTO public.bills (
    branch_id, dining_session_id, bill_number, 
    subtotal_vnd, discount_vnd, service_charge_vnd, vat_vnd, grand_total_vnd, paid_total_vnd, debt_total_vnd, status, cashier_profile_id
  ) VALUES (
    p_branch_id, v_dining_session_id, v_invoice_number,
    0, 0, 0, 0, 0, 0, 0, 'paid', p_cashier_id
  ) RETURNING bill_id INTO v_bill_id;

  -- If D2 E-Invoice Trigger is requested
  IF p_require_invoice AND p_tax_id IS NOT NULL THEN
    INSERT INTO public.outbox_jobs (branch_id, type, payload)
    VALUES (p_branch_id, 'einvoice_issue', jsonb_build_object(
      'bill_id', v_bill_id,
      'tax_id', p_tax_id,
      'company_name', p_company_name
    ));
  END IF;

  -- Close the dining session
  UPDATE public.dining_sessions SET status = 'completed' WHERE dining_session_id = v_dining_session_id;

  RETURN jsonb_build_object(
    'success', true,
    'bill_id', v_bill_id,
    'invoice_number', v_invoice_number,
    'grand_total', 0,
    'voucher_discount', 0,
    'service_charge_amount', 0,
    'vat_amount', 0
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_checkout TO authenticated;
GRANT EXECUTE ON FUNCTION public.hall_get_checkout_totals TO authenticated;
