export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];
// =============================================================================
// src/types/database.ts
// Hand-written mirror of docs/DATABASE_SCHEMA.sql (Refactored 2026-06-25)
// =============================================================================

// ─── Enums ──────────────────────────────────────────────────────────────────
export type UserRole = 'superadmin' | 'manager' | 'reception' | 'staff' | 'customer' | 'procurement_manager' | 'procurement_staff' | 'accountant' | 'crm_manager' | 'marketing'
export type TableStatus = 'available' | 'reserved' | 'occupied' | 'maintenance' | 'needs_cleaning'
export type ReservationStatus = 'Pending' | 'Arrived' | 'Dining' | 'Completed' | 'Cancelled'
export type OrderStatus = 'Pending' | 'Preparing' | 'Served' | 'Paid' | 'Cancelled'
export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'cancelled' | 'refunded'
export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
export type ShiftStatus = 'open' | 'closed'
export type PackageType = 'buffet' | 'set' | 'drink' | 'other'
export type RevenueType = 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
export type VoucherType = 'percent' | 'amount'
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]
export type CrmSurveyStatus = 'not_started' | 'assigned' | 'in_progress' | 'completed' | 'skipped' | 'customer_refused' | 'expired' | 'late_submitted'

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
  normalized_phone?: string | null
  email: string | null
  source_code?: string | null
  visit_reason?: string | null
  first_visit_at?: string | null
  marketing_consent?: boolean
  marketing_tags?: Json
  zalo?: string | null
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
  subcategory_id: string | null
  menu_categories?: { name: string }
  name: string
  i18n_name: I18nString
  description: string | null
  i18n_description: I18nString
  price: number
  cost: number | null
  unit: string
  price_display: string | null
  image_url: string | null
  is_available: boolean
  is_active: boolean
  sort_order: number
  modifiers: unknown[]
  tags: string[]
  nutrition: Record<string, unknown>
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}

export interface MenuSubcategoryRow {
  id: string
  branch_id: string
  category_id: string
  name: string
  sort_order: number
  is_active: boolean
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}

export interface PackageItemRow {
  id: string
  package_id: string
  menu_item_id: string
  item_limit: number | null
  sort_order: number
  is_active: boolean
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface PackageRow {
  id: string
  branch_id: string
  name: string
  type: PackageType
  price: number
  item_limit: number | null
  duration_minutes: number | null
  image_url: string | null
  is_active: boolean
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
  reservation_id: string | null
  table_id?: string | null
  customer_id?: string | null
  order_number: string
  status: OrderStatus
  guest_count?: number
  subtotal: number
  vat_rate: number
  vat: number
  discount?: number
  total: number
  notes: Record<string, unknown>
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface BillRow {
  id: string
  branch_id: string
  bill_code: string
  order_id: string | null
  table_id: string | null
  cashier_id: string | null
  sub_total: number
  discount_total: number
  vat_8_amount: number
  vat_10_amount: number
  grand_total: number
  payment_method: string | null
  status: 'OPEN' | 'PRINTED' | 'PAID' | 'VOID'
  created_at: string
}

export interface CrmSurveyRow {
  id: string
  branch_id: string
  table_id: string
  order_id: string | null
  table_assignment_id: string | null
  reservation_id: string | null
  bill_id: string | null
  customer_id: string | null
  source_code: string | null
  visit_reason: string | null
  feedback: string | null
  improvement_note: string | null
  customer_name: string | null
  customer_phone: string | null
  normalized_phone: string | null
  zalo: string | null
  marketing_consent: boolean
  tags: string[]
  note: string | null
  survey_status: CrmSurveyStatus
  asked_by: string | null
  asked_at: string | null
  submitted_at: string | null
  closed_at: string | null
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
  color?: 'yellow' | 'pink' | string | null
  metadata?: Record<string, unknown>
}

export interface MenuSubcategory {
  id: string
  branch_id: string
  category_id: string
  name: string
  sort_order: number
  is_active: boolean
  metadata?: Record<string, unknown>
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
      bod_approvals: {
        Row: {
          entity_id: string
          entity_type: string
          id: string
          metadata: Json | null
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          submitted_at: string | null
          submitted_by: string
          title: string | null
        }
        Insert: {
          entity_id: string
          entity_type: string
          id?: string
          metadata?: Json | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          submitted_at?: string | null
          submitted_by: string
          title?: string | null
        }
        Update: {
          entity_id?: string
          entity_type?: string
          id?: string
          metadata?: Json | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          submitted_at?: string | null
          submitted_by?: string
          title?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bod_approvals_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bod_approvals_submitted_by_fkey"
            columns: ["submitted_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      branches: TableShape<BranchRow>
      users: TableShape<UserRow>
      tables: TableShape<TableRow>
      customers: TableShape<CustomerRow>
      menu_categories: TableShape<MenuCategory>
      menu_subcategories: TableShape<MenuSubcategoryRow>
      menu_items: TableShape<MenuItemRow>
      packages: TableShape<PackageRow>
      package_items: TableShape<PackageItemRow>
      reservations: TableShape<ReservationRow>
      orders: TableShape<OrderRow>
      order_items: TableShape<OrderItemRow>
      bills: TableShape<BillRow>
      crm_surveys: TableShape<CrmSurveyRow>
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
export type MenuSub = MenuSubcategoryRow
export type Package = PackageRow
export type PackageItem = PackageItemRow
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
