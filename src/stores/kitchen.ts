import { defineStore } from 'pinia';
import { ref } from 'vue';

export interface GrillRequest {
  id: string;
  status: 'pending' | 'completed' | string;
  [key: string]: any;
}

export interface PrepTask {
  id: string;
  completed: boolean;
  [key: string]: any;
}

// Kitchen Requisition Interface
export interface RequisitionItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  kitchenStock: number;
  mainStock: number;
  requestedQty: number;
  deliveredQty: number;
  status: 'pending' | 'approved' | 'rejected' | string;
  rejectionReason?: string;
  proposedSubstitute?: string;
}

export interface AuditLog {
  id: string;
  action: string;
  actor: string;
  timestamp: string;
}

export interface Requisition {
  id: string;
  date: string;
  timestamp: number;
  station: string;
  actor: string;
  priority: 'low' | 'medium' | 'high';
  status: 'pending' | 'substitute_proposed' | 'approved' | 'delivered' | 'rejected';
  notes: string;
  items: RequisitionItem[];
  rejectionReason?: string;
  auditLogs: AuditLog[];
  signatureImage?: string; // Signature Data URL
  cogsUpdated?: boolean;
}

export interface HandoverLogItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  theoretical: number;
  actual: number;
  diff: number;
}

export interface HandoverLog {
  id: string;
  date: string;
  shift: string;
  outgoingChef: string;
  incomingChef: string;
  fridgeTemp: number;
  freezerTemp: number;
  wasteNotes?: string;
  notes: string;
  items: HandoverLogItem[];
  signatureImage?: string;
}

export interface InventoryItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  kitchenStock: number;
  mainStock: number;
  minKitchenStock: number;
  unitPrice: number; // Unit price in VND for COGS
  category?: string; // e.g. 'Thịt', 'Hải sản', 'Rau củ', 'Gia vị'
}

export const useKitchenStore = defineStore('kitchen', () => {
  // Lists
  const qcQueue = ref<any[]>([]);
  const grillRequests = ref<GrillRequest[]>([]);
  const prepList = ref<PrepTask[]>([
    { id: 'prep-1', name: 'Rã đông thịt bò Wagyu', completed: true },
    { id: 'prep-2', name: 'Cắt thái rau thập cẩm', completed: false },
    { id: 'prep-3', name: 'Nấu nước lẩu Sukiyaki', completed: false },
    { id: 'prep-4', name: 'Sơ chế tôm sú lớn', completed: true }
  ]);
  const delayedTickets = ref<any[]>([]);

  // Modals / Panels
  const showGrillRequestModal = ref(false);
  const isGrillPanelVisible = ref(true);
  const showPrepListModal = ref(false);
  const showHACCPModal = ref(false);
  const show86dModal = ref(false);
  const showDelayedOrdersModal = ref(false);

  // === REQUISITION STATE ===
  const inventoryList = ref<InventoryItem[]>([
    { id: 'inv-1', name: 'Thịt bò Wagyu', icon: '🥩', unit: 'kg', kitchenStock: 2, mainStock: 50, minKitchenStock: 5, unitPrice: 1200000, category: 'Thịt' },
    { id: 'inv-2', name: 'Nước lẩu Sukiyaki', icon: '🍲', unit: 'L', kitchenStock: 3, mainStock: 100, minKitchenStock: 8, unitPrice: 150000, category: 'Gia vị' },
    { id: 'inv-3', name: 'Rau thập cẩm', icon: '🥬', unit: 'kg', kitchenStock: 5, mainStock: 20, minKitchenStock: 4, unitPrice: 40000, category: 'Rau củ' },
    { id: 'inv-4', name: 'Sườn heo Mỹ', icon: '🥓', unit: 'kg', kitchenStock: 1, mainStock: 30, minKitchenStock: 3, unitPrice: 250000, category: 'Thịt' },
    { id: 'inv-5', name: 'Cá hồi tươi', icon: '🐟', unit: 'kg', kitchenStock: 1, mainStock: 15, minKitchenStock: 2, unitPrice: 450000, category: 'Hải sản' },
    { id: 'inv-6', name: 'Tôm sú lớn', icon: '🦐', unit: 'kg', kitchenStock: 0, mainStock: 25, minKitchenStock: 3, unitPrice: 38000, category: 'Hải sản' },
  ]);

  const requisitions = ref<Requisition[]>([
    {
      id: 'REQ-001',
      date: '2026-06-26 10:30',
      timestamp: Date.now() - 3600000 * 2, // 2 hours ago
      station: 'Bếp Nướng',
      actor: 'Chef Luc',
      priority: 'high',
      status: 'pending',
      notes: 'Cần gấp cho tiệc buffet tối nay của khách đoàn VIP.',
      items: [
        { id: 'inv-1', name: 'Thịt bò Wagyu', icon: '🥩', unit: 'kg', kitchenStock: 2, mainStock: 50, requestedQty: 5, deliveredQty: 5, status: 'pending' },
        { id: 'inv-2', name: 'Nước lẩu Sukiyaki', icon: '🍲', unit: 'L', kitchenStock: 3, mainStock: 100, requestedQty: 10, deliveredQty: 10, status: 'pending' },
        { id: 'inv-3', name: 'Rau thập cẩm', icon: '🥬', unit: 'kg', kitchenStock: 5, mainStock: 20, requestedQty: 3, deliveredQty: 3, status: 'pending' }
      ],
      auditLogs: [
        { id: 'log-1', action: 'Tạo phiếu yêu cầu xuất kho', actor: 'Chef Luc', timestamp: '2026-06-26 10:30' }
      ]
    },
    {
      id: 'REQ-002',
      date: '2026-06-26 09:15',
      timestamp: Date.now() - 3600000 * 3.5, // 3.5 hours ago
      station: 'Bếp Lẩu',
      actor: 'Chef Minh',
      priority: 'medium',
      status: 'delivered',
      notes: 'Hàng xuất định kỳ đầu ca.',
      items: [
        { id: 'inv-2', name: 'Nước lẩu Sukiyaki', icon: '🍲', unit: 'L', kitchenStock: 3, mainStock: 90, requestedQty: 20, deliveredQty: 20, status: 'approved' },
        { id: 'inv-3', name: 'Rau thập cẩm', icon: '🥬', unit: 'kg', kitchenStock: 5, mainStock: 17, requestedQty: 5, deliveredQty: 5, status: 'approved' }
      ],
      auditLogs: [
        { id: 'log-2', action: 'Tạo phiếu yêu cầu xuất kho', actor: 'Chef Minh', timestamp: '2026-06-26 09:15' },
        { id: 'log-3', action: 'Duyệt & Xuất kho giao hàng', actor: 'Thủ kho Nam', timestamp: '2026-06-26 09:30' },
        { id: 'log-4', action: 'Xác nhận nhận đủ hàng', actor: 'Chef Minh', timestamp: '2026-06-26 09:40' }
      ]
    },
    {
      id: 'REQ-003',
      date: '2026-06-25 16:45',
      timestamp: Date.now() - 3600000 * 22, // 22 hours ago
      station: 'Bếp Nướng',
      actor: 'Chef Luc',
      priority: 'low',
      status: 'rejected',
      notes: 'Bổ sung sườn Wagyu dự phòng.',
      rejectionReason: 'Sườn Wagyu chính hiện đang hết hàng tại kho tổng.',
      items: [
        { id: 'inv-4', name: 'Sườn heo Mỹ', icon: '🥓', unit: 'kg', kitchenStock: 1, mainStock: 30, requestedQty: 3, deliveredQty: 0, status: 'rejected', rejectionReason: 'Hết hàng tại kho tổng' }
      ],
      auditLogs: [
        { id: 'log-5', action: 'Tạo phiếu yêu cầu xuất kho', actor: 'Chef Luc', timestamp: '2026-06-25 16:45' },
        { id: 'log-6', action: 'Từ chối yêu cầu - Hết sườn', actor: 'Thủ kho Nam', timestamp: '2026-06-25 17:00' }
      ]
    },
    {
      id: 'REQ-004',
      date: '2026-06-27 11:00',
      timestamp: Date.now() - 1800000, // 30 mins ago
      station: 'Bếp Lẩu',
      actor: 'Chef Minh',
      priority: 'medium',
      status: 'substitute_proposed',
      notes: 'Cần gấp tôm sú bổ sung cho ca trưa.',
      rejectionReason: 'Tôm sú tươi lớn tạm thời hết hàng tại kho chính.',
      items: [
        { 
          id: 'inv-6', 
          name: 'Tôm sú lớn', 
          icon: '🦐', 
          unit: 'kg', 
          kitchenStock: 0, 
          mainStock: 0, 
          requestedQty: 5, 
          deliveredQty: 0, 
          status: 'rejected', 
          rejectionReason: 'Hết hàng tại kho tổng',
          proposedSubstitute: 'Thay bằng 6kg Tôm sú đông lạnh hoặc 5kg Tôm thẻ'
        }
      ],
      auditLogs: [
        { id: 'log-7', action: 'Tạo phiếu yêu cầu xuất kho', actor: 'Chef Minh', timestamp: '2026-06-27 11:00' },
        { id: 'log-8', action: 'Đề xuất phương án thay thế: Thay bằng 6kg Tôm sú đông lạnh hoặc 5kg Tôm thẻ', actor: 'Thủ kho Nam', timestamp: '2026-06-27 11:15' }
      ]
    }
  ]);

  // Actions for Requisitions
  const addRequisition = (req: Omit<Requisition, 'id' | 'date' | 'timestamp' | 'auditLogs'>) => {
    const nextNum = requisitions.value.length + 1;
    const padNum = String(nextNum).padStart(3, '0');
    const id = `REQ-${padNum}`;
    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 16);
    
    const newReq: Requisition = {
      ...req,
      id,
      date: nowStr,
      timestamp: Date.now(),
      auditLogs: [
        { id: `log-${Date.now()}-1`, action: 'Tạo phiếu yêu cầu xuất kho', actor: req.actor, timestamp: nowStr }
      ]
    };
    
    requisitions.value.unshift(newReq);
    return newReq;
  };

  const updateRequisitionStatus = (id: string, status: Requisition['status'], actor: string, reason?: string, signature?: string) => {
    const found = requisitions.value.find(r => r.id === id);
    if (found) {
      found.status = status;
      if (reason) found.rejectionReason = reason;
      if (signature) found.signatureImage = signature;
      const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 16);
      
      let actionMsg = `Thay đổi trạng thái thành: ${status}`;
      if (status === 'approved') actionMsg = 'Duyệt & Xuất kho giao hàng';
      if (status === 'rejected') actionMsg = `Từ chối yêu cầu. Lý do: ${reason}`;
      if (status === 'delivered') {
        actionMsg = 'Bếp trưởng ký xác nhận nhận hàng';
        found.cogsUpdated = true;
      }
      if (status === 'substitute_proposed') actionMsg = `Đề xuất phương án thay thế: ${reason}`;

      found.auditLogs.push({
        id: `log-${Date.now()}`,
        action: actionMsg,
        actor,
        timestamp: nowStr
      });

      // If delivered, update stocks automatically (Kitchen Inventory + Main Warehouse subtraction)
      if (status === 'delivered') {
        found.items.forEach(item => {
          // Subtract from Main Warehouse
          const mainInv = inventoryList.value.find(i => i.id === item.id);
          if (mainInv) {
            mainInv.mainStock = Math.max(0, mainInv.mainStock - item.deliveredQty);
            mainInv.kitchenStock += item.deliveredQty;
          }
        });
      }
    }
  };

  const updateRequisitionItemDelivery = (reqId: string, itemId: string, deliveredQty: number, status: string, reason?: string) => {
    const found = requisitions.value.find(r => r.id === reqId);
    if (found) {
      const item = found.items.find(i => i.id === itemId);
      if (item) {
        item.deliveredQty = deliveredQty;
        item.status = status;
        if (reason) item.rejectionReason = reason;
      }
    }
  };

  // === SHIFT HANDOVER STATE ===
  const handoverLogs = ref<HandoverLog[]>([
    {
      id: 'HO-001',
      date: '2026-06-25 14:00',
      shift: 'Ca Sáng (06:00 - 14:00)',
      outgoingChef: 'Chef Luc',
      incomingChef: 'Chef Minh',
      fridgeTemp: 3,
      freezerTemp: -19,
      notes: 'Bếp đã dọn sạch sẽ, than còn dư nửa bao ở tủ phụ. Bếp nướng số 2 hơi bị kẹt nút khởi động đã báo bảo trì.',
      items: [
        { id: 'inv-1', name: 'Thịt bò Wagyu', icon: '🥩', unit: 'kg', theoretical: 3, actual: 3, diff: 0 },
        { id: 'inv-2', name: 'Nước lẩu Sukiyaki', icon: '🍲', unit: 'L', theoretical: 10, actual: 10, diff: 0 },
        { id: 'inv-3', name: 'Rau thập cẩm', icon: '🥬', unit: 'kg', theoretical: 6, actual: 5.5, diff: -0.5 }
      ]
    }
  ]);

  const addHandoverLog = (log: Omit<HandoverLog, 'id' | 'date'>) => {
    const nextNum = handoverLogs.value.length + 1;
    const padNum = String(nextNum).padStart(3, '0');
    const id = `HO-${padNum}`;
    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 16);

    const newLog: HandoverLog = {
      ...log,
      id,
      date: nowStr
    };

    handoverLogs.value.unshift(newLog);
    return newLog;
  };

  return {
    qcQueue,
    grillRequests,
    prepList,
    delayedTickets,
    showGrillRequestModal,
    isGrillPanelVisible,
    showPrepListModal,
    showHACCPModal,
    show86dModal,
    showDelayedOrdersModal,

    // Requisition State & Actions
    inventoryList,
    requisitions,
    addRequisition,
    updateRequisitionStatus,
    updateRequisitionItemDelivery,
    
    // Handover state & actions
    handoverLogs,
    addHandoverLog
  };
});
