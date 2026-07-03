-- Migration: customer self-service order (URL-based, no JWT)
--
-- Why this exists: prior to this migration, the `/customer/menu` UI in the
-- Vite app wrote through an in-memory mock (`src/services/customerApi.ts`)
-- that never touched the database. That broke every cross-side flow:
--   - admin floors didn't see the table change colour
--   - cashier OrderView didn't see the items the customer picked
--   - CRM module never saw the order (its `crm_link_surveys_to_bill`
--     helper is order_id-driven and an order_id never existed)
--
-- This RPC is callable from the ANON role because the customer tablet
-- experience is a URL-driven, no-login flow (you scan the QR on the table
-- and immediately land on the menu). SECURITY DEFINER + branch-scoped
-- checks keep it safe: a malicious caller cannot reach any data outside
-- the (branch, table) pair encoded in the URL.
--
-- The RPC mirrors the staff `add-order-item` flow that already exists:
--   - validates the (branch, table) tuple and acquires an advisory lock
--   - activates a tablet_session if none exists for this table
--   - marks the table `occupied` (idempotent — only if currently
--     'available')
--   - inserts an `orders` row + bulk `order_items` lines
--   - recomputes subtotal / VAT / total (VAT = 8% per Ishii 02/07/2026)
--   - emits a `notifications` row with template = 'new_order' so the
--     reception dashboard (already subscribed via `useRealtime`) beeps
--   - creates a `crm_surveys` row in 'assigned' state so the CRM
--     `Serving Tables` view lists the table and
--     `process_checkout → crm_link_surveys_to_bill` can stamp the bill
--     later even when the manager hasn't filled the survey yet
--
-- All of this runs inside one transaction so the customer never sees a
-- partial state where the order exists but the notification hasn't been
-- emitted. NOTE: schema column quirks — `tablet_sessions` has no
-- `metadata` column; `orders` has `notes` not `metadata`. The migration
-- adapts to the live schema.

CREATE OR REPLACE FUNCTION public.customer_create_self_service_order(
  p_branch_code          text,
  p_table_code           text,
  p_items                jsonb,
  p_session_token        text DEFAULT NULL,
  p_customer_name        text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch public.branches%ROWTYPE;
  v_table   public.tables%ROWTYPE;
  v_order_id uuid;
  v_order_number text;
  v_session public.tablet_sessions%ROWTYPE;
  v_item record;
  v_menu_item record;
  v_line_total numeric(14,2);
  v_subtotal numeric(14,2);
  v_vat numeric(14,2);
  v_total numeric(14,2);
  v_notification_id uuid;
  v_vat_rate numeric(5,4) := 0.08;
  v_token text;
  v_now timestamptz := now();
BEGIN
  -- 1. Resolve branch by short code.
  SELECT * INTO v_branch
  FROM public.branches
  WHERE code = p_branch_code
    AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Branch not found or inactive: %', p_branch_code
      USING ERRCODE = 'P0001';
  END IF;

  -- 2. Resolve the table by short code. `FOR UPDATE` serialises against
  --    concurrent staff actions (check-in, table-swap, etc.).
  SELECT * INTO v_table
  FROM public.tables
  WHERE branch_id = v_branch.id
    AND code = p_table_code
    AND is_active = true
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table % not found in branch %', p_table_code, p_branch_code
      USING ERRCODE = 'P0001';
  END IF;

  IF v_table.status = 'maintenance' THEN
    RAISE EXCEPTION 'Table % is under maintenance', p_table_code
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Reject empty carts.
  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'p_items must be a non-empty JSON array'
      USING ERRCODE = 'P0001';
  END IF;

  -- 4. Idempotency key.
  v_token := COALESCE(
    NULLIF(trim(p_session_token), ''),
    md5(v_branch.id::text || ':' || v_table.id::text || ':' || p_items::text)
  );
  PERFORM pg_advisory_xact_lock(hashtext(v_branch.id::text || ':' || v_table.id::text || ':' || v_token));

  -- 5. Activate or create a `tablet_sessions` row.
  SELECT * INTO v_session
  FROM public.tablet_sessions
  WHERE branch_id = v_branch.id
    AND table_id = v_table.id
    AND ended_at IS NULL
    AND status IN ('ACTIVE', 'CHECKOUT_REQUESTED')
  ORDER BY started_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.tablet_sessions (
      branch_id, table_id, status, started_at, last_activity_at, language
    ) VALUES (
      v_branch.id, v_table.id, 'ACTIVE', v_now, v_now, 'vi'
    )
    RETURNING * INTO v_session;

    -- First-time session opens: flip table to occupied once.
    IF v_table.status = 'available' THEN
      UPDATE public.tables
      SET status = 'occupied',
          metadata = COALESCE(v_table.metadata, '{}'::jsonb)
            || jsonb_build_object('occupied_at', v_now, 'opened_by', 'customer_self_service')
      WHERE id = v_table.id;
    END IF;
  END IF;

  -- 6. Create or reuse the open order for this table.
  SELECT id INTO v_order_id
  FROM public.orders
  WHERE branch_id = v_branch.id
    AND table_id = v_table.id
    AND status IN ('Pending', 'Preparing', 'Served')
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_order_id IS NULL THEN
    v_order_number := 'ORD-' || to_char(v_now, 'YYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

    INSERT INTO public.orders (
      branch_id, table_id, order_number, status,
      order_source, guest_count, subtotal, vat, vat_rate, discount, total,
      notes, created_at, updated_at
    ) VALUES (
      v_branch.id, v_table.id, v_order_number, 'Pending',
      'TABLET',
      COALESCE(NULLIF(v_table.metadata->>'party_size', '')::int, 1),
      0, 0, v_vat_rate, 0, 0,
      jsonb_build_object('self_service', true, 'opened_via', 'customer_self_service'),
      v_now, v_now
    )
    RETURNING id INTO v_order_id;
  END IF;

  -- 7. Bulk insert order_items + recompute subtotal/VAT/total.
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

    SELECT id, branch_id, name, price, cost, is_available
    INTO v_menu_item
    FROM public.menu_items
    WHERE id = v_item.menu_item_id
      AND branch_id = v_branch.id
      AND is_available = true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu item % not available in branch %',
        v_item.menu_item_id, v_branch.code;
    END IF;

    v_line_total := round(v_item.quantity * v_menu_item.price, 2);

    INSERT INTO public.order_items (
      branch_id, order_id, menu_item_id,
      name_snapshot, unit_price, unit_cost,
      quantity, line_total, status, modifiers, note,
      created_at, updated_at
    ) VALUES (
      v_branch.id, v_order_id, v_menu_item.id,
      v_menu_item.name, v_menu_item.price, v_menu_item.cost,
      v_item.quantity, v_line_total, 'Pending',
      COALESCE(v_item.modifiers, '[]'::jsonb),
      NULLIF(left(COALESCE(v_item.note, ''), 500), ''),
      v_now, v_now
    );
  END LOOP;

  -- Totals — exclude cancelled lines (same as cashier preview).
  SELECT COALESCE(SUM(line_total), 0)
    INTO v_subtotal
    FROM public.order_items
    WHERE order_id = v_order_id
      AND status != 'Cancelled';

  v_vat := round(v_subtotal * v_vat_rate, 2);
  v_total := v_subtotal + v_vat;

  UPDATE public.orders
  SET subtotal = v_subtotal,
      vat = v_vat,
      total = v_total,
      updated_at = v_now
  WHERE id = v_order_id;

  -- 8. Emit a `notifications` row so the reception dashboard beeps.
  --    Same template the staff `add-order-item` Edge Function uses;
  --    the dashboard is unaware of (and indifferent to) whether the
  --    order came from a tablet or a customer URL.
  INSERT INTO public.notifications (
    branch_id, channel, recipient, template, variables, status, sent_at,
    metadata, created_at
  ) VALUES (
    v_branch.id,
    'reception-panel',
    'reception',
    'new_order',
    jsonb_build_object(
      'table_id', v_table.id,
      'table_code', v_table.code,
      'order_id', v_order_id,
      'source', 'customer_self_service',
      'message', format('Bàn %s vừa gọi món (khách tự phục vụ)', v_table.code)
    ),
    'sent', v_now,
    jsonb_build_object('source', 'customer-create-order', 'order_id', v_order_id),
    v_now
  )
  RETURNING id INTO v_notification_id;

  -- 9. Auto-create the CRM survey row so the manager sees the table
  --    in CRMServingTablesView and can fill customer info later.
  --    The partial unique index `crm_surveys_one_active_per_order`
  --    guards against duplicate active surveys per order. We do the
  --    dedup with a NOT EXISTS check rather than ON CONFLICT because
  --    the index's predicate (`order_id IS NOT NULL AND survey_status
  --    IN ('assigned','in_progress','completed')`) includes the
  --    `order_id IS NOT NULL` clause, which makes the exact ON
  --    CONFLICT WHERE clause awkward in plpgsql. The NOT EXISTS form
  --    is just as idempotent and avoids that subtlety.
  BEGIN
    INSERT INTO public.crm_surveys (
      branch_id, table_id, order_id, customer_name, reservation_id,
      survey_status, asked_at, created_at, updated_at
    )
    SELECT v_branch.id, v_table.id, v_order_id,
           NULLIF(trim(p_customer_name), ''),
           NULL,
           'assigned', v_now, v_now, v_now
    WHERE NOT EXISTS (
      SELECT 1 FROM public.crm_surveys cs
      WHERE cs.order_id = v_order_id
        AND cs.survey_status IN ('assigned','in_progress','completed')
    );
  EXCEPTION WHEN OTHERS THEN
    -- CRM auto-row is best-effort. If it fails (e.g. partial unique
    -- index missing on a hot migration path), the order itself still
    -- succeeds. The manager can still create the survey manually.
    RAISE WARNING '[customer_create_self_service_order] crm_surveys auto-insert failed: %', SQLERRM;
  END;

  -- 10. Update the tablet_session to point at this order.
  UPDATE public.tablet_sessions
  SET order_id = v_order_id,
      last_activity_at = v_now
  WHERE id = v_session.id;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'order_number', v_order_number,
    'session_id', v_session.id,
    'table_id', v_table.id,
    'table_code', v_table.code,
    'branch_id', v_branch.id,
    'branch_code', v_branch.code,
    'subtotal', v_subtotal,
    'vat', v_vat,
    'total', v_total,
    'notification_id', v_notification_id,
    'items_count', jsonb_array_length(p_items)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.customer_create_self_service_order(text, text, jsonb, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_create_self_service_order(text, text, jsonb, text, text)
  TO anon, authenticated;

COMMENT ON FUNCTION public.customer_create_self_service_order(text, text, jsonb, text, text) IS
  'Customer self-service URL flow: takes (branchCode, tableCode, items, sessionToken, customerName), '
  'marks the table occupied, opens a tablet_session + orders row + order_items in one transaction, '
  'emits a `new_order` notification for the reception dashboard, and auto-creates a `crm_surveys` '
  'row so the CRM Serving Tables view + process_checkout -> crm_link_surveys_to_bill chain work.';
