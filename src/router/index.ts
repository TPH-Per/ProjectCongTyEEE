import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { getFallbackRouteForRole } from '@/utils/route'

// ─── Auth ─────────────────────────────────────────────────────────────────────
import LoginView from '@/views/LoginView.vue'
import SelectBranchView from '@/views/admin/SelectBranchView.vue'

// ─── 6 ROLES MVP LAYOUTS & VIEWS ──────────────────────────────────────────────

// 1. Admin
import AdminLayout from '@/layouts/AdminLayout.vue'
import AdminDashboardView from '@/views/admin/AdminDashboardView.vue'
import AdminAccountsView from '@/views/admin/AdminAccountsView.vue'
import AdminMenusView from '@/views/admin/AdminMenusView.vue'
import AdminFloorsView from '@/views/admin/AdminFloorsView.vue'

// 2. Hall (Tiền Sảnh + Phục vụ)
import StaffLayout from '@/layouts/StaffLayout.vue'
import StaffFloorPlanView from '@/views/staff/StaffFloorPlanView.vue'
import StaffOpenTableView from '@/views/staff/StaffOpenTableView.vue'
import ReceptionCheckoutView from '@/views/reception/ReceptionCheckoutView.vue'

// 3. Kitchen (Bếp)
import KitchenLayout from '@/layouts/KitchenLayout.vue'
import KitchenKDSView from '@/views/kitchen/KitchenKDSView.vue'

// 4. Purchasing (Mua Hàng / Kho)
import PurchasingLayout from '@/layouts/PurchasingLayout.vue'
import DailyReceiptView from '@/views/purchasing/DailyReceiptView.vue'
import InventoryAuditView from '@/views/purchasing/InventoryAuditView.vue'

// 5. Accounting (Kế Toán)
import AccountingLayout from '@/layouts/AccountingLayout.vue'
import InvoiceManagerView from '@/views/accounting/InvoiceManagerView.vue'
import TaxExportView from '@/views/accounting/TaxExportView.vue'

// 6. Customer (Tablet)
import TabletLayout from '@/layouts/TabletLayout.vue'
import TabletIdleView from '@/views/tablet/TabletIdleView.vue'
import TabletOrderView from '@/views/tablet/TabletOrderView.vue'
import TabletCheckoutView from '@/views/tablet/TabletCheckoutView.vue'


const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: LoginView,
    meta: { requiresAuth: false },
  },
  {
    path: '/select-branch',
    name: 'SelectBranch',
    component: SelectBranchView,
    meta: { requiresAuth: true, requiresBranch: false },
  },
  {
    path: '/',
    redirect: '/login',
  },

  // 1. ADMIN
  {
    path: '/admin',
    component: AdminLayout,
    children: [
      { path: 'dashboard', name: 'admin-dashboard', component: AdminDashboardView },
      { path: 'accounts', name: 'admin-accounts', component: AdminAccountsView },
      { path: 'menus', name: 'admin-menus', component: AdminMenusView },
      { path: 'floors', name: 'admin-floors', component: AdminFloorsView },
    ],
  },

  // 2. HALL
  {
    path: '/hall',
    component: StaffLayout,
    children: [
      { path: 'floor-plan', name: 'hall-floor-plan', component: StaffFloorPlanView },
      { path: 'table/:id/open', name: 'hall-open-table', component: StaffOpenTableView },
      { path: 'checkout/:id', name: 'hall-checkout', component: ReceptionCheckoutView },
    ],
  },

  // 3. KITCHEN
  {
    path: '/kitchen',
    component: KitchenLayout,
    children: [
      { path: 'kds', name: 'kitchen-kds', component: KitchenKDSView },
    ],
  },

  // 4. PURCHASING
  {
    path: '/purchasing',
    component: PurchasingLayout,
    children: [
      { path: 'receipts', name: 'purchasing-receipts', component: DailyReceiptView },
      { path: 'audit', name: 'purchasing-audit', component: InventoryAuditView },
    ],
  },

  // 5. ACCOUNTING
  {
    path: '/accounting',
    component: AccountingLayout,
    children: [
      { path: 'invoices', name: 'accounting-invoices', component: InvoiceManagerView },
      { path: 'tax', name: 'accounting-tax', component: TaxExportView },
    ],
  },

  // 6. CUSTOMER (TABLET)
  {
    path: '/tablet',
    component: TabletLayout,
    children: [
      { path: 'idle', name: 'tablet-idle', component: TabletIdleView },
      { path: 'order', name: 'tablet-order', component: TabletOrderView },
      { path: 'checkout', name: 'tablet-checkout', component: TabletCheckoutView },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const ROUTE_ROLES: Record<string, string[]> = {
  admin: ['admin'],
  hall: ['admin', 'hall'],
  kitchen: ['admin', 'kitchen'],
  purchasing: ['admin', 'purchasing'],
  accounting: ['admin', 'accounting'],
  tablet: ['admin', 'hall', 'customer'],
}

router.beforeEach(async (to) => {
  const { isAuthenticated, loading, role, isAdmin } = useAuth()

  if (loading.value) {
    await new Promise<void>((resolve) => {
      const check = setInterval(() => {
        if (!loading.value) {
          clearInterval(check)
          resolve()
        }
      }, 50)
    })
  }

  if (to.meta.requiresAuth === false) return

  if (!isAuthenticated.value) {
    return { name: 'login' }
  }

  const { activeBranchId } = useBranch()
  const needsBranch = to.meta.requiresBranch ?? true
  if (needsBranch && !activeBranchId.value) {
    if (isAdmin.value && to.name !== 'SelectBranch') {
      return { name: 'SelectBranch' }
    }
  }

  const prefix = String(to.path.split('/')[1] ?? '')
  const allowed = ROUTE_ROLES[prefix]
  
  // Normalize checking
  const currentRole = role.value === 'superadmin' || role.value === 'manager' ? 'admin' 
                    : role.value === 'reception' || role.value === 'staff' ? 'hall'
                    : role.value;

  if (allowed && currentRole && !allowed.includes(currentRole)) {
    return getFallbackRouteForRole(currentRole)
  }

  return
})

export default router
