import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
} from "vue-router";
import { useAuth } from "@/composables/useAuth";
import { useBranch } from "@/composables/useBranch";
import { getFallbackRouteForRole } from "@/utils/route";

// ─── Layouts ───────────────────────────────────
import ManagerLayout from "@/layouts/ManagerLayout.vue";
import AdminLayout from "@/layouts/AdminLayout.vue";
import ReceptionLayout from "@/layouts/ReceptionLayout.vue";
import CustomerLayout from "@/layouts/CustomerLayout.vue";
import ReportsView from "@/views/reception/ReportsView.vue";
import RevenueOverviewView from "@/views/reception/RevenueOverviewView.vue";
import ShiftHandoverView from "@/views/reception/ShiftHandoverView.vue";
import InventoryView from "@/views/reception/InventoryView.vue";
import ProcessItemsView from "@/views/reception/ProcessItemsView.vue";

// ─── Auth ─────────────────────────────────────────────────────────────────────
import LoginView from "@/views/LoginView.vue";
import SelectBranchView from "@/views/admin/SelectBranchView.vue";

// ─── Admin Views ──────────────────────────────────────────────────────────────
import AdminDashboardView from "@/views/admin/AdminDashboardView.vue";
import AdminAccountsView from "@/views/admin/AdminAccountsView.vue";
import AdminMenusView from "@/views/admin/AdminMenusView.vue";
import AdminFloorsView from "@/views/admin/AdminFloorsView.vue";
import AdminKPIView from "@/views/admin/AdminKPIView.vue";
import AdminAuditView from "@/views/admin/AdminAuditView.vue";
import AdminVoucherView from "@/views/admin/AdminVoucherView.vue";

// ─── Staff/Hall Views (used by Reception) ─────────────────────────────────────────────────────────
import ReceptionCheckoutView from "@/views/reception/ReceptionCheckoutView.vue";
import ReceptionDashboardView from "@/views/reception/ReceptionDashboardView.vue";
import ReceptionCloseShiftView from "@/views/reception/ReceptionCloseShiftView.vue";
import ShiftSummaryView from "@/views/reception/ShiftSummaryView.vue";
import ReceptionOrderView from "@/views/reception/ReceptionOrderView.vue";
import MenuManagementView from "@/views/reception/MenuManagementView.vue";

// ─── Manager Views ────────────────────────────────────────────────────────────
import ManagerDashboardView from "@/views/manager/ManagerDashboardView.vue";
import ManagerRevenueView from "@/views/manager/ManagerRevenueView.vue";
import ManagerCOGSView from "@/views/manager/ManagerCOGSView.vue";
import ManagerMarketingView from "@/views/manager/ManagerMarketingView.vue";
import ManagerCRMView from "@/views/manager/ManagerCRMView.vue";
import ManagerInventoryView from "@/views/manager/ManagerInventoryView.vue";

// Removed unused view imports

// ─── Customer Views ──────────────────────────────────────────────────────────────
import CustomerHome from "@/views/customer/CustomerHome.vue";
import CustomerMenu from "@/views/customer/CustomerMenu.vue";
import CustomerCart from "@/views/customer/CustomerCart.vue";
import OrderHistory from "@/views/customer/OrderHistory.vue";
import ServiceRequest from "@/views/customer/ServiceRequest.vue";
import SessionEnd from "@/views/customer/SessionEnd.vue";
import Feedback from "@/views/customer/Feedback.vue";

// Removed superadmin views

const routes: RouteRecordRaw[] = [
  {
    path: "/login",
    name: "login",
    component: LoginView,
    meta: { requiresAuth: false },
  },
  {
    path: "/select-branch",
    name: "SelectBranch",
    component: SelectBranchView,
    meta: { requiresAuth: true, requiresBranch: false },
  },
  {
    path: "/",
    redirect: "/login",
  },

  // 1. ADMIN
  {
    path: "/admin",
    component: AdminLayout,
    children: [
      {
        path: "dashboard",
        name: "admin-dashboard",
        component: AdminDashboardView,
      },
      {
        path: "accounts",
        name: "admin-accounts",
        component: AdminAccountsView,
      },
      { path: "menus", name: "admin-menus", component: AdminMenusView },
      { path: "floors", name: "admin-floors", component: AdminFloorsView },
      { path: "kpi", name: "admin-kpi", component: AdminKPIView },
      { path: "audit", name: "admin-audit", component: AdminAuditView },
      { path: "vouchers", name: "admin-vouchers", component: AdminVoucherView },
    ],
  },

  // Removed Hall, Kitchen, Purchasing, Accounting, Tablet, Superadmin routes
  {
    path: "/manager",
    component: ManagerLayout,
    children: [
      {
        path: "dashboard",
        name: "manager-dashboard",
        component: ManagerDashboardView,
      },
      {
        path: "revenue",
        name: "manager-revenue",
        component: ManagerRevenueView,
      },
      {
        path: "cogs",
        name: "manager-cogs",
        component: ManagerCOGSView,
      },
      {
        path: "marketing",
        name: "manager-marketing",
        component: ManagerMarketingView,
      },
      {
        path: "crm",
        name: "manager-crm",
        component: ManagerCRMView,
      },
      {
        path: "inventory",
        name: "manager-inventory",
        component: ManagerInventoryView,
      },
    ],
  },

  {
    path: "/reception",
    component: ReceptionLayout,
    children: [
      {
        path: "dashboard",
        name: "reception-dashboard",
        component: ReceptionDashboardView,
      },
      {
        path: "reservation-detail",
        name: "reception-reservation-detail",
        component: () => import("@/views/reception/ReservationDetailView.vue"),
        meta: {
          requiresAuth: true,
          title: "Chi tiết đặt bàn",
          fullscreen: true,
        }
      },
      {
        path: "checkout/:id",
        name: "reception-checkout",
        component: ReceptionCheckoutView,
      },
      {
        path: "close-shift",
        name: "reception-close-shift",
        component: ReceptionCloseShiftView,
      },
      {
        path: "shift-summary",
        name: "reception-shift-summary",
        component: ShiftSummaryView,
        meta: {
          requiresAuth: true,
          title: "Tổng kết ca",
        },
      },
      {
        path: "floors",
        name: "reception-floors",
        component: () => import("@/views/reception/ReceptionFloorsView.vue"),
      },
      {
        path: "order",
        name: "reception-order",
        component: ReceptionOrderView,
        meta: { fullscreen: true },
      },
      {
        path: "reports",
        name: "reception-reports",
        component: ReportsView,
        meta: {
          requiresAuth: true,
          title: "Báo cáo",
          fullscreen: true,
        },
      },
      {
        path: "revenue-overview",
        name: "reception-revenue-overview",
        component: RevenueOverviewView,
        meta: {
          requiresAuth: true,
          title: "DT Tổng thể",
          fullscreen: true,
        },
      },
      {
        path: "shift-handover",
        name: "reception-shift-handover",
        component: ShiftHandoverView,
        meta: {
          requiresAuth: true,
          title: "Giao ca",
          fullscreen: true,
        },
      },
      {
        path: "inventory",
        name: "reception-inventory",
        component: InventoryView,
        meta: {
          requiresAuth: true,
          title: "Tồn kho tức thời",
          fullscreen: true,
        },
      },
      {
        path: "process-items",
        name: "reception-process-items",
        component: ProcessItemsView,
        meta: {
          requiresAuth: true,
          title: "Xử lý món",
          fullscreen: true,
        },
      },
      {
        path: "menu-management",
        name: "reception-menu-management",
        component: MenuManagementView,
        meta: {
          requiresAuth: true,
          title: "Quản lý Món",
          fullscreen: true,
        },
      },
      {
        path: "other-expense",
        name: "reception-other-expense",
        component: () => import("@/views/reception/OtherExpenseView.vue"),
        meta: {
          requiresAuth: true,
          title: "Chi khác",
          fullscreen: true,
        },
      },
    ],
  },
  // Removed CRM, Staff routes
  {
    path: "/customer",
    component: CustomerLayout,
    meta: { requiresAuth: false, requiresBranch: false },
    children: [
      {
        path: "",
        name: "CustomerHome",
        component: CustomerHome,
      },
      {
        path: "menu",
        name: "CustomerMenu",
        component: CustomerMenu,
      },
      {
        path: "cart",
        name: "CustomerCart",
        component: CustomerCart,
      },
      {
        path: "orders",
        name: "OrderHistory",
        component: OrderHistory,
      },
      {
        path: "service",
        name: "ServiceRequest",
        component: ServiceRequest,
      },
      {
        path: "feedback",
        name: "Feedback",
        component: Feedback,
      },
      {
        path: "session-end",
        name: "SessionEnd",
        component: SessionEnd,
      },
    ],
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

const ROUTE_ROLES: Record<string, string[]> = {
  admin: ["admin"],
  manager: ["admin", "manager"],
  reception: ["admin", "manager", "cashier"],
  customer: ["customer"],
};

router.beforeEach(async (to) => {
  const { isAuthenticated, loading, role, isAdmin } = useAuth();

  if (loading.value) {
    await new Promise<void>((resolve) => {
      const check = setInterval(() => {
        if (!loading.value) {
          clearInterval(check);
          resolve();
        }
      }, 50);
    });
  }

  console.log(
    "[DEBUG ROUTER] Navigating to:",
    to.path,
    "requiresAuth:",
    to.meta.requiresAuth,
    "isAuthenticated:",
    isAuthenticated.value,
  );

  // Public routes.
  if (to.meta.requiresAuth === false) {
    console.log(
      "[DEBUG ROUTER] Bypass match for public customer route:",
      to.path,
    );
    if (isAuthenticated.value && to.name === "login" && role.value) {
      const fallback = getFallbackRouteForRole(role.value);
      if (typeof fallback === 'object' && fallback !== null && 'name' in fallback && fallback.name === 'login') {
        return; // Prevent infinite loop if role has no home mapped
      }
      return fallback;
    }
    return;
  }

  if (!isAuthenticated.value) {
    console.warn(
      "[DEBUG ROUTER] Redirecting to login: User not authenticated for route",
      to.path,
    );
    return { name: "login" };
  }

  const { activeBranchId } = useBranch();
  const needsBranch = to.meta.requiresBranch ?? true;
  if (needsBranch && !activeBranchId.value) {
    if (isAdmin.value && to.name !== "SelectBranch") {
      return { name: "SelectBranch" };
    }
  }

  const prefix = String(to.path.split("/")[1] ?? "");
  const allowed = ROUTE_ROLES[prefix];

  // Normalize checking
  const currentRole = role.value;

  if (allowed && currentRole && !allowed.includes(currentRole)) {
    return getFallbackRouteForRole(currentRole);
  }

  console.log("[DEBUG ROUTER] Navigation allowed to:", to.path);
  return;
});

export default router;
