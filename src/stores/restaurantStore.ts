// File: src/stores/restaurantStore.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { MenuItem } from '@/data/menuData';

export interface TableInfo {
  code: string;
  status: 'Available' | 'Reserved' | 'Arrived' | 'Serving';
  capacity: number;
  customerName?: string;
  billAmount?: string;
  occupiedDuration?: string;
  checkInTime?: string;
}

export interface AreaInfo {
  name: string;
  description: string;
  tables: TableInfo[];
}

export interface Booking {
  id: string;
  bookingNumber: string;
  customerName: string;
  phone: string;
  adults: number;
  children: number;
  reservationTime: string;
  assignedTable: string;
  notes: string;
  status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled';
  date: string;
}

export interface CartItem {
  id: string;
  name: string;
  unit: string;
  price: number;
  price_display: string;
  quantity: number;
  category_id: string;
}

export interface TableOrder {
  orderNumber: string;
  tableCode: string;
  customerName: string;
  guestCount: number;
  openedTime: string;
  items: CartItem[];
}

export const useRestaurantStore = defineStore('restaurant', () => {
  // NOTE: This is OFFLINE / DEV fallback data. In production the cashier
  // views (ReceptionOrderView, AdminFloorsView, ReceptionDashboardView)
  // all source their tables from `hall_list_tables` RPC and the realtime
  // channel. The structure here is kept ONLY so the dashboard UI does not
  // crash during a cold dev run with no Supabase project; billAmount /
  // occupiedDuration / checkInTime are intentionally NOT pre-filled so
  // no fake numbers leak into the cashier's view.
  const areas = ref<AreaInfo[]>([
    {
      name: 'Khu A',
      description: 'Khu chính trong nhà',
      tables: [
        { code: 'A01', status: 'Available', capacity: 4 },
        { code: 'A02', status: 'Reserved', capacity: 4, customerName: 'Nguyễn Văn A' },
        { code: 'A03', status: 'Serving', capacity: 2, customerName: 'Phạm Hùng' },
        { code: 'A04', status: 'Arrived', capacity: 6, customerName: 'Lê Thảo' },
        { code: 'A05', status: 'Available', capacity: 4 },
        { code: 'A06', status: 'Available', capacity: 4 },
        { code: 'A07', status: 'Reserved', capacity: 4, customerName: 'Trần Bình' },
        { code: 'A08', status: 'Serving', capacity: 8, customerName: 'Lê Văn C' },
        { code: 'A09', status: 'Available', capacity: 4 },
      ]
    },
    {
      name: 'Khu B',
      description: 'Khu VIP trong nhà',
      tables: [
        { code: 'B01', status: 'Available', capacity: 10 },
        { code: 'B02', status: 'Reserved', capacity: 8, customerName: 'Bùi Lan' },
        { code: 'B03', status: 'Serving', capacity: 10, customerName: 'Công ty ABC' },
      ]
    },
    {
      name: 'Khu C',
      description: 'Ban công ngoài trời',
      tables: [
        { code: 'C01', status: 'Available', capacity: 2 },
        { code: 'C02', status: 'Available', capacity: 2 },
        { code: 'C03', status: 'Arrived', capacity: 4, customerName: 'Trần Thị B' },
        { code: 'C04', status: 'Available', capacity: 4 },
        { code: 'C05', status: 'Reserved', capacity: 2, customerName: 'Hoàng Long' },
        { code: 'C06', status: 'Serving', capacity: 4, customerName: 'Đức Huy' },
        { code: 'C07', status: 'Available', capacity: 2 },
        { code: 'C08', status: 'Available', capacity: 4 },
      ]
    },
    {
      name: 'Khu R',
      description: 'Phòng riêng đặc biệt',
      tables: [
        { code: 'R01', status: 'Available', capacity: 6 },
        { code: 'R02', status: 'Reserved', capacity: 6, customerName: 'Vũ Nam' },
        { code: 'R03', status: 'Serving', capacity: 6, customerName: 'Gia đình chị Vy' },
        { code: 'R04', status: 'Available', capacity: 6 },
        { code: 'R05', status: 'Reserved', capacity: 8, customerName: 'Phạm Minh Hoàng' },
        { code: 'R06', status: 'Available', capacity: 6 },
        { code: 'R07', status: 'Reserved', capacity: 6, customerName: 'Trần Hào' },
        { code: 'R08', status: 'Serving', capacity: 12, customerName: 'Sinh nhật Minh' },
      ]
    },
    {
      name: 'Khu T',
      description: 'Sân thượng ngắm cảnh',
      tables: [
        { code: 'T01', status: 'Available', capacity: 4 },
        { code: 'T02', status: 'Reserved', capacity: 4, customerName: 'Đặng Thu Thảo' },
        { code: 'T03', status: 'Reserved', capacity: 4 },
        { code: 'T04', status: 'Serving', capacity: 4, customerName: 'Anh Trung' },
        { code: 'T05', status: 'Arrived', capacity: 4, customerName: 'Khánh Hà' },
        { code: 'T06', status: 'Available', capacity: 4 },
        { code: 'T07', status: 'Available', capacity: 4 },
        { code: 'T08', status: 'Reserved', capacity: 4 },
      ]
    },
    {
      name: 'Khu Capichi',
      description: 'Trực tuyến Capichi',
      tables: [
        { code: 'CP01', status: 'Available', capacity: 1 },
        { code: 'CP02', status: 'Serving', capacity: 1, customerName: 'Capichi Order #1' },
        { code: 'CP03', status: 'Available', capacity: 1 },
        { code: 'CP04', status: 'Reserved', capacity: 1, customerName: 'Capichi Order #2' },
        { code: 'CP05', status: 'Arrived', capacity: 1, customerName: 'Capichi Order #3' },
      ]
    },
    {
      name: 'Khu Shopee',
      description: 'ShopeeFood Orders',
      tables: [
        { code: 'Shopee01', status: 'Available', capacity: 1 },
        { code: 'Shopee02', status: 'Available', capacity: 1 },
        { code: 'Shopee03', status: 'Serving', capacity: 1, customerName: 'Shopee #452' },
        { code: 'Shopee04', status: 'Reserved', capacity: 1, customerName: 'Shopee #460' },
        { code: 'Shopee05', status: 'Arrived', capacity: 1, customerName: 'Shopee #461' },
      ]
    },
    {
      name: 'Khu BE',
      description: 'beFood Orders',
      tables: [
        { code: 'BE01', status: 'Available', capacity: 1 },
        { code: 'BE02', status: 'Reserved', capacity: 1, customerName: 'beFood #11' },
        { code: 'BE03', status: 'Serving', capacity: 1, customerName: 'beFood #12' },
        { code: 'BE04', status: 'Available', capacity: 1 },
        { code: 'BE05', status: 'Arrived', capacity: 1, customerName: 'beFood #14' },
      ]
    },
    {
      name: 'Khu Grab',
      description: 'GrabFood Orders',
      tables: [
        { code: 'Grab01', status: 'Available', capacity: 1 },
        { code: 'Grab02', status: 'Serving', capacity: 1, customerName: 'Grab #90' },
        { code: 'Grab03', status: 'Reserved', capacity: 1, customerName: 'Grab #91' },
        { code: 'Grab04', status: 'Available', capacity: 1 },
        { code: 'Grab05', status: 'Arrived', capacity: 1, customerName: 'Grab #95' },
      ]
    },
    {
      name: 'Khu Catalog',
      description: 'Đơn Take-away trực tiếp',
      tables: [
        { code: 'Catalog', status: 'Available', capacity: 1 },
      ]
    }
  ]);

  const bookings = ref<Booking[]>([
    {
      id: 'b1',
      bookingNumber: 'NC-20260624-001',
      customerName: 'Nguyễn Văn A',
      phone: '0901234567',
      adults: 4,
      children: 0,
      reservationTime: '18:30',
      assignedTable: 'A02',
      notes: 'Khách hàng thân thiết, cần bàn thoáng rộng rãi.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b2',
      bookingNumber: 'NC-20260624-002',
      customerName: 'Trần Thị B',
      phone: '0987654321',
      adults: 2,
      children: 1,
      reservationTime: '12:00',
      assignedTable: 'C03',
      notes: 'Đặt tiệc sinh nhật nhẹ cho bé gái.',
      status: 'Arrived',
      date: '2026-07-18'
    },
    {
      id: 'b3',
      bookingNumber: 'NC-20260624-003',
      customerName: 'Lê Văn C',
      phone: '0912345678',
      adults: 6,
      children: 2,
      reservationTime: '17:30',
      assignedTable: 'A08',
      notes: 'Khách gia đình dùng bữa tối.',
      status: 'Seated',
      date: '2026-07-18'
    },
    {
      id: 'b4',
      bookingNumber: 'NC-20260624-004',
      customerName: 'Phạm Minh Hoàng',
      phone: '0934567890',
      adults: 8,
      children: 0,
      reservationTime: '20:00',
      assignedTable: 'R05',
      notes: 'Đặt phòng VIP ăn tối gặp gỡ đối tác.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b5',
      bookingNumber: 'NC-20260624-005',
      customerName: 'Đặng Thu Thảo',
      phone: '0978123456',
      adults: 3,
      children: 1,
      reservationTime: '19:30',
      assignedTable: 'T02',
      notes: 'Khách ngắm cảnh sân thượng đẹp.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b6',
      bookingNumber: 'NC-20260625-001',
      customerName: 'Vũ Thị Minh',
      phone: '0943210987',
      adults: 2,
      children: 0,
      reservationTime: '11:30',
      assignedTable: 'C01',
      notes: 'Khách đặt ăn trưa nhẹ.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b7',
      bookingNumber: 'NC-20260625-002',
      customerName: 'Đỗ Hữu Nam',
      phone: '0956789012',
      adults: 5,
      children: 2,
      reservationTime: '18:00',
      assignedTable: 'R02',
      notes: 'Khách họp gia đình liên hoan.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b8',
      bookingNumber: 'NC-20260623-001',
      customerName: 'Nguyễn Tiến Đạt',
      phone: '0911223344',
      adults: 4,
      children: 1,
      reservationTime: '19:00',
      assignedTable: 'B02',
      notes: 'Lịch tiệc tối hôm qua.',
      status: 'Completed',
      date: '2026-07-18'
    },
    {
      id: 'b9',
      bookingNumber: 'NC-20260624-009',
      customerName: 'Anh Huy (Ăn sáng)',
      phone: '0911222333',
      adults: 3,
      children: 0,
      reservationTime: '08:45',
      assignedTable: 'A01',
      notes: 'Đặt bàn ăn sáng họp nhóm.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b10',
      bookingNumber: 'NC-20260624-010',
      customerName: 'Đoàn khách họp chiều 1',
      phone: '0933444555',
      adults: 4,
      children: 0,
      reservationTime: '14:30',
      assignedTable: 'A05',
      notes: 'Khách họp bàn công việc.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b11',
      bookingNumber: 'NC-20260624-011',
      customerName: 'Đoàn khách họp chiều 2',
      phone: '0955666777',
      adults: 6,
      children: 0,
      reservationTime: '14:45',
      assignedTable: 'A06',
      notes: 'Ăn nhẹ buổi chiều.',
      status: 'Waiting',
      date: '2026-07-18'
    },
    {
      id: 'b12',
      bookingNumber: 'NC-20260624-012',
      customerName: 'Đoàn khách họp chiều 3',
      phone: '0977888999',
      adults: 7,
      children: 0,
      reservationTime: '15:00',
      assignedTable: 'B01',
      notes: 'Họp trà chiều.',
      status: 'Waiting',
      date: '2026-07-18'
    }
  ]);

  // Selected Table Context for Ordering
  const selectedTableCode = ref<string | null>(null);

  // Table Orders Map (persistent carts for each table)
  const tableOrders = ref<Record<string, TableOrder>>({
    A03: {
      orderNumber: 'SF_00001003',
      tableCode: 'A03',
      customerName: 'Phạm Hùng',
      guestCount: 2,
      openedTime: '17:45 18/07/2026',
      items: [
        {
          id: 'bf-tiec-1',
          name: 'SET1-Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 450000,
          price_display: '450K',
          quantity: 1,
          category_id: 'set-tiec-cd'
        }
      ]
    },
    A08: {
      orderNumber: 'SF_00001008',
      tableCode: 'A08',
      customerName: 'Lê Văn C',
      guestCount: 4,
      openedTime: '16:55 18/07/2026',
      items: [
        {
          id: 'bf680-1',
          name: 'Vé Người Lớn 680',
          unit: 'Vé',
          price: 680000,
          price_display: '680K',
          quantity: 2,
          category_id: 'buffet'
        },
        {
          id: 'bf-tiec-1',
          name: 'SET1-Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 450000,
          price_display: '450K',
          quantity: 1,
          category_id: 'set-tiec-cd'
        },
        {
          id: 'lunch-40',
          name: 'Tôm Tempura - Lunch',
          unit: 'Phần',
          price: 40000,
          price_display: '40K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    B03: {
      orderNumber: 'SF_00002003',
      tableCode: 'B03',
      customerName: 'Công ty ABC',
      guestCount: 10,
      openedTime: '16:05 18/07/2026',
      items: [
        {
          id: 'bf1390-1',
          name: 'Vé Người Lớn 1380',
          unit: 'Vé',
          price: 1380000,
          price_display: '1.380K',
          quantity: 3,
          category_id: 'buffet'
        },
        {
          id: 'bf-drink-soft',
          name: 'Nước ngọt uống không giới hạn',
          unit: 'Vé',
          price: 80000,
          price_display: '80K',
          quantity: 1,
          category_id: 'buffet'
        }
      ]
    },
    C06: {
      orderNumber: 'SF_00003006',
      tableCode: 'C06',
      customerName: 'Đức Huy',
      guestCount: 4,
      openedTime: '17:25 18/07/2026',
      items: [
        {
          id: 'bf-tiec-3',
          name: 'SET3-Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 850000,
          price_display: '850K',
          quantity: 1,
          category_id: 'set-tiec-cd'
        },
        {
          id: 'lunch-40',
          name: 'Tôm Tempura - Lunch',
          unit: 'Phần',
          price: 40000,
          price_display: '40K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    R03: {
      orderNumber: 'SF_00004003',
      tableCode: 'R03',
      customerName: 'Gia đình chị Vy',
      guestCount: 6,
      openedTime: '17:05 18/07/2026',
      items: [
        {
          id: 'bf-tiec-1',
          name: 'SET1-Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 450000,
          price_display: '450K',
          quantity: 5,
          category_id: 'set-tiec-cd'
        },
        {
          id: 'bf-tiec-drink-1',
          name: 'SET1-Drink Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 250000,
          price_display: '250K',
          quantity: 1,
          category_id: 'set-tiec-cd'
        }
      ]
    },
    R08: {
      orderNumber: 'SF_00004008',
      tableCode: 'R08',
      customerName: 'Sinh nhật Minh',
      guestCount: 12,
      openedTime: '16:30 18/07/2026',
      items: [
        {
          id: 'bf1390-1',
          name: 'Vé Người Lớn 1380',
          unit: 'Vé',
          price: 1380000,
          price_display: '1.380K',
          quantity: 4,
          category_id: 'buffet'
        },
        {
          id: 'bf-drink-soft',
          name: 'Nước ngọt uống không giới hạn',
          unit: 'Vé',
          price: 80000,
          price_display: '80K',
          quantity: 1,
          category_id: 'buffet'
        }
      ]
    },
    T04: {
      orderNumber: 'SF_00005004',
      tableCode: 'T04',
      customerName: 'Anh Trung',
      guestCount: 4,
      openedTime: '17:30 18/07/2026',
      items: [
        {
          id: 'bf-tiec-2',
          name: 'SET2-Tiệc Chiêu Đãi',
          unit: 'Phần',
          price: 550000,
          price_display: '550K',
          quantity: 2,
          category_id: 'set-tiec-cd'
        },
        {
          id: 'lunch-7',
          name: 'Lunch - Sét Cơm Gà Cay Ngọt',
          unit: 'Phần',
          price: 109000,
          price_display: '109K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    CP02: {
      orderNumber: 'SF_00006002',
      tableCode: 'CP02',
      customerName: 'Capichi Order #1',
      guestCount: 1,
      openedTime: '17:50 18/07/2026',
      items: [
        {
          id: 'lunch-4',
          name: 'Lunch - Cơm thịt heo kim chi',
          unit: 'Phần',
          price: 129000,
          price_display: '129K',
          quantity: 1,
          category_id: 'set-lunch'
        },
        {
          id: 'lunch-45',
          name: 'Gà Chiên Nhật Bản - Lunch',
          unit: 'Phần',
          price: 35000,
          price_display: '35K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    Shopee03: {
      orderNumber: 'SF_00007003',
      tableCode: 'Shopee03',
      customerName: 'Shopee #452',
      guestCount: 1,
      openedTime: '17:53 18/07/2026',
      items: [
        {
          id: 'lunch-8',
          name: 'Lunch - Set Heo Tổng Hợp',
          unit: 'Phần',
          price: 169000,
          price_display: '169K',
          quantity: 1,
          category_id: 'set-lunch'
        },
        {
          id: 'lunch-16',
          name: 'Mì Udon Kim Chi - Lunch',
          unit: 'Phần',
          price: 149000,
          price_display: '149K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    BE03: {
      orderNumber: 'SF_00008003',
      tableCode: 'BE03',
      customerName: 'beFood #12',
      guestCount: 1,
      openedTime: '17:47 04/07/2026',
      items: [
        {
          id: 'lunch-4',
          name: 'Lunch - Cơm thịt heo kim chi',
          unit: 'Phần',
          price: 129000,
          price_display: '129K',
          quantity: 1,
          category_id: 'set-lunch'
        },
        {
          id: 'lunch-41',
          name: 'Cá Ngân chiên giòn',
          unit: 'Phần',
          price: 45000,
          price_display: '45K',
          quantity: 1,
          category_id: 'set-lunch'
        }
      ]
    },
    Grab02: {
      orderNumber: 'SF_00009002',
      tableCode: 'Grab02',
      customerName: 'Grab #90',
      guestCount: 1,
      openedTime: '17:42 04/07/2026',
      items: [
        {
          id: 'lunch-8',
          name: 'Lunch - Set Heo Tổng Hợp',
          unit: 'Phần',
          price: 169000,
          price_display: '169K',
          quantity: 1,
          category_id: 'set-lunch'
        },
        {
          id: 'lunch-45',
          name: 'Gà Chiên Nhật Bản - Lunch',
          unit: 'Phần',
          price: 35000,
          price_display: '35K',
          quantity: 2,
          category_id: 'set-lunch'
        }
      ]
    }
  });

  // Helper: Find table by code in areas
  const getTableByCode = (code: string): TableInfo | null => {
    for (const area of areas.value) {
      const found = area.tables.find(t => t.code === code);
      if (found) return found;
    }
    return null;
  };

  // Helper: Get area name of a table
  const getTableAreaName = (code: string): string => {
    for (const area of areas.value) {
      if (area.tables.some(t => t.code === code)) {
        return area.name;
      }
    }
    return 'Khu vực';
  };

  // Get active order for a table (or create an empty one)
  const getOrCreateOrder = (tableCode: string): TableOrder => {
    if (!tableOrders.value[tableCode]) {
      const table = getTableByCode(tableCode);
      const guestCount = table?.customerName ? 4 : 2; // Default mock guests count
      const now = new Date();
      const openTimeFormatted = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + now.toLocaleDateString('vi-VN');
      
      // Generate standard order number
      const randId = Math.floor(1000 + Math.random() * 9000);
      const orderNumber = `SF_0000${randId}`;

      tableOrders.value[tableCode] = {
        orderNumber,
        tableCode,
        customerName: table?.customerName || 'Khách vãng lai',
        guestCount,
        openedTime: table?.checkInTime || openTimeFormatted,
        items: []
      };
    }
    return tableOrders.value[tableCode];
  };

  // Select table for order and navigate
  const setSelectedTable = (tableCode: string | null) => {
    selectedTableCode.value = tableCode;
  };

  // Add Item to Table Order Cart
  const addOrderItem = (tableCode: string, item: MenuItem) => {
    const order = getOrCreateOrder(tableCode);
    const existing = order.items.find(i => i.id === item.id);
    if (existing) {
      existing.quantity++;
    } else {
      order.items.push({
        id: item.id,
        name: item.name,
        unit: item.unit,
        price: item.price,
        price_display: item.price_display,
        quantity: 1,
        category_id: item.category_id
      });
    }
  };

  // Update item quantity in cart
  const updateItemQuantity = (tableCode: string, itemId: string, change: number) => {
    const order = tableOrders.value[tableCode];
    if (!order) return;
    const item = order.items.find(i => i.id === itemId);
    if (item) {
      item.quantity += change;
      if (item.quantity <= 0) {
        order.items = order.items.filter(i => i.id !== itemId);
      }
    }
  };

  // Remove item from cart
  const removeOrderItem = (tableCode: string, itemId: string) => {
    const order = tableOrders.value[tableCode];
    if (!order) return;
    order.items = order.items.filter(i => i.id !== itemId);
  };

  return {
    areas,
    bookings,
    selectedTableCode,
    tableOrders,
    getTableByCode,
    getTableAreaName,
    getOrCreateOrder,
    setSelectedTable,
    addOrderItem,
    updateItemQuantity,
    removeOrderItem
  };
});
