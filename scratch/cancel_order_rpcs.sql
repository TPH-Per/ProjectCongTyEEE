-- ====================================================================
-- BE-2.6: hall_cancel_order_or_item  -- Hủy món với PIN Manager
-- BE-2.2: hall_get_checkout_totals   -- Lấy thông tin order/items cho table
-- ====================================================================

-- ─── 1. hall_get_checkout_totals ─────────────────────────────────────
-- Lấy order hiện tại + danh sách order_details cho 1 table
-- Frontend dùng để load trước khi show modal hủy món
CREATE OR REPLACE FUNCTION public.hall_get_checkout_totals(
  p_branch_id  uuid,
  p_table_id   uuid,
  p_order_id   uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_session_id uuid;
  v_order      jsonb;
  v_items      jsonb;
BEGIN
  -- Find the active dining session for this table
  SELECT ds.dining_session_id INTO v_session_id
  FROM   public.session_tables st
  JOIN   public.dining_sessions ds ON ds.dining_session_id = st.dining_session_id
  WHERE  st.table_id  = p_table_id
    AND  ds.branch_id = p_branch_id
    AND  ds.status    = 'open'
  ORDER  BY ds.opened_at DESC
  LIMIT  1;

  IF v_session_id IS NULL THEN
    RETURN jsonb_build_object('order', NULL, 'items', '[]'::jsonb);
  END IF;

  -- Get the active order (prefer passed order_id)
  SELECT row_to_json(o.*)::jsonb INTO v_order
  FROM   public.orders o
  WHERE  o.dining_session_id = v_session_id
    AND  o.branch_id = p_branch_id
    AND  (p_order_id IS NULL OR o.order_id = p_order_id)
    AND  o.status NOT IN ('cancelled', 'completed')
  ORDER  BY o.created_at DESC
  LIMIT  1;

  IF v_order IS NULL THEN
    RETURN jsonb_build_object('order', NULL, 'items', '[]'::jsonb);
  END IF;

  -- Get order details
  SELECT jsonb_agg(
    jsonb_build_object(
      'id',              od.order_detail_id,
      'menu_item_id',    od.branch_menu_item_id,
      'name_snapshot',   od.item_name_snapshot,
      'quantity',        od.quantity,
      'cancelled_qty',   od.cancelled_quantity,
      'unit_price',      od.unit_price_vnd_snapshot,
      'kitchen_status',  od.kitchen_status,
      'note',            od.note
    )
  ) INTO v_items
  FROM   public.order_details od
  WHERE  od.order_id  = (v_order->>'order_id')::uuid
    AND  od.branch_id = p_branch_id
    AND  od.cancelled_quantity < od.quantity;  -- only non-fully-cancelled

  RETURN jsonb_build_object(
    'order', v_order,
    'items', COALESCE(v_items, '[]'::jsonb)
  );
END;
$$;

-- ─── 2. hall_cancel_order_or_item ────────────────────────────────────
-- Hủy 1 order_detail (hoặc toàn bộ order). Verify PIN Manager trước.
-- Ghi log vào audit_logs. Trả về success/error JSON.
CREATE OR REPLACE FUNCTION public.hall_cancel_order_or_item(
  p_branch_id      uuid,
  p_order_id       uuid,
  p_order_item_id  uuid,            -- NULL = hủy toàn bộ order
  p_manager_pin    text,
  p_reason         text DEFAULT 'Không có lý do'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_manager_id   uuid;
  v_item         record;
  v_new_cancelled numeric;
BEGIN
  -- 1. Verify Manager PIN (fn_verify_manager_pin returns manager profile_id or NULL)
  SELECT public.fn_verify_manager_pin(p_manager_pin) INTO v_manager_id;
  IF v_manager_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'PIN_INVALID');
  END IF;

  IF p_order_item_id IS NOT NULL THEN
    -- ── Cancel single item ──────────────────────────────────────────
    SELECT * INTO v_item
    FROM   public.order_details
    WHERE  order_detail_id = p_order_item_id
      AND  order_id        = p_order_id
      AND  branch_id       = p_branch_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RETURN jsonb_build_object('success', false, 'error', 'ITEM_NOT_FOUND');
    END IF;

    v_new_cancelled := LEAST(v_item.quantity, v_item.cancelled_quantity + (v_item.quantity - v_item.cancelled_quantity));

    UPDATE public.order_details
    SET    cancelled_quantity    = v_new_cancelled,
           cancellation_reason  = p_reason,
           cancelled_by_profile_id = auth.uid(),
           approved_by_profile_id  = v_manager_id,
           cancelled_at         = now(),
           kitchen_status       = CASE WHEN v_new_cancelled >= quantity THEN 'cancelled' ELSE kitchen_status END,
           updated_at           = now()
    WHERE  order_detail_id = p_order_item_id;

  ELSE
    -- ── Cancel entire order ─────────────────────────────────────────
    UPDATE public.order_details
    SET    cancelled_quantity    = quantity,
           cancellation_reason  = p_reason,
           cancelled_by_profile_id = auth.uid(),
           approved_by_profile_id  = v_manager_id,
           cancelled_at         = now(),
           kitchen_status       = 'cancelled',
           updated_at           = now()
    WHERE  order_id   = p_order_id
      AND  branch_id  = p_branch_id
      AND  cancelled_quantity < quantity;

    UPDATE public.orders
    SET    status     = 'cancelled',
           updated_at = now()
    WHERE  order_id  = p_order_id
      AND  branch_id = p_branch_id;
  END IF;

  -- 2. Write audit log
  INSERT INTO public.audit_logs (
    branch_id, actor_profile_id, action, target_table, target_id, payload
  ) VALUES (
    p_branch_id,
    auth.uid(),
    'CANCEL_ORDER_ITEM',
    'order_details',
    COALESCE(p_order_item_id, p_order_id),
    jsonb_build_object(
      'order_id',       p_order_id,
      'item_id',        p_order_item_id,
      'reason',         p_reason,
      'approved_by',    v_manager_id,
      'cancelled_at',   now()
    )
  );

  RETURN jsonb_build_object(
    'success',      true,
    'approved_by',  v_manager_id,
    'item_id',      p_order_item_id,
    'order_id',     p_order_id
  );
END;
$$;

-- ─── Grants ──────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.hall_get_checkout_totals   TO authenticated;
GRANT EXECUTE ON FUNCTION public.hall_cancel_order_or_item  TO authenticated;

SELECT 'RPCs created: hall_get_checkout_totals, hall_cancel_order_or_item' AS result;
