# Hall + Customer Changelog

## 1. Files added

- `supabase/migrations/20260702083325_hall_customer_rpc.sql`
- `phu_updated/HALL_CUSTOMER_UPDATED_PLAN.md`
- `phu_updated/HALL_CUSTOMER_FLOW.md`
- `phu_updated/HALL_CUSTOMER_SCHEMA.md`
- `phu_updated/HALL_CUSTOMER_TEST_REPORT.md`
- `phu_updated/HALL_CUSTOMER_CHANGELOG.md`
- `phu_updated/HALL_CUSTOMER_TASK_STATUS.md`

## 2. Files updated

- `src/composables/useMenu.ts`
  - Menu category/item/package reads moved to RPC.
  - Admin `upsertItem` remains direct query and is marked outside this phase.

- `src/composables/useTable.ts`
  - Table list now uses `hall_list_tables`.
  - Direct status update is blocked in this composable for this phase.

- `src/composables/useTablet.ts`
  - Tablet content/session/language now use RPC.
  - Session stores branch/table/session in localStorage for tablet order flow.

- `src/composables/useServiceRequest.ts`
  - Create/list/ack/complete service request now use RPC.

- `src/composables/useReservation.ts`
  - Reservation list/stats/status updates moved to Hall RPC.
  - Status model aligned to current schema: `Pending`, `Arrived`, `Dining`, `Completed`, `Cancelled`.

- `src/views/tablet/TabletIdleView.vue`
  - Removed hard-coded default branch string and uses branch fallback.

- `src/views/tablet/TabletOrderView.vue`
  - Menu load uses RPC via `useMenu`.
  - Submit order calls `customer_submit_table_order`.
  - Support/payment buttons call `create_service_request`.

- `src/views/reception/ReceptionCheckoutView.vue`
  - Order/table/items load now uses `hall_get_checkout_summary`.
  - Final checkout remains through existing `process_checkout`.

- `src/views/reception/ReceptionDashboardView.vue`
  - Active shift read moved to `hall_get_active_shift`.
  - Service requests loaded into dashboard alerts.

- `src/views/reception/ReceptionOrderView.vue`
  - Send-to-kitchen/order submit now uses `hall_submit_table_order`.
  - Menu DB id resolution uses menu RPC instead of direct menu query.

- `src/views/staff/StaffFloorPlanView.vue`
  - Table list moved to `useTable().listTables()`.

- `src/views/staff/StaffActiveTablesView.vue`
  - Active table list moved to `useTable().listTables()`.

- `src/views/hall/ActiveTablesView.vue`
  - Active table list moved to `useTable().listTables()`.

## 3. RPC added/updated

### Customer / Tablet

- `customer_list_menu_categories`
- `customer_list_menu_items`
- `customer_get_tablet_content`
- `customer_activate_tablet_session`
- `customer_set_tablet_language`
- `customer_submit_table_order`

### Hall

- `hall_submit_table_order`
- `hall_list_tables`
- `hall_list_packages`
- `get_floor_plan`
- `hall_get_checkout_summary`
- `hall_get_active_shift`

### Service Request

- `create_service_request`
- `hall_list_service_requests`
- `hall_ack_service_request`
- `hall_complete_service_request`

### Reservation

- `hall_list_reservations_by_date`
- `get_reservation_stats`
- `hall_update_reservation_status`
- `confirm_reservation`
- `seat_reservation`

### Helper

- `hall_customer_assert_branch_access`

## 4. Database objects added

- `tablet_sessions.order_id`
- `tablet_sessions.last_activity_at`
- `tablet_order_submissions`
- RLS policy `tablet_order_submissions_branch_access`
- Index `tablet_sessions_active_table_idx`
- Index `tablet_order_submissions_session_idx`

## 5. Checkout changes

- Checkout UI no longer directly selects table/order/order_items for the summary.
- Summary is produced by `hall_get_checkout_summary`.
- Final payment remains through existing `process_checkout`.
- No CRM dependency was added.

## 6. Notes for future developer

- Do not make customer/tablet send price or total as trusted input.
- Do not implement split bill by letting staff type manual total.
- Do not merge tables by overwriting table ids.
- Order modification needs kitchen/bill/audit rule before implementation.
- Close shift and admin menu maintenance still need separate strict RPC cleanup.
