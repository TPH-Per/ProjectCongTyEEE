// =============================================================================
// src/types/database.ts
// Hand-written mirror of docs/DATABASE_SCHEMA.sql (2026-06-22).
//
// Run `npx supabase gen types typescript --project-id <ref> --schema public`
// to regenerate from the live DB. Until then this file gives full type
// safety on the typed client: `createClient<Database>(url, key)`.
// =============================================================================

// ─── Enums ──────────────────────────────────────────────────────────────────
export type UserRole = 'admin' | 'manager' | 'reception' | 'staff' | 'kitchen'
export type TableStatus = 'available' | 'reserved' | 'occupied' | 'maintenance'
export type ReservationStatus =
  | 'Pending'
  | 'Arrived'
  | 'Dining'
  | 'Completed'
  | 'Cancelled'
export type OrderStatus =
  | 'Pending'
  | 'Preparing'
  | 'Served'
  | 'Paid'
  | 'Cancelled'
export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'cancelled' | 'refunded'
export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
export type ShiftStatus = 'open' | 'closed'
export type PackageType = 'buffet' | 'set' | 'drink' | 'other'
export type RevenueType = 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
export type VoucherType = 'percent' | 'amount'

// ─── Helpers (typed shortcuts for JSONB columns we read/write a lot) ───────
export interface CustomerSnapshot {
  name?: string
  phone?: string
  email?: string
  tax_code?: string
}

export interface PartySize {
  male: number
  female: number
  children: number
  age_bucket: string
  gender?: 'male' | 'female' | 'mixed'
  nationality?: 'local' | 'foreign'
}

export interface TableAssignmentMetadata {
  package_id?: string
  package_name_snapshot?: string
  package_type?: PackageType
  item_limit?: number
  duration_minutes?: number
  flow_mode?: 'one_way' | 'free'
  party_size?: PartySize
  demographics_capture?: PartySize
  checkout_acknowledged?: boolean
  [k: string]: unknown
}

export interface CustomerDemographics {
  gender?: 'male' | 'female' | 'mixed' | string
  age_bucket?: string
  nationality?: 'local' | 'foreign' | string
  [k: string]: unknown
}

export interface InvoiceMetadata {
  serial?: string
  template?: string
  xml_url?: string
  pdf_path?: string
  vt_invoice_id?: string
  vt_serial?: string
  vt_number?: string
  vt_status?: string
  notes?: string
  [k: string]: unknown
}

export interface ShiftNotes {
  handover_notes?: string
  incidents?: string
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
export interface ZoneRow {
  id: string
  branch_id: string
  name: string
  color: string | null
  sort_order: number
  is_active: boolean
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface TableRow {
  id: string
  branch_id: string
  zone_id: string
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
  preferences: Record<string, unknown>
  demographics: CustomerDemographics
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface MenuCategoryRow {
  id: string
  branch_id: string
  name: string
  sort_order: number
  is_active: boolean
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}
export interface MenuItemRow {
  id: string
  branch_id: string
  category_id: string
  name: string
  description: string | null
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
export interface PackageItemRow {
  package_id: string
  menu_item_id: string
  sort_order: number
  unit_price: number | null
  is_included: boolean
  created_at: string
}
export interface ReservationRow {
  id: string
  branch_id: string
  customer_id: string
  booking_code: string
  reservation_date: string
  reservation_time: string
  guests: number
  status: ReservationStatus
  source: string | null
  type: string | null
  customer_snapshot: CustomerSnapshot
  notes: Record<string, unknown>
  occasion: string | null
  decorations: Record<string, unknown>
  transport: string | null
  children_count: number
  expected_end: string | null
  metadata: Record<string, unknown>
  created_by: string | null
  arrived_at: string | null
  seated_at: string | null
  completed_at: string | null
  cancelled_at: string | null
  cancel_reason: string | null
  created_at: string
  updated_at: string
}
export interface TableAssignmentRow {
  id: string
  branch_id: string
  reservation_id: string | null
  table_id: string
  assigned_at: string
  released_at: string | null
  assigned_by: string | null
  metadata: TableAssignmentMetadata
}
export interface OrderRow {
  id: string
  branch_id: string
  reservation_id: string | null
  table_id: string | null
  customer_id: string | null
  order_number: string
  status: OrderStatus
  subtotal: number
  vat_rate: number
  vat: number
  discount: number
  total: number
  notes: Record<string, unknown>
  created_by: string | null
  served_by: string | null
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
  order_id: string
  invoice_number: string
  status: InvoiceStatus
  subtotal: number
  vat: number
  discount: number
  total: number
  tax_code: string | null
  customer_company: string | null
  customer_address: string | null
  customer_snapshot: CustomerSnapshot
  notes: Record<string, unknown>
  metadata: InvoiceMetadata
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
export interface VoucherRedemptionRow {
  id: string
  branch_id: string
  voucher_id: string
  invoice_id: string
  discount_amount: number
  redeemed_at: string
  redeemed_by: string | null
}
export interface DepositRow {
  id: string
  branch_id: string
  reservation_id: string
  amount: number
  method: PaymentMethod
  received_by: string | null
  reference: string | null
  received_at: string
  metadata: Record<string, unknown>
  created_at: string
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
export interface KPITargetRow {
  id: string
  branch_id: string | null
  metric_key: string
  target_value: number
  period_start: string
  period_end: string
  scope: 'branch' | 'group'
  notes: Record<string, unknown>
  created_by: string | null
  created_at: string
  updated_at: string
}
export interface MarketingCostRow {
  id: string
  branch_id: string
  channel: string
  period_start: string
  period_end: string
  amount: number
  notes: string | null
  metadata: Record<string, unknown>
  created_by: string | null
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
  reservation_id: string | null
  order_id: string | null
  invoice_id: string | null
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

// ─── Public schema definition for createClient<Database> ───────────────────
//
// We hand-author an Insert/Update shape per table so postgrest-js can keep
// strong typing on .insert() / .update() / .upsert().
//
// `RejectExcessProperties<Base, Row>` allows keys in `Base` (the Insert/Update
// shape) to accept either the typed value OR `never`, but anything missing from
// `Base` is `never`. We make every column a Partial<Row> which is the
// canonical typing Supabase itself generates. Anything in the Row type that is
// NOT in MakeInsert becomes a typing error — which is what we want.

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
      zones: TableShape<ZoneRow>
      tables: TableShape<TableRow>
      customers: TableShape<CustomerRow>
      menu_categories: TableShape<MenuCategoryRow>
      menu_items: TableShape<MenuItemRow>
      packages: TableShape<PackageRow>
      package_items: TableShape<PackageItemRow>
      reservations: TableShape<ReservationRow>
      table_assignments: TableShape<TableAssignmentRow>
      orders: TableShape<OrderRow>
      order_items: TableShape<OrderItemRow>
      invoices: TableShape<InvoiceRow>
      payments: TableShape<PaymentRow>
      vouchers: TableShape<VoucherRow>
      voucher_redemptions: TableShape<VoucherRedemptionRow>
      deposits: TableShape<DepositRow>
      shifts: TableShape<ShiftRow>
      kpi_targets: TableShape<KPITargetRow>
      marketing_costs: TableShape<MarketingCostRow>
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
      increment_customer_stats: {
        Args: { p_customer_id: string; p_total_spent: number }
        Returns: undefined
      }
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

// Convenience aliases used by composables.
export type AppUser = UserRow
export type Branch = BranchRow
export type Zone = ZoneRow
export type TableT = TableRow
export type Customer = CustomerRow
export type MenuCategory = MenuCategoryRow
export type MenuItem = MenuItemRow
export type Package = PackageRow
export type Reservation = ReservationRow
export type TableAssignment = TableAssignmentRow
export type Order = OrderRow
export type OrderItem = OrderItemRow
export type Invoice = InvoiceRow
export type Payment = PaymentRow
export type Voucher = VoucherRow
export type Shift = ShiftRow
export type KPITarget = KPITargetRow
export type MarketingCost = MarketingCostRow
export type AuditEvent = AuditEventRow
export type Notification = NotificationRow
export type BranchSetting = BranchSettingRow
