-- ==============================================================================
-- PART 2: RLS POLICIES & SEED DATA
-- ==============================================================================

-- RLS POLICIES

-- Branches
CREATE POLICY "admin_all_branches" ON public.branches FOR ALL USING (public.has_role(ARRAY['admin']::user_role[]));
CREATE POLICY "manager_read_branches" ON public.branches FOR SELECT USING (public.has_role(ARRAY['admin', 'manager']::user_role[]));
CREATE POLICY "staff_read_branch" ON public.branches FOR SELECT USING (id = public.current_branch_id());

-- Users
CREATE POLICY "users_read_self_or_admin" ON public.users FOR SELECT USING (id = public.current_user_id() OR public.has_role(ARRAY['admin', 'manager']::user_role[]));
CREATE POLICY "users_admin_write" ON public.users FOR ALL USING (public.has_role(ARRAY['admin']::user_role[]));

-- Tables
CREATE POLICY "tables_branch_read" ON public.tables FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "tables_branch_write" ON public.tables FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Customers
CREATE POLICY "customers_branch_read" ON public.customers FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "customers_branch_write" ON public.customers FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Menu Items
CREATE POLICY "menu_branch_read" ON public.menu_items FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "menu_branch_write" ON public.menu_items FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Packages
CREATE POLICY "packages_branch_read" ON public.packages FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "packages_branch_write" ON public.packages FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Reservations (Sessions)
CREATE POLICY "reservations_branch_read" ON public.reservations FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "reservations_branch_write" ON public.reservations FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception', 'staff']::user_role[]));

-- Orders
CREATE POLICY "orders_branch_read" ON public.orders FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "orders_branch_write" ON public.orders FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception', 'staff']::user_role[]));

-- Order Items
CREATE POLICY "order_items_branch_read" ON public.order_items FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "order_items_branch_write" ON public.order_items FOR ALL USING (branch_id = public.current_branch_id());

-- Invoices
CREATE POLICY "invoices_branch_read" ON public.invoices FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "invoices_branch_write" ON public.invoices FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Payments
CREATE POLICY "payments_branch_read" ON public.payments FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "payments_branch_write" ON public.payments FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));

-- Vouchers
CREATE POLICY "vouchers_branch_read" ON public.vouchers FOR SELECT USING (branch_id = public.current_branch_id() AND is_active = true);
CREATE POLICY "vouchers_branch_write" ON public.vouchers FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Shifts
CREATE POLICY "shifts_branch_read" ON public.shifts FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "shifts_branch_write" ON public.shifts FOR ALL USING (branch_id = public.current_branch_id() AND (user_id = public.current_user_id() OR public.has_role(ARRAY['admin', 'manager']::user_role[])));

-- Branch Settings
CREATE POLICY "settings_branch_read" ON public.branch_settings FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "settings_branch_write" ON public.branch_settings FOR ALL USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager']::user_role[]));

-- Audit Events
CREATE POLICY "audit_branch_read" ON public.audit_events FOR SELECT USING (branch_id = public.current_branch_id() AND public.has_role(ARRAY['admin', 'manager', 'reception']::user_role[]));
CREATE POLICY "audit_branch_write" ON public.audit_events FOR INSERT WITH CHECK (branch_id = public.current_branch_id());

-- Notifications
CREATE POLICY "notifications_branch_read" ON public.notifications FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "notifications_branch_write" ON public.notifications FOR ALL USING (branch_id = public.current_branch_id());

-- System Events
CREATE POLICY "system_events_branch_read" ON public.system_events FOR SELECT USING (branch_id = public.current_branch_id());
CREATE POLICY "system_events_branch_write" ON public.system_events FOR INSERT WITH CHECK (branch_id = public.current_branch_id());


-- AUDIT LOGGING TRIGGER

CREATE OR REPLACE FUNCTION public.write_audit() RETURNS trigger AS $$
DECLARE
  v_action text;
  v_payload jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := TG_TABLE_NAME || '_created';
    v_payload := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'UPDATE' THEN
    v_action := TG_TABLE_NAME || '_updated';
    v_payload := jsonb_build_object('old', row_to_json(OLD)::jsonb, 'new', row_to_json(NEW)::jsonb);
  ELSIF TG_OP = 'DELETE' THEN
    v_action := TG_TABLE_NAME || '_deleted';
    v_payload := row_to_json(OLD)::jsonb;
  END IF;

  INSERT INTO public.audit_events (branch_id, actor_id, action, entity_type, entity_id, payload)
  VALUES (
    COALESCE((v_payload->>'branch_id')::uuid, public.current_branch_id()),
    public.current_user_id(),
    v_action,
    TG_TABLE_NAME,
    COALESCE((v_payload->>'id')::uuid, NULL),
    v_payload
  );

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_reservations AFTER INSERT OR UPDATE OR DELETE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_orders AFTER INSERT OR UPDATE OR DELETE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_order_items AFTER INSERT OR UPDATE OR DELETE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_payments AFTER INSERT OR UPDATE OR DELETE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_invoices AFTER INSERT OR UPDATE OR DELETE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.write_audit();
CREATE TRIGGER trg_audit_shifts AFTER INSERT OR UPDATE OR DELETE ON public.shifts FOR EACH ROW EXECUTE FUNCTION public.write_audit();

-- REVENUE REPORTING RPC
CREATE OR REPLACE FUNCTION public.revenue_by_hour(p_branch_id uuid, p_date date)
RETURNS TABLE (hour_of_day int, total_revenue numeric, order_count int) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(HOUR FROM created_at)::int AS hour_of_day,
    SUM(total) AS total_revenue,
    COUNT(id)::int AS order_count
  FROM public.orders
  WHERE branch_id = p_branch_id
    AND DATE(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_date
    AND status IN ('Served', 'Paid')
  GROUP BY EXTRACT(HOUR FROM created_at)
  ORDER BY hour_of_day;
END;
$$ LANGUAGE plpgsql STABLE;

-- REALTIME CONFIGURATION
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_events;

-- SEED DATA
INSERT INTO public.branches (id, code, name, address, phone, timezone, currency, vat_rate, is_active) VALUES
('b1000000-0000-0000-0000-000000000001', 'B001', 'Ngưu Cát Quận 1', '123 Lê Lợi, Q1, HCM', '0901234567', 'Asia/Ho_Chi_Minh', 'VND', 0.08, true),
('b2000000-0000-0000-0000-000000000002', 'B002', 'Ngưu Cát Phú Nhuận', '456 Phan Xích Long, PN, HCM', '0901234568', 'Asia/Ho_Chi_Minh', 'VND', 0.08, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.tables (id, branch_id, zone, code, capacity, pos_x, pos_y) VALUES
('t1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'VIP', 'A01', 4, 100, 100),
('t1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'VIP', 'A02', 4, 200, 100),
('t1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Main', 'B01', 2, 100, 200),
('t1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Main', 'B02', 6, 200, 200),
('t1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'Outdoor', 'C01', 4, 300, 200)
ON CONFLICT DO NOTHING;

INSERT INTO public.menu_items (id, branch_id, category, name, price, cost, i18n_name) VALUES
('m1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Beef', 'Wagyu A5', 500000, 200000, '{"vi": "Bò Wagyu A5", "en": "Wagyu A5 Beef", "ja": "和牛A5"}'),
('m1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Beef', 'Thăn ngoại bò Mỹ', 200000, 80000, '{"vi": "Thăn ngoại bò Mỹ", "en": "US Striploin", "ja": "USサーロイン"}'),
('m1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Side', 'Salad rau củ', 50000, 15000, '{"vi": "Salad rau củ", "en": "Vegetable Salad", "ja": "野菜サラダ"}'),
('m1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Drink', 'Coca Cola', 30000, 10000, '{"vi": "Coca Cola", "en": "Coca Cola", "ja": "コカ・コーラ"}'),
('m1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'Drink', 'Soju', 100000, 40000, '{"vi": "Rượu Soju", "en": "Soju", "ja": "焼酎"}')
ON CONFLICT DO NOTHING;

INSERT INTO public.packages (id, branch_id, name, type, price, items_included, i18n_name) VALUES
('p1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Buffet Standard', 'buffet', 380000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000002", "limit": null}, {"menu_item_id": "m1000000-0000-0000-0000-000000000003", "limit": null}]', '{"vi": "Buffet Tiêu chuẩn", "en": "Standard Buffet", "ja": "スタンダードビュッフェ"}'),
('p1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Buffet Premium', 'buffet', 680000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000001", "limit": 2}, {"menu_item_id": "m1000000-0000-0000-0000-000000000002", "limit": null}]', '{"vi": "Buffet Cao cấp", "en": "Premium Buffet", "ja": "プレミアムビュッフェ"}'),
('p1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Drink Package A', 'drink', 150000, '[{"menu_item_id": "m1000000-0000-0000-0000-000000000004", "limit": null}]', '{"vi": "Gói Nước A", "en": "Drink Package A", "ja": "ドリンクパックA"}')
ON CONFLICT DO NOTHING;

-- KPI/Marketing settings moved to branch_settings
INSERT INTO public.branch_settings (branch_id, key, value) VALUES
('b1000000-0000-0000-0000-000000000001', 'kpi.revenue.daily', '{"target_value": 50000000, "period_start": "2026-06-01", "period_end": "2026-12-31"}'),
('b1000000-0000-0000-0000-000000000001', 'kpi.guest_count.daily', '{"target_value": 150, "period_start": "2026-06-01", "period_end": "2026-12-31"}'),
('b1000000-0000-0000-0000-000000000001', 'marketing.facebook_ads', '{"amount": 10000000, "period_start": "2026-06-01", "period_end": "2026-06-30"}')
ON CONFLICT DO NOTHING;
