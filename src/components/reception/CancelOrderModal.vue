<template>
  <!-- Overlay -->
  <Transition name="cancel-overlay">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9998] bg-black/75 backdrop-blur-sm"
      @click="handleClose"
    ></div>
  </Transition>

  <!-- Panel -->
  <Transition name="cancel-panel" appear>
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 select-none pointer-events-none"
    >
      <div
        class="bg-[#2d2d2d] border border-red-500/30 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col pointer-events-auto max-h-[90vh]"
      >
        <!-- Header -->
        <div class="p-4 bg-gradient-to-r from-red-950/80 to-[#2d2d2d] border-b border-red-500/20 flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-red-500/10 border border-red-500/30 flex items-center justify-center text-red-500 text-lg">
            ⚠️
          </div>
          <div class="flex-1">
            <h3 class="text-sm font-black uppercase text-red-400 tracking-wider">
              Hủy món / Hủy phiếu
            </h3>
            <p class="text-[11px] text-gray-400 mt-0.5">
              Yêu cầu xác thực quản lý
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

        <!-- Order Info -->
        <div class="p-4 bg-[#222] border-b border-[#333]">
          <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wide mb-3">Thông tin phiếu</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-500">Mã phiếu:</span>
              <span class="font-mono font-semibold text-white">{{ orderInfo.code }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Bàn:</span>
              <span class="font-semibold text-white">{{ orderInfo.tableNumber }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Tổng tiền:</span>
              <span class="font-bold text-orange-500">{{ formatPrice(orderInfo.total) }}</span>
            </div>
          </div>
        </div>

        <!-- Content -->
        <div class="p-6 space-y-5 flex-1 overflow-y-auto">
          <!-- Reason Selection -->
          <div class="space-y-1.5">
            <label class="block text-xs font-bold text-gray-300 uppercase tracking-wide">
              Lý do hủy <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <select
                v-model="formData.reason"
                class="w-full bg-[#1e1e1e] border rounded-xl px-4 py-3 text-sm text-white font-semibold focus:outline-none transition-colors cursor-pointer appearance-none"
                :class="errors.reason ? 'border-red-500' : 'border-[#444] hover:border-[#555] focus:border-red-500'"
              >
                <option value="" disabled>-- Chọn lý do --</option>
                <option v-for="reason in reasons" :key="reason.value" :value="reason.value">
                  {{ reason.label }}
                </option>
              </select>
              <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400 text-xs">
                ▼
              </div>
            </div>
            <p v-if="errors.reason" class="text-sm text-red-500">{{ errors.reason }}</p>

            <!-- Custom Reason Input -->
            <div v-if="formData.reason === 'OTHER'" class="mt-2">
              <textarea
                v-model="formData.customReason"
                rows="3"
                placeholder="Vui lòng mô tả chi tiết lý do..."
                class="w-full bg-[#1e1e1e] border rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none transition-colors resize-none"
                :class="errors.customReason ? 'border-red-500' : 'border-[#444] focus:border-red-500'"
              ></textarea>
              <p v-if="errors.customReason" class="text-sm text-red-500 mt-1">{{ errors.customReason }}</p>
            </div>
          </div>

          <!-- PIN Entry -->
          <div class="space-y-2">
            <label class="block text-xs font-bold text-gray-300 uppercase tracking-wide text-center">
              Mã PIN Quản lý (6 số) <span class="text-red-500">*</span>
            </label>

            <!-- PIN Display -->
            <div class="flex justify-center gap-3 pt-1">
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
            <p v-if="errors.pin" class="text-sm text-red-500 text-center">{{ errors.pin }}</p>
            <p v-if="pinError" class="text-sm text-red-500 text-center">{{ pinError }}</p>
          </div>

          <!-- PIN Keypad -->
          <div class="grid grid-cols-3 gap-3 max-w-[280px] mx-auto pt-2">
            <button
              v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]"
              :key="num"
              @click="appendPin(String(num))"
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
              Xóa hết
            </button>
            <button
              @click="appendPin('0')"
              class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] active:bg-red-500/20 border border-[#3c3c3c] hover:border-[#555] text-white text-lg font-bold transition-all active:scale-95 flex items-center justify-center"
              type="button"
            >
              0
            </button>
            <button
              @click="backspacePin"
              class="h-14 rounded-xl bg-[#242424] hover:bg-[#3a3a3a] border border-[#3c3c3c] text-lg font-bold text-gray-400 hover:text-white transition-all active:scale-95 flex items-center justify-center"
              type="button"
            >
              ⌫
            </button>
          </div>
        </div>

        <!-- Warning Box -->
        <div class="mx-4 mb-4 p-3 bg-amber-950/30 border-l-4 border-amber-500 rounded-r-lg">
          <div class="flex items-start gap-2">
            <span class="text-amber-500 text-base flex-shrink-0">⚠️</span>
            <div>
              <p class="font-semibold text-amber-200 text-xs">Cảnh báo</p>
              <p class="text-[11px] text-amber-300/70 mt-0.5">
                Hành động này sẽ hủy phiếu và không thể hoàn tác. Thao tác được ghi nhận vào nhật ký hệ thống.
              </p>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-4 bg-[#222] border-t border-[#333] flex gap-3">
          <button
            @click="handleClose"
            class="flex-1 px-4 py-3 bg-[#3a3a3a] hover:bg-[#4a4a4a] text-white text-sm font-bold rounded-xl transition-all active:scale-95"
            type="button"
          >
            Hủy
          </button>
          <button
            @click="handleSubmit"
            :disabled="isSubmitting || !canSubmit"
            :class="[
              'flex-1 px-4 py-3 text-sm font-bold rounded-xl transition-all active:scale-95 flex items-center justify-center gap-2',
              canSubmit && !isSubmitting
                ? 'bg-red-600 hover:bg-red-700 text-white shadow'
                : 'bg-[#333] text-gray-500 border border-[#444] cursor-not-allowed'
            ]"
            type="button"
          >
            <svg v-if="isSubmitting" class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            <span v-else>Xác nhận hủy</span>
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import Swal from 'sweetalert2'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  orderInfo: {
    type: Object,
    required: true,
    default: () => ({
      code: '',
      tableNumber: '',
      total: 0
    })
  }
})

const emit = defineEmits(['close', 'confirm'])

// State
const pin = ref('')
const formData = reactive({
  reason: '',
  customReason: ''
})
const errors = reactive({})
const pinError = ref('')
const isSubmitting = ref(false)

// Reasons list
const reasons = [
  { value: 'CUSTOMER_REQUEST', label: 'Khách hàng yêu cầu hủy' },
  { value: 'WRONG_ORDER', label: 'Order sai món/sai số lượng' },
  { value: 'PAYMENT_ERROR', label: 'Lỗi thanh toán' },
  { value: 'SYSTEM_ERROR', label: 'Lỗi hệ thống' },
  { value: 'DUPLICATE', label: 'Phiếu trùng lặp' },
  { value: 'CUSTOMER_COMPLAINT', label: 'Khách hàng phàn nàn' },
  { value: 'MANAGER_REQUEST', label: 'Yêu cầu từ quản lý' },
  { value: 'OTHER', label: 'Lý do khác' }
]

// Computed
const canSubmit = computed(() => {
  if (!formData.reason || pin.value.length !== 6) return false
  if (formData.reason === 'OTHER' && !formData.customReason.trim()) return false
  return true
})

// Watch for modal open
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    resetForm()
  }
})

// PIN methods
function appendPin(digit) {
  if (pin.value.length < 6) {
    pin.value += digit
    pinError.value = ''
    if (errors.pin) delete errors.pin
  }
}

function clearPin() {
  pin.value = ''
}

function backspacePin() {
  pin.value = pin.value.slice(0, -1)
}

function resetForm() {
  pin.value = ''
  formData.reason = ''
  formData.customReason = ''
  pinError.value = ''
  Object.keys(errors).forEach(key => delete errors[key])
}

function validateForm() {
  let isValid = true
  Object.keys(errors).forEach(key => delete errors[key])

  if (!formData.reason) {
    errors.reason = 'Vui lòng chọn lý do'
    isValid = false
  }

  if (formData.reason === 'OTHER' && !formData.customReason.trim()) {
    errors.customReason = 'Vui lòng nhập lý do chi tiết'
    isValid = false
  }

  if (!pin.value) {
    errors.pin = 'Vui lòng nhập mã PIN'
    isValid = false
  } else if (pin.value.length !== 6) {
    errors.pin = 'PIN phải có 6 chữ số'
    isValid = false
  }

  return isValid
}

async function handleSubmit() {
  if (!validateForm()) return

  isSubmitting.value = true

  try {
    // Simulate API call to verify PIN
    await new Promise(resolve => setTimeout(resolve, 1000))

    // Mock PIN verification (in production, call API)
    const validPins = ['123456', '000000', '111111']
    if (!validPins.includes(pin.value)) {
      pinError.value = '❌ Mã PIN không chính xác'
      isSubmitting.value = false
      return
    }

    // Prepare data
    const cancelData = {
      orderCode: props.orderInfo.code,
      reason: formData.reason === 'OTHER' ? formData.customReason : formData.reason,
      reasonCode: formData.reason,
      pin: pin.value,
      timestamp: new Date().toISOString(),
      canceledBy: 'Manager'
    }

    emit('confirm', cancelData)

    await Swal.fire({
      title: '✅ Thành công',
      text: `Đã hủy phiếu ${props.orderInfo.code}`,
      icon: 'success',
      timer: 2000,
      showConfirmButton: false,
      toast: true,
      position: 'top-end'
    })

    handleClose()
  } catch (error) {
    console.error('Cancellation error:', error)
    Swal.fire({
      title: 'Lỗi',
      text: 'Có lỗi xảy ra. Vui lòng thử lại.',
      icon: 'error',
      timer: 2000,
      showConfirmButton: false
    })
  } finally {
    isSubmitting.value = false
  }
}

function handleClose() {
  emit('close')
}

function formatPrice(amount) {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount)
}

// Handle physical keyboard input
function handleKeyDown(event) {
  if (!props.isOpen) return

  if (event.key >= '0' && event.key <= '9') {
    appendPin(event.key)
  } else if (event.key === 'Backspace') {
    backspacePin()
  } else if (event.key === 'Escape') {
    handleClose()
  } else if (event.key === 'Enter') {
    if (canSubmit.value && !isSubmitting.value) {
      handleSubmit()
    }
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
})
</script>

<style scoped>
/* Overlay transition */
.cancel-overlay-enter-active,
.cancel-overlay-leave-active {
  transition: opacity 0.3s ease;
}
.cancel-overlay-enter-from,
.cancel-overlay-leave-to {
  opacity: 0;
}

/* Panel transition */
.cancel-panel-enter-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.cancel-panel-leave-active {
  transition: all 0.2s ease-in;
}
.cancel-panel-enter-from,
.cancel-panel-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(16px);
}

/* PIN dot animation */
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
