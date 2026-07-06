-- 1. Drop existing get_suppliers to recreate it with new columns
DROP FUNCTION IF EXISTS public.get_suppliers();

CREATE OR REPLACE FUNCTION public.get_suppliers()
RETURNS TABLE (
  id UUID,
  name TEXT,
  contact_info TEXT,
  tax_code TEXT,
  payment_terms TEXT,
  contract_type TEXT,
  payment_due_day INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.name,
    COALESCE(s.contact_name, '') || ' / ' ||
      COALESCE(s.contact_phone, '') || ' / ' ||
      COALESCE(s.contact_email, '') AS contact_info,
    s.tax_code,
    s.payment_terms,
    s.contract_type,
    s.payment_due_day
  FROM public.suppliers s
  WHERE s.is_active = true
  ORDER BY s.name ASC;
END;
$$;

-- 2. Create Requisition RPC
CREATE OR REPLACE FUNCTION public.create_requisition(
  p_items JSONB,
  p_quotes JSONB,
  p_notes TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req_id UUID;
  v_branch_id UUID;
BEGIN
  -- Validate Role
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff', 'kitchen') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to create requisitions';
  END IF;

  v_branch_id := public.current_branch_id();
  v_req_id := gen_random_uuid();

  INSERT INTO public.requisitions (
    id, branch_id, req_number, status, requested_by, notes, items_jsonb, quotes_jsonb
  ) VALUES (
    v_req_id,
    v_branch_id,
    'REQ-' || to_char(now(), 'YYYYMMDDHH24MISS'),
    'PENDING',
    auth.uid(),
    p_notes,
    p_items,
    p_quotes
  );

  RETURN v_req_id;
END;
$$;

-- 3. Get Requisitions RPC
CREATE OR REPLACE FUNCTION public.get_requisitions(
  p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  branch_id UUID,
  req_number TEXT,
  status TEXT,
  notes TEXT,
  items_jsonb JSONB,
  quotes_jsonb JSONB,
  selected_quote_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate Role
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff', 'kitchen') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to view requisitions';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.branch_id,
    r.req_number,
    r.status,
    r.notes,
    r.items_jsonb,
    r.quotes_jsonb,
    r.selected_quote_id,
    r.created_at
  FROM public.requisitions r
  WHERE (r.branch_id = public.current_branch_id() OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
    AND (p_status IS NULL OR r.status = p_status)
  ORDER BY r.created_at DESC;
END;
$$;
-- =================================================================================
-- MIGRATION: 20260704000003_procurement_manager_rls.sql
-- DESCRIPTION: Grant procurement_manager cross-branch access for procurement tables
-- =================================================================================

-- 1. Suppliers
DROP POLICY IF EXISTS "suppliers_branch_access" ON public.suppliers;
CREATE POLICY "suppliers_branch_access" ON public.suppliers
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 2. Ingredients
DROP POLICY IF EXISTS "ingredients_branch_access" ON public.ingredients;
CREATE POLICY "ingredients_branch_access" ON public.ingredients
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 3. Ingredient Categories
DROP POLICY IF EXISTS "ingredient_categories_branch_access" ON public.ingredient_categories;
CREATE POLICY "ingredient_categories_branch_access" ON public.ingredient_categories
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR branch_id IS NULL
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 4. Inventory Stock
DROP POLICY IF EXISTS "inventory_stock_branch_access" ON public.inventory_stock;
CREATE POLICY "inventory_stock_branch_access" ON public.inventory_stock
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 5. Inventory Transactions
DROP POLICY IF EXISTS "inventory_transactions_branch_read" ON public.inventory_transactions;
CREATE POLICY "inventory_transactions_branch_read" ON public.inventory_transactions
  FOR SELECT
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

DROP POLICY IF EXISTS "inventory_transactions_branch_insert" ON public.inventory_transactions;
CREATE POLICY "inventory_transactions_branch_insert" ON public.inventory_transactions
  FOR INSERT
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 6. Goods Receipts
DROP POLICY IF EXISTS "goods_receipts_branch_access" ON public.goods_receipts;
CREATE POLICY "goods_receipts_branch_access" ON public.goods_receipts
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 7. Goods Receipt Items
DROP POLICY IF EXISTS "goods_receipt_items_branch_access" ON public.goods_receipt_items;
CREATE POLICY "goods_receipt_items_branch_access" ON public.goods_receipt_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.goods_receipts gr
    WHERE gr.id = receipt_id
      AND (gr.branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  ));

-- 8. Purchase Orders (Legacy but update just in case)
DROP POLICY IF EXISTS "purchase_orders_branch_access" ON public.purchase_orders;
CREATE POLICY "purchase_orders_branch_access" ON public.purchase_orders
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 9. Purchase Order Items
DROP POLICY IF EXISTS "purchase_order_items_branch_access" ON public.purchase_order_items;
CREATE POLICY "purchase_order_items_branch_access" ON public.purchase_order_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.purchase_orders po
    WHERE po.id = purchase_order_id
      AND (po.branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  ));

-- 10. Requisitions
DROP POLICY IF EXISTS "requisitions_branch_access" ON public.requisitions;
CREATE POLICY "requisitions_branch_access" ON public.requisitions
  FOR ALL
  USING (branch_id = public.current_branch_id()
      OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  WITH CHECK (branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'));

-- 11. Requisition Items
DROP POLICY IF EXISTS "requisition_items_branch_access" ON public.requisition_items;
CREATE POLICY "requisition_items_branch_access" ON public.requisition_items
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.requisitions r
    WHERE r.id = requisition_id
      AND (r.branch_id = public.current_branch_id()
           OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
  ));

-- 12. Fix RPC Security to enforce Role Check when querying cross-branch
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

  -- ENFORCE SECURITY: If asking for another branch, must be admin or procurement_manager
  IF v_branch_id != public.current_branch_id() 
     AND NOT public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to view analytics for other branches' USING ERRCODE = '28000';
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
