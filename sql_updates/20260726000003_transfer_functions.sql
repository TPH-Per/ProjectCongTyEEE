CREATE OR REPLACE FUNCTION public.rpc_transfer_table_partial(
  p_branch_id uuid,
  p_source_table_id uuid,
  p_target_table_id uuid,
  p_items jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_source_session_id uuid;
  v_target_status text;
  v_target_session_id uuid;
  v_source_order_id uuid;
  v_target_order_id uuid;
  v_item record;
  v_source_qty integer;
  v_transfer_qty integer;
  v_detail_id uuid;
  v_source_detail record;
  v_existing_target_detail uuid;
BEGIN
  -- 1. Check source table
  SELECT dining_session_id INTO v_source_session_id
  FROM public.session_tables
  WHERE dining_table_id = p_source_table_id AND left_at IS NULL
  LIMIT 1;

  IF v_source_session_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Source table has no active session');
  END IF;

  -- 2. Check target table status
  SELECT availability_status INTO v_target_status
  FROM public.dining_tables
  WHERE dining_table_id = p_target_table_id AND branch_id = p_branch_id;

  IF v_target_status IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Target table not found');
  END IF;

  IF p_source_table_id = p_target_table_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Cannot transfer to the same table');
  END IF;

  -- 3. Get source order
  SELECT order_id INTO v_source_order_id
  FROM public.orders
  WHERE dining_session_id = v_source_session_id AND branch_id = p_branch_id AND status NOT IN ('cancelled', 'completed')
  ORDER BY created_at DESC LIMIT 1;

  IF v_source_order_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No active order found for source table');
  END IF;

  -- 4. Get or Create target session and order
  IF v_target_status = 'available' THEN
    -- Create new session
    INSERT INTO public.dining_sessions (branch_id, status)
    VALUES (p_branch_id, 'open')
    RETURNING dining_session_id INTO v_target_session_id;

    -- Assign to table
    INSERT INTO public.session_tables (branch_id, dining_session_id, dining_table_id, is_primary)
    VALUES (p_branch_id, v_target_session_id, p_target_table_id, true);

    -- Create new order
    INSERT INTO public.orders (branch_id, dining_session_id, status)
    VALUES (p_branch_id, v_target_session_id, 'draft')
    RETURNING order_id INTO v_target_order_id;

    -- Update table status
    UPDATE public.dining_tables SET availability_status = 'occupied' WHERE dining_table_id = p_target_table_id;
  ELSE
    -- Find existing active session
    SELECT dining_session_id INTO v_target_session_id
    FROM public.session_tables
    WHERE dining_table_id = p_target_table_id AND left_at IS NULL
    LIMIT 1;

    IF v_target_session_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'Target table is occupied but has no active session');
    END IF;

    -- Get target order
    SELECT order_id INTO v_target_order_id
    FROM public.orders
    WHERE dining_session_id = v_target_session_id AND branch_id = p_branch_id AND status NOT IN ('cancelled', 'completed')
    ORDER BY created_at DESC LIMIT 1;

    IF v_target_order_id IS NULL THEN
      INSERT INTO public.orders (branch_id, dining_session_id, status)
      VALUES (p_branch_id, v_target_session_id, 'draft')
      RETURNING order_id INTO v_target_order_id;
    END IF;
  END IF;

  -- 5. Move items
  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(order_detail_id uuid, quantity integer)
  LOOP
    v_detail_id := v_item.order_detail_id;
    v_transfer_qty := v_item.quantity;

    IF v_transfer_qty <= 0 THEN
      CONTINUE;
    END IF;

    -- Get source detail
    SELECT * INTO v_source_detail
    FROM public.order_details
    WHERE order_detail_id = v_detail_id AND order_id = v_source_order_id;

    IF v_source_detail.order_detail_id IS NULL THEN
      CONTINUE;
    END IF;

    v_source_qty := v_source_detail.quantity - COALESCE(v_source_detail.cancelled_quantity, 0);
    
    IF v_transfer_qty > v_source_qty THEN
      v_transfer_qty := v_source_qty;
    END IF;

    -- Check if target order already has this exact item (same menu_item_id, note)
    SELECT order_detail_id INTO v_existing_target_detail
    FROM public.order_details
    WHERE order_id = v_target_order_id 
      AND branch_menu_item_id = v_source_detail.branch_menu_item_id
      AND COALESCE(note, '') = COALESCE(v_source_detail.note, '')
    LIMIT 1;

    IF v_existing_target_detail IS NOT NULL THEN
      -- Update existing
      UPDATE public.order_details
      SET quantity = quantity + v_transfer_qty, updated_at = now()
      WHERE order_detail_id = v_existing_target_detail;
    ELSE
      -- Insert new
      INSERT INTO public.order_details (
        branch_id, order_id, branch_menu_item_id, quantity, unit_price_vnd_snapshot, item_name_snapshot, note
      ) VALUES (
        p_branch_id, v_target_order_id, v_source_detail.branch_menu_item_id, v_transfer_qty, v_source_detail.unit_price_vnd_snapshot, v_source_detail.item_name_snapshot, v_source_detail.note
      );
    END IF;

    -- Deduct from source
    IF v_transfer_qty = v_source_detail.quantity THEN
      -- Full transfer of this line -> delete
      DELETE FROM public.order_details WHERE order_detail_id = v_detail_id;
    ELSE
      UPDATE public.order_details
      SET quantity = quantity - v_transfer_qty, updated_at = now()
      WHERE order_detail_id = v_detail_id;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Partial transfer successful');
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_transfer_table_partial TO authenticated;
