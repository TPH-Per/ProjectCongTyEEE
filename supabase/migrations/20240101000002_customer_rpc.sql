CREATE OR REPLACE FUNCTION public.customer_list_packages(p_branch_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  "priceAdult" bigint,
  "priceChild" bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.menu_item_id as id,
    m.item_name as name,
    bmi.base_price_vnd as "priceAdult",
    -- Fallback for child price: 50% of adult price if not specified in display_config
    COALESCE(
      (bmi.display_config->>'priceChild')::bigint,
      (bmi.base_price_vnd / 2)::bigint
    ) as "priceChild"
  FROM public.menu_items m
  JOIN public.branch_menu_items bmi ON bmi.menu_item_id = m.menu_item_id
  WHERE bmi.branch_id = p_branch_id
    AND m.item_type = 'buffet_package'
    AND bmi.is_active = true
    AND m.is_active = true
    AND bmi.availability_status = 'available';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.customer_list_packages(uuid) TO anon, authenticated;
