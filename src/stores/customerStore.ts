// File: src/stores/customerStore.ts
import { defineStore } from 'pinia';
import type { 
  CustomerSession, 
  Table, 
  Area, 
  MenuItem, 
  MenuCategory, 
  CartItem, 
  Order, 
  ServiceRequest, 
  Feedback,
  SubCategory
} from '@/types/customer';
import { customerApiImpl } from '@/services/customerApi';

export interface Notification {
  id: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
}

export const useCustomerStore = defineStore('customer', {
  state: () => ({
    // Session
    session: null as CustomerSession | null,
    isAuthenticated: false, // unlocked by staff passcode
    
    // Area & Table
    areas: [] as Area[],
    selectedAreaId: null as string | null,
    tables: [] as Table[],
    selectedTable: null as Table | null,
    
    // Menu
    menuData: [] as MenuCategory[],
    selectedCategory: null as MenuCategory | null,
    selectedSubcategory: null as SubCategory | null,
    
    // Cart
    cart: [] as CartItem[],
    
    // Orders
    orders: [] as Order[],
    currentOrder: null as Order | null,
    
    // Service Requests
    serviceRequests: [] as ServiceRequest[],
    
    // Feedback
    feedback: null as Feedback | null,
    
    // UI State
    currentView: 'home' as 'home' | 'menu' | 'cart' | 'history' | 'feedback',
    notifications: [] as Notification[],
    searchQuery: '',
    currentLanguage: 'vi' as 'vi' | 'en' | 'ja'
  }),
  
  actions: {
    // NV1: Authentication & Table Selection
    async authenticateStaff(passcode: string): Promise<boolean> {
      const res = await customerApiImpl.authenticateStaff(passcode);
      this.isAuthenticated = res.success;
      return res.success;
    },

    async loadAreas(): Promise<Area[]> {
      const areas = await customerApiImpl.getAreas();
      this.areas = areas;
      return areas;
    },

    async loadTables(areaId: string): Promise<Table[]> {
      const tables = await customerApiImpl.getTables(areaId);
      this.tables = tables;
      return tables;
    },

    async selectTable(tableId: string): Promise<boolean> {
      const res = await customerApiImpl.selectTable(tableId);
      if (res.success) {
        const table = this.tables.find(t => t.id === tableId);
        if (table) {
          this.selectedTable = table;
        }
        return true;
      }
      return false;
    },

    async confirmTable(): Promise<void> {
      if (!this.selectedTable) return;
      
      const newSession: CustomerSession = {
        id: `sess-${Date.now()}`,
        tableId: this.selectedTable.id,
        tableNumber: this.selectedTable.number,
        areaId: this.selectedTable.areaId,
        areaName: this.areas.find(a => a.id === this.selectedTable?.areaId)?.name || 'Khu vực',
        staffId: 'staff-uuid-001',
        startedAt: new Date(),
        status: 'active'
      };

      const session = await customerApiImpl.confirmTable(newSession);
      this.session = session;
      this.currentView = 'menu';

      // Persist session to localStorage for active session recovery
      localStorage.setItem('nguucat_customer_session', JSON.stringify(session));
      localStorage.setItem('nguucat_customer_auth', 'true');
      if (this.selectedTable) {
        localStorage.setItem('nguucat_customer_table', JSON.stringify(this.selectedTable));
      }
    },
    
    // NV2: Menu & Add to Cart
    async loadMenu(): Promise<void> {
      const menu = await customerApiImpl.getMenu();
      this.menuData = menu;
      if (menu.length > 0) {
        this.selectedCategory = menu[0];
        if (menu[0].subcategories && menu[0].subcategories.length > 0) {
          this.selectedSubcategory = menu[0].subcategories[0];
        }
      }
    },

    selectCategory(categoryId: string): void {
      const cat = this.menuData.find(c => c.id === categoryId);
      if (cat) {
        this.selectedCategory = cat;
        if (cat.subcategories && cat.subcategories.length > 0) {
          this.selectedSubcategory = cat.subcategories[0];
        } else {
          this.selectedSubcategory = null;
        }
      }
    },

    selectSubcategory(subcategoryId: string): void {
      if (this.selectedCategory?.subcategories) {
        const sub = this.selectedCategory.subcategories.find(s => s.id === subcategoryId);
        if (sub) {
          this.selectedSubcategory = sub;
        }
      }
    },

    addToCart(item: MenuItem, quantity: number = 1): void {
      const existing = this.cart.find(c => c.menuItemId === item.id);
      if (existing) {
        existing.quantity += quantity;
      } else {
        this.cart.push({
          menuItemId: item.id,
          name: item.name,
          unit: item.unit,
          price: item.price,
          price_display: item.price_display,
          quantity: quantity,
          note: ''
        });
      }
    },

    updateCartItem(itemId: string, quantity: number): void {
      const existing = this.cart.find(c => c.menuItemId === itemId);
      if (existing) {
        existing.quantity = quantity;
        if (existing.quantity <= 0) {
          this.removeFromCart(itemId);
        }
      }
    },

    removeFromCart(itemId: string): void {
      this.cart = this.cart.filter(c => c.menuItemId !== itemId);
    },

    clearCart(): void {
      this.cart = [];
    },
    
    // NV3: Service Request
    async submitServiceRequest(requestType: string, content?: string): Promise<void> {
      if (!this.session) return;

      const request: ServiceRequest = {
        id: `req-${Date.now()}`,
        sessionId: this.session.id,
        tableNumber: this.session.tableNumber,
        type: requestType as any,
        content: content || '',
        status: 'created',
        createdAt: new Date()
      };

      const result = await customerApiImpl.submitServiceRequest(request);
      this.serviceRequests.push(result);
      this.addNotification(`Đã gửi yêu cầu: ${this.translateRequestType(requestType)}`, 'success');
    },

    async cancelServiceRequest(requestId: string): Promise<void> {
      await customerApiImpl.updateServiceRequest(requestId, 'cancelled');
      const req = this.serviceRequests.find(r => r.id === requestId);
      if (req) {
        req.status = 'cancelled';
      }
      this.addNotification('Đã hủy yêu cầu phục vụ', 'info');
    },
    
    // NV4: Cart & Order
    async confirmOrder(): Promise<Order> {
      if (!this.session || this.cart.length === 0) {
        throw new Error('Giỏ hàng trống hoặc phiên làm việc chưa bắt đầu');
      }

      const subtotal = this.cartTotal;
      const charge = this.serviceCharge;
      const vatVal = this.vat;
      const grand = this.grandTotal;

      const order: Order = {
        id: `ord-${Date.now()}`,
        sessionId: this.session.id,
        tableNumber: this.session.tableNumber,
        items: [...this.cart],
        subtotal,
        serviceCharge: charge,
        vat: vatVal,
        discount: 0,
        total: grand,
        status: 'draft',
        createdAt: new Date()
      };

      const confirmedOrder = await customerApiImpl.createOrder(order);
      confirmedOrder.status = 'confirmed';
      this.orders.push(confirmedOrder);
      this.clearCart();
      this.addNotification('Đã gửi món vào bếp thành công!', 'success');
      return confirmedOrder;
    },

    async cancelOrder(orderId: string): Promise<void> {
      // Typically orders cannot be canceled after confirmation from tablet,
      // but let's provide client side action
      this.orders = this.orders.filter(o => o.id !== orderId);
      this.addNotification('Đã hủy order', 'info');
    },
    
    // NV5: History & Payment
    async loadOrderHistory(): Promise<Order[]> {
      if (!this.session) return [];
      const history = await customerApiImpl.getOrderHistory(this.session.id);
      this.orders = history;
      return history;
    },

    async requestPayment(): Promise<void> {
      if (!this.session) return;
      await customerApiImpl.requestPayment(this.session.id);
      this.session.status = 'waiting_payment';
      this.addNotification('Đã gửi yêu cầu thanh toán. Vui lòng đợi nhân viên.', 'success');
    },

    async requestInvoice(): Promise<void> {
      if (!this.session) return;
      await customerApiImpl.requestInvoice(this.session.id);
      this.addNotification('Đã gửi yêu cầu xuất hóa đơn đỏ.', 'success');
    },

    async submitFeedback(feedbackData: Omit<Feedback, 'id' | 'sessionId' | 'createdAt'>): Promise<void> {
      if (!this.session) return;
      
      const newFeedback: Feedback = {
        id: `fb-${Date.now()}`,
        sessionId: this.session.id,
        rating: feedbackData.rating,
        criteria: feedbackData.criteria,
        comment: feedbackData.comment || '',
        createdAt: new Date()
      };

      const result = await customerApiImpl.submitFeedback(newFeedback);
      this.feedback = result;
      this.addNotification('Cảm ơn đóng góp ý kiến của quý khách!', 'success');
    },
    
    // Session Management
    async endSession(): Promise<void> {
      if (this.session) {
        await customerApiImpl.releaseTable(this.session.id);
      }
      this.resetState();
    },

    resetState(): void {
      this.session = null;
      this.isAuthenticated = false;
      this.selectedAreaId = null;
      this.selectedTable = null;
      this.cart = [];
      this.orders = [];
      this.serviceRequests = [];
      this.feedback = null;
      this.currentView = 'home';
      this.notifications = [];
    },

    // UI Helpers
    addNotification(message: string, type: 'info' | 'success' | 'warning' | 'error' = 'info'): void {
      const id = `notif-${Date.now()}`;
      this.notifications.push({ id, message, type });
      setTimeout(() => {
        this.notifications = this.notifications.filter(n => n.id !== id);
      }, 4000);
    },

    translateRequestType(type: string): string {
      const types: Record<string, string> = {
        tissue: 'Lấy khăn giấy',
        bowl: 'Lấy chén bát sạch',
        sauce: 'Lấy nước chấm',
        ice: 'Lấy đá thêm',
        grill_change: 'Thay vỉ nướng',
        charcoal_change: 'Thêm than',
        request_bill: 'Thanh toán hóa đơn',
        call_waiter: 'Gọi nhân viên',
        other: 'Yêu cầu khác'
      };
      return types[type] || type;
    }
  },
  
  getters: {
    cartTotal: (state) => {
      return state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
    },
    cartItemCount: (state) => {
      return state.cart.reduce((sum, item) => sum + item.quantity, 0);
    },
    serviceCharge: (state) => {
      // 5% service charge
      const total = state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
      return Math.round(total * 0.05);
    },
    vat: (state) => {
      // 8% VAT on total + service charge
      const total = state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
      const service = Math.round(total * 0.05);
      return Math.round((total + service) * 0.08);
    },
    grandTotal: (state) => {
      const total = state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
      const service = Math.round(total * 0.05);
      const vat = Math.round((total + service) * 0.08);
      return total + service + vat;
    },
    activeServiceRequests: (state) => {
      return state.serviceRequests.filter(r => r.status !== 'completed' && r.status !== 'cancelled');
    },
    orderHistory: (state) => {
      return state.orders;
    }
  }
});
