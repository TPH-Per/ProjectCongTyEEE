-- Create get_goods_receipts RPC
CREATE OR REPLACE FUNCTION public.get_goods_receipts(
  p_branch_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  branch_id UUID,
  branch_name TEXT,
  receipt_code TEXT,
  supplier_id UUID,
  supplier_name TEXT,
  total_amount NUMERIC,
  status TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  items_jsonb JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate Role
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to view goods receipts';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.branch_id,
    b.name AS branch_name,
    r.receipt_code,
    r.supplier_id,
    s.name AS supplier_name,
    r.total_amount,
    r.status,
    r.notes,
    r.created_at,
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'ingredient_id', gri.ingredient_id,
            'ingredient_name', i.name,
            'unit', i.unit,
            'quantity', gri.quantity,
            'unit_price', gri.unit_price,
            'total_price', gri.total_price
          )
        )
        FROM public.goods_receipt_items gri
        JOIN public.ingredients i ON i.id = gri.ingredient_id
        WHERE gri.receipt_id = r.id
      ),
      '[]'::jsonb
    ) AS items_jsonb
  FROM public.goods_receipts r
  LEFT JOIN public.branches b ON r.branch_id = b.id
  LEFT JOIN public.suppliers s ON r.supplier_id = s.id
  WHERE (r.branch_id = public.current_branch_id() OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
    AND (p_branch_id IS NULL OR r.branch_id = p_branch_id)
  ORDER BY r.created_at DESC;
END;
$$;
