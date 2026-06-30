---

## PART 3 — COMPOSABLES

> Each composable lives in `src/composables/`. TypeScript signatures only — agents write the implementation following the same pattern as existing composables (`useInventory`, `useVoucher`, etc.).

### 3.1 `useReservation.ts`

```typescript
// Manages reservation CRUD for CRM and Hall roles

export function useReservation() {
  const reservations = ref<Reservation[]>([]);
  const stats        = ref<ReservationStats | null>(null);
  const loading      = ref(false);
  const { activeBranchId } = useBranchStore();

  // FETCH: paginated list with optional date filter
  async function listReservations(params?: {
    date?: string;    // ISO date string, default today
    status?: string;  // filter by status
    search?: string;  // search by guest_name or phone
  }): Promise<{ reservations: Reservation[]; total: number }>;

  // FETCH: today's stats (single RPC)
  async function fetchStats(date?: string): Promise<ReservationStats>;

  // CREATE: new reservation
  async function createReservation(input: {
    guest_name: string;
    guest_phone?: string;
    guest_count: number;
    reservation_date: string;
    reservation_time: string;
    package_type?: 'BUFFET' | 'A_LA_CARTE';
    source?: string;
    special_requests?: string;
    customer_id?: string;
    deposit_amount?: number;
  }): Promise<string>; // returns reservation_id

  // ACTION: confirm and assign table
  async function confirmReservation(
    reservationId: string,
    tableId: string,
    internalNotes?: string
  ): Promise<void>;

  // ACTION: customer arrived, start order
  async function seatReservation(reservationId: string): Promise<string>; // returns order_id

  // ACTION: mark no-show
  async function markNoShow(reservationId: string): Promise<void>;

  // ACTION: cancel
  async function cancelReservation(reservationId: string, reason?: string): Promise<void>;

  // REALTIME: subscribe to today's reservations changes
  function subscribeToReservations(date: string, callback: () => void): RealtimeChannel;

  return {
    reservations, stats, loading,
    listReservations, fetchStats, createReservation,
    confirmReservation, seatReservation, markNoShow, cancelReservation,
    subscribeToReservations
  };
}
```

---

### 3.2 `useServiceRequest.ts`

```typescript
export function useServiceRequest() {
  const openRequests = ref<ServiceRequest[]>([]);
  const { activeBranchId } = useBranchStore();

  // FETCH: all open/in-progress requests for the branch
  async function fetchOpenRequests(): Promise<ServiceRequest[]>;

  // CREATE: from tablet (no auth — calls RPC directly)
  async function createRequest(params: {
    branchId: string;
    tableId: string;
    type: 'CALL_WAITER' | 'REQUEST_BILL' | 'REQUEST_CONDIMENT' | 'COMPLAINT' | 'OTHER';
    orderId?: string;
    message?: string;
    priority?: 'NORMAL' | 'URGENT';
  }): Promise<string>; // request_id

  // ACTION: mark in progress (hall staff claims it)
  async function startHandling(requestId: string): Promise<void>;

  // ACTION: resolve
  async function resolveRequest(requestId: string): Promise<void>;

  // REALTIME: push notification to hall staff when new request comes in
  function subscribeToRequests(callback: (req: ServiceRequest) => void): RealtimeChannel;

  const urgentCount = computed(() =>
    openRequests.value.filter(r => r.priority === 'URGENT' && r.status === 'OPEN').length
  );

  return {
    openRequests, urgentCount,
    fetchOpenRequests, createRequest, startHandling, resolveRequest,
    subscribeToRequests
  };
}
```

---

### 3.3 `usePurchaseOrder.ts`

```typescript
export function usePurchaseOrder() {
  const purchaseOrders = ref<PurchaseOrder[]>([]);
  const { activeBranchId } = useBranchStore();

  // FETCH: list POs with optional status filter (one query with supplier join)
  async function listPurchaseOrders(params?: {
    status?: string;
    supplierId?: string;
    dateFrom?: string;
    dateTo?: string;
  }): Promise<PurchaseOrder[]>;
  // Single join query: select('*, supplier:supplier_id(name), items:purchase_order_items(*, ingredient:ingredient_id(name_vi,sku,unit))')

  // CREATE: from requisition or manual
  async function createPurchaseOrder(input: {
    supplierId: string;
    items: Array<{ ingredientId: string; orderedQuantity: number; unit: string; unitPrice: number }>;
    expectedDeliveryDate?: string;
    notes?: string;
    sourceRequisitionId?: string;
  }): Promise<string>; // po_id

  // ACTION: confirm delivery (receive goods)
  async function receiveOrder(
    poId: string,
    receivedItems: Array<{
      purchaseOrderItemId: string;
      receivedQuantity: number;
      expiryDate?: string;
    }>
  ): Promise<void>;

  // ACTION: cancel PO
  async function cancelPurchaseOrder(poId: string, reason?: string): Promise<void>;

  // COMPUTED: pending + partial orders count (for badge)
  const pendingCount = computed(() =>
    purchaseOrders.value.filter(po =>
      ['SUBMITTED','CONFIRMED_BY_SUPPLIER','PARTIAL'].includes(po.status)
    ).length
  );

  return {
    purchaseOrders, pendingCount,
    listPurchaseOrders, createPurchaseOrder, receiveOrder, cancelPurchaseOrder
  };
}
```

---

### 3.4 `useAccounting.ts`

```typescript
export function useAccounting() {
  const revenueReport  = ref<RevenueReport | null>(null);
  const expenseReport  = ref<ExpenseReport | null>(null);
  const plReport       = ref<PLReport | null>(null);
  const taxRecords     = ref<TaxRecord[]>([]);
  const loading        = ref(false);
  const { activeBranchId } = useBranchStore();

  // FETCH: revenue for date range (calls get_revenue_report RPC)
  async function fetchRevenue(dateFrom: string, dateTo: string): Promise<void>;

  // FETCH: expenses for date range (calls get_expense_report RPC)
  async function fetchExpenses(dateFrom: string, dateTo: string): Promise<void>;

  // FETCH: P&L (calls get_profit_loss RPC)
  async function fetchProfitLoss(dateFrom: string, dateTo: string): Promise<void>;

  // ACTION: generate + save tax record (calls generate_tax_record RPC)
  async function generateTaxRecord(
    periodType: 'DAILY' | 'MONTHLY' | 'QUARTERLY',
    periodStart: string,
    periodEnd: string
  ): Promise<string>; // tax_record_id

  // FETCH: list saved tax records
  async function listTaxRecords(year?: number): Promise<TaxRecord[]>;

  // ACTION: finalize a tax record (marks it FINALIZED)
  async function finalizeTaxRecord(id: string): Promise<void>;

  // FETCH: raw invoice list for a date range
  async function listInvoices(params?: {
    dateFrom?: string;
    dateTo?: string;
    paymentMethod?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ invoices: Invoice[]; total: number }>;

  // ACTION: void an invoice
  async function voidInvoice(invoiceId: string, reason: string): Promise<void>;

  return {
    revenueReport, expenseReport, plReport, taxRecords, loading,
    fetchRevenue, fetchExpenses, fetchProfitLoss,
    generateTaxRecord, listTaxRecords, finalizeTaxRecord,
    listInvoices, voidInvoice
  };
}
```

---

### 3.5 `useCampaign.ts`

```typescript
export function useCampaign() {
  const campaigns = ref<Campaign[]>([]);
  const { activeBranchId } = useBranchStore();
  const { id: userId }     = useAuthStore();

  // FETCH: list campaigns with voucher count (one join query)
  async function listCampaigns(statusFilter?: string[]): Promise<Campaign[]>;

  // CREATE: draft campaign
  async function createCampaign(input: {
    name: string; type: string; description?: string;
    startDate?: string; endDate?: string; budget?: number;
    targetSegment?: Record<string, unknown>;
    expectedImpact?: number; voucherIds?: string[];
  }): Promise<string>; // campaign_id

  // UPDATE: edit draft
  async function updateCampaign(id: string, patch: Partial<CampaignInput>): Promise<void>;

  // ACTION: submit for BOD approval
  async function submitForApproval(campaignId: string): Promise<string>; // bod_approval_id

  // ACTION: activate (if already approved by BOD)
  async function activateCampaign(campaignId: string): Promise<void>;

  // ACTION: pause/end
  async function pauseCampaign(campaignId: string): Promise<void>;

  // FETCH: campaign performance analytics
  async function getCampaignPerformance(campaignId: string): Promise<CampaignPerformance>;
  // = voucher usage count + total discount given + estimated revenue from campaign voucher holders

  return {
    campaigns,
    listCampaigns, createCampaign, updateCampaign,
    submitForApproval, activateCampaign, pauseCampaign,
    getCampaignPerformance
  };
}
```

---

### 3.6 `useBOD.ts`

```typescript
export function useBOD() {
  const dashboard    = ref<ExecutiveDashboard | null>(null);
  const approvals    = ref<BODApproval[]>([]);
  const kpiTargets   = ref<KPITarget[]>([]);
  const budgets      = ref<Budget[]>([]);
  const { activeBranchId } = useBranchStore();

  // FETCH: executive dashboard (calls get_executive_dashboard RPC)
  async function fetchDashboard(
    dateFrom: string,
    dateTo: string,
    branchId?: string  // null = all branches
  ): Promise<void>;

  // FETCH: pending BOD approvals
  async function fetchPendingApprovals(): Promise<void>;

  // ACTION: approve or reject a campaign/budget proposal
  async function reviewApproval(
    approvalId: string,
    campaignId: string,
    action: 'APPROVE' | 'REJECT',
    note?: string
  ): Promise<void>;

  // SET: KPI targets for a period
  async function setKPITarget(input: {
    branchId?: string;
    periodType: 'MONTHLY' | 'QUARTERLY' | 'ANNUAL';
    periodStart: string;
    periodEnd: string;
    revenueTarget?: number;
    breakevenPoint?: number;
    customerCountTarget?: number;
    avgSpendTarget?: number;
    repeatRateTarget?: number;
  }): Promise<string>;

  // SET: Budget allocation
  async function setBudget(input: {
    department: string;
    allocatedAmount: number;
    periodType: string;
    periodStart: string;
    periodEnd: string;
  }): Promise<string>;

  // FETCH: budget utilization
  async function fetchBudgets(periodStart?: string): Promise<Budget[]>;

  return {
    dashboard, approvals, kpiTargets, budgets,
    fetchDashboard, fetchPendingApprovals, reviewApproval,
    setKPITarget, setBudget, fetchBudgets
  };
}
```

---

### 3.7 `useFeedback.ts`

```typescript
export function useFeedback() {
  const feedbackList = ref<CustomerFeedback[]>([]);
  const { activeBranchId } = useBranchStore();

  // SUBMIT: from tablet (no auth)
  async function submitFeedback(input: {
    branchId: string; tableId: string;
    overallRating: number; foodRating?: number;
    serviceRating?: number; ambianceRating?: number;
    comment?: string; tags?: string[];
    orderId?: string; customerId?: string;
  }): Promise<string>;

  // FETCH: feedback list for CRM/manager view
  async function listFeedback(params?: {
    dateFrom?: string; dateTo?: string;
    minRating?: number; source?: string;
    limit?: number; offset?: number;
  }): Promise<{ items: CustomerFeedback[]; total: number; avgRating: number }>;

  // ACTION: staff responds to feedback
  async function respondToFeedback(
    feedbackId: string,
    response: string,
    respondedBy: string
  ): Promise<void>;

  // FETCH: summary stats (avg ratings by dimension)
  async function getFeedbackStats(dateFrom?: string, dateTo?: string): Promise<FeedbackStats>;

  return {
    feedbackList,
    submitFeedback, listFeedback, respondToFeedback, getFeedbackStats
  };
}
```

---

### 3.8 `useCheckout.ts` (NEW — wraps process_checkout)

```typescript
export function useCheckout() {
  const checkoutResult = ref<CheckoutResult | null>(null);
  const loading        = ref(false);
  const error          = ref<string | null>(null);
  const { id: cashierId } = useAuthStore();

  // VALIDATE: preview discount before confirming
  // (calls validate_voucher if code present, previews point value)
  async function previewCheckout(params: {
    orderId: string;
    voucherCode?: string;
    pointsToRedeem?: number;
    orderTotal: number;
    customerId?: string;
  }): Promise<CheckoutPreview>;

  // EXECUTE: the full atomic checkout
  async function executeCheckout(params: {
    orderId: string;
    paymentMethod: string;
    paymentRef?: string;
    voucherCode?: string;
    pointsToRedeem?: number;
    serviceChargePct?: number;
    vatPct?: number;
  }): Promise<CheckoutResult>;
  // Calls process_checkout RPC
  // On P0050: show "Order already checked out"
  // On P0010: show "Voucher no longer valid" + remove discount from preview
  // On P0022: show "Insufficient points"
  // On success: store result in checkoutResult.value

  // PRINT: open print dialog with receipt data
  function printReceipt(result: CheckoutResult): void;

  return {
    checkoutResult, loading, error,
    previewCheckout, executeCheckout, printReceipt
  };
}
```

---

## PART 4 — ROLE-BY-ROLE VIEWS

> For each role, agent creates the listed files. Layout follows existing project patterns (dark theme, Noto Serif JP headings, gold accents). All strings use `t('key')` from language store.

---

### 4.1 Hall Role — `src/views/hall/`

**Route prefix:** `/hall`  
**Role guard:** `requires: ['hall', 'manager', 'admin', 'superadmin']`

#### `HallDashboardView.vue`
- **Data fetched on mount:** floor plan (tables + their current status), open service requests count, today's reservation count
- **Layout:** Two-column: left = floor plan grid (table cards), right = service requests panel + quick stats
- **Table card states:** IDLE (dark gray), OCCUPIED (amber), WAITING_PAYMENT (gold pulsing), RESERVED (blue outline)
- **Table card click:** opens table detail slide-in → shows current order summary, customer info, option to process checkout
- **Realtime:** subscribe to `service_requests` (new alert), `tablet_sessions` (status change), `orders` (new or completed)
- **Composables:** `useServiceRequest`, `useTable` (existing), `useReservation`

#### `HallCheckoutView.vue`
- **Purpose:** Hall staff processes payment for a specific table/order
- **Data:** order items list, order total, customer info (if registered), current tier discount
- **Inputs:** voucher code field (with real-time preview via `validate_voucher`), points slider (if customer has points), payment method selector (CASH / CARD / ZALOPAY / MOMO)
- **Flow:**
  1. Load order by table_id or order_id
  2. Look up customer by phone if not already linked
  3. Voucher field: live validation on input → show discount preview (green chip)
  4. Points toggle: show max redeemable → input or slider
  5. "Proceed to Payment" → show totals breakdown (subtotal / discount / service charge / VAT / total)
  6. Confirm payment received → call `useCheckout.executeCheckout()`
  7. On success → show receipt with `points_earned`, tier upgrade notification (if any), print button
- **Composables:** `useCheckout`, `useCustomer`, `useVoucher`, `useMembership`

#### `HallServiceRequestView.vue`
- **Purpose:** Live incoming table service requests (call waiter, request bill, etc.)
- **Layout:** List/card feed, newest first, sorted by priority (URGENT on top with red badge)
- **Each card:** table number, request type icon, time elapsed since created, "Handle" / "Resolve" buttons
- **Realtime:** Subscribe to `service_requests` table — new rows push into list with vibrate/sound effect hint in UI comment
- **Composables:** `useServiceRequest`

#### `HallReservationView.vue`
- **Purpose:** Hall staff views today's reservations and seats arriving guests
- **Layout:** Tab strip: "Today | Tomorrow | Next 7 Days"
- **Stats bar at top:** Pending, Confirmed, Seated, No-show count (from `get_reservation_stats`)
- **Reservation list:** sorted by time, with status badge
- **Actions per row:** Confirm (+ assign table) | Seat Guest (opens order) | No-show
- **Composables:** `useReservation`, `useTable`

---

### 4.2 Purchasing Role — `src/views/purchasing/`

**Route prefix:** `/purchasing`  
**Role guard:** `requires: ['purchasing', 'manager', 'admin', 'superadmin']`

#### `PurchasingDashboardView.vue`
- **Data:** pending approved kitchen requisitions count, open POs count, recent PO activity
- **Layout:** Stats cards row → two panels: "Approved Requisitions to Process" | "Purchase Orders"
- **Key action:** Click "Convert to PO" on a requisition → pre-fills create PO form with items from requisition

#### `PurchasingRequisitionsView.vue`
- **Purpose:** View APPROVED kitchen requisitions waiting for a purchase order to be created
- **Filter tabs:** All Approved | Urgent (needed_by_date approaching)
- **Each row:** REQ number, items summary, needed_by_date, requester, "Create PO →" button
- **"Create PO" flow:** Select supplier → confirm unit prices → set expected delivery date → submit
- **Composables:** `useRequisition` (existing), `usePurchaseOrder`

#### `PurchasingOrdersView.vue`
- **Purpose:** All purchase orders management
- **Filter tabs:** Draft | Submitted | In Transit | Partially Received | Received | Cancelled
- **Each row:** PO number, supplier name, item count, total amount, expected delivery, status badge, "Receive Goods" button (visible if SUBMITTED or PARTIAL)
- **Create PO manually:** FAB button → slide panel → supplier selector → item table (add rows) → total calculation
- **Composables:** `usePurchaseOrder`

#### `PurchasingReceivingView.vue`
- **Purpose:** Confirm physical delivery of goods, which triggers inventory IN
- **Flow:**
  1. Select a PO (status = SUBMITTED or PARTIAL)
  2. For each line item: show "Ordered Qty | Received So Far | Receive Now" input
  3. Optional: set expiry dates per item
  4. Submit → calls `receiveOrder()` → shows inventory updated confirmation
- **Composables:** `usePurchaseOrder`, `useInventory` (existing)

---

### 4.3 Accounting Role — `src/views/accounting/`

**Route prefix:** `/accounting`  
**Role guard:** `requires: ['accounting', 'admin', 'superadmin']`

#### `AccountingDashboardView.vue`
- **Data on mount:** this month's revenue, expense, P&L; comparison vs last month; pending tax records
- **Layout:** KPI cards row (Revenue / Expenses / Gross Profit / Profit Margin %) → charts section → recent invoices
- **Charts:** Revenue vs Expense bar chart (daily breakdown from `daily_breakdown` field in revenue report)
- **Quick actions:** "Generate Tax Record" button → opens period selector modal

#### `AccountingRevenueView.vue`
- **Date range picker** (default: current month)
- **Summary cards:** Gross Revenue, Total Discounts, Service Charge, VAT Collected, Net
- **Invoice table:** sortable by amount, date; filterable by payment method; paginated
- **Export:** CSV download button → `exportInvoicesToCSV(invoices)`
- **Void Invoice:** button on each row → confirmation dialog → reason input → call `voidInvoice()`
- **Composables:** `useAccounting`

#### `AccountingExpenseView.vue`
- **Date range picker**
- **Summary cards:** Total Expenses, PO Count, By Supplier (top 5 chart), By Category
- **PO table:** each row links to full PO detail
- **Composables:** `useAccounting`, `usePurchaseOrder`

#### `AccountingTaxView.vue`
- **Purpose:** Generate, manage, and finalize VAT/tax records
- **Tab strip:** "Tax Records | VAT Configuration"
- **Tax Records tab:** list of saved records sorted by period; status badge (Draft / Finalized / Submitted)
  - Each row: period, gross revenue, VAT, total tax, "View" / "Finalize" / "Download" actions
  - "Generate New" → date picker → calls `generateTaxRecord()`
- **VAT Config tab:** read-only view of current service_charge_pct and vat_pct (editable by admin only)
- **Composables:** `useAccounting`

#### `AccountingReportView.vue`
- **Purpose:** P&L report generator and display
- **Controls:** Period selector (custom | MTD | QTD | YTD), Branch selector (admin)
- **Output sections:** Revenue Summary | Expense Summary | Gross Profit | By Category expense breakdown
- **All data from `get_profit_loss` RPC**
- **Export to PDF:** opens browser print dialog in landscape mode

---

### 4.4 CRM Role — `src/views/crm/`

**Route prefix:** `/crm`  
**Role guard:** `requires: ['crm', 'manager', 'admin', 'superadmin']`

> Note: CRM team largely shares views with Manager. Focus here is on the uniquely CRM views.

#### `CRMDashboardView.vue`
- **Data:** same as `ManagerCRMView.vue` (which should be refactored to use real data per Plan 2)
- **Extra CRM-specific widgets:** Today's reservations mini-summary, recent feedback average rating
- **Composables:** `useCustomer`, `useReservation`, `useFeedback`

#### `CRMReservationView.vue`
- **Full reservation management** (same as `HallReservationView.vue` but with more editing capabilities)
- **Extra actions:** Edit reservation details, add internal notes, link to existing customer record
- **Customer lookup:** "Link to Customer" → phone search → if found, associate customer_id with reservation
- **Composables:** `useReservation`, `useCustomer`

#### `CRMFeedbackView.vue`
- **Purpose:** View and respond to customer feedback
- **Filter:** date range + rating filter (show only 1-3 stars for issue tracking)
- **Stats at top:** Average overall, food, service, ambiance ratings; trend vs last month
- **Feedback cards:** rating stars, comment, tags, table, date; staff response field
- **Respond:** text field → "Reply" button → calls `respondToFeedback()`
- **Composables:** `useFeedback`

---

### 4.5 Marketing Role — `src/views/marketing/`

**Route prefix:** `/marketing`  
**Role guard:** `requires: ['marketing', 'admin', 'superadmin']`

#### `MarketingDashboardView.vue`
- **Data:** active campaigns count, vouchers issued this month, total discount given, new members this month
- **CRM data read-only access:** tier distribution chart, top customers list (read from existing CRM APIs)
- **Composables:** `useCampaign`, `useVoucher`, `useCustomer`

#### `MarketingCampaignView.vue`
- **List + CRUD for campaigns**
- **Filter tabs:** Draft | Pending Approval | Approved | Active | Ended | Rejected
- **Campaign card:** name, type badge, date range, budget, status badge, linked vouchers count
- **Create/Edit slide-in panel:**
  - Campaign name, type selector
  - Date range picker
  - Budget input
  - Target segment builder (tier chips, min_spent, min_visits, tags)
  - Expected revenue impact input
  - Attach Vouchers: multi-select from existing vouchers table
  - Submit as Draft or Submit for Approval
- **Submit for BOD:** button on DRAFT campaign → calls `submitForApproval()` → status changes to PENDING_APPROVAL → BOD badge increments
- **Composables:** `useCampaign`, `useVoucher`

#### `MarketingAnalyticsView.vue`
- **Purpose:** Read-only analytics view from CRM data
- **Charts:** Revenue trend (from `get_revenue_report`), New Members trend, Repeat Rate trend
- **Filter:** date range, branch
- **All data from existing accounting/CRM RPCs — no new APIs needed**
- **Composables:** `useAccounting`, `useCustomer`

---

### 4.6 BOD Role — `src/views/bod/`

**Route prefix:** `/bod`  
**Role guard:** `requires: ['bod', 'superadmin']`

#### `BODDashboardView.vue`
- **Data:** `get_executive_dashboard` RPC result
- **Layout:** Large KPI cards: Revenue vs Target (with progress bar to 2.5B), Gross Profit, Profit Margin, Is Above Breakeven (bold green/red indicator)
- **Pending approvals badge** → links to `BODApprovalView`
- **Period selector:** MTD | QTD | YTD | Custom
- **Branch selector:** All Branches | Individual branch
- **Composables:** `useBOD`

#### `BODApprovalView.vue`
- **Purpose:** Review and act on pending campaign/budget submissions from Marketing
- **List of pending approvals:** entity type, title, who submitted, when, budget/impact summary
- **Each item:** click → expand detail view showing full campaign metadata
- **Actions:** Approve (green button) | Reject (red, requires reason text)
- **Completed approvals tab:** historical log
- **Composables:** `useBOD`, `useCampaign`

#### `BODKPIView.vue`
- **Purpose:** Set and track KPI targets per branch and period
- **List of existing targets:** period, branch, revenue target, breakeven, actual vs target
- **Set new target:** form with period type, branch selector, revenue target (2,500,000,000), breakeven (1,500,000,000), customer count, avg spend, repeat rate
- **Progress bars:** actual vs target for current period
- **Composables:** `useBOD`

#### `BODBudgetView.vue`
- **Purpose:** Allocate departmental budgets and track spend
- **Table:** Department | Budget | Spent | Remaining | % Used
- **Spent column:** pulled from purchase orders (KITCHEN/PURCHASING dept) and campaign actual_spend (MARKETING dept)
- **Allocate:** form → department selector, amount, period → calls `setBudget()`
- **Composables:** `useBOD`, `usePurchaseOrder`

---

### 4.7 Tablet Role — Enhanced Views

> Additions to existing tablet flow.

#### `TabletServiceRequestView.vue`
- **Trigger:** Customer taps "Call Waiter" or "Request Bill" buttons in existing order flow
- **UI:** Bottom sheet popup with 4 large buttons: 🙋 Call Waiter | 🧾 Request Bill | 🧂 Request Condiments | 💬 Feedback
- **On tap:** calls `createRequest()` → shows "Request sent!" confirmation → auto-closes after 3s
- **Composables:** `useServiceRequest`

#### `TabletFeedbackView.vue`
- **Shown automatically when order is COMPLETED (tablet session status becomes IDLE after checkout)**
- **Star rating UI:** 5-star tap for overall, food, service, ambiance
- **Comment field:** optional multiline text
- **Tag chips:** pre-defined positive/negative tags ("Excellent service", "Too slow", "Delicious")
- **Submit → calls `submitFeedback()` → thank you screen → back to idle carousel**
- **Composables:** `useFeedback`

---

## PART 5 — ROUTER CONFIGURATION

```typescript
// src/router/index.ts — ADD these route groups

// ── Hall ─────────────────────────────────────────────────────
{
  path: '/hall',
  component: HallLayout,
  meta: { requiresRoles: ['hall','manager','admin','superadmin'] },
  children: [
    { path: '',          name: 'HallDashboard',      component: HallDashboardView },
    { path: 'checkout',  name: 'HallCheckout',        component: HallCheckoutView },
    { path: 'requests',  name: 'HallServiceRequests', component: HallServiceRequestView },
    { path: 'reservations', name: 'HallReservations', component: HallReservationView },
  ]
},
// ── Purchasing ───────────────────────────────────────────────
{
  path: '/purchasing',
  component: PurchasingLayout,
  meta: { requiresRoles: ['purchasing','manager','admin','superadmin'] },
  children: [
    { path: '',            name: 'PurchasingDashboard',    component: PurchasingDashboardView },
    { path: 'requisitions',name: 'PurchasingRequisitions', component: PurchasingRequisitionsView },
    { path: 'orders',      name: 'PurchasingOrders',       component: PurchasingOrdersView },
    { path: 'receiving',   name: 'PurchasingReceiving',    component: PurchasingReceivingView },
  ]
},
// ── Accounting ────────────────────────────────────────────────
{
  path: '/accounting',
  component: AccountingLayout,
  meta: { requiresRoles: ['accounting','admin','superadmin'] },
  children: [
    { path: '',        name: 'AccountingDashboard', component: AccountingDashboardView },
    { path: 'revenue', name: 'AccountingRevenue',   component: AccountingRevenueView },
    { path: 'expense', name: 'AccountingExpense',   component: AccountingExpenseView },
    { path: 'tax',     name: 'AccountingTax',       component: AccountingTaxView },
    { path: 'report',  name: 'AccountingReport',    component: AccountingReportView },
  ]
},
// ── CRM ───────────────────────────────────────────────────────
{
  path: '/crm',
  component: CRMLayout,
  meta: { requiresRoles: ['crm','manager','admin','superadmin'] },
  children: [
    { path: '',            name: 'CRMDashboard',    component: CRMDashboardView },
    { path: 'reservations',name: 'CRMReservations', component: CRMReservationView },
    { path: 'feedback',    name: 'CRMFeedback',     component: CRMFeedbackView },
    // Customer detail reuses existing composable, linked from list
  ]
},
// ── Marketing ─────────────────────────────────────────────────
{
  path: '/marketing',
  component: MarketingLayout,
  meta: { requiresRoles: ['marketing','admin','superadmin'] },
  children: [
    { path: '',          name: 'MarketingDashboard', component: MarketingDashboardView },
    { path: 'campaigns', name: 'MarketingCampaigns', component: MarketingCampaignView },
    { path: 'analytics', name: 'MarketingAnalytics', component: MarketingAnalyticsView },
  ]
},
// ── BOD ───────────────────────────────────────────────────────
{
  path: '/bod',
  component: BODLayout,
  meta: { requiresRoles: ['bod','superadmin'] },
  children: [
    { path: '',          name: 'BODDashboard', component: BODDashboardView },
    { path: 'approvals', name: 'BODApprovals', component: BODApprovalView },
    { path: 'kpi',       name: 'BODKpi',       component: BODKPIView },
    { path: 'budget',    name: 'BODBudget',    component: BODBudgetView },
  ]
},
// ── Tablet additions ──────────────────────────────────────────
// Add to existing tablet route group:
{ path: 'service',  name: 'TabletService',  component: TabletServiceRequestView },
{ path: 'feedback', name: 'TabletFeedback', component: TabletFeedbackView },
```

**Role guard middleware** (add to existing `router.beforeEach`):
```typescript
router.beforeEach((to, from, next) => {
  const auth  = useAuthStore();
  const roles = to.meta.requiresRoles as string[] | undefined;

  if (roles && !roles.includes(auth.userRole)) {
    return next({ name: 'Forbidden' });  // create a simple 403 view
  }
  // existing branch guard continues...
  next();
});
```

---

## PART 6 — DATA FLOWS

```
╔═══════════════════════════════════════════════════════════════╗
║  FLOW 1: Customer Dines → Revenue flows to Accounting         ║
╚═══════════════════════════════════════════════════════════════╝

[CUSTOMER]
  │ Books reservation via App/Phone
  ▼
[CRM] creates reservation (status=PENDING)
  │ Confirms table, assigns table_id (status=CONFIRMED)
  ▼
[HALL] customer arrives → seatReservation() → ORDER created (ACTIVE)
  │ Tablet session activated (status=ACTIVE)
  ▼
[CUSTOMER/TABLET] orders items → order_items inserted → Realtime push
  ▼
[KITCHEN] receives order via Realtime → prepares food
  ▼
[CUSTOMER/TABLET] taps "Request Bill" → service_request (type=REQUEST_BILL)
  ▼
[HALL] sees service request → opens HallCheckoutView for that table
  │ Optional: scan customer phone → lookup loyalty points + tier
  │ Optional: enter voucher code → live preview discount
  │ Optional: redeem loyalty points
  │ Select payment method → Confirm
  ▼
[process_checkout RPC] — ATOMIC —
  ├─ Creates INVOICE (with subtotal, discounts, tax, total)
  ├─ Increments voucher used_count
  ├─ Deducts redeemed points
  ├─ Updates order status → COMPLETED
  ├─ Resets tablet_session → IDLE
  ├─ Updates customer total_spent + total_visits
  └─ Earns loyalty points + triggers tier upgrade check
  ▼
[ACCOUNTING] Invoice visible in AccountingRevenueView → monthly VAT record


╔═══════════════════════════════════════════════════════════════╗
║  FLOW 2: Low Stock → Purchase → Expense recorded             ║
╚═══════════════════════════════════════════════════════════════╝

[KITCHEN] Inventory alert: stock < threshold (Realtime on inventory_stock)
  ▼
[KITCHEN] Creates REQUISITION (status=PENDING)
  ▼
[MANAGER/PURCHASING] Approves requisition (status=APPROVED)
  ▼
[PURCHASING] Creates PURCHASE ORDER from requisition
  │ createPurchaseOrder(source_requisition_id=X)
  │ Requisition status → PROCESSING
  ▼
[SUPPLIER] Delivers goods
  ▼
[PURCHASING] Confirms receipt → receiveOrder()
  ├─ Triggers create_inventory_transaction(type='IN') for each item
  ├─ inventory_stock updated (via trigger)
  ├─ PO status → RECEIVED
  └─ Requisition source status → COMPLETED
  ▼
[ACCOUNTING] PO visible in AccountingExpenseView → expense report


╔═══════════════════════════════════════════════════════════════╗
║  FLOW 3: Marketing Campaign → BOD Approval → Vouchers Live   ║
╚═══════════════════════════════════════════════════════════════╝

[MARKETING] Creates campaign draft
  │ Sets name, dates, budget, target segment
  │ Attaches vouchers (discount codes)
  │ Submits for BOD approval
  ▼
[BOD] bod_approvals entry created (status=PENDING)
  │ BOD dashboard shows pending badge
  ▼
[BOD] Reviews in BODApprovalView → APPROVE or REJECT
  │ If APPROVE: campaign status → APPROVED, linked vouchers is_active → TRUE
  │ If REJECT: campaign status → REJECTED, marketing sees rejection reason
  ▼
[MARKETING] Activates campaign → campaign status → ACTIVE
  ▼
[CUSTOMERS] Can now use the voucher codes at checkout (Hall checkout)


╔═══════════════════════════════════════════════════════════════╗
║  FLOW 4: Customer Reservation (Full)                         ║
╚═══════════════════════════════════════════════════════════════╝

[CUSTOMER/CRM] create_reservation(guest_name, date, time, guest_count)
  │ reservation_number auto-generated: RES-YYYYMMDD-NNNN
  │ status = PENDING
  ▼
[CRM/HALL] confirm_reservation(reservation_id, table_id)
  │ status = CONFIRMED, table_id assigned
  ▼
[HALL] Customer arrives
  │ seat_reservation(reservation_id)
  │ → ORDER created, tablet_session activated, reservation status = SEATED
  ▼
[Normal order flow continues → checkout → reservation status = COMPLETED]


╔═══════════════════════════════════════════════════════════════╗
║  FLOW 5: Tablet "Call Waiter" → Hall Alert                   ║
╚═══════════════════════════════════════════════════════════════╝

[CUSTOMER/TABLET] taps "Call Waiter"
  ▼
create_service_request(branch_id, table_id, type='CALL_WAITER')
  │ No auth required — public function
  ▼
[Realtime INSERT on service_requests fires]
  ▼
[HALL/HallDashboardView] receives Realtime event
  │ New card appears in service requests panel with table number
  │ Visual/audio alert in UI
  ▼
[HALL] clicks "Handle" → status = IN_PROGRESS
  ▼
[HALL] resolves → resolveRequest() → status = RESOLVED
  ▼
[CUSTOMER/TABLET] optional: sees "Help is on the way" message
  (achieved via Realtime subscription on service_requests by table_id)
```

---

## PART 7 — CHECKOUT ENHANCEMENT (Existing Reception/Hall View)

The existing `ReceptionCheckoutView.vue` (or equivalent) must be upgraded:

**Current state:** Static UI, calls checkout without full atomicity  
**Target state:** Uses `useCheckout.executeCheckout()` which calls `process_checkout` RPC

**Step-by-step migration:**
1. Replace direct invoice insert with `useCheckout.executeCheckout()`
2. Add voucher validation preview (call `validateVoucherAtCheckout` on input blur)
3. Add points redemption UI (if customer is loaded):
   - Show current points balance
   - Slider: 0 → max_redeemable points (capped at 50% of order total)
   - Live preview: "X points = -Yđ discount"
4. Totals breakdown section (show before final confirm):
   - Subtotal: Xđ
   - Tier Discount (-Y%): -Xđ
   - Voucher: -Xđ
   - Points: -Xđ
   - Net: Xđ
   - Service Charge (5%): +Xđ
   - VAT (10%): +Xđ
   - **Grand Total: Xđ** (bold, gold color)
5. Payment method selector: CASH | CARD | ZaloPay | MoMo | VNPay
6. Payment reference field (auto-hide for CASH)
7. "Process Payment" → loading state → show result:
   - Points earned: +Xđ
   - Tier upgrade notification (if `tier_upgraded = true`)
   - Print Receipt button
8. On error P0010 (voucher expired mid-flow): remove voucher, recalculate, notify cashier
9. On error P0022 (points insufficient): reset points to 0, notify cashier

---

## PART 8 — i18n ADDITIONS

> Add these keys to all three language objects in `useLanguageStore.ts`:

```typescript
// vi / en / ja (3-language object — vi shown; en/ja follow same keys)
{
  // Hall / Checkout
  'hall.title':              'Tiền Sảnh',
  'hall.dashboard':          'Bảng Điều Khiển',
  'hall.floor_plan':         'Sơ Đồ Bàn',
  'hall.service_requests':   'Yêu Cầu Phục Vụ',
  'hall.checkout':           'Thanh Toán',
  'checkout.subtotal':       'Tạm tính',
  'checkout.discount_tier':  'Ưu đãi hội viên',
  'checkout.discount_voucher':'Mã giảm giá',
  'checkout.discount_points':'Đổi điểm',
  'checkout.service_charge': 'Phụ thu dịch vụ',
  'checkout.vat':            'Thuế VAT',
  'checkout.grand_total':    'Tổng cộng',
  'checkout.payment_method': 'Phương thức thanh toán',
  'checkout.points_preview': '{points} điểm = -{amount}đ',
  'checkout.confirm':        'Xác nhận thanh toán',
  'checkout.success':        'Thanh toán thành công!',
  'checkout.receipt.print':  'In hóa đơn',
  // Service Requests
  'service.call_waiter':     'Gọi nhân viên',
  'service.request_bill':    'Yêu cầu thanh toán',
  'service.condiment':       'Yêu cầu gia vị',
  'service.complaint':       'Phản hồi',
  'service.open':            'Mới',
  'service.in_progress':     'Đang xử lý',
  'service.resolved':        'Đã xử lý',
  'service.urgent':          'Khẩn cấp',
  'service.sent':            'Yêu cầu đã được gửi!',
  // Reservations
  'reservation.title':       'Đặt Bàn',
  'reservation.create':      'Đặt bàn mới',
  'reservation.date':        'Ngày',
  'reservation.time':        'Giờ',
  'reservation.guests':      'Số khách',
  'reservation.status.pending':  'Chờ xác nhận',
  'reservation.status.confirmed':'Đã xác nhận',
  'reservation.status.seated':   'Đã vào bàn',
  'reservation.status.completed':'Hoàn thành',
  'reservation.status.no_show':  'Không đến',
  'reservation.confirm_table':   'Xác nhận bàn',
  'reservation.seat_now':        'Cho khách vào bàn',
  'reservation.no_show':         'Đánh dấu không đến',
  // Purchasing
  'purchasing.title':          'Mua Hàng',
  'purchasing.purchase_order': 'Đơn Đặt Hàng',
  'purchasing.po_number':      'Số PO',
  'purchasing.supplier':       'Nhà cung cấp',
  'purchasing.expected_delivery':'Ngày giao dự kiến',
  'purchasing.receive':        'Xác nhận nhận hàng',
  'purchasing.status.draft':   'Bản nháp',
  'purchasing.status.submitted':'Đã gửi',
  'purchasing.status.received':'Đã nhận',
  'purchasing.status.partial': 'Nhận một phần',
  // Accounting
  'accounting.title':          'Kế Toán',
  'accounting.revenue':        'Doanh Thu',
  'accounting.expense':        'Chi Phí',
  'accounting.profit_loss':    'Lợi Nhuận & Lỗ',
  'accounting.tax':            'Thuế',
  'accounting.gross_revenue':  'Doanh thu gộp',
  'accounting.net_revenue':    'Doanh thu thuần',
  'accounting.gross_profit':   'Lợi nhuận gộp',
  'accounting.profit_margin':  'Biên lợi nhuận',
  'accounting.vat_collected':  'VAT thu được',
  'accounting.generate_tax':   'Lập tờ khai thuế',
  'accounting.void_invoice':   'Hủy hóa đơn',
  // Campaigns
  'campaign.title':            'Chiến Dịch',
  'campaign.create':           'Tạo chiến dịch',
  'campaign.type.seasonal':    'Theo mùa',
  'campaign.type.loyalty':     'Khách thân thiết',
  'campaign.type.flash':       'Flash Sale',
  'campaign.status.draft':     'Bản nháp',
  'campaign.status.pending':   'Chờ phê duyệt',
  'campaign.status.approved':  'Đã phê duyệt',
  'campaign.status.active':    'Đang chạy',
  'campaign.submit_approval':  'Gửi phê duyệt',
  // BOD
  'bod.title':               'Ban Giám Đốc',
  'bod.dashboard':           'Tổng Quan',
  'bod.approvals':           'Phê Duyệt',
  'bod.kpi':                 'Chỉ Tiêu KPI',
  'bod.budget':              'Ngân Sách',
  'bod.revenue_target':      'Mục tiêu doanh thu',
  'bod.breakeven':           'Điểm hòa vốn',
  'bod.vs_target':           'Thực tế / Mục tiêu',
  'bod.approve':             'Phê duyệt',
  'bod.reject':              'Từ chối',
  // Feedback
  'feedback.title':          'Đánh Giá',
  'feedback.overall':        'Đánh giá tổng thể',
  'feedback.food':           'Chất lượng món ăn',
  'feedback.service':        'Chất lượng phục vụ',
  'feedback.ambiance':       'Không gian',
  'feedback.comment':        'Nhận xét',
  'feedback.submit':         'Gửi đánh giá',
  'feedback.thank_you':      'Cảm ơn bạn đã đánh giá!',
  'feedback.respond':        'Phản hồi',
}
```

> **English keys** follow same structure with English values.  
> **Japanese keys** follow same structure with Japanese values (ja).

---

## PART 9 — TESTING CHECKLIST

> Agent runs these scenarios after implementation to verify correctness. Each item should produce the stated outcome.

### DB Verification
```sql
-- Verify all new tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'reservations','service_requests','purchase_orders',
    'purchase_order_items','tax_records','campaigns',
    'campaign_vouchers','bod_approvals','kpi_targets',
    'budgets','customer_feedback'
  );
-- Expected: 11 rows

-- Verify all RPC functions exist
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'process_checkout','create_reservation','confirm_reservation',
    'seat_reservation','get_reservation_stats',
    'create_service_request','resolve_service_request',
    'create_purchase_order','receive_purchase_order',
    'get_revenue_report','get_expense_report','get_profit_loss',
    'generate_tax_record','create_campaign','submit_campaign_for_approval',
    'approve_reject_campaign','get_executive_dashboard',
    'record_customer_feedback'
  );
-- Expected: 18 rows
```

### Scenario Tests

| # | Scenario | Steps | Expected |
|---|---|---|---|
| T1 | Full checkout with voucher | Create order → add items ($500k) → enter valid 10% voucher → checkout with CASH → print | Invoice created: discount=$50k, vat=10%, grand_total=$405k |
| T2 | Concurrent voucher exhaustion | Set max_uses=1 → two cashiers redeem simultaneously | Only one succeeds; second gets "Voucher fully redeemed" error |
| T3 | Points earn + tier upgrade | Customer total_spent just below Gold tier ($4.9M) → checkout for $200k | Points earned; tier upgrades to Gold; response has `tier_upgraded: true` |
| T4 | Purchase order flow | Kitchen creates requisition → manager approves → purchasing creates PO → receive goods | inventory_stock increases by received qty; PO status=RECEIVED |
| T5 | Concurrent inventory depletion | 2kg of tuna remaining → two kitchens simultaneously try to take 1.5kg each | First succeeds; second gets INSUFFICIENT_STOCK error |
| T6 | Reservation seating | Create reservation → confirm with table_id → seat customer | Order created, tablet_session=ACTIVE, reservation=SEATED |
| T7 | Campaign approval | Marketing creates campaign → submits for BOD → BOD approves | Campaign=APPROVED, attached vouchers is_active=true |
| T8 | Revenue report accuracy | 3 invoices totaling $1.5M for today | get_revenue_report returns grand_total=$1.5M |
| T9 | P&L report | $2M revenue + $500k in POs received today | get_profit_loss returns gross_profit=$1.5M |
| T10 | Service request Realtime | Tablet submits "Call Waiter" → Hall dashboard open in another tab | New card appears in HallDashboard within 1 second |
| T11 | Void invoice | Create invoice → void it with reason | Invoice is_void=true; revenue report excludes it |
| T12 | BOD executive dashboard | Set KPI target $2.5B → actual revenue is $1.2B | Dashboard shows 48% of target; is_above_breakeven=false (if BEP=$1.5B) |
| T13 | Feedback submission | Customer submits 5-star review from tablet | Appears in CRMFeedbackView with correct ratings |
| T14 | Tax record generation | Run generate_tax_record for current month | Tax record created with correct VAT from sum of invoices |
| T15 | Role routing guard | User with role=kitchen tries to access /bod | Redirected to 403 Forbidden view |

### Realtime Subscriptions to Verify

| Channel | Trigger | Expected receiver |
|---|---|---|
| `service_requests` INSERT | Tablet calls createRequest | HallDashboard shows new card |
| `tablet_sessions` UPDATE | process_checkout sets status=IDLE | Tablet auto-returns to idle carousel |
| `inventory_stock` UPDATE | receive_purchase_order triggers inventory IN | KitchenInventoryView quantity increments |
| `orders` INSERT | seat_reservation creates order | Kitchen order board shows new order |
| `bod_approvals` INSERT | Marketing submits campaign | BOD badge increments |

---

## IMPLEMENTATION ORDER (for agent)

```
Step 1: Run Plan 1 SQL (inventory, requisitions, branches, kitchen)
Step 2: Run Plan 2 SQL (membership tiers, loyalty, vouchers patch)
Step 3: Run THIS plan SQL (Part 1 — patches + 11 new tables)
Step 4: Run ALL RPC functions (Part 2 — in order as listed)
Step 5: Create composables (Part 3 — 8 composables)
Step 6: Create layouts (HallLayout, PurchasingLayout, AccountingLayout, CRMLayout, MarketingLayout, BODLayout)
Step 7: Create views per role (Part 4 — in priority order: Hall → Purchasing → Accounting → CRM → Marketing → BOD → Tablet additions)
Step 8: Update router (Part 5)
Step 9: Enhance checkout view (Part 7)
Step 10: Add i18n keys (Part 8)
Step 11: Run test checklist (Part 9)
```

---

*End of MASTER IMPLEMENTATION PLAN*  
*Covers: 6 new roles + 11 new DB tables + 18 new RPC functions + 8 composables + ~25 new views*  
*Prior plans (Plan 1, Plan 2) must be applied before this one.*