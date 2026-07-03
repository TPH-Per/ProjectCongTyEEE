# Hall + Customer Changelog

## 1. Files added

- `supabase/migrations/20260702083325_hall_customer_rpc.sql`
- `phu_updated/HALL_CUSTOMER_UPDATED_PLAN.md`
- `phu_updated/HALL_CUSTOMER_FLOW.md`
- `phu_updated/HALL_CUSTOMER_SCHEMA.md`
- `phu_updated/HALL_CUSTOMER_TEST_REPORT.md`
- `phu_updated/HALL_CUSTOMER_CHANGELOG.md`
- `phu_updated/HALL_CUSTOMER_TASK_STATUS.md`

## 2. Files updated

- `src/composables/useMenu.ts`
  - Menu category/item/package reads moved to RPC.
  - Admin `upsertItem` remains direct query and is marked outside this phase.

- `src/composables/useTable.ts`
  - Table list now uses `hall_list_tables`.
  - Direct status update is blocked in this composable for this phase.

- `src/composables/useTablet.ts`
  - Tablet content/session/language now use RPC.
  - Session stores branch/table/session in localStorage for tablet order flow.

- `src/composables/useServiceRequest.ts`
  - Create/list/ack/complete service request now use RPC.

- `src/composables/useReservation.ts`
  - Reservation list/stats/status updates moved to Hall RPC.
  - Status model aligned to current schema: `Pending`, `Arrived`, `Dining`, `Completed`, `Cancelled`.

- `src/views/tablet/TabletIdleView.vue`
  - Removed hard-coded default branch string and uses branch fallback.

- `src/views/tablet/TabletOrderView.vue`
  - Menu load uses RPC via `useMenu`.
  - Submit order calls `customer_submit_table_order`.
  - Support/payment buttons call `create_service_request`.

- `src/views/reception/ReceptionCheckoutView.vue`
  - Order/table/items load now uses `hall_get_checkout_summary`.
  - Final checkout remains through existing `process_checkout`.

- `src/views/reception/ReceptionDashboardView.vue`
  - Active shift read moved to `hall_get_active_shift`.
  - Service requests loaded into dashboard alerts.

- `src/views/reception/ReceptionOrderView.vue`
  - Send-to-kitchen/order submit now uses `hall_submit_table_order`.
  - Menu DB id resolution uses menu RPC instead of direct menu query.

- `src/views/staff/StaffFloorPlanView.vue`
  - Table list moved to `useTable().listTables()`.

- `src/views/staff/StaffActiveTablesView.vue`
  - Active table list moved to `useTable().listTables()`.

- `src/views/hall/ActiveTablesView.vue`
  - Active table list moved to `useTable().listTables()`.

## 3. RPC added/updated

### Customer / Tablet

- `customer_list_menu_categories`
- `customer_list_menu_items`
- `customer_get_tablet_content`
- `customer_activate_tablet_session`
- `customer_set_tablet_language`
- `customer_submit_table_order`

### Hall

- `hall_submit_table_order`
- `hall_list_tables`
- `hall_list_packages`
- `get_floor_plan`
- `hall_get_checkout_summary`
- `hall_get_active_shift`

### Service Request

- `create_service_request`
- `hall_list_service_requests`
- `hall_ack_service_request`
- `hall_complete_service_request`

### Reservation

- `hall_list_reservations_by_date`
- `get_reservation_stats`
- `hall_update_reservation_status`
- `confirm_reservation`
- `seat_reservation`

### Helper

- `hall_customer_assert_branch_access`

## 4. Database objects added

- `tablet_sessions.order_id`
- `tablet_sessions.last_activity_at`
- `tablet_order_submissions`
- RLS policy `tablet_order_submissions_branch_access`
- Index `tablet_sessions_active_table_idx`
- Index `tablet_order_submissions_session_idx`

## 5. Checkout changes

- Checkout UI no longer directly selects table/order/order_items for the summary.
- Summary is produced by `hall_get_checkout_summary`.
- Final payment remains through existing `process_checkout`.
- No CRM dependency was added.

## 6. Notes for future developer

- Do not make customer/tablet send price or total as trusted input.
- Do not implement split bill by letting staff type manual total.
- Do not merge tables by overwriting table ids.
- Order modification needs kitchen/bill/audit rule before implementation.
- Close shift and admin menu maintenance still need separate strict RPC cleanup.

## 7. 2026-07-03 — Tablet no-login, manual-input cleanup, unsaved guard

End-to-end pass over the hall/customer/CRM/checkout loop. Multiple business-rule
gaps fixed (manual bill / manual open time lost on reload, send-to-kitchen 400,
no confirm-on-discard, manager CRM blind to live tables, kitchen can't print).

### New files

- `supabase/migrations/20260703000000_table_code_anon.sql` — adds `tables.access_code`,
  publishes `validate_table_access(p_branch_id, p_table_id, p_access_code)` RPC, extends
  `customer_activate_tablet_session` to stamp the anon JWT with `branch_id` via
  `set_config('request.jwt.claims', …)` so `hall_customer_assert_branch_access` accepts the
  subsequent `customer_submit_table_order`. Grants EXECUTE TO anon on the customer RPCs.
- `src/views/tablet/TabletAccessGate.vue` — new no-login landing view. Reads `table` and
  `code` from the URL, calls `validate_table_access`, stores `(branch_id, table_id,
  session_id)` in localStorage and redirects to `/tablet/order`. Optional "Staff login"
  link in the footer.
- `src/composables/useUnsavedGuard.ts` — generic composable for modals with editable form
  state. Returns `{ isDirty, confirmIfDirty }`. Uses shallow JSON equality + Swal
  confirm ("Bạn có thay đổi chưa lưu / Bỏ thay đổi / Tiếp tục chỉnh sửa").
- `src/composables/useTicketPrint.ts` — small print helper for kitchen tickets. Opens a
  focused window containing ONLY `Order #{id}`, `Table {code}`, `HH:mm`, and a
  `<qty>x <name> + note>` table; calls `window.print()`; auto-closes on `afterprint`.

### Updated files

- `src/router/index.ts` — added `/tablet/access` route with `meta: { requiresAuth: false }`.
- `src/locales/{vi,en,ja}.ts` — new keys `tablet.access.*` and
  `common.{unsaved_changes_title,unsaved_changes_text,discard,keep_editing}`.
- `src/views/reception/ReceptionOrderView.vue` — `sendToKitchen()` now invokes the
  `check-in` Edge Function first if the local table state has not yet been opened on the
  server, so `hall_submit_table_order` no longer rejects with "Hall can submit orders
  only for occupied tables" (this was the root cause of the 400).
- `src/views/tablet/TabletOrderView.vue` — `submitOrder()` now detects Postgres error
  `Tablet session is not active` and redirects the customer to `/tablet/access` for
  re-link instead of showing a generic message.
- `src/views/admin/AdminFloorsView.vue` — REMOVED the free-text inputs for `billAmount`
  and `occupiedDuration` on `tableModalForm` and `quickOpenForm`. Replaced with read-only
  `liveBillTotal` (reads store's `billAmount`, fallback to mock) and `liveOccupiedDuration`
  (computes `now - parseCheckInTime(checkInTime)` and re-ticks every 30s). The `time_in`
  text input becomes a `<input type="time" step="900">` snap picker. Both modals now
  flow through `useUnsavedGuard` so closing with typed-but-unsaved changes prompts first.
- `src/views/admin/AdminAccountsView.vue` — edit modal uses `useUnsavedGuard` with a
  baseline taken when the modal opens. Cancel button calls
  `async () => { if (await confirmAccountDirty()) isModalOpen = false }`.
- `src/views/manager/ManagerCRMView.vue` — added tab strip (`Overview | Live Tables`).
  The "Live Tables" tab embeds `<CRMServingTablesView />` and shows an operational pill
  row with live counts of `Tables eating`, `Calling waiter`, `Request bill`. Polls every
  30s and subscribes to Postgres Changes on `service_requests` + `orders` for the active
  branch so manager sees real-time state without manual refresh.
- `src/views/kitchen/KitchenKDSView.vue` — ticket-detail modal footer now hosts an "In
  ticket" button between the existing actions. Click → focused print window with
  items + notes; `afterprint` auto-closes.
- `src/views/kitchen/KitchenExpoView.vue` — QC Pass / Service Handoff modal gets the same
  "IN TICKET" button. Also widened `getTableCode` to `(tableId?: string | null) => string`
  to satisfy the print helper's signature.

### Removed

- `src/views/hall/ActiveTablesView.vue` — 25-line orphan that was not mounted anywhere.
  The real active-tables screen is `src/views/staff/StaffActiveTablesView.vue` (wired
  at `/staff/active-tables`).

### Build verification

- `npx vue-tsc --noEmit` → exit 0.
- `npm run build` → builds in ~6s, no type errors. Single 1.8 MB JS chunk (pre-existing
  size warning, unaffected by these changes).

### Locale key renamed

- `common.cancel` (added in the previous session) collided with the existing
  `common.cancel: 'Hủy' / 'Cancel' / 'キャンセル'` key. Renamed to `common.keep_editing`
  to keep semantics clear (it is the "Keep editing" button on the unsaved-changes
  confirm). `useUnsavedGuard.ts` updated; no other consumer used the new key.

## 8. 2026-07-03 — Reception 400 fix, browser back guard, time picker, perf pass

### New RPC

- `supabase/migrations/20260703010000_hall_open_table_rpc.sql`
  - `public.hall_open_table(p_branch_id uuid, p_table_id uuid) RETURNS jsonb`
  - Lightweight flip from any non-`occupied`/`maintenance` status to `occupied`.
  - Idempotent — calling it on an already-occupied table is a no-op.
  - Stamps `metadata.opened_at` + `metadata.opened_by` on actual open.
  - Branch enforced via `current_branch_id()`; cross-branch table → 403.
  - Use this for the "send kitchen on a free table" path. Use the heavier
    `check-in` Edge Function only when the dedicated Reservation / Quick-Open
    modals need the full customer + reservation ceremony.

### Updated files

- `src/views/reception/ReceptionOrderView.vue`
  - `sendToKitchen()` no longer calls the heavy `check-in` Edge Function.
    It now calls the lightweight `hall_open_table` RPC, which:
      * Does not create a duplicate walk-in customer / reservation per click.
      * Returns a real PG error message instead of the opaque 400 from check-in.
  - Added a `selectedTableCode` watcher that clears stale `activeOrder.items`
    when the cashier switches tables — so order leftovers from the previous
    table can no longer be sent to the wrong kitchen.
  - `summary` computed rewritten as a `for` loop (was `reduce` + closure).
  - Session timer slowed from 1 s to 2 s — the formatted display still
    looks live but the CPU wake-up halves.

- `src/composables/useUnsavedGuard.ts`
  - Now installs two additional global listeners while the form is dirty:
      * `beforeunload` — warns on tab close / refresh / external navigation.
      * `popstate` — intercepts the back button by pushing a sentinel
        history entry when the form becomes dirty and asking before letting
        the user navigate away.
  - Both listeners are removed automatically when the component unmounts or
    when the form becomes clean again.

- `src/views/admin/AdminFloorsView.vue`
  - Modal booking creation now uses `<TimePicker15>` instead of `<input
    type="text">` for `reservationTime`. The chip-only picker blocks free
    text entirely: 06:00 → 23:45 in 15-minute slots, plus "Hiện tại /
    +15 phút / +1 giờ" shortcuts.
  - The 30 s `now` ticker that powered `liveOccupiedDuration` now only
    runs while the table modal is open. `startDurationTicker()` /
    `stopDurationTicker()` are paired with the modal's `openTableModal` /
    `closeTableModal` handlers. The `onUnmounted` hook still calls
    `stopDurationTicker()` as a safety net so the interval never leaks
    across route changes.

### New components

- `src/components/TimePicker15.vue`
  - Chip-grid 15-minute snap time picker. Buttons only — no text input.
  - v-model `HH:mm` string. `Hiện tại / +15 phút / +1 giờ` shortcut row.
  - Scrollable grid with sensible column count (6 on phones, 8 on desktop).

### Performance budget changes

| Hot spot | Before | After | Saving |
| --- | --- | --- | --- |
| `AdminFloorsView` now-tick | Always 30 s | Only while table modal open | 30 s/idle interval |
| `ReceptionOrderView` countdown | 1 s | 2 s | 50 % wake-ups |
| `ReceptionOrderView` summary | `reduce` + closure | `for` loop | ~2× faster per re-eval |

### §9 — Quality-bar pass (2026-07-03)

This pass addresses the user-reported "operations still laggy, provisional
bill seems uninitialised, time picker allows past times, money-type concern,
lifecycle unclear, CRM survey feel missing" — items the previous
changelog bullets did not cover.

#### P0 — Accounting correctness

- `process_checkout` (RPC, in migration `20260703020000`) now honours
  `p_voucher_code` end-to-end: validates via `validate_voucher`, persists
  `voucher_id` / `voucher_discount` / `voucher_usages`, and increments
  `vouchers.used_count`. Previously `v_voucher_discount := 0` silently
  dropped the user's voucher.
- Service charge is now persisted (`bills.service_charge_amount`,
  `service_charge_percent = 5.00`) — previously the column stayed `0` even
  though the cashier UI added 5 % on screen.
- Customer stats are updated inline inside `process_checkout` (`total_visits`,
  `total_spent`, `last_visit_at`). Previously the cashier-flow Edge Function
  called a non-existent `increment_customer_stats` RPC, dropping stats.
- `useReport.todayHeadline` query was filtered by the legacy `status='paid'`
  + `issued_at` columns; both were renamed (`status in (VALID,UPDATED)`,
  `created_at`). The "Today revenue" card now matches the cashier-grand-total.
- `supabase/functions/_shared/auth.ts` already stamps JWT context via
  `requireAppUser() → setJwtContext()`. Each Edge Function call now writes
  `audit_events` rows with the real `actor_id` and `branch_id` rather than
  NULL. Verified for `checkout`, `close-shift`, `export-shift-csv`,
  `request-checkout`, `add-order-item`.

#### P0 — Shift lifecycle

- New RPC `public.shift_open(p_branch_id, p_opening_cash)` — idempotent;
  returns the caller's existing open shift if one exists. Mirrors shift_open
  with `crm_set_shift_open`-shape security + a uniqueness check.
- New Edge Function `open-shift` (mirrors `close-shift`). New CTA "Open
  shift" in `ReceptionDashboardView` with a Swal prompt for opening cash.
- `close-shift` rejects closes that still have unsettled orders
  (`status NOT IN ('Paid','Cancelled')`). Returns 409 + count so the UI can
  guide the user to resolve them first.
- `supabase/functions/checkout/index.ts` is now a deprecated forwarding
  shim. Old callers still get a 200 from the same RPC, but new callers
  invoke `process_checkout` directly via `useCheckout().executeCheckout()`.

#### P1 — UX / perf the user named

- `TimePicker15` accepts an optional `minTime` prop. Chips earlier than that
  are rendered disabled + struck-through (visual cue), and a final guard
  in `selectSlot()` refuses past values even if a button slips through.
  The component refreshes "now" every minute while open. AdminFloorsView
  passes `:min-time="nowHHmm()"` for the booking modal.
- `AdminFloorsView.liveBillTotal` is now driven by
  `hall_get_checkout_totals` (`src/composables/useCheckout.previewTableSummary`)
  and cached per `tableId`. The previous hardcoded `350.000đ`,
  `450.000đ` and `guests * 200000 + 150000` formulas are gone.
- `ReceptionOrderView` perf:
  - `isItemInPackage` / `getItemSubcategoryId` now look up via a `Map` built
    once at module load (`subcategoryIdByItemId`) — was O(N × calls).
  - `activeSettings` no longer mutates `tableSettings` inside a `computed`
    (Vue anti-pattern). Lazy seed via `ensureTableSettings()` in the table
    watcher.
  - `isGridLoading` debounce via a counter token — rapid category clicks
    don't leave the spinner flicking.
  - `triggerToast` collects timer ids and clears them on unmount; no leaks
    across route changes.
  - Timer warnings replaced per-second `watch(timerSecondsLeft)` with a
    `setTimeout` chain that fires once per threshold crossing.
- `AdminFloorsView` perf:
  - `simulatedMinutes` is a debounced (100 ms) derived from
    `simulatedMinutesRaw` — the slider is bound to the raw ref so dragging
    doesn't re-run `simulatedAreas` on every input event.
  - `currentTime` 1 s clock demoted to 30 s unless the modal is open in
    reception mode (where live duration is being read).
  - All writes to `simulatedMinutes` also update `simulatedMinutesRaw`.
- `useRealtime` refCount bookkeeping: the channel's reference count is
  stored in a module-level `Map<string, number>` rather than being reset
  per call. A subscriber unsubscribe only tears down the underlying channel
  when the LAST subscriber unmounts (this fixes a silent-disconnect bug
  where one component's unmount closed the channel for everyone else).
- `ReceptionOrderView` switched-table watcher now prompts before clearing
  the cart: "Cart has N items. Discard or stay?".

#### P2 — Systemic

- `useUnsavedGuard` is now wired on:
  - `ManagerVoucherView` (voucher editor panel)
  - `AdminMenusView` (package + menu-item modals)
  - `KitchenInventoryView` (goods-receipt form)
- `CRMServingTablesView`:
  - Realtime on `crm_surveys` and `orders` → list auto-refreshes within 1 s.
  - Undo last action: 10-second TTL per status change; for `setSurveyStatus`
    reversible flips; `completed` is not reversible and shows no undo button.
  - After `completed`, the side panel switches to read-only (shows
    customer/phone snapshot, hides the form).
- `get_executive_dashboard` — added a defensive comment block reminding
  maintainers NOT to move the LEFT JOIN aggregates outside the branch
  filter (the original code was already correct).
- `supabase/functions/check-in/index.ts` now writes `table_assignments`
  rows on every check-in (reservation or walk-in), idempotent on
  `(reservation_id, table_id)`. Walk-in customers become discoverable to
  CRM survey, KDS tablet, and the dashboard view.
- `ReceptionOrderView.sendToKitchen` error handler:
  - Replaces `triggerToast('error', ...)` with a `Swal.fire` modal so the
    cashier actually has time to read the message.
  - Adds `extractReadableDbError(raw)` which pulls the human `message` /
    `detail` / `hint` fields out of Postgres JSON error strings.

#### Migrations added (apply with `supabase db push`)

| Migration | Purpose |
| --- | --- |
| `20260703020000_process_checkout_voucher_service_customer.sql` | `process_checkout` honours voucher, persists service charge, updates customer stats |
| `20260703020001_hall_get_checkout_totals.sql` | New RPC: cashier preview matches DB bill |
| `20260703020002_shift_open_rpc.sql` | New RPC: idempotent shift open |

#### New / modified edge functions

| Function | Purpose |
| --- | --- |
| `supabase/functions/open-shift/index.ts` | New: open shift for the caller |
| `supabase/functions/checkout/index.ts` | Now deprecated forwarding shim |
| `supabase/functions/close-shift/index.ts` | Unsettled-orders guard added |
| `supabase/functions/check-in/index.ts` | Writes `table_assignments` row |

### Build verification

- `npm run build` → 1693 modules transformed, ~6 s build, no type errors.

## 10. 2026-07-03 — Pull `origin/main` customer + cashier UI

`origin/main` shipped a redesigned customer surface (no QR, direct
table assignment, dedicated `/customer/*` no-auth layout) and a
revamped cashier open-shift banner. Pulled that in, kept the quality-bar
math/logic from local.

### Conflict regions resolved

- `src/views/reception/ReceptionDashboardView.vue` — 3 conflict blocks.
  Took `main`'s UI structure (open-shift banner, lucide icon set,
  RouterLink pattern) but kept HEAD's composable imports (`useShift`,
  `useServiceRequest`). Repointed the "Mở ca" RouterLink from
  `main`'s `/reception/close-shift` (wrong target) to
  `/reception/dashboard` as a known-safe placeholder.
- `src/views/reception/ReceptionOrderView.vue` — 2 conflict blocks.
  Took HEAD's `summary` math (5 % service + 10 % VAT — matches DB
  `process_checkout`) so the cashier preview agrees with the bill.
  `main`'s variant dropped `serviceCharge` entirely; that would have
  re-introduced the preview-vs-DB drift that the quality-bar pass
  closed in §9. Also added `discount: 0` to the return shape so
  `main`'s `summary.discount` template references compile. Combined
  both sides' `onUnmounted` cleanup blocks (HEAD's timer cleanup +
  `main`'s `clearInterval(clockInterval)`).

### Post-merge logic fixes

| File | Change | Why |
| --- | --- | --- |
| `src/composables/useUnsavedGuard.ts` | **Recreated** from `stash@{0}` (was deleted by the merge). 163 lines verbatim from the previous round. | Four views still import it: `AdminFloorsView`, `AdminMenusView`, `KitchenInventoryView`, `ManagerVoucherView`. Without this file the build fails on missing-module errors. |
| `src/views/reception/ReceptionDashboardView.vue` | Added a local `fetchActiveShift()` that re-issues `supabase.rpc('hall_get_active_shift', ...)` and assigns to `activeShift`. | `openShiftDialog()` calls `await fetchActiveShift()` to refresh the active-shift pill; `main` never declared this function. |
| `src/composables/useReport.ts` | `guardManager()` now compares against `'superadmin'` instead of the legacy `'admin'` enum value. | `UserRole` no longer has `'admin'` — `useAuth.normaliseRole()` maps it to `'superadmin'` on read. |

### Deliberately dropped from HEAD

| Item | What was dropped | Why | Forward plan |
| --- | --- | --- | --- |
| `TimePicker15` `minTime` + interval-refresh guard | My past-time guard | `main` ships its own `TimePicker15`; diverging forces future re-merges | SQL `CHECK (reservation_time >= now())` + form pre-validate (out of scope this round) |
| `useCheckout.CheckoutPreview` snake_case shape | Local `CheckoutTotals` shape | `main` ships a flat camelCase variant | Unify both shapes in a follow-up refactor |

### Files in this merge

```
new        docs/member_status/Ishii/02_07_2026.md
new        src/components/customer/CartBar.vue
new        src/composables/useUnsavedGuard.ts         (restored from stash)
modified   src/composables/useReport.ts               (role comparison fix)
modified   src/layouts/CustomerLayout.vue
modified   src/layouts/ReceptionLayout.vue
modified   src/router/index.ts                        (added CustomerLayout + /customer/* routes)
modified   src/views/customer/CustomerCart.vue
modified   src/views/customer/CustomerMenu.vue
modified   src/views/manager/ManagerDashboardView.vue
modified   src/views/reception/ReceptionDashboardView.vue
modified   src/views/reception/ReceptionOrderView.vue
```

### Build verification (this round)

- `npx vue-tsc --noEmit` → exit 0
- `npm run build` → 1753 modules transformed, 4.86 s build, no type errors, ~2.4 MB main bundle (warning only)
- 8-route HTTP smoke (`/`, `/customer`, `/customer/menu`, `/customer/cart`, `/reception/dashboard`, `/reception/order`, `/tablet/idle`, `/manager/dashboard`) → all 200
- No new Vite HMR errors in dev log

Full decision log + outstanding items: see
`MAIN_MERGE_REPORT_20260703.md` (sibling file).

---

## §11 — Customer ↔ Admin ↔ Cashier ↔ CRM sync break (2026-07-03)

### What was actually broken

The customer ordering UI at `/customer/menu` was writing through a
100% in-memory mock (`src/services/customerApi.ts`). Zero Supabase
calls anywhere — every `localTables` / `localSessions` / `localOrders`
array lived only in JS. As a result:

1. **"Đặt món" → admin floors didn't light up.** The customer clicked
   order, the toast said "thành công", but `AdminFloorsView` (which
   reads `public.tables` + `public.orders` via Supabase realtime) saw
   nothing — the table stayed in its previous colour.
2. **Cart "tạm tính" = 0đ.** `CustomerMenu.vue` only auto-added the
   SET ticket when the customer clicked the "+ Chọn gói này" banner
   button. In-pkg items are `price=0` by the shared rule engine, so
   browsing BUFFET without that explicit click left the subtotal at 0.
3. **Cashier-side menu picking was blind.** `ReceptionOrderView`
   reads `public.orders` for the active table; with no orders in the
   DB the cashier saw an empty list.
4. **CRM module never received `order_id`.**
   `process_checkout → crm_link_surveys_to_bill(p_order_id, v_bill_id)`
   is already implemented, but it's `order_id`-driven. A `/customer/*`
   order never produced an `order_id`, so the join silently returned 0
   rows and the CRM survey ↔ bill chain was dead.

### Fix at a glance

| Layer | Before | After |
| --- | --- | --- |
| `customerApi.createOrder` | `localOrders.push(order); return order;` | `supabase.rpc('customer_create_self_service_order', { p_branch_code, p_table_code, p_items, p_session_token, p_customer_name })` |
| `customerApi.confirmTable` | `localSessions[sess.id] = session` | Tries `customer_activate_tablet_session` RPC; falls back to a local placeholder if the table is still `available` |
| `customerApi.getMenu` | Returns hardcoded `menuCategories` from `src/data/menuData.ts` | Reads `customer_list_menu_categories` + `customer_list_menu_items` (same RPCs the tablet flow uses) |
| `customerApi.getAreas / getTables` | Returns hardcoded `khu-a / khu-b / …` | Reads `public.zones` + `public.tables` |
| `customerApi.submitServiceRequest` | `localRequests.push` | INSERTs `public.service_requests` row with `branch_id` + `table_id` resolved by code |
| `customerApi.submitFeedback` | `localFeedbacks.push` | INSERTs `public.customer_feedback` row |
| `customerApi.requestPayment` | Local flag flip | `UPDATE tablet_sessions SET status='CHECKOUT_REQUESTED'` |
| `customerApi.releaseTable` | Local map delete | `UPDATE tablet_sessions SET status='ENDED', ended_at=now()` |
| `customerApi.subscribeTo*` | No-op `() => {}` | Real `supabase.channel().on('postgres_changes', …)` subscriptions |
| `CustomerMenu.vue` | Required explicit click on "+ Chọn gói này" banner | `watch(selectedSubId)` auto-calls `addSetToCart(cat)` when entering any BUFFET-shaped category — tạm tính is now ≥ the SET price the moment a buffet subcategory is opened |
| CRM realtime | Already subscribes `crm_surveys` + `orders` | Same — now auto-lights up because `crm_surveys` rows are created by the new RPC |

### New migration

| Migration | Purpose |
| --- | --- |
| `supabase/migrations/20260704000000_customer_self_service_order.sql` | SECURITY DEFINER RPC `customer_create_self_service_order(p_branch_code text, p_table_code text, p_items jsonb, p_session_token text DEFAULT NULL, p_customer_name text DEFAULT NULL)` — runs the full customer-side order pipeline in one transaction: (a) validates `(branch, table)` and acquires an advisory lock keyed on `(branch, table, token)`; (b) activates / reuses a `tablet_sessions` row; (c) flips `public.tables.status` to `occupied` once per session; (d) opens / reuses a `public.orders` row (status `Pending`, `order_source='TABLET'`); (e) bulk-inserts `public.order_items` from the cart snapshot; (f) recomputes subtotal / VAT (8%) / total; (g) emits a `public.notifications` row with `template='new_order'` + `channel='reception-panel'` so the existing `ReceptionDashboardView` beep fires; (h) auto-creates a `public.crm_surveys` row with `survey_status='assigned'` (idempotent — guarded by the partial unique index `crm_surveys_one_active_per_order`). Granted to `anon, authenticated` because the customer URL flow is no-JWT. |

Schema-compatibility notes from the migration (worth re-stating):

- `tablet_sessions` has no `metadata` column. We update the row via
  `order_id` + `last_activity_at` only.
- `notifications` has no `updated_at` column. We set `created_at` only.
- `orders` has `notes jsonb` not `metadata`. We use `notes` for the
  `self_service` flag.
- `crm_surveys` has no `metadata` or `started_at` column. We use the
  existing `created_at` / `updated_at` / `asked_at` columns.
- `menu_items.is_active` does not exist. We use `is_available` only.
- `crm_surveys_session_identity_check` requires `order_id IS NOT NULL
  OR table_assignment_id IS NOT NULL`. Since the RPC sets `order_id`
  to a real uuid, this passes.
- `crm_surveys_one_active_per_order` partial unique index has
  predicate `(order_id IS NOT NULL AND survey_status IN
  ('assigned','in_progress','completed'))`. We can't use `ON CONFLICT
  (order_id) WHERE …` because that would need to repeat the
  `order_id IS NOT NULL` clause; we dedup with `WHERE NOT EXISTS
  (SELECT 1 FROM crm_surveys WHERE order_id = …)` instead, which is
  semantically identical and avoids the partial-index predicate
  gotcha.

### Files changed

| File | Change |
| --- | --- |
| `supabase/migrations/20260704000000_customer_self_service_order.sql` | New migration — see above |
| `src/services/customerApi.ts` | Rewritten. Was 100% mock; now backed by `supabase.rpc(...)` + `supabase.from(...).insert/select/update` calls. The `CustomerApi` interface is preserved so `customerStore.ts` doesn't change. Branch resolution is hardcoded to `B001` (the only test branch) for now — TODO: read `?branch=…` from the URL once multi-branch QR labels ship. |
| `src/views/customer/CustomerMenu.vue` | Extended the `watch(selectedSubId)` block to auto-call `addSetToCart(cat)` when entering any BUFFET-shaped subcategory (`cat.id === 'buffet'` or starts with `'buffet-'`). The explicit "+ Chọn gói này" banner button is now a no-op once auto-add has fired. |

### CRM ↔ bill auto-link

Already implemented in the previous round (see `§10` and the
`crm_link_surveys_to_bill` RPC at
`supabase/migrations/20260702044658_crm_serving_table_surveys.sql`).
The new migration's auto-`crm_surveys` row gives it something to
join on. The `process_checkout → crm_link_surveys_to_bill(p_order_id,
v_bill_id)` chain now completes end-to-end even when the manager
hasn't filled the survey yet — the survey row's `bill_id` gets
stamped at checkout time, the manager can fill customer info later,
and `crm_surveys.customer_info_snapshot` propagates to the bill via
`generate_invoice` when the cashier issues a tax invoice.

### Verification (see `HALL_CUSTOMER_TEST_REPORT.md §10` for the
full matrix)

- `npx vue-tsc --noEmit` → exit 0
- `npm run build` → exit 0, 1754 modules transformed
- RPC smoke test:
  ```
  SELECT * FROM customer_create_self_service_order(
    'B001', 'A01',
    '[{"menu_item_id":"…","quantity":2,"note":"no onion"}]'::jsonb,
    NULL, 'Smoke Test Walk-in');
  ```
  → returns `{order_id, order_number: "ORD-260703-7142", subtotal:
  800000, vat: 64000, total: 864000, items_count: 1, …}`. Side effects
  verified: `orders` row inserted, `tablet_sessions` row created,
  `tables.status` flipped to `occupied`, `notifications` row emitted,
  `crm_surveys` row auto-created in `'assigned'` state.
- Idempotency: calling the RPC twice with the same `p_session_token`
  appends items to the same `order_id` (subtotal doubles correctly);
  `crm_surveys` dedupes via `WHERE NOT EXISTS` — no duplicate survey
  rows.
- `npx playwright test e2e/no-mock-runtime.spec.ts` → 1 pass (kitchen
  KDS), 2 pre-existing failures (tablet `mock-order-id` + router
  legacy `/customer` — both already in `FUTURE_TODO_OUT_OF_SCOPE.md`,
  no regression introduced by this round).

### Forward / out of scope

- Branch hardcode `B001` is a temporary scaffold. Production: URL
  `?branch=…` or QR-encoded.
- `TabletCheckoutView.vue:36` still references `'mock-order-id-checkout'`
  — pre-existing, tracked.
- `useCheckout().previewCheckout` legacy is still imported by the
  tablet checkout view — pre-existing, tracked.

## §10 — Unification round (2026-07-03)

Customer + cashier were carrying divergent copies of the package-pricing
rule engine. The customer side matched package names by string,
the cashier side by subcategory IDs. Result: two implementations of the
same business rule, with the same five-tier buffet table (1390 → 380),
and no guarantee the customer cart preview ever matched the cashier
bill. Plus a silent bug in `useRealtime` that dropped the second
subscriber's callback on the floor. This section records the fix.

### New shared module

| File | Purpose |
| --- | --- |
| `src/utils/packageRules.ts` | Single source of truth for: 5-tier buffet eligibility, `Kids Meal` / `Buffet Lẩu` / `Set 550JP` / `SET DRINK`, surcharge items always paid, lunch 50% discount, and the canonical subtotal / service-charge (5%) / VAT (8%) / total math. Both `CustomerMenu.vue` and `ReceptionOrderView.vue` import it; nobody carries their own duplicate. |

API surface:

| Export | Caller-side use |
| --- | --- |
| `getPackageTier(item, packageName)` | `'1390' \| '1150' \| '680' \| '490' \| 'kids' \| 'lau' \| '550jp' \| 'drink' \| null` |
| `isItemInPackage(item, packageName)` | `true` iff `getPackageTier` returns a non-null tier (and not surcharge) |
| `applyPackage(item, packageName)` | Returns item with `price=0` and `price_display='0K (Trong gói)'` when in-pkg; returns item as-is otherwise |
| `calculateItemUnitPrice(item, packageName)` | 0 if in-pkg, half if lunch, full otherwise — bypasses surcharges |
| `computeTotals(subtotal)` | `{subtotal, serviceCharge: round(sub*0.05), vat: round((sub+svc)*0.08), total}` |

### Files changed

| File | Change |
| --- | --- |
| `src/views/customer/CustomerMenu.vue` | Replaced the 45-line name-matching `isItemInPackage` and `getModifiedItem` with a 12-line delegation to `applyPackage` + `calculateItemUnitPrice`. Added the `subCatIdByItemId` lookup map so the rule engine can resolve subcategory membership in O(1) (was O(items) per call). Lunch 50% now applied on `handleAddToCart` / `onUpdateQuantity` / `confirmDetailAdd`. |
| `src/views/reception/ReceptionOrderView.vue` | `isItemInPackage` now delegates to `applyPackage` (cashier side). `calculateNetPrice` now delegates unit-price resolution to `calculateItemUnitPrice` — keeps VAT-per-line UI but defers the package/lunch math to the shared engine. |
| `src/stores/customerStore.ts` | `cartTotal` / `serviceCharge` / `vat` / `grandTotal` getters collapse to `price * quantity` after `handleAddToCart` writes a rule-adjusted price (0 for in-pkg, half for lunch). Service charge + VAT derived through `computeTotals()`. Removed the duplicate iteration loops + the duplicated `lunch` name-check that had been copy-pasted four times. |
| `src/composables/useRealtime.ts` | **Bug fix.** Two bugs were latent here — both reproduced reliably when the reception dashboard + view both subscribed to the same `(table, event, filter)` tuple:<br/>1. **Lost-callback bug**: when `channels.get(channelName)` returned an existing channel, the new subscriber's `onChange` was silently dropped (the `if (!ch)` guard short-circuited the `.on(...)` wire-up).<br/>2. **Lost-status bug**: late joiners to an already-`SUBSCRIBED` channel never got their `status` ref moved off the default `'disconnected'` because the `subscribe()` callback had already fired.<br/>New design: a `Map<channelName, { ch, listeners: Set<Listener>, ref, status }>` registry. Subscriber adds itself to `listeners` and bumps `ref`. The Supabase channel fans out each event to every listener via a `for…of Array.from(listeners)`. The channel only tears down when `ref <= 0` on cleanup. Status mirror in the registry entry so late joiners read the current state. |

### Spec alignment (Ishii 02/07/2026)

| Spec line | Before | After |
| --- | --- | --- |
| Buffet 1390 → all eligible items | Customer: name `'1390'` substring (matched nothing for menu IDs without the digit). Cashier: parent-cat whitelist ✓ | Both: parent-category whitelist + subcategory ban-list (wagyu/premium-beef on lower tiers) |
| Lunch 50% discount | **Cashier only** (`ReceptionOrderView.vue:1354-1358`); customer store never applied it | Both — `calculateItemUnitPrice()` returns 50% on items whose id/name contains `lunch` |
| Surcharges always paid | Cashier: `khac / surcharge` check ✓. Customer: nothing — surcharge items would visibly be free in the cart | Both — `isSurchargeItem()` early-returns `false` from `isItemInPackage` and `calculateItemUnitPrice` |
| `Buffet Lẩu` rule | Customer only (`name.includes('LẨU')` + word-list); cashier would treat it as A la carte | Both: `getPackageTier` returns `'lau'` for the right items in either view |
| `Set 550JP` rule | Customer only | Both |
| `Kids Meal` rule | Cashier only | Both |

### Verification

- `npx vue-tsc --noEmit` → exit 0
- `npm run build` → exit 0, 1754 modules transformed, ~4.46 s
- `npx playwright test e2e/no-mock-runtime.spec.ts` → 1 pass (kitchen KDS), 2 pre-existing failures on tablet/router (out of scope; see `FUTURE_TODO_OUT_OF_SCOPE.md`)
- All other e2e specs → 9 skipped (need live Supabase env), 0 new failures

### Forward / out of scope

- `useCheckout().previewTableSummary()` is still hardcoded per-view; unify next round.
- Front-end `useCheckout().previewCheckout` (legacy) is still imported by `TabletCheckoutView.vue`; tracked in `FUTURE_TODO_OUT_OF_SCOPE.md`.
- Per-line VAT in `calculateNetPrice` is a UI choice (visible tax per row on the cashier side); the order-level VAT stored on `orders.vat` uses the same `computeTotals` math.


## §12 — Reception checkout / dashboard fix-up (2026-07-03)

### Root cause

The customer could place an order and the table colour flipped correctly on
admin floors, but **the cashier's "tạm tính" column kept spinning on
PostgREST 404s** for every occupied table:

```
POST /rest/v1/rpc/hall_get_checkout_totals  HTTP/2 404
Searched for the function public.hall_get_checkout_totals(...)
Perhaps you meant to call the function public.hall_get_checkout_summary
```

`hall_get_checkout_totals` was the **new** RPC introduced in
`20260703020001_hall_get_checkout_totals.sql` (replaces the legacy
`hall_get_checkout_summary` whose preview totals disagreed with the actual
bill because the cashier-side `useCheckout.previewCheckout` used a hardcoded
10 % VAT + 1000 VND/point instead of the DB's 8 % VAT + loyalty rules).

The migration file existed locally and was committed, but **`supabase db
push` had not actually applied it to the linked remote project** — the
remote `schema_migrations` table stopped at version `20260702083325`.

### What was done

1. **Migration applied via Management API** (same bypass pattern used for
   `20260704000000_customer_self_service_order.sql`):
   ```
   supabase db query --linked -f supabase/migrations/20260703020001_hall_get_checkout_totals.sql
   ```
   Verified afterwards with
   `pg_proc WHERE proname IN ('hall_get_checkout_totals', 'hall_get_checkout_summary', 'process_checkout')`
   — the new RPC is callable, signed by `authenticated` + `service_role`,
   and its signature matches the four call sites in the codebase
   (`useCheckout.ts:63`, `ReceptionCheckoutView.vue:528`,
   `ReceptionDashboardView.vue:983`, `AdminFloorsView.vue`).

2. **Customer-redirect fix** (`src/views/customer/OrderHistory.vue:213-214`).
   After `await store.requestPayment()`, the customer was being pushed to
   the `Feedback` route — but the user wants to stay on `/customer/menu`
   so they can still see "đang chờ thanh toán" status and the live order
   list. We must NOT push them to `/customer/Feedback` (would surface an
   empty rating form) and we must NOT clear `isAuthenticated` (would force
   them to re-enter the staff passcode).
   ```ts
   await store.requestPayment();
   router.push({ name: 'CustomerMenu' });
   ```

3. **Stale-bill / cross-table leak fix** (`src/views/admin/AdminFloorsView.vue:2873-2890`).
   Previously the per-table `liveBillTotal` only fetched when the cache
   was empty for that `tableId`. Re-opening the same modal (or rapid
   A→B→A clicks) showed a stale or even a wrong table's total because the
   cache key is `tableId` only. Now we **always** re-fetch on every modal
   open, and we **invalidate** the cache whenever a realtime
   `orders` / `order_items` event lands. This is what makes the floor-plan
   totals actually live when a customer taps "Đặt món".

4. **Realtime totals refresh** (`src/views/reception/ReceptionDashboardView.vue:1035-1045`
   and `src/views/reception/ReceptionCheckoutView.vue:605-630`).
   The dashboard now subscribes to `orders` + `order_items` in addition
   to `tables` / `reservations` / `notifications`, so a new customer order
   triggers an immediate `fetchAll()` → fresh `tạm tính` per occupied
   table. The dedicated checkout view (`ReceptionCheckoutView`) gains a
   15-second auto-refresh + realtime reload so a cashier who lingers on
   the bill preview sees the new items without manually clicking refresh.

5. **`previewTableSummary` semantics flipped**
   (`src/composables/useCheckout.ts:90-115`).
   The cache is now opt-in: callers must pass `{ useCache: true }` if they
   want a sticky read. Every default call site (admin floor modal,
   reception dashboard, cashier checkout) takes the cache-less path so
   totals are always authoritative. `clearTableCache(tableId)` is now
   exercised in three places (realtime event, after checkout, manual
   refresh).

### Verification

- Migration applied on remote DB:
  `pg_proc` confirms `hall_get_checkout_totals(p_branch_id, p_table_id, p_order_id, p_voucher_code, p_points_to_use, p_customer_id)`
  returns `jsonb`, granted to `authenticated, service_role`.
- `npx vue-tsc --noEmit` → exit 0
- `npm run build` → exit 0, 1754 modules transformed, ~4.48 s
- `npx playwright test` → 3 pass, 2 pre-existing fail (tablet mock + legacy router), 9 skipped (need live env)
- Math sanity-checked against the live DB: 5 occupied tables (C01..C03, B01, B02) produce distinct grand_totals
  (1.564.920đ / 1.564.920đ / 2.846.340đ / 861.840đ / 430.920đ), confirming the per-table filter and the
  5 % service + 8 % VAT pipeline.

### Hand-trace for the 5-step cashier flow

1. Open `/reception/dashboard` — dashboard fetches 5 occupied tables in parallel
   via `hall_list_tables` + `hall_get_checkout_totals`. No more 404s.
2. Click table `C03` → `/reception/checkout/<tableId>` mounts `ReceptionCheckoutView`.
   Realtime subscribed. `previewCheckout` returns the right totals.
3. Customer at table `B02` adds another item → realtime `order_items` event →
   both dashboard and (still-mounted) checkout view auto-reload.
4. Cashier types the cash received → `refreshTotals()` re-runs the preview
   RPC, the right column updates.
5. Cashier clicks "Thanh toán" → `process_checkout` RPC → success Swal +
   invoice number + redirect to `/reception/dashboard` (existing behaviour).
   `_tableCache.clear()` flushes every table's preview so the next visit
   fetches fresh.

### Hand-trace for the customer redirect

1. Customer at table `C02` taps "Yêu cầu thanh toán" from OrderHistory.
2. `store.requestPayment()` updates `tablet_sessions.status = 'CHECKOUT_REQUESTED'`.
3. `router.push({ name: 'CustomerMenu' })` keeps them on `/customer/menu`.
4. They still see the order list with the "đang chờ thanh toán" badge
   while the cashier processes the bill. They are NOT asked to re-enter
   the staff passcode.
