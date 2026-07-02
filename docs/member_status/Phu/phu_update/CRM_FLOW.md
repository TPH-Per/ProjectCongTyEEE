# CRM Flow

## UC 6.1 - Serving Tables

Route: `/crm/serving-tables`

The page calls `crm_list_serving_tables(p_branch_id)` and shows only active orders where table status is `occupied`.

Each row includes:

- Table code
- Zone
- Active order id
- Current table assignment id if available
- Reservation id if available
- Guest count
- Started time
- CRM status

Status values:

- `not_started`
- `assigned`
- `in_progress`
- `completed`
- `skipped`
- `customer_refused`
- `expired`
- `late_submitted`

## UC 6.2 - Source And Visit Reason

CRM staff selects a serving table and records:

- Source code: Google Map, Facebook, TikTok, Instagram, friend referral, walk by, returning customer, booking platform, other.
- Visit reason: family meal, birthday, date, company, friends, first try, regular customer, other.

The frontend sends these values to `crm_submit_table_survey`.

## UC 6.3 - Feedback

CRM staff records:

- Feedback
- Improvement note
- Optional internal note
- Optional customer name
- Optional phone
- Optional Zalo
- Optional marketing consent
- Optional tags

Phone is normalized in PostgreSQL by `crm_normalize_phone`.

## UC 6.4 - Link Survey To Bill

Checkout does not collect CRM data.

When `process_checkout` creates a bill, it calls:

```text
crm_link_surveys_to_bill(order_id, bill_id)
```

This links surveys by `order_id`, not by `table_id`.

## Guest DB Temporary Source Flow

Current business assumption: CRM staff should not routinely ask guests for phone numbers at the table. Therefore Guest DB contact data should primarily come from booking/reservation contact once the booking is confirmed as a real visit.

Flow:

1. Guest makes a reservation with name/phone.
2. Staff confirms the guest actually arrived by moving reservation/order/table into an arrived/seated/dining/completed state.
3. Backend may seed or update `customers` from reservation contact.
4. CRM survey remains linked to the dining `order_id` and can optionally link `customer_id` if a customer was matched.
5. Checkout links CRM survey to bill.

Important temporary limitation:

- If staff are too busy and never mark the reservation as arrived/seated/dining/completed, the booking contact may not enter Guest DB.
- This is accepted for now because it prevents no-show/cancelled bookings from polluting Marketing data.

## Case: Reserved Guest Already Exists In Guest DB

Input:

- Reservation contact phone matches an existing `customers.normalized_phone`.
- Reservation is confirmed as arrived/seated/dining/completed.

Expected:

- Do not create a duplicate customer.
- Update existing customer lightly:
  - `last_visit_at`
  - optional source/visit reason if available
  - optional tags/consent if available
- CRM survey for this meal remains a separate `crm_surveys` row linked to the current `order_id`.
- At checkout, survey receives `bill_id`.

## Case: Reserved Guest Is New

Input:

- Reservation contact exists.
- No matching normalized phone in `customers`.
- Reservation is confirmed as arrived/seated/dining/completed.

Expected:

- Create a temporary Guest DB profile from booking contact.
- Mark source/metadata so developers understand it came from booking, not direct CRM interview.
- CRM survey phone remains optional.

## Case: CRM Does Not Ask Phone

Input:

- CRM submits source/reason/feedback only.

Expected:

- Survey is saved.
- `customer_id` can stay null unless booking-derived customer is linked by future backend logic.
- Guest DB is not blocked by CRM survey because reservation-arrival flow is the temporary primary source.

## Case: Booking Contact Is Not The Real Guest

Example: assistant books for a manager, or company admin books for a group.

Temporary behavior:

- Booking-derived Guest DB is acceptable as a provisional profile once the reservation arrives.
- CRM survey should still store event-level feedback separately.
- Future improvement should add a UI confirmation step: "booking contact is actual guest / company contact / booker only".

## Start / Continue

When CRM selects a `not_started` table, the frontend calls `crm_mark_survey_in_progress`, which creates or updates the survey row for the current active order/session.

## Customer Refused

The frontend calls `crm_refuse_table_survey`.

Expected result:

- Survey status becomes `customer_refused`.
- It does not appear as `not_started`.
- No customer profile is required.
- It can still be linked to the bill later.

## Skipped

The frontend calls `crm_skip_table_survey`.

Expected result:

- Survey status becomes `skipped`.
- It does not appear as `not_started`.
- Optional note can explain why.

## Expired / Late Submitted

`crm_expire_old_surveys` marks stale `assigned` or `in_progress` surveys as `expired` if their order is no longer active.

If a user submits a survey with an explicit closed `order_id`, `crm_submit_table_survey` stores it as `late_submitted`. It does not attach to a new table session.

## Core Protection

Survey state follows `order_id` / `table_assignment_id`, not table identity. A new seating at the same table has a new order and therefore starts with `not_started`.
