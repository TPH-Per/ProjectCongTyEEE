-- Create get_ingredient_stats RPC
CREATE OR REPLACE FUNCTION public.get_ingredient_stats(
  p_branch_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  code text,
  name text,
  unit text,
  is_active boolean,
  imported_this_week numeric,
  imported_this_month numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate Role
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to view ingredient stats';
  END IF;

  RETURN QUERY
  SELECT
    i.id,
    i.code,
    i.name,
    i.unit,
    i.is_active,
    COALESCE(SUM(it.quantity) FILTER (WHERE it.type = 'IN' AND date_trunc('week', it.created_at) = date_trunc('week', now())), 0)::numeric AS imported_this_week,
    COALESCE(SUM(it.quantity) FILTER (WHERE it.type = 'IN' AND date_trunc('month', it.created_at) = date_trunc('month', now())), 0)::numeric AS imported_this_month
  FROM public.ingredients i
  LEFT JOIN public.inventory_transactions it 
    ON i.id = it.ingredient_id 
    AND (it.branch_id = public.current_branch_id() OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
    AND (p_branch_id IS NULL OR it.branch_id = p_branch_id)
  WHERE i.is_active = true
  GROUP BY i.id, i.code, i.name, i.unit, i.is_active
  ORDER BY i.name ASC;
END;
$$;
