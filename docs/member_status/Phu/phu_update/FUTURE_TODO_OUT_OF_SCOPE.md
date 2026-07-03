# Future TODO — Out of Scope (Tier P3)

This list captures work that was **deliberately deferred** during the
2026-07-03 quality-bar pass. Items here are real features, not bugs — but
each needs its own spec, design, and migration before implementation. Keep
the file current; tick off items as new specs land.

---

## 1. Cashier item-level void

- **What.** Allow cashier / manager to void a single `order_items` row from
  the order screen with a manager-PIN override.
- **Why now.** Requires a `voided_at`, `voided_by`, `void_reason` audit
  trail plus a reversal entry in `bills` (negative `line_total`). Touches
  `grand_total` flow → conflict with current `process_checkout` shape.
- **Owner.** TBD — needs cashier + accounting sign-off.

## 2. Split bill (multi-tender)

- **What.** Pay a single `bills` row across multiple methods (or split by
  guests — "Table of 4, each pays their own").
- **Why now.** Needs `bill_splits` table (or similar) + a new
  `process_split_checkout` RPC. The current `process_checkout` is
  monolithic.
- **Owner.** TBD — design first.

## 3. Merge table

- **What.** Reception moves guests from table A to table B mid-session,
  combining orders + bill.
- **Why now.** Requires a `table_session_merge_log` audit + an RPC that
  re-points `order_items.table_id` and updates `tables.status` atomically.
  Edge cases: in-flight KDS tickets for the source table.
- **Owner.** TBD.

## 4. Top-dishes / voids / daily-revenue reporting RPCs + view

- **What.** Read-optimised `dashboard.top_dishes_7d`, `dashboard.voids_today`,
  `dashboard.daily_revenue_30d`.
- **Why now.** Either define them in SQL (one migration) or accept they're
  computed in the Edge Function / supabase-js each call. Both options need
  a perf decision.
- **Owner.** TBD — coordinate with `useReport`.

## 5. Drop legacy `invoices` table

- **What.** The schema-hardened `invoices` is now the single source of
  truth. The legacy `invoices` table (with `subtotal/vat/discount/total`)
  is unreferenced by code as of 2026-07-03 but still exists in the schema.
- **Why now.** Dropping requires a backfill of any new-column values into the
  rebuilt table; mid-operation, that's unsafe.
- **Owner.** Migration lead.

## 6. `tables.status='reserved'` enum value wiring

- **What.** The DB enum accepts `'reserved'`, but the floor view currently
  derives "Reserved" from booking overlap (`simulatedAreas`). A real DB row
  → UI binding would simplify things.
- **Why now.** Requires a reservation lifecycle that writes/clears the
  status atomically with `table_assignments`.
- **Owner.** TBD.

## 7. `reservation_time` SLA monitoring

- **What.** Cron job that flips `crm_surveys.status` → `expired` if the
  guest leaves without the cashier asking within, say, 30 minutes.
- **Why now.** Needs a `pg_cron` job, plus a downgrade path for late
  submissions (`late_submitted` enum value already exists).
- **Owner.** TBD — infra.

## 8. Walk-in dedup without phone

- **What.** Today, two walk-ins with the same name on the same day create
  two `customers` rows (because we dedupe on `phone` only).
- **Why now.** Needs fuzzy name match + branch-scoped merge UI for the
  rare double-entry case.
- **Owner.** TBD — receptionist UX.

## 9. `/customer/*` mock views

- **What.** The customer-facing tablet / QR views are mocked per
  `HALL_CUSTOMER_UPDATED_PLAN.md` §5.
- **Why now.** Out of scope until product decides on the customer-experience
  surface (loyalty sign-up? order tracking? feedback only?).
- **Owner.** Product.

## 10. Code-splitting the Vite bundle

- **What.** The 1.8 MB `index-*.js` chunk triggers a rollup warning today.
- **Why now.** Requires either route-level dynamic imports (changes SSR /
  test shape) or a vendor/feature split. Both need a deliberate decision.
- **Owner.** TBD — frontend lead.

---

## How to add a new "out of scope" item

1. Add a numbered section above with: `What. / Why now. / Owner.`
2. Link the matching migration / file if any side work exists.
3. If the work is later picked up, **move the section into the active plan**
   instead of editing in place — keep this file as the "deferred" backlog.

---

_Last updated: 2026-07-03 (Phase F of quality-bar pass)._
