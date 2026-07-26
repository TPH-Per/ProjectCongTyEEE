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
export interface DiningSession {
  id: string; // dining_session_id
  branchId: string;
  tableId: string;
  tableNumber: string;
  areaId: string;
  areaName: string;
  staffId: string;
  guestCount: number;
  packageId?: string;
  serviceMode: 'buffet' | 'set_menu' | 'alacarte';
  languageCode: string;
  startedAt: Date;
  status: 'open' | 'ordering' | 'checkout_requested' | 'closed';
}
export type CustomerSession = DiningSession;

export type TableStatus = 'available' | 'selecting' | 'occupied';

export interface DiningTable {
  id: string; // dining_table_id
  number: string; // table_code
  areaId: string;
  status: TableStatus; // availability_status
  capacity: number;
  currentSessionId?: string;
}
export type Table = DiningTable;

export interface SessionGuest {
  guest_no: number;
  package_branch_menu_item_id: string;
  package_price_vnd_snapshot: number;
  guest_type: 'adult' | 'child';
}

export interface Area {
  id: string;
  name: string;
  tables: DiningTable[];
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
  is_sold_out?: boolean;
}

export interface PackageDetail {
  package_menu_item_id: string;
  included_menu_item_id: string;
  is_unlimited: boolean;
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
  branchMenuItemId: string;
  menuItemId?: string; // Kept for backward compatibility
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
  subtotal_vnd: number;
  serviceCharge_vnd: number;
  vat_vnd: number;
  discount_vnd: number;
  total_vnd: number;
  // Backward compatibility fields
  subtotal?: number;
  serviceCharge?: number;
  vat?: number;
  discount?: number;
  total?: number;
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
  | 'call_staff' | 'add_charcoal' | 'water' | 'checkout' | 'other'
  // Backward compatibility
  | 'tissue' | 'bowl' | 'sauce' | 'ice' 
  | 'grill_change' | 'charcoal_change'
  | 'request_bill' | 'call_waiter';

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
  surveyData: {
    criteria: string[];
    customerName?: string;
    customerPhone?: string;
  };
  criteria?: string[]; // Kept for backward compatibility
  comment?: string;
  customerName?: string;
  customerPhone?: string;
  createdAt: Date;
}
