# CRM Future TODO

This file records the remaining work needed to complete the CRM business logic after the current CRM survey and bill-linking baseline.

## Current State

Implemented now:

- CRM survey follows the current dining `order_id` / `table_assignment_id`.
- `table_id` is display context only.
- Survey can be completed without customer phone.
- Checkout only links existing CRM survey to bill.
- Guest DB / booking contact / CRM survey are documented as separate data layers.

Not fully implemented yet:

- Automatic Guest DB seeding from arrived reservations.
- Automatic link from booking-derived customer profile to the active order/session/survey.

## Priority 1 - Seed Guest DB From Arrived Booking

Business reason:

CRM staff should not routinely ask for guest phone at the table. Therefore the most practical source for Guest DB contact data is reservation contact, but only after the guest is confirmed as actually arrived.

Required backend behavior:

1. When reservation status becomes arrived/seated/dining/completed, normalize reservation phone.
2. Search `customers.normalized_phone`.
3. If found, update the existing customer lightly.
4. If not found, create a provisional Guest DB customer.
5. Mark the profile source clearly as reservation/booking-derived.
6. Do not seed Guest DB from pending, cancelled, or no-show reservations.

Recommended RPC:

```text
crm_seed_guest_from_arrived_reservation(p_reservation_id uuid)
```

Alternative:

- Put the same logic inside the existing check-in / seat-reservation RPC if that is the real source of truth for arrival.

Acceptance criteria:

- A confirmed arrived reservation with phone creates or updates exactly one customer.
- Same phone does not create duplicate customers.
- Pending/cancelled/no-show reservations do not create customers.
- The function is branch-scoped and follows current RLS/security conventions.

## Priority 2 - Normalize Reservation Arrival Status

Current risk:

If reservation status names are inconsistent between UI, composables, and database, the system may miss real guests or seed from the wrong status.

Required decision:

Define the exact statuses that mean "guest actually came".

Recommended valid arrival states:

- `Arrived`
- `Dining`
- `Completed`
- equivalent checked-in/seated status if the reservation module changes naming

Invalid states for Guest DB seeding:

- `Pending`
- `Cancelled`
- no-show
- expired booking without arrival confirmation

Acceptance criteria:

- Reservation UI and database use the same status vocabulary.
- Guest DB seed logic depends on arrival status, not booking creation alone.

## Priority 3 - Link Booking-Derived Customer To Current Dining Session

Business reason:

If a reserved guest is already matched to Guest DB, the current order/session and CRM survey should be able to reference that `customer_id` without asking CRM to request phone again.

Required behavior:

1. When an arrived reservation is assigned to a table/order, resolve or create the booking-derived customer.
2. Store or expose `customer_id` for the active dining context.
3. When CRM opens serving tables, include the matched `customer_id` if available.
4. When CRM submits survey without phone, keep the survey linked to the booking-derived customer if the match is reliable.

Acceptance criteria:

- Reserved guest with existing customer profile links to the new dining session.
- CRM survey can have `customer_id` without CRM asking phone.
- Non-reservation walk-in survey still works with `customer_id = null`.

## Priority 4 - Add Provisional Guest Profile Metadata

Business reason:

Booking contact may be the real guest, a company admin, or someone booking for another person. Marketing should know the confidence/source of the profile.

Recommended fields or metadata:

- `guest_source = reservation_arrival`
- `profile_confidence = provisional`
- `source_reservation_id`
- `first_seen_from = booking`

If the current `customers` table does not have JSON metadata, this can be deferred or represented with existing source/tag fields.

Acceptance criteria:

- Developers and Marketing can distinguish direct CRM customer data from booking-derived customer data.
- Future cleanup/merge tools can prioritize provisional records.

## Priority 5 - CRM UI Signal For Booking Match

Recommended UI behavior:

- On `/crm/serving-tables`, show whether the active table/order has a booking-derived customer match.
- Do not ask CRM staff to manually enter phone as the main path.
- Keep phone as optional only when guest voluntarily provides it.

Possible badges:

- `Booking matched`
- `No guest profile`
- `Walk-in`
- `Provisional profile`

Acceptance criteria:

- CRM staff can see whether the current table already has Guest DB context.
- Tables without customer profile are still surveyable.

## Priority 6 - Guest DB Data Quality And Merge Flow

Future risk:

Even with phone normalization, duplicates can still happen because of typos, different booking channels, missing phones, or company bookings.

Future improvements:

- Customer merge tool by normalized phone/name.
- Duplicate detection report.
- Profile confidence score.
- Audit trail for source updates.
- Marketing tag cleanup.

Acceptance criteria:

- Duplicate customers can be reviewed and merged without losing survey/bill history.
- CRM survey and bill records keep their original audit trail.

## Priority 7 - Reporting For Marketing

After booking-to-Guest DB seeding is implemented, Marketing can use:

- Source code by reservation and survey.
- Visit reason by survey.
- Repeat visit count.
- Last visit.
- Total spend when bill matching is available.
- Feedback/improvement trends.

Acceptance criteria:

- Reports separate booking-derived profile data from event-level CRM survey data.
- Walk-ins without phone still contribute survey/feedback metrics.

## Non-Goals For Now

- Do not force cashier to collect CRM data at checkout.
- Do not require CRM staff to ask for phone.
- Do not seed customers from unconfirmed bookings.
- Do not use `table_id` as the survey identity.
- Do not block checkout when no CRM survey exists.
