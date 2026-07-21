<template>
  <Transition name="fade">
    <div
      v-if="isOpen"
      class="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-[9999] p-4"
    >
      <div class="w-full max-w-md bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#3D2817]">
        <!-- Header -->
        <div class="bg-[#1a5276] text-white p-4 flex items-center justify-between">
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

        <!-- Form Content -->
        <div class="p-6 space-y-5">
          <!-- Cashier Name -->
          <div class="flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600 uppercase tracking-wide">{{
              t('reception.username', 'Nhân viên')
            }}</label>
            <input
              :value="cashierName"
              type="text"
              disabled
              class="w-full px-4 py-2.5 bg-gray-100 border border-gray-300 rounded-lg text-sm font-bold text-gray-600 cursor-not-allowed"
            />
          </div>

          <!-- Opening Cash -->
          <div class="flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600 uppercase tracking-wide">
              {{ t('reception.initial_cash', 'Tiền mặt đầu ca') }} (VNĐ)
              <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                v-model="openingCash"
                type="number"
                min="0"
                step="1000"
                placeholder="0"
                class="w-full px-4 py-3 border-2 rounded-lg text-lg font-bold text-[#3D2817] focus:outline-none transition-colors"
                :class="error ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-[#E8772E]'"
                @input="error = ''"
              />
              <span class="absolute right-4 top-3.5 text-gray-500 font-bold text-sm">VNĐ</span>
            </div>
            <p v-if="error" class="text-xs text-red-500 font-bold">{{ error }}</p>
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
        <div class="p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3">
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
            {{ t('reception.dashboard.open_shift_confirm', 'Mở ca') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { LockOpen, Info, Loader2 } from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'

const props = defineProps<{
  isOpen: boolean
  cashierName: string
  loading?: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'confirm', openingCash: number): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const openingCash = ref<number | null>(null)
const error = ref('')

const isValid = computed(() => {
  return openingCash.value !== null && openingCash.value >= 0 && !error.value
})

// Reset form when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      openingCash.value = null
      error.value = ''
    }
  },
)

function handleClose() {
  emit('close')
}

function handleConfirm() {
  if (!isValid.value || openingCash.value === null) return
  emit('confirm', openingCash.value)
}
</script>
