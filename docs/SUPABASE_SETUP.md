# SUPABASE_SETUP.md — Thiết lập Supabase cho NguuCat POS

> File này là bước đầu tiên. Sau khi chạy xong, đọc `SUPABASE_IMPLEMENTATION.md` để build từng chức năng.

## 1. Tạo project Supabase

1. Vào <https://supabase.com/dashboard> → **New project**
2. Cấu hình:
   - **Name**: `nguucat-pos`
   - **Database password**: lưu vào password manager (cần dùng cho psql & migrations)
   - **Region**: `Singapore` (gần VN nhất, < 50ms từ HCMC)
   - **Plan**: Pro ($25/mo) — đã được budget duyệt cho 5 chi nhánh
3. Đợi ~2 phút để project spin up.

## 2. Lấy credentials

Vào **Project Settings → API**:

| Biến | Dùng cho |
|---|---|
| `Project URL` (e.g. `https://abcxyz.supabase.co`) | `VITE_SUPABASE_URL` |
| `anon public key` | `VITE_SUPABASE_ANON_KEY` (an toàn cho client) |
| `service_role secret` | **KHÔNG commit** — chỉ dùng Edge Functions/admin |
| `JWT Secret` | Custom JWT hooks nếu cần |

## 3. Cấu hình database

### 3.1. Extensions

Vào **Database → Extensions**, bật:
- `uuid-ossp` (đã có sẵn trong schema)
- `pgcrypto` (đã có sẵn)
- `pg_stat_statements` (optional, debug slow queries)

### 3.2. Chạy schema

Vào **SQL Editor → New query**, paste toàn bộ nội dung `docs/DATABASE_SCHEMA.sql` (đã sửa ở version 1.0) → **Run**.

Sau khi chạy xong, kiểm tra **Database → Tables**, phải thấy **23 bảng** (19 HIGH + 4 LOW):

```
HIGH: branches, users, zones, tables, customers, menu_categories, menu_items,
      packages, package_items, reservations, table_assignments, orders,
      order_items, invoices, payments, vouchers, voucher_redemptions,
      deposits, shifts, kpi_targets, marketing_costs
LOW:  audit_events, notifications, branch_settings, system_events
```

### 3.3. Enable Realtime

Vào **Database → Replication**, với mỗi bảng dưới đây, bật **"Enable Realtime"**:

- `reservations` — Manager/Reception timeline
- `tables` — Staff floor plan
- `table_assignments` — Staff open/seat events
- `orders` — Bếp KDS + Manager dashboard
- `order_items` — Bếp KDS
- `notifications` — Staff notification panel
- `vouchers` — Manager voucher counter (optional)

Hoặc chạy SQL (đã có sẵn trong schema, bỏ comment):

```sql
alter publication supabase_realtime add table public.reservations;
alter publication supabase_realtime add table public.tables;
alter publication supabase_realtime add table public.table_assignments;
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_items;
alter publication supabase_realtime add table public.notifications;
```

### 3.4. Auth.users → public.users trigger

Schema có trigger trong comment (mục 8). Bật lên:

```sql
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  insert into public.users (id, email, full_name, role, branch_id)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'staff'),
    (new.raw_user_meta_data->>'branch_id')::uuid
  )
  on conflict (id) do nothing;
  return new;
end$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();
```

### 3.5. Cấu hình Auth

Vào **Authentication → Providers**:

- **Email**: enabled (default)
- **Password**: enabled, min length = 8
- **Magic Link**: enabled (choị staff khi quên mật khẩu)
- **Anonymous**: DISABLED (chỉ tablet guest dùng sau khi pair với bàn)

Vào **Authentication → Email Templates**:
- Giữ template confirm, recovery mặc định.
- Tùy chỉnh **Subject** + **Body** có logo NguuCat + ngôn ngữ `vi`.

Vào **Authentication → URL Configuration**:
- **Site URL**: `https://pos.nguucat.vn` (production) hoặc `http://localhost:5173` (dev)
- **Redirect URLs**: thêm `http://localhost:5173/**` cho dev

### 3.6. Storage buckets

Vào **Storage → New bucket**:

| Bucket | Public | Dùng cho |
|---|---|---|
| `menu-images` | Yes | `menu_items.image_url`, `packages.image_url` |
| `customer-photos` | No | Staff chụp khách (có consent) |
| `invoices` | No | PDF hóa đơn đỏ VN |
| `audit-attachments` | No | Audit log evidence |

Cấu hình RLS cho mỗi bucket (sẽ viết ở `SUPABASE_IMPLEMENTATION.md` mục **Auth & Storage**).

## 4. Cấu hình Vue 3 frontend

### 4.1. Cài package

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH
npm install @supabase/supabase-js
```

### 4.2. Tạo file `.env`

Vào project root, tạo file `.env` (đã có trong `.gitignore`):

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-public-key>
```

### 4.3. Tạo Supabase client singleton

Tạo file `src/lib/supabase.ts`:

```ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl  = import.meta.env.VITE_SUPABASE_URL
const supabaseKey  = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in .env')
}

export const supabase = createClient<Database>(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,        // lưu localStorage để auto-login
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storageKey: 'ngu-cat.auth',
  },
  realtime: {
    params: { eventsPerSecond: 10 },  // throttle per client
  },
  global: {
    headers: { 'x-application-name': 'nguucat-pos' },
  },
})
```

### 4.4. Tạo file types `src/types/database.ts`

Lấy types tự động:

```bash
npx supabase gen types typescript --project-id <project-ref> --schema public > src/types/database.ts
```

(Nếu chưa cài CLI: `npm i -g supabase` hoặc dùng `npx`)

File này sẽ tự động sinh ~700 dòng types cho 23 bảng. Vue components sẽ có autocomplete chính xác.

## 5. Cấu hình Edge Functions (sẽ dùng nhiều)

### 5.1. Cài CLI

```bash
npm i -g supabase
supabase login
supabase link --project-ref <project-ref>
```

### 5.2. Tạo functions folder

```bash
mkdir -p supabase/functions
cd supabase/functions
supabase functions new check-in
supabase functions new checkout
supabase functions new close-shift
supabase functions new issue-tax-invoice
supabase functions new export-shift-csv
supabase functions new kds-push
```

(Code chi tiết từng function: xem `SUPABASE_FUNCTIONS.md`)

### 5.3. Set secrets

```bash
supabase secrets set VT_API_KEY=xxx        # cổng thuế điện tử VN
supabase secrets set PRINT_AGENT_URL=xxx   # máy in hóa đơn
supabase secrets set KDS_WS_URL=xxx        # kitchen display websocket
```

## 6. Cấu hình Vercel (deploy)

### 6.1. Tạo project

Vào <https://vercel.com/new>, import repo GitHub:
- **Framework Preset**: Vite
- **Build Command**: `npm run build`
- **Output Directory**: `dist`

### 6.2. Env vars

Vào **Settings → Environment Variables**, thêm:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Cả 3 môi trường (Production, Preview, Development).

### 6.3. Domain

Vào **Settings → Domains**, thêm `pos.nguucat.vn`. SSL tự động.

## 7. Checklist trước khi dev

- [ ] Project Supabase đã tạo, schema chạy thành công (23 bảng)
- [ ] Realtime enabled cho 7 bảng
- [ ] Auth trigger bật
- [ ] Storage buckets: `menu-images` (public), `customer-photos` (private)
- [ ] `.env` có `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`
- [ ] `npm install @supabase/supabase-js`
- [ ] `src/lib/supabase.ts` đã tạo
- [ ] `src/types/database.ts` đã generate
- [ ] Edge Function CLI login + link
- [ ] Vercel project ready, env vars set

→ Bắt đầu dev: đọc `SUPABASE_IMPLEMENTATION.md` mục **Auth & Login**, rồi đi theo thứ tự 5 role portals.
