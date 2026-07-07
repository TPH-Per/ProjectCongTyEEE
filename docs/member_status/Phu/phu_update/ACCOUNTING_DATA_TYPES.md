# Accounting Data Types — 2026-07-03

This is the **one-pager for the accounting team**. Every monetary column in
the POS system is `numeric(N,2)` — never `float`, never `bigint`, never
`integer` — because accounting reconciliation cannot tolerate IEEE-754
rounding drift.

## Why `numeric` and not `bigint` (cents)?

Some teams choose `integer` and store money as a count of the smallest unit
(VND doesn't have minor units, but imagine USD × 100). We deliberately do
NOT do that because:

1. **Form fields are decimal.** Cashier UI accepts `1,234,567đ` typed by
   hand. Multiplication by `quantity` or division by 100 must match what the
   user sees.
2. **SQL `ROUND` / `SUM` behaviour matches what accounting expects.** Postgres
   `numeric` honours `ROUND(col, 2)` deterministically; integer-of-cents
   forces a translation layer that has historically drifted on tax rounding
   edge cases.
3. **Same JS representation.** Frontend uses `Number` for arithmetic and
   `Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' })`
   for display. JSON-marshalled `numeric(14,2)` round-trips as a JS number
   without precision loss for amounts up to ~10¹² — well outside any
   realistic VND column.

## Column inventory

> "All money columns are `numeric(14,2)`." — main migration preamble
> (`20260623000000_setup.sql`). This table is the verification, not the
> introduction.

### `customers`

| Column | Type | Used in |
| --- | --- | --- |
| `total_spent` | `numeric(14,2)` not null default `0` | Updated by `process_checkout` (2026-07-03 fix) |

### `menu_items`

| Column | Type | Used in |
| --- | --- | --- |
| `price` | `numeric(12,2)` not null check `price >= 0` | Read at order add time |
| `unit_price` | `numeric(12,2)` not null check `unit_price >= 0` | Snapshot on `order_items` |

### `packages`

| Column | Type | Used in |
| --- | --- | --- |
| `price` | `numeric(12,2)` not null check `price >= 0` | `packages` |

### `bills` (rebuilt `invoices`)

| Column | Type | Notes |
| --- | --- | --- |
| `subtotal` | `numeric(14,2)` not null default `0` check `>= 0` | |
| `service_charge_amount` | `numeric(14,2)` default `0` | NOW persisted by `process_checkout` |
| `discount_total` | `numeric(14,2)` default `0` | Includes voucher discount |
| `vat_8_amount` | `numeric(14,2)` default `0` | Reduced rate |
| `vat_10_amount` | `numeric(14,2)` default `0` | Standard rate (defaulted for buffets) |
| `grand_total` | `numeric(14,2)` not null check `>= 0` | The cashier UI displays this verbatim |

### `bill_items`

| Column | Type | Notes |
| --- | --- | --- |
| `line_total` | `numeric(14,2)` not null check `>= 0` | `quantity * unit_price` rounded to 2 dp |

### `order_items`

| Column | Type | Notes |
| --- | --- | --- |
| `subtotal` | `numeric(14,2)` not null default `0` | Snapshot at add time |
| `total` | `numeric(14,2)` not null default `0` check `>= 0` | Used by older paths; mirrored to `bill_items.line_total` |

### `payments`

| Column | Type | Notes |
| --- | --- | --- |
| `amount` | `numeric(14,2)` not null check `> 0` | Cashier-side; can be partial (combined split-pay supported via sum) |
| `received_amount` | `numeric(14,2)` nullable | For cash: tender amount |
| `change_amount` | `numeric(14,2)` default `0` | `received_amount - amount` |

### `vouchers`

| Column | Type | Notes |
| --- | --- | --- |
| `discount_amount` | `numeric(14,2)` not null check `> 0` | For `type='fixed'` vouchers |

### `financial_transactions`

| Column | Type | Notes |
| --- | --- | --- |
| `amount` | `numeric(14,2)` not null check `>= 0` | Expense vs income; `transaction_type` selects sign |

### `shifts`

| Column | Type | Notes |
| --- | --- | --- |
| `opening_cash`, `closing_cash`, `expected_cash`, `cash_difference` | `numeric(14,2)` | Derived from cash payments on close |

## Where the math happens

| Computation | Where | Notes |
| --- | --- | --- |
| `subtotal` | `process_checkout` / `add-order-item` / `hall_get_checkout_totals` | DB-computed; cashier UI is read-only |
| Voucher validation | `validate_voucher` SQL function | Reused by `process_checkout` (was missing before 2026-07-03) |
| Service charge | `process_checkout` (`v_service_charge := round(v_net * 0.05, 2)`) | 5 % on net — matches frontend |
| VAT | `process_checkout` (`v_vat_amount := round(v_net * v_vat_rate, 0)`) | Rounded to whole VND — `numeric(14,2)` carries zero |
| Grand total | `process_checkout` (`v_grand_total := round(v_net + v_service_charge + v_vat_amount - v_voucher_discount, 0)`) | The single number printed on the receipt |

## What is NOT a money column?

- `quantity` is always `integer` (never sub-units in this system).
- `customer_id`, `branch_id`, etc. — `uuid`.
- `current_points`, `points_to_use` — `integer`.
- `metadata` JSON columns may carry legacy VND strings; do NOT rely on them
  for accounting queries. Only the typed columns count.

## Accounting reconciliation query

The full per-shift breakdown:

```sql
SELECT
  b.branch_id,
  COUNT(*) FILTER (WHERE b.status = 'PAID') AS paid_bills,
  SUM(b.grand_total) FILTER (WHERE b.status = 'PAID') AS revenue,
  SUM(b.vat_8_amount + b.vat_10_amount) FILTER (WHERE b.status = 'PAID') AS vat_collected,
  SUM(b.discount_total) FILTER (WHERE b.status = 'PAID') AS discount_total
FROM public.bills b
WHERE b.created_at::date BETWEEN :from AND :to
GROUP BY b.branch_id;
```

`get_executive_dashboard` runs essentially this; documentation comment
on the function points future maintainers to KEEP the LEFT-JOIN aggregates
inside the branch-filter subquery (no cross-branch leak).
