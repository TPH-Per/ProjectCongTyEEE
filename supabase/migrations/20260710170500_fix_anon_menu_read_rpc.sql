-- Migration: Fix anonymous access to menu categories and items
-- Date: 2026-07-10
--
-- Why: Customers accessing the tablet/self-service ordering flow run as the 'anon' role.
-- The functions `customer_list_menu_categories` and `customer_list_menu_items` were previously
-- restricted to authenticated users only and filtered by `public.current_branch_id()`,
-- which returned NULL for anonymous sessions. This prevented mapping the template's mock IDs
-- to their real database UUIDs and led to "invalid input syntax for type uuid" errors.

-- 1. Update customer_list_menu_categories
CREATE OR REPLACE FUNCTION public.customer_list_menu_categories(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH ctx AS (
    SELECT COALESCE(p_branch_id, public.current_branch_id()) AS branch_id
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', mc.id,
      'branch_id', mc.branch_id,
      'name', mc.name,
      'sort_order', mc.sort_order,
      'is_active', mc.is_active,
      'color', mc.color,
      'metadata', mc.metadata
    )
    ORDER BY mc.sort_order, mc.name
  ), '[]'::jsonb)
  FROM public.menu_categories mc
  JOIN ctx ON ctx.branch_id = mc.branch_id
  WHERE mc.is_active = true
    AND (
      public.has_role(ARRAY['admin']::public.user_role[])
      OR mc.branch_id = public.current_branch_id()
      OR auth.uid() IS NULL
    );
$$;

REVOKE EXECUTE ON FUNCTION public.customer_list_menu_categories(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_list_menu_categories(uuid) TO anon, authenticated;

-- 2. Update customer_list_menu_items
CREATE OR REPLACE FUNCTION public.customer_list_menu_items(
  p_branch_id uuid DEFAULT NULL,
  p_category_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH ctx AS (
    SELECT COALESCE(p_branch_id, public.current_branch_id()) AS branch_id
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', mi.id,
      'branch_id', mi.branch_id,
      'category_id', mi.category_id,
      'subcategory_id', mi.subcategory_id,
      'name', mi.name,
      'description', mi.description,
      'price', mi.price,
      'cost', mi.cost,
      'unit', mi.unit,
      'price_display', mi.price_display,
      'image_url', mi.image_url,
      'is_available', mi.is_available,
      'is_active', mi.is_active,
      'modifiers', mi.modifiers,
      'tags', mi.tags,
      'nutrition', mi.nutrition,
      'ingredients', COALESCE(mi.ingredients, '[]'::jsonb),
      'metadata', mi.metadata,
      'menu_categories', jsonb_build_object('name', mc.name)
    )
    ORDER BY mi.name
  ), '[]'::jsonb)
  FROM public.menu_items mi
  JOIN public.menu_categories mc ON mc.id = mi.category_id
  JOIN ctx ON ctx.branch_id = mi.branch_id
  WHERE mi.is_available = true
    AND mi.is_active = true
    AND (p_category_id IS NULL OR mi.category_id = p_category_id)
    AND (
      public.has_role(ARRAY['admin']::public.user_role[])
      OR mi.branch_id = public.current_branch_id()
      OR auth.uid() IS NULL
    );
$$;

REVOKE EXECUTE ON FUNCTION public.customer_list_menu_items(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.customer_list_menu_items(uuid, uuid) TO anon, authenticated;
