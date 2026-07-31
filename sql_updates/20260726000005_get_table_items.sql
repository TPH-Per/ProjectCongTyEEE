CREATE OR REPLACE FUNCTION public.rpc_get_table_order_items(p_table_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session_id uuid;
  v_order_id uuid;
  v_result jsonb;
BEGIN
  -- Get active session
  SELECT dining_session_id INTO v_session_id
  FROM public.session_tables
  WHERE dining_table_id = p_table_id AND left_at IS NULL
  LIMIT 1;

  IF v_session_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Get active order
  SELECT order_id INTO v_order_id
  FROM public.orders
  WHERE dining_session_id = v_session_id AND status NOT IN ('cancelled', 'completed')
  ORDER BY created_at DESC LIMIT 1;

  IF v_order_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Return items
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'order_detail_id', od.order_detail_id,
      'branch_menu_item_id', od.branch_menu_item_id,
      'quantity', od.quantity - COALESCE(od.cancelled_quantity, 0),
      'item_name', COALESCE(od.item_name_snapshot, m.name),
      'note', od.note
    )
  ), '[]'::jsonb) INTO v_result
  FROM public.order_details od
  LEFT JOIN public.branch_menu_items bmi ON od.branch_menu_item_id = bmi.branch_menu_item_id
  LEFT JOIN public.menu_items m ON bmi.menu_item_id = m.menu_item_id
  WHERE od.order_id = v_order_id AND (od.quantity - COALESCE(od.cancelled_quantity, 0)) > 0;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_get_table_order_items TO authenticated;
