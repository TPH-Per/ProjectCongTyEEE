# ADDENDUM: PROCUREMENT & ACCOUNTING WORKFLOWS

Tài liệu này bổ sung cho `MASTER_IMPLEMENTATION_PLAN.md`, tập trung thiết kế kiến trúc và giao diện nhằm số hóa 100% quy trình nghiệp vụ thực tế của team Procurement (Nhập hàng phi tập trung, Kiểm kho) và Accounting (Đối soát hóa đơn, Chốt sổ), tuân thủ triết lý bảo toàn dữ liệu và tính toán tự động của F2TECH.

---

## PART 1 — CẤU TRÚC CƠ SỞ DỮ LIỆU (DATABASE SCHEMA)

Cần bổ sung các bảng sau để đáp ứng quy trình Daily, Weekly, Monthly:

### 1. Daily Workflow (Goods Receipts)
Xử lý các phiếu giao hàng thực tế từ NCC, hỗ trợ chụp ảnh/scan và nhập tay.

```sql
CREATE TABLE public.goods_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    supplier_id UUID REFERENCES public.suppliers(id) NOT NULL,
    receipt_date DATE NOT NULL,
    image_url TEXT, -- Lưu link ảnh chụp phiếu giao hàng
    total_amount NUMERIC(12,2) DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'COMPLETED', -- COMPLETED (đã nhập kho), VOID
    UNIQUE(supplier_id, receipt_date) -- Chống trùng lặp phiếu giao hàng trong ngày
);

CREATE TABLE public.goods_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID REFERENCES public.goods_receipts(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES public.ingredients(id) NOT NULL,
    quantity NUMERIC(10,2) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    total_price NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);
```

### 2. Weekly Workflow (Inventory Audits)
Xử lý quy trình kiểm kho thực tế hàng tuần.

```sql
CREATE TABLE public.inventory_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    audit_date DATE NOT NULL,
    status TEXT DEFAULT 'DRAFT', -- DRAFT (Đang đếm), REVIEW (Đang chờ đối chiếu), COMPLETED (Đã chốt)
    auditor_id UUID REFERENCES auth.users(id), -- Người đếm (Bếp)
    reviewer_id UUID REFERENCES auth.users(id), -- Người chốt (Procurement)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.inventory_audit_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_id UUID REFERENCES public.inventory_audits(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES public.ingredients(id) NOT NULL,
    system_qty NUMERIC(10,2) NOT NULL, -- Tồn kho hệ thống lúc bắt đầu kiểm
    actual_qty NUMERIC(10,2), -- Bếp nhập số lượng đếm thực tế
    discrepancy NUMERIC(10,2) GENERATED ALWAYS AS (actual_qty - system_qty) STORED,
    reason TEXT -- Lý do hao hụt/chênh lệch
);
```

### 3. Monthly Workflow (AP Invoices & Inventory Snapshots)
Đối soát hóa đơn đỏ (3-Way Matching) và chốt sổ kho.

```sql
CREATE TABLE public.supplier_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number TEXT NOT NULL UNIQUE, -- Số hóa đơn đỏ
    supplier_id UUID REFERENCES public.suppliers(id) NOT NULL,
    issue_date DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL, -- Tổng tiền trên hóa đơn đỏ
    status TEXT DEFAULT 'PENDING', -- PENDING, MATCHED, PAID
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng mapping 3-Way Matching (Nối Hóa đơn đỏ với nhiều Phiếu giao hàng)
CREATE TABLE public.invoice_receipt_matches (
    invoice_id UUID REFERENCES public.supplier_invoices(id) ON DELETE CASCADE,
    receipt_id UUID REFERENCES public.goods_receipts(id) ON DELETE CASCADE,
    PRIMARY KEY (invoice_id, receipt_id)
);

-- Bảng lưu trữ chốt sổ kho hàng tháng
CREATE TABLE public.inventory_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    period_month INT NOT NULL,
    period_year INT NOT NULL,
    ingredient_id UUID REFERENCES public.ingredients(id) NOT NULL,
    opening_balance NUMERIC(10,2) NOT NULL,
    total_in NUMERIC(10,2) NOT NULL,
    total_out NUMERIC(10,2) NOT NULL,
    closing_balance NUMERIC(10,2) NOT NULL,
    UNIQUE(branch_id, period_month, period_year, ingredient_id)
);
```

---

## PART 2 — CÁC HÀM RPC ĐẢM BẢO ATOMICITY

> **Critical Rule:** Các hàm làm thay đổi kho phải khóa row (`FOR UPDATE`) để chống race condition.

1. **`submit_goods_receipt(p_branch_id, p_supplier_id, p_receipt_date, p_image_url, p_items)`**
   - Insert vào `goods_receipts` (Database tự động chặn nếu trùng `supplier_id` + `receipt_date`).
   - Insert vào `goods_receipt_items`.
   - Vòng lặp `p_items`: Lock `inventory_stock` FOR UPDATE $\rightarrow$ Cộng dồn `quantity` $\rightarrow$ Insert `inventory_transactions` loại `IN`.

2. **`complete_inventory_audit(p_audit_id, p_reviewer_id)`**
   - Chuyển `inventory_audits.status = COMPLETED`.
   - Vòng lặp các items có `discrepancy != 0`: Lock `inventory_stock` FOR UPDATE $\rightarrow$ Cập nhật bằng `actual_qty` $\rightarrow$ Insert `inventory_transactions` loại `ADJUSTMENT`.

3. **`match_invoice(p_invoice_id, p_receipt_ids_array)`**
   - Insert vào `invoice_receipt_matches`.
   - Tính tổng `total_amount` từ các receipts truyền vào.
   - Nếu tổng khớp với `supplier_invoices.total_amount`, update status hóa đơn thành `MATCHED`. Nếu không khớp, raise Exception (Báo lỗi cho Kế toán).

4. **`close_inventory_period(p_branch_id, p_month, p_year)`**
   - Tự động tính: Tồn đầu kỳ = Tồn cuối kỳ của tháng trước. Tổng In = Tổng các giao dịch IN. Tổng Out = Tổng các giao dịch OUT/ADJUSTMENT.
   - Insert kết quả vào `inventory_snapshots`.

---

## PART 3 — COMPOSABLES & UI MODULES

### 1. Purchasing Team UI (`src/views/purchasing/`)

- **`DailyReceiptView.vue` (Nhập Phiếu Giao Hàng)**
  - UI chia 2 phần: Bên trái là Upload Ảnh/Hiển thị ảnh scan, bên phải là Form nhập liệu.
  - Chọn Supplier, Chọn Ngày $\rightarrow$ Cảnh báo ngay nếu đã tồn tại.
  - Form table: Chọn Nguyên liệu (Có nút "+" để thêm mã định danh mới ngay lập tức), nhập Qty, nhập Unit Price. Total Price tự động tính.
  - Nút **"Xác nhận & Nhập Kho"** gọi `submit_goods_receipt()`.

- **`WeeklyAuditView.vue` (Kiểm Kho / e-Stocktake)**
  - Chọn ngày để xem hoặc tạo Phiếu kiểm kho mới.
  - Hiển thị danh sách nguyên liệu. 2 Cột hiển thị: **Số hệ thống (System)** và **Số đếm thực tế (Actual)**.
  - Cột Chênh lệch (Discrepancy) tự động tô màu đỏ nếu âm.
  - Kèm theo dropdown chọn Lý do hao hụt.
  - Nút **"Chốt Sổ Tồn Kho"** gọi `complete_inventory_audit()`.

### 2. Accounting Team UI (`src/views/accounting/`)

- **`APInvoiceView.vue` (Quản Lý Hóa Đơn Đỏ & 3-Way Matching)**
  - Nửa trên: Danh sách Hóa đơn đỏ (PENDING / MATCHED / PAID).
  - Khung Matching: Chọn 1 Hóa đơn đỏ $\rightarrow$ Hiển thị danh sách các Phiếu giao hàng chưa được match của NCC đó.
  - Tick chọn các phiếu giao hàng. Hệ thống tự động tính tổng tiền các phiếu và đối chiếu với số tiền Hóa đơn đỏ. Hiển thị chữ MATCH (màu xanh) hoặc sai số (màu đỏ).
  - Nút **"Thực Hiện Đối Soát"** gọi `match_invoice()`.

- **`InventoryClosingView.vue` (Chốt Sổ Kho & Báo Cáo)**
  - Quản lý các kỳ kế toán (Tháng/Năm).
  - Nút **"Khóa sổ tháng N"** gọi `close_inventory_period()`.
  - Hiển thị bảng Báo Cáo Nhập Xuất Tồn (Opening, In, Out, Closing) đọc từ `inventory_snapshots`.

---
*Bản thiết kế này tích hợp trực tiếp vào MASTER_IMPLEMENTATION_PLAN.md, đảm bảo bảo toàn tính nguyên vẹn của dòng chảy dữ liệu từ kho vật lý đến chứng từ kế toán.*
