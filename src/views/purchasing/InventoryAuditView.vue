<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Kiểm kê Kho (Inventory Audit)</h1>
        <p class="text-gray-500 mt-1">Ghi nhận số lượng tồn kho thực tế và tự động điều chỉnh sổ sách.</p>
      </div>
      <div>
        <button 
          @click="loadStock" 
          class="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Làm mới dữ liệu
        </button>
      </div>
    </div>

    <!-- Error/Loading states -->
    <div v-if="error" class="p-4 bg-red-50 text-red-600 rounded-lg border border-red-200 mb-4">
      {{ error }}
    </div>

    <div class="bg-white rounded-lg shadow border border-gray-200 overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Nguyên vật liệu
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Tồn kho hiện tại
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Tồn kho thực tế (Kiểm đếm)
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Chênh lệch
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Ghi chú
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="loading && auditItems.length === 0">
            <td colspan="5" class="px-6 py-4 text-center text-gray-500">Đang tải dữ liệu...</td>
          </tr>
          <tr v-else-if="auditItems.length === 0">
            <td colspan="5" class="px-6 py-4 text-center text-gray-500">Kho hiện tại chưa có dữ liệu.</td>
          </tr>
          <tr v-for="(item, index) in auditItems" :key="item.ingredient_id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ item.ingredient_name }}</div>
              <div class="text-sm text-gray-500">Đơn vị: {{ item.unit }}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span class="px-2 py-1 text-sm font-semibold rounded-full bg-blue-100 text-blue-800">
                {{ item.current_quantity }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <input 
                v-model.number="item.actual_quantity" 
                type="number" 
                step="0.01" 
                min="0"
                class="block w-32 px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" 
              />
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span 
                class="text-sm font-bold"
                :class="getDiffClass(item.actual_quantity - item.current_quantity)"
              >
                {{ formatDiff(item.actual_quantity - item.current_quantity) }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <input 
                v-model="item.notes" 
                type="text" 
                placeholder="Lý do chênh lệch..."
                class="block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" 
              />
            </td>
          </tr>
        </tbody>
      </table>
      
      <div class="bg-gray-50 px-6 py-4 border-t border-gray-200 flex justify-between items-center">
        <div class="text-sm text-gray-600">
          Chỉ những mặt hàng có số lượng thực tế khác với tồn kho hiện tại mới được cập nhật.
        </div>
        <button 
          @click="submitAuditHandler" 
          class="inline-flex justify-center rounded-md border border-transparent shadow-sm px-6 py-2 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
          :disabled="loading || changedItems.length === 0"
        >
          <span v-if="loading">Đang lưu...</span>
          <span v-else>Cập Nhật ({{ changedItems.length }} mục)</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { usePurchasing } from '@/composables/usePurchasing'
import { useBranch } from '@/composables/useBranch'

const { loading, error, currentStock, fetchCurrentStock, submitAudit } = usePurchasing()
const { activeBranchId } = useBranch()

interface AuditItem {
  ingredient_id: string
  ingredient_name: string
  unit: string
  current_quantity: number
  actual_quantity: number
  notes: string
}

const auditItems = ref<AuditItem[]>([])

const loadStock = async () => {
  if (!activeBranchId.value) return
  await fetchCurrentStock(activeBranchId.value)
  
  auditItems.value = currentStock.value.map(stock => ({
    ingredient_id: stock.ingredient_id,
    ingredient_name: stock.ingredient_name,
    unit: stock.unit,
    current_quantity: Number(stock.quantity),
    actual_quantity: Number(stock.quantity), // Default to current
    notes: ''
  }))
}

// Watch for branch changes to reload data
watch(activeBranchId, (newId) => {
  if (newId) {
    loadStock()
  }
})

onMounted(() => {
  if (activeBranchId.value) {
    loadStock()
  }
})

const getDiffClass = (diff: number) => {
  if (diff > 0) return 'text-green-600'
  if (diff < 0) return 'text-red-600'
  return 'text-gray-400'
}

const formatDiff = (diff: number) => {
  if (diff > 0) return `+${diff.toFixed(2)}`
  if (diff < 0) return diff.toFixed(2)
  return '0.00'
}

const changedItems = computed(() => {
  return auditItems.value.filter(item => item.actual_quantity !== item.current_quantity)
})

const submitAuditHandler = async () => {
  if (changedItems.value.length === 0) return
  
  const payload = changedItems.value.map(item => ({
    item_id: item.ingredient_id,
    new_quantity: item.actual_quantity,
    notes: item.notes || `Chênh lệch ${formatDiff(item.actual_quantity - item.current_quantity)}`
  }))

  try {
    await submitAudit(payload)
    alert('Đã cập nhật tồn kho thành công!')
    await loadStock() // Reload new values
  } catch (err: any) {
    alert('Lỗi: ' + err.message)
  }
}
</script>
