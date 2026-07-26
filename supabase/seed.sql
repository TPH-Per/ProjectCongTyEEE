-- NGUU CAT POS - AUTO GENERATED SEED
BEGIN;

-- 1. Create a Branch
DO $$
DECLARE
    v_branch_id uuid := '00000000-0000-4000-8000-000000000000'::uuid;
BEGIN
    INSERT INTO public.branches (branch_id, branch_code, branch_name, address, is_active)
    VALUES (v_branch_id, 'BR01', 'Ngưu Cát Quận 1', '123 Nguyễn Huệ', true)
    ON CONFLICT (branch_code) DO NOTHING;
END $$;

-- Category: BUFFET
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet', 'BUFFET', 1) ON CONFLICT DO NOTHING;
-- SubCategory: SET 1390
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-1390', 'SET 1390', 2) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-1390';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf1390-1', 'Vé Người Lớn 1380', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1380000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: SET 1150
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-1150', 'SET 1150', 3) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-1150';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf1150-2', 'Vé Người Lớn 1150', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1150000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: SET 680
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-680', 'SET 680', 4) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-680';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf680-3', 'Vé Người Lớn 680', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 680000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: SET 490
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-490', 'SET 490', 5) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-490';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf490-4', 'Vé Người Lớn 490', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 490000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: SET 380
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-380', 'SET 380', 6) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-380';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf380-5', 'Vé Người Lớn 380', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 380000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: SET DRINK
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-drink', 'SET DRINK', 7) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-drink';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-drink-250jp-6', 'BUFFET NƯỚC GÓI 250 (JP)', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 227273);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-drink';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-drink-soft-7', 'Nước ngọt uống không giới hạn', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 80000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-drink';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-drink-alcohol-350-8', 'Rượu bia cao cấp uống không giới hạn trong 2 giờ', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 350000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-drink';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-drink-alcohol-250-9', 'Rượu bia uống không giới hạn trong 2 giờ', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 250000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: A la carte
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-alacarte', 'A la carte', 8) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-alacarte-ticket-10', 'A la carte', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-lunch-ticket-11', 'SET LUNCH', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-tiec-jp-ticket-12', 'Sét Tiệc Chiêu Đãi JP', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-tiec-vn-ticket-13', 'Sét Tiệc Chiêu Đãi VN', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Set 550JP
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-550jp', 'Set 550JP', 9) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-550jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-550jp-14', 'Vé Người Lớn 550 (JP)', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 509259);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Buffet Lẩu
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_buffet-lau', 'Buffet Lẩu', 10) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_buffet-lau';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'bf-lau-250-15', 'Set Lẩu 250', 'buffet_package', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 250000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- Category: Set Lunch
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_set-lunch', 'Set Lunch', 11) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-16', 'Cơm Bibimbap - Lunch Menu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 99000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-17', 'Cơm Cà Ri Ushiyoshi - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 89000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-18', 'Cơm gà Nanban Nhật Bản - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 179000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-19', 'Lunch - Cơm thịt heo kim chi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 129000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-20', 'Lunch - Cơm thịt heo kim chi phủ trứng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 139000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-21', 'Lunch - Set Bò Cao Cấp', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 259000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-22', 'Lunch - Sét Cơm Gà Cay Ngọt', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 109000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-23', 'Lunch - Set Heo Tổng Hợp', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 169000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-24', 'Lunch - Sét Nướng Healthy', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 199000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-25', 'Lunch - Sét Nướng Thập Cẩm (Heo & Gà)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 149000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-26', 'Lunch - Set Nướng Thập Cẩm (Heo & Bò)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 189000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-27', 'Lunch - Sét Oyakodon (Cơm Gà & Trứng)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 119000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-28', 'Lunch - Sét Wagyu Thượng Hạng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 450000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-29', 'Lunch - Set Wagyu Tuyển Chọn', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 325000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-30', 'Mì Chua Cay Kiểu Á Đông - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 179000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-31', 'Mì Udon Kim Chi - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 149000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-32', 'Mì udon xào cùng thịt bò - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 129000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-33', 'Sét Chiên Thập Cẩm Và Cơm Kiểu Nhật - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 189000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-34', 'Sét trưa Hamburger - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 99000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-35', 'Tôm Tempura - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 40000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-36', 'Cá Ngân chiên giòn', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 45000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-lunch';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'lunch-37', 'Gà Chiên Nhật Bản - Lunch', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;
-- Category: SET TIỆC CHIÊU ĐÃI
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_set-tiec-cd', 'SET TIỆC CHIÊU ĐÃI', 12) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-38', 'SET1-Drink Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 250000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-39', 'SET1-Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 450000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-40', 'SET2-Drink Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 350000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-41', 'SET2-Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 550000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-42', 'SET3-Drink Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 350000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-43', 'SET3-Tiệc Chiêu Đãi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 850000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;
-- Category: SET TIỆC CHIÊU ĐÃI (JP)
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_set-tiec-cd-jp', 'SET TIỆC CHIÊU ĐÃI (JP)', 13) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-44', 'SET DRINK 250K', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 227273);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-45', 'SET DRINK 350K', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 318182);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-46', 'Set tiệc chiêu đãi - 001', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 416667);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-47', 'Set tiệc chiêu đãi - 002', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 509259);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-48', 'Set tiệc chiêu đãi - 003', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 787037);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-49', 'SET TIỆC GUMA', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1310185);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-tiec-cd-jp';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tiec-jp-50', 'SET TIỆC NAGASAKI', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1032407);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;
-- Category: SET Vietravel
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_set-vietravel', 'SET Vietravel', 14) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_set-vietravel';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'vt-51', 'Set tiệc Vietravel D Course', 'food', 'Vé', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 500000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;
-- Category: Thức Ăn
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_thuc-an', 'Thức Ăn', 15) ON CONFLICT DO NOTHING;
-- SubCategory: Wagyu
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-wagyu', 'Wagyu', 16) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-52', 'Sườn Wagyu Xốt Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-53', 'Thăn Ngoại Wagyu Chọn Lọc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-54', 'Thăn Lưng Wagyu Chọn Lọc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-55', 'Sườn Ngắn Wagyu Nướng Kiểu Shabu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-56', 'Lõi Vai Wagyu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-57', 'Lưỡi bò cắt dày', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-58', 'Lưỡi bò cắt dày', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 170000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-wagyu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wagyu-59', 'Thịt đỏ Wagyu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Beef tongue
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-tongue', 'Beef tongue', 17) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-tongue';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tongue-60', 'Lưỡi Bò Cắt Mỏng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-tongue';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tongue-61', 'Lưỡi Bò Xốt Muối Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-tongue';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tongue-62', 'Lưỡi Bò Hoa', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Beef
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-beef', 'Beef', 18) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-63', 'Set Thịt Đặc Trưng Ushiyoshi (2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-64', 'Set Thịt Đặc Trưng Ushiyoshi (3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-65', 'Set Thịt Đặc Trưng Ushiyoshi (4 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-66', 'Set Thịt Tổng Hợp Đặc Biệt (4 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-67', 'Set Thịt Tổng Hợp Đặc Biệt (2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-68', 'Set Thịt Tổng Hợp Đặc Biệt (3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-69', 'Set Thịt Tuyển Chọn (2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-70', 'Set Thịt Tuyển Chọn (3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-71', 'Set Thịt Tuyển Chọn (4 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-72', 'Thăn Lưng Ushiyoshi Cao Cấp', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-73', 'Thăn Lưng Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-74', 'Sườn Ngắn Ushiyoshi Cao Cấp', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-75', 'Sườn Ngắn Ushiyoshi Ướp Miso', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-76', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Ushiyoshi)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-77', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Sukiyaki)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-78', 'Sườn Ngắn Xốt Muối Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-79', 'Sườn Ngắn Xốt Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-80', 'Sườn Ngắn Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-81', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Ushiyoshi)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-82', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Miso Cay)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-83', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Sukiyaki)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-84', 'Sườn Nguyên Tảng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-beef';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beef-85', 'Diềm Thăn Xốt Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Nội Tạng
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-offal', 'Nội Tạng', 19) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-86', 'Lòng Bò Đặc Trưng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-87', 'Lòng Bò Non Ushiyoshi Xốt', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-88', 'Lòng Bò Già Ushiyoshi Xốt', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-89', 'Gan Bò Xốt Đặc Biệt', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-90', 'Lòng Bò Non Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-91', 'Lòng Bò Già Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-92', 'Gan Bò Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-93', 'Dạ dày bò (tổ ong) sốt miso cay', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-94', 'Dạ dày bò (tổ ong) sốt miso cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 50000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-offal';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'offal-95', 'Dạ dày bò (tổ ong) sốt tare', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Thịt Heo
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-pork', 'Thịt Heo', 20) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-96', 'Ba Chỉ Heo Vị Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-97', 'Ba Chỉ Heo Ướp Miso', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-98', 'Ba Chỉ Heo Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-99', 'Nọng Heo Vị Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-100', 'Nọng Heo Ướp Miso', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-pork';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'pork-101', 'Nọng Heo Ướp Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Thịt Gà
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-chicken', 'Thịt Gà', 21) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-102', 'Đùi Gà Vị Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-103', 'Đùi Gà Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-104', 'Cổ Gà Vị Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-105', 'Cổ Gà Ướp Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-106', 'Cánh Gà Vị Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-chicken';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'chicken-107', 'Cánh Gà Miso Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Grill a la carte
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-grill', 'Grill a la carte', 22) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-108', 'Trứng gà', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 20000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-109', 'Rau Củ Nướng Thập Cẩm', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-110', 'Tôm', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-111', 'Bạch Tuộc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-112', 'Hải Sản Nướng Giấy Bạc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-113', 'Bắp Nướng Bơ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-114', 'Khoai Tây Nướng Bơ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-grill';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'grill-115', 'Tỏi Nướng Giấy Bạc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: A la carte
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-alacarte', 'A la carte', 23) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-116', 'Cá Ngân Chiên Giòn', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-117', 'Tôm Tempura', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-118', 'Chả Cá Nhật Chiên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-119', 'Cua Lột Chiên Giòn', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-120', 'Râu Sò Điệp Trộn Tiêu Tứ Xuyên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-121', 'Cá Trứng Chiên Giòn', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-122', 'Trứng Hấp Kiểu Nhật', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-123', 'Gà Chiên Nhật Bản', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-124', 'Cánh Gà Chiên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-125', 'Khoai Tây Chiên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-126', 'Bánh Bạch Tuộc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-127', 'Bánh Xèo Nhật Mini', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-128', 'Há Cảo Chiên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-129', 'Hamburger', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-130', 'Trứng Cuộn Nhật', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-131', 'Set Trẻ Em', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-alacarte';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alacarte-132', 'Sushi Bò Wagyu Áp Lửa Hồng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Khai Vị
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-appetizer', 'Khai Vị', 24) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-133', 'Đậu Nành Nhật', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-134', 'Dưa Leo Trộn Kiểu Nhật', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-135', 'Kimchi Tổng Hợp', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-136', 'Kimchi Cải Thảo', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-137', 'Kimchi Dưa Leo', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-138', 'Kimchi Củ Cải', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-appetizer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'appetizer-139', 'Rau Trộn Hàn Quốc (Tổng Hợp)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Xà Lách
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-salad', 'Xà Lách', 25) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-salad';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'salad-140', 'Salad Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-salad';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'salad-141', 'Salad Đậu Hũ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-salad';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'salad-142', 'Salad Caesar', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-salad';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'salad-143', 'Xà lách', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Cơm
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-rice', 'Cơm', 26) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-144', 'Bibimbap Thố Đá', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-145', 'Bibimbap Mini', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-146', 'Cơm Chiên Tỏi Thố Đá', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-147', 'Canh Cơm Hàn Quốc', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-148', 'Cơm Chiên Kimchi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-149', 'Cơm Gân Bò Mini', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-150', 'Cà Ri Ushiyoshi', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-151', 'Cơm Ăn Kèm Yakiniku', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-rice';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'rice-152', 'Cơm Trắng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Mì các loại
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-noodle', 'Mì các loại', 27) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-153', 'Mì Udon Lạnh Goto', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-154', 'Mì Udon Bò', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-155', 'Mì Xương Ống Hầm', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-156', 'Mì Ramen Xào Bò', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-157', 'Mì Ramen Xào Hải Sản', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-noodle';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'noodle-158', 'Súp Mala Cay Tê', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Súp
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-soup', 'Súp', 28) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-159', 'Súp mala cay tê', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 45000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-160', 'Súp Phở', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-161', 'Súp Rong Biển', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-162', 'Súp Nghêu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-163', 'Súp Nghêu Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-164', 'Súp Trứng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-soup';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soup-165', 'Súp Chua Cay', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Tráng Miệng
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-dessert', 'Tráng Miệng', 29) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-166', 'Kem Vani', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-167', 'Kem Vani Sốt Dâu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-168', 'Kem Vani Sốt Socola', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-169', 'Kem Matcha', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-170', 'Kem Chanh Yuzu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-171', 'Kem Nho', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-172', 'Bánh Bông Lan Phô Mai Trứng Muối', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-173', 'Bánh Cá Nhân Đậu Đỏ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-174', 'Bánh Cá Nhân Kem Trứng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-175', 'Dorayaki Đậu Đỏ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-176', 'Dorayaki Kem Trứng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-177', 'Bánh Su Kem', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-178', 'Bánh Chuối Nướng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-dessert';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'dessert-179', 'Gateau Sô-cô-la', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Sốt
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-sauce', 'Sốt', 30) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sauce';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sauce-180', 'Xốt Bơ Tỏi Xì Dầu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sauce';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sauce-181', 'Xốt Phô Mai Nóng Chảy', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Lẩu Sukiyaki
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_ta-sukiyaki', 'Lẩu Sukiyaki', 31) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-182', 'Đĩa rau thập cẩm (Phần cho 2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-183', 'Đĩa rau thập cẩm (Phần cho 3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-184', 'Mì Udon', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-185', 'Nấm đùi gà', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-186', 'Nấm hương', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-187', 'Nấm kim châm', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-188', 'Rau củ và nấm thập cẩm (Phần cho 2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-189', 'Rau củ và nấm thập cẩm (Phần cho 3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-190', 'Trứng gà', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-191', 'Các loại nấm (Phần cho 2 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-192', 'Các loại nấm (Phần cho 3 người)', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-193', 'Cải thảo', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-194', 'Cải thìa', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-195', 'Cơm trắng', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-196', 'Đậu hũ chiên', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-197', 'Đậu hũ non', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-198', 'Thịt bò dùng cho lẩu Shabu-Shabu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_ta-sukiyaki';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sukiyaki-199', 'Nước lẩu', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- Category: Thức Uống
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_thuc-uong', 'Thức Uống', 32) ON CONFLICT DO NOTHING;
-- SubCategory: Soft drink
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_tu-soft', 'Soft drink', 33) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-200', '(A)Trà Đào', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 72000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-201', '(A)Trà Vải', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 72000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-202', '(A)Nước Cam', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-203', '(A)Nước Ép Táo', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-204', '(A)Nước Ép Trái Cây Tổng Hợp', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-205', '(A)Coca-Cola', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-206', '(A)Trà Sữa Trân Châu', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 50000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-207', '(A)Coca-Cola Zero', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-208', '(A)Trà Sữa Thái Xanh', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 50000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-209', '(A)7UP', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-210', '(A)Trà Sữa Thái Đỏ', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 50000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-211', '(A)Soda', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-212', '(A)Trà Lài', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 35000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-soft';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'soft-213', '(A)Nước Suối', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 25000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: NON ALCOHOLIC
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_tu-non-alcoholic', 'NON ALCOHOLIC', 34) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-non-alcoholic';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'non-alc-214', '(A)Nước chanh xanh biển', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 80000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-non-alcoholic';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'non-alc-215', '(A)Soda Chanh Vải', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 78000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-non-alcoholic';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'non-alc-216', '(A)Soda Cassis Nho', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 108000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-non-alcoholic';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'non-alc-217', '(A)Soda Dứa Chanh Dây', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 78000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Tea
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_tu-tea', 'Tea', 35) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-tea';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tea-218', '(A) Trà Rang Nhật Bản', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 80000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-tea';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tea-219', '(A) Trà Xanh Nhật Bản', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 80000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-tea';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tea-220', '(A)Trà Đào', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 72000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Đồ uống - Set
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_tu-set', 'Đồ uống - Set', 36) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-221', '7UP', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-222', 'Coca-Cola', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-223', 'Coca-Cola Zero', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-224', 'Nước Cam', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-225', 'Nước Ép Táo', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-226', 'Nước Ép Trái Cây Tổng Hợp', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-227', 'Nước Suối', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-228', 'Trà Lài', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-229', 'Soda', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-230', 'Trà Sữa Thái Đỏ', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-231', 'Trà Sữa Thái Xanh', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_tu-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'tu-set-232', 'Trà Sữa Trân Châu', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- Category: Thức Uống Có Cồn
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_thuc-uong-co-con', 'Thức Uống Có Cồn', 37) ON CONFLICT DO NOTHING;
-- SubCategory: Bia (món đơn)
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-beer', 'Bia (món đơn)', 38) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-beer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beer-233', '(A)Bia Tươi Sapporo', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 78000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-beer';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'beer-234', '(A)Bia Tiger', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 55000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Whisky
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-whisky', 'Whisky', 39) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-whisky';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'whisky-235', '(A)Rượu Jim Beam/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-whisky';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'whisky-236', '(A)Rượu Suntory Kaku/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Shochu
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-shochu', 'Shochu', 40) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-237', '(A)Rượu Kuro Kurishima Bottle', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1200000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-238', 'Rượu Sâm Cau Việt Nam', 'food', 'Lọ', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1000000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-239', '(A)Rượu Lemon Soda', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 90000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-240', '(A)Rượu Mơ', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 86000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-241', '(A)Chuhai Đào Fukushima', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 119000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-242', '(A)Chuhai Quýt Arita', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 119000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-243', '(A)Rượu iichiko/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 98000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-shochu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'shochu-244', '(A)Rượu Kuro Kirishima/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 98000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Nihonshuu
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-nihonshuu', 'Nihonshuu', 41) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-nihonshuu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sake-245', 'Awayuki Sparkling Sake/bottle 300ml', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 450000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-nihonshuu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sake-246', 'Kijuro (喜十郎)/ bottle 720ml', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1200000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-nihonshuu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sake-247', 'Dassai (獺祭)/ bottle 300ml', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 890000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-nihonshuu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'sake-248', 'Nabeshima (鍋島)/ bottle 720ml', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 2000000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Wine
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-wine', 'Wine', 42) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-249', 'Mussel Bay (chai)', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 880000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-250', '(A)Mussel Bay/white', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 150000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-251', 'Michel Lynch (chai)', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 880000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-252', '(A)Michel Lynch/ red', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 150000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-253', '(A)Champagne Bollinger Special Cuvée /Sparkling', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 4000000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-254', 'Parallèle 45 Côtes du Rhône PJA/white', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1200000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-255', '(A)Chablis – Courtault Michelet/white', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 2300000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-256', 'Logan Weemala/red', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1180000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-257', 'La Posta Fazzio/red', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 1380000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-258', '(A)Château Haut-Cadet Saint-Émilion Grand Cru/red', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 2500000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-wine';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'wine-259', '(A)Côte de Nuits Villages – Lou Dumont/red', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 3800000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Đồ uống có cồn - Set
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_alc-set', 'Đồ uống có cồn - Set', 43) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-260', 'Rượu iichiko/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-261', 'Rượu Jim Beam /glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-262', 'Rượu Suntory Kaku/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-263', 'Chuhai Đào Fukushima', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-264', 'Chuhai Quýt Arita', 'food', 'Lọ', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-265', 'Rượu Lemon Soda Liqueur', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-266', 'Rượu Mơ', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-267', 'Bia Tiger', 'food', 'Lon', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-268', 'Bia Tươi Sapporo', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_alc-set';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'alc-set-269', 'Rượu Kuro Kirishima/glass', 'food', 'Ly', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- Category: Khác
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_khac', 'Khác', 44) ON CONFLICT DO NOTHING;
-- SubCategory: Phục vụ
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_khac-phuc-vu', 'Phục vụ', 45) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-270', 'Chén', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-271', 'Đĩa Trẻ Em', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-272', 'Đĩa Trẻ Em', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-273', 'Khăn giấy lau', 'food', 'hộp', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-274', 'Khăn giấy lau', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-275', 'Lấy Kéo', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-276', 'Lấy Kéo', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-277', 'Lấy Kẹp Gắp', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-278', 'Lấy Kẹp Gắp', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-279', 'Lấy Muôi Múc Canh', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-280', 'Lấy Muôi Múc Canh', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-281', 'Lấy Muỗng', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-282', 'Lấy Thìa Desert', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-283', 'Lấy Thìa Desert', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-284', 'Nĩa Trẻ Em', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-285', 'Nĩa Trẻ Em', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-286', 'Tạp dề giấy', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-287', 'Thay Đũa', 'food', 'đôi', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-288', 'Thay Đũa', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-289', 'Thay Khăn', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-290', 'Thay Khăn', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-291', 'Thay Than', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-292', 'Thay Than', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-293', 'Thay Vỉ', 'food', 'Phần', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-294', 'Thay Vỉ', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-295', 'Thêm Đĩa (Đĩa Thường)', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-296', 'Thêm Đĩa (Đĩa Thường)', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-297', 'Thìa Trẻ Em', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phuc-vu';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'svc-298', 'Thìa Trẻ Em', 'food', 'cái', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: Gia Vị
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_khac-gia-vi', 'Gia Vị', 46) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-299', 'Chanh', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-300', 'Hành lá nhỏ', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-301', 'Mù Tạt', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-302', 'Muối', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-303', 'Ớt Xắt', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-304', 'Sốt chấm', 'food', 'Đĩa', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-305', 'Sốt chấm', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-gia-vi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'gia-vi-306', 'Tỏi Băm', 'food', 'BỊCH', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 0);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
-- SubCategory: PHÍ PHỤ THU
INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_khac-phi', 'PHÍ PHỤ THU', 47) ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'phi-307', 'Phí phụ thu mang rượu', 'food', 'Chai', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 400000);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_khac-phi';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, 'phi-308', 'Phí phụ thu thức ăn thừa (100g)', 'food', 'gram', '')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, 500);
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;

COMMIT;
