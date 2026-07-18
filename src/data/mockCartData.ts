/**
 * Mock data tĩnh để test UI cart mà không cần kết nối Supabase.
 *
 * Tất cả menuItemId đều là UUID hợp lệ (đã qua isValidUUID).
 * Covers các loại: thịt (meat station), salad (salad station),
 * đồ uống/nước (hot station), hải sản, và item giá 0 (trong gói).
 */
import type { CartItem, CustomerSession } from '@/types/customer'

export const mockCartItems: CartItem[] = [
  {
    menuItemId: 'a1b2c3d4-e5f6-4789-abcd-ef1234567890',
    name: 'Wagyu Thăn Ngoại (A5)',
    unit: 'Phần',
    price: 680000,
    price_display: '680K',
    quantity: 2,
    note: 'Chín medium, không hành',
  },
  {
    menuItemId: 'b2c3d4e5-f6a7-4890-bcde-f12345678901',
    name: 'Sườn Bò Nướng Muối Ớt',
    unit: 'Phần',
    price: 220000,
    price_display: '220K',
    quantity: 1,
    note: '',
  },
  {
    menuItemId: 'c3d4e5f6-a7b8-4901-cdef-123456789012',
    name: 'Gà Nướng Mật Ong',
    unit: 'Phần',
    price: 150000,
    price_display: '150K',
    quantity: 3,
    note: 'Cắt nhỏ cho dễ ăn',
  },
  {
    menuItemId: 'd4e5f6a7-b8c9-4012-def0-234567890123',
    name: 'Tôm Hấp Hành Gừng',
    unit: 'Phần',
    price: 320000,
    price_display: '320K',
    quantity: 1,
    note: '',
  },
  {
    menuItemId: 'e5f6a7b8-c9d0-4123-ef01-345678901234',
    name: 'Salad Rau Câu Biển',
    unit: 'Phần',
    price: 85000,
    price_display: '85K',
    quantity: 2,
    note: 'Ít dấm, thêm hành',
  },
  {
    menuItemId: 'f6a7b8c9-d0e1-4234-f012-456789012345',
    name: 'Mì Udon Nước Dashi',
    unit: 'Tô',
    price: 120000,
    price_display: '120K',
    quantity: 1,
    note: 'Nước nhiều',
  },
  {
    menuItemId: 'a7b8c9d0-e1f2-4345-8123-567890123456',
    name: 'Coca Cola (Lon)',
    unit: 'Lon',
    price: 35000,
    price_display: '35K',
    quantity: 4,
    note: '',
  },
  {
    menuItemId: 'b8c9d0e1-f2a3-4456-9234-678901234567',
    name: 'Bia Sapporo',
    unit: 'Chai',
    price: 65000,
    price_display: '65K',
    quantity: 2,
    note: '',
  },
  {
    menuItemId: 'c9d0e1f2-a3b4-4567-a345-789012345678',
    name: 'Kem Trà Xanh (Trong gói)',
    unit: 'Ly',
    price: 0,
    price_display: '0K (Trong gói)',
    quantity: 2,
    note: '',
  },
  {
    menuItemId: 'd0e1f2a3-b4c5-4678-b456-890123456789',
    name: 'Lẩu Bò Tương Miso',
    unit: 'Lẩu',
    price: 450000,
    price_display: '450K',
    quantity: 1,
    note: 'Nước lẩu nhạt hơn bình thường',
  },
]

export const mockSession: CustomerSession = {
  id: 'sess-mock-00000000-0000-4000-8000-000000000000',
  tableId: '00000000-0000-4000-8000-000000000001',
  tableNumber: 'A05',
  areaId: '00000000-0000-4000-8000-000000000002',
  areaName: 'Khu VIP 1',
  staffId: 'staff-uuid-001',
  startedAt: new Date(),
  status: 'active',
}
