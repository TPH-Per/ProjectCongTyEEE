-- Update submit_goods_receipt to auto-create ingredients by name
CREATE OR REPLACE FUNCTION public.submit_goods_receipt(
  p_branch_id       uuid,
  p_receipt_code    text,
  p_supplier_id     uuid,
  p_purchase_order_id uuid DEFAULT NULL,
  p_scan_image_url  text  DEFAULT NULL,
  p_items           jsonb  DEFAULT '[]'
  -- Array of { ingredient_id (optional), ingredient_name (optional), unit (optional), quantity, unit_price }
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
  v_ing_id      uuid;
  v_ing_name    text;
  v_unit        text;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin', 'procurement', 'procurement_manager']::user_role[]) THEN
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
    v_qty   := COALESCE((v_item->>'quantity')::numeric, 0);
    v_price := COALESCE((v_item->>'unit_price')::numeric, 0);
    v_ing_id := NULLIF(v_item->>'ingredient_id', '')::uuid;
    v_ing_name := NULLIF(TRIM(v_item->>'ingredient_name'), '');
    v_unit := COALESCE(NULLIF(TRIM(v_item->>'unit'), ''), 'unit');

    -- If no ingredient_id is provided, try to find by name
    IF v_ing_id IS NULL AND v_ing_name IS NOT NULL THEN
      SELECT id INTO v_ing_id
      FROM public.ingredients
      WHERE branch_id = p_branch_id AND lower(name) = lower(v_ing_name)
      LIMIT 1;

      -- If still not found, create new ingredient
      IF v_ing_id IS NULL THEN
        v_ing_id := gen_random_uuid();
        INSERT INTO public.ingredients (id, branch_id, code, name, unit, is_active)
        VALUES (v_ing_id, p_branch_id, 'ING-' || substr(md5(random()::text), 1, 6), v_ing_name, v_unit, true);
      END IF;
    END IF;

    -- If we still don't have an ingredient_id, something is wrong
    IF v_ing_id IS NULL THEN
      RAISE EXCEPTION 'Item must have an ingredient_id or ingredient_name';
    END IF;

    INSERT INTO public.goods_receipt_items (receipt_id, ingredient_id, quantity, unit_price)
    VALUES (v_receipt_id, v_ing_id, v_qty, v_price);

    -- Atomic increment
    INSERT INTO public.inventory_stock (branch_id, ingredient_id, quantity)
    VALUES (p_branch_id, v_ing_id, v_qty)
    ON CONFLICT (branch_id, ingredient_id)
    DO UPDATE SET quantity   = inventory_stock.quantity + EXCLUDED.quantity,
                  updated_at = now();

    -- Audit ledger
    INSERT INTO public.inventory_transactions (
      branch_id, ingredient_id, type, quantity,
      balance_after, reference_id, reference_type, created_by
    )
    SELECT p_branch_id, v_ing_id, 'IN', v_qty,
           quantity, v_receipt_id, 'GOODS_RECEIPT', public.current_user_id()
    FROM public.inventory_stock
    WHERE branch_id = p_branch_id AND ingredient_id = v_ing_id;

    v_total := v_total + (v_qty * v_price);
  END LOOP;

  UPDATE public.goods_receipts SET total_amount = v_total WHERE id = v_receipt_id;

  RETURN v_receipt_id;
END;
$$;
