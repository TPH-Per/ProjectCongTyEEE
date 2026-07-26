<template>
  <div class="h-screen flex flex-col p-4 max-w-5xl mx-auto overflow-hidden text-gray-800">
    <!-- Header compact -->
    <header class="flex justify-between items-center py-2 mb-3 border-b-2 border-gray-200 shrink-0">
      <h1 class="text-lg font-extrabold text-gray-800">{{ t('other_expense.title') }}</h1>
      <button 
        class="px-4 py-1.5 border border-gray-300 rounded-lg text-xs text-gray-600 bg-white hover:bg-gray-50 active:scale-95 transition-all font-semibold shadow-xs" 
        @click="goBack"
      >
        {{ t('common.cancel') }}
      </button>
    </header>

    <!-- Info bar -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center bg-gray-50 px-4 py-2 rounded-xl border border-gray-200 mb-3 text-xs shrink-0 gap-2">
      <div class="flex items-center gap-2">
        <span class="font-bold text-gray-500">{{ t('other_expense.creator') }}:</span>
        <span class="font-bold text-gray-800">{{ currentUser.name }}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="font-bold text-gray-500">{{ t('other_expense.date') }}:</span>
        <div class="flex gap-2">
          <input 
            v-model="formData.date" 
            type="date" 
            class="px-2 py-1 border border-gray-300 rounded-lg font-mono font-bold text-[11px] bg-white focus:outline-none"
          />
          <input 
            v-model="formData.time" 
            type="time" 
            class="px-2 py-1 border border-gray-300 rounded-lg font-mono font-bold text-[11px] bg-white focus:outline-none"
          />
        </div>
      </div>
    </div>

    <!-- Form layout (No scroll, flex-1) -->
    <div class="flex-1 bg-white rounded-2xl border border-gray-100 p-5 flex flex-col gap-4 overflow-hidden justify-center shadow-xs">
      
      <!-- Object & Expense Type -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Object -->
        <div class="flex flex-col gap-1">
          <label class="text-[11px] font-bold text-gray-600">
            {{ t('other_expense.object') }} <span class="text-red-500">*</span>
          </label>
          <div class="flex items-center gap-2">
            <input 
              v-model="formData.object" 
              type="text" 
              :placeholder="t('other_expense.select_object')"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-[#E8772E] bg-white" 
              :class="{ 'border-red-300 bg-red-50/20': errors.object }"
              readonly
              @click="selectObject"
            />
            <button 
              type="button" 
              @click="selectObject" 
              class="w-9 h-9 flex items-center justify-center bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all shrink-0"
            >
              ...
            </button>
          </div>
          <p v-if="errors.object" class="text-red-500 text-[10px] font-bold">
            {{ t('other_expense.validation.object_required') }}
          </p>
        </div>

        <!-- Expense Type -->
        <div class="flex flex-col gap-1">
          <label class="text-[11px] font-bold text-gray-600">
            {{ t('other_expense.expense_type') }} <span class="text-red-500">*</span>
          </label>
          <select 
            v-model="formData.expenseType" 
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-xs bg-white focus:outline-none focus:ring-1 focus:ring-[#E8772E] h-9"
            required
          >
            <option value="chi_khac">{{ t('expense_types.other') }}</option>
            <option value="van_phong_pham">Văn phòng phẩm</option>
            <option value="di_lai">Đi lại</option>
            <option value="tiep_khach">Tiếp khách</option>
          </select>
        </div>
      </div>

      <!-- Expense Item & Amount -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Expense Item -->
        <div class="flex flex-col gap-1">
          <label class="text-[11px] font-bold text-gray-600">
            {{ t('other_expense.expense_item') }} <span class="text-red-500">*</span>
          </label>
          <div class="flex items-center gap-2">
            <input 
              v-model="formData.expenseItem" 
              type="text" 
              :placeholder="t('other_expense.select_expense')"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-[#E8772E]" 
              :class="{ 'border-red-300 bg-red-50/20': errors.expenseItem }"
              readonly
              @click="selectExpenseItem"
            />
            <button 
              type="button" 
              @click="selectExpenseItem" 
              class="w-9 h-9 flex items-center justify-center bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all shrink-0"
            >
              ...
            </button>
          </div>
          <p v-if="errors.expenseItem" class="text-red-500 text-[10px] font-bold">
            {{ t('other_expense.validation.expense_required') }}
          </p>
        </div>

        <!-- Amount -->
        <div class="flex flex-col gap-1 bg-[#FFF0F0] border border-red-200 p-2 px-3 rounded-xl justify-center">
          <label class="text-[11px] font-bold text-red-700">
            {{ t('other_expense.amount') }} <span class="text-red-500">*</span>
          </label>
          <div class="flex items-center gap-2">
            <input 
              :value="formattedAmount" 
              @input="handleAmountInput"
              type="text" 
              :placeholder="t('other_expense.enter_amount')"
              class="flex-1 px-3 py-1.5 border border-red-300 rounded-lg text-xs font-mono font-bold text-right text-red-600 focus:outline-none focus:ring-1 focus:ring-red-300 bg-white" 
              :class="{ 'border-red-500 bg-red-100/20': errors.amount }"
            />
            <button 
              type="button" 
              @click="triggerSelectAmount" 
              class="w-9 h-8 flex items-center justify-center bg-red-100 hover:bg-red-200 border border-red-300 text-xs font-bold text-red-700 rounded-lg active:scale-95 transition-all shrink-0"
            >
              ...
            </button>
          </div>
          <p v-if="errors.amount" class="text-red-500 text-[10px] font-bold">
            {{ t('other_expense.validation.amount_required') }}
          </p>
        </div>
      </div>

      <!-- Reason & Voucher Number -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Reason -->
        <div class="flex flex-col gap-1">
          <label class="text-[11px] font-bold text-gray-600">{{ t('other_expense.reason') }}</label>
          <div class="flex items-center gap-2">
            <input 
              v-model="formData.reason" 
              type="text" 
              :placeholder="t('other_expense.enter_reason')"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-[#E8772E]" 
            />
            <button 
              type="button" 
              @click="triggerSelectReason" 
              class="w-9 h-9 flex items-center justify-center bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all shrink-0"
            >
              ...
            </button>
          </div>
        </div>

        <!-- Voucher Number -->
        <div class="flex flex-col gap-1">
          <label class="text-[11px] font-bold text-gray-600">{{ t('other_expense.voucher_number') }}</label>
          <input 
            v-model="formData.voucherNumber" 
            type="text" 
            :placeholder="t('other_expense.enter_voucher')"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-xs bg-gray-50 focus:outline-none h-9" 
            readonly
          />
        </div>
      </div>

      <!-- Payment Method -->
      <div class="flex items-center gap-2 select-none py-1">
        <input 
          v-model="formData.isCash" 
          type="checkbox" 
          id="isCash" 
          class="w-4 h-4 accent-[#E8772E] cursor-pointer"
        />
        <label for="isCash" class="text-xs font-bold text-gray-700 cursor-pointer">
          {{ t('other_expense.cash') }}
        </label>
      </div>
    </div>

    <!-- Fixed Footer with Actions -->
    <div class="flex flex-col sm:flex-row gap-3 pt-3 border-t border-gray-200 shrink-0">
      <button 
        type="button" 
        class="flex-1 px-4 py-2.5 bg-[#4CAF50] hover:bg-[#43A047] text-white text-xs font-extrabold rounded-lg shadow-sm active:scale-95 transition-all flex items-center justify-center gap-1.5"
        @click="handleSaveAndPrint"
      >
        🖨️ {{ t('other_expense.save_and_print') }}
      </button>
      <button 
        type="button" 
        class="flex-1 px-4 py-2.5 bg-[#FF9800] hover:bg-[#F57C00] text-white text-xs font-extrabold rounded-lg shadow-sm active:scale-95 transition-all flex items-center justify-center gap-1.5"
        @click="handleSave"
      >
        💾 {{ t('other_expense.save') }}
      </button>
      <button 
        type="button" 
        class="flex-1 px-4 py-2.5 bg-[#F44336] hover:bg-[#E53935] text-white text-xs font-extrabold rounded-lg shadow-sm active:scale-95 transition-all flex items-center justify-center gap-1.5"
        @click="goBack"
      >
        ✕ {{ t('other_expense.skip') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useLanguageStore } from '@/stores/useLanguageStore'
import Swal from 'sweetalert2'

const router = useRouter()
const { profile } = useAuth()
const { t } = useLanguageStore()

// Current User Details
const currentUser = computed(() => ({
  name: profile.value?.full_name || 'Dương Thị Mộng'
}))

// Form State
const formData = reactive({
  date: '2026-07-02',
  time: '15:09:09',
  object: '',
  expenseType: 'chi_khac',
  expenseItem: '',
  amount: 0,
  reason: '',
  voucherNumber: '',
  isCash: true,
})

// Validation Errors state
const errors = reactive({
  object: false,
  expenseItem: false,
  amount: false
})

const formattedAmount = computed(() => {
  if (!formData.amount) return ''
  return Number(formData.amount).toLocaleString('vi-VN')
})

const handleAmountInput = (e: Event) => {
  const target = e.target as HTMLInputElement
  const rawValue = target.value.replace(/[^0-9]/g, '')
  formData.amount = rawValue ? parseInt(rawValue, 10) : 0
  if (formData.amount > 0) errors.amount = false
}

// Selection triggers
const selectObject = () => {
  formData.object = 'Khách vãng lai'
  errors.object = false
  triggerToast('info', 'Đã tự động chọn Đối tượng: Khách vãng lai')
}

const selectExpenseItem = () => {
  formData.expenseItem = 'Văn phòng phẩm'
  errors.expenseItem = false
  triggerToast('info', 'Đã tự động chọn Khoản chi: Văn phòng phẩm')
}

const triggerSelectAmount = () => {
  formData.amount = 150000
  errors.amount = false
  triggerToast('info', 'Đã nhập số tiền mặc định: 150.000đ')
}

const triggerSelectReason = () => {
  formData.reason = 'Mua sổ sách và bút ghi chép lễ tân'
  triggerToast('info', 'Đã tự động điền lý do chi')
}

const validateForm = (): boolean => {
  errors.object = !formData.object
  errors.expenseItem = !formData.expenseItem
  errors.amount = !formData.amount || formData.amount <= 0
  
  return !errors.object && !errors.expenseItem && !errors.amount
}

const triggerToast = (type: 'success' | 'error' | 'info' | 'warning', text: string) => {
  Swal.fire({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 2000,
    timerProgressBar: true,
    icon: type,
    title: text
  })
}

const handleSave = () => {
  if (!validateForm()) {
    triggerToast('error', t('other_expense.validation.amount_required'))
    return
  }
  Swal.fire({
    title: t('common.success'),
    text: `${t('other_expense.success.saved')}: ${formData.object} (${Number(formData.amount).toLocaleString('vi-VN')}đ)`,
    icon: 'success',
    confirmButtonText: t('common.close') || 'Đóng',
    confirmButtonColor: '#FF9800'
  })
  goBack()
}

const handleSaveAndPrint = () => {
  if (!validateForm()) {
    triggerToast('error', t('other_expense.validation.amount_required'))
    return
  }
  Swal.fire({
    title: t('common.success'),
    text: `${t('other_expense.success.saved_and_printed')}: ${formData.object} (${Number(formData.amount).toLocaleString('vi-VN')}đ)`,
    icon: 'success',
    confirmButtonText: t('common.close') || 'Đóng',
    confirmButtonColor: '#4CAF50'
  })
  goBack()
}

const goBack = () => {
  router.push('/reception/dashboard')
}
</script>
