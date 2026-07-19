import { ref, computed } from "vue";
import Swal from "sweetalert2";
import { useRestaurantStore } from "@/stores/restaurantStore";
import { storeToRefs } from "pinia";
import { supabase } from "@/lib/supabase";
import { useTable } from "@/composables/useTable";
import { useAuth } from "@/composables/useAuth";
import { useLanguageStore } from "@/stores/useLanguageStore";

type ToastType = "success" | "warning" | "error" | "info";
type SelectionMode = "none" | "transfer" | "merge" | "split-order" | "split-item";

interface UseTableOperationsOptions {
  triggerToast: (type: ToastType, message: string) => void;
  formatVND: (value: number) => string;
  getActiveMainTab: () => string;
  setActiveMainTab: (val: string) => void;
  getFilteredTables: () => any[];
  getDbTablesList: () => any[];
  getSummary: () => any;
}

const allTableActions = [
  {
    id: "select_items",
    label: "Chọn món",
    icon: "📝",
    colorClass: "bg-green-500 text-white",
    description: "Thêm món vào bàn",
    isPrimary: true,
    group: "order",
  },
  {
    id: "transfer",
    label: "Chuyển bàn",
    icon: "🔁",
    colorClass: "bg-blue-500 text-white",
    description: "Di chuyển order sang bàn khác",
    group: "table",
  },
  {
    id: "merge",
    label: "Ghép phiếu",
    icon: "🔗",
    colorClass: "bg-purple-500 text-white",
    description: "Gộp order từ 2 bàn thành 1",
    group: "table",
  },
  {
    id: "split-order",
    label: "Tách phiếu",
    icon: "✂️",
    colorClass: "bg-orange-500 text-white",
    description: "Chia order thành nhiều phiếu",
    group: "order",
  },
  {
    id: "split-item",
    label: "Tách món",
    icon: "🍽️",
    colorClass: "bg-pink-500 text-white",
    description: "Tách riêng một số món",
    group: "order",
  },
  {
    id: "cancel",
    label: "Hủy phiếu",
    icon: "❌",
    colorClass: "bg-red-500 text-white",
    description: "Xóa toàn bộ order",
    group: "danger",
  },
];

export function useTableOperations(options: UseTableOperationsOptions) {
  const {
    triggerToast,
    formatVND,
    getActiveMainTab,
    setActiveMainTab,
    getFilteredTables,
    getDbTablesList,
    getSummary,
  } = options;

  const restaurantStore = useRestaurantStore();
  const { selectedTableCode } = storeToRefs(restaurantStore);
  const { listTables } = useTable();
  const langStore = useLanguageStore();
  const t = langStore.t;

  // ===== CONTEXT MENU STATE =====
  const showTableContextMenu = ref(false);
  const selectedTableForAction = ref<any>(null);
  const contextMenuPosition = ref({ x: 0, y: 0 });

  // Selection Mode state
  const selectionMode = ref<SelectionMode>("none");
  const sourceTableCode = ref<string>("");
  const selectedItemsToSplit = ref<string[]>([]);

  // Modal states (transfer/merge/split-order use selection mode, not modals;
  // these are kept for keyboard-handler compatibility)
  const showTransferModal = ref(false);
  const showMergeModal = ref(false);
  const showSplitOrderModal = ref(false);
  const showSplitItemModal = ref(false);
  const showCancelModal = ref(false);

  // Transfer state
  const transferTargetTable = ref("");
  const transferLoading = ref(false);

  // Merge state
  const mergeTargetTable = ref("");
  const mergeLoading = ref(false);

  // Split order state
  const splitOrderCount = ref(2);
  const splitOrderLoading = ref(false);

  // Split item state
  const splitItemLoading = ref(false);
  const splitItemQuantities = ref<Record<string, number>>({});

  // Cancel state
  const cancelConfirmText = ref("");
  const cancelLoading = ref(false);

  // ===== COMPUTED: Table actions for context menu =====
  const tableActions = computed(() => {
    const isEmpty =
      !selectedTableForAction.value ||
      selectedTableForAction.value.status === "Available";
    if (isEmpty) {
      return allTableActions.filter((a) => a.id === "select_items");
    }
    return allTableActions;
  });

  // ===== COMPUTED: Valid target tables for selection mode =====
  const validTargetTables = computed(() => {
    if (selectionMode.value === "none") return [];

    const allTables = restaurantStore.areas.flatMap((a) => a.tables);

    switch (selectionMode.value) {
      case "transfer":
        return allTables.filter(
          (t) => t.status === "Available" && t.code !== sourceTableCode.value,
        );
      case "merge":
        return allTables.filter((t) => {
          const order = restaurantStore.tableOrders[t.code];
          return (
            t.status !== "Available" &&
            t.code !== sourceTableCode.value &&
            order &&
            order.items &&
            order.items.length > 0
          );
        });
      case "split-order":
      case "split-item":
        return allTables.filter((t) => t.code !== sourceTableCode.value);
      default:
        return [];
    }
  });

  // Check if table is valid target
  function isValidTargetTable(tableCode: string): boolean {
    return validTargetTables.value.some((t) => t.code === tableCode);
  }

  // ===== COMPUTED: Split item total =====
  const splitItemTotal = computed(() => {
    const sourceOrder =
      restaurantStore.tableOrders[selectedTableForAction.value?.code];
    if (!sourceOrder?.items) return 0;
    return sourceOrder.items.reduce((sum: number, item: any) => {
      if (selectedItemsToSplit.value.includes(item.id)) {
        const qty = splitItemQuantities.value[item.id] || item.quantity;
        return sum + item.price * qty;
      }
      return sum;
    }, 0);
  });

  // ===== HANDLERS: Context menu =====
  function handleTableDoubleClick(table: any, event: MouseEvent) {
    selectedTableForAction.value = table;
    contextMenuPosition.value = { x: event.clientX, y: event.clientY };
    showTableContextMenu.value = true;
  }

  function handleTableListActionClick(table: any, event: MouseEvent) {
    selectedTableForAction.value = table;
    selectedTableCode.value = table.code;
    contextMenuPosition.value = { x: event.clientX, y: event.clientY };
    showTableContextMenu.value = true;
  }

  function handleTableAction(actionId: string) {
    showTableContextMenu.value = false;

    const table = selectedTableForAction.value;
    if (!table) return;

    switch (actionId) {
      case "select_items":
        setActiveMainTab("menu");
        selectedTableCode.value = table.code;
        triggerToast(
          "success",
          `Đã chọn bàn ${table.code} - Vui lòng chọn món`,
        );
        break;
      case "transfer":
        sourceTableCode.value = table.code;
        selectionMode.value = "transfer";
        triggerToast("info", `Chọn bàn đích để chuyển từ bàn ${table.code}`);
        break;
      case "merge":
        sourceTableCode.value = table.code;
        selectionMode.value = "merge";
        triggerToast("info", `Chọn bàn để ghép với bàn ${table.code}`);
        break;
      case "split-order":
        sourceTableCode.value = table.code;
        selectionMode.value = "split-order";
        triggerToast(
          "info",
          `Chọn bàn đích để tách phiếu từ bàn ${table.code}`,
        );
        break;
      case "split-item":
        sourceTableCode.value = table.code;
        selectionMode.value = "split-item";
        triggerToast("info", `Chọn bàn đích để tách món từ bàn ${table.code}`);
        break;
      case "cancel":
        showCancelModal.value = true;
        break;
    }
  }

  const closeContextMenu = () => {
    showTableContextMenu.value = false;
  };

  // ===== HANDLERS: Table click (dispatches to selection mode or select) =====
  function handleTableClick(table: any) {
    if (selectionMode.value !== "none") {
      handleTableClickInSelectionMode(table);
      return;
    }
    selectedTableCode.value = table.code;
  }

  // ===== HANDLERS: Selection mode =====
  const handleTableClickInSelectionMode = async (targetTable: any) => {
    if (selectionMode.value === "none") return;

    if (!isValidTargetTable(targetTable.code)) {
      triggerToast("warning", "Bàn chọn không hợp lệ!");
      return;
    }

    const sourceTable = restaurantStore.getTableByCode(sourceTableCode.value);
    if (!sourceTable) return;

    switch (selectionMode.value) {
      case "transfer":
        Swal.fire({
          title: "Xác nhận chuyển bàn?",
          text: `Chuyển toàn bộ order từ bàn ${sourceTable.code} sang bàn ${targetTable.code}?`,
          icon: "question",
          showCancelButton: true,
          confirmButtonText: "Đồng ý",
          cancelButtonText: "Hủy",
          confirmButtonColor: "#3b82f6",
        }).then(async (result) => {
          if (result.isConfirmed) {
            await executeTransfer(sourceTable, targetTable);
            exitSelectionMode();
          }
        });
        break;

      case "merge":
        Swal.fire({
          title: "Xác nhận ghép phiếu?",
          text: `Ghép phiếu bàn ${sourceTable.code} vào bàn ${targetTable.code}?`,
          icon: "question",
          showCancelButton: true,
          confirmButtonText: "Đồng ý",
          cancelButtonText: "Hủy",
          confirmButtonColor: "#8b5cf6",
        }).then(async (result) => {
          if (result.isConfirmed) {
            await executeMerge(sourceTable, targetTable);
            exitSelectionMode();
          }
        });
        break;

      case "split-order":
        Swal.fire({
          title: `Tách phiếu bàn ${sourceTable.code}`,
          text: "Tách thành bao nhiêu phiếu?",
          input: "number",
          inputValue: "2",
          inputAttributes: { min: "2", max: "10" },
          showCancelButton: true,
          confirmButtonText: "Tách",
          cancelButtonText: "Hủy",
          confirmButtonColor: "#f97316",
        }).then(async (result) => {
          if (result.isConfirmed && result.value) {
            splitOrderCount.value = parseInt(result.value) || 2;
            await executeSplitOrder(sourceTable, targetTable);
            exitSelectionMode();
          }
        });
        break;

      case "split-item":
        selectedTableForAction.value = sourceTable;
        transferTargetTable.value = targetTable.code;
        showSplitItemModal.value = true;
        break;
    }
  };

  const exitSelectionMode = () => {
    selectionMode.value = "none";
    sourceTableCode.value = "";
  };

  const cancelSelectionMode = () => {
    if (selectionMode.value !== "none") {
      triggerToast("info", "Đã hủy thao tác");
      exitSelectionMode();
    }
  };

  function getSelectionModeTitle(): string {
    switch (selectionMode.value) {
      case "transfer":
        return `Chuyển bàn từ ${sourceTableCode.value}`;
      case "merge":
        return `Ghép phiếu với bàn ${sourceTableCode.value}`;
      case "split-order":
        return `Tách phiếu từ bàn ${sourceTableCode.value}`;
      case "split-item":
        return `Tách món từ bàn ${sourceTableCode.value}`;
      default:
        return "";
    }
  }

  // ===== EXECUTE: Transfer =====
  async function executeTransfer(sourceTable: any, targetTable: any) {
    try {
      const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);
      if (!sourceOrder.items || sourceOrder.items.length === 0) {
        throw new Error("Bàn nguồn không có order!");
      }

      const targetOrder = restaurantStore.getOrCreateOrder(targetTable.code);
      targetOrder.items = [...sourceOrder.items];
      targetOrder.customerName = sourceOrder.customerName;
      targetOrder.openedTime = sourceOrder.openedTime;

      // Capture source table timing before clearing
      const sourceCheckInTime = sourceTable.checkInTime || "";
      const sourceOccupiedDuration = sourceTable.occupiedDuration || "";

      sourceOrder.items = [];
      sourceOrder.customerName = "";

      sourceTable.status = "Available";
      sourceTable.customerName = "";
      sourceTable.billAmount = "";
      sourceTable.checkInTime = "";
      sourceTable.occupiedDuration = "";

      targetTable.status = "Serving";
      targetTable.customerName = targetOrder.customerName;
      targetTable.checkInTime = sourceCheckInTime;
      targetTable.occupiedDuration = sourceOccupiedDuration;

      const total = targetOrder.items.reduce(
        (sum: number, item: any) => sum + item.price * item.quantity,
        0,
      );
      targetTable.billAmount = formatVND(total);

      triggerToast(
        "success",
        `Đã chuyển bàn ${sourceTable.code} sang bàn ${targetTable.code}`,
      );
      selectedTableCode.value = targetTable.code;
    } catch (error) {
      triggerToast(
        "error",
        error instanceof Error ? error.message : "Chuyển bàn thất bại!",
      );
    }
  }

  // ===== EXECUTE: Merge =====
  async function executeMerge(sourceTable: any, targetTable: any) {
    try {
      const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);
      const targetOrder = restaurantStore.getOrCreateOrder(targetTable.code);

      if (!sourceOrder.items || sourceOrder.items.length === 0) {
        throw new Error("Bàn nguồn không có order!");
      }

      targetOrder.items = [...targetOrder.items, ...sourceOrder.items];

      if (!targetOrder.customerName) {
        targetOrder.customerName = sourceOrder.customerName;
      }

      sourceOrder.items = [];
      sourceOrder.customerName = "";

      sourceTable.status = "Available";
      sourceTable.customerName = "";
      sourceTable.billAmount = "";
      sourceTable.checkInTime = "";
      sourceTable.occupiedDuration = "";

      const targetTotal = targetOrder.items.reduce(
        (sum: number, item: any) => sum + item.price * item.quantity,
        0,
      );
      targetTable.billAmount = formatVND(targetTotal);

      triggerToast(
        "success",
        `Đã ghép phiếu bàn ${sourceTable.code} vào bàn ${targetTable.code}`,
      );
      selectedTableCode.value = targetTable.code;
    } catch (error) {
      triggerToast(
        "error",
        error instanceof Error ? error.message : "Ghép phiếu thất bại!",
      );
    }
  }

  // ===== EXECUTE: Split order =====
  async function executeSplitOrder(sourceTable: any, targetTable: any) {
    try {
      const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);

      if (!sourceOrder.items || sourceOrder.items.length === 0) {
        throw new Error("Bàn không có order!");
      }

      const items = sourceOrder.items;
      const itemsPerSplit = Math.ceil(items.length / splitOrderCount.value);

      // Validate: enough available tables for all splits
      const requiredTargets = splitOrderCount.value - 1; // source keeps 1 portion
      const availableCount = getFilteredTables().filter(
        (t) =>
          t.status === "Available" &&
          t.code !== sourceTable.code &&
          t.code !== targetTable.code,
      ).length;

      // First target is the clicked table; remaining targets need available tables
      const extraTargetsNeeded = requiredTargets - 1; // -1 for the clicked targetTable
      if (extraTargetsNeeded > availableCount) {
        throw new Error(
          `Không đủ bàn trống để tách thành ${splitOrderCount.value} phiếu! Cần thêm ${extraTargetsNeeded - availableCount} bàn trống.`,
        );
      }

      const assignedCodes = new Set<string>();

      for (let i = 1; i < splitOrderCount.value; i++) {
        const splitItems = items.slice(
          i * itemsPerSplit,
          (i + 1) * itemsPerSplit,
        );

        if (splitItems.length > 0) {
          let availableTable: any = null;
          if (i === 1) {
            availableTable = targetTable;
          } else {
            availableTable = getFilteredTables().find(
              (t) =>
                t.status === "Available" &&
                t.code !== sourceTable.code &&
                t.code !== targetTable.code &&
                !assignedCodes.has(t.code),
            );
          }

          if (availableTable) {
            assignedCodes.add(availableTable.code);
            const splitOrder = restaurantStore.getOrCreateOrder(
              availableTable.code,
            );
            splitOrder.items = splitItems;
            splitOrder.customerName = sourceOrder.customerName;
            splitOrder.openedTime = sourceOrder.openedTime;

            const table = restaurantStore.getTableByCode(availableTable.code);
            if (table) {
              table.status = "Serving";
              table.customerName = splitOrder.customerName;
              const total = splitItems.reduce(
                (sum: number, item: any) => sum + item.price * item.quantity,
                0,
              );
              table.billAmount = formatVND(total);
            }
          }
        }
      }

      // Keep remaining items in source
      sourceOrder.items = items.slice(0, itemsPerSplit);
      if (sourceTable) {
        const sourceTotal = sourceOrder.items.reduce(
          (sum: number, item: any) => sum + item.price * item.quantity,
          0,
        );
        sourceTable.billAmount = formatVND(sourceTotal);
      }

      triggerToast("success", `Đã tách thành ${splitOrderCount.value} phiếu!`);
      splitOrderCount.value = 2;
    } catch (error) {
      triggerToast(
        "error",
        error instanceof Error ? error.message : "Tách phiếu thất bại!",
      );
    }
  }

  // ===== SPLIT ITEM HELPERS =====
  function toggleItemForSplit(item: any) {
    const index = selectedItemsToSplit.value.indexOf(item.id);
    if (index > -1) {
      selectedItemsToSplit.value.splice(index, 1);
      delete splitItemQuantities.value[item.id];
    } else {
      selectedItemsToSplit.value.push(item.id);
      splitItemQuantities.value[item.id] = item.quantity;
    }
  }

  function changeSplitQty(itemId: string, qty: number, maxQty: number) {
    const clamped = Math.max(1, Math.min(qty, maxQty));
    splitItemQuantities.value[itemId] = clamped;
  }

  function closeSplitItemModal() {
    showSplitItemModal.value = false;
    selectedItemsToSplit.value = [];
    splitItemQuantities.value = {};
    exitSelectionMode();
  }

  // ===== EXECUTE: Split item =====
  async function executeSplitItem() {
    if (selectedItemsToSplit.value.length === 0) {
      triggerToast("warning", "Vui lòng chọn ít nhất 1 món!");
      return;
    }

    splitItemLoading.value = true;

    try {
      const sourceOrder = restaurantStore.getOrCreateOrder(
        selectedTableForAction.value.code,
      );

      const targetCode = transferTargetTable.value;
      if (!targetCode) {
        throw new Error("Không có bàn đích để tách!");
      }

      const itemsToSplit = sourceOrder.items
        .filter((item: any) =>
          selectedItemsToSplit.value.includes(item.id),
        )
        .map((item: any) => {
          const qty = splitItemQuantities.value[item.id] || item.quantity;
          return { ...item, quantity: qty };
        });

      if (itemsToSplit.length === 0) {
        throw new Error("Không tìm thấy món cần tách!");
      }

      for (const splitItem of itemsToSplit) {
        const orig = sourceOrder.items.find((i: any) => i.id === splitItem.id);
        if (!orig) throw new Error(`Không tìm thấy món ${splitItem.name}`);
        if (splitItem.quantity > orig.quantity) {
          throw new Error(
            `Số lượng tách (${splitItem.quantity}) vượt quá số lượng hiện có (${orig.quantity}) cho món ${splitItem.name}`,
          );
        }
        if (splitItem.quantity < 1) {
          throw new Error(
            `Số lượng tách phải ít nhất 1 cho món ${splitItem.name}`,
          );
        }
      }

      const targetOrder = restaurantStore.getOrCreateOrder(targetCode);
      for (const splitItem of itemsToSplit) {
        targetOrder.items.push({
          ...splitItem,
          id: `${splitItem.id}-split-${Date.now()}`,
        });
      }
      if (!targetOrder.customerName) {
        targetOrder.customerName = sourceOrder.customerName;
        targetOrder.openedTime = sourceOrder.openedTime;
      }

      sourceOrder.items = sourceOrder.items
        .map((item: any) => {
          const splitQty = splitItemQuantities.value[item.id];
          if (
            splitQty &&
            selectedItemsToSplit.value.includes(item.id)
          ) {
            return { ...item, quantity: item.quantity - splitQty };
          }
          return item;
        })
        .filter((item: any) => item.quantity > 0);

      const targetTable = restaurantStore.getTableByCode(targetCode);
      if (targetTable) {
        targetTable.status = "Serving";
        if (!targetTable.customerName) {
          targetTable.customerName =
            targetOrder.customerName || "Khách tách món";
        }
        const targetTotal = targetOrder.items.reduce(
          (sum: number, item: any) => sum + item.price * item.quantity,
          0,
        );
        targetTable.billAmount = formatVND(targetTotal);
      }

      const sourceTable = restaurantStore.getTableByCode(
        selectedTableForAction.value.code,
      );
      if (sourceTable) {
        const sourceTotal = sourceOrder.items.reduce(
          (sum: number, item: any) => sum + item.price * item.quantity,
          0,
        );
        sourceTable.billAmount = formatVND(sourceTotal);
      }

      triggerToast(
        "success",
        `Đã tách ${itemsToSplit.length} món sang bàn ${targetCode}`,
      );
      showSplitItemModal.value = false;
      selectedItemsToSplit.value = [];
      splitItemQuantities.value = {};
      exitSelectionMode();
    } catch (error) {
      triggerToast(
        "error",
        error instanceof Error ? error.message : "Tách món thất bại!",
      );
    } finally {
      splitItemLoading.value = false;
    }
  }

  // ===== EXECUTE: Cancel =====
  async function executeCancel() {
    if (cancelConfirmText.value !== "HỦY") {
      triggerToast("warning", 'Vui lòng nhập "HỦY" để xác nhận!');
      return;
    }

    const { value: pin } = await Swal.fire({
      title: "Xác thực Quản lý",
      text: "Vui lòng nhập mã PIN của Quản lý để hủy đơn hàng:",
      input: "password",
      inputPlaceholder: "Nhập mã PIN",
      inputAttributes: {
        maxlength: "4",
        autocapitalize: "off",
        autocorrect: "off",
      },
      showCancelButton: true,
      cancelButtonText: "Quay lại",
      confirmButtonText: "Xác thực",
      confirmButtonColor: "#F44336",
    });

    if (pin === undefined) return;

    if (pin !== "1234") {
      Swal.fire("Lỗi", "Mã PIN xác thực không chính xác!", "error");
      return;
    }

    cancelLoading.value = true;

    try {
      const code = selectedTableForAction.value.code;
      let tableRow = (await listTables()).find((t: any) => t.code === code);
      if (!tableRow) {
        tableRow = getDbTablesList().find((t: any) => t.code === code);
      }
      if (
        tableRow &&
        tableRow.status === "occupied" &&
        !String(tableRow.id).startsWith("mock-")
      ) {
        const { branchId } = useAuth();
        const { data: checkoutData, error: getErr } = await supabase.rpc(
          "hall_get_checkout_totals",
          {
            p_branch_id: branchId.value,
            p_table_id: tableRow.id,
            p_order_id: null,
          },
        );
        if (getErr) throw getErr;

        if (checkoutData && checkoutData.order) {
          const { error: cancelErr } = await supabase.rpc(
            "hall_cancel_order_or_item",
            {
              p_branch_id: branchId.value,
              p_order_id: checkoutData.order.id,
              p_order_item_id: null,
              p_manager_pin: pin,
              p_reason: "Cashier cancelled entire order",
            },
          );
          if (cancelErr) throw cancelErr;
        }
      }

      const order = restaurantStore.getOrCreateOrder(code);
      order.items = [];
      order.customerName = "";
      order.openedTime = "";

      const table = restaurantStore.getTableByCode(code);
      if (table) {
        table.status = "Available";
        table.customerName = "";
        table.billAmount = "";
        table.checkInTime = "";
        table.occupiedDuration = "";
      }

      triggerToast("success", `Đã hủy phiếu bàn ${code}`);
      showCancelModal.value = false;
      cancelConfirmText.value = "";
      selectedTableCode.value = "";
    } catch (error: any) {
      triggerToast(
        "error",
        error instanceof Error ? error.message : "Hủy phiếu thất bại!",
      );
    } finally {
      cancelLoading.value = false;
    }
  }

  return {
    // Context menu state
    showTableContextMenu,
    selectedTableForAction,
    contextMenuPosition,
    tableActions,
    allTableActions,
    handleTableDoubleClick,
    handleTableListActionClick,
    handleTableAction,
    closeContextMenu,
    // Selection mode
    selectionMode,
    sourceTableCode,
    validTargetTables,
    isValidTargetTable,
    handleTableClick,
    handleTableClickInSelectionMode,
    exitSelectionMode,
    cancelSelectionMode,
    getSelectionModeTitle,
    // Split item modal
    showSplitItemModal,
    selectedItemsToSplit,
    splitItemQuantities,
    splitItemTotal,
    splitItemLoading,
    transferTargetTable,
    toggleItemForSplit,
    changeSplitQty,
    closeSplitItemModal,
    executeSplitItem,
    // Cancel modal
    showCancelModal,
    cancelConfirmText,
    cancelLoading,
    executeCancel,
    // Keyboard handler compatibility (unused but referenced)
    showTransferModal,
    showMergeModal,
    showSplitOrderModal,
    splitOrderCount,
  };
}
