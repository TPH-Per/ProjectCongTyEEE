# ĐỀ XUẤT KIẾN TRÚC DATABASE & BACKEND CHO HỆ THỐNG POS (F2TECH)
Tài liệu quy chuẩn luồng xử lý từ khi chạm nút "Đặt món" đến khi in phiếu Bếp & Hóa đơn.

## 1. MÔ HÌNH DỮ LIỆU CHUẨN (Database Schema)

Để giải quyết mượt mà các case phức tạp (Combo, Buffet, A-la-carte) mà không làm rối hệ thống, Database cần được chia làm 3 nhóm chính: Nhóm Menu, Nhóm Bán hàng, và Nhóm Ngoại vi.

### Nhóm 1: Menu & Sản phẩm (Dữ liệu tĩnh)
- **Bảng `products` (Sản phẩm):**
  - `id`, `name`, `price`, `type` *(enum: alacarte, combo, buffet_ticket)*.
  - `printer_id` *(VD: 'KITCHEN_HOT', 'BAR' - Rất quan trọng để định tuyến)*.
- **Bảng `combo_details` (Công thức Set/Combo):**
  - `combo_id` (FK tới `products.id`).
  - `child_item_id` (FK tới `products.id` - Món thành phần).
  - `quantity` (Số lượng).

### Nhóm 2: Bán hàng (Lưu doanh thu)
- **Bảng `orders` (Phiếu tính tiền):**
  - `id`, `customer_id`, `total_amount`, `order_type` *(buffet / alacarte)*.
- **Bảng `order_items` (Chi tiết phiếu tính tiền):**
  - `id`, `order_id`, `product_id`, `quantity`.
  - `price_at_sale` *(Bắt buộc phải lưu giá tại thời điểm bán để chống sai lệch báo cáo nếu sau này đổi giá menu)*.

### Nhóm 3: Ngoại vi & Phần cứng
- **Bảng `print_jobs` (Hàng đợi in):**
  - `id`, `branch_id`, `printer_id`, `payload` (JSONB), `status`.

---

## 2. THUẬT TOÁN XỬ LÝ (Backend Algorithm)

Khi Frontend gọi API `POST /api/orders`, Backend (NodeJS/Python) KHÔNG ĐƯỢC dùng SQL Trigger, mà phải thực thi đoạn code tuần tự theo thuật toán sau (chạy trong 1 Transaction duy nhất):

### BƯỚC 1: Chuẩn bị giỏ hàng in (Print Payload Builder)
Backend tạo một biến tạm trong RAM để gom nhóm các món ăn theo máy in.
```json
{
  "KITCHEN_HOT": [],
  "BAR": [],
  "RECEIPT": []
}
```

### BƯỚC 2: Duyệt từng món trong Cart (Vòng lặp)
Backend duyệt qua danh sách món mà Frontend gửi lên. Có 3 kịch bản:

**Kịch bản A: Khách gọi món lẻ (A-la-carte)**
- Backend kiểm tra `products.printer_id` của món đó.
- Ném thông tin món vào giỏ in tương ứng (VD: `KITCHEN_HOT`).

**Kịch bản B: Khách gọi Combo / Set Menu (Gia Đình)**
- Backend bỏ qua máy in của cái Combo.
- Query bảng `combo_details` để moi ra các món thành phần (Child items: Bò, Nấm, Salad...).
- Duyệt qua từng món thành phần, kiểm tra `printer_id` của món thành phần.
- Ném món thành phần vào giỏ in tương ứng. **Gắn thêm cờ `part_of_combo: "Combo Gia Đình"`** để đầu bếp biết chúng thuộc một Set.

**Kịch bản C: Bàn này đang ăn Buffet**
- Nếu `order_type == 'buffet'`, Backend ép toàn bộ `price_at_sale = 0` (để tính doanh thu = 0).
- Ném món vào giỏ in, **Gắn thêm Note: "Buffet"** để Bếp không làm quá to/nhiều như món bán lẻ.

### BƯỚC 3: Lưu doanh thu & Ra lệnh in (Database Transaction)
Sau khi vòng lặp kết thúc, Backend thực thi 1 Transaction vào Database gồm 3 chặng:
1. `INSERT INTO orders` và `INSERT INTO order_items` (Lưu lịch sử kinh doanh).
2. Backend gom toàn bộ thông tin thanh toán (Tiền, VAT, Danh sách món hiển thị cho khách) tạo thành 1 cục JSON rồi `INSERT INTO print_jobs (printer_id = 'RECEIPT')`.
3. Backend lôi các mảng trong biến tạm (ở BƯỚC 1) ra, cứ mỗi mảng có data, nó tạo 1 cục JSON rồi `INSERT INTO print_jobs` (Ví dụ: 1 dòng cho `KITCHEN_HOT`, 1 dòng cho `BAR`).
4. `COMMIT` Transaction.

---

## 3. LỢI ÍCH CỦA KIẾN TRÚC NÀY
1. **Phân tách trách nhiệm (Separation of Concerns):** Bếp và Quầy Bar không bị "rác" thông tin. Bếp không cần đọc nguyên cái Hóa đơn dài thoòng, Bếp chỉ nhận được đúng những món mình cần nấu (đã bóc tách sẵn từ Combo).
2. **Khả năng bắt lỗi (Fault Tolerance):** Nếu máy in chết, data trong `print_jobs` bị kẹt, nhưng doanh thu trong `orders` đã chốt xong xuôi, không bị mất tiền hay sai báo cáo.
3. **Mở rộng dễ dàng:** Mai mốt có thêm máy in pha chế (Bar), chỉ cần tạo món mới gán `printer_id = 'BAR'`, Backend tự động tách luồng in mà không cần đụng 1 dòng code nào vào hệ thống Print Server.
