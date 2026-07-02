# CRM Updated Plan

## Goal

Standardize CRM as a simple, table-side customer-care workflow that is separate from booking contact and checkout payment.

## Data Separation

### Guest DB / Customer Profile

`customers` is the long-term Marketing/customer intelligence profile. It stores durable customer attributes such as name, phone, normalized phone, Zalo, source, visit reason, tags, consent, first visit, last visit, visits, and spend when a bill can be matched later.

Temporary current design: because CRM staff should not be expected to ask for a phone number at the table, the primary reliable source for Guest DB contact data is booking/reservation contact after the restaurant has confirmed the guest actually arrived. CRM survey phone fields stay optional.

### Booking Contact

`reservations` remains the operational booking/contact layer. A booking name/phone can seed or update Guest DB only when the booking is confirmed as arrived/seated/dining/completed. Pending/no-show/cancelled reservations should not become Guest DB profiles by default.

### CRM Survey

`crm_surveys` is event/session-level data captured while guests are eating. It is linked to the current dining `order_id` and optionally `table_assignment_id`, `reservation_id`, `customer_id`, and later `bill_id`.

## New Flow

1. CRM opens `/crm/serving-tables`.
2. System lists only active serving tables from active orders.
3. CRM starts or continues the survey for the current order/session.
4. CRM submits source, visit reason, feedback, improvement note, optional customer info, consent, tags, and note.
5. The survey is stored against the current `order_id`/`table_assignment_id`.
6. If CRM survey phone is present, the DB normalizes it and updates or creates a guest profile.
7. Checkout remains a payment flow. It only calls DB logic to link existing surveys to the new bill.

## Temporary Guest DB Source Rule

For the current phase, Guest DB should be populated from:

1. Booking/reservation contact once the guest is confirmed as actually arrived.
2. CRM survey contact only if the guest voluntarily provides phone/name.
3. Future integrations such as Zalo OA or booking platforms.

If staff are too busy and do not update reservation arrival/seated status, that booking may not enter Guest DB yet. This is accepted for the temporary design because it avoids polluting Guest DB with no-show/cancelled reservations.

## Design Decisions

- `table_id` is display context only.
- Duplicate prevention is based on `order_id` and `table_assignment_id`.
- Old `assigned` or `in_progress` surveys are expired when their order is no longer active.
- Checkout does not require CRM survey.
- CRM does not require staff to ask for customer phone.
- Booking contact can feed Guest DB only after arrival is confirmed.
- Frontend calls RPC only for CRM operations.
- Migration is additive except `process_checkout`, which is replaced to keep the same checkout flow and add CRM survey linking.

## Implemented

- Added `crm_surveys`.
- Added minimal Marketing fields to `customers`.
- Added RPCs for list, submit, status updates, skip, refused, expire, and link-to-bill.
- Added `/crm/serving-tables`.
- Refactored old staff in-dining CRM view to call RPC instead of direct table queries.
- Updated checkout RPC to link surveys to bill.
- Updated CRM feedback view to use RPC path.

## Not Changed

- Booking/reservation flow was not redesigned in code yet; this document records the temporary rule that arrived bookings may seed Guest DB.
- Automatic booking-to-Guest DB seeding is not implemented yet. This is tracked in `phu_updated/CRM_FUTURE_TODO.md`.
- Checkout UI was not turned into CRM capture.
- Existing broad project TypeScript errors outside CRM were not fully fixed.

## Future Extensions

- Implement booking-to-Guest DB seeding after reservation arrival is normalized.
- Link booking-derived `customer_id` to active order/session and CRM survey.
- Add MKT dashboard by `source_code`, `visit_reason`, and tags.
- Add Zalo OA sync after `marketing_consent`.
- Add richer survey templates per branch.
- Add voucher issuance after survey completion if business confirms.

Detailed implementation backlog is recorded in `phu_updated/CRM_FUTURE_TODO.md`.
