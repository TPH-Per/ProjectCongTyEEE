# CRM Schema

## Existing Tables Used

- `customers`: long-term guest database / Marketing profile.
- `reservations`: booking/contact layer.
- `tables`: physical table display context.
- `table_assignments`: seating/session context when available.
- `orders`: primary active dining identity used by CRM.
- `bills`: financial snapshot created at checkout.

## New Customer Fields

Added nullable/additive fields:

- `normalized_phone`
- `source_code`
- `visit_reason`
- `first_visit_at`
- `marketing_consent`
- `marketing_tags`
- `zalo`

## Temporary Booking-To-Guest DB Rule

Guest DB contact data should be sourced from `reservations` only after the booking is confirmed as an actual visit.

Recommended trigger/status sources:

- `Arrived`
- `Dining`
- `Completed`
- equivalent seated/checked-in status if the reservation module changes names

Do not seed Guest DB from:

- `Pending`
- `Cancelled`
- no-show states

This prevents cancelled/no-show bookings from becoming Marketing customer profiles.

Recommended future RPC:

- `crm_seed_guest_from_arrived_reservation(p_reservation_id uuid)`
- or call equivalent logic inside check-in / seat reservation RPC.

The current CRM survey migration focuses on table-side survey and bill linking. Booking-to-Guest DB seeding is documented here as the temporary business design and should be implemented in the reservation/check-in layer when that flow is normalized.

## New Table: `crm_surveys`

Important fields:

- `branch_id`
- `table_id`
- `order_id`
- `table_assignment_id`
- `reservation_id`
- `bill_id`
- `customer_id`
- `source_code`
- `visit_reason`
- `feedback`
- `improvement_note`
- `customer_name`
- `customer_phone`
- `normalized_phone`
- `zalo`
- `marketing_consent`
- `tags`
- `survey_status`
- `asked_by`
- `asked_at`
- `submitted_at`
- `closed_at`

## Constraint

`crm_surveys_session_identity_check`

Requires at least one session/order identity:

```sql
CHECK (order_id IS NOT NULL OR table_assignment_id IS NOT NULL)
```

## Unique Indexes

The system does not use `table_id` as duplicate identity.

```sql
CREATE UNIQUE INDEX crm_surveys_one_active_per_order
ON public.crm_surveys (order_id)
WHERE order_id IS NOT NULL
  AND survey_status IN ('assigned', 'in_progress', 'completed');
```

```sql
CREATE UNIQUE INDEX crm_surveys_one_active_per_session
ON public.crm_surveys (table_assignment_id)
WHERE table_assignment_id IS NOT NULL
  AND survey_status IN ('assigned', 'in_progress', 'completed');
```

## RPC Functions

- `crm_normalize_phone(text)`
- `crm_assert_branch_access(uuid)`
- `crm_expire_old_surveys(uuid)`
- `crm_list_serving_tables(uuid)`
- `crm_list_customer_feedback(uuid)`
- `crm_list_service_requests(uuid)`
- `crm_resolve_serving_context(uuid, uuid, uuid, uuid, boolean)`
- `crm_submit_table_survey(...)`
- `crm_set_table_survey_status(...)`
- `crm_mark_survey_in_progress(...)`
- `crm_skip_table_survey(...)`
- `crm_refuse_table_survey(...)`
- `crm_link_surveys_to_bill(uuid, uuid)`
- `process_checkout(...)` replaced to call `crm_link_surveys_to_bill`

Recommended next RPC for Guest DB:

- `crm_seed_guest_from_arrived_reservation(uuid)`

This function should normalize reservation phone, match existing `customers.normalized_phone`, create/update customer if needed, and optionally link the customer to reservation/order.

Detailed backlog for this missing Guest DB layer is tracked in `phu_updated/CRM_FUTURE_TODO.md`.

## RLS

`crm_surveys` has RLS enabled.

Policies:

- Branch scoped read for current branch or admin.
- Insert/update for current branch users with roles `admin`, `manager`, `crm`, `staff`, `reception`.
- No public access.

RPC functions also check branch access through `crm_assert_branch_access`.

## Why Not `table_id`

`table_id` is not unique per dining event. A single table can serve many parties in the same day and across days. Using it as a unique key could attach yesterday's survey to today's customer. `table_id` is kept only for display and context.
