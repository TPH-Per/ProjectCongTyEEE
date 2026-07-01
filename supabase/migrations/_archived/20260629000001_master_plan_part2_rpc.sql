-- ==============================================================================
-- MASTER PLAN - PART 2: MISSING TABLES & RPC FUNCTIONS
-- ==============================================================================

-- ==============================================================================
-- 1. MISSING TABLES
-- ==============================================================================

-- 1.1 FINANCIAL TRANSACTIONS (Accounting)
-- Used for recording payments NOT related to customer orders (e.g. paying suppliers, internal expenses)
CREATE TABLE IF NOT EXISTS public.financial_transactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  transaction_type text NOT NULL CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
  category         text NOT NULL, -- e.g. 'SUPPLIER_PAYMENT', 'UTILITIES', 'SALARY'
  amount           numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_method   text NOT NULL, -- 'CASH', 'BANK_TRANSFER'
  reference_id     uuid,          -- e.g. purchase_order_id
  reference_type   text,          -- e.g. 'PURCHASE_ORDER'
  notes            text,
  recorded_by      uuid REFERENCES auth.users(id),
  transaction_date timestamptz NOT NULL DEFAULT now(),
  metadata         jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 2. RPC FUNCTIONS (Strict FOR UPDATE, using correct ENUMs)
-- ==============================================================================

-- 2.1 submit_tablet_order (Customer/Staff ordering via Tablet)
CREATE OR REPLACE FUNCTION public.submit_tablet_order(
  p_branch_id uuid,
  p_table_id uuid,
  p_session_id uuid,
  p_items jsonb -- Array of { menu_item_id, quantity, modifiers, note }
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_order_id uuid;
  v_order_status public.order_status;
  v_item record;
  v_menu_item record;
  v_line_total numeric(14,2);
  v_order_number text;
BEGIN
  -- 1. Find active order for this table/session or create new
  SELECT id, status INTO v_order_id, v_order_status 
  FROM public.orders 
  WHERE table_id = p_table_id AND status IN ('Pending', 'Preparing', 'Served') 
  FOR UPDATE;

  IF NOT FOUND THEN
    v_order_number := 'ORD-' || to_char(now(), 'YYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 4);
    INSERT INTO public.orders (branch_id, table_id, order_number, status)
    VALUES (p_branch_id, p_table_id, v_order_number, 'Pending')
    RETURNING id INTO v_order_id;
  END IF;

  -- 2. Insert items
  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(menu_item_id uuid, quantity numeric, modifiers jsonb, note text)
  LOOP
    -- Get menu item current price & cost
    SELECT name, base_price, cogs INTO v_menu_item 
    FROM public.menu_items 
    WHERE id = v_item.menu_item_id AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu item % not found or inactive', v_item.menu_item_id;
    END IF;

    v_line_total := v_item.quantity * v_menu_item.base_price;

    INSERT INTO public.order_items (
      branch_id, order_id, menu_item_id, name_snapshot, unit_price, unit_cost, quantity, line_total, status, modifiers, note
    ) VALUES (
      p_branch_id, v_order_id, v_item.menu_item_id, v_menu_item.name, v_menu_item.base_price, v_menu_item.cogs, v_item.quantity, v_line_total, 'Pending', v_item.modifiers, v_item.note
    );
  END LOOP;

  -- 3. Recalculate order totals
  UPDATE public.orders 
  SET 
    subtotal = (SELECT COALESCE(sum(line_total), 0) FROM public.order_items WHERE order_id = v_order_id AND status != 'Cancelled'),
    total = (SELECT COALESCE(sum(line_total), 0) FROM public.order_items WHERE order_id = v_order_id AND status != 'Cancelled')
  WHERE id = v_order_id;

  RETURN jsonb_build_object('success', true, 'order_id', v_order_id);
END;
$$;


-- 2.2 update_kitchen_ticket (Kitchen confirming preparation)
CREATE OR REPLACE FUNCTION public.update_kitchen_ticket(
  p_item_id uuid,
  p_new_status public.order_status, -- 'Preparing' or 'Served'
  p_staff_id uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
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


-- 2.3 process_checkout (Atomic payment)
CREATE OR REPLACE FUNCTION public.process_checkout(
  p_order_id uuid,
  p_branch_id uuid,
  p_cashier_id uuid,
  p_payment_method public.payment_method,
  p_voucher_code text DEFAULT NULL,
  p_points_to_use int DEFAULT 0
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_order record;
  v_invoice_id uuid;
  v_subtotal numeric(14,2);
  v_voucher_discount numeric(14,2) := 0;
  v_points_discount numeric(14,2) := 0;
  v_total_discount numeric(14,2);
  v_net_before_tax numeric(14,2);
  v_vat numeric(14,2);
  v_grand_total numeric(14,2);
  v_invoice_number text;
BEGIN
  -- 1. Lock order
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND branch_id = p_branch_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;
  
  IF v_order.status IN ('Paid', 'Cancelled') THEN
    RAISE EXCEPTION 'Order is already paid or cancelled';
  END IF;

  v_subtotal := v_order.subtotal;

  -- 2. Apply Voucher (Simplified)
  IF p_voucher_code IS NOT NULL THEN
    v_voucher_discount := 0; 
  END IF;

  -- 3. Apply Points (Simplified)
  IF p_points_to_use > 0 THEN
    v_points_discount := p_points_to_use * 1000; -- 1 pt = 1000 VND
  END IF;

  v_total_discount := v_voucher_discount + v_points_discount;
  v_net_before_tax := v_subtotal - v_total_discount;
  IF v_net_before_tax < 0 THEN v_net_before_tax := 0; END IF;

  v_vat := v_net_before_tax * v_order.vat_rate;
  v_grand_total := v_net_before_tax + v_vat;

  v_invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 4);

  -- 4. Insert invoice
  INSERT INTO public.invoices (
    branch_id, order_id, invoice_number, status, subtotal, vat, discount, total
  ) VALUES (
    p_branch_id, p_order_id, v_invoice_number, 'paid', v_subtotal, v_vat, v_total_discount, v_grand_total
  ) RETURNING id INTO v_invoice_id;

  -- 5. Insert payment
  INSERT INTO public.payments (
    branch_id, invoice_id, method, revenue_type, amount, received_amount, change_amount, received_by
  ) VALUES (
    p_branch_id, v_invoice_id, p_payment_method, 'other', v_grand_total, v_grand_total, 0, p_cashier_id
  );

  -- 6. Update order status
  UPDATE public.orders 
  SET status = 'Paid', vat = v_vat, discount = v_total_discount, total = v_grand_total 
  WHERE id = p_order_id;

  -- 7. Update table status if applicable
  IF v_order.table_id IS NOT NULL THEN
    UPDATE public.tables SET status = 'available' WHERE id = v_order.table_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'invoice_id', v_invoice_id,
    'invoice_number', v_invoice_number,
    'grand_total', v_grand_total
  );
END;
$$;


-- 2.4 create_purchase_order (Purchasing/Inventory)
CREATE OR REPLACE FUNCTION public.create_purchase_order(
  p_branch_id uuid,
  p_ordered_by uuid,
  p_requisition_id uuid,
  p_items jsonb -- Array of { ingredient_id, quantity, unit, unit_price }
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_po_id uuid;
  v_po_number text;
  v_item record;
  v_subtotal numeric(14,2) := 0;
BEGIN
  v_po_number := 'PO-' || to_char(now(), 'YYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.purchase_orders (
    branch_id, po_number, source_requisition_id, status, ordered_by
  ) VALUES (
    p_branch_id, v_po_number, p_requisition_id, 'DRAFT', p_ordered_by
  ) RETURNING id INTO v_po_id;

  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(ingredient_id uuid, quantity numeric, unit text, unit_price numeric)
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


-- 2.5 receive_purchase_order (Inventory update + Finance trigger)
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
  p_po_id uuid,
  p_received_by uuid,
  p_items jsonb -- Array of { item_id, received_quantity }
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_po record;
  v_item record;
BEGIN
  SELECT * INTO v_po FROM public.purchase_orders WHERE id = p_po_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'PO not found';
  END IF;

  IF v_po.status IN ('RECEIVED', 'CANCELLED') THEN
    RAISE EXCEPTION 'PO is already received or cancelled';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(item_id uuid, received_quantity numeric)
  LOOP
    UPDATE public.purchase_order_items 
    SET received_quantity = v_item.received_quantity
    WHERE id = v_item.item_id AND purchase_order_id = p_po_id;
  END LOOP;

  UPDATE public.purchase_orders 
  SET status = 'RECEIVED', actual_delivery_date = CURRENT_DATE, updated_at = now()
  WHERE id = p_po_id;

  RETURN jsonb_build_object('success', true, 'po_id', p_po_id);
END;
$$;


-- 2.6 record_expense_payment (Accounting)
CREATE OR REPLACE FUNCTION public.record_expense_payment(
  p_branch_id uuid,
  p_po_id uuid,
  p_amount numeric,
  p_method text,
  p_recorded_by uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_po record;
BEGIN
  SELECT * INTO v_po FROM public.purchase_orders WHERE id = p_po_id FOR UPDATE;
  
  INSERT INTO public.financial_transactions (
    branch_id, transaction_type, category, amount, payment_method, reference_id, reference_type, recorded_by
  ) VALUES (
    p_branch_id, 'EXPENSE', 'SUPPLIER_PAYMENT', p_amount, p_method, p_po_id, 'PURCHASE_ORDER', p_recorded_by
  );

  UPDATE public.purchase_orders 
  SET payment_status = CASE 
        WHEN p_amount >= total_amount THEN 'PAID'
        ELSE 'PARTIALLY_PAID' 
      END
  WHERE id = p_po_id;

  RETURN jsonb_build_object('success', true, 'po_id', p_po_id);
END;
$$;


-- 2.7 update_customer_profile (CRM)
CREATE OR REPLACE FUNCTION public.update_customer_profile(
  p_customer_id uuid,
  p_preferences jsonb
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.customers
  SET preferences = preferences || p_preferences, updated_at = now()
  WHERE id = p_customer_id;

  RETURN jsonb_build_object('success', true, 'customer_id', p_customer_id);
END;
$$;


-- 2.8 set_monthly_kpi (BOD/Marketing)
CREATE OR REPLACE FUNCTION public.set_monthly_kpi(
  p_branch_id uuid,
  p_metric_key text,
  p_target_value numeric,
  p_period_start date,
  p_period_end date,
  p_scope text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.kpi_targets (
    branch_id, metric_key, target_value, period_start, period_end, scope
  ) VALUES (
    p_branch_id, p_metric_key, p_target_value, p_period_start, p_period_end, p_scope
  )
  ON CONFLICT (branch_id, metric_key, period_start)
  DO UPDATE SET target_value = EXCLUDED.target_value, period_end = EXCLUDED.period_end, scope = EXCLUDED.scope;

  RETURN jsonb_build_object('success', true);
END;
$$;
