// File: src/composables/useCustomerSession.ts
import { ref, computed, onMounted } from 'vue';
import { useCustomerStore } from '@/stores/customerStore';
import type { CustomerSession, Table } from '@/types/customer';

export function useCustomerSession() {
  const store = useCustomerStore();

  const SESSION_KEY = 'nguucat_customer_session';
  const AUTH_KEY = 'nguucat_customer_auth';
  const TABLE_KEY = 'nguucat_customer_table';
  const CART_KEY = 'nguucat_customer_cart';
  const ORDERS_KEY = 'nguucat_customer_orders';

  const session = computed(() => store.session);
  const isAuthenticated = computed(() => store.isAuthenticated);
  const selectedTable = computed(() => store.selectedTable);

  function saveSessionToLocalStorage() {
    if (store.session) {
      localStorage.setItem(SESSION_KEY, JSON.stringify(store.session));
    } else {
      localStorage.removeItem(SESSION_KEY);
    }

    localStorage.setItem(AUTH_KEY, String(store.isAuthenticated));

    if (store.selectedTable) {
      localStorage.setItem(TABLE_KEY, JSON.stringify(store.selectedTable));
    } else {
      localStorage.removeItem(TABLE_KEY);
    }

    localStorage.setItem(CART_KEY, JSON.stringify(store.cart));
  }

  function restoreSessionFromLocalStorage() {
    try {
      const savedSession = localStorage.getItem(SESSION_KEY);
      const savedAuth = localStorage.getItem(AUTH_KEY);
      const savedTable = localStorage.getItem(TABLE_KEY);
      const savedCart = localStorage.getItem(CART_KEY);
      const savedOrders = localStorage.getItem(ORDERS_KEY);

      if (savedAuth === 'true') {
        store.isAuthenticated = true;
      }

      if (savedTable) {
        store.selectedTable = JSON.parse(savedTable);
      }

      if (savedSession) {
        const parsedSession = JSON.parse(savedSession);
        // Revive date objects
        parsedSession.startedAt = new Date(parsedSession.startedAt);
        store.session = parsedSession;
        store.currentView = 'menu';
      }

      if (savedCart) {
        store.cart = JSON.parse(savedCart);
      }

      // Restore orders so they survive page reloads in mock mode
      if (savedOrders && store.orders.length === 0) {
        const parsed = JSON.parse(savedOrders) as any[];
        store.orders = parsed.map(o => ({
          ...o,
          createdAt: typeof o.createdAt === 'string' ? new Date(o.createdAt) : o.createdAt,
        }));
      }
    } catch (e) {
      console.error('Failed to restore customer session from localStorage:', e);
      clearSession();
    }
  }

  function startSession(table: Table, areaName: string) {
    store.selectedTable = table;
    store.isAuthenticated = true;
    
    const newSession: CustomerSession = {
      id: `sess-${Date.now()}`,
      tableId: table.id,
      tableNumber: table.number,
      areaId: table.areaId,
      areaName: areaName,
      staffId: 'staff-uuid-001',
      startedAt: new Date(),
      status: 'active'
    };

    store.session = newSession;
    store.currentView = 'menu';
    saveSessionToLocalStorage();
  }

  function clearSession() {
    store.resetState();
    localStorage.removeItem(SESSION_KEY);
    localStorage.removeItem(AUTH_KEY);
    localStorage.removeItem(TABLE_KEY);
    localStorage.removeItem(CART_KEY);
    localStorage.removeItem(ORDERS_KEY);
  }

  // Monitor and save changes whenever cart changes
  function syncCart() {
    localStorage.setItem(CART_KEY, JSON.stringify(store.cart));
  }

  return {
    session,
    isAuthenticated,
    selectedTable,
    startSession,
    clearSession,
    restoreSessionFromLocalStorage,
    saveSessionToLocalStorage,
    syncCart
  };
}
