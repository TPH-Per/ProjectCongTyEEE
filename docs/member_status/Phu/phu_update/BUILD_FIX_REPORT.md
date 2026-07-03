# Build Fix Report

## Commands

```bash
npm run typecheck
npm run lint
npm run build
```

## Results

- `npm run typecheck`: Fail, script does not exist.
- `npm run lint`: Fail, script does not exist.
- `npm run build`: Pass. This script runs `vue-tsc -b && vite build`, so TypeScript build checking is covered by build.

## Build output

Final build:

```text
✓ built
```

Warnings:

- Bundle chunk larger than 500 kB.
- Plugin timing warning from Vite/Rolldown.

These are not deploy blockers but should be optimized later.

## Fix table

| Error area | File | Cause | Fix applied | Result |
| --- | --- | --- | --- | --- |
| Duplicate locale keys | `src/locales/vi.ts` | Duplicate `reception_order.*` keys | Removed duplicate trailing keys | Pass |
| Duplicate language store keys | `src/stores/useLanguageStore.ts` | Repeated Purchasing/Accounting/CRM/Marketing/BOD keys per locale | Removed duplicate blocks | Pass |
| Accounting composable contract | `src/composables/useAccounting.ts` | Views called missing methods | Added `getProfitLoss`, `fetchProfitLoss`, tax record methods | Pass |
| BOD composable contract | `src/composables/useBOD.ts` | Views called missing methods/state | Added `getAuditLogs`, `fetchBODApprovals`, `branchPerformance`, `fetchBranchPerformance` | Pass |
| Purchasing composable contract | `src/composables/usePurchasing.ts` | View called `fetchPurchaseOrders` | Added read method and state | Pass |
| Legacy customer store | `src/stores/customerStore.ts` | Missing `loading`, `updateCartItemNote` | Added minimal state/action | Pass |
| Feedback rating type | `src/views/customer/Feedback.vue` | `number` not assignable to `1 | 2 | 3 | 4 | 5` | Normalized/cast rating | Pass |
| Hall checkout branch id | `src/views/hall/CheckoutView.vue` | `activeBranchId` can be undefined | Added branch guard before checkout | Pass |
| Legacy mock customer route | `src/router/index.ts` | `/customer` public route imported mock-backed customer views | Redirected `/customer` to `/tablet/idle`; removed imports | Pass |
| KDS mock queue | `src/views/kitchen/KitchenKDSView.vue` | Auto-loaded mock tickets/grill requests | Removed mock import and auto-load calls | Pass |
| Tablet checkout fake order | `src/views/tablet/TabletCheckoutView.vue` | Used `mock-order-id-checkout` and direct checkout | Replaced with `REQUEST_BILL` service request | Pass |
| Unsafe checkout preview | `src/composables/useCheckout.ts` | Client-side checkout estimate from frontend total | Disabled function and directed callers to `hall_get_checkout_summary` | Pass |
| Accounting dashboard fake visuals | `src/views/accounting/AccountingDashboardView.vue` | Random chart/fake recent transactions | Replaced with deterministic data/empty state | Pass |

## Decision

Build gate: **Pass**

Typecheck/lint standalone scripts: **Not available**
