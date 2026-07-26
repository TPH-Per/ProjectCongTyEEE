export interface MockQCItem {
  id: string;
  name: string;
  quantity: number;
  icon: string;
  status: 'cooked' | 'checking' | 'passed' | 'failed';
  temperature?: string;
  portion?: string;
  presentation?: string;
}

export interface MockQCOrder {
  id: string;
  ticketNumber: string;
  tableNumber: string;
  guestCount: number;
  items: MockQCItem[];
  createdAt: Date;
  hasAllergy: boolean;
  allergyInfo?: string;
  checklist: {
    presentation: boolean;
    temperature: boolean;
    portion: boolean;
    allergy: boolean;
    taste: boolean;
  };
}

export const mockQCOrders: MockQCOrder[] = [
  {
    id: 'qc-001',
    ticketNumber: '#006',
    tableNumber: 'table-B07',
    guestCount: 5,
    createdAt: new Date(Date.now() - 2 * 60000),
    hasAllergy: true,
    allergyInfo: 'KHÔNG ĐẬU PHỘNG - Nghiêm trọng',
    items: [
      {
        id: 'qc-item-001',
        name: 'Lưỡi Bò Xốt Muối Ushiyoshi',
        quantity: 2,
        icon: '👅',
        status: 'cooked',
        temperature: '60°C',
        portion: 'Đúng đĩa',
        presentation: 'Đẹp'
      }
    ],
    checklist: {
      presentation: false,
      temperature: false,
      portion: false,
      allergy: false,
      taste: false
    }
  },
  {
    id: 'qc-002',
    ticketNumber: '#004',
    tableNumber: 'table-C05',
    guestCount: 4,
    createdAt: new Date(Date.now() - 5 * 60000),
    hasAllergy: false,
    items: [
      {
        id: 'qc-item-002',
        name: 'Sườn Ngắn Wagyu Nướng Kiểu Shabu',
        quantity: 2,
        icon: '🥩',
        status: 'cooked',
        temperature: '60°C',
        portion: 'Đúng đĩa',
        presentation: 'Đẹp'
      },
      {
        id: 'qc-item-003',
        name: 'Lõi Vai Wagyu',
        quantity: 1,
        icon: '🥩',
        status: 'cooked',
        temperature: '60°C',
        portion: 'Đúng đĩa',
        presentation: 'Đẹp'
      }
    ],
    checklist: {
      presentation: false,
      temperature: false,
      portion: false,
      allergy: false,
      taste: false
    }
  }
];

export const mockRemakeQueue = [
  {
    id: 'remake-001',
    ticketNumber: '#003-R1',
    tableNumber: 'table-A02',
    itemName: 'Thăn Ngoại Wagyu',
    quantity: 1,
    reason: 'Cháy (Lỗi bếp)',
    severity: 'high',
    priority: 1,
    createdAt: new Date(Date.now() - 5 * 60000),
    status: 'cooking' as const
  }
];

export const mockStatistics = {
  passRate: 92,
  remakeRate: 3.1,
  avgQCTime: 4.2,
  totalQC: 116,
  firstPass: 107,
  wasteLogged: 0
};
