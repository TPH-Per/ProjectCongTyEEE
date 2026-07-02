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
import CustomerLayout from "@/layouts/CustomerLayout.vue";
import CRMLayout from "@/layouts/CRMLayout.vue";

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
import InvoiceManagerView from "@/views/accounting/InvoiceManagerView.vue";
import TaxExportView from "@/views/accounting/TaxExportView.vue";

// ─── Tablet Views ───────────────────────────────────────────────────────────────
import TabletIdleView from "@/views/tablet/TabletIdleView.vue";
import TabletLanguageView from "@/views/tablet/TabletLanguageView.vue";
import TabletOrderView from "@/views/tablet/TabletOrderView.vue";
import TabletCheckoutView from "@/views/tablet/TabletCheckoutView.vue";

// ─── Superadmin Views ─────────────────────────────────────────────────────────
import SuperadminDashboardView from "@/views/superadmin/SuperadminDashboardView.vue";
import SuperadminBrandsView from "@/views/superadmin/SuperadminBrandsView.vue";
import SuperadminIntegrationsView from "@/views/superadmin/SuperadminIntegrationsView.vue";

// ─── Customer Views ───────────────────────────────────────────────────────────
import CustomerHome from "@/views/customer/CustomerHome.vue";
import CustomerMenu from "@/views/customer/CustomerMenu.vue";
import CustomerCart from "@/views/customer/CustomerCart.vue";
import ServiceRequest from "@/views/customer/ServiceRequest.vue";
import OrderHistory from "@/views/customer/OrderHistory.vue";
import Feedback from "@/views/customer/Feedback.vue";

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
      {
        path: "invoices",
        name: "accounting-invoices",
        component: InvoiceManagerView,
      },
      { path: "tax", name: "accounting-tax", component: TaxExportView },
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
    meta: {
      requiresAuth: false,
      role: "customer",
    },
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
        path: "service-request",
        name: "ServiceRequest",
        component: ServiceRequest,
      },
      {
        path: "order-history",
        name: "OrderHistory",
        component: OrderHistory,
      },
      {
        path: "feedback",
        name: "Feedback",
        component: Feedback,
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
  reception: ["admin", "manager", "reception"],
  staff: ["admin", "manager", "staff"],
  hall: ["admin", "hall"],
  kitchen: ["admin", "kitchen"],
  purchasing: ["admin", "purchasing"],
  accounting: ["admin", "accounting"],
  crm: ["admin", "manager", "crm"],
  tablet: ["admin", "hall", "customer"],
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
  if (to.path.startsWith("/customer") || to.meta.requiresAuth === false) {
    console.log(
      "[DEBUG ROUTER] Bypass match for public customer route:",
      to.path,
    );
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
  if (allowed && role.value && !allowed.includes(role.value)) {
    return getFallbackRouteForRole(role.value);
  }

  console.log("[DEBUG ROUTER] Navigation allowed to:", to.path);
  return;
});

export default router;
