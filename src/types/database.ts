// =============================================================================
// src/types/database.ts
// Hand-written mirror of docs/DATABASE_SCHEMA.sql (Refactored 2026-06-25)
// =============================================================================

// ─── Enums ──────────────────────────────────────────────────────────────────
export type UserRole = 'admin' | 'manager' | 'reception' | 'staff' | 'kitchen'
export type TableStatus = 'available' | 'reserved' | 'occupied' | 'maintenance' | 'needs_cleaning'
export type ReservationStatus = 'Pending' | 'Arrived' | 'Dining' | 'Completed' | 'Cancelled'
export type OrderStatus = 'Pending' | 'Preparing' | 'Served' | 'Paid' | 'Cancelled'
export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'cancelled' | 'refunded'
export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
export type ShiftStatus = 'open' | 'closed'
export type PackageType = 'buffet' | 'set' | 'drink' | 'other'
export type RevenueType = 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
export type VoucherType = 'percent' | 'amount'

// ─── JSONB Interfaces ───────────────────────────────────────────────────────
export interface I18nString {
  vi: string
  en: string
  ja: string
  [k: string]: string
}

export interface CustomerPreferences {
  allergies?: string[]
  favorite_tables?: string[]
  [k: string]: unknown
}

export interface PackageItemConfig {
  menu_item_id: string
  limit: number | null
}

export interface AppliedVoucher {
  voucher_id: string
  code: string
  discount_amount: number
}

export interface TaxInfo {
  tax_code?: string
  company_name?: string
  address?: string
  email?: string
}

export interface ShiftNotes {
  handover_notes?: string
  incidents?: string
  [k: string]: unknown
}

export interface BookingInfo {
  source?: string
  occasion?: string
  notes?: string
  [k: string]: unknown
}

// ─── Row / Insert / Update shapes ──────────────────────────────────────────
export interface BranchRow {
  id: string
  code: string
  name: string
  address: string | null
  phone: string | null
  timezone: string
  currency: string
  vat_rate: number
  is_active: boolean
  created_at: string
  updated_at: string
}
export interface UserRow {
  id: string
  branch_id: string | null
  full_name: string
  email: string
  phone: string | null
  role: UserRole
  is_active: boolean
  preferences: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface TableRow {
  id: string
  branch_id: string
  zone: string
  code: string
  capacity: number
  shape: 'round' | 'square' | 'rectangle' | null
  pos_x: number
  pos_y: number
  status: TableStatus
  is_active: boolean
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface CustomerRow {
  id: string
  branch_id: string
  name: string
  phone: string | null
  email: string | null
  total_visits: number
  total_spent: number
  last_visit_at: string | null
  is_vip: boolean
  tags: string[]
  preferences: CustomerPreferences
  demographics: Record<string, unknown>
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface MenuItemRow {
  id: string
  branch_id: string
  category_id: string
  menu_categories?: { name: string }
  name: string
  i18n_name: I18nString
  description: string | null
  i18n_description: I18nString
  price: number
  cost: number | null
  unit: string
  image_url: string | null
  is_available: boolean
  modifiers: unknown[]
  tags: string[]
  nutrition: Record<string, unknown>
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface PackageRow {
  id: string
  branch_id: string
  name: string
  i18n_name: I18nString
  type: PackageType
  price: number
  item_limit: number | null
  duration_minutes: number | null
  image_url: string | null
  is_active: boolean
  items_included: PackageItemConfig[]
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface ReservationRow {
  id: string
  branch_id: string
  customer_id: string | null
  table_id: string | null
  booking_code: string
  reservation_date: string
  reservation_time: string
  guests: number
  children_count: number
  status: ReservationStatus
  source: string | null
  customer_snapshot: Record<string, unknown>
  booking_info: BookingInfo
  survey_results: Record<string, unknown>
  course_id: string | null
  drink_group: string | null
  qr_token: string | null
  qr_expires_at: string | null
  timer_started_at: string | null
  expected_end_at: string | null
  arrived_at: string | null
  completed_at: string | null
  cancelled_at: string | null
  cancel_reason: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}
export interface OrderRow {
  id: string
  branch_id: string
  reservation_id: string
  order_number: string
  status: OrderStatus
  subtotal: number
  vat_rate: number
  vat: number
  total: number
  notes: Record<string, unknown>
  created_by: string | null
  created_at: string
  updated_at: string
}
export interface OrderItemRow {
  id: string
  branch_id: string
  order_id: string
  menu_item_id: string
  name_snapshot: string
  unit_price: number
  unit_cost: number | null
  quantity: number
  line_total: number
  status: OrderStatus
  modifiers: unknown[]
  note: string | null
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface InvoiceRow {
  id: string
  branch_id: string
  reservation_id: string
  invoice_number: string
  status: InvoiceStatus
  subtotal: number
  vat: number
  discount: number
  total: number
  tax_info: TaxInfo
  applied_vouchers: AppliedVoucher[]
  customer_snapshot: Record<string, unknown>
  notes: Record<string, unknown>
  metadata: Record<string, unknown>
  issued_at: string | null
  issued_by: string | null
  created_at: string
  updated_at: string
}
export interface PaymentRow {
  id: string
  branch_id: string
  invoice_id: string
  shift_id: string | null
  method: PaymentMethod
  revenue_type: RevenueType
  amount: number
  received_amount: number | null
  change_amount: number | null
  reference: string | null
  metadata: Record<string, unknown>
  paid_at: string
  received_by: string | null
  created_at: string
}
export interface VoucherRow {
  id: string
  branch_id: string
  code: string
  type: VoucherType
  value: number
  valid_from: string | null
  valid_until: string | null
  max_uses: number | null
  used_count: number
  is_active: boolean
  metadata: Record<string, unknown>
  created_by: string | null
  created_at: string
  updated_at: string
}
export interface ShiftRow {
  id: string
  branch_id: string
  user_id: string
  status: ShiftStatus
  opened_at: string
  closed_at: string | null
  opening_cash: number
  closing_cash: number | null
  expected_cash: number | null
  cash_difference: number | null
  notes: ShiftNotes
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface AuditEventRow {
  id: string
  branch_id: string
  actor_id: string | null
  action: string
  entity_type: string | null
  entity_id: string | null
  payload: Record<string, unknown>
  ip_address: string | null
  user_agent: string | null
  created_at: string
}
export interface NotificationRow {
  id: string
  branch_id: string
  channel: string
  recipient: string
  template: string
  variables: Record<string, unknown>
  status: string
  sent_at: string | null
  error_message: string | null
  metadata: Record<string, unknown>
  created_at: string
}
export interface BranchSettingRow {
  id: string
  branch_id: string
  key: string
  value: unknown
  value_type: 'string' | 'number' | 'boolean' | 'json' | 'array'
  description: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}
export interface SystemEventRow {
  id: string
  branch_id: string | null
  type: string
  payload: Record<string, unknown>
  created_at: string
}

export interface MenuCategory {
  id: string
  branch_id: string
  name: string
  i18n_name?: I18nString
  sort_order?: number
  is_active?: boolean
}

export interface Zone {
  id: string
  branch_id: string
  name: string
  color: string
}

export interface KPITarget {
  id: string
  branch_id: string
  period: string
  target_revenue: number
  metric_key?: string
  target_value?: number
  period_start?: string
  period_end?: string
  [k: string]: any
}

export interface MarketingCost {
  id: string
  branch_id: string
  channel: string
  cost: number
  period_start?: string
  period_end?: string
  [k: string]: any
}


type TableShape<Row, InsertT = Partial<Row>, UpdateT = Partial<Row>> = {
  Row: Row
  Insert: InsertT
  Update: UpdateT
  Relationships: any[]
}

export type Database = {
  public: {
    Tables: {
      branches: TableShape<BranchRow>
      users: TableShape<UserRow>
      tables: TableShape<TableRow>
      customers: TableShape<CustomerRow>
      menu_items: TableShape<MenuItemRow>
      packages: TableShape<PackageRow>
      reservations: TableShape<ReservationRow>
      orders: TableShape<OrderRow>
      order_items: TableShape<OrderItemRow>
      invoices: TableShape<InvoiceRow>
      payments: TableShape<PaymentRow>
      vouchers: TableShape<VoucherRow>
      shifts: TableShape<ShiftRow>
      audit_events: TableShape<AuditEventRow>
      notifications: TableShape<NotificationRow>
      branch_settings: TableShape<BranchSettingRow>
      system_events: TableShape<SystemEventRow>
    }
    Views: Record<string, never>
    Functions: {
      current_user_id: { Args: Record<string, never>; Returns: string }
      current_branch_id: { Args: Record<string, never>; Returns: string }
      has_role: { Args: { roles: UserRole[] }; Returns: boolean }
      revenue_by_hour: { Args: { p_branch_id: string, p_date: string }; Returns: any }
    }
    Enums: {
      user_role: UserRole
      table_status: TableStatus
      reservation_status: ReservationStatus
      order_status: OrderStatus
      invoice_status: InvoiceStatus
      payment_method: PaymentMethod
      shift_status: ShiftStatus
      package_type: PackageType
      revenue_type: RevenueType
      voucher_type: VoucherType
    }
  }
}

// Convenience aliases
export type AppUser = UserRow
export type Branch = BranchRow
export type TableT = TableRow
export type Customer = CustomerRow
export type MenuItem = MenuItemRow
export type Package = PackageRow
export type Reservation = ReservationRow
export type Order = OrderRow
export type OrderItem = OrderItemRow
export type Invoice = InvoiceRow
export type Payment = PaymentRow
export type Voucher = VoucherRow
export type Shift = ShiftRow
export type AuditEvent = AuditEventRow
export type Notification = NotificationRow
export type BranchSetting = BranchSettingRow
