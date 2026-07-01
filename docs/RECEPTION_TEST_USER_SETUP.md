# Hướng dẫn user test — Reception / Manager / Kitchen

Mục tiêu: có đủ 5 tài khoản test theo từng role, mỗi tài khoản gắn với đúng chi nhánh Q.1 để role matrix và RLS hoạt động đúng.

> Dev-only passwords. Không dùng các mật khẩu này cho production.

## 1. Tài Khoản

| # | Email | Password | Role | Branch | Cách tạo |
| --- | --- | --- | --- | --- | --- |
| 1 | `admin@nguucat.vn` | `Admin@2026` | `admin` | Q.1 | Đã có sẵn, tạo qua Supabase Dashboard |
| 2 | `quocphu02032005@gmail.com` | `Staff@2026` | `staff` | Q.1 | Đã có sẵn, tạo qua Supabase Dashboard |
| 3 | `manager.q1@nguucat.vn` | `Manager@2026` | `manager` | Q.1 | Tạo qua Supabase Dashboard |
| 4 | `reception.q1@nguucat.vn` | `Reception@2026` | `reception` | Q.1 | Tạo qua Supabase Dashboard |
| 5 | `kitchen.q1@nguucat.vn` | `Kitchen@2026` | `kitchen` | Q.1 | Tạo qua Supabase Dashboard |

## 2. Cách Tạo Đúng

Tạo 3 tài khoản mới bằng Supabase Dashboard để đồng nhất với 2 tài khoản cũ:

1. Vào `Authentication -> Users -> Add user -> Create new user`.
2. Tạo lần lượt:
   - `manager.q1@nguucat.vn` / `Manager@2026`
   - `reception.q1@nguucat.vn` / `Reception@2026`
   - `kitchen.q1@nguucat.vn` / `Kitchen@2026`
3. Bật `Auto Confirm User`.
4. Sau khi tạo xong cả 3 user, chạy SQL ở mục 3 trong SQL Editor.

Không tạo test users bằng migration insert trực tiếp vào `auth.users`. Cách đó dễ lệch với GoTrue/Dashboard flow và gây nhầm lẫn về password hash.

## 3. SQL Đồng Bộ Role/Branch

Chạy trong Supabase Dashboard SQL Editor sau khi đã tạo 3 auth users ở Dashboard:

```sql
do $$
declare
  v_branch_q1 uuid;
begin
  select id
    into v_branch_q1
    from public.branches
   where code = 'B001'
   limit 1;

  if v_branch_q1 is null then
    raise exception 'Không tìm thấy branch code=B001. Hãy chạy seed branch trước.';
  end if;

  insert into public.users (id, email, full_name, role, branch_id, is_active)
  select au.id,
         au.email,
         'Nguyễn Quản Lý',
         'manager'::public.user_role,
         v_branch_q1,
         true
    from auth.users au
   where au.email = 'manager.q1@nguucat.vn'
  on conflict (id) do update
    set email     = excluded.email,
        full_name = excluded.full_name,
        role      = excluded.role,
        branch_id = excluded.branch_id,
        is_active = true,
        updated_at = now();

  insert into public.users (id, email, full_name, role, branch_id, is_active)
  select au.id,
         au.email,
         'Trần Thu Ngân',
         'reception'::public.user_role,
         v_branch_q1,
         true
    from auth.users au
   where au.email = 'reception.q1@nguucat.vn'
  on conflict (id) do update
    set email     = excluded.email,
        full_name = excluded.full_name,
        role      = excluded.role,
        branch_id = excluded.branch_id,
        is_active = true,
        updated_at = now();

  insert into public.users (id, email, full_name, role, branch_id, is_active)
  select au.id,
         au.email,
         'Lê Bếp Trưởng',
         'kitchen'::public.user_role,
         v_branch_q1,
         true
    from auth.users au
   where au.email = 'kitchen.q1@nguucat.vn'
  on conflict (id) do update
    set email     = excluded.email,
        full_name = excluded.full_name,
        role      = excluded.role,
        branch_id = excluded.branch_id,
        is_active = true,
        updated_at = now();

  if not exists (select 1 from auth.users where email = 'manager.q1@nguucat.vn') then
    raise warning 'Chưa có auth user manager.q1@nguucat.vn';
  end if;

  if not exists (select 1 from auth.users where email = 'reception.q1@nguucat.vn') then
    raise warning 'Chưa có auth user reception.q1@nguucat.vn';
  end if;

  if not exists (select 1 from auth.users where email = 'kitchen.q1@nguucat.vn') then
    raise warning 'Chưa có auth user kitchen.q1@nguucat.vn';
  end if;
end $$;
```

## 4. Verify

```sql
select
  au.email,
  au.email_confirmed_at is not null as email_confirmed,
  pu.full_name,
  pu.role,
  pu.branch_id,
  b.code as branch_code,
  pu.is_active
from auth.users au
left join public.users pu on pu.id = au.id
left join public.branches b on b.id = pu.branch_id
where au.email in (
  'admin@nguucat.vn',
  'quocphu02032005@gmail.com',
  'manager.q1@nguucat.vn',
  'reception.q1@nguucat.vn',
  'kitchen.q1@nguucat.vn'
)
order by au.email;
```

Kỳ vọng:

- Có đủ 5 rows.
- `manager.q1@nguucat.vn` có role `manager`, branch code `B001`.
- `reception.q1@nguucat.vn` có role `reception`, branch code `B001`.
- `kitchen.q1@nguucat.vn` có role `kitchen`, branch code `B001`.
- `is_active = true`.

## 5. Refresh JWT

Project dùng custom access token hook để đưa `role` và `branch_id` từ `public.users` vào JWT. Sau khi update role/branch:

1. Logout khỏi app.
2. Login lại.

Dev-only, nếu muốn ép mọi user login lại:

```sql
delete from auth.sessions;
```

Không set role/branch bằng `user_metadata` hoặc `raw_user_meta_data`.
