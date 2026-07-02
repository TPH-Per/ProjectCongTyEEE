-- =================================================================================
-- MIGRATION: Fix 7 RPC lint errors — column-reference mismatches
--
-- Bối cảnh
-- --------
-- `supabase db lint --local` flag 7 RPC có function body tham chiếu cột không
-- tồn tại. Nguyên nhân: schema_hardening_v2.sql rebuild các bảng
-- (ingredients, suppliers, inventory_stock, inventory_transactions, reservations)
-- nhưng các RPC viết trước đó không được đồng bộ. PL/pgSQL chỉ check schema
-- tại runtime → function CREATE được nhưng CALL sẽ crash 42703.
--
-- 7 RPC cần sửa
-- -------------
-- 1. get_suppliers              — s.contact_info  → s.contact_name / contact_phone / contact_email
-- 2. get_ingredients            — i.category      → JOIN ingredient_categories (i.category_id → ic.name)
-- 3. get_current_stock          — s.last_updated  → s.updated_at
-- 4. get_inventory_transactions — t.supplier_id   → JOIN suppliers ON s.id = t.supplier_id (cần ADD COLUMN)
-- 5. record_inventory_transaction — transaction_type → type, +balance_after, ADD unit_cost/supplier_id
-- 6. get_revenue_report         — b.branch_id     → bi.branch_id (b là alias của branches, không có branch_id)
-- 7. create_reservation         — guest_name/guest_phone không tồn tại trong reservations
--                                  → ADD COLUMN + ALTER customer_id thành nullable
--
-- Schema changes (tối thiểu, không phá vỡ dữ liệu cũ)
-- ------------------------------------------------------
-- * ADD COLUMN inventory_transactions.unit_cost   numeric(14,2) DEFAULT 0
-- * ADD COLUMN inventory_transactions.supplier_id uuid REFERENCES suppliers(id)
-- * ALTER reservations.customer_id DROP NOT NULL
-- * ADD COLUMN reservations.guest_name text
-- * ADD COLUMN reservations.guest_phone text
--
-- ⚠️ CAVEATS — bạn cần biết khi apply
-- -----------------------------------
-- 1. ADD COLUMN ... DEFAULT 0 an toàn cho bảng có data (Postgres 11+ làm in-place).
-- 2. DROP NOT NULL trên customer_id là bước đi đúng theo design intent — cho phép
--    walk-in / phone booking không cần customer record trước.
-- 3. get_suppliers RETURNS TABLE giữ nguyên 1 cột `contact_info text` để không break
--    caller; nội dung là concat 3 cột contact_*. Caller muốn tách riêng có thể nâng
--    cấp sau bằng cách đổi RETURNS TABLE.
-- 4. Sau migration này, `db lint --local` sẽ giảm từ 7 errors xuống 0 errors
--    cho 7 function trên (warnings "unused parameter/variable" vẫn còn — đó là
--    cosmetic, không phải runtime issue).
-- =================================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. SCHEMA FIXES — bảng inventory_transactions + reservations
-- ─────────────────────────────────────────────────────────────────────────────

-- 1.1 inventory_transactions: bổ sung unit_cost + supplier_id cho function INSERT
ALTER TABLE public.inventory_transactions
  ADD COLUMN IF NOT EXISTS unit_cost   numeric(14,2) NOT NULL DEFAULT 0;
ALTER TABLE public.inventory_transactions
  ADD COLUMN IF NOT EXISTS supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL;

-- 1.2 reservations: cho phép walk-in / phone booking (customer_id không bắt buộc)
ALTER TABLE public.reservations
  ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS guest_name  text;
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS guest_phone text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RPC FIXES — CREATE OR REPLACE cho 7 function
-- ─────────────────────────────────────────────────────────────────────────────

-- 2.1 get_suppliers  (FIX: s.contact_info → concat contact_name/phone/email)
CREATE OR REPLACE FUNCTION public.get_suppliers()
RETURNS TABLE (
  id uuid,
  name text,
  contact_info text,
  tax_code text,
  payment_terms text
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.name,
    COALESCE(s.contact_name, '') || ' / ' ||
      COALESCE(s.contact_phone, '') || ' / ' ||
      COALESCE(s.contact_email, '') AS contact_info,
    s.tax_code,
    s.payment_terms
  FROM public.suppliers s
  WHERE s.is_active = true
  ORDER BY s.name ASC;
END;
$$;

-- 2.2 get_ingredients  (FIX: i.category → JOIN ingredient_categories)
CREATE OR REPLACE FUNCTION public.get_ingredients()
RETURNS TABLE (
  id uuid,
  name text,
  unit text,
  category text
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN QUERY
  SELECT
    i.id,
    i.name,
    i.unit,
    ic.name AS category
  FROM public.ingredients i
  LEFT JOIN public.ingredient_categories ic ON ic.id = i.category_id
  WHERE i.is_active = true
  ORDER BY i.name ASC;
END;
$$;

-- 2.3 get_current_stock  (FIX: s.last_updated → s.updated_at)
CREATE OR REPLACE FUNCTION public.get_current_stock(p_branch_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  ingredient_id uuid,
  ingredient_name text,
  unit text,
  quantity numeric,
  last_updated timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());

  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    i.id        AS ingredient_id,
    i.name      AS ingredient_name,
    i.unit      AS unit,
    s.quantity,
    s.updated_at AS last_updated
  FROM public.inventory_stock s
  JOIN public.ingredients i ON i.id = s.ingredient_id
  WHERE s.branch_id = v_branch_id
  ORDER BY s.quantity DESC;
END;
$$;

-- 2.4 get_inventory_transactions  (FIX: supplier_id đã có trong table sau ALTER)
CREATE OR REPLACE FUNCTION public.get_inventory_transactions(
  p_branch_id uuid DEFAULT NULL,
  p_limit     int   DEFAULT 100
)
RETURNS TABLE (
  id uuid,
  transaction_type text,
  ingredient_name text,
  unit text,
  quantity numeric,
  unit_cost numeric,
  supplier_name text,
  notes text,
  created_at timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());

  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Branch ID is required' USING ERRCODE = '28000';
  END IF;

  IF v_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.type        AS transaction_type,
    i.name        AS ingredient_name,
    i.unit        AS unit,
    t.quantity,
    t.unit_cost,
    s.name        AS supplier_name,
    t.notes,
    t.created_at
  FROM public.inventory_transactions t
  JOIN public.ingredients i   ON i.id = t.ingredient_id
  LEFT JOIN public.suppliers s ON s.id = t.supplier_id
  WHERE t.branch_id = v_branch_id
  ORDER BY t.created_at DESC
  LIMIT p_limit;
END;
$$;

-- 2.5 record_inventory_transaction  (FIX: dùng `type` + balance_after + supplier_id)
CREATE OR REPLACE FUNCTION public.record_inventory_transaction(
  p_ingredient_id    uuid,
  p_transaction_type text,   -- 'IN','OUT','ADJUST','WASTE','RETURN','PURCHASE'
  p_quantity         numeric,
  p_unit_cost        numeric DEFAULT 0,
  p_supplier_id      uuid    DEFAULT NULL,
  p_notes            text    DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id       uuid;
  v_transaction_id  uuid;
  v_current_stock   numeric;
  v_new_stock       numeric;
  v_normalized_type text;
BEGIN
  v_branch_id := public.current_branch_id();

  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: current_branch_id is required' USING ERRCODE = '28000';
  END IF;

  -- Khóa row tồn kho hiện tại để chống race-condition
  SELECT quantity INTO v_current_stock
  FROM public.inventory_stock
  WHERE branch_id = v_branch_id AND ingredient_id = p_ingredient_id
  FOR UPDATE;

  IF NOT FOUND THEN
    v_current_stock := 0;
  END IF;

  -- Map 'PURCHASE' → 'IN' cho phù hợp với CHECK constraint của table
  v_normalized_type := CASE
    WHEN p_transaction_type = 'PURCHASE' THEN 'IN'
    ELSE p_transaction_type
  END;

  -- Tính toán số lượng tồn kho mới
  IF v_normalized_type = 'IN' THEN
    v_new_stock := v_current_stock + p_quantity;
  ELSIF v_normalized_type = 'OUT' THEN
    v_new_stock := v_current_stock - p_quantity;
    IF v_new_stock < 0 THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK: Không đủ tồn kho để xuất' USING ERRCODE = 'P0001';
    END IF;
  ELSIF v_normalized_type = 'ADJUST' THEN
    -- Ở chế độ kiểm kê, p_quantity chính là số lượng thực tế kiểm đếm được
    v_new_stock := p_quantity;
  ELSE
    -- WASTE / RETURN giữ nguyên balance
    v_new_stock := v_current_stock;
  END IF;

  -- 1. Ghi log vào inventory_transactions (giờ đã có unit_cost, supplier_id, balance_after)
  INSERT INTO public.inventory_transactions (
    branch_id, ingredient_id, type, quantity, balance_after,
    unit_cost, supplier_id, notes, created_by,
    reference_type
  ) VALUES (
    v_branch_id, p_ingredient_id, v_normalized_type, p_quantity, v_new_stock,
    COALESCE(p_unit_cost, 0), p_supplier_id, p_notes, auth.uid(),
    CASE WHEN p_supplier_id IS NOT NULL THEN 'PURCHASE_ORDER' ELSE 'MANUAL' END
  ) RETURNING id INTO v_transaction_id;

  -- 2. Upsert tồn kho mới vào inventory_stock (column updated_at chứ không phải last_updated)
  INSERT INTO public.inventory_stock (branch_id, ingredient_id, quantity, updated_at)
  VALUES (v_branch_id, p_ingredient_id, v_new_stock, now())
  ON CONFLICT (branch_id, ingredient_id)
  DO UPDATE SET
    quantity   = EXCLUDED.quantity,
    updated_at = EXCLUDED.updated_at;

  RETURN v_transaction_id;
END;
$$;

-- 2.6 get_revenue_report  (FIX: b.branch_id → bi.branch_id trong SELECT + GROUP BY)
CREATE OR REPLACE FUNCTION public.get_revenue_report(
  p_branch_id  uuid    DEFAULT NULL,
  p_start_date date    DEFAULT CURRENT_DATE,
  p_end_date   date    DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(row_to_json(t) ORDER BY t.total_revenue DESC)
    FROM (
      SELECT
        bi.branch_id,
        br.name                              AS branch_name,
        COUNT(DISTINCT bi.id)                AS bill_count,
        COALESCE(SUM(bi.grand_total), 0)     AS total_revenue,
        COALESCE(SUM(bi.vat_8_amount), 0)
          + COALESCE(SUM(bi.vat_10_amount), 0) AS total_vat,
        COALESCE(SUM(bi.discount_total), 0)  AS total_discount
      FROM public.bills bi
      JOIN public.branches br ON br.id = bi.branch_id
      WHERE bi.status = 'PAID'
        AND bi.created_at::date BETWEEN p_start_date AND p_end_date
        AND (p_branch_id IS NULL OR bi.branch_id = p_branch_id)
        AND (
          bi.branch_id = public.current_branch_id()
          OR public.has_role(ARRAY['admin']::user_role[])
        )
      GROUP BY bi.branch_id, br.name
    ) t
  );
END;
$$;

-- 2.7 create_reservation  (FIX: customer_id có thể NULL; INSERT dùng guest_name/guest_phone thực sự)
CREATE OR REPLACE FUNCTION public.create_reservation(
  p_branch_id        uuid,
  p_guest_name       text,
  p_guest_phone      text,
  p_reservation_time timestamptz,
  p_guests           int,
  p_notes            text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_res_id       uuid;
  v_booking_code text;
BEGIN
  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  v_booking_code := 'RES-' || to_char(p_reservation_time, 'MMDD') || '-'
                 || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.reservations (
    branch_id, booking_code, reservation_date, reservation_time, guests, status,
    customer_id, guest_name, guest_phone, source, notes
  ) VALUES (
    p_branch_id, v_booking_code, p_reservation_time::date, p_reservation_time::time,
    p_guests, 'Pending'::reservation_status,
    NULL, p_guest_name, p_guest_phone, 'Walk-in',
    CASE WHEN p_notes IS NULL THEN '{}'::jsonb
         ELSE jsonb_build_object('request', p_notes) END
  ) RETURNING id INTO v_res_id;

  RETURN v_res_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Re-grant EXECUTE — CREATE OR REPLACE không drop grant nhưng thói quen tốt
--    để chạy lại để rõ ràng (idempotent).
-- ─────────────────────────────────────────────────────────────────────────────

REVOKE EXECUTE ON FUNCTION public.get_suppliers()                          FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_suppliers()                          TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.get_ingredients()                        FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_ingredients()                        TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.get_current_stock(uuid)                  FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_current_stock(uuid)                  TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.get_inventory_transactions(uuid, int)    FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_inventory_transactions(uuid, int)    TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.record_inventory_transaction(uuid, text, numeric, numeric, uuid, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.record_inventory_transaction(uuid, text, numeric, numeric, uuid, text) TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.get_revenue_report(uuid, date, date)     FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_revenue_report(uuid, date, date)     TO   authenticated;

REVOKE EXECUTE ON FUNCTION public.create_reservation(uuid, text, text, timestamptz, int, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.create_reservation(uuid, text, text, timestamptz, int, text) TO   authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Reload PostgREST schema cache để supabase-js nhận enum/column mới ngay
-- ─────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';