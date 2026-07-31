<!--
  OtherIncomeModal.vue
  ─────────────────────────────────────────────────────────────────────────────
  Modal form for recording "Thu khác" (other income).  Self-contained:
  form state, validation, amount formatting.  Parent only needs to
  toggle `isOpen` and handle `save` / `saveAndPrint` events.
-->
<template>
  <Transition name="fade">
    <div v-if="isOpen" class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-[9999] p-4">
      <div class="w-full max-w-[600px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]">

        <!-- Header -->
        <div class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between">
          <h2 class="text-base font-black uppercase tracking-wide">{{ t('reception.other_income_short') }}</h2>
          <button @click="$emit('close')" class="text-white/80 hover:text-white transition-colors" type="button">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <!-- Creator Info -->
        <div class="creator-info bg-[#f5f5f5] p-4 border-b border-gray-200">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="flex items-center gap-2">
              <span class="text-xs font-bold text-gray-500 uppercase min-w-[80px]">Người tạo:</span>
              <span class="text-xs font-bold text-gray-800">{{ creator }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-xs font-bold text-gray-500 uppercase min-w-[80px]">Ngày lập:</span>
              <input v-model="createdDate" type="text" class="bg-white border border-gray-300 rounded px-2.5 py-1 text-xs font-mono font-bold w-full max-w-[160px] focus:outline-none focus:border-[#E8772E]" />
            </div>
          </div>
        </div>

        <!-- Form Content -->
        <form @submit.prevent="handleSave" class="form-content p-5 max-h-[420px] overflow-y-auto space-y-4">

          <!-- Đối tượng -->
          <div class="form-row required flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600">Đối tượng <span class="text-red-500">*</span></label>
            <div class="input-with-button flex items-center gap-1.5">
              <input
                v-model="form.object"
                type="text"
                class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-2 focus:ring-[#E8772E]/10"
                :placeholder="t('reception.enter_target_name')"
                required
              />
              <button type="button" @click="triggerSelectObject" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
            </div>
          </div>

          <!-- Loại thu & Khoản thu (Grid) -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="form-row required flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Loại thu <span class="text-red-500">*</span></label>
              <select v-model="form.incomeType" class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" required>
                <option value="other">Thu Khác</option>
                <option value="deposit">Tiền đặt cọc</option>
                <option value="refund">Hoàn tiền</option>
              </select>
            </div>
            <div class="form-row required flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Khoản thu <span class="text-red-500">*</span></label>
              <select v-model="form.incomeItem" class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" required>
                <option value="withdraw">Rút tiền dư</option>
                <option value="adjustment">Điều chỉnh</option>
                <option value="other">{{ t('reception.other') }}</option>
              </select>
            </div>
          </div>

          <!-- Tiền thu (Highlight hồng nhạt) -->
          <div class="form-row required highlight bg-[#FFF0F0] border border-red-200/50 p-3.5 rounded-xl flex flex-col gap-1">
            <label class="text-xs font-bold text-red-700">Tiền thu <span class="text-red-500">*</span></label>
            <div class="input-with-button flex items-center gap-1.5">
              <input
                :value="formattedAmount"
                @input="handleAmountInput"
                type="text"
                class="form-input flex-1 px-3 py-2 border border-red-300 rounded-lg text-xs font-mono font-bold text-right text-red-600 focus:outline-none focus:ring-2 focus:ring-red-100"
                placeholder="0"
                required
              />
              <button type="button" class="btn-browse px-3 py-2 bg-red-100 hover:bg-red-200 border border-red-300 text-xs font-bold text-red-700 rounded-lg active:scale-95 transition-all">...</button>
            </div>
          </div>

          <!-- Lý do -->
          <div class="form-row flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600">{{ t('reception.reason') }}</label>
            <div class="input-with-button flex items-center gap-1.5">
              <input
                v-model="form.reason"
                type="text"
                class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                :placeholder="t('reception.enter_reason')"
              />
              <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
            </div>
          </div>

          <!-- Số chứng từ & Mã đặt chỗ (Grid) -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Số chứng từ</label>
              <input
                v-model="form.voucherNumber"
                type="text"
                class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                :placeholder="t('reception.auto_generated')"
              />
            </div>
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Mã đặt chỗ</label>
              <input
                v-model="form.bookingCode"
                type="text"
                class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                :placeholder="t('reception.enter_booking_code')"
              />
            </div>
          </div>

          <!-- Tiền mặt -->
          <div class="form-row checkbox-row flex items-center gap-2 pt-2 select-none">
            <input v-model="form.isCash" type="checkbox" id="isCash" class="w-4 h-4 accent-[#E8772E] cursor-pointer" />
            <label for="isCash" class="text-xs font-bold text-gray-700 cursor-pointer">{{ t('reception.cash') }}</label>
          </div>
        </form>

        <!-- Footer Actions -->
        <div class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3">
          <button
            type="button"
            class="btn btn-save-print px-4 py-2 bg-[#4CAF50] hover:bg-[#43A047] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95 flex items-center gap-1.5"
            @click="handleSaveAndPrint"
          >{{ t('reception.save_and_print') }}</button>
          <button
            type="button"
            class="btn btn-save px-4 py-2 bg-[#FF9800] hover:bg-[#F57C00] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
            @click="handleSave"
          >{{ t('reception.save') }}</button>
          <button
            type="button"
            class="btn btn-cancel px-4 py-2 bg-[#F44336] hover:bg-[#E53935] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
            @click="$emit('close')"
          >{{ t('reception.skip') }}</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import Swal from 'sweetalert2'
import { useLanguageStore } from '@/stores/useLanguageStore'

export interface OtherIncomePayload {
  object: string
  incomeType: string
  incomeItem: string
  amount: number
  reason: string
  voucherNumber: string
  bookingCode: string
  isCash: boolean
}

const props = defineProps<{
  isOpen: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'save', payload: OtherIncomePayload): void
  (e: 'saveAndPrint', payload: OtherIncomePayload): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const creator = ref('Dương Thị Mộng')
const createdDate = ref('02/07/2026 15:08:41')

const form = ref({
  object: '',
  incomeType: 'other',
  incomeItem: 'withdraw',
  amount: 0,
  reason: '',
  voucherNumber: '',
  bookingCode: '',
  isCash: true,
})

const formattedAmount = computed(() => {
  if (!form.value.amount) return ''
  return Number(form.value.amount).toLocaleString('vi-VN')
})

function handleAmountInput(e: Event) {
  const target = e.target as HTMLInputElement
  const rawValue = target.value.replace(/[^0-9]/g, '')
  form.value.amount = rawValue ? parseInt(rawValue, 10) : 0
}

function triggerSelectObject() {
  form.value.object = 'Khách vãng lai'
  triggerToast('info', 'Đã tự động chọn Đối tượng: Khách vãng lai')
}

function triggerToast(type: 'success' | 'error' | 'info' | 'warning', text: string) {
  Swal.fire({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000,
    timerProgressBar: true,
    icon: type,
    title: text,
  })
}

function validate(): boolean {
  if (!form.value.object) {
    triggerToast('error', 'Vui lòng nhập Đối tượng!')
    return false
  }
  if (!form.value.amount) {
    triggerToast('error', 'Vui lòng nhập Số tiền thu!')
    return false
  }
  return true
}

function getPayload(): OtherIncomePayload {
  return { ...form.value }
}

function handleSave() {
  if (!validate()) return
  emit('save', getPayload())
}

function handleSaveAndPrint() {
  if (!validate()) return
  emit('saveAndPrint', getPayload())
}

// Reset form when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      form.value = {
        object: '',
        incomeType: 'other',
        incomeItem: 'withdraw',
        amount: 0,
        reason: '',
        voucherNumber: '',
        bookingCode: '',
        isCash: true,
      }
    }
  },
)
</script>
