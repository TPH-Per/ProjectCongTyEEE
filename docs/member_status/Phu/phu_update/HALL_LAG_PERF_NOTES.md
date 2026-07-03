# Hall Lag & Performance Notes — 2026-07-03

This note exists so future contributors don't accidentally re-introduce the
hot spots that were profiled and fixed during the 2026-07-03 quality-bar pass.
The list is **non-exhaustive** — it's the set of "always check before touching"
items.

## Hall / cashier view perf checklist

| Hot spot | Where | Symptom | Fix |
| --- | --- | --- | --- |
| Per-render O(N) menu walks | `ReceptionOrderView.getItemSubcategoryId` / `isItemInPackage` | Visible stutter when the cashier scrolls a 200-item menu, since each tile triggered two nested for-loops over `menuData.categories` × subcategories × items | Build a `Map<itemId, {subCatId, parentCatId}>` once at module load (`subcategoryIdByItemId`). Reads are O(1). |
| Side-effect inside `computed` | `ReceptionOrderView.activeSettings` | `tableSettings.value[code] = {...}` inside the computed caused eager-write reactivity, full-table re-renders | Move the lazy seed into `ensureTableSettings(code)` and call it from the table-change watcher. |
| Multiple overlapping setTimeouts | `ReceptionOrderView.selectCategory` `isGridLoading` | Rapid category clicks fired racing timers; spinner flickered | Counter-token cancellation: each call bumps a `gridLoadingToken`; only the last token's timer is honoured. |
| Untracked timers on unmount | `ReceptionOrderView.triggerToast` / `timerWarnings` / `gridLoadingTimer` | After router push, callbacks mutated refs of an unmounted component | Centralise timer ids in a `Set<number>` and clear in `onUnmounted`. |
| Per-second `watch(timerSecondsLeft)` | `ReceptionOrderView` 30/60/0-minute warnings | Re-evaluated twice per second for the entire 2-hour session | Replaced with `scheduleTimerWarnings(secondsLeft)` — fires once per crossing via a chain of `setTimeout`. |
| Stale cart silently dropped | `ReceptionOrderView` switched-table watcher | Cashier lost typed items by accidentally clicking another table | Watcher now reads the cart length, prompts via `Swal`, restores the previous `selectedTableCode` if the user keeps editing. |
| Live ledger not shared | `useRealtime` | Component A mounting + unmounting closed the channel for component B | Reference count tracked in a module-level `Map<string, number>`; the underlying channel only tears down on the last unsubscribe. |

## AdminFloorsView perf checklist

| Hot spot | Where | Symptom | Fix |
| --- | --- | --- | --- |
| 1 Hz `currentTime` always on | Header clock | Per-second wake-up even when the user wasn't looking at the dashboard | `scheduleSystemClock()` bumps cadence to 1 s only when (reception mode AND modal open), else 30 s. |
| Every slider tick recomputes the whole floor | `simulatedAreas` reads `simulatedMinutes` | Slider drag stutters as the entire `areas` array rebuilds per frame | Split into `simulatedMinutesRaw` (slider-bound) + `simulatedMinutes` (debounced 100 ms via `commitSimulatedMinutes`). All consumers read the debounced ref. |

## Reception view reactivity checklist

- Watchers on `selectedTableCode` should always be **async-friendly**: any
  prompt that might cancel the action must restore the previous value.
  See the `reception_order.switch_table_prompt_*` i18n keys.
- `useRealtime().watchTable('table', '*', cb)` is now safe to call from
  multiple components concurrently; do NOT add local channel bookkeeping.

## Build + verification gate

Before any PR that touches hall / cashier / floors views:

1. `npx vue-tsc --noEmit` — must exit 0.
2. `npm run build` — must exit 0.
3. Hand-test the cart-switch prompt at least once on `ReceptionOrderView`.
4. Hand-test that `CRMServingTablesView` updates within 1 s of a remote survey
   status change.
5. Confirm idle CPU on the dashboard tab is ~0 % (open DevTools Performance
   recording for 10 s, count wakes/sec).

If you slip on any of these, treat it as a regression — fix forward, don't
revert the perf work.
