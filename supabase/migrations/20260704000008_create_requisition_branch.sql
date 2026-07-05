-- 2. Create Requisition RPC (Updated to support branch_id selection)
DROP FUNCTION IF EXISTS public.create_requisition(JSONB, JSONB, TEXT);
DROP FUNCTION IF EXISTS public.create_requisition(JSONB, JSONB, TEXT, UUID);

CREATE OR REPLACE FUNCTION public.create_requisition(
  p_items JSONB,
  p_quotes JSONB,
  p_notes TEXT,
  p_branch_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req_id UUID;
  v_branch_id UUID;
  v_user_role TEXT;
BEGIN
  v_user_role := public.current_user_role()::text;
  
  -- Validate Role
  IF v_user_role NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff', 'kitchen') THEN
    RAISE EXCEPTION 'FORBIDDEN: You do not have permission to create requisitions';
  END IF;

  -- Determine target branch
  IF p_branch_id IS NOT NULL THEN
    -- Only managers and admins can create for other branches
    IF v_user_role IN ('admin', 'procurement', 'procurement_manager') THEN
      v_branch_id := p_branch_id;
    ELSE
      -- Staff can only create for their own branch
      IF p_branch_id != public.current_branch_id() THEN
        RAISE EXCEPTION 'FORBIDDEN: You can only create requisitions for your own branch';
      END IF;
      v_branch_id := p_branch_id;
    END IF;
  ELSE
    v_branch_id := public.current_branch_id();
  END IF;

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
