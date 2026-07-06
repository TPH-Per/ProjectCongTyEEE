import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
} from "vue-router";
import { useAuth } from "@/composables/useAuth";
import { useBranch } from "@/composables/useBranch";
import { getFallbackRouteForRole } from "@/utils/route";

// ─── Layouts ──────────────────────────────────────────────────────────────────
import ManagerLayout from "@/layouts/ManagerLayout.vue";
import AdminLayout from "@/layouts/AdminLayout.vue";
import TabletLayout from "@/layouts/TabletLayout.vue";
import StaffLayout from "@/layouts/StaffLayout.vue";
import ReceptionLayout from "@/layouts/ReceptionLayout.vue";
import KitchenLayout from "@/layouts/KitchenLayout.vue";
import SuperadminLayout from "@/layouts/SuperadminLayout.vue";
import PurchasingLayout from "@/layouts/PurchasingLayout.vue";
import AccountingLayout from "@/layouts/AccountingLayout.vue";
import CRMLayout from "@/layouts/CRMLayout.vue";
import CustomerLayout from "@/layouts/CustomerLayout.vue";
import ReportsView from "@/views/reception/ReportsView.vue";

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

// ─── Staff/Hall Views ─────────────────────────────────────────────────────────
import StaffFloorPlanView from "@/views/staff/StaffFloorPlanView.vue";
import StaffOpenTableView from "@/views/staff/StaffOpenTableView.vue";
import StaffActiveTablesView from "@/views/staff/StaffActiveTablesView.vue";
import StaffInDiningCRMView from "@/views/staff/StaffInDiningCRMView.vue";
import ReceptionCheckoutView from "@/views/reception/ReceptionCheckoutView.vue";
import ReceptionDashboardView from "@/views/reception/ReceptionDashboardView.vue";
import ReceptionCloseShiftView from "@/views/reception/ReceptionCloseShiftView.vue";
import ReceptionOrderView from "@/views/reception/ReceptionOrderView.vue";

// ─── Manager Views ────────────────────────────────────────────────────────────
import ManagerDashboardView from "@/views/manager/ManagerDashboardView.vue";
import ManagerRevenueView from "@/views/manager/ManagerRevenueView.vue";
import ManagerCOGSView from "@/views/manager/ManagerCOGSView.vue";
import ManagerMarketingView from "@/views/manager/ManagerMarketingView.vue";
import ManagerCRMView from "@/views/manager/ManagerCRMView.vue";
import ManagerInventoryView from "@/views/manager/ManagerInventoryView.vue";

// ─── CRM Views ───────────────────────────────────────────────────────────────
import CRMDashboardView from "@/views/crm/CRMDashboardView.vue";
import CustomerFeedbackView from "@/views/crm/CustomerFeedbackView.vue";
import CRMServingTablesView from "@/views/crm/CRMServingTablesView.vue";

// ─── Kitchen Views ────────────────────────────────────────────────────────────
import KitchenKDSView from "@/views/kitchen/KitchenKDSView.vue";

// ─── Purchasing Views ──────────────────────────────────────────────────────────
import DailyReceiptView from "@/views/purchasing/DailyReceiptView.vue";
import InventoryAuditView from "@/views/purchasing/InventoryAuditView.vue";

// ─── Accounting Views ──────────────────────────────────────────────────────────
import AccountingDashboardView from "@/views/accounting/AccountingDashboardView.vue";
import InvoiceManagerView from "@/views/accounting/InvoiceManagerView.vue";
import TaxExportView from "@/views/accounting/TaxExportView.vue";
import CashFlowView from "@/views/accounting/CashFlowView.vue";
import APPayablesView from "@/views/accounting/APPayablesView.vue";
import PLReportView from "@/views/accounting/PLReportView.vue";

// ─── Tablet Views ───────────────────────────────────────────────────────────────
import TabletIdleView from "@/views/tablet/TabletIdleView.vue";
import TabletLanguageView from "@/views/tablet/TabletLanguageView.vue";
import TabletOrderView from "@/views/tablet/TabletOrderView.vue";
import TabletCheckoutView from "@/views/tablet/TabletCheckoutView.vue";

// ─── Customer Views ──────────────────────────────────────────────────────────────
import CustomerHome from "@/views/customer/CustomerHome.vue";
import CustomerMenu from "@/views/customer/CustomerMenu.vue";
import CustomerCart from "@/views/customer/CustomerCart.vue";
import OrderHistory from "@/views/customer/OrderHistory.vue";
import ServiceRequest from "@/views/customer/ServiceRequest.vue";
import SessionEnd from "@/views/customer/SessionEnd.vue";
import Feedback from "@/views/customer/Feedback.vue";

// ─── Superadmin Views ─────────────────────────────────────────────────────────
import SuperadminDashboardView from "@/views/superadmin/SuperadminDashboardView.vue";
import SuperadminBrandsView from "@/views/superadmin/SuperadminBrandsView.vue";
import SuperadminIntegrationsView from "@/views/superadmin/SuperadminIntegrationsView.vue";

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

  // 2. HALL
  {
    path: "/hall",
    component: StaffLayout,
    children: [
      {
        path: "floor-plan",
        name: "hall-floor-plan",
        component: StaffFloorPlanView,
      },
      {
        path: "table/:id/open",
        name: "hall-open-table",
        component: StaffOpenTableView,
      },
      {
        path: "checkout/:id",
        name: "hall-checkout",
        component: ReceptionCheckoutView,
      },
    ],
  },

  // 3. KITCHEN
  {
    path: "/kitchen",
    component: KitchenLayout,
    children: [{ path: "kds", name: "kitchen-kds", component: KitchenKDSView }],
  },

  // 4. PURCHASING
  {
    path: "/purchasing",
    component: PurchasingLayout,
    children: [
      {
        path: "receipts",
        name: "purchasing-receipts",
        component: DailyReceiptView,
      },
      {
        path: "audit",
        name: "purchasing-audit",
        component: InventoryAuditView,
      },
    ],
  },

  // 5. ACCOUNTING
  {
    path: "/accounting",
    component: AccountingLayout,
    children: [
      { path: "", redirect: "/accounting/dashboard" },
      { path: "dashboard", name: "accounting-dashboard", component: AccountingDashboardView },
      { path: "cashflow",  name: "accounting-cashflow",  component: CashFlowView },
      { path: "ap",        name: "accounting-ap",        component: APPayablesView },
      { path: "pl-report", name: "accounting-pl-report", component: PLReportView },
      { path: "invoices",  name: "accounting-invoices",  component: InvoiceManagerView },
      { path: "tax",       name: "accounting-tax",       component: TaxExportView },
    ],
  },

  // 6. CUSTOMER (TABLET)
  {
    path: "/tablet",
    component: TabletLayout,
    children: [
      {
        path: "idle",
        name: "tablet-idle",
        component: TabletIdleView,
      },
      {
        path: "language",
        name: "tablet-language",
        component: TabletLanguageView,
      },
      {
        path: "order",
        name: "tablet-order",
        component: TabletOrderView,
      },
      {
        path: "checkout",
        name: "tablet-checkout",
        component: TabletCheckoutView,
      },
    ],
  },

  // ═══════════════════════════════════════════════════════════════
  // SUPERADMIN PORTAL (Desktop — Role: Enterprise Admin)
  // ═══════════════════════════════════════════════════════════════
  {
    path: "/superadmin",
    component: SuperadminLayout,
    children: [
      {
        path: "dashboard",
        name: "superadmin-dashboard",
        component: SuperadminDashboardView,
      },
      {
        path: "brands",
        name: "superadmin-brands",
        component: SuperadminBrandsView,
      },
      {
        path: "integrations",
        name: "superadmin-integrations",
        component: SuperadminIntegrationsView,
      },
      {
        path: "accounts",
        name: "superadmin-accounts",
        component: AdminAccountsView,
      },
      {
        path: "vouchers",
        name: "superadmin-vouchers",
        component: AdminVoucherView,
      },
    ],
  },
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
        path: "floors",
        name: "reception-floors",
        component: AdminFloorsView,
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
    ],
  },
  {
    path: "/crm",
    component: CRMLayout,
    children: [
      {
        path: "",
        redirect: "/crm/serving-tables",
      },
      {
        path: "dashboard",
        name: "crm-dashboard",
        component: CRMDashboardView,
      },
      {
        path: "serving-tables",
        name: "crm-serving-tables",
        component: CRMServingTablesView,
      },
      {
        path: "feedback",
        name: "crm-feedback",
        component: CustomerFeedbackView,
      },
    ],
  },
  {
    path: "/staff",
    component: StaffLayout,
    children: [
      {
        path: "floor-plan",
        name: "staff-floor-plan",
        component: StaffFloorPlanView,
      },
      {
        path: "active-tables",
        name: "staff-active-tables",
        component: StaffActiveTablesView,
      },
      {
        path: "table/:id/open",
        name: "staff-open-table",
        component: StaffOpenTableView,
      },
      {
        path: "table/:id/crm",
        name: "staff-crm",
        component: StaffInDiningCRMView,
      },
    ],
  },
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
  superadmin: ["superadmin"],
  admin: ["superadmin", "admin"],
  manager: ["superadmin", "admin", "manager"],
  reception: ["superadmin", "admin", "manager", "reception"],
  staff: ["superadmin", "admin", "manager", "staff"],
  hall: ["superadmin", "admin", "manager", "reception", "staff"],
  kitchen: ["superadmin", "admin", "manager", "kitchen"],
  purchasing: ["superadmin", "admin", "procurement", "procurement_manager", "procurement_staff", "purchasing"],
  accounting: ["superadmin", "admin", "accounting", "accounting_manager", "manager"],
  crm: ["superadmin", "admin", "manager", "crm_manager", "crm"],
  marketing: ["superadmin", "admin", "manager", "marketing"],
  bod: ["superadmin", "admin", "bod"],
  tablet: ["superadmin", "admin", "manager", "reception", "staff", "customer"],
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
