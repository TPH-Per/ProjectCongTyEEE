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
