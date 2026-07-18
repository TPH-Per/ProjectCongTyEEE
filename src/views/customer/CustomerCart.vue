<!-- File: src/views/customer/CustomerCart.vue -->
<template>
  <div class="cart-layout">
    <!-- Sub Header Bar -->
    <div class="cart-header">
      <div class="header-left">
        <button @click="backToMenu" class="btn-back" type="button">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
          </svg>
        </button>
        <div>
          <h1 class="header-title">Giỏ hàng của bạn</h1>
          <p class="header-subtitle">
            Rà soát lại số lượng và ghi chú trước khi chuyển vào bếp
          </p>
        </div>
      </div>

      <!-- Action buttons: bulk deletion and clear all -->
      <div v-if="cart.length > 0" class="header-actions">
        <button
          v-if="selectedIds.size > 0"
          @click="deleteSelectedItems"
          class="btn-bulk-delete"
          type="button"
        >
          Xóa đã chọn ({{ selectedIds.size }})
        </button>

        <button @click="clearAllCart" class="btn-clear-all" type="button">
          Xóa toàn bộ
        </button>
      </div>
    </div>

    <!-- Main Content Stream (Dark theme, scrollable) -->
    <div class="cart-content" :class="{ 'has-items': cart.length > 0 }">
      <!-- Empty State -->
      <div v-if="cart.length === 0" class="empty-cart-state">
        <div class="empty-icon-wrapper">🧺</div>
        <div>
          <h3 class="empty-title">Giỏ hàng của bạn đang trống</h3>
          <p class="empty-subtitle">Hãy thêm món từ thực đơn nhé!</p>
        </div>
        <button @click="backToMenu" class="btn-add-food" type="button">
          Thêm món ăn
        </button>

        <!-- Dev: Seed test data khi chưa có backend -->
        <button @click="seedTestData" class="btn-seed-test" type="button">
          🧪 Nạp dữ liệu test (mock)
        </button>
        <p v-if="!isSupabaseConfigured" class="mock-mode-hint">
          ⚠ Đang chạy chế độ offline — Supabase chưa cấu hình
        </p>
      </div>

      <!-- Non-empty Cart State -->
      <template v-else>
        <!-- Left Column: Item List & Selection -->
        <div class="cart-left-col">
          <!-- Checkbox Select All Toggle -->
          <div class="select-all-row">
            <input
              type="checkbox"
              :checked="isAllSelected"
              @change="toggleSelectAll"
              id="select-all"
              class="custom-checkbox"
            />
            <label for="select-all" class="select-all-label">
              Chọn tất cả ({{ cart.length }} món)
            </label>
          </div>

          <!-- Render list -->
          <div class="cart-items-list">
            <CartItem
              v-for="item in cart"
              :key="item.menuItemId"
              :item="item"
              :is-selected="selectedIds.has(item.menuItemId)"
              @toggle-select="toggleItemSelection(item.menuItemId)"
              @update-quantity="onUpdateQuantity(item.menuItemId, $event)"
              @update-note="onUpdateNote(item.menuItemId, $event)"
              @remove="onRemoveItem(item.menuItemId)"
            />
          </div>
        </div>

        <!-- Right Column: Billing Summary & Actions -->
        <div class="cart-right-col">
          <!-- Billing Summary Section at the bottom of the list (Matching UI-07 specs) -->
          <div class="billing-summary-card">
            <h3 class="summary-title">
              <span>📊</span> Chi tiết thanh toán tạm tính
            </h3>

            <div class="summary-details">
              <div class="summary-row">
                <span>Tổng số món:</span>
                <span class="value-highlight">{{ cart.length }} món</span>
              </div>
              <div class="summary-row">
                <span>Tổng số lượng:</span>
                <span class="value-highlight">{{ totalQtyCount }} phần</span>
              </div>
              <div class="summary-row">
                <span>Tiền món tạm tính:</span>
                <span class="value-highlight">{{ formatPrice(cartTotal) }}</span>
              </div>
              <div class="summary-row">
                <span>Phí dịch vụ (5%):</span>
                <span class="value-highlight">{{
                  formatPrice(serviceCharge)
                }}</span>
              </div>
              <div class="summary-row">
                <span>Thuế VAT (8%):</span>
                <span class="value-highlight">{{ formatPrice(vat) }}</span>
              </div>

              <div class="divider"></div>

              <div class="summary-row grand-total-row">
                <span>Tạm tính (gồm VAT + phí dịch vụ):</span>
                <span class="grand-total-price">{{
                  formatPrice(grandTotal)
                }}</span>
              </div>
            </div>
          </div>

          <!-- Sticky Bottom Actions Row -->
          <div class="cart-bottom-actions">
            <button
              @click="backToMenu"
              class="btn-continue-shopping"
              type="button"
            >
              Thêm món
            </button>

            <button
              @click="submitOrder"
              :disabled="submitting"
              class="btn-place-order"
              type="button"
            >
              <span v-if="submitting" class="spinner"></span>
              {{ submitting ? "Đang gửi..." : "Đặt món" }}
            </button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from "vue";
import { useRouter } from "vue-router";
import { useCustomerStore } from "@/stores/customerStore";
import { useCustomerSession } from "@/composables/useCustomerSession";
import { useBusinessRules } from "@/composables/useBusinessRules";
import { isSupabaseConfigured } from "@/lib/supabase";
import { mockCartItems, mockSession } from "@/data/mockCartData";
import CartItem from "@/components/customer/CartItem.vue";
import Swal from "sweetalert2";
import { isValidUUID } from "@/utils/validators";

const store = useCustomerStore();
const router = useRouter();
const { syncCart, saveSessionToLocalStorage } = useCustomerSession();
const { BR23, BR27, BR28 } = useBusinessRules();

const submitting = ref(false);
const selectedIds = reactive(new Set<string>());

const cart = computed(() => store.cart);
const cartTotal = computed(() => store.cartTotal);
const serviceCharge = computed(() => store.serviceCharge);
const vat = computed(() => store.vat);
const grandTotal = computed(() => store.grandTotal);

// Total quantity count (total parts/items sum)
const totalQtyCount = computed(() => {
  return cart.value.reduce((sum, item) => sum + item.quantity, 0);
});

// Selection management
const isAllSelected = computed(() => {
  return cart.value.length > 0 && selectedIds.size === cart.value.length;
});

function toggleItemSelection(itemId: string) {
  if (selectedIds.has(itemId)) {
    selectedIds.delete(itemId);
  } else {
    selectedIds.add(itemId);
  }
}

function toggleSelectAll() {
  if (isAllSelected.value) {
    selectedIds.clear();
  } else {
    cart.value.forEach((item) => selectedIds.add(item.menuItemId));
  }
}

function deleteSelectedItems() {
  Swal.fire({
    title: "Xác nhận xóa món đã chọn?",
    text: `Bạn có muốn xóa ${selectedIds.size} món ăn đang chọn khỏi giỏ hàng?`,
    icon: "warning",
    showCancelButton: true,
    confirmButtonColor: "#C62828",
    confirmButtonText: "Xóa ngay",
    cancelButtonText: "Hủy",
    background: "#1e1e1e",
    color: "#fff",
  }).then((result) => {
    if (result.isConfirmed) {
      selectedIds.forEach((id) => {
        store.removeFromCart(id);
      });
      selectedIds.clear();
      syncCart();
    }
  });
}

function onUpdateQuantity(itemId: string, qty: number) {
  store.updateCartItem(itemId, qty);
  syncCart();
}

// FIX: Update reactive Pinia state for notes
function onUpdateNote(itemId: string, note: string) {
  store.updateCartItemNote(itemId, note);
  syncCart();
}

function onRemoveItem(itemId: string) {
  store.removeFromCart(itemId);
  selectedIds.delete(itemId);
  syncCart();
}

function clearAllCart() {
  Swal.fire({
    title: "Xác nhận xóa?",
    text: "Bạn có chắc chắn muốn xóa toàn bộ món ăn trong giỏ?",
    icon: "warning",
    showCancelButton: true,
    confirmButtonColor: "#C62828",
    cancelButtonColor: "#3085d6",
    confirmButtonText: "Có, xóa hết!",
    cancelButtonText: "Hủy",
    background: "#1e1e1e",
    color: "#fff",
  }).then((result) => {
    if (result.isConfirmed) {
      store.clearCart();
      selectedIds.clear();
      syncCart();
    }
  });
}

function backToMenu() {
  router.push({ name: "CustomerMenu" });
}

/**
 * Nạp dữ liệu test tĩnh vào store để test UI cart mà không cần backend.
 * Tạo mock session + thêm cart items với UUID hợp lệ.
 */
function seedTestData() {
  // Tạo mock session nếu chưa có (để CustomerLayout không redirect)
  if (!store.session) {
    store.session = mockSession;
    store.isAuthenticated = true;
    store.currentView = "cart";
    saveSessionToLocalStorage();
  }
  // Thêm mock items vào cart (deep clone để tránh tham chiếu)
  store.cart = JSON.parse(JSON.stringify(mockCartItems));
  syncCart();

  Swal.fire({
    title: "Đã nạp dữ liệu test!",
    text: `Đã thêm ${mockCartItems.length} món ăn vào giỏ hàng. Giờ bạn có thể test các chức năng: tăng/giảm số lượng, ghi chú, chọn/xóa, và đặt món (mock).`,
    icon: "success",
    timer: 2500,
    showConfirmButton: false,
    background: "#1e1e1e",
    color: "#fff",
  });
}

async function submitOrder() {
  if (cart.value.length === 0) return;

  // Validate all items in the cart for valid UUID
  const invalidItems = cart.value.filter(item => !isValidUUID(item.menuItemId));
  if (invalidItems.length > 0) {
    Swal.fire({
      title: "Món ăn không hợp lệ",
      text: `Món ăn "${invalidItems[0].name}" có mã không hợp lệ. Vui lòng tải lại thực đơn hoặc liên hệ nhân viên!`,
      icon: "error",
      background: "#1e1e1e",
      color: "#fff",
    });
    return;
  }

  submitting.value = true;

  try {
    let order;

    if (!isSupabaseConfigured) {
      // ── Mock mode: simulate order locally ──
      await new Promise((resolve) => setTimeout(resolve, 800));
      order = {
        id: `ord-mock-${Date.now()}`,
        sessionId: store.session?.id ?? "sess-mock",
        tableNumber: store.session?.tableNumber ?? "A05",
        items: [...store.cart],
        subtotal: store.cartTotal,
        serviceCharge: store.serviceCharge,
        vat: store.vat,
        discount: 0,
        total: store.grandTotal,
        status: "confirmed" as const,
        createdAt: new Date(),
      };
      store.orders.push(order);
      store.clearCart();
      syncCart();
    } else {
      // ── Live mode: gọi API thật ──
      order = await store.confirmOrder();
      syncCart();
    }

    // BR-23: Group by kitchen station (meat, salad, hot)
    const tickets = BR23(order);

    // BR-27 / BR-28: Simulate printing kitchen tickets
    tickets.forEach((ticket) => {
      BR28(ticket); // increment printed count
      console.log(
        BR27(ticket, store.session?.tableNumber || "A02"),
        "Printed items count:",
        ticket.items.length,
      );
    });

    Swal.fire({
      title: "Đặt món thành công!",
      text: "Bếp đang chuẩn bị món ăn của bạn. Vui lòng chờ trong ít phút.",
      icon: "success",
      confirmButtonColor: "#E8772E",
      background: "#1e1e1e",
      color: "#fff",
    }).then(() => {
      router.push({ name: "OrderHistory" });
    });
  } catch (err: any) {
    console.error(err);
    Swal.fire({
      title: "Lỗi đặt món",
      text: err.message || "Có lỗi xảy ra trong quá trình gửi bếp.",
      icon: "error",
      background: "#1e1e1e",
      color: "#fff",
    });
  } finally {
    submitting.value = false;
  }
}

function formatPrice(val: number): string {
  return val.toLocaleString("vi-VN") + "đ";
}
</script>

<style scoped>
.cart-layout {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #121212;
  color: white;
}

.cart-header {
  padding: 16px 24px;
  background: #1a110a;
  border-bottom: 1px solid #2d1e12;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-back {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #2d2d2d;
  border: 1px solid #444;
  color: #a0a0a0;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-back:hover {
  color: white;
  background: #3d3d3d;
  transform: scale(1.05);
}

.header-title {
  font-size: 20px;
  font-weight: 800;
  color: white;
  margin: 0;
  font-family: inherit;
}

.header-subtitle {
  font-size: 11px;
  color: #888;
  margin: 2px 0 0 0;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-bulk-delete {
  font-size: 12px;
  font-weight: 700;
  color: #ff6b6b;
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.2);
  padding: 8px 16px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-bulk-delete:hover {
  background: rgba(255, 107, 107, 0.2);
}

.btn-clear-all {
  font-size: 12px;
  font-weight: 700;
  color: #a0a0a0;
  background: #2d2d2d;
  border: 1px solid #444;
  padding: 8px 16px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-clear-all:hover {
  color: white;
  background: #3d3d3d;
}

.cart-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Empty State */
.empty-cart-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 80px 20px;
  gap: 20px;
}

.empty-icon-wrapper {
  width: 80px;
  height: 80px;
  background: #1e1e1e;
  border: 1px solid #333;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36px;
  box-shadow: inset 0 4px 10px rgba(0, 0, 0, 0.5);
}

.empty-title {
  font-size: 18px;
  font-weight: 700;
  color: white;
  margin: 0 0 4px 0;
}

.empty-subtitle {
  font-size: 13px;
  color: #888;
  margin: 0;
}

.btn-add-food {
  height: 48px;
  padding: 0 32px;
  border-radius: 12px;
  background: #ff9800;
  color: white;
  font-weight: 800;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.2);
}

.btn-add-food:hover {
  background: #e68a00;
  transform: translateY(-1px);
}

.btn-seed-test {
  height: 44px;
  padding: 0 24px;
  border-radius: 12px;
  background: transparent;
  border: 2px dashed #555;
  color: #a0a0a0;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-seed-test:hover {
  border-color: #ff9800;
  color: #ff9800;
  background: rgba(255, 152, 0, 0.05);
}

.mock-mode-hint {
  font-size: 12px;
  color: #f59e0b;
  margin: 0;
  font-weight: 600;
}

/* Select All Row */
.select-all-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 8px;
}

.custom-checkbox {
  width: 18px;
  height: 18px;
  border-radius: 5px;
  border: 2px solid #555;
  background: transparent;
  accent-color: #ff9800;
  cursor: pointer;
}

.select-all-label {
  font-size: 13px;
  font-weight: 700;
  color: #a0a0a0;
  cursor: pointer;
}

.cart-items-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 800px;
  width: 100%;
  margin: 0 auto;
}

/* Billing Summary Card */
.billing-summary-card {
  background: #1e1e1e;
  border: 1px solid #333;
  border-radius: 20px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  color: #e0e0e0;
  max-width: 800px;
  width: 100%;
  margin: 16px auto 0 auto;
  box-sizing: border-box;
}

.summary-title {
  font-size: 12px;
  font-weight: 800;
  color: #888;
  border-bottom: 1px solid #333;
  padding-bottom: 10px;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 1px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.summary-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  color: #a0a0a0;
  font-weight: 600;
}

.value-highlight {
  color: white;
  font-weight: 700;
}

.divider {
  height: 1px;
  background: #333;
  margin: 4px 0;
}

.grand-total-row {
  font-size: 14px;
  font-weight: 800;
  color: white;
}

.grand-total-price {
  color: #ff9800;
  font-size: 18px;
  font-weight: 850;
}

/* Sticky Bottom Actions */
.cart-bottom-actions {
  display: flex;
  align-items: center;
  gap: 16px;
  max-width: 800px;
  width: 100%;
  margin: 12px auto 0 auto;
  padding-bottom: 24px;
}

.btn-continue-shopping {
  flex: 1;
  height: 52px;
  border-radius: 12px;
  background: #2d2d2d;
  border: 1px solid #444;
  color: white;
  font-weight: 800;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-continue-shopping:hover {
  background: #3d3d3d;
}

.btn-place-order {
  flex: 1;
  height: 52px;
  border-radius: 12px;
  background: #ff9800;
  color: white;
  font-weight: 800;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.btn-place-order:hover:not(:disabled) {
  background: #e68a00;
  transform: translateY(-1px);
}

.btn-place-order:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid white;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Layout columns for desktop/tablet landscape (no scroll for billing card) */
.cart-content.has-items {
  display: flex;
  flex-direction: row;
  gap: 24px;
  overflow: hidden;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
  box-sizing: border-box;
}

.cart-left-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
  overflow-y: auto;
  padding-right: 8px;
}

.cart-right-col {
  width: 380px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  flex-shrink: 0;
  justify-content: flex-start;
}

.cart-right-col .billing-summary-card {
  margin: 0;
  max-width: none;
}

.cart-right-col .cart-bottom-actions {
  margin: 0;
  max-width: none;
  padding-bottom: 0;
}

/* Hide scrollbars for left column but allow scrolling */
.cart-left-col::-webkit-scrollbar {
  width: 6px;
}
.cart-left-col::-webkit-scrollbar-track {
  background: transparent;
}
.cart-left-col::-webkit-scrollbar-thumb {
  background: #333;
  border-radius: 3px;
}

@media (max-width: 1024px) {
  .cart-content.has-items {
    flex-direction: column;
    overflow-y: auto;
  }
  
  .cart-left-col {
    overflow-y: visible;
    padding-right: 0;
  }
  
  .cart-right-col {
    width: 100%;
  }
}
</style>
