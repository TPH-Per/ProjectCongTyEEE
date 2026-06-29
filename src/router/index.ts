import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { getFallbackRouteForRole } from '@/utils/route'

// ─── Layouts ──────────────────────────────────────────────────────────────────
import ManagerLayout from '@/layouts/ManagerLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import TabletLayout from '@/layouts/TabletLayout.vue'
import StaffLayout from '@/layouts/StaffLayout.vue'
import ReceptionLayout from '@/layouts/ReceptionLayout.vue'
import KitchenLayout from '@/layouts/KitchenLayout.vue'
import SuperadminLayout from '@/layouts/SuperadminLayout.vue'

// ─── Auth ─────────────────────────────────────────────────────────────────────
import LoginView from '@/views/LoginView.vue'
import SelectBranchView from '@/views/admin/SelectBranchView.vue'

// ─── Manager Views ──────────────────────────────────────────────────────────────
import ManagerDashboardView from '@/views/manager/ManagerDashboardView.vue'
import ManagerRevenueView from '@/views/manager/ManagerRevenueView.vue'
import ManagerCOGSView from '@/views/manager/ManagerCOGSView.vue'
import ManagerMarketingView from '@/views/manager/ManagerMarketingView.vue'
import ManagerCRMView from '@/views/manager/ManagerCRMView.vue'
import ManagerInventoryView from '@/views/manager/ManagerInventoryView.vue'

// ─── Admin Views ──────────────────────────────────────────────────────────────
import AdminDashboardView from '@/views/admin/AdminDashboardView.vue'
import AdminAccountsView from '@/views/admin/AdminAccountsView.vue'
import AdminMenusView from '@/views/admin/AdminMenusView.vue'
import AdminFloorsView from '@/views/admin/AdminFloorsView.vue'
import AdminKPIView from '@/views/admin/AdminKPIView.vue'
import AdminAuditView from '@/views/admin/AdminAuditView.vue'

// ─── Tablet Views ──────────────────────────────────────────────────────────────
import TabletIdleView from '@/views/tablet/TabletIdleView.vue'
import TabletLanguageView from '@/views/tablet/TabletLanguageView.vue'
import TabletOrderView from '@/views/tablet/TabletOrderView.vue'
import TabletCheckoutView from '@/views/tablet/TabletCheckoutView.vue'

// ─── Staff Views ──────────────────────────────────────────────────────────────
import StaffFloorPlanView from '@/views/staff/StaffFloorPlanView.vue'
import StaffOpenTableView from '@/views/staff/StaffOpenTableView.vue'
import StaffInDiningCRMView from '@/views/staff/StaffInDiningCRMView.vue'
import StaffActiveTablesView from '@/views/staff/StaffActiveTablesView.vue'

// ─── Reception Views ──────────────────────────────────────────────────────────
import ReceptionDashboardView from '@/views/reception/ReceptionDashboardView.vue'
import ReceptionCheckoutView from '@/views/reception/ReceptionCheckoutView.vue'
import ReceptionCloseShiftView from '@/views/reception/ReceptionCloseShiftView.vue'
import ReceptionOrderView from '@/views/reception/ReceptionOrderView.vue'

// ─── Kitchen Views ────────────────────────────────────────────────────────────
import KitchenKDSView from '@/views/kitchen/KitchenKDSView.vue'
import KitchenExpoView from '@/views/kitchen/KitchenExpoView.vue'
import KitchenRequisitionView from '@/views/kitchen/KitchenRequisitionView.vue'
import KitchenHandoverView from '@/views/kitchen/KitchenHandoverView.vue'
import KitchenInventoryView from '@/views/kitchen/KitchenInventoryView.vue'

// ─── Superadmin Views ─────────────────────────────────────────────────────────
import SuperadminDashboardView from '@/views/superadmin/SuperadminDashboardView.vue'
import SuperadminBrandsView from '@/views/superadmin/SuperadminBrandsView.vue'
import SuperadminIntegrationsView from '@/views/superadmin/SuperadminIntegrationsView.vue'

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
    redirect: '/manager/dashboard',
  },

  // ═══════════════════════════════════════════════════════════════
  // ADMIN PORTAL (Desktop — Role: System Admin)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/admin',
    component: AdminLayout,
    children: [
      {
        path: 'dashboard',
        name: 'admin-dashboard',
        component: AdminDashboardView,
      },
      {
        path: 'accounts',
        name: 'admin-accounts',
        component: AdminAccountsView,
      },
      {
        path: 'menus',
        name: 'admin-menus',
        component: AdminMenusView,
      },
      {
        path: 'floors',
        name: 'admin-floors',
        component: AdminFloorsView,
      },
      {
        path: 'kpi',
        name: 'admin-kpi',
        component: AdminKPIView,
      },
      {
        path: 'audit',
        name: 'admin-audit',
        component: AdminAuditView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // MANAGER PORTAL (Desktop — Role: Manager / Quản Lý)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/manager',
    component: ManagerLayout,
    children: [
      {
        path: 'dashboard',
        name: 'manager-dashboard',
        component: ManagerDashboardView,
      },
      {
        path: 'revenue',
        name: 'manager-revenue',
        component: ManagerRevenueView,
      },
      {
        path: 'cogs',
        name: 'manager-cogs',
        component: ManagerCOGSView,
      },
      {
        path: 'marketing',
        name: 'manager-marketing',
        component: ManagerMarketingView,
      },
      {
        path: 'crm',
        name: 'manager-crm',
        component: ManagerCRMView,
      },
      {
        path: 'inventory',
        name: 'manager-inventory',
        component: ManagerInventoryView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // RECEPTION POS (Desktop — Role: Thu Ngân / Cashier)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/reception',
    component: ReceptionLayout,
    children: [
      {
        path: 'dashboard',
        name: 'reception-dashboard',
        component: ReceptionDashboardView,
      },
      {
        path: 'checkout/:id',
        name: 'reception-checkout',
        component: ReceptionCheckoutView,
      },
      {
        path: 'close-shift',
        name: 'reception-close-shift',
        component: ReceptionCloseShiftView,
      },
      {
        path: 'floors',
        name: 'reception-floors',
        component: AdminFloorsView,
      },
      {
        path: 'order',
        name: 'reception-order',
        component: ReceptionOrderView,
        meta: { fullscreen: true },
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // STAFF APP (Mobile — Role: Nhân Viên / Waiter)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/staff',
    component: StaffLayout,
    children: [
      {
        path: 'floor-plan',
        name: 'staff-floor-plan',
        component: StaffFloorPlanView,
      },
      {
        path: 'active-tables',
        name: 'staff-active-tables',
        component: StaffActiveTablesView,
      },
      {
        path: 'table/:id/open',
        name: 'staff-open-table',
        component: StaffOpenTableView,
      },
      {
        path: 'table/:id/crm',
        name: 'staff-crm',
        component: StaffInDiningCRMView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // CUSTOMER TABLET (Tablet — Role: Khách Hàng / Guest)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/tablet',
    component: TabletLayout,
    children: [
      {
        path: 'idle',
        name: 'tablet-idle',
        component: TabletIdleView,
      },
      {
        path: 'language',
        name: 'tablet-language',
        component: TabletLanguageView,
      },
      {
        path: 'order',
        name: 'tablet-order',
        component: TabletOrderView,
      },
      {
        path: 'checkout',
        name: 'tablet-checkout',
        component: TabletCheckoutView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // KITCHEN KDS (Display — Role: Kitchen / Bếp)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/kitchen',
    component: KitchenLayout,
    children: [
      {
        path: 'kds',
        name: 'kitchen-kds',
        component: KitchenKDSView,
      },
      {
        path: 'expo',
        name: 'kitchen-expo',
        component: KitchenExpoView,
      },
      {
        path: 'requisition',
        name: 'kitchen-requisition',
        component: KitchenRequisitionView,
      },
      {
        path: 'handover',
        name: 'kitchen-handover',
        component: KitchenHandoverView,
      },
      {
        path: 'inventory',
        name: 'kitchen-inventory',
        component: KitchenInventoryView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // SUPERADMIN PORTAL (Desktop — Role: Enterprise Admin)
  // ═══════════════════════════════════════════════════════════════
  {
    path: '/superadmin',
    component: SuperadminLayout,
    children: [
      {
        path: 'dashboard',
        name: 'superadmin-dashboard',
        component: SuperadminDashboardView,
      },
      {
        path: 'brands',
        name: 'superadmin-brands',
        component: SuperadminBrandsView,
      },
      {
        path: 'integrations',
        name: 'superadmin-integrations',
        component: SuperadminIntegrationsView,
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

/**
 * Map URL prefix → set of roles allowed to enter that portal.
 * `admin` can always impersonate any portal (supervisor mode).
 */
const ROUTE_ROLES: Record<string, string[]> = {
  admin: ['admin'],
  superadmin: ['admin'],
  manager: ['admin', 'manager'],
  reception: ['admin', 'manager', 'reception'],
  staff: ['admin', 'manager', 'staff'],
  kitchen: ['admin', 'kitchen'],
  tablet: ['admin', 'manager', 'reception', 'staff'],
}

router.beforeEach(async (to) => {
  const { isAuthenticated, loading, role, isAdmin } = useAuth()

  // Wait for the initial session/profile fetch to finish.
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

  // Public routes.
  if (to.meta.requiresAuth === false) return

  // Must be signed in for everything else.
  if (!isAuthenticated.value) {
    return { name: 'login' }
  }

  // Branch null safety for admin/superadmin
  const { activeBranchId } = useBranch()
  const needsBranch = to.meta.requiresBranch ?? true
  if (needsBranch && !activeBranchId.value) {
    if (isAdmin.value && to.name !== 'SelectBranch') {
      return { name: 'SelectBranch' }
    }
  }

  const prefix = String(to.path.split('/')[1] ?? '')
  const allowed = ROUTE_ROLES[prefix]
  if (allowed && role.value && !allowed.includes(role.value)) {
    return getFallbackRouteForRole(role.value)
  }

  return
})

export default router
