<!-- File: src/views/customer/SessionEnd.vue -->
<template>
  <div class="flex flex-col items-center justify-center min-h-[500px] gap-6 text-center p-8 max-w-md w-full mx-auto relative overflow-hidden select-none">
    
    <!-- Cherry blossom decoration background -->
    <div class="absolute -top-20 -right-20 w-48 h-48 bg-rose-500/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-20 -left-20 w-48 h-48 bg-amber-500/5 rounded-full blur-3xl pointer-events-none"></div>

    <div class="text-center">
      <div class="w-16 h-16 rounded-full bg-rose-600/10 border border-rose-500/20 flex items-center justify-center text-3xl mx-auto shadow-md mb-4 select-none">
        🌸
      </div>
      <h1 class="text-xl font-black text-amber-500 uppercase tracking-widest font-serif mb-1">NGƯU CÁT</h1>
      <h3 class="text-2xl font-black text-white font-serif tracking-wide">Cảm ơn bạn đã dùng bữa!</h3>
      <p class="text-gray-400 text-xs mt-1">Hẹn gặp lại bạn lần sau</p>
    </div>

    <!-- Invoice summary box (White Panel) -->
    <div class="bg-white border border-gray-200 rounded-2xl p-5 w-full shadow-lg text-[#333333] flex flex-col gap-3 font-sans">
      <div class="flex justify-between items-center text-xs font-bold text-[#666666] border-b border-gray-150 pb-2">
        <span>MÃ HÓA ĐƠN</span>
        <span class="text-[#333333] font-black uppercase">{{ finalInvoiceNumber }}</span>
      </div>

      <div class="flex justify-between items-center text-sm font-black text-[#333333] pt-1">
        <span>Tổng thanh toán:</span>
        <span class="text-[#C62828] text-base font-black">{{ finalTotalDisplay }}</span>
      </div>
    </div>

    <!-- QR Code Section -->
    <div class="bg-white border border-gray-200 rounded-2xl p-4 flex flex-col items-center justify-center gap-2.5 shadow-md w-full max-w-[200px]">
      <!-- Beautiful Mock SVG QR Code -->
      <svg class="w-28 h-28 text-[#333333]" viewBox="0 0 100 100" fill="currentColor">
        <rect x="0" y="0" width="25" height="25" />
        <rect x="5" y="5" width="15" height="15" fill="white" />
        <rect x="75" y="0" width="25" height="25" />
        <rect x="80" y="5" width="15" height="15" fill="white" />
        <rect x="0" y="75" width="25" height="25" />
        <rect x="5" y="80" width="15" height="15" fill="white" />
        <!-- Random dot matrix style -->
        <rect x="35" y="10" width="10" height="5" />
        <rect x="40" y="20" width="5" height="15" />
        <rect x="10" y="35" width="15" height="5" />
        <rect x="55" y="35" width="10" height="10" />
        <rect x="65" y="15" width="5" height="10" />
        <rect x="35" y="50" width="20" height="5" />
        <rect x="15" y="55" width="10" height="5" />
        <rect x="50" y="65" width="15" height="10" />
        <rect x="75" y="50" width="10" height="20" />
        <rect x="80" y="75" width="15" height="5" />
        <rect x="75" y="85" width="5" height="10" />
      </svg>
      <span class="text-[9px] font-black text-[#666666] tracking-widest uppercase">Quét QR đánh giá Google</span>
    </div>

    <!-- Timer Countdown indicator -->
    <div class="text-[11px] text-gray-400 bg-[#1a110a] border border-[#2d1e12] rounded-full px-4.5 py-2.5 flex items-center justify-center gap-2 w-full max-w-xs">
      <span class="w-2 h-2 rounded-full bg-amber-500 animate-ping shrink-0"></span>
      <span>Màn hình sẽ tự động reset sau <span class="font-black text-amber-500">{{ countdown }} giây...</span></span>
    </div>

    <!-- Staff override button -->
    <button @click="endSessionNow"
            class="text-[11px] font-black text-gray-500 hover:text-white transition-colors py-2 border-b border-transparent hover:border-gray-500 uppercase tracking-widest active:scale-95">
      Quay về chính (Nhân viên)
    </button>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';

const emit = defineEmits<{
  (e: 'done'): void;
}>();

const store = useCustomerStore();
const { clearSession } = useCustomerSession();
const countdown = ref(30);
let timerId: any = null;

// Dynamic Invoice computation
const finalInvoiceNumber = computed(() => {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const sessId = store.session?.id.slice(-4).toUpperCase() || '001';
  return `#INV-${dateStr}-${sessId}`;
});

// Dynamic Total computation
const finalTotalDisplay = computed(() => {
  const subtotal = store.orders.reduce((sum, order) => sum + order.subtotal, 0);
  const serviceCharge = Math.round(subtotal * 0.05);
  const vat = Math.round((subtotal + serviceCharge) * 0.08);
  const total = subtotal + serviceCharge + vat;
  if (total === 0) return '0đ';
  return total.toLocaleString('vi-VN') + 'đ';
});

onMounted(() => {
  timerId = setInterval(() => {
    countdown.value--;
    if (countdown.value <= 0) {
      endSessionNow();
    }
  }, 1000);
});

onUnmounted(() => {
  if (timerId) clearInterval(timerId);
});

function endSessionNow() {
  if (timerId) clearInterval(timerId);
  clearSession();
  emit('done');
}
</script>
