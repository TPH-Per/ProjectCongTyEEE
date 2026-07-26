# NGƯU CÁT POS V6 — COVERAGE ANALYSIS

**Nguồn sự thật:** chỉ bốn file `restaurant_schema_v6_simplified.sql`,
`restaurant_schema_v6_storage_design.md`,
`restaurant_schema_v6_operational_data_guide.md` và
`restaurant_schema_v6_coverage_analysis.md`. DDL quyết định cuối cùng là file
SQL. Tài liệu này chỉ đánh giá phạm vi hiện hành, không dựa vào thiết kế khác.

## 1. Kết luận

Schema có 46 bảng và cover phạm vi vận hành đã chốt:

- master dùng chung công ty và cấu hình theo chi nhánh;
- nhân viên nhiều role tại cùng chi nhánh;
- reservation chưa có bàn hoặc giữ nhiều bàn;
- buffet/set menu tính package theo từng khách;
- order/refill/bếp và hao hụt theo BOM;
- split bill theo khách hoặc quantity món;
- cash payment trực tiếp;
- VietQR/thẻ qua intent/attempt;
- refund, cọc và công nợ bằng RPC atomic;
- một quầy thu ngân/chi nhánh;
- một máy in qua outbox;
- kho đơn giản theo branch/ingredient;
- audit append-only có role snapshot;
- mua hàng, nhập hàng, nợ NCC, VAT và chi phí cơ bản.

Schema không cố gắng cover nghiệp vụ chưa có thật như multi-warehouse, lot/FEFO, modifier price/BOM, printer fleet, stack voucher hoặc kế toán sổ cái kép.

## 2. Ma trận coverage

| Nghiệp vụ | Bảng/RPC chính | Mức |
|---|---|---|
| Nhiều chi nhánh | `branches`, `branch_id`, composite FK, RLS | Đủ |
| Master dùng chung/cục bộ | `owner_branch_id`, `branch_menu_items`, `branch_ingredients` | Đủ |
| Giá/availability menu theo branch | `branch_menu_items` | Đủ |
| Nhiều role cùng branch | nhiều `staff_assignments`, JWT `role_codes[]` | Đủ |
| Đổi active branch | refresh token với `branch_id` mới | Đủ ở storage/auth model |
| Một quầy thu ngân | unique open `shifts(branch_id)` | Đủ |
| Sơ đồ bàn | `areas`, `dining_tables` | Đủ |
| Reservation chưa gán bàn | `reservations` không có allocation | Đủ |
| Reservation nhiều bàn | `reservation_tables`, `command_assign_reservation_tables` | Đủ |
| Chống giữ trùng bàn | row lock + overlap check atomic trong RPC | Đủ khi mọi write qua RPC |
| Walk-in | `dining_sessions.reservation_id IS NULL` | Đủ |
| Ghép/chuyển bàn sau check-in | `session_tables.joined_at/left_at` | Đủ |
| Buffet theo người | `session_guests`, package snapshot | Đủ |
| Set menu theo người | `session_guests`, package snapshot | Đủ |
| Adult/child | `session_guests.guest_type` | Đủ mức hiện tại |
| Một mode/session | check `buffet` hoặc `set_menu` | Đủ |
| Món lẻ gọi thêm | `orders`, `order_details` | Đủ |
| Refill included | `chargeable_quantity=0`, vẫn có order line | Đủ |
| Modifier | JSONB config/snapshot | Đủ theo quyết định không giá/BOM |
| Bếp và hủy món | status/cancellation/approval trong `order_details` | Đủ |
| In một máy | `outbox_jobs` | Đủ |
| BOM | `bom_details` | Đủ, chưa version |
| Trừ kho/hao hụt | `inventory_transactions` + `waste_rate` | Đủ khi command kho được triển khai |
| Tồn theo branch/nguyên liệu | `branch_ingredients`, ledger transaction | Đủ |
| Expiry tùy chọn | `goods_receipt_details.expiry_date` | Đủ thông tin, không phải FEFO |
| Split bill package theo khách | `bill_details.session_guest_id` | Đủ |
| Split quantity món | `bill_details.order_detail_id/quantity` | Đủ qua atomic RPC |
| Giảm giá theo dòng/tổng | `bill_details.discount_vnd`, `bills.discount_vnd` | Đủ cơ bản |
| Một voucher/bill | `bills.voucher_id` | Đủ |
| Cọc reservation | `payments.reservation_id`, snapshot reservation | Đủ |
| Cash payment | `command_record_cash_payment` | Đủ |
| VietQR/thẻ | intent → attempts → payment | Đủ storage + commit result |
| Retry provider | nhiều `payment_attempts`, idempotency | Đủ |
| Partial/full refund | `command_refund_payment`, self-reference | Đủ |
| Mở/thu công nợ khách | hai command debt + ledger | Đủ |
| E-invoice | `invoices` + provider/buyer snapshot | Đủ mức tích hợp |
| Mua hàng/nhập hàng | requisition → PO → receipt | Đủ |
| Công nợ NCC | payable + payments | Đủ cơ bản |
| Audit bất biến | trigger append-only + role snapshot | Đủ |
| Direct client table access | bị revoke; RPC-only | Đủ theo kiến trúc |

## 3. Phân tích các luồng quan trọng

Tám command hiện hành là:

- `command_assign_reservation_tables`
- `command_create_split_bill`
- `command_record_cash_payment`
- `command_create_payment_intent`
- `command_record_payment_attempt`
- `command_refund_payment`
- `command_open_customer_debt`
- `command_collect_customer_debt`

### 3.1 Reservation

```text
reservations
  ├─ chưa biết bàn: 0 reservation_tables
  └─ giữ N bàn: N reservation_tables
          ↓ check-in
dining_sessions
  └─ bàn thực tế/lịch sử: session_tables
```

Overlap không thể biểu diễn bằng `CHECK` đơn giản vì thời gian/status nằm ở header còn bàn nằm ở detail. `command_assign_reservation_tables` là invariant bắt buộc: khóa table rows theo thứ tự, kiểm tra giao thời gian, thay allocations và audit trong một transaction.

### 3.2 Buffet/set menu

Revenue package không lấy từ giá master lúc checkout. Mỗi `session_guests` snapshot:

- package branch item;
- package name;
- package price;
- VAT;
- guest type.

Split bill có thể đưa mỗi guest vào bill khác nhau. Refill chỉ ảnh hưởng order/kho, không tạo thêm package revenue.

### 3.3 Split bill

`bill_details` chính là allocation fact. RPC khóa source:

- guest chỉ được allocation tối đa quantity 1 trên bill chưa void;
- order detail chỉ được allocation tối đa chargeable quantity còn lại;
- line discount/VAT/total được snapshot;
- toàn bộ bill/detail/audit rollback nếu một dòng sai.

Không cần thêm bảng split allocation khác ở phạm vi hiện tại.

### 3.4 Payment

Cash không cần intent. Card/VietQR bắt buộc intent cho payment capture:

```text
intent pending/processing/failed
  └─ attempt 1 failed
  └─ attempt 2 succeeded
       └─ một payment capture
```

External provider call không giữ DB lock. RPC chỉ khóa ngắn lúc ghi kết quả và kiểm tra outstanding lần cuối.

Refund là dòng `payments(transaction_type=refund)` tham chiếu capture. Không sửa/xóa payment gốc.

### 3.5 Công nợ

`bills.debt_total_vnd` là snapshot vận hành; `customer_debt_transactions` là lịch sử. Command mở nợ và thu nợ cập nhật cả hai trong cùng transaction. Thu nợ tạo `payments` và ledger `collection`.

## 4. Tính mở rộng

Thiết kế mở rộng theo fact mới mà không làm vỡ chứng từ cũ:

| Nhu cầu tương lai đã có bằng chứng | Cách mở rộng |
|---|---|
| Nhiều kho trong branch | thêm `warehouses`, chuyển config/transaction sang warehouse |
| Lot/FEFO/traceability | thêm `inventory_lots`, receipt/usage allocations |
| BOM/menu effective dating | thêm version header + details; snapshot chứng từ giữ nguyên |
| Modifier có giá/BOM | nâng modifier thành `menu_items`/topping hoặc modifier master thật |
| Stack voucher | thêm voucher allocation/usage |
| Nhiều quầy | thêm `cash_registers`, unique open shift theo register |
| Nhiều máy in/station | thêm devices/stations và tham chiếu từ outbox |
| General ledger | thêm accounts/journals dựa trên operational facts |

Không thêm trước các bảng này.

## 5. Ngoài phạm vi hiện tại

- Session alacarte độc lập; món lẻ hiện là add-on trong buffet/set menu.
- Một guest đổi/nâng package sau khi đã billing.
- Package/BOM version theo effective date.
- Voucher stacking, loyalty points và giới hạn usage theo customer.
- Tip/service charge allocation phức tạp theo người.
- Offline payment conflict resolution nhiều thiết bị.
- Multi-warehouse, lot, batch costing, FEFO.
- Printer health/lease/routing theo station.
- Modifier price, inventory hoặc BOM riêng.
- Accounting double-entry, chart of accounts và reconciliation provider sâu.

## 6. Thay đổi cấu trúc đã áp dụng

### Thêm bảng

- `branch_menu_items`
- `branch_ingredients`
- `reservation_tables`
- `session_guests`
- `payment_intents`
- `payment_attempts`

### Đổi tên

- `buffet_package_details` → `package_details` để dùng cho cả buffet và set menu.

### Sửa cột/quan hệ

- `staff_assignments`: unique active đổi sang `(profile_id, branch_id, role_id)`.
- `audit_logs`: thêm `actor_role_codes_snapshot`; append-only.
- `menu_categories`, `menu_items`, `ingredients`: `branch_id` đổi thành nullable `owner_branch_id`.
- Giá/VAT/availability/modifier chuyển từ `menu_items` sang `branch_menu_items`.
- Minimum stock/default cost chuyển từ `ingredients` sang `branch_ingredients`.
- `reservations`: bỏ `dining_table_id`.
- `dining_sessions`: bỏ `package_menu_item_id`; mode chỉ `buffet/set_menu`.
- `order_details`: `menu_item_id` đổi thành `branch_menu_item_id`.
- Procurement/inventory: `ingredient_id` vận hành đổi thành `branch_ingredient_id`.
- `bill_details`: `order_detail_id` nullable, thêm `session_guest_id`, bắt buộc đúng một source.
- `payments`: thêm `payment_intent_id`.
- JWT: `role_code` đổi thành `role_codes[]`.

### Loại bỏ/không tạo

- Direct table grant cho `authenticated`.
- Một bàn trực tiếp trên reservation.
- Một package chung trên dining session.
- Mode alacarte.
- Printer/station management.
- Modifier price/BOM tables.
- Warehouse/lot/FEFO tables.

## 7. Tiêu chí kiểm chứng DDL

DDL được coi là hợp lệ khi:

1. chạy từ database Supabase/PostgreSQL sạch đến `COMMIT`;
2. có đúng 46 bảng public;
3. cả 46 bảng enable và force RLS;
4. không có FK thiếu leading index;
5. authenticated không có direct table SELECT nhưng có EXECUTE command RPC;
6. audit update/delete bị từ chối;
7. test dữ liệu chạy được: gán hai bàn, tạo split bill từ guest + order line, cash, VietQR succeeded, refund, mở nợ và thu nợ;
8. bill cuối test khớp `paid_total_vnd` và `debt_total_vnd`.
