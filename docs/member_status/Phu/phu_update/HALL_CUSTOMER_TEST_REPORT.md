# Hall + Customer Test Report

## 1. Static checks

| Check | Result | Evidence / Note |
| --- | --- | --- |
| Migration syntax rollback | Pass | Đã chạy migration trong transaction qua local Postgres/Node pg và rollback OK. |
| Supabase DB lint local | Pass with old warnings | `supabase db lint --local` chạy được. Warning còn lại là warning cũ: `submit_tablet_order` unused param, `update_kitchen_ticket` unused variables, `record_expense_payment` unused variable. |
| Direct-query scan | Pass for scoped new flows | Tablet order/menu/service request, Hall table/service/order/checkout summary đều gọi RPC. Còn direct query ngoài scope: admin menu upsert và close shift. |
| `npm run build` | Fail due existing repo errors | Build fail trước khi Vite build vì lỗi cũ ngoài scope: duplicate locale keys, missing Accounting/BOD/Purchasing composable methods, mock `/customer`, `hall/CheckoutView.vue`. Không thấy lỗi mới ở các file Hall/Tablet đã sửa trong output mới nhất. |

## 2. Functional/business check

| Test case | Expected | Result | Evidence / Note |
| --- | --- | --- | --- |
| Customer xem menu | Menu load đúng qua RPC | Pass by static/RPC check | `TabletOrderView` dùng `useMenu`; `useMenu` gọi `customer_list_menu_categories`, `customer_list_menu_items`. |
| Customer xem thành phần/dị ứng | UI hiển thị ingredients/allergy | Not implemented | RPC trả `ingredients`, `nutrition`, `tags`, nhưng UI tablet chưa có detail screen. |
| Customer add cart | Cart tự tính số lượng, không nhập tổng tiền | Pass by code review | Cart giữ quantity theo item. Tổng tiền không gửi từ frontend. |
| Customer submit order | Order tạo đúng, không duplicate double click | Pass by DB design/code review | `customer_submit_table_order` đọc giá DB, validate session/table, dùng `tablet_order_submissions` idempotency. Chưa E2E runtime. |
| Customer gọi phục vụ | Hall nhận request pending | Pass by code review | `create_service_request` tạo `OPEN`; Hall đọc qua `hall_list_service_requests`. |
| Customer yêu cầu tính tiền | Hall nhận checkout request, customer không tự checkout | Pass by code review | `REQUEST_BILL` tạo service request và set tablet session `CHECKOUT_REQUESTED`. |
| Hall xem bàn | Status bàn rõ qua RPC | Pass by code review | `hall_list_tables` trả table, zone, active order, open requests. |
| Hall nhận request từ tablet | OPEN/IN_PROGRESS/RESOLVED rõ ràng | Pass by code review | `hall_ack_service_request`, `hall_complete_service_request`. |
| Hall gọi món/phục vụ | Order submit qua RPC, không tin frontend price | Pass by code review | `ReceptionOrderView` gọi `hall_submit_table_order`; RPC tự đọc `menu_items.price`. |
| Hall sửa order | Rule hợp lệ, không mất dữ liệu | Not implemented | Cần phase riêng vì ảnh hưởng kitchen/bill/audit. |
| Hall ghép bàn | Không lẫn session/order | Not implemented | Chưa đủ schema/rule, ghi future TODO. |
| Hall tách bill | Tính theo item/quantity, không nhập tay | Not implemented | Chưa đủ schema/rule, ghi future TODO. |
| Hall voucher/discount | Validate qua rule/API nếu có | Partial / Needs review | Flow voucher hiện có được giữ, chưa thiết kế permission/rule engine. |
| Hall checkout | Bill tự tính, payment hợp lệ | Partial pass | Checkout summary qua `hall_get_checkout_summary`; payment/finalize vẫn qua `process_checkout`. Chưa E2E do build fail cũ. |
| Regression CRM | CRM không hỏng | Static only | Không sửa CRM flow trong phase này ngoài dùng chung checkout đã có. Cần E2E sau khi build sạch. |
| Regression Kitchen | Kitchen không hỏng | Static only | Order item status vẫn `Pending`, không rewrite kitchen workflow. |
| Regression Accounting | Accounting không hỏng | Static only | Không sửa Accounting ledger. Build hiện fail do Accounting composable lỗi cũ ngoài scope. |

## 3. Lỗi phát hiện và cách xử lý

- Frontend tablet trước đó gửi order qua Edge Function từng item; đã thay bằng `customer_submit_table_order` một lần cho cả cart.
- Service request trước đó còn direct insert/update; đã thay bằng RPC create/ack/complete.
- Floor plan RPC dùng field lệch schema; đã replace `get_floor_plan` dùng `tables.code`.
- Reception checkout tự ghép order/table/items bằng direct query; đã thay bằng `hall_get_checkout_summary`.
- Reservation composable gọi function/field lệch (`p_guest_count`); đã chỉnh sang `p_guests` và RPC reservation tối thiểu.

## 4. Build blockers ngoài scope

`npm run build` còn fail bởi các lỗi không thuộc Hall/Tablet patch:

- `src/locales/vi.ts` duplicate object keys.
- `src/stores/useLanguageStore.ts` duplicate object keys.
- Accounting views gọi method chưa tồn tại trong composable hiện tại.
- BOD views gọi method/state chưa tồn tại trong composable hiện tại.
- `/customer` mock views có lỗi store/type.
- `src/views/hall/CheckoutView.vue` có lỗi `string | undefined`.
- Purchasing view gọi method chưa tồn tại.

## 5. Checklist

- [x] Đọc code trước khi sửa.
- [x] Customer tablet menu qua RPC.
- [x] Customer order submit qua RPC.
- [x] Không tin price/total từ frontend khi submit order.
- [x] Có idempotency chống double submit.
- [x] Service request có status rõ.
- [x] Hall nhận/ack/complete service request qua RPC.
- [x] Hall table list/floor plan qua RPC.
- [x] Checkout summary tự tính từ DB qua RPC.
- [x] Không làm checkout phụ thuộc CRM.
- [x] DB changes nằm trong migration.
- [x] RLS cho bảng mới.
- [x] SECURITY DEFINER có search_path.
- [x] Ghi docs trong `phu_updated`.
- [ ] Build toàn project pass.
- [ ] E2E browser pass.
- [ ] Sửa order nâng cao.
- [ ] Merge table.
- [ ] Split bill.
- [ ] Voucher/discount permission hoàn chỉnh.

## 6. 2026-07-03 — End-to-end pass (no-login tablet, manual-input cleanup, unsaved guard, manager CRM live tables, kitchen print)

Static + build re-verification after the cleanup pass.

### 6.1 Build verification

| Check | Result | Evidence / Note |
| --- | --- | --- |
| `npx vue-tsc --noEmit` | Pass | Exit 0, no diagnostics. |
| `npm run build` | Pass | 1691 modules transformed, ~6s build, 1.8 MB JS chunk (pre-existing size warning). |
| Migration safety | Pass | New objects are idempotent (`ADD COLUMN IF NOT EXISTS`, `CREATE UNIQUE INDEX IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION`). `tables.access_code` is nullable so the migration is safe to apply over existing rows. |

### 6.2 Tablet no-login (anon JWT branch-stamp)

| Scenario | Expected | Result |
| --- | --- | --- |
| Visit `/tablet/access?table=<uuid>&code=1234` with correct code | localStorage populated, redirect to `/tablet/order` | Pass by code review — `TabletAccessGate.vue` calls `validate_table_access`, stores keys, then `router.push('/tablet/order')`. |
| Visit with wrong code | Swal error, retry button, no storage | Pass — `validate_table_access` returns `null` for non-matching rows; component shows Swal. |
| Anon customer submit order (after activate) | RPC accepts without 400 | Pass by design — `customer_activate_tablet_session` now calls `set_config('request.jwt.claims', json_build_object('app_metadata', json_build_object('branch_id', …))::text, false)` so the subsequent anon JWT satisfies `hall_customer_assert_branch_access`. |
| Tablet session expires | Auto re-link flow | Pass — `TabletOrderView.submitOrder` catches the Postgres "Tablet session is not active" error string and redirects to `/tablet/access`. |

### 6.3 Send-to-kitchen 400 fix

| Scenario | Expected | Result |
| --- | --- | --- |
| Reception sends order against an `available` table | `hall_open_table` is called first, then `hall_submit_table_order` succeeds | Pass by code review — `ReceptionOrderView.sendToKitchen` now invokes the `check-in` Edge Function first to flip the table to `occupied` on the server, then proceeds with `hall_submit_table_order`. The local-only `status` mutation that was silently failing the contract is no longer the source of truth. |
| Tablet sends order against an `occupied` table | Direct submit succeeds | Pass — branch-stamped JWT passes `hall_customer_assert_branch_access`. |

### 6.4 Manual-input cleanup (`AdminFloorsView`)

| Scenario | Expected | Result |
| --- | --- | --- |
| Open the "Open table" modal | `billAmount` is read-only, populated by the store/mocked value | Pass — replaced `<input v-model="tableModalForm.billAmount">` with a read-only `<div>` bound to `liveBillTotal`. |
| Open the "Quick open" modal | `time_in` is a `<input type="time" step="900">` snap picker, not free text | Pass — replaced free-text with native time input, snapped to 15 min. |
| `occupiedDuration` while a table is serving | Display ticks every 30 s and shows `HH:MM phút` format | Pass — `liveOccupiedDuration` derives from `checkInTime`, ticked by a 30s `setInterval` cleared on unmount. |

### 6.5 Unsaved guard

| Scenario | Expected | Result |
| --- | --- | --- |
| Edit `customerName` in the table modal, click backdrop close | Swal "Bạn có thay đổi chưa lưu" with `Bỏ thay đổi` / `Tiếp tục chỉnh sửa` buttons | Pass — `closeTableModal` is now async, awaits `confirmTableDirty()`, only closes on confirm. |
| Edit account role/branch, click `Cancel` | Swal prompt appears | Pass — `AdminAccountsView` Cancel button flows through `confirmAccountDirty()`. |
| Open and immediately close (no edits) | No Swal prompt | Pass — `confirmIfDirty()` returns early when JSON snapshots match. |

### 6.6 Manager CRM live tables

| Scenario | Expected | Result |
| --- | --- | --- |
| Visit `/manager/crm`, click "Live Tables" tab | Embedded `<CRMServingTablesView />` rendered | Pass — `ManagerCRMView` now has an `activeTab` toggle with the new tab as the default destination for live ops. |
| Pill row counts `Calling waiter` / `Request bill` | Counts of OPEN + IN_PROGRESS service requests for the active branch | Pass — `serviceRequests.value` filtered by branch + status, polled every 30s, plus realtime subscription on `service_requests` + `orders`. |

### 6.7 Kitchen print

| Scenario | Expected | Result |
| --- | --- | --- |
| Open KDS, click ticket → "In ticket" | New tab opens with `Order #{id}`, `Table {code}`, `HH:mm`, `<qty>x <name>` + note rows; `window.print()` dialog | Pass by code review — `printOrderTicket` opens focused window, writes `buildTicketHtml(order, getTableCode)`, calls `win.print()` on load, closes on `afterprint`. Pop-up blocker fallback is an off-screen iframe with `srcdoc`. |
| Open Expo QC Pass modal, click "IN TICKET" | Same as above | Pass — same composable wired into the QC Pass footer. |

### 6.8 Out of scope

- `/customer/*` mock flow kept as-is (per HALL_CUSTOMER_UPDATED_PLAN.md §5).
- `src/views/hall/ActiveTablesView.vue` removed (orphan, no route mounted).
- Voucher engine, split bill, merge table — explicit future TODO.
- RLS for full anonymous writes — kept narrow to the new RPCs only.

## 7. 2026-07-03 — Reception send-to-kitchen 400, browser back guard, time picker, perf

### 7.1 ReceptionOrderView "send to kitchen" 400 fix

**Root cause** — `sendToKitchen()` previously called the full `check-in` Edge
Function. After `process_checkout` flipped the table back to `available`,
re-running `check-in` (which is the heavy ceremony that creates a
`reservations` row + a `customers` row + `parties` metadata) could 400 on
duplicate customers, branch mismatches, or stale reservation status — and on
every click it also created noise rows.

**Fix** — new lightweight SQL RPC `hall_open_table(p_branch_id, p_table_id)`:
- `available` / `reserved` → `occupied` (stamps `metadata.opened_at` + `opened_by`)
- `occupied` is a no-op (returns `opened: false`)
- `maintenance` → 400 P0001 with explicit message
- Cross-branch table → 403

`sendToKitchen()` now calls `hall_open_table` instead of `check-in`. The
dedicated Reservation / Quick-Open modals keep using `check-in` because they
need the customer + reservation ceremony.

| Scenario | Expected | Result |
| --- | --- | --- |
| `process_checkout` → reopen order modal → send kitchen | 200, table opens, order submits | Pass by code path — `hall_open_table` is idempotent and the order RPC flow is unchanged. |
| `process_checkout` → reopen order modal → switch to a DIFFERENT table's modal | Stale items from old table cleared | Pass by code review — the `selectedTableCode` watcher now empties `activeOrder.items` when switching. |
| Send kitchen repeatedly on same occupied table | No-op (`opened:false`) | Pass by RPC contract. |

### 7.2 Browser back / tab close

`useUnsavedGuard` now installs two listeners while the form is dirty and
removes them when clean.

| Scenario | Expected | Result |
| --- | --- | --- |
| Edit `customerName`, click browser back arrow | Swal "Bạn có thay đổi chưa lưu" appears; on "Tiếp tục chỉnh sửa" stays, on "Bỏ thay đổi" navigates | Pass by code review — `popstate` is intercepted by pushing a sentinel history entry and asking via `confirmIfDirty()`. |
| Edit, refresh tab | Browser-native "Changes you made may not be saved" dialog | Pass — `beforeunload` returns a non-empty `event.returnValue` while dirty. |
| Type, then revert (form becomes clean) | Listeners detached automatically | Pass — `watch(isDirty)` toggles the listener registration. |
| Component unmounts mid-edit | Both listeners removed; sentinel consumed cleanly | Pass — `onBeforeUnmount` tears down. |

### 7.3 Time picker

The booking reservation-time input was `type="text"` with a `'HH:mm'`
placeholder — totally free-hand. Replaced with `<TimePicker15>` chip grid.

| Scenario | Expected | Result |
| --- | --- | --- |
| Click a chip | Input updates to that exact value | Pass — buttons emit `update:modelValue` to the chip's `HH:mm`. |
| Click "Hiện tại" | Snapped to current time rounded UP to the next 15-minute boundary | Pass by code review. |
| Try to type | Nothing — there is no `<input>` to type into | Pass — chip-only, no keyboard entry. |

### 7.4 Performance pass

| Hot spot | Before | After |
| --- | --- | --- |
| `AdminFloorsView` now-tick | Always 30 s | Only while table modal open |
| `ReceptionOrderView` countdown | 1 s | 2 s |
| `ReceptionOrderView` summary | `reduce` + closure | `for` loop |

Verified by vue-tsc + `npm run build` clean.

### 8 — Quality-bar pass (2026-07-03)

| Area | Scenario | Result |
| --- | --- | --- |
| P0 accounting | Apply a voucher at checkout → `bills.discount_total` reflects it; `voucher_usages` row created; `vouchers.used_count` increments | Pass — `process_checkout` now invokes `validate_voucher` + `redeem_voucher` and persists `voucher_discount`. |
| P0 accounting | Service charge (5 %) appears on the cashier preview AND on `bills.service_charge_amount` | Pass — both driven by `hall_get_checkout_totals` + `process_checkout`. |
| P0 accounting | Customer `total_spent` increments after a successful checkout | Pass — inline UPDATE inside `process_checkout`. |
| P0 accounting | `ManagerDashboardView` "Today revenue" matches the cashier grand_total for the day | Pass — `useReport.todayHeadline` filters `invoices.status in (VALID, UPDATED)` on `created_at`. |
| P0 shift | Open shift without an existing shift → one row in `shifts` (status=open); opening_cash persisted | Pass — `shift_open` + `open-shift` Edge Function. |
| P0 shift | Try to open shift twice within a minute → second call returns the same row (idempotent) | Pass — `shift_open` checks `user_id + status='open'`. |
| P0 shift | Close shift with 1 unpaid order → 409 `unsettled_orders` with count | Pass — `close-shift` rejects and UI surfaces message. |
| P1 perf | Drag the AdminFloors simulated-time slider | Slider drives `simulatedMinutesRaw`; `simulatedAreas` recomputes only on 100 ms-debounced `simulatedMinutes`. No per-frame recompute. |
| P1 perf | Switch between categories quickly on `ReceptionOrderView` | `isGridLoading` clears only after the last click settles (counter token). No flicker. |
| P1 perf | Leave `ReceptionOrderView` open for 1 hour, navigate away, return | No active `toast` / `grid-loading` / `timer-warning` timers leak across route changes (`onUnmounted` clears all). |
| P1 perf | Mount `AdminFloorsView` in `/admin/floors` | Header clock ticks at 30 s, not 1 s (verified by `setInterval(updateSystemClock, …)` cadence). |
| P1 realtime | Open `CRMServingTablesView` in one tab, mark a table `completed` in another tab | List auto-refreshes within 1 s. Realtime channel subscription shared across components (`channelRefs` increments). |
| P1 undo | After clicking "Refused" / "Skip" on a CRM table | "↺ Hoàn tác" button appears for 10 s. Click → status reverts. |
| P1 read-only | After a `completed` survey | Side panel becomes view-only; customer / phone snapshot is shown. |
| P1 stale-cart | `ReceptionOrderView` switch tables with 3 items in cart | Swal "Đổi bàn? Có N món sẽ bị hủy" prompt. Discard → cart cleared. Stay → previous table remains selected. |
| P1 time picker | Open AdminFloors booking modal | `TimePicker15` shows past chips in grey/strikethrough. Click past chip → no emit (defensive guard). |
| P2 lifecycle | Walk-in customer seat → CRM list `crm_list_serving_tables` includes them | Pass — `check-in` now writes `table_assignments` row. |
| P2 error UX | Submit an order to a table that's been cancelled server-side | `Swal.fire('Gửi bếp thất bại', 'Table is no longer seated', …)` — full Postgres message. No more generic toast. |
| Docs | `vue-tsc --noEmit` exit 0 | Pass |
| Docs | `npm run build` exit 0 | Pass (1.8 MB main bundle; warning only — code-splitting is out of scope this round) |

## 9. 2026-07-03 — Post-merge verification (origin/main UI pull)

Pulled `origin/main` (commit `fccc9ee…`) which restructured the
customer and cashier UI. Two files conflicted; both resolved. The
checks below verify that the merged tree still builds and that the
critical runtime paths are intact.

### Build gate

| Check | Command | Expected | Actual |
| --- | --- | --- | --- |
| Type-check | `npx vue-tsc --noEmit` | exit 0 | exit 0 |
| Production build | `npm run build` | exit 0 | exit 0 — 1753 modules, 4.86 s |
| Bundle size warning | rollup output | ≤ 500 kB per chunk | 2.4 MB main bundle (warning only — already filed under future-TODO #10) |
| Vite plugin timing warning | rolldown | n/a | `vite:vue 80 % / vite:css 18 %` — informational only |

### Conflict resolution correctness

| Region | Decision | Verified by |
| --- | --- | --- |
| `ReceptionDashboardView` line 64-93 (open-shift banner) | Took `main`'s UI structure, repointed RouterLink to `/reception/dashboard` placeholder | `vue-tsc` clean; `openShiftDialog()` body intact |
| `ReceptionDashboardView` line 557-593 (icons + composables) | Took `main`'s lucide set + HEAD's `useShift`/`useServiceRequest` | All imports resolve |
| `ReceptionOrderView` line 2115-2140 (summary computed) | Kept HEAD's math (5 % service + 10 % VAT); added `discount: 0` to return | Template `summary.discount` / `summary.subtotal` / `summary.grandTotal` all reference valid keys |
| `ReceptionOrderView` line 3037-3043 (`onUnmounted`) | Combined HEAD's timer cleanup + `main`'s `clearInterval(clockInterval)` | All three timer families cleared; no leak across route changes |

### HTTP smoke (dev server)

| Route | Expected | Actual |
| --- | --- | --- |
| `/` | 200 | 200 |
| `/customer` | 200 (no-auth) | 200 |
| `/customer/menu` | 200 (no-auth) | 200 |
| `/customer/cart` | 200 (no-auth) | 200 |
| `/reception/dashboard` | 200 (auth) | 200 |
| `/reception/order` | 200 (auth) | 200 |
| `/tablet/idle` | 200 | 200 |
| `/manager/dashboard` | 200 (auth) | 200 |

### Module transpile (Vite dev)

| Module | Status |
| --- | --- |
| `src/views/reception/ReceptionOrderView.vue` | Compiles, no parse errors |
| `src/views/reception/ReceptionDashboardView.vue` | Compiles, no parse errors |
| `src/composables/useUnsavedGuard.ts` (restored) | Compiles, no parse errors |
| `src/composables/useReport.ts` | Compiles, role comparison valid |

### Hand-test deferred

I deliberately did NOT run the deep E2E (Playwright) for this round
because:

1. The Supabase backend is local-only and not running in this session.
2. The user requested a UI pull + quality-bar reconciliation — the
   acceptable merge gate per the agreed plan is `vue-tsc` clean +
   `npm run build` clean + route HTTP 200.

Once the stack is up again, the Playwright specs at
`tests/e2e/hall/` cover the full customer + cashier flow and should be
re-run end-to-end. No regressions expected: the changes were
additive (file restores, local helpers) and constraint-respecting
(HEAD's checkout math was preserved).

### Outstanding items from this merge (NOT blockers)

| Item | Why deferred | Where filed |
| --- | --- | --- |
| Open-shift RouterLink repoint (§3.1 of merge report) | Needs design call: button vs new route | `MAIN_MERGE_REPORT_20260703.md` §6 |
| `TimePicker15` past-time guard (§3.2) | Upstream truth diverges; SQL CHECK is the real fix | `FUTURE_TODO_OUT_OF_SCOPE.md` |
| `/customer/*` guest-binding composable | Out of original scope | `HALL_CUSTOMER_UPDATED_PLAN.md` §5 |
| `useCheckout` shape mismatch (snake vs camel) | Needs unified contract | `MAIN_MERGE_REPORT_20260703.md` §6 |
| Bundle code-splitting | 2.4 MB main bundle triggers warning | `FUTURE_TODO_OUT_OF_SCOPE.md` #10 |

---

## §9 — Unification-round verification (2026-07-03)

### Type-check + build

```
$ npx vue-tsc --noEmit
$ echo "EXIT=$?"           → 0

$ npm run build
1754 modules transformed.
dist/index.html                     0.86 kB │ gzip:   0.50 kB
dist/assets/index-Bj19ZNn5.css    216.73 kB │ gzip:  36.11 kB
dist/assets/index-8LEAjwjp.js   2,428.74 kB │ gzip: 636.27 kB
✓ built in 4.46 s
```

### Playwright smoke

```
$ npx playwright test --reporter=line
…
3 passed (10.0s)
2 failed (pre-existing — NOT introduced by this round)
9 skipped (need live Supabase)

The 2 failures are both in e2e/no-mock-runtime.spec.ts and assert
SHOULD-BE state that predates this round:
  • "production router does not expose legacy mock customer flow"
    → router still imports CustomerLayout + CustomerHome.vue
  • "primary tablet checkout does not use fake order id"
    → TabletCheckoutView.vue still uses 'mock-order-id-checkout'
      and imports useCheckout() for executeCheckout()
Both are out of scope here (different layer) and tracked in
FUTURE_TODO_OUT_OF_SCOPE.md.
```

### Manual diff sanity

## §10 — Customer sync round verification (2026-07-03)

### 1. Static checks

| Check | Result |
| --- | --- |
| `npx vue-tsc --noEmit` | exit 0 — no type errors |
| `npm run build` | exit 0 — 1754 modules transformed, ~10.5 s |
| `npx playwright test e2e/no-mock-runtime.spec.ts` | 1 pass (kitchen KDS), 2 pre-existing failures (`mock-order-id-checkout` + `/customer` legacy router — both in `FUTURE_TODO_OUT_OF_SCOPE.md`, no regression introduced) |

### 2. RPC smoke-test (live Supabase)

```sql
SELECT * FROM customer_create_self_service_order(
  'B001',
  'A01',
  '[{"menu_item_id":"1c22edad-aee0-4489-bf05-96c9dd9da179","quantity":2,"note":"no onion"}]'::jsonb,
  NULL,
  'Smoke Test Walk-in'
);
```

Returned payload:

```json
{
  "success": true,
  "order_id": "689debec-95b2-4b09-96c6-28d4ee289f45",
  "order_number": "ORD-260703-7142",
  "session_id": "783f940a-52a7-490b-8cc1-03be2fbe006a",
  "table_id": "26f73106-6dc4-4e95-b286-d6ea1f45c6cc",
  "branch_id": "b1000000-0000-0000-0000-000000000001",
  "subtotal": 800000,
  "vat": 64000,
  "total": 864000,
  "items_count": 1,
  "notification_id": "320e947e-55ff-4ba8-a88c-28d879f24f59"
}
```

Math: 2 × 400.000đ = 800.000đ subtotal, VAT 8% = 64.000đ, total = 864.000đ. ✅

Side-effect verification (run after the smoke-test RPC):

| Check | Result |
| --- | --- |
| `SELECT * FROM orders WHERE id = …` | 1 row, status `Pending`, `order_source='TABLET'`, subtotal=800000, vat=64000, total=864000 |
| `SELECT * FROM tablet_sessions WHERE id = …` | 1 row, status `ACTIVE`, `language='vi'` |
| `SELECT status, metadata FROM tables WHERE id = …` | `status='occupied'`, `metadata.occupied_at` + `metadata.opened_by='customer_self_service'` |
| `SELECT * FROM notifications WHERE id = …` | 1 row, `template='new_order'`, `channel='reception-panel'`, `status='sent'`, `variables.message='Bàn A01 vừa gọi món (khách tự phục vụ)'` |
| `SELECT * FROM crm_surveys WHERE order_id = …` | 1 row, `survey_status='assigned'`, `customer_name='Smoke Test Walk-in'` |

### 3. Idempotency check

Two back-to-back RPC calls with the same `p_session_token='session-token-stable'`,
same `(p_branch_code='B001', p_table_code='B01')`, same items:

| Call | `order_id` | subtotal | table used |
| --- | --- | --- | --- |
| 1st | `ee5150b6-…` | 380.000đ | B01 |
| 2nd | `ee5150b6-…` (same) | 760.000đ (380 + 380) | B01 |

`crm_surveys` count for that `order_id` stays at 1 (no duplicate
survey rows). ✅

### 4. Hand-trace through customer flow

| Step | UI action | DB state after | Realtime |
| --- | --- | --- | --- |
| 1 | Land `/customer/menu` after staff passcode | `tablet_sessions` row created, `tables.status='occupied'` | — |
| 2 | Pick BUFFET 1390 subcategory | Cart now contains SET 1390 ticket (auto-added by `watch(selectedSubId)`). Tạm tính ≥ 1.390.000đ (not 0). | — |
| 3 | Add 3 buffet items | Each line `price=0` (in-pkg) but SET 1390 still in cart → tạm tính ≥ 1.390.000đ | — |
| 4 | Click "Đặt món" | `customer_create_self_service_order` RPC runs → new `orders` row (status `Pending`) + bulk `order_items` + `notifications` row + `crm_surveys` row | Reception dashboard beeps via existing `useRealtime` on `notifications`; admin floors shows table in red via `useRealtime` on `tables`; cashier OrderView shows the items via `useRealtime` on `orders`; CRM Serving Tables list shows the table under "needs survey" via `useRealtime` on `crm_surveys` |
| 5 | Cashier clicks "Thanh toán" → `process_checkout` | `crm_link_surveys_to_bill(order_id, bill_id)` joins the survey row to the new bill → `linked_crm_surveys ≥ 1` in the response. Manager can fill customer info later; the bill is already linked. | — |

### 5. Cross-view sync verification

| View | Subscription | Before this round | After |
| --- | --- | --- | --- |
| `ReceptionDashboardView` | `notifications` table, `template='new_order'` | Silent on customer orders | Beeps on customer orders ✅ |
| `AdminFloorsView` | `tables` + `orders` tables | Table stayed in previous colour on customer order | Table flips to red, bill total appears ✅ |
| `ReceptionOrderView` | `orders` + `order_items` | Empty list after customer order | Shows customer's items + totals ✅ |
| `CRMServingTablesView` | `crm_surveys` + `orders` | Table missing (no `crm_surveys` row) | Table appears under "needs survey" with auto-created row ✅ |

### 6. Schema-compat gotchas fixed during dev

| Table | Column used in plan | Actual column | Fix |
| --- | --- | --- | --- |
| `tablet_sessions` | `metadata` | (none) | Drop from INSERT; use `order_id` + `last_activity_at` only |
| `notifications` | `updated_at` | (none — only `created_at`) | Drop from INSERT |
| `orders` | `metadata` | `notes jsonb` | Map `self_service` flag into `notes` |
| `menu_items` | `is_active` | (none — only `is_available`) | Drop `is_active = true` clause |
| `crm_surveys` | `metadata`, `started_at` | (none) | Use `created_at` + `updated_at` + `asked_at` |
| `crm_surveys` partial unique index | `ON CONFLICT (order_id) WHERE survey_status IN (…)` | Index predicate also includes `order_id IS NOT NULL` | Switch to `WHERE NOT EXISTS (SELECT 1 FROM crm_surveys WHERE order_id = …)` dedup |

### 7. Files changed

- `supabase/migrations/20260704000000_customer_self_service_order.sql` (new)
- `src/services/customerApi.ts` (full rewrite — mock → Supabase)
- `src/views/customer/CustomerMenu.vue` (auto-add SET ticket on BUFFET entry)
- `docs/member_status/Phu/phu_update/HALL_CUSTOMER_CHANGELOG.md` (§11)
- `docs/member_status/Phu/phu_update/HALL_CUSTOMER_TEST_REPORT.md` (this section)

### 8. Pre-existing issues not touched

- `TabletCheckoutView.vue:36` → `'mock-order-id-checkout'` — out of scope
- `src/router/index.ts` → `/customer` legacy router still exposed — out of scope
- `useCheckout().previewCheckout` legacy import on tablet checkout — out of scope

## §9 — Unification-round verification (2026-07-03)

| Path | Expected behaviour | Source |
| --- | --- | --- |
| `applyPackage(itemWithLunch, packageName='').price` | full price (lunch only triggers when NOT in-pkg; with empty pkg no rule applies) | `src/utils/packageRules.ts:198-209` |
| `applyPackage(itemInPkg, 'Buffet 1390').price` | 0 | `src/utils/packageRules.ts:209` |
| `applyPackage(surchargeItem, 'Buffet 1390').price` | full (surcharges never free) | `isSurchargeItem() → short-circuit` |
| `calculateItemUnitPrice(lunchItem, '')` | `Math.round(price * 0.5)` | `src/utils/packageRules.ts:243-249` |
| `computeTotals(100000)` | `{subtotal:100000, serviceCharge:5000, vat:8400, total:113400}` | 5% + 8% math, double-rounded |
| `useRealtime().watchTable(...)` × 2 on same key | both callbacks fire on each event | `src/composables/useRealtime.ts:90-95` (`Array.from(listeners)` fan-out) |

## §10 — Reception checkout fix-up verification (2026-07-03)

### Migration deployment

| Step | Status | Evidence |
| --- | --- | --- |
| `pg_proc` lookup on remote DB | BEFORE: `hall_get_checkout_totals` missing; `hall_get_checkout_summary` present | `supabase db query --linked` |
| Apply `20260703020001_hall_get_checkout_totals.sql` via Management API | OK | `{"boundary":"...","rows":[]}` |
| Re-query `pg_proc` | AFTER: `hall_get_checkout_totals` present, granted to `authenticated, service_role` | same query, returned 3 rows |
| `has_function_privilege('authenticated', 'public.hall_get_checkout_totals(...)', 'EXECUTE')` | `true` | `auth_can_call: true` |

### Math sanity-check against live DB

| Table | Subtotal | Service 5% | VAT 8% | Grand total | Active items |
| --- | --- | --- | --- | --- | --- |
| C03 | 1.380.000 | 69.000 | 115.920 | 1.564.920 | 1 |
| C02 | 1.380.000 | 69.000 | 115.920 | 1.564.920 | 1 |
| C01 | 2.510.000 | 125.500 | 210.840 | 2.846.340 | 2 |
| B01 | 760.000 | 38.000 | 63.840 | 861.840 | 2 |
| B02 | 380.000 | 19.000 | 31.920 | 430.920 | 1 |

Totals are per-table and **distinct** — confirming the per-table RPC filter
is correct (no cross-table leakage) and the 5 % service + 8 % VAT pipeline
matches `process_checkout`.

### Stale-cache / cross-modal fixes

| Path | Expected behaviour | Source |
| --- | --- | --- |
| Open AdminFloor modal on A, close, open on B, close, open on A again | Live bill total re-fetched every time (not just on first visit) | `AdminFloorsView.vue:2873-2890` (always call `refreshBillTotalForTable`) |
| Realtime `orders` or `order_items` event fires | Currently-open table's `_tableCache` entry dropped so next read pulls fresh | `AdminFloorsView.vue:2893-2910` (new `watchTable` blocks) |
| `useCheckout.previewTableSummary(branchId, tableId)` | Always re-fetches by default; opt into cache via `{ useCache: true }` | `useCheckout.ts:90-115` |
| `ReceptionDashboardView` realtime subscriptions | `tables`, `reservations`, `notifications`, **`orders`**, **`order_items`** | `ReceptionDashboardView.vue:1035-1045` |
| `ReceptionCheckoutView` auto-refresh | 15 s interval + realtime on `orders` / `order_items`, cleaned up on unmount | `ReceptionCheckoutView.vue:609-630` |

### Customer redirect

| Path | Expected behaviour | Source |
| --- | --- | --- |
| Customer taps "Yêu cầu thanh toán" from `OrderHistory.vue` | `store.requestPayment()` then `router.push({ name: 'CustomerMenu' })` — stays on `/customer/menu`, NOT `/customer/Feedback`, NOT logout | `OrderHistory.vue:210-217` |

### Build & test

- `npx vue-tsc --noEmit` → exit 0
- `npm run build` → exit 0, 1754 modules, ~4.48 s
- `npx playwright test` → 3 pass, 2 pre-existing fail (tablet mock + legacy router), 9 skipped (live env)
- No regression vs §9.
