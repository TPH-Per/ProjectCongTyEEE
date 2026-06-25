# NguuCat POS - API & Frontend Implementation Guide

## 1. Architectural Overview

The application follows a thick-client architecture using Vue 3 and Supabase.
- **High-Consistency Data**: Structured into 13 relational tables (Branches, Users, Tables, Customers, Menu Items, Packages, Reservations, Orders, Order Items, Invoices, Payments, Vouchers, Shifts).
- **Flexibility via JSONB**: Data mapping 1-to-1 such as translation strings (i18n), course inclusions, applied vouchers, and tax info are natively stored inside JSONB columns to avoid expensive table joins.
- **Low-Consistency Data**: Metrics, waitlist info, and marketing targets are stored in `branch_settings`.
- **Edge Functions**: Reserved exclusively for atomic, multi-table transactions (Check-in, Order placement, Checkout, Shift Closing).

## 2. i18n Implementation (Vietnamese, English, Japanese)

Internationalization is deeply embedded at both the Database and UX/UI layer.

### Database Layer
Tables like `menu_items` and `packages` use the `i18n_name` JSONB column.
```json
{
  "vi": "Bò Wagyu A5",
  "en": "Wagyu A5 Beef",
  "ja": "和牛A5"
}
```

### UX-UI / Frontend Layer
The application UI must parse these JSONB fields based on the currently selected locale (via `vue-i18n`).
**Implementation Example in Vue:**
```typescript
import { useI18n } from 'vue-i18n'

export function useLocalizedName(item: { i18n_name: any }) {
  const { locale } = useI18n()
  return computed(() => item.i18n_name[locale.value] || item.i18n_name['vi'])
}
```
All UI displays (Staff Order, KDS, Customer QR Page) MUST render the name using this computed property to guarantee the customer sees their preferred language.

## 3. Database Schema Access (Direct via Composables)

Instead of dedicated Edge Functions, reading data MUST rely on Supabase's Auto-generated PostgREST APIs. RLS ensures security.

### 3.1. `useTable.ts`
- **Tables & Zones**: Zones are no longer a separate table. They are a `zone` string column on `tables`.
- **Fetching**:
```typescript
const { data } = await supabase.from('tables').select('*').order('zone')
const zones = computed(() => [...new Set(data.map(t => t.zone))])
```

### 3.2. `useMenu.ts`
- **Categories**: Categories are strings on `menu_items.category`.
- **Fetching**:
```typescript
const { data } = await supabase.from('menu_items').select('*').eq('is_available', true)
const categories = computed(() => [...new Set(data.map(item => item.category))])
```

### 3.3. `useReservation.ts` (Sessions)
- **Reservations = Sessions**: The `reservations` table acts as the unified session manager. It handles pending bookings and active dining sessions (`status = 'Dining'`).

## 4. Edge Functions (Transactional Endpoints)

Edge Functions MUST be used for operations spanning multiple tables or requiring atomic execution.

**Important Note:** Ensure `corsHeaders` is imported correctly from `../_shared/cors.ts`, NOT `../_shared/auth.ts`.

### 4.1. `check-in`
- **Purpose**: Creates/updates a `reservation`, links it to a `table_id`, sets status to `Dining`, generates `qr_token`, and emits an `audit_event`.
- **Payload**:
```json
{
  "reservationId": "uuid (optional for walk-ins)",
  "tableId": "uuid",
  "guests": 4,
  "courseId": "uuid (optional)"
}
```

### 4.2. `add-order-item`
- **Purpose**: Batches items into an `orders` record and inserts multiple `order_items`. Used by Staff and Customer QR.
- **Payload**:
```json
{
  "reservationId": "uuid",
  "items": [
    { "menuItemId": "uuid", "quantity": 2, "modifiers": [] }
  ]
}
```

### 4.3. `checkout`
- **Purpose**: Generates an `invoices` record from the `orders`, applies `vouchers` (updating their `used_count`), processes `payments`, closes the `reservation`, and frees the `tables`.
- **Payload**:
```json
{
  "reservationId": "uuid",
  "paymentMethod": "cash|card|transfer|voucher",
  "appliedVouchers": ["VOUCHER_CODE_1"],
  "amountPaid": 1000000
}
```

## 5. Security & Vacuum Optimizations
- **RLS**: Row Level Security dictates that staff can only query records where `branch_id = public.current_branch_id()`.
- **Vacuuming**: Because `reservations`, `order_items`, and `tables` receive high-frequency updates, their `autovacuum_vacuum_scale_factor` is tuned to `0.05` to prevent bloat.
