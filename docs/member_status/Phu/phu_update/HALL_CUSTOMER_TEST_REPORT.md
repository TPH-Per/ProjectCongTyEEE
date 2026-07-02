# Hall + Customer Test Report

## 1. Static checks

| Check | Result | Evidence / Note |
| --- | --- | --- |
| Migration syntax rollback | Pass | Đã chạy migration trong transaction qua local Postgres/Node pg và rollback OK. |
| Supabase DB lint local | Pass with old warnings | `supabase db lint --local` chạy được. Warning còn lại là warning cũ: `submit_tablet_order` unused param, `update_kitchen_ticket` unused variables, `record_expense_payment` unused variable. |
| Direct-query scan | Pass for scoped new flows | Tablet order/menu/service request, Hall table/service/order/checkout summary đều gọi RPC. Còn direct query ngoài scope: admin menu upsert và close shift. |
| `npm run build` | Fail due existing repo errors | Build fail trước khi Vite build vì lỗi cũ ngoài scope: duplicate locale keys, missing Accounting/BOD/Purchasing composable methods, mock `/customer`, `hall/CheckoutView.vue`. Không thấy lỗi mới ở các file Hall/Tablet đã sửa trong output mới nhất. |

## 2. Functional/business check

| Test case | Expected | Result | Evidence / Note |
| --- | --- | --- | --- |
| Customer xem menu | Menu load đúng qua RPC | Pass by static/RPC check | `TabletOrderView` dùng `useMenu`; `useMenu` gọi `customer_list_menu_categories`, `customer_list_menu_items`. |
| Customer xem thành phần/dị ứng | UI hiển thị ingredients/allergy | Not implemented | RPC trả `ingredients`, `nutrition`, `tags`, nhưng UI tablet chưa có detail screen. |
| Customer add cart | Cart tự tính số lượng, không nhập tổng tiền | Pass by code review | Cart giữ quantity theo item. Tổng tiền không gửi từ frontend. |
| Customer submit order | Order tạo đúng, không duplicate double click | Pass by DB design/code review | `customer_submit_table_order` đọc giá DB, validate session/table, dùng `tablet_order_submissions` idempotency. Chưa E2E runtime. |
| Customer gọi phục vụ | Hall nhận request pending | Pass by code review | `create_service_request` tạo `OPEN`; Hall đọc qua `hall_list_service_requests`. |
| Customer yêu cầu tính tiền | Hall nhận checkout request, customer không tự checkout | Pass by code review | `REQUEST_BILL` tạo service request và set tablet session `CHECKOUT_REQUESTED`. |
| Hall xem bàn | Status bàn rõ qua RPC | Pass by code review | `hall_list_tables` trả table, zone, active order, open requests. |
| Hall nhận request từ tablet | OPEN/IN_PROGRESS/RESOLVED rõ ràng | Pass by code review | `hall_ack_service_request`, `hall_complete_service_request`. |
| Hall gọi món/phục vụ | Order submit qua RPC, không tin frontend price | Pass by code review | `ReceptionOrderView` gọi `hall_submit_table_order`; RPC tự đọc `menu_items.price`. |
| Hall sửa order | Rule hợp lệ, không mất dữ liệu | Not implemented | Cần phase riêng vì ảnh hưởng kitchen/bill/audit. |
| Hall ghép bàn | Không lẫn session/order | Not implemented | Chưa đủ schema/rule, ghi future TODO. |
| Hall tách bill | Tính theo item/quantity, không nhập tay | Not implemented | Chưa đủ schema/rule, ghi future TODO. |
| Hall voucher/discount | Validate qua rule/API nếu có | Partial / Needs review | Flow voucher hiện có được giữ, chưa thiết kế permission/rule engine. |
| Hall checkout | Bill tự tính, payment hợp lệ | Partial pass | Checkout summary qua `hall_get_checkout_summary`; payment/finalize vẫn qua `process_checkout`. Chưa E2E do build fail cũ. |
| Regression CRM | CRM không hỏng | Static only | Không sửa CRM flow trong phase này ngoài dùng chung checkout đã có. Cần E2E sau khi build sạch. |
| Regression Kitchen | Kitchen không hỏng | Static only | Order item status vẫn `Pending`, không rewrite kitchen workflow. |
| Regression Accounting | Accounting không hỏng | Static only | Không sửa Accounting ledger. Build hiện fail do Accounting composable lỗi cũ ngoài scope. |

## 3. Lỗi phát hiện và cách xử lý

- Frontend tablet trước đó gửi order qua Edge Function từng item; đã thay bằng `customer_submit_table_order` một lần cho cả cart.
- Service request trước đó còn direct insert/update; đã thay bằng RPC create/ack/complete.
- Floor plan RPC dùng field lệch schema; đã replace `get_floor_plan` dùng `tables.code`.
- Reception checkout tự ghép order/table/items bằng direct query; đã thay bằng `hall_get_checkout_summary`.
- Reservation composable gọi function/field lệch (`p_guest_count`); đã chỉnh sang `p_guests` và RPC reservation tối thiểu.

## 4. Build blockers ngoài scope

`npm run build` còn fail bởi các lỗi không thuộc Hall/Tablet patch:

- `src/locales/vi.ts` duplicate object keys.
- `src/stores/useLanguageStore.ts` duplicate object keys.
- Accounting views gọi method chưa tồn tại trong composable hiện tại.
- BOD views gọi method/state chưa tồn tại trong composable hiện tại.
- `/customer` mock views có lỗi store/type.
- `src/views/hall/CheckoutView.vue` có lỗi `string | undefined`.
- Purchasing view gọi method chưa tồn tại.

## 5. Checklist

- [x] Đọc code trước khi sửa.
- [x] Customer tablet menu qua RPC.
- [x] Customer order submit qua RPC.
- [x] Không tin price/total từ frontend khi submit order.
- [x] Có idempotency chống double submit.
- [x] Service request có status rõ.
- [x] Hall nhận/ack/complete service request qua RPC.
- [x] Hall table list/floor plan qua RPC.
- [x] Checkout summary tự tính từ DB qua RPC.
- [x] Không làm checkout phụ thuộc CRM.
- [x] DB changes nằm trong migration.
- [x] RLS cho bảng mới.
- [x] SECURITY DEFINER có search_path.
- [x] Ghi docs trong `phu_updated`.
- [ ] Build toàn project pass.
- [ ] E2E browser pass.
- [ ] Sửa order nâng cao.
- [ ] Merge table.
- [ ] Split bill.
- [ ] Voucher/discount permission hoàn chỉnh.
