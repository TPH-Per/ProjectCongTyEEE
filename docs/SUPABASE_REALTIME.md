# SUPABASE_REALTIME.md — Live updates cho 27 chức năng

> Supabase Realtime dùng Phoenix Channels qua WebSocket. Mỗi client subscribe tối đa 1 channel, mỗi channel có thể có nhiều "topic" (postgres_changes per table + filter).

## 1. Cấu hình Realtime (đã làm ở SETUP)

7 bảng đã enable Realtime:
- `reservations` — Manager timeline, Reception dashboard
- `tables` — Staff floor plan, Manager floor
- `table_assignments` — Staff open/seat
- `orders` — KDS, Manager dashboard
- `order_items` — KDS, Tablet order
- `notifications` — Staff panel
- `vouchers` — Manager (optional)

Filter mặc định: `branch_id=eq.<current-branch-id>` (tiết kiệm connection slots).

## 2. Tạo composable `useRealtime` gom logic

`src/composables/useRealtime.ts`:

```ts
import { ref, onUnmounted, type Ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'
import { RealtimeChannel } from '@supabase/supabase-js'

const channels = new Map<string, RealtimeChannel>()

export function useRealtime() {
  const { branchId } = useAuth()
  const status = ref<'connecting' | 'connected' | 'disconnected' | 'error'>('disconnected')

  /**
   * Subscribe to postgres_changes on a table.
   * Auto-cleanup khi component unmount.
   */
  function watchTable<T = any>(
    table: string,
    event: 'INSERT' | 'UPDATE' | 'DELETE' | '*',
    onChange: (payload: { eventType: string; new: T; old: T }) => void,
    filter?: Record<string, string | number>,
  ): () => void {
    const channelName = `watch:${table}:${event}:${JSON.stringify(filter ?? {})}`
    let ch = channels.get(channelName)

    if (!ch) {
      ch = supabase
        .channel(channelName)
        .on(
          'postgres_changes' as any,
          {
            event,
            schema: 'public',
            table,
            filter: buildPgFilter(branchId.value, filter),
          },
          (payload: any) => onChange({
            eventType: payload.eventType,
            new: payload.new as T,
            old: payload.old as T,
          }),
        )
        .subscribe((s) => {
          status.value = s === 'SUBSCRIBED' ? 'connected' : 'connecting'
        })
      channels.set(channelName, ch)
    }

    // Return cleanup function
    return () => {
      const c = channels.get(channelName)
      if (c) {
        supabase.removeChannel(c)
        channels.delete(channelName)
      }
    }
  }

  function buildPgFilter(
    branch: string | null | undefined,
    extra?: Record<string, string | number>,
  ): string {
    const parts: string[] = []
    if (branch) parts.push(`branch_id=eq.${branch}`)
    if (extra) {
      for (const [k, v] of Object.entries(extra)) {
        parts.push(`${k}=${typeof v === 'string' ? `eq.${v}` : `eq.${v}`}`)
      }
    }
    return parts.join(',')
  }

  /**
   * Broadcast channel (in-app pub/sub, không qua Postgres).
   * Dùng cho tab coordination: ví dụ 2 receptionist cùng ca,
   * bấm checkout 1 người thì người kia thấy disable ngay.
   */
  function broadcast(
    channelName: string,
    event: string,
    onMessage: (payload: any) => void,
  ): () => void {
    const ch = supabase.channel(channelName, { config: { broadcast: { self: false } } })
    ch
      .on('broadcast', { event }, ({ payload }) => onMessage(payload))
      .subscribe()
    return () => {
      supabase.removeChannel(ch)
    }
  }

  function sendBroadcast(channelName: string, event: string, payload: any) {
    const ch = supabase.channel(channelName)
    ch.send({ type: 'broadcast', event, payload })
    // Channel broadcast không cần subscribe, nhưng cleanup
    setTimeout(() => supabase.removeChannel(ch), 100)
  }

  onUnmounted(() => {
    // Auto-cleanup nếu composable dùng trong setup() scope
    for (const [name, ch] of channels) {
      if (ch.state === 'closed') {
        channels.delete(name)
      }
    }
  })

  return { watchTable, broadcast, sendBroadcast, status }
}
```

## 3. Wire Realtime cho từng view

### 3.1. Manager — Timeline (F1)

File `src/views/TimelineView.vue` (đã có sẵn, refactor phần data):

```vue
<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useRealtime } from '@/composables/useRealtime'
// ...

const allReservations = ref<Reservation[]>([])
const cleanupFns: Array<() => void> = []
const { watchTable } = useRealtime()

async function loadInitial() {
  const { data, error } = await supabase
    .from('reservations')
    .select(`
      id, booking_code, reservation_date, reservation_time, guests, status, source, type,
      customer_snapshot,
      table_assignments(id, table_id, tables(code, zone_id))
    `)
    .eq('branch_id', useAuth().branchId.value)
    .order('reservation_time', { ascending: true })
  if (error) throw error
  allReservations.value = data ?? []
}

onMounted(async () => {
  await loadInitial()
  // Live update khi có reservation mới / status đổi
  cleanupFns.push(
    watchTable<Reservation>('reservations', 'INSERT', () => loadInitial()),
    watchTable<Reservation>('reservations', 'UPDATE', () => loadInitial()),
    watchTable<Reservation>('reservations', 'DELETE', () => loadInitial()),
    watchTable('table_assignments', '*', () => loadInitial()),
  )
})

onUnmounted(() => cleanupFns.forEach(fn => fn()))
</script>
```

### 3.2. Manager — List (F2)

Giống F1, nhưng filter `eq('status', statusFilter)` ở client. Có thể dùng `useRealtime().watchTable('reservations', 'UPDATE', ...)` với filter `status=eq.Pending` để auto-refresh khi staff check-in.

### 3.3. Manager — Floor plan (F3)

```ts
onMounted(async () => {
  await loadTables()
  cleanupFns.push(
    watchTable<Table>('tables', '*', () => loadTables()),
    watchTable<TableAssignment>('table_assignments', '*', () => loadTables()),
  )
})
```

### 3.4. Reception — Dashboard (C1)

```ts
onMounted(async () => {
  await loadCheckoutAlerts()
  await loadActiveTables()
  cleanupFns.push(
    // Yêu cầu checkout từ tablet → alert badge
    watchTable<AuditEvent>('audit_events', 'INSERT', (p) => {
      if (p.new.action === 'table.checkout_requested') loadCheckoutAlerts()
    }, { action: 'eq.table.checkout_requested' }),
    // Bàn vừa được mở
    watchTable('table_assignments', 'INSERT', () => loadActiveTables()),
    watchTable('table_assignments', 'UPDATE', () => loadActiveTables()),
  )
})
```

### 3.5. Reception — Checkout (C2)

```ts
// Khi bấm "Apply" voucher → realtime check max_uses
watchTable<Voucher>('vouchers', 'UPDATE', (p) => {
  if (p.new.code === enteredVoucherCode.value && p.new.used_count >= (p.new.max_uses ?? Infinity)) {
    errorMessage.value = 'Voucher đã hết lượt sử dụng'
  }
})
```

### 3.6. Staff — Floor plan (D1)

Realtime cho `tables.status` + `table_assignments.released_at`:

```ts
onMounted(async () => {
  await loadFloor()
  cleanupFns.push(
    watchTable<Table>('tables', 'UPDATE', () => loadFloor()),
    watchTable<TableAssignment>('table_assignments', 'INSERT', () => loadFloor()),
    watchTable<TableAssignment>('table_assignments', 'UPDATE', () => loadFloor()),
  )
})
```

### 3.7. Staff — Active tables (D2)

```ts
onMounted(async () => {
  await loadActive()
  cleanupFns.push(
    watchTable('table_assignments', 'UPDATE', (p) => {
      if (p.new.released_at) loadActive()  // vừa đóng bàn
    }),
    watchTable('order_items', 'INSERT', () => loadActive()),  // có món mới
  )
})
```

### 3.8. Tablet — Order (E3)

Đây là view cần Realtime nhiều nhất:
- Item limit "3/10" → update khi staff thêm món
- Locked category → update khi staff đổi flow_mode
- Order status (Pending → Preparing → Served)

```ts
onMounted(async () => {
  await loadMenu()
  await loadCurrentOrder()
  const orderId = currentOrder.value?.id
  if (orderId) {
    cleanupFns.push(
      // Món mới được thêm
      watchTable<OrderItem>('order_items', 'INSERT', (p) => {
        if (p.new.order_id === orderId) {
          loadCurrentOrder()
          // Toast: "Đã thêm món X"
        }
      }, { order_id: `eq.${orderId}` }),
      // Trạng thái món thay đổi
      watchTable('order_items', 'UPDATE', () => loadCurrentOrder(), { order_id: `eq.${orderId}` }),
      // Staff đổi flow_mode / package
      watchTable<TableAssignment>('table_assignments', 'UPDATE', (p) => {
        if (p.new.table_id === currentTableId.value) {
          loadMenu()  // reload locked categories
        }
      }),
    )
  }
})
```

### 3.9. Tablet — Checkout (E4)

```ts
onMounted(async () => {
  await sendCheckoutRequest()
  // Realtime: reception bấm "Đã đến quầy" → hiển thị "Đang thanh toán"
  cleanupFns.push(
    watchTable('table_assignments', 'UPDATE', (p) => {
      // tùy convention, ví dụ metadata.checkout_acknowledged
      if (p.new.metadata?.checkout_acknowledged) {
        router.push('/tablet/thank-you')
      }
    }),
  )
})
```

### 3.10. Manager — Dashboard (B1), Revenue (B2), COGS (B3)

Không bắt buộc Realtime vì là static report. Nhưng có thể thêm "live revenue today" subscribe `payments` filter `revenue_type`:

```ts
watchTable<Payment>('payments', 'INSERT', (p) => {
  // Cộng dồn vào "Today's revenue" KPI
  todayRevenue.value += p.new.amount
}, { revenue_type: 'eq.dinner' })
```

### 3.11. Manager — Marketing (B5), CRM (B4)

Không cần Realtime.

### 3.12. Admin — Dashboard (A1), Audit (A6)

Audit cần Realtime để xem log liên tục:

```ts
watchTable<AuditEvent>('audit_events', 'INSERT', (p) => {
  auditList.value = [p.new, ...auditList.value].slice(0, 100)
})
```

## 4. Channel management — tránh leak

`useRealtime` composable đã cache channel theo `channelName`. **Mỗi component mount tạo cleanup function, onUnmounted gọi supabase.removeChannel.**

Kiểm tra leak trong DevTools:
```ts
// src/composables/useDebugRealtime.ts
setInterval(() => {
  console.log('active channels:', supabase.getChannels().length)
}, 5000)
```

Nếu số channel tăng liên tục → có component nào đó quên cleanup.

## 5. Broadcast channel — coordination giữa các tab

Dùng cho 2 receptionist cùng lúc bấm checkout 1 bàn (cảnh báo nhau):

```ts
// reception-checkout component
const { broadcast, sendBroadcast } = useRealtime()

// Khi mở checkout view
const cleanup = broadcast('reception:co-browsing', 'viewing', (payload) => {
  if (payload.table_id === currentTableId.value) {
    isLockedByOther.value = true  // disable nút "In hóa đơn"
  }
})

// Khi click "In hóa đơn"
sendBroadcast('reception:co-browsing', 'processing', { table_id: currentTableId.value })

onUnmounted(() => cleanup())
```

## 6. Presence — biết ai đang online

Dùng cho Manager xem staff nào đang online:

```ts
const channel = supabase.channel('staff:online', { config: { presence: { key: userId } } })
channel
  .on('presence', { event: 'sync' }, () => {
    const state = channel.presenceState()
    onlineStaff.value = Object.values(state).flat() as any[]
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      await channel.track({ user_id: userId, name: userName, role: 'staff', since: new Date() })
    }
  })
```

## 7. Performance tuning

### 7.1. Limit payload

Tránh subscribe `*` mà không filter. Ví dụ:
```ts
// ❌ Subscribe toàn bộ orders → nặng
watchTable('orders', '*', ...)

// ✅ Chỉ orders của branch + status active
watchTable('orders', 'INSERT', ..., { status: 'neq.Paid' })
```

### 7.2. Debounce update

Khi nhận event, không refetch toàn bộ — chỉ update row đó:

```ts
watchTable('reservations', 'UPDATE', (p) => {
  // Patch vào list thay vì loadInitial
  const idx = allReservations.value.findIndex(r => r.id === p.new.id)
  if (idx >= 0) allReservations.value[idx] = { ...allReservations.value[idx], ...p.new }
}, { branch_id: `eq.${branchId.value}` })
```

### 7.3. Connection pool

Supabase Pro cho phép **500 realtime connections** đồng thời. Với 1 chi nhánh ~10 thiết bị (5 staff mobile + 1-2 reception + 5-10 tablet), tổng ~30 channels/branch. 5 chi nhánh = 150 → dư sức.

Nếu vượt → tăng plan hoặc tối ưu channel.

## 8. Fallback khi mất mạng

Realtime tự reconnect, nhưng khi reconnect cần reload state:

```ts
supabase.channel('any').on('system', { event: 'disconnect' }, () => {
  status.value = 'disconnected'
})
// Khi reconnect → gọi loadInitial() ở component
```

Wrap trong composable:

```ts
function onConnectionChange(cb: (state: 'connected' | 'disconnected') => void) {
  const ch = supabase.channel('system:watch')
  ch.on('system', { event: 'disconnect' }, () => cb('disconnected'))
  ch.on('system', { event: 'connect' }, () => cb('connected'))
  ch.subscribe()
  return () => supabase.removeChannel(ch)
}
```

Dùng trong app root:

```ts
// src/App.vue
const cleanup = onConnectionChange((state) => {
  if (state === 'connected') {
    // reload all data
    eventBus.emit('reload-all')
  }
})
onUnmounted(cleanup)
```

## 9. Realtime + Auth token refresh

Khi JWT refresh (mỗi 1h), Supabase tự cập nhật channel auth. Nhưng nếu channel bị disconnect do lỗi auth, cần:

```ts
supabase.auth.onAuthStateChange((event) => {
  if (event === 'TOKEN_REFRESHED') {
    // Resubscribe tất cả channel
    for (const ch of supabase.getChannels()) {
      if (ch.state === 'joined') ch.unsubscribe()
      ch.subscribe()
    }
  }
})
```

## 10. Checklist

- [ ] 7 bảng enabled Realtime trong Supabase Dashboard
- [ ] `src/composables/useRealtime.ts` đã tạo
- [ ] 5 view có Realtime (Timeline, Floor, Reception Dashboard, Staff Floor, Tablet Order)
- [ ] Cleanup function gọi đúng trong `onUnmounted`
- [ ] Connection count monitor trong dev mode
- [ ] Test: mở 2 tab Manager Timeline → INSERT reservation ở tab A → tab B refresh ngay

→ Tiếp theo: đọc `SUPABASE_IMPLEMENTATION.md` để build SQL queries + Vue components cho từng chức năng.
