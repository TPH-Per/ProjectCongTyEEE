// File: src/data/customerAreaData.ts
//
// Mock area & table data for the customer self-service flow when
// Supabase is not configured. Provides 10 areas (A, B, C, R, T,
// Capichi, Shopee, BE, Grab, Catalog) with 57 tables total.
//
// The structure follows the existing `Area` and `Table` interfaces
// from `@/types/customer` so the customer API mock fallback can
// return these directly without any mapping layer.

import type { Area } from '@/types/customer';

export const customerAreas: Area[] = [
  {
    id: 'area_a',
    code: 'A',
    name: 'Khu A',
    name_en: 'Area A',
    tables: [
      { id: 'A01', number: 'A01', areaId: 'area_a', status: 'available', capacity: 4 },
      { id: 'A02', number: 'A02', areaId: 'area_a', status: 'available', capacity: 4 },
      { id: 'A03', number: 'A03', areaId: 'area_a', status: 'occupied', capacity: 6 },
      { id: 'A04', number: 'A04', areaId: 'area_a', status: 'available', capacity: 4 },
      { id: 'A05', number: 'A05', areaId: 'area_a', status: 'available', capacity: 8 },
      { id: 'A06', number: 'A06', areaId: 'area_a', status: 'available', capacity: 4 },
      { id: 'A07', number: 'A07', areaId: 'area_a', status: 'available', capacity: 4 },
      { id: 'A08', number: 'A08', areaId: 'area_a', status: 'available', capacity: 6 },
      { id: 'A09', number: 'A09', areaId: 'area_a', status: 'available', capacity: 4 },
    ],
  },
  {
    id: 'area_b',
    code: 'B',
    name: 'Khu B',
    name_en: 'Area B',
    tables: [
      { id: 'B01', number: 'B01', areaId: 'area_b', status: 'available', capacity: 2 },
      { id: 'B02', number: 'B02', areaId: 'area_b', status: 'available', capacity: 4 },
      { id: 'B03', number: 'B03', areaId: 'area_b', status: 'available', capacity: 6 },
    ],
  },
  {
    id: 'area_c',
    code: 'C',
    name: 'Khu C',
    name_en: 'Area C',
    tables: [
      { id: 'C01', number: 'C01', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C02', number: 'C02', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C03', number: 'C03', areaId: 'area_c', status: 'available', capacity: 6 },
      { id: 'C04', number: 'C04', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C05', number: 'C05', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C06', number: 'C06', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C07', number: 'C07', areaId: 'area_c', status: 'available', capacity: 4 },
      { id: 'C08', number: 'C08', areaId: 'area_c', status: 'available', capacity: 6 },
    ],
  },
  {
    id: 'area_r',
    code: 'R',
    name: 'Khu R',
    name_en: 'Area R',
    tables: [
      { id: 'R01', number: 'R01', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R02', number: 'R02', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R03', number: 'R03', areaId: 'area_r', status: 'available', capacity: 6 },
      { id: 'R04', number: 'R04', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R05', number: 'R05', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R06', number: 'R06', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R07', number: 'R07', areaId: 'area_r', status: 'available', capacity: 4 },
      { id: 'R08', number: 'R08', areaId: 'area_r', status: 'available', capacity: 6 },
    ],
  },
  {
    id: 'area_t',
    code: 'T',
    name: 'Khu T',
    name_en: 'Area T',
    tables: [
      { id: 'T01', number: 'T01', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T02', number: 'T02', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T03', number: 'T03', areaId: 'area_t', status: 'available', capacity: 6 },
      { id: 'T04', number: 'T04', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T05', number: 'T05', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T06', number: 'T06', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T07', number: 'T07', areaId: 'area_t', status: 'available', capacity: 4 },
      { id: 'T08', number: 'T08', areaId: 'area_t', status: 'available', capacity: 6 },
    ],
  },
  {
    id: 'area_capichi',
    code: 'CAPICHI',
    name: 'Khu Capichi',
    name_en: 'Capichi Area',
    tables: [
      { id: 'CP01', number: 'CP01', areaId: 'area_capichi', status: 'available', capacity: 1 },
      { id: 'CP02', number: 'CP02', areaId: 'area_capichi', status: 'occupied', capacity: 1 },
      { id: 'CP03', number: 'CP03', areaId: 'area_capichi', status: 'available', capacity: 1 },
      { id: 'CP04', number: 'CP04', areaId: 'area_capichi', status: 'available', capacity: 1 },
      { id: 'CP05', number: 'CP05', areaId: 'area_capichi', status: 'available', capacity: 1 },
    ],
  },
  {
    id: 'area_shopee',
    code: 'SHOPEE',
    name: 'Khu Shopee',
    name_en: 'Shopee Area',
    tables: [
      { id: 'Shopee01', number: 'Shopee01', areaId: 'area_shopee', status: 'available', capacity: 1 },
      { id: 'Shopee02', number: 'Shopee02', areaId: 'area_shopee', status: 'available', capacity: 1 },
      { id: 'Shopee03', number: 'Shopee03', areaId: 'area_shopee', status: 'available', capacity: 1 },
      { id: 'Shopee04', number: 'Shopee04', areaId: 'area_shopee', status: 'available', capacity: 1 },
      { id: 'Shopee05', number: 'Shopee05', areaId: 'area_shopee', status: 'available', capacity: 1 },
    ],
  },
  {
    id: 'area_be',
    code: 'BE',
    name: 'Khu BE',
    name_en: 'BE Area',
    tables: [
      { id: 'BE01', number: 'BE01', areaId: 'area_be', status: 'available', capacity: 1 },
      { id: 'BE02', number: 'BE02', areaId: 'area_be', status: 'available', capacity: 1 },
      { id: 'BE03', number: 'BE03', areaId: 'area_be', status: 'available', capacity: 1 },
      { id: 'BE04', number: 'BE04', areaId: 'area_be', status: 'available', capacity: 1 },
      { id: 'BE05', number: 'BE05', areaId: 'area_be', status: 'available', capacity: 1 },
    ],
  },
  {
    id: 'area_grab',
    code: 'GRAB',
    name: 'Khu Grab',
    name_en: 'Grab Area',
    tables: [
      { id: 'Grab01', number: 'Grab01', areaId: 'area_grab', status: 'available', capacity: 1 },
      { id: 'Grab02', number: 'Grab02', areaId: 'area_grab', status: 'available', capacity: 1 },
      { id: 'Grab03', number: 'Grab03', areaId: 'area_grab', status: 'available', capacity: 1 },
      { id: 'Grab04', number: 'Grab04', areaId: 'area_grab', status: 'available', capacity: 1 },
      { id: 'Grab05', number: 'Grab05', areaId: 'area_grab', status: 'available', capacity: 1 },
    ],
  },
  {
    id: 'area_catalog',
    code: 'CATALOG',
    name: 'Khu Catalog',
    name_en: 'Catalog Area',
    tables: [
      { id: 'Catalog', number: 'Catalog', areaId: 'area_catalog', status: 'available', capacity: 1 },
    ],
  },
];

export default customerAreas;
