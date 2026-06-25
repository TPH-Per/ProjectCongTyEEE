# Custom Access Token Hook — Đăng ký trong Dashboard

> **Mục đích:** Khi user đăng nhập, hook sẽ chạy, đọc `users.role` +
> `users.branch_id` từ DB, gắn vào JWT `app_metadata`. RLS policies + frontend
> đọc được trực tiếp từ JWT mà không cần query lại.
>
> **Hiện trạng (đã làm):**
> - ✅ Edge Function `custom-access-token` deployed lên live
>   → URL: `https://zjtnmrcczkbcoxjlndva.supabase.co/functions/v1/custom-access-token`
> - ✅ Postgres function `public.custom_access_token_hook(event jsonb)` đã
>   tạo trong live DB, grants đúng (chỉ `supabase_auth_admin` có execute)
> - ❌ **Hook CHƯA đăng ký trong Dashboard** — bạn cần chọn 1 trong 2 option dưới

---

## 2 option để đăng ký hook

Supabase Dashboard cho phép chọn 1 trong 2 loại hook target:

| | **Option A: Postgres Function** ✅ Khuyến nghị | **Option B: Edge Function** |
|---|---|---|
| **Cái gì được gọi** | `public.custom_access_token_hook(event jsonb)` | URL Edge Function |
| **Cái này đã có chưa** | ✅ Đã tạo trong live DB | ✅ Đã deploy |
| **Ưu** | Gọi qua pg_net trong cùng DB → latency thấp nhất, không qua internet | Code Deno, dễ sửa/redeploy |
| **Nhược** | Phải edit SQL để thay đổi logic | Mỗi lần sửa phải `supabase functions deploy` |

**Mình khuyến nghị Option A** vì hook chỉ query 1 row, latency quan trọng hơn flexibility, và function đã verify hoạt động trên live.

---

## Option A: Postgres Function (khuyến nghị)

### A1. Mở trang Hooks
```
https://supabase.com/dashboard/project/zjtnmrcczkbcoxjlndva/auth/hooks?hook=custom-access-token-claims
```

### A2. Tìm card "Custom Access Token Hook"
- Click **"Enable"** (nếu chưa enable)
- Một form config xuất hiện

### A3. Chọn type = "Postgres Function"
- Thường là dropdown / radio:
  - **Edge Function** ← KHÔNG chọn cái này
  - **Postgres Function** ← CHỌN cái này
- Một dropdown mới xuất hiện: "Select function"

### A4. Pick function
- Dropdown sẽ list các function public.* có signature `(event jsonb) returns jsonb`
- Chọn: **`custom_access_token_hook`**
- Nếu KHÔNG thấy function này:
  - Refresh trang (F5)
  - Function vừa apply, đôi khi cần 10-30s để Dashboard detect
  - Hoặc check function tồn tại: vào SQL editor chạy
    ```sql
    select proname from pg_proc where proname = 'custom_access_token_hook';
    ```

### A5. Save
- Click nút Save / Confirm
- Dashboard sẽ test ping function → phải pass

### A6. Verify
- Đăng nhập lại với 1 user bất kỳ
- DevTools → Application → Local Storage → tìm `sb-zjtnmrcczkbcoxjlndva-auth-token`
- Decode JWT → phần `app_metadata` phải có:
  ```json
  { "role": "admin", "branch_id": "uuid" }
  ```

---

## Option B: Edge Function (alternative)

### B1. Mở cùng trang
```
https://supabase.com/dashboard/project/zjtnmrcczkbcoxjlndva/auth/hooks?hook=custom-access-token-claims
```

### B2. Chọn type = "Edge Function"
- Dropdown chọn **Edge Function** (không phải Postgres Function)

### B3. Paste URL
```
https://zjtnmrcczkbcoxjlndva.supabase.co/functions/v1/custom-access-token
```

### B4. Save
- Cùng các bước verify như Option A6

---

## Nếu bạn không thấy dropdown "Type"

Một số version Dashboard cũ chỉ cho phép 1 loại. Nếu chỉ thấy input "Function URL" → Dashboard của bạn đang ở mode Edge Function → dùng Option B.

Nếu chỉ thấy dropdown "Select function" (không có type selector) → Dashboard đang ở mode Postgres → dùng Option A. Function `custom_access_token_hook` sẽ ở trong list (sau khi refresh).

---

## Rollback (1 trong 2 cách)
- Vào lại trang Hooks → tắt toggle "Enable"
- KHÔNG cần xóa function/edge (chỉ cần unbind)

## Nếu user JWT cũ chưa có claims
User phải **đăng xuất + đăng nhập lại** (hoặc chờ JWT refresh) để JWT mới
chứa `app_metadata.role` + `app_metadata.branch_id`.

JWT cũ vẫn valid cho đến khi expire (mặc định 1 giờ) — trong thời gian đó
RLS vẫn dùng DB fallback `coalesce(jwt_claim, lookup)` nên app không broken.

## Liên quan
- **Postgres function** (Option A): `supabase/migrations/20260625080844_auth_hook_custom_access_token.sql`
  - Đã apply: ✅ (verified qua `pg_proc` + grants)
- **Edge Function** (Option B): `supabase/functions/custom-access-token/index.ts`
  - Đã deploy: ✅ (HTTP 500 khi gọi trực tiếp = function tồn tại, chỉ thiếu payload đúng)
- **Fallback path** (khi hook fail): `coalesce(jwt_claim, select role from users where id = auth.uid())` trong DB functions `current_user_role()` + `current_branch_id()` — **vẫn an toàn nếu hook không hoạt động**.
