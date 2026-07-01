-- Siết chặt quyền truy cập bảng tax_records 
-- Chỉ cho phép role 'accounting' và 'admin' được chỉnh sửa (Thêm/Sửa/Xóa).
-- Role 'manager' chỉ được xem (SELECT).
-- Các role khác (thu ngân, bếp, phục vụ) KHÔNG được truy cập.

-- 1. Xóa policy lỏng lẻo cũ
DROP POLICY IF EXISTS "tax_records_branch_access" ON public.tax_records;

-- 2. Policy cho quyền XEM (SELECT): admin, accounting, manager
CREATE POLICY "tax_records_select" ON public.tax_records
  FOR SELECT
  USING (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting', 'manager']::user_role[])
    )
  );

-- 3. Policy cho quyền GHI (INSERT, UPDATE, DELETE): CHỈ admin và accounting
CREATE POLICY "tax_records_modify" ON public.tax_records
  FOR ALL
  USING (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting']::user_role[])
    )
  )
  WITH CHECK (
    public.has_role(ARRAY['admin']::user_role[])
    OR (
      branch_id = public.current_branch_id() 
      AND public.has_role(ARRAY['accounting']::user_role[])
    )
  );

-- 4. Vá lại hàm RPC generate_tax_record để chặn các role không phận sự gọi hàm
CREATE OR REPLACE FUNCTION public.generate_tax_record(
  p_branch_id    uuid,
  p_period_type  text,
  p_period_start date,
  p_period_end   date
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_gross_revenue numeric(16,2);
  v_vat_amount    numeric(16,2);
  v_discount      numeric(16,2);
  v_expense       numeric(16,2);
  v_tax_id        uuid;
BEGIN
  -- CHẶN NGAY nếu không phải admin hoặc accounting
  IF NOT public.has_role(ARRAY['admin', 'accounting']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: only admin or accounting can generate tax records' USING ERRCODE = '28000';
  END IF;

  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  SELECT
    COALESCE(SUM(grand_total), 0),
    COALESCE(SUM(vat_8_amount + vat_10_amount), 0),
    COALESCE(SUM(discount_total), 0)
  INTO v_gross_revenue, v_vat_amount, v_discount
  FROM public.bills
  WHERE branch_id = p_branch_id
    AND status = 'PAID'
    AND created_at::date BETWEEN p_period_start AND p_period_end;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense
  FROM public.financial_transactions
  WHERE branch_id = p_branch_id
    AND transaction_type = 'EXPENSE'
    AND transaction_date::date BETWEEN p_period_start AND p_period_end;

  INSERT INTO public.tax_records (
    branch_id, period_type, period_start, period_end,
    gross_revenue, discount_total, net_revenue,
    vat_amount, expense_total, gross_profit, status
  ) VALUES (
    p_branch_id, p_period_type, p_period_start, p_period_end,
    v_gross_revenue, v_discount, v_gross_revenue - v_discount,
    v_vat_amount, v_expense, v_gross_revenue - v_discount - v_expense, 'DRAFT'
  )
  ON CONFLICT (branch_id, period_type, period_start)
  DO UPDATE SET
    gross_revenue  = EXCLUDED.gross_revenue,
    discount_total = EXCLUDED.discount_total,
    net_revenue    = EXCLUDED.net_revenue,
    vat_amount     = EXCLUDED.vat_amount,
    expense_total  = EXCLUDED.expense_total,
    gross_profit   = EXCLUDED.gross_profit,
    status         = 'DRAFT'
  RETURNING id INTO v_tax_id;

  RETURN v_tax_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.generate_tax_record(uuid,text,date,date) TO authenticated;
