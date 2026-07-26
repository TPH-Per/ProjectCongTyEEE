# NGƯU CÁT POS V6 — OPERATIONAL DATA GUIDE

**Nguồn DDL:** `restaurant_schema_v6_simplified.sql`.  
Tài liệu trả lời: nghiệp vụ tạo/sửa fact nào, ngoại lệ ảnh hưởng bảng nào và thao tác nào phải gọi RPC atomic.

## 1. Bản đồ tổng thể

```text
customers → reservations → reservation_tables
                     └──→ dining_sessions → session_guests
                                          → session_tables
                                          → orders → order_details
                                                       └→ bill_details → bills
                                                                        ├→ payment_intents
                                                                        │    └→ payment_attempts
                                                                        │         └→ payments
                                                                        ├→ customer_debt_transactions
                                                                        └→ invoices

menu_items → branch_menu_items → order_details
ingredients → branch_ingredients → inventory_transactions
menu_items + ingredients → bom_details
```

## 2. Ý nghĩa từng nhóm bảng

### 2.1 Tài khoản, chi nhánh, ca và kỹ thuật

| Bảng | Fact được lưu |
|---|---|
| `branches` | Chi nhánh, thông tin pháp lý/cấu hình chung |
| `profiles` | Hồ sơ người dùng, PK trùng `auth.users.id` |
| `roles` | Danh mục role dùng chung công ty |
| `staff_assignments` | Một role của một nhân viên tại một chi nhánh; nhiều dòng = nhiều role |
| `audit_logs` | Log append-only, actor và role snapshot tại thời điểm thao tác |
| `notifications` | Thông báo cho profile |
| `outbox_jobs` | Job in bếp/in bill/gửi tích hợp; dùng cho một máy in hiện tại |
| `shifts` | Phiên mở/đóng quầy; một branch chỉ có một shift open |

### 2.2 Hall, reservation và CRM

| Bảng | Fact được lưu |
|---|---|
| `areas` | Khu vực và layout |
| `dining_tables` | Bàn vật lý, sức chứa, trạng thái cleaning/maintenance |
| `customers` | Hồ sơ CRM tối thiểu, điện thoại chuẩn hóa, preferences/consent JSONB |
| `reservations` | Header đặt chỗ, giờ, số khách, cọc, trạng thái; có thể chưa giữ bàn |
| `reservation_tables` | Các bàn được giữ trước check-in |
| `dining_sessions` | Phiên phục vụ thực tế, mode buffet/set_menu, QR và timer |
| `session_guests` | Từng khách, adult/child, package và giá/VAT snapshot |
| `session_tables` | Bàn thực tế trong phiên; dùng cho ghép/chuyển bàn |
| `service_requests` | Gọi nhân viên/nước/than/checkout |
| `customer_feedbacks` | Rating, comment, survey JSONB |

### 2.3 Master, menu, BOM và kho

| Bảng | Fact được lưu |
|---|---|
| `menu_categories` | Danh mục món dùng chung hoặc sở hữu bởi chi nhánh |
| `menu_items` | Định nghĩa món/package dùng chung hoặc cục bộ, chưa chứa giá chi nhánh |
| `branch_menu_items` | Giá, VAT, availability, local name, display/modifier JSONB theo branch |
| `package_details` | Món nào thuộc buffet/set menu, quantity theo khách/giới hạn refill |
| `ingredients` | Định nghĩa nguyên liệu và base unit |
| `branch_ingredients` | Nguyên liệu được dùng ở branch, tồn tối thiểu, default cost |
| `bom_details` | Một món tiêu hao bao nhiêu nguyên liệu, waste rate chuẩn |
| `inventory_transactions` | Ledger nhập/xuất/waste/adjustment; nguồn tính tồn |

### 2.4 Order và bếp

| Bảng | Fact được lưu |
|---|---|
| `orders` | Một lần gửi order từ reception/hall/tablet |
| `order_details` | Từng món, snapshot giá/VAT, số gọi/số tính tiền, trạng thái bếp, hủy và modifier JSONB |

### 2.5 Bill, thanh toán và tài chính

| Bảng | Fact được lưu |
|---|---|
| `vouchers` | Rule voucher của chi nhánh |
| `bills` | Tổng nghĩa vụ thanh toán của một phần/toàn session |
| `bill_details` | Allocation từ order detail hoặc session guest vào một bill |
| `payment_intents` | Ý định thanh toán VietQR/thẻ |
| `payment_attempts` | Từng lần gọi provider và request/response |
| `payments` | Tiền đã capture hoặc refund; cash đi thẳng vào đây |
| `invoices` | E-invoice và snapshot buyer/provider |
| `customer_debt_transactions` | Ledger debt/collection/writeoff/adjustment |
| `cash_expenses` | Chi tiền tại quầy/ca |

### 2.6 Mua hàng và nợ nhà cung cấp

| Bảng | Fact được lưu |
|---|---|
| `suppliers` | Nhà cung cấp theo chi nhánh |
| `purchase_requisitions` / `_details` | Yêu cầu mua và nguyên liệu cần mua |
| `purchase_orders` / `_details` | Đơn đặt NCC, quantity và giá đã chốt |
| `goods_receipts` / `_details` | Hàng thực nhận; `expiry_date` tùy chọn, không phải lot |
| `supplier_payables` | Khoản phải trả từ goods receipt |
| `supplier_payments` | Từng lần trả một payable |

## 3. Đặt bàn trước

### 3.1 Chưa biết bàn

Chỉ tạo `reservations`. Không tạo `reservation_tables`, không nhét danh sách bàn vào `extra_data`.

```text
reservations:
  guest_count = 6
  reserved_from = 18:00
  reserved_to = 20:00
  status = waiting
```

### 3.2 Giữ nhiều bàn

Gọi RPC:

```sql
select public.command_assign_reservation_tables(
  p_reservation_id := 'reservation-uuid',
  p_dining_table_ids := array['table-1-uuid', 'table-2-uuid']::uuid[],
  p_primary_dining_table_id := 'table-1-uuid'
);
```

RPC khóa các bàn theo thứ tự, kiểm tra branch, trạng thái reservation và giao thời gian. Thành công tạo hai `reservation_tables`; thay đổi được ghi vào `audit_logs`. Nếu conflict, toàn bộ transaction rollback.

### 3.3 Check-in, ghép/chuyển bàn

- Tạo `dining_sessions` tham chiếu `reservation_id`.
- Tạo từng `session_guests`.
- Tạo `session_tables` cho bàn thực tế.
- Khi chuyển bàn: đặt `left_at` cho allocation cũ và thêm allocation mới.
- `reservation_tables` là bàn đã hứa trước check-in; `session_tables` là lịch sử bàn thực tế.

### 3.4 Ngoại lệ reservation

| Ngoại lệ | Bảng/RPC |
|---|---|
| Đổi giờ | `reservations`; sau đó gọi lại RPC gán bàn để kiểm tra conflict |
| Hủy/no-show | `reservations.status`; không xóa row |
| Hoàn cọc | `command_refund_payment` → `payments`, cập nhật deposit snapshot |
| Mất cọc | `reservations.deposit_status = forfeited`, audit |
| Một booking nhiều bàn | `reservation_tables` |
| Một bàn bị hai booking giữ cùng giờ | RPC từ chối atomic |

## 4. Buffet/set menu theo khách

Ví dụ session có 3 người:

```text
dining_sessions:
  service_mode = buffet
  guest_count = 3

session_guests:
  guest_no=1, guest_type=adult, package_price=399000
  guest_no=2, guest_type=adult, package_price=399000
  guest_no=3, guest_type=child, package_price=199000
```

Package phải là `branch_menu_items` của đúng branch. Giá/tên/VAT đã snapshot trong `session_guests`, nên đổi giá master sau đó không thay bill cũ.

Set menu dùng cùng cấu trúc; `dining_sessions.service_mode = set_menu`, mỗi guest chọn một `menu_items.item_type = set_menu`.

Món lẻ/đồ uống ngoài package vẫn là `order_details` tính tiền. Vì quyết định hiện hành chỉ có hai session mode, món lẻ không tạo mode `alacarte`; nó là add-on của session.

## 5. Refill và trừ kho

Mỗi refill vẫn tạo order detail:

```text
order_details:
  quantity = 4
  chargeable_quantity = 0
  unit_price_vnd_snapshot = 0
  kitchen_status = served
```

Khi bếp xác nhận đã làm/served, command kho đọc:

```text
branch_menu_items → menu_items → bom_details
                                ↓
ingredients → branch_ingredients → inventory_transactions
```

Mỗi nguyên liệu sinh một `inventory_transactions`:

```text
transaction_type = sale_usage
quantity_delta = -(quantity_thực_làm × BOM × (1 + waste_rate))
reference_type = order_detail
reference_id = order_detail_id
idempotency_key = duy nhất
```

Refill không tăng doanh thu nhưng tăng giá vốn theo số thực làm. Nếu hủy trước khi làm: không trừ. Nếu đã làm rồi bỏ: ghi `waste`, không tự nhập kho lại.

Modifier chỉ lưu JSONB để bếp biết lựa chọn. Modifier không tăng giá và không có BOM độc lập; nếu lựa chọn làm thay đổi giá/BOM thì phải nâng thành menu item/topping thật trước khi triển khai nghiệp vụ đó.

## 6. Split bill atomic

`command_create_split_bill` nhận các nguồn:

- `source_type = session_guest`: tiền package của một khách;
- `source_type = order_detail`: quantity món gọi thêm.

Ví dụ:

```sql
select public.command_create_split_bill(
  p_dining_session_id := 'session-uuid',
  p_shift_id := 'open-shift-uuid',
  p_bill_number := 'BILL-20260724-001',
  p_lines := '[
    {
      "source_type": "session_guest",
      "source_id": "guest-1-uuid",
      "quantity": 1,
      "discount_vnd": 0
    },
    {
      "source_type": "order_detail",
      "source_id": "drink-line-uuid",
      "quantity": 2,
      "discount_vnd": 10000
    }
  ]'::jsonb,
  p_customer_id := 'customer-uuid'
);
```

Trong cùng transaction, RPC:

1. khóa dining session và source rows;
2. kiểm tra tổng quantity đã allocation trên các bill chưa void;
3. tạo `bills`;
4. tạo `bill_details`;
5. tính subtotal, line discount, VAT, service charge và deposit;
6. append `audit_logs`.

Hai request đồng thời không thể bill cùng guest hoặc vượt quantity order. Bill detail bắt buộc tham chiếu đúng một source.

## 7. Giảm giá

- Rule voucher: `vouchers`.
- Voucher được chọn: `bills.voucher_id`.
- Số giảm thực tế theo dòng: `bill_details.discount_vnd`.
- Tổng giảm thực tế: `bills.discount_vnd`, do RPC cộng từ các dòng.
- Phê duyệt/lý do thao tác nhạy cảm: `audit_logs` với role snapshot.
- Hiện một bill chỉ có một voucher; chưa có stack voucher hoặc loyalty allocation.

## 8. Payment, attempt và refund

### 8.1 Tiền mặt

```sql
select public.command_record_cash_payment(
  p_amount_vnd := 500000,
  p_idempotency_key := 'cash:BILL-001:1',
  p_bill_id := 'bill-uuid'
);
```

RPC khóa bill, kiểm tra outstanding và open shift, tạo `payments(payment_method=cash)`, cập nhật `paid_total_vnd/status`.

### 8.2 VietQR/thẻ

```sql
select public.command_create_payment_intent(
  p_amount_vnd := 500000,
  p_payment_method := 'vietqr',
  p_idempotency_key := 'vietqr:BILL-001:1',
  p_bill_id := 'bill-uuid',
  p_provider := 'provider-name'
);
```

Ứng dụng gọi provider ngoài DB. Sau khi nhận kết quả:

```sql
select public.command_record_payment_attempt(
  p_payment_intent_id := 'intent-uuid',
  p_status := 'succeeded',
  p_provider_reference := 'provider-transaction-id',
  p_request_payload := '{}'::jsonb,
  p_response_payload := '{}'::jsonb
);
```

Chỉ attempt `succeeded` mới tạo `payments` và cập nhật bill/reservation. Một intent chỉ capture một lần.

### 8.3 Refund

Provider refund thực hiện ngoài DB trước. Sau khi provider thành công hoặc refund cash đã trả:

```sql
select public.command_refund_payment(
  p_payment_id := 'original-payment-uuid',
  p_amount_vnd := 100000,
  p_idempotency_key := 'refund:original-payment:1',
  p_provider_reference := 'provider-refund-id'
);
```

RPC khóa payment gốc, cộng các refund cũ, từ chối nếu vượt capture, tạo payment loại `refund` và cập nhật bill/cọc.

## 9. Công nợ atomic

Mở nợ:

```sql
select public.command_open_customer_debt(
  p_bill_id := 'bill-uuid',
  p_due_date := current_date + 7,
  p_note := 'Công nợ khách doanh nghiệp'
);
```

RPC lấy toàn bộ outstanding còn lại, tạo `customer_debt_transactions(type=debt)` và cập nhật bill.

Thu nợ:

```sql
select public.command_collect_customer_debt(
  p_bill_id := 'bill-uuid',
  p_amount_vnd := 200000,
  p_payment_method := 'bank_transfer',
  p_idempotency_key := 'collection:BILL-001:1'
);
```

RPC tạo payment + ledger collection và cập nhật `paid_total_vnd`, `debt_total_vnd`, `status` trong cùng transaction.

## 10. Các giới hạn chủ động

- Không có direct table query từ client; mọi read/write phải qua RPC phù hợp.
- Chưa có kho con, lot, FEFO; `expiry_date` không đủ để truy xuất lô.
- Chưa có giá vốn theo batch hoặc BOM version.
- Chưa có printer/station management.
- Chưa có modifier price/BOM.
- Chưa stack voucher, loyalty ledger hoặc general ledger kép.
- Provider call không chạy trong transaction PostgreSQL; DB chỉ commit kết quả.
