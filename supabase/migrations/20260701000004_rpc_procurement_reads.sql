-- =================================================================================
-- MIGRATION: Procurement Read RPCs
-- Tuân thủ Rule: Strict RPC Architecture (Database as an API)
-- Không cho phép Frontend query trực tiếp vào table.
-- =================================================================================

-- 1. Lấy danh sách Nhà cung cấp
CREATE OR REPLACE FUNCTION public.get_suppliers()
RETURNS TABLE (
  id uuid,
  name text,
  contact_info text,
  tax_code text,
  payment_terms text
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.name, s.contact_info, s.tax_code, s.payment_terms
  FROM public.suppliers s
  WHERE s.is_active = true
  ORDER BY s.name ASC;
END;
$$;

-- 2. Lấy từ điển nguyên liệu
CREATE OR REPLACE FUNCTION public.get_ingredients()
RETURNS TABLE (
  id uuid,
  name text,
  unit text,
  category text
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN QUERY
  SELECT i.id, i.name, i.unit, i.category
  FROM public.ingredients i
  WHERE i.is_active = true
  ORDER BY i.name ASC;
END;
$$;

-- 3. Xem tồn kho hiện tại (Tự động theo chi nhánh)
CREATE OR REPLACE FUNCTION public.get_current_stock(p_branch_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  ingredient_id uuid,
  ingredient_name text,
  unit text,
  quantity numeric,
  last_updated timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  -- Lấy branch_id từ JWT nếu không truyền vào
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  -- Bảo mật chéo: Chặn query chi nhánh khác nếu không phải admin
  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT 
    s.id,
    i.id as ingredient_id,
    i.name as ingredient_name,
    i.unit as unit,
    s.quantity,
    s.last_updated
  FROM public.inventory_stock s
  JOIN public.ingredients i ON i.id = s.ingredient_id
  WHERE s.branch_id = v_branch_id
  ORDER BY s.quantity DESC;
END;
$$;

-- 4. Lịch sử giao dịch nhập/xuất kho
CREATE OR REPLACE FUNCTION public.get_inventory_transactions(
  p_branch_id uuid DEFAULT NULL, 
  p_limit int DEFAULT 100
)
RETURNS TABLE (
  id uuid,
  transaction_type text,
  ingredient_name text,
  unit text,
  quantity numeric,
  unit_cost numeric,
  supplier_name text,
  notes text,
  created_at timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT 
    t.id,
    t.transaction_type,
    i.name as ingredient_name,
    i.unit as unit,
    t.quantity,
    t.unit_cost,
    s.name as supplier_name,
    t.notes,
    t.created_at
  FROM public.inventory_transactions t
  JOIN public.ingredients i ON i.id = t.ingredient_id
  LEFT JOIN public.suppliers s ON s.id = t.supplier_id
  WHERE t.branch_id = v_branch_id
  ORDER BY t.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Thu hồi quyền mặc định và cấp quyền truy cập chuẩn
REVOKE EXECUTE ON FUNCTION public.get_suppliers() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_suppliers() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_ingredients() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_ingredients() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_current_stock(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_current_stock(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_inventory_transactions(uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_inventory_transactions(uuid, int) TO authenticated;
