-- Save ingredient RPC
CREATE OR REPLACE FUNCTION public.save_ingredient(
  p_id UUID,
  p_branch_id UUID,
  p_code TEXT,
  p_name TEXT,
  p_unit TEXT,
  p_cost_per_unit NUMERIC,
  p_min_stock_level NUMERIC,
  p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Valid roles: admin, procurement_manager, procurement_staff
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager', 'procurement_staff') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only admin or procurement can save ingredients';
  END IF;

  -- Validate code uniqueness globally if code is provided
  IF p_code IS NOT NULL AND TRIM(p_code) <> '' THEN
    SELECT COUNT(*) INTO v_count
    FROM public.ingredients
    WHERE code = p_code AND branch_id = p_branch_id AND id != COALESCE(p_id, '00000000-0000-0000-0000-000000000000'::UUID);

    IF v_count > 0 THEN
      RAISE EXCEPTION 'Mã sản phẩm này đã tồn tại trong chi nhánh.';
    END IF;
  END IF;

  -- Insert or Update
  IF p_id IS NULL THEN
    -- Insert
    INSERT INTO public.ingredients (id, branch_id, code, name, unit, cost_per_unit, min_stock_level, is_active)
    VALUES (gen_random_uuid(), p_branch_id, p_code, p_name, p_unit, p_cost_per_unit, p_min_stock_level, COALESCE(p_is_active, true));
  ELSE
    -- Update
    UPDATE public.ingredients
    SET branch_id = p_branch_id,
        code = p_code,
        name = p_name,
        unit = p_unit,
        cost_per_unit = p_cost_per_unit,
        min_stock_level = p_min_stock_level,
        is_active = COALESCE(p_is_active, true),
        updated_at = NOW()
    WHERE id = p_id;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;
