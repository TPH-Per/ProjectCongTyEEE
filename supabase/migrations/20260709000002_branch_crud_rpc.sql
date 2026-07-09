CREATE OR REPLACE FUNCTION public.get_branches() RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.has_role(ARRAY['superadmin', 'admin', 'manager']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Must be superadmin, admin or manager' USING ERRCODE = '28000';
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(b)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT br.*, 
           jsonb_build_object('id', u.id, 'full_name', u.full_name) as manager
    FROM public.branches br
    LEFT JOIN public.users u ON br.manager_id = u.id
    ORDER BY br.created_at DESC
  ) b;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_branch(
  p_name text,
  p_address text,
  p_phone text,
  p_capacity int,
  p_manager_id uuid DEFAULT NULL,
  p_operating_hours jsonb DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
  v_branch_id uuid;
BEGIN
  IF NOT public.has_role(ARRAY['superadmin', 'admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Must be superadmin or admin' USING ERRCODE = '28000';
  END IF;

  INSERT INTO public.branches (
    name, address, phone, capacity, manager_id, operating_hours, is_active
  ) VALUES (
    p_name, p_address, p_phone, p_capacity, p_manager_id, p_operating_hours, true
  ) RETURNING id INTO v_branch_id;

  SELECT row_to_json(b)::jsonb INTO v_result
  FROM public.branches b
  WHERE id = v_branch_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_branch(
  p_id uuid,
  p_patch jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.has_role(ARRAY['superadmin', 'admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Must be superadmin or admin' USING ERRCODE = '28000';
  END IF;

  UPDATE public.branches
  SET
    name = COALESCE((p_patch->>'name'), name),
    address = COALESCE((p_patch->>'address'), address),
    phone = COALESCE((p_patch->>'phone'), phone),
    capacity = COALESCE((p_patch->>'capacity')::int, capacity),
    manager_id = CASE WHEN p_patch ? 'manager_id' THEN (p_patch->>'manager_id')::uuid ELSE manager_id END,
    operating_hours = CASE WHEN p_patch ? 'operating_hours' THEN (p_patch->'operating_hours') ELSE operating_hours END,
    is_active = COALESCE((p_patch->>'is_active')::boolean, is_active),
    updated_at = now()
  WHERE id = p_id;

  SELECT row_to_json(b)::jsonb INTO v_result
  FROM public.branches b
  WHERE id = p_id;

  RETURN v_result;
END;
$$;
