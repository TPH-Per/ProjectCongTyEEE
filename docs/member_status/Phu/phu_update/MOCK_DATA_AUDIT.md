# Mock Data Audit

## Scan command

```bash
rg -n --hidden --glob '!node_modules' --glob '!dist' --glob '!build' \
  "mock|Mock|MOCK|fake|Fake|FAKE|dummy|Dummy|DUMMY|sample|Sample|SAMPLE|demo|Demo|DEMO|placeholder|Placeholder|hardcoded|testData|fixture|fixtures|seedData|fallbackData" .
```

Raw result: **530 matching lines** across docs, legacy views, production views, scripts, seed files and comments.

## Summary

| Classification | Count / Scope | Status |
| --- | --- | --- |
| Production mock removed in this task | 4 key runtime paths | Fixed |
| Production mock still present / needs follow-up | Multiple Kitchen/Reception/Superadmin/legacy areas | Not ready |
| Legacy/unrouted mock | `/customer`, root demo views, data files | Kept but not production route |
| Seed/dev/sample data | Supabase seed/migration sample comments | Kept |
| Placeholder UI text | many inputs/placeholders | Kept |
| Docs/plans mentioning mock | many docs | Kept |

## Detailed findings

| File | Pattern found | Runtime impact | Classification | Action |
| --- | --- | --- | --- | --- |
| `src/router/index.ts` | `/customer` public legacy route imported customer views | Public production route to mock-backed customer flow | Production mock | Removed from runtime; `/customer` now redirects to `/tablet/idle` |
| `src/services/customerApi.ts` | in-memory local tables/orders/requests/menu | Legacy customer flow mock data | Legacy/unrouted mock | Kept but no longer routed from production router |
| `src/stores/customerStore.ts` | imports `customerApiImpl` | Legacy customer store depends mock API | Legacy/unrouted mock | Kept for compile; route removed |
| `src/views/kitchen/KitchenKDSView.vue` | imported `mockKitchenData`, called `loadMockTickets`, `loadMockGrillRequests` | KDS queue auto-filled fake tickets | Production mock | Removed import and auto-load calls |
| `src/data/mockKitchenData.ts` | `mockTickets`, `mockGrillRequests`, `mock86dItems` | Mock data source | Legacy/dev data | Kept, no longer auto-loaded by KDS |
| `src/views/tablet/TabletCheckoutView.vue` | `mock-order-id-checkout` | Customer checkout used fake order id | Production mock | Replaced with `REQUEST_BILL` service request |
| `src/composables/useCheckout.ts` | mock checkout preview estimation | Unsafe client-side total preview | Production risk | Disabled function; callers must use `hall_get_checkout_summary` |
| `src/views/accounting/AccountingDashboardView.vue` | `Mock Chart Area`, `Math.random`, fake recent transactions | Fake accounting dashboard values | Production mock | Removed random chart/fake transaction list; shows empty state |
| `src/views/reception/ReceptionOrderView.vue` | static `menuData`, `getMockOptionsForItem`, mock table-code comments | Reception order UI still uses static catalog/options before resolving DB ids | Production risk | Kept; needs follow-up to load catalog/options fully from DB/RPC |
| `src/views/tablet/TabletIdleView.vue` | "Mock QR Code" comment | Visual placeholder only | Placeholder UI | Kept |
| `src/views/hall/ActiveTablesView.vue` | "Mock timers and requests" comment | Comment/visual text; data now from `hall_list_tables` | False positive / needs text cleanup | Kept |
| `src/views/kitchen/KitchenExpoView.vue` | imports `mockExpoData`, insert demo order functions | Kitchen Expo not in active router, but production file exists | Legacy/unrouted or future module risk | Kept; needs future cleanup before routing |
| `src/views/kitchen/KitchenInventoryView.vue` | mock suppliers/alerts/expiring count | Kitchen inventory mock UI | Production risk if route enabled | Kept; outside current Hall/Customer/CRM scope |
| `src/views/FloorPlanView.vue` | imports `@/lib/mock-data` | Root legacy demo view | Legacy/unrouted mock | Kept |
| `src/views/ListView.vue` | imports `@/lib/mock-data` | Root legacy demo view | Legacy/unrouted mock | Kept |
| `src/views/TimelineView.vue` | imports `@/lib/mock-data` | Root legacy demo view | Legacy/unrouted mock | Kept |
| `src/lib/mock-data.ts` | branch/table/reservation/menu mock data | Demo data file | Legacy/dev data | Kept; not used by primary router paths reviewed |
| `src/data/menuData.ts` | static menu data | Used by legacy customer and ReceptionOrder UI | Production risk | Kept; ReceptionOrder needs DB-driven catalog refactor |
| `src/views/superadmin/SuperadminDashboardView.vue` | mocked rating | Superadmin production route has fake metric | Production mock | Needs follow-up |
| `src/stores/restaurantStore.ts` | `Math.random` ID | Random local id generation | Production risk unknown | Needs follow-up |
| `src/composables/useAuth.ts` | mock auth gate | Dev-only mock auth allowed by placeholder URL or env | Dev-only mock | Kept; default with real URL should not silently mock |
| `src/views/purchasing/POCreateView.vue` | `mockItem` form state | Variable name for form draft | False positive / naming risk | Kept |
| `supabase/migrations/*seed*` | sample/seed data | Local/dev seed | Seed/dev data | Kept |
| `docs/**`, `README.md`, `PROJECT_OVERVIEW.md`, `PLAN_VOUCHER_MEMBERSHIP.md` | mock/demo/sample references | Documentation only | Docs | Kept |
| `scripts/_archive/**` | mock cleanup scripts | Archived scripts | Archive | Kept |

## No-mock runtime test

Added `e2e/no-mock-runtime.spec.ts`.

Covered:

- Router no longer exposes legacy mock customer flow.
- Tablet checkout no longer uses fake order id or direct checkout.
- Kitchen KDS no longer auto-loads mock tickets.

Result: **Pass**

## Decision

No production mock data gate: **Fail**

Reason: key Customer/Tablet/KDS mock issues were fixed, but additional production-route or potentially routed modules still contain mock/static/demo data and require follow-up.
