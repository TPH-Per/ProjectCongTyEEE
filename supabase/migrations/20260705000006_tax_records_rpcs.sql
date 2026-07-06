-- =================================================================================
-- MIGRATION: Tax Records RPCs
-- Tuân thủ Rule: Strict RPC Architecture (Database as an API)
-- Không cho phép Frontend query trực tiếp vào table.
--
-- Cung cấp 3 RPC:
--   1. get_tax_records(p_branch_id) — danh sách tax_records (admin/accounting/manager).
--   2. get_tax_report(p_start_date, p_end_date, p_branch_id) — báo cáo
--      bill + invoice hợp lệ (admin/accounting/manager).
--   3. finalize_tax_record(p_record_id) — đánh dấu tax_record = FINALIZED
--      (chỉ admin hoặc accounting).
--
-- SECURITY:
--   Tất cả dùng SECURITY DEFINER + SET search_path = public, auth.
--   Phân quyền ownership/branch thông qua has_role() + current_branch_id().
-- =================================================================================

-- 1. Lấy danh sách tax_records
CREATE OR REPLACE FUNCTION public.get_tax_records(p_branch_id uuid DEFAULT NULL)
RETURNS SETOF public.tax_records
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.has_role(ARRAY['admin', 'accounting', 'manager']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.tax_records
  WHERE (p_branch_id IS NULL OR branch_id = p_branch_id)
    AND (public.has_role(ARRAY['admin']::user_role[]) OR branch_id = public.current_branch_id())
  ORDER BY created_at DESC;
END;
$$;

-- 2. Báo cáo thuế (bills + invoices hợp lệ)
CREATE OR REPLACE FUNCTION public.get_tax_report(
  p_start_date date,
  p_end_date date,
  p_branch_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  bill_code text,
  grand_total numeric,
  created_at timestamptz,
  invoice_id uuid,
  invoice_symbol text,
  invoice_number text,
  buyer_company text,
  buyer_tax_code text,
  status text
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.has_role(ARRAY['admin', 'accounting', 'manager']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  RETURN QUERY
  SELECT
    b.id,
    b.bill_code,
    b.grand_total,
    b.created_at,
    i.id AS invoice_id,
    i.invoice_symbol,
    i.invoice_number,
    i.buyer_company,
    i.buyer_tax_code,
    i.status::text
  FROM public.bills b
  INNER JOIN public.invoices i ON i.bill_id = b.id
  WHERE i.status = 'VALID'
    AND (p_branch_id IS NULL OR b.branch_id = p_branch_id)
    AND (public.has_role(ARRAY['admin']::user_role[]) OR b.branch_id = public.current_branch_id())
    AND (b.created_at >= p_start_date)
    AND (b.created_at <= p_end_date)
  ORDER BY b.created_at DESC;
END;
$$;

-- 3. Finalize tax_record
CREATE OR REPLACE FUNCTION public.finalize_tax_record(p_record_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.has_role(ARRAY['admin', 'accounting']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: only admin or accounting can finalize tax records';
  END IF;

  UPDATE public.tax_records
  SET status = 'FINALIZED'
  WHERE id = p_record_id
    AND (public.has_role(ARRAY['admin']::user_role[]) OR branch_id = public.current_branch_id());
END;
$$;
