# REVISED MVP PLAN: 6 ROLES & CORE DATA FLOW

Tài liệu này là bản kế hoạch chốt hạ (MVP) thay thế và ghi đè các cấu trúc phức tạp trong `MASTER_IMPLEMENTATION_PLAN.md`. Chúng ta sẽ chỉ tập trung vào 6 Roles cốt lõi để đảm bảo dòng tiền và hàng hóa được kiểm soát chặt chẽ, an toàn tuyệt đối khỏi Race Condition và N+1 Query.

---

## PHẦN 1: CẤU TRÚC 6 ROLES (PHẠM VI MVP)

### 1. Khách Hàng (Customer - Tablet Role)
- C1: Xem Menu & Đặt món.
- C2: Gọi phục vụ (Call Waiter) / Yêu cầu tính tiền (Request Bill).
- C3: Gửi đánh giá dịch vụ (Feedback).

### 2. Tiền Sảnh / Phục Vụ (Hall)
- H1: Quản lý bàn (Xem sơ đồ bàn, theo dõi trạng thái).
- H2: Xử lý dịch vụ (Nhận thông báo Realtime từ Tablet).
- H3: Sắp xếp bàn, đón khách và mở Order mới.
- H4: Thu ngân (Checkout): Tính tiền, áp dụng voucher, xuất Bill.

### 3. Bếp (Kitchen)
- K1: Màn hình KDS (Kitchen Display System): Xem danh sách các món ăn đang được order (Realtime) để chế biến.

### 4. Mua Hàng & Kho (Purchasing / Procurement)
- P1: Tạo phiếu nhập từ hóa đơn được giao tới kèm hàng hóa (Daily Receipt) - Có upload ảnh scan.
- P2: Xử lý kiểm kho (Weekly Audit): Đếm thực tế, đối chiếu hệ thống, chốt hao hụt.
- P3: Quản lý Danh mục Nhà Cung Cấp & Nguyên vật liệu.

### 5. Kế Toán (Accounting)
- A1: Báo cáo Doanh thu & Chi phí (Dựa trên Bills và Invoices hợp lệ).
- A2: Khai Thuế & P&L: Tự động xuất báo cáo nộp thuế.

### 6. Quản Trị Cấp Cao (Admin / Owner)
- AD1: Cấu hình hệ thống (VAT) & Quản lý User.
- AD2: Executive Dashboard (Tổng quan kinh doanh).
- AD3: Quản trị Marketing & Khuyến mãi (Tự tạo Campaign/Voucher không qua duyệt).
- AD4: Giao chỉ tiêu KPI & Ngân sách.
- AD5: Hủy hóa đơn (Void Invoice) & Xử lý ngoại lệ khẩn cấp.

---

## PHẦN 2: THIẾT KẾ CƠ SỞ DỮ LIỆU (BILLS & INVOICES)
*Tuân thủ tiêu chuẩn ACID, Immutable Bills và chống Race Condition.*

```sql
-- 1. BẢNG BILLS (POS Flow - Immutable)
CREATE TABLE public.bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_code TEXT UNIQUE NOT NULL,
    table_id UUID REFERENCES tables(id),
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

-- 2. BẢNG INVOICES (Tax Flow - Hóa đơn đỏ)
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    status TEXT NOT NULL DEFAULT 'VALID', -- VALID, UPDATED, VOID
    is_signed BOOLEAN DEFAULT TRUE,
    signature_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CHỐNG RACE CONDITION (DB LEVEL): Không cho phép 2 hóa đơn VALID cho cùng 1 Bill
CREATE UNIQUE INDEX idx_one_valid_invoice_per_bill 
ON public.invoices (bill_id) 
WHERE status = 'VALID';
```

---

## PHẦN 3: RPC FUNCTIONS (CHỐNG RACE CONDITION BẰNG "FOR UPDATE")

### RPC: Thay thế / Sửa Hóa Đơn (`replace_invoice`)
```sql
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
  FROM invoices 
  WHERE bill_id = p_bill_id AND status = 'VALID' 
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy hóa đơn VALID cho bill_id %', p_bill_id;
  END IF;

  -- Đổi status hóa đơn cũ thành UPDATED
  UPDATE invoices SET status = 'UPDATED' WHERE id = v_old_invoice_id;

  -- Tạo hóa đơn mới
  INSERT INTO invoices (
    bill_id, invoice_symbol, invoice_number, issue_date,
    buyer_tax_code, buyer_company, status
  ) VALUES (
    p_bill_id, p_new_invoice_symbol, p_new_invoice_number, CURRENT_DATE,
    p_buyer_tax_code, p_buyer_company, 'VALID'
  ) RETURNING id INTO v_new_invoice_id;

  RETURN v_new_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### RPC: Hủy Hóa Đơn (`void_invoice`)
```sql
CREATE OR REPLACE FUNCTION void_invoice(p_bill_id UUID) RETURNS VOID AS $$
DECLARE
  v_invoice_id UUID;
BEGIN
  -- Khóa dòng "FOR UPDATE"
  SELECT id INTO v_invoice_id 
  FROM invoices 
  WHERE bill_id = p_bill_id AND status = 'VALID' 
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không có hóa đơn hợp lệ để hủy.';
  END IF;

  -- Chuyển thành VOID
  UPDATE invoices SET status = 'VOID' WHERE id = v_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## PHẦN 4: GIẢI PHÁP CHỐNG N+1 QUERY (DATA FETCHING)

Để không gây kẹt Server khi truy xuất Báo Cáo Thuế, Frontend sẽ dùng `!inner` join của Supabase thay vì lặp qua từng `bill_id`. Bằng cách này, PostgreSQL tự động thực thi 1 câu lệnh `INNER JOIN` duy nhất ở tầng Database.

```javascript
// Dataflow truy xuất Báo cáo thuế: CHỈ 1 QUERY DUY NHẤT
const fetchTaxReport = async (startDate, endDate) => {
  const { data, error } = await supabase
    .from('bills')
    .select(`
      id, bill_code, grand_total, created_at,
      invoices!inner (
        id, invoice_number, buyer_company, buyer_tax_code, status
      )
    `)
    .eq('invoices.status', 'VALID') // Bỏ qua UPDATED và VOID
    .gte('created_at', startDate)
    .lte('created_at', endDate);
    
  return data; 
};
```
