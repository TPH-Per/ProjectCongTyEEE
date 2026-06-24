# EXECUTION PLAYBOOK — Hướng dẫn Agent thực thi, kiểm thử, deploy và nối API

> **Mục đích:** Agent đọc file này để biết chính xác THỨ TỰ thực hiện, CÁCH kiểm thử từng bước, CÁCH deploy, và CÁCH nối API vào frontend.
> **Đọc trước:** `API_IMPLEMENTATION_GUIDE.md` (WHAT to do) → file này (HOW to do it, step by step).

---

## MỤC LỤC

1. [Quy tắc vàng](#1-quy-tắc-vàng)
2. [Phase 0 — Infrastructure Setup](#2-phase-0--infrastructure-setup)
3. [Phase 1 — Auth Flow](#3-phase-1--auth-flow)
4. [Phase 2 — Core Composables](#4-phase-2--core-composables)
5. [Phase 3 — Edge Functions Deploy + Test](#5-phase-3--edge-functions-deploy--test)
6. [Phase 4 — Wire Frontend (từng Portal)](#6-phase-4--wire-frontend)
7. [Phase 5 — Realtime Integration](#7-phase-5--realtime-integration)
8. [Phase 6 — End-to-End Testing](#8-phase-6--end-to-end-testing)
9. [Phase 7 — Production Deploy](#9-phase-7--production-deploy)
10. [Troubleshooting](#10-troubleshooting)
11. [Rollback Strategy](#11-rollback-strategy)

---

## 1. Quy tắc vàng

> [!CAUTION]
> Agent PHẢI tuân thủ các quy tắc này trong suốt quá trình thực thi.

1. **Không bao giờ hardcode credentials** — dùng `.env` hoặc `supabase secrets`
2. **Không sửa `DATABASE_SCHEMA.sql` trực tiếp** — tạo migration file riêng
3. **Mỗi composable phải có error handling** — `try/catch` + user-friendly error message
4. **Test từng bước trước khi đi tiếp** — không skip test
5. **Commit sau mỗi phase hoàn thành** — dễ rollback
6. **HIGH consistency tables** = FK enforced, transactions. **LOW** = no FK, append-only
7. **Realtime subscriptions phải cleanup** trong `onUnmounted`
8. **Mọi query phải filter `branch_id`** — multi-tenant by default

---

## 2. Phase 0 — Infrastructure Setup

### Bước 0.1: Cài dependencies

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH
npm install @supabase/supabase-js
```

**Verify:** Kiểm tra `package.json` có `@supabase/supabase-js` (đã có sẵn `^2.108.2`)

### Bước 0.2: Tạo `.env`

```bash
# File: .env (project root)
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

**Verify:**
```bash
# Phải thấy file .env tồn tại
dir .env
# Kiểm tra .gitignore có chứa .env
findstr ".env" .gitignore
```

### Bước 0.3: Tạo Supabase client

Tạo file `src/lib/supabase.ts` — code đầy đủ trong `API_IMPLEMENTATION_GUIDE.md` §2.

**Verify:**
```ts
// Test nhanh trong browser console (sau khi npm run dev):
import { supabase } from '@/lib/supabase'
const { data, error } = await supabase.from('branches').select('*')
console.log('branches:', data, 'error:', error)
// Phải trả về data (có thể rỗng nếu chưa seed) và error = null
```

### Bước 0.4: Generate TypeScript types

```bash
npx supabase gen types typescript --project-id <project-ref> --schema public > src/types/database.ts
```

**Verify:** File `src/types/database.ts` phải có ~700 dòng, chứa `Database` interface.

### Bước 0.5: Tạo types thủ công (models)

Tạo `src/types/models.ts` — code đầy đủ trong `API_IMPLEMENTATION_GUIDE.md` §4.

**✅ Phase 0 checkpoint:** Chạy `npm run dev` → không lỗi TypeScript.

---

## 3. Phase 1 — Auth Flow

### Bước 1.1: Tạo `useAuth` composable

File: `src/composables/useAuth.ts`  
Source: `docs/SUPABASE_AUTH.md` §5.1

### Bước 1.2: Tạo LoginView

File: `src/views/LoginView.vue`  
Source: `docs/SUPABASE_AUTH.md` §5.3

### Bước 1.3: Thêm route `/login`

```ts
// Thêm vào src/router/index.ts ở đầu routes array:
import LoginView from '@/views/LoginView.vue'

// Trong const routes = [
{
  path: '/login',
  name: 'login',
  component: LoginView,
  meta: { requiresAuth: false },
},
```

### Bước 1.4: Thêm router guard vào main.ts

```ts
// src/main.ts — thêm sau app.use(router):
import { useAuth } from '@/composables/useAuth'

const { init } = useAuth()
init() // load session + listener

router.beforeEach(async (to) => {
  const { isAuthenticated, loading, role } = useAuth()
  // Đợi init xong
  if (loading.value) {
    await new Promise<void>(resolve => {
      const check = setInterval(() => {
        if (!loading.value) { clearInterval(check); resolve() }
      }, 50)
    })
  }
  if (to.meta.requiresAuth === false) return // login page
  if (!isAuthenticated.value) return { name: 'login' }
})
```

### Bước 1.5: Deploy `custom-access-token` Edge Function

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH
mkdir -p supabase\functions\custom-access-token
# Tạo file supabase/functions/custom-access-token/index.ts
# Code: docs/SUPABASE_AUTH.md §4.1

supabase functions deploy custom-access-token
```

Sau khi deploy → vào **Supabase Dashboard → Authentication → Hooks → Customize Access Token** → enable + paste function URL.

### Bước 1.6: Tạo test users

Vào **Supabase Dashboard → Authentication → Users → Add user**:

| Email | Password | Role (update sau) |
|-------|----------|-------------------|
| `admin@nguucat.vn` | (16 chars random) | admin |
| `manager.q1@nguucat.vn` | (16 chars random) | manager |
| `reception.q1@nguucat.vn` | (16 chars random) | reception |
| `staff.q1@nguucat.vn` | (16 chars random) | staff |
| `kitchen.q1@nguucat.vn` | (16 chars random) | kitchen |

Chạy SQL update role:

```sql
UPDATE public.users SET role = 'admin',
  branch_id = (SELECT id FROM public.branches WHERE code = 'B001')
WHERE email = 'admin@nguucat.vn';

UPDATE public.users SET role = 'manager',
  branch_id = (SELECT id FROM public.branches WHERE code = 'B001')
WHERE email = 'manager.q1@nguucat.vn';

UPDATE public.users SET role = 'reception',
  branch_id = (SELECT id FROM public.branches WHERE code = 'B001')
WHERE email = 'reception.q1@nguucat.vn';

UPDATE public.users SET role = 'staff',
  branch_id = (SELECT id FROM public.branches WHERE code = 'B001')
WHERE email = 'staff.q1@nguucat.vn';

UPDATE public.users SET role = 'kitchen',
  branch_id = (SELECT id FROM public.branches WHERE code = 'B001')
WHERE email = 'kitchen.q1@nguucat.vn';
```

### TEST Phase 1

```
TEST-AUTH-01: Mở http://localhost:5173 → redirect đến /login ✅
TEST-AUTH-02: Login admin@nguucat.vn → redirect /admin/dashboard ✅
TEST-AUTH-03: Login manager.q1@nguucat.vn → redirect /manager/dashboard ✅
TEST-AUTH-04: Login reception.q1@nguucat.vn → redirect /reception/dashboard ✅
TEST-AUTH-05: Login staff.q1@nguucat.vn → redirect /staff/floor-plan ✅
TEST-AUTH-06: Logout → redirect /login ✅
TEST-AUTH-07: Truy cập /admin/* khi đang login staff → redirect /login ✅
TEST-AUTH-08: Refresh page → vẫn giữ session (auto-login) ✅
```

**✅ Phase 1 checkpoint:** 5 users login thành công, redirect đúng role, guard hoạt động.

```bash
git add -A && git commit -m "Phase 1: Auth flow complete - login, guards, JWT claims"
```

---

## 4. Phase 2 — Core Composables

> Tạo từng composable theo thứ tự dependency.

### Thứ tự tạo file

```
1. src/composables/useBranch.ts      ← không phụ thuộc gì ngoài useAuth
2. src/composables/useRealtime.ts    ← cần useAuth (lấy branchId)
3. src/composables/useReservation.ts ← CRUD reservations
4. src/composables/useTable.ts       ← CRUD zones + tables
5. src/composables/useMenu.ts        ← CRUD menu + packages
6. src/composables/useCustomer.ts    ← CRUD customers
7. src/composables/useKPI.ts         ← CRUD kpi_targets
8. src/composables/useAudit.ts       ← SELECT audit_events
9. src/composables/useMarketing.ts   ← CRUD marketing_costs
10. src/composables/useInventory.ts  ← CRUD inventory_items + txns
11. src/composables/useReport.ts     ← Aggregate queries
12. src/composables/useCheckIn.ts    ← Edge Function wrapper
13. src/composables/useOrder.ts      ← Edge Function wrapper
14. src/composables/useCheckout.ts   ← Edge Function wrapper
15. src/composables/useShift.ts      ← Edge Function wrapper
16. src/composables/useKDS.ts        ← Edge Function wrapper
17. src/composables/useTaxInvoice.ts ← Edge Function wrapper
```

### Template cho CRUD composable

Mỗi CRUD composable theo pattern sau (ví dụ `useMenu.ts`):

```ts
// src/composables/useMenu.ts
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { MenuCategory, MenuItem } from '@/types/models'

export function useMenu() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  // ── SELECT ──────────────────────────────────
  async function getCategories(): Promise<MenuCategory[]> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .from('menu_categories')
        .select('id, name, sort_order, is_active')
        .eq('branch_id', activeBranchId.value!)
        .order('sort_order')
      if (err) throw err
      return data ?? []
    } catch (e: any) {
      error.value = e.message
      return []
    } finally {
      loading.value = false
    }
  }

  async function getItemsByCategory(categoryId: string): Promise<MenuItem[]> {
    const { data, error: err } = await supabase
      .from('menu_items')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .eq('category_id', categoryId)
      .order('name')
    if (err) throw err
    return data ?? []
  }

  // ── INSERT ──────────────────────────────────
  async function createItem(item: Partial<MenuItem>) {
    const { data, error: err } = await supabase
      .from('menu_items')
      .insert({ ...item, branch_id: activeBranchId.value! })
      .select()
      .single()
    if (err) throw err
    return data
  }

  // ── UPDATE ──────────────────────────────────
  async function updateItem(id: string, updates: Partial<MenuItem>) {
    const { data, error: err } = await supabase
      .from('menu_items')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (err) throw err
    return data
  }

  // ── TOGGLE ──────────────────────────────────
  async function toggleAvailable(id: string, current: boolean) {
    return updateItem(id, { is_available: !current })
  }

  return {
    loading, error,
    getCategories, getItemsByCategory,
    createItem, updateItem, toggleAvailable,
  }
}
```

### Template cho Edge Function wrapper

```ts
// src/composables/useCheckIn.ts
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

interface CheckInPayload {
  reservationId?: string
  walkIn?: { customerName: string; customerPhone?: string; guests: number; notes?: string }
  tableIds: string[]
  partySize: { male: number; female: number; children: number; ageBucket: string; nationality?: string }
  packageId?: string
  flowMode: 'one_way' | 'free'
}

interface CheckInResult {
  ok: boolean
  customerId: string
  assignments: Array<{ id: string; table_id: string }>
  package: any
}

export function useCheckIn() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function checkIn(payload: CheckInPayload): Promise<CheckInResult | null> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.functions.invoke('check-in', {
        body: payload,
      })
      if (err) throw err
      if (data?.error) throw new Error(data.error)
      return data as CheckInResult
    } catch (e: any) {
      error.value = e.message ?? 'Check-in thất bại'
      return null
    } finally {
      loading.value = false
    }
  }

  return { checkIn, loading, error }
}
```

### TEST Phase 2

```
TEST-COMP-01: useMenu().getCategories() → trả về array (có thể rỗng) ✅
TEST-COMP-02: useMenu().createItem({ name: 'Test', price: 100000, cost: 50000, category_id: '...' }) → trả về item ✅
TEST-COMP-03: useMenu().toggleAvailable(id, true) → is_available = false ✅
TEST-COMP-04: useTable().getZones() → trả về array ✅
TEST-COMP-05: useReservation().getTodayReservations() → trả về array ✅
```

**✅ Phase 2 checkpoint:** 17 composables tạo xong, import không lỗi.

```bash
git add -A && git commit -m "Phase 2: Core composables - 17 files"
```

---

## 5. Phase 3 — Edge Functions Deploy + Test

### Bước 3.1: Tạo shared modules

```bash
mkdir -p supabase\functions\_shared
```

Tạo `supabase/functions/_shared/cors.ts` và `supabase/functions/_shared/auth.ts` — code trong `SUPABASE_FUNCTIONS.md` §2.

### Bước 3.2: Tạo 9 Edge Functions

| # | Function | Source |
|---|----------|--------|
| 1 | `check-in/index.ts` | SUPABASE_FUNCTIONS.md §3.2 |
| 2 | `add-order-item/index.ts` | SUPABASE_FUNCTIONS.md §4 |
| 3 | `checkout/index.ts` | SUPABASE_FUNCTIONS.md §5 |
| 4 | `close-shift/index.ts` | SUPABASE_FUNCTIONS.md §6 |
| 5 | `export-shift-csv/index.ts` | SUPABASE_FUNCTIONS.md §7 |
| 6 | `kds-push/index.ts` | SUPABASE_FUNCTIONS.md §8 |
| 7 | `issue-tax-invoice/index.ts` | SUPABASE_FUNCTIONS.md §9 |
| 8 | `request-checkout/index.ts` | SUPABASE_FUNCTIONS.md §10 |
| 9 | `custom-access-token/index.ts` | SUPABASE_AUTH.md §4.1 |

### Bước 3.3: Deploy tất cả

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH

supabase functions deploy custom-access-token --no-verify-jwt
supabase functions deploy check-in --no-verify-jwt
supabase functions deploy add-order-item --no-verify-jwt
supabase functions deploy checkout --no-verify-jwt
supabase functions deploy close-shift --no-verify-jwt
supabase functions deploy export-shift-csv --no-verify-jwt
supabase functions deploy kds-push --no-verify-jwt
supabase functions deploy issue-tax-invoice --no-verify-jwt
supabase functions deploy request-checkout --no-verify-jwt
```

> **Note:** `--no-verify-jwt` vì functions tự verify JWT bên trong via `requireUser()`.

### Bước 3.4: Set secrets

```bash
supabase secrets set VT_API_KEY=<your-vnpt-api-key>
supabase secrets set VT_API_URL=https://api.vntax.vn/v1/invoices
```

### TEST Phase 3 — API Smoke Tests

Dùng curl hoặc Postman. Lấy token trước:

```bash
# Lấy JWT token
$TOKEN = (Invoke-RestMethod -Method POST `
  -Uri "https://<ref>.supabase.co/auth/v1/token?grant_type=password" `
  -Headers @{ "apikey" = "<anon-key>"; "Content-Type" = "application/json" } `
  -Body '{"email":"staff.q1@nguucat.vn","password":"<password>"}' `
).access_token

Write-Host "Token: $TOKEN"
```

**Test check-in:**

```bash
Invoke-RestMethod -Method POST `
  -Uri "https://<ref>.supabase.co/functions/v1/check-in" `
  -Headers @{ "Authorization" = "Bearer $TOKEN"; "Content-Type" = "application/json" } `
  -Body '{
    "walkIn": {"customerName":"Test Guest","guests":2},
    "tableIds": ["<table-uuid>"],
    "partySize": {"male":1,"female":1,"children":0,"ageBucket":"30-40"},
    "flowMode": "free"
  }'
```

**Expected response:**
```json
{ "ok": true, "customerId": "...", "assignments": [...], "package": {} }
```

**Test checklist:**

```
TEST-EF-01: check-in (walk-in) → ok: true, table status = occupied ✅
TEST-EF-02: check-in (reservation) → ok: true, reservation status = Dining ✅
TEST-EF-03: check-in (bàn đã occupied) → error: "Bàn X không khả dụng" ✅
TEST-EF-04: add-order-item → ok: true, order_items count + 1 ✅
TEST-EF-05: add-order-item (item_limit exceeded) → error: "Đã đạt giới hạn" ✅
TEST-EF-06: add-order-item (menu unavailable) → error: "Món tạm hết" ✅
TEST-EF-07: kds-push → ok: true, notifications table has new row ✅
TEST-EF-08: request-checkout → ok: true, audit_events + notifications ✅
TEST-EF-09: checkout (cash) → ok: true, invoice created, table released ✅
TEST-EF-10: checkout (voucher invalid) → error message ✅
TEST-EF-11: checkout (amount mismatch) → error: "Tổng thanh toán ≠ tổng bill" ✅
TEST-EF-12: close-shift → ok: true, cash_difference correct ✅
TEST-EF-13: export-shift-csv → CSV file downloaded ✅
TEST-EF-14: issue-tax-invoice (valid MST) → ok: true (hoặc VT API mock) ✅
TEST-EF-15: issue-tax-invoice (invalid MST) → error: "MST không hợp lệ" ✅
```

**✅ Phase 3 checkpoint:** 9 Edge Functions deployed, 15 tests pass.

```bash
git add -A && git commit -m "Phase 3: 9 Edge Functions deployed and tested"
```

---

## 6. Phase 4 — Wire Frontend

### Nguyên tắc nối API vào View

```
Bước 1: Import composable
Bước 2: Khai báo reactive state (ref)
Bước 3: Tạo load function (gọi composable)
Bước 4: Gọi load trong onMounted
Bước 5: Bind data vào template (thay thế mock data)
Bước 6: Wire user actions (button click → composable mutation)
Bước 7: Thêm loading/error states vào UI
```

### Pattern chung cho mỗi view

```vue
<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useRealtime } from '@/composables/useRealtime'
// Import domain composable
import { useMenu } from '@/composables/useMenu'
import type { MenuItem } from '@/types/models'

// ── State ────────────────────────
const items = ref<MenuItem[]>([])
const loading = ref(true)
const errorMsg = ref<string | null>(null)

// ── Composables ──────────────────
const { getItemsByCategory, updateItem, toggleAvailable } = useMenu()
const { watchTable } = useRealtime()
const cleanupFns: Array<() => void> = []

// ── Load ─────────────────────────
async function loadData() {
  loading.value = true
  errorMsg.value = null
  try {
    items.value = await getItemsByCategory('...')
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    loading.value = false
  }
}

// ── Actions ──────────────────────
async function handleToggle(item: MenuItem) {
  try {
    await toggleAvailable(item.id, item.is_available)
    // Optimistic update
    item.is_available = !item.is_available
  } catch (e: any) {
    errorMsg.value = e.message
  }
}

// ── Lifecycle ────────────────────
onMounted(async () => {
  await loadData()
  // Realtime subscription
  cleanupFns.push(
    watchTable('menu_items', 'UPDATE', () => loadData())
  )
})

onUnmounted(() => {
  cleanupFns.forEach(fn => fn())
})
</script>

<template>
  <!-- Loading state -->
  <div v-if="loading" class="flex items-center justify-center h-64">
    <div class="animate-spin rounded-full h-8 w-8 border-2 border-pink-500 border-t-transparent"></div>
  </div>

  <!-- Error state -->
  <div v-else-if="errorMsg" class="kawaii-card p-6 border-red-200 bg-red-50">
    <p class="text-red-600 font-bold">⚠ {{ errorMsg }}</p>
    <button @click="loadData" class="kawaii-btn-ghost mt-2">Thử lại</button>
  </div>

  <!-- Data state -->
  <div v-else>
    <!-- ... existing template with mock data replaced by `items` ... -->
  </div>
</template>
```

### Thứ tự wire views (theo luồng nghiệp vụ POS)

> Wire theo thứ tự flow thực tế: Check-in → Order → KDS → Checkout → Close Shift → Reports

#### 4A: Reception Portal (Core POS)

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 1 | `ReceptionDashboardView` | `useReservation`, `useTable`, `useRealtime`, `useShift` | Replace mock reservations/tables với Supabase queries. Thêm "Open Shift" button. |
| 2 | `ReceptionCheckoutView` | `useCheckout`, `useCustomer`, `useRealtime` | Replace mock order/items. Wire "Thanh toán" button → `checkout` Edge Function. |
| 3 | `ReceptionCloseShiftView` | `useShift`, `useReport` | Replace mock shift data. Wire "Đóng ca" → `close-shift` Edge Function. |

**TEST Reception:**
```
TEST-REC-01: Dashboard hiển thị reservations từ DB ✅
TEST-REC-02: Active tables realtime update ✅
TEST-REC-03: Checkout flow: select order → payment → invoice created ✅
TEST-REC-04: Close shift: cash difference tính đúng ✅
TEST-REC-05: Export CSV: file tải về có data ✅
```

#### 4B: Staff Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 4 | `StaffFloorPlanView` | `useTable`, `useRealtime` | Replace mock tables → Supabase query. Realtime status updates. |
| 5 | `StaffOpenTableView` | `useCheckIn`, `useTable` | Wire check-in form → Edge Function. |
| 6 | `StaffActiveTablesView` | `useTable`, `useOrder`, `useRealtime` | Replace mock active tables. |
| 7 | `StaffInDiningCRMView` | `useCustomer` | Replace mock customer data. |

**TEST Staff:**
```
TEST-STF-01: Floor plan shows tables from DB with correct status ✅
TEST-STF-02: Click table → open table form → check-in → table becomes occupied ✅
TEST-STF-03: Active tables shows elapsed time, items count ✅
TEST-STF-04: CRM shows customer history ✅
```

#### 4C: Tablet Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 8 | `TabletIdleView` | `useRealtime` | Realtime: wake up khi table assigned. |
| 9 | `TabletOrderView` | `useMenu`, `useOrder`, `useKDS`, `useRealtime` | Replace mock menu → DB. Wire "Thêm món" + "Gửi bếp". |
| 10 | `TabletCheckoutView` | `useCheckout`, `useRealtime` | Wire "Yêu cầu thanh toán" → Edge Function. |

**TEST Tablet:**
```
TEST-TAB-01: Menu categories + items load from DB ✅
TEST-TAB-02: Add item → order_items count updates ✅
TEST-TAB-03: Item limit enforced (buffet package) ✅
TEST-TAB-04: Send to KDS → notification created ✅
TEST-TAB-05: Request checkout → reception gets alert ✅
```

#### 4D: Kitchen Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 11 | `KitchenKDSView` | `useKDS`, `useMenu`, `useRealtime` | Replace mock orders → DB query. Realtime new items. Timer colors. |

**TEST Kitchen:**
```
TEST-KDS-01: Pending items show from DB ✅
TEST-KDS-02: New item ordered on tablet → appears in KDS < 2s ✅
TEST-KDS-03: Mark item "Served" → moves to Done column ✅
TEST-KDS-04: Timer color: green (<10min), yellow (10-15), red (>15) ✅
TEST-KDS-05: Sold-out toggle → menu_items.is_available = false ✅
```

#### 4E: Manager Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 12 | `ManagerDashboardView` | `useReport`, `useKPI`, `useRealtime` | Replace mock KPI + stats → DB aggregates. |
| 13 | `ManagerRevenueView` | `useReport` | Replace mock charts → DB payment aggregates. |
| 14 | `ManagerCOGSView` | `useMenu`, `useReport` | Replace mock cost table → DB menu_items.cost + order_items. |
| 15 | `ManagerMarketingView` | `useMarketing`, `useReport` | Replace mock channels → DB marketing_costs + reservations. |
| 16 | `ManagerCRMView` | `useCustomer` | Replace mock customer list → DB customers table. |
| 17 | `ManagerInventoryView` | `useInventory` | Replace mock inventory → DB inventory_items. |

#### 4F: Admin Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 18 | `AdminDashboardView` | `useBranch`, `useAudit` | Replace mock stats → DB counts. |
| 19 | `AdminAccountsView` | `useAuth` | Replace mock users → DB users table. |
| 20 | `AdminMenusView` | `useMenu` | Replace mock menu → full CRUD. |
| 21 | `AdminFloorsView` | `useTable` | Replace mock floor plan → CRUD zones + tables. |
| 22 | `AdminKPIView` | `useKPI` | Replace mock targets → CRUD kpi_targets. |
| 23 | `AdminAuditView` | `useAudit`, `useRealtime` | Replace mock log → realtime audit_events. |

#### 4G: Superadmin Portal

| Thứ tự | View | Composables | Thay đổi chính |
|--------|------|-------------|-----------------|
| 24 | `SuperadminDashboardView` | `useBranch`, `useReport` | Replace mock → multi-branch aggregate. |
| 25 | `SuperadminBrandsView` | `useBranch` | Replace mock → CRUD branches. |
| 26 | `SuperadminIntegrationsView` | `useBranch` | Replace mock → branch_settings CRUD. |

**✅ Phase 4 checkpoint:** 26 views wired to Supabase. All mock data replaced.

```bash
git add -A && git commit -m "Phase 4: All 26 views wired to Supabase"
```

---

## 7. Phase 5 — Realtime Integration

### Bước 5.1: Enable Realtime cho 7 bảng

Chạy trong Supabase SQL Editor:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.table_assignments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_events;
```

### Bước 5.2: Wire subscriptions theo view

Xem `API_IMPLEMENTATION_GUIDE.md` §7 Realtime Subscriptions Map.

### TEST Realtime

```
TEST-RT-01: Mở 2 tab Reception Dashboard → insert reservation ở SQL → cả 2 tab thấy ✅
TEST-RT-02: Mở Staff Floor + Reception → staff check-in → cả 2 thấy table chuyển occupied ✅
TEST-RT-03: Tablet gọi món → KDS thấy item mới < 2s ✅
TEST-RT-04: Tablet bấm "Thanh toán" → Reception thấy alert badge ✅
TEST-RT-05: Manager Dashboard → staff checkout → revenue tăng realtime ✅
TEST-RT-06: Close tab → check supabase.getChannels().length = 0 (no leak) ✅
```

**✅ Phase 5 checkpoint:** Realtime works across portals.

---

## 8. Phase 6 — End-to-End Testing

### Full POS Flow Test (Happy Path)

```
E2E-01: SETUP
  - Login reception → Open Shift (opening_cash = 5,000,000đ)
  - Login staff → see floor plan

E2E-02: CHECK-IN
  - Staff: click bàn A01 → Open Table → fill walk-in info
  - Party: 2 nam, 1 nữ, 0 trẻ em, 30-40 tuổi, Việt Nam
  - Package: "Premium Buffet" (1,380,000đ, limit 20 món)
  - Flow: free
  → Table A01 turns OCCUPIED ✅
  → Reception dashboard shows active table ✅

E2E-03: ORDER
  - Tablet: thấy menu categories + items
  - Add: Thăn Ngoại Wagyu x2, Nấm Nhật x3
  - Item counter shows "5/20"
  - Bấm "Gửi Bếp"
  → KDS: 5 items appear in "Chờ chế biến" column ✅
  → Timer starts green ✅

E2E-04: KDS
  - Kitchen: mark Wagyu x2 → "Đang làm"
  - After 12 minutes → timer turns yellow ✅
  - Mark all items → "Hoàn thành"
  → Order items status = Served ✅

E2E-05: CHECKOUT REQUEST
  - Tablet: bấm "Yêu cầu thanh toán"
  → Reception: alert badge appears ✅

E2E-06: CHECKOUT
  - Reception: click alert → open checkout view
  - See order summary: 2 Wagyu (1,000,000đ) + 3 Nấm (360,000đ) = 1,360,000đ
  - VAT 8% = 108,800đ → Total = 1,468,800đ
  - Nhập voucher "WELCOME10" (10% off) → discount 146,880đ → Final = 1,321,920đ
  - Payment: cash, received 1,500,000đ → change 178,080đ
  - Bấm "Thanh toán"
  → Invoice created ✅
  → Table A01 released → available ✅
  → Customer stats updated ✅

E2E-07: CLOSE SHIFT
  - Reception: "Đóng ca"
  - Nhập closing_cash = 6,321,920đ (5M opening + 1,321,920đ cash)
  - Expected = 6,321,920đ → difference = 0đ ✅
  - Export CSV → file downloads with correct data ✅

E2E-08: REPORTS
  - Manager: Dashboard shows KPI progress ✅
  - Revenue report shows today's total ✅
  - COGS: Wagyu = 360,000 cost / 1,000,000 revenue = 36% ✅
  - CRM: new customer appears with 1 visit ✅
```

### Error Path Tests

```
E2E-ERR-01: Check-in bàn đã occupied → error message ✅
E2E-ERR-02: Add item khi order đã Paid → error ✅
E2E-ERR-03: Add item vượt limit → error ✅
E2E-ERR-04: Checkout với amount mismatch → error ✅
E2E-ERR-05: Apply expired voucher → error ✅
E2E-ERR-06: Login sai password → error message ✅
E2E-ERR-07: Staff truy cập /admin → redirect ✅
E2E-ERR-08: Mất mạng → reconnect → data reload ✅
```

**✅ Phase 6 checkpoint:** Full POS flow passes end-to-end.

```bash
git add -A && git commit -m "Phase 6: E2E tests pass - full POS flow verified"
```

---

## 9. Phase 7 — Production Deploy

### Bước 7.1: Build kiểm tra

```bash
cd C:\Users\Per\Downloads\noMoreF2TECH
npm run build
```

**Verify:** Không có TypeScript errors. Output trong `dist/`.

### Bước 7.2: Preview local

```bash
npm run preview
```

Mở http://localhost:4173 → test login + 1 checkout flow.

### Bước 7.3: Deploy Vercel

```bash
# Option A: Vercel CLI
npx vercel --prod

# Option B: Git push (nếu đã connect Vercel ← GitHub)
git push origin main
```

### Bước 7.4: Set production env vars

Trong Vercel Dashboard → Settings → Environment Variables:

| Key | Value | Environments |
|-----|-------|-------------|
| `VITE_SUPABASE_URL` | `https://<ref>.supabase.co` | Production, Preview |
| `VITE_SUPABASE_ANON_KEY` | `eyJ...` | Production, Preview |

### Bước 7.5: Update Supabase Auth URLs

Vào **Supabase Dashboard → Authentication → URL Configuration**:
- **Site URL**: `https://pos.nguucat.vn`
- **Redirect URLs**: thêm `https://pos.nguucat.vn/**`

### Bước 7.6: DNS

Thêm CNAME record:
- `pos.nguucat.vn` → `cname.vercel-dns.com`

### Bước 7.7: Production Smoke Test

```
PROD-01: Mở https://pos.nguucat.vn → thấy login page ✅
PROD-02: Login admin → dashboard loads ✅
PROD-03: Login staff → floor plan loads ✅
PROD-04: Full checkout flow (walk-in → order → checkout) ✅
PROD-05: Realtime: 2 browser checkout → sync ✅
PROD-06: Mobile: Staff app responsive on phone ✅
PROD-07: HTTPS + SSL valid ✅
```

**✅ Phase 7 checkpoint:** Production live.

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 10. Troubleshooting

### Lỗi thường gặp và cách sửa

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | `missing VITE_SUPABASE_URL` | `.env` chưa tạo hoặc sai key | Kiểm tra `.env` ở project root |
| 2 | `new row violates row-level security` | RLS policy chưa đúng | Kiểm tra `has_role()` + `current_branch_id()` |
| 3 | `relation "xxx" does not exist` | Schema chưa chạy | Chạy `DATABASE_SCHEMA.sql` trong SQL Editor |
| 4 | `JWT expired` | Token hết hạn (1h) | `supabase.auth.refreshSession()` |
| 5 | `functions: relay error` | Edge Function crash | Kiểm tra logs: Supabase Dashboard → Edge Functions → Logs |
| 6 | `channel limit reached` | Quá nhiều realtime channels | Kiểm tra cleanup, giảm subscriptions |
| 7 | `CORS error` | Missing CORS headers | Kiểm tra `corsHeaders` trong Edge Function |
| 8 | `branch_id is null` | User chưa được gán branch | Update `public.users.branch_id` |
| 9 | `duplicate key value` | Insert conflict | Dùng `.upsert()` hoặc check trước |
| 10 | `permission denied for table` | RLS enabled nhưng chưa có policy | Chạy policy SQL từ SUPABASE_AUTH.md §6.2 |

### Debug commands

```ts
// Kiểm tra current user
const { data: { user } } = await supabase.auth.getUser()
console.log('User:', user)

// Kiểm tra JWT claims
const session = (await supabase.auth.getSession()).data.session
const claims = JSON.parse(atob(session!.access_token.split('.')[1]))
console.log('Claims:', claims) // { role, branch_id, ... }

// Kiểm tra active channels
console.log('Channels:', supabase.getChannels().length)

// Test RLS
const { data, error } = await supabase.from('orders').select('*')
console.log('Orders visible to this role:', data?.length, error)
```

---

## 11. Rollback Strategy

### Nếu Phase X fail → rollback

```bash
# Xem commit history
git log --oneline -10

# Rollback to last good commit
git revert HEAD

# Hoặc hard reset (nguy hiểm)
git reset --hard <commit-hash>
```

### Database rollback

```sql
-- Nếu migration gây lỗi, revert bằng SQL
-- Ví dụ: đã thêm column sai
ALTER TABLE public.menu_items DROP COLUMN IF EXISTS wrong_column;
```

### Edge Function rollback

```bash
# Rollback function to previous version
# (Supabase giữ version history trong Dashboard)
# Hoặc redeploy từ git:
git checkout <previous-commit> -- supabase/functions/check-in/index.ts
supabase functions deploy check-in
```

---

## Quick Reference: Phase → Files Modified

| Phase | Files Created/Modified | Commit Message |
|-------|----------------------|----------------|
| 0 | `.env`, `src/lib/supabase.ts`, `src/types/database.ts`, `src/types/models.ts` | "Phase 0: Infrastructure setup" |
| 1 | `src/composables/useAuth.ts`, `src/views/LoginView.vue`, `src/router/index.ts`, `src/main.ts` | "Phase 1: Auth flow complete" |
| 2 | `src/composables/*.ts` (17 files) | "Phase 2: Core composables" |
| 3 | `supabase/functions/*/index.ts` (9 functions + shared) | "Phase 3: Edge Functions deployed" |
| 4 | All 26 view files in `src/views/` | "Phase 4: Views wired to Supabase" |
| 5 | (SQL only — enable realtime) | "Phase 5: Realtime enabled" |
| 6 | (Test only — no code changes) | "Phase 6: E2E verified" |
| 7 | (Deploy only) | "Phase 7: Production v1.0.0" |
