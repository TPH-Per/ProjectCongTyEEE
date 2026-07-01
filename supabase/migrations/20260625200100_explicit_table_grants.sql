-- =============================================================================
-- 20260625200100_explicit_table_grants.sql
--
-- As of 2026-05-30, new Supabase projects no longer auto-grant table access
-- to `anon` / `authenticated` / `service_role`. Tables come locked down by
-- default and you have to opt in explicitly. Without these grants, every
-- supabase-js query from the frontend returns 403 (PGRST301) even when RLS
-- would otherwise allow the row.
--
-- This migration grants the access patterns the Vue app actually needs:
--   anon            → SELECT only on the few tables the tablet menu uses
--                     (menu_categories, menu_items, branches)
--   authenticated   → CRUD on the rest, except audit_events / users which
--                     are write-protected (only service_role / triggers write)
--   service_role    → full CRUD on everything (used by Edge Functions with
--                     the service-role key)
--
-- RLS stays enabled everywhere. Grants control WHO CAN ISSUE the query;
-- RLS controls WHICH ROWS they see. They're complementary, not redundant.
--
-- Idempotent — `grant ... to ...` is a no-op if the grant already exists.
-- =============================================================================

-- ─── anon (guest tablet, unauthenticated) ────────────────────────────────────
-- Tablet reads menu + branch info without logging in.
grant select on public.menu_categories to anon;
grant select on public.menu_items     to anon;
grant select on public.branches       to anon;

-- ─── authenticated (logged-in staff) ────────────────────────────────────────
-- Read-only reference data
grant select on public.branches,
                public.branch_settings,
                public.menu_categories,
                public.menu_items,
                public.packages,
                public.tables,
                public.users
            to authenticated;

-- Operational CRUD
grant select, insert, update, delete on public.customers         to authenticated;
grant select, insert, update, delete on public.reservations      to authenticated;
grant select, insert, update, delete on public.orders            to authenticated;
grant select, insert, update, delete on public.order_items       to authenticated;
grant select, insert, update, delete on public.payments          to authenticated;
grant select, insert, update, delete on public.invoices          to authenticated;
grant select, insert, update, delete on public.shifts            to authenticated;
grant select, insert, update, delete on public.table_assignments to authenticated;
grant select, insert, update, delete on public.notifications     to authenticated;

-- audit_events is INSERT-ONLY from authenticated (RLS USING with check),
-- but the practical pattern is that the audit TRIGGER inserts on their
-- behalf — so we only need the trigger to have access (it runs as table
-- owner) and admins/managers to read. Leave the grant select-only.
grant select on public.audit_events to authenticated;

-- ─── service_role (Edge Functions) ──────────────────────────────────────────
-- Edge Functions use the service-role key and need unrestricted access.
-- RLS is bypassed for service_role by design.
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
