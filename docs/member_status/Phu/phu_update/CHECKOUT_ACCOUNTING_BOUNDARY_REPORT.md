# Checkout Accounting Boundary Report

## Current flow

```text
Hall opens checkout
-> hall_get_checkout_summary calculates summary from DB order_items
-> Hall selects payment method
-> process_checkout creates bill/payment/revenue
-> CRM survey link runs during checkout if survey exists
```

## What is safer now

- `ReceptionCheckoutView` uses `hall_get_checkout_summary` instead of joining table/order/order_items in frontend.
- `useCheckout.previewCheckout` no longer returns client-side estimated totals.
- `TabletCheckoutView` no longer tries direct checkout with fake order id; it creates `REQUEST_BILL` for Hall.
- `process_checkout` remains the final backend boundary.

## Current risks

- `process_checkout` still needs full audit against Accounting requirements.
- Close shift/payment summary still has direct DB access and is not production-ready.
- Voucher/discount permission/rule engine is partial.
- Some accounting dashboard reads are not strict RPC yet.
- E2E final checkout with DB assertions is skipped because test seed/auth data is missing.

## Gate checks

| Gate | Result | Evidence |
| --- | --- | --- |
| Build | Pass | `npm run build` |
| Local migration reset | Pass | `supabase db reset --local` |
| Checkout summary RPC exists | Pass | `hall_get_checkout_summary` migration applied |
| Final checkout E2E | Skipped | Needs seeded order/payment fixtures |
| Accounting production readiness | Fail | close shift and accounting boundary still need audit |

## Decision

Checkout boundary: **Partial / Not production-ready**

Ready for staging DB push: **No**, because remote migration history is currently out of sync.

Ready for production: **No**, because full checkout/accounting E2E and close shift audit are not complete.
