-- ==============================================================================
-- MVP REVISED PLAN: REFINED BILLS & INVOICES (ANTI RACE-CONDITION)
-- ==============================================================================

-- 1. CLEANUP OLD CONFLICTING TABLES
DROP TABLE IF EXISTS public.invoices CASCADE;
DROP TABLE IF EXISTS public.bills CASCADE;
DROP TABLE IF EXISTS public.bill_items CASCADE;

-- 2. CREATE BILLS TABLE (POS Flow - Immutable)
CREATE TABLE public.bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_code TEXT UNIQUE NOT NULL,
    table_id UUID REFERENCES public.tables(id) ON DELETE SET NULL,
    shift_number INT,
    time_in TIMESTAMPTZ,
    time_out TIMESTAMPTZ,
    cashier_id UUID REFERENCES auth.users(id),
    waiter_id UUID REFERENCES auth.users(id),
    print_count INT DEFAULT 1,
    sub_total NUMERIC(12,2) NOT NULL,
    vat_8_amount NUMERIC(12,2) DEFAULT 0,
    vat_10_amount NUMERIC(12,2) DEFAULT 0,
    grand_total NUMERIC(12,2) NOT NULL,
    payment_method TEXT,
    payment_detail JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CREATE BILL ITEMS (Line items for historical immutability)
CREATE TABLE public.bill_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
    quantity NUMERIC(12,2) NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL
);

-- 3. CREATE INVOICES TABLE (Tax Flow - Hóa đơn đỏ)
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID REFERENCES public.bills(id) ON DELETE CASCADE,
    invoice_symbol TEXT NOT NULL,
    invoice_number TEXT NOT NULL,
    issue_date DATE NOT NULL,
    buyer_name TEXT DEFAULT 'Người mua không lấy hoá đơn',
    buyer_company TEXT DEFAULT 'Người mua không lấy hoá đơn',
    buyer_tax_code TEXT,
    payment_method_code TEXT DEFAULT 'KTT',
    total_goods_amount NUMERIC(12,2),
    total_tax_amount NUMERIC(12,2),
    grand_total NUMERIC(12,2),
    tax_breakdown JSONB,
    status TEXT NOT NULL DEFAULT 'VALID' CHECK (status IN ('VALID', 'UPDATED', 'VOID')), 
    is_signed BOOLEAN DEFAULT TRUE,
    signature_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ANTI RACE-CONDITION: Only ONE valid invoice per bill
CREATE UNIQUE INDEX idx_one_valid_invoice_per_bill 
ON public.invoices (bill_id) 
WHERE status = 'VALID';

-- 5. RPC: REPLACE INVOICE (FOR UPDATE LOCK)
CREATE OR REPLACE FUNCTION replace_invoice(
  p_bill_id UUID,
  p_new_invoice_symbol TEXT,
  p_new_invoice_number TEXT,
  p_buyer_tax_code TEXT,
  p_buyer_company TEXT
) RETURNS UUID AS $$
DECLARE
  v_old_invoice_id UUID;
  v_new_invoice_id UUID;
BEGIN
  -- Khóa dòng "FOR UPDATE" để chặn đứng Race Condition
  SELECT id INTO v_old_invoice_id 
  FROM public.invoices 
  WHERE bill_id = p_bill_id AND status = 'VALID' 
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy hóa đơn VALID cho bill_id %', p_bill_id;
  END IF;

  -- Đổi status hóa đơn cũ thành UPDATED
  UPDATE public.invoices SET status = 'UPDATED' WHERE id = v_old_invoice_id;

  -- Tạo hóa đơn mới
  INSERT INTO public.invoices (
    bill_id, invoice_symbol, invoice_number, issue_date,
    buyer_tax_code, buyer_company, status
  ) VALUES (
    p_bill_id, p_new_invoice_symbol, p_new_invoice_number, CURRENT_DATE,
    p_buyer_tax_code, p_buyer_company, 'VALID'
  ) RETURNING id INTO v_new_invoice_id;

  RETURN v_new_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC: VOID INVOICE (FOR UPDATE LOCK)
CREATE OR REPLACE FUNCTION void_invoice(p_bill_id UUID) RETURNS VOID AS $$
DECLARE
  v_invoice_id UUID;
BEGIN
  -- Khóa dòng "FOR UPDATE"
  SELECT id INTO v_invoice_id 
  FROM public.invoices 
  WHERE bill_id = p_bill_id AND status = 'VALID' 
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không có hóa đơn hợp lệ để hủy.';
  END IF;

  -- Chuyển thành VOID
  UPDATE public.invoices SET status = 'VOID' WHERE id = v_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
