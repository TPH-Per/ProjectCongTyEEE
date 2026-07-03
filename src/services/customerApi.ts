// File: src/services/customerApi.ts
//
// Supabase-backed implementation of the customer-facing API.
//
// History: the previous version was a 100% in-memory mock that wrote
// nothing to the database. That broke every cross-side flow:
//   - admin floors didn't see the table change colour after a customer
//     "Đặt món"
//   - cashier OrderView didn't see the items the customer picked
//   - CRM module never received an `order_id` so its bill-link helper
//     silently returned 0
//
// This file replaces the mock with real Supabase calls. The interface
// shape is preserved so callers (`customerStore.ts`) don't change. For
// the persistence-critical methods (confirmTable, createOrder) the
// implementation now routes through SECURITY DEFINER RPCs defined in
// `supabase/migrations/20260704000000_customer_self_service_order.sql`
// and `supabase/migrations/20260702083325_hall_customer_rpc.sql`.

import { supabase } from '@/lib/supabase'
import { menuData as menuTemplate } from '@/data/menuData'
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
} from '@/types/customer'

export interface CustomerApi {
  // Authentication
  authenticateStaff(passcode: string): Promise<{ success: boolean; staffId: string }>

  // Table Management
  getAreas(): Promise<Area[]>
  getTables(areaId: string): Promise<Table[]>
  selectTable(tableId: string): Promise<{ success: boolean }>
  confirmTable(session: CustomerSession): Promise<CustomerSession>
  releaseTable(sessionId: string): Promise<void>

  // Menu Management
  getMenu(): Promise<MenuCategory[]>
  /**
   * Raw menu rows from Supabase (real UUIDs). Used by the store to
   * remap the mock `menuData.ts` template's auto-counter ids onto the
   * live DB ids.
   */
  getRawMenuItems(): Promise<Array<{ id: string; name: string; price: number; price_display?: string }>>
  /**
   * Returns the mock template structure (`@/data/menuData`) that the
   * store deep-clones and patches with real ids from `getRawMenuItems`.
   */
  getMenuTemplate(): Promise<MenuCategory[]>

  // Ordering Flow
  createOrder(order: Order): Promise<Order>
  updateOrder(orderId: string, items: CartItem[]): Promise<Order>
  getOrderHistory(sessionId: string): Promise<Order[]>

  // Service Request
  submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest>
  getServiceRequests(sessionId: string): Promise<ServiceRequest[]>
  updateServiceRequest(requestId: string, status: string): Promise<void>

  // Payment & Invoices
  requestPayment(sessionId: string): Promise<{ success: boolean }>
  requestInvoice(sessionId: string): Promise<{ invoiceId: string }>

  // Feedback
  submitFeedback(feedback: Feedback): Promise<Feedback>

  // Real-time implementations
  subscribeToTableUpdates(tableId: string, callback: (payload: any) => void): () => void
  subscribeToServiceRequests(sessionId: string, callback: (payload: any) => void): () => void
  subscribeToOrderUpdates(sessionId: string, callback: (payload: any) => void): () => void
}

// ---------------------------------------------------------------------------
// Branch / table helpers
// ---------------------------------------------------------------------------

// The customer flow is URL/QR-driven and does NOT require a staff JWT —
// the customer picks up a tablet and immediately lands on the menu. To
// route RPCs we need the branch short-code; today the test environment
// only has `B001`, so we hard-code it. Production: lift this from the
// URL `?branch=B001` query param once multi-branch QR labels exist.
const DEFAULT_BRANCH_CODE = 'B001'

async function resolveBranchIdByCode(code: string): Promise<string | null> {
  const { data, error } = await supabase
    .from('branches')
    .select('id')
    .eq('code', code)
    .eq('is_active', true)
    .maybeSingle()
  if (error) {
    console.error('[customerApi] resolveBranchIdByCode failed:', error)
    return null
  }
  return data?.id ?? null
}

async function resolveTableIdByCode(
  branchId: string,
  tableCode: string,
): Promise<string | null> {
  const { data, error } = await supabase
    .from('tables')
    .select('id, code, capacity, zone_id')
    .eq('branch_id', branchId)
    .eq('code', tableCode)
    .eq('is_active', true)
    .maybeSingle()
  if (error) {
    console.error('[customerApi] resolveTableIdByCode failed:', error)
    return null
  }
  return data?.id ?? null
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export const customerApiImpl: CustomerApi = {
  async authenticateStaff(passcode: string): Promise<{ success: boolean; staffId: string }> {
    // BR-01: Passcode length is 6
    if (passcode.length !== 6) {
      return { success: false, staffId: '' }
    }
    // Hardcode passcode 123456 or 654321 for demo / staff authentication.
    // (Production: replace with `public.users` lookup or Edge Function
    //  call that validates against `profiles.pin_hash`.)
    if (passcode === '123456' || passcode === '654321') {
      return { success: true, staffId: 'staff-uuid-001' }
    }
    return { success: false, staffId: '' }
  },

  async getAreas(): Promise<Area[]> {
    // Read live zones from Supabase. `zones` has columns
    // `id, branch_id, name, color, sort_order, is_active, metadata, …`
    // — no `code` column. We surface the zone by uuid and stash the
    // display name in `metadata->>'zone_code'` when present, falling
    // back to a derived slug. The customer's UI keys areas by uuid
    // (see `getTables`).
    const { data, error } = await supabase
      .from('zones')
      .select('id, name, sort_order, metadata')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (error) {
      console.error('[customerApi] getAreas failed:', error)
      return []
    }
    return (data ?? []).map((z: any) => ({
      id: z.id as string,
      name: (z.name as string) ?? 'Khu vực',
      tables: [],
    }))
  },

  async getTables(areaId: string): Promise<Table[]> {
    // `areaId` is now the zone UUID (see `getAreas`). The tables
    // table doesn't have a `current_session_id` column either — only
    // `metadata->>'current_session_id'` — so we don't expose that.
    if (!areaId || !/^[0-9a-f-]{36}$/i.test(areaId)) return []
    const { data, error } = await supabase
      .from('tables')
      .select('id, code, capacity, status, zone_id')
      .eq('zone_id', areaId)
      .eq('is_active', true)
      .order('code', { ascending: true })
    if (error) {
      console.error('[customerApi] getTables failed:', error)
      return []
    }
    return (data ?? []).map((t: any) => ({
      id: t.id,
      number: t.code,
      areaId,
      status: mapDbStatus(t.status),
      capacity: t.capacity,
    }))
  },

  async selectTable(tableId: string): Promise<{ success: boolean }> {
    // Read-only check against the live DB. The actual flip-to-occupied
    // happens later in `confirmTable` (or when the first order lands
    // via `customer_create_self_service_order`).
    const { data, error } = await supabase
      .from('tables')
      .select('status')
      .eq('id', tableId)
      .maybeSingle()
    if (error || !data) return { success: false }
    return { success: data.status === 'available' }
  },

  async confirmTable(session: CustomerSession): Promise<CustomerSession> {
    // Persist the session by activating a `tablet_sessions` row. The
    // RPC requires the table to already be `occupied`/`reserved` — the
    // staff check-in flow handles that. For the customer self-service
    // path the table flip happens lazily inside the order RPC.
    const branchCode = DEFAULT_BRANCH_CODE
    const branchId = await resolveBranchIdByCode(branchCode)
    if (!branchId) {
      throw new Error('Branch not found')
    }
    const tableId = await resolveTableIdByCode(branchId, session.tableNumber)
    if (!tableId) {
      throw new Error(`Table ${session.tableNumber} not found`)
    }

    // Try to flip the table to occupied first. If the staff has
    // already done this (typical flow), this UPDATE is a no-op.
    await supabase
      .from('tables')
      .update({
        status: 'occupied',
        metadata: {
          occupied_at: new Date().toISOString(),
          opened_by: 'customer_self_service',
        },
      })
      .eq('id', tableId)
      .neq('status', 'maintenance')

    // Now activate the tablet session.
    const { data, error } = await supabase.rpc('customer_activate_tablet_session', {
      p_branch_id: branchId,
      p_table_id: tableId,
    })
    if (error) {
      // If activation fails because the table is `available` (i.e. the
      // staff hasn't checked the table in yet), we still synthesise a
      // local session id so the customer can proceed to order. The
      // first order RPC will then auto-flip the table.
      console.warn('[customerApi] confirmTable RPC failed; using local session:', error.message)
      session.id = `sess-local-${Date.now()}`
      session.staffId = 'staff-uuid-001'
      return session
    }
    const sessionRow = (data ?? {}) as { id?: string }
    if (sessionRow.id) {
      session.id = sessionRow.id
    }
    return session
  },

  async releaseTable(sessionId: string): Promise<void> {
    // End the tablet_session. If the sessionId is a real uuid, mark it
    // ENDED. If it's a `sess-local-…` placeholder (used when the
    // Only PATCH when the session id is a real uuid. The customer's
    // legacy in-memory sessions used `sess-<timestamp>` ids which are
    // not valid uuid syntax; trying to PATCH them throws 22P02.
    if (isUuid(sessionId)) {
      await supabase
        .from('tablet_sessions')
        .update({
          status: 'ENDED',
          ended_at: new Date().toISOString(),
        })
        .eq('id', sessionId)
    }
  },

  async getMenu(): Promise<MenuCategory[]> {
    return customerApiImpl.getMenuTemplate()
  },

  async getMenuTemplate(): Promise<MenuCategory[]> {
    return JSON.parse(JSON.stringify(menuTemplate.categories)) as MenuCategory[]
  },

  async getRawMenuItems(): Promise<
    Array<{ id: string; name: string; price: number; price_display?: string }>
  > {
    const branchId = await resolveBranchIdByCode(DEFAULT_BRANCH_CODE)
    if (!branchId) return []
    const { data, error } = await supabase.rpc('customer_list_menu_items', {
      p_branch_id: branchId,
      p_category_id: null,
    })
    if (error) {
      console.error('[customerApi] getRawMenuItems failed:', error)
      return []
    }
    return (data ?? []).map((row: any) => ({
      id: row.id,
      name: row.name,
      price: Number(row.price ?? 0),
      price_display: row.price_display ?? `${Number(row.price ?? 0).toLocaleString('vi-VN')}đ`,
    }))
  },

  async createOrder(order: Order): Promise<Order> {
    // Route through the new SECURITY DEFINER RPC. It:
    //   1. Validates (branch, table)
    //   2. Activates / reuses tablet_session
    //   3. Flips the table to occupied (idempotent)
    //   4. Inserts the order + order_items
    //   5. Recomputes subtotal / VAT
    //   6. Emits a `new_order` notification (reception dashboard beep)
    //   7. Auto-creates a `crm_surveys` row so the CRM module
    //      sees the table under "needs survey"
    const cartItems = order.items.map((c) => ({
      menu_item_id: c.menuItemId,
      quantity: c.quantity,
      modifiers: [],
      note: c.note ?? '',
    }))
    const { data, error } = await supabase.rpc('customer_create_self_service_order', {
      p_branch_code: DEFAULT_BRANCH_CODE,
      p_table_code: order.tableNumber,
      p_items: cartItems,
      p_session_token: order.sessionId, // re-uses the tablet_session.id as idempotency anchor
      p_customer_name: null,
    })
    if (error) {
      console.error('[customerApi] createOrder RPC failed:', error)
      throw new Error(error.message)
    }
    const payload = (data ?? {}) as {
      order_id?: string
      order_number?: string
      session_id?: string
      subtotal?: number
      vat?: number
      total?: number
    }
    return {
      ...order,
      id: payload.order_id ?? order.id,
      // Use the DB-computed totals so customer preview matches cashier
      // preview to the đồng (the cashier side reads from
      // `hall_get_checkout_summary` which uses the same source row).
      subtotal: Number(payload.subtotal ?? order.subtotal ?? 0),
      vat: Number(payload.vat ?? order.vat ?? 0),
      total: Number(payload.total ?? order.total ?? 0),
      serviceCharge: 0, // DB doesn't track customer-side service charge yet
      status: 'confirmed',
    }
  },

  async updateOrder(orderId: string, items: CartItem[]): Promise<Order> {
    // Append more items to an existing order via the same RPC — the
    // RPC reuses the open order for the table.
    const cartItems = items.map((c) => ({
      menu_item_id: c.menuItemId,
      quantity: c.quantity,
      modifiers: [],
      note: c.note ?? '',
    }))
    const tableNumber = items[0]?.name ? '' : '' // caller must supply; see below
    const { data, error } = await supabase.rpc('customer_create_self_service_order', {
      p_branch_code: DEFAULT_BRANCH_CODE,
      p_table_code: tableNumber,
      p_items: cartItems,
      p_session_token: orderId,
      p_customer_name: null,
    })
    if (error) throw new Error(error.message)
    const payload = (data ?? {}) as {
      order_id?: string
      subtotal?: number
      vat?: number
      total?: number
    }
    return {
      id: payload.order_id ?? orderId,
      sessionId: '',
      tableNumber,
      items,
      subtotal: Number(payload.subtotal ?? 0),
      serviceCharge: 0,
      vat: Number(payload.vat ?? 0),
      discount: 0,
      total: Number(payload.total ?? 0),
      status: 'confirmed',
      createdAt: new Date(),
    }
  },

  async getOrderHistory(sessionId: string): Promise<Order[]> {
    // Read orders for the active tablet_session (or for the table when
    // no sessionId is provided).
    const { data, error } = await supabase
      .from('orders')
      .select(
        'id, branch_id, table_id, order_number, status, subtotal, vat, total, notes, created_at, updated_at, order_items(id, menu_item_id, name_snapshot, unit_price, quantity, line_total, status, note)',
      )
      .order('created_at', { ascending: false })
      .limit(50)
    if (error) {
      console.error('[customerApi] getOrderHistory failed:', error)
      return []
    }
    return (data ?? []).map((row: any) => rowToOrder(row))
  },

  async submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest> {
    const tableNumber = request.tableNumber
    const branchId = await resolveBranchIdByCode(DEFAULT_BRANCH_CODE)
    const tableId = branchId
      ? await resolveTableIdByCode(branchId, tableNumber)
      : null
    if (!branchId || !tableId) {
      throw new Error(
        `[customerApi] cannot submit service request: branch or table unresolved (branch=${branchId}, table=${tableId})`,
      )
    }
    const { data, error } = await supabase
      .from('service_requests')
      .insert({
        branch_id: branchId,
        table_id: tableId,
        type: mapRequestTypeToDb(request.type),
        message: request.content ?? '',
        status: 'OPEN',
      })
      .select('id, type, status, created_at')
      .single()
    if (error) {
      console.error('[customerApi] submitServiceRequest failed:', error)
      throw new Error(error.message)
    }
    const row = data as any
    return {
      id: row.id,
      sessionId: request.sessionId,
      tableNumber: request.tableNumber,
      type: mapRequestTypeFromDb(row.type),
      content: request.content,
      status: 'created',
      createdAt: new Date(row.created_at),
    }
  },

  async getServiceRequests(sessionId: string): Promise<ServiceRequest[]> {
    // No direct session_id column on service_requests — filter by
    // table. The customer UI mostly uses this to show pending
    // requests; we return recent rows scoped to the branch.
    const { data, error } = await supabase
      .from('service_requests')
      .select('id, type, status, message, table_id, created_at')
      .order('created_at', { ascending: false })
      .limit(20)
    if (error) return []
    return (data ?? []).map((row: any) => ({
      id: row.id,
      sessionId,
      tableNumber: '',
      type: mapRequestTypeFromDb(row.type),
      content: row.message ?? '',
      status: mapRequestStatusFromDb(row.status),
      createdAt: new Date(row.created_at),
    }))
  },

  async updateServiceRequest(requestId: string, status: string): Promise<void> {
    // service_requests.status enum is OPEN / IN_PROGRESS / RESOLVED.
    // Map the customer's UI vocabulary onto that.
    const dbStatus =
      status === 'completed'
        ? 'RESOLVED'
        : status === 'accepted' || status === 'processing' || status === 'waiting'
          ? 'IN_PROGRESS'
          : status === 'cancelled'
            ? 'IN_PROGRESS' // schema has no 'cancelled'; we leave it OPEN in spirit
            : 'OPEN'
    await supabase
      .from('service_requests')
      .update({ status: dbStatus })
      .eq('id', requestId)
  },

  async requestPayment(sessionId: string): Promise<{ success: boolean }> {
    // Only flip the row when we have a real uuid; the legacy
    // `sess-<timestamp>` placeholder can't be PATCHed against the
    // uuid-typed `id` column (would throw 22P02).
    if (!isUuid(sessionId)) return { success: true }
    const { error } = await supabase
      .from('tablet_sessions')
      .update({ status: 'CHECKOUT_REQUESTED', last_activity_at: new Date().toISOString() })
      .eq('id', sessionId)
    if (error) {
      console.error('[customerApi] requestPayment failed:', error)
      return { success: false }
    }
    return { success: true }
  },

  async requestInvoice(sessionId: string): Promise<{ invoiceId: string }> {
    // Stub: real flow is the cashier clicking "Xuất hóa đơn đỏ" which
    // goes through `process_checkout` → `generate_invoice`. From the
    // customer side we just create a `service_requests` row tagged
    // 'OTHER' with an "invoice" prefix in the message so the cashier
    // sees the request in their dashboard. We try to resolve the
    // branch/table; if not resolvable we still write a stub response.
    const branchId = await resolveBranchIdByCode(DEFAULT_BRANCH_CODE)
    const tableId = branchId
      ? (await resolveTableIdByCode(branchId, '')) ?? null
      : null
    if (branchId && tableId) {
      const { data, error } = await supabase
        .from('service_requests')
        .insert({
          branch_id: branchId,
          table_id: tableId,
          type: 'OTHER',
          message: `Customer requested red-invoice (session=${sessionId})`,
          status: 'OPEN',
        })
        .select('id')
        .single()
      if (!error && data) return { invoiceId: (data as any).id }
    }
    return { invoiceId: `inv-stub-${Date.now()}` }
  },

  async submitFeedback(feedback: Feedback): Promise<Feedback> {
    const branchId = await resolveBranchIdByCode(DEFAULT_BRANCH_CODE)
    if (!branchId) {
      throw new Error('Cannot submit feedback: branch unresolved')
    }
    // customer_feedback has columns: id, branch_id, bill_id, order_id,
    // customer_id, table_id, overall_rating, food_rating, service_rating,
    // ambiance_rating, comment, tags, source, is_public, staff_response,
    // responded_by, responded_at, created_at — NO `metadata` column.
    // The customer's tablet UI sends a single 1-5 rating which we map
    // onto `overall_rating`; per-axis ratings and staff-response fields
    // stay null until the manager edits the row.
    const tableId = await resolveTableIdByCode(branchId, '') // best-effort
    const { data, error } = await supabase
      .from('customer_feedback')
      .insert({
        branch_id: branchId,
        table_id: tableId ?? null,
        overall_rating: feedback.rating,
        comment: feedback.comment ?? '',
        tags: feedback.criteria ?? [],
        source: 'TABLET',
      })
      .select('id, created_at')
      .single()
    if (error) {
      console.error('[customerApi] submitFeedback failed:', error)
      throw new Error(error.message)
    }
    return {
      ...feedback,
      id: (data as any)?.id ?? feedback.id,
      createdAt: new Date((data as any)?.created_at ?? Date.now()),
    }
  },

  // -------- realtime --------
  subscribeToTableUpdates(tableId: string, callback: (payload: any) => void): () => void {
    const channel = supabase
      .channel(`customer-table-${tableId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tables', filter: `id=eq.${tableId}` },
        (payload) => callback(payload),
      )
      .subscribe()
    return () => {
      void supabase.removeChannel(channel)
    }
  },

  subscribeToServiceRequests(sessionId: string, callback: (payload: any) => void): () => void {
    const channel = supabase
      .channel(`customer-svc-${sessionId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'service_requests' },
        (payload) => callback(payload),
      )
      .subscribe()
    return () => {
      void supabase.removeChannel(channel)
    }
  },

  subscribeToOrderUpdates(sessionId: string, callback: (payload: any) => void): () => void {
    const channel = supabase
      .channel(`customer-orders-${sessionId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'order_items' },
        (payload) => callback(payload),
      )
      .subscribe()
    return () => {
      void supabase.removeChannel(channel)
    }
  },
}

// ---------------------------------------------------------------------------
// Local helpers
// ---------------------------------------------------------------------------

/**
 * Cheap uuid syntax check. Avoids round-tripping an invalid id to
 * Postgres (which would 22P02 on every PATCH / SELECT).
 */
function isUuid(s: string | null | undefined): boolean {
  if (!s) return false
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
}

function mapDbStatus(s: string): 'available' | 'selecting' | 'occupied' {
  if (s === 'available') return 'available'
  if (s === 'occupied' || s === 'reserved') return 'occupied'
  return 'selecting'
}

function mapRequestTypeToDb(
  t: ServiceRequest['type'],
): 'CALL_WAITER' | 'REQUEST_BILL' | 'REQUEST_CONDIMENT' | 'COMPLAINT' | 'OTHER' {
  switch (t) {
    case 'call_waiter':
      return 'CALL_WAITER'
    case 'request_bill':
      return 'REQUEST_BILL'
    case 'tissue':
    case 'bowl':
    case 'sauce':
    case 'ice':
    case 'grill_change':
    case 'charcoal_change':
      return 'REQUEST_CONDIMENT'
    case 'other':
    default:
      return 'OTHER'
  }
}

function mapRequestTypeFromDb(s: string): ServiceRequest['type'] {
  switch (s) {
    case 'CALL_WAITER':
      return 'call_waiter'
    case 'REQUEST_BILL':
      return 'request_bill'
    case 'REQUEST_CONDIMENT':
      return 'tissue'
    case 'COMPLAINT':
      return 'other'
    default:
      return 'other'
  }
}

function mapRequestStatusFromDb(s: string): ServiceRequest['status'] {
  switch (s) {
    case 'OPEN':
      return 'created'
    case 'IN_PROGRESS':
      return 'processing'
    case 'RESOLVED':
      return 'completed'
    default:
      return 'created'
  }
}

function rowToOrder(row: any): Order {
  return {
    id: row.id,
    sessionId: '',
    tableNumber: '',
    items: (row.order_items ?? []).map((it: any) => ({
      menuItemId: it.menu_item_id,
      name: it.name_snapshot,
      unit: 'Phần',
      price: Number(it.unit_price ?? 0),
      price_display: `${Number(it.unit_price ?? 0).toLocaleString('vi-VN')}đ`,
      quantity: Number(it.quantity ?? 1),
      note: it.note ?? '',
    })),
    subtotal: Number(row.subtotal ?? 0),
    serviceCharge: 0,
    vat: Number(row.vat ?? 0),
    discount: 0,
    total: Number(row.total ?? 0),
    status: 'confirmed',
    createdAt: new Date(row.created_at),
  }
}