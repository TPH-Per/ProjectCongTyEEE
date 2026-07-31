-- ==============================================================================
-- F2TECH SQL Update Script
-- Tasks: BE-2.4 (Hủy món/Hủy Order) & BE-2.5 (Chuyển bàn/Ghép bàn)
-- ==============================================================================

-- 1. Helper function to verify Manager PIN
CREATE OR REPLACE FUNCTION public.fn_verify_manager_pin(p_manager_pin text)
RETURNS uuid AS $$
DECLARE
  v_profile_id uuid;
  v_role_code text;
BEGIN
  -- Lấy profile_id của user hiện tại
  v_profile_id := auth.uid();
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Kiểm tra staff_assignments xem có mã PIN hash khớp không
  SELECT r.role_code INTO v_role_code
  FROM public.staff_assignments sa
  JOIN public.roles r ON sa.role_id = r.role_id
  WHERE sa.profile_id = v_profile_id
    AND sa.approval_pin_hash = p_manager_pin
    AND sa.is_active = true
    AND sa.ended_at IS NULL
  LIMIT 1;

  IF v_role_code IS NULL THEN
    RAISE EXCEPTION 'Invalid Manager PIN or insufficient permissions';
  END IF;

  RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- BE-2.4: API Hủy 1 món (Cập nhật cancelled_quantity và lý do)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.rpc_cancel_order_item(
  p_order_detail_id uuid,
  p_cancel_quantity numeric,
  p_reason text,
  p_manager_pin text
) RETURNS jsonb AS $$
DECLARE
  v_manager_profile_id uuid;
  v_current_quantity numeric;
  v_current_cancelled numeric;
BEGIN
  v_manager_profile_id := public.fn_verify_manager_pin(p_manager_pin);

  SELECT quantity, cancelled_quantity INTO v_current_quantity, v_current_cancelled
  FROM public.order_details
  WHERE order_detail_id = p_order_detail_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order detail not found';
  END IF;

  IF p_cancel_quantity <= 0 OR (v_current_cancelled + p_cancel_quantity) > v_current_quantity THEN
    RAISE EXCEPTION 'Invalid cancel quantity. Cannot cancel more than ordered quantity.';
  END IF;

  UPDATE public.order_details
  SET 
    cancelled_quantity = cancelled_quantity + p_cancel_quantity,
    cancellation_reason = p_reason,
    cancelled_by_profile_id = auth.uid(),
    approved_by_profile_id = v_manager_profile_id,
    cancelled_at = now(),
    updated_at = now()
  WHERE order_detail_id = p_order_detail_id;

  RETURN jsonb_build_object('success', true, 'message', 'Item cancelled successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- BE-2.4: API Hủy toàn bộ Order
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.rpc_cancel_full_order(
  p_order_id uuid,
  p_reason text,
  p_manager_pin text
) RETURNS jsonb AS $$
DECLARE
  v_manager_profile_id uuid;
BEGIN
  v_manager_profile_id := public.fn_verify_manager_pin(p_manager_pin);

  UPDATE public.orders
  SET 
    status = 'cancelled',
    note = COALESCE(note, '') || ' | Cancelled reason: ' || p_reason,
    updated_at = now()
  WHERE order_id = p_order_id;

  UPDATE public.order_details
  SET 
    cancelled_quantity = quantity,
    cancellation_reason = p_reason,
    cancelled_by_profile_id = auth.uid(),
    approved_by_profile_id = v_manager_profile_id,
    cancelled_at = now(),
    updated_at = now()
  WHERE order_id = p_order_id
    AND cancelled_quantity < quantity;

  RETURN jsonb_build_object('success', true, 'message', 'Order cancelled successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- BE-2.5: API Chuyển Bàn & Ghép Bàn
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.rpc_transfer_or_merge_table(
  p_source_session_id uuid,
  p_target_table_id uuid
) RETURNS jsonb AS $$
DECLARE
  v_target_status text;
  v_target_session_id uuid;
  v_source_table_id uuid;
BEGIN
  SELECT availability_status INTO v_target_status
  FROM public.dining_tables
  WHERE dining_table_id = p_target_table_id;

  IF v_target_status IS NULL THEN
    RAISE EXCEPTION 'Target table not found';
  END IF;

  SELECT dining_table_id INTO v_source_table_id
  FROM public.session_tables
  WHERE dining_session_id = p_source_session_id AND left_at IS NULL AND is_primary = true
  LIMIT 1;

  IF v_target_status = 'available' THEN
    -- TH1: CHUYỂN BÀN
    UPDATE public.session_tables SET left_at = now() WHERE dining_session_id = p_source_session_id AND left_at IS NULL;
    
    INSERT INTO public.session_tables (branch_id, dining_session_id, dining_table_id, is_primary)
    SELECT branch_id, p_source_session_id, p_target_table_id, true
    FROM public.dining_sessions WHERE dining_session_id = p_source_session_id;

    UPDATE public.dining_tables SET availability_status = 'available' WHERE dining_table_id = v_source_table_id;
    UPDATE public.dining_tables SET availability_status = 'occupied' WHERE dining_table_id = p_target_table_id;

    RETURN jsonb_build_object('success', true, 'action', 'transfer', 'message', 'Table transferred successfully');
  ELSE
    -- TH2: GHÉP BÀN
    SELECT dining_session_id INTO v_target_session_id
    FROM public.session_tables
    WHERE dining_table_id = p_target_table_id AND left_at IS NULL
    LIMIT 1;

    IF v_target_session_id IS NULL THEN
      RAISE EXCEPTION 'Target table is marked as occupied but has no active session';
    END IF;

    UPDATE public.orders SET dining_session_id = v_target_session_id, updated_at = now() WHERE dining_session_id = p_source_session_id;

    UPDATE public.dining_sessions
    SET status = 'merged', closed_at = now(), updated_at = now(),
        note = COALESCE(note, '') || ' | Merged into session: ' || v_target_session_id::text
    WHERE dining_session_id = p_source_session_id;

    UPDATE public.session_tables SET left_at = now() WHERE dining_session_id = p_source_session_id;
    UPDATE public.dining_tables SET availability_status = 'available' WHERE dining_table_id = v_source_table_id;

    RETURN jsonb_build_object('success', true, 'action', 'merge', 'message', 'Tables merged successfully');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
