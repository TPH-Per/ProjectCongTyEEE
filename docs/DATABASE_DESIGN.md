# NGƯU CÁT — Database Design Rationale

> Companion to `DATABASE_SCHEMA.sql`.
> Explains *why* each table is shaped the way it is, so adding new functions later doesn't require re-architecting.

---

## 0. Scope

**In scope (this plan):** POS functions for NguuCat branches — ordering, payment, table management, basic reports.

**Out of scope (deferred to future phases):**
- Multi-brand support
- Group-wide consolidation
- HR integration
- Inventory integration with external systems

When those features land, they fit into the same two-tier pattern documented below.

---

## 1. The single design rule

Every table is EITHER a **HIGH-consistency** table OR a **LOW-consistency** table. There is no in-between.

| Tier | Rule | Consequence if data is wrong |
|---|---|---|
| **HIGH** | FK + CHECK + UNIQUE enforced. Money, identity, booking graph. | Lost money, broken history |
| **LOW**  | Stored as a table, but **NO foreign keys**. Event / fact / config streams. | Missing log, not lost money |

The DB literally cannot enforce integrity on a LOW table — that's the point. You want to be able to write a notification even if the user has been deleted. You want to be able to write an audit row even if the entity it references is gone.

---

## 2. What goes in each tier

### HIGH-consistency tables (FK-enforced)

These form the core POS data graph. FKs are mandatory:

| Table | Why HIGH | Critical FK chain |
|---|---|---|
| `branches` | Tenant root | — |
| `users` | Auth identity | `id → auth.users`, `branch_id → branches` |
| `zones` | Floor plan structure | `branch_id → branches` |
| `tables` | Bookable resource | `branch_id → branches`, `zone_id → zones` |
| `customers` | CRM / identity | `branch_id → branches` |
| `menu_categories` | Catalog structure | `branch_id → branches` |
| `menu_items` | Catalog (priced) | `branch_id → branches`, `category_id → menu_categories` |
| `reservations` | Booking is the POS entry | `branch_id`, `customer_id`, `created_by` |
| `table_assignments` | "Who is sitting where" | `reservation_id`, `table_id`, `assigned_by` |
| `orders` | Money math starts here | `branch_id`, `reservation_id`, `customer_id`, `created_by`, `served_by` |
| `order_items` | Money math continues | `order_id`, `menu_item_id` + price snapshot |
| `invoices` | Fiscal record | `order_id`, `issued_by` |
| `payments` | Money received | `invoice_id`, `received_by` |
| `deposits` | Pre-payment at booking | `reservation_id`, `received_by` |
| `shifts` | Cashier envelope | `user_id`, `branch_id` |

All HIGH tables:
- Have an `updated_at` column + auto-update trigger
- Are mutable (can be UPDATEd)
- Cascade / restrict rules are picked carefully (e.g. `RESTRICT` on `menu_items` from `order_items` — never lose an order because a menu item was deleted)

### LOW-consistency tables (NO foreign keys)

These are append-only streams. No FKs at all — not even to `branches`. `branch_id` is just a plain UUID column. Multi-tenancy is enforced by **RLS only**, not by the schema.

| Table | Why LOW | What it stores |
|---|---|---|
| `audit_events` | Audit must survive deletion of related entities | Every mutation, with diff in `payload` JSONB |
| `notifications` | Notification history must survive | Outgoing messages with template variables |
| `branch_settings` | Settings are independent key-value pairs | Per-branch configuration |
| `system_events` | Generic event log for the app | Login, page views, errors, feature usage |

All LOW tables:
- Have a `created_at` (no `updated_at` — events are immutable)
- Can be SELECTed, JOINed, even JOINed against HIGH tables (using `entity_id = orders.id`) — the DB just won't *enforce* the relationship
- Are write-fast (no FK check overhead)
- `actor_id` / `entity_id` / `reservation_id` / `order_id` / `invoice_id` are **plain UUIDs**, never FKs

---

## 3. The snapshot pattern (the trick that keeps reports honest)

Whenever money or identity could mutate after the fact, freeze a copy on the transaction row:

- **`order_items.name_snapshot` + `unit_price`** → if `menu_items.price` changes tomorrow, last week's orders still show what was charged.
- **`invoices.customer_snapshot`** → printed invoices show the customer as they were at the moment of issue.
- **`reservations.customer_snapshot`** → historical timeline views don't break when a customer updates their phone number.

Without this, every report has to LEFT JOIN current data and quietly lies when that data changes. With this, reports are point-in-time correct.

---

## 4. The JSONB pattern (flexibility without losing structure)

Every HIGH table has a `metadata` `jsonb` column. The pattern is:
- **Common, queryable fields** → typed columns
- **Per-row variable fields** → `metadata jsonb`

Examples:
- `reservations.notes` (free text, never the same twice) → JSONB
- `menu_items.modifiers` (each item has different add-on shape) → JSONB
- `menu_items.metadata` — used for `package_type:'buffet'`, `item_limit:53`, `duration_minutes:120`, `vip_only:true`, etc. (see AdminMenusView: "Set Biz 1200k", "Buffet Wagyu 1380k")
- `order_items.modifiers` (the actual choice the customer made) → JSONB
- `payments.metadata` (gateway response, varies by provider) → JSONB
- `branches.metadata` is **not** used — config lives in `branch_settings` (LOW table) so we can add keys without touching the `branches` row

JSONB columns get **GIN indexes only when the UI searches them**. Don't pre-index.

---

## 5. Multi-tenancy via `branch_id` + RLS

Every table has `branch_id` (typed column for HIGH, plain uuid for LOW). RLS policies scope by branch using the helper:

```sql
create or replace function public.current_branch_id()
returns uuid language sql stable security definer as $$
  select branch_id from public.users where id = auth.uid()
$$;
```

So every policy is a one-liner:

```sql
create policy "branch read reservations" on public.reservations
  for select using (branch_id = public.current_branch_id());
```

Helper functions also included in the schema:
- `public.current_user_id()` → `auth.uid()`
- `public.current_branch_id()` → caller's branch
- `public.has_role(roles[])` → role check for policies

---

## 6. How to extend the database for a new function (POS scope)

This is the key promise: **you should be able to ship a new feature without writing a migration that touches existing tables**.

| New feature type | Where it goes | Migration needed? |
|---|---|---|
| New domain entity with strong identity (e.g. `suppliers`, `inventory_items`) | New HIGH table with FKs | One CREATE TABLE |
| New per-row variable field on existing entity | Add a JSONB key to the existing `metadata` column | **None** |
| New per-row field that needs indexing | Add a typed column | One ALTER TABLE |
| New polymorphic tag (tag a customer AND a reservation) | Use existing `*.tags` JSONB | **None** |
| New kind of audit event | Insert a row in `audit_events` with a new `action` string | **None** |
| New notification template | Insert a row in `notifications` with a new `template` string | **None** |
| New per-branch config (e.g. printer fleet, marketing cost ledger, KPI targets) | Insert a row in `branch_settings` | **None** |
| New status / role value | Add value to ENUM | One `ALTER TYPE ... ADD VALUE` |
| New money flow (refunds) | Either add a HIGH table, or add to `payments` with `method='refund'` + status flag | Either way, small |
| Cost data for COGS/margin reporting on menu items | `menu_items.cost` (numeric(12,2), already in schema) | **None** (already there) |

**Rule of thumb:**
- *If losing referential integrity would cost money* → new HIGH table with FKs.
- *If losing it would only cost a feature flag* → JSONB column or LOW table, no migration.

### Worked examples

**Example 1: Add a "table-turn-time" stat (low effort, no migration)**
- Add a row to `audit_events` every time a `table_assignments` row is released, with `action='table.released'` and `payload={"turn_time_seconds": 4500}`.
- Query directly. No schema change.

**Example 2: Add a "VIP-only menu" filter (low effort, no migration)**
- Add a JSONB key to the `metadata` column of `menu_items`: `metadata: {vip_only: true}`.
- Filter the API call with `metadata->>'vip_only' = 'true'`.

**Example 3: Add a "kitchen display" feature (medium effort, one new table)**
- New HIGH table `kitchen_tickets` (FK → order, FK → branch, FK → user) with status enum.
- Or, simpler: reuse `order_items.status` (`'Pending' → 'Preparing' → 'Served'`), subscribe to Realtime, no new table.

**Example 4: Add a "split bill" feature (medium effort, small migration)**
- Reuse the existing `invoices` + `payments` chain — already supports N payments per invoice. No schema change.

**Example 5: Add a "customer notes timeline" (low effort, no migration)**
- Add a row to `audit_events` with `entity_type='customer'`, `entity_id=customer.id`, `action='customer.note_added'`, `payload={"note": "..."}`.
- Query: `SELECT created_at, payload->>'note' FROM audit_events WHERE entity_type='customer' AND entity_id=$1 ORDER BY created_at DESC`.

---

## 7. Money handling rules (HIGH table invariants)

- All amounts are `numeric(14,2)` — never `float`.
- VAT rate lives in `branches.vat_rate` (default) and can be overridden per `orders.vat_rate`.
- Subtotal / VAT / total are **stored** (not just computed) so reconciliation reports match what's on the receipt.
- `CHECK (amount > 0)` / `CHECK (quantity > 0)` / `CHECK (capacity > 0)` / `CHECK (line_total >= 0)` everywhere — refuse nonsense at the DB level.
- Split payments supported: many `payments` rows can point to one `invoice` (e.g. half cash + half card).
- `received_amount` / `change_amount` on `payments` lets us store exact cash math without breaking the `amount > 0` invariant.

---

## 8. Audit (LOW `audit_events`)

One row per mutation. Payload is JSONB so we don't need a new column every time we add a feature:

```jsonc
// reservation.status changed
{ "from": "Pending", "to": "Arrived", "by": "Nguyễn Văn A" }

// table.assigned
{ "tables_added": ["A01","A02"], "tables_removed": [] }

// payment.received
{ "method": "cash", "amount": 560000, "received": 600000, "change": 40000 }

// customer.note_added
{ "note": "Asked for window seat next time" }

// system.error
{ "code": "PDF_RENDER_FAIL", "message": "...", "stack": "..." }
```

Filterable by `entity_type` + `entity_id` for "show me everything that happened to reservation `SF_00001729`".

This is the LOW pattern at work: `actor_id`, `entity_id`, etc. are **plain UUIDs, not FKs** — so the audit log keeps working even after entities are deleted.

---

## 9. Realtime (Supabase)

Only the **volatile, multi-user** tables need Realtime subscription:

| Table | Why subscribe |
|---|---|
| `reservations` | New bookings appear live on the manager timeline |
| `tables`, `table_assignments` | Staff floor-plan reflects check-ins instantly |
| `orders`, `order_items` | Kitchen sees new items immediately |
| `notifications` | Real-time notification panel for staff |

Everything else (reports, settings, audit) is fine as request/response.

Always:
1. `alter publication supabase_realtime add table …` for each.
2. Subscribe with `filter: branch_id=eq.…` from the client (never subscribe to whole tables).

---

## 10. What this design intentionally does NOT have (yet)

- **Inventory** — out of scope per the plan; when needed, it will be its own HIGH table (similar shape to `menu_items`) plus a HIGH `inventory_txns` table. **However**, `menu_items.cost` (numeric) is already stored so ManagerCOGSView can show per-item cost without needing the full inventory subsystem first.
- **Recipes / BOM** — when needed, a join table between `menu_items` and inventory.
- **Marketing / promotions** — `orders.discount` already exists for ad-hoc discounts. A full campaign engine can come later as a new HIGH table (FK → branches) or LOW table for ad-hoc event tracking.
- **Customer reviews** — when added, will be a new HIGH table.
- **Printers / KDS** — live in `branch_settings` as JSONB until a printer fleet feature is needed.
- **Loyalty ledger** — points live in `customers.preferences.loyalty` JSONB; when a proper earn/burn ledger is needed, promote to a HIGH table.
- **Multi-brand / group integration** — out of scope. When needed, will add a `brands` HIGH table and a `brand_id` column to relevant tables; the two-tier pattern still applies.
- **VIP-only menu filter** — implemented via `menu_items.metadata->>'vip_only' = 'true'` (no migration needed).
- **CRM media consent / marketing channel capture at table** — stored as `audit_events` rows with `entity_type='table_assignment'` and `payload: {channel, media_consent, voucher_issued}`. No schema change.

Each of these is intentionally out of scope until the UI actually queries it. Adding tables you don't read is just storage you don't use.

---

## 11. Coverage matrix (View → Schema)

Verified against `src/views/` (27 view files across 5 roles) and `src/lib/mock-data.ts`:

| View | Required data | Covered by | Tier | Status |
|---|---|---|---|---|
| **ADMIN** | | | | |
| AdminDashboardView | Headline KPIs | aggregated from `orders`, `payments`, `reservations` | derived | ✅ |
| AdminAccountsView | User CRUD | `users` | HIGH | ✅ |
| AdminMenusView | Menu CRUD + packages | `menu_categories`, `menu_items` | HIGH | ✅ |
| AdminFloorsView | Drag-drop floor plan | `zones`, `tables` | HIGH | ✅ |
| AdminKPIView | KPI/KGI config (placeholder) | future `branch_settings` keys | LOW | ✅ |
| AdminAuditView | Audit log list | `audit_events` | LOW | ✅ |
| **MANAGER** | | | | |
| ManagerDashboardView | Aggregates | derived | derived | ✅ |
| ManagerRevenueView | Revenue by day / meal type / channel | `orders`, `payments`, `invoices` + `branch_settings.report_segments` | HIGH + LOW | ✅ |
| ManagerCOGSView | Per-item cost & margin | `menu_items.cost`, `menu_items.price`, `order_items` | HIGH (extended) | ✅ |
| ManagerMarketingView | Channel attribution, cost input | `audit_events` (channel capture) + `branch_settings` (cost history) | LOW | ✅ |
| ManagerCRMView | Customer segmentation, repeat rate, demographics | `customers` + aggregated `orders` | HIGH | ✅ |
| ManagerInventoryView | Daily inventory × SKU | OUT OF SCOPE per plan §0 | — | ⛔ Deferred |
| **RECEPTION** | | | | |
| ReceptionDashboardView | Tables needing checkout | `table_assignments` (open rows) + `orders.status` | HIGH | ✅ |
| ReceptionCheckoutView | Membership lookup, totals, pay | `customers` + `orders` + `invoices` + `payments` | HIGH | ✅ |
| ReceptionCloseShiftView | Shift summary, export CSV/Excel | `shifts` + aggregated `payments` | HIGH | ✅ |
| **STAFF** | | | | |
| StaffFloorPlanView | Visual table layout | `zones`, `tables`, `table_assignments` | HIGH | ✅ |
| StaffActiveTablesView | Live dining tables | `table_assignments` (open) + `orders` | HIGH | ✅ |
| StaffOpenTableView | QR-pairing, party size, course | `tables` + `reservations` (or new walk-in) + `audit_events` (crm.capture) | HIGH + LOW | ✅ |
| StaffInDiningCRMView | Marketing channel, photo consent, voucher | `audit_events` (per-table capture) | LOW | ✅ |
| **TABLET** | | | | |
| TabletIdleView | QR + table code | `tables.code` (lookup by code) | HIGH | ✅ |
| TabletLanguageView | Language picker | `branch_settings` (default locale) | LOW | ✅ |
| TabletOrderView | Menu browse, course/limit | `menu_categories`, `menu_items` + `orders`/`order_items` | HIGH | ✅ |
| TabletCheckoutView | Request checkout signal | `audit_events` (`action='table.checkout_requested'`) | LOW | ✅ |

**Legend:** ✅ covered, ⛔ explicitly out of scope (will require schema additions when scope expands).

**Summary:** 26 of 27 views are fully covered. The only gap is `ManagerInventoryView` which is intentionally out of scope per plan §0 (multi-store POS, not inventory management). When inventory is added, it slots in as a HIGH pair (`inventory_items` + `inventory_txns`) without disturbing any existing table.
