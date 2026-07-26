// Types
export type ReservationStatus = 'Pending' | 'Arrived' | 'Dining' | 'Completed' | 'Cancelled';
export type TableStatus = 'available' | 'reserved' | 'occupied';
export type MenuCategory = 'Buffet' | 'Set Lunch' | 'Thức ăn' | 'Thức uống' | 'Khác';
export type OrderStatus = 'Pending' | 'Preparing' | 'Served' | 'Paid';

export interface Branch {
  id: string;
  name: string;
  address: string;
  phone: string;
}

export interface Zone {
  id: string;
  branchId: string;
  name: string;
  color: string;
}

export interface Table {
  id: string;
  zoneId: string;
  code: string;
  capacity: number;
  status: TableStatus;
  shape?: 'round' | 'square' | 'rectangle';
  posX: number;
  posY: number;
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  totalVisits: number;
  totalSpent: number;
  note?: string;
}

export interface Reservation {
  id: string;
  branchId: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  date: string;
  time: string;
  guests: number;
  status: ReservationStatus;
  tables: string[];
  note?: string;
  source?: string;
  type?: string;
  createdAt: string;
}

export interface MenuItem {
  id: string;
  name: string;
  category: MenuCategory;
  price: number;
  unit: string;
  description?: string;
}

export interface OrderItem {
  menuItemId: string;
  name: string;
  price: number;
  quantity: number;
}

export interface Order {
  id: string;
  reservationId: string;
  items: OrderItem[];
  subtotal: number;
  vat: number;
  total: number;
  status: OrderStatus;
  createdAt: string;
}

// Branches
export const branches: Branch[] = [
  { id: 'B001', name: 'Ngưu Cát Quận 1', address: '123 Nguyễn Huệ, Quận 1, TP.HCM', phone: '02838223344' },
  { id: 'B002', name: 'Ngưu Cát Quận 7', address: '456 Nguyễn Văn Linh, Quận 7, TP.HCM', phone: '02854127788' },
];

// Zones
export const zones: Zone[] = [
  { id: 'Z001', branchId: 'B001', name: 'Khu vực A', color: '#3B82F6' },
  { id: 'Z002', branchId: 'B001', name: 'Khu vực B', color: '#10B981' },
  { id: 'Z003', branchId: 'B001', name: 'Khu VIP', color: '#F59E0B' },
  { id: 'Z004', branchId: 'B001', name: 'Sân vườn', color: '#8B5CF6' },
];

// Tables
export const tables: Table[] = [
  { id: 'T01', zoneId: 'Z001', code: 'A01', capacity: 2, status: 'available', posX: 0, posY: 0 },
  { id: 'T02', zoneId: 'Z001', code: 'A02', capacity: 4, status: 'occupied', posX: 1, posY: 0 },
  { id: 'T03', zoneId: 'Z001', code: 'A03', capacity: 4, status: 'available', posX: 2, posY: 0 },
  { id: 'T04', zoneId: 'Z001', code: 'A04', capacity: 6, status: 'reserved', posX: 0, posY: 1 },
  { id: 'T05', zoneId: 'Z001', code: 'A05', capacity: 4, status: 'available', posX: 1, posY: 1 },
  { id: 'T06', zoneId: 'Z001', code: 'A06', status: 'occupied', capacity: 4, posX: 2, posY: 1 },
  { id: 'T07', zoneId: 'Z002', code: 'B01', capacity: 4, status: 'available', posX: 0, posY: 2 },
  { id: 'T08', zoneId: 'Z002', code: 'B02', capacity: 6, status: 'available', posX: 1, posY: 2 },
  { id: 'T09', zoneId: 'Z002', code: 'B03', capacity: 4, status: 'reserved', posX: 2, posY: 2 },
  { id: 'T10', zoneId: 'Z002', code: 'B04', capacity: 8, status: 'available', posX: 0, posY: 3 },
  { id: 'T11', zoneId: 'Z003', code: 'VIP01', capacity: 10, status: 'available', posX: 0, posY: 4 },
  { id: 'T12', zoneId: 'Z003', code: 'VIP02', capacity: 12, status: 'occupied', posX: 1, posY: 4 },
  { id: 'T13', zoneId: 'Z004', code: 'SV01', capacity: 4, status: 'available', posX: 0, posY: 5 },
  { id: 'T14', zoneId: 'Z004', code: 'SV02', capacity: 6, status: 'available', posX: 1, posY: 5 },
  { id: 'T15', zoneId: 'Z004', code: 'SV03', capacity: 8, status: 'reserved', posX: 2, posY: 5 },
  { id: 'T16', zoneId: 'Z004', code: 'SV04', capacity: 4, status: 'available', posX: 3, posY: 5 },
];

// Customers
export const customers: Customer[] = [
  { id: 'C001', name: 'Ms.Duyên', phone: '0788883399', email: 'duyen@example.com', totalVisits: 12, totalSpent: 18500000, note: 'Khách VIP, thích bàn gần cửa sổ' },
  { id: 'C002', name: 'Ms.Huyền Lê', phone: '0978972707', email: 'huyenle@example.com', totalVisits: 8, totalSpent: 9200000 },
  { id: 'C003', name: 'Hưng', phone: '0964485085', totalVisits: 3, totalSpent: 2450000 },
  { id: 'C004', name: 'Mr Quí', phone: '0844444312', totalVisits: 1, totalSpent: 560000 },
  { id: 'C005', name: 'Mr. Ueno', phone: '0909123456', email: 'ueno@example.com', totalVisits: 25, totalSpent: 45000000, note: 'Khách Nhật, thường đặt tiệc công ty' },
  { id: 'C006', name: 'Ms. Trang', phone: '0918222333', totalVisits: 6, totalSpent: 7800000 },
  { id: 'C007', name: 'Mr. Minh', phone: '0933111444', email: 'minh@example.com', totalVisits: 15, totalSpent: 22000000 },
  { id: 'C008', name: 'Ms. Thảo', phone: '0977555666', totalVisits: 2, totalSpent: 1800000 },
  { id: 'C009', name: 'Mr. Phong', phone: '0905777888', totalVisits: 10, totalSpent: 13500000 },
  { id: 'C010', name: 'Ms. Linh', phone: '0936999000', totalVisits: 5, totalSpent: 6200000 },
];

// Reservations
export const reservations: Reservation[] = [
  { id: 'SF_00001729', branchId: 'B001', customerId: 'C001', customerName: 'Ms.Duyên', customerPhone: '0788883399', date: '2026-06-18', time: '11:30', guests: 4, status: 'Arrived', tables: ['A02'], note: 'Kỷ niệm ngày cưới', source: 'Hotline', type: 'Tiệc đôi', createdAt: '2026-06-17T14:00:00Z' },
  { id: 'SF_00001741', branchId: 'B001', customerId: 'C002', customerName: 'Ms.Huyền Lê', customerPhone: '0978972707', date: '2026-06-18', time: '11:30', guests: 3, status: 'Arrived', tables: ['A06'], source: 'App', type: 'Hội nghị', createdAt: '2026-06-17T10:30:00Z' },
  { id: 'SF_00001775', branchId: 'B001', customerId: 'C003', customerName: 'Hưng', customerPhone: '0964485085', date: '2026-06-18', time: '11:30', guests: 6, status: 'Pending', tables: ['B03'], note: 'Có trẻ em, cần ghế cao', source: 'Facebook', type: 'Gia đình', createdAt: '2026-06-17T16:45:00Z' },
  { id: 'SF_00001782', branchId: 'B001', customerId: 'C004', customerName: 'Mr Quí', customerPhone: '0844444312', date: '2026-06-18', time: '11:30', guests: 2, status: 'Cancelled', tables: [], source: 'Hotline', type: 'Tiệc đôi', createdAt: '2026-06-16T09:00:00Z' },
  { id: 'SF_00001801', branchId: 'B001', customerId: 'C005', customerName: 'Mr. Ueno', customerPhone: '0909123456', date: '2026-06-18', time: '12:00', guests: 8, status: 'Pending', tables: ['VIP01'], note: 'Tiệc công ty Nhật, cần bàn riêng', source: 'Email', type: 'Hội nghị', createdAt: '2026-06-15T11:00:00Z' },
  { id: 'SF_00001802', branchId: 'B001', customerId: 'C006', customerName: 'Ms. Trang', customerPhone: '0918222333', date: '2026-06-18', time: '18:00', guests: 5, status: 'Pending', tables: ['B01'], source: 'App', type: 'Gia đình', createdAt: '2026-06-16T20:00:00Z' },
  { id: 'SF_00001803', branchId: 'B001', customerId: 'C007', customerName: 'Mr. Minh', customerPhone: '0933111444', date: '2026-06-18', time: '18:30', guests: 6, status: 'Dining', tables: ['VIP02'], note: 'Sinh nhật, cần trang trí', source: 'Hotline', type: 'Tiệc đôi', createdAt: '2026-06-14T15:30:00Z' },
  { id: 'SF_00001804', branchId: 'B001', customerId: 'C008', customerName: 'Ms. Thảo', customerPhone: '0977555666', date: '2026-06-18', time: '19:00', guests: 2, status: 'Pending', tables: ['SV03'], source: 'Walk-in', type: 'Tiệc đôi', createdAt: '2026-06-18T10:00:00Z' },
  { id: 'SF_00001805', branchId: 'B001', customerId: 'C009', customerName: 'Mr. Phong', customerPhone: '0905777888', date: '2026-06-18', time: '18:00', guests: 4, status: 'Completed', tables: ['A04'], note: 'Đã thanh toán', source: 'Facebook', type: 'Gia đình', createdAt: '2026-06-15T08:00:00Z' },
  { id: 'SF_00001806', branchId: 'B001', customerId: 'C010', customerName: 'Ms. Linh', customerPhone: '0936999000', date: '2026-06-18', time: '12:30', guests: 3, status: 'Arrived', tables: ['A01'], source: 'App', type: 'Tiệc đôi', createdAt: '2026-06-17T12:00:00Z' },
  { id: 'SF_00001807', branchId: 'B001', customerId: 'C003', customerName: 'Hưng', customerPhone: '0964485085', date: '2026-06-18', time: '18:00', guests: 4, status: 'Cancelled', tables: [], source: 'Zalo', type: 'Gia đình', createdAt: '2026-06-17T18:00:00Z' },
  { id: 'SF_00001808', branchId: 'B001', customerId: 'C001', customerName: 'Ms.Duyên', customerPhone: '0788883399', date: '2026-06-19', time: '11:30', guests: 4, status: 'Pending', tables: ['A05'], note: 'Khách quen, ưu tiên bàn đẹp', source: 'Hotline', type: 'Tiệc đôi', createdAt: '2026-06-18T08:00:00Z' },
  { id: 'SF_00001809', branchId: 'B001', customerId: 'C007', customerName: 'Mr. Minh', customerPhone: '0933111444', date: '2026-06-19', time: '18:00', guests: 10, status: 'Pending', tables: ['VIP02'], source: 'Hotline', type: 'Hội nghị', createdAt: '2026-06-16T10:00:00Z' },
  { id: 'SF_00001810', branchId: 'B001', customerId: 'C005', customerName: 'Mr. Ueno', customerPhone: '0909123456', date: '2026-06-20', time: '12:00', guests: 15, status: 'Pending', tables: ['VIP01', 'VIP02'], note: 'Tiệc công ty cuối tuần', source: 'Email', type: 'Hội nghị', createdAt: '2026-06-14T09:00:00Z' },
];

// Menu Items
export const menuItems: MenuItem[] = [
  { id: 'M001', name: 'Buffet Nước Gói 250 (JP)', category: 'Buffet', price: 227273, unit: 'Vé', description: 'Buffet nước lẩu Nhật cao cấp' },
  { id: 'M002', name: 'Buffet Nước Gói 80', category: 'Buffet', price: 80000, unit: 'Vé', description: 'Buffet nước lẩu cơ bản' },
  { id: 'M003', name: 'Rượu vang cao cấp', category: 'Thức uống', price: 350000, unit: 'Chai', description: 'Rượu vang nhập khẩu Pháp' },
  { id: 'M004', name: 'Set Lẩu 250', category: 'Set Lunch', price: 250000, unit: 'Vé', description: 'Set lẩu cho 1 người' },
  { id: 'M005', name: 'Set Lẩu 550 (JP)', category: 'Set Lunch', price: 509259, unit: 'Vé', description: 'Set lẩu Nhật cao cấp' },
  { id: 'M006', name: 'Thịt bò nướng', category: 'Thức ăn', price: 150000, unit: 'Đĩa', description: 'Thịt bò Mỹ nướng BBQ' },
  { id: 'M007', name: 'Bia tươi', category: 'Thức uống', price: 35000, unit: 'Lon', description: 'Bia tươi nhập khẩu Đức' },
  { id: 'M008', name: 'Coca Cola', category: 'Thức uống', price: 15000, unit: 'Lon' },
  { id: 'M009', name: 'Nước suối', category: 'Thức uống', price: 10000, unit: 'Chai' },
  { id: 'M010', name: 'Salad khai vị', category: 'Thức ăn', price: 45000, unit: 'Đĩa' },
  { id: 'M011', name: 'Sashimi cá hồi', category: 'Thức ăn', price: 180000, unit: 'Đĩa', description: 'Cá hồi tươi nhập khẩu Nhật' },
  { id: 'M012', name: 'Tempura tôm', category: 'Thức ăn', price: 95000, unit: 'Đĩa' },
  { id: 'M013', name: 'Cơm cuộn California', category: 'Khác', price: 75000, unit: 'Phần' },
  { id: 'M014', name: 'Trà đá', category: 'Thức uống', price: 8000, unit: 'Ly' },
  { id: 'M015', name: 'Kem matcha', category: 'Khác', price: 35000, unit: 'Cây' },
];

// Orders
export const orders: Order[] = [
  {
    id: 'O001', reservationId: 'SF_00001729',
    items: [
      { menuItemId: 'M001', name: 'Buffet Nước Gói 250 (JP)', price: 227273, quantity: 2 },
      { menuItemId: 'M011', name: 'Sashimi cá hồi', price: 180000, quantity: 1 },
      { menuItemId: 'M007', name: 'Bia tươi', price: 35000, quantity: 3 },
    ],
    subtotal: 669546, vat: 66955, total: 736501, status: 'Served', createdAt: '2026-06-18T11:45:00Z',
  },
  {
    id: 'O002', reservationId: 'SF_00001803',
    items: [
      { menuItemId: 'M005', name: 'Set Lẩu 550 (JP)', price: 509259, quantity: 6 },
      { menuItemId: 'M007', name: 'Bia tươi', price: 35000, quantity: 8 },
      { menuItemId: 'M012', name: 'Tempura tôm', price: 95000, quantity: 2 },
    ],
    subtotal: 3515554, vat: 351555, total: 3867109, status: 'Preparing', createdAt: '2026-06-18T18:30:00Z',
  },
  {
    id: 'O003', reservationId: 'SF_00001805',
    items: [
      { menuItemId: 'M002', name: 'Buffet Nước Gói 80', price: 80000, quantity: 4 },
      { menuItemId: 'M008', name: 'Coca Cola', price: 15000, quantity: 4 },
      { menuItemId: 'M015', name: 'Kem matcha', price: 35000, quantity: 4 },
    ],
    subtotal: 520000, vat: 52000, total: 572000, status: 'Paid', createdAt: '2026-06-18T18:15:00Z',
  },
];
