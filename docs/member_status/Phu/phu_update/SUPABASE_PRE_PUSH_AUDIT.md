# Supabase Pre-Push Audit

## Local migration status

Command:

```bash
supabase migration list --local
```

Result: **Failed readiness due remote/local mismatch.**

Observed from `supabase migration list --linked`:

- Local has migrations not applied remotely:
  - `20260701000002`
  - `20260701000003`
  - `20260701000004`
  - `20260702044658`
  - `20260702083325`
- Remote has migrations missing locally:
  - `20260701000005`
  - `20260701000006`
  - `20260701093424`

Dry-run reported the same remote versions not found locally.

This must be reconciled before any DB push.

## Local reset result

Command:

```bash
supabase db reset --local
```

Result: **Pass**

Notes:

- All local migrations applied successfully.
- `supabase/seed.sql` warning: no files matched pattern. There is also `supabase/migrations/seed.sql`, but Supabase skips it because it does not match migration filename format.

## DB lint result

Command:

```bash
supabase db lint --local
```

Result: **Pass with warnings**

Warnings:

- `public.submit_tablet_order`: unused parameter `p_session_id`.
- `public.update_kitchen_ticket`: never read variable `v_current_status`, unused parameter `p_staff_id`.
- `public.record_expense_payment`: never read variable `v_po`.

These are existing warnings and should be cleaned before production hardening, but they did not fail local lint.

## DB diff result

Command:

```bash
supabase db diff --local
```

Result: **Pass**

Evidence:

```text
No schema changes found
```

## Remote dry-run result

Command:

```bash
supabase db push --dry-run --linked
```

Result: **Failed**

Reason:

```text
Remote migration versions not found in local migrations directory.
```

Supabase CLI suggested:

```bash
supabase migration repair --status reverted 20260701000005 20260701000006 20260701093424
supabase db pull
```

Do not run repair/pull blindly. First compare remote migration history with Git history/team changes.

## Migration history risks

- Local repo and linked remote are not in sync.
- Pushing now could fail or create confusing migration history.
- Production push is not safe.
- Staging push is also not ready until remote history is reconciled.

## RPC/security review

Reviewed new CRM/Hall/Customer migrations:

- DB changes are versioned in `supabase/migrations`.
- New RPCs use `CREATE OR REPLACE FUNCTION`.
- Sensitive RPCs use `SECURITY DEFINER` with `SET search_path`.
- New `tablet_order_submissions` has RLS enabled.
- Order submit RPCs calculate price from `menu_items`, not frontend totals.
- Checkout finalization still goes through `process_checkout`.
- `hall_get_checkout_summary` calculates summary from DB/order items.

Known gaps:

- Some old functions have lint warnings.
- Some accounting/purchasing/BOD views/composables still use direct table reads for non-core reports.
- Close shift/payment summary still needs strict RPC review.
- Security definer functions should be reviewed with Supabase advisors before production.

## Decision

- Ready for staging DB push: **No**
- Ready for production DB push: **No**

Primary blocker: remote/local migration history mismatch.
