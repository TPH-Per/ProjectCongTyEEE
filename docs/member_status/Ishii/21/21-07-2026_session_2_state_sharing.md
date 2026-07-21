# Báo cáo phiên làm việc — 21/07/2026 (Session 2: State Sharing & Bug Fix)

**Thành viên:** Ishii  
**Ngày:** Thứ Ba, 21/07/2026  
**Dự án:** POS Ngưu Cát (Vue 3 + TypeScript + Supabase + Pinia + Tailwind CSS)

---

## Tổng quan

Phiên làm việc tập trung vào 2 vấn đề chia sẻ trạng thái (state sharing) giữa các trang, và fix bug nghiêm trọng khiến đơn hàng khách không hiển thị.

| # | Công việc | Trạng thái |
|---|-----------|------------|
| 1 | Bridge `ReceptionFloorsView` đọc từ `receptionStore` | ✅ Hoàn thành |
| 2 | Kiểm tra transfer/merge/cancel trên `/reception/floors` | ✅ Hoàn thành (phát hiện thiếu) |
| 3 | Fix bug orders không hiển thị ở `/customer/orders` | ✅ Hoàn thành |

---

## 1. Bridge ReceptionFloorsView → receptionStore

### Mô tả

Trang `/reception/reservation-detail` ghi reservation vào `receptionStore` (Pinia, có localStorage). Nhưng trang `/reception/floors` đọc từ `restaurantStore.bookings` — một nguồn dữ liệu hoàn toàn riêng biệt. Kết quả: reservation tạo ở trang detail không xuất hiện trong danh sách chờ xếp bàn ở trang floors.

### Phân tích kiến trúc

| Trang | Store đang dùng | Vai trò |
|-------|----------------|---------|
| `ReservationDetailView` | `receptionStore` (Pinia + localStorage) | Ghi reservation ✅ |
| `ReceptionFloorsView` | `restaurantStore.bookings` (Pinia, mock data) | Đọc từ nguồn khác ❌ |

`receptionStore` đã có sẵn mọi thứ cần thiết:
- `waitingReservations` computed — lọc `!tableCode && status !== CANCELLED/COMPLETED`
- `assignTable(reservationId, tableCode, tableId)` — gán bàn, đổi status → `SEATED`
- localStorage persistence (`nguucat_reception_data`)
- `loadReservations()` — Supabase → localStorage → mock fallback

**Quyết định:** Bridge `ReceptionFloorsView` đọc từ `receptionStore` thay vì tạo store mới.

### Files sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/views/reception/ReceptionFloorsView.vue` | **Sửa** | Import `useReceptionSync`, merge data từ cả 2 store |

### Chi tiết thay đổi

#### Import & setup

```typescript
import { useReceptionSync } from '@/composables/useReceptionSync'

const {
  reservations: receptionReservations,
  waitingReservations: receptionWaiting,
  addReservation: receptionAddReservation,
  assignTable: receptionAssignTable,
  updateReservation: receptionUpdateReservation,
  loadReservations: loadReceptionReservations,
} = useReceptionSync()
```

#### `unassignedReservations` computed

Trước: chỉ đọc `restaurantStore.bookings`  
Sau: merge `receptionWaiting` (từ `receptionStore`) + `restaurantStore.bookings`, deduplicate theo `customerName + reservationTime`, sort theo giờ.

#### `handleDrop`

Trước: gán `reservation.assignedTable = table.code` trực tiếp lên `restaurantStore.bookings`  
Sau: tìm reservation trong `receptionReservations`, nếu tìm thấy → gọi `receptionAssignTable()` (cập nhật shared state, persist localStorage). Nếu không → fallback legacy `restaurantStore.bookings`.

#### `simulatedAreas`

Trước: chỉ xem `restaurantStore.bookings` cho table status  
Sau: merge cả `receptionReservations` có `tableCode` để tính Reserved/Arrived/Serving theo timeline.

#### Các helper khác cập nhật

| Function | Thay đổi |
|----------|----------|
| `checkConflicts` | Thêm quét `receptionReservations` cho conflict detection |
| `getShiftCount` | Merge cả 2 store cho shift count |
| `getZoneBookingsCount` | Merge cả 2 store cho zone count |
| `getTableReservationTime` | Check `receptionReservations` nếu `restaurantStore.bookings` không match |
| `getTableArrivalTime` | Check `receptionReservations` (CONFIRMED = Arrived) |
| `sidebarStats` | Merge counts từ cả 2 store |
| `saveNewBooking` | Thêm `receptionAddReservation()` để sync sang `ReservationDetailView` |
| `saveQuickArrived` | Thêm `receptionUpdateReservation()` cho reservations từ `receptionStore` |
| Quick Check-in modal | Thêm `<option>` cho reservations `PENDING` từ `receptionStore` |
| `onMounted` | Gọi `loadReceptionReservations()` để load shared data |

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~12s)

---

## 2. Kiểm tra transfer/merge/cancel trên `/reception/floors`

### Kết quả kiểm tra

| Chức năng | Trạng thái | Chi tiết |
|-----------|-----------|---------|
| 🔄 Chuyển bàn (Transfer) | ❌ Chưa có | Không có nút, không có selection mode |
| 🔗 Ghép bàn (Merge) | ❌ Chưa có | Không có logic ghép bàn |
| ❌ Hủy phiếu (Cancel) | ❌ Chưa có | Chỉ có nút "Hủy" đóng modal |

### Phát hiện

Các composable và component đã tồn tại nhưng chưa được tích hợp vào `ReceptionFloorsView`:

| File | Trạng thái | Đã dùng ở đâu |
|------|-----------|---------------|
| `src/composables/useTableOperations.ts` | ✅ Đầy đủ logic | `ReceptionOrderView.vue` |
| `src/components/reception/TableOperationsMenu.vue` | ✅ Context menu UI | `ReceptionOrderView.vue` |
| `src/views/reception/ReceptionOrderView.vue` | ✅ Tích hợp đầy đủ | Double-click bàn → context menu |

`ReceptionFloorsView` chỉ có `openTableModal` khi click bàn — không có double-click, context menu, hay selection mode.

### Những gì trang hiện tại CÓ

- Click bàn → mở modal chi tiết (đổi trạng thái, sửa tên khách, xem bill)
- Drag & drop reservation từ sidebar vào bàn trống
- Create booking, Quick Open, Quick Check-in modals
- Timeline slider (xem trạng thái bàn theo thời gian)

---

## 3. Fix bug orders không hiển thị ở `/customer/orders`

### Mô tả

Sau khi khách đặt món ở `/customer/cart`, đơn hàng không xuất hiện ở `/customer/orders`.

### Root Cause Analysis

3 lỗi cộng dồn:

| # | Lỗi | Vị trí | Mức độ |
|---|-----|--------|--------|
| 1 | `loadOrderHistory()` gọi API, mock mode trả `[]`, **ghi đè** `this.orders = []` | `customerStore.ts` | Nghiêm trọng |
| 2 | Orders **không được persist** vào localStorage — chỉ cart/session/table được lưu | `useCustomerSession.ts` | Nghiêm trọng |
| 3 | `restoreSessionFromLocalStorage()` không restore orders — reload trang = mất hết | `useCustomerSession.ts` | Nghiêm trọng |

### Chi tiết flow bị lỗi

```
CustomerCart.vue
  → store.orders.push(order)        ← OK, store có 1 order
  → store.clearCart()
  → syncCart()                       ← Chỉ lưu cart, không lưu orders

OrderHistory.vue (onMounted)
  → store.loadOrderHistory()
    → customerApiImpl.getOrderHistory()  ← Mock mode: return []
    → this.orders = history             ← GHI ĐÈ bằng [] — XÓA order!
  → orders = computed(() => store.orders) ← Trả [] — Empty state!
```

### Files sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/stores/customerStore.ts` | **Sửa** | Fix `loadOrderHistory`, thêm `persistOrders`/`restoreOrders` |
| `src/composables/useCustomerSession.ts` | **Sửa** | Thêm orders vào localStorage persistence |
| `src/views/customer/CustomerCart.vue` | **Sửa** | Gọi `store.persistOrders()` trong mock path |

### Chi tiết fix

#### Fix 1: `loadOrderHistory()` — skip API trong mock mode (`customerStore.ts`)

```typescript
// Trước: luôn gọi API, mock trả [] → ghi đè this.orders = []
async loadOrderHistory(): Promise<Order[]> {
  if (!this.session) return [];
  const history = await customerApiImpl.getOrderHistory(this.session.id);
  this.orders = history;  // ← BUG: ghi đè bằng [] trong mock mode
  return history;
}

// Sau: mock mode skip API, chỉ restore từ localStorage nếu cần
async loadOrderHistory(): Promise<Order[]> {
  if (!this.session) return [];
  if (!isSupabaseConfigured) {
    if (this.orders.length === 0) {
      this.restoreOrders();
    }
    return this.orders;
  }
  const history = await customerApiImpl.getOrderHistory(this.session.id);
  if (history.length > 0) {
    this.orders = history;
    this.persistOrders();
  }
  return this.orders;
}
```

#### Fix 2: Thêm `persistOrders()` / `restoreOrders()` (`customerStore.ts`)

```typescript
const ORDERS_KEY = 'nguucat_customer_orders';

persistOrders(): void {
  // Serialize dates as ISO strings for round-trip safety
  const serializable = this.orders.map(o => ({
    ...o,
    createdAt: o.createdAt instanceof Date ? o.createdAt.toISOString() : o.createdAt,
  }));
  localStorage.setItem(ORDERS_KEY, JSON.stringify(serializable));
},

restoreOrders(): void {
  const raw = localStorage.getItem(ORDERS_KEY);
  if (raw) {
    const parsed = JSON.parse(raw) as Order[];
    this.orders = parsed.map(o => ({
      ...o,
      createdAt: typeof o.createdAt === 'string' ? new Date(o.createdAt) : o.createdAt,
    }));
  }
},
```

#### Fix 3: `confirmOrder()` và `cancelOrder()` gọi `persistOrders()`

```typescript
async confirmOrder(): Promise<Order> {
  // ...
  this.orders.push(confirmedOrder);
  this.clearCart();
  this.persistOrders();  // ← Mới
  // ...
}

async cancelOrder(orderId: string): Promise<void> {
  this.orders = this.orders.filter(o => o.id !== orderId);
  this.persistOrders();  // ← Mới
  // ...
}
```

#### Fix 4: `resetState()` clear orders khỏi localStorage

```typescript
resetState(): void {
  // ...
  this.orders = [];
  localStorage.removeItem(ORDERS_KEY);  // ← Mới
}
```

#### Fix 5: `useCustomerSession.ts` — restore & clear orders

```typescript
const ORDERS_KEY = 'nguucat_customer_orders';

// restoreSessionFromLocalStorage():
if (savedOrders && store.orders.length === 0) {
  const parsed = JSON.parse(savedOrders) as any[];
  store.orders = parsed.map(o => ({
    ...o,
    createdAt: typeof o.createdAt === 'string' ? new Date(o.createdAt) : o.createdAt,
  }));
}

// clearSession():
localStorage.removeItem(ORDERS_KEY);
```

#### Fix 6: `CustomerCart.vue` — mock path gọi `persistOrders()`

```typescript
// Mock mode path
store.orders.push(order);
store.clearCart();
store.persistOrders();  // ← Mới
syncCart();
```

### Flow sau fix

```
CustomerCart.vue (mock mode)
  → store.orders.push(order)       ← Store có 1 order
  → store.persistOrders()          ← Lưu vào localStorage (nguucat_customer_orders)

OrderHistory.vue (onMounted)
  → store.loadOrderHistory()
    → isSupabaseConfigured = false → skip API
    → this.orders.length > 0 → giữ nguyên
    → return this.orders           ← Trả 1 order
  → orders = computed(() => store.orders) ← Trả 1 order ✅

(F5 reload trang)
  → restoreSessionFromLocalStorage()
    → Đọc nguucat_customer_orders → restore store.orders ← Có 1 order ✅
```

### Verification

- `vue-tsc --noEmit` — ✅ pass (0 errors)
- `vite build` — ✅ pass (built in ~12s)

---

## Danh sách file tạo/sửa tổng hợp

| File | Hành động | Công việc |
|------|-----------|-----------|
| `src/views/reception/ReceptionFloorsView.vue` | Sửa | Bridge receptionStore |
| `src/stores/customerStore.ts` | Sửa | Fix loadOrderHistory + persistOrders/restoreOrders |
| `src/composables/useCustomerSession.ts` | Sửa | Thêm orders localStorage persistence |
| `src/views/customer/CustomerCart.vue` | Sửa | Gọi persistOrders() trong mock path |

---

## Ghi chú kỹ thuật

- **Không tạo store mới** — `receptionStore` (Pinia) đã có sẵn mọi thứ cần thiết (localStorage, `waitingReservations`, `assignTable`). Tạo `reservationStore.js` (standalone `reactive()`) sẽ vi phạm convention TypeScript + Pinia.
- **`isSupabaseConfigured` = `false`** — hardcode trong `supabase.ts`, app luôn chạy mock mode
- **localStorage key mới:** `nguucat_customer_orders` — serialize `Order[]` với `Date` → ISO string
- **Backward compat:** `receptionFloorsView` vẫn đọc `restaurantStore.bookings` (legacy) và merge với `receptionStore` — không break existing mock data
- **3 cuộc đối thoại với user:** Cải tiến đề xuất của user (tạo store mới JS) thành dùng Pinia store đã có sẵn
- Type-check và build đều pass clean
