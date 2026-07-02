-- =============================================================================
-- Hall + Customer / Tablet RPC baseline
-- =============================================================================
-- Goals:
-- - Move Hall/Tablet sensitive reads and writes behind RPC.
-- - Keep the current schema and business flow; no merge/split-bill redesign here.
-- - Do not trust frontend totals or menu prices.
-- - Keep checkout as the Hall -> Accounting boundary through process_checkout.

-- -----------------------------------------------------------------------------
-- Small additive tablet session fields used by the tablet flow.
-- -----------------------------------------------------------------------------
ALTER TABLE public.tablet_sessions
  ADD COLUMN IF NOT EXISTS order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS last_activity_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS tablet_sessions_active_table_idx
  ON public.tablet_sessions (branch_id, table_id, status, started_at DESC)
  WHERE ended_at IS NULL;

-- -----------------------------------------------------------------------------
-- Idempotency guard for tablet order submission.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tablet_order_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  table_id uuid NOT NULL REFERENCES public.tables(id) ON DELETE CASCADE,
  session_id uuid REFERENCES public.tablet_sessions(id) ON DELETE SET NULL,
  idempotency_key text NOT NULL,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  result jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, table_id, idempotency_key)
);

ALTER TABLE public.tablet_order_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tablet_order_submissions_branch_access" ON public.tablet_order_submissions;
CREATE POLICY "tablet_order_submissions_branch_access" ON public.tablet_order_submissions
FOR ALL TO authenticated
USING (
  public.has_role(ARRAY['admin']::public.user_role[])
  OR branch_id = public.current_branch_id()
)
WITH CHECK (
  public.has_role(ARRAY['admin']::public.user_role[])
  OR branch_id = public.current_branch_id()
);

CREATE INDEX IF NOT EXISTS tablet_order_submissions_session_idx
  ON public.tablet_order_submissions (session_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- Shared Hall/Customer branch guard.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hall_customer_assert_branch_access(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF p_branch_id IS NULL THEN
    RAISE EXCEPTION 'branch_id is required';
  END IF;

  IF NOT (
    public.has_role(ARRAY['admin']::public.user_role[])
    OR p_branch_id = public.current_branch_id()
  ) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_customer_assert_branch_access(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_customer_assert_branch_access(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- Customer / Tablet menu read RPCs.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.customer_list_menu_categories(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH ctx AS (
    SELECT COALESCE(p_branch_id, public.current_branch_id()) AS branch_id
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', mc.id,
      'branch_id', mc.branch_id,
      'name', mc.name,
      'sort_order', mc.sort_order,
      'is_active', mc.is_active,
      'color', mc.color,
      'metadata', mc.metadata
    )
    ORDER BY mc.sort_order, mc.name
  ), '[]'::jsonb)
  FROM public.menu_categories mc
  JOIN ctx ON ctx.branch_id = mc.branch_id
  WHERE mc.is_active = true
    AND (
      public.has_role(ARRAY['admin']::public.user_role[])
      OR mc.branch_id = public.current_branch_id()
    );
$$;

REVOKE EXECUTE ON FUNCTION public.customer_list_menu_categories(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_list_menu_categories(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_list_menu_items(
  p_branch_id uuid DEFAULT NULL,
  p_category_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH ctx AS (
    SELECT COALESCE(p_branch_id, public.current_branch_id()) AS branch_id
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', mi.id,
      'branch_id', mi.branch_id,
      'category_id', mi.category_id,
      'subcategory_id', mi.subcategory_id,
      'name', mi.name,
      'description', mi.description,
      'price', mi.price,
      'cost', mi.cost,
      'unit', mi.unit,
      'price_display', mi.price_display,
      'image_url', mi.image_url,
      'is_available', mi.is_available,
      'is_active', mi.is_active,
      'modifiers', mi.modifiers,
      'tags', mi.tags,
      'nutrition', mi.nutrition,
      'ingredients', COALESCE(mi.ingredients, '[]'::jsonb),
      'metadata', mi.metadata,
      'menu_categories', jsonb_build_object('name', mc.name)
    )
    ORDER BY mi.name
  ), '[]'::jsonb)
  FROM public.menu_items mi
  JOIN public.menu_categories mc ON mc.id = mi.category_id
  JOIN ctx ON ctx.branch_id = mi.branch_id
  WHERE mi.is_available = true
    AND mi.is_active = true
    AND (p_category_id IS NULL OR mi.category_id = p_category_id)
    AND (
      public.has_role(ARRAY['admin']::public.user_role[])
      OR mi.branch_id = public.current_branch_id()
    );
$$;

REVOKE EXECUTE ON FUNCTION public.customer_list_menu_items(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_list_menu_items(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_get_tablet_content(p_branch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', id,
      'branch_id', branch_id,
      'type', type,
      'content_type', type,
      'title', title,
      'title_vi', title,
      'title_en', title,
      'title_ja', title,
      'image_url', image_url,
      'video_url', video_url,
      'sort_order', sort_order,
      'display_order', sort_order,
      'is_active', is_active,
      'created_at', created_at
    )
    ORDER BY sort_order, created_at
  ), '[]'::jsonb)
  INTO v_result
  FROM public.tablet_content
  WHERE branch_id = p_branch_id
    AND is_active = true;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.customer_get_tablet_content(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_get_tablet_content(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_activate_tablet_session(
  p_branch_id uuid,
  p_table_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_table public.tables%ROWTYPE;
  v_session public.tablet_sessions%ROWTYPE;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  PERFORM pg_advisory_xact_lock(hashtext(p_table_id::text));

  SELECT * INTO v_table
  FROM public.tables
  WHERE id = p_table_id
    AND branch_id = p_branch_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table not found for branch';
  END IF;

  IF v_table.status NOT IN ('occupied', 'reserved') THEN
    RAISE EXCEPTION 'Tablet can only be activated for an occupied/reserved table';
  END IF;

  SELECT * INTO v_session
  FROM public.tablet_sessions
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND ended_at IS NULL
    AND status IN ('ACTIVE', 'CHECKOUT_REQUESTED')
  ORDER BY started_at DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    UPDATE public.tablet_sessions
    SET status = 'ACTIVE',
        last_activity_at = now()
    WHERE id = v_session.id
    RETURNING * INTO v_session;
  ELSE
    INSERT INTO public.tablet_sessions (
      branch_id, table_id, status, started_at, last_activity_at
    ) VALUES (
      p_branch_id, p_table_id, 'ACTIVE', now(), now()
    )
    RETURNING * INTO v_session;
  END IF;

  RETURN row_to_json(v_session)::jsonb;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.customer_activate_tablet_session(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_activate_tablet_session(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_set_tablet_language(
  p_session_id uuid,
  p_language text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_session public.tablet_sessions%ROWTYPE;
BEGIN
  IF p_language NOT IN ('vi', 'en', 'ja') THEN
    RAISE EXCEPTION 'Unsupported tablet language: %', p_language;
  END IF;

  SELECT * INTO v_session
  FROM public.tablet_sessions
  WHERE id = p_session_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tablet session not found';
  END IF;

  PERFORM public.hall_customer_assert_branch_access(v_session.branch_id);

  UPDATE public.tablet_sessions
  SET language = p_language,
      last_activity_at = now()
  WHERE id = p_session_id
  RETURNING * INTO v_session;

  RETURN row_to_json(v_session)::jsonb;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.customer_set_tablet_language(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_set_tablet_language(uuid, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- Customer order submission. Prices are read from menu_items in DB.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.customer_submit_table_order(
  p_branch_id uuid,
  p_table_id uuid,
  p_session_id uuid,
  p_items jsonb,
  p_idempotency_key text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_table public.tables%ROWTYPE;
  v_session public.tablet_sessions%ROWTYPE;
  v_order_id uuid;
  v_order_number text;
  v_item record;
  v_menu_item record;
  v_line_total numeric(14,2);
  v_subtotal numeric(14,2);
  v_result jsonb;
  v_key text;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'p_items must be a non-empty JSON array';
  END IF;

  v_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), md5(p_table_id::text || ':' || p_session_id::text || ':' || p_items::text));
  PERFORM pg_advisory_xact_lock(hashtext(p_branch_id::text || ':' || p_table_id::text || ':' || v_key));

  SELECT result INTO v_result
  FROM public.tablet_order_submissions
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND idempotency_key = v_key
    AND result IS NOT NULL;

  IF FOUND THEN
    RETURN v_result || jsonb_build_object('idempotent_replay', true);
  END IF;

  SELECT * INTO v_table
  FROM public.tables
  WHERE id = p_table_id
    AND branch_id = p_branch_id
    AND is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table not found for branch';
  END IF;

  IF v_table.status <> 'occupied' THEN
    RAISE EXCEPTION 'Table is not currently serving';
  END IF;

  SELECT * INTO v_session
  FROM public.tablet_sessions
  WHERE id = p_session_id
    AND branch_id = p_branch_id
    AND table_id = p_table_id
    AND ended_at IS NULL
    AND status = 'ACTIVE'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Active tablet session not found for this table';
  END IF;

  INSERT INTO public.tablet_order_submissions (
    branch_id, table_id, session_id, idempotency_key
  ) VALUES (
    p_branch_id, p_table_id, p_session_id, v_key
  )
  ON CONFLICT (branch_id, table_id, idempotency_key) DO NOTHING;

  SELECT id INTO v_order_id
  FROM public.orders
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND status IN ('Pending', 'Preparing', 'Served')
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    v_order_number := 'ORD-' || to_char(now(), 'YYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

    INSERT INTO public.orders (
      branch_id, table_id, reservation_id, customer_id,
      order_number, status, order_source, guest_count,
      subtotal, vat, vat_rate, discount, total
    ) VALUES (
      p_branch_id,
      p_table_id,
      v_session.reservation_id,
      v_session.customer_id,
      v_order_number,
      'Pending',
      'TABLET',
      COALESCE((v_table.metadata->'party_size'->>'male')::int, 0)
        + COALESCE((v_table.metadata->'party_size'->>'female')::int, 0)
        + COALESCE((v_table.metadata->'party_size'->>'children')::int, 0),
      0, 0, 0.08, 0, 0
    )
    RETURNING id INTO v_order_id;
  END IF;

  FOR v_item IN
    SELECT * FROM jsonb_to_recordset(p_items)
    AS x(menu_item_id uuid, quantity numeric, modifiers jsonb, note text)
  LOOP
    IF v_item.menu_item_id IS NULL THEN
      RAISE EXCEPTION 'menu_item_id is required';
    END IF;

    IF v_item.quantity IS NULL OR v_item.quantity <= 0 OR v_item.quantity > 99 THEN
      RAISE EXCEPTION 'quantity must be > 0 and <= 99';
    END IF;

    SELECT id, branch_id, name, price, cost, is_available, is_active
    INTO v_menu_item
    FROM public.menu_items
    WHERE id = v_item.menu_item_id
      AND branch_id = p_branch_id
      AND is_available = true
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu item % not found or unavailable for this branch', v_item.menu_item_id;
    END IF;

    v_line_total := v_item.quantity * v_menu_item.price;

    INSERT INTO public.order_items (
      branch_id, order_id, menu_item_id,
      name_snapshot, unit_price, unit_cost,
      quantity, line_total, status, modifiers, note
    ) VALUES (
      p_branch_id, v_order_id, v_menu_item.id,
      v_menu_item.name, v_menu_item.price, v_menu_item.cost,
      v_item.quantity, v_line_total, 'Pending',
      COALESCE(v_item.modifiers, '[]'::jsonb),
      NULLIF(left(COALESCE(v_item.note, ''), 500), '')
    );
  END LOOP;

  SELECT COALESCE(SUM(line_total), 0)
  INTO v_subtotal
  FROM public.order_items
  WHERE order_id = v_order_id
    AND status != 'Cancelled';

  UPDATE public.orders
  SET subtotal = v_subtotal,
      total = v_subtotal,
      updated_at = now()
  WHERE id = v_order_id;

  UPDATE public.tablet_sessions
  SET order_id = v_order_id,
      last_activity_at = now()
  WHERE id = p_session_id;

  v_result := jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'table_id', p_table_id,
    'session_id', p_session_id,
    'subtotal', v_subtotal,
    'total', v_subtotal
  );

  UPDATE public.tablet_order_submissions
  SET order_id = v_order_id,
      result = v_result
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND idempotency_key = v_key;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.customer_submit_table_order(uuid, uuid, uuid, jsonb, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_submit_table_order(uuid, uuid, uuid, jsonb, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_submit_table_order(
  p_branch_id uuid,
  p_table_id uuid,
  p_items jsonb,
  p_idempotency_key text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_table public.tables%ROWTYPE;
  v_order_id uuid;
  v_order_number text;
  v_item record;
  v_menu_item record;
  v_line_total numeric(14,2);
  v_subtotal numeric(14,2);
  v_result jsonb;
  v_key text;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  IF NOT public.has_role(ARRAY['admin','manager','reception','staff']::public.user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: Hall order submit requires staff/reception/manager/admin'
      USING ERRCODE = '28000';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'p_items must be a non-empty JSON array';
  END IF;

  v_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), md5(p_table_id::text || ':' || p_items::text));
  PERFORM pg_advisory_xact_lock(hashtext(p_branch_id::text || ':' || p_table_id::text || ':' || v_key));

  SELECT result INTO v_result
  FROM public.tablet_order_submissions
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND idempotency_key = v_key
    AND result IS NOT NULL;

  IF FOUND THEN
    RETURN v_result || jsonb_build_object('idempotent_replay', true);
  END IF;

  SELECT * INTO v_table
  FROM public.tables
  WHERE id = p_table_id
    AND branch_id = p_branch_id
    AND is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table not found for branch';
  END IF;

  IF v_table.status <> 'occupied' THEN
    RAISE EXCEPTION 'Hall can submit orders only for occupied tables';
  END IF;

  INSERT INTO public.tablet_order_submissions (
    branch_id, table_id, session_id, idempotency_key
  ) VALUES (
    p_branch_id, p_table_id, NULL, v_key
  )
  ON CONFLICT (branch_id, table_id, idempotency_key) DO NOTHING;

  SELECT id INTO v_order_id
  FROM public.orders
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND status IN ('Pending', 'Preparing', 'Served')
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    v_order_number := 'ORD-' || to_char(now(), 'YYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

    INSERT INTO public.orders (
      branch_id, table_id, reservation_id,
      order_number, status, order_source, guest_count,
      subtotal, vat, vat_rate, discount, total
    ) VALUES (
      p_branch_id,
      p_table_id,
      NULLIF(v_table.metadata->>'reservation_id', '')::uuid,
      v_order_number,
      'Pending',
      'STAFF',
      COALESCE((v_table.metadata->'party_size'->>'male')::int, 0)
        + COALESCE((v_table.metadata->'party_size'->>'female')::int, 0)
        + COALESCE((v_table.metadata->'party_size'->>'children')::int, 0),
      0, 0, 0.08, 0, 0
    )
    RETURNING id INTO v_order_id;
  END IF;

  FOR v_item IN
    SELECT * FROM jsonb_to_recordset(p_items)
    AS x(menu_item_id uuid, quantity numeric, modifiers jsonb, note text)
  LOOP
    IF v_item.menu_item_id IS NULL THEN
      RAISE EXCEPTION 'menu_item_id is required';
    END IF;

    IF v_item.quantity IS NULL OR v_item.quantity <= 0 OR v_item.quantity > 99 THEN
      RAISE EXCEPTION 'quantity must be > 0 and <= 99';
    END IF;

    SELECT id, branch_id, name, price, cost, is_available, is_active
    INTO v_menu_item
    FROM public.menu_items
    WHERE id = v_item.menu_item_id
      AND branch_id = p_branch_id
      AND is_available = true
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu item % not found or unavailable for this branch', v_item.menu_item_id;
    END IF;

    v_line_total := v_item.quantity * v_menu_item.price;

    INSERT INTO public.order_items (
      branch_id, order_id, menu_item_id,
      name_snapshot, unit_price, unit_cost,
      quantity, line_total, status, modifiers, note
    ) VALUES (
      p_branch_id, v_order_id, v_menu_item.id,
      v_menu_item.name, v_menu_item.price, v_menu_item.cost,
      v_item.quantity, v_line_total, 'Pending',
      COALESCE(v_item.modifiers, '[]'::jsonb),
      NULLIF(left(COALESCE(v_item.note, ''), 500), '')
    );
  END LOOP;

  SELECT COALESCE(SUM(line_total), 0)
  INTO v_subtotal
  FROM public.order_items
  WHERE order_id = v_order_id
    AND status != 'Cancelled';

  UPDATE public.orders
  SET subtotal = v_subtotal,
      total = v_subtotal,
      updated_at = now()
  WHERE id = v_order_id;

  v_result := jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'table_id', p_table_id,
    'subtotal', v_subtotal,
    'total', v_subtotal
  );

  UPDATE public.tablet_order_submissions
  SET order_id = v_order_id,
      result = v_result
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND idempotency_key = v_key;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_submit_table_order(uuid, uuid, jsonb, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_submit_table_order(uuid, uuid, jsonb, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- Service requests. Schema statuses are mapped as:
-- OPEN = pending, IN_PROGRESS = acknowledged, RESOLVED = completed.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_service_request(
  p_branch_id uuid,
  p_table_id uuid,
  p_type text,
  p_message text DEFAULT NULL,
  p_order_id uuid DEFAULT NULL,
  p_priority text DEFAULT 'NORMAL',
  p_session_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_table public.tables%ROWTYPE;
  v_session public.tablet_sessions%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_request public.service_requests%ROWTYPE;
  v_type text;
  v_priority text;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  v_type := upper(trim(p_type));
  v_priority := upper(COALESCE(NULLIF(trim(p_priority), ''), 'NORMAL'));

  IF v_type NOT IN ('CALL_WAITER', 'REQUEST_BILL', 'REQUEST_CONDIMENT', 'COMPLAINT', 'OTHER') THEN
    RAISE EXCEPTION 'Unsupported service request type: %', p_type;
  END IF;

  IF v_priority NOT IN ('NORMAL', 'URGENT') THEN
    RAISE EXCEPTION 'Unsupported service request priority: %', p_priority;
  END IF;

  SELECT * INTO v_table
  FROM public.tables
  WHERE id = p_table_id
    AND branch_id = p_branch_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table not found for branch';
  END IF;

  IF p_session_id IS NOT NULL THEN
    SELECT * INTO v_session
    FROM public.tablet_sessions
    WHERE id = p_session_id
      AND branch_id = p_branch_id
      AND table_id = p_table_id
      AND ended_at IS NULL
      AND status IN ('ACTIVE', 'CHECKOUT_REQUESTED');

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Active tablet session not found for this table';
    END IF;
  END IF;

  IF p_order_id IS NOT NULL THEN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
      AND branch_id = p_branch_id
      AND table_id = p_table_id
      AND status IN ('Pending', 'Preparing', 'Served');

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Active order not found for this table';
    END IF;
  ELSE
    SELECT * INTO v_order
    FROM public.orders
    WHERE branch_id = p_branch_id
      AND table_id = p_table_id
      AND status IN ('Pending', 'Preparing', 'Served')
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  SELECT * INTO v_request
  FROM public.service_requests
  WHERE branch_id = p_branch_id
    AND table_id = p_table_id
    AND type = v_type
    AND status IN ('OPEN', 'IN_PROGRESS')
    AND (
      (v_order.id IS NULL AND order_id IS NULL)
      OR order_id = v_order.id
    )
  ORDER BY created_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN row_to_json(v_request)::jsonb || jsonb_build_object('deduped', true);
  END IF;

  INSERT INTO public.service_requests (
    branch_id, table_id, order_id, type, status, message, priority
  ) VALUES (
    p_branch_id,
    p_table_id,
    v_order.id,
    v_type,
    'OPEN',
    NULLIF(left(COALESCE(p_message, ''), 500), ''),
    v_priority
  )
  RETURNING * INTO v_request;

  IF p_session_id IS NOT NULL AND v_type = 'REQUEST_BILL' THEN
    UPDATE public.tablet_sessions
    SET status = 'CHECKOUT_REQUESTED',
        last_activity_at = now()
    WHERE id = p_session_id;
  END IF;

  RETURN row_to_json(v_request)::jsonb || jsonb_build_object('deduped', false);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_service_request(uuid, uuid, text, text, uuid, text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_service_request(uuid, uuid, text, text, uuid, text, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_list_service_requests(
  p_branch_id uuid DEFAULT NULL,
  p_statuses text[] DEFAULT ARRAY['OPEN', 'IN_PROGRESS']
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  PERFORM public.hall_customer_assert_branch_access(v_branch_id);

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', sr.id,
      'branch_id', sr.branch_id,
      'table_id', sr.table_id,
      'table_code', t.code,
      'order_id', sr.order_id,
      'type', sr.type,
      'status', sr.status,
      'message', sr.message,
      'priority', sr.priority,
      'resolved_by', sr.resolved_by,
      'resolved_at', sr.resolved_at,
      'created_at', sr.created_at
    )
    ORDER BY sr.created_at DESC
  ), '[]'::jsonb)
  INTO v_result
  FROM public.service_requests sr
  JOIN public.tables t ON t.id = sr.table_id
  WHERE sr.branch_id = v_branch_id
    AND sr.status = ANY(p_statuses);

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_list_service_requests(uuid, text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_list_service_requests(uuid, text[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_ack_service_request(p_request_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_request public.service_requests%ROWTYPE;
BEGIN
  SELECT * INTO v_request
  FROM public.service_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service request not found';
  END IF;

  PERFORM public.hall_customer_assert_branch_access(v_request.branch_id);

  IF v_request.status = 'RESOLVED' THEN
    RETURN row_to_json(v_request)::jsonb;
  END IF;

  UPDATE public.service_requests
  SET status = 'IN_PROGRESS'
  WHERE id = p_request_id
  RETURNING * INTO v_request;

  RETURN row_to_json(v_request)::jsonb;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_ack_service_request(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_ack_service_request(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_complete_service_request(p_request_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_request public.service_requests%ROWTYPE;
BEGIN
  SELECT * INTO v_request
  FROM public.service_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service request not found';
  END IF;

  PERFORM public.hall_customer_assert_branch_access(v_request.branch_id);

  UPDATE public.service_requests
  SET status = 'RESOLVED',
      resolved_by = auth.uid(),
      resolved_at = now()
  WHERE id = p_request_id
  RETURNING * INTO v_request;

  RETURN row_to_json(v_request)::jsonb;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_complete_service_request(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_complete_service_request(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- Hall table/floor and checkout summary reads.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hall_list_tables(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  PERFORM public.hall_customer_assert_branch_access(v_branch_id);

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'branch_id', t.branch_id,
      'zone_id', t.zone_id,
      'zone', z.name,
      'code', t.code,
      'capacity', t.capacity,
      'shape', t.shape,
      'pos_x', t.pos_x,
      'pos_y', t.pos_y,
      'status', t.status,
      'is_active', t.is_active,
      'metadata', t.metadata,
      'created_at', t.created_at,
      'updated_at', t.updated_at,
      'active_order', odata.order_info,
      'open_service_requests', COALESCE(srdata.open_count, 0)
    )
    ORDER BY z.sort_order, t.code
  ), '[]'::jsonb)
  INTO v_result
  FROM public.tables t
  JOIN public.zones z ON z.id = t.zone_id
  LEFT JOIN LATERAL (
    SELECT jsonb_build_object(
      'order_id', o.id,
      'order_number', o.order_number,
      'status', o.status,
      'guest_count', o.guest_count,
      'subtotal', o.subtotal,
      'created_at', o.created_at
    ) AS order_info
    FROM public.orders o
    WHERE o.table_id = t.id
      AND o.status IN ('Pending', 'Preparing', 'Served')
    ORDER BY o.created_at DESC
    LIMIT 1
  ) odata ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::int AS open_count
    FROM public.service_requests sr
    WHERE sr.table_id = t.id
      AND sr.status IN ('OPEN', 'IN_PROGRESS')
  ) srdata ON true
  WHERE t.branch_id = v_branch_id
    AND t.is_active = true;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_list_tables(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_list_tables(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_list_packages(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  PERFORM public.hall_customer_assert_branch_access(v_branch_id);

  SELECT COALESCE(jsonb_agg(row_to_json(p)::jsonb ORDER BY p.name), '[]'::jsonb)
  INTO v_result
  FROM public.packages p
  WHERE p.branch_id = v_branch_id
    AND p.is_active = true;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_list_packages(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_list_packages(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_floor_plan(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := COALESCE(p_branch_id, public.current_branch_id());
  PERFORM public.hall_customer_assert_branch_access(v_branch_id);

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'zone_id', z.id,
      'zone_name', z.name,
      'sort_order', z.sort_order,
      'tables', COALESCE(tdata.tables, '[]'::jsonb)
    )
    ORDER BY z.sort_order
  ), '[]'::jsonb)
  INTO v_result
  FROM public.zones z
  LEFT JOIN LATERAL (
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'table_number', t.code,
        'code', t.code,
        'capacity', t.capacity,
        'status', t.status,
        'active_order', odata.order_info
      )
      ORDER BY t.code
    ), '[]'::jsonb) AS tables
    FROM public.tables t
    LEFT JOIN LATERAL (
      SELECT jsonb_build_object(
        'order_id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'guest_count', o.guest_count,
        'subtotal', o.subtotal
      ) AS order_info
      FROM public.orders o
      WHERE o.table_id = t.id
        AND o.status IN ('Pending', 'Preparing', 'Served')
      ORDER BY o.created_at DESC
      LIMIT 1
    ) odata ON true
    WHERE t.zone_id = z.id
      AND t.branch_id = v_branch_id
      AND t.is_active = true
  ) tdata ON true
  WHERE z.branch_id = v_branch_id
    AND z.is_active = true;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_floor_plan(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_floor_plan(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_get_checkout_summary(
  p_branch_id uuid,
  p_table_id uuid DEFAULT NULL,
  p_order_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_table public.tables%ROWTYPE;
  v_items jsonb;
  v_subtotal numeric(14,2);
  v_discount numeric(14,2);
  v_vat_rate numeric(5,4);
  v_vat_amount numeric(14,2);
  v_grand_total numeric(14,2);
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  IF p_order_id IS NULL AND p_table_id IS NULL THEN
    RAISE EXCEPTION 'Either p_order_id or p_table_id is required';
  END IF;

  IF p_order_id IS NOT NULL THEN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
      AND branch_id = p_branch_id
      AND status IN ('Pending', 'Preparing', 'Served')
    FOR UPDATE;
  ELSE
    SELECT * INTO v_order
    FROM public.orders
    WHERE table_id = p_table_id
      AND branch_id = p_branch_id
      AND status IN ('Pending', 'Preparing', 'Served')
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE;
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'table', NULL,
      'order', NULL,
      'items', '[]'::jsonb,
      'summary', jsonb_build_object(
        'subtotal', 0,
        'discount', 0,
        'vat_rate', 0,
        'vat', 0,
        'grand_total', 0
      )
    );
  END IF;

  IF v_order.table_id IS NOT NULL THEN
    SELECT * INTO v_table FROM public.tables WHERE id = v_order.table_id;
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', oi.id,
      'branch_id', oi.branch_id,
      'order_id', oi.order_id,
      'menu_item_id', oi.menu_item_id,
      'name_snapshot', oi.name_snapshot,
      'unit_price', oi.unit_price,
      'unit_cost', oi.unit_cost,
      'quantity', oi.quantity,
      'line_total', oi.line_total,
      'status', oi.status,
      'modifiers', oi.modifiers,
      'note', oi.note,
      'metadata', oi.metadata,
      'created_at', oi.created_at,
      'updated_at', oi.updated_at
    )
    ORDER BY oi.created_at
  ), '[]'::jsonb),
  COALESCE(SUM(CASE WHEN oi.status != 'Cancelled' THEN oi.line_total ELSE 0 END), 0)
  INTO v_items, v_subtotal
  FROM public.order_items oi
  WHERE oi.order_id = v_order.id;

  v_discount := COALESCE(v_order.discount, 0);
  v_vat_rate := COALESCE(v_order.vat_rate, 0.08);
  v_vat_amount := ROUND(GREATEST(0, v_subtotal - v_discount) * v_vat_rate, 0);
  v_grand_total := GREATEST(0, v_subtotal - v_discount) + v_vat_amount;

  RETURN jsonb_build_object(
    'table', CASE WHEN v_table.id IS NULL THEN NULL ELSE row_to_json(v_table)::jsonb END,
    'order', row_to_json(v_order)::jsonb,
    'items', v_items,
    'summary', jsonb_build_object(
      'subtotal', v_subtotal,
      'discount', v_discount,
      'vat_rate', v_vat_rate,
      'vat', v_vat_amount,
      'grand_total', v_grand_total
    )
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_get_checkout_summary(uuid, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_get_checkout_summary(uuid, uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_get_active_shift(p_branch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  SELECT row_to_json(s)::jsonb
  INTO v_result
  FROM public.shifts s
  WHERE s.branch_id = p_branch_id
    AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_get_active_shift(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_get_active_shift(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- Reservation read used by the Reception dashboard. Status mutations remain
-- intentionally small; full reservation check-in stays in the existing Edge flow.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hall_list_reservations_by_date(
  p_branch_id uuid,
  p_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  SELECT COALESCE(jsonb_agg(row_to_json(r)::jsonb ORDER BY r.reservation_time), '[]'::jsonb)
  INTO v_result
  FROM public.reservations r
  WHERE r.branch_id = p_branch_id
    AND r.reservation_date = p_date;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_list_reservations_by_date(uuid, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_list_reservations_by_date(uuid, date) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_reservation_stats(p_date date DEFAULT CURRENT_DATE)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid;
  v_result jsonb;
BEGIN
  v_branch_id := public.current_branch_id();
  PERFORM public.hall_customer_assert_branch_access(v_branch_id);

  SELECT jsonb_build_object(
    'total', COUNT(*),
    'pending', COUNT(*) FILTER (WHERE status = 'Pending'),
    'seated', COUNT(*) FILTER (WHERE status IN ('Arrived', 'Dining')),
    'completed', COUNT(*) FILTER (WHERE status = 'Completed')
  )
  INTO v_result
  FROM public.reservations
  WHERE branch_id = v_branch_id
    AND reservation_date = p_date;

  RETURN COALESCE(v_result, jsonb_build_object('total', 0, 'pending', 0, 'seated', 0, 'completed', 0));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_reservation_stats(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_reservation_stats(date) TO authenticated;

CREATE OR REPLACE FUNCTION public.hall_update_reservation_status(
  p_reservation_id uuid,
  p_status public.reservation_status,
  p_table_id uuid DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_res public.reservations%ROWTYPE;
BEGIN
  SELECT * INTO v_res
  FROM public.reservations
  WHERE id = p_reservation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found';
  END IF;

  PERFORM public.hall_customer_assert_branch_access(v_res.branch_id);

  IF p_status = 'Cancelled' THEN
    UPDATE public.reservations
    SET status = p_status,
        cancelled_at = now(),
        cancel_reason = NULLIF(left(COALESCE(p_reason, ''), 500), ''),
        updated_at = now()
    WHERE id = p_reservation_id
    RETURNING * INTO v_res;
  ELSIF p_status = 'Arrived' THEN
    UPDATE public.reservations
    SET status = p_status,
        arrived_at = COALESCE(arrived_at, now()),
        updated_at = now()
    WHERE id = p_reservation_id
    RETURNING * INTO v_res;
  ELSIF p_status = 'Dining' THEN
    UPDATE public.reservations
    SET status = p_status,
        arrived_at = COALESCE(arrived_at, now()),
        seated_at = COALESCE(seated_at, now()),
        updated_at = now()
    WHERE id = p_reservation_id
    RETURNING * INTO v_res;

    IF p_table_id IS NOT NULL THEN
      UPDATE public.tables
      SET status = 'occupied',
          metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('reservation_id', p_reservation_id)
      WHERE id = p_table_id
        AND branch_id = v_res.branch_id
        AND status IN ('available', 'reserved');
    END IF;
  ELSIF p_status = 'Completed' THEN
    UPDATE public.reservations
    SET status = p_status,
        completed_at = COALESCE(completed_at, now()),
        updated_at = now()
    WHERE id = p_reservation_id
    RETURNING * INTO v_res;
  ELSE
    UPDATE public.reservations
    SET status = p_status,
        updated_at = now()
    WHERE id = p_reservation_id
    RETURNING * INTO v_res;
  END IF;

  RETURN row_to_json(v_res)::jsonb;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_update_reservation_status(uuid, public.reservation_status, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_update_reservation_status(uuid, public.reservation_status, uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.confirm_reservation(
  p_reservation_id uuid,
  p_table_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.hall_update_reservation_status(p_reservation_id, 'Arrived'::public.reservation_status, p_table_id, NULL);
$$;

CREATE OR REPLACE FUNCTION public.seat_reservation(
  p_reservation_id uuid,
  p_table_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.hall_update_reservation_status(p_reservation_id, 'Dining'::public.reservation_status, p_table_id, NULL);
$$;

REVOKE EXECUTE ON FUNCTION public.confirm_reservation(uuid, uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seat_reservation(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_reservation(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.seat_reservation(uuid, uuid) TO authenticated;
