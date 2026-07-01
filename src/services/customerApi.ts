// File: src/services/customerApi.ts
import type { 
  CustomerSession, 
  Table, 
  Area, 
  MenuItem, 
  MenuCategory, 
  CartItem, 
  Order, 
  ServiceRequest, 
  Feedback 
} from '@/types/customer';
import { menuCategories } from '@/data/menuData';

export interface CustomerApi {
  // Authentication
  authenticateStaff(passcode: string): Promise<{ success: boolean; staffId: string }>;
  
  // Table Management
  getAreas(): Promise<Area[]>;
  getTables(areaId: string): Promise<Table[]>;
  selectTable(tableId: string): Promise<{ success: boolean }>;
  confirmTable(session: CustomerSession): Promise<CustomerSession>;
  releaseTable(sessionId: string): Promise<void>;
  
  // Menu Management
  getMenu(): Promise<MenuCategory[]>;
  
  // Ordering Flow
  createOrder(order: Order): Promise<Order>;
  updateOrder(orderId: string, items: CartItem[]): Promise<Order>;
  getOrderHistory(sessionId: string): Promise<Order[]>;
  
  // Service Request
  submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest>;
  getServiceRequests(sessionId: string): Promise<ServiceRequest[]>;
  updateServiceRequest(requestId: string, status: string): Promise<void>;
  
  // Payment & Invoices
  requestPayment(sessionId: string): Promise<{ success: boolean }>;
  requestInvoice(sessionId: string): Promise<{ invoiceId: string }>;
  
  // Feedback
  submitFeedback(feedback: Feedback): Promise<Feedback>;
  
  // Real-time implementations
  subscribeToTableUpdates(tableId: string, callback: (payload: any) => void): () => void;
  subscribeToServiceRequests(sessionId: string, callback: (payload: any) => void): () => void;
  subscribeToOrderUpdates(sessionId: string, callback: (payload: any) => void): () => void;
}

// In-Memory Database / Mock Layer
const localTables: Table[] = [
  // 9 tables for Khu A
  { id: 't-khu-a-A01', number: 'A01', areaId: 'khu-a', status: 'available', capacity: 4 },
  { id: 't-khu-a-A02', number: 'A02', areaId: 'khu-a', status: 'occupied', capacity: 4 },
  { id: 't-khu-a-A03', number: 'A03', areaId: 'khu-a', status: 'available', capacity: 4 },
  { id: 't-khu-a-A04', number: 'A04', areaId: 'khu-a', status: 'selecting', capacity: 4 },
  { id: 't-khu-a-A05', number: 'A05', areaId: 'khu-a', status: 'available', capacity: 4 },
  { id: 't-khu-a-A06', number: 'A06', areaId: 'khu-a', status: 'occupied', capacity: 4 },
  { id: 't-khu-a-A07', number: 'A07', areaId: 'khu-a', status: 'available', capacity: 4 },
  { id: 't-khu-a-A08', number: 'A08', areaId: 'khu-a', status: 'available', capacity: 4 },
  { id: 't-khu-a-A09', number: 'A09', areaId: 'khu-a', status: 'available', capacity: 4 },

  // 3 tables for Khu B
  { id: 't-khu-b-B01', number: 'B01', areaId: 'khu-b', status: 'available', capacity: 4 },
  { id: 't-khu-b-B02', number: 'B02', areaId: 'khu-b', status: 'occupied', capacity: 4 },
  { id: 't-khu-b-B03', number: 'B03', areaId: 'khu-b', status: 'available', capacity: 4 },

  // 8 tables for Khu C
  { id: 't-khu-c-C01', number: 'C01', areaId: 'khu-c', status: 'available', capacity: 4 },
  { id: 't-khu-c-C02', number: 'C02', areaId: 'khu-c', status: 'occupied', capacity: 4 },
  { id: 't-khu-c-C03', number: 'C03', areaId: 'khu-c', status: 'available', capacity: 4 },
  { id: 't-khu-c-C04', number: 'C04', areaId: 'khu-c', status: 'selecting', capacity: 4 },
  { id: 't-khu-c-C05', number: 'C05', areaId: 'khu-c', status: 'available', capacity: 4 },
  { id: 't-khu-c-C06', number: 'C06', areaId: 'khu-c', status: 'occupied', capacity: 4 },
  { id: 't-khu-c-C07', number: 'C07', areaId: 'khu-c', status: 'available', capacity: 4 },
  { id: 't-khu-c-C08', number: 'C08', areaId: 'khu-c', status: 'available', capacity: 4 },

  // 8 tables for Khu R
  { id: 't-khu-r-R01', number: 'R01', areaId: 'khu-r', status: 'available', capacity: 4 },
  { id: 't-khu-r-R02', number: 'R02', areaId: 'khu-r', status: 'occupied', capacity: 4 },
  { id: 't-khu-r-R03', number: 'R03', areaId: 'khu-r', status: 'available', capacity: 4 },
  { id: 't-khu-r-R04', number: 'R04', areaId: 'khu-r', status: 'selecting', capacity: 4 },
  { id: 't-khu-r-R05', number: 'R05', areaId: 'khu-r', status: 'available', capacity: 4 },
  { id: 't-khu-r-R06', number: 'R06', areaId: 'khu-r', status: 'occupied', capacity: 4 },
  { id: 't-khu-r-R07', number: 'R07', areaId: 'khu-r', status: 'available', capacity: 4 },
  { id: 't-khu-r-R08', number: 'R08', areaId: 'khu-r', status: 'available', capacity: 4 },

  // 8 tables for Khu T
  { id: 't-khu-t-T01', number: 'T01', areaId: 'khu-t', status: 'available', capacity: 4 },
  { id: 't-khu-t-T02', number: 'T02', areaId: 'khu-t', status: 'occupied', capacity: 4 },
  { id: 't-khu-t-T03', number: 'T03', areaId: 'khu-t', status: 'available', capacity: 4 },
  { id: 't-khu-t-T04', number: 'T04', areaId: 'khu-t', status: 'selecting', capacity: 4 },
  { id: 't-khu-t-T05', number: 'T05', areaId: 'khu-t', status: 'available', capacity: 4 },
  { id: 't-khu-t-T06', number: 'T06', areaId: 'khu-t', status: 'occupied', capacity: 4 },
  { id: 't-khu-t-T07', number: 'T07', areaId: 'khu-t', status: 'available', capacity: 4 },
  { id: 't-khu-t-T08', number: 'T08', areaId: 'khu-t', status: 'available', capacity: 4 },

  // 5 tables for Capichi
  { id: 't-capichi-CP01', number: 'CP01', areaId: 'capichi', status: 'available', capacity: 4 },
  { id: 't-capichi-CP02', number: 'CP02', areaId: 'capichi', status: 'occupied', capacity: 4 },
  { id: 't-capichi-CP03', number: 'CP03', areaId: 'capichi', status: 'available', capacity: 4 },
  { id: 't-capichi-CP04', number: 'CP04', areaId: 'capichi', status: 'selecting', capacity: 4 },
  { id: 't-capichi-CP05', number: 'CP05', areaId: 'capichi', status: 'available', capacity: 4 },

  // 5 tables for Shopee
  { id: 't-shopee-Shopee01', number: 'Shopee01', areaId: 'shopee', status: 'available', capacity: 4 },
  { id: 't-shopee-Shopee02', number: 'Shopee02', areaId: 'shopee', status: 'occupied', capacity: 4 },
  { id: 't-shopee-Shopee03', number: 'Shopee03', areaId: 'shopee', status: 'available', capacity: 4 },
  { id: 't-shopee-Shopee04', number: 'Shopee04', areaId: 'shopee', status: 'selecting', capacity: 4 },
  { id: 't-shopee-Shopee05', number: 'Shopee05', areaId: 'shopee', status: 'available', capacity: 4 },

  // 5 tables for BE
  { id: 't-be-BE01', number: 'BE01', areaId: 'be', status: 'available', capacity: 4 },
  { id: 't-be-BE02', number: 'BE02', areaId: 'be', status: 'occupied', capacity: 4 },
  { id: 't-be-BE03', number: 'BE03', areaId: 'be', status: 'available', capacity: 4 },
  { id: 't-be-BE04', number: 'BE04', areaId: 'be', status: 'selecting', capacity: 4 },
  { id: 't-be-BE05', number: 'BE05', areaId: 'be', status: 'available', capacity: 4 },

  // 5 tables for Grab
  { id: 't-grab-Grab01', number: 'Grab01', areaId: 'grab', status: 'available', capacity: 4 },
  { id: 't-grab-Grab02', number: 'Grab02', areaId: 'grab', status: 'occupied', capacity: 4 },
  { id: 't-grab-Grab03', number: 'Grab03', areaId: 'grab', status: 'available', capacity: 4 },
  { id: 't-grab-Grab04', number: 'Grab04', areaId: 'grab', status: 'selecting', capacity: 4 },
  { id: 't-grab-Grab05', number: 'Grab05', areaId: 'grab', status: 'available', capacity: 4 },

  // 1 table for Catalog
  { id: 't-catalog-Catalog', number: 'Catalog', areaId: 'catalog', status: 'available', capacity: 4 }
];

const localSessions: Record<string, CustomerSession> = {};
const localOrders: Order[] = [];
const localRequests: ServiceRequest[] = [];
const localFeedbacks: Feedback[] = [];

export const customerApiImpl: CustomerApi = {
  async authenticateStaff(passcode: string): Promise<{ success: boolean; staffId: string }> {
    // BR-01: Passcode length is 6
    if (passcode.length !== 6) {
      return { success: false, staffId: '' };
    }
    // Hardcode passcode 123456 or 654321 for demo / staff authentication
    if (passcode === '123456' || passcode === '654321') {
      return { success: true, staffId: 'staff-uuid-001' };
    }
    return { success: false, staffId: '' };
  },

  async getAreas(): Promise<Area[]> {
    return [
      { id: 'khu-a', name: 'Khu A', tables: [] },
      { id: 'khu-b', name: 'Khu B', tables: [] },
      { id: 'khu-c', name: 'Khu C', tables: [] },
      { id: 'khu-r', name: 'Khu R', tables: [] },
      { id: 'khu-t', name: 'Khu T', tables: [] },
      { id: 'capichi', name: 'Khu Capichi', tables: [] },
      { id: 'shopee', name: 'Khu Shopee', tables: [] },
      { id: 'be', name: 'Khu BE', tables: [] },
      { id: 'grab', name: 'Khu Grab', tables: [] },
      { id: 'catalog', name: 'Khu Catalog (Nội bộ)', tables: [] }
    ];
  },

  async getTables(areaId: string): Promise<Table[]> {
    return localTables.filter(t => t.areaId === areaId);
  },

  async selectTable(tableId: string): Promise<{ success: boolean }> {
    const table = localTables.find(t => t.id === tableId);
    if (table) {
      if (table.status !== 'available') {
        return { success: false };
      }
      table.status = 'selecting';
    }
    return { success: true };
  },

  async confirmTable(session: CustomerSession): Promise<CustomerSession> {
    localSessions[session.id] = session;
    const table = localTables.find(t => t.id === session.tableId);
    if (table) {
      table.status = 'occupied';
      table.currentSessionId = session.id;
    }
    return session;
  },

  async releaseTable(sessionId: string): Promise<void> {
    const session = localSessions[sessionId];
    if (session) {
      session.status = 'completed';
      const table = localTables.find(t => t.id === session.tableId);
      if (table) {
        table.status = 'available';
        delete table.currentSessionId;
      }
      delete localSessions[sessionId];
    }
  },

  async getMenu(): Promise<MenuCategory[]> {
    return menuCategories;
  },

  async createOrder(order: Order): Promise<Order> {
    order.id = `ord-${Date.now()}`;
    localOrders.push(order);
    return order;
  },

  async updateOrder(orderId: string, items: CartItem[]): Promise<Order> {
    const order = localOrders.find(o => o.id === orderId);
    if (order) {
      order.items = items;
      order.subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
      order.vat = Math.round(order.subtotal * 0.08);
      order.total = order.subtotal + order.vat;
    }
    return order!;
  },

  async getOrderHistory(sessionId: string): Promise<Order[]> {
    return localOrders.filter(o => o.sessionId === sessionId);
  },

  async submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest> {
    localRequests.push(request);
    return request;
  },

  async getServiceRequests(sessionId: string): Promise<ServiceRequest[]> {
    return localRequests.filter(r => r.sessionId === sessionId);
  },

  async updateServiceRequest(requestId: string, status: string): Promise<void> {
    const req = localRequests.find(r => r.id === requestId);
    if (req) {
      req.status = status as any;
      if (status === 'completed') {
        req.completedAt = new Date();
      }
    }
  },

  async requestPayment(sessionId: string): Promise<{ success: boolean }> {
    const session = localSessions[sessionId];
    if (session) {
      session.status = 'waiting_payment';
    }
    return { success: true };
  },

  async requestInvoice(sessionId: string): Promise<{ invoiceId: string }> {
    return { invoiceId: `inv-mock-${Math.floor(Math.random() * 100000)}` };
  },

  async submitFeedback(feedback: Feedback): Promise<Feedback> {
    localFeedbacks.push(feedback);
    return feedback;
  },

  // Real-time mock implementation channels
  subscribeToTableUpdates(tableId: string, callback: (payload: any) => void): () => void {
    return () => {};
  },

  subscribeToServiceRequests(sessionId: string, callback: (payload: any) => void): () => void {
    return () => {};
  },

  subscribeToOrderUpdates(sessionId: string, callback: (payload: any) => void): () => void {
    return () => {};
  }
};
