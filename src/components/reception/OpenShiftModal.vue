<template>
  <Transition name="fade">
    <div
      v-if="isOpen"
      class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-[9999] p-4"
    >
      <div class="w-full max-w-lg bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#3D2817] flex flex-col max-h-[90vh]">
        <!-- Header -->
        <div class="bg-[#1a5276] text-white p-4 flex items-center justify-between flex-shrink-0">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center">
              <LockOpen class="w-5 h-5 text-green-400" />
            </div>
            <div>
              <h2 class="text-base font-black uppercase tracking-wide">{{
                t('reception.dashboard.open_shift_dialog_title', 'Mở ca làm việc')
              }}</h2>
              <p class="text-[11px] text-white/70 mt-0.5">{{
                t('reception.dashboard.open_shift_dialog_text', 'Nhập số tiền đầu ca trong két (VND).')
              }}</p>
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

        <!-- Scrollable Form Content -->
        <div class="p-6 space-y-5 overflow-y-auto flex-1">
          <!-- Info Section: Cashier / Date / Shift -->
          <div class="grid grid-cols-3 gap-3">
            <div class="bg-gray-50 rounded-lg p-3 border border-gray-200">
              <div class="text-[10px] font-bold text-gray-500 uppercase tracking-wide mb-1">{{
                t('reception.username', 'Nhân viên')
              }}</div>
              <div class="text-sm font-bold text-[#3D2817] truncate">{{ cashierName }}</div>
            </div>
            <div class="bg-gray-50 rounded-lg p-3 border border-gray-200">
              <div class="text-[10px] font-bold text-gray-500 uppercase tracking-wide mb-1">{{
                t('reception.date', 'Ngày')
              }}</div>
              <div class="text-sm font-bold text-[#3D2817]">{{ currentDate }}</div>
            </div>
            <div class="bg-gray-50 rounded-lg p-3 border border-gray-200">
              <div class="text-[10px] font-bold text-gray-500 uppercase tracking-wide mb-1">{{
                t('reception.shift', 'Ca')
              }}</div>
              <div class="text-sm font-bold text-[#3D2817]">{{ currentShift }}</div>
            </div>
          </div>

          <!-- Opening Cash -->
          <div class="flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600 uppercase tracking-wide">
              {{ t('reception.initial_cash', 'Tiền mặt đầu ca') }} (VNĐ)
              <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                :value="openingCashDisplay"
                type="text"
                inputmode="numeric"
                placeholder="0"
                class="w-full px-4 py-3 border-2 rounded-lg text-lg font-bold text-[#3D2817] focus:outline-none transition-colors pr-16"
                :class="error ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-[#E8772E]'"
                @input="onCashInput"
              />
              <span class="absolute right-4 top-3.5 text-gray-500 font-bold text-sm">VNĐ</span>
            </div>
            <p v-if="error" class="text-xs text-red-500 font-bold">{{ error }}</p>
          </div>

          <!-- Denomination Breakdown -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <label class="text-xs font-bold text-gray-600 uppercase tracking-wide flex items-center gap-1.5">
                <Wallet class="w-3.5 h-3.5 text-[#E8772E]" />
                {{ t('reception.denomination_breakdown', 'Chi tiết mệnh giá') }}
              </label>
              <span class="text-[10px] text-gray-400 font-bold">{{
                t('reception.denomination_hint', 'Tùy chọn — tự tính tổng')
              }}</span>
            </div>
            <div class="grid grid-cols-3 gap-2">
              <div
                v-for="denom in denominations"
                :key="denom.value"
                class="bg-gray-50 border border-gray-200 rounded-lg p-2.5"
              >
                <div class="text-xs font-bold text-[#3D2817] mb-1">{{ denom.label }}</div>
                <div class="flex items-center gap-1">
                  <input
                    v-model.number="denom.quantity"
                    type="number"
                    min="0"
                    placeholder="0"
                    class="w-full px-2 py-1.5 bg-white border border-gray-300 rounded text-sm font-bold text-[#3D2817] focus:outline-none focus:border-[#E8772E] text-center"
                  />
                  <span class="text-[10px] text-gray-400 font-bold whitespace-nowrap">tờ</span>
                </div>
                <div class="text-[10px] text-gray-500 font-bold mt-1 text-right">
                  {{ formatMoney(denom.value * (denom.quantity || 0)) }}
                </div>
              </div>
            </div>
            <div class="mt-2 flex items-center justify-between bg-[#E8772E]/5 border border-[#E8772E]/20 rounded-lg px-3 py-2">
              <span class="text-xs font-bold text-gray-600">{{
                t('reception.denomination_total', 'Tổng cộng từ mệnh giá')
              }}</span>
              <span class="text-sm font-mono font-black text-[#E8772E]">{{ formatMoney(denominationTotal) }}</span>
            </div>
          </div>

          <!-- Notes -->
          <div>
            <label class="block text-xs font-bold text-gray-600 uppercase tracking-wide mb-1">
              {{ t('reception.open_shift_notes', 'Ghi chú (nếu có)') }}
            </label>
            <textarea
              v-model="notes"
              rows="2"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#E8772E]/10 focus:border-[#E8772E] transition-colors"
              :placeholder="t('reception.open_shift_notes_placeholder', 'VD: Tiền lẻ từ ca trước, tiền vật phẩm...')"
            ></textarea>
          </div>

          <!-- Info Note -->
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-start gap-2">
            <Info class="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
            <p class="text-xs text-blue-800 leading-relaxed">{{
              t('reception.dashboard.open_shift_note', 'Số tiền này sẽ được dùng làm mốc đối soát khi kết thúc ca làm việc.')
            }}</p>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3 flex-shrink-0">
          <button
            type="button"
            @click="handleClose"
            class="px-5 py-2.5 border border-gray-300 hover:bg-white text-gray-700 text-xs font-bold rounded-lg transition-all active:scale-95"
          >
            {{ t('reception.dashboard.open_shift_cancel', 'Hủy') }}
          </button>
          <button
            type="button"
            :disabled="!isValid || loading"
            @click="handleConfirm"
            :class="[
              'px-5 py-2.5 text-xs font-bold rounded-lg transition-all active:scale-95 flex items-center gap-1.5 shadow',
              isValid && !loading
                ? 'bg-green-600 hover:bg-green-700 text-white'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed border border-gray-400'
            ]"
          >
            <Loader2 v-if="loading" class="w-4 h-4 animate-spin" />
            {{ t('reception.dashboard.open_shift_confirm', 'Xác nhận mở ca') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive } from 'vue'
import { LockOpen, Info, Loader2, Wallet } from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'

const props = defineProps<{
  isOpen: boolean
  cashierName: string
  loading?: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'confirm', payload: { openingCash: number; notes: string }): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const openingCash = ref<number | null>(null)
const openingCashDisplay = ref('')
const error = ref('')
const notes = ref('')

interface Denomination {
  value: number
  label: string
  quantity: number
}

const denominations = reactive<Denomination[]>([
  { value: 500000, label: '500.000₫', quantity: 0 },
  { value: 200000, label: '200.000₫', quantity: 0 },
  { value: 100000, label: '100.000₫', quantity: 0 },
  { value: 50000, label: '50.000₫', quantity: 0 },
  { value: 20000, label: '20.000₫', quantity: 0 },
  { value: 10000, label: '10.000₫', quantity: 0 },
])

const denominationTotal = computed(() =>
  denominations.reduce((sum, d) => sum + d.value * (d.quantity || 0), 0),
)

const currentDate = computed(() => {
  return new Date().toLocaleDateString('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
})

const currentShift = computed(() => {
  const hour = new Date().getHours()
  if (hour >= 6 && hour < 12) return t('shift.type.morning', 'Sáng')
  if (hour >= 12 && hour < 18) return t('shift.type.afternoon', 'Chiều')
  return t('shift.type.evening', 'Tối')
})

const isValid = computed(() => {
  return openingCash.value !== null && openingCash.value >= 0 && !error.value
})

function formatMoney(amount: number): string {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0)
}

function parseMoney(str: string): number {
  const cleaned = str.replace(/[^\d]/g, '')
  return cleaned ? parseInt(cleaned, 10) : 0
}

function onCashInput(event: Event) {
  const input = event.target as HTMLInputElement
  const num = parseMoney(input.value)
  openingCash.value = num
  openingCashDisplay.value = num > 0 ? num.toLocaleString('vi-VN') : ''
  error.value = ''
}

// Auto-fill openingCash when denomination quantities change
watch(denominationTotal, (total) => {
  if (total > 0) {
    openingCash.value = total
    openingCashDisplay.value = total.toLocaleString('vi-VN')
  }
})

// Reset form when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      openingCash.value = null
      openingCashDisplay.value = ''
      error.value = ''
      notes.value = ''
      denominations.forEach((d) => (d.quantity = 0))
    }
  },
)

function handleClose() {
  emit('close')
}

function handleConfirm() {
  if (!isValid.value || openingCash.value === null) return
  emit('confirm', {
    openingCash: openingCash.value,
    notes: notes.value,
  })
}
</script>
