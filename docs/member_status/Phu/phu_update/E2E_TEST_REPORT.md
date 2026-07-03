# E2E Test Report

## Commands

```bash
npx playwright install chromium
npx playwright test
```

## Result

Final run:

```text
14 tests
5 passed
9 skipped
```

The skipped tests are business-flow skeletons that require seeded authenticated users, branch/table/session/order data and DB assertions.

## Test cases

| Test case | Expected | Result | Evidence / Note |
| --- | --- | --- | --- |
| Login page renders | Login UI visible | Pass | Existing `e2e/auth.spec.ts` |
| Invalid login fails | Error shown | Pass | Existing `e2e/auth.spec.ts` |
| No mock runtime - customer route | `/customer` does not expose legacy mock flow | Pass | `e2e/no-mock-runtime.spec.ts` |
| No mock runtime - tablet checkout | No fake order id/direct checkout | Pass | `e2e/no-mock-runtime.spec.ts` |
| No mock runtime - KDS | No auto-loaded mock tickets | Pass | `e2e/no-mock-runtime.spec.ts` |
| Reservation -> seat guest | Table/session/reservation state correct | Skipped | Requires seeded auth/test data |
| Tablet menu | Menu loads from DB | Skipped | Requires seeded auth/tablet context |
| Tablet cart | Cart total self-calculated | Skipped | Requires seeded menu/session |
| Tablet submit order | Order/order_items created, no duplicate | Skipped | Requires DB setup and assertions |
| Hall/Kitchen receive order | Order appears in Hall/KDS | Skipped | Requires seeded active order |
| Service request | OPEN -> IN_PROGRESS -> RESOLVED | Skipped | Requires active tablet session and Hall auth |
| Checkout request | Customer only requests checkout | Skipped | Requires active tablet session |
| CRM survey regression | Survey attaches to order/session and links bill | Skipped | Requires active order and checkout seed |
| Checkout summary/final checkout | Summary from DB, bill/payment created | Skipped | Requires order items and payment assertions |
| Voucher/discount | Valid/invalid vouchers handled | Skipped | Voucher engine still partial |
| Modify order item | Valid actions allowed, locked items blocked | Not implemented | Documented TODO |
| Merge table | No session/order loss | Not implemented | Documented TODO |
| Split bill | No manual total/double charge | Not implemented | Documented TODO |
| Full flow smoke | Reservation -> checkout consistent | Skipped | Needs seeded E2E environment |

## E2E files added

- `e2e/customer-tablet.spec.ts`
- `e2e/hall-reception.spec.ts`
- `e2e/crm-regression.spec.ts`
- `e2e/checkout-boundary.spec.ts`
- `e2e/no-mock-runtime.spec.ts`

## Decision

E2E gate: **Partial / Not production-ready**

Reason: baseline tests pass, but core business flows are skipped until proper seed/auth/test fixtures are available.
