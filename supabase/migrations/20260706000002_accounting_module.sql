-- ============================================================
-- ACCOUNTING MODULE - PART 2: Tables, RLS, RPCs
-- Run AFTER 20260706000001_add_accounting_manager_role.sql
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- HELPER: is_accounting_manager (text-based check, no enum cast needed)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_accounting_manager()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT COALESCE(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')
    = ANY(ARRAY['admin', 'accounting_manager']),
    false
  )
$$;

CREATE OR REPLACE FUNCTION public.is_accountant()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT COALESCE(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'role')
    = ANY(ARRAY['admin', 'manager', 'accounting', 'accounting_manager']),
    false
  )
$$;

-- ────────────────────────────────────────────────────────────
-- STEP 2: accounting_categories table
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.accounting_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  name_en     text,
  name_ja     text,
  type        text NOT NULL CHECK (type IN ('income', 'expense')),
  code        text UNIQUE,
  is_system   boolean NOT NULL DEFAULT false,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.accounting_categories IS 'Danh mục phân loại phiếu thu/chi';

INSERT INTO public.accounting_categories (name, name_en, name_ja, type, code, is_system) VALUES
  ('Doanh thu bán hàng',       'Sales Revenue',            '売上高',           'income',  'INC-001', true),
  ('Thu khác',                  'Other Income',             'その他収入',       'income',  'INC-002', true),
  ('Thu từ đối tác',            'Partner Income',           'パートナー収入',   'income',  'INC-003', false),
  ('Chi trả lương',             'Payroll',                  '給与',             'expense', 'EXP-001', true),
  ('Chi mua nguyên vật liệu',  'Raw Material Purchase',    '原材料購入',       'expense', 'EXP-002', true),
  ('Chi điện nước',             'Utilities',                '光熱費',           'expense', 'EXP-003', true),
  ('Chi thuê mặt bằng',        'Rent',                     '家賃',             'expense', 'EXP-004', false),
  ('Chi marketing',            'Marketing',                'マーケティング費', 'expense', 'EXP-005', false),
  ('Chi vận chuyển',            'Logistics',                '輸送費',           'expense', 'EXP-006', false),
  ('Chi khác',                  'Other Expenses',           'その他費用',       'expense', 'EXP-007', true)
ON CONFLICT (code) DO NOTHING;

-- ────────────────────────────────────────────────────────────
-- STEP 3: cash_flow_entries table
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cash_flow_entries (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  category_id     uuid REFERENCES public.accounting_categories(id) ON DELETE SET NULL,
  type            text NOT NULL CHECK (type IN ('income', 'expense')),
  amount          numeric(15,2) NOT NULL CHECK (amount > 0),
  description     text NOT NULL,
  reference_no    text,
  payment_method  text DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'card')),
  status          text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'approved', 'rejected')),
  entry_date      date NOT NULL DEFAULT CURRENT_DATE,
  approved_by     uuid REFERENCES auth.users(id),
  approved_at     timestamptz,
  reject_reason   text,
  created_by      uuid REFERENCES auth.users(id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  procurement_po_id   uuid,
  notes               text
);

COMMENT ON TABLE public.cash_flow_entries IS 'Sổ thu chi - phiếu thu và phiếu chi';

CREATE INDEX IF NOT EXISTS idx_cash_flow_branch ON public.cash_flow_entries(branch_id);
CREATE INDEX IF NOT EXISTS idx_cash_flow_date   ON public.cash_flow_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_cash_flow_type   ON public.cash_flow_entries(type);
CREATE INDEX IF NOT EXISTS idx_cash_flow_status ON public.cash_flow_entries(status);

-- ────────────────────────────────────────────────────────────
-- STEP 4: ap_payment_records
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ap_payment_records (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  supplier_id     uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  invoice_ref     text,
  total_amount    numeric(15,2) NOT NULL,
  paid_amount     numeric(15,2) NOT NULL DEFAULT 0,
  due_date        date,
  payment_date    date,
  status          text NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid', 'overdue')),
  notes           text,
  created_by      uuid REFERENCES auth.users(id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.ap_payment_records IS 'Công nợ phải trả nhà cung cấp';

CREATE INDEX IF NOT EXISTS idx_ap_branch   ON public.ap_payment_records(branch_id);
CREATE INDEX IF NOT EXISTS idx_ap_supplier ON public.ap_payment_records(supplier_id);
CREATE INDEX IF NOT EXISTS idx_ap_status   ON public.ap_payment_records(status);

-- ────────────────────────────────────────────────────────────
-- STEP 5: RLS Policies
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.accounting_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_flow_entries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ap_payment_records    ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "accountants_read_categories" ON public.accounting_categories;
DROP POLICY IF EXISTS "managers_write_categories"   ON public.accounting_categories;
DROP POLICY IF EXISTS "accountant_read_cashflow"    ON public.cash_flow_entries;
DROP POLICY IF EXISTS "accountant_write_cashflow"   ON public.cash_flow_entries;
DROP POLICY IF EXISTS "accountant_update_cashflow"  ON public.cash_flow_entries;
DROP POLICY IF EXISTS "accountant_delete_cashflow"  ON public.cash_flow_entries;
DROP POLICY IF EXISTS "accountant_read_ap"          ON public.ap_payment_records;
DROP POLICY IF EXISTS "accountant_write_ap"         ON public.ap_payment_records;

CREATE POLICY "accountants_read_categories"
  ON public.accounting_categories FOR SELECT
  USING (public.is_accountant());

CREATE POLICY "managers_write_categories"
  ON public.accounting_categories FOR ALL
  USING (public.is_accounting_manager());

CREATE POLICY "accountant_read_cashflow"
  ON public.cash_flow_entries FOR SELECT
  USING (
    public.is_accounting_manager()
    OR (public.is_accountant() AND branch_id = public.current_branch_id())
  );

CREATE POLICY "accountant_write_cashflow"
  ON public.cash_flow_entries FOR INSERT
  WITH CHECK (
    public.is_accountant()
    AND (
      public.is_accounting_manager()
      OR branch_id = public.current_branch_id()
    )
  );

CREATE POLICY "accountant_update_cashflow"
  ON public.cash_flow_entries FOR UPDATE
  USING (
    public.is_accountant()
    AND (
      public.is_accounting_manager()
      OR branch_id = public.current_branch_id()
    )
  );

CREATE POLICY "accountant_delete_cashflow"
  ON public.cash_flow_entries FOR DELETE
  USING (
    public.is_accounting_manager()
    OR (
      status = 'draft'
      AND public.is_accountant()
      AND branch_id = public.current_branch_id()
    )
  );

CREATE POLICY "accountant_read_ap"
  ON public.ap_payment_records FOR SELECT
  USING (
    public.is_accounting_manager()
    OR (public.is_accountant() AND branch_id = public.current_branch_id())
  );

CREATE POLICY "accountant_write_ap"
  ON public.ap_payment_records FOR ALL
  USING (
    public.is_accounting_manager()
    OR (public.is_accountant() AND branch_id = public.current_branch_id())
  );

-- ────────────────────────────────────────────────────────────
-- STEP 6: RPCs
-- ────────────────────────────────────────────────────────────

-- 6.1: Accounting dashboard
CREATE OR REPLACE FUNCTION public.get_accounting_dashboard(
  p_branch_id  uuid DEFAULT NULL,
  p_year       int  DEFAULT NULL,
  p_month      int  DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_year      int  := COALESCE(p_year, EXTRACT(YEAR FROM now())::int);
  v_month     int  := COALESCE(p_month, EXTRACT(MONTH FROM now())::int);
  v_start     date := make_date(v_year, v_month, 1);
  v_end       date := (v_start + interval '1 month - 1 day')::date;
  v_branch_id uuid;
  v_result    jsonb;
BEGIN
  IF NOT public.is_accountant() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  IF public.is_accounting_manager() THEN
    v_branch_id := p_branch_id;
  ELSE
    v_branch_id := public.current_branch_id();
  END IF;

  SELECT jsonb_build_object(
    'period',         jsonb_build_object('year', v_year, 'month', v_month),
    'total_income',   COALESCE(SUM(CASE WHEN type = 'income'  AND status = 'approved' THEN amount ELSE 0 END), 0),
    'total_expense',  COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'approved' THEN amount ELSE 0 END), 0),
    'net_cashflow',   COALESCE(SUM(CASE WHEN type = 'income'  AND status = 'approved' THEN amount
                                        WHEN type = 'expense' AND status = 'approved' THEN -amount
                                        ELSE 0 END), 0),
    'pending_count',  COUNT(*) FILTER (WHERE status = 'pending'),
    'draft_count',    COUNT(*) FILTER (WHERE status = 'draft')
  )
  INTO v_result
  FROM public.cash_flow_entries
  WHERE entry_date BETWEEN v_start AND v_end
    AND (v_branch_id IS NULL OR branch_id = v_branch_id);

  SELECT v_result || jsonb_build_object(
    'ap_unpaid_count',  COUNT(*) FILTER (WHERE status IN ('unpaid', 'overdue')),
    'ap_unpaid_amount', COALESCE(SUM(total_amount - paid_amount) FILTER (WHERE status IN ('unpaid', 'overdue')), 0),
    'ap_overdue_count', COUNT(*) FILTER (WHERE status != 'paid' AND due_date IS NOT NULL AND due_date < CURRENT_DATE)
  )
  INTO v_result
  FROM public.ap_payment_records
  WHERE (v_branch_id IS NULL OR branch_id = v_branch_id);

  RETURN v_result;
END;
$$;

-- 6.2: List cash flow entries
CREATE OR REPLACE FUNCTION public.get_cash_flow_entries(
  p_branch_id uuid    DEFAULT NULL,
  p_start     date    DEFAULT NULL,
  p_end       date    DEFAULT NULL,
  p_type      text    DEFAULT NULL,
  p_status    text    DEFAULT NULL,
  p_limit     int     DEFAULT 50,
  p_offset    int     DEFAULT 0
)
RETURNS TABLE (
  id              uuid,
  branch_id       uuid,
  branch_name     text,
  category_id     uuid,
  category_name   text,
  category_code   text,
  type            text,
  amount          numeric,
  description     text,
  reference_no    text,
  payment_method  text,
  status          text,
  entry_date      date,
  approved_by     uuid,
  approved_at     timestamptz,
  reject_reason   text,
  created_by      uuid,
  creator_name    text,
  created_at      timestamptz,
  notes           text,
  total_count     bigint
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  IF NOT public.is_accountant() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  IF public.is_accounting_manager() THEN
    v_branch_id := p_branch_id;
  ELSE
    v_branch_id := public.current_branch_id();
  END IF;

  RETURN QUERY
  SELECT
    e.id,
    e.branch_id,
    b.name                                    AS branch_name,
    e.category_id,
    c.name                                    AS category_name,
    c.code                                    AS category_code,
    e.type,
    e.amount,
    e.description,
    e.reference_no,
    e.payment_method,
    e.status,
    e.entry_date,
    e.approved_by,
    e.approved_at,
    e.reject_reason,
    e.created_by,
    u.raw_user_meta_data->>'full_name'        AS creator_name,
    e.created_at,
    e.notes,
    COUNT(*) OVER()                           AS total_count
  FROM public.cash_flow_entries e
  LEFT JOIN public.branches b             ON b.id = e.branch_id
  LEFT JOIN public.accounting_categories c ON c.id = e.category_id
  LEFT JOIN auth.users u                  ON u.id = e.created_by
  WHERE (v_branch_id IS NULL OR e.branch_id = v_branch_id)
    AND (p_start  IS NULL OR e.entry_date >= p_start)
    AND (p_end    IS NULL OR e.entry_date <= p_end)
    AND (p_type   IS NULL OR e.type = p_type)
    AND (p_status IS NULL OR e.status = p_status)
  ORDER BY e.entry_date DESC, e.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 6.3: Create cash flow entry
CREATE OR REPLACE FUNCTION public.create_cash_flow_entry(
  p_branch_id       uuid,
  p_category_id     uuid,
  p_type            text,
  p_amount          numeric,
  p_description     text,
  p_payment_method  text  DEFAULT 'cash',
  p_entry_date      date  DEFAULT CURRENT_DATE,
  p_reference_no    text  DEFAULT NULL,
  p_notes           text  DEFAULT NULL
)
RETURNS public.cash_flow_entries
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_entry  public.cash_flow_entries;
  v_branch uuid;
BEGIN
  IF NOT public.is_accountant() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  IF public.is_accounting_manager() THEN
    v_branch := p_branch_id;
  ELSE
    v_branch := public.current_branch_id();
    IF v_branch IS NULL THEN
      RAISE EXCEPTION 'NO_BRANCH_CONTEXT';
    END IF;
  END IF;

  INSERT INTO public.cash_flow_entries (
    branch_id, category_id, type, amount, description,
    payment_method, entry_date, reference_no, notes, created_by
  ) VALUES (
    v_branch, p_category_id, p_type, p_amount, p_description,
    p_payment_method, p_entry_date, p_reference_no, p_notes, auth.uid()
  )
  RETURNING * INTO v_entry;

  RETURN v_entry;
END;
$$;

-- 6.4: Update cash flow entry
CREATE OR REPLACE FUNCTION public.update_cash_flow_entry(
  p_id              uuid,
  p_category_id     uuid    DEFAULT NULL,
  p_amount          numeric DEFAULT NULL,
  p_description     text    DEFAULT NULL,
  p_payment_method  text    DEFAULT NULL,
  p_entry_date      date    DEFAULT NULL,
  p_reference_no    text    DEFAULT NULL,
  p_notes           text    DEFAULT NULL
)
RETURNS public.cash_flow_entries
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_entry   public.cash_flow_entries;
  v_current public.cash_flow_entries;
BEGIN
  IF NOT public.is_accountant() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  SELECT * INTO v_current FROM public.cash_flow_entries WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND'; END IF;
  IF v_current.status NOT IN ('draft', 'rejected') THEN RAISE EXCEPTION 'CANNOT_EDIT_APPROVED'; END IF;

  UPDATE public.cash_flow_entries
  SET
    category_id    = COALESCE(p_category_id, category_id),
    amount         = COALESCE(p_amount, amount),
    description    = COALESCE(p_description, description),
    payment_method = COALESCE(p_payment_method, payment_method),
    entry_date     = COALESCE(p_entry_date, entry_date),
    reference_no   = COALESCE(p_reference_no, reference_no),
    notes          = COALESCE(p_notes, notes),
    status         = 'draft',
    updated_at     = now()
  WHERE id = p_id
  RETURNING * INTO v_entry;

  RETURN v_entry;
END;
$$;

-- 6.5: Approve / Reject
CREATE OR REPLACE FUNCTION public.approve_cash_flow_entry(
  p_id     uuid,
  p_action text,
  p_reason text DEFAULT NULL
)
RETURNS public.cash_flow_entries
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_entry public.cash_flow_entries;
BEGIN
  IF NOT public.is_accounting_manager() THEN
    RAISE EXCEPTION 'FORBIDDEN: only accounting_manager or admin can approve';
  END IF;
  IF p_action NOT IN ('approve', 'reject') THEN RAISE EXCEPTION 'INVALID_ACTION'; END IF;

  UPDATE public.cash_flow_entries
  SET
    status        = CASE p_action WHEN 'approve' THEN 'approved' ELSE 'rejected' END,
    approved_by   = CASE p_action WHEN 'approve' THEN auth.uid() ELSE NULL END,
    approved_at   = CASE p_action WHEN 'approve' THEN now() ELSE NULL END,
    reject_reason = CASE p_action WHEN 'reject'  THEN p_reason ELSE NULL END,
    updated_at    = now()
  WHERE id = p_id AND status = 'pending'
  RETURNING * INTO v_entry;

  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND_OR_NOT_PENDING'; END IF;
  RETURN v_entry;
END;
$$;

-- 6.6: Submit for approval
CREATE OR REPLACE FUNCTION public.submit_cash_flow_entry(p_id uuid)
RETURNS public.cash_flow_entries
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_entry public.cash_flow_entries;
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;

  UPDATE public.cash_flow_entries
  SET status = 'pending', updated_at = now()
  WHERE id = p_id
    AND status IN ('draft', 'rejected')
    AND (public.is_accounting_manager() OR branch_id = public.current_branch_id())
  RETURNING * INTO v_entry;

  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND_OR_INVALID_STATUS'; END IF;
  RETURN v_entry;
END;
$$;

-- 6.7: Delete (draft only)
CREATE OR REPLACE FUNCTION public.delete_cash_flow_entry(p_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;

  DELETE FROM public.cash_flow_entries
  WHERE id = p_id
    AND status = 'draft'
    AND (public.is_accounting_manager() OR branch_id = public.current_branch_id());

  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND_OR_NOT_DRAFT'; END IF;
END;
$$;

-- 6.8: Get categories
CREATE OR REPLACE FUNCTION public.get_accounting_categories(p_type text DEFAULT NULL)
RETURNS SETOF public.accounting_categories
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;
  RETURN QUERY
  SELECT * FROM public.accounting_categories
  WHERE is_active = true
    AND (p_type IS NULL OR type = p_type)
  ORDER BY type, code;
END;
$$;

-- 6.9: AP Summary
CREATE OR REPLACE FUNCTION public.get_ap_summary(
  p_branch_id uuid DEFAULT NULL,
  p_status    text DEFAULT NULL
)
RETURNS TABLE (
  id              uuid,
  branch_id       uuid,
  branch_name     text,
  supplier_id     uuid,
  supplier_name   text,
  invoice_ref     text,
  total_amount    numeric,
  paid_amount     numeric,
  outstanding     numeric,
  due_date        date,
  payment_date    date,
  status          text,
  is_overdue      boolean,
  notes           text,
  created_at      timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;

  IF public.is_accounting_manager() THEN
    v_branch_id := p_branch_id;
  ELSE
    v_branch_id := public.current_branch_id();
  END IF;

  RETURN QUERY
  SELECT
    ap.id,
    ap.branch_id,
    b.name                                          AS branch_name,
    ap.supplier_id,
    s.name                                          AS supplier_name,
    ap.invoice_ref,
    ap.total_amount,
    ap.paid_amount,
    (ap.total_amount - ap.paid_amount)              AS outstanding,
    ap.due_date,
    ap.payment_date,
    ap.status,
    (ap.status != 'paid' AND ap.due_date IS NOT NULL AND ap.due_date < CURRENT_DATE) AS is_overdue,
    ap.notes,
    ap.created_at
  FROM public.ap_payment_records ap
  LEFT JOIN public.branches b  ON b.id = ap.branch_id
  LEFT JOIN public.suppliers s ON s.id = ap.supplier_id
  WHERE (v_branch_id IS NULL OR ap.branch_id = v_branch_id)
    AND (p_status IS NULL OR ap.status = p_status)
  ORDER BY ap.due_date ASC NULLS LAST, ap.created_at DESC;
END;
$$;

-- 6.10: Record AP payment
CREATE OR REPLACE FUNCTION public.record_ap_payment(
  p_branch_id     uuid,
  p_supplier_id   uuid,
  p_invoice_ref   text,
  p_total_amount  numeric,
  p_paid_amount   numeric,
  p_due_date      date  DEFAULT NULL,
  p_notes         text  DEFAULT NULL
)
RETURNS public.ap_payment_records
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_record public.ap_payment_records;
  v_status text;
  v_branch uuid;
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;

  IF public.is_accounting_manager() THEN
    v_branch := p_branch_id;
  ELSE
    v_branch := public.current_branch_id();
  END IF;

  v_status := CASE
    WHEN p_paid_amount >= p_total_amount THEN 'paid'
    WHEN p_paid_amount > 0               THEN 'partial'
    ELSE 'unpaid'
  END;

  INSERT INTO public.ap_payment_records (
    branch_id, supplier_id, invoice_ref, total_amount, paid_amount,
    due_date, status, notes, created_by, payment_date
  ) VALUES (
    v_branch, p_supplier_id, p_invoice_ref, p_total_amount, p_paid_amount,
    p_due_date, v_status, p_notes, auth.uid(),
    CASE WHEN p_paid_amount >= p_total_amount THEN CURRENT_DATE ELSE NULL END
  )
  RETURNING * INTO v_record;

  RETURN v_record;
END;
$$;

-- 6.11: P&L Report
CREATE OR REPLACE FUNCTION public.get_pl_report(
  p_branch_id uuid DEFAULT NULL,
  p_year      int  DEFAULT NULL,
  p_month     int  DEFAULT NULL
)
RETURNS TABLE (
  category_code text,
  category_name text,
  type          text,
  month_amount  numeric,
  ytd_amount    numeric
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_year      int  := COALESCE(p_year, EXTRACT(YEAR FROM now())::int);
  v_month     int  := COALESCE(p_month, EXTRACT(MONTH FROM now())::int);
  v_start     date := make_date(v_year, v_month, 1);
  v_end       date := (v_start + interval '1 month - 1 day')::date;
  v_ytd_start date := make_date(v_year, 1, 1);
  v_branch_id uuid;
BEGIN
  IF NOT public.is_accountant() THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;

  IF public.is_accounting_manager() THEN
    v_branch_id := p_branch_id;
  ELSE
    v_branch_id := public.current_branch_id();
  END IF;

  RETURN QUERY
  SELECT
    c.code              AS category_code,
    c.name              AS category_name,
    c.type,
    COALESCE(SUM(e.amount) FILTER (WHERE e.entry_date BETWEEN v_start AND v_end
                                     AND e.status = 'approved'), 0) AS month_amount,
    COALESCE(SUM(e.amount) FILTER (WHERE e.entry_date BETWEEN v_ytd_start AND v_end
                                     AND e.status = 'approved'), 0) AS ytd_amount
  FROM public.accounting_categories c
  LEFT JOIN public.cash_flow_entries e ON e.category_id = c.id
    AND (v_branch_id IS NULL OR e.branch_id = v_branch_id)
  WHERE c.is_active = true
  GROUP BY c.id, c.code, c.name, c.type
  ORDER BY c.type DESC, c.code;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- STEP 7: Grants
-- ────────────────────────────────────────────────────────────
GRANT SELECT ON public.accounting_categories TO authenticated;
GRANT SELECT ON public.cash_flow_entries     TO authenticated;
GRANT SELECT ON public.ap_payment_records    TO authenticated;

GRANT EXECUTE ON FUNCTION public.is_accountant           TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_accounting_manager   TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_accounting_dashboard TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_cash_flow_entries   TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_cash_flow_entry  TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_cash_flow_entry  TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_cash_flow_entry TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_cash_flow_entry  TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_cash_flow_entry  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_accounting_categories TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_ap_summary          TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_ap_payment       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pl_report           TO authenticated;
