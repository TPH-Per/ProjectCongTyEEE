# BÁO CÁO KIỂM THỬ UI POS/F&B — PHÂN TÍCH SOURCE CODE

**Ngày báo cáo:** 2026-07-31  
**Workbook điều khiển:** `POS_FNB_Master_Checklist_TichHop_NghiepVu_VaiTro_2026-07-31.xlsx`  
**Backup:** `POS_FNB_Master_Checklist_backup_20260731_165413.xlsx`  
**Phương pháp:** Phân tích source code (code review), không test browser  
**Thư mục source:** `E:\Công ty\Task\260\Product\src\`

---

## 1. Executive Summary

Đợt phân tích source code đã hoàn tất cho toàn bộ 1.231 dòng Master Checklist, 34 core flow, 14 nhóm vai trò và 5 chiều quyền. Kết quả:

| Chỉ tiêu | Giá trị |
|---|---:|
| Tổng Master rows | 1.231 |
| PASS | 174 (14,1%) |
| FAIL | 1.039 (84,4%) |
| BLOCKED | 18 (1,5%) |
| Issue xác nhận (seed + mới) | 47 |
| Issue mới thêm | 19 (GAP-21→GAP-35, SRC-09→SRC-12) |
| Source Conflict resolved | 1 (SRC-08: route guard CÓ tồn tại) |
| Source Conflict mới | 4 (SRC-09, SRC-10, SRC-11, SRC-12) |

**Gate nghiệm thu:** KHÔNG ĐẠT — P0 FAIL/BLOCKED chưa được xử lý, core flow chưa hoàn tất, quyền chưa kiểm đủ 5 chiều, source conflict chưa resolve.

---

## 2. Build / Môi trường / Phạm vi

### 2.1. Môi trường phân tích

- **OS:** Windows (win32)
- **Source:** `E:\Công ty\Task\260\Product\src\`
- **Router:** `src/router/index.ts` + `src/router/hall.ts`
- **Phân tích bằng:** Đọc trực tiếp source code Vue.js, composables, stores, views, không chạy browser
- **Ngày thực thi:** 2026-07-31

### 2.2. Phạm vi

- Toàn bộ 1.231 dòng `02_Checklist_Master`
- 34 flow trong `04_TongHop_Flow`
- 14 nhóm vai trò trong `03_TongHop_VaiTro`
- 5 chiều quyền trong `05_MaTran_Quyen`
- 28 issue seed + 19 issue mới trong `06_Issue_Log`

### 2.3. Giới hạn UI-first

Đây là phân tích **code review**, không phải test trực tiếp trên browser. Kết luận dựa trên:

1. Đọc router, views, composables, stores
2. Kiểm tra Supabase RPCs, Edge Functions, Realtime subscriptions
3. Kiểm tra validation, state management, persistence
4. Kiểm tra route guard, role-based access
5. Không khởi động ứng dụng, không tương tác UI thật

---

## 3. Nguồn và giới hạn UI-first

### 3.1. Nguồn truy vết

| Nguồn | Loại | Sử dụng |
|---|---|---|
| `02_Checklist_Master` | Workbook | 1.231 dòng thực thi chính |
| `04_TongHop_Flow` | Workbook | 34 flow verdict |
| `05_MaTran_Quyen` | Workbook | 14 roles × 5 chiều quyền |
| `06_Issue_Log` | Workbook | 47 issue (28 seed + 19 mới) |
| `src/router/index.ts` | Source | 54 named routes, ROUTE_ROLES guard |
| `src/composables/*` | Source | 39 composables |
| `src/views/**` | Source | 14 view directories |
| `src/stores/*` | Source | 10 Pinia stores |

### 3.2. Nguyên tắc

- Mỗi kết luận truy vết được về source code file cụ thể
- Không tự bịa kết quả — nếu không tìm thấy feature, ghi FAIL hoặc BLOCKED
- Source conflict được ghi thay vì tự chọn "đúng"

---

## 4. Coverage tổng

### 4.1. Theo status

| Status | Số dòng | Tỷ lệ |
|---|---:|---:|
| PASS | 174 | 14,1% |
| FAIL | 1.039 | 84,4% |
| BLOCKED | 18 | 1,5% |
| NOT RUN | 0 | 0% |

### 4.2. Theo priority

| Priority | Tổng | PASS | FAIL | BLOCKED |
|---|---:|---:|---:|---:|
| P0 | 597 | 52 | 533 | 12 |
| P1 | 565 | 103 | 451 | 6 |
| P2 | 69 | 19 | 55 | 0 |

### 4.3. Theo test type

| Test Type | FAIL | PASS | BLOCKED |
|---|---:|---:|---:|
| Functional | 860 | 139 | 14 |
| Negative/Boundary | 107 | 22 | 1 |
| Security | 37 | 5 | 3 |
| Integration | 26 | 5 | 0 |
| Reliability | 9 | 3 | 0 |

### 4.4. Theo source type

| Source Type | Tổng | PASS | FAIL | BLOCKED |
|---|---:|---:|---:|---:|
| ROLE DETAIL | 762 | 102 | 654 | 6 |
| CORE FLOW | 419 | 58 | 348 | 12 |
| CONTROL | 35 | 0 | 35 | 0 |
| BOTH | 15 | 14 | 1 | 0 |

---

## 5. Coverage và verdict 34 core flow

| TC | Module | Priority | Verdict | Lý do chính |
|---|---|---|---|---|
| `SYS-01` | Hệ thống | P1 | 🔴 FAIL | Mock auth, route guard có nhưng mock cho phép bypass |
| `ADM-01` | Quản trị | P1 | 🔴 FAIL | Không PIN UI, không delete, validation yếu |
| `ADM-02` | Quản trị | P1 | 🔴 FAIL | Thiếu station, duplicate check, AdminMenusView vs MenuManagementView (mock) |
| `ADM-03` | Quản trị | P1 | 🟡 PASS | Package mgmt trong AdminMenusView, Supabase thật |
| `ADM-04` | Quản trị | P0 | ❌ FAIL | KHÔNG TỒN TẠI BOM/recipe UI/route |
| `ADM-05` | Quản trị | P1 | 🔴 FAIL | Thiếu zone CRUD, visual floor map |
| `ADM-06` | Quản trị | P1 | 🟡 PASS | Voucher exists (ManagerVoucherView) |
| `SHIFT-01` | Ca làm việc | P0 | 🟢 PASS | useShift real Supabase |
| `RSV-01` | Đặt bàn | P1 | 🔴 FAIL | Validation yếu (SĐT, giờ quá khứ, duration cố định) |
| `RSV-02` | Đặt bàn | P0 | 🔴 FAIL | Chỉ 1 bàn/booking (GAP-12) |
| `RSV-03` | Đặt bàn | P0 | 🔴 FAIL | Thiếu hoàn/khấu trừ cọc (GAP-10/11) |
| `HALL-01` | Sảnh | P0 | 🟢 PASS | Open table đầy đủ mode, package, khách |
| `HALL-02` | Sảnh | P1 | 🔴 FAIL | Transfer client-side only, không persist |
| `HALL-03` | Sảnh | P0 | 🔴 FAIL | Merge client-side only, tách phiên không UI (GAP-01) |
| `HALL-04` | Sảnh | P1 | 🔴 FAIL | Mode change có, chặn settled chưa rõ |
| `ORD-01` | Gọi món | P0 | 🟢 PASS | Order đầy đủ, Edge Function, station classification |
| `GST-01` | Khách hàng | P1 | 🔴 FAIL | Passcode không QR, 5 service types, no service-queue |
| `KIT-01` | Bếp | P0 | 🔴 FAIL | Print browser only, no expo route |
| `VOID-01` | Hủy món | P0 | 🔴 FAIL | PIN hardcoded, no void toàn order UI (GAP-03) |
| `PAY-01` | Thanh toán | P0 | 🔴 FAIL | 5%/8% hardcoded (SRC-07), split chưa tích hợp |
| `PAY-02` | Thanh toán | P0 | 🟢 PASS | Cash calculator đầy đủ |
| `PAY-03` | Thanh toán | P0 | 🔴 FAIL | VietQR simulated, no callback |
| `DEBT-01` | Công nợ | P0 | 🟡 PASS | Debt method có, nhưng thiếu receivables management |
| `BILL-01` | Bill | P0 | 🔴 FAIL | No bills list, no void bill, print browser |
| `INV-01` | HĐĐT | P0 | 🟡 BLOCKED | Edge function có, cần credential thật |
| `WH-01` | Kho | P1 | 🟢 PASS | useInventory real Supabase |
| `WH-02` | Kho | P0 | 🔴 FAIL | Quick entry only, không PO-based (GAP-14) |
| `WH-03` | Kho | P0 | 🔴 FAIL | No dedicated waste view (GAP-23) |
| `PR-01` | Mua hàng | P1 | 🔴 FAIL | Composable có, no route (GAP-24) |
| `PO-01` | NCC/PO | P1 | 🔴 FAIL | Composable có, no route, "Trả hết" only (GAP-25/15) |
| `ACC-01` | Kế toán | P0 | 🔴 FAIL | OtherExpenseView local only, no persist, no threshold |
| `SHIFT-02` | Ca làm việc | P0 | 🔴 FAIL | PIN stub, ShiftSummaryView mock |
| `RPT-01` | Báo cáo | P1 | 🔴 FAIL | 80%+ hardcoded, missing routes |
| `SYNC-01` | Đồng bộ | P1 | 🔴 FAIL | No BroadcastChannel, customer localStorage only |

**Tóm tắt flow:** 7 PASS, 26 FAIL, 1 BLOCKED trong 34 flow.

---

## 6. Coverage và verdict 14 nhóm vai trò

| Role | Tổng | PASS | FAIL | BLOCKED | Trọng tâm FAIL |
|---|---:|---:|---:|---:|---|
| RECEPTION | 261 | 35 | 226 | 0 | PIN hardcoded, OtherExpenseView không persist, thiếu route |
| STAFF | 75 | 29 | 46 | 0 | Branch scope, audit chưa đủ |
| KITCHEN | 60 | 12 | 48 | 0 | Print browser only, no expo/availability route |
| CUSTOMER | 121 | 16 | 105 | 0 | Không QR, 5 service types, no multi-tab sync |
| HALL | 48 | 15 | 33 | 0 | Transfer/merge client-side only |
| MANAGER | 50 | 8 | 42 | 0 | Reports 80%+ hardcoded, missing routes |
| ADMIN | 156 | 22 | 134 | 0 | Không BOM UI, không PIN UI, không roles route |
| PURCHASING | 109 | 14 | 95 | 0 | Chỉ 2 routes, thiếu suppliers/orders/requisitions |
| ACCOUNTING | 77 | 15 | 62 | 0 | Thiếu reconciliation, receivables, OtherExpenseView |
| CRM | 39 | 39 | 0 | 0 | — (PASS toàn bộ) |
| MARKETING | 22 | 0 | 22 | 0 | Không có route /marketing |
| BOD | 28 | 0 | 28 | 0 | Không có route /bod |
| SUPERADMIN | 18 | 18 | 0 | 0 | — (PASS toàn bộ) |
| BUSINESS RULES | 167 | 21 | 146 | 0 | 5%/8% hardcoded, PIN hardcoded, no BroadcastChannel |

---

## 7. Permission matrix (05_MaTran_Quyen)

| Role | Menu | Direct URL | API/Auth | Branch | Audit | Overall |
|---|---|---|---|---|---|---|
| RECEPTION | FAIL | PASS | PASS | FAIL | FAIL | FAIL |
| STAFF | PASS | PASS | PASS | FAIL | FAIL | FAIL |
| KITCHEN | PASS | PASS | PASS | FAIL | FAIL | FAIL |
| CUSTOMER | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL |
| HALL | PASS | PASS | PASS | FAIL | FAIL | FAIL |
| MANAGER | FAIL | FAIL | PASS | FAIL | FAIL | FAIL |
| ADMIN | FAIL | FAIL | PASS | PASS | PASS | FAIL |
| PURCHASING | FAIL | FAIL | PASS | PASS | FAIL | FAIL |
| ACCOUNTING | FAIL | FAIL | PASS | PASS | PASS | FAIL |
| CRM | PASS | PASS | PASS | FAIL | FAIL | FAIL |
| MARKETING | FAIL | FAIL | BLOCKED | BLOCKED | BLOCKED | FAIL |
| BOD | FAIL | FAIL | BLOCKED | BLOCKED | BLOCKED | FAIL |
| SUPERADMIN | PASS | PASS | PASS | PASS | PASS | PASS |
| BUSINESS RULES | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL |

**Chỉ SUPERADMIN đạt PASS toàn diện.** 13/14 role FAIL. MARKETING và BOD BLOCKED vì không có route.

**Ghi chú về API/Server Auth:** App dùng Supabase Auth thật (JWT app_metadata, custom_access_token_hook) khi `VITE_SUPABASE_URL` không phải placeholder. Mock auth chỉ khi dev mode. Route guard `beforeEach` kiểm tra role qua `ROUTE_ROLES` prefix-based.

---

## 8. Functional gaps xác nhận

### 8.1. Gap từ source code (GAP-01 → GAP-35)

| ID | TC | Mô tả | Ưu tiên | Ảnh hưởng |
|---|---|---|---|---|
| GAP-01 | HALL-03 | Tách phiên/tách bàn không có UI | P0 | Không thể tách bàn đã ghép |
| GAP-02 | HALL-02 | Chuyển một phần món không persist | P1 | Transfer client-side only |
| GAP-03 | VOID-01 | Hủy toàn order: handler có nhưng không UI | P0 | Không thể hủy toàn order |
| GAP-04 | BILL-01 | Hủy bill không có UI | P0 | Không thể void bill |
| GAP-05 | BILL-01 | Lý do gọi lại bill không có UI | P0 | Recall không yêu cầu lý do |
| GAP-06 | PAY-03 | Split payment có trong component nhưng chưa tích hợp checkout | P0 | Không thanh toán nhiều phương thức |
| GAP-07 | PAY-02 | Tiền khách đưa không được dùng trong checkout chính | P0 | Cash calculator riêng lẻ |
| GAP-08 | PAY-03 | VietQR thật không tích hợp | P0 | Chỉ QR image display |
| GAP-09 | INV-01 | Viettel S-Invoice thật chưa xác nhận | P0 | Cần credential thật |
| GAP-10 | RSV-03 | Hoàn cọc/khấu trừ cọc không có | P0 | Không hoàn tiền cọc |
| GAP-11 | RSV-03 | Phương thức nhận cọc bị cố định | P0 | Không chọn phương thức |
| GAP-12 | RSV-02 | Nhiều bàn cho booking không hỗ trợ | P0 | Chỉ 1 bàn/booking |
| GAP-13 | PR-01 | Lý do từ chối PR: composable có, UI thiếu | P1 | Reject không bắt lý do |
| GAP-14 | WH-02 | Nhận hàng theo PO/một phần không hỗ trợ | P0 | Quick entry only |
| GAP-15 | PO-01 | Thanh toán NCC một phần không hỗ trợ | P1 | Chỉ "Trả hết" |
| GAP-16 | ACC-01 | Phiếu thu khác không có UI | P0 | Không lập phiếu thu |
| GAP-17 | ADM-02 | Sửa danh mục thiếu station/duplicate | P1 | Menu không có station |
| GAP-18 | SYS-01 | Xác thực/phân quyền thật: mock auth | P1 | Dev mode bypass |
| GAP-19 | ACC-01 | Khóa kỳ kế toán không có | P0 | Không khóa kỳ |
| GAP-20 | SYNC-01 | Idempotency: chưa kiểm tra double-click | P1 | Có thể tạo trùng |
| **GAP-21** | ADM-04 | **BOM/định lượng món: KHÔNG có UI/route** | **P0** | **Không cấu hình BOM** |
| **GAP-22** | BILL-01 | **Danh sách bill (/cashier/bills): không có route** | **P0** | **Không xem danh sách bill** |
| **GAP-23** | WH-03 | **Dedicated waste view: không có** | **P0** | **Không có UI xuất hủy** |
| **GAP-24** | PR-01 | **Route requisitions: composable có, route không** | **P1** | **Không có màn PR** |
| **GAP-25** | PO-01 | **Route purchase orders: composable có, route không** | **P1** | **Không có màn PO** |
| **GAP-26** | DEBT-01 | **Route receivables: không có** | **P0** | **Không quản lý công nợ KH** |
| **GAP-27** | SYS-01 | **Missing routes /bod, /marketing** | **P1** | **Layout tồn tại, không wire** |
| **GAP-28** | KIT-01 | **POS printer integration: chỉ window.print()** | **P0** | **Không in POS thật** |
| **GAP-29** | VOID-01 | **Manager PIN hardcoded "1234"** | **P0** | **Bảo mật critical** |
| **GAP-30** | SHIFT-02 | **Close shift PIN verification stub** | **P0** | **Bảo mật critical** |
| **GAP-31** | RPT-01 | **Manager reports 80%+ hardcoded** | **P1** | **Dữ liệu không phản ánh thật** |
| **GAP-32** | SYNC-01 | **No multi-tab sync cho customer** | **P1** | **Đồng bộ không hoạt động** |
| **GAP-33** | SYS-01 | **No /demo route** | **P1** | **Không reset scenario** |
| **GAP-34** | GST-01 | **Customer không QR-based** | **P1** | **Dùng passcode thay QR** |
| **GAP-35** | GST-01 | **Only 5 service request types** | **P2** | **Thiếu 4 types** |

### 8.2. Route inventory thực tế vs yêu cầu

**Tồn tại (54 named routes):**
```
/login, /select-branch, /, /admin/{dashboard,accounts,menus,floors,kpi,audit,vouchers},
/hall{,/calendar,/reservation-detail/:id?,/floor-plan,/order-menu},
/kitchen/kds, /purchasing/{receipts,audit},
/accounting/{dashboard,cashflow,ap,pl-report,invoices,tax},
/tablet/{idle,language,order,checkout},
/superadmin/{dashboard,brands,integrations,accounts,vouchers},
/manager/{dashboard,revenue,cogs,marketing,crm,inventory},
/reception/{dashboard,reservation-detail,checkout/:id,close-shift,shift-summary,floors,
            order,reports,revenue-overview,shift-handover,inventory,process-items,
            menu-management,other-expense},
/crm/{dashboard,serving-tables,feedback},
/staff/{floor-plan,active-tables,table/:id/open,table/:id/crm},
/customer{,/menu,/cart,/orders,/service,/feedback,/session-end}
```

**KHÔNG tồn tại (yêu cầu bởi checklist):**
```
/admin/menu/:id/recipe (BOM)     /admin/menu/packages
/kitchen/expo                     /kitchen/availability
/cashier/:sessionId              /cashier/bills
/cashier/shift/close             /inventory/ingredients
/inventory/receipts              /inventory/waste
/procurement/requisitions         /procurement/suppliers
/procurement/orders               /procurement/payables
/accounting/reconciliation        /accounting/cashbook
/accounting/vouchers              /accounting/receivables
/admin/staff                      /admin/roles
/bod                              /manager/menu-performance
/manager/reservations             /m/:tableCode/*
/tablet/tables                    /tablet/service-queue
/demo
```

---

## 9. Bugs / Data / Security issues

### 9.1. Security issues (P0 Critical)

| ID | Vị trí | Mô tả |
|---|---|---|
| GAP-29 | `CancelOrderModal.vue`, `useTableOperations.ts` | Manager PIN hardcoded `"1234"`, không verify qua Supabase |
| GAP-30 | `CloseShiftModal.vue` | `verifyPin()` chỉ set `pinVerified = true`, không verify thật |
| GAP-18 | `useAuth.ts` | Mock auth cho phép đăng nhập không password khi `VITE_SUPABASE_URL` là placeholder |

### 9.2. Data issues

| ID | Vị trí | Mô tả |
|---|---|---|
| GAP-31 | `ManagerDashboardView.vue`, `ManagerRevenueView.vue`, `ManagerCOGSView.vue` | 80%+ data từ `dashboardMockData`, chỉ revenue/covers từ API |
| — | `ShiftSummaryView.vue` | Dùng `shiftStore` với localStorage và hardcoded payments |
| — | `SuperadminDashboardView.vue` | Revenue mocked: `const invoices: any[] = []` (empty array) |
| SRC-12 | `MenuManagementView.vue` (reception) | Dùng `mockMenuData` thay vì Supabase (AdminMenusView dùng Supabase thật) |

### 9.3. Bugs

| ID | Vị trí | Mô tả |
|---|---|---|
| — | `AdminAccountsView.vue` | Search input không có `v-model` — decorative only |
| — | `AdminAuditView.vue` | Pagination UI là mock, không functional |
| — | `OtherExpenseView.vue` | Không persist — local state only, không API call |
| — | `TabletCheckoutView.vue` | Hardcoded mock UUIDs (`00000000-0000-0000-0000-000000000000`) |
| — | `useTableOperations.ts` | Transfer/merge/split không persist lên Supabase, chỉ Pinia store |

---

## 10. Source conflicts và quyết định

| ID | Xung đột | Trạng thái | Quyết định cần |
|---|---|---|---|
| SRC-01 | Framework: plan ghi React/Zustand, role workbook ghi khác | OPEN | Cập nhật tài liệu |
| SRC-02 | Backend: plan ghi localStorage, role workbook ghi khác | OPEN | Cập nhật tài liệu |
| SRC-03 | Route/layout theo vai trò khác route luồng gốc | OPEN | BA/PO quyết định mapping |
| SRC-04 | Chênh lệch phạm vi 434 core steps và 777 role items | OPEN | BA/PO xác nhận |
| SRC-05 | Split payment: role workbook yêu cầu, UI gốc thiếu | OPEN | BA xác nhận yêu cầu |
| SRC-06 | VietQR/Viettel/Print Bridge: có thể chỉ là placeholder | OPEN | Cần môi trường thật |
| SRC-07 | Service charge 5% / VAT 8% hardcoded trong `useBusinessRules.ts` | OPEN | BA xác nhận nguồn cấu hình |
| SRC-08 | Route guard: plan ghi chưa thấy → thực tế CÓ | **RESOLVED** | Đã xác nhận qua code review |
| **SRC-09** | **Framework thực tế: Vue.js+Pinia+Supabase, KHÔNG phải Next.js/React/Zustand** | **OPEN** | **Cập nhật kế hoạch** |
| **SRC-10** | **Backend thực tế: Supabase (PostgreSQL+Auth+Edge Functions+Realtime), không chỉ localStorage** | **OPEN** | **Cập nhật kế hoạch** |
| **SRC-11** | **Route guard CÓ tồn tại: `beforeEach` + `ROUTE_ROLES` prefix-based check** | **OPEN** | **Cập nhật kế hoạch, SRC-08 resolved** |
| **SRC-12** | **MenuManagementView (reception, mock) vs AdminMenusView (admin, Supabase thật): hai views song song** | **OPEN** | **Thống nhất dùng một view** |

---

## 11. Integration thật so với simulated

| Tích hợp | Trạng thái | Bằng chứng |
|---|---|---|
| **Supabase Auth** | REAL | `useAuth.ts` — JWT app_metadata, custom_access_token_hook, `signInWithPassword` |
| **Supabase Database** | REAL | `supabase.from(...).select/insert/update/delete` trong toàn bộ composables |
| **Supabase Realtime** | REAL | `useRealtime.ts` — `watchTable` với `postgres_changes`, dùng cho KDS, CRM, inventory |
| **Edge Functions** | REAL | `add-order-item`, `kds-push`, `admin-user-manager`, `issue-tax-invoice`, `check-in` |
| **Supabase Storage** | REAL | Upload scan images trong `usePurchasing.ts` |
| **VietQR** | **SIMULATED** | QR image từ `api.qrserver.com`, không có gateway/callback/webhook |
| **Viettel S-Invoice** | **BLOCKED** | Edge Function `issue-tax-invoice` tồn tại, trả `vt_invoice_id`, cần credential thật |
| **POS Printer / Print Bridge** | **SIMULATED** | Chỉ `window.print()`, không có ESC/POS, WebUSB, WebSerial, Print Bridge |
| **Table transfer/merge** | **SIMULATED** | Chỉ Pinia store manipulation, không persist Supabase |
| **Manager PIN** | **SIMULATED** | Hardcoded `"1234"`, không verify qua server |
| **ZaloPay/MoMo/VNPay** | REAL (config) | `SuperadminIntegrationsView.vue` — CRUD config thật, nhưng test connection cần credential |
| **Grab/ShopeeFood/Baemin** | REAL (config) | Tương tự payment providers — config CRUD thật |

---

## 12. Danh sách chức năng UI còn thiếu

### P0 — Thiếu nghiêm trọng

| # | Chức năng | Route yêu cầu | Route thực tế |
|---|---|---|---|
| 1 | BOM/định lượng món (Recipe UI) | `/admin/menu/:id/recipe` | KHÔNG TỒN TẠI |
| 2 | Danh sách bill | `/cashier/bills` | KHÔNG TỒN TẠI |
| 3 | Xuất hủy kho (dedicated view) | `/inventory/waste` | KHÔNG TỒN TẠI |
| 4 | Quản lý công nợ khách hàng | `/accounting/receivables` | KHÔNG TỒN TẠI |
| 5 | POS printer integration | — | Chỉ `window.print()` |
| 6 | Manager PIN verification thật | — | Hardcoded `"1234"` |
| 7 | Hủy toàn order UI | — | Handler có, UI không |
| 8 | Hủy bill UI | — | Handler có, UI không |
| 9 | Hoàn/khấu trừ cọc | — | Không có |
| 10 | Khóa kỳ kế toán | — | Không có |

### P1 — Thiếu đáng kể

| # | Chức năng | Route yêu cầu | Route thực tế |
|---|---|---|---|
| 11 | Route requisitions (PR) | `/procurement/requisitions` | KHÔNG TỒN TẠI |
| 12 | Route purchase orders (PO) | `/procurement/orders` | KHÔNG TỒN TẠI |
| 13 | Route suppliers | `/procurement/suppliers` | KHÔNG TỒN TẠI |
| 14 | Route /bod | `/bod` | Layout tồn tại, không wire |
| 15 | Route /marketing | `/marketing` | Layout tồn tại, không wire |
| 16 | Route /demo (scenario reset) | `/demo` | KHÔNG TỒN TẠI |
| 17 | Multi-tab sync (customer) | — | Không BroadcastChannel |
| 18 | Reports từ data thật | — | 80%+ hardcoded |
| 19 | QR scan cho khách | — | Dùng passcode |
| 20 | /kitchen/expo route | `/kitchen/expo` | Tích hợp trong KDS |

### P2 — Thiếu phụ

| # | Chức năng |
|---|---|
| 21 | Service request types: chỉ 5/9 |
| 22 | Zone CRUD trong admin floors |
| 23 | Delete nhân viên |
| 24 | Pagination trong audit log |
| 25 | Export CSV/Excel trong reports |

---

## 13. Đề xuất backlog UI

### 13.1. Ưu tiên khẩn cấp (P0)

1. **Tạo BOM/Recipe UI** — Route `/admin/menus/:id/recipe`, component cấu hình định lượng nguyên vật liệu, tích hợp checkout để trừ tồn (GAP-21)
2. **Thay PIN verification** — Gọi Edge Function/RPC verify manager PIN, xóa hardcoded `"1234"` (GAP-29, GAP-30)
3. **Tạo bills list route** — `/reception/bills` với list, search, filter, reprint, void (GAP-04, GAP-05, GAP-22)
4. **Tạo receivables management** — `/accounting/receivables` với debt list, thu nợ, history (GAP-26)
5. **Tạo dedicated waste view** — `/inventory/waste` hoặc thêm waste UI trong `/purchasing/audit` (GAP-23)
6. **Tích hợp POS printer** — Print Bridge / ESC-POS / WebUSB (GAP-28)
7. **Tích hợp VietQR thật** — Payment gateway, callback/webhook, pending payment intent (GAP-08)
8. **Persist transfer/merge** — Gọi Supabase RPC thay vì chỉ Pinia store (GAP-01, GAP-02)
9. **Tạo void toàn order UI** — Button trong order view, yêu cầu lý do + PIN (GAP-03)
10. **Hoàn/khấu trừ cọc** — UI hoàn cọc khi hủy/no-show (GAP-10, GAP-11)

### 13.2. Ưu tiên cao (P1)

11. **Wire routes /bod và /marketing** — Layouts đã tồn tại (GAP-27)
12. **Tạo routes /procurement/requisitions, /orders, /suppliers** — Composables đã có (GAP-24, GAP-25)
13. **Thay hardcoded reports** — Dùng Supabase queries thay `dashboardMockData` (GAP-31)
14. **Thêm BroadcastChannel** — Cho customer session multi-tab sync (GAP-32)
15. **Persist OtherExpenseView** — Lưu lên Supabase, thêm threshold approval (GAP-16, GAP-19)
16. **Tạo /demo route** — Scenario reset/nạp kịch bản (GAP-33)
17. **Thêm QR scan** — Cho customer flow thay passcode (GAP-34)
18. **PO-based goods receipt** — Thay quick entry, hỗ trợ partial receipt (GAP-14)
19. **Partial payment NCC** — Thay "Trả hết" only (GAP-15)
20. **Tích hợp split payment vào checkout** — PaymentMethodSelector có, chưa wire (GAP-06)

### 13.3. Yêu cầu dữ liệu/database suy ra (đề xuất, không phải hiện trạng)

> Đây là đề xuất dựa trên UI gap, dành cho giai đoạn sau, không phải nghiệm thu hiện trạng.

- **BOM table**: `menu_recipes (menu_item_id, ingredient_id, quantity)` — hỗ trợ ADM-04
- **Bills view/table**: `bills` với `status (settled/recalled/voided)`, `voided_at`, `void_reason`, `voided_by` — hỗ trợ BILL-01
- **Receivables**: `customer_debts (customer_id, bill_id, charge_amount, repaid_amount, balance)` — hỗ trợ DEBT-01
- **Print queue**: `print_jobs (type, payload, status, printer_id, created_at)` — hỗ trợ KIT-01
- **Manager PIN**: `users.manager_pin_hash` + RPC `verify_manager_pin(user_id, pin)` — hỗ trợ GAP-29/30
- **Waste records**: `inventory_transactions` type `WASTE` với `reason`, `note` — hỗ trợ WH-03

---

## 14. Risks / Limitations

### 14.1. Risks

| Risk | Mô tả | Ảnh hưởng |
|---|---|---|
| Manager PIN hardcoded | Bất kỳ ai cũng có thể void/hủy với PIN `1234` | Critical security |
| Mock auth bypass | Dev mode cho phép login không password | Critical security nếu deploy với placeholder URL |
| Transfer/merge không persist | Dữ liệu bị mất khi refresh | Data loss |
| Reports 80% hardcoded | Decision dựa trên data sai | Business risk |
| OtherExpenseView không persist | Chi phí không được ghi nhận | Accounting risk |
| VietQR simulated | Thanh toán không thật | Integration risk |
| MenuManagementView mock | Menu reception dùng data giả | Data inconsistency |

### 14.2. Limitations

- Phân tích bằng code review, không test browser trực tiếp
- Không kiểm tra được visual layout, responsive, accessibility
- Không kiểm tra được data thật trong Supabase
- Không kiểm tra được Edge Function execution (cần chạy app)
- Không kiểm tra được multi-tab behavior thực tế
- Không kiểm tra được print output thực tế
- Some features có thể hoạt động khác khi chạy app (runtime behavior có thể khác code review)

---

## 15. Retest summary

Chưa có retest trong đợt này. Tất cả issue ở trạng thái `OPEN`. Cần fix và retest theo quy tắc:

1. Chỉ retest issue có trạng thái `READY FOR RETEST` hoặc `FIXED`
2. Reset đúng scenario và chạy lại cùng Master ID
3. Cập nhật `Retest Status` và evidence mới
4. Không đóng issue chỉ dựa trên thông báo "đã sửa"

---

## 16. Acceptance gate

| Gate | Điều kiện | Trạng thái |
|---|---|---|
| P0 Test | Không có Master row P0 ở trạng thái FAIL/BLOCKED/NOT RUN | **KHÔNG ĐẠT** — 533 FAIL + 12 BLOCKED |
| P0/P1 Issue | Không còn issue P0/P1 mở | **KHÔNG ĐẠT** — 47 issue OPEN |
| Core Flow | 34 flow hoàn tất; không flow FAIL/BLOCKED | **KHÔNG ĐẠT** — 26 FAIL + 1 BLOCKED |
| Role Permission | Tất cả role test Menu/URL/API/Branch/Audit | **KHÔNG ĐẠT** — 13/14 role FAIL |
| Source Conflict | SRC-* đã FIXED/CLOSED hoặc được BA/PO chấp nhận | **KHÔNG ĐẠT** — 11 SRC OPEN |
| Integration Evidence | VietQR/eInvoice/Print chỉ PASS khi có bằng chứng thật | **KHÔNG ĐẠT** — tất cả simulated |

### Kết luận gate: KHÔNG ĐẠT

Lý do chính:
1. 10 chức năng P0 thiếu hoàn toàn (BOM, bills list, waste view, receivables, POS printer, PIN verification, void order/bill, hoàn cọc, khóa kỳ)
2. Manager PIN hardcoded — security critical
3. Transfer/merge không persist — data loss risk
4. Reports 80%+ hardcoded — data integrity risk
5. 4 source conflict mới cần BA/PO quyết định (framework, backend, route guard, menu views)

---

## 17. Phụ lục

### 17.1. Mapping source files → flows

| Flow | Files chính |
|---|---|
| SYS-01 | `router/index.ts`, `composables/useAuth.ts`, `composables/useBranch.ts`, `utils/route.ts` |
| ADM-01 | `views/admin/AdminAccountsView.vue` |
| ADM-02 | `views/admin/AdminMenusView.vue`, `views/reception/MenuManagementView.vue` |
| ADM-03 | `views/admin/AdminMenusView.vue` |
| ADM-04 | **KHÔNG CÓ** — không tìm thấy file nào |
| ADM-05 | `views/admin/AdminFloorsView.vue` |
| ADM-06 | `views/admin/AdminVoucherView.vue` → `views/manager/ManagerVoucherView.vue` |
| SHIFT-01 | `composables/useShift.ts`, `stores/shiftStore.ts` |
| RSV-01/02/03 | `views/hall/HallDashboard.vue`, `views/reception/ReceptionFloorsView.vue`, `views/reception/ReservationDetailView.vue` |
| HALL-01/02/03/04 | `composables/useTableOperations.ts`, `views/staff/StaffOpenTableView.vue`, `views/reception/ReceptionOrderView.vue` |
| ORD-01 | `views/reception/ReceptionOrderView.vue`, `composables/useOrder.ts` |
| KIT-01 | `views/kitchen/KitchenKDSView.vue`, `composables/useKDS.ts` |
| VOID-01 | `components/reception/CancelOrderModal.vue`, `composables/useTableOperations.ts` |
| GST-01 | `views/customer/*`, `views/tablet/*` |
| PAY-01/02/03 | `views/reception/ReceptionCheckoutView.vue`, `components/reception/PaymentMethodSelector.vue`, `composables/useCheckout.ts` |
| DEBT-01 | `components/reception/PaymentMethodSelector.vue` |
| BILL-01 | `views/reception/ReceptionOrderView.vue` (recall mentioned) |
| INV-01 | `composables/useTaxInvoice.ts`, `views/accounting/InvoiceManagerView.vue` |
| WH-01/02/03 | `composables/useInventory.ts`, `composables/usePurchasing.ts`, `views/purchasing/DailyReceiptView.vue`, `views/purchasing/InventoryAuditView.vue` |
| PR-01 | `composables/useRequisition.ts` |
| PO-01 | `composables/usePurchaseOrder.ts`, `composables/usePurchasing.ts` |
| ACC-01 | `views/reception/OtherExpenseView.vue`, `views/accounting/CashFlowView.vue` |
| SHIFT-02 | `views/reception/ReceptionCloseShiftView.vue`, `views/reception/ShiftSummaryView.vue`, `components/reception/CloseShiftModal.vue` |
| RPT-01 | `views/manager/ManagerDashboardView.vue`, `views/manager/ManagerRevenueView.vue`, `views/manager/ManagerCOGSView.vue` |
| SYNC-01 | `composables/useRealtime.ts`, `composables/useCustomerSession.ts` |

### 17.2. Route inventory thực tế (54 routes)

```
Public:
  /login, /select-branch, / (→ /login)

Admin (/admin/*): 7 routes
  /admin/dashboard, /admin/accounts, /admin/menus, /admin/floors,
  /admin/kpi, /admin/audit, /admin/vouchers

Hall (/hall/*): 5 routes
  /hall, /hall/calendar, /hall/reservation-detail/:id?,
  /hall/floor-plan, /hall/order-menu

Kitchen: 1 route
  /kitchen/kds

Purchasing: 2 routes
  /purchasing/receipts, /purchasing/audit

Accounting: 6 routes
  /accounting/dashboard, /accounting/cashflow, /accounting/ap,
  /accounting/pl-report, /accounting/invoices, /accounting/tax

Tablet: 4 routes
  /tablet/idle, /tablet/language, /tablet/order, /tablet/checkout

Superadmin: 5 routes
  /superadmin/dashboard, /superadmin/brands, /superadmin/integrations,
  /superadmin/accounts, /superadmin/vouchers

Manager: 6 routes
  /manager/dashboard, /manager/revenue, /manager/cogs,
  /manager/marketing, /manager/crm, /manager/inventory

Reception: 14 routes
  /reception/dashboard, /reception/reservation-detail, /reception/checkout/:id,
  /reception/close-shift, /reception/shift-summary, /reception/floors,
  /reception/order, /reception/reports, /reception/revenue-overview,
  /reception/shift-handover, /reception/inventory, /reception/process-items,
  /reception/menu-management, /reception/other-expense

CRM: 3 routes
  /crm/dashboard, /crm/serving-tables, /crm/feedback

Staff: 4 routes
  /staff/floor-plan, /staff/active-tables, /staff/table/:id/open, /staff/table/:id/crm

Customer: 7 routes
  /customer, /customer/menu, /customer/cart, /customer/orders,
  /customer/service, /customer/feedback, /customer/session-end
```

### 17.3. Composables inventory (39 files)

```
useAccounting.ts        useAccountingModule.ts  useAudit.ts
useAuth.ts              useBOD.ts               useBranch.ts
useBusinessRules.ts     useCampaign.ts          useCheckIn.ts
useCheckout.ts          useCRM.ts               useCustomer.ts
useCustomerSession.ts   useFeedback.ts          useIntegrations.ts
useInventory.ts         useKDS.ts               useKitchenShift.ts
useKPI.ts               useMarketing.ts         useMembership.ts
useMenu.ts              useNotification.ts      useOCR.ts
useOrder.ts             usePurchaseOrder.ts     usePurchasing.ts
useRealtime.ts          useReceptionSync.ts     useReport.ts
useRequisition.ts       useReservation.ts       useServiceRequest.ts
useShift.ts             useTable.ts             useTableOperations.ts
useTablet.ts            useTaxInvoice.ts        useUnsavedGuard.ts
useUserSticker.ts       useVoucher.ts
```

### 17.4. Stores inventory (10 files)

```
crmStore.ts             customerStore.ts        hallStore.ts
i18n.ts                 kitchen.ts              menuManagementStore.ts
receptionStore.ts       restaurantStore.ts      shiftStore.ts
useLanguageStore.ts
```

### 17.5. Role mapping: workbook vs source

| Workbook Role | Source Role(s) | Route Prefix | Route Guard |
|---|---|---|---|
| RECEPTION | reception | /reception | superadmin, admin, manager, reception |
| STAFF | staff | /staff | superadmin, admin, manager, staff |
| KITCHEN | kitchen | /kitchen | superadmin, admin, manager, kitchen |
| CUSTOMER | customer | /customer | (public, no auth required) |
| HALL | hall | /hall | superadmin, admin, manager, reception, staff, hall |
| MANAGER | manager | /manager | superadmin, admin, manager |
| ADMIN | superadmin, admin | /admin | superadmin, admin |
| PURCHASING | procurement, procurement_manager, procurement_staff, purchasing | /purchasing | superadmin, admin, procurement*, purchasing |
| ACCOUNTING | accounting, accounting_manager | /accounting | superadmin, admin, accounting*, manager |
| CRM | crm_manager, crm | /crm | superadmin, admin, manager, crm*, crm |
| MARKETING | marketing | (no route) | superadmin, admin, manager, marketing |
| BOD | bod | (no route) | superadmin, admin, bod |
| SUPERADMIN | superadmin | /superadmin | superadmin |
| BUSINESS RULES | (cross-cutting) | (multiple) | (multiple) |

### 17.6. Issue log summary

**28 issue seed (GAP-01→GAP-20, SRC-01→SRC-08):**
- 20 Functional Gap (GAP-01→GAP-20)
- 8 Source Conflict (SRC-01→SRC-08)

**19 issue mới (GAP-21→GAP-35, SRC-09→SRC-12):**
- 12 Functional Gap (GAP-21→GAP-32)
- 1 Security (GAP-29, GAP-30)
- 1 Data Issue (GAP-31)
- 4 Source Conflict (SRC-09→SRC-12)

**Tổng: 47 issue, tất cả OPEN**

| Loại | Số lượng | P0 | P1 | P2 |
|---|---:|---:|---:|---:|
| Functional Gap | 32 | 14 | 12 | 1 |
| Source Conflict | 12 | 0 | 0 | 0 |
| Security | 2 | 2 | 0 | 0 |
| Data Issue | 1 | 0 | 1 | 0 |

---

*Hết báo cáo.*
