# Tạo tài khoản admin@test.com — 24/06/2026

> Mục đích: hỗ trợ test role-based routing + RLS cho Supabase Auth.
> Không commit password thật vào GitHub.

## ⚠️ Bugs đã phát hiện & cần fix trước khi login

Trong quá trình verify auth flow, tôi phát hiện 3 bug ngăn không cho `admin@test.com` login và truy cập admin route:

| # | Bug | Triệu chứng | Fix |
|---|-----|-------------|-----|
| 1 | `VITE_SUPABASE_URL` trong `.env.local` có suffix `/rest/v1/` thừa | POST `/auth/v1/token` bị rewrite thành `/rest/v1/auth/v1/token` → 404 | Đã sửa trong file này — bạn **restart dev server** để Vite reload env |
| 2 | Hàm `current_user_role()` cast trực tiếp `'anon'` (PostgREST anon role) sang enum `user_role` | Mọi request anon tới bảng RLS đều lỗi `22P02 invalid input value for enum user_role: "anon"` → 400 | Migration mới `20260624000000_fix_current_user_role_anon.sql` (chưa push) |
| 3 | Trigger tạo `public.users.role='staff'` khi tạo user qua Dashboard (vì không có `user_metadata.role`) | Login OK nhưng router guard redirect admin về `/manager/dashboard` | UPDATE role sau khi tạo user |

### Fix 1: `.env.local` (đã sửa)

```bash
# SAI (gây 404)
VITE_SUPABASE_URL=https://zjtnmrcczkbcoxjlndva.supabase.co/rest/v1/

# ĐÚNG
VITE_SUPABASE_URL=https://zjtnmrcczkbcoxjlndva.supabase.co
```

`src/lib/supabase.ts` cũng đã thêm guard fail-fast nếu URL có suffix `/rest/v1/` hoặc `/auth/v1/`.

### Fix 2: Migration mới (cần push lên remote)

File `supabase/migrations/20260624000000_fix_current_user_role_anon.sql` đã sẵn. Chạy một trong 2 cách:

```bash
# Cách 1: CLI (khuyến nghị)
supabase db push

# Cách 2: Dán thẳng vào SQL Editor của Dashboard
# Nội dung file 20260624000000_fix_current_user_role_anon.sql
```

Migration này cập nhật `current_user_role()` whitelist JWT `role` claim trước khi cast, và làm `has_role()` an toàn hơn.

### Fix 3: UPDATE role cho admin@test.com

Sau khi đã tạo user (xem bên dưới), chạy trong SQL Editor:

```sql
update public.users
set role = 'admin',
    full_name = 'System Admin',
    branch_id = null
where email = 'admin@test.com';
```

---

## Thông tin tài khoản test

| Field | Value |
|-------|-------|
| Email | `admin@test.com` |
| Password | `Admin@123456` |
| Role | `admin` |
| Full name | `System Admin` |
| Branch | (để trống — admin thấy mọi chi nhánh) |

> ⚠️ **CHỈ dùng cho môi trường dev/test.** Không dùng password này ở production.

## Cách A — Qua Supabase Dashboard (khuyến nghị, an toàn nhất)

1. Mở https://supabase.com/dashboard/project/zjtnmrcczkbcoxjlndva/auth/users
2. Bấm **Add user** → **Create new user**
3. Điền:
   - **Email**: `admin@test.com`
   - **Password**: `Admin@123456`
   - **Auto Confirm User**: ✅ bật (bỏ qua email confirmation cho test nhanh)
4. Bấm **Create user**
5. Trigger `handle_new_auth_user()` tự chèn row vào `public.users` với role mặc định `'staff'`. Cần UPDATE để set role = `admin`:

   ```sql
   -- Chạy trong SQL Editor của Dashboard
   update public.users
   set role = 'admin',
       full_name = 'System Admin',
       branch_id = null
   where email = 'admin@test.com';
   ```

6. Verify:
   ```sql
   select id, email, full_name, role, branch_id
   from public.users
   where email = 'admin@test.com';
   -- Expect: role = 'admin', full_name = 'System Admin'
   ```

## Cách B — Qua SQL Editor (tự tạo cả auth.users + public.users)

> ⚠️ Cách này tạo user với password đã hash sẵn bằng extension `pgcrypto`.
> Chỉ dùng khi bạn không muốn vào Dashboard.

```sql
-- 1. Tạo auth user với password đã hash
insert into auth.users (
  instance_id, id, aud, role,
  email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@test.com',
  crypt('Admin@123456', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"System Admin","role":"admin"}',
  now(),
  now(),
  '', '', '', ''
);

-- 2. Trigger đã tự tạo row trong public.users (role = 'staff' do meta-data đã set nhưng ON CONFLICT DO NOTHING giữ row từ trigger lần đầu).
--    Nếu row chưa tồn tại, chạy thêm:
insert into public.users (id, email, full_name, role, branch_id)
select id, email, 'System Admin', 'admin'::user_role, null
from auth.users
where email = 'admin@test.com'
on conflict (id) do update
  set role = 'admin', full_name = 'System Admin', branch_id = null;
```

## Cách C — Qua Supabase Edge Function (production-grade)

Nếu muốn tự động seed admin account mỗi lần deploy:

1. Tạo edge function `create-test-admin` (dùng service-role key):
   ```ts
   // supabase/functions/create-test-admin/index.ts
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   const admin = createClient(
     Deno.env.get('SUPABASE_URL')!,
     Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
   )
   const { data, error } = await admin.auth.admin.createUser({
     email: 'admin@test.com',
     password: 'Admin@123456',
     email_confirm: true,
     user_metadata: { full_name: 'System Admin', role: 'admin' },
   })
   ```
2. Deploy: `supabase functions deploy create-test-admin`
3. Invoke một lần: `curl -X POST .../functions/v1/create-test-admin`

> ❌ **KHÔNG** tự ý thêm `SUPABASE_SERVICE_ROLE_KEY` vào `.env` của frontend Vite.
> Service role bypass RLS → lộ là lộ toàn bộ DB.

## Verify đăng nhập thành công

1. `npm run dev`
2. Mở http://localhost:5173/login
3. Đăng nhập với `admin@test.com` / `Admin@123456`
4. Router guard sẽ tự redirect sang `/admin/dashboard` (vì role = 'admin' và prefix `/admin` thuộc `ROUTE_ROLES.admin`).
5. Mở DevTools → Application → Local Storage → kiểm tra có `sb-zjtnmrcczkbcoxjlndva-auth-token`.

## ⚙️ Cấu hình Site URL trong Dashboard (BẮT BUỘC nếu bật "Confirm email")

> ℹ️ **Phạm vi áp dụng:** Từ đợt 6 (24/06/2026), frontend **KHÔNG** có chức năng tự đăng ký. Tài khoản chỉ do admin tạo qua Dashboard. Tuy nhiên, nếu trong tương lai bật lại `signUp()` hoặc bật "Confirm email" cho user mới do admin invite, Supabase vẫn sẽ gửi email chứa link xác nhận — link mặc định redirect về **Site URL** trong Dashboard. Nếu Site URL không trỏ tới dev server → `ERR_CONNECTION_REFUSED`.

**Khi bật lại `signUp()`, cần:** set `emailRedirectTo: window.location.origin` để link về đúng port dev server đang chạy (vd `http://localhost:5173`).

**Whitelist URL trong Dashboard** (bảo mật chống open redirect — luôn làm dù không dùng signUp):

1. Mở https://supabase.com/dashboard/project/zjtnmrcczkbcoxjlndva/auth/url-configuration
2. Mục **Site URL**: đặt thành `http://localhost:5173` (production thì đổi thành domain thật)
3. Mục **Redirect URLs** (whitelist): thêm các dòng sau (click "Add redirect URL" cho mỗi dòng):
   ```
   http://localhost:5173
   http://localhost:5173/**
   http://localhost:5173/login
   ```
   > Không cần `/register` nữa vì đã xoá route đó ở đợt 6.
4. Bấm **Save**

Khi user click link trong email, họ sẽ được đưa về `http://localhost:5173/#access_token=...` — Supabase client (với `detectSessionInUrl: true`) tự xử lý hash, lưu session, và route guard sẽ redirect họ về dashboard đúng role.

**Nếu vẫn lỗi ERR_CONNECTION_REFUSED sau khi whitelist:**
- Mở DevTools → Network tab
- Click link trong email
- Xem request đang gọi URL nào
- Nếu URL là `http://localhost:3000/...` → Site URL chưa được lưu hoặc cần hard refresh Dashboard
- Nếu URL là `http://localhost:5173/...` → vấn đề khác (xem Network response)

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|------|-------------|------------|
| `Invalid login credentials` | Email chưa confirm, hoặc password sai | Vào Dashboard → tick **Auto Confirm User** khi tạo |
| `Email not confirmed` | Email confirmation đang bật | Tắt confirmation trong Dashboard → Auth → Providers → Email, hoặc auto-confirm khi tạo |
| Login thành công nhưng bị redirect về `/manager/dashboard` thay vì `/admin/dashboard` | `public.users.role` chưa = 'admin' | Chạy lại UPDATE ở Fix 3 ở đầu file |
| `No match for {"name":"home"}` (router warning) | Frontend gọi `router.push({name:'home'})` — không tồn tại | **ĐÃ FIX** — dùng `getHomeRouteForRole(role)` thay thế (xem `src/utils/route.ts`) |
| `ERR_CONNECTION_REFUSED` khi click link trong email xác nhận | Supabase redirect về `Site URL` mặc định `http://localhost:3000` (port sai) | **ĐÃ FIX** (khi bật lại signUp) — set `emailRedirectTo: window.location.origin`. Cũng cần whitelist URL trong Dashboard (xem section trên). Hiện tại signUp bị xoá ở đợt 6 nên lỗi này không phát sinh từ flow của nhân viên. |
| 401 khi truy cập data | RLS policy chặn | Verify role trong JWT bằng cách SELECT `auth.jwt()` trong SQL Editor |
| `22P02 invalid input value for enum user_role: "anon"` | Hàm `current_user_role()` cũ crash với anon role | **ĐÃ FIX** — migration `20260624000000_fix_current_user_role_anon.sql` (cần `supabase db push`) |

## Lệnh cleanup (xóa tài khoản test khi xong)

```sql
-- Chạy trong SQL Editor
delete from public.users where email = 'admin@test.com';
delete from auth.users where email = 'admin@test.com';
```
