# SUPABASE_AUTH.md — Authentication & Authorization cho 5 Role

> NguuCat POS có 5 role: `admin`, `manager`, `reception`, `staff`, `kitchen`.
> Auth flow dùng Supabase Auth (email + password) + JWT custom claims để RLS phân quyền.

## 1. Tổng quan kiến trúc auth

```
User đăng nhập
  ↓
Supabase Auth (auth.users)
  ↓ (trigger handle_new_auth_user)
public.users (mirror + role + branch_id)
  ↓
JWT gắn claims: { role, branch_id }  (qua auth hook)
  ↓
Mọi query từ client → RLS dùng current_user_id() + current_branch_id() + has_role()
  ↓
Realtime subscription filter theo branch_id
```

## 2. Tạo user đầu tiên (Super Admin)

Vào **Supabase Dashboard → Authentication → Users → Add user → Create new user**:
- Email: `admin@nguucat.vn`
- Password: (random 16 chars, lưu password manager)
- Auto Confirm User: ✅

Sau khi tạo, copy `User UID`. Chạy SQL:

```sql
update public.users
set role = 'admin',
    branch_id = (select id from public.branches where code = 'B001'),
    full_name = 'System Admin',
    phone = '+84-xxx'
where email = 'admin@nguucat.vn';
```

## 3. Tạo user cho 5 role (template)

Mỗi user khi tạo qua Supabase Auth, trigger `handle_new_auth_user` sẽ tự mirror vào `public.users` với `role` lấy từ `raw_user_meta_data`. Cách thêm user:

**Cách A: Dashboard (1 user/lần)** — Authentication → Users → Add user → sau đó update `public.users.role` qua SQL.

**Cách B: SQL bulk (cho seed/test)**:

```sql
-- Tạo user qua auth.users + trigger tự chạy
-- (Supabase không cho insert trực tiếp auth.users nếu không có admin client)

-- Cách thực tế: dùng Admin API từ Edge Function hoặc Dashboard
-- Sau đó update role:

update public.users set role = 'manager', branch_id = (select id from public.branches where code = 'B001')
where email = 'manager.q1@nguucat.vn';

update public.users set role = 'reception', branch_id = (select id from public.branches where code = 'B001')
where email = 'reception.q1@nguucat.vn';

update public.users set role = 'staff', branch_id = (select id from public.branches where code = 'B001')
where email = 'staff.q1@nguucat.vn';
```

## 4. JWT Custom Claims (auth hook)

Để RLS dùng `current_branch_id()` và `has_role()` hiệu quả (không phải JOIN mỗi query), gắn role + branch_id vào JWT qua **Custom Access Token Hook**.

### 4.1. Tạo Edge Function `custom-access-token`

```bash
supabase functions new custom-access-token
```

File `supabase/functions/custom-access-token/index.ts`:

```ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const payload = await req.json()
  const userId = payload.user_id
  const claims = payload.claims ?? {}

  if (!userId) {
    return new Response(JSON.stringify({ error: 'user_id required' }), { status: 400 })
  }

  // Admin client để bypass RLS
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  const { data: user } = await supabaseAdmin
    .from('users')
    .select('role, branch_id')
    .eq('id', userId)
    .single()

  return new Response(
    JSON.stringify({
      ...claims,
      role: user?.role ?? 'staff',
      branch_id: user?.branch_id,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
```

### 4.2. Deploy + register hook

```bash
supabase functions deploy custom-access-token
```

Vào **Supabase Dashboard → Authentication → Hooks → Customize Access Token (JWT)**:
- **Hook URL**: copy URL của function vừa deploy, dạng `https://<project-ref>.supabase.co/functions/v1/custom-access-token`
- **Enabled**: ✅

Sau khi bật, mỗi JWT mới sẽ chứa:
```json
{
  "sub": "<user-uuid>",
  "email": "...",
  "role": "manager",
  "branch_id": "abc-xyz-...",
  "exp": ...
}
```

### 4.3. Update helper functions (dùng JWT claim, không query DB)

Sửa 2 helper trong schema (chạy sau khi hook hoạt động):

```sql
create or replace function public.current_branch_id()
returns uuid language sql stable as $$
  -- ưu tiên JWT claim, fallback query DB
  select coalesce(
    (current_setting('request.jwt.claims', true)::jsonb->>'branch_id')::uuid,
    (select branch_id from public.users where id = auth.uid())
  )
$$;

create or replace function public.has_role(roles user_role[])
returns boolean language sql stable as $$
  select coalesce(
    (current_setting('request.jwt.claims', true)::jsonb->>'role')::user_role = any(roles),
    exists (select 1 from public.users where id = auth.uid() and role = any(roles))
  )
$$;
```

→ Bây giờ RLS policies chạy nhanh, không phải subquery mỗi lần check.

## 5. Login flow trong Vue 3

### 5.1. Tạo Auth composable `src/composables/useAuth.ts`

```ts
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Session, User } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

type AppUser = Database['public']['Tables']['users']['Row']

const session = ref<Session | null>(null)
const profile = ref<AppUser | null>(null)
const loading = ref(true)

export function useAuth() {
  async function fetchProfile(userId: string) {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single()
    if (error) throw error
    profile.value = data
  }

  async function init() {
    const { data: { session: s } } = await supabase.auth.getSession()
    session.value = s
    if (s?.user) await fetchProfile(s.user.id)
    loading.value = false

    supabase.auth.onAuthStateChange(async (_event, newSession) => {
      session.value = newSession
      if (newSession?.user) await fetchProfile(newSession.user.id)
      else profile.value = null
    })
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut()
    session.value = null
    profile.value = null
  }

  const role = computed(() => profile.value?.role)
  const branchId = computed(() => profile.value?.branch_id)
  const isAuthenticated = computed(() => !!session.value)
  const isAdmin = computed(() => role.value === 'admin')
  const isManager = computed(() => role.value === 'admin' || role.value === 'manager')

  return {
    session, profile, loading,
    role, branchId, isAuthenticated, isAdmin, isManager,
    signIn, signOut, init,
  }
}
```

### 5.2. Khởi tạo trong `main.ts`

```ts
// src/main.ts
import { useAuth } from '@/composables/useAuth'

const app = createApp(App)
app.use(pinia)
app.use(router)
app.use(i18n)

useAuth().init()  // load session + listener

// Router guard — block nếu chưa login
router.beforeEach(async (to) => {
  const { isAuthenticated, loading } = useAuth()
  if (loading.value) return  // đợi init xong
  if (!isAuthenticated.value && to.name !== 'login') return { name: 'login' }
})

app.mount('#app')
```

### 5.3. Login page `src/views/LoginView.vue`

```vue
<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-pink-50 to-orange-50 p-4">
    <form @submit.prevent="onSubmit" class="kawaii-card p-8 w-full max-w-md space-y-5">
      <h1 class="text-3xl font-black text-center">🐂 NGƯU CÁT</h1>
      <p class="text-center text-sm text-gray-500">Đăng nhập POS</p>

      <div>
        <label class="text-xs font-bold text-gray-500">Email</label>
        <input v-model="email" type="email" required class="kawaii-input w-full" />
      </div>
      <div>
        <label class="text-xs font-bold text-gray-500">Mật khẩu</label>
        <input v-model="password" type="password" required minlength="8" class="kawaii-input w-full" />
      </div>

      <p v-if="error" class="text-sm text-red-600 font-bold">⚠ {{ error }}</p>

      <button type="submit" :disabled="submitting" class="kawaii-btn-primary w-full py-3">
        {{ submitting ? 'Đang đăng nhập...' : 'Đăng nhập' }}
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const email = ref('')
const password = ref('')
const error = ref('')
const submitting = ref(false)
const router = useRouter()
const { signIn, role } = useAuth()

async function onSubmit() {
  submitting.value = true
  error.value = ''
  try {
    await signIn(email.value, password.value)
    // redirect theo role
    const dest =
      role.value === 'admin'   ? '/admin/dashboard'   :
      role.value === 'manager' ? '/manager/dashboard' :
      role.value === 'reception' ? '/reception/dashboard' :
      role.value === 'staff'   ? '/staff/floor-plan'  :
      '/tablet/idle'
    router.push(dest)
  } catch (e: any) {
    error.value = e.message ?? 'Đăng nhập thất bại'
  } finally {
    submitting.value = false
  }
}
</script>
```

Thêm route login vào `src/router/index.ts`:

```ts
{ path: '/login', name: 'login', component: () => import('@/views/LoginView.vue') }
```

## 6. RLS — chi tiết cho 5 role

Schema đã có RLS scaffold. Bảng dưới liệt kê policy thực tế cho từng role × bảng. **Mặc định: mọi role chỉ thấy data trong `branch_id` của mình** (qua `current_branch_id()`).

| Bảng | admin | manager | reception | staff | kitchen |
|---|---|---|---|---|---|
| `branches` | ALL | SELECT (all) | SELECT (own) | SELECT (own) | SELECT (own) |
| `users` | ALL | SELECT + UPDATE (own branch) | SELECT (own) | SELECT (own) | – |
| `zones` | ALL | ALL (own) | ALL (own) | SELECT (own) | SELECT (own) |
| `tables` | ALL | ALL (own) | ALL (own) | SELECT (own) | SELECT (own) |
| `customers` | ALL | ALL (own) | ALL (own) | SELECT (own) | – |
| `menu_*`, `packages` | ALL | ALL (own) | SELECT (own) | SELECT (own) | SELECT (own) |
| `reservations` | ALL | ALL (own) | ALL (own) | SELECT (own) | – |
| `table_assignments` | ALL | ALL (own) | ALL (own) | ALL (own) | SELECT (own) |
| `orders`, `order_items` | ALL | ALL (own) | ALL (own) | INSERT + UPDATE (own) | SELECT (own) |
| `invoices` | ALL | ALL (own) | ALL (own) | – | – |
| `payments` | ALL | ALL (own) | ALL (own) | – | – |
| `vouchers` | ALL | ALL (own) | SELECT (own) | – | – |
| `voucher_redemptions` | ALL | ALL (own) | INSERT (own) | – | – |
| `deposits` | ALL | ALL (own) | ALL (own) | – | – |
| `shifts` | ALL | ALL (own) | ALL (own, chỉ của mình) | – | – |
| `kpi_targets` | ALL | ALL (own) | – | – | – |
| `marketing_costs` | ALL | ALL (own) | – | – | – |
| `audit_events` | SELECT | SELECT (own) | SELECT (own) | INSERT only | – |
| `notifications` | SELECT | SELECT (own) | SELECT (own) | SELECT (own) | – |
| `branch_settings` | ALL | ALL (own) | SELECT (own) | SELECT (own) | SELECT (own) |
| `system_events` | SELECT | – | – | – | – |

### 6.1. Helper function `current_user_role()`

```sql
-- Ưu tiên JWT claim, fallback DB
create or replace function public.current_user_role()
returns user_role language sql stable as $$
  select coalesce(
    (current_setting('request.jwt.claims', true)::jsonb->>'role')::user_role,
    (select role from public.users where id = auth.uid())
  )
$$;
```

### 6.2. Policy thực tế (copy sau khi hook xong)

Xóa mấy policy mẫu, chạy đoạn này:

```sql
-- ========== USERS ==========
create policy "users self read" on public.users
  for select using (id = auth.uid() or public.has_role(array['admin','manager']::user_role[]));
create policy "users admin write" on public.users
  for all using (public.has_role(array['admin']::user_role[]));

-- ========== RESERVATIONS ==========
-- Read: tất cả role trong branch
create policy "reservations read" on public.reservations
  for select using (branch_id = public.current_branch_id());
-- Insert: reception/manager/admin/staff (walk-in)
create policy "reservations insert" on public.reservations
  for insert with check (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception','staff']::user_role[])
  );
-- Update: reception/manager/admin (staff chỉ xem)
create policy "reservations update" on public.reservations
  for update using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ========== ORDERS ==========
create policy "orders read" on public.orders
  for select using (branch_id = public.current_branch_id());
create policy "orders write" on public.orders
  for all using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ========== ORDER ITEMS ==========
create policy "order_items read" on public.order_items
  for select using (branch_id = public.current_branch_id());
create policy "order_items write" on public.order_items
  for all using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  );

-- ========== INVOICES + PAYMENTS ==========
create policy "invoices read" on public.invoices
  for select using (branch_id = public.current_branch_id());
create policy "invoices write" on public.invoices
  for all using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception']::user_role[])
  );
create policy "payments read" on public.payments
  for select using (branch_id = public.current_branch_id());
create policy "payments write" on public.payments
  for all using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ========== TABLE_ASSIGNMENTS ==========
create policy "table_assignments read" on public.table_assignments
  for select using (branch_id = public.current_branch_id());
create policy "table_assignments write" on public.table_assignments
  for all using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ========== VOUCHERS ==========
create policy "vouchers read" on public.vouchers
  for select using (branch_id = public.current_branch_id() and is_active);
create policy "vouchers admin write" on public.vouchers
  for all using (
    public.has_role(array['admin','manager']::user_role[]) and
    branch_id = public.current_branch_id()
  );
create policy "voucher_redemptions read" on public.voucher_redemptions
  for select using (branch_id = public.current_branch_id());
create policy "voucher_redemptions reception write" on public.voucher_redemptions
  for insert with check (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ========== SHIFTS ==========
create policy "shifts read" on public.shifts
  for select using (branch_id = public.current_branch_id());
create policy "shifts own write" on public.shifts
  for all using (
    branch_id = public.current_branch_id() and
    (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  );

-- ========== BRANCH SETTINGS ==========
create policy "settings read" on public.branch_settings
  for select using (branch_id = public.current_branch_id() and is_active);
create policy "settings write" on public.branch_settings
  for all using (
    public.has_role(array['admin','manager']::user_role[]) and
    branch_id = public.current_branch_id()
  );

-- ========== AUDIT_EVENTS ==========
create policy "audit read" on public.audit_events
  for select using (
    branch_id = public.current_branch_id() and
    public.has_role(array['admin','manager','reception']::user_role[])
  );
create policy "audit insert" on public.audit_events
  for insert with check (branch_id = public.current_branch_id());

-- ========== KPI + MARKETING (manager+ only) ==========
create policy "kpi read" on public.kpi_targets
  for select using (branch_id is null or branch_id = public.current_branch_id());
create policy "kpi write" on public.kpi_targets
  for all using (public.has_role(array['admin','manager']::user_role[]));
create policy "marketing read" on public.marketing_costs
  for select using (branch_id = public.current_branch_id());
create policy "marketing write" on public.marketing_costs
  for all using (
    public.has_role(array['admin','manager']::user_role[]) and
    branch_id = public.current_branch_id()
  );
```

## 7. Audit helper — ghi log mọi mutation

Tạo helper trigger tự động ghi `audit_events` khi row thay đổi.

```sql
create or replace function public.write_audit()
returns trigger language plpgsql as $$
declare
  v_action text;
  v_payload jsonb;
  v_actor uuid := auth.uid();
  v_branch uuid := public.current_branch_id();
begin
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
  end if;

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], NEW.id, v_payload);

  return coalesce(NEW, OLD);
end$$;

-- Gắn cho các bảng tiền/booking
create trigger trg_audit_reservations after insert or update or delete on public.reservations
  for each row execute function public.write_audit('reservation');
create trigger trg_audit_orders after insert or update or delete on public.orders
  for each row execute function public.write_audit('order');
create trigger trg_audit_order_items after insert or update or delete on public.order_items
  for each row execute function public.write_audit('order_item');
create trigger trg_audit_payments after insert or update or delete on public.payments
  for each row execute function public.write_audit('payment');
create trigger trg_audit_invoices after insert or update or delete on public.invoices
  for each row execute function public.write_audit('invoice');
create trigger trg_audit_table_assignments after insert or update or delete on public.table_assignments
  for each row execute function public.write_audit('table_assignment');
create trigger trg_audit_shifts after insert or update or delete on public.shifts
  for each row execute function public.write_audit('shift');
```

## 8. Logout + session refresh

Đã có trong `useAuth.signOut()`. Mỗi lần session refresh (mỗi 1h), JWT mới có claim mới nhất.

Để force logout khi đổi role (admin promote lên manager):
```ts
// trong admin UI khi update role:
await supabase.auth.refreshSession()  // lấy JWT mới với claim mới
```

## 9. Password reset flow

Vào **Authentication → URL Configuration**, đặt **Site URL** = production domain.
Flow tự động: user bấm "Quên mật khẩu" → gọi `supabase.auth.resetPasswordForEmail(email, { redirectTo: 'https://pos.nguucat.vn/reset-password' })` → user click link trong email → mở trang reset → nhập password mới.

Vue page `src/views/ResetPasswordView.vue` (template chuẩn của Supabase, lược bỏ ở đây).

## 10. Multi-branch switch (admin only)

Admin có thể switch giữa các chi nhánh qua UI. Cách đơn giản nhất:
- Lưu `selected_branch_id` vào `localStorage` key `ngu-cat.selectedBranch`
- Mọi query dùng `eq('branch_id', selectedBranchId)` thay vì RLS tự scope
- Edge Function đọc `selected_branch_id` từ header `x-selected-branch` thay vì JWT claim khi admin

Trong `src/composables/useAuth.ts`:
```ts
const selectedBranchId = ref<string | null>(
  localStorage.getItem('ngu-cat.selectedBranch')
)
function selectBranch(branchId: string | null) {
  selectedBranchId.value = branchId
  if (branchId) localStorage.setItem('ngu-cat.selectedBranch', branchId)
  else localStorage.removeItem('ngu-cat.selectedBranch')
}
```

## 11. Checklist

- [ ] 5 user mẫu đã tạo qua Dashboard (admin/manager/reception/staff/kitchen) + update `public.users.role`/`branch_id`
- [ ] Edge Function `custom-access-token` deployed + Hook bật
- [ ] Helper functions updated để dùng JWT claim
- [ ] Full policy block ở mục 6.2 đã chạy
- [ ] `useAuth` composable + LoginView đã build
- [ ] Router guard chạy
- [ ] Test: login admin → query `select * from users` → thấy 5 user. Login staff → chỉ thấy 1 staff.
- [ ] Test: staff tạo order → RLS cho phép (own branch). Staff update payment → RLS từ chối.

→ Tiếp theo: đọc `SUPABASE_REALTIME.md` để wire live updates cho timeline + floor plan + KDS.
