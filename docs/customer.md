# Customer Role — Full Implementation Plan

> **Purpose:** This document is both an **executable prompt for an AI agent** and the
> **single source of truth** for the Customer (tablet webview) subsystem.
> An AI agent (Gemini 3.1 Pro) must follow this plan step-by-step, phase-by-phase.
> After each phase, update the checklist in this file before moving on.

---

## 0. Context & Constraints

### 0.1 Project Overview
You are building the **Customer self-ordering interface** for a Vietnamese BBQ
buffet restaurant POS system called "Ngưu Cát" (NGUU CAT). The app runs as a
**webview on a tablet held in landscape orientation** at each dining table.

### 0.2 Tech Stack (Do NOT deviate)
| Layer | Technology |
|-------|-----------|
| Framework | Vue 3 (Composition API with `<script setup>`) |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS |
| State | Pinia |
| Routing | Vue Router 4 |
| i18n | vue-i18n (3 locales: `vi`, `en`, `ja`) |
| Backend | Supabase (PostgreSQL + Realtime + RPC) |
| Build | Vite |

### 0.3 Architecture Principles (CRITICAL — Read Carefully)
1. **RPC-Only Access:** The database enforces RLS on every table. Client code
   MUST call Supabase RPCs (`supabase.rpc('function_name', params)`) — NEVER
   query tables directly via `.from('table').select()`. The only exception is
   during mock/offline mode when `isSupabaseConfigured === false`.
2. **Dual-Mode API Layer:** Every API function must check `isSupabaseConfigured`.
   When `false`, return mock data. When `true`, call the real Supabase RPC.
3. **Landscape-First Design:** All layouts MUST be optimized for 1024×768 or
   1280×800 tablets in landscape. Use 2-column or 3-column layouts. Never
   design for portrait.
4. **Session Persistence:** Use `localStorage` to survive page reloads.
   Keys: `nguucat_customer_session`, `nguucat_customer_auth`,
   `nguucat_customer_table`, `nguucat_customer_cart`, `nguucat_customer_orders`.
5. **File Discipline:** Do NOT create extra `.md` files in docs/. Update THIS
   file only. Code goes in `src/`.

### 0.4 Database Schema Quick Reference
The full schema is at `docs/restaurant_schema_v6_simplified.sql`. Key tables
the Customer UI interacts with:

| DB Table | UI Concept | Key Columns |
|----------|-----------|-------------|
| `branches` | Branch selector | `branch_id`, `branch_name`, `branch_code` |
| `areas` | Area selector | `area_id`, `branch_id`, `area_name`, `sort_order` |
| `dining_tables` | Table selector | `dining_table_id`, `area_id`, `table_code`, `capacity`, `availability_status` |
| `dining_sessions` | Active session | `dining_session_id`, `branch_id`, `service_mode` (buffet/set_menu), `status` (open→ordering→checkout_requested→closed), `guest_count`, `language_code` |
| `session_tables` | Link session↔table | `dining_table_id`, `dining_session_id`, `is_primary` |
| `session_guests` | Each guest's package | `guest_no`, `package_branch_menu_item_id`, `package_price_vnd_snapshot`, `guest_type` (adult/child) |
| `menu_categories` | Category tabs | `menu_category_id`, `category_name`, `sort_order` |
| `menu_items` | Dish master data | `menu_item_id`, `item_name`, `item_type` (food/drink/buffet_package/set_menu/topping) |
| `branch_menu_items` | Branch-level price/availability | `branch_menu_item_id`, `base_price_vnd`, `availability_status`, `vat_rate` |
| `package_details` | Which items are included in a buffet package | `package_menu_item_id`, `included_menu_item_id`, `is_unlimited` |
| `orders` | Order header | `order_id`, `dining_session_id`, `order_source` ('tablet'), `status` |
| `order_details` | Each dish line | `order_detail_id`, `branch_menu_item_id`, `quantity`, `chargeable_quantity`, `unit_price_vnd_snapshot`, `kitchen_status`, `note` |
| `service_requests` | Call staff / add charcoal etc. | `request_type` ('call_staff','add_charcoal','water','checkout','other'), `status` |
| `customer_feedbacks` | Rating + survey | `rating` (1-5), `comment`, `survey_data` (jsonb), `customer_id` |
| `customers` | CRM record | `full_name`, `normalized_phone`, `email` |
| `outbox_jobs` | Async job queue (print, etc.) | `job_type`, `payload`, `status`, `attempt_count` |

### 0.5 Business Logic Issues Found & Corrections

> [!IMPORTANT]
> The following issues exist in the CURRENT codebase. You MUST fix them during
> implementation.

1. **MISSING FILE: `src/utils/packageRules.ts`.**
   This file is imported by `customerStore.ts` and `CustomerMenu.vue` but does
   NOT exist on disk. You must create it. It must export:
   - `computeTotals(subtotal: number) → { serviceCharge, vat, total }` where
     service_charge = 5% of subtotal, VAT = 8% of (subtotal + serviceCharge).
   - `calculateItemUnitPrice(item, packageDetails, guestType) → number` — returns
     0 if the item is included in the guest's buffet package, or the `base_price_vnd`
     if it's an à la carte add-on.
   - `applyPackage(item, packageName) → MenuItem` — clones the item and sets
     price to 0 if covered by the package.

2. **Service Request types mismatch between UI and DB.**
   - UI currently uses: `tissue`, `bowl`, `sauce`, `ice`, `grill_change`,
     `charcoal_change`, `request_bill`, `call_waiter`, `other`.
   - DB constraint allows: `call_staff`, `add_charcoal`, `water`, `checkout`, `other`.
   - **Fix:** Map UI labels to DB-compatible values. The service API layer must
     translate before sending to the RPC.

3. **`dining_sessions.service_mode` only allows `buffet` | `set_menu`.**
   The current UI doesn't ask the guest count or package selection. This is a
   critical gap because the schema expects `session_guests` rows with package
   info to determine pricing. **Fix:** After table confirmation, add a step
   where staff selects the package (e.g., "Buffet Thường 299K" / "Buffet VIP
   499K") and enters guest count (adults + children). This creates
   `session_guests` rows.

4. **`CustomerSession` type doesn't match `dining_sessions` columns.**
   Current type uses `tableId`, `tableNumber`, `areaId`, `areaName`, `staffId`,
   `startedAt`, `status`. The DB uses `dining_session_id`, `branch_id`,
   `guest_count`, `service_mode`, `language_code`, `status`
   (open/ordering/checkout_requested/closed). **Fix:** Redesign the TypeScript
   type to mirror the DB schema.

5. **Price is stored as `bigint` (VND, no decimal) in DB, but `number` in UI.**
   This is fine because VND has no fractional units. Just ensure consistent
   integer math (use `Math.round()` everywhere).

6. **The `order_details` table has `chargeable_quantity` separate from `quantity`.**
   For buffet items, `quantity` = actual count ordered, `chargeable_quantity` = 0
   (because it's included in the package price). For à la carte add-ons,
   `chargeable_quantity` = `quantity`. The UI must compute this correctly.

7. **Feedback: DB uses `survey_data` (jsonb) not `criteria` (string[]).**
   Store criteria selections inside `survey_data` as
   `{ "criteria": [...], "customerName": "...", "customerPhone": "..." }`.

---

## 1. File Structure (Target State)

After all phases are complete, the `src/` directory for Customer should look
exactly like this:

```
src/
├── types/
│   └── customer.ts              # All interfaces aligned to DB schema
├── utils/
│   ├── validators.ts            # UUID validator (exists, keep as-is)
│   └── packageRules.ts          # NEW — price computation engine
├── lib/
│   └── supabase.ts              # Supabase client (exists, keep as-is)
├── composables/
│   └── useCustomerSession.ts    # Session lifecycle & localStorage sync
├── data/
│   ├── mockMenuData.ts          # Mock menu categories/items
│   └── customerAreaData.ts      # Mock areas & tables
├── stores/
│   └── customerStore.ts         # Pinia store — single state tree
├── services/
│   └── customerApi.ts           # API layer (mock + Supabase RPC)
├── components/
│   └── customer/
│       ├── PasscodeInput.vue     # 6-digit PIN entry
│       ├── BranchGrid.vue        # Branch selection cards
│       ├── AreaGrid.vue          # Area selection cards
│       ├── TableGrid.vue         # Table selection grid
│       ├── CategoryTabs.vue      # Horizontal category scroller
│       ├── MenuItemCard.vue      # Single menu item card
│       ├── MenuItemDetailModal.vue # Item detail + quantity + note
│       ├── CartBar.vue           # Floating cart summary bar
│       ├── CartItem.vue          # Single cart item row
│       ├── OrderTrackingModal.vue # Full-screen order tracking overlay
│       ├── InvoiceRequestModal.vue # VAT invoice with tax code lookup
│       ├── StarRating.vue        # 5-star rating widget
│       └── FeedbackCriteria.vue  # Criteria chip selector
├── views/
│   └── customer/
│       ├── CustomerHome.vue      # PIN → Branch → Area → Table flow
│       ├── CustomerMenu.vue      # Menu browsing + add to cart
│       ├── CustomerCart.vue       # Cart review + submit order
│       ├── OrderHistory.vue      # Aggregated bill + payment request
│       ├── ServiceRequest.vue    # Service request panel
│       ├── FeedbackPopup.vue     # Post-payment feedback
│       └── SessionEnd.vue        # Session completed screen
└── router/
    └── index.ts                  # Customer routes under /customer
```

---

## 2. Implementation Phases

### Phase 0: Foundation & Type Safety ✅
**Goal:** Fix the broken build. Create missing files. Align types to DB schema.

**Tasks:**
- [x] **P0-1:** Create `src/utils/packageRules.ts` with these exports:
  ```typescript
  export function computeTotals(subtotalVnd: number): {
    serviceCharge: number; vat: number; total: number;
  }
  // serviceCharge = Math.round(subtotal * 0.05)
  // vat = Math.round((subtotal + serviceCharge) * 0.08)
  // total = subtotal + serviceCharge + vat
  
  export function isItemInPackage(
    menuItemId: string,
    packageDetails: PackageDetail[]
  ): boolean
  
  export function calculateChargeablePrice(
    basePrice: number,
    isInPackage: boolean
  ): number
  // Returns 0 if in package, basePrice otherwise
  
  export function applyPackage(
    item: MenuItem,
    isInPackage: boolean
  ): MenuItem
  // Returns a cloned item with price = 0 if in package
  ```
- [x] **P0-2:** Rewrite `src/types/customer.ts` to match DB schema:
  ```typescript
  // Key changes:
  // - CustomerSession → DiningSession (match dining_sessions table)
  // - Add: branchId, guestCount, serviceMode, languageCode
  // - Table → DiningTable (match dining_tables table)
  // - Add: SessionGuest interface (match session_guests table)
  // - CartItem.menuItemId → CartItem.branchMenuItemId
  // - Order fields use _vnd suffix for money (bigint)
  // - ServiceRequestType values match DB constraint
  // - Feedback.criteria → surveyData (jsonb)
  ```
  Keep backward compatibility by also exporting the old names as type aliases
  until all views are migrated.
- [x] **P0-3:** Verify the project builds: `npm run dev` succeeds with no
  TypeScript errors in the customer/ directory.

---

### Phase 1: Session Initialization Flow ✅
**Goal:** Staff unlocks tablet → selects branch/area/table → selects package
& guest count → creates dining session.

**Tasks:**
- [x] **P1-1:** Refactor `CustomerHome.vue` step flow:
  1. `passcode` — Staff enters 6-digit PIN
  2. `branch` — Select branch (skip if only 1 branch)
  3. `area` — Select area within branch
  4. `table` — Select available table (green = available, gray = occupied)
  5. `package` — **NEW STEP:** Select buffet package, enter adult count +
     child count. This step is critical because the DB requires `session_guests`
     rows. Show package cards with name + price. Allow different packages per
     guest type (adult vs child pricing).
  6. `confirm` — Review summary and confirm
- [x] **P1-2:** Add `PackageSelector.vue` component:
  - Fetches available packages from `branch_menu_items` where
    `item_type = 'buffet_package'`
  - Shows price per adult / per child
  - Inputs: number of adults, number of children
  - Emits: `{ packageId, adultCount, childCount }`
- [x] **P1-3:** Update `customerApi.ts` with RPCs:
  - `authenticateStaff(passcode)` → validates PIN against
    `staff_assignments.approval_pin_hash`
  - `getBranches()` → RPC or query `branches` where `is_active = true`
  - `getAreas(branchId)` → RPC for `areas` filtered by branch
  - `getTables(areaId)` → RPC for `dining_tables` with `availability_status`
  - `createDiningSession(params)` → **Atomic RPC** that:
    1. Inserts into `dining_sessions`
    2. Inserts into `session_tables`
    3. Inserts into `session_guests` (one row per guest)
    4. Returns the full session object
- [x] **P1-4:** Update `useCustomerSession.ts` to persist the new session
  shape (with `guestCount`, `serviceMode`, `packageId`).
- [x] **P1-5:** Session restore on page reload: if `localStorage` has a valid
  session, skip to `CustomerMenu` directly.

---

### Phase 2: Menu Browsing & Cart ✅
**Goal:** Customer browses menu, sees correct pricing (0đ for in-package items),
adds items to cart with notes.

**Tasks:**
- [x] **P2-1:** Refactor `CustomerMenu.vue` layout for landscape tablet:
  - **Left sidebar (25% width):** Category tabs (vertical list, scrollable)
  - **Center area (50% width):** Menu item grid (2-3 columns of cards)
  - **Right sidebar (25% width):** Live cart summary (always visible)
  - Floating service bell button (bottom-right)
- [x] **P2-2:** Implement package-aware pricing in the menu:
  - Load `package_details` for the guest's selected package
  - For each menu item, check if `menu_item_id` is in `package_details`
  - If yes: show "Trong gói" badge, price displays as "0đ"
  - If no: show regular price
  - Use `packageRules.ts` functions for this logic
- [x] **P2-3:** `MenuItemCard.vue` must show:
  - Item image (or placeholder emoji based on category)
  - Item name (use `item_name` from DB, or `local_name` from `branch_menu_items`)
  - Price badge: "0đ" with green "Trong gói" tag, OR formatted price in red
  - "Hết món" overlay if `availability_status = 'out_of_stock'`
  - +/- quantity buttons if item is already in cart
- [x] **P2-4:** `MenuItemDetailModal.vue`:
  - Full-screen overlay with item image, name, description
  - Quantity selector (min 1, max 10)
  - Note input (max 100 chars) with placeholder "Ghi chú cho bếp..."
  - "Thêm vào giỏ" button
- [x] **P2-5:** Cart state management in `customerStore`:
  - `addToCart(branchMenuItemId, item, quantity, note)` — if same item+note
    exists, increment quantity; otherwise add new row
  - `updateCartItemQuantity(branchMenuItemId, newQty)` — remove if 0
  - `updateCartItemNote(branchMenuItemId, note)`
  - `removeFromCart(branchMenuItemId)`
  - `clearCart()`
  - Persist cart to `localStorage` on every change (via watcher or explicit call)

---

### Phase 3: Cart Review & Order Submission ✅
**Goal:** Customer reviews cart, sees bill preview, submits order to kitchen.

**Tasks:**
- [x] **P3-1:** `CustomerCart.vue` layout (landscape):
  - **Left column (60%):** Cart items list with:
    - Select-all checkbox for bulk delete
    - Each item: checkbox, name, quantity adjuster (+/-), note (editable inline),
      unit price, line total
    - "Xóa đã chọn" button, "Xóa tất cả" button
  - **Right column (40%):** Bill summary card:
    - Total items count
    - Subtotal (sum of chargeable items only)
    - Service charge 5%
    - VAT 8%
    - Grand total (bold, red)
    - "Thêm món" button → back to menu
    - "Gửi món cho bếp" button → submit order
- [x] **P3-2:** Order submission flow:
  1. Validate: cart not empty, all items have valid `branchMenuItemId` (UUID)
  2. Show confirmation dialog (SweetAlert2)
  3. Call `customerApi.createOrder()` which triggers the atomic RPC:
     - Inserts into `orders` (source='tablet', status='submitted')
     - Inserts into `order_details` for each cart item:
       - `quantity` = actual count
       - `chargeable_quantity` = 0 if in-package, else = quantity
       - `unit_price_vnd_snapshot` = 0 if in-package, else base_price
       - `kitchen_status` = 'sent'
       - `note` = customer's note
     - Inserts a `print_job` row into `outbox_jobs` (atomic, same transaction)
  4. On success: clear cart, show success toast, navigate to Order Tracking
  5. On failure: show error toast, keep cart intact
- [x] **P3-3:** Persist submitted orders to `localStorage` (for history view).

---

### Phase 4: Order Tracking ✅
**Goal:** Customer sees real-time status of each dish they ordered.

**Tasks:**
- [x] **P4-1:** `OrderTrackingModal.vue` as a full-screen overlay:
  - **Header:** Table number, total items count
  - **Status summary cards:** 3 cards showing count of Pending/Preparing/Served
  - **Progress bar:** Overall % of items served
  - **Filter tabs:** All | Served | Preparing | Pending
  - **Items list:** Each item shows:
    - Name, quantity
    - Status badge (color-coded): Pending (gray) → Preparing (orange) → Served (green)
    - Timeline dots: Ordered → Preparing → Served
  - **Refresh button** to re-fetch from API
  - **Close button** to return to menu
- [x] **P4-2:** Status mapping (DB `kitchen_status` → UI label):
  | DB Value | UI Label (vi) | Color |
  |----------|--------------|-------|
  | `new` | Đã nhận | Gray |
  | `sent` | Đã gửi bếp | Blue |
  | `preparing` | Đang nấu | Orange |
  | `ready` | Sẵn sàng | Yellow |
  | `served` | Đã lên món | Green |
  | `cancelled` | Đã hủy | Red |
- [x] **P4-3:** Real-time updates (optional, for Supabase live mode):
  - Subscribe to `order_details` changes via Supabase Realtime channel
  - On `kitchen_status` change → update the item in the local store
  - Show toast notification: "Món [X] đã sẵn sàng!"

---

### Phase 5: Order History & Bill ✅
**Goal:** Customer sees aggregated bill across all orders, can request payment
and VAT invoice.

**Tasks:**
- [x] **P5-1:** `OrderHistory.vue` layout:
  - **Left column (60%):** Aggregated item list (merge all orders into flat list,
    sum quantities for identical items)
  - **Right column (40%):** Bill summary:
    - Subtotal, Service charge 5%, VAT 8%, Discount, Grand total
    - Info box: "Nhân viên sẽ đến bàn xác nhận thanh toán"
    - "Yêu cầu hóa đơn VAT" button → opens `InvoiceRequestModal`
    - "Yêu cầu thanh toán" button → calls RPC to change session status to
      `checkout_requested`, disables further ordering
- [x] **P5-2:** Payment request flow:
  1. Confirmation dialog
  2. Call RPC to update `dining_sessions.status` → `'checkout_requested'`
  3. Disable the "Gửi món" button across the app
  4. Show "Đang chờ thanh toán" badge
- [x] **P5-3:** VAT Invoice (`InvoiceRequestModal.vue`):
  - Input: Mã số thuế (Tax Code)
  - "Tra cứu" button → calls `https://api.vietqr.io/v2/business/{taxCode}`
  - Auto-fills: Company name, Address (readonly fields)
  - Input: Email kế toán (required)
  - Submit → stores in `service_requests` or a dedicated outbox job
  - Validation: taxCode required, company name must be auto-filled (not empty),
    email must contain @

---

### Phase 6: Service Requests ✅
**Goal:** Customer can call staff for various needs without raising their hand.

**Tasks:**
- [x] **P6-1:** `ServiceRequest.vue`:
  - Grid of request buttons (3 columns for landscape):
    | UI Label | Icon | DB `request_type` |
    |----------|------|-------------------|
    | Gọi nhân viên | 🙋 | `call_staff` |
    | Thêm than | 🔥 | `add_charcoal` |
    | Lấy nước | 💧 | `water` |
    | Tính tiền | 💰 | `checkout` |
    | Yêu cầu khác | ✏️ | `other` |
  - For "other": show text input for custom note
  - Active requests list at bottom with status badge and cancel button
- [x] **P6-2:** API mapping — the `customerApi.submitServiceRequest()` must
  translate between UI request types and DB constraint values.
- [x] **P6-3:** The floating bell button on `CustomerMenu.vue` should show a
  badge with count of active (non-completed) requests.

---

### Phase 7: Feedback & Session End ✅
**Goal:** After payment, customer rates experience and optionally provides
contact info.

**Tasks:**
- [x] **P7-1:** `FeedbackPopup.vue`:
  - Star rating (1-5) using `StarRating.vue`
  - Criteria chips (using `FeedbackCriteria.vue`): service_time, food_quality,
    hygiene, ambiance, staff_attitude, value_for_money
  - Comment textarea
  - Customer name input (optional)
  - Customer phone input (optional)
  - Submit button (disabled until rating ≥ 1 AND at least 1 criterion selected)
  - Skip button
- [x] **P7-2:** On submit, call RPC that:
  - Creates/finds `customers` record if phone provided
  - Inserts into `customer_feedbacks`:
    - `rating` = star value
    - `survey_data` = `{ criteria: [...], customerName, customerPhone }`
    - `customer_id` = found/created customer UUID (or null)
- [x] **P7-3:** After feedback (submit or skip):
  - Show `SessionEnd.vue` with:
    - "Cảm ơn quý khách!" message
    - QR code linking to Google Maps Review
    - Auto-redirect to `CustomerHome` after 30 seconds
    - "Kết thúc" button for immediate redirect
  - Clear all `localStorage` session data
  - Reset Pinia store

---

### Phase 8: Localization & Polish ✅
**Goal:** App supports EN/JA/VI and looks great on a tablet in landscape mode.

**Tasks:**
- [x] **P8-1:** Audit every component — replace ALL hardcoded Vietnamese strings
  with `$t('key')` or `t('key')` calls. No exceptions.
- [x] **P8-2:** Ensure `vi.json`, `en.json`, `ja.json` all have complete
  `customer.*` key coverage.
- [x] **P8-3:** Language switcher in `CustomerMenu.vue` header: vi | en | ja
  flags. Switching language updates `dining_sessions.language_code` via RPC.
  - [ ] No hover-only interactions (tablet has no hover)

---

## 3. RPC Contract Reference

These are the Supabase RPCs the Customer UI needs. Some already exist in the
schema; others need to be created.

| RPC Name | Exists? | Purpose | Key Params |
|----------|---------|---------|-----------|
| `customer_authenticate_pin` | ❌ Create | Validate staff PIN | `p_branch_id`, `p_pin` |
| `customer_list_branches` | ❌ Create | List active branches | (none) |
| `customer_list_areas` | ❌ Create | List areas for branch | `p_branch_id` |
| `customer_list_tables` | ❌ Create | List tables with status | `p_branch_id`, `p_area_id` |
| `customer_list_packages` | ❌ Create | List buffet packages with price | `p_branch_id` |
| `customer_create_session` | ❌ Create | Atomic: session + guests + table link | `p_branch_id`, `p_table_id`, `p_package_id`, `p_adult_count`, `p_child_count`, `p_opened_by` |
| `customer_list_menu_items` | ❌ Create | Menu items with package inclusion info | `p_branch_id`, `p_package_menu_item_id` |
| `customer_create_self_service_order` | ❌ Create | Atomic: order + details + print job | `p_session_id`, `p_items` (jsonb array) |
| `customer_get_order_status` | ❌ Create | Order details with kitchen_status | `p_session_id` |
| `customer_request_checkout` | ❌ Create | Set session status to checkout_requested | `p_session_id` |
| `customer_submit_service_request` | ❌ Create | Insert service_request | `p_session_id`, `p_type`, `p_note` |
| `customer_cancel_service_request` | ❌ Create | Cancel pending request | `p_request_id` |
| `customer_submit_feedback` | ❌ Create | Insert feedback + optional customer | `p_session_id`, `p_rating`, `p_survey_data`, `p_customer_name`, `p_customer_phone` |
| `customer_request_vat_invoice` | ❌ Create | Store VAT invoice request | `p_session_id`, `p_tax_code`, `p_company_name`, `p_address`, `p_email` |

> [!WARNING]
> These RPCs do NOT exist yet in the schema. For now, implement them as mock
> functions in `customerApi.ts`. When the backend team creates them, simply
> replace the mock implementation with `supabase.rpc()` calls.

---

## 4. Mock Data Strategy

When `isSupabaseConfigured === false`, the API layer must return realistic mock
data. Use existing files:

- `src/data/mockMenuData.ts` — menu categories and items
- `src/data/customerAreaData.ts` — areas and tables
- `src/data/mockCartData.ts` — sample cart items

For mock mode, generate UUIDs using `crypto.randomUUID()` so that UUID
validation in the store doesn't reject mock items.

---

## 5. Quality Checklist (Run Before Marking Phase Complete)

For EACH phase, verify:
- [ ] `npm run dev` starts without errors
- [ ] No TypeScript errors in `src/views/customer/` and `src/components/customer/`
- [ ] All text strings use `$t()` i18n function
- [ ] Layout looks correct at 1280×800 landscape
- [ ] Touch interactions work (no hover-only elements)
- [ ] localStorage persistence works across page reload
- [ ] Mock mode returns sensible data
- [ ] No console errors in browser

---

## 6. Progress Tracker

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| Phase 0: Foundation | ✅ Complete | 2026-07-25 | Verified build and types |
| Phase 1: Session Init | ✅ Complete | 2026-07-25 | Built PackageSelector, updated APIs and session shape |
| Phase 2: Menu & Cart | ✅ Complete | 2026-07-25 | 3-column layout, package-aware pricing |
| Phase 3: Cart Review | ✅ Complete | 2026-07-25 | Order validation and submission flow |
| Phase 4: Order Tracking | ✅ Complete | 2026-07-25 | Tracking modal, UI status mapping, mock API |
| Phase 5: Bill & Payment | ✅ Complete | 2026-07-25 | Aggregated list, checkout logic, VAT invoice |
| Phase 6: Service Requests | ✅ Complete | 2026-07-25 | Call staff buttons, custom notes, bell badge |
| Phase 7: Feedback | ✅ Complete | 2026-07-25 | Ratings, criteria, survey JSON, session clearing |
| Phase 8: Localization | ✅ Complete | 2026-07-25 | Complete `$t` coverage, UI polish, touch targets |

---

*Last updated: 2026-07-25 by Per (Project Lead)*
