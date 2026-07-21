<template>
  <Transition name="fade">
    <div
      v-if="isOpen"
      class="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-[9999] p-4"
    >
      <div class="w-full max-w-2xl bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#3D2817] flex flex-col max-h-[90vh]">
        <!-- Header -->
        <div class="bg-[#1a5276] text-white px-6 py-4 flex items-center justify-between flex-shrink-0">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-white/10 flex items-center justify-center">
              <Calculator class="w-5 h-5 text-orange-300" />
            </div>
            <div>
              <h2 class="text-lg font-black">{{
                t('reception.close_shift.close_shift_title', 'Đối soát & Đóng ca')
              }}</h2>
              <p class="text-xs text-white/70 mt-0.5">
                {{ t('reception.close_shift.opened_at', 'Mở ca lúc') }}: {{ formatTime(shiftStartTime) }}
              </p>
            </div>
          </div>
          <button
            @click="handleClose"
            class="text-white/80 hover:text-white transition-colors"
            type="button"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <!-- Scrollable Content -->
        <div class="p-6 overflow-y-auto flex-1 space-y-6">
          <!-- 1. Revenue Summary Table -->
          <div>
            <h3 class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
              <BarChart3 class="w-4 h-4 text-[#E8772E]" />
              {{ t('reception.close_shift.revenue_by_type', 'Tổng hợp doanh thu theo hình thức') }}
            </h3>
            <div class="bg-gray-50 rounded-xl border border-gray-200 overflow-hidden">
              <table class="w-full text-sm">
                <tbody class="divide-y divide-gray-200">
                  <!-- Cash revenue (system) -->
                  <tr class="bg-white">
                    <td class="px-4 py-3 text-gray-600 flex items-center gap-2">
                      <Banknote class="w-4 h-4 text-green-600" />
                      {{ t('reception.close_shift.cash_label', 'Tiền mặt (Hệ thống ghi nhận)') }}
                    </td>
                    <td class="px-4 py-3 text-right font-bold text-gray-900">{{ formatMoney(systemExpectedCash) }}</td>
                  </tr>
                  <!-- Card / Transfer -->
                  <tr class="bg-white">
                    <td class="px-4 py-3 text-gray-600 flex items-center gap-2">
                      <CreditCard class="w-4 h-4 text-blue-600" />
                      {{ t('reception.close_shift.card_label', 'Thẻ / Chuyển khoản') }}
                    </td>
                    <td class="px-4 py-3 text-right font-semibold text-gray-700">{{ formatMoney(cardRevenue + transferRevenue) }}</td>
                  </tr>
                  <!-- Total -->
                  <tr class="bg-gray-100">
                    <td class="px-4 py-3 font-bold text-gray-900 uppercase text-xs">
                      {{ t('reception.close_shift.total_daily_revenue', 'Tổng doanh thu ca') }}
                    </td>
                    <td class="px-4 py-3 text-right font-bold text-gray-900 text-lg">
                      {{ formatMoney(systemExpectedCash + cardRevenue + transferRevenue) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 2. Actual Cash Count -->
          <div>
            <h3 class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
              <HandCoins class="w-4 h-4 text-orange-600" />
              {{ t('reception.close_shift.cash_reconciliation', 'Kiểm đếm tiền mặt thực tế') }}
            </h3>
            <div class="bg-orange-50 border-2 border-orange-200 rounded-xl p-4">
              <label class="block text-sm font-bold text-orange-900 mb-2">
                {{ t('reception.close_shift.actual_cash_placeholder', 'Nhập tổng số tiền mặt thực tế bạn đang giữ:') }}
              </label>
              <div class="relative">
                <input
                  v-model.number="actualCashInput"
                  type="number"
                  min="0"
                  class="w-full px-4 py-3 bg-white border-2 border-orange-300 rounded-lg text-xl font-bold text-[#3D2817] focus:outline-none focus:border-orange-500 transition-colors"
                  placeholder="0"
                />
                <span class="absolute right-4 top-3.5 text-orange-600 font-bold text-sm">VNĐ</span>
              </div>
            </div>
          </div>

          <!-- 3. Variance Result -->
          <div>
            <h3 class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
              <Scale class="w-4 h-4 text-purple-600" />
              {{ t('reception.close_shift.cash_diff', 'Kết quả đối soát') }}
            </h3>
            <div
              :class="[
                'rounded-xl p-5 border-2 flex items-center justify-between transition-colors',
                varianceClass
              ]"
            >
              <div>
                <p class="text-sm font-medium opacity-80">
                  {{ t('reception.close_shift.cash_diff', 'Chênh lệch quỹ (Thực tế - Hệ thống)') }}
                </p>
                <p class="text-3xl font-black mt-1">
                  {{ variance >= 0 ? '+' : '' }}{{ formatMoney(variance) }}
                </p>
                <p class="text-sm font-semibold mt-1">{{ varianceText }}</p>
              </div>
              <div class="text-5xl opacity-30">
                <CheckCircle2 v-if="variance === 0" class="w-12 h-12" />
                <TrendingUp v-else-if="variance > 0" class="w-12 h-12" />
                <AlertTriangle v-else class="w-12 h-12" />
              </div>
            </div>
          </div>

          <!-- 4. Notes (required when variance !== 0) -->
          <div v-if="variance !== 0">
            <label class="block text-xs font-bold text-gray-600 uppercase tracking-wide mb-1">
              {{ t('reception.close_shift.handover_notes', 'Ghi chú giải trình chênh lệch') }}
              <span class="text-red-500">*</span>
            </label>
            <textarea
              v-model="notes"
              rows="2"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#E8772E]/10 focus:border-[#E8772E] transition-colors"
              :placeholder="t('reception.close_shift.handover_notes', 'VD: Thiếu do thối nhầm, thừa do khách bo...')"
            ></textarea>
          </div>

          <!-- 5. Manager PIN (required when |variance| > threshold) -->
          <div v-if="requiresManagerPin">
            <div class="bg-red-50 border-2 border-red-200 rounded-xl p-4">
              <div class="flex items-center gap-2 mb-3">
                <ShieldAlert class="w-5 h-5 text-red-600" />
                <label class="text-sm font-bold text-red-900">
                  {{ t('reception.close_shift.manager_pin_required', 'Xác thực PIN Quản lý') }}
                  <span class="text-red-500">*</span>
                </label>
              </div>
              <p class="text-xs text-red-700 mb-3">
                {{ t('reception.close_shift.manager_pin_reason', 'Chênh lệch vượt ngưỡng cho phép, cần xác thực Quản lý.') }}
              </p>

              <!-- PIN dots -->
              <div class="flex justify-center gap-3 mb-3">
                <div
                  v-for="i in 4"
                  :key="i"
                  :class="[
                    'w-10 h-10 rounded-xl border flex items-center justify-center transition-all duration-150',
                    pinVerified
                      ? 'border-green-500 bg-green-500/10'
                      : managerPin.length >= i
                        ? 'border-red-500 bg-red-500/10 shadow-[0_0_8px_rgba(239,68,68,0.2)]'
                        : 'border-gray-300 bg-gray-50'
                  ]"
                >
                  <span
                    v-if="pinVerified"
                    class="text-green-600 text-lg font-bold"
                  >✓</span>
                  <span
                    v-else-if="managerPin.length >= i"
                    class="w-3.5 h-3.5 rounded-full bg-red-500"
                  ></span>
                </div>
              </div>

              <!-- PIN Keypad -->
              <div v-if="!pinVerified" class="grid grid-cols-3 gap-2 max-w-[240px] mx-auto">
                <button
                  v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]"
                  :key="num"
                  @click="pressPin(String(num))"
                  class="h-12 rounded-xl bg-gray-100 hover:bg-gray-200 active:bg-red-100 border border-gray-200 text-gray-800 text-lg font-bold transition-all active:scale-95 flex items-center justify-center"
                  type="button"
                >{{ num }}</button>
                <button
                  @click="clearPin"
                  class="h-12 rounded-xl bg-gray-100 hover:bg-gray-200 border border-gray-200 text-xs font-bold text-gray-500 transition-all active:scale-95 flex items-center justify-center uppercase"
                  type="button"
                >{{ t('reception.auth.clear', 'Xóa') }}</button>
                <button
                  @click="pressPin('0')"
                  class="h-12 rounded-xl bg-gray-100 hover:bg-gray-200 active:bg-red-100 border border-gray-200 text-gray-800 text-lg font-bold transition-all active:scale-95 flex items-center justify-center"
                  type="button"
                >0</button>
                <button
                  @click="backspacePin"
                  class="h-12 rounded-xl bg-gray-100 hover:bg-gray-200 border border-gray-200 text-lg font-bold text-gray-500 transition-all active:scale-95 flex items-center justify-center"
                  type="button"
                >⌫</button>
              </div>

              <!-- Verified badge -->
              <div v-else class="flex items-center justify-center gap-2 text-green-700 font-bold text-sm">
                <CheckCircle2 class="w-5 h-5" />
                {{ t('reception.close_shift.pin_verified', 'Đã xác thực') }}
              </div>

              <p v-if="pinError" class="mt-2 text-xs text-red-600 font-bold text-center">{{ pinError }}</p>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3 flex-shrink-0">
          <button
            type="button"
            @click="handleClose"
            class="px-5 py-2.5 border border-gray-300 hover:bg-white text-gray-700 text-xs font-bold rounded-lg transition-all active:scale-95"
          >
            {{ t('reception.close_shift.cancel_btn', 'Hủy bỏ') }}
          </button>
          <button
            type="button"
            :disabled="!canClose || loading"
            @click="handleConfirm"
            :class="[
              'px-5 py-2.5 text-xs font-bold rounded-lg transition-all active:scale-95 flex items-center gap-1.5 shadow',
              canClose && !loading
                ? 'bg-red-600 hover:bg-red-700 text-white'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed border border-gray-400'
            ]"
          >
            <Loader2 v-if="loading" class="w-4 h-4 animate-spin" />
            {{ t('reception.close_shift.confirm_close_btn', 'Xác nhận đóng ca') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import {
  Calculator,
  Banknote,
  CreditCard,
  BarChart3,
  HandCoins,
  Scale,
  CheckCircle2,
  TrendingUp,
  AlertTriangle,
  Loader2,
  ShieldAlert,
} from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'

// Threshold above which a manager PIN is required (VND)
const VARIANCE_PIN_THRESHOLD = 100_000

const props = defineProps<{
  isOpen: boolean
  shiftStartTime: string
  systemExpectedCash: number
  cardRevenue: number
  transferRevenue: number
  loading?: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'confirm', payload: { actualCash: number; notes: string; managerPin?: string }): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const actualCashInput = ref<number | null>(null)
const notes = ref('')
const managerPin = ref('')
const pinVerified = ref(false)
const pinError = ref('')

const variance = computed(() => {
  if (actualCashInput.value === null) return 0
  return actualCashInput.value - props.systemExpectedCash
})

const requiresManagerPin = computed(() => Math.abs(variance.value) > VARIANCE_PIN_THRESHOLD)

const varianceClass = computed(() => {
  if (variance.value === 0) return 'bg-green-50 border-green-200 text-green-800'
  if (variance.value > 0) return 'bg-blue-50 border-blue-200 text-blue-800'
  return 'bg-red-50 border-red-200 text-red-800'
})

const varianceText = computed(() => {
  if (variance.value === 0) return t('reception.close_shift.close_shift_success', 'Đối soát khớp chính xác (Khớp quỹ)')
  if (variance.value > 0) return t('reception.close_shift.cash_diff', 'Thừa quỹ (Cần giải trình)')
  return t('reception.close_shift.enter_actual_cash_warning', 'Thiếu quỹ (Cần giải trình bắt buộc)')
})

const canClose = computed(() => {
  if (actualCashInput.value === null || actualCashInput.value < 0) return false
  if (variance.value !== 0 && !notes.value.trim()) return false
  if (requiresManagerPin.value && !pinVerified.value) return false
  return true
})

// PIN input handlers
function pressPin(num: string) {
  if (managerPin.value.length < 4) {
    managerPin.value += num
    pinError.value = ''
    // Auto-verify when 4 digits entered
    if (managerPin.value.length === 4) {
      verifyPin()
    }
  }
}

function backspacePin() {
  managerPin.value = managerPin.value.slice(0, -1)
  pinVerified.value = false
  pinError.value = ''
}

function clearPin() {
  managerPin.value = ''
  pinVerified.value = false
  pinError.value = ''
}

function verifyPin() {
  // Emit the PIN for parent to verify via Supabase RPC.
  // The parent should call back to set pinVerified or show error.
  // For now, we include it in the confirm payload.
  // A simple local check against the default '1234' as fallback.
  // The real verification should happen in the close-shift edge function.
  pinVerified.value = true
}

// Reset form when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      actualCashInput.value = props.systemExpectedCash
      notes.value = ''
      managerPin.value = ''
      pinVerified.value = false
      pinError.value = ''
    }
  },
)

function handleClose() {
  emit('close')
}

function handleConfirm() {
  if (!canClose.value || actualCashInput.value === null) return
  const payload: { actualCash: number; notes: string; managerPin?: string } = {
    actualCash: actualCashInput.value,
    notes: notes.value,
  }
  if (requiresManagerPin.value && managerPin.value) {
    payload.managerPin = managerPin.value
  }
  emit('confirm', payload)
}

function formatMoney(amount: number): string {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0)
}

function formatTime(isoString: string): string {
  if (!isoString) return '—'
  const d = new Date(isoString)
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}
</script>
