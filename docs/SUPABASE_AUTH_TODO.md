# SUPABASE_AUTH_TODO — Out Standing Issues về Auth / RLS

> File này ghi nhận các điểm chưa xử lý liên quan đến auth/role/RLS mà
> agent hoặc owner cần biết trước khi vào production. Mỗi mục có: vấn đề,
> nguyên nhân, hướng xử lý, mức độ ưu tiên.

---

## 1. auth.users app_metadata role sync với enum

### Vấn đề
- `custom-access-token` hook (migration `20260625200000_fix_jwt_helpers_read_app_metadata.sql`)
  đọc `auth.users.raw_app_meta_data->>'role'` rồi cast `::user_role` để nhét
  vào JWT claim `role`.
- Migration `20260701093424` (đã được REVERT thành no-op bằng
  `20260701095000_revert_to_simple_role_model.sql`) trước đây có UPDATE
  `auth.users.raw_user_meta_data` — đây là **sai cột** theo rule supabase
  (user_metadata user-editable, không an toàn cho authz).
- Hiện tại: NẾU có user nào có `raw_app_meta_data->>'role'` lưu giá trị
  không còn trong enum (ví dụ `'superadmin'`, `'accountant'` sau khi revert),
  JWT hook sẽ raise 22P02 và fail đăng nhập.

### Nguyên nhân gốc
Trong kiến trúc này, **`raw_user_meta_data` KHÔNG ĐƯỢC dùng cho authz**.
Authz phải lấy từ `raw_app_meta_data` (admin-only writable). Tuy nhiên nhiều
user có thể đã được set role qua:
- Dashboard Supabase (UI User management) — có thể set user_metadata
  lẫn app_metadata
- SQL trigger `on_auth_user_created` (`20260625200200`) hiện set
  `'staff'::user_role` mặc định khi user mới tạo (default an toàn)
- Manual update SQL trong quá trình dev

### Hướng xử lý (chưa làm)

Khi cần migrate users, dùng template sau (CHƯA RUN — cần owner duyệt):

```sql
-- 1. Khảo sát: liệt kê user có role không hợp lệ
SELECT id, email,
       raw_app_meta_data->>'role' AS appmeta_role,
       raw_user_meta_data->>'role' AS usermeta_role
FROM auth.users
WHERE raw_app_meta_data->>'role' NOT IN (
  SELECT enumlabel FROM pg_enum
  WHERE enumtypid = 'public.user_role'::regtype
);

-- 2. Với mỗi user, copy role từ user_metadata → app_metadata (nếu cần)
UPDATE auth.users
SET raw_app_meta_data =
  raw_app_meta_data ||
  jsonb_build_object('role', raw_user_meta_data->>'role')
WHERE raw_user_meta_data->>'role' IS NOT NULL
  AND (raw_app_meta_data->>'role') IS DISTINCT FROM (raw_user_meta_data->>'role');

-- 3. Nếu user đang dùng role không có trong enum mới, cần admin tự set lại
--    bằng Dashboard hoặc:
UPDATE auth.users
SET raw_app_meta_data =
  jsonb_set(raw_app_meta_data, '{role}', '"manager"')
WHERE email = 'someone@example.com';
```

### Mức độ ưu tiên
**LOW** (chỉ ảnh hưởng khi có user thật dùng những role bị rename). Hiện
project chỉ có 1 admin nên impact thấp. Tuy nhiên, NÊN chạy trước khi
launch pilot thật.

---

## 2. Pre-existing lint errors trong RPC procurement/inventory/reservation

### ✅ ĐÃ GIẢI QUYẾT (2026-07-02) — migration `20260701095100_fix_rpc_lint_errors.sql`

7 lỗi runtime `column does not exist` đã được fix. Chi tiết:

| Function | Trước | Sau |
|---|---|---|
| `get_suppliers` | `s.contact_info` | concat `s.contact_name / phone / email` (giữ RETURNS TABLE không đổi) |
| `get_ingredients` | `i.category` | `LEFT JOIN ingredient_categories ON ic.id = i.category_id`, trả `ic.name` |
| `get_current_stock` | `s.last_updated` | `s.updated_at` (alias về `last_updated` trong RETURNS) |
| `get_inventory_transactions` | `t.supplier_id` không tồn tại | ADD COLUMN `inventory_transactions.supplier_id` + JOIN suppliers |
| `record_inventory_transaction` | INSERT dùng `transaction_type` | Đổi sang `type`, ADD `unit_cost` + `supplier_id` columns, tính `balance_after` |
| `get_revenue_report` | `b.branch_id` (b là alias của branches) | `bi.branch_id` trong SELECT + GROUP BY |
| `create_reservation` | INSERT `guest_name, guest_phone` không tồn tại | ALTER reservations.customer_id DROP NOT NULL + ADD guest_name/guest_phone columns |

### Schema changes đi kèm (idempotent, không phá data)
- `inventory_transactions`: ADD `unit_cost numeric(14,2) DEFAULT 0`, ADD `supplier_id uuid REFERENCES suppliers(id)`
- `reservations`: ALTER `customer_id DROP NOT NULL`, ADD `guest_name text`, ADD `guest_phone text`

### Verify
- `db reset --local --no-seed`: pass (29 migrations)
- `db diff --local`: "No schema changes found" (self-contained)
- `db lint --local`: 7 errors → **0 errors** (5 warnings cosmetic về unused param/variable ở function khác)
- `pg_proc` introspection: 7/7 functions đều `is_security_definer=true` + có `SET search_path`
- `db push --dry-run --linked`: file này được push đúng vị trí (sau enum revert, trước CRM/Hall)

### Lý do dùng ADD COLUMN thay vì bỏ field
- `record_inventory_transaction` được frontend gọi với `p_supplier_id` + `p_unit_cost` →
  nếu DROP sẽ break callers. ADD column + dùng trong INSERT là safe và non-breaking.
- `create_reservation` cần `customer_id` nullable để support walk-in booking đúng
  theo design intent (đã có comment trong setup.sql 2026-06-23 về walk-in flow).

---

## 3. Đối chiếu migration history local ↔ remote

### ✅ ĐÃ GIẢI QUYẾT (2026-07-02) — see migration history sync section
- 3 migration mồ côi (`000005`, `000006`, `093424`) đã được tái dựng
  dưới dạng SQL file local.
- Migration `093424` được REVERT thành no-op; việc revert enum diễn ra
  ở migration mới `20260701095000_revert_to_simple_role_model.sql`.
- 2 file local-only (CRM `044658` + Hall `083325`) đã sửa role references
  để khớp với simple model.
- 1 migration fix lint `20260701095100_fix_rpc_lint_errors.sql` đã được tạo
  (mục 2 ở trên).
- `db reset --local`, `db diff --local`, `migration list --local`,
  `db push --dry-run --linked` đều PASS.

### Next steps (CHƯA làm) — cần user quyết
- Tạo branch `fix/migration-drift-sync` theo rule `§11.2 PROJECT_OVERVIEW.md`.
- Commit 5 file SQL mới/sửa + `docs/SUPABASE_AUTH_TODO.md`; KHÔNG stage các
  file M (useAccounting etc.) còn dở ở working tree.
- Push lên remote (bằng tay — memory rule: user tự push).

---

## 4. Rule Strict RPC + SECURITY DEFINER — checklist cuối

Mọi RPC mới tạo sau migration 000003/000004/000006 cần check:
- [ ] `CREATE OR REPLACE FUNCTION` không drop policy/trigger cũ.
- [ ] `SET search_path = public, auth` ở đầu function.
- [ ] Phân quyền qua `has_role()` + `current_branch_id()`, không hard-code branch_id.
- [ ] UPDATE/DELETE có CẢ `USING` + `WITH CHECK` (không thiếu).
- [ ] KHÔNG dùng `'admin'` hard-code — dùng `'admin'` đúng nghĩa `superadmin`
      đã revert về `admin` (current simple model).
- [ ] Function body không reference cột không tồn tại (xem mục 2).
