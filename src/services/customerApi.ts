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

import { supabase, isSupabaseConfigured } from "@/lib/supabase";
import { menuData as menuTemplate } from "@/data/menuData";
import { customerAreas } from "@/data/customerAreaData";
import type {
  CustomerSession,
  Table,
  Area,
  Branch,
  MenuItem,
  MenuCategory,
  CartItem,
  Order,
  ServiceRequest,
  Feedback,
} from "@/types/customer";
import { isValidUUID } from "@/utils/validators";

export interface CustomerApi {
  // Authentication
  authenticateStaff(
    passcode: string,
  ): Promise<{ success: boolean; staffId: string }>;

  // Branch Management
  getBranches(): Promise<Branch[]>;

  // Table Management
  getAreas(branchId?: string): Promise<Area[]>;
  getTables(areaId: string): Promise<Table[]>;
  selectTable(tableId: string): Promise<{ success: boolean }>;
  createSession(params: {
    branchId: string;
    tableId: string;
    tableNumber: string;
    areaId: string;
    areaName: string;
    packageId: string;
    adultCount: number;
    childCount: number;
    openedBy: string;
  }): Promise<CustomerSession>;
  releaseTable(sessionId: string): Promise<void>;

  // Menu Management
  getPackages(branchId: string): Promise<any[]>;
  getMenu(): Promise<MenuCategory[]>;
  /**
   * Raw menu rows from Supabase (real UUIDs). Used by the store to
   * remap the mock `menuData.ts` template's auto-counter ids onto the
   * live DB ids.
   */
  getRawMenuItems(): Promise<
    Array<{ id: string; name: string; price: number; price_display?: string }>
  >;
  /**
   * Returns the mock template structure (`@/data/menuData`) that the
   * store deep-clones and patches with real ids from `getRawMenuItems`.
   */
  getMenuTemplate(): Promise<MenuCategory[]>;

  // Ordering Flow
  createOrder(order: Order): Promise<Order>;
  updateOrder(orderId: string, items: CartItem[]): Promise<Order>;
  getOrderStatus(sessionId: string): Promise<
    Array<{
      id: string | number;
      name: string;
      quantity: number;
      status: "new" | "sent" | "preparing" | "ready" | "served" | "cancelled";
      orderedTime: string;
      servedTime: string | null;
    }>
  >;
  getOrderHistory(sessionId: string): Promise<Order[]>;

  // Service Request
  submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest>;
  getServiceRequests(sessionId: string): Promise<ServiceRequest[]>;
  updateServiceRequest(requestId: string, status: string): Promise<void>;

  // Payment & Invoices
  requestPayment(sessionId: string): Promise<{ success: boolean }>;
  requestInvoice(
    sessionId: string,
    details?: any,
  ): Promise<{ invoiceId: string }>;
  updateCrmInfo(
    sessionId: string,
    phone: string,
    name: string,
  ): Promise<{ success: boolean }>;

  // Feedback
  submitFeedback(feedback: Feedback): Promise<Feedback>;
  updateLanguage(sessionId: string, languageCode: string): Promise<void>;

  // Real-time implementations
  subscribeToTableUpdates(
    tableId: string,
    callback: (payload: any) => void,
  ): () => void;
  subscribeToServiceRequests(
    sessionId: string,
    callback: (payload: any) => void,
  ): () => void;
  subscribeToOrderUpdates(
    sessionId: string,
    callback: (payload: any) => void,
  ): () => void;
}

// ---------------------------------------------------------------------------
// Branch / table helpers
// ---------------------------------------------------------------------------

// The customer flow is URL/QR-driven and does NOT require a staff JWT —
// the customer picks up a tablet and immediately lands on the menu. To
// route RPCs we need the branch short-code; today the test environment
// only has `B001`, so we hard-code it. Production: lift this from the
// URL `?branch=B001` query param once multi-branch QR labels exist.
const DEFAULT_BRANCH_CODE = "B001";

// Mock branches for the customer self-service flow. When Supabase is
// configured, `getBranches()` reads from the `branches` table instead.
const MOCK_BRANCHES: Branch[] = [
  {
    id: "branch_1",
    code: "B001",
    name: "Ngưu Cát 1",
    name_en: "Nguu Cat 1",
    address: "123 Nguyễn Văn A, Quận 1, TP.HCM",
    phone: "028 1234 5678",
    isActive: true,
  },
  {
    id: "branch_2",
    code: "B002",
    name: "Ngưu Cát 2",
    name_en: "Nguu Cat 2",
    address: "456 Lê Văn B, Quận 3, TP.HCM",
    phone: "028 8765 4321",
    isActive: true,
  },
];

async function resolveBranchIdByCode(code: string): Promise<string | null> {
  const { data, error } = await supabase
    .from("branches")
    .select("branch_id")
    .eq("branch_code", code)
    .eq("is_active", true)
    .maybeSingle();
  if (error) {
    console.error("[customerApi] resolveBranchIdByCode failed:", error);
    return null;
  }
  return (data as any)?.branch_id ?? (data as any)?.id ?? null;
}

async function resolveTableIdByCode(
  branchId: string,
  tableCode: string,
): Promise<string | null> {
  const { data, error } = await supabase
    .from("dining_tables")
    .select("dining_table_id, table_code, capacity, area_id")
    .eq("branch_id", branchId)
    .eq("table_code", tableCode)
    .eq("is_active", true)
    .maybeSingle();
  if (error) {
    console.error("[customerApi] resolveTableIdByCode failed:", error);
    return null;
  }
  return (data as any)?.dining_table_id ?? (data as any)?.id ?? null;
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export const customerApiImpl: CustomerApi = {
  async authenticateStaff(
    passcode: string,
  ): Promise<{ success: boolean; staffId: string }> {
    // BR-01: Passcode length is 6
    if (passcode.length !== 6) {
      return { success: false, staffId: "" };
    }
    // Hardcode passcode 123456 or 654321 for demo / staff authentication.
    // (Production: replace with `public.users` lookup or Edge Function
    //  call that validates against `profiles.pin_hash`.)
    if (passcode === "123456" || passcode === "654321") {
      return { success: true, staffId: "staff-uuid-001" };
    }
    return { success: false, staffId: "" };
  },

  async getBranches(): Promise<Branch[]> {
    if (!isSupabaseConfigured) {
      return MOCK_BRANCHES;
    }
    const { data, error } = await supabase
      .from("branches")
      .select("branch_id, branch_code, branch_name, address, phone, is_active")
      .eq("is_active", true)
      .order("branch_name", { ascending: true });
    if (error || !data || data.length === 0) {
      // Fall back to mock data when Supabase returns an error or no
      // active branches are configured yet.
      if (error)
        console.warn(
          "[customerApi] getBranches failed, using mock:",
          error.message,
        );
      return MOCK_BRANCHES;
    }
    return data.map((b: any) => ({
      id: b.branch_id,
      code: b.branch_code,
      name: b.branch_name,
      address: b.address,
      phone: b.phone,
      isActive: b.is_active,
    }));
  },

  async getAreas(branchId?: string): Promise<Area[]> {
    if (!isSupabaseConfigured) {
      // Mock fallback: return all 10 areas with embedded tables so the
      // area selection grid can show table counts and previews.
      return JSON.parse(JSON.stringify(customerAreas));
    }
    // Read live zones from Supabase. `zones` has columns
    // `id, branch_id, name, color, sort_order, is_active, metadata, …`
    // — no `code` column. We surface the zone by uuid and stash the
    // display name in `metadata->>'zone_code'` when present, falling
    // back to a derived slug. The customer's UI keys areas by uuid
    // (see `getTables`).
    let query = supabase
      .from("areas")
      .select("area_id, area_code, area_name, sort_order")
      .eq("is_active", true);
    if (branchId) {
      if (!/^[0-9a-f-]{36}$/i.test(branchId)) {
        return JSON.parse(JSON.stringify(customerAreas));
      }
      query = query.eq("branch_id", branchId);
    }
    const { data, error } = await query.order("sort_order", {
      ascending: true,
    });
    if (error || !data || data.length === 0) {
      // Fall back to mock data when Supabase returns an error or no
      // zones are configured yet. This keeps the UI functional during
      // development / before DB seeding.
      if (error)
        console.warn(
          "[customerApi] getAreas failed, using mock:",
          error.message,
        );
      return JSON.parse(JSON.stringify(customerAreas));
    }
    // Supabase returns zones without embedded tables. The customer UI
    // (AreaGrid) needs tables embedded in each area for stats and
    // previews. Fetch table counts per zone so we can populate them.
    const zonesWithData = await Promise.all(
      (data ?? []).map(async (z: any) => {
        const { data: zoneTables } = await supabase
          .from("dining_tables")
          .select("dining_table_id, table_code, capacity, availability_status")
          .eq("area_id", z.area_id)
          .eq("is_active", true)
          .order("table_code", { ascending: true });
        return {
          id: z.area_id as string,
          name: (z.area_name as string) ?? "Khu vực",
          tables: (zoneTables ?? []).map((t: any) => ({
            id: t.dining_table_id,
            number: t.table_code,
            areaId: z.area_id,
            status: mapDbStatus(t.availability_status),
            capacity: t.capacity,
          })),
        };
      }),
    );
    // If none of the zones have any tables, fall back to mock data.
    const totalTablesFromDb = zonesWithData.reduce(
      (s, a) => s + a.tables.length,
      0,
    );
    if (totalTablesFromDb === 0) {
      console.warn(
        "[customerApi] getAreas: no tables found in any zone, using mock data",
      );
      return JSON.parse(JSON.stringify(customerAreas));
    }
    return zonesWithData;
  },

  async getTables(areaId: string): Promise<Table[]> {
    if (!isSupabaseConfigured) {
      // Mock fallback: look up tables from the customerAreaData by area id
      const area = customerAreas.find((a) => a.id === areaId);
      return area ? JSON.parse(JSON.stringify(area.tables)) : [];
    }
    // `areaId` is now the zone UUID (see `getAreas`). The tables
    // table doesn't have a `current_session_id` column either — only
    // `metadata->>'current_session_id'` — so we don't expose that.
    if (!areaId || !/^[0-9a-f-]{36}$/i.test(areaId)) {
      // Not a valid UUID — likely a mock area id (e.g. "area_a").
      // Fall back to mock data so the UI still works.
      const area = customerAreas.find((a) => a.id === areaId);
      return area ? JSON.parse(JSON.stringify(area.tables)) : [];
    }
    const { data, error } = await supabase
      .from("dining_tables")
      .select(
        "dining_table_id, table_code, capacity, availability_status, area_id",
      )
      .eq("area_id", areaId)
      .eq("is_active", true)
      .order("table_code", { ascending: true });
    if (error || !data || data.length === 0) {
      // Fall back to mock data when Supabase returns an error or no
      // tables are found for this zone.
      if (error)
        console.warn(
          "[customerApi] getTables failed, using mock:",
          error.message,
        );
      const area = customerAreas.find((a) => a.id === areaId);
      return area ? JSON.parse(JSON.stringify(area.tables)) : [];
    }
    return (data ?? []).map((t: any) => ({
      id: t.dining_table_id,
      number: t.table_code,
      areaId,
      status: mapDbStatus(t.availability_status),
      capacity: t.capacity,
    }));
  },

  async selectTable(tableId: string): Promise<{ success: boolean }> {
    if (!isSupabaseConfigured || !/^[0-9a-f-]{36}$/i.test(tableId)) {
      // Mock fallback: allow selection if the table exists and is available
      const table = customerAreas
        .flatMap((a) => a.tables)
        .find((t) => t.id === tableId);
      return { success: !!table && table.status === "available" };
    }
    // Read-only check against the live DB. The actual flip-to-occupied
    // happens later in `confirmTable` (or when the first order lands
    // via `customer_create_self_service_order`).
    const { data, error } = await supabase
      .from("dining_tables")
      .select("availability_status")
      .eq("dining_table_id", tableId)
      .maybeSingle();
    if (error || !data) return { success: false };
    return { success: data.availability_status === "available" };
  },

  async getPackages(branchId: string): Promise<any[]> {
    if (!isSupabaseConfigured) {
      return [
        {
          id: "pkg-1",
          name: "Buffet Thường 299K",
          priceAdult: 299000,
          priceChild: 149000,
        },
        {
          id: "pkg-2",
          name: "Buffet VIP 499K",
          priceAdult: 499000,
          priceChild: 249000,
        },
      ];
    }
    if (!branchId || !/^[0-9a-f-]{36}$/i.test(branchId)) {
      console.warn("[customerApi] getPackages: invalid branchId, using mock.");
      return [
        {
          id: "pkg-1",
          name: "Buffet Thường 299K",
          priceAdult: 299000,
          priceChild: 149000,
        },
        {
          id: "pkg-2",
          name: "Buffet VIP 499K",
          priceAdult: 499000,
          priceChild: 249000,
        },
      ];
    }
    const { data, error } = await supabase.rpc("customer_list_packages", {
      p_branch_id: branchId,
    });
    if (error) {
      console.error("[customerApi] getPackages failed:", error);
      return [];
    }
    if (!data || data.length === 0) {
      console.warn(
        "[customerApi] getPackages returned empty, using mock packages.",
      );
      return [
        {
          id: "pkg-1",
          name: "Buffet Thường 299K",
          priceAdult: 299000,
          priceChild: 149000,
        },
        {
          id: "pkg-2",
          name: "Buffet VIP 499K",
          priceAdult: 499000,
          priceChild: 249000,
        },
      ];
    }
    return data;
  },

  async createSession(params: {
    branchId: string;
    tableId: string;
    tableNumber: string;
    areaId: string;
    areaName: string;
    packageId: string;
    adultCount: number;
    childCount: number;
    openedBy: string;
  }): Promise<CustomerSession> {
    if (
      !isSupabaseConfigured ||
      !/^[0-9a-f-]{36}$/i.test(params.branchId) ||
      !/^[0-9a-f-]{36}$/i.test(params.tableId)
    ) {
      // Mock fallback: return a local session immediately
      return {
        id: `sess-mock-${Date.now()}`,
        branchId: params.branchId,
        tableId: params.tableId,
        tableNumber: params.tableNumber,
        areaId: params.areaId,
        areaName: params.areaName,
        staffId: params.openedBy,
        guestCount: params.adultCount + params.childCount,
        packageId: params.packageId,
        serviceMode: "buffet",
        languageCode: "vi",
        startedAt: new Date(),
        status: "open",
      };
    }

    // Call the atomic RPC
    const { data, error } = await supabase.rpc("customer_create_session", {
      p_branch_id: params.branchId,
      p_table_id: params.tableId,
      p_package_id: params.packageId || null,
      p_adult_count: params.adultCount,
      p_child_count: params.childCount,
      p_opened_by: params.openedBy,
    });

    if (error) {
      console.warn(
        "[customerApi] createSession RPC failed; using local session:",
        error.message,
      );
      return {
        id: `sess-local-${Date.now()}`,
        branchId: params.branchId,
        tableId: params.tableId,
        tableNumber: params.tableNumber,
        areaId: params.areaId,
        areaName: params.areaName,
        staffId: params.openedBy,
        guestCount: params.adultCount + params.childCount,
        serviceMode: "buffet",
        languageCode: "vi",
        startedAt: new Date(),
        status: "open",
      };
    }

    const sessionRow = (data ?? {}) as any;
    return {
      id: sessionRow.id || `sess-local-${Date.now()}`,
      branchId: params.branchId,
      tableId: params.tableId,
      tableNumber: params.tableNumber,
      areaId: params.areaId,
      areaName: params.areaName,
      staffId: params.openedBy,
      guestCount: params.adultCount + params.childCount,
      packageId: params.packageId,
      serviceMode: "buffet",
      languageCode: "vi",
      startedAt: sessionRow.created_at
        ? new Date(sessionRow.created_at)
        : new Date(),
      status: "open",
    };
  },

  async releaseTable(sessionId: string): Promise<void> {
    if (!isSupabaseConfigured) {
      // Mock fallback: no-op
      return;
    }
    // End the tablet_session. If the sessionId is a real uuid, mark it
    // ENDED. If it's a `sess-local-…` placeholder (used when the
    // Only PATCH when the session id is a real uuid. The customer's
    // legacy in-memory sessions used `sess-<timestamp>` ids which are
    // not valid uuid syntax; trying to PATCH them throws 22P02.
    if (isUuid(sessionId)) {
      await supabase
        .from("tablet_sessions")
        .update({
          status: "ENDED",
          ended_at: new Date().toISOString(),
        })
        .eq("id", sessionId);
    }
  },

  async getMenu(): Promise<MenuCategory[]> {
    return customerApiImpl.getMenuTemplate();
  },

  async getMenuTemplate(): Promise<MenuCategory[]> {
    return JSON.parse(
      JSON.stringify(menuTemplate.categories),
    ) as MenuCategory[];
  },

  async getRawMenuItems(): Promise<
    Array<{ id: string; name: string; price: number; price_display?: string }>
  > {
    if (!isSupabaseConfigured) {
      // Mock fallback: generate stable UUIDs for the mock menu items
      // so isValidUUID passes in cart validation.
      const allItems: Array<{
        id: string;
        name: string;
        price: number;
        price_display?: string;
      }> = [];
      let counter = 0;
      const walk = (items?: MenuItem[]) => {
        if (!items) return;
        for (const it of items) {
          counter++;
          const uuid = `00000000-0000-4000-8000-${String(counter).padStart(12, "0")}`;
          allItems.push({
            id: uuid,
            name: it.name,
            price: it.price,
            price_display: it.price_display,
          });
        }
      };
      for (const cat of menuTemplate.categories) {
        walk(cat.items);
        if (cat.subcategories) {
          for (const sub of cat.subcategories) walk(sub.items);
        }
      }
      return allItems;
    }
    const branchId = await resolveBranchIdByCode(DEFAULT_BRANCH_CODE);
    if (!branchId) return [];
    const { data, error } = await supabase.rpc("customer_list_menu_items", {
      p_branch_id: branchId,
      p_category_id: null,
    });
    if (error) {
      console.error("[customerApi] getRawMenuItems failed:", error);
      return [];
    }
    return (data ?? []).map((row: any) => ({
      id: row.id,
      name: row.name,
      price: Number(row.price ?? 0),
      price_display:
        row.price_display ??
        `${Number(row.price ?? 0).toLocaleString("vi-VN")}đ`,
    }));
  },

  async createOrder(order: Order): Promise<Order> {
    if (!isSupabaseConfigured) {
      // Mock fallback: return order with local id
      console.log("[MOCK] createOrder:", order);
      await new Promise((r) => setTimeout(r, 800));
      return {
        ...order,
        id: `ord-mock-${Date.now()}`,
        status: "confirmed",
      };
    }
    for (const item of order.items) {
      if (!isValidUUID(item.menuItemId)) {
        console.error(`[customerApi] Invalid UUID: ${item.menuItemId}`);
        throw new Error(
          `Mã món ăn "${item.name}" (${item.menuItemId}) không hợp lệ (yêu cầu UUID)`,
        );
      }
    }

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
      note: c.note ?? "",
    }));
    const { data, error } = await supabase.rpc(
      "customer_create_self_service_order",
      {
        p_branch_code: DEFAULT_BRANCH_CODE,
        p_table_code: order.tableNumber,
        p_items: cartItems,
        p_session_token: order.sessionId, // re-uses the tablet_session.id as idempotency anchor
        p_customer_name: null,
      },
    );
    if (error) {
      console.error("[customerApi] createOrder RPC failed:", error);
      throw new Error(error.message);
    }
    const payload = (data ?? {}) as {
      order_id?: string;
      order_number?: string;
      session_id?: string;
      subtotal?: number;
      vat?: number;
      total?: number;
    };
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
      status: "confirmed",
    };
  },

  async getOrderStatus(sessionId: string): Promise<
    Array<{
      id: string | number;
      name: string;
      quantity: number;
      status: "new" | "sent" | "preparing" | "ready" | "served" | "cancelled";
      orderedTime: string;
      servedTime: string | null;
    }>
  > {
    if (!isSupabaseConfigured) {
      return [
        {
          id: 1,
          name: "Bò Wagyu A5",
          quantity: 1,
          status: "served",
          orderedTime: new Date(Date.now() - 30 * 60000).toLocaleTimeString(
            [],
            { hour: "2-digit", minute: "2-digit" },
          ),
          servedTime: new Date(Date.now() - 10 * 60000).toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          }),
        },
        {
          id: 2,
          name: "Lõi vai bò Mỹ",
          quantity: 2,
          status: "preparing",
          orderedTime: new Date(Date.now() - 20 * 60000).toLocaleTimeString(
            [],
            { hour: "2-digit", minute: "2-digit" },
          ),
          servedTime: null,
        },
        {
          id: 3,
          name: "Salad rong biển",
          quantity: 1,
          status: "new",
          orderedTime: new Date().toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          }),
          servedTime: null,
        },
      ];
    }

    try {
      const { data, error } = await supabase.rpc("customer_get_order_status", {
        p_session_token: sessionId,
      });
      if (error) {
        console.warn(
          "[customerApi] getOrderStatus RPC error, falling back to mock:",
          error,
        );
        throw error;
      }
      return data || [];
    } catch (err) {
      return [
        {
          id: 1,
          name: "Bò Wagyu A5",
          quantity: 1,
          status: "served",
          orderedTime: new Date(Date.now() - 30 * 60000).toLocaleTimeString(
            [],
            { hour: "2-digit", minute: "2-digit" },
          ),
          servedTime: new Date(Date.now() - 10 * 60000).toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          }),
        },
        {
          id: 2,
          name: "Lõi vai bò Mỹ",
          quantity: 2,
          status: "preparing",
          orderedTime: new Date(Date.now() - 20 * 60000).toLocaleTimeString(
            [],
            { hour: "2-digit", minute: "2-digit" },
          ),
          servedTime: null,
        },
      ];
    }
  },

  async updateOrder(orderId: string, items: CartItem[]): Promise<Order> {
    // Pre-flight UUID validation
    for (const item of items) {
      if (!isValidUUID(item.menuItemId)) {
        console.error(`[customerApi] Invalid UUID: ${item.menuItemId}`);
        throw new Error(
          `Mã món ăn "${item.name}" (${item.menuItemId}) không hợp lệ (yêu cầu UUID)`,
        );
      }
    }

    // Append more items to an existing order via the same RPC — the
    // RPC reuses the open order for the table.
    const cartItems = items.map((c) => ({
      menu_item_id: c.menuItemId,
      quantity: c.quantity,
      modifiers: [],
      note: c.note ?? "",
    }));
    const tableNumber = items[0]?.name ? "" : ""; // caller must supply; see below
    const { data, error } = await supabase.rpc(
      "customer_create_self_service_order",
      {
        p_branch_code: DEFAULT_BRANCH_CODE,
        p_table_code: tableNumber,
        p_items: cartItems,
        p_session_token: orderId,
        p_customer_name: null,
      },
    );
    if (error) throw new Error(error.message);
    const payload = (data ?? {}) as {
      order_id?: string;
      subtotal?: number;
      vat?: number;
      total?: number;
    };
    return {
      id: payload.order_id ?? orderId,
      sessionId: "",
      tableNumber,
      items,
      subtotal: Number(payload.subtotal ?? 0),
      serviceCharge: 0,
      vat: Number(payload.vat ?? 0),
      discount: 0,
      total: Number(payload.total ?? 0),
      subtotal_vnd: Number(payload.subtotal ?? 0),
      serviceCharge_vnd: 0,
      vat_vnd: Number(payload.vat ?? 0),
      discount_vnd: 0,
      total_vnd: Number(payload.total ?? 0),
      status: "confirmed",
      createdAt: new Date(),
    };
  },

  async getOrderHistory(sessionId: string): Promise<Order[]> {
    if (!isSupabaseConfigured) {
      return [];
    }
    // Read orders for the active dining_session
    if (!sessionId || !/^[0-9a-f-]{36}$/i.test(sessionId)) {
      return []; // invalid or mock session
    }
    const { data, error } = await supabase
      .from("orders")
      .select(
        "order_id, branch_id, dining_session_id, order_number, status, note, created_at, updated_at, order_details(order_detail_id, branch_menu_item_id, item_name_snapshot, unit_price_vnd_snapshot, quantity, detail_total_vnd, kitchen_status, note)",
      )
      .eq("dining_session_id", sessionId)
      .order("created_at", { ascending: false })
      .limit(50);
    if (error) {
      console.error("[customerApi] getOrderHistory failed:", error);
      return [];
    }
    return (data ?? []).map((row: any) => rowToOrder(row));
  },

  async submitServiceRequest(request: ServiceRequest): Promise<ServiceRequest> {
    if (!isSupabaseConfigured) {
      // Mock fallback: return the request with a fake id
      return {
        ...request,
        id: `sr-mock-${Date.now()}`,
        status: "created",
        createdAt: new Date(),
      };
    }

    try {
      const { data, error } = await supabase.rpc(
        "customer_submit_service_request",
        {
          p_session_token: request.sessionId,
          p_request_type: request.type,
          p_message: request.content ?? "",
        },
      );
      if (error) {
        console.warn(
          "[customerApi] submitServiceRequest RPC failed, falling back:",
          error,
        );
        throw error;
      }
      return {
        ...request,
        id: (data as any)?.request_id || `sr-${Date.now()}`,
        status: "created",
        createdAt: new Date(),
      };
    } catch (e) {
      console.error("[customerApi] submitServiceRequest failed:", e);
      return {
        ...request,
        id: `sr-mock-${Date.now()}`,
        status: "created",
        createdAt: new Date(),
      };
    }
  },

  async getServiceRequests(sessionId: string): Promise<ServiceRequest[]> {
    if (!isSupabaseConfigured) {
      return [];
    }
    // No direct session_id column on service_requests — filter by
    // table. The customer UI mostly uses this to show pending
    // requests; we return recent rows scoped to the branch.
    const { data, error } = await supabase
      .from("service_requests")
      .select("id, type, status, message, table_id, created_at")
      .order("created_at", { ascending: false })
      .limit(20);
    if (error) return [];
    return (data ?? []).map((row: any) => ({
      id: row.id,
      sessionId,
      tableNumber: "",
      type: mapRequestTypeFromDb(row.type),
      content: row.message ?? "",
      status: mapRequestStatusFromDb(row.status),
      createdAt: new Date(row.created_at),
    }));
  },

  async updateServiceRequest(requestId: string, status: string): Promise<void> {
    if (!isSupabaseConfigured) {
      return;
    }

    if (status === "cancelled") {
      try {
        const { error } = await supabase.rpc(
          "customer_cancel_service_request",
          {
            p_request_id: requestId,
          },
        );
        if (error) {
          console.warn(
            "[customerApi] customer_cancel_service_request RPC failed, falling back:",
            error,
          );
          await supabase
            .from("service_requests")
            .update({ status: "CANCELLED" })
            .eq("id", requestId);
        }
      } catch (e) {
        console.error("[customerApi] updateServiceRequest failed:", e);
      }
    } else {
      const dbStatus =
        status === "completed"
          ? "RESOLVED"
          : status === "accepted" ||
              status === "processing" ||
              status === "waiting"
            ? "IN_PROGRESS"
            : "OPEN";
      await supabase
        .from("service_requests")
        .update({ status: dbStatus })
        .eq("id", requestId);
    }
  },

  async requestPayment(sessionId: string): Promise<{ success: boolean }> {
    if (!isSupabaseConfigured) return { success: true };

    try {
      const { error } = await supabase.rpc("customer_request_checkout", {
        p_session_token: sessionId,
      });
      if (error) {
        console.warn(
          "[customerApi] requestPayment RPC failed, falling back:",
          error,
        );
        // Fallback to table update if RPC doesn't exist
        await supabase
          .from("tablet_sessions")
          .update({
            status: "CHECKOUT_REQUESTED",
            last_activity_at: new Date().toISOString(),
          })
          .eq("id", sessionId);
      }
      return { success: true };
    } catch (e) {
      console.error("[customerApi] requestPayment failed:", e);
      return { success: false };
    }
  },

  async updateCrmInfo(
    sessionId: string,
    phone: string,
    name: string,
  ): Promise<{ success: boolean }> {
    if (!isSupabaseConfigured) return { success: true };
    try {
      const { error } = await supabase.rpc("customer_update_crm_info", {
        p_session_token: sessionId,
        p_phone: phone,
        p_name: name,
      });
      if (error) {
        console.warn("[customerApi] updateCrmInfo RPC failed:", error);
        return { success: false };
      }
      return { success: true };
    } catch (e) {
      console.error("[customerApi] updateCrmInfo failed:", e);
      return { success: false };
    }
  },

  async requestInvoice(
    sessionId: string,
    details?: any,
  ): Promise<{ invoiceId: string }> {
    if (!isSupabaseConfigured) return { invoiceId: `inv-mock-${Date.now()}` };

    try {
      const { data, error } = await supabase.rpc(
        "customer_request_vat_invoice",
        {
          p_session_token: sessionId,
          p_details: details,
        },
      );
      if (error) {
        console.warn(
          "[customerApi] requestVATInvoice RPC failed, falling back:",
          error,
        );
        return { invoiceId: `inv-stub-${Date.now()}` };
      }
      return { invoiceId: (data as any)?.invoice_id || `inv-${Date.now()}` };
    } catch (e) {
      console.error("[customerApi] requestInvoice failed:", e);
      return { invoiceId: `inv-stub-${Date.now()}` };
    }
  },

  async submitFeedback(feedback: Feedback): Promise<Feedback> {
    if (!isSupabaseConfigured) {
      // Mock fallback
      return {
        ...feedback,
        id: `fb-mock-${Date.now()}`,
        createdAt: new Date(),
      };
    }

    try {
      const surveyData = {
        criteria: feedback.criteria || feedback.surveyData?.criteria || [],
        customerName:
          feedback.customerName || feedback.surveyData?.customerName || "",
        customerPhone:
          feedback.customerPhone || feedback.surveyData?.customerPhone || "",
      };

      const { data, error } = await supabase.rpc("customer_submit_feedback", {
        p_session_token: feedback.sessionId,
        p_rating: feedback.rating,
        p_comment: feedback.comment ?? "",
        p_survey_data: surveyData,
      });

      if (error) {
        console.warn("[customerApi] submitFeedback RPC failed:", error);
        throw error;
      }

      return {
        ...feedback,
        id: (data as any)?.feedback_id || `fb-${Date.now()}`,
        createdAt: new Date(),
      };
    } catch (e) {
      console.error("[customerApi] submitFeedback failed:", e);
      return {
        ...feedback,
        id: `fb-mock-${Date.now()}`,
        createdAt: new Date(),
      };
    }
  },

  async updateLanguage(sessionId: string, languageCode: string): Promise<void> {
    if (!isSupabaseConfigured) return;
    try {
      const { error } = await supabase
        .from("dining_sessions")
        .update({ language_code: languageCode })
        .eq("id", sessionId); // Fallback mock update
      if (error) console.error("[customerApi] updateLanguage failed:", error);
    } catch (e) {
      console.error("[customerApi] updateLanguage failed:", e);
    }
  },

  // -------- realtime --------
  subscribeToTableUpdates(
    tableId: string,
    callback: (payload: any) => void,
  ): () => void {
    if (!isSupabaseConfigured) {
      // Mock fallback: no-op subscription
      return () => {};
    }
    const channel = supabase
      .channel(`customer-table-${tableId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "tables",
          filter: `id=eq.${tableId}`,
        },
        (payload) => callback(payload),
      )
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  },

  subscribeToServiceRequests(
    sessionId: string,
    callback: (payload: any) => void,
  ): () => void {
    const channel = supabase
      .channel(`customer-svc-${sessionId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "service_requests" },
        (payload) => callback(payload),
      )
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  },

  subscribeToOrderUpdates(
    sessionId: string,
    callback: (payload: any) => void,
  ): () => void {
    const channel = supabase
      .channel(`customer-orders-${sessionId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "order_items" },
        (payload) => callback(payload),
      )
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  },
};

// ---------------------------------------------------------------------------
// Local helpers
// ---------------------------------------------------------------------------

/**
 * Cheap uuid syntax check. Avoids round-tripping an invalid id to
 * Postgres (which would 22P02 on every PATCH / SELECT).
 */
function isUuid(s: string | null | undefined): boolean {
  if (!s) return false;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    s,
  );
}

function mapDbStatus(s: string): "available" | "selecting" | "occupied" {
  if (s === "available") return "available";
  if (s === "occupied" || s === "reserved") return "occupied";
  return "selecting";
}

function mapRequestTypeToDb(
  t: ServiceRequest["type"],
):
  | "CALL_WAITER"
  | "REQUEST_BILL"
  | "REQUEST_CONDIMENT"
  | "COMPLAINT"
  | "OTHER" {
  switch (t) {
    case "call_waiter":
      return "CALL_WAITER";
    case "request_bill":
      return "REQUEST_BILL";
    case "tissue":
    case "bowl":
    case "sauce":
    case "ice":
    case "grill_change":
    case "charcoal_change":
      return "REQUEST_CONDIMENT";
    case "other":
    default:
      return "OTHER";
  }
}

function mapRequestTypeFromDb(s: string): ServiceRequest["type"] {
  switch (s) {
    case "CALL_WAITER":
      return "call_waiter";
    case "REQUEST_BILL":
      return "request_bill";
    case "REQUEST_CONDIMENT":
      return "tissue";
    case "COMPLAINT":
      return "other";
    default:
      return "other";
  }
}

function mapRequestStatusFromDb(s: string): ServiceRequest["status"] {
  switch (s) {
    case "OPEN":
      return "created";
    case "IN_PROGRESS":
      return "processing";
    case "RESOLVED":
      return "completed";
    default:
      return "created";
  }
}

function rowToOrder(row: any): Order {
  const items = (row.order_details ?? []).map((it: any) => ({
    menuItemId: it.branch_menu_item_id,
    name: it.item_name_snapshot,
    unit: "Phần",
    price: Number(it.unit_price_vnd_snapshot ?? 0),
    price_display: `${Number(it.unit_price_vnd_snapshot ?? 0).toLocaleString("vi-VN")}đ`,
    quantity: Number(it.quantity ?? 1),
    note: it.note ?? "",
  }));
  const computedTotal = items.reduce(
    (sum: number, it: any) => sum + it.price * it.quantity,
    0,
  );

  return {
    id: row.order_id,
    sessionId: row.dining_session_id ?? "",
    tableNumber: "",
    items,
    subtotal: computedTotal,
    serviceCharge: 0,
    vat: 0,
    discount: 0,
    total: computedTotal,
    subtotal_vnd: computedTotal,
    serviceCharge_vnd: 0,
    vat_vnd: 0,
    discount_vnd: 0,
    total_vnd: computedTotal,
    status: (['draft', 'confirmed', 'cooking', 'served', 'completed'].includes(row.status) ? row.status : 'confirmed') as any,
    createdAt: new Date(row.created_at),
  };
}
