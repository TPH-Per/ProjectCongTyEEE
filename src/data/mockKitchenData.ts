export interface MockTicketItem {
  id: string;
  name: string;
  quantity: number;
  unit: string;
  icon: string;
  notes?: string;
  hasAllergy?: boolean;
  allergyInfo?: string;
  checklist?: string[];
  checklistCompleted?: string[];
}

export interface MockTicket {
  id: string;
  ticketNumber: string;
  tableNumber: string;
  guestCount: number;
  station: 'grill' | 'hotpot' | 'cold' | 'fry' | 'bar';
  status: 'pending' | 'preparing' | 'ready' | 'done' | 'delayed';
  priority: 1 | 2 | 3 | 4; // 1=Remake, 2=Round1, 3=ALacarte, 4=RoundN
  createdAt: Date;
  startedAt?: Date;
  completedAt?: Date;
  items: MockTicketItem[];
  notes?: string;
  isRemake?: boolean;
  roundNumber?: number;
}

export const mockTickets: MockTicket[] = [
  // Cột 1: Chờ Xác Nhận (Pending)
  {
    id: 'ticket-001',
    ticketNumber: '#001',
    tableNumber: 'table-A01',
    guestCount: 4,
    station: 'grill',
    status: 'pending',
    priority: 2,
    createdAt: new Date(Date.now() - 5 * 60000), // 5 phút trước
    items: [
      {
        id: 'item-001',
        name: 'Sườn Wagyu Xốt Ushiyoshi',
        quantity: 2,
        unit: 'phần',
        icon: '🥩',
        notes: 'Nướng tái',
        checklist: ['Sơ chế', 'Nướng canh chín', 'Trở mặt', 'Plating'],
        checklistCompleted: []
      },
      {
        id: 'item-002',
        name: 'Lưỡi bò cắt dày',
        quantity: 1,
        unit: 'phần',
        icon: '👅',
        checklist: ['Sơ chế', 'Nướng chín tới', 'Cắt lát', 'Plating'],
        checklistCompleted: []
      }
    ],
    notes: 'Khách VIP - Ưu tiên phục vụ nhanh'
  },
  {
    id: 'ticket-002',
    ticketNumber: '#002',
    tableNumber: 'table-B03',
    guestCount: 2,
    station: 'hotpot',
    status: 'pending',
    priority: 3,
    createdAt: new Date(Date.now() - 3 * 60000), // 3 phút trước
    items: [
      {
        id: 'item-003',
        name: 'Lẩu Sukiyaki',
        quantity: 1,
        unit: 'lẩu',
        icon: '🍲',
        notes: 'Ít cay',
        checklist: ['Chuẩn bị nước dùng', 'Xếp rau củ', 'Đun sôi'],
        checklistCompleted: []
      }
    ]
  },

  // Cột 2: Đang Chế Biến (Preparing)
  {
    id: 'ticket-003',
    ticketNumber: '#003',
    tableNumber: 'table-A02',
    guestCount: 6,
    station: 'grill',
    status: 'preparing',
    priority: 1, // Remake - ưu tiên cao nhất
    createdAt: new Date(Date.now() - 15 * 60000),
    startedAt: new Date(Date.now() - 10 * 60000),
    isRemake: true,
    items: [
      {
        id: 'item-004',
        name: 'Thăn Ngoại Wagyu',
        quantity: 1,
        unit: 'phần',
        icon: '🥩',
        notes: 'Làm lại - Cháy (lỗi bếp)',
        checklist: ['Sơ chế', 'Nướng chín tới', 'Trở mặt', 'Plating'],
        checklistCompleted: ['Sơ chế', 'Nướng chín tới']
      }
    ]
  },
  {
    id: 'ticket-004',
    ticketNumber: '#004',
    tableNumber: 'table-C05',
    guestCount: 4,
    station: 'grill',
    status: 'preparing',
    priority: 2,
    createdAt: new Date(Date.now() - 20 * 60000),
    startedAt: new Date(Date.now() - 18 * 60000),
    items: [
      {
        id: 'item-005',
        name: 'Sườn Ngắn Wagyu Nướng Kiểu Shabu',
        quantity: 2,
        unit: 'phần',
        icon: '🥩',
        checklist: ['Sơ chế', 'Nướng chín', 'Cắt miếng vừa', 'Plating'],
        checklistCompleted: ['Sơ chế', 'Nướng chín', 'Cắt miếng vừa']
      },
      {
        id: 'item-006',
        name: 'Lõi Vai Wagyu',
        quantity: 1,
        unit: 'phần',
        icon: '🥩',
        checklist: ['Sơ chế', 'Nướng tái', 'Plating'],
        checklistCompleted: ['Sơ chế']
      }
    ]
  },
  {
    id: 'ticket-005',
    ticketNumber: '#005',
    tableNumber: 'table-A04',
    guestCount: 3,
    station: 'hotpot',
    status: 'preparing',
    priority: 3,
    createdAt: new Date(Date.now() - 25 * 60000),
    startedAt: new Date(Date.now() - 20 * 60000),
    items: [
      {
        id: 'item-007',
        name: 'Lẩu Kimchi',
        quantity: 1,
        unit: 'lẩu',
        icon: '🍲',
        checklist: ['Chuẩn bị nước dùng', 'Thêm kimchi', 'Đun sôi'],
        checklistCompleted: ['Chuẩn bị nước dùng', 'Thêm kimchi']
      }
    ]
  },

  // Cột 3: Sẵn Sàng Ra Món (Ready)
  {
    id: 'ticket-006',
    ticketNumber: '#006',
    tableNumber: 'table-B07',
    guestCount: 5,
    station: 'grill',
    status: 'ready',
    priority: 2,
    createdAt: new Date(Date.now() - 30 * 60000),
    startedAt: new Date(Date.now() - 25 * 60000),
    completedAt: new Date(Date.now() - 2 * 60000),
    items: [
      {
        id: 'item-008',
        name: 'Lưỡi Bò Xốt Muối Ushiyoshi',
        quantity: 2,
        unit: 'phần',
        icon: '👅',
        checklist: ['Sơ chế', 'Nướng chín tới', 'Cắt lát', 'Plating'],
        checklistCompleted: ['Sơ chế', 'Nướng chín tới', 'Cắt lát', 'Plating']
      }
    ]
  },

  // Cột 4: Hoàn Tất (Done)
  {
    id: 'ticket-007',
    ticketNumber: '#007',
    tableNumber: 'table-A03',
    guestCount: 4,
    station: 'cold',
    status: 'done',
    priority: 3,
    createdAt: new Date(Date.now() - 40 * 60000),
    startedAt: new Date(Date.now() - 35 * 60000),
    completedAt: new Date(Date.now() - 5 * 60000),
    items: [
      {
        id: 'item-009',
        name: 'Salad Cá Ngừ',
        quantity: 1,
        unit: 'phần',
        icon: '🥗',
        checklist: ['Rửa rau', 'Cắt cá ngừ', 'Trộn salad', 'Plating'],
        checklistCompleted: ['Rửa rau', 'Cắt cá ngừ', 'Trộn salad', 'Plating']
      }
    ]
  }
];

// Mock Grill Requests (Yêu cầu Vỉ & Than)
export const mockGrillRequests = [
  {
    id: 'grill-001',
    tableNumber: 'table-A02',
    type: 'vỉ',
    reason: 'Vỉ bẩn, cần thay mới',
    status: 'pending',
    createdAt: new Date(Date.now() - 5 * 60000),
    estimatedTime: 3 // phút
  },
  {
    id: 'grill-002',
    tableNumber: 'table-C05',
    type: 'than',
    reason: 'Than yếu, cần châm thêm',
    status: 'in-progress',
    createdAt: new Date(Date.now() - 8 * 60000),
    estimatedTime: 2
  }
];

// Mock 86'd Items (Món hết hàng)
export const mock86dItems = [
  {
    id: '86-001',
    itemName: 'Tỏi băm',
    category: 'Gia vị',
    reason: 'Hết nguyên liệu',
    reportedAt: new Date(Date.now() - 30 * 60000),
    estimatedRestock: new Date(Date.now() + 60 * 60000), // 1 giờ nữa
    affectedOrders: ['ticket-001', 'ticket-003']
  },
  {
    id: '86-002',
    itemName: 'Nấm Kim Châm',
    category: 'Rau củ',
    reason: 'Hết hàng trong kho',
    reportedAt: new Date(Date.now() - 45 * 60000),
    estimatedRestock: new Date(Date.now() + 2 * 60 * 60000), // 2 giờ nữa
    affectedOrders: []
  }
];
