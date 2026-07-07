-- 1. Add category column
ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS category TEXT;

-- 2. Create RPC for saving supplier with tax_code check
CREATE OR REPLACE FUNCTION public.save_supplier(
  p_id UUID,
  p_branch_id UUID,
  p_name TEXT,
  p_tax_code TEXT,
  p_category TEXT,
  p_contract_type TEXT,
  p_payment_due_day INTEGER,
  p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing_name TEXT;
  v_new_id UUID;
BEGIN
  -- Check permission
  IF public.current_user_role()::text NOT IN ('admin', 'procurement', 'procurement_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only admin or procurement manager can manage suppliers';
  END IF;

  -- Check tax_code uniqueness
  IF p_tax_code IS NOT NULL AND p_tax_code != '' THEN
    SELECT name INTO v_existing_name
    FROM public.suppliers
    WHERE tax_code = p_tax_code
      AND (p_id IS NULL OR id != p_id)
    LIMIT 1;

    IF FOUND THEN
      RAISE EXCEPTION 'Mã số thuế % đã được sử dụng cho nhà cung cấp: %', p_tax_code, v_existing_name;
    END IF;
  END IF;

  IF p_id IS NOT NULL AND p_id != '00000000-0000-0000-0000-000000000000'::uuid THEN
    -- Update
    UPDATE public.suppliers
    SET
      name = p_name,
      tax_code = p_tax_code,
      category = p_category,
      contract_type = p_contract_type,
      payment_due_day = p_payment_due_day,
      is_active = p_is_active,
      updated_at = NOW()
    WHERE id = p_id;
    v_new_id := p_id;
  ELSE
    -- Insert
    v_new_id := gen_random_uuid();
    INSERT INTO public.suppliers (
      id, branch_id, name, tax_code, category, contract_type, payment_due_day, is_active
    ) VALUES (
      v_new_id, p_branch_id, p_name, p_tax_code, p_category, p_contract_type, p_payment_due_day, p_is_active
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'id', v_new_id);
END;
$$;
