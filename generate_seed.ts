import fs from 'fs';
import path from 'path';
import { menuCategories } from './src/data/menuData';

let sql = `-- NGUU CAT POS - AUTO GENERATED SEED
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

`;

let _catId = 1;

for (const cat of menuCategories) {
    sql += `-- Category: ${cat.name}\n`;
    sql += `INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_${cat.id}', '${cat.name}', ${_catId}) ON CONFLICT DO NOTHING;\n`;
    _catId++;
    
    // Process items in the main category
    if (cat.items) {
        for (const item of cat.items) {
            const itemType = item.category_id === 'buffet' ? 'buffet_package' : 'food'; // simplified
            sql += `
DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_${cat.id}';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, '${item.id}', '${item.name.replace(/'/g, "''")}', '${itemType}', '${item.unit}', '${item.image_url || ''}')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, ${item.price});
EXCEPTION WHEN unique_violation THEN
    -- Ignore if exists
END $$;
`;
        }
    }
    
    // Process subcategories
    if (cat.subcategories) {
        for (const sub of cat.subcategories) {
            sql += `-- SubCategory: ${sub.name}\n`;
            sql += `INSERT INTO public.menu_categories (category_code, category_name, sort_order) VALUES ('CAT_${sub.id}', '${sub.name}', ${_catId}) ON CONFLICT DO NOTHING;\n`;
            _catId++;
            
            for (const item of sub.items) {
                let itemType = 'food';
                if (item.category_id === 'buffet' || sub.id.startsWith('buffet')) itemType = 'buffet_package';
                else if (item.category_id.includes('drink') || sub.id.includes('drink')) itemType = 'drink';
                
                sql += `
DO $$
DECLARE
    v_cat_id uuid;
    v_item_id uuid;
BEGIN
    SELECT menu_category_id INTO v_cat_id FROM public.menu_categories WHERE category_code = 'CAT_${sub.id}';
    
    INSERT INTO public.menu_items (menu_category_id, item_code, item_name, item_type, unit_name, image_url)
    VALUES (v_cat_id, '${item.id}', '${item.name.replace(/'/g, "''")}', '${itemType}', '${item.unit}', '${item.image_url || ''}')
    RETURNING menu_item_id INTO v_item_id;
    
    INSERT INTO public.branch_menu_items (branch_id, menu_item_id, base_price_vnd)
    VALUES ('00000000-0000-4000-8000-000000000000'::uuid, v_item_id, ${item.price});
EXCEPTION WHEN unique_violation THEN
    -- Ignore
END $$;
`;
            }
        }
    }
}

sql += `\nCOMMIT;\n`;

import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

fs.writeFileSync(path.resolve(__dirname, 'supabase/seed.sql'), sql);
console.log('Successfully generated supabase/seed.sql');
