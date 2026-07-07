<!-- File: src/views/customer/OrderHistory.vue -->
<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-[#3D2817]">
    
    <!-- Sub Header Bar -->
    <div class="px-6 md:px-8 py-4 bg-[#1a110a] border-b border-[#2d1e12] flex items-center justify-between shrink-0">
      <div>
        <h1 class="text-lg md:text-xl font-black text-white font-serif tracking-wide">Lịch sử gọi món</h1>
        <p class="text-[10px] text-gray-400 mt-0.5">Theo dõi chi tiết món ăn đang chuẩn bị và hóa đơn tại bàn</p>
      </div>

      <div class="bg-[#2a1b10] border border-[#442c19] rounded-lg px-3.5 py-1.5 text-xs flex items-center gap-2">
        <span class="text-gray-400 font-bold">Tổng gọi:</span>
        <span class="text-[#E8772E] font-black text-xs">{{ totalItemsCount }} món</span>
      </div>
    </div>

    <!-- Main Content Split -->
    <div class="flex-1 flex flex-col lg:flex-row overflow-hidden">
      <!-- Ordered Items list (Wood background, scrollable) -->
      <div class="flex-1 overflow-y-auto p-6 md:p-8 flex flex-col gap-4">
        <div v-if="orders.length === 0" 
             class="flex-1 flex flex-col items-center justify-center text-center p-12 gap-4">
          <div class="w-16 h-16 bg-[#2a1b10] border border-[#442c19] rounded-full flex items-center justify-center text-3xl shadow-inner">
            🥩
          </div>
          <div>
            <h3 class="text-base font-bold text-white font-serif">Chưa gọi món nào</h3>
            <p class="text-xs text-gray-400 mt-1">Các món ăn sau khi bạn gửi bếp thành công sẽ xuất hiện ở đây.</p>
          </div>
        </div>

        <template v-else>
          <!-- Loop through orders (rendered in White cards) -->
          <div v-for="order in orders" :key="order.id" 
               class="bg-white border border-gray-200 rounded-2xl p-5 flex flex-col gap-3.5 shadow-sm">
            <!-- Order Header -->
            <div class="flex items-center justify-between border-b border-gray-100 pb-2.5">
              <div>
                <span class="text-[10px] text-gray-500 font-bold uppercase">Mã Order:</span>
                <span class="text-xs font-black text-[#E8772E] ml-1.5">{{ order.id.slice(-8).toUpperCase() }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-[10px] text-[#666666] font-bold">
                  {{ formatTime(order.createdAt) }}
                </span>
                <!-- Order Status -->
                <span :class="[
                  'text-[9px] font-black px-2.5 py-1 rounded-full border uppercase tracking-wider',
                  order.status === 'confirmed' ? 'bg-amber-500/10 text-amber-600 border-amber-500/20' :
                  order.status === 'cooking' ? 'bg-blue-500/10 text-blue-500 border-blue-500/20 animate-pulse' :
                  order.status === 'served' ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20' :
                  'bg-purple-500/10 text-purple-600 border-purple-500/20'
                ]">
                  {{ getStatusLabel(order.status) }}
                </span>
              </div>
            </div>

            <!-- Ordered Dishes inside this Order -->
            <div class="flex flex-col gap-2.5">
              <div v-for="item in order.items" :key="item.menuItemId"
                   class="flex items-center justify-between text-xs text-[#333333]">
                <div class="flex items-start gap-2.5">
                  <span class="w-5.5 h-5.5 bg-gray-105 rounded flex items-center justify-center text-[10px] text-gray-600 font-bold border border-gray-200">
                    {{ item.quantity }}
                  </span>
                  <div>
                    <h4 class="font-bold text-[#333333]">{{ item.name }}</h4>
                    <p v-if="item.note" class="text-[9px] text-[#E8772E] font-bold mt-0.5">
                      ✎ {{ item.note }}
                    </p>
                  </div>
                </div>
                <span class="font-extrabold text-[#C62828]">
                  {{ formatPrice(item.price * item.quantity) }}
                </span>
              </div>
            </div>
          </div>
        </template>
      </div>

      <!-- Bill Settlement Sidebar (Light Gray panel) -->
      <div v-if="orders.length > 0" 
           class="w-full lg:w-96 bg-[#F5F5F5] border-t lg:border-t-0 lg:border-l border-gray-300 p-6 md:p-8 flex flex-col justify-between shrink-0 text-[#333333]">
        
        <div class="flex flex-col gap-5">
          <h3 class="text-sm font-black text-[#333333] border-b border-gray-250 pb-3 flex items-center gap-2 font-serif uppercase tracking-wider">
            <span>🧾</span> Hóa đơn tạm tính tại bàn
          </h3>

          <div class="flex flex-col gap-3.5 text-xs">
            <div class="flex items-center justify-between text-[#666666] font-bold">
              <span>Tổng tiền món:</span>
              <span class="text-[#333333] font-black">{{ formatPrice(billSummary.subtotal) }}</span>
            </div>

            <div class="flex items-center justify-between text-[#666666] font-bold">
              <span>Phí dịch vụ phục vụ (5%):</span>
              <span class="text-[#333333] font-black">{{ formatPrice(billSummary.serviceCharge) }}</span>
            </div>

            <div class="flex items-center justify-between text-[#666666] font-bold">
              <span>Thuế VAT (8%):</span>
              <span class="text-[#333333] font-black">{{ formatPrice(billSummary.vat) }}</span>
            </div>

            <div v-if="billSummary.discount > 0" class="flex items-center justify-between text-rose-600 font-bold">
              <span>Chiết khấu/Giảm giá:</span>
              <span>-{{ formatPrice(billSummary.discount) }}</span>
            </div>

            <div class="border-t border-gray-200 my-1"></div>

            <div class="flex items-center justify-between text-sm font-black">
              <span class="text-[#333333]">Tổng cộng tạm tính:</span>
              <!-- Red price text -->
              <span class="text-[#C62828] text-lg font-black">{{ formatPrice(billSummary.total) }}</span>
            </div>
          </div>

          <!-- Helper instructions -->
          <div class="bg-gray-100 border border-gray-200 rounded-xl p-3.5 flex items-start gap-2.5">
            <span class="text-blue-500 mt-0.5 text-xs">ℹ</span>
            <p class="text-[10px] text-[#666666] leading-relaxed font-bold">
              Để tiến hành thanh toán tại bàn hoặc yêu cầu xuất hóa đơn đỏ VAT, vui lòng bấm nút bên dưới. Phục vụ sẽ đến hỗ trợ bạn ngay lập tức.
            </p>
          </div>
        </div>

        <div class="flex flex-col gap-3 mt-6 lg:mt-0">
          <button @click="requestVATInvoice"
                  class="w-full h-12 rounded-xl bg-white border border-gray-200 hover:bg-gray-50 text-[#333333] font-bold text-xs transition-colors active:scale-95 shadow-sm">
            📋 Yêu cầu hóa đơn VAT
          </button>
          
          <button @click="triggerPayment"
                  :disabled="store.session?.status === 'waiting_payment'"
                  :class="[
                    'w-full h-14 rounded-xl font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md flex items-center justify-center gap-2',
                    store.session?.status === 'waiting_payment'
                      ? 'bg-gray-200 text-gray-400 border border-gray-300 cursor-not-allowed'
                      : 'bg-[#E8772E] text-white hover:bg-amber-600 shadow-[#E8772E]/10'
                  ]">
            <span>💵</span>
            {{ store.session?.status === 'waiting_payment' ? 'Chờ phục vụ thanh toán...' : 'Yêu Cầu Thanh Toán' }}
          </button>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import Swal from 'sweetalert2';

const store = useCustomerStore();
const router = useRouter();

const orders = computed(() => store.orders);

// Aggregate items counts
const totalItemsCount = computed(() => {
  return orders.value.reduce((total, order) => {
    return total + order.items.reduce((sum, item) => sum + item.quantity, 0);
  }, 0);
});

// Calculate accumulated bill totals
const billSummary = computed(() => {
  const subtotal = orders.value.reduce((sum, order) => sum + order.subtotal, 0);
  const serviceCharge = Math.round(subtotal * 0.05);
  const vat = Math.round((subtotal + serviceCharge) * 0.08);
  const discount = orders.value.reduce((sum, order) => sum + (order.discount || 0), 0);
  const total = subtotal + serviceCharge + vat - discount;

  return {
    subtotal,
    serviceCharge,
    vat,
    discount,
    total
  };
});

onMounted(async () => {
  // BR-09: Require session
  if (!store.session) {
    router.push({ name: 'CustomerHome' });
    return;
  }
  await store.loadOrderHistory();
});

function triggerPayment() {
  Swal.fire({
    title: 'Gửi yêu cầu thanh toán?',
    text: 'Nhân viên sẽ mang hóa đơn đến thanh toán trực tiếp tại bàn của bạn.',
    icon: 'question',
    showCancelButton: true,
    confirmButtonColor: '#E8772E',
    cancelButtonColor: '#3085d6',
    confirmButtonText: 'Đúng, thanh toán!',
    cancelButtonText: 'Hủy'
  }).then(async (result) => {
    if (result.isConfirmed) {
      await store.requestPayment();
      // After "Yêu cầu thanh toán", keep the customer on the menu screen
      // so they can still see the order list and the "đang chờ thanh
      // toán" status badge. The cashier will pick the bill up from the
      // reception dashboard and process it from there. We must NOT push
      // them to /customer/Feedback (that would surface an empty rating
      // form) and we must NOT log them out (that would force them to
      // re-enter the staff passcode).
      router.push({ name: 'CustomerMenu' });
    }
  });
}

function requestVATInvoice() {
  Swal.fire({
    title: 'Yêu cầu hóa đơn đỏ?',
    text: 'Vui lòng cung cấp thông tin xuất hóa đơn cho phục vụ khi thanh toán.',
    icon: 'info',
    showCancelButton: true,
    confirmButtonColor: '#E8772E',
    confirmButtonText: 'Gửi yêu cầu',
    cancelButtonText: 'Hủy'
  }).then(async (result) => {
    if (result.isConfirmed) {
      await store.requestInvoice();
    }
  });
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    confirmed: 'Đã nhận',
    cooking: 'Đang nấu',
    served: 'Đã phục vụ',
    completed: 'Đã xong',
    paid: 'Đã thanh toán'
  };
  return labels[status] || status;
}

function formatPrice(val: number): string {
  return val.toLocaleString('vi-VN') + 'đ';
}

function formatTime(date: any): string {
  const d = new Date(date);
  return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
}
</script>
