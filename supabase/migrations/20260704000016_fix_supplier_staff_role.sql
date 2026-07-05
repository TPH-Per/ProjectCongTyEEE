-- Allow procurement_staff to create and update suppliers
CREATE OR REPLACE FUNCTION public.save_supplier(
  p_id UUID,
  p_branch_id UUID,
  p_name TEXT,
  p_tax_code TEXT,
  p_category TEXT,
  p_contract_type TEXT,
  p_payment_due_day INT,
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
    RAISE EXCEPTION 'FORBIDDEN: Only admin, procurement manager or procurement staff can save suppliers';
  END IF;

  -- Validate tax_code uniqueness globally if tax_code is provided
  IF p_tax_code IS NOT NULL AND TRIM(p_tax_code) <> '' THEN
    SELECT COUNT(*) INTO v_count
    FROM public.suppliers
    WHERE tax_code = p_tax_code AND id != COALESCE(p_id, '00000000-0000-0000-0000-000000000000'::UUID);

    IF v_count > 0 THEN
      RAISE EXCEPTION 'Mã số thuế này đã tồn tại trong hệ thống.';
    END IF;
  END IF;

  -- Insert or Update
  IF p_id IS NULL THEN
    -- Insert
    INSERT INTO public.suppliers (id, branch_id, name, tax_code, category, contract_type, payment_due_day, is_active)
    VALUES (gen_random_uuid(), p_branch_id, p_name, p_tax_code, p_category, p_contract_type, p_payment_due_day, COALESCE(p_is_active, true));
  ELSE
    -- Update
    UPDATE public.suppliers
    SET branch_id = p_branch_id,
        name = p_name,
        tax_code = p_tax_code,
        category = p_category,
        contract_type = p_contract_type,
        payment_due_day = p_payment_due_day,
        is_active = COALESCE(p_is_active, true),
        updated_at = NOW()
    WHERE id = p_id;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;
