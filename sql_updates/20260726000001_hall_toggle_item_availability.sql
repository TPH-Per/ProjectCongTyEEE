CREATE OR REPLACE FUNCTION public.hall_toggle_item_availability(
  p_branch_id uuid,
  p_item_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_status text;
  v_new_status text;
BEGIN
  -- Validate inputs
  IF p_branch_id IS NULL OR p_item_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Missing required parameters');
  END IF;

  -- Get current status
  SELECT availability_status INTO v_current_status
  FROM public.branch_menu_items
  WHERE branch_id = p_branch_id AND menu_item_id = p_item_id;

  IF v_current_status IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Menu item not found in this branch');
  END IF;

  -- Toggle
  IF v_current_status = 'available' THEN
    v_new_status := 'out_of_stock';
  ELSE
    v_new_status := 'available';
  END IF;

  -- Update
  UPDATE public.branch_menu_items
  SET availability_status = v_new_status,
      updated_at = now()
  WHERE branch_id = p_branch_id AND menu_item_id = p_item_id;

  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Availability toggled successfully',
    'new_status', v_new_status
  );
END;
$$;

-- Grant execute to reception and hall roles
GRANT EXECUTE ON FUNCTION public.hall_toggle_item_availability TO reception;
GRANT EXECUTE ON FUNCTION public.hall_toggle_item_availability TO hall;
