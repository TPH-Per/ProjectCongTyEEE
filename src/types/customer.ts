// File: src/types/customer.ts

// Branch
export interface Branch {
  id: string;
  code: string;
  name: string;
  name_en?: string;
  address?: string;
  phone?: string;
  isActive: boolean;
}

// Session & Table
export interface CustomerSession {
  id: string;
  tableId: string;
  tableNumber: string;
  areaId: string;
  areaName: string;
  staffId: string;
  startedAt: Date;
  status: 'active' | 'waiting_payment' | 'completed';
}

export type TableStatus = 'available' | 'selecting' | 'occupied';

export interface Table {
  id: string;
  number: string;
  areaId: string;
  status: TableStatus;
  capacity: number;
  currentSessionId?: string;
}

export interface Area {
  id: string;
  name: string;
  tables: Table[];
  code?: string;
  name_en?: string;
}

// Menu
export interface MenuItem {
  id: string;
  name: string;
  unit: string;
  price: number;
  price_display: string;
  category_id: string;
  description?: string;
  image_url?: string;
  is_available?: boolean;
}

export interface SubCategory {
  id: string;
  name: string;
  items: MenuItem[];
}

export interface MenuCategory {
  id: string;
  name: string;
  color: 'yellow' | 'pink';
  items?: MenuItem[];
  subcategories?: SubCategory[];
}

// Cart & Order
export interface CartItem {
  menuItemId: string;
  name: string;
  unit: string;
  price: number;
  price_display: string;
  quantity: number;
  note?: string;
}

export interface Order {
  id: string;
  sessionId: string;
  tableNumber: string;
  items: CartItem[];
  subtotal: number;
  serviceCharge: number;
  vat: number;
  discount: number;
  total: number;
  status: 'draft' | 'confirmed' | 'cooking' | 'served' | 'completed';
  createdAt: Date;
  kitchenTickets?: KitchenTicket[];
}

export interface KitchenTicket {
  id: string;
  orderId: string;
  kitchenStation: 'hot' | 'meat' | 'salad';
  items: CartItem[];
  printedCount: number;
  printedAt: Date;
}

// Service Request
export type ServiceRequestType = 
  | 'tissue' | 'bowl' | 'sauce' | 'ice' 
  | 'grill_change' | 'charcoal_change'
  | 'request_bill' | 'call_waiter' | 'other';

export interface ServiceRequest {
  id: string;
  sessionId: string;
  tableNumber: string;
  type: ServiceRequestType;
  content?: string;
  status: 'created' | 'waiting' | 'accepted' | 'processing' | 'completed' | 'cancelled';
  createdAt: Date;
  completedAt?: Date;
}

// Feedback
export interface Feedback {
  id: string;
  sessionId: string;
  rating: 1 | 2 | 3 | 4 | 5;
  criteria: string[];  // ['service_time', 'food_quality', 'hygiene', ...]
  comment?: string;
  createdAt: Date;
}
