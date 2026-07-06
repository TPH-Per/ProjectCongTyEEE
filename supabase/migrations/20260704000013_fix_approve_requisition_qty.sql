-- Fix goods_receipt_items column name from quantity_received to quantity
CREATE OR REPLACE FUNCTION public.approve_requisition_and_receipt(
  p_requisition_id UUID,
  p_selected_quote_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req public.requisitions%ROWTYPE;
  v_quote JSONB;
  v_supplier_id UUID;
  v_receipt_id UUID;
  v_item JSONB;
BEGIN
  -- Validate Role using text match to accommodate JWT role updates
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only admin or procurement manager can approve requisitions';
  END IF;

  -- Get Requisition
  SELECT * INTO v_req
  FROM public.requisitions
  WHERE id = p_requisition_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Requisition not found';
  END IF;

  IF v_req.status = 'APPROVED' THEN
    RAISE EXCEPTION 'Requisition is already approved';
  END IF;

  -- Extract the selected quote
  SELECT elem INTO v_quote
  FROM jsonb_array_elements(v_req.quotes_jsonb) AS elem
  WHERE elem->>'id' = p_selected_quote_id;

  IF v_quote IS NULL THEN
    RAISE EXCEPTION 'Selected quote not found in requisition quotes';
  END IF;

  -- Process Supplier (Create if not exists by name)
  SELECT id INTO v_supplier_id
  FROM public.suppliers
  WHERE name = v_quote->>'supplier_name'
  LIMIT 1;

  IF v_supplier_id IS NULL THEN
    v_supplier_id := gen_random_uuid();
    INSERT INTO public.suppliers (id, branch_id, name, contract_type, is_active)
    VALUES (
      v_supplier_id,
      v_req.branch_id,
      v_quote->>'supplier_name',
      'NON_CONTRACTED',
      true
    );
  END IF;

  -- Generate Receipt
  v_receipt_id := gen_random_uuid();
  INSERT INTO public.goods_receipts (
    id, branch_id, receipt_code, supplier_id, status, notes, total_amount, payment_status, created_by
  ) VALUES (
    v_receipt_id,
    v_req.branch_id,
    'GR-' || to_char(now(), 'YYYYMMDDHH24MISS'),
    v_supplier_id,
    'COMPLETED',
    'Auto-generated from Requisition ' || v_req.req_number || ' - Quote URL: ' || COALESCE(v_quote->>'product_url', ''),
    0, -- we can compute this or set it to 0 and let the user update
    'PAID',
    auth.uid()
  );

  -- Insert items (assuming items_jsonb has ingredient_id, quantity, unit_price, etc.)
  IF jsonb_typeof(v_req.items_jsonb) = 'array' AND jsonb_array_length(v_req.items_jsonb) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_req.items_jsonb)
    LOOP
      INSERT INTO public.goods_receipt_items (
        receipt_id, ingredient_id, quantity, unit_price
      ) VALUES (
        v_receipt_id,
        (v_item->>'ingredient_id')::UUID,
        COALESCE((v_item->>'quantity')::NUMERIC, 0),
        COALESCE((v_item->>'unit_price')::NUMERIC, 0)
      );
    END LOOP;
  END IF;

  -- Calculate true total from items (using the stored generated column total_price or recalculating)
  UPDATE public.goods_receipts
  SET total_amount = (
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    FROM public.goods_receipt_items
    WHERE receipt_id = v_receipt_id
  )
  WHERE id = v_receipt_id;

  -- Update Requisition Status
  UPDATE public.requisitions
  SET status = 'APPROVED',
      approved_by = auth.uid(),
      selected_quote_id = p_selected_quote_id,
      updated_at = NOW()
  WHERE id = p_requisition_id;

  RETURN jsonb_build_object(
    'success', true,
    'supplier_id', v_supplier_id,
    'receipt_id', v_receipt_id
  );
END;
$$;
