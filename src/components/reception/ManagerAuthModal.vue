<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4 select-none"
  >
    <div
      class="bg-[#2d2d2d] border border-red-500/30 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col transform transition-all duration-300 scale-100"
    >
      <!-- Header -->
      <div class="p-4 bg-gradient-to-r from-red-950/80 to-[#2d2d2d] border-b border-red-500/20 flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-red-500/10 border border-red-500/30 flex items-center justify-center text-red-500 text-lg">
          ⚠️
        </div>
        <div class="flex-1">
          <h3 class="text-sm font-black uppercase text-red-400 tracking-wider">
            {{ title }}
          </h3>
          <p class="text-[11px] text-gray-400 mt-0.5">
            {{ targetName ? `${t('reception.auth.target', 'Đối tượng')}: ${targetName}` : t('reception.auth.subtitle', 'Yêu cầu quyền Quản lý để tiếp tục') }}
          </p>
        </div>
        <button
          @click="handleClose"
          class="w-8 h-8 rounded-lg bg-[#3a3a3a] hover:bg-[#4a4a4a] text-gray-400 hover:text-white flex items-center justify-center text-xs transition-colors"
          type="button"
        >
          ✕
        </button>
      </div>

      <!-- Content -->
      <div class="p-6 space-y-5 flex-1 overflow-y-auto max-h-[80vh]">
        <!-- Dropdown Reason -->
        <div class="space-y-1.5">
          <label class="block text-xs font-bold text-gray-300 uppercase tracking-wide">
            {{ t('reception.auth.reason_label', 'Lý do thao tác') }} <span class="text-red-500">*</span>
          </label>
          <div class="relative">
            <select
              v-model="selectedReason"
              class="w-full bg-[#1e1e1e] border border-[#444] hover:border-[#555] rounded-xl px-4 py-3 text-sm text-white font-semibold focus:outline-none focus:border-red-500 transition-colors cursor-pointer appearance-none"
            >
              <option value="" disabled>{{ t('reception.auth.select_reason', '-- Chọn lý do --') }}</option>
              <option v-for="r in reasons" :key="r" :value="r">{{ r }}</option>
              <option value="Khác...">{{ t('reception.auth.other_reason', 'Khác...') }}</option>
            </select>
            <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400 text-xs">
              ▼
            </div>
          </div>

          <!-- Textarea if "Khác..." is selected -->
          <div v-if="selectedReason === 'Khác...'" class="mt-2">
            <textarea
              v-model="customReason"
              rows="2"
              :placeholder="t('reception.auth.reason_placeholder', 'Nhập chi tiết lý do...')"
              class="w-full bg-[#1e1e1e] border border-[#444] focus:border-red-500 rounded-xl px-4 py-2 text-sm text-white focus:outline-none transition-colors"
            ></textarea>
          </div>
        </div>

        <!-- PIN display dots -->
        <div class="space-y-2">
          <label class="block text-xs font-bold text-gray-300 uppercase tracking-wide text-center">
            {{ t('reception.auth.enter_pin', 'Mã PIN xác thực (6 số)') }}
          </label>
          <div class="flex justify-center gap-3">
            <div
              v-for="i in 6"
              :key="i"
              :class="[
                'w-10 h-10 rounded-xl border flex items-center justify-center transition-all duration-150',
                pin.length >= i
                  ? 'border-red-500 bg-red-500/10 shadow-[0_0_8px_rgba(239,68,68,0.2)]'
                  : 'border-[#444] bg-[#1e1e1e]'
              ]"
            >
              <span
                v-if="pin.length >= i"
                class="w-3.5 h-3.5 rounded-full bg-red-500 animate-scale-up"
              ></span>
            </div>
          </div>
        </div>

        <!-- Virtual PIN Pad -->
        <div class="grid grid-cols-3 gap-3 max-w-[280px] mx-auto pt-2">
          <button
            v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]"
            :key="num"
            @click="pressNum(String(num))"
            class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] active:bg-red-500/20 border border-[#3c3c3c] hover:border-[#555] text-white text-lg font-bold transition-all active:scale-95 flex items-center justify-center"
            type="button"
          >
            {{ num }}
          </button>
          <button
            @click="clearPin"
            class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] border border-[#3c3c3c] text-xs font-bold text-gray-400 hover:text-white transition-all active:scale-95 flex items-center justify-center uppercase"
            type="button"
          >
            {{ t('reception.auth.clear', 'Xóa hết') }}
          </button>
          <button
            @click="pressNum('0')"
            class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] active:bg-red-500/20 border border-[#3c3c3c] hover:border-[#555] text-white text-lg font-bold transition-all active:scale-95 flex items-center justify-center"
            type="button"
          >
            0
          </button>
          <button
            @click="backspace"
            class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] border border-[#3c3c3c] text-lg font-bold text-gray-400 hover:text-white transition-all active:scale-95 flex items-center justify-center"
            type="button"
          >
            ⌫
          </button>
        </div>
      </div>

      <!-- Footer Buttons -->
      <div class="p-4 bg-[#222] border-t border-[#333] flex justify-end gap-3">
        <button
          @click="handleClose"
          class="px-5 py-2.5 bg-[#3a3a3a] hover:bg-[#4a4a4a] text-white text-xs font-bold rounded-xl transition-all active:scale-95"
          type="button"
        >
          {{ t('reception.auth.cancel', 'Bỏ qua') }}
        </button>
        <button
          @click="handleConfirm"
          :disabled="!isValid"
          :class="[
            'px-5 py-2.5 text-xs font-bold rounded-xl transition-all active:scale-95 flex items-center gap-1.5 shadow',
            isValid
              ? 'bg-red-600 hover:bg-red-700 text-white'
              : 'bg-[#333] text-gray-500 border border-[#444] cursor-not-allowed'
          ]"
          type="button"
        >
          <span>{{ t('reception.auth.confirm', 'Xác nhận') }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  actionType: {
    type: String,
    default: 'VOID_ITEM'
  },
  targetName: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['confirm', 'close']);
const { t } = useI18n();

const pin = ref('');
const selectedReason = ref('');
const customReason = ref('');

const reasons = [
  'Khách đổi ý',
  'Nhân viên nhập sai',
  'Bếp làm sai/Hết nguyên liệu',
];

const title = computed(() => {
  switch (props.actionType) {
    case 'VOID_ITEM':
      return t('reception.auth.title_void_item', '⚠️ Xác nhận hủy món');
    case 'CANCEL_TABLE':
      return t('reception.auth.title_cancel_table', '⚠️ Xác nhận hủy bàn');
    case 'EDIT_PRICE':
      return t('reception.auth.title_edit_price', '⚠️ Xác nhận sửa giá');
    default:
      return t('reception.auth.title_default', '⚠️ Xác nhận quyền quản lý');
  }
});

const finalReason = computed(() => {
  if (selectedReason.value === 'Khách đổi ý') {
    return 'Khách đổi ý';
  }
  if (selectedReason.value === 'Nhân viên nhập sai') {
    return 'Nhân viên nhập sai';
  }
  if (selectedReason.value === 'Bếp làm sai/Hết nguyên liệu') {
    return 'Bếp làm sai/Hết nguyên liệu';
  }
  if (selectedReason.value === 'Khác...') {
    return customReason.value.trim() || 'Lý do khác';
  }
  return '';
});

const isValid = computed(() => {
  const hasReason = selectedReason.value && (selectedReason.value !== 'Khác...' || customReason.value.trim().length > 0);
  return hasReason && pin.value.length === 6;
});

function pressNum(num) {
  if (pin.value.length < 6) {
    pin.value += num;
  }
}

function backspace() {
  pin.value = pin.value.slice(0, -1);
}

function clearPin() {
  pin.value = '';
}

function handleClose() {
  emit('close');
}

function handleConfirm() {
  if (isValid.value) {
    emit('confirm', {
      pin: pin.value,
      reason: finalReason.value
    });
  }
}

// Handle physical keyboard input
function handleKeyDown(event) {
  if (event.key >= '0' && event.key <= '9') {
    pressNum(event.key);
  } else if (event.key === 'Backspace') {
    backspace();
  } else if (event.key === 'Escape') {
    handleClose();
  } else if (event.key === 'Enter') {
    if (isValid.value) {
      handleConfirm();
    }
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});
</script>

<style scoped>
@keyframes scale-up {
  0% {
    transform: scale(0.6);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
.animate-scale-up {
  animation: scale-up 0.15s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
}
</style>
