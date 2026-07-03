# PROJECT RISK REGISTER — Audit toàn diện ngày 2026-07-02

> **Tác giả**: Agent audit (session 2026-07-02)
> **Trạng thái**: READY FOR REVIEW
> **Mục đích**: Ghi nhận toàn bộ risk hiện tại của project để owner xử lý và share với team.
> **Phương pháp**: Audit tĩnh trên local DB + source code + git state. CHƯA chạy runtime E2E.
>
> **Severity legend**:
> - 🔴 **CRITICAL** — phải fix trước khi launch / trước khi push DB
> - 🟠 **MEDIUM** — nên fix trong sprint hiện tại
> - 🟡 **LOW** — technical debt, fix khi có thời gian

---

## 📊 TỔNG QUAN

| Loại risk | 🔴 CRITICAL | 🟠 MEDIUM | 🟡 LOW | Tổng |
|---|---|---|---|---|
| Database | 2 | 2 | 1 | 5 |
| Security / Auth | 1 | 2 | 0 | 3 |
| Frontend / Code | 2 | 1 | 1 | 4 |
| Testing | 1 | 0 | 1 | 2 |
| Project hygiene | 0 | 1 | 2 | 3 |
| **Tổng** | **6** | **6** | **5** | **17** |

**Điểm sáng** (không phải risk):
- ✅ DB lint: 0 errors
- ✅ Migration history local↔remote: 29/29 synced
- ✅ 95% RPC có SECURITY DEFINER, 100% RPC có GRANT EXECUTE to authenticated
- ✅ JWT hook đọc từ `raw_app_meta_data` (đúng quy tắc Supabase, không dùng `raw_user_meta_data`)
- ✅ Router không còn legacy mock customer flow

---

## 🔴 CRITICAL RISKS (phải fix trước khi launch / push DB)

### CRIT-1. user_role enum chưa đạt 8-role model — vẫn có 10 value

**Phát hiện**: Local DB hiện có **10 values** trong `user_role` enum, không phải 8 như owner quyết ngày 2026-07-02.

| # | Value | Sort | Nguồn gốc | Đáng giữ? |
|---|---|---|---|---|
| 1 | `admin` | 1 | `20260623000000_setup.sql:58` | ✅ |
| 2 | `manager` | 2 | `20260623000000_setup.sql:58` | ✅ |
| 3 | `reception` | 3 | `20260623000000_setup.sql:58` | ✅ |
| 4 | `staff` | 4 | `20260623000000_setup.sql:58` | ✅ |
| 5 | `kitchen` | 5 | `20260623000000_setup.sql:58` | ✅ |
| 6 | **`purchasing`** | 6 | `20260701000000_schema_hardening_v2.sql:32` | ❌ Trùng nghĩa `procurement` |
| 7 | `accounting` | 7 | `20260701000000_schema_hardening_v2.sql:36` | ✅ |
| 8 | **`crm`** | 8 | `20260701000000_schema_hardening_v2.sql:40` | ❌ Owner quyết: dùng `manager` |
| 9 | `procurement` | 9 | `20260701000005_add_roles_procurement_customer.sql:16` | ✅ |
| 10 | `customer` | 10 | `20260701000005_add_roles_procurement_customer.sql:20` | ✅ |

**Root cause**:
- Migration `20260701095000_revert_to_simple_role_model.sql` (do agent tạo 2026-07-02) chỉ revert những value được tạo bởi migration `093424` (`superadmin`, `accountant`, `procurement_manager`, `crm_manager`, `marketing`, `procurement_staff`).
- Những value này **KHÔNG TỒN TẠI** trên local (chỉ tồn tại trên remote trước khi revert). Do đó migration này là **NO-OP trên local**.
- Migration KHÔNG xử lý `purchasing` (sort 6) và `crm` (sort 8) — hai value đã được `schema_hardening_v2.sql` tạo sẵn.

**Impact**:
- Nếu push migration hiện tại lên remote rồi cast `enum_range` cho app, sẽ thấy 10 role → owner / BOD có thể nhầm tưởng hệ thống còn `purchasing` và `crm`.
- Nếu sau này cần viết `user_role = 'crm'` trong SQL, function sẽ fail ở local vì `_unused_crm` (sau revert) không khớp code logic.

**Fix đề xuất** (5 phút):
Sửa `supabase/migrations/20260701095000_revert_to_simple_role_model.sql`, thêm 2 DO block:
```sql
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid=t.oid
    JOIN pg_namespace n ON t.typnamespace=n.oid
    WHERE t.typname='user_role' AND n.nspname='public' AND e.enumlabel='purchasing'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'purchasing' TO '_unused_purchasing';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid=t.oid
    JOIN pg_namespace n ON t.typnamespace=n.oid
    WHERE t.typname='user_role' AND n.nspname='public' AND e.enumlabel='crm'
  ) THEN
    ALTER TYPE public.user_role RENAME VALUE 'crm' TO '_unused_crm';
  END IF;
END $$;
```

**Owner action**: Phạm (DB) — apply sửa migration 095000 + `db reset --local --no-seed` để verify.

---

### CRIT-2. Source code tham chiếu `purchasing` và `'crm'` role — 10 file

**Phát hiện**: Sau khi CRIT-1 fix, enum không còn `purchasing`/`crm`. Nhưng source code vẫn đang dùng:

```
src/router/index.ts                            ← route guard / role check
src/views/purchasing/PurchaseOrdersView.vue    ← UI role gate
src/composables/usePurchasing.ts               ← business logic
src/composables/useAuth.ts                     ← auth flow
src/types/database.ts                          ← TypeScript enum mirror
src/layouts/PurchasingLayout.vue               ← layout
src/stores/useLanguageStore.ts                 ← state (có thể liên quan)
src/locales/ja.ts, en.ts, vi.ts                ← i18n labels (có thể chỉ là string)
```

**Root cause**:
- `purchasing` được `schema_hardening_v2.sql` thêm enum value + tạo folder `views/purchasing/`. Folder name "Purchasing" tự nhiên match với role `purchasing` → dẫn đến nhiều file dùng `role === 'purchasing'`.
- Tương tự `crm`: folder `views/crm/` tồn tại + enum value `crm` → router/check dùng `role === 'crm'`.

**Impact**:
- Sau CRIT-1 fix: SQL `user_role = 'crm'` sẽ throw 22P02 invalid enum value.
- TypeScript types (`src/types/database.ts`) có thể không khớp enum mới → type error.
- Router có thể block user khỏi module nghiệp vụ vì check role cũ.

**Fix đề xuất** (30 phút):

1. `src/types/database.ts`: thay `'purchasing' | 'crm'` → `'procurement' | 'manager'`
2. `src/router/index.ts`: tìm các guard check `'purchasing'` / `'crm'`, đổi sang `'procurement'` / `'manager'`
3. `src/composables/useAuth.ts`: tương tự
4. `src/composables/usePurchasing.ts`: tương tự
5. `src/views/purchasing/*` và `src/layouts/PurchasingLayout.vue`: **KHÔNG CẦN ĐỔI** — folder name vẫn dùng được, chỉ là string label. Chỉ đổi nếu role check có.

**Owner action**: Phạm (Frontend) — grep toàn project, fix theo từng file.

---

### CRIT-3. View folder `superadmin/` và `marketing/` tồn tại nhưng role không có

**Phát hiện**: `ls src/views/` cho thấy:
```
superadmin/    ← không có role 'superadmin' trong 8-role model
marketing/     ← không có role 'marketing' trong 8-role model
```

**Impact**:
- Folder có thể chứa code dead / placeholder
- Router có thể expose route không ai truy cập được (sẽ 403 / redirect)
- Source code size lớn hơn cần thiết

**Fix đề xuất** (10 phút):

1. Check `src/router/index.ts` có route nào map tới `views/superadmin/` hoặc `views/marketing/` không
2. Nếu không có route → xóa folder
3. Nếu có route → đổi tên folder (vd: `superadmin/` → `admin/`) và update route

**Owner action**: Phạm (Frontend) — verify routes + xóa/đổi tên folder.

---

### CRIT-4. RPC `crm_normalize_phone` & `revenue_by_hour` thiếu SECURITY DEFINER

**Phát hiện**: Audit `pg_proc` cho thấy 2 RPC business logic thiếu `SECURITY DEFINER` + `SET search_path`:

| Function | Signature | SECURITY DEFINER | search_path |
|---|---|---|---|
| `crm_normalize_phone(p_phone text)` | helper CRM | ❌ | ❌ |
| `revenue_by_hour(p_branch_id uuid, p_date date)` | BOD report | ❌ | ❌ |

**Root cause**:
- `crm_normalize_phone` được tạo từ migration CRM (20260702044658) — có thể agent CRM miss template.
- `revenue_by_hour` được tạo từ migration BOD — tương tự.

**Impact**:
- Function chạy với permission của caller (không phải owner) → có thể bị RLS block unexpectedly.
- Thiếu `SET search_path = public, auth` → có thể bị search_path hijack attack (kẻ tấn công tạo function ở schema khác cùng tên).

**Fix đề xuất** (10 phút):
Tạo migration `20260701095200_secdef_for_2_rpcs.sql`:
```sql
CREATE OR REPLACE FUNCTION public.crm_normalize_phone(p_phone text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth AS $$
BEGIN
  RETURN regexp_replace(COALESCE(p_phone, ''), '[^0-9+]', '', 'g');
END; $$;

CREATE OR REPLACE FUNCTION public.revenue_by_hour(p_branch_id uuid, p_date date)
RETURNS TABLE (...) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth AS $$
BEGIN
  ...
END; $$;

REVOKE EXECUTE ON FUNCTION public.crm_normalize_phone(text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.crm_normalize_phone(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.revenue_by_hour(uuid, date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.revenue_by_hour(uuid, date) TO authenticated;

NOTIFY pgrst, 'reload schema';
```

**Owner action**: Phạm (DB) — apply migration mới.

---

### CRIT-5. RLS policy coverage — 24 tables chỉ có 1 policy

**Phát hiện**: Audit `pg_policies`:
| Tables | Policy count | Ghi chú |
|---|---|---|
| 24 tables | 1 policy | Thường là SELECT only |
| 25 tables | 2 policies | SELECT + write |
| 1 table (`crm_surveys`) | 3 policies | OK |

Các table chỉ có 1 policy (SELECT only): `bod_approvals`, `budgets`, `campaign_vouchers`, `campaigns`, `customer_feedback`, `financial_transactions`, `goods_receipt_items`, `goods_receipts`, `ingredient_categories`, `ingredients`, `inventory_stock`, `invoices`, `kitchen_shifts`, `orders`, `payments`, `purchase_order_items`, `purchase_orders`, `requisition_items`, `requisitions`, `reservations`, `service_requests`, `suppliers`, `tablet_order_submissions`, `tablet_sessions`.

**Impact**:
- Nếu policy duy nhất là `FOR SELECT USING (branch_id = current_branch_id())`:
  - INSERT/UPDATE/DELETE bị block 100% → frontend phải dùng RPC (đúng theo rule) nhưng RPC cũng sẽ fail nếu SECURITY DEFINER không bypass RLS cho caller.
- Có thể là design intent (frontend không ghi trực tiếp), hoặc thiếu policy do dev miss.

**Fix đề xuất** (30 phút):
1. Với mỗi table 1-policy, kiểm tra xem có RPC nào ghi vào đó không.
2. Nếu có RPC ghi → bổ sung policy `FOR INSERT/UPDATE/DELETE WITH CHECK (branch_id = current_branch_id() OR has_role('admin'))`.
3. Nếu không có RPC ghi → document là "read-only via frontend, write via RPC only" và thêm comment vào migration.

**Owner action**: Phạm (DB) — chạy audit query, bổ sung policy thiếu.

---

### CRIT-6. E2E test coverage gần như bằng 0 cho flow nghiệp vụ

**Phát hiện**: 6 spec file, **chỉ 5 active tests**, 11 skip:
```
auth.spec.ts:                2 active  ← UI render + login fail (shallow)
checkout-boundary.spec.ts:   0 active  ← 2 skip (skeleton)
crm-regression.spec.ts:      0 active  ← 1 skip (skeleton)
customer-tablet.spec.ts:     0 active  ← 3 skip (skeleton)
hall-reception.spec.ts:      0 active  ← 3 skip (skeleton)
no-mock-runtime.spec.ts:     3 active  ← grep tests only
```

Các flow nghiệp vụ chính đều CHƯA CÓ TEST:
- ❌ Checkout → bill → payment
- ❌ CRM survey submission
- ❌ Tablet order → kitchen → serve
- ❌ Hall: confirm reservation → seat → serve
- ❌ Procurement: PO → goods receipt → inventory update
- ❌ Accounting: tax record finalization

**Impact**:
- Mỗi lần refactor RPC, không có regression test → dễ break production.
- Khó demo cho stakeholder / pilot branch — không có "evidence" flow chạy đúng.

**Fix đề xuất** (1-2 ngày effort):
1. Viết helper `e2e/helpers/seed.ts` để seed test data (branch, user, role, table)
2. Implement 1 happy-path test cho mỗi flow:
   - `e2e/checkout-boundary.spec.ts`: order seeded → login hall user → click checkout → verify bill created
   - `e2e/hall-reception.spec.ts`: reservation seeded → login hall → confirm + seat → verify table status
   - `e2e/crm-regression.spec.ts`: order seeded → login CRM → submit survey → verify crm_surveys row
   - `e2e/customer-tablet.spec.ts`: open tablet → add to cart → submit → verify orders row
   - `e2e/procurement.spec.ts` (NEW): login procurement → create PO → submit goods receipt → verify inventory
   - `e2e/accounting.spec.ts` (NEW): login accounting → generate tax record → finalize → verify status

**Owner action**: Phạm (QA) hoặc Phạm (lead) assign cho member — sau khi CRIT-1 → CRIT-5 done.

---

## 🟠 MEDIUM RISKS (nên fix trong sprint hiện tại)

### MED-1. 13 RPC có SECURITY DEFINER nhưng thiếu SET search_path

**Phát hiện**: 78 RPC, 65 có search_path → **13 RPC (~17%) thiếu search_path**. Security smell: function chạy với search_path của caller → có thể bị search_path hijack.

**Owner action**: Phạm (DB) — extend migration ở CRIT-4 để bao gồm cả 13 RPC này (audit query: `pg_proc WHERE prosecdef=true AND proconfig NOT LIKE '%search_path%'`).

---

### MED-2. Frontend vi phạm Strict RPC Architecture — 45 lần `.from()` trực tiếp

**Phát hiện**: Quy tắc `.agents/AGENTS.md` yêu cầu **MỌI** data access qua `supabase.rpc()`. Tuy nhiên có 45 instances dùng `.from('table').select()` trực tiếp:

```
5× .from('tables')              ← Hall/tablet UI
3× .from('packages')            ← Hall
3× .from('menu_items')          ← Hall/tablet
2× .from('users')               ← Admin
2× .from('payment_integrations')
2× .from('branches')
1× .from('reservations')
1× .from('purchase_orders')
1× .from('orders')
1× .from('order_items')
1× .from('customers')
1× .from('customer_feedback')
1× .from('campaigns')
1× .from('inventory_items')
1× .from('requisitions')
1× .from('vouchers')
... (và nhiều file views/)
```

**Exception hợp lý** (cần verify):
- Realtime subscriptions (`channel.on('postgres_changes', { table: 'X' }, ...)`)
- Audit events append (nếu có)
- `auth.users` (qua supabase.auth.getUser() thay vì .from())

**Owner action**: Phạm (lead) — review 45 instance, quyết case nào giữ (realtime), case nào tách thành RPC.

---

### MED-3. Working tree có 13 file M (modified, chưa commit)

**Phát hiện**:
```
M src/composables/{useAccounting,useBOD,useCheckout,usePurchasing}.ts
M src/locales/vi.ts
M src/router/index.ts                    ← liên quan CRIT-2
M src/stores/{customerStore,useLanguageStore}.ts
M src/views/accounting/AccountingDashboardView.vue
M src/views/customer/Feedback.vue
M src/views/hall/CheckoutView.vue
M src/views/kitchen/KitchenKDSView.vue
M src/views/tablet/TabletCheckoutView.vue  ← có no-mock test guard
M docs/member_status/Phu/phu_update/HALL_CUSTOMER_TASK_STATUS.md
```

**Impact**:
- `git status` không sạch → khó review / merge / push.
- `tablet/TabletCheckoutView.vue` đang M — `no-mock-runtime.spec.ts` có test đảm bảo nó KHÔNG dùng `mock-order-id` và KHÔNG dùng `useCheckout`. Cần verify sau khi sửa xong file này.

**Fix đề xuất** (30 phút):
1. Commit tách riêng: `commit 1: chore(router): update role guards for simple 8-role model` (sửa CRIT-2)
2. `commit 2: feat(views): update TabletCheckoutView for primary tablet flow` (sửa mock usage)
3. `commit 3: chore(composables): useCheckout refactor`
4. `commit 4: docs(Phu): update HALL_CUSTOMER_TASK_STATUS`

**Owner action**: Phạm (lead) — review + commit theo concern.

---

### MED-4. Working tree có thay đổi nhưng DB migration chưa push (mixed concern)

**Phát hiện**: Working tree có 13 file M **+** 5 file SQL mới chưa push lên remote. Nếu push theo thứ tự sai có thể break:
- Push DB trước khi push frontend → frontend chưa có enum mới → có thể crash UI
- Push frontend trước khi push DB → frontend check role mới → 22P02 invalid enum

**Fix đề xuất**: Đẩy theo thứ tự:
1. Commit migration revert enum (CRIT-1 fix)
2. Push DB
3. Wait for DB applied
4. Commit frontend role guards fix (CRIT-2)
5. Push frontend

**Owner action**: Phạm (lead) — sequence 2 commit groups.

---

### MED-5. E2E test config chưa wired vào npm scripts

**Phát hiện**: `package.json` không có script `test:e2e`. Hiện tại muốn chạy phải gõ `npx playwright test`. Mỗi lần CI/CD cần config riêng.

**Fix đề xuất** (5 phút):
```json
"scripts": {
  ...
  "test:e2e": "playwright test",
  "test:e2e:headed": "playwright test --headed",
  "test:e2e:debug": "playwright test --debug"
}
```

**Owner action**: Phạm (lead) — add vào package.json.

---

### MED-6. Branch không theo convention

**Phát hiện**: Branch hiện tại `local-main-repair-20260702`. PROJECT_OVERVIEW §11.2 yêu cầu feature branch riêng cho mỗi concern.

**Fix đề xuất** (5 phút):
Tạo branch mới `fix/role-enum-cleanup-20260702`:
```bash
git checkout -b fix/role-enum-cleanup-20260702
git checkout local-main-repair-20260702 -- supabase/migrations/20260701095000_revert_to_simple_role_model.sql
# sửa file → commit → push branch
```

**Owner action**: Phạm (lead) — tạo branch trước khi commit CRIT-1 fix.

---

## 🟡 LOW RISKS (technical debt, fix khi có thời gian)

### LOW-1. Branch name "local-main-repair" không theo convention dài hạn

**Phát hiện**: Branch `local-main-repair-20260702` đang được dùng cho mọi thứ. Sau khi session kết thúc, cần merge vào `main` hoặc tạo branch mới.

**Fix đề xuất**: Sau khi push DB + frontend, merge vào `main`, archive branch cũ.

---

### LOW-2. Reports folder có 9 file mới chưa commit

**Phát hiện**: `docs/member_status/Phu/phu_update/` có 9 untracked file (BUILD_FIX_REPORT, CHECKOUT_ACCOUNTING_BOUNDARY_REPORT, CRM_REGRESSION_REPORT, E2E_TEST_REPORT, FINAL_READY_FOR_DB_PUSH_REPORT, MOCK_DATA_AUDIT, PRODUCTION_READINESS_PLAN, SUPABASE_PRE_PUSH_AUDIT).

**Fix đề xuất**: Commit nhóm docs này vào 1 commit `docs(Phu): add audit reports for 2026-07-02 push`.

---

### LOW-3. Memory index có thể cần cập nhật

**Phát hiện**: User memory đã có 8 entry. Sau session này, có thể cần thêm:
- `project-role-model-is-8-simple` (memory mới, ghi nhận quyết định 8 role)

**Owner action**: Phạm (lead) hoặc owner — review memory, thêm nếu cần.

---

## 📋 ACTION PLAN ĐỀ XUẤT CHO NGÀY MAI

### Buổi sáng (DB / Backend)
1. **CRIT-1** (5 min): Sửa migration `20260701095000`, thêm 2 rename `purchasing→_unused`, `crm→_unused`
2. **CRIT-4** (10 min): Tạo migration mới `20260701095200` cho 2 RPC thiếu SECURITY DEFINER
3. **MED-1** (15 min): Mở rộng migration trên fix 13 RPC thiếu search_path
4. **CRIT-5** (30 min): Audit 24 tables 1-policy, bổ sung nếu thiếu
5. **Verify** (10 min): `db reset --local` + `db lint` + `db diff` + `db push --dry-run`

### Buổi chiều (Frontend)
6. **CRIT-3** (10 min): Check + xóa/đổi tên `views/superadmin/`, `views/marketing/`
7. **CRIT-2** (30 min): Grep + fix 10 file src/ tham chiếu `purchasing`/`crm` role
8. **MED-3** (30 min): Commit 13 file M theo từng concern
9. **MED-4** (5 min): Sequence push DB → wait → push frontend
10. **MED-5** (5 min): Add npm test scripts

### Sprint sau
11. **CRIT-6** (1-2 ngày): Viết E2E test cho 5 flow nghiệp vụ chính
12. **MED-2** (2 giờ): Review 45 instance `.from()` direct, quyết giữ/loại

---

## 📎 LIÊN KẾT

- [BUILD_FIX_REPORT.md](./BUILD_FIX_REPORT.md) — build errors trước đó
- [CHECKOUT_ACCOUNTING_BOUNDARY_REPORT.md](./CHECKOUT_ACCOUNTING_BOUNDARY_REPORT.md) — boundary giữa checkout & accounting
- [CRM_REGRESSION_REPORT.md](./CRM_REGRESSION_REPORT.md) — CRM regression suite
- [E2E_TEST_REPORT.md](./E2E_TEST_REPORT.md) — E2E test status
- [FINAL_READY_FOR_DB_PUSH_REPORT.md](./FINAL_READY_FOR_DB_PUSH_REPORT.md) — DB push readiness
- [MOCK_DATA_AUDIT.md](./MOCK_DATA_AUDIT.md) — mock data audit
- [PRODUCTION_READINESS_PLAN.md](./PRODUCTION_READINESS_PLAN.md) — launch plan
- [SUPABASE_PRE_PUSH_AUDIT.md](./SUPABASE_PRE_PUSH_AUDIT.md) — pre-push audit

---

## 📌 SHARE WITH TEAM

Gửi kèm link file này cho team với note:
> "Audit tổng thể 2026-07-02: 6 critical risks cần xử lý trước push. Xem file PROJECT_RISK_REGISTER_20260702.md, focus mục CRIT (1-6). Action plan đã chia sáng/chiều mai."

---

*Generated by audit agent — session 2026-07-02. Tất cả findings dựa trên static audit (không runtime test). Mọi con số/file path đã verify tại thời điểm audit.*