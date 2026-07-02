# CRM Changelog

## Files Added

- `src/views/crm/CRMServingTablesView.vue`
- `supabase/migrations/20260702044658_crm_serving_table_surveys.sql`
- `phu_updated/CRM_UPDATED_PLAN.md`
- `phu_updated/CRM_FLOW.md`
- `phu_updated/CRM_SCHEMA.md`
- `phu_updated/CRM_TEST_REPORT.md`
- `phu_updated/CRM_CHANGELOG.md`
- `phu_updated/CRM_FUTURE_TODO.md`
- `phu_updated/CRM_TASK_STATUS.md`

## Files Updated

- `src/composables/useCRM.ts`
- `src/composables/useCheckout.ts`
- `src/layouts/CRMLayout.vue`
- `src/router/index.ts`
- `src/utils/route.ts`
- `src/types/database.ts`
- `src/views/staff/StaffInDiningCRMView.vue`
- `src/views/crm/FeedbackManagerView.vue`
- `src/views/reception/ReceptionCheckoutView.vue`

## Database Changes

Migration:

- `20260702044658_crm_serving_table_surveys.sql`

Added:

- `crm_surveys`
- `crm_normalize_phone`
- Customer Marketing fields:
  - `normalized_phone`
  - `source_code`
  - `visit_reason`
  - `first_visit_at`
  - `marketing_consent`
  - `marketing_tags`
  - `zalo`

## RPC Added

- `crm_assert_branch_access`
- `crm_expire_old_surveys`
- `crm_list_serving_tables`
- `crm_list_customer_feedback`
- `crm_list_service_requests`
- `crm_resolve_serving_context`
- `crm_submit_table_survey`
- `crm_set_table_survey_status`
- `crm_mark_survey_in_progress`
- `crm_skip_table_survey`
- `crm_refuse_table_survey`
- `crm_link_surveys_to_bill`

## Checkout Change

`process_checkout` was replaced in a new migration to:

- Keep checkout as payment flow.
- Create bill/invoice/payment as before.
- Call `crm_link_surveys_to_bill(order_id, bill_id)` after bill creation.
- Not require CRM survey.
- Map UI payment strings such as `CASH`, `CARD`, `MOMO`, `ZALOPAY`, `VNPAY`.

## Frontend Change

- Added `/crm/serving-tables`.
- Added CRM sidebar link for serving tables.
- Added `crm` route role access.
- `useCRM` now exposes RPC methods for serving tables and survey actions.
- Staff in-dining CRM old page now uses RPC instead of direct table/order queries.
- CRM feedback manager now reads feedback through `useCRM` RPC.

## Important Notes

- Do not reintroduce `table_id` as the survey duplicate key.
- Do not move CRM survey capture into checkout as the primary workflow.
- If a bill has no CRM survey, checkout must still complete.
- CRM staff should not be expected to ask for phone numbers at the table.
- Temporary Guest DB contact source should be booking/reservation contact after the guest is confirmed as arrived/seated/dining/completed.
- Do not seed Guest DB from pending, cancelled, or no-show bookings.
- Booking-to-Guest DB seeding is documented as the next reservation/check-in layer improvement; the current migration focuses on CRM survey and bill linking.
- Remaining work for complete Guest DB logic is tracked in `phu_updated/CRM_FUTURE_TODO.md`.
- CRM task/function status table is tracked in `phu_updated/CRM_TASK_STATUS.md`.
- If local migration history complains about old stash migrations, repair/pull intentionally instead of applying ad hoc fixes.
