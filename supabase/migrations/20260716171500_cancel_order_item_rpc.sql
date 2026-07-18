-- Migration to add cancellation API for orders and order items requiring Manager PIN
-- Task BE-2.6: Backend API Hủy món / Hủy Order (Yêu cầu PIN Manager)

CREATE OR REPLACE FUNCTION public.hall_cancel_order_or_item(
  p_branch_id uuid,
  p_order_id uuid,
  p_order_item_id uuid DEFAULT NULL,
  p_manager_pin text DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_table public.tables%ROWTYPE;
  v_subtotal numeric(14,2);
  v_result jsonb;
BEGIN
  -- 1. Assert branch access
  PERFORM public.hall_customer_assert_branch_access(p_branch_id);

  -- 2. Verify manager PIN (Default is '1234' as hardcoded in frontend)
  IF p_manager_pin <> '1234' THEN
    RAISE EXCEPTION 'INVALID_PIN: Mã PIN xác thực của Quản lý không chính xác.' USING ERRCODE = 'P0001';
  END IF;

  -- 3. Check order exists and is not closed/paid
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id AND branch_id = p_branch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND: Không tìm thấy đơn hàng.' USING ERRCODE = 'P0002';
  END IF;

  IF v_order.status IN ('Paid', 'Cancelled') THEN
    RAISE EXCEPTION 'ORDER_CLOSED: Đơn hàng đã được thanh toán hoặc đã hủy trước đó.' USING ERRCODE = 'P0003';
  END IF;

  -- 4. Execute cancellation logic
  IF p_order_item_id IS NOT NULL THEN
    -- Cancel specific order item
    UPDATE public.order_items
    SET status = 'Cancelled'::public.order_status,
        note = COALESCE(note, '') || ' [Hủy: ' || COALESCE(p_reason, '') || ']',
        updated_at = now()
    WHERE id = p_order_item_id AND order_id = p_order_id AND branch_id = p_branch_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ITEM_NOT_FOUND: Không tìm thấy món ăn trong đơn hàng.' USING ERRCODE = 'P0004';
    END IF;

    -- Recalculate order subtotal and total
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_subtotal
    FROM public.order_items
    WHERE order_id = p_order_id AND status <> 'Cancelled';

    UPDATE public.orders
    SET subtotal = v_subtotal,
        total = v_subtotal,
        updated_at = now()
    WHERE id = p_order_id;

    v_result := jsonb_build_object(
      'success', true,
      'order_id', p_order_id,
      'cancelled_item_id', p_order_item_id,
      'subtotal', v_subtotal,
      'total', v_subtotal
    );
  ELSE
    -- Cancel the entire order
    UPDATE public.order_items
    SET status = 'Cancelled'::public.order_status,
        updated_at = now()
    WHERE order_id = p_order_id AND branch_id = p_branch_id;

    UPDATE public.orders
    SET status = 'Cancelled'::public.order_status,
        subtotal = 0,
        total = 0,
        cancelled_at = now(),
        cancel_reason = p_reason,
        updated_at = now()
    WHERE id = p_order_id;

    -- Free up the table
    IF v_order.table_id IS NOT NULL THEN
      SELECT * INTO v_table
      FROM public.tables
      WHERE id = v_order.table_id AND branch_id = p_branch_id
      FOR UPDATE;

      IF FOUND THEN
        UPDATE public.tables
        SET status = 'available',
            metadata = metadata - 'reservation_id' - 'party_size',
            updated_at = now()
        WHERE id = v_order.table_id;
      END IF;
    END IF;

    v_result := jsonb_build_object(
      'success', true,
      'order_id', p_order_id,
      'cancelled_entire_order', true,
      'subtotal', 0,
      'total', 0
    );
  END IF;

  -- Write audit event
  INSERT INTO public.audit_events (
    branch_id,
    actor_id,
    entity_type,
    entity_id,
    action,
    payload,
    created_at
  ) VALUES (
    p_branch_id,
    auth.uid(),
    'order',
    p_order_id,
    CASE WHEN p_order_item_id IS NOT NULL THEN 'order.cancel_item' ELSE 'order.cancel_order' END,
    v_result || jsonb_build_object('reason', p_reason),
    now()
  );

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.hall_cancel_order_or_item(uuid, uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hall_cancel_order_or_item(uuid, uuid, uuid, text, text) TO authenticated;
