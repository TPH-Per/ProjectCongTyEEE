-- =============================================================================
-- 20260625210000_seed_zones_and_tables_full.sql
--
-- Seed a full restaurant floor plan (zones + tables) for both B001
-- (Ngưu Cát Quận 1) and B002 (Ngưu Cát Phú Nhuận).
--
-- Original seed (20260623000000_setup.sql §11.2-11.3) only created 5 zones
-- (with the " - VIP / Sân Vườn / Tầng 2 / Phòng Riêng / Terrace" suffixes)
-- and 5 tables for B001 (3 in Khu A, 2 in Khu B) and zero zones/tables for
-- B002. The AdminFloorsView UI is built around a 10-zone, ~57-table layout
-- (Khu A, B, C, R, T + 5 delivery-app zones: Capichi, Shopee, BE, Grab,
-- Catalog — short display names that match the Pinia store's mock data).
--
-- This migration is idempotent:
--   * zones: insert only if (branch_id, name) doesn't already exist
--   * tables: on conflict (branch_id, code) do nothing
--
-- Notes:
--   * zone.color uses Tailwind hex so AdminFloorsView's zone dropdown chips
--     and the optional canvas-based FloorPlanView render the same hue.
--   * table.shape is one of ('round','square','rectangle') per the schema
--     check constraint. VIP rooms = round, banquet = rectangle, ban công =
--     square, delivery 'bàn' = square (capacity 1).
--   * pos_x / pos_y are seeded so the optional canvas floor plan renders
--     sensibly. AdminFloorsView uses CSS grid so these are only consumed
--     if you switch to absolute positioning later.
--   * status defaults to 'available'; an admin can flip a table to
--     'maintenance' via the existing AdminFloorsView edit-mode UI.
-- =============================================================================

-- ----- Zones for B001 -----
insert into public.zones (branch_id, name, color, sort_order, is_active)
select b.id, z.name, z.color, z.sort_order, true
from public.branches b
cross join (values
  ('Khu A',           '#F59E0B', 1),
  ('Khu B',           '#A855F7', 2),
  ('Khu C',           '#10B981', 3),
  ('Khu R',           '#EF4444', 4),
  ('Khu T',           '#3B82F6', 5),
  ('Khu Capichi',     '#EC4899', 6),
  ('Khu Shopee',      '#F97316', 7),
  ('Khu BE',          '#06B6D4', 8),
  ('Khu Grab',        '#22C55E', 9),
  ('Khu Catalog',     '#6B7280', 10)
) as z(name, color, sort_order)
where b.code = 'B001'
  and not exists (
    select 1 from public.zones zx
    where zx.branch_id = b.id and zx.name = z.name
  );

-- ----- Zones for B002 -----
insert into public.zones (branch_id, name, color, sort_order, is_active)
select b.id, z.name, z.color, z.sort_order, true
from public.branches b
cross join (values
  ('Khu A',           '#F59E0B', 1),
  ('Khu B',           '#A855F7', 2),
  ('Khu C',           '#10B981', 3),
  ('Khu R',           '#EF4444', 4),
  ('Khu T',           '#3B82F6', 5),
  ('Khu Capichi',     '#EC4899', 6),
  ('Khu Shopee',      '#F97316', 7),
  ('Khu BE',          '#06B6D4', 8),
  ('Khu Grab',        '#22C55E', 9),
  ('Khu Catalog',     '#6B7280', 10)
) as z(name, color, sort_order)
where b.code = 'B002'
  and not exists (
    select 1 from public.zones zx
    where zx.branch_id = b.id and zx.name = z.name
  );

-- ----- Tables for B001 -----
-- Resolve zone_id by (branch_id, zone.name) so the insert is robust to
-- the zones table's auto-generated PKs.
with
  z as (
    select z.id, z.branch_id, z.name
    from public.zones z
    join public.branches b on b.id = z.branch_id and b.code = 'B001'
  )
insert into public.tables (branch_id, zone_id, code, capacity, shape, pos_x, pos_y, status, is_active)
select
  z.branch_id,
  z.id,
  t.code, t.capacity, t.shape, t.pos_x, t.pos_y, 'available', true
from z, (values
  -- Khu A (9 bàn, 4-8 khách) - "Khu chính trong nhà"
  ('Khu A', 'A01', 4, 'round',     1,  1),
  ('Khu A', 'A02', 4, 'round',     2,  1),
  ('Khu A', 'A03', 6, 'round',     3,  1),
  ('Khu A', 'A04', 6, 'round',     4,  1),
  ('Khu A', 'A05', 4, 'round',     1,  2),
  ('Khu A', 'A06', 4, 'round',     2,  2),
  ('Khu A', 'A07', 4, 'round',     3,  2),
  ('Khu A', 'A08', 8, 'rectangle', 4,  2),
  ('Khu A', 'A09', 4, 'round',     1,  3),
  -- Khu B (3 bàn VIP, 8-10 khách) - "Khu VIP trong nhà"
  ('Khu B', 'B01', 10, 'round',    1,  1),
  ('Khu B', 'B02', 8,  'round',    2,  1),
  ('Khu B', 'B03', 10, 'round',    3,  1),
  -- Khu C (8 bàn, 2-4 khách) - "Ban công ngoài trời"
  ('Khu C', 'C01', 2, 'square', 1, 1),
  ('Khu C', 'C02', 2, 'square', 2, 1),
  ('Khu C', 'C03', 4, 'square', 3, 1),
  ('Khu C', 'C04', 4, 'square', 4, 1),
  ('Khu C', 'C05', 2, 'square', 1, 2),
  ('Khu C', 'C06', 4, 'square', 2, 2),
  ('Khu C', 'C07', 2, 'square', 3, 2),
  ('Khu C', 'C08', 4, 'square', 4, 2),
  -- Khu R (8 phòng riêng, 6-12 khách)
  ('Khu R', 'R01', 6,  'round',     1, 1),
  ('Khu R', 'R02', 6,  'round',     2, 1),
  ('Khu R', 'R03', 6,  'round',     3, 1),
  ('Khu R', 'R04', 6,  'round',     4, 1),
  ('Khu R', 'R05', 8,  'round',     1, 2),
  ('Khu R', 'R06', 6,  'round',     2, 2),
  ('Khu R', 'R07', 6,  'round',     3, 2),
  ('Khu R', 'R08', 12, 'rectangle', 4, 2),
  -- Khu T (8 bàn, 4 khách) - "Sân thượng ngắm cảnh"
  ('Khu T', 'T01', 4, 'square', 1, 1),
  ('Khu T', 'T02', 4, 'square', 2, 1),
  ('Khu T', 'T03', 4, 'square', 3, 1),
  ('Khu T', 'T04', 4, 'square', 4, 1),
  ('Khu T', 'T05', 4, 'square', 1, 2),
  ('Khu T', 'T06', 4, 'square', 2, 2),
  ('Khu T', 'T07', 4, 'square', 3, 2),
  ('Khu T', 'T08', 4, 'square', 4, 2),
  -- Khu Capichi (5 đơn, capacity 1)
  ('Khu Capichi', 'CP01', 1, 'square', 1, 1),
  ('Khu Capichi', 'CP02', 1, 'square', 2, 1),
  ('Khu Capichi', 'CP03', 1, 'square', 3, 1),
  ('Khu Capichi', 'CP04', 1, 'square', 4, 1),
  ('Khu Capichi', 'CP05', 1, 'square', 1, 2),
  -- Khu Shopee
  ('Khu Shopee', 'Shopee01', 1, 'square', 1, 1),
  ('Khu Shopee', 'Shopee02', 1, 'square', 2, 1),
  ('Khu Shopee', 'Shopee03', 1, 'square', 3, 1),
  ('Khu Shopee', 'Shopee04', 1, 'square', 4, 1),
  ('Khu Shopee', 'Shopee05', 1, 'square', 1, 2),
  -- Khu BE
  ('Khu BE', 'BE01', 1, 'square', 1, 1),
  ('Khu BE', 'BE02', 1, 'square', 2, 1),
  ('Khu BE', 'BE03', 1, 'square', 3, 1),
  ('Khu BE', 'BE04', 1, 'square', 4, 1),
  ('Khu BE', 'BE05', 1, 'square', 1, 2),
  -- Khu Grab
  ('Khu Grab', 'Grab01', 1, 'square', 1, 1),
  ('Khu Grab', 'Grab02', 1, 'square', 2, 1),
  ('Khu Grab', 'Grab03', 1, 'square', 3, 1),
  ('Khu Grab', 'Grab04', 1, 'square', 4, 1),
  ('Khu Grab', 'Grab05', 1, 'square', 1, 2),
  -- Khu Catalog (take-away ảo)
  ('Khu Catalog', 'Catalog', 1, 'square', 1, 1)
) as t(zone_name, code, capacity, shape, pos_x, pos_y)
where z.name = t.zone_name
on conflict (branch_id, code) do nothing;

-- ----- Tables for B002 (same layout, codes prefixed P-) -----
with
  z as (
    select z.id, z.branch_id, z.name
    from public.zones z
    join public.branches b on b.id = z.branch_id and b.code = 'B002'
  )
insert into public.tables (branch_id, zone_id, code, capacity, shape, pos_x, pos_y, status, is_active)
select
  z.branch_id,
  z.id,
  t.code, t.capacity, t.shape, t.pos_x, t.pos_y, 'available', true
from z, (values
  -- Khu A
  ('Khu A', 'PA01', 4, 'round',     1,  1),
  ('Khu A', 'PA02', 4, 'round',     2,  1),
  ('Khu A', 'PA03', 6, 'round',     3,  1),
  ('Khu A', 'PA04', 6, 'round',     4,  1),
  ('Khu A', 'PA05', 4, 'round',     1,  2),
  ('Khu A', 'PA06', 4, 'round',     2,  2),
  ('Khu A', 'PA07', 4, 'round',     3,  2),
  ('Khu A', 'PA08', 8, 'rectangle', 4,  2),
  ('Khu A', 'PA09', 4, 'round',     1,  3),
  -- Khu B
  ('Khu B', 'PB01', 10, 'round',    1,  1),
  ('Khu B', 'PB02', 8,  'round',    2,  1),
  ('Khu B', 'PB03', 10, 'round',    3,  1),
  -- Khu C
  ('Khu C', 'PC01', 2, 'square', 1, 1),
  ('Khu C', 'PC02', 2, 'square', 2, 1),
  ('Khu C', 'PC03', 4, 'square', 3, 1),
  ('Khu C', 'PC04', 4, 'square', 4, 1),
  ('Khu C', 'PC05', 2, 'square', 1, 2),
  ('Khu C', 'PC06', 4, 'square', 2, 2),
  ('Khu C', 'PC07', 2, 'square', 3, 2),
  ('Khu C', 'PC08', 4, 'square', 4, 2),
  -- Khu R
  ('Khu R', 'PR01', 6,  'round',     1, 1),
  ('Khu R', 'PR02', 6,  'round',     2, 1),
  ('Khu R', 'PR03', 6,  'round',     3, 1),
  ('Khu R', 'PR04', 6,  'round',     4, 1),
  ('Khu R', 'PR05', 8,  'round',     1, 2),
  ('Khu R', 'PR06', 6,  'round',     2, 2),
  ('Khu R', 'PR07', 6,  'round',     3, 2),
  ('Khu R', 'PR08', 12, 'rectangle', 4, 2),
  -- Khu T
  ('Khu T', 'PT01', 4, 'square', 1, 1),
  ('Khu T', 'PT02', 4, 'square', 2, 1),
  ('Khu T', 'PT03', 4, 'square', 3, 1),
  ('Khu T', 'PT04', 4, 'square', 4, 1),
  ('Khu T', 'PT05', 4, 'square', 1, 2),
  ('Khu T', 'PT06', 4, 'square', 2, 2),
  ('Khu T', 'PT07', 4, 'square', 3, 2),
  ('Khu T', 'PT08', 4, 'square', 4, 2),
  -- Delivery zones for B002
  ('Khu Capichi', 'PCP01', 1, 'square', 1, 1),
  ('Khu Capichi', 'PCP02', 1, 'square', 2, 1),
  ('Khu Capichi', 'PCP03', 1, 'square', 3, 1),
  ('Khu Capichi', 'PCP04', 1, 'square', 4, 1),
  ('Khu Capichi', 'PCP05', 1, 'square', 1, 2),
  ('Khu Shopee', 'PSh01', 1, 'square', 1, 1),
  ('Khu Shopee', 'PSh02', 1, 'square', 2, 1),
  ('Khu Shopee', 'PSh03', 1, 'square', 3, 1),
  ('Khu Shopee', 'PSh04', 1, 'square', 4, 1),
  ('Khu Shopee', 'PSh05', 1, 'square', 1, 2),
  ('Khu BE', 'PBE01', 1, 'square', 1, 1),
  ('Khu BE', 'PBE02', 1, 'square', 2, 1),
  ('Khu BE', 'PBE03', 1, 'square', 3, 1),
  ('Khu BE', 'PBE04', 1, 'square', 4, 1),
  ('Khu BE', 'PBE05', 1, 'square', 1, 2),
  ('Khu Grab', 'PGr01', 1, 'square', 1, 1),
  ('Khu Grab', 'PGr02', 1, 'square', 2, 1),
  ('Khu Grab', 'PGr03', 1, 'square', 3, 1),
  ('Khu Grab', 'PGr04', 1, 'square', 4, 1),
  ('Khu Grab', 'PGr05', 1, 'square', 1, 2),
  ('Khu Catalog', 'PCatalog', 1, 'square', 1, 1)
) as t(zone_name, code, capacity, shape, pos_x, pos_y)
where z.name = t.zone_name
on conflict (branch_id, code) do nothing;