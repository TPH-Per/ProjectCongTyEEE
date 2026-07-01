-- Tạo RPC để ghi nhận nhập/xuất kho và tự động cập nhật tồn kho (Atomic Transaction)
-- RPC này giải quyết dataflow nhập hàng / kiểm kê của phân hệ Procurement

CREATE OR REPLACE FUNCTION public.record_inventory_transaction(
  p_ingredient_id uuid,
  p_transaction_type text, -- 'IN', 'OUT', 'ADJUST', 'PURCHASE'
  p_quantity numeric,
  p_unit_cost numeric DEFAULT 0,
  p_supplier_id uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_transaction_id uuid;
  v_current_stock numeric;
  v_new_stock numeric;
BEGIN
  -- Lấy chi nhánh hiện tại từ JWT
  v_branch_id := public.current_branch_id();

  -- Bắt buộc phải thuộc một chi nhánh mới được nhập/xuất kho
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: current_branch_id is required' USING ERRCODE = '28000';
  END IF;

  -- Khóa row tồn kho hiện tại để chống race-condition (nếu có người khác đang nhập cùng lúc)
  SELECT quantity INTO v_current_stock
  FROM public.inventory_stock
  WHERE branch_id = v_branch_id AND ingredient_id = p_ingredient_id
  FOR UPDATE;

  IF NOT FOUND THEN
    v_current_stock := 0;
  END IF;

  -- Tính toán số lượng tồn kho mới
  IF p_transaction_type IN ('IN', 'PURCHASE') THEN
    v_new_stock := v_current_stock + p_quantity;
  ELSIF p_transaction_type = 'OUT' THEN
    v_new_stock := v_current_stock - p_quantity;
    -- Kiểm tra âm kho
    IF v_new_stock < 0 THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK: Không đủ tồn kho để xuất' USING ERRCODE = 'P0001';
    END IF;
  ELSIF p_transaction_type = 'ADJUST' THEN
    -- Ở chế độ kiểm kê, p_quantity chính là số lượng thực tế kiểm đếm được
    v_new_stock := p_quantity;
  ELSE
    RAISE EXCEPTION 'INVALID_TYPE: Loại giao dịch kho không hợp lệ' USING ERRCODE = 'P0001';
  END IF;

  -- 1. Ghi log vào inventory_transactions
  INSERT INTO public.inventory_transactions (
    branch_id, ingredient_id, transaction_type, 
    quantity, unit_cost, supplier_id, notes, created_by
  ) VALUES (
    v_branch_id, p_ingredient_id, p_transaction_type, 
    p_quantity, p_unit_cost, p_supplier_id, p_notes, auth.uid()
  ) RETURNING id INTO v_transaction_id;

  -- 2. Upsert tồn kho mới vào inventory_stock
  INSERT INTO public.inventory_stock (
    branch_id, ingredient_id, quantity, last_updated
  ) VALUES (
    v_branch_id, p_ingredient_id, v_new_stock, now()
  )
  ON CONFLICT (branch_id, ingredient_id)
  DO UPDATE SET
    quantity = EXCLUDED.quantity,
    last_updated = EXCLUDED.last_updated;

  RETURN v_transaction_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.record_inventory_transaction(uuid, text, numeric, numeric, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_inventory_transaction(uuid, text, numeric, numeric, uuid, text) TO authenticated;
