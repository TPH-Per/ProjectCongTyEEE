# API IMPLEMENTATION GUIDE — Hướng dẫn Agent thực thi toàn bộ chức năng

> **Mục đích:** Đây là tài liệu duy nhất mà agent cần đọc để kết nối toàn bộ giao diện Vue với Supabase backend.
> Mọi query, mutation, Edge Function call, Realtime subscription đều được liệt kê chi tiết cho từng view.

> **Tech Stack:** Vue 3 (Composition API) + TypeScript + Supabase (PostgreSQL + Edge Functions + Realtime + Auth)

---

## MỤC LỤC

1. [Cấu trúc thư mục cần tạo](#1-cấu-trúc-thư-mục-cần-tạo)
2. [Setup Supabase Client](#2-setup-supabase-client)
3. [Composables cốt lõi](#3-composables-cốt-lõi)
4. [TypeScript Types](#4-typescript-types)
5. [View → API Mapping (7 Portals)](#5-view--api-mapping)
   - 5.1 Admin Portal
   - 5.2 Manager Portal
   - 5.3 Reception Portal
   - 5.4 Staff Portal
   - 5.5 Tablet Portal
   - 5.6 Kitchen Portal
   - 5.7 Superadmin Portal
6. [Edge Functions (9 functions)](#6-edge-functions)
7. [Realtime Subscriptions Map](#7-realtime-subscriptions-map)
8. [RLS Policy Matrix](#8-rls-policy-matrix)
9. [Seed Data](#9-seed-data)
10. [Checklist triển khai](#10-checklist-triển-khai)

---

## 1. Cấu trúc thư mục cần tạo

```
src/
├── lib/
│   └── supabase.ts              ← Supabase client singleton
├── composables/
│   ├── useAuth.ts               ← Auth state + login/logout + role check
│   ├── useRealtime.ts           ← Realtime subscriptions + cleanup
│   ├── useBranch.ts             ← Branch selector (admin/superadmin)
│   ├── useCheckIn.ts            ← Edge Function: check-in
│   ├── useOrder.ts              ← Edge Function: add-order-item + queries
│   ├── useCheckout.ts           ← Edge Function: checkout
│   ├── useShift.ts              ← Edge Function: close-shift + export-shift-csv
│   ├── useKDS.ts                ← Edge Function: kds-push + KDS queries
│   ├── useTaxInvoice.ts         ← Edge Function: issue-tax-invoice
│   ├── useReservation.ts        ← CRUD reservations
│   ├── useMenu.ts               ← CRUD menu_categories + menu_items + packages
│   ├── useTable.ts              ← CRUD zones + tables
│   ├── useCustomer.ts           ← CRUD customers
│   ├── useKPI.ts                ← CRUD kpi_targets
│   ├── useMarketing.ts          ← CRUD marketing_costs
│   ├── useAudit.ts              ← SELECT audit_events
│   ├── useInventory.ts          ← CRUD inventory_items + inventory_txns
│   └── useReport.ts             ← Aggregate queries cho revenue/COGS
├── types/
│   └── database.ts              ← Generated types (supabase gen types)
├── views/
│   └── LoginView.vue            ← Login page (chưa tồn tại)
```

---

## 2. Setup Supabase Client

### File: `src/lib/supabase.ts`

```ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in .env')
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
  realtime: {
    params: { eventsPerSecond: 10 },
  },
})
```

### File: `.env`

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

### Cài đặt package

```bash
npm install @supabase/supabase-js
```

### Generate types

```bash
npx supabase gen types typescript --project-id <project-ref> > src/types/database.ts
```

---

## 3. Composables cốt lõi

### 3.1 `useAuth.ts` — Authentication + Role-based routing

**Đầy đủ code:** Xem `docs/SUPABASE_AUTH.md` mục 5.1

**API Surface:**

```ts
// Import
import { useAuth } from '@/composables/useAuth'

// Usage
const {
  session,           // Ref<Session | null>
  profile,           // Ref<AppUser | null>  — row from public.users
  loading,           // Ref<boolean>
  role,              // ComputedRef<'admin'|'manager'|'reception'|'staff'|'kitchen'>
  branchId,          // ComputedRef<string>
  isAuthenticated,   // ComputedRef<boolean>
  isAdmin,           // ComputedRef<boolean>
  isManager,         // ComputedRef<boolean> (admin OR manager)
  signIn,            // (email, password) => Promise<void>
  signOut,           // () => Promise<void>
  init,              // () => Promise<void> — gọi 1 lần trong main.ts
} = useAuth()
```

**Router guard (trong `main.ts`):**

```ts
router.beforeEach(async (to) => {
  const { isAuthenticated, loading, role } = useAuth()
  if (loading.value) return
  if (!isAuthenticated.value && to.name !== 'login') return { name: 'login' }

  // Role-based route protection
  const prefix = to.path.split('/')[1] // 'admin', 'manager', etc.
  const roleMap: Record<string, string[]> = {
    admin: ['admin'],
    superadmin: ['admin'], // superadmin dùng role admin
    manager: ['admin', 'manager'],
    reception: ['admin', 'manager', 'reception'],
    staff: ['admin', 'manager', 'staff'],
    kitchen: ['admin', 'kitchen'],
    tablet: ['admin', 'manager', 'reception', 'staff'], // tablet không cần role riêng
  }
  if (roleMap[prefix] && !roleMap[prefix].includes(role.value!)) {
    return { name: 'login' }
  }
})
```

---

### 3.2 `useRealtime.ts` — Realtime subscriptions

**Đầy đủ code:** Xem `docs/SUPABASE_REALTIME.md` mục 2

**API Surface:**

```ts
import { useRealtime } from '@/composables/useRealtime'

const { watchTable, broadcast, sendBroadcast, status } = useRealtime()

// Subscribe to table changes (auto-filtered by branch_id)
const cleanup = watchTable<Reservation>(
  'reservations',  // table name
  'INSERT',        // event: 'INSERT' | 'UPDATE' | 'DELETE' | '*'
  (payload) => {   // callback: { eventType, new, old }
    console.log('New reservation:', payload.new)
  },
  { status: 'Pending' }  // optional extra filter
)

// Cleanup in onUnmounted
onUnmounted(() => cleanup())
```

---

### 3.3 `useBranch.ts` — Branch selector (Admin/Superadmin)

```ts
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'

const selectedBranchId = ref<string | null>(
  localStorage.getItem('ngu-cat.selectedBranch')
)

export function useBranch() {
  const { branchId: defaultBranch, isAdmin } = useAuth()
  const activeBranchId = computed(() =>
    isAdmin.value && selectedBranchId.value
      ? selectedBranchId.value
      : defaultBranch.value
  )

  function selectBranch(id: string | null) {
    selectedBranchId.value = id
    if (id) localStorage.setItem('ngu-cat.selectedBranch', id)
    else localStorage.removeItem('ngu-cat.selectedBranch')
  }

  async function listBranches() {
    const { data, error } = await supabase
      .from('branches')
      .select('id, name, code, address, is_active')
      .order('name')
    if (error) throw error
    return data ?? []
  }

  return { activeBranchId, selectBranch, listBranches }
}
```

---

## 4. TypeScript Types

Agent phải chạy `supabase gen types` để tạo `src/types/database.ts`. Nếu không có sẵn, dùng types thủ công sau:

```ts
// src/types/models.ts — Shortcut types cho các bảng chính

export type UserRole = 'admin' | 'manager' | 'reception' | 'staff' | 'kitchen'
export type ReservationStatus = 'Pending' | 'Confirmed' | 'Arrived' | 'Dining' | 'Completed' | 'No-show' | 'Cancelled'
export type TableStatus = 'available' | 'occupied' | 'reserved' | 'maintenance'
export type OrderStatus = 'Open' | 'Preparing' | 'Served' | 'Paid' | 'Cancelled'
export type OrderItemStatus = 'Pending' | 'Preparing' | 'Served' | 'Cancelled'
export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
export type ShiftStatus = 'open' | 'closed'
export type RevenueType = 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'

export interface Branch {
  id: string; name: string; code: string; address: string; phone?: string; is_active: boolean
}
export interface AppUser {
  id: string; email: string; full_name: string; phone?: string
  role: UserRole; branch_id: string; is_active: boolean
}
export interface Zone {
  id: string; branch_id: string; name: string; sort_order: number; metadata?: any
}
export interface Table {
  id: string; branch_id: string; zone_id: string; code: string
  capacity: number; status: TableStatus; position_x?: number; position_y?: number
}
export interface Customer {
  id: string; branch_id: string; name: string; phone?: string; email?: string
  is_vip: boolean; tags?: any; demographics?: any; tax_code?: string
  total_visits: number; total_spent: number; last_visit_at?: string
}
export interface MenuCategory {
  id: string; branch_id: string; name: string; sort_order: number; is_active: boolean
}
export interface MenuItem {
  id: string; branch_id: string; category_id: string; name: string
  price: number; cost: number; is_available: boolean; image_url?: string
  modifiers?: any; tags?: any; metadata?: any
}
export interface Package {
  id: string; branch_id: string; name: string; type: string
  price: number; item_limit?: number; duration_minutes?: number; is_active: boolean
}
export interface Reservation {
  id: string; branch_id: string; booking_code: string
  reservation_date: string; reservation_time: string; guests: number
  status: ReservationStatus; source?: string; type?: string
  customer_id?: string; customer_snapshot?: any
  marketing_channel?: string; notes?: any
  created_by?: string; arrived_at?: string; seated_at?: string; completed_at?: string
}
export interface TableAssignment {
  id: string; branch_id: string; reservation_id?: string
  table_id: string; assigned_by: string; assigned_at: string; released_at?: string
  metadata?: any
}
export interface Order {
  id: string; branch_id: string; order_number?: string
  reservation_id?: string; customer_id?: string; table_id?: string
  status: OrderStatus; subtotal: number; vat_rate: number; vat: number
  discount: number; total: number; created_by?: string; served_by?: string
}
export interface OrderItem {
  id: string; branch_id: string; order_id: string; menu_item_id: string
  name_snapshot: string; unit_price: number; unit_cost: number
  quantity: number; line_total: number; status: OrderItemStatus
  modifiers?: any; note?: string
}
export interface Invoice {
  id: string; branch_id: string; order_id: string; invoice_number: string
  status: string; subtotal: number; vat: number; discount: number; total: number
  tax_code?: string; customer_company?: string; customer_address?: string
  customer_snapshot?: any; issued_at: string; issued_by: string; metadata?: any
}
export interface Payment {
  id: string; branch_id: string; invoice_id: string; shift_id?: string
  method: PaymentMethod; revenue_type?: RevenueType
  amount: number; received_amount?: number; change_amount?: number
  reference?: string; received_by: string; paid_at: string
}
export interface Shift {
  id: string; branch_id: string; user_id: string; status: ShiftStatus
  opened_at: string; closed_at?: string
  opening_cash: number; closing_cash?: number; expected_cash?: number; cash_difference?: number
  notes?: any
}
export interface KPITarget {
  id: string; branch_id?: string; metric_key: string
  target_value: number; period_start: string; period_end: string; scope?: string
}
export interface AuditEvent {
  id: string; branch_id?: string; actor_id?: string
  action: string; entity_type: string; entity_id?: string
  payload?: any; ip_address?: string; created_at: string
}
export interface Notification {
  id: string; branch_id?: string; channel: string; recipient: string
  template: string; variables?: any; status: string; created_at: string
}
export interface MarketingCost {
  id: string; branch_id: string; channel: string
  period_start: string; period_end: string; amount: number; metadata?: any
}
```

---

## 5. View → API Mapping

> Mỗi view liệt kê: **Queries** (SELECT), **Mutations** (INSERT/UPDATE/DELETE), **Edge Functions**, **Realtime subscriptions**.

---

### 5.1 ADMIN PORTAL (`/admin/*`)

#### 5.1.1 `AdminDashboardView.vue`

| Action | API Call |
|--------|----------|
| Load stats | `supabase.from('users').select('id', { count: 'exact' }).eq('branch_id', branchId)` |
| Load branch info | `supabase.from('branches').select('*').eq('id', branchId).single()` |
| Load recent activity | `supabase.from('audit_events').select('*').order('created_at', { ascending: false }).limit(10)` |
| **Realtime** | `watchTable('audit_events', 'INSERT', reload)` |

#### 5.1.2 `AdminAccountsView.vue`

| Action | API Call |
|--------|----------|
| List users | `supabase.from('users').select('id, email, full_name, phone, role, is_active, branch_id, branches(name)').order('created_at', { ascending: false })` |
| Create user | `supabase.auth.admin.createUser({ email, password, user_metadata: { role, branch_id, full_name } })` — **Requires service_role key, do via Edge Function** |
| Update user role | `supabase.from('users').update({ role, is_active }).eq('id', userId)` |
| Delete user | `supabase.from('users').update({ is_active: false }).eq('id', userId)` — soft delete |

**Edge Function cần tạo thêm: `create-user`**

```ts
// POST /functions/v1/create-user
// Body: { email, password, fullName, phone, role, branchId }
// Logic: admin.auth.admin.createUser() → trigger tự mirror vào public.users
```

#### 5.1.3 `AdminMenusView.vue`

| Action | API Call |
|--------|----------|
| List categories | `supabase.from('menu_categories').select('id, name, sort_order, is_active').order('sort_order')` |
| List items by category | `supabase.from('menu_items').select('*').eq('category_id', catId).order('name')` |
| Create category | `supabase.from('menu_categories').insert({ branch_id, name, sort_order })` |
| Create item | `supabase.from('menu_items').insert({ branch_id, category_id, name, price, cost, image_url })` |
| Update item | `supabase.from('menu_items').update({ name, price, cost, is_available }).eq('id', itemId)` |
| Delete item | `supabase.from('menu_items').update({ is_available: false }).eq('id', itemId)` — soft delete |
| Toggle available | `supabase.from('menu_items').update({ is_available: !current }).eq('id', itemId)` |

#### 5.1.4 `AdminFloorsView.vue`

| Action | API Call |
|--------|----------|
| List zones | `supabase.from('zones').select('id, name, sort_order, metadata').order('sort_order')` |
| List tables | `supabase.from('tables').select('id, code, capacity, status, zone_id, position_x, position_y').order('code')` |
| Create zone | `supabase.from('zones').insert({ branch_id, name, sort_order })` |
| Create table | `supabase.from('tables').insert({ branch_id, zone_id, code, capacity, position_x, position_y })` |
| Update table position | `supabase.from('tables').update({ position_x, position_y }).eq('id', tableId)` |
| Delete table | `supabase.from('tables').delete().eq('id', tableId)` |
| Delete zone | `supabase.from('zones').delete().eq('id', zoneId)` — CASCADE deletes tables in zone |

#### 5.1.5 `AdminKPIView.vue`

| Action | API Call |
|--------|----------|
| List targets | `supabase.from('kpi_targets').select('*').order('period_start', { ascending: false })` |
| Create target | `supabase.from('kpi_targets').insert({ branch_id, metric_key, target_value, period_start, period_end, scope })` |
| Update target | `supabase.from('kpi_targets').update({ target_value }).eq('id', targetId)` |
| Delete target | `supabase.from('kpi_targets').delete().eq('id', targetId)` |
| Get actual value | Computed from `useReport` composable (see Section 5.2.2) |

**metric_key values:** `'revenue_daily'`, `'revenue_weekly'`, `'revenue_monthly'`, `'guest_count'`, `'avg_check'`, `'cogs_ratio'`, `'reservation_fill_rate'`

#### 5.1.6 `AdminAuditView.vue`

| Action | API Call |
|--------|----------|
| List events | `supabase.from('audit_events').select('id, action, entity_type, entity_id, actor_id, payload, ip_address, created_at, branch_id').order('created_at', { ascending: false }).range(offset, offset + limit - 1)` |
| Filter by action | `.ilike('action', `%${search}%`)` |
| Filter by entity_type | `.eq('entity_type', type)` |
| Filter by date range | `.gte('created_at', startDate).lte('created_at', endDate)` |
| Filter by user | `.eq('actor_id', userId)` |
| Join user name | Separate query: `supabase.from('users').select('id, full_name').in('id', actorIds)` |
| **Realtime** | `watchTable('audit_events', 'INSERT', (p) => prepend(p.new))` |

---

### 5.2 MANAGER PORTAL (`/manager/*`)

#### 5.2.1 `ManagerDashboardView.vue`

| Action | API Call |
|--------|----------|
| KPI target | `supabase.from('kpi_targets').select('*').eq('metric_key', 'revenue_daily').gte('period_start', today).lte('period_end', today).maybeSingle()` |
| Today revenue | `supabase.from('payments').select('amount').gte('paid_at', todayStart).lte('paid_at', todayEnd)` → sum |
| Today guests | `supabase.from('reservations').select('guests').eq('reservation_date', today).in('status', ['Arrived','Dining','Completed'])` → sum |
| Foreign guests | `supabase.from('reservations').select('customer_snapshot').eq('reservation_date', today)` → filter nationality=foreign → count |
| Avg check | `todayRevenue / todayGuests` |
| Revenue by time | `supabase.rpc('revenue_by_hour', { p_branch_id: branchId, p_date: today })` — **Need SQL function** |
| Reservation rate | `supabase.from('reservations').select('source').eq('reservation_date', today)` → group by source |
| **Realtime** | `watchTable('payments', 'INSERT', recalcRevenue)` |

**SQL Function cần tạo:**

```sql
create or replace function public.revenue_by_hour(p_branch_id uuid, p_date date)
returns table(hour_bucket int, total numeric) language sql stable as $$
  select extract(hour from p.paid_at)::int as hour_bucket, sum(p.amount) as total
  from public.payments p
  where p.branch_id = p_branch_id
    and p.paid_at::date = p_date
  group by 1 order by 1;
$$;
```

#### 5.2.2 `ManagerRevenueView.vue`

| Action | API Call |
|--------|----------|
| Daily revenue | `supabase.from('payments').select('amount, revenue_type, method, paid_at').gte('paid_at', startDate).lte('paid_at', endDate)` |
| Group by type | Client-side: `payments.reduce((acc, p) => { acc[p.revenue_type] = (acc[p.revenue_type] ?? 0) + p.amount; return acc }, {})` |
| Guest demographics | `supabase.from('reservations').select('customer_snapshot, guests').eq('reservation_date', date)` → extract demographics from snapshot |
| Period comparison | Same query with different date ranges → calculate diff % |
| Export CSV | Generate CSV in client or call `export-shift-csv` Edge Function |
| Export Excel | Use `xlsx` npm package client-side |

**Composable: `useReport.ts`**

```ts
export function useReport() {
  const { activeBranchId } = useBranch()

  async function getRevenue(startDate: string, endDate: string) {
    const { data } = await supabase
      .from('payments')
      .select('amount, revenue_type, method, paid_at, invoices(total, customer_snapshot)')
      .eq('branch_id', activeBranchId.value)
      .gte('paid_at', startDate)
      .lte('paid_at', endDate)
    return data ?? []
  }

  async function getGuestCount(date: string) {
    const { data } = await supabase
      .from('reservations')
      .select('guests, customer_snapshot')
      .eq('branch_id', activeBranchId.value)
      .eq('reservation_date', date)
      .in('status', ['Arrived', 'Dining', 'Completed'])
    return data ?? []
  }

  async function getCOGS(startDate: string, endDate: string) {
    const { data } = await supabase
      .from('order_items')
      .select('name_snapshot, unit_price, unit_cost, quantity, line_total')
      .eq('branch_id', activeBranchId.value)
      .gte('created_at', startDate)
      .lte('created_at', endDate)
    return data ?? []
  }

  return { getRevenue, getGuestCount, getCOGS }
}
```

#### 5.2.3 `ManagerCOGSView.vue`

| Action | API Call |
|--------|----------|
| Menu items with cost | `supabase.from('menu_items').select('id, name, price, cost, category_id, menu_categories(name)').eq('is_available', true).order('name')` |
| Sold quantity (period) | `supabase.from('order_items').select('menu_item_id, quantity, unit_cost, line_total').gte('created_at', periodStart).lte('created_at', periodEnd)` |
| COGS per item | Client: `soldQty * unit_cost` |
| COGS ratio | Client: `totalCOGS / totalRevenue * 100` |
| Update cost | `supabase.from('menu_items').update({ cost: newCost }).eq('id', itemId)` |

**COGS Calculation Logic (client-side):**

```ts
function calculateCOGS(menuItems: MenuItem[], orderItems: OrderItem[]) {
  return menuItems.map(item => {
    const sold = orderItems
      .filter(oi => oi.menu_item_id === item.id)
      .reduce((sum, oi) => sum + oi.quantity, 0)
    const totalCost = sold * item.cost
    const totalRevenue = sold * item.price
    const cogsRatio = totalRevenue > 0 ? (totalCost / totalRevenue * 100) : 0
    return { ...item, sold, totalCost, totalRevenue, cogsRatio }
  })
}
```

#### 5.2.4 `ManagerMarketingView.vue`

| Action | API Call |
|--------|----------|
| Channel attribution | `supabase.from('reservations').select('marketing_channel, guests, customer_snapshot').eq('reservation_date', date).not('marketing_channel', 'is', null)` → group by channel |
| Revenue per channel | Join with `orders` + `payments` via `reservation_id` |
| Marketing costs | `supabase.from('marketing_costs').select('*').eq('branch_id', branchId).gte('period_start', startDate)` |
| Save cost | `supabase.from('marketing_costs').upsert({ branch_id, channel, period_start, period_end, amount })` |
| CPA calc | Client: `totalCost / totalGuestsFromDigital` |
| Campaigns | `supabase.from('marketing_costs').select('*').order('period_start', { ascending: false })` |

#### 5.2.5 `ManagerCRMView.vue`

| Action | API Call |
|--------|----------|
| Customer list | `supabase.from('customers').select('id, name, phone, email, is_vip, tags, demographics, total_visits, total_spent, last_visit_at, marketing_channel').order('last_visit_at', { ascending: false }).range(offset, offset + limit - 1)` |
| Search by phone | `.ilike('phone', `%${query}%`)` |
| Search by name | `.ilike('name', `%${query}%`)` |
| Filter VIP | `.eq('is_vip', true)` |
| Filter by tag | `.contains('tags', [tag])` |
| Repeat rate | Client: `customers.filter(c => c.total_visits > 1).length / customers.length * 100` |
| Update customer | `supabase.from('customers').update({ is_vip, tags }).eq('id', customerId)` |
| Customer history | `supabase.from('reservations').select('id, reservation_date, status, orders(total, order_items(name_snapshot, quantity))').eq('customer_id', customerId).order('reservation_date', { ascending: false })` |

#### 5.2.6 `ManagerInventoryView.vue`

| Action | API Call |
|--------|----------|
| List items | `supabase.from('inventory_items').select('id, name, category, unit, quantity, min_quantity, cost_per_unit, is_active').eq('is_active', true).order('name')` |
| Low stock alert | `.lte('quantity', supabase.rpc('get_min_quantity'))` — or client filter: `items.filter(i => i.quantity <= i.min_quantity)` |
| Add stock (nhập kho) | `supabase.from('inventory_txns').insert({ branch_id, inventory_item_id, txn_type: 'in', quantity, unit_cost, reference, notes })` → then update `inventory_items.quantity += quantity` |
| Use stock (xuất bếp) | `supabase.from('inventory_txns').insert({ ..., txn_type: 'out', quantity: -amount })` → update quantity |
| Transaction history | `supabase.from('inventory_txns').select('*').eq('inventory_item_id', itemId).order('created_at', { ascending: false })` |

---

### 5.3 RECEPTION PORTAL (`/reception/*`)

#### 5.3.1 `ReceptionDashboardView.vue`

| Action | API Call |
|--------|----------|
| Today reservations | `supabase.from('reservations').select('id, booking_code, reservation_time, guests, status, customer_snapshot, table_assignments(table_id, tables(code))').eq('reservation_date', today).order('reservation_time')` |
| Active tables | `supabase.from('table_assignments').select('id, table_id, assigned_at, metadata, tables(code, zone_id, zones(name))').is('released_at', null)` |
| Checkout alerts | `supabase.from('notifications').select('*').eq('channel', 'reception-panel').eq('template', 'checkout_request').eq('status', 'pending').order('created_at', { ascending: false })` |
| Acknowledge alert | `supabase.from('notifications').update({ status: 'read' }).eq('id', notifId)` |
| Open shift | `supabase.from('shifts').insert({ branch_id, user_id, opening_cash, status: 'open' })` |
| **Realtime** | `watchTable('notifications', 'INSERT', checkAlerts)` + `watchTable('table_assignments', '*', reloadTables)` + `watchTable('reservations', 'UPDATE', reloadReservations)` |

#### 5.3.2 `ReceptionCheckoutView.vue` (route param: `:id` = order ID)

| Action | API Call |
|--------|----------|
| Load order | `supabase.from('orders').select('*, order_items(*, menu_items(name, image_url)), reservations(customer_snapshot), tables(code)').eq('id', orderId).single()` |
| Lookup customer | `supabase.from('customers').select('*').eq('phone', phone).maybeSingle()` |
| Apply voucher | `supabase.from('vouchers').select('*').eq('code', code.toUpperCase()).eq('is_active', true).maybeSingle()` → validate client-side |
| **Execute checkout** | `supabase.functions.invoke('checkout', { body: { orderId, revenueType, customerId, voucherCode, taxCode, payments, notes } })` |
| Print receipt | Client-side: generate receipt HTML → `window.print()` |
| Issue tax invoice | `supabase.functions.invoke('issue-tax-invoice', { body: { invoiceId, taxCode, customerCompany, customerAddress } })` |
| **Realtime** | `watchTable('vouchers', 'UPDATE', revalidateVoucher)` + `broadcast('reception:co-browsing', ...)` |

#### 5.3.3 `ReceptionCloseShiftView.vue`

| Action | API Call |
|--------|----------|
| Get current shift | `supabase.from('shifts').select('*').eq('user_id', userId).eq('status', 'open').maybeSingle()` |
| Shift payments summary | `supabase.from('payments').select('method, revenue_type, amount').eq('shift_id', shiftId)` → aggregate by method + revenue_type |
| **Close shift** | `supabase.functions.invoke('close-shift', { body: { shiftId, closingCash, notes } })` |
| **Export CSV** | `supabase.functions.invoke('export-shift-csv', { body: null, headers: { shiftId } })` — returns CSV blob |
| Shift history | `supabase.from('shifts').select('*').order('opened_at', { ascending: false }).limit(10)` |

---

### 5.4 STAFF PORTAL (`/staff/*`)

#### 5.4.1 `StaffFloorPlanView.vue`

| Action | API Call |
|--------|----------|
| Load zones | `supabase.from('zones').select('id, name, sort_order').order('sort_order')` |
| Load tables | `supabase.from('tables').select('id, code, capacity, status, zone_id, position_x, position_y, table_assignments(id, reservation_id, assigned_at, metadata)').order('code')` |
| Filter by zone | Client-side filter on `zone_id` |
| **Realtime** | `watchTable('tables', 'UPDATE', reloadTables)` + `watchTable('table_assignments', '*', reloadTables)` |

#### 5.4.2 `StaffOpenTableView.vue` (route param: `:id` = table ID)

| Action | API Call |
|--------|----------|
| Load table info | `supabase.from('tables').select('id, code, capacity, zone_id, zones(name)').eq('id', tableId).single()` |
| Load packages | `supabase.from('packages').select('*').eq('is_active', true).order('price')` |
| **Check-in** | `supabase.functions.invoke('check-in', { body: { reservationId?, walkIn?, tableIds, partySize, packageId, flowMode } })` |
| Create walk-in order | Automatic after check-in: `supabase.from('orders').insert({ branch_id, table_id: tableId, status: 'Open', vat_rate: 0.08, created_by: userId })` |

#### 5.4.3 `StaffActiveTablesView.vue`

| Action | API Call |
|--------|----------|
| Active assignments | `supabase.from('table_assignments').select('id, table_id, assigned_at, metadata, tables(code, zone_id, zones(name)), reservations(customer_snapshot, guests)').is('released_at', null).order('assigned_at')` |
| Order items per table | For each assignment: `supabase.from('orders').select('id, total, status, order_items(id, name_snapshot, quantity, status)').eq('table_id', assignment.table_id).neq('status', 'Paid').limit(1)` |
| Time elapsed | Client: `Date.now() - new Date(assignment.assigned_at).getTime()` |
| **Realtime** | `watchTable('table_assignments', '*', reloadActive)` + `watchTable('order_items', 'INSERT', reloadActive)` |

#### 5.4.4 `StaffInDiningCRMView.vue` (route param: `:id` = table ID)

| Action | API Call |
|--------|----------|
| Load customer | Join via assignment: `supabase.from('table_assignments').select('reservation_id, reservations(customer_id, customer_snapshot, customers(*))').eq('table_id', tableId).is('released_at', null).maybeSingle()` |
| Customer history | `supabase.from('reservations').select('reservation_date, status, orders(total)').eq('customer_id', customerId).order('reservation_date', { ascending: false }).limit(5)` |
| Add note | `supabase.from('customers').update({ tags: [...tags, newTag] }).eq('id', customerId)` |
| Mark VIP | `supabase.from('customers').update({ is_vip: true }).eq('id', customerId)` |

---

### 5.5 TABLET PORTAL (`/tablet/*`)

#### 5.5.1 `TabletIdleView.vue`

| Action | API Call |
|--------|----------|
| None | Static view — shows welcome screen. Auto-navigates when `table_assignments` INSERT detected. |
| **Realtime** | `watchTable('table_assignments', 'INSERT', (p) => { if (p.new.table_id === currentTableId) router.push('/tablet/language') })` |

**Note:** Tablet cần biết `tableId` của mình. Lưu trong `localStorage` key `ngu-cat.tabletTableId` (set 1 lần khi cấu hình tablet).

#### 5.5.2 `TabletLanguageView.vue`

| Action | API Call |
|--------|----------|
| None | Static — user chọn ngôn ngữ → `router.push('/tablet/order')` |

#### 5.5.3 `TabletOrderView.vue`

| Action | API Call |
|--------|----------|
| Load menu | `supabase.from('menu_categories').select('id, name, sort_order, menu_items(id, name, price, image_url, is_available, modifiers, tags)').eq('is_active', true).order('sort_order')` |
| Load current order | `supabase.from('orders').select('id, status, subtotal, vat, total, order_items(*)').eq('table_id', tableId).eq('status', 'Open').maybeSingle()` |
| Load package info | From `table_assignments.metadata` |
| Item count (for limit) | `orderItems.length` vs `assignment.metadata.item_limit` |
| **Add item** | `supabase.functions.invoke('add-order-item', { body: { orderId, menuItemId, quantity, note, modifiers } })` |
| **Send to KDS** | `supabase.functions.invoke('kds-push', { body: { orderId, itemIds } })` |
| **Realtime** | `watchTable('order_items', '*', reloadOrder, { order_id: orderId })` + `watchTable('table_assignments', 'UPDATE', reloadPackageInfo)` |

#### 5.5.4 `TabletCheckoutView.vue`

| Action | API Call |
|--------|----------|
| **Request checkout** | `supabase.functions.invoke('request-checkout', { body: { tableId } })` |
| Show waiting | Static "Vui lòng đến quầy thanh toán" screen |
| **Realtime** | `watchTable('table_assignments', 'UPDATE', (p) => { if (p.new.released_at) router.push('/tablet/idle') })` |

---

### 5.6 KITCHEN PORTAL (`/kitchen/*`)

#### 5.6.1 `KitchenKDSView.vue`

| Action | API Call |
|--------|----------|
| Load pending items | `supabase.from('order_items').select('id, order_id, name_snapshot, quantity, note, modifiers, status, created_at, orders(order_number, table_id, tables(code))').in('status', ['Pending', 'Preparing']).order('created_at')` |
| Load done items (last 30min) | Same query with `.eq('status', 'Served').gte('updated_at', thirtyMinAgo)` |
| Mark item preparing | `supabase.from('order_items').update({ status: 'Preparing' }).eq('id', itemId)` |
| Mark item served | `supabase.from('order_items').update({ status: 'Served' }).eq('id', itemId)` |
| Mark order done | `supabase.from('order_items').update({ status: 'Served' }).eq('order_id', orderId).in('status', ['Pending', 'Preparing'])` |
| Sold-out toggle | `supabase.from('menu_items').update({ is_available: false }).eq('id', menuItemId)` |
| List sold-out | `supabase.from('menu_items').select('id, name').eq('is_available', false)` |
| Re-enable item | `supabase.from('menu_items').update({ is_available: true }).eq('id', menuItemId)` |
| **Realtime** | `watchTable('order_items', 'INSERT', addToQueue)` + `watchTable('order_items', 'UPDATE', updateInQueue)` |

**Timer color logic (client-side):**

```ts
function getTimerColor(createdAt: string): 'green' | 'yellow' | 'red' {
  const elapsed = (Date.now() - new Date(createdAt).getTime()) / 60000 // minutes
  if (elapsed < 10) return 'green'
  if (elapsed < 15) return 'yellow'
  return 'red'
}
```

---

### 5.7 SUPERADMIN PORTAL (`/superadmin/*`)

#### 5.7.1 `SuperadminDashboardView.vue`

| Action | API Call |
|--------|----------|
| List all branches | `supabase.from('branches').select('id, name, code, address, is_active').order('name')` |
| Revenue per branch | For each branch: `supabase.from('payments').select('amount').eq('branch_id', bid).gte('paid_at', todayStart)` → sum |
| Active tables per branch | `supabase.from('table_assignments').select('id, branch_id').is('released_at', null)` → group by branch_id |
| System health | `supabase.from('system_events').select('*').order('created_at', { ascending: false }).limit(20)` |
| Total users | `supabase.from('users').select('id, branch_id, role', { count: 'exact' })` |

#### 5.7.2 `SuperadminBrandsView.vue`

| Action | API Call |
|--------|----------|
| List branches | `supabase.from('branches').select('id, name, code, address, phone, is_active, metadata')` |
| Create branch | `supabase.from('branches').insert({ name, code, address, phone })` |
| Update branch | `supabase.from('branches').update({ name, address, is_active }).eq('id', branchId)` |
| Branch manager | `supabase.from('users').select('full_name').eq('branch_id', branchId).eq('role', 'manager').maybeSingle()` |

#### 5.7.3 `SuperadminIntegrationsView.vue`

| Action | API Call |
|--------|----------|
| Load settings | `supabase.from('branch_settings').select('*').eq('category', 'integration')` |
| Save setting | `supabase.from('branch_settings').upsert({ branch_id, key, value, category: 'integration' })` |
| Test webhook | Client-side: `fetch(webhookUrl, { method: 'POST', body: JSON.stringify({ test: true }) })` |

---

## 6. Edge Functions (9 functions)

> Chi tiết code đầy đủ: xem `docs/SUPABASE_FUNCTIONS.md`

| # | Function | Method | Endpoint | Auth | Request Body | Response |
|---|----------|--------|----------|------|-------------|----------|
| 1 | `check-in` | POST | `/functions/v1/check-in` | Bearer JWT | `{ reservationId?, walkIn?, tableIds, partySize, packageId?, flowMode }` | `{ ok, customerId, assignments, package }` |
| 2 | `add-order-item` | POST | `/functions/v1/add-order-item` | Bearer JWT | `{ orderId, menuItemId, quantity, note?, modifiers? }` | `{ ok, item, subtotal, vat, total }` |
| 3 | `checkout` | POST | `/functions/v1/checkout` | Bearer JWT | `{ orderId, revenueType, customerId?, voucherCode?, taxCode?, payments[], notes? }` | `{ ok, invoiceId, invoiceNumber, total, change }` |
| 4 | `close-shift` | POST | `/functions/v1/close-shift` | Bearer JWT | `{ shiftId, closingCash, notes? }` | `{ ok, shift, summary, expectedCash, closingCash, cashDifference }` |
| 5 | `export-shift-csv` | GET | `/functions/v1/export-shift-csv?shiftId=...` | Bearer JWT | — | CSV file (blob) |
| 6 | `kds-push` | POST | `/functions/v1/kds-push` | Bearer JWT | `{ orderId, itemIds[] }` | `{ ok, sent: number }` |
| 7 | `issue-tax-invoice` | POST | `/functions/v1/issue-tax-invoice` | Bearer JWT | `{ invoiceId, taxCode, customerCompany, customerAddress, customerEmail? }` | `{ ok, invoiceNumber, vtNumber, vtStatus, viewUrl }` |
| 8 | `request-checkout` | POST | `/functions/v1/request-checkout` | Bearer JWT | `{ tableId }` | `{ ok }` |
| 9 | `custom-access-token` | POST | (Auto-called by Supabase Auth Hook) | Internal | `{ user_id, claims }` | `{ ...claims, role, branch_id }` |

### Gọi Edge Function từ Vue

```ts
// Pattern chung
const { data, error } = await supabase.functions.invoke('function-name', {
  body: { /* payload */ },
})
if (error) throw error
return data
```

### Deploy tất cả

```bash
supabase functions deploy check-in
supabase functions deploy add-order-item
supabase functions deploy checkout
supabase functions deploy close-shift
supabase functions deploy export-shift-csv
supabase functions deploy kds-push
supabase functions deploy issue-tax-invoice
supabase functions deploy request-checkout
supabase functions deploy custom-access-token
```

---

## 7. Realtime Subscriptions Map

> 7 bảng cần enable Realtime trong Supabase Dashboard.

```sql
-- Chạy trong SQL Editor:
alter publication supabase_realtime add table public.reservations;
alter publication supabase_realtime add table public.tables;
alter publication supabase_realtime add table public.table_assignments;
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_items;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.audit_events;
```

### Subscription Matrix

| View | Table | Event | Filter | Purpose |
|------|-------|-------|--------|---------|
| TimelineView | `reservations` | `*` | branch_id | Auto-refresh timeline |
| TimelineView | `table_assignments` | `*` | branch_id | Table assignment changes |
| FloorPlanView | `tables` | `UPDATE` | branch_id | Table status changes |
| FloorPlanView | `table_assignments` | `*` | branch_id | Seat/release events |
| ReceptionDashboard | `notifications` | `INSERT` | channel=reception-panel | Checkout alerts from tablet |
| ReceptionDashboard | `table_assignments` | `*` | branch_id | Active table changes |
| ReceptionCheckout | `vouchers` | `UPDATE` | code=X | Voucher used_count live check |
| StaffFloorPlan | `tables` | `UPDATE` | branch_id | Status changes |
| StaffActiveTables | `table_assignments` | `*` | branch_id | New seats / releases |
| StaffActiveTables | `order_items` | `INSERT` | branch_id | New items ordered |
| TabletIdle | `table_assignments` | `INSERT` | table_id=X | Wake up when assigned |
| TabletOrder | `order_items` | `*` | order_id=X | Items added/updated |
| TabletCheckout | `table_assignments` | `UPDATE` | table_id=X | Released → go to idle |
| KitchenKDS | `order_items` | `INSERT` | branch_id | New items to prepare |
| KitchenKDS | `order_items` | `UPDATE` | branch_id | Status transitions |
| AdminAudit | `audit_events` | `INSERT` | branch_id | Live audit log |
| ManagerDashboard | `payments` | `INSERT` | branch_id | Live revenue counter |

---

## 8. RLS Policy Matrix

> Chi tiết SQL: xem `docs/SUPABASE_AUTH.md` mục 6.2

| Table | admin | manager | reception | staff | kitchen |
|-------|-------|---------|-----------|-------|---------|
| `branches` | ALL | SELECT all | SELECT own | SELECT own | SELECT own |
| `users` | ALL | SELECT+UPDATE own | SELECT own | SELECT own | — |
| `zones` | ALL | ALL own | ALL own | SELECT own | SELECT own |
| `tables` | ALL | ALL own | ALL own | SELECT own | SELECT own |
| `customers` | ALL | ALL own | ALL own | SELECT own | — |
| `menu_*`, `packages` | ALL | ALL own | SELECT own | SELECT own | SELECT own |
| `reservations` | ALL | ALL own | ALL own | SELECT own | — |
| `table_assignments` | ALL | ALL own | ALL own | ALL own | SELECT own |
| `orders`, `order_items` | ALL | ALL own | ALL own | INSERT+UPDATE own | SELECT own |
| `invoices` | ALL | ALL own | ALL own | — | — |
| `payments` | ALL | ALL own | ALL own | — | — |
| `shifts` | ALL | ALL own | own user only | — | — |
| `kpi_targets` | ALL | ALL own | — | — | — |
| `marketing_costs` | ALL | ALL own | — | — | — |
| `audit_events` | SELECT | SELECT own | SELECT own | INSERT only | — |
| `notifications` | SELECT | SELECT own | SELECT own | SELECT own | — |
| `branch_settings` | ALL | ALL own | SELECT own | SELECT own | SELECT own |

**"own"** = `branch_id = current_branch_id()`

---

## 9. Seed Data

Chạy sau khi schema đã apply, trước khi test:

```sql
-- Branch
insert into public.branches (id, name, code, address, phone, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Ngưu Cát Quận 1', 'B001', '123 Nguyễn Huệ, Q1, TP.HCM', '028-1234-5678', true),
  ('b1000000-0000-0000-0000-000000000002', 'Ngưu Cát Phú Nhuận', 'B002', '456 Phan Xích Long, Phú Nhuận', '028-8765-4321', true);

-- Zones (B001)
insert into public.zones (branch_id, name, sort_order) values
  ('b1000000-0000-0000-0000-000000000001', 'Khu A - VIP', 1),
  ('b1000000-0000-0000-0000-000000000001', 'Khu B - Sân Vườn', 2),
  ('b1000000-0000-0000-0000-000000000001', 'Khu C - Tầng 2', 3),
  ('b1000000-0000-0000-0000-000000000001', 'Khu R - Phòng Riêng', 4),
  ('b1000000-0000-0000-0000-000000000001', 'Khu T - Terrace', 5);

-- Tables (10 bàn cho B001, zone A)
insert into public.tables (branch_id, zone_id, code, capacity, status) values
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A01', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A02', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu A - VIP' limit 1), 'A03', 6, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu B - Sân Vườn' limit 1), 'B01', 4, 'available'),
  ('b1000000-0000-0000-0000-000000000001', (select id from zones where name='Khu B - Sân Vườn' limit 1), 'B02', 8, 'available');

-- Menu categories
insert into public.menu_categories (branch_id, name, sort_order, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Thịt Bò', 1, true),
  ('b1000000-0000-0000-0000-000000000001', 'Hải Sản', 2, true),
  ('b1000000-0000-0000-0000-000000000001', 'Rau Củ & Nấm', 3, true),
  ('b1000000-0000-0000-0000-000000000001', 'Đồ Uống', 4, true),
  ('b1000000-0000-0000-0000-000000000001', 'Tráng Miệng', 5, true);

-- Menu items (sample)
insert into public.menu_items (branch_id, category_id, name, price, cost, is_available) values
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Thăn Ngoại Wagyu A5', 500000, 180000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Lưỡi Bò Thượng Hạng', 400000, 120000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Thịt Bò' limit 1), 'Dẻ Sườn Bò', 380000, 95000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Rau Củ & Nấm' limit 1), 'Nấm Nhật Kiểu', 120000, 25000, true),
  ('b1000000-0000-0000-0000-000000000001', (select id from menu_categories where name='Đồ Uống' limit 1), 'Rượu Sake Chín', 800000, 450000, true);

-- Packages
insert into public.packages (branch_id, name, type, price, item_limit, duration_minutes, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'Set Biz Trưa', 'set', 350000, 5, 90, true),
  ('b1000000-0000-0000-0000-000000000001', 'Premium Buffet', 'buffet', 1380000, 20, 120, true),
  ('b1000000-0000-0000-0000-000000000001', 'Drink A', 'drink', 690000, 10, 120, true);

-- KPI targets
insert into public.kpi_targets (branch_id, metric_key, target_value, period_start, period_end, scope) values
  ('b1000000-0000-0000-0000-000000000001', 'revenue_daily', 15000000, '2026-06-01', '2026-06-30', 'daily'),
  ('b1000000-0000-0000-0000-000000000001', 'revenue_weekly', 90000000, '2026-06-01', '2026-06-30', 'weekly'),
  ('b1000000-0000-0000-0000-000000000001', 'revenue_monthly', 360000000, '2026-06-01', '2026-06-30', 'monthly');
```

---

## 10. Checklist triển khai

### Phase 0: Infrastructure

- [ ] `.env` file với `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`
- [ ] `npm install @supabase/supabase-js`
- [ ] `src/lib/supabase.ts` tạo xong
- [ ] `src/types/database.ts` generated
- [ ] `supabase gen types typescript` chạy được

### Phase 1: Auth

- [ ] `src/composables/useAuth.ts` tạo xong (copy từ SUPABASE_AUTH.md §5.1)
- [ ] `src/views/LoginView.vue` tạo xong (copy từ SUPABASE_AUTH.md §5.3)
- [ ] Route `/login` thêm vào router
- [ ] Router guard trong `main.ts`
- [ ] Edge Function `custom-access-token` deployed
- [ ] Auth Hook enabled trong Supabase Dashboard
- [ ] Test: login → redirect đúng role

### Phase 2: Core Composables

- [ ] `useRealtime.ts` (copy từ SUPABASE_REALTIME.md §2)
- [ ] `useBranch.ts`
- [ ] `useCheckIn.ts`
- [ ] `useOrder.ts`
- [ ] `useCheckout.ts`
- [ ] `useShift.ts`
- [ ] `useKDS.ts`
- [ ] `useReport.ts`

### Phase 3: Wire Views (theo portal)

- [ ] **Reception** (highest impact — core POS flow):
  - [ ] ReceptionDashboardView — realtime reservations + checkout alerts
  - [ ] ReceptionCheckoutView — checkout flow + payment
  - [ ] ReceptionCloseShiftView — shift management
- [ ] **Staff**:
  - [ ] StaffFloorPlanView — realtime table status
  - [ ] StaffOpenTableView — check-in flow
  - [ ] StaffActiveTablesView — active table monitoring
  - [ ] StaffInDiningCRMView — customer lookup
- [ ] **Tablet**:
  - [ ] TabletIdleView — auto-wake on assignment
  - [ ] TabletOrderView — ordering + KDS push
  - [ ] TabletCheckoutView — checkout request
- [ ] **Kitchen**:
  - [ ] KitchenKDSView — order queue + timer
- [ ] **Manager**:
  - [ ] ManagerDashboardView — KPI + live revenue
  - [ ] ManagerRevenueView — reports
  - [ ] ManagerCOGSView — cost analysis
  - [ ] ManagerMarketingView — attribution
  - [ ] ManagerCRMView — customer management
  - [ ] ManagerInventoryView — stock management
- [ ] **Admin**:
  - [ ] AdminDashboardView — system stats
  - [ ] AdminAccountsView — user management
  - [ ] AdminMenusView — menu CRUD
  - [ ] AdminFloorsView — floor plan editor
  - [ ] AdminKPIView — target configuration
  - [ ] AdminAuditView — audit log

### Phase 4: Edge Functions Deploy

- [ ] 9 Edge Functions deployed
- [ ] Secrets set (`VT_API_KEY`, `VT_API_URL`)
- [ ] End-to-end test: check-in → order → KDS → checkout → close-shift

### Phase 5: Realtime

- [ ] 7 tables added to `supabase_realtime` publication
- [ ] All views with realtime subscriptions verified
- [ ] Cleanup functions verified (no channel leaks)
- [ ] Connection count < 500 per branch

---

## Quick Reference: Composable → View Mapping

| Composable | Used By Views |
|-----------|---------------|
| `useAuth` | ALL views (via router guard) + LoginView |
| `useRealtime` | Timeline, FloorPlan, ReceptionDashboard, StaffFloor, TabletOrder, TabletIdle, KitchenKDS, AdminAudit, ManagerDashboard |
| `useBranch` | Admin*, Superadmin*, ManagerDashboard |
| `useCheckIn` | StaffOpenTableView |
| `useOrder` | TabletOrderView, StaffActiveTablesView |
| `useCheckout` | ReceptionCheckoutView, TabletCheckoutView |
| `useShift` | ReceptionDashboardView, ReceptionCloseShiftView |
| `useKDS` | KitchenKDSView, TabletOrderView |
| `useTaxInvoice` | ReceptionCheckoutView |
| `useReservation` | TimelineView, ListView, ReceptionDashboardView |
| `useMenu` | AdminMenusView, TabletOrderView, KitchenKDS (sold-out) |
| `useTable` | AdminFloorsView, StaffFloorPlanView |
| `useCustomer` | ManagerCRMView, StaffInDiningCRMView, ReceptionCheckoutView |
| `useKPI` | AdminKPIView, ManagerDashboardView |
| `useMarketing` | ManagerMarketingView |
| `useAudit` | AdminAuditView, AdminDashboardView |
| `useInventory` | ManagerInventoryView |
| `useReport` | ManagerRevenueView, ManagerCOGSView, ManagerDashboardView |
