-- ============================================================================
-- customer_create_self_service_order
--
-- SECURITY DEFINER RPC that lets an anonymous tablet customer place an order
-- without a staff JWT. The function:
--   1. Resolves branch + table from short codes
--   2. Finds or creates a dining_session (idempotent via p_session_token)
--   3. Links the table to the session (session_tables)
--   4. Creates an order (order_source = 'tablet', status = 'submitted')
--   5. Inserts order_details for each cart item (looks up price/VAT from
--      branch_menu_items)
--   6. Computes subtotal / VAT / total
--   7. Inserts a notification row so the reception dashboard beeps
--   8. Returns JSONB with order_id, order_number, session_id, totals
--
-- Parameters match the call in src/services/customerApi.ts:
--   p_branch_code   TEXT   -- e.g. 'B001'
--   p_table_code    TEXT   -- e.g. 'A05'
--   p_items         JSONB  -- [{ menu_item_id, quantity, modifiers, note }]
--   p_session_token TEXT   -- dining_session UUID (idempotency anchor)
--   p_customer_name TEXT   -- optional, currently unused
-- ============================================================================

CREATE OR REPLACE FUNCTION public.customer_create_self_service_order(
  p_branch_code   TEXT,
  p_table_code    TEXT,
  p_items         JSONB,
  p_session_token TEXT,
  p_customer_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_branch_id           UUID;
  v_table_id            UUID;
  v_session_id          UUID;
  v_order_id            UUID;
  v_order_number        TEXT;
  v_shift_id            UUID;
  v_item                JSONB;
  v_branch_menu_item_id UUID;
  v_item_name           TEXT;
  v_unit_price          BIGINT;
  v_vat_rate            NUMERIC(7,4);
  v_quantity            NUMERIC(14,3);
  v_detail_no           INTEGER := 0;
  v_detail_total        BIGINT;
  v_vat_amount          BIGINT;
  v_subtotal            BIGINT := 0;
  v_vat_total           BIGINT := 0;
  v_total               BIGINT := 0;
  v_modifiers           JSONB;
BEGIN
  -- ── 1. Resolve branch ──────────────────────────────────────────────
  SELECT branch_id INTO v_branch_id
  FROM public.branches
  WHERE branch_code = p_branch_code
    AND is_active = true;
  IF v_branch_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'Branch not found: ' || p_branch_code
    );
  END IF;

  -- ── 2. Resolve table ───────────────────────────────────────────────
  SELECT dining_table_id INTO v_table_id
  FROM public.dining_tables
  WHERE branch_id  = v_branch_id
    AND table_code = p_table_code
    AND is_active  = true;
  IF v_table_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'Table not found: ' || p_table_code
    );
  END IF;

  -- ── 3. Find or create dining_session ───────────────────────────────

  -- 3a. Try by session token (if valid UUID)
  IF p_session_token IS NOT NULL
     AND p_session_token ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    SELECT dining_session_id INTO v_session_id
    FROM public.dining_sessions
    WHERE dining_session_id = p_session_token::uuid
      AND branch_id = v_branch_id
      AND status IN ('open', 'ordering', 'checkout_requested');
  END IF;

  -- 3b. Try by active session_table for this table
  IF v_session_id IS NULL THEN
    SELECT ds.dining_session_id INTO v_session_id
    FROM public.dining_sessions ds
    JOIN public.session_tables  st ON st.dining_session_id = ds.dining_session_id
    WHERE ds.branch_id        = v_branch_id
      AND st.dining_table_id  = v_table_id
      AND st.left_at IS NULL
      AND ds.status IN ('open', 'ordering');
  END IF;

  -- 3c. Create new session if none found
  IF v_session_id IS NULL THEN
    INSERT INTO public.dining_sessions (
      branch_id, guest_count, service_mode, language_code,
      status, opened_at
    ) VALUES (
      v_branch_id, 1, 'buffet', 'vi', 'open', now()
    )
    RETURNING dining_session_id INTO v_session_id;

    -- Link table to session
    INSERT INTO public.session_tables (
      branch_id, dining_session_id, dining_table_id, is_primary, joined_at
    ) VALUES (
      v_branch_id, v_session_id, v_table_id, true, now()
    )
    ON CONFLICT DO NOTHING;  -- table might already be linked
  END IF;

  -- Update session status to 'ordering' if it was 'open'
  UPDATE public.dining_sessions
  SET status       = 'ordering',
      updated_at   = now()
  WHERE dining_session_id = v_session_id
    AND status = 'open';

  -- ── 4. Resolve active shift (optional, for reporting) ──────────────
  SELECT shift_id INTO v_shift_id
  FROM public.shifts
  WHERE branch_id = v_branch_id
    AND status     = 'open';

  -- ── 5. Generate order number ───────────────────────────────────────
  v_order_number := 'ORD-' || to_char(now(), 'YYYYMMDD') || '-'
    || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));

  -- ── 6. Create order ────────────────────────────────────────────────
  INSERT INTO public.orders (
    branch_id, dining_session_id, shift_id,
    order_number, order_source, status,
    submitted_at, created_at
  ) VALUES (
    v_branch_id, v_session_id, v_shift_id,
    v_order_number, 'tablet', 'submitted',
    now(), now()
  )
  RETURNING order_id INTO v_order_id;

  -- ── 7. Insert order_details ────────────────────────────────────────
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- Look up branch_menu_item by menu_item_id
    SELECT bmi.branch_menu_item_id,
           COALESCE(bmi.local_name, mi.item_name),
           bmi.base_price_vnd,
           bmi.vat_rate
      INTO v_branch_menu_item_id, v_item_name, v_unit_price, v_vat_rate
    FROM public.branch_menu_items bmi
    JOIN public.menu_items        mi ON mi.menu_item_id = bmi.menu_item_id
    WHERE bmi.menu_item_id = (v_item->>'menu_item_id')::uuid
      AND bmi.branch_id    = v_branch_id
      AND bmi.is_active    = true;

    -- Skip items that don't exist (validation should have caught them,
    -- but defend in depth)
    IF v_branch_menu_item_id IS NULL THEN
      CONTINUE;
    END IF;

    v_detail_no    := v_detail_no + 1;
    v_quantity     := COALESCE((v_item->>'quantity')::numeric, 1);
    v_detail_total := (v_unit_price * v_quantity)::bigint;
    v_vat_amount   := ((v_detail_total * v_vat_rate) / 100)::bigint;

    -- modifiers must be a JSON object per schema constraint
    v_modifiers := CASE
      WHEN jsonb_typeof(v_item->'modifiers') = 'object'
        THEN v_item->'modifiers'
      ELSE '{}'::jsonb
    END;

    INSERT INTO public.order_details (
      branch_id, order_id, detail_no, branch_menu_item_id,
      item_name_snapshot, quantity, chargeable_quantity,
      unit_price_vnd_snapshot, vat_rate_snapshot, detail_total_vnd,
      kitchen_status, modifiers, note, created_at
    ) VALUES (
      v_branch_id, v_order_id, v_detail_no, v_branch_menu_item_id,
      v_item_name, v_quantity, v_quantity,
      v_unit_price, v_vat_rate, v_detail_total,
      'new', v_modifiers, v_item->>'note', now()
    );

    v_subtotal  := v_subtotal  + v_detail_total;
    v_vat_total := v_vat_total + v_vat_amount;
  END LOOP;

  v_total := v_subtotal + v_vat_total;

  -- ── 8. Notification for reception dashboard ────────────────────────
  INSERT INTO public.notifications (
    branch_id, notification_type, payload
  ) VALUES (
    v_branch_id,
    'new_order',
    jsonb_build_object(
      'table_code',    p_table_code,
      'order_id',      v_order_id,
      'order_number',  v_order_number,
      'session_id',    v_session_id,
      'item_count',    v_detail_no,
      'total_vnd',     v_total
    )
  );

  -- ── 9. Return result ───────────────────────────────────────────────
  RETURN jsonb_build_object(
    'success',      true,
    'order_id',     v_order_id,
    'order_number', v_order_number,
    'session_id',   v_session_id,
    'subtotal',     v_subtotal,
    'vat',          v_vat_total,
    'total',        v_total
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_create_self_service_order(
  TEXT, TEXT, JSONB, TEXT, TEXT
) TO anon, authenticated;

-- ============================================================================
-- customer_list_menu_items
--
-- Returns active menu items for a branch, optionally filtered by category.
-- Used by the customer tablet to load the menu and by getRawMenuItems()
-- in customerApi.ts to remap mock template IDs to real DB UUIDs.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.customer_list_menu_items(
  p_branch_id   UUID,
  p_category_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id            UUID,
  name          TEXT,
  price         BIGINT,
  price_display TEXT,
  category_id   UUID,
  category_name TEXT,
  item_type     TEXT,
  image_url     TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    bmi.branch_menu_item_id                           AS id,
    COALESCE(bmi.local_name, mi.item_name)            AS name,
    bmi.base_price_vnd                                AS price,
    COALESCE(
      bmi.display_config->>'price_display',
      bmi.base_price_vnd::text || 'đ'
    )                                                 AS price_display,
    mc.menu_category_id                               AS category_id,
    mc.category_name                                  AS category_name,
    mi.item_type                                      AS item_type,
    mi.image_url                                      AS image_url
  FROM public.branch_menu_items bmi
  JOIN public.menu_items        mi ON mi.menu_item_id     = bmi.menu_item_id
  JOIN public.menu_categories   mc ON mc.menu_category_id = mi.menu_category_id
  WHERE bmi.branch_id           = p_branch_id
    AND bmi.is_active            = true
    AND bmi.availability_status  = 'available'
    AND mi.is_active              = true
    AND (p_category_id IS NULL OR mi.menu_category_id = p_category_id)
  ORDER BY mc.sort_order, mi.item_name;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_list_menu_items(UUID, UUID)
  TO anon, authenticated;

-- ============================================================================
-- customer_create_session
--
-- Creates a dining_session for a tablet customer. Called when the customer
-- selects a table and service mode. Returns the session row.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.customer_create_session(
  p_branch_id    UUID,
  p_table_id     UUID,
  p_package_id   UUID DEFAULT NULL,
  p_adult_count  INTEGER DEFAULT 1,
  p_child_count  INTEGER DEFAULT 0,
  p_opened_by    TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session_id UUID;
  v_guest_count INTEGER;
BEGIN
  v_guest_count := p_adult_count + p_child_count;
  IF v_guest_count < 1 THEN
    v_guest_count := 1;
  END IF;

  INSERT INTO public.dining_sessions (
    branch_id, guest_count, service_mode, language_code,
    status, opened_at
  ) VALUES (
    p_branch_id, v_guest_count, 'buffet', 'vi', 'open', now()
  )
  RETURNING dining_session_id INTO v_session_id;

  -- Link table to session
  INSERT INTO public.session_tables (
    branch_id, dining_session_id, dining_table_id, is_primary, joined_at
  ) VALUES (
    p_branch_id, v_session_id, p_table_id, true, now()
  )
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object(
    'id',         v_session_id,
    'branch_id',  p_branch_id,
    'created_at', now()
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_create_session(
  UUID, UUID, UUID, INTEGER, INTEGER, TEXT
) TO anon, authenticated;
