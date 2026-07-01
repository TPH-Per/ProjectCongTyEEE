-- =============================================================================
-- 20260625200300_rls_add_with_check_clauses.sql
--
-- Senior security review (2026-06-25):
--
-- Every `*_branch_write` policy in 20260623000000_setup.sql uses
--   for all using (branch_id = public.current_branch_id() and …)
-- without a WITH CHECK clause. Postgres semantics:
--
--   * SELECT  → USING applies (you see only matching rows)
--   * INSERT  → no constraint at all (you can insert ANY branch_id!)
--   * UPDATE  → USING applies to the OLD row (so you can only target rows
--               in your branch) BUT there's no check on the NEW row, so
--               you can SET branch_id = 'other-branch' on your own row
--               and effectively move it cross-branch.
--   * DELETE  → USING applies (you can only delete your branch's rows)
--
-- The USING clause is necessary but NOT sufficient for write paths. This
-- migration drops every *_branch_write / *_admin_write policy and recreates
-- them as separate per-command policies with explicit WITH CHECK.
--
-- Defence-in-depth rule we follow:
--   SELECT  → USING matches branch_id
--   INSERT  → WITH CHECK branch_id = current_branch_id() AND role allowed
--   UPDATE  → USING branch_id = current_branch_id() AND role allowed
--             WITH CHECK branch_id = current_branch_id() AND role allowed
--   DELETE  → USING branch_id = current_branch_id() AND role allowed
--
-- Idempotent: drop-if-exists + create. Safe to re-run.
-- =============================================================================

-- Helper: drop policy if it exists (Postgres has no IF EXISTS for policies
-- before 15, but we can wrap in DO blocks). Use DO for safety.
do $$
declare
  pol record;
begin
  for pol in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and policyname in (
        'users_admin_all',
        'zones_branch_write',
        'tables_branch_write',
        'customers_branch_write',
        'menu_categories_branch_write',
        'menu_items_branch_write',
        'packages_branch_write',
        'package_items_branch_write',
        'shifts_branch_write',
        'table_assignments_branch_write',
        'orders_branch_write',
        'order_items_branch_write',
        'invoices_branch_write',
        'payments_branch_write',
        'vouchers_admin_write',
        'deposits_branch_write',
        'kpi_targets_admin_write',
        'marketing_costs_admin_write',
        'branch_settings_admin_write'
      )
  loop
    execute format('drop policy %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end$$;

-- ----- users (admin only) -----
create policy "users_admin_all" on public.users
  for all using (public.has_role(array['admin']::user_role[]))
            with check (public.has_role(array['admin']::user_role[]));

-- ----- zones -----
create policy "zones_branch_write" on public.zones
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- tables -----
create policy "tables_branch_write" on public.tables
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- customers -----
create policy "customers_branch_write" on public.customers
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- menu_categories -----
create policy "menu_categories_branch_write" on public.menu_categories
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- menu_items -----
create policy "menu_items_branch_write" on public.menu_items
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- packages -----
create policy "packages_branch_write" on public.packages
  for all using (branch_id = public.current_branch_id())
            with check (branch_id = public.current_branch_id());

-- ----- package_items (derive branch via parent package) -----
create policy "package_items_branch_write" on public.package_items
  for all using (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ))
  with check (exists (
    select 1 from public.packages p
    where p.id = package_items.package_id
      and p.branch_id = public.current_branch_id()
  ));

-- ----- shifts -----
create policy "shifts_branch_write" on public.shifts
  for all using (
    branch_id = public.current_branch_id()
    and (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  )
  with check (
    branch_id = public.current_branch_id()
    and (user_id = auth.uid() or public.has_role(array['admin','manager']::user_role[]))
  );

-- ----- table_assignments -----
create policy "table_assignments_branch_write" on public.table_assignments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- orders -----
create policy "orders_branch_write" on public.orders
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff']::user_role[])
  );

-- ----- order_items -----
create policy "order_items_branch_write" on public.order_items
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception','staff','kitchen']::user_role[])
  );

-- ----- invoices -----
create policy "invoices_branch_write" on public.invoices
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- payments -----
create policy "payments_branch_write" on public.payments
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- vouchers (admin/manager write) -----
create policy "vouchers_admin_write" on public.vouchers
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- deposits -----
create policy "deposits_branch_write" on public.deposits
  for all using (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  )
  with check (
    branch_id = public.current_branch_id()
    and public.has_role(array['admin','manager','reception']::user_role[])
  );

-- ----- kpi_targets (admin/manager write) -----
create policy "kpi_targets_admin_write" on public.kpi_targets
  for all using (public.has_role(array['admin','manager']::user_role[]))
            with check (public.has_role(array['admin','manager']::user_role[]));

-- ----- marketing_costs (admin/manager write) -----
create policy "marketing_costs_admin_write" on public.marketing_costs
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );

-- ----- branch_settings (admin/manager write) -----
create policy "branch_settings_admin_write" on public.branch_settings
  for all using (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  )
  with check (
    public.has_role(array['admin','manager']::user_role[])
    and branch_id = public.current_branch_id()
  );
