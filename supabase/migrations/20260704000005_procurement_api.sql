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
