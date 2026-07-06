-- 3. Get Requisitions RPC (Updated to include branch_name)
DROP FUNCTION IF EXISTS public.get_requisitions(TEXT);

CREATE OR REPLACE FUNCTION public.get_requisitions(
  p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  branch_id UUID,
  branch_name TEXT,
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
    b.name AS branch_name,
    r.req_number,
    r.status,
    r.notes,
    r.items_jsonb,
    r.quotes_jsonb,
    r.selected_quote_id,
    r.created_at
  FROM public.requisitions r
  LEFT JOIN public.branches b ON r.branch_id = b.id
  WHERE (r.branch_id = public.current_branch_id() OR public.current_user_role()::text IN ('admin', 'procurement', 'procurement_manager'))
    AND (p_status IS NULL OR r.status = p_status)
  ORDER BY r.created_at DESC;
END;
$$;
