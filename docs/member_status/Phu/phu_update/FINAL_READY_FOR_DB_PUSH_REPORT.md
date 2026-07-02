# Final Ready For DB Push Report

## Final Decision

Ready for staging DB push: **NO**

Ready for production DB push: **NO**

## Reason

- Remote migration history is out of sync with local migration files.
- `supabase db push --dry-run --linked` failed.
- Full Customer/Hall/CRM/Checkout E2E flows are not passing yet; they are currently skipped pending seeded auth/test data.
- Mock data audit still has remaining production risk areas outside the exact fixes applied.
- Accounting/close shift boundary is not production-ready.

## Checks

| Gate | Result | Evidence |
| --- | --- | --- |
| Build | Pass | `npm run build` passed |
| Typecheck | Pass via build / No standalone script | `vue-tsc -b` runs inside build; `npm run typecheck` missing |
| Lint | Not run | `npm run lint` missing |
| Supabase local reset | Pass | `supabase db reset --local` passed |
| Supabase lint | Pass with warnings | `supabase db lint --local` warnings only |
| Supabase diff | Pass | `supabase db diff --local`: no schema changes |
| Supabase dry-run | Fail | `supabase db push --dry-run --linked`: remote migration versions missing locally |
| E2E | Partial | `npx playwright test`: 5 passed, 9 skipped |
| No production mock | Fail | Key issues fixed, but remaining mock/static risks exist |
| Customer flow | Partial | `/tablet` RPC flow exists; full E2E skipped |
| Hall flow | Partial | RPC baseline exists; full E2E skipped |
| CRM regression | Partial | Migration/build pass; full CRM E2E skipped |
| Checkout boundary | Partial / Fail for production | Summary RPC exists; final accounting E2E skipped |

## Remaining Risks

- Remote migration mismatch must be reconciled before push.
- `ReceptionOrderView` still uses static `menuData`/mock options for UI catalog.
- Legacy mock files remain in repo, though `/customer` is no longer routed.
- Kitchen Expo/Inventory modules still contain mock/demo data and should not be treated as production-ready.
- Close shift/payment summary needs Strict RPC cleanup.
- Voucher/discount needs permission/rule audit.

## Exact command recommendation

Do **not** push yet.

Next steps:

```bash
supabase migration list --linked
supabase db pull
```

Then compare pulled remote migrations against repo history. Only after review, consider a targeted repair if the team confirms those remote migrations should be marked reverted:

```bash
supabase migration repair --status reverted 20260701000005 20260701000006 20260701093424
```

After history is reconciled:

```bash
supabase db reset --local
supabase db lint --local
supabase db diff --local
supabase db push --dry-run --linked
npm run build
npx playwright test
```

Only if all gates pass should staging DB push be considered.
