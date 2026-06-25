-- =============================================================================
-- AUTO-GENERATED from docs/member_status/Ishii/thực đơn.txt
-- Source: Ishii's menuData.ts (700+ items across 12 categories, 16 subcategories)
-- Generated at: 2026-06-25T10:57:24.308Z
-- DO NOT EDIT BY HAND — regenerate via scripts/_archive/per-onetime/parse_menu_to_sql.js
--
-- Idempotent: every insert uses ON CONFLICT DO NOTHING against a deterministic
-- UUID (uuidFor) so re-running the migration does not duplicate rows.
-- =============================================================================
BEGIN;

-- 1. Categories (12)
-- ----------------------------------------------------------------------------
INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7c9dfe17-9184-5d75-b6f3-d6ad00ab31ae', 'b1000000-0000-0000-0000-000000000001', 'SET 1390', 100, true, '{"fe_id":"set_1390"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_1390 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0ecac5f4-5a21-53de-9b08-08ad24b8f61e', 'b1000000-0000-0000-0000-000000000001', '7c9dfe17-9184-5d75-b6f3-d6ad00ab31ae', 'Vé Người Lớn 1380', 1380000, 'Vé', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set1390_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('a6b3068d-868e-5b45-88e2-acafe1cbdf04', 'b1000000-0000-0000-0000-000000000001', 'SET 1150', 101, true, '{"fe_id":"set_1150"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_1150 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('baedab6a-f939-56d5-a65a-d11cbfb36879', 'b1000000-0000-0000-0000-000000000001', 'a6b3068d-868e-5b45-88e2-acafe1cbdf04', 'Vé Người Lớn 1150', 1150000, 'Vé', '1.150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set1150_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('d3e9aa63-ceda-5e23-8ac0-50d78d3f6213', 'b1000000-0000-0000-0000-000000000001', 'SET 680', 102, true, '{"fe_id":"set_680"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_680 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('85f74311-fd9f-5c67-aac5-3d8a4ed15a5e', 'b1000000-0000-0000-0000-000000000001', 'd3e9aa63-ceda-5e23-8ac0-50d78d3f6213', 'Vé Người Lớn 680', 680000, 'Vé', '680K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set680_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('9babff3d-469b-5f89-88c4-48691adb5b96', 'b1000000-0000-0000-0000-000000000001', 'SET 490', 103, true, '{"fe_id":"set_490"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_490 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('03fa9ce7-5cb7-513a-bf32-26b166b2544c', 'b1000000-0000-0000-0000-000000000001', '9babff3d-469b-5f89-88c4-48691adb5b96', 'Vé Người Lớn 490', 490000, 'Vé', '490K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set490_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7634202c-09be-5e7b-b0f8-0c0d72e952c6', 'b1000000-0000-0000-0000-000000000001', 'SET 380', 104, true, '{"fe_id":"set_380"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_380 (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d53e04d9-c8ac-5b58-8bf4-e6bf3f6776e5', 'b1000000-0000-0000-0000-000000000001', '7634202c-09be-5e7b-b0f8-0c0d72e952c6', 'Vé Người Lớn 380', 380000, 'Vé', '380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set380_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('4f502a03-94ab-598c-9e75-a7b193c21d01', 'b1000000-0000-0000-0000-000000000001', 'SET DRINK', 105, true, '{"fe_id":"set_drink"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_drink (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('547e71c2-cfad-5022-a9b5-0c306d17d504', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'BUFFET NƯỚC GÓI 250 (JP)', 227273, 'Vé', '227,273K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_buffet_250jp","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f74026b8-2460-5f5a-ad9c-022bb34bdd06', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Nước ngọt uống không giới hạn', 80000, 'Vé', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_unlimited_soft","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e9de840f-27f1-5b1b-a769-62a9fd182a4a', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Rượu bia uống không giới hạn trong 2 giờ', 250000, 'Vé', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_alcohol_2h_250","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8f52aa2b-e5c1-554b-8f9a-567ad3b6c565', 'b1000000-0000-0000-0000-000000000001', '4f502a03-94ab-598c-9e75-a7b193c21d01', 'Rượu bia cao cấp uống không giới hạn', 350000, 'Vé', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"drink_alcohol_2h_350","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('c80f8d49-30ac-576c-9b41-d4efaae26852', 'b1000000-0000-0000-0000-000000000001', 'A la carte', 106, true, '{"fe_id":"a_la_carte"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category a_la_carte (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('345d4d7e-570c-58c1-bdaf-9a6fc2ad1e32', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'A la carte', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('54f39dd7-5142-584a-9cff-07ef84813003', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET LUNCH', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lunch_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('df994aa3-37e6-5ac5-85db-d29b34d96c8d', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET TIỆC CHIÊU ĐÃI VN', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiec_cd_vn_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b5694927-4c39-520e-b778-4c0025b22636', 'b1000000-0000-0000-0000-000000000001', 'c80f8d49-30ac-576c-9b41-d4efaae26852', 'SET TIỆC CHIÊU ĐÃI JP', 0, 'Vé', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiec_cd_jp_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('71ef4d58-6968-588a-aa7f-c2338eb51ad7', 'b1000000-0000-0000-0000-000000000001', 'Set 550JP', 107, true, '{"fe_id":"set_550jp"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_550jp (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d51a16bd-dac5-568c-a670-7cedd84c53e7', 'b1000000-0000-0000-0000-000000000001', '71ef4d58-6968-588a-aa7f-c2338eb51ad7', 'SET 550 (JP)', 509259, 'Vé', '509,259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set550jp_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('c656c3b6-1db1-52b9-83e0-fa03ead8bf7c', 'b1000000-0000-0000-0000-000000000001', 'Buffet Lẩu', 108, true, '{"fe_id":"buffet_lau"}', 'yellow')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category buffet_lau (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('612229f3-ce09-50fe-8d48-c336134ce56f', 'b1000000-0000-0000-0000-000000000001', 'c656c3b6-1db1-52b9-83e0-fa03ead8bf7c', 'Set Lẩu 250', 250000, 'Vé', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lau_250_ticket","color":"yellow"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'BUFFET', 109, true, '{"fe_id":"buffet"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category buffet
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('e23dee91-afff-58c8-8d99-eb013f91b858', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 1390', 0, true, '{"fe_id":"buffet_1390"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4e5a299b-cae2-521a-b8f9-132a54621ad2', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 1150', 1, true, '{"fe_id":"buffet_1150"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('fae964ff-c179-5c96-a2f5-05e1750fdc7a', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 680', 2, true, '{"fe_id":"buffet_680"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('c093cfcb-18ee-5ca7-9c8e-004b9fb07d78', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 490', 3, true, '{"fe_id":"buffet_490"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('7ea2ad16-e1d4-5b84-89db-ea75585b6b48', 'f63d3c21-dd37-53de-b967-a65951996693', 'b1000000-0000-0000-0000-000000000001', 'SET 380', 4, true, '{"fe_id":"buffet_380"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_1390
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('61c0cff6-6db7-54cf-b249-9b260a396383', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'e23dee91-afff-58c8-8d99-eb013f91b858', 'Vé Người Lớn 1380', 1380000, 'Vé', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf1390_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_1150
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('21c8e252-3e3d-5895-9f44-4a2e74c6d663', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', '4e5a299b-cae2-521a-b8f9-132a54621ad2', 'Vé Người Lớn 1150', 1150000, 'Vé', '1.150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf1150_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_680
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('af6c9d5b-50b2-5b2c-84f3-c3f6b3303827', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'fae964ff-c179-5c96-a2f5-05e1750fdc7a', 'Vé Người Lớn 680', 680000, 'Vé', '680K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf680_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_490
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ffb57568-0e67-542c-be34-2d4ae2318304', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', 'c093cfcb-18ee-5ca7-9c8e-004b9fb07d78', 'Vé Người Lớn 490', 490000, 'Vé', '490K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf490_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory buffet_380
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3672fb96-eedc-585c-af1a-8e321c36fdca', 'b1000000-0000-0000-0000-000000000001', 'f63d3c21-dd37-53de-b967-a65951996693', '7ea2ad16-e1d4-5b84-89db-ea75585b6b48', 'Vé Người Lớn 380', 380000, 'Vé', '380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"bf380_ticket","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('9b038804-81d2-56c0-a139-0b5d9008e88c', 'b1000000-0000-0000-0000-000000000001', 'Set Lunch', 110, true, '{"fe_id":"set_lunch"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_lunch (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a5901473-93ea-50d2-a384-33db3ebf113a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm Bibimbap - Lunch Menu', 99000, 'Phần', '99K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_bibimbap","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f73da03c-ea89-5d79-a62e-d29be352293a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm Cà Ri Ushiyoshi - Lunch', 89000, 'Phần', '89K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_cary","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('55aea1bc-e4a0-5182-af9d-037ba6db10a1', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cơm gà Nanban Nhật Bản - Lunch', 179000, 'Phần', '179K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_nanban","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0fe0022c-a0ac-59b0-bba6-af577810d082', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Cơm thịt heo kim chi', 129000, 'Phần', '129K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_kimchi_pork","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('daa20abc-650b-54a7-a123-2425d651aff2', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Cơm thịt heo kim chi phủ trứng', 139000, 'Phần', '139K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_kimchi_pork_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('98a37efc-c4b6-526f-b671-bd2f3a45a497', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Bò Cao Cấp', 259000, 'Phần', '259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_beef_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('246e3c74-944e-5608-87a8-75a9a52ce724', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Cơm Gà Cay Ngọt', 109000, 'Phần', '109K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_chicken_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e45b84fe-6ad8-5094-bcb7-10ac819eeb91', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Heo Tổng Hợp', 169000, 'Phần', '169K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_pork_mix","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('48504cc4-7f82-5375-bbbd-e2a523c1dc47', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Nướng Healthy', 199000, 'Phần', '199K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_healthy_grill","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a19e9e55-4f71-54dc-940e-a42f2703dbf5', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Nướng Thập Cẩm (Heo & Gà)', 149000, 'Phần', '149K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_grill_mix_pork_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f15c3492-e13a-56fc-8842-fddac9dac17f', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Nướng Thập Cẩm (Heo & Bò)', 189000, 'Phần', '189K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_grill_mix_pork_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('226b3df4-9604-55e8-bcf6-caeba5e874d9', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Oyakodon (Cơm Gà & Trứng)', 119000, 'Phần', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_oyakodon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c5bff9c9-7cae-5310-82c3-1f3e196ecf1a', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Sét Wagyu Thượng Hạng', 450000, 'Phần', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_wagyu_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5415fb8f-f703-58f1-b062-e6c84d533cba', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Lunch - Set Wagyu Tuyển Chọn', 325000, 'Phần', '325K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_wagyu_select","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e37652b2-a0f9-5559-9c16-c98f9a4a1294', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì Chua Cay Kiểu Á Đông - Lunch', 179000, 'Phần', '179K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_spicy_noodle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8783e51b-a94b-540f-a478-df42e9266bd0', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì Udon Kim Chi - Lunch', 149000, 'Phần', '149K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_udon_kimchi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f7840ea-35ac-59d0-abb7-763bddaeca16', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Mì udon xào cùng thịt bò - Lunch', 129000, 'Phần', '129K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_udon_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cea23768-ef2d-53f9-a096-444b75f9f4cf', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Sét Chiên Thập Cẩm Và Cơm Kiểu Nhật - Lunch', 189000, 'Phần', '189K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_mix_rice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cc3a28fb-50ed-5a7f-b949-3f22e238e40f', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Sét trưa Hamburger - Lunch', 99000, 'Phần', '99K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_hamburger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('daa60310-5b8f-535e-afa7-2a76ee13bad3', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Tôm Tempura - Lunch', 40000, 'Phần', '40K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_tempura_shrimp","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('85a41020-069e-5ea5-a31f-a327390926df', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Cá Ngân chiên giòn', 45000, 'Phần', '45K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_fish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6f43093-1c23-549e-b674-bd297245c3a7', 'b1000000-0000-0000-0000-000000000001', '9b038804-81d2-56c0-a139-0b5d9008e88c', 'Gà Chiên Nhật Bản - Lunch', 35000, 'Phần', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"lunch_fried_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'b1000000-0000-0000-0000-000000000001', 'SET TIỆC CHIÊU ĐÃI', 111, true, '{"fe_id":"set_tiec_chieu_dai"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_tiec_chieu_dai (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c5a88e47-9cca-537d-8d77-4e7b594fd05b', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET1-Drink Tiệc Chiêu Đãi', 250000, 'Phần', '250K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set1_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b84d739d-0287-5f16-b649-cad5677adb9e', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET1-Tiệc Chiêu Đãi', 450000, 'Phần', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set1","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('975c4986-3a98-5615-bc52-d7c543a44d8a', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET2-Drink Tiệc Chiêu Đãi', 350000, 'Phần', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set2_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a3a368bb-78a8-5124-aff2-ca703722451d', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET2-Tiệc Chiêu Đãi', 550000, 'Phần', '550K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('eb314f31-cea3-56e7-95a2-a1067f09739f', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET3-Drink Tiệc Chiêu Đãi', 350000, 'Phần', '350K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set3_drink","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('35b8322c-48da-5f31-be67-0a306376f023', 'b1000000-0000-0000-0000-000000000001', '3a91ec06-a50a-5d90-833b-ca6d66d4e0f5', 'SET3-Tiệc Chiêu Đãi', 850000, 'Phần', '850K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_set3","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('5e494b08-881a-54eb-a020-d023548575e9', 'b1000000-0000-0000-0000-000000000001', 'SET TIỆC CHIÊU ĐÃI (JP)', 112, true, '{"fe_id":"set_tiec_chieu_dai_jp"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_tiec_chieu_dai_jp (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b59d4f55-f2bc-5087-939c-70d63787bd75', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET DRINK 250K', 227273, 'Vé', '227,273K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_drink_250","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('603ad4e9-cde1-593d-b406-04a90ca6322d', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET DRINK 350K', 318182, 'Vé', '318,182K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_drink_350","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('da855d88-e8e8-5074-8877-e7cd8e1938cb', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 001', 416667, 'Vé', '416,667K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_001","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('80dc2677-d718-533b-ad14-c353baf03a0f', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 002', 509259, 'Vé', '509,259K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_002","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('83880232-4946-5b3b-b66c-8675c4b67ac5', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'Set tiệc chiêu đãi - 003', 787037, 'Vé', '787,037K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_003","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b2fa1a11-7618-5e4a-bbe6-597135ab2fa6', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET TIỆC GUMA', 1310185, 'Vé', '1.310,185K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_guma","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7f62963d-d216-520b-ab21-ae39a27002d7', 'b1000000-0000-0000-0000-000000000001', '5e494b08-881a-54eb-a020-d023548575e9', 'SET TIỆC NAGASAKI', 1032407, 'Vé', '1.032,407K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cd_jp_nagasaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('5232db90-7f64-5d7a-8e2b-f311ca7f9305', 'b1000000-0000-0000-0000-000000000001', 'SET Vietravel', 113, true, '{"fe_id":"set_vietravel"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1a. Items under category set_vietravel (no subcategory)
INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c4449640-b3d5-5013-85d8-b6cbfa84c45a', 'b1000000-0000-0000-0000-000000000001', '5232db90-7f64-5d7a-8e2b-f311ca7f9305', 'SET TIỆC Vietravel D Course', 500000, 'Vé', '500K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"vietravel_d_course","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thức Ăn', 114, true, '{"fe_id":"thuc_an"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_an
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Wagyu', 0, true, '{"fe_id":"wagyu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('6942ff59-4096-5848-b299-0a32045ad325', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Beef tongue', 1, true, '{"fe_id":"beef_tongue"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('c3899596-122a-5c93-a20b-225120f2f2ff', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Beef', 2, true, '{"fe_id":"beef"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('b7bcbe61-7027-5e59-81c5-c53649c4a055', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Nội Tạng', 3, true, '{"fe_id":"offal"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thịt Heo', 4, true, '{"fe_id":"pork"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Thịt Gà', 5, true, '{"fe_id":"chicken"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Grill a la carte', 6, true, '{"fe_id":"grill_alacarte"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'A la carte', 7, true, '{"fe_id":"alacarte"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ebf8cf7e-8ab7-5062-8049-4231a674e094', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Khai Vị', 8, true, '{"fe_id":"appetizer"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('550c50e2-ee85-5ded-aebb-12ea7a66143d', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Xà Lách', 9, true, '{"fe_id":"salad"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0b8f0878-f117-5356-9ca3-febce150d9bd', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Cơm', 10, true, '{"fe_id":"rice"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('3c8fe227-2183-5b31-9a6e-4532411d1c60', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Mì các loại', 11, true, '{"fe_id":"noodle"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Súp', 12, true, '{"fe_id":"soup"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Tráng Miệng', 13, true, '{"fe_id":"dessert"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Sốt', 14, true, '{"fe_id":"sauce"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('ca82c088-92a3-53e8-a709-3a77bc673ff9', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b1000000-0000-0000-0000-000000000001', 'Lẩu Sukiyaki', 15, true, '{"fe_id":"sukiyaki"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory wagyu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c16268df-580b-5c06-bdaf-aac42fa58502', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Sườn Wagyu Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_ribs","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3a84780b-99ed-5cf0-89fb-600b77bfdc91', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thăn Ngoại Wagyu Chọn Lọc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_sirloin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9d172055-fbbf-5c34-86d4-f17a65c41b7d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thăn Lưng Wagyu Chọn Lọc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_back","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b1aca5a6-afd2-51ae-a3e4-041fc4470e6e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Sườn Ngắn Wagyu Nướng Kiểu Shabu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_short_ribs_shabu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9373f6ae-5f15-532a-9b70-4ef10223c0b4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lõi Vai Wagyu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_shoulder","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8233459f-32a6-5de0-b84d-63d86c1fd354', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lưỡi bò cắt dày', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_tongue_thick_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6695a94-275b-53f0-976d-29cc168af312', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Lưỡi bò cắt dày', 170000, 'Phần', '170K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_tongue_thick","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c3c75e97-9bb3-5800-9b77-24a8fbf0fc23', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '73db29ce-d64a-5d5d-988a-3eb4ea704c4c', 'Thịt đỏ Wagyu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wagyu_red_meat","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beef_tongue
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9a140b66-2cdb-567b-b5a7-2e1bc7e0f0d3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Cắt Mỏng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_thin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('621be4d3-c84a-538d-a85d-2c445ccd0ca2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Xốt Muối Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2db8e967-f0c2-561d-a39d-f15c9e89fa50', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '6942ff59-4096-5848-b299-0a32045ad325', 'Lưỡi Bò Hoa', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tongue_flower","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beef
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8359729e-e39a-55f1-9463-058338a10529', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab2e34a5-ec36-5d6b-b3de-df507055c072', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab1e819e-e27c-53c1-9321-6459fa48a041', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Đặc Trưng Ushiyoshi (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_ushiyoshi_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('45c4f5d6-9579-5cfb-aa0e-11a864512982', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('70a8207a-84fc-52f7-a9d2-e40dca212f82', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2dccd15d-4e65-588e-b816-637745e5d554', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tổng Hợp Đặc Biệt (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_mix_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4ad632fd-9c30-5925-9409-7da11ca96f5a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f540ffcd-b9f2-5eb7-b1a2-6f283bb7e910', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4a070db3-65e8-5a87-8875-b52062e1df36', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Set Thịt Tuyển Chọn (4 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_set_select_4p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('22b295d5-fe10-524a-8293-c5acf348a9a6', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Thăn Lưng Ushiyoshi Cao Cấp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_sirloin_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('39abd938-f254-55cf-8b01-30218674d985', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Thăn Lưng Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_sirloin","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b015fdb2-b278-58a2-996c-dcb5682d220f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Ushiyoshi Cao Cấp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_premium","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('011e6b3b-6ea7-5f36-acf1-e95db95cd8c6', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Ushiyoshi Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('212a973a-b6f3-5aa8-b8f3-c5fc0fced322', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Ushiyoshi)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('02c545a1-a7f5-5425-8c91-a3b47a426b03', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Cao Cấp Nướng Kiểu Shabu (Xốt Sukiyaki)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_sukiyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9d664a1-1af3-50b2-98dd-039398a47016', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Xốt Muối Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a7186f04-6bb3-5b91-b11f-c682ac9a01af', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('73953959-4f42-5d00-a846-e3a9bc1fc549', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1aa40947-cdce-569b-bc24-41c3065d0d55', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Ushiyoshi)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_ushiyoshi2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b3c05685-8bec-5bc7-87ec-f21b99a7d0b8', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Miso Cay)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('94d92750-8713-58e4-969f-f0f7647297ad', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Ngắn Nướng Kiểu Shabu (Xốt Sukiyaki)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_shabu_sukiyaki2","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bcedd790-0172-5adc-8a45-30525956155e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Sườn Nguyên Tảng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_short_ribs_whole","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0a867ed0-9034-5111-8504-4e845707f9be', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'c3899596-122a-5c93-a20b-225120f2f2ff', 'Diềm Thăn Xốt Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beef_flap","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory offal
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('285f4b12-68f1-564c-920a-1dd45e6bca6f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Đặc Trưng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_special","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c1e6c6b6-0bc2-5632-8c8a-79b14768ed60', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Đặc Trưng 1', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_special_1","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ce28ebfe-03fe-58f0-bfb4-17ce6fd4cdcd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Non Ushiyoshi Xốt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_young_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dd491c0f-9cf0-5502-b55e-8d243da5d81c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Già Ushiyoshi Xốt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_old_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d27edf99-92fc-57fe-9e2b-bc11533099fd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Gan Bò Xốt Đặc Biệt', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_liver_special","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('56a8b477-1433-580a-9c2e-348355da74ff', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Non Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_young_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9b3b9ff1-35d3-5ede-bb16-7c7f66205eec', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Lòng Bò Già Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_old_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7871b65a-e480-5a4a-aee6-5fd360a8a90c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Gan Bò Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_liver_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d7d80532-1331-528d-8864-91109134d988', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt miso cay', 50000, 'Phần', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5f948c02-a40d-58f3-a302-9d42c9b7f021', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt miso cay', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_miso_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a869031f-2b7a-5f9a-9e8f-513b7c86aa32', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'b7bcbe61-7027-5e59-81c5-c53649c4a055', 'Dạ dày bò (tổ ong) sốt tare', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"offal_tripe_tare","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory pork
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a2c9aa20-6a43-528e-a66b-3c3352b97376', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7287a0fa-afb4-513f-bb63-7950089c62e2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('845da15a-89c7-57d8-af70-e408fdab5a2d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Ba Chỉ Heo Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_belly_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('67e0b863-2d7b-5358-a8e4-e5ca0e919bd2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2c73063f-1705-5aca-948e-8e2b55721705', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Ướp Miso', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ff62bd7c-fb05-5e4e-b4c2-a6f11e18fcb2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0e1d6ef1-ea55-5ed4-ab0c-48f5d14dacaf', 'Nọng Heo Ướp Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"pork_neck_miso_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory chicken
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c9023045-5785-50e5-a193-aa662198d9ca', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Đùi Gà Vị Muối', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_thigh_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8df54667-0f5f-57e6-aa4b-aa6f5b9a36c7', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Đùi Gà Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_thigh_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bd142585-42bd-585b-8b5f-6575414dc4db', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cổ Gà Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_neck_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('aeea8da6-5f3a-531d-9f20-eebb1862d787', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cổ Gà Ướp Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_neck_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('854fe4d6-6f53-575a-9a77-c44d4546d7ac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cánh Gà Vị Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_wing_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('721ca4cc-3907-5e72-9d1c-1727af6c7041', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'fe1e0cdb-23ed-573f-841d-3b4ab57d432c', 'Cánh Gà Miso Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"chicken_wing_miso","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory grill_alacarte
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7fe692f9-f777-5366-96dd-f2080ca4109b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Trứng gà', 120000, 'Phần', '120K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('66de4629-0da2-5514-8b06-52685f730f63', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Rau Củ Nướng Thập Cẩm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_vegetables","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4e5b1ee5-2928-5994-8828-a90b6060decb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Tôm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_shrimp","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8562bcc3-c6c4-5d86-a98f-7bcc857a1d47', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Bạch Tuộc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_octopus","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1e8a598a-9d0f-5d45-98b1-dff96ce65db4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Hải Sản Nướng Giấy Bạc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_seafood_foil","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8e2d1fe8-1240-5a4f-947d-ce644aff1294', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Bắp Nướng Bơ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_corn","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7ca292b5-c422-5331-997e-43363f66bbda', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Khoai Tây Nướng Bơ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_potato","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('05c021f6-1f20-57dd-bebc-c4c7fa65197e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'bc958c35-8f07-54e0-a64b-e6d14cc52b58', 'Tỏi Nướng Giấy Bạc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"grill_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory alacarte
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('68c2fda3-42ae-5072-9973-957cf2c5f597', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cá Ngân Chiên Giòn', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_fish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e0a0342c-0485-5fd8-af67-b2a28790be72', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Tôm Tempura', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_tempura","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3de823b5-9dfe-5243-8bd3-00e6fde7a6fb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Chả Cá Nhật Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fish_cake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fade93d6-3308-5d6c-92d2-8a724a4fb53c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cua Lột Chiên Giòn', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_crab","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0150e57e-9937-52f6-a52b-8423c9cca2e7', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Râu Sò Điệp Trộn Tiêu Tứ Xuyên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_scallop","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('32dc4952-1fa4-52ff-a4d4-6e3db6ce3d96', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cá Trứng Chiên Giòn', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_fish_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a537848d-f271-57c2-b262-5ddc39649a20', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Trứng Hấp Kiểu Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_steamed_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('952a24a6-521c-5d05-ae7c-d8d5d89a1729', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Gà Chiên Nhật Bản', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_chicken","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7e257e6a-be9e-5d3e-b337-54972a3697c3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Cánh Gà Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fried_wing","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9ad80cd-303e-5293-988a-adbdbfdbc172', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Khoai Tây Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_fries","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4ea4854d-f247-5b68-aa9d-8140cc9d5646', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Bánh Bạch Tuộc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_takoyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fa280acd-d762-56a6-8010-0e04bd688281', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Bánh Xèo Nhật Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_okonomiyaki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1ab7958a-e04c-5da2-8e31-2076c27680da', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Há Cảo Chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_gyoza","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('77471825-c4ab-5d2e-9169-75af43b65ebe', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Hamburger', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_hamburger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4e088d70-293f-554f-b74d-921902a5fe07', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Trứng Cuộn Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_rolled_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('47be26cc-f1b9-5fc6-9964-a52c506cfe5d', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Set Trẻ Em', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_kids_set","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ee06974e-64e4-5328-9cfc-1fe7a83d4c8f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '7e60b57c-ae52-5a75-b2e4-c4ec6c3813a2', 'Sushi Bò Wagyu Áp Lửa Hồng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"alacarte_wagyu_sushi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory appetizer
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4aa87ec7-d159-59f2-9676-38817cf78d63', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Đậu Nành Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('413bd0aa-4317-5f4a-957d-78364c5101ff', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Dưa Leo Trộn Kiểu Nhật', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_cucumber","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('becfb846-ff86-572b-af14-e8eac78ff49b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Tổng Hợp', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_mix","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a73b0ee3-237b-5008-b6f1-7f92d3d49150', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Cải Thảo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_cabbage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('11f7c01b-23d8-5f80-9b62-86ce5d037760', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Dưa Leo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_cucumber","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f87fe7e6-53bb-551b-a570-fd3c1dd759bb', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Kimchi Củ Cải', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_kimchi_radish","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2d3b85f1-ef05-5cd8-bc69-a4a0e8a026a3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ebf8cf7e-8ab7-5062-8049-4231a674e094', 'Rau Trộn Hàn Quốc (Tổng Hợp)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"appetizer_korean_salad","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory salad
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ebde1e52-1571-5529-a20d-f584ecaeb2b1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Ushiyoshi', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_ushiyoshi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e3b8e4ca-28b5-526a-9710-95f9543b7bcf', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Đậu Hũ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('809fa7ce-0d02-577f-8526-c50b0f0cd0db', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Salad Caesar', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_caesar","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('395708a7-0e7e-53f6-b018-16473cd59e89', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '550c50e2-ee85-5ded-aebb-12ea7a66143d', 'Xà lách', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"salad_lettuce","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory rice
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5bef6819-8d63-5e7b-88ef-c3a6f95f0e1e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Bibimbap Thố Đá', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_bibimbap_stone","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2102c2e5-1bf9-5d7a-8071-ac21c80625f1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Bibimbap Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_bibimbap_mini","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('23dbf27e-a18f-57f2-b633-f344fc2877ab', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Chiên Tỏi Thố Đá', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_fried_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5fa3ec07-ce18-5090-ab37-7fb66d0a0052', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Canh Cơm Hàn Quốc', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_korean_soup","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1997ee7d-70d0-5cc2-8c52-a34c4bb61079', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Chiên Kimchi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_fried_kimchi","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c230201b-a97d-5350-a04e-56d642a08641', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Gân Bò Mini', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_beef_tendon_mini","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4d0f6e8e-260e-5120-a3a6-177ad30d9953', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cà Ri Ushiyoshi', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_curry","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d0b61419-054f-5775-84f5-ce804580db13', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Ăn Kèm Yakiniku', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_yakiniku","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d13e07a2-ed6e-5111-9851-5fadcca317bf', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '0b8f0878-f117-5356-9ca3-febce150d9bd', 'Cơm Trắng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"rice_white","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory noodle
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f2d793a1-04ab-52ae-af25-9cc81b54fbb0', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Udon Lạnh Goto', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_udon_cold","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1a6a0f93-69f7-527d-ae07-b43d37694c49', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Udon Bò', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_udon_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0f37292a-1d03-5690-9c52-edad9f6dedfd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Xương Ống Hầm', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_bone_soup","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ab525a39-5e16-50c9-a2bb-02305a1d7e16', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Ramen Xào Bò', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_ramen_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9c63f5e-4045-5256-849c-d0f5a070a6e0', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Mì Ramen Xào Hải Sản', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_ramen_seafood","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0885f096-e4e7-5992-ac69-717c1b6801ab', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', '3c8fe227-2183-5b31-9a6e-4532411d1c60', 'Súp Mala Cay Tê', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"noodle_mala","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory soup
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('339b040a-d7d4-59a3-96c7-75ffed4928ac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp mala cay tê', 145000, 'Phần', '145K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_mala","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c1912f28-5af7-5b87-9b24-35461bfa8b08', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Phở', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_pho","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('be3d92cf-11dd-5526-86dd-04396f8c99f2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Rong Biển', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_seaweed","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2eba74c5-c873-551c-a678-099e685103b2', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Nghêu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_clam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('228a13e5-91b9-524b-8861-c06ace2461c4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Nghêu Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_clam_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('307b0bf0-a965-531e-8c0f-fd89716f488b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('84632bea-e71d-5159-a4f2-c1aa7d4c8d91', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ed1b7833-e3a6-5ca5-ab19-adea006ba826', 'Súp Chua Cay', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soup_sour_spicy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory dessert
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7a015f09-ab68-564d-a796-15ccd1c0091a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8afc01e9-b29a-5b68-8988-c6845f6de07b', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani Sốt Dâu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla_strawberry","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fb42ab70-89b3-5eb2-a93e-bd55502dff21', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Vani Sốt Socola', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_vanilla_chocolate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f5341af-8f57-5faf-85fb-64c6762cbfb3', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Matcha', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_matcha","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9aa73e55-e219-566f-a324-d263a757e20c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Chanh Yuzu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_yuzu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49698d2f-ce3f-5689-b55a-a542e8fcb6b4', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Kem Nho', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_grape","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('664e3243-4835-5bec-96a2-bde8855a0c28', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Bông Lan Phô Mai Trứng Muối', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_cheesecake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8de1af0f-cb42-57bd-add9-df269457f5c1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Cá Nhân Đậu Đỏ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_fish_cake_bean","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6d28378e-6ba4-521d-8efa-df5d2d89f742', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Cá Nhân Kem Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_fish_cake_cream","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8c1af3fd-6924-5a89-8810-baaa383f6270', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Dorayaki Đậu Đỏ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_dorayaki_bean","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6e0cbe7d-29ca-54fe-95a6-21f6fd0de966', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Dorayaki Kem Trứng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_dorayaki_cream","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a7fe0ca4-7d4d-5359-b301-16b9309e4357', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Su Kem', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_cream_puff","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d0a70d5f-1150-5a8c-941c-c677fff09876', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Bánh Chuối Nướng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_banana","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('972bfef8-b033-5542-a889-22d4e55079c5', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'dea7d26b-9dec-55cc-a324-1b6dd1c149f3', 'Gateau Sô-cô-la', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"dessert_chocolate_gateau","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory sauce
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('83eb8390-504f-52d7-a811-5e5d7732dbe8', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'Xốt Bơ Tỏi Xì Dầu', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sauce_butter_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('16c7e74d-1bf0-52fa-bd24-be55812e281e', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'a14cd11f-1ba8-594c-a5f2-cf8a836e3051', 'Xốt Phô Mai Nóng Chảy', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sauce_cheese","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory sukiyaki
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cbfb66b8-6c9d-5242-b112-f019138947ef', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đĩa rau thập cẩm (Phần cho 2 người)', 10000, 'Phần', '10K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f898a1ec-f87f-54c3-83d3-788aee617428', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đĩa rau thập cẩm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bb7c209e-29fd-5570-aa2b-b3f7932a832f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Mì Udon', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_udon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('556f9176-d50f-5ed6-b91b-e3cfca146395', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm đùi gà', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_eryngii","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('95d5645d-bf7d-51d9-b1aa-5865cdd81fdd', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm hương', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_shiitake","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('445381f4-33b0-5617-a71c-5cd679a4cf18', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nấm kim châm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_enoki_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ebb63232-0abd-5347-8241-46fd95dc4b54', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Rau củ và nấm thập cẩm (Phần cho 2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_mix_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9fdb972a-99d5-57dc-a40f-7551ce0794f1', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Rau củ và nấm thập cẩm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_vegetable_mix_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('80f70ee0-b059-51f4-9a41-5e3349ed4e21', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Trứng gà', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_egg","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b5a18469-159d-5c8a-a52b-c1779232deac', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Các loại nấm (Phần cho 2 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_mushroom_2p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('68240bab-2d9d-51b2-bb42-15b43f117589', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Các loại nấm (Phần cho 3 người)', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_mushroom_3p","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ec204c25-42c7-5843-8ca2-73fa6054a725', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cải thảo', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_cabbage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a9c1cf90-aa7e-5829-ac6f-5b468b504d98', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cải thìa', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_bok_choy","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3f78102c-6420-5cfd-bc10-f3dba49b01dc', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Cơm trắng', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_rice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f0a20c04-4e6f-5fff-8140-c9bf06ab139a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đậu hũ chiên', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_fried_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d3b19c89-97e3-5a3d-95b8-e99b01e07b8a', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Đậu hũ non', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_silken_tofu","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6b0e89c2-0523-58f5-975a-1c65bdf3bf6f', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Thịt bò dùng cho lẩu Shabu-Shabu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_beef","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('04c96cc8-0d47-5912-999e-398a3aa2329c', 'b1000000-0000-0000-0000-000000000001', 'cc6c8111-7144-5213-ac2d-aa85c28f28c3', 'ca82c088-92a3-53e8-a709-3a77bc673ff9', 'Nước lẩu', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sukiyaki_broth","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Thức Uống', 115, true, '{"fe_id":"thuc_uong"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_uong
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('96ceb6f0-22fb-5415-81d6-430112cc279d', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Soft drink', 0, true, '{"fe_id":"soft_drink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'NON ALCOHOLIC', 1, true, '{"fe_id":"non_alcoholic"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('d56d911a-f8d3-5701-ae7d-e320aa2a0bb7', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Tea', 2, true, '{"fe_id":"tea"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('acf426e4-de38-543e-a56d-90e930969619', '2ba2f809-37be-5d04-84a5-04e792631de4', 'b1000000-0000-0000-0000-000000000001', 'Đồ uống – Set', 3, true, '{"fe_id":"drink_set"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory soft_drink
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('544421c1-b60d-52e2-a248-d0b999f2ca72', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Đào', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_peach_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('534bb1e9-fdec-54a0-88f3-7ce552c4e8b5', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Vải', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_lychee_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fecb2d65-a3f6-580b-b3c0-0cc7882026bd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Cam', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_orange_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ae484f76-f3fb-5079-b309-b28500433657', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Ép Táo', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_apple_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ff2ead0a-e848-55a0-9cd9-c9f96ada0584', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Ép Trái Cây Tổng Hợp', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_mixed_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5ab14b61-0f54-5306-af61-ddc22323d588', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Coca-Cola', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_coca","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4daa7511-7ccc-50c9-8417-d8a5a5a385d8', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Trân Châu', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_bubble_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a5ad02a7-691d-5bb6-9455-f4fe2a2e57d5', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Coca-Cola Zero', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_coca_zero","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('116adc3f-1806-5876-a426-7302695d7bec', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Thái Xanh', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_thai_green_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cd9248ec-6528-5261-a0e8-0d661d3c78bb', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', '7UP', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_7up","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ac97f456-3f6d-5eb2-82c2-8bc72c8685fa', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Sữa Thái Đỏ', 50000, 'Ly', '50K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_thai_red_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('caa41a0b-7bd6-5e78-a6d0-fd6932f86ca9', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Soda', 35000, 'Lon', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7ef8edbf-bf28-5701-84e3-799916f7cbdd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Trà Lài', 35000, 'Ly', '35K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_jasmine_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('56e33116-9236-5f67-93e4-2734dbbbece9', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', '96ceb6f0-22fb-5415-81d6-430112cc279d', 'Nước Suối', 25000, 'Chai', '25K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"soft_water","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory non_alcoholic
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('adf43cdc-1509-5e8d-8d2f-f81d084d9b55', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Nước chanh xanh biển', 80000, 'Ly', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_green_lemon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5449a3ec-c7e2-5e4a-9763-19ac6f11057b', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Chanh Vải', 78000, 'Ly', '78K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_lychee","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f25ae630-675c-5e77-8332-1fa426672b17', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Cassis Nho', 108000, 'Ly', '108K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_cassis","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4f8ef6ff-f88b-5e7c-8299-212a6bd3d6e7', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'cf8371ba-aca1-58bd-9959-2c57c1e8cb7d', 'Soda Dứa Chanh Dây', 78000, 'Ly', '78K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"non_alc_soda_pineapple","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory tea
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('206e190d-2f8a-5dfb-a56c-40586d37394f', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Xanh Nhật Bản', 80000, 'Ly', '80K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_green_japan","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('decff9b9-ccb2-510a-a6f1-7dd21e864809', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Đào', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('697a6b15-a18d-5ef0-b266-b84d2fc4f512', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'd56d911a-f8d3-5701-ae7d-e320aa2a0bb7', 'Trà Vải', 72000, 'Ly', '72K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"tea_lychee","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory drink_set
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e4a673d7-04c0-501e-a4a7-abc31d83585c', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', '7UP', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_7up","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('7a1bce5e-1c32-5b89-9c25-f5d5773d4a9d', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Coca-Cola', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_coca","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e422fa9c-5302-56bc-9ff5-9896fcfdebfd', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Coca-Cola Zero', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_coca_zero","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5482b8f9-4d38-5ffe-8bc0-20e16b5c76b2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Cam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_orange","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c58196de-3276-5d0f-9958-3795b3c6b864', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Ép Táo', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_apple","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('92f0dce5-2baa-58f5-b792-ebaa7d41fc30', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Ép Trái Cây Tổng Hợp', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_mixed_juice","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c94cfa9d-9ddf-5ff2-81e8-e05d60ec34a2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Nước Suối', 0, 'Chai', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_water","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2d607663-9702-5080-910f-f6b9f8cc7c39', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Lài', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_jasmine_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('20b092c2-7124-50f9-bd31-dd62f50e37fe', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Soda', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('de7fcfa7-d983-59b3-97a6-b7bd8f589d8d', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Thái Đỏ', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_thai_red","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('13fee4fd-0abf-5194-9f13-12ef6008d4b2', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Thái Xanh', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_thai_green","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('afd7474c-e7db-5696-a168-c7aef4f81dc6', 'b1000000-0000-0000-0000-000000000001', '2ba2f809-37be-5d04-84a5-04e792631de4', 'acf426e4-de38-543e-a56d-90e930969619', 'Trà Sữa Trân Châu', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_bubble_tea","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Thức Uống Có Cồn', 116, true, '{"fe_id":"thuc_uong_co_con"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category thuc_uong_co_con
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4c88869f-e3e9-5b45-be56-6b624fad3182', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Bia', 0, true, '{"fe_id":"beer"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Whisky', 1, true, '{"fe_id":"whisky"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Shochu', 2, true, '{"fe_id":"shochu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('52790926-f71b-5e3a-b7fd-6a128737a3c0', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Nihonshuu', 3, true, '{"fe_id":"nihonshuu"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('f182c2e3-67b8-5757-b6af-95e7567fed21', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Wine', 4, true, '{"fe_id":"wine"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('6edb3670-30bb-5398-9485-87cf86cb2a6a', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'b1000000-0000-0000-0000-000000000001', 'Đồ uống có cồn – Set', 5, true, '{"fe_id":"alcohol_set"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory beer
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8c0f33aa-4293-5709-8f8d-fe794cd80722', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4c88869f-e3e9-5b45-be56-6b624fad3182', 'Bia Tươi Sapporo', 178000, 'Ly', '178K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beer_sapporo","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5fd1782b-4043-5b4a-b922-ea42bd05b1aa', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4c88869f-e3e9-5b45-be56-6b624fad3182', 'Bia Tiger', 55000, 'Lon', '55K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"beer_tiger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory whisky
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f51416e5-92ca-5625-967f-1a8792382f09', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'Rượu Jim Beam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"whisky_jim_beam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6cef9f6-77fa-5117-a398-d04dea5c6ade', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '4a4ea6a3-04bd-5747-a33a-1a07cf10c9a3', 'Rượu Suntory Kaku', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"whisky_suntory","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory shochu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d796dd6f-4373-5a14-8f09-edf736f09b66', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Kuro Kurishima Bottle', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_kuro_kirishima_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49a186b6-87ca-57a9-a265-259095e2daa7', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Sâm Cau Việt Nam', 1000000, 'Lọ', '1.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_sam_cau","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5257b5c8-ba94-5a4b-87f0-dbf23e6b5c13', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Lemon Soda', 90000, 'Ly', '90K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_lemon_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8400de4a-6986-5c2c-add2-b56858186e1a', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Mơ', 86000, 'Ly', '86K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_plum","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dcba0d42-d121-52b6-83dc-99631f466e88', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Chuhai Đào Fukushima', 119000, 'Ly', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_chuhai_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('52ec327a-9f17-5da5-b0fc-b0ea6a19a862', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Chuhai Quýt Arita', 119000, 'Ly', '119K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_chuhai_tangerine","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a81a7dc1-24e8-5bc7-b8a1-215f2c8207a3', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu iichiko', 98000, 'Ly', '98K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_iichiko","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('847a9359-6036-5662-a894-7a08caccfdbe', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'e63ebd41-d08e-5ce1-a335-5b9f26fc4b4c', 'Rượu Kuro Kirishima', 98000, 'Ly', '98K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"shochu_kuro_kirishima_glass","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory nihonshuu
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ae3fb2f9-cef5-5a43-bdc0-4c430c13ecae', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Awayuki Sparkling Sake', 450000, 'Chai', '450K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_awayuki","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('43c6d95f-06e5-527e-ab40-6e534019c8da', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Kijuro (喜十郎)', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_kijuro","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('762003b3-4367-55b1-bc89-16861af98628', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Dassai (獺祭)', 890000, 'Chai', '890K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_dassai","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('33713e7a-3033-521d-82c4-b38f6c13e63b', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '52790926-f71b-5e3a-b7fd-6a128737a3c0', 'Nabeshima (鍋島)', 2000000, 'Chai', '2.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"sake_nabeshima","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory wine
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f0a98b7a-5abe-5f43-ba92-d823fd806099', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Mussel Bay (chai)', 880000, 'Chai', '880K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_mussel_bay_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('64259f3a-fd36-5deb-aa80-f57c8de3c41e', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Mussel Bay/white', 150000, 'Ly', '150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_mussel_bay_white","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0b64f762-046d-51bb-8b16-f72b28814c99', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Michel Lynch (chai)', 880000, 'Chai', '880K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_michel_lynch_bottle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('5afe42e6-a0da-51ec-9f72-424cdb13cea7', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Michel Lynch/red', 150000, 'Ly', '150K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_michel_lynch_red","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0f5cfe34-9763-5751-a296-1369de65b818', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Champagne Bollinger Special Cuvée', 4000000, 'Chai', '4.000K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_bollinger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0e719943-f4ac-52c1-b467-e07cc8862315', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Parallèle 45 Côtes du Rhône PJA/white', 1200000, 'Chai', '1.200K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_parallel_45","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bb7816b5-18f8-5398-a965-f01b78a8b1bf', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Chablis – Courtault Michelet/white', 2300000, 'Chai', '2.300K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_chablis","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c87d5306-644c-5623-a895-24e2b15c1e8b', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Logan Weemala/red', 1180000, 'Chai', '1.180K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_logan","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('41a82df1-b864-536d-9e7c-c6acffdfc8ca', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'La Posta Fazzio/red', 1380000, 'Chai', '1.380K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_la_posta","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('bc18f965-8032-5fc2-a3ca-86239e2788ac', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Château Haut-Cadet Saint-Émilion Grand Cru/red', 2500000, 'Chai', '2.500K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_haut_cadet","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d74bc353-efa2-5799-b92d-d7b7cffa6691', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', 'f182c2e3-67b8-5757-b6af-95e7567fed21', 'Côte de Nuits Villages – Lou Dumont/red', 3800000, 'Chai', '3.800K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"wine_cote_nuits","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory alcohol_set
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dd0942aa-7ae1-58be-b3fe-e56348fe3b26', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu iichiko', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_iichiko","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f5b7bc4a-e888-5301-95ac-f275629db1b5', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Jim Beam', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_jim_beam","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1bc3b983-5c14-5547-ab16-99d1aed964cc', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Suntory Kaku', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_suntory","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f1616018-f27f-5cdb-98a2-b08390a8e03c', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Chuhai Đào Fukushima', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_chuhai_peach","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8e844212-f595-5f6b-9ed9-ec13addf8d0e', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Chuhai Quýt Arita', 0, 'Lọ', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_chuhai_tangerine","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('50af49c2-a738-5617-a973-b2f2f0225a01', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Lemon Soda Liqueur', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_lemon_soda","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b6b3f2ab-c43b-51d4-8771-91df649080d6', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Mơ', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_plum","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6d121514-f493-56cb-b011-c63953adba03', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Bia Tiger', 0, 'Lon', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_tiger","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2034d9d2-5435-507b-b94d-d547d134274a', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Bia Tươi Sapporo', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_sapporo","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d3bd9778-36eb-5aaf-9ba0-a78392592252', 'b1000000-0000-0000-0000-000000000001', 'be5c467c-d91e-5625-92b3-fe93509cf35a', '6edb3670-30bb-5398-9485-87cf86cb2a6a', 'Rượu Kuro Kirishima', 0, 'Ly', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"set_kuro_kirishima","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)
VALUES ('7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Khác', 117, true, '{"fe_id":"khac"}', 'pink')
ON CONFLICT (id) DO NOTHING;

-- 1b. Subcategories under category khac
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('0e336964-491c-5c77-87ee-b02be449443a', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Phục vụ', 0, true, '{"fe_id":"service"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'Gia Vị', 1, true, '{"fe_id":"condiment"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)
VALUES ('980e540c-2ab7-546b-8eff-e4b70d367afc', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', 'b1000000-0000-0000-0000-000000000001', 'PHÍ PHỤ THU', 2, true, '{"fe_id":"surcharge"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory service
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('881ec138-de8b-5a24-9386-15c902347004', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Chén', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_bowl","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('ccdf50e1-4a7a-52e7-9040-d719ee7987ec', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Đĩa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d8eff0e0-1bc2-591b-82c5-a72a4b95d41e', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Đĩa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_plate_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('32752b39-3129-50b5-aa44-6e679c40d76d', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Khăn giấy lau', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tissue","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2f4be945-d9cf-5463-ab16-964ce17448d0', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Khăn giấy lau', 0, 'hộp', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tissue_box","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cd33c2cf-a7dc-5e9e-b933-ae0ffa0fe938', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kéo', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_scissors","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e7a31d03-cb54-5a87-a71f-06681a59a2aa', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kéo', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_scissors_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c4cb8fb2-1a88-549c-b6a7-4e3d2aebaae3', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kẹp Gắp', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tongs","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('cee85c91-8dc8-5632-addc-ebd0a6e0d98c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Kẹp Gắp', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_tongs_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f6dc9659-e2c5-50ac-b01e-67e233897c0a', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muôi Múc Canh', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_ladle","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f250fe45-1b58-53cc-a670-c3e090629a77', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muôi Múc Canh', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_ladle_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1013d22f-b325-5fe4-a90f-28b201f32201', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Muỗng', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('f2ba48bb-1eb8-5073-9a2e-45da92e6467b', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Thìa Desert', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_dessert_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9d7c2c8f-53dd-5eeb-87b3-23bbcc44ba8c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Lấy Thìa Desert', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_dessert_spoon_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('50cca2a9-80f4-5faa-8e06-eb494215f686', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Nĩa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_fork","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('3fe7c404-3bb5-5f85-9431-74e03e549f19', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Nĩa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_fork_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c6755873-93f3-501b-9f21-1153e2bfb639', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Tạp dề giấy', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_apron","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('49e5c399-6f64-5a43-8af4-74a35c467117', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Đũa', 0, 'đôi', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_chopsticks","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('6cb6cd8a-f23a-5838-9b69-82c1fdaa0c25', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Đũa', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_chopsticks_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('d020ba4e-67bc-5535-a451-92f227eae901', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Khăn', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_towel","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('1e5e3d55-e3e4-51cf-94ce-df85b97b6568', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Khăn', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_towel_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('dacb9617-d60c-5c49-ae45-c95ccef20bce', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Than', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_charcoal","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('e9e9deef-9da7-5f0c-b576-448a81b744e9', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Than', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_charcoal_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('0146fb04-eac5-5147-8a19-107b5ab21e2b', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Vỉ', 0, 'Phần', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_grill_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b9eb11fd-ccf0-5f73-91ab-f3e91eb8fc0d', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thay Vỉ', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_grill_plate_piece","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9a47fc7d-8292-51ac-ae95-04271b4e6b2e', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thêm Đĩa (Đĩa Thường)', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_extra_plate","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c258d5a0-8721-5150-a1f1-c40fd9ce7b2a', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thêm Đĩa (Đĩa Thường)', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_extra_plate_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('15d68dd6-0c46-57b9-8aa9-8d94eb6564e4', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thìa Trẻ Em', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_spoon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('2a590433-2108-5b98-90f5-cbaa62a1beb5', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '0e336964-491c-5c77-87ee-b02be449443a', 'Thìa Trẻ Em', 0, 'cái', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"svc_kids_spoon_piece","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory condiment
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('db98c6b8-59f8-512f-8b0d-1f2ace494189', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Chanh', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_lemon","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('9861bab9-2bf8-5d42-8f72-4067ee2690da', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Hành lá nhỏ', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_green_onion","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('b09892e9-ba6a-55e9-ae5e-7f1d8e2958fd', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Mù Tạt', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_mustard","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('506e4c35-f858-5174-91ad-6bd331e825a3', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Muối', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_salt","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('fb298968-6cbb-5152-91c0-d2db9b89c677', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Ớt Xắt', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_chili","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('8a460eb7-c1bb-5dab-a275-80949a9a4a27', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Sốt chấm', 0, 'Đĩa', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_dipping_sauce","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('a8548ae7-84fc-5f59-8429-3d8d6c55afc5', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Sốt chấm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_dipping_sauce_bag","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('4bab8f0a-cd72-5646-a2d9-1d7332950296', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '1ea70ed8-8bf8-592c-8198-7ca1c4a4dc7e', 'Tỏi Băm', 0, 'BỊCH', '0K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"cond_garlic","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

-- Items under subcategory surcharge
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('c04d21e5-a79b-5787-b7d1-10c4e052631c', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '980e540c-2ab7-546b-8eff-e4b70d367afc', 'Phí phụ thu mang rượu', 400000, 'Chai', '400K', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"surcharge_corkage","color":"pink"}')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)
VALUES ('99c36f6e-5f76-516e-9a2c-ba021e92b5bc', 'b1000000-0000-0000-0000-000000000001', '7414f1e4-aa66-56e0-8f17-82d56e5269c2', '980e540c-2ab7-546b-8eff-e4b70d367afc', 'Phí phụ thu thức ăn thừa', 500, 'gram', '50K/100g', true, '[]'::jsonb, '{}'::jsonb, '{"fe_id":"surcharge_leftover","color":"pink"}')
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- Verification query (commented out — run manually to confirm):
-- SELECT count(*) AS categories FROM public.menu_categories;
-- SELECT count(*) AS subcategories FROM public.menu_subcategories;
-- SELECT count(*) AS items FROM public.menu_items;