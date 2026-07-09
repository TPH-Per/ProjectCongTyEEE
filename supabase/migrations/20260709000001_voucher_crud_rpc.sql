CREATE OR REPLACE FUNCTION public.get_vouchers(
  p_branch_id uuid,
  p_only_active boolean DEFAULT false,
  p_only_expired boolean DEFAULT false,
  p_type text DEFAULT null,
  p_search text DEFAULT null
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- Basic auth check
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = '401';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', v.id,
      'branch_id', v.branch_id,
      'code', v.code,
      'type', v.type,
      'value', v.value,
      'min_order_value', v.min_order_value,
      'max_discount_amount', v.max_discount_amount,
      'valid_from', v.valid_from,
      'valid_until', v.valid_until,
      'max_uses', v.max_uses,
      'used_count', v.used_count,
      'is_active', v.is_active,
      'usage_limit_per_customer', v.usage_limit_per_customer,
      'customer_id', v.customer_id,
      'description_vi', v.description_vi,
      'description_en', v.description_en,
      'description_ja', v.description_ja,
      'created_by', v.created_by,
      'metadata', v.metadata,
      'created_at', v.created_at,
      'customer', CASE WHEN c.id IS NOT NULL THEN
                    jsonb_build_object('id', c.id, 'name', c.name, 'phone', c.phone)
                  ELSE NULL END
    )
  ), '[]'::jsonb)
  INTO v_result
  FROM public.vouchers v
  LEFT JOIN public.customers c ON v.customer_id = c.id
  WHERE v.branch_id = p_branch_id
    AND v.is_deleted = false
    AND (p_only_active = false OR (v.is_active = true AND v.valid_until >= now()))
    AND (p_only_expired = false OR (v.valid_until < now()))
    AND (p_type IS NULL OR v.type = p_type)
    AND (p_search IS NULL OR v.code ILIKE '%' || p_search || '%');

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_voucher(
  p_branch_id uuid,
  p_code text,
  p_type text,
  p_value numeric,
  p_min_order_value numeric,
  p_max_discount_amount numeric,
  p_valid_from timestamptz,
  p_valid_until timestamptz,
  p_max_uses int,
  p_usage_limit_per_customer int,
  p_customer_id uuid,
  p_description_vi text,
  p_description_en text,
  p_description_ja text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
  v_voucher_id uuid;
BEGIN
  -- basic auth
  IF NOT public.has_role(ARRAY['superadmin', 'admin', 'manager']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Must be superadmin, admin or manager' USING ERRCODE = '28000';
  END IF;

  -- check dup
  IF EXISTS (
    SELECT 1 FROM public.vouchers 
    WHERE branch_id = p_branch_id 
      AND code ILIKE p_code 
      AND is_deleted = false
  ) THEN
    RAISE EXCEPTION 'DUPLICATE_CODE' USING ERRCODE = '23505';
  END IF;

  INSERT INTO public.vouchers (
    branch_id, code, type, value, min_order_value, max_discount_amount,
    valid_from, valid_until, max_uses, usage_limit_per_customer,
    customer_id, description_vi, description_en, description_ja,
    created_by, used_count, is_active, is_deleted
  ) VALUES (
    p_branch_id, UPPER(TRIM(p_code)), p_type, p_value, p_min_order_value, p_max_discount_amount,
    p_valid_from, p_valid_until, p_max_uses, COALESCE(p_usage_limit_per_customer, 1),
    p_customer_id, p_description_vi, p_description_en, p_description_ja,
    auth.uid(), 0, true, false
  ) RETURNING id INTO v_voucher_id;

  SELECT row_to_json(v)::jsonb INTO v_result
  FROM public.vouchers v
  WHERE id = v_voucher_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_voucher(
  p_id uuid,
  p_patch jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.has_role(ARRAY['superadmin', 'admin', 'manager']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Must be superadmin, admin or manager' USING ERRCODE = '28000';
  END IF;

  UPDATE public.vouchers
  SET
    code = COALESCE((p_patch->>'code'), code),
    type = COALESCE((p_patch->>'type'), type),
    value = COALESCE((p_patch->>'value')::numeric, value),
    min_order_value = COALESCE((p_patch->>'min_order_value')::numeric, min_order_value),
    max_discount_amount = COALESCE((p_patch->>'max_discount_amount')::numeric, max_discount_amount),
    valid_from = CASE WHEN p_patch ? 'valid_from' THEN (p_patch->>'valid_from')::timestamptz ELSE valid_from END,
    valid_until = CASE WHEN p_patch ? 'valid_until' THEN (p_patch->>'valid_until')::timestamptz ELSE valid_until END,
    max_uses = CASE WHEN p_patch ? 'max_uses' THEN (p_patch->>'max_uses')::int ELSE max_uses END,
    usage_limit_per_customer = COALESCE((p_patch->>'usage_limit_per_customer')::int, usage_limit_per_customer),
    customer_id = CASE WHEN p_patch ? 'customer_id' THEN (p_patch->>'customer_id')::uuid ELSE customer_id END,
    description_vi = CASE WHEN p_patch ? 'description_vi' THEN (p_patch->>'description_vi') ELSE description_vi END,
    description_en = CASE WHEN p_patch ? 'description_en' THEN (p_patch->>'description_en') ELSE description_en END,
    description_ja = CASE WHEN p_patch ? 'description_ja' THEN (p_patch->>'description_ja') ELSE description_ja END,
    is_active = COALESCE((p_patch->>'is_active')::boolean, is_active),
    is_deleted = COALESCE((p_patch->>'is_deleted')::boolean, is_deleted),
    updated_at = now()
  WHERE id = p_id;

  SELECT row_to_json(v)::jsonb INTO v_result
  FROM public.vouchers v
  WHERE id = p_id;

  RETURN v_result;
END;
$$;
