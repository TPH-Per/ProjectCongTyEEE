-- =================================================================================
-- MIGRATION: Procurement Updates (RPCs for PO & Dashboard)
-- Tuân thủ Rule: Strict RPC Architecture
-- =================================================================================

-- 1. get_purchase_orders
CREATE OR REPLACE FUNCTION public.get_purchase_orders(
  p_branch_id uuid DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_supplier_id uuid DEFAULT NULL,
  p_date_from timestamptz DEFAULT NULL,
  p_date_to timestamptz DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', po.id,
      'po_number', po.po_number,
      'status', po.status,
      'total_amount', po.total_amount,
      'expected_delivery_date', po.expected_delivery_date,
      'created_at', po.created_at,
      'supplier', (
        SELECT jsonb_build_object('name', s.name)
        FROM public.suppliers s WHERE s.id = po.supplier_id
      ),
      'items', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', poi.id,
            'ingredient_id', poi.ingredient_id,
            'ordered_quantity', poi.ordered_quantity,
            'received_quantity', poi.received_quantity,
            'unit_price', poi.unit_price,
            'unit', poi.unit,
            'ingredient', (
              SELECT jsonb_build_object('name_vi', i.name, 'sku', i.sku, 'unit', i.unit)
              FROM public.ingredients i WHERE i.id = poi.ingredient_id
            )
          )
        ), '[]'::jsonb)
        FROM public.purchase_order_items poi WHERE poi.purchase_order_id = po.id
      )
    ) ORDER BY po.created_at DESC
  ), '[]'::jsonb) INTO v_result
  FROM public.purchase_orders po
  WHERE po.branch_id = v_branch_id
    AND (p_status IS NULL OR po.status = p_status)
    AND (p_supplier_id IS NULL OR po.supplier_id = p_supplier_id)
    AND (p_date_from IS NULL OR po.created_at >= p_date_from)
    AND (p_date_to IS NULL OR po.created_at <= p_date_to);

  RETURN v_result;
END;
$$;

-- 2. cancel_purchase_order
CREATE OR REPLACE FUNCTION public.cancel_purchase_order(
  p_po_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_status text;
BEGIN
  SELECT branch_id, status INTO v_branch_id, v_status
  FROM public.purchase_orders
  WHERE id = p_po_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Purchase order not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  IF v_status IN ('RECEIVED', 'CANCELLED') THEN
    RAISE EXCEPTION 'Cannot cancel PO in status: %', v_status USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.purchase_orders
  SET status = 'CANCELLED',
      notes = COALESCE(p_reason, notes),
      updated_at = now()
  WHERE id = p_po_id;
END;
$$;

-- 3. receive_purchase_order
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
  p_po_id uuid,
  p_received_by uuid,
  p_items jsonb -- Array of { item_id, received_quantity }
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_status text;
  v_supplier_id uuid;
  v_item jsonb;
  v_poi_record record;
  v_all_received boolean := true;
BEGIN
  SELECT branch_id, status, supplier_id INTO v_branch_id, v_status, v_supplier_id
  FROM public.purchase_orders
  WHERE id = p_po_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Purchase order not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  IF v_status IN ('RECEIVED', 'CANCELLED') THEN
    RAISE EXCEPTION 'Cannot receive PO in status: %', v_status USING ERRCODE = 'P0001';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_poi_record
    FROM public.purchase_order_items
    WHERE id = (v_item->>'item_id')::uuid AND purchase_order_id = p_po_id;

    IF FOUND THEN
      -- Update received quantity
      UPDATE public.purchase_order_items
      SET received_quantity = received_quantity + (v_item->>'received_quantity')::numeric,
          is_fully_received = (received_quantity + (v_item->>'received_quantity')::numeric >= ordered_quantity)
      WHERE id = v_poi_record.id;
      
      IF (v_poi_record.received_quantity + (v_item->>'received_quantity')::numeric) < v_poi_record.ordered_quantity THEN
        v_all_received := false;
      END IF;

      -- Update inventory stock
      INSERT INTO public.inventory_stock (branch_id, ingredient_id, quantity)
      VALUES (v_branch_id, v_poi_record.ingredient_id, (v_item->>'received_quantity')::numeric)
      ON CONFLICT (branch_id, ingredient_id)
      DO UPDATE SET quantity = inventory_stock.quantity + EXCLUDED.quantity,
                    last_updated = now();

      -- Log transaction
      INSERT INTO public.inventory_transactions (
        branch_id, ingredient_id, transaction_type, quantity,
        unit_cost, supplier_id, reference_id, reference_type, created_by
      )
      VALUES (
        v_branch_id, v_poi_record.ingredient_id, 'PURCHASE', (v_item->>'received_quantity')::numeric,
        v_poi_record.unit_price, v_supplier_id, p_po_id, 'PURCHASE_ORDER', p_received_by
      );
    END IF;
  END LOOP;

  -- Update PO status
  UPDATE public.purchase_orders
  SET status = CASE WHEN v_all_received THEN 'RECEIVED' ELSE 'PARTIAL' END,
      actual_delivery_date = now()::date,
      updated_at = now()
  WHERE id = p_po_id;
END;
$$;

-- 4. get_purchasing_dashboard_metrics
CREATE OR REPLACE FUNCTION public.get_purchasing_dashboard_metrics(
  p_branch_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_pending_orders int;
  v_approved_orders int;
  v_rejected_orders int;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  SELECT count(*) INTO v_pending_orders FROM public.purchase_orders WHERE branch_id = v_branch_id AND status IN ('DRAFT', 'SUBMITTED');
  SELECT count(*) INTO v_approved_orders FROM public.purchase_orders WHERE branch_id = v_branch_id AND status IN ('CONFIRMED_BY_SUPPLIER', 'PARTIAL', 'RECEIVED');
  SELECT count(*) INTO v_rejected_orders FROM public.purchase_orders WHERE branch_id = v_branch_id AND status = 'CANCELLED';

  RETURN jsonb_build_object(
    'pending_orders', v_pending_orders,
    'approved_orders', v_approved_orders,
    'rejected_orders', v_rejected_orders
  );
END;
$$;

-- GRANTS
REVOKE EXECUTE ON FUNCTION public.get_purchase_orders(uuid,text,uuid,timestamptz,timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_purchase_orders(uuid,text,uuid,timestamptz,timestamptz) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.cancel_purchase_order(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_purchase_order(uuid,text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.receive_purchase_order(uuid,uuid,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.receive_purchase_order(uuid,uuid,jsonb) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_purchasing_dashboard_metrics(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_purchasing_dashboard_metrics(uuid) TO authenticated;
