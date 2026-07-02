// File: src/composables/useBusinessRules.ts
import { computed } from 'vue';
import { useCustomerStore } from '@/stores/customerStore';
import type { Table, MenuItem, CartItem, Order, KitchenTicket, ServiceRequest } from '@/types/customer';

export const useBusinessRules = () => {
  const store = useCustomerStore();

  const rules = {
    // ─── NV1 - Table Selection ───────────────────────────────────────────
    BR01: (passcode: string) => passcode.length === 6,
    BR02: () => store.selectedAreaId !== null,
    BR03: () => store.selectedTable !== null,
    BR04: (table: Table) => table.status === 'available',
    BR05: () => store.session === null, // Only 1 session/tablet at a time
    BR06: (table: Table) => !table.currentSessionId,
    BR07: (router: any) => router.push('/customer/menu'),
    BR08: (releaseCallback: () => void) => {
      // 60s timeout for selecting table state
      return setTimeout(releaseCallback, 60000);
    },
    
    // ─── NV2 - Menu ──────────────────────────────────────────────────────
    BR09: () => store.session !== null, // Must have active session to order
    BR10: () => store.menuData.length > 0,
    BR11: () => {
      // Preserve cart when switching categories
      // This is handled by storing cart in Pinia store state
      return true;
    },
    BR12: (item: MenuItem) => store.addToCart(item),
    BR13: (item: MenuItem) => {
      const existing = store.cart.find(i => i.menuItemId === item.id);
      if (existing) {
        store.updateCartItem(item.id, existing.quantity + 1);
      } else {
        store.addToCart(item);
      }
    },
    BR14: (quantity: number) => quantity > 0 && quantity <= 99,
    BR15: () => {
      // Auto-update cart total
      // Handled by Pinia store getters: cartTotal, cartItemCount, grandTotal
      return true;
    },
    BR16: (router: any) => router.push('/customer/cart'),
    BR17: () => store.menuData,
    
    // ─── NV4 - Cart & Order ──────────────────────────────────────────────
    BR18: () => store.cart.length === 0,
    BR19: (item: CartItem, qty: number) => {
      if (qty <= 0) {
        store.removeFromCart(item.menuItemId);
      } else if (qty <= 99) {
        store.updateCartItem(item.menuItemId, qty);
      }
    },
    BR20: (items: CartItem[]) => {
      items.forEach(item => store.removeFromCart(item.menuItemId));
    },
    BR21: () => {
      // Recalculate totals
      return {
        subtotal: store.cartTotal,
        serviceCharge: store.serviceCharge,
        vat: store.vat,
        grandTotal: store.grandTotal
      };
    },
    BR22: () => store.cart.length > 0,
    BR23: (order: Order): KitchenTicket[] => {
      // Classify by kitchen station (hot, meat, salad)
      const stations: Record<'hot' | 'meat' | 'salad', CartItem[]> = {
        hot: [],
        meat: [],
        salad: []
      };

      order.items.forEach(item => {
        // Simple logic to classify item names
        const nameLower = item.name.toLowerCase();
        if (nameLower.includes('wagyu') || nameLower.includes('thăn') || nameLower.includes('sườn') || nameLower.includes('heo') || nameLower.includes('ba chỉ')) {
          stations.meat.push(item);
        } else if (nameLower.includes('salad') || nameLower.includes('rau') || nameLower.includes('kem') || nameLower.includes('chè')) {
          stations.salad.push(item);
        } else {
          stations.hot.push(item); // Default to hot kitchen for soup, hotpot, drinks etc.
        }
      });

      const tickets: KitchenTicket[] = [];
      (Object.keys(stations) as Array<'hot' | 'meat' | 'salad'>).forEach(station => {
        if (stations[station].length > 0) {
          tickets.push({
            id: `ticket-${station}-${Date.now()}`,
            orderId: order.id,
            kitchenStation: station,
            items: stations[station],
            printedCount: 0,
            printedAt: new Date()
          });
        }
      });
      return tickets;
    },
    BR24: (station: 'hot' | 'meat' | 'salad', items: CartItem[]) => {
      return items.filter(item => {
        const nameLower = item.name.toLowerCase();
        if (station === 'meat') {
          return nameLower.includes('wagyu') || nameLower.includes('thăn') || nameLower.includes('sườn') || nameLower.includes('heo') || nameLower.includes('ba chỉ');
        } else if (station === 'salad') {
          return nameLower.includes('salad') || nameLower.includes('rau') || nameLower.includes('kem') || nameLower.includes('chè');
        } else {
          return !nameLower.includes('wagyu') && !nameLower.includes('thăn') && !nameLower.includes('sườn') && !nameLower.includes('heo') && !nameLower.includes('ba chỉ') && !nameLower.includes('salad') && !nameLower.includes('rau') && !nameLower.includes('kem') && !nameLower.includes('chè');
        }
      });
    },
    BR25: (ticket: KitchenTicket) => {
      // Validate ticket content
      return ticket.id && ticket.orderId && ticket.items.length > 0;
    },
    BR26: () => new Date(),
    BR27: (ticket: KitchenTicket, tableNumber: string) => {
      // Ticket formatting (mock helper)
      return `[TICKET BẾP] BÀN ${tableNumber} | Trạm: ${ticket.kitchenStation.toUpperCase()}`;
    },
    BR28: (ticket: KitchenTicket) => {
      ticket.printedCount++;
      ticket.printedAt = new Date();
    },
    
    // ─── NV5 - History & Payment ──────────────────────────────────────────
    BR29: (order: Order) => order.status === 'confirmed',
    BR30: (item: CartItem) => !!(item.name && item.price && item.quantity),
    BR31: (order: Order) => {
      const subtotal = order.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
      const serviceCharge = Math.round(subtotal * 0.05); // 5% service charge
      const vat = Math.round((subtotal + serviceCharge) * 0.08); // 8% VAT
      const discount = order.discount || 0;
      return subtotal + serviceCharge + vat - discount;
    },
    BR32: () => store.requestInvoice(),
    BR33: () => store.requestPayment(),
    BR34: () => store.currentView = 'feedback',
    BR35: (rating: number) => rating >= 1 && rating <= 5,
    BR36: (criteria: string[]) => criteria.length >= 1,
    BR37: (comment: string) => true, // Optional comments
    BR38: (sessionId: string) => {
      // Check if feedback already submitted for session
      return store.feedback !== null && store.feedback.sessionId === sessionId;
    }
  };

  return rules;
};
