<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">{{ $t('purchasing.receipts.receiveReceiptTitle') }} (Daily Receipt)</h1>
        <p class="text-gray-500 mt-1">{{ $t('purchasing.receipts.scanSubTitle') }}</p>
      </div>
    </div>

    <!-- Error/Loading states -->
    <div v-if="error" class="p-4 bg-red-50 text-red-600 rounded-lg border border-red-200 mb-4">
      {{ error }}
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- CỘT TRÁI: UPLOAD & HIỂN THỊ ẢNH SCAN -->
      <div class="bg-white p-6 rounded-lg shadow border border-gray-200 flex flex-col h-full">
        <h2 class="text-xl font-bold text-gray-800 mb-4">1. {{ $t('purchasing.receipts.scanImageLabel') }}</h2>
        
        <div 
          class="border-2 border-dashed border-gray-300 rounded-lg p-6 flex-1 flex flex-col items-center justify-center bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer relative"
          @click="triggerFileInput"
        >
          <!-- Nếu chưa có ảnh -->
          <div v-if="!previewImage" class="text-center">
            <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
              <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
            <div class="mt-4 flex text-sm text-gray-600 justify-center">
              <span class="relative font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
                {{ $t('purchasing.receipts.uploadImage') }}
              </span>
              <p class="pl-1">{{ $t('purchasing.receipts.uploadSubText') }}</p>
            </div>
            <p class="text-xs text-gray-500 mt-2">PNG, JPG, PDF tối đa 10MB</p>
          </div>

          <!-- Nếu đã có ảnh -->
          <div v-else class="w-full h-full min-h-[300px] flex items-center justify-center overflow-hidden">
            <img :src="previewImage" alt="Scan Preview" class="max-w-full max-h-[500px] object-contain rounded" />
            <button @click.stop="clearImage" class="absolute top-2 right-2 bg-red-600 text-white rounded-full p-2 hover:bg-red-700 shadow-md">
              ✕
            </button>
          </div>

          <input 
            type="file" 
            ref="fileInput" 
            class="hidden" 
            accept="image/png, image/jpeg, application/pdf"
            @change="handleFileUpload"
          />
        </div>
      </div>

      <!-- CỘT PHẢI: NHẬP TAY DỮ LIỆU & SUBMIT -->
      <div class="bg-white p-6 rounded-lg shadow border border-gray-200">
        <h2 class="text-xl font-bold text-gray-800 mb-4">2. {{ $t('purchasing.receipts.receiptDetails') }}</h2>
        
        <form @submit.prevent="submitForm" class="space-y-4">
          <!-- Thông tin chung -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">{{ $t('purchasing.receipts.columns.receiptCode') }}</label>
              <input v-model="form.receiptCode" type="text" :placeholder="$t('purchasing.receipts.receiptCodePlaceholder')" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">{{ $t('purchasing.receipts.columns.supplier') }}</label>
              <select v-model="form.supplierId" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required>
                <option value="" disabled>{{ $t('purchasing.receipts.selectSupplier') }}</option>
                <option v-for="sup in suppliers" :key="sup.id" :value="sup.id">
                  {{ sup.name }}
                </option>
              </select>
            </div>
          </div>

          <hr class="my-4 border-gray-200" />
          
          <!-- Chi tiết nguyên vật liệu -->
          <div>
            <div class="flex justify-between items-center mb-2">
              <label class="block text-sm font-medium text-gray-700">{{ $t('purchasing.receipts.receiptItems') }}</label>
              <button type="button" @click="addItem" class="text-sm text-blue-600 font-medium hover:text-blue-800">
                + {{ $t('purchasing.receipts.addRow') }}
              </button>
            </div>
            
            <div v-for="(item, index) in form.items" :key="index" class="flex gap-2 mb-3 items-start bg-gray-50 p-3 rounded border border-gray-100">
              <div class="flex-1">
                <input 
                  v-model="item.ingredient_name" 
                  @change="handleIngredientChange(item)"
                  list="ingredients-list" 
                  :placeholder="$t('purchasing.receipts.selectIngredient')" 
                  class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" 
                  required 
                />
                <datalist id="ingredients-list">
                  <option v-for="inv in ingredients" :key="inv.id" :value="inv.name"></option>
                </datalist>
              </div>
              <div class="w-24 relative">
                <input 
                  v-model="item.unit" 
                  @focus="activeInput = `unit_${index}`"
                  type="text" 
                  :placeholder="$t('purchasing.receipts.columns.unit')" 
                  class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" 
                  :class="{ 'ring-2 ring-blue-300 border-blue-400': activeInput === `unit_${index}` }"
                  required 
                />
              </div>
              <div class="w-24">
                <input v-model="item.quantity" type="number" step="0.01" min="0.01" :placeholder="$t('purchasing.receipts.columns.quantity')" class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
              </div>
              <div class="w-32">
                <input v-model="item.unit_price" type="number" step="1000" min="0" :placeholder="$t('purchasing.receipts.columns.totalValue')" class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
              </div>
              <button type="button" @click="removeItem(index)" class="p-2 text-red-500 hover:bg-red-50 rounded" title="Xóa dòng">
                ✕
              </button>
            </div>

            <div v-if="form.items.length === 0" class="text-sm text-gray-500 italic text-center py-4">
              {{ $t('purchasing.receipts.noItemsAdded') }}
            </div>
          </div>

          <!-- Total sum preview -->
          <div class="mt-4 p-4 bg-blue-50 rounded-lg flex justify-between items-center">
            <span class="font-bold text-gray-700">{{ $t('purchasing.receipts.totalReceiptValue') }}:</span>
            <span class="text-xl font-black text-blue-700">{{ formatCurrency(totalAmount) }}</span>
          </div>

          <div class="pt-4 flex justify-end">
            <button 
              type="submit" 
              class="inline-flex justify-center rounded-md border border-transparent shadow-sm px-6 py-3 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
              :disabled="loading || form.items.length === 0"
            >
              <span v-if="loading">{{ $t('common.loading') }}</span>
              <span v-else>{{ $t('purchasing.receipts.saveAndSync') }}</span>
            </button>
          </div>
        </form>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { usePurchasing } from '@/composables/usePurchasing'
import { useBranch } from '@/composables/useBranch'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
const { loading, error, ingredients, suppliers, fetchIngredients, fetchSuppliers, submitGoodsReceipt, uploadScanImage } = usePurchasing()
const { activeBranchId } = useBranch()

const activeInput = ref('')

// -- File Upload State --
const fileInput = ref<HTMLInputElement | null>(null)
const selectedFile = ref<File | null>(null)
const previewImage = ref<string | null>(null)

const triggerFileInput = () => {
  fileInput.value?.click()
}

const handleFileUpload = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const file = target.files[0]
    selectedFile.value = file
    previewImage.value = URL.createObjectURL(file)
  }
}

const clearImage = () => {
  selectedFile.value = null
  previewImage.value = null
  if (fileInput.value) fileInput.value.value = ''
}

// -- Form State --
const form = ref({
  receiptCode: '',
  supplierId: '',
  items: [] as Array<{ ingredient_name: string; unit: string; quantity: number | string; unit_price: number | string }>
})

const addItem = () => {
  form.value.items.push({ ingredient_name: '', unit: '', quantity: '', unit_price: '' })
}

const handleIngredientChange = (item: any) => {
  const found = ingredients.value.find(ing => ing.name.toLowerCase() === (item.ingredient_name || '').toLowerCase())
  if (found && found.unit) {
    item.unit = found.unit
  }
}

const removeItem = (index: number) => {
  form.value.items.splice(index, 1)
}

const totalAmount = computed(() => {
  return form.value.items.reduce((sum, item) => {
    const q = Number(item.quantity) || 0
    const p = Number(item.unit_price) || 0
    return sum + (q * p)
  }, 0)
})

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

// -- Submit Logic --
const submitForm = async () => {
  if (!activeBranchId.value) {
    alert(t('purchasing.receipts.selectBranchAlert'))
    return
  }

  try {
    let uploadedUrl = ''
    
    // 1. Upload ảnh lên Supabase Storage (Nếu có chọn)
    if (selectedFile.value) {
      uploadedUrl = await uploadScanImage(selectedFile.value)
    }

    // 2. Format dữ liệu
    const formattedItems = form.value.items.map(i => {
      const found = ingredients.value.find(ing => ing.name.toLowerCase() === (i.ingredient_name || '').toLowerCase());
      return {
        ingredient_id: found ? found.id : null,
        ingredient_name: found ? null : i.ingredient_name,
        unit: i.unit || (found ? found.unit : 'unit'),
        quantity: Number(i.quantity),
        unit_price: Number(i.unit_price)
      }
    })

    // 3. Gọi RPC cập nhật (Gồm Phiếu nhập + Cập nhật cộng dồn Tồn Kho)
    await submitGoodsReceipt(
      activeBranchId.value,
      form.value.receiptCode,
      form.value.supplierId,
      uploadedUrl,
      formattedItems
    )

    alert(t('purchasing.receipts.successMessage'))
    
    // Reset form
    form.value.receiptCode = ''
    form.value.supplierId = ''
    form.value.items = []
    clearImage()

  } catch (err: any) {
    alert(t('purchasing.receipts.errorMessage') + err.message)
  }
}

// -- Lifecycle --
onMounted(() => {
  fetchIngredients()
  fetchSuppliers()
})
</script>
