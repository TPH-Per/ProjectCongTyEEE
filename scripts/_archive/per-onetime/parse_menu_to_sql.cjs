// scripts/_archive/per-onetime/parse_menu_to_sql.js
//
// One-shot generator: parse the Ishii `thực đơn.txt` (which is a TS file
// containing a `menuData` JS object) and emit a Postgres-compatible SQL
// file that seeds the menu_categories / menu_subcategories / menu_items
// tables. Not part of the runtime — kept under _archive/per-onetime.
//
// Usage:  node scripts/_archive/per-onetime/parse_menu_to_sql.js \
//             docs/member_status/Ishii/thực\ đơn.txt \
//             supabase/migrations/20260625130000_seed_menu_from_ishii.sql
//
// The output file uses ON CONFLICT DO NOTHING + deterministic UUIDs derived
// from the FE item/category id (so re-running the migration is a no-op).

const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const [,, inFile, outFile] = process.argv;
if (!inFile || !outFile) {
  console.error('Usage: node parse_menu_to_sql.js <input.ts> <output.sql>');
  process.exit(1);
}

// -- 1. Read the source and strip the TS type annotation so we can eval it.
const src = fs.readFileSync(inFile, 'utf8');
// Replace "export const menuData: MenuData = " with "module.exports = "
const jsSrc = src
  .replace(/^export const menuData\s*:\s*MenuData\s*=\s*/m, 'module.exports = ')
  .replace(/;?\s*$/, ';');
const tmpFile = path.join(require('os').tmpdir(), 'menu_data_' + Date.now() + '.js');
fs.writeFileSync(tmpFile, jsSrc);
const menuData = require(tmpFile);
fs.unlinkSync(tmpFile);

// -- 2. Deterministic UUID v5 (namespace = 'nguucat-menu') so the same FE
// id always maps to the same DB id. Re-running the migration is a no-op.
const NAMESPACE = '6f1d2b4e-9b3a-4f5d-8c7e-1a2b3c4d5e6f';
function uuidFor(s) {
  const h = crypto.createHash('sha1').update(NAMESPACE + '::' + s).digest();
  // Set version (5) and variant (10xx) per RFC 4122
  h[6] = (h[6] & 0x0f) | 0x50;
  h[8] = (h[8] & 0x3f) | 0x80;
  const hex = h.toString('hex');
  return [
    hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16),
    hex.slice(16, 20), hex.slice(20, 32),
  ].join('-');
}

// -- 3. Helpers to escape SQL string literals.
function sqlStr(s) {
  if (s == null) return 'NULL';
  return "'" + String(s).replace(/'/g, "''") + "'";
}
function sqlNum(n) {
  if (n == null || Number.isNaN(Number(n))) return 'NULL';
  return String(Number(n));
}

// -- 4. Walk the menu tree and emit SQL.
const out = [];
out.push(`-- =============================================================================`);
out.push(`-- AUTO-GENERATED from docs/member_status/Ishii/thực đơn.txt`);
out.push(`-- Source: Ishii's menuData.ts (700+ items across 12 categories, 16 subcategories)`);
out.push(`-- Generated at: ${new Date().toISOString()}`);
out.push(`-- DO NOT EDIT BY HAND — regenerate via scripts/_archive/per-onetime/parse_menu_to_sql.js`);
out.push(`--`);
out.push(`-- Idempotent: every insert uses ON CONFLICT DO NOTHING against a deterministic`);
out.push(`-- UUID (uuidFor) so re-running the migration does not duplicate rows.`);
out.push(`-- =============================================================================`);
out.push(`BEGIN;`);
out.push(``);
out.push(`-- 1. Categories (12)`);
out.push(`-- ----------------------------------------------------------------------------`);
let sortOrder = 100;
for (const cat of menuData.categories) {
  const catId = uuidFor('cat::' + cat.id);
  out.push(
    `INSERT INTO public.menu_categories (id, branch_id, name, sort_order, is_active, metadata, color)`,
    `VALUES ('${catId}', 'b1000000-0000-0000-0000-000000000001', ${sqlStr(cat.name)}, ${sortOrder++}, true, '${`{"fe_id":"${cat.id}"}`}', ${sqlStr(cat.color)})`,
    `ON CONFLICT (id) DO NOTHING;`,
  );
  out.push(``);

  // Direct items (no subcategories)
  if (cat.items) {
    out.push(`-- 1a. Items under category ${cat.id} (no subcategory)`);
    for (const it of cat.items) {
      const itId = uuidFor('item::' + it.id);
      out.push(
        `INSERT INTO public.menu_items (id, branch_id, category_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)`,
        `VALUES ('${itId}', 'b1000000-0000-0000-0000-000000000001', '${catId}', ${sqlStr(it.name)}, ${sqlNum(it.price)}, ${sqlStr(it.unit)}, ${sqlStr(it.price_display)}, true, '[]'::jsonb, '{}'::jsonb, '${`{"fe_id":"${it.id}","color":"${cat.color || ''}"}`}')`,
        `ON CONFLICT (id) DO NOTHING;`,
      );
    }
    out.push(``);
  }

  // Subcategories + their items
  if (cat.subcategories) {
    out.push(`-- 1b. Subcategories under category ${cat.id}`);
    let subOrder = 0;
    for (const sub of cat.subcategories) {
      const subId = uuidFor('sub::' + sub.id);
      out.push(
        `INSERT INTO public.menu_subcategories (id, category_id, branch_id, name, sort_order, is_active, metadata)`,
        `VALUES ('${subId}', '${catId}', 'b1000000-0000-0000-0000-000000000001', ${sqlStr(sub.name)}, ${subOrder++}, true, '${`{"fe_id":"${sub.id}"}`}')`,
        `ON CONFLICT (id) DO NOTHING;`,
      );
    }
    out.push(``);

    for (const sub of cat.subcategories) {
      const subId = uuidFor('sub::' + sub.id);
      out.push(`-- Items under subcategory ${sub.id}`);
      for (const it of sub.items) {
        const itId = uuidFor('item::' + it.id);
        out.push(
          `INSERT INTO public.menu_items (id, branch_id, category_id, subcategory_id, name, price, unit, price_display, is_active, tags, nutrition, metadata)`,
          `VALUES ('${itId}', 'b1000000-0000-0000-0000-000000000001', '${catId}', '${subId}', ${sqlStr(it.name)}, ${sqlNum(it.price)}, ${sqlStr(it.unit)}, ${sqlStr(it.price_display)}, true, '[]'::jsonb, '{}'::jsonb, '${`{"fe_id":"${it.id}","color":"${cat.color || ''}"}`}')`,
          `ON CONFLICT (id) DO NOTHING;`,
        );
      }
      out.push(``);
    }
  }
}

out.push(`COMMIT;`);
out.push(``);
out.push(`-- Verification query (commented out — run manually to confirm):`);
out.push(`-- SELECT count(*) AS categories FROM public.menu_categories;`);
out.push(`-- SELECT count(*) AS subcategories FROM public.menu_subcategories;`);
out.push(`-- SELECT count(*) AS items FROM public.menu_items;`);

fs.writeFileSync(outFile, out.join('\n'));
console.log(`Wrote ${outFile}`);
console.log(`Categories: ${menuData.categories.length}`);
const subCount = menuData.categories.reduce((n, c) => n + (c.subcategories?.length || 0), 0);
const itemCount = menuData.categories.reduce((n, c) => {
  let k = (c.items?.length || 0);
  for (const s of (c.subcategories || [])) k += s.items.length;
  return n + k;
}, 0);
console.log(`Subcategories: ${subCount}`);
console.log(`Items: ${itemCount}`);
