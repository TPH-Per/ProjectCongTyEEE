DO $$ 
DECLARE
  v_branch_id uuid;
  v_cat_id uuid;
  v_menu_item_id uuid;
  v_branch_menu_item_id uuid;
BEGIN
  -- Get first branch
  SELECT branch_id INTO v_branch_id FROM branches LIMIT 1;
  
  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'No branches found';
  END IF;

  -- Ensure category "Phí phạt" exists
  SELECT menu_category_id INTO v_cat_id FROM menu_categories WHERE category_name = 'Phí phạt' AND owner_branch_id = v_branch_id;
  
  IF v_cat_id IS NULL THEN
    INSERT INTO menu_categories (owner_branch_id, category_name, display_order, is_active)
    VALUES (v_branch_id, 'Phí phạt', 99, true)
    RETURNING menu_category_id INTO v_cat_id;
  END IF;

  -- Ensure menu_item exists
  SELECT menu_item_id INTO v_menu_item_id FROM menu_items WHERE item_code = 'WASTE_PENALTY' AND owner_branch_id = v_branch_id;
  
  IF v_menu_item_id IS NULL THEN
    INSERT INTO menu_items (owner_branch_id, menu_category_id, item_code, item_name, item_type, unit_name, is_active)
    VALUES (v_branch_id, v_cat_id, 'WASTE_PENALTY', 'Phạt đồ ăn thừa', 'ALACARTE', 'Lần', true)
    RETURNING menu_item_id INTO v_menu_item_id;
  END IF;

  -- Ensure branch_menu_item exists
  SELECT branch_menu_item_id INTO v_branch_menu_item_id FROM branch_menu_items WHERE menu_item_id = v_menu_item_id AND branch_id = v_branch_id;
  
  IF v_branch_menu_item_id IS NULL THEN
    INSERT INTO branch_menu_items (branch_id, menu_item_id, local_name, base_price_vnd, vat_rate, availability_status, is_active)
    VALUES (v_branch_id, v_menu_item_id, 'Phạt đồ ăn thừa', 50000, 8.0, 'AVAILABLE', true);
  END IF;
  
END $$;
