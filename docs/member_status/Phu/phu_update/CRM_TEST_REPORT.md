# CRM Test Report

## Static Checks

### `rg` direct Supabase query check

Command:

```bash
rg -n "supabase\\.from|\\.from\\(" src/views/crm src/views/staff/StaffInDiningCRMView.vue src/composables/useCRM.ts
```

Result: pass. No direct `.from(...)` query remains in the touched CRM views/composable.

### Migration syntax rollback check

Command used Node `pg` to run:

```text
BEGIN;
<20260702044658_crm_serving_table_surveys.sql>
ROLLBACK;
```

Result: pass.

Output:

```text
migration syntax rollback ok
```

### Supabase DB lint

Command:

```bash
supabase db lint --local
```

Result: pass with existing warnings unrelated to this CRM migration.

Warnings:

- `public.submit_tablet_order`: unused parameter `p_session_id`
- `public.update_kitchen_ticket`: unused variable `v_current_status`, unused parameter `p_staff_id`
- `public.record_expense_payment`: unused variable `v_po`

### Build

Command:

```bash
npm run build
```

Result: fail due existing project-wide TypeScript issues outside this CRM update.

CRM-specific errors found earlier in `FeedbackManagerView` were fixed. Remaining errors include:

- Duplicate keys in `src/locales/vi.ts`
- Duplicate keys in `src/stores/useLanguageStore.ts`
- Accounting/BOD composable contract gaps
- Customer/tablet store contract gaps
- Reception dashboard reservation API mismatch
- Several existing type mismatches in reception order flow

## Functional Review

The implementation supports these flows at RPC level:

- Load serving tables: `crm_list_serving_tables`
- Mark in progress: `crm_mark_survey_in_progress`
- Submit survey: `crm_submit_table_survey`
- Mark refused: `crm_refuse_table_survey`
- Skip: `crm_skip_table_survey`
- Link bill after checkout: `crm_link_surveys_to_bill`
- Expire stale surveys: `crm_expire_old_surveys`

Full browser E2E was not run because the project build is blocked by unrelated TypeScript errors.

## Edge Case Checklist

- [x] Survey is keyed by `order_id` / `table_assignment_id`, not `table_id`.
- [x] `table_id` is display context only.
- [x] One active survey per order via partial unique index.
- [x] One active survey per table assignment via partial unique index.
- [x] Old assigned/in-progress surveys can be expired.
- [x] Checkout does not require CRM survey.
- [x] Checkout links existing survey by `order_id`.
- [x] Survey can be saved without phone/customer.
- [x] Phone is normalized before matching Guest DB.
- [x] Customer refused status is separate from not asked.
- [x] Skipped status is separate from not asked.
- [x] Branch access is checked inside RPC.
- [x] RLS is enabled on `crm_surveys`.

## Remaining Risks

- Local migration history is out of sync with three old CRM stash migration versions: `20260701115538`, `20260701121659`, `20260701121924`. I did not repair migration history automatically.
- Build cannot fully pass until existing non-CRM TypeScript issues are fixed.
- Browser-level UX validation should be run after the build is unblocked.
