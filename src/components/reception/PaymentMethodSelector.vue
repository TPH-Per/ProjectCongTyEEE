<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4 select-none"
    @click.self="handleClose"
  >
    <div
      class="bg-[#2d2d2d] border border-gray-700 rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl flex flex-col transform transition-all duration-300 scale-100 max-h-[90vh]"
    >
      <!-- Header -->
      <div class="p-4 bg-[#262626] border-b border-[#3a3a3a] flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-orange-500/10 border border-orange-500/30 flex items-center justify-center text-orange-500 text-lg">
            💵
          </div>
          <div>
            <h3 class="text-sm font-black uppercase text-orange-400 tracking-wider">
              {{ t('reception.payment.title', 'Thanh toán & Phương thức') }}
            </h3>
            <p class="text-[11px] text-gray-400 mt-0.5">
              {{ t('reception.payment.table', 'Bàn') }}: <span class="text-white font-bold">{{ tableCode || 'N/A' }}</span> | {{ t('reception.payment.total_bill', 'Tổng hóa đơn') }}: <span class="text-orange-400 font-bold">{{ formatCurrency(grandTotal) }}</span>
            </p>
          </div>
        </div>
        <button
          @click="handleClose"
          class="w-8 h-8 rounded-lg bg-[#3a3a3a] hover:bg-[#4a4a4a] text-gray-400 hover:text-white flex items-center justify-center text-xs transition-colors"
          type="button"
        >
          ✕
        </button>
      </div>

      <!-- Main Layout Split -->
      <div class="flex-1 flex flex-col md:flex-row overflow-hidden min-h-0">
        <!-- Left: Payment Selection & Detail Inputs -->
        <div class="flex-1 p-6 space-y-6 overflow-y-auto min-h-0 border-b md:border-b-0 md:border-r border-[#3a3a3a]">
          <!-- Grid of Large Touch-friendly Payment Methods -->
          <div class="space-y-2">
            <label class="block text-xs font-bold text-gray-400 uppercase tracking-wide">
              {{ t('reception.payment.select_method', 'Chọn phương thức thanh toán') }}
            </label>
            <div class="grid grid-cols-2 gap-3">
              <button
                v-for="m in methods"
                :key="m.id"
                @click="selectMethod(m.id)"
                :class="[
                  'p-4 rounded-xl border-2 text-left font-bold transition-all active:scale-95 flex items-center gap-3 min-h-[70px]',
                  activeMethod === m.id
                    ? 'border-orange-500 bg-orange-500/10 text-orange-400'
                    : 'border-[#3c3c3c] bg-[#242424] text-gray-300 hover:border-[#555]'
                ]"
                type="button"
              >
                <span class="text-2xl">{{ m.icon }}</span>
                <div class="leading-tight">
                  <div class="text-sm font-bold">{{ m.label }}</div>
                  <div class="text-[10px] text-gray-500 font-normal mt-0.5">{{ m.desc }}</div>
                </div>
              </button>
            </div>
          </div>

          <!-- Dynamic Input Fields based on activeMethod -->
          <div class="bg-[#1e1e1e] p-4 rounded-xl border border-[#3a3a3a] space-y-4">
            <div class="flex justify-between items-center">
              <span class="text-xs font-bold uppercase text-gray-400">{{ t('reception.payment.amount_to_pay', 'Số tiền thanh toán') }}</span>
              <span class="text-xs text-orange-400 font-bold">{{ t('reception.payment.remaining_label', 'Còn lại') }}: {{ formatCurrency(remainingAmount) }}</span>
            </div>
            
            <div class="relative">
              <input
                v-model.number="currentAmount"
                type="number"
                min="1"
                :max="remainingAmount"
                class="w-full bg-[#141414] border border-[#333] focus:border-orange-500 rounded-xl px-4 py-3 text-lg font-mono font-bold text-white focus:outline-none transition-colors"
                @input="clampCurrentAmount"
              />
              <span class="absolute right-4 top-1/2 -translate-y-1/2 font-bold text-gray-500 text-sm">VND</span>
            </div>

            <!-- Cash Method Details (Cash Calculator) -->
            <div v-if="activeMethod === 'CASH'" class="space-y-4 pt-2">
              <div class="space-y-1.5">
                <label class="block text-xs font-bold text-gray-400 uppercase tracking-wide">
                  {{ t('reception.payment.cash_given', 'Tiền khách đưa') }}
                </label>
                <div class="relative">
                  <input
                    v-model.number="customerPaid"
                    type="number"
                    min="0"
                    placeholder="Nhập số tiền..."
                    class="w-full bg-[#141414] border border-[#333] focus:border-orange-500 rounded-xl px-4 py-3 text-lg font-mono font-bold text-white focus:outline-none transition-colors"
                  />
                  <span class="absolute right-4 top-1/2 -translate-y-1/2 font-bold text-gray-500 text-sm">VND</span>
                </div>
              </div>

              <!-- Quick amount selectors -->
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="amt in quickAmounts"
                  :key="amt"
                  @click="customerPaid = amt"
                  class="px-3.5 py-2 bg-[#2d2d2d] hover:bg-[#3d3d3d] text-white text-xs font-bold rounded-lg transition-colors border border-[#3c3c3c] active:scale-95"
                  type="button"
                >
                  {{ formatShortCurrency(amt) }}
                </button>
                <button
                  @click="customerPaid = currentAmount"
                  class="px-3.5 py-2 bg-orange-600/20 hover:bg-orange-600/30 text-orange-400 border border-orange-500/30 text-xs font-bold rounded-lg transition-colors active:scale-95"
                  type="button"
                >
                  {{ t('reception.payment.exact', 'Vừa đủ') }}
                </button>
              </div>

              <!-- Change calculation display -->
              <div
                v-if="changeAmount > 0"
                class="p-4 bg-green-500/10 border border-green-500/30 rounded-xl flex items-center justify-between text-green-400"
              >
                <span class="text-xs font-bold uppercase">{{ t('reception.payment.change', 'Tiền thừa thối khách') }}</span>
                <span class="text-lg font-mono font-black">{{ formatCurrency(changeAmount) }}</span>
              </div>
            </div>

            <!-- VietQR Display -->
            <div v-else-if="activeMethod === 'QR'" class="flex flex-col items-center justify-center p-4 space-y-3 bg-[#242424] rounded-xl border border-[#3c3c3c]">
              <div class="relative w-36 h-36 bg-white rounded-lg p-2 flex items-center justify-center shadow-md overflow-hidden">
                <!-- QR Code representation (VietQR simulation) -->
                <div class="absolute inset-0 bg-gradient-to-t from-orange-500/5 to-transparent pointer-events-none"></div>
                <img
                  :src="`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=VietQR_Transfer_Table_${tableCode}_Amount_${currentAmount}`"
                  alt="VietQR code"
                  class="w-full h-full object-contain"
                />
                <!-- Scanning scanning beam effect -->
                <div class="absolute left-0 right-0 h-0.5 bg-orange-500 animate-scan shadow-[0_0_8px_#f97316]"></div>
              </div>
              <div class="text-center space-y-1">
                <p class="text-xs font-bold text-gray-300">VietQR chuyển khoản nhanh</p>
                <div class="flex items-center justify-center gap-1.5 text-[10px] text-orange-400">
                  <span class="w-1.5 h-1.5 bg-orange-400 rounded-full animate-ping"></span>
                  <span class="font-mono uppercase tracking-wider animate-pulse">{{ t('reception.payment.waiting', 'Đang chờ xác nhận quét mã...') }}</span>
                </div>
              </div>
            </div>

            <!-- Card / EDC reference -->
            <div v-else-if="activeMethod === 'CARD'" class="space-y-1.5">
              <label class="block text-xs font-bold text-gray-400 uppercase tracking-wide">
                {{ t('reception.payment.ref_code', 'Mã giao dịch / Mã tham chiếu') }}
              </label>
              <input
                v-model="referenceCode"
                type="text"
                placeholder="Nhập mã giao dịch thẻ..."
                class="w-full bg-[#141414] border border-[#333] focus:border-orange-500 rounded-xl px-4 py-3 text-sm text-white focus:outline-none transition-colors"
              />
            </div>

            <!-- Debt Note -->
            <div v-else-if="activeMethod === 'DEBT'" class="space-y-3">
              <div class="space-y-1.5">
                <label class="block text-xs font-bold text-gray-400 uppercase tracking-wide">
                  {{ t('reception.payment.debt_client', 'Ghi chú Khách nợ / Công ty') }} <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="debtNote"
                  type="text"
                  placeholder="Ví dụ: Công ty Rikkei, Khách quen Anh Hùng..."
                  class="w-full bg-[#141414] border border-[#333] focus:border-orange-500 rounded-xl px-4 py-3 text-sm text-white focus:outline-none transition-colors"
                />
              </div>
            </div>

            <!-- Add payment to stack -->
            <button
              @click="addPaymentToStack"
              :disabled="!canAddPayment"
              :class="[
                'w-full py-3 rounded-xl font-bold text-xs uppercase tracking-wider transition-all active:scale-95 flex items-center justify-center gap-1.5 border',
                canAddPayment
                  ? 'bg-orange-500 border-orange-400 text-white hover:bg-orange-600 shadow'
                  : 'bg-[#2a2a2a] border-[#3a3a3a] text-gray-500 cursor-not-allowed'
              ]"
              type="button"
            >
              <span>➕ {{ t('reception.payment.add_payment', 'Xác nhận phần thanh toán này') }}</span>
            </button>
          </div>
        </div>

        <!-- Right: Payment Stack & Split Progress -->
        <div class="w-full md:w-[240px] bg-[#222] p-6 flex flex-col justify-between overflow-hidden">
          <div class="space-y-5 flex-1 flex flex-col min-h-0">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wide border-b border-[#333] pb-2">
              {{ t('reception.payment.progress', 'Tiến trình thanh toán') }}
            </h4>

            <!-- Progress Bar -->
            <div class="space-y-2">
              <div class="flex justify-between text-xs font-bold font-mono">
                <span class="text-green-400">{{ percentPaid }}%</span>
                <span class="text-gray-400">{{ formatCurrency(totalPaid) }} / {{ formatCurrency(grandTotal) }}</span>
              </div>
              <div class="w-full h-3.5 bg-[#141414] rounded-full overflow-hidden border border-[#333] p-0.5">
                <div
                  class="h-full bg-gradient-to-r from-orange-600 to-green-500 rounded-full transition-all duration-300"
                  :style="{ width: `${percentPaid}%` }"
                ></div>
              </div>
            </div>

            <!-- Split Info Cards -->
            <div class="grid grid-cols-1 gap-2 text-xs font-bold">
              <div class="p-2.5 bg-[#2d2d2d] rounded-lg border border-[#3c3c3c] flex justify-between">
                <span class="text-gray-400">{{ t('reception.payment.sub_total', 'Tổng tiền') }}:</span>
                <span class="text-white font-mono">{{ formatCurrency(grandTotal) }}</span>
              </div>
              <div class="p-2.5 bg-green-500/10 rounded-lg border border-green-500/20 flex justify-between text-green-400">
                <span>{{ t('reception.payment.paid_label', 'Đã thu') }}:</span>
                <span class="font-mono">{{ formatCurrency(totalPaid) }}</span>
              </div>
              <div class="p-2.5 bg-red-500/10 rounded-lg border border-red-500/20 flex justify-between text-red-400">
                <span>{{ t('reception.payment.remaining', 'Còn thiếu') }}:</span>
                <span class="font-mono">{{ formatCurrency(remainingAmount) }}</span>
              </div>
            </div>

            <!-- Payment Stack Items List -->
            <div class="flex-1 flex flex-col min-h-0 space-y-2 pt-2">
              <span class="text-[10px] font-black uppercase text-gray-500 tracking-wide">{{ t('reception.payment.list_payments', 'Danh sách đã thu') }}</span>
              
              <div v-if="paymentStack.length === 0" class="flex-1 border border-dashed border-[#3c3c3c] rounded-xl flex items-center justify-center text-[11px] text-gray-500 text-center p-4">
                Chưa có phần thanh toán nào được xác nhận.
              </div>
              
              <div v-else class="flex-1 overflow-y-auto space-y-2 pr-1">
                <div
                  v-for="(p, index) in paymentStack"
                  :key="index"
                  class="p-2 bg-[#1a1a1a] rounded-lg border border-[#333] flex justify-between items-center group transition-colors hover:border-[#444]"
                >
                  <div class="space-y-0.5">
                    <div class="flex items-center gap-1.5">
                      <span class="text-xs">{{ getMethodIcon(p.method) }}</span>
                      <span class="text-[11px] font-bold text-gray-300">{{ getMethodLabel(p.method) }}</span>
                    </div>
                    <p class="text-[9px] text-gray-500 italic max-w-[140px] truncate" v-if="p.ref || p.note">
                      {{ p.ref || p.note }}
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="text-xs font-mono font-bold text-white">{{ formatCurrency(p.amount) }}</span>
                    <button
                      @click="removePaymentFromStack(index)"
                      class="text-gray-500 hover:text-red-500 text-[10px] w-5 h-5 rounded hover:bg-[#333] transition-all flex items-center justify-center"
                      title="Xóa"
                      type="button"
                    >
                      ✕
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Bottom Action Buttons -->
          <div class="pt-4 border-t border-[#333] space-y-2 shrink-0">
            <button
              @click="handlePaymentSubmit"
              :disabled="!isCompleted"
              :class="[
                'w-full py-3 rounded-xl font-bold text-xs uppercase tracking-wider transition-all active:scale-95 flex items-center justify-center gap-1.5 shadow',
                isCompleted
                  ? 'bg-green-600 hover:bg-green-700 text-white'
                  : 'bg-[#333] text-gray-500 border border-[#444] cursor-not-allowed'
              ]"
              type="button"
            >
              <span>✔️ {{ t('reception.payment.complete', 'Hoàn tất thanh toán') }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  grandTotal: {
    type: Number,
    required: true
  },
  tableCode: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['confirm', 'close']);
const { t } = useI18n();

// Component states
const activeMethod = ref('CASH');
const currentAmount = ref(props.grandTotal);
const customerPaid = ref(0);
const referenceCode = ref('');
const debtNote = ref('');
const paymentStack = ref([]);

// Available methods config
const methods = [
  { id: 'CASH', label: 'Tiền mặt', icon: '💵', desc: 'Thu ngân tiền mặt' },
  { id: 'CARD', label: 'Thẻ / EDC', icon: '💳', desc: 'Thẻ ATM, Visa, Mastercard' },
  { id: 'QR', label: 'VietQR / CK', icon: '📱', desc: 'Chuyển khoản QR ngân hàng' },
  { id: 'DEBT', label: 'Công nợ', icon: '💰', desc: 'Ghi nhận nợ công ty/khách VIP' }
];

const quickAmounts = [50000, 100000, 200000, 500000];

// Computed fields
const totalPaid = computed(() => {
  return paymentStack.value.reduce((sum, item) => sum + item.amount, 0);
});

const remainingAmount = computed(() => {
  return Math.max(0, props.grandTotal - totalPaid.value);
});

const percentPaid = computed(() => {
  if (props.grandTotal <= 0) return 0;
  return Math.min(100, Math.round((totalPaid.value / props.grandTotal) * 100));
});

const isCompleted = computed(() => {
  return totalPaid.value >= props.grandTotal;
});

const changeAmount = computed(() => {
  if (activeMethod.value !== 'CASH') return 0;
  return Math.max(0, customerPaid.value - currentAmount.value);
});

const canAddPayment = computed(() => {
  if (currentAmount.value <= 0) return false;
  if (activeMethod.value === 'CASH') {
    return customerPaid.value >= currentAmount.value;
  }
  if (activeMethod.value === 'DEBT') {
    return debtNote.value.trim().length > 0;
  }
  return true;
});

// Setup current amount initial value and restrict it
function selectMethod(methodId) {
  activeMethod.value = methodId;
  currentAmount.value = remainingAmount.value;
  customerPaid.value = 0;
  referenceCode.value = '';
  debtNote.value = '';
}

function clampCurrentAmount() {
  if (currentAmount.value > remainingAmount.value) {
    currentAmount.value = remainingAmount.value;
  }
}

// Add current payment details to payment list (stack)
function addPaymentToStack() {
  if (!canAddPayment.value) return;

  const payment = {
    method: activeMethod.value,
    amount: currentAmount.value
  };

  if (activeMethod.value === 'CASH') {
    payment.paid = customerPaid.value;
    payment.change = changeAmount.value;
  } else if (activeMethod.value === 'CARD') {
    payment.ref = referenceCode.value.trim();
  } else if (activeMethod.value === 'QR') {
    payment.ref = `QR_${Date.now()}`;
  } else if (activeMethod.value === 'DEBT') {
    payment.note = debtNote.value.trim();
  }

  paymentStack.value.push(payment);

  // Reset input fields
  customerPaid.value = 0;
  referenceCode.value = '';
  debtNote.value = '';

  // Auto select CASH again and set remaining
  selectMethod('CASH');
}

function removePaymentFromStack(index) {
  paymentStack.value.splice(index, 1);
  selectMethod('CASH');
}

// Complete payment callback
function handlePaymentSubmit() {
  if (isCompleted.value) {
    emit('confirm', {
      payments: paymentStack.value,
      grandTotal: props.grandTotal,
      totalPaid: totalPaid.value
    });
  }
}

function handleClose() {
  emit('close');
}

// Helper methods for label formatting
function getMethodIcon(methodId) {
  const m = methods.find(item => item.id === methodId);
  return m ? m.icon : '💵';
}

function getMethodLabel(methodId) {
  const m = methods.find(item => item.id === methodId);
  return m ? m.label : 'Tiền mặt';
}

function formatCurrency(val) {
  return Number(val).toLocaleString('vi-VN') + 'đ';
}

function formatShortCurrency(val) {
  if (val >= 1000) {
    return (val / 1000) + 'k';
  }
  return val;
}
</script>

<style scoped>
@keyframes scan {
  0% {
    top: 5%;
  }
  50% {
    top: 95%;
  }
  100% {
    top: 5%;
  }
}
.animate-scan {
  animation: scan 2s linear infinite;
}
</style>
