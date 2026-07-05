-- =================================================================================
-- MIGRATION: Procurement Analytics RPC
-- =================================================================================

CREATE OR REPLACE FUNCTION public.get_procurement_analytics(
  p_branch_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_total_this_month numeric;
  v_total_last_month numeric;
  v_top_ingredients jsonb;
  v_supplier_spend jsonb;
  v_price_variations jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  -- 1. Total spent this month
  SELECT COALESCE(SUM(total_amount), 0) INTO v_total_this_month
  FROM public.goods_receipts
  WHERE branch_id = v_branch_id
    AND created_at >= date_trunc('month', now());

  -- 2. Total spent last month
  SELECT COALESCE(SUM(total_amount), 0) INTO v_total_last_month
  FROM public.goods_receipts
  WHERE branch_id = v_branch_id
    AND created_at >= date_trunc('month', now() - interval '1 month')
    AND created_at < date_trunc('month', now());

  -- 3. Top 5 ingredients by value (This Month)
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO v_top_ingredients
  FROM (
    SELECT i.name as ingredient_name, SUM(gri.quantity) as total_quantity, SUM(gri.total_price) as total_value
    FROM public.goods_receipt_items gri
    JOIN public.goods_receipts gr ON gr.id = gri.receipt_id
    JOIN public.ingredients i ON i.id = gri.ingredient_id
    WHERE gr.branch_id = v_branch_id AND gr.created_at >= date_trunc('month', now())
    GROUP BY i.id, i.name
    ORDER BY total_value DESC
    LIMIT 5
  ) t;

  -- 4. Supplier spend (This Month)
  SELECT COALESCE(jsonb_agg(row_to_json(s_spend)), '[]'::jsonb) INTO v_supplier_spend
  FROM (
    SELECT COALESCE(s.name, 'Unknown') as supplier_name, SUM(gr.total_amount) as total_spent
    FROM public.goods_receipts gr
    LEFT JOIN public.suppliers s ON s.id = gr.supplier_id
    WHERE gr.branch_id = v_branch_id AND gr.created_at >= date_trunc('month', now())
    GROUP BY s.id, s.name
    ORDER BY total_spent DESC
    LIMIT 5
  ) s_spend;

  -- 5. Price variations (All time min/max vs latest for items bought this month)
  SELECT COALESCE(jsonb_agg(row_to_json(p_var)), '[]'::jsonb) INTO v_price_variations
  FROM (
    SELECT 
      i.name as ingredient_name,
      MIN(gri.unit_price) as min_price,
      MAX(gri.unit_price) as max_price,
      (
        SELECT unit_price 
        FROM public.goods_receipt_items gri2 
        JOIN public.goods_receipts gr2 ON gr2.id = gri2.receipt_id
        WHERE gri2.ingredient_id = i.id AND gr2.branch_id = v_branch_id
        ORDER BY gr2.created_at DESC LIMIT 1
      ) as current_price
    FROM public.goods_receipt_items gri
    JOIN public.goods_receipts gr ON gr.id = gri.receipt_id
    JOIN public.ingredients i ON i.id = gri.ingredient_id
    WHERE gr.branch_id = v_branch_id
    GROUP BY i.id, i.name
    ORDER BY max_price DESC
    LIMIT 10
  ) p_var;

  RETURN jsonb_build_object(
    'total_spent_this_month', v_total_this_month,
    'total_spent_last_month', v_total_last_month,
    'top_ingredients', v_top_ingredients,
    'supplier_spend', v_supplier_spend,
    'price_variations', v_price_variations
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_procurement_analytics(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_procurement_analytics(uuid) TO authenticated;
