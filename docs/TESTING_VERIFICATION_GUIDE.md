# TESTING & VERIFICATION GUIDE — Kiểm thử API + Tích hợp

> **Mục đích:** Agent đọc file này để biết CÁCH kiểm thử từng API, từng composable, từng realtime subscription.
> Mỗi test case có: input, expected output, và lệnh verify.

---

## 1. Setup Test Environment

### 1.1 Test Data Prerequisites

Trước khi chạy test, chắc chắn đã có:

```sql
-- Kiểm tra bảng có data:
SELECT 'branches' as tbl, count(*) FROM branches
UNION ALL SELECT 'users', count(*) FROM users
UNION ALL SELECT 'zones', count(*) FROM zones
UNION ALL SELECT 'tables', count(*) FROM tables
UNION ALL SELECT 'menu_categories', count(*) FROM menu_categories
UNION ALL SELECT 'menu_items', count(*) FROM menu_items
UNION ALL SELECT 'packages', count(*) FROM packages;
```

Expected: Mỗi bảng phải > 0. Nếu 0, chạy seed data từ `API_IMPLEMENTATION_GUIDE.md` §9.

### 1.2 Test User Credentials

| Role | Email | Branch |
|------|-------|--------|
| admin | `admin@nguucat.vn` | B001 |
| manager | `manager.q1@nguucat.vn` | B001 |
| reception | `reception.q1@nguucat.vn` | B001 |
| staff | `staff.q1@nguucat.vn` | B001 |
| kitchen | `kitchen.q1@nguucat.vn` | B001 |

### 1.3 Helper: Get Auth Token

```ts
// src/utils/test-helpers.ts — CHỈ dùng trong dev mode
import { supabase } from '@/lib/supabase'

export async function getTestToken(email: string, password: string): Promise<string> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data.session!.access_token
}

export async function verifyJWTClaims(token: string) {
  const payload = JSON.parse(atob(token.split('.')[1]))
  console.table({
    role: payload.role,
    branch_id: payload.branch_id,
    exp: new Date(payload.exp * 1000).toISOString(),
  })
  return payload
}
```

---

## 2. Unit Tests — Composables

### 2.1 useAuth

```ts
// Test trong browser console hoặc vitest:

// TEST-AUTH-U01: signIn success
const { signIn, session, role, branchId } = useAuth()
await signIn('admin@nguucat.vn', '<password>')
console.assert(session.value !== null, 'Session should not be null')
console.assert(role.value === 'admin', `Expected admin, got ${role.value}`)
console.assert(branchId.value !== null, 'Branch ID should not be null')

// TEST-AUTH-U02: signIn fail
try { await signIn('wrong@email.com', 'wrong') } catch (e) {
  console.assert(e.message.includes('Invalid'), 'Should get invalid credentials error')
}

// TEST-AUTH-U03: signOut
const { signOut, isAuthenticated } = useAuth()
await signOut()
console.assert(!isAuthenticated.value, 'Should be logged out')
```

### 2.2 useBranch

```ts
// TEST-BRANCH-U01: activeBranchId defaults to JWT claim
const { activeBranchId } = useBranch()
console.assert(activeBranchId.value !== null, 'Should have default branch')

// TEST-BRANCH-U02: admin can switch branch
const { selectBranch, listBranches } = useBranch()
const branches = await listBranches()
console.assert(branches.length > 0, 'Should have at least 1 branch')
selectBranch(branches[0].id)
console.assert(activeBranchId.value === branches[0].id, 'Branch should switch')
```

### 2.3 useMenu

```ts
// TEST-MENU-U01: getCategories returns array
const { getCategories } = useMenu()
const cats = await getCategories()
console.assert(Array.isArray(cats), 'Should be array')
console.assert(cats.length > 0, 'Should have categories')

// TEST-MENU-U02: getItemsByCategory returns items
const { getItemsByCategory } = useMenu()
const items = await getItemsByCategory(cats[0].id)
console.assert(Array.isArray(items), 'Should be array')

// TEST-MENU-U03: createItem inserts and returns
const { createItem } = useMenu()
const newItem = await createItem({
  name: 'Test Món ' + Date.now(),
  price: 99000,
  cost: 30000,
  category_id: cats[0].id,
  is_available: true,
})
console.assert(newItem.id !== undefined, 'Should have ID')
console.assert(newItem.name.startsWith('Test Món'), 'Name should match')

// TEST-MENU-U04: toggleAvailable
const { toggleAvailable } = useMenu()
await toggleAvailable(newItem.id, true)
const updated = await getItemsByCategory(cats[0].id)
const toggled = updated.find(i => i.id === newItem.id)
console.assert(toggled?.is_available === false, 'Should be false')

// CLEANUP
await supabase.from('menu_items').delete().eq('id', newItem.id)
```

### 2.4 useReservation

```ts
// TEST-RES-U01: create reservation
const { createReservation, getTodayReservations } = useReservation()
const today = new Date().toISOString().split('T')[0]
const res = await createReservation({
  reservation_date: today,
  reservation_time: '19:00',
  guests: 4,
  customer_snapshot: { name: 'Test Khách', phone: '0901234567' },
  marketing_channel: 'google_map',
})
console.assert(res.id !== undefined, 'Should have ID')
console.assert(res.status === 'Pending', 'Default status = Pending')
console.assert(res.booking_code !== undefined, 'Should have booking code')

// TEST-RES-U02: list today
const list = await getTodayReservations()
console.assert(list.some(r => r.id === res.id), 'Should contain new reservation')

// CLEANUP
await supabase.from('reservations').delete().eq('id', res.id)
```

### 2.5 useCustomer

```ts
// TEST-CUS-U01: search by phone
const { searchByPhone } = useCustomer()
const results = await searchByPhone('090')
console.assert(Array.isArray(results), 'Should be array')

// TEST-CUS-U02: create customer
const { createCustomer } = useCustomer()
const cust = await createCustomer({
  name: 'Test Customer',
  phone: '0999' + Date.now().toString().slice(-6),
})
console.assert(cust.id !== undefined, 'Should have ID')

// CLEANUP
await supabase.from('customers').delete().eq('id', cust.id)
```

---

## 3. Integration Tests — Edge Functions

### 3.1 Test Script (PowerShell)

```powershell
# === SETUP ===
$SUPABASE_URL = "https://<ref>.supabase.co"
$ANON_KEY = "<anon-key>"

function Get-Token($email, $password) {
  $body = @{ email = $email; password = $password } | ConvertTo-Json
  $resp = Invoke-RestMethod -Method POST `
    -Uri "$SUPABASE_URL/auth/v1/token?grant_type=password" `
    -Headers @{ "apikey" = $ANON_KEY; "Content-Type" = "application/json" } `
    -Body $body
  return $resp.access_token
}

function Invoke-EdgeFunction($name, $token, $body) {
  $headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
    "apikey" = $ANON_KEY
  }
  try {
    $resp = Invoke-RestMethod -Method POST `
      -Uri "$SUPABASE_URL/functions/v1/$name" `
      -Headers $headers `
      -Body ($body | ConvertTo-Json -Depth 10)
    return $resp
  } catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    return $null
  }
}

# === GET TOKENS ===
$STAFF_TOKEN = Get-Token "staff.q1@nguucat.vn" "<password>"
$RECEPTION_TOKEN = Get-Token "reception.q1@nguucat.vn" "<password>"
Write-Host "Staff token: $($STAFF_TOKEN.Substring(0,20))..." -ForegroundColor Green
Write-Host "Reception token: $($RECEPTION_TOKEN.Substring(0,20))..." -ForegroundColor Green
```

### 3.2 Test: check-in

```powershell
# TEST-EF-01: Walk-in check-in
$TABLE_ID = "<uuid-of-available-table>"  # Query: SELECT id FROM tables WHERE status='available' LIMIT 1

$result = Invoke-EdgeFunction "check-in" $STAFF_TOKEN @{
  walkIn = @{ customerName = "Test Guest"; guests = 2 }
  tableIds = @($TABLE_ID)
  partySize = @{ male = 1; female = 1; children = 0; ageBucket = "30-40" }
  flowMode = "free"
}

# VERIFY
Write-Host "check-in ok: $($result.ok)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})
Write-Host "customerId: $($result.customerId)"
Write-Host "assignments: $($result.assignments.Count)"

# VERIFY DB: table should be occupied
# SQL: SELECT status FROM tables WHERE id = '<TABLE_ID>'
# Expected: 'occupied'
```

### 3.3 Test: add-order-item

```powershell
# Get order ID from the check-in
# SQL: SELECT id FROM orders WHERE table_id = '<TABLE_ID>' AND status = 'Open'
$ORDER_ID = "<order-uuid>"
$MENU_ITEM_ID = "<wagyu-uuid>"  # SELECT id FROM menu_items WHERE name LIKE '%Wagyu%'

$result = Invoke-EdgeFunction "add-order-item" $STAFF_TOKEN @{
  orderId = $ORDER_ID
  menuItemId = $MENU_ITEM_ID
  quantity = 2
  note = "Medium rare"
}

Write-Host "add-order-item ok: $($result.ok)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})
Write-Host "subtotal: $($result.subtotal)"

# VERIFY DB:
# SQL: SELECT count(*) FROM order_items WHERE order_id = '<ORDER_ID>'
# Expected: >= 1
```

### 3.4 Test: kds-push

```powershell
# Get item IDs
# SQL: SELECT id FROM order_items WHERE order_id = '<ORDER_ID>' AND status = 'Pending'
$ITEM_IDS = @("<item-uuid-1>", "<item-uuid-2>")

$result = Invoke-EdgeFunction "kds-push" $STAFF_TOKEN @{
  orderId = $ORDER_ID
  itemIds = $ITEM_IDS
}

Write-Host "kds-push ok: $($result.ok), sent: $($result.sent)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})

# VERIFY DB:
# SQL: SELECT template, status FROM notifications WHERE variables->>'order_id' = '<ORDER_ID>'
# Expected: template = 'kds_new_items'
```

### 3.5 Test: request-checkout

```powershell
$result = Invoke-EdgeFunction "request-checkout" $STAFF_TOKEN @{
  tableId = $TABLE_ID
}

Write-Host "request-checkout ok: $($result.ok)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})

# VERIFY DB:
# SQL: SELECT * FROM notifications WHERE template = 'checkout_request' ORDER BY created_at DESC LIMIT 1
# Expected: status = 'pending', channel = 'reception-panel'
```

### 3.6 Test: checkout

```powershell
# Open shift first
# SQL: INSERT INTO shifts (branch_id, user_id, opening_cash, status)
#      VALUES ('<branch>', '<reception-user-id>', 5000000, 'open') RETURNING id;
$SHIFT_ID = "<shift-uuid>"

$result = Invoke-EdgeFunction "checkout" $RECEPTION_TOKEN @{
  orderId = $ORDER_ID
  revenueType = "dinner"
  payments = @(
    @{ method = "cash"; amount = 1500000 }
  )
  notes = "Test checkout"
}

Write-Host "checkout ok: $($result.ok)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})
Write-Host "invoiceNumber: $($result.invoiceNumber)"
Write-Host "change: $($result.change)"

# VERIFY DB:
# 1. SELECT status FROM orders WHERE id = '<ORDER_ID>' → 'Paid'
# 2. SELECT status FROM invoices WHERE order_id = '<ORDER_ID>' → 'Paid'
# 3. SELECT status FROM tables WHERE id = '<TABLE_ID>' → 'available'
# 4. SELECT released_at FROM table_assignments WHERE table_id = '<TABLE_ID>' ORDER BY assigned_at DESC LIMIT 1
#    → NOT NULL
```

### 3.7 Test: close-shift

```powershell
$result = Invoke-EdgeFunction "close-shift" $RECEPTION_TOKEN @{
  shiftId = $SHIFT_ID
  closingCash = 6500000
  notes = "Ca tối bình thường"
}

Write-Host "close-shift ok: $($result.ok)" -ForegroundColor $(if($result.ok){"Green"}else{"Red"})
Write-Host "expected: $($result.expectedCash), closing: $($result.closingCash), diff: $($result.cashDifference)"

# VERIFY DB:
# SELECT status, closing_cash, expected_cash, cash_difference FROM shifts WHERE id = '<SHIFT_ID>'
# Expected: status = 'closed', values match
```

### 3.8 Test: export-shift-csv

```powershell
$headers = @{
  "Authorization" = "Bearer $RECEPTION_TOKEN"
  "apikey" = $ANON_KEY
}
Invoke-WebRequest -Method GET `
  -Uri "$SUPABASE_URL/functions/v1/export-shift-csv?shiftId=$SHIFT_ID" `
  -Headers $headers `
  -OutFile "test_shift_export.csv"

# VERIFY: File exists and has content
Get-Content "test_shift_export.csv" | Select-Object -First 5
# Expected: CSV headers + data rows
```

---

## 4. RLS Policy Tests

### 4.1 Cross-branch isolation

```sql
-- Login as staff B001, try to see B002 data
-- (Supabase client auto-applies RLS)

-- Test via SQL Editor with service_role override:
SET request.jwt.claim.branch_id = 'b1000000-0000-0000-0000-000000000001';
SET request.jwt.claim.role = 'staff';

SELECT count(*) FROM orders WHERE branch_id = 'b1000000-0000-0000-0000-000000000002';
-- Expected: 0 (RLS blocks cross-branch)

SELECT count(*) FROM orders WHERE branch_id = 'b1000000-0000-0000-0000-000000000001';
-- Expected: > 0 (own branch visible)
```

### 4.2 Role permission matrix test

```ts
// Test in browser console with different role logins:

// Login as KITCHEN user:
const { data, error } = await supabase.from('payments').select('*')
// Expected: error or empty (kitchen cannot read payments)

const { data: items } = await supabase.from('order_items').select('*').limit(5)
// Expected: returns items (kitchen can read order_items)

const { error: writeErr } = await supabase.from('menu_items').update({ price: 999 }).eq('id', '...')
// Expected: error (kitchen cannot write menu_items)
```

### 4.3 Automated RLS test script

```sql
-- Run as admin to verify all policies exist:
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected: Each table should have at least 1 read + 1 write policy
-- Count: >= 30 policies total
```

---

## 5. Realtime Integration Tests

### 5.1 Test Script (Browser Console)

```ts
// ── Test 1: Subscribe to table changes ──
import { supabase } from '@/lib/supabase'

const channel = supabase
  .channel('test-tables')
  .on(
    'postgres_changes',
    { event: 'UPDATE', schema: 'public', table: 'tables' },
    (payload) => {
      console.log('🔴 Table changed:', payload.new.code, '→', payload.new.status)
    }
  )
  .subscribe((status) => {
    console.log('Channel status:', status)
  })

// In another tab/SQL Editor:
// UPDATE public.tables SET status = 'maintenance' WHERE code = 'A01';
// Expected: Console log: "🔴 Table changed: A01 → maintenance"

// Cleanup:
supabase.removeChannel(channel)
```

### 5.2 Multi-tab sync test

```
STEP 1: Open Tab A (Reception Dashboard) + Tab B (Staff Floor Plan)
STEP 2: In Tab A, change reservation status
STEP 3: Verify Tab B updates within 2 seconds
STEP 4: In Tab B, check-in a table
STEP 5: Verify Tab A shows table as active within 2 seconds
```

### 5.3 Channel cleanup verification

```ts
// After navigating away from a view:
console.log('Active channels:', supabase.getChannels().length)
// Expected: 0 (after leaving all subscribed views)

// If > 0, there's a leak. Check onUnmounted cleanup.
```

---

## 6. Performance Benchmarks

### 6.1 Query performance targets

| Query | Max Time | How to measure |
|-------|----------|---------------|
| List menu items (50 items) | < 200ms | `console.time('menu'); await getItems(); console.timeEnd('menu')` |
| Today reservations | < 300ms | Same pattern |
| Revenue aggregate (1 month) | < 500ms | Same pattern |
| Full floor plan load | < 400ms | Same pattern |
| KDS pending items | < 200ms | Same pattern |

### 6.2 Realtime latency target

| Event | Max Latency |
|-------|-------------|
| Order item → KDS | < 2 seconds |
| Checkout request → Reception alert | < 2 seconds |
| Table status change → Floor plan | < 1 second |

### 6.3 Measurement script

```ts
async function benchmark(name: string, fn: () => Promise<any>, iterations = 5) {
  const times: number[] = []
  for (let i = 0; i < iterations; i++) {
    const start = performance.now()
    await fn()
    times.push(performance.now() - start)
  }
  const avg = times.reduce((a, b) => a + b) / times.length
  const max = Math.max(...times)
  console.log(`${name}: avg=${avg.toFixed(0)}ms, max=${max.toFixed(0)}ms`)
  return { avg, max }
}

// Usage:
await benchmark('getCategories', () => useMenu().getCategories())
await benchmark('getTodayReservations', () => useReservation().getTodayReservations())
```

---

## 7. Pre-Deploy Checklist

Chạy trước mỗi deploy:

```bash
# 1. TypeScript check
npx vue-tsc --noEmit

# 2. Build check
npm run build

# 3. Check .env not committed
git status | findstr ".env"
# Expected: not in staged/tracked files

# 4. Check no console.log in production code
findstr /S /I "console.log" src\composables\*.ts src\views\**\*.vue
# Expected: 0 matches (or only in dev-only blocks)

# 5. Check all imports resolve
npm run dev
# Expected: No "Failed to resolve import" errors in console
```

---

## 8. Test Results Template

Agent ghi kết quả test vào format này:

```markdown
## Test Report — Phase [X]
**Date:** YYYY-MM-DD
**Tester:** Agent/Human
**Environment:** localhost:5173 / pos.nguucat.vn

### Results

| Test ID | Description | Status | Notes |
|---------|-------------|--------|-------|
| TEST-AUTH-01 | Redirect to login | ✅ PASS | |
| TEST-AUTH-02 | Admin login | ✅ PASS | |
| TEST-EF-01 | check-in walk-in | ✅ PASS | |
| TEST-EF-02 | check-in reservation | ❌ FAIL | RLS policy missing for staff |

### Blockers
- [ ] Issue: ...
- [ ] Fix: ...

### Next Steps
- [ ] Fix failing tests
- [ ] Re-run and update this report
```
