import { createRouter, createWebHistory } from 'vue-router'

// ─── Layouts ──────────────────────────────────────────────────────────────────
import ManagerLayout from '@/layouts/ManagerLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import TabletLayout from '@/layouts/TabletLayout.vue'
import StaffLayout from '@/layouts/StaffLayout.vue'
import ReceptionLayout from '@/layouts/ReceptionLayout.vue'

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

const routes = [
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
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
