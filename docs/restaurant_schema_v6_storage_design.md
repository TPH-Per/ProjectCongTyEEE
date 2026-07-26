# NGƯU CÁT POS — DATABASE V6 STORAGE DESIGN

**Trạng thái:** nguồn sự thật hiện hành.  
**DDL thực thi:** `restaurant_schema_v6_simplified.sql`.  
**Phạm vi:** một công ty, nhiều chi nhánh; 46 bảng `public`; PostgreSQL 17/Supabase.

Tài liệu này mô tả dữ liệu cần lưu và ràng buộc cấu trúc. Giao diện, thứ tự màn hình, provider network call và quy tắc chuyển trạng thái chi tiết không phải là bảng dữ liệu. Riêng các thao tác có rủi ro cạnh tranh dữ liệu—giữ nhiều bàn, split bill, payment, refund và công nợ—đi qua command/RPC atomic trong DDL.

## 1. Quyết định thiết kế

### 1.1 Master data dùng chung và cấu hình chi nhánh

Master data dùng mô hình hai lớp:

```text
master dùng chung/cục bộ               cấu hình vận hành tại chi nhánh
menu_categories ─┐
menu_items ──────┴──────────────────→ branch_menu_items
ingredients ────────────────────────→ branch_ingredients
```

- `owner_branch_id IS NULL`: master dùng chung toàn công ty.
- `owner_branch_id = branch_id`: master riêng của một chi nhánh.
- `branch_menu_items` giữ giá, VAT, availability, tên hiển thị và modifier JSONB tại chi nhánh.
- `branch_ingredients` giữ tồn tối thiểu, giá vốn mặc định và trạng thái tại chi nhánh.
- Chứng từ chỉ tham chiếu cấu hình chi nhánh (`branch_menu_item_id`, `branch_ingredient_id`) để không bán/nhập nhầm cấu hình của chi nhánh khác.
- `roles`, `package_details` và `bom_details` là master dùng chung; master cục bộ chỉ được dùng tại chính `owner_branch_id`.

### 1.2 Phân quyền nhiều role

Một nhân viên có thể có nhiều dòng active trong `staff_assignments` tại cùng chi nhánh, miễn là khác `role_id`.

JWT trusted claim nằm trong `app_metadata`:

```json
{
  "branch_id": "uuid",
  "role_codes": ["manager", "reception"]
}
```

Không dùng `user_metadata` để phân quyền. Không tạo role theo tên chi nhánh. Token chỉ mang một `branch_id` active nhưng mang toàn bộ `role_codes` active của nhân viên tại chi nhánh đó.

### 1.3 Buffet và set menu theo từng khách

- `dining_sessions.service_mode` chỉ nhận `buffet` hoặc `set_menu`.
- Một session chỉ có một mode.
- Mỗi khách là một dòng `session_guests`.
- Mỗi khách giữ package tại chi nhánh, loại adult/child, tên package, giá và VAT snapshot.
- Món gọi thêm vẫn nằm trong `order_details`.
- Món included/refill có `chargeable_quantity = 0` nhưng vẫn được ghi order và trừ nguyên liệu khi thực sự chế biến.
- Modifier chỉ là `branch_menu_items.modifier_config` và `order_details.modifiers` JSONB; không có giá/BOM riêng.

### 1.4 Reservation và bàn

`reservations` là header đặt chỗ và có thể chưa giữ bàn. Mỗi bàn giữ trước check-in là một dòng `reservation_tables`. Khi khách check-in, bàn thực tế nằm ở `session_tables`.

Việc gán/đổi nhiều bàn gọi `command_assign_reservation_tables`; RPC khóa các bàn theo thứ tự UUID, kiểm tra chồng thời gian rồi thay allocation trong cùng transaction. `audit_logs` giữ lịch sử thay đổi.

### 1.5 Một quầy thu ngân

Không tạo bảng cash register. Một dòng `shifts` là phiên hoạt động của quầy tại chi nhánh. Partial unique index bảo đảm một chi nhánh chỉ có một shift `open`. Bill và payment tham chiếu shift đó.

### 1.6 Payment

```text
cash ─────────────────────────────────────────→ payments
card / vietqr → payment_intents → payment_attempts → payments khi succeeded
refund ───────────────────────────────────────→ payments liên kết payment gốc
```

Network call đến provider diễn ra ngoài transaction DB. Kết quả được commit bằng RPC atomic. `idempotency_key`, provider reference và khóa row ngăn ghi trùng.

### 1.7 Kho và máy in

- Tồn kho là `SUM(inventory_transactions.quantity_delta)` theo `branch_ingredient_id`.
- Chỉ quản lý một mức chi nhánh/nguyên liệu, không có warehouse, lot hoặc FEFO.
- `goods_receipt_details.expiry_date` là thông tin tùy chọn; không đại diện cho lot.
- Chỉ một máy in; mọi job in dùng `outbox_jobs`. Không có printer/station management.

### 1.8 Audit

`audit_logs` append-only:

- trigger từ chối `UPDATE` và `DELETE`;
- `service_role` không có quyền update/delete/truncate;
- `actor_role_codes_snapshot` bắt buộc và lưu role tại thời điểm thao tác;
- `detail` JSONB chỉ là context, không thay thế fact nghiệp vụ.

## 2. Chuẩn tên và kiểu dữ liệu

- Bảng số nhiều, `snake_case`.
- PK: `<entity>_id`; không dùng `id` trần.
- Bảng con chứng từ: hậu tố `_details`, thứ tự `detail_no`.
- Tiền VND: `bigint` + hậu tố `_vnd`.
- Số món: `numeric(14,3)`; nguyên liệu: `numeric(18,6)`.
- Thời gian: `timestamptz`.
- Trạng thái: `text` + `CHECK`.
- JSONB chỉ cho cấu hình/modifier/payload/evidence/survey; không dùng cho FK, tiền, quantity hoặc status lõi.
- Chứng từ snapshot tên, giá, VAT tại thời điểm phát sinh.

## 3. Danh mục 46 bảng

| Nhóm | Bảng |
|---|---|
| Nền tảng và ca (8) | `branches`, `profiles`, `roles`, `staff_assignments`, `audit_logs`, `notifications`, `outbox_jobs`, `shifts` |
| Hall, reservation, CRM (10) | `areas`, `dining_tables`, `customers`, `reservations`, `reservation_tables`, `dining_sessions`, `session_guests`, `session_tables`, `service_requests`, `customer_feedbacks` |
| Master, package, BOM, kho (8) | `menu_categories`, `menu_items`, `branch_menu_items`, `package_details`, `ingredients`, `branch_ingredients`, `bom_details`, `inventory_transactions` |
| Order và bếp (2) | `orders`, `order_details` |
| Billing và tài chính (9) | `vouchers`, `bills`, `bill_details`, `payment_intents`, `payment_attempts`, `payments`, `invoices`, `customer_debt_transactions`, `cash_expenses` |
| Mua hàng và công nợ NCC (9) | `suppliers`, `purchase_requisitions`, `purchase_requisition_details`, `purchase_orders`, `purchase_order_details`, `goods_receipts`, `goods_receipt_details`, `supplier_payables`, `supplier_payments` |

## 4. ERD V6 — Eraser DSL

```text
// NGUUCAT POS V6 | PostgreSQL/Supabase | 46 public tables

branches {
  branch_id uuid pk
  branch_code string
  branch_name string
  settings jsonb
  is_active boolean
  created_at timestamp
  updated_at timestamp
}
profiles {
  profile_id uuid pk
  full_name string
  phone string
  email string
  preferences jsonb
  account_status string
}
roles {
  role_id uuid pk
  role_code string
  role_name string
  is_active boolean
}
staff_assignments {
  staff_assignment_id uuid pk
  profile_id uuid fk
  branch_id uuid fk
  role_id uuid fk
  approval_pin_hash string
  is_active boolean
  assigned_at timestamp
  ended_at timestamp
}
audit_logs {
  audit_log_id uuid pk
  branch_id uuid fk
  actor_profile_id uuid fk
  actor_role_codes_snapshot string[]
  action_code string
  target_type string
  target_id uuid
  detail jsonb
  correlation_id uuid
  created_at timestamp
}
notifications {
  notification_id uuid pk
  branch_id uuid fk
  target_profile_id uuid fk
  notification_type string
  payload jsonb
  read_at timestamp
  created_at timestamp
}
outbox_jobs {
  outbox_job_id uuid pk
  branch_id uuid fk
  job_type string
  reference_type string
  reference_id uuid
  payload jsonb
  status string
  idempotency_key string
  attempt_count int
  next_attempt_at timestamp
}
shifts {
  shift_id uuid pk
  branch_id uuid fk
  opened_by_profile_id uuid fk
  closed_by_profile_id uuid fk
  opening_cash_vnd bigint
  expected_cash_vnd bigint
  counted_cash_vnd bigint
  variance_cash_vnd bigint
  status string
  opened_at timestamp
  closed_at timestamp
}

areas {
  area_id uuid pk
  branch_id uuid fk
  area_code string
  area_name string
  layout_config jsonb
}
dining_tables {
  dining_table_id uuid pk
  branch_id uuid fk
  area_id uuid fk
  table_code string
  table_name string
  capacity int
  availability_status string
}
customers {
  customer_id uuid pk
  branch_id uuid fk
  full_name string
  normalized_phone string
  profile_data jsonb
  anonymized_at timestamp
}
reservations {
  reservation_id uuid pk
  branch_id uuid fk
  customer_id uuid fk
  guest_name_snapshot string
  phone_snapshot string
  guest_count int
  reserved_from timestamp
  reserved_to timestamp
  deposit_amount_vnd bigint
  deposit_status string
  status string
  extra_data jsonb
}
reservation_tables {
  reservation_table_id uuid pk
  branch_id uuid fk
  reservation_id uuid fk
  dining_table_id uuid fk
  is_primary boolean
}
dining_sessions {
  dining_session_id uuid pk
  branch_id uuid fk
  reservation_id uuid fk
  customer_id uuid fk
  guest_count int
  service_mode string
  service_config jsonb
  course_locked_at timestamp
  service_ends_at timestamp
  qr_token_hash string
  status string
}
session_guests {
  session_guest_id uuid pk
  branch_id uuid fk
  dining_session_id uuid fk
  guest_no int
  guest_type string
  package_branch_menu_item_id uuid fk
  package_name_snapshot string
  package_price_vnd_snapshot bigint
  vat_rate_snapshot numeric
  status string
}
session_tables {
  session_table_id uuid pk
  branch_id uuid fk
  dining_session_id uuid fk
  dining_table_id uuid fk
  is_primary boolean
  joined_at timestamp
  left_at timestamp
}
service_requests {
  service_request_id uuid pk
  branch_id uuid fk
  dining_session_id uuid fk
  request_type string
  status string
  handled_by_profile_id uuid fk
}
customer_feedbacks {
  customer_feedback_id uuid pk
  branch_id uuid fk
  customer_id uuid fk
  dining_session_id uuid fk
  rating int
  survey_data jsonb
}

menu_categories {
  menu_category_id uuid pk
  owner_branch_id uuid fk
  category_code string
  category_name string
  is_active boolean
}
menu_items {
  menu_item_id uuid pk
  owner_branch_id uuid fk
  menu_category_id uuid fk
  item_code string
  item_name string
  item_type string
  unit_name string
  is_active boolean
}
branch_menu_items {
  branch_menu_item_id uuid pk
  branch_id uuid fk
  menu_item_id uuid fk
  local_name string
  base_price_vnd bigint
  vat_rate numeric
  availability_status string
  display_config jsonb
  modifier_config jsonb
}
package_details {
  package_detail_id uuid pk
  package_menu_item_id uuid fk
  included_menu_item_id uuid fk
  detail_no int
  included_quantity_per_guest numeric
  max_quantity_per_order numeric
  is_unlimited boolean
}
ingredients {
  ingredient_id uuid pk
  owner_branch_id uuid fk
  ingredient_code string
  ingredient_name string
  base_unit string
  metadata jsonb
}
branch_ingredients {
  branch_ingredient_id uuid pk
  branch_id uuid fk
  ingredient_id uuid fk
  minimum_stock numeric
  default_cost_vnd bigint
  is_active boolean
}
bom_details {
  bom_detail_id uuid pk
  menu_item_id uuid fk
  ingredient_id uuid fk
  detail_no int
  quantity_in_base_unit numeric
  waste_rate numeric
}
inventory_transactions {
  inventory_transaction_id uuid pk
  branch_id uuid fk
  branch_ingredient_id uuid fk
  transaction_type string
  quantity_delta numeric
  unit_cost_vnd bigint
  reference_type string
  reference_id uuid
  idempotency_key string
  occurred_at timestamp
}

orders {
  order_id uuid pk
  branch_id uuid fk
  dining_session_id uuid fk
  shift_id uuid fk
  order_number string
  order_source string
  status string
}
order_details {
  order_detail_id uuid pk
  branch_id uuid fk
  order_id uuid fk
  detail_no int
  branch_menu_item_id uuid fk
  item_name_snapshot string
  quantity numeric
  chargeable_quantity numeric
  unit_price_vnd_snapshot bigint
  vat_rate_snapshot numeric
  detail_total_vnd bigint
  kitchen_status string
  modifiers jsonb
  cancelled_quantity numeric
}

vouchers {
  voucher_id uuid pk
  branch_id uuid fk
  voucher_code string
  discount_type string
  discount_value numeric
  conditions jsonb
  valid_from timestamp
  valid_to timestamp
}
bills {
  bill_id uuid pk
  branch_id uuid fk
  dining_session_id uuid fk
  shift_id uuid fk
  customer_id uuid fk
  voucher_id uuid fk
  bill_number string
  subtotal_vnd bigint
  discount_vnd bigint
  vat_vnd bigint
  deposit_applied_vnd bigint
  grand_total_vnd bigint
  paid_total_vnd bigint
  debt_total_vnd bigint
  status string
}
bill_details {
  bill_detail_id uuid pk
  branch_id uuid fk
  bill_id uuid fk
  detail_no int
  order_detail_id uuid fk
  session_guest_id uuid fk
  item_name_snapshot string
  quantity numeric
  unit_price_vnd bigint
  discount_vnd bigint
  vat_vnd bigint
  detail_total_vnd bigint
}
payment_intents {
  payment_intent_id uuid pk
  branch_id uuid fk
  bill_id uuid fk
  reservation_id uuid fk
  shift_id uuid fk
  payment_method string
  amount_vnd bigint
  status string
  idempotency_key string
  provider string
  provider_intent_reference string
  qr_payload string
}
payment_attempts {
  payment_attempt_id uuid pk
  branch_id uuid fk
  payment_intent_id uuid fk
  attempt_no int
  status string
  provider_reference string
  request_payload jsonb
  response_payload jsonb
}
payments {
  payment_id uuid pk
  branch_id uuid fk
  bill_id uuid fk
  reservation_id uuid fk
  payment_intent_id uuid fk
  shift_id uuid fk
  related_payment_id uuid fk
  transaction_type string
  payment_method string
  amount_vnd bigint
  idempotency_key string
}
invoices {
  invoice_id uuid pk
  branch_id uuid fk
  bill_id uuid fk
  related_invoice_id uuid fk
  invoice_type string
  provider_status string
  buyer_snapshot jsonb
  provider_payload jsonb
}
customer_debt_transactions {
  customer_debt_transaction_id uuid pk
  branch_id uuid fk
  customer_id uuid fk
  bill_id uuid fk
  payment_id uuid fk
  transaction_type string
  amount_vnd bigint
  due_date date
}
cash_expenses {
  cash_expense_id uuid pk
  branch_id uuid fk
  shift_id uuid fk
  expense_code string
  amount_vnd bigint
  status string
  evidence jsonb
}

suppliers {
  supplier_id uuid pk
  branch_id uuid fk
  supplier_code string
  supplier_name string
  payment_terms_days int
}
purchase_requisitions {
  purchase_requisition_id uuid pk
  branch_id uuid fk
  requisition_number string
  status string
}
purchase_requisition_details {
  purchase_requisition_detail_id uuid pk
  branch_id uuid fk
  purchase_requisition_id uuid fk
  branch_ingredient_id uuid fk
  detail_no int
  requested_quantity numeric
}
purchase_orders {
  purchase_order_id uuid pk
  branch_id uuid fk
  purchase_requisition_id uuid fk
  supplier_id uuid fk
  purchase_order_number string
  status string
}
purchase_order_details {
  purchase_order_detail_id uuid pk
  branch_id uuid fk
  purchase_order_id uuid fk
  branch_ingredient_id uuid fk
  detail_no int
  ordered_quantity numeric
  unit_cost_vnd bigint
}
goods_receipts {
  goods_receipt_id uuid pk
  branch_id uuid fk
  purchase_order_id uuid fk
  supplier_id uuid fk
  receipt_number string
  status string
}
goods_receipt_details {
  goods_receipt_detail_id uuid pk
  branch_id uuid fk
  goods_receipt_id uuid fk
  purchase_order_detail_id uuid fk
  branch_ingredient_id uuid fk
  detail_no int
  received_quantity numeric
  unit_cost_vnd bigint
  expiry_date date
}
supplier_payables {
  supplier_payable_id uuid pk
  branch_id uuid fk
  supplier_id uuid fk
  goods_receipt_id uuid fk
  original_amount_vnd bigint
  paid_amount_vnd bigint
  status string
}
supplier_payments {
  supplier_payment_id uuid pk
  branch_id uuid fk
  supplier_payable_id uuid fk
  supplier_id uuid fk
  shift_id uuid fk
  amount_vnd bigint
  payment_method string
}

staff_assignments.profile_id > profiles.profile_id
staff_assignments.branch_id > branches.branch_id
staff_assignments.role_id > roles.role_id
areas.branch_id > branches.branch_id
dining_tables.area_id > areas.area_id
reservations.customer_id > customers.customer_id
reservation_tables.reservation_id > reservations.reservation_id
reservation_tables.dining_table_id > dining_tables.dining_table_id
dining_sessions.reservation_id > reservations.reservation_id
dining_sessions.customer_id > customers.customer_id
session_guests.dining_session_id > dining_sessions.dining_session_id
session_guests.package_branch_menu_item_id > branch_menu_items.branch_menu_item_id
session_tables.dining_session_id > dining_sessions.dining_session_id
session_tables.dining_table_id > dining_tables.dining_table_id
menu_categories.owner_branch_id > branches.branch_id
menu_items.owner_branch_id > branches.branch_id
menu_items.menu_category_id > menu_categories.menu_category_id
branch_menu_items.menu_item_id > menu_items.menu_item_id
branch_menu_items.branch_id > branches.branch_id
package_details.package_menu_item_id > menu_items.menu_item_id
package_details.included_menu_item_id > menu_items.menu_item_id
ingredients.owner_branch_id > branches.branch_id
branch_ingredients.ingredient_id > ingredients.ingredient_id
bom_details.menu_item_id > menu_items.menu_item_id
bom_details.ingredient_id > ingredients.ingredient_id
inventory_transactions.branch_ingredient_id > branch_ingredients.branch_ingredient_id
orders.dining_session_id > dining_sessions.dining_session_id
order_details.order_id > orders.order_id
order_details.branch_menu_item_id > branch_menu_items.branch_menu_item_id
bills.dining_session_id > dining_sessions.dining_session_id
bill_details.bill_id > bills.bill_id
bill_details.order_detail_id > order_details.order_detail_id
bill_details.session_guest_id > session_guests.session_guest_id
payment_intents.bill_id > bills.bill_id
payment_intents.reservation_id > reservations.reservation_id
payment_attempts.payment_intent_id > payment_intents.payment_intent_id
payments.bill_id > bills.bill_id
payments.reservation_id > reservations.reservation_id
payments.payment_intent_id > payment_intents.payment_intent_id
payments.related_payment_id > payments.payment_id
invoices.bill_id > bills.bill_id
customer_debt_transactions.bill_id > bills.bill_id
purchase_requisition_details.purchase_requisition_id > purchase_requisitions.purchase_requisition_id
purchase_order_details.purchase_order_id > purchase_orders.purchase_order_id
goods_receipt_details.goods_receipt_id > goods_receipts.goods_receipt_id
supplier_payables.goods_receipt_id > goods_receipts.goods_receipt_id
supplier_payments.supplier_payable_id > supplier_payables.supplier_payable_id
```

## 5. Ràng buộc quan trọng

- Mọi bảng vận hành có `branch_id`; composite FK ngăn liên kết chéo chi nhánh.
- Một profile có tối đa một assignment active cho mỗi `(branch_id, role_id)`.
- Một chi nhánh có tối đa một shift `open`.
- Một bàn chỉ thuộc một session active (`session_tables.left_at IS NULL`).
- Một reservation có nhiều bàn nhưng không lặp bàn; tối đa một bàn primary.
- Một reservation sinh tối đa một dining session.
- Mỗi session guest có `guest_no` duy nhất trong session.
- Bill detail tham chiếu đúng một nguồn: `order_detail_id` hoặc `session_guest_id`.
- Payment/intent tham chiếu đúng một target: bill hoặc reservation.
- Một payment intent chỉ sinh tối đa một payment capture.
- Refund bắt buộc tham chiếu payment gốc; tổng refund được RPC khóa và kiểm tra không vượt capture.
- Audit log không được update/delete.
- Tất cả 46 bảng bật và force RLS; authenticated không có quyền table trực tiếp.

## 6. Atomic command/RPC

| RPC | Mục đích |
|---|---|
| `command_assign_reservation_tables` | Khóa bàn, kiểm tra thời gian, gán/đổi nhiều bàn và audit |
| `command_create_split_bill` | Khóa session/source line, kiểm tra tổng allocation, tạo bill + details + audit |
| `command_record_cash_payment` | Thu tiền mặt cho bill hoặc cọc reservation và cập nhật tổng |
| `command_create_payment_intent` | Tạo intent VietQR/thẻ idempotent |
| `command_record_payment_attempt` | Ghi attempt; attempt thành công tạo payment và cập nhật target |
| `command_refund_payment` | Khóa payment, kiểm tra tổng hoàn, tạo refund và cập nhật target |
| `command_open_customer_debt` | Chuyển outstanding của bill thành debt ledger |
| `command_collect_customer_debt` | Thu nợ, tạo payment + collection ledger và cập nhật bill |

Các RPC là `SECURITY DEFINER`, `search_path = ''`, tự kiểm tra `auth.uid()`, `branch_id`, `role_codes`; đã revoke khỏi `PUBLIC`/`anon` và chỉ grant `EXECUTE` cho `authenticated`.

## 7. Nội dung không còn dùng

- Không có `reservations.dining_table_id`; dùng `reservation_tables`.
- Không có `dining_sessions.package_menu_item_id`; package nằm theo từng `session_guests`.
- Không có mode `alacarte` tại session; món bán lẻ là order thêm trong buffet/set menu.
- Không dùng một `role_code` trong JWT; dùng `role_codes[]`.
- Không cho authenticated đọc/ghi bảng trực tiếp; dùng RPC.
- Không dùng `buffet_package_details`; tên hiện hành là `package_details` để dùng chung buffet/set menu.
- Không có printer/station, modifier master, warehouse, lot, FEFO hoặc permission matrix.
