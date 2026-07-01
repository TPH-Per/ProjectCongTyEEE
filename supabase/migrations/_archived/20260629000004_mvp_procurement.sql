-- ==============================================================================
-- MVP REVISED PLAN: PROCUREMENT & INVENTORY (GOODS RECEIPTS)
-- ==============================================================================

-- 1. BẢNG HÀNG HÓA / NGUYÊN LIỆU (Ingredients / Items)
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    code TEXT NOT NULL, -- Mã định danh riêng (Unique Identifier)
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    current_stock NUMERIC(12,3) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (branch_id, code)
);

-- 2. BẢNG PHIẾU NHẬP HÀNG (Goods Receipts - Tương đương Receipt Scans)
CREATE TABLE IF NOT EXISTS public.goods_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    receipt_code TEXT UNIQUE NOT NULL,
    supplier_name TEXT,
    scan_image_url TEXT, -- Đường dẫn ảnh scan chứng từ
    total_amount NUMERIC(14,2) DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    status TEXT DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- BẢNG CHI TIẾT PHIẾU NHẬP
CREATE TABLE IF NOT EXISTS public.goods_receipt_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_id UUID NOT NULL REFERENCES public.goods_receipts(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.inventory_items(id),
    quantity NUMERIC(12,3) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    total_price NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- 3. RPC: Nhập hàng (Cập nhật kho an toàn)
CREATE OR REPLACE FUNCTION submit_goods_receipt(
  p_branch_id UUID,
  p_receipt_code TEXT,
  p_supplier_name TEXT,
  p_scan_image_url TEXT,
  p_items JSONB -- Array of { item_id, quantity, unit_price }
) RETURNS UUID AS $$
DECLARE
  v_receipt_id UUID;
  v_item JSONB;
  v_total_amount NUMERIC(14,2) := 0;
BEGIN
  -- Tạo phiếu nhập
  INSERT INTO public.goods_receipts (branch_id, receipt_code, supplier_name, scan_image_url, status)
  VALUES (p_branch_id, p_receipt_code, p_supplier_name, p_scan_image_url, 'COMPLETED')
  RETURNING id INTO v_receipt_id;

  -- Duyệt qua từng item
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- Insert chi tiết
    INSERT INTO public.goods_receipt_items (receipt_id, item_id, quantity, unit_price)
    VALUES (
      v_receipt_id, 
      (v_item->>'item_id')::UUID, 
      (v_item->>'quantity')::NUMERIC, 
      (v_item->>'unit_price')::NUMERIC
    );

    -- Cập nhật tồn kho (Cộng dồn)
    UPDATE public.inventory_items 
    SET current_stock = current_stock + (v_item->>'quantity')::NUMERIC
    WHERE id = (v_item->>'item_id')::UUID;

    v_total_amount := v_total_amount + ((v_item->>'quantity')::NUMERIC * (v_item->>'unit_price')::NUMERIC);
  END LOOP;

  -- Cập nhật tổng tiền phiếu nhập
  UPDATE public.goods_receipts SET total_amount = v_total_amount WHERE id = v_receipt_id;

  RETURN v_receipt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
