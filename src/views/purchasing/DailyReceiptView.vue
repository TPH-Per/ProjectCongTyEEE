<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Tiếp nhận Phiếu giao hàng (Daily Receipt)</h1>
        <p class="text-gray-500 mt-1">Scan phiếu giao từ bếp và cập nhật số lượng tồn kho thực tế.</p>
      </div>
    </div>

    <!-- Error/Loading states -->
    <div v-if="error" class="p-4 bg-red-50 text-red-600 rounded-lg border border-red-200 mb-4">
      {{ error }}
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- CỘT TRÁI: UPLOAD & HIỂN THỊ ẢNH SCAN -->
      <div class="bg-white p-6 rounded-lg shadow border border-gray-200 flex flex-col h-full">
        <h2 class="text-xl font-bold text-gray-800 mb-4">1. Ảnh Scan / Chụp Phiếu</h2>
        
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
                Tải ảnh lên
              </span>
              <p class="pl-1">hoặc kéo thả vào đây</p>
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
        <h2 class="text-xl font-bold text-gray-800 mb-4">2. Nhập thông tin & Mã định danh</h2>
        
        <form @submit.prevent="submitForm" class="space-y-4">
          <!-- Thông tin chung -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Mã Phiếu Giao</label>
              <input v-model="form.receiptCode" type="text" placeholder="VD: GR-20260629-01" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Nhà Cung Cấp</label>
              <input v-model="form.supplierName" type="text" placeholder="VD: Công ty TNHH Rau Sạch" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
            </div>
          </div>

          <hr class="my-4 border-gray-200" />
          
          <!-- Chi tiết nguyên vật liệu -->
          <div>
            <div class="flex justify-between items-center mb-2">
              <label class="block text-sm font-medium text-gray-700">Chi tiết hàng hóa (Nhập tay)</label>
              <button type="button" @click="addItem" class="text-sm text-blue-600 font-medium hover:text-blue-800">
                + Thêm dòng
              </button>
            </div>
            
            <div v-for="(item, index) in form.items" :key="index" class="flex gap-2 mb-3 items-start bg-gray-50 p-3 rounded border border-gray-100">
              <div class="flex-1">
                <select v-model="item.item_id" class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required>
                  <option value="" disabled>Chọn mã NVL</option>
                  <option v-for="inv in inventoryItems" :key="inv.id" :value="inv.id">
                    [{{ inv.code }}] - {{ inv.name }} ({{ inv.unit }})
                  </option>
                </select>
              </div>
              <div class="w-24">
                <input v-model="item.quantity" type="number" step="0.01" min="0.01" placeholder="Số lượng" class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
              </div>
              <div class="w-32">
                <input v-model="item.unit_price" type="number" step="1000" min="0" placeholder="Đơn giá" class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
              </div>
              <button type="button" @click="removeItem(index)" class="p-2 text-red-500 hover:bg-red-50 rounded" title="Xóa dòng">
                ✕
              </button>
            </div>

            <div v-if="form.items.length === 0" class="text-sm text-gray-500 italic text-center py-4">
              Chưa có mặt hàng nào. Bấm "+ Thêm dòng" để bắt đầu.
            </div>
          </div>

          <!-- Total sum preview -->
          <div class="mt-4 p-4 bg-blue-50 rounded-lg flex justify-between items-center">
            <span class="font-bold text-gray-700">Tổng Giá Trị Phiếu:</span>
            <span class="text-xl font-black text-blue-700">{{ formatCurrency(totalAmount) }}</span>
          </div>

          <div class="pt-4 flex justify-end">
            <button 
              type="submit" 
              class="inline-flex justify-center rounded-md border border-transparent shadow-sm px-6 py-3 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
              :disabled="loading || form.items.length === 0"
            >
              <span v-if="loading">Đang lưu...</span>
              <span v-else>Lưu Phiếu & Cập Nhật Tồn Kho</span>
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

const { loading, error, inventoryItems, fetchInventoryItems, submitGoodsReceipt, uploadScanImage } = usePurchasing()
const { activeBranchId } = useBranch()

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
  supplierName: '',
  items: [] as Array<{ item_id: string; quantity: number | string; unit_price: number | string }>
})

const addItem = () => {
  form.value.items.push({ item_id: '', quantity: '', unit_price: '' })
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
    alert("Vui lòng chọn chi nhánh trước khi làm việc.")
    return
  }

  try {
    let uploadedUrl = ''
    
    // 1. Upload ảnh lên Supabase Storage (Nếu có chọn)
    if (selectedFile.value) {
      uploadedUrl = await uploadScanImage(selectedFile.value)
    }

    // 2. Format dữ liệu
    const formattedItems = form.value.items.map(i => ({
      item_id: i.item_id,
      quantity: Number(i.quantity),
      unit_price: Number(i.unit_price)
    }))

    // 3. Gọi RPC cập nhật (Gồm Phiếu nhập + Cập nhật cộng dồn Tồn Kho)
    await submitGoodsReceipt(
      activeBranchId.value,
      form.value.receiptCode,
      form.value.supplierName,
      uploadedUrl,
      formattedItems
    )

    alert("Nhập hàng thành công! Tồn kho đã được cập nhật.")
    
    // Reset form
    form.value.receiptCode = ''
    form.value.supplierName = ''
    form.value.items = []
    clearImage()

  } catch (err: any) {
    alert('Lỗi: ' + err.message)
  }
}

// -- Lifecycle --
onMounted(() => {
  if (activeBranchId.value) {
    fetchInventoryItems(activeBranchId.value)
  }
})
</script>
