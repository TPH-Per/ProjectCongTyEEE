<!-- File: src/views/customer/CustomerCart.vue -->
<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-[#3D2817]">
    
    <!-- Sub Header Bar -->
    <div class="px-6 md:px-8 py-4 bg-[#1a110a] border-b border-[#2d1e12] flex items-center justify-between shrink-0">
      <div class="flex items-center gap-3">
        <button @click="backToMenu" 
                class="flex items-center justify-center w-8 h-8 rounded-lg bg-[#2a1b10] border border-[#442c19] text-gray-400 hover:text-white transition-all active:scale-90">
          ←
        </button>
        <div>
          <h1 class="text-lg md:text-xl font-black text-white font-serif tracking-wide">Giỏ hàng của bạn</h1>
          <p class="text-[10px] text-gray-400 mt-0.5">Rà soát lại số lượng và ghi chú trước khi chuyển vào bếp</p>
        </div>
      </div>

      <!-- Action buttons: bulk deletion and clear all -->
      <div v-if="cart.length > 0" class="flex items-center gap-2">
        <button v-if="selectedIds.size > 0"
                @click="deleteSelectedItems"
                class="text-xs font-bold text-rose-400 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/20 px-3.5 py-1.5 rounded-lg transition-colors active:scale-95">
          Xóa đã chọn ({{ selectedIds.size }})
        </button>
        
        <button @click="clearAllCart"
                class="text-xs font-bold text-gray-400 bg-[#2a1b10] hover:bg-gray-800 border border-gray-700 px-3.5 py-1.5 rounded-lg transition-colors active:scale-95">
          Xóa toàn bộ
        </button>
      </div>
    </div>

    <!-- Main Content Stream (Wood background, scrollable) -->
    <div class="flex-1 overflow-y-auto p-6 md:p-8 flex flex-col gap-6">
      
      <!-- Empty State -->
      <div v-if="cart.length === 0" 
           class="flex-1 flex flex-col items-center justify-center text-center py-16 gap-5 select-none">
        <div class="w-20 h-20 bg-[#2a1b10] border border-[#442c19] rounded-full flex items-center justify-center text-4xl shadow-inner">
          🧺
        </div>
        <div>
          <h3 class="text-lg font-bold text-white mb-1 font-serif">Giỏ hàng của bạn đang trống</h3>
          <p class="text-xs text-gray-400 max-w-xs leading-relaxed">
            Hãy thêm món từ thực đơn nhé!
          </p>
        </div>
        <button @click="backToMenu"
                class="h-12 px-8 rounded-xl bg-[#E8772E] hover:bg-amber-600 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-lg shadow-amber-500/10">
          Thêm món
        </button>
      </div>

      <!-- Non-empty Cart State -->
      <template v-else>
        <!-- Checkbox Select All Toggle -->
        <div class="flex items-center gap-2.5 px-4 select-none">
          <input type="checkbox" 
                 :checked="isAllSelected" 
                 @change="toggleSelectAll" 
                 id="select-all" 
                 class="w-5 h-5 rounded-lg border-gray-350 text-[#E8772E] focus:ring-[#E8772E]/50 focus:ring-2 cursor-pointer transition-colors" />
          <label for="select-all" class="text-xs font-bold text-gray-300 cursor-pointer">
            Chọn tất cả ({{ cart.length }} món)
          </label>
        </div>

        <!-- Render list -->
        <div class="flex flex-col gap-3.5">
          <CartItem v-for="item in cart" :key="item.menuItemId"
                    :item="item"
                    :is-selected="selectedIds.has(item.menuItemId)"
                    @toggle-select="toggleItemSelection(item.menuItemId)"
                    @update-quantity="onUpdateQuantity(item.menuItemId, $event)"
                    @update-note="onUpdateNote(item.menuItemId, $event)"
                    @remove="onRemoveItem(item.menuItemId)" />
        </div>

        <!-- Billing Summary Section at the bottom of the list (Matching UI-07 specs) -->
        <div class="bg-white border border-gray-200 rounded-2xl p-5 md:p-6 flex flex-col gap-4 text-[#333333] shadow-sm max-w-2xl mx-auto w-full mt-4">
          <h3 class="text-xs font-black text-[#333333] border-b border-gray-200 pb-2.5 flex items-center gap-2 font-serif uppercase tracking-wider">
            <span>📊</span> Chi tiết thanh toán tạm tính
          </h3>

          <div class="flex flex-col gap-2.5 text-xs font-bold text-[#666666]">
            <div class="flex justify-between items-center">
              <span>Tổng số món:</span>
              <span class="text-[#333333] font-black">{{ cart.length }} món</span>
            </div>
            <div class="flex justify-between items-center">
              <span>Tổng số lượng:</span>
              <span class="text-[#333333] font-black">{{ totalQtyCount }} phần</span>
            </div>
            <div class="flex justify-between items-center">
              <span>Tiền món tạm tính:</span>
              <span class="text-[#333333] font-black">{{ formatPrice(cartTotal) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span>Phí dịch vụ (5%):</span>
              <span class="text-[#333333] font-black">{{ formatPrice(serviceCharge) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span>Thuế VAT (8%):</span>
              <span class="text-[#333333] font-black">{{ formatPrice(vat) }}</span>
            </div>
            
            <div class="border-t border-gray-150 my-1"></div>

            <div class="flex justify-between items-center text-sm font-black text-[#333333]">
              <span>Tạm tính (gồm VAT + phí dịch vụ):</span>
              <span class="text-[#C62828] text-base font-black">{{ formatPrice(grandTotal) }}</span>
            </div>
          </div>
        </div>

        <!-- Sticky Bottom Actions Row -->
        <div class="flex items-center justify-center gap-4 max-w-2xl mx-auto w-full mt-2 select-none shrink-0 pb-6">
          <button @click="backToMenu"
                  class="flex-1 h-14 rounded-xl bg-white border border-gray-200 hover:bg-gray-50 text-[#333333] font-extrabold text-sm transition-colors active:scale-95 shadow-sm">
            Thêm món
          </button>
          
          <button @click="submitOrder"
                  :disabled="submitting"
                  class="flex-1 h-14 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-sm tracking-wider uppercase transition-all active:scale-95 shadow-md flex items-center justify-center gap-2">
            <span v-if="submitting" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            {{ submitting ? 'Đang gửi...' : 'Đặt món' }}
          </button>
        </div>

      </template>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';
import { useBusinessRules } from '@/composables/useBusinessRules';
import CartItem from '@/components/customer/CartItem.vue';
import Swal from 'sweetalert2';

const store = useCustomerStore();
const router = useRouter();
const { syncCart } = useCustomerSession();
const { BR23, BR27, BR28 } = useBusinessRules();

const submitting = ref(false);
const selectedIds = reactive(new Set<string>());

const cart = computed(() => store.cart);
const cartItemCount = computed(() => store.cartItemCount);
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
    cart.value.forEach(item => selectedIds.add(item.menuItemId));
  }
}

function deleteSelectedItems() {
  Swal.fire({
    title: 'Xác nhận xóa món đã chọn?',
    text: `Bạn có muốn xóa ${selectedIds.size} món ăn đang chọn khỏi giỏ hàng?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#C62828',
    confirmButtonText: 'Xóa ngay',
    cancelButtonText: 'Hủy'
  }).then((result) => {
    if (result.isConfirmed) {
      selectedIds.forEach(id => {
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

function onUpdateNote(itemId: string, note: string) {
  const item = store.cart.find(c => c.menuItemId === itemId);
  if (item) {
    item.note = note;
  }
  syncCart();
}

function onRemoveItem(itemId: string) {
  store.removeFromCart(itemId);
  selectedIds.delete(itemId);
  syncCart();
}

function clearAllCart() {
  Swal.fire({
    title: 'Xác nhận xóa?',
    text: 'Bạn có chắc chắn muốn xóa toàn bộ món ăn trong giỏ?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#C62828',
    cancelButtonColor: '#3085d6',
    confirmButtonText: 'Có, xóa hết!',
    cancelButtonText: 'Hủy'
  }).then((result) => {
    if (result.isConfirmed) {
      store.clearCart();
      selectedIds.clear();
      syncCart();
    }
  });
}

function backToMenu() {
  router.push({ name: 'CustomerMenu' });
}

async function submitOrder() {
  if (cart.value.length === 0) return;
  submitting.value = true;
  
  try {
    const order = await store.confirmOrder();
    syncCart();

    // BR-23: Group by kitchen station (meat, salad, hot)
    const tickets = BR23(order);
    
    // BR-27 / BR-28: Simulate printing kitchen tickets
    tickets.forEach(ticket => {
      BR28(ticket); // increment printed count
      console.log(BR27(ticket, store.session?.tableNumber || 'A02'), 'Printed items count:', ticket.items.length);
    });

    Swal.fire({
      title: 'Đặt món thành công!',
      text: 'Bếp đang chuẩn bị món ăn của bạn. Vui lòng chờ trong ít phút.',
      icon: 'success',
      confirmButtonColor: '#E8772E'
    }).then(() => {
      router.push({ name: 'OrderHistory' });
    });
  } catch (err: any) {
    console.error(err);
    Swal.fire('Lỗi đặt món', err.message || 'Có lỗi xảy ra trong quá trình gửi bếp.', 'error');
  } finally {
    submitting.value = false;
  }
}

function formatPrice(val: number): string {
  return val.toLocaleString('vi-VN') + 'đ';
}
</script>
