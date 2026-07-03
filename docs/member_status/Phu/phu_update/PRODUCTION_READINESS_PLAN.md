# Production Readiness Plan

## Current status

Project đã build được lại sau khi sửa các lỗi TypeScript/blocker. Local Supabase migrations có thể reset/diff sạch. Tuy nhiên project **chưa ready để push DB lên Supabase staging/production** vì remote migration history đang lệch local và E2E nghiệp vụ thật mới có skeleton, chưa có seed/auth data để chạy full flow.

## Files inspected

- `package.json`, `tsconfig*.json`, `vite.config.ts`, `playwright.config.ts`
- `src/router/index.ts`
- `src/views/tablet/*`
- `src/views/hall/*`
- `src/views/reception/*`
- `src/views/staff/*`
- `src/views/crm/*`
- `src/views/kitchen/KitchenKDSView.vue`
- `src/views/accounting/*`
- `src/composables/useAccounting.ts`, `useBOD.ts`, `useCheckout.ts`, `useMenu.ts`, `useReservation.ts`, `useServiceRequest.ts`, `useTable.ts`, `useTablet.ts`, `useCRM.ts`, `usePurchasing.ts`
- `src/stores/customerStore.ts`, `src/stores/useLanguageStore.ts`
- `src/services/customerApi.ts`
- `supabase/migrations/*`
- `docs/member_status/Phu/phu_update/*`

## Current modules found

- Customer/Tablet: `/tablet` is the real DB/RPC-oriented customer tablet flow. Legacy `/customer` was public and mock-backed; it has now been removed from production routing and redirected to `/tablet/idle`.
- Hall/Reception: table list, service request, order submit, reservation status, checkout summary are partially RPC-backed.
- CRM: serving table survey flow exists and is linked to current order/session.
- Kitchen: KDS reads real `orders`/`order_items`, but still has several local UI/HACCP/prep behaviors. Auto-loading mock tickets was removed.
- Checkout: `hall_get_checkout_summary` calculates checkout summary; final checkout still goes through `process_checkout`.
- Accounting boundary: still partial. Build blockers were fixed, but accounting/shift production readiness is not complete.

## What was incomplete

- Build failed due duplicate locale keys and missing composable methods.
- `/customer` legacy route used in-memory mock `customerApi.ts`.
- `KitchenKDSView` auto-loaded mock tickets and mock grill requests.
- `TabletCheckoutView` used a fake order id and attempted checkout directly.
- `previewCheckout` calculated totals on the client from frontend total.
- Playwright browser was missing.
- Remote migration history is out of sync with local migrations.
- Business E2E tests did not exist for Customer/Hall/CRM/Checkout flows.

## What was fixed

- Removed duplicate locale keys in `src/locales/vi.ts` and `src/stores/useLanguageStore.ts`.
- Added missing compile-time contracts in `useAccounting`, `useBOD`, `usePurchasing`.
- Added `loading` and `updateCartItemNote` to `customerStore`.
- Fixed feedback rating type.
- Fixed Hall checkout branch guard.
- Redirected `/customer` to `/tablet/idle` and removed legacy mock customer route imports.
- Removed KDS runtime mock ticket/grill request import and auto-load calls.
- Reworked `TabletCheckoutView` to create `REQUEST_BILL` service request instead of using fake order checkout.
- Disabled unsafe client-side `previewCheckout`; checkout totals must come from `hall_get_checkout_summary`.
- Removed random/mock chart and fake recent transactions from `AccountingDashboardView`.
- Added Playwright business-flow skeleton specs and no-mock runtime checks.

## Intentionally not implemented

- Merge table.
- Split bill.
- Advanced order item modify/cancel workflow.
- Voucher/discount permission engine.
- Accounting ledger/close shift hardening.
- Guest DB automatic enrichment from booking.
- Full Kitchen HACCP/stock/deduction workflow.

## Risk areas

- Remote migration history mismatch blocks safe DB push.
- Several production modules still have mock/demo/placeholder code outside Customer/Hall/CRM baseline.
- Reception order view still uses static `menuData` for UI catalog and maps to real DB ids at submit time.
- Full business E2E needs seeded authenticated users and test fixtures.
- Accounting and close shift are not production-ready.

## Final acceptance checklist

- [x] Build pass.
- [x] Local Supabase reset pass.
- [x] Local Supabase lint pass with warnings.
- [x] Local Supabase diff clean.
- [x] Basic Playwright auth/no-mock runtime pass.
- [x] Docs updated.
- [ ] Remote dry-run pass.
- [ ] Migration history reconciled.
- [ ] Full Customer/Hall/CRM/Checkout E2E pass.
- [ ] No production mock findings across all routed production modules.
- [ ] Accounting/close shift boundary verified.
