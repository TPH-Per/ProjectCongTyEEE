# CRM Regression Report

## Scope

Reviewed CRM state after Hall/Customer/Checkout fixes.

Relevant CRM files:

- `src/views/crm/CRMServingTablesView.vue`
- `src/composables/useCRM.ts`
- `src/composables/useCheckout.ts`
- `supabase/migrations/20260702044658_crm_serving_table_surveys.sql`

## Regression expectations

- Survey attaches to current order/session, not `table_id` as primary identity.
- Old survey does not appear as pending for new table session.
- Refused/skipped/completed statuses are distinct.
- Checkout links survey to bill if survey exists.
- Checkout does not require CRM survey.

## Checks performed

| Check | Result | Evidence / Note |
| --- | --- | --- |
| Build after CRM changes | Pass | `npm run build` passed |
| Migration reset with CRM migration | Pass | `supabase db reset --local` passed through `20260702044658_crm_serving_table_surveys.sql` |
| RPC lint | Pass with warnings outside CRM | `supabase db lint --local` did not report CRM function warnings |
| CRM E2E | Skipped | Needs seeded active order/table and CRM auth |

## Decision

CRM regression gate: **Partial**

CRM implementation remains structurally sound, but full CRM E2E was not executed. Do not mark CRM production-ready until seeded E2E verifies survey submit/refused/skipped/checkout-link on a live local/staging DB.
