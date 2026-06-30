<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Quản Lý Hóa Đơn (Accounting)</h1>
        <p class="text-gray-500 mt-1">Xuất báo cáo thuế và xử lý hóa đơn sai lệch</p>
      </div>
      
      <!-- Date Filters -->
      <div class="flex items-center gap-3 bg-white p-3 rounded-lg shadow-sm">
        <input 
          type="date" 
          v-model="startDate"
          class="px-3 py-2 border rounded focus:ring-2 focus:ring-blue-500"
        />
        <span class="text-gray-500">đến</span>
        <input 
          type="date" 
          v-model="endDate"
          class="px-3 py-2 border rounded focus:ring-2 focus:ring-blue-500"
        />
        <button 
          @click="loadData" 
          class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
          :disabled="loading"
        >
          <span v-if="loading">Đang tải...</span>
          <span v-else>Lọc dữ liệu</span>
        </button>
      </div>
    </div>

    <!-- Error State -->
    <div v-if="error" class="p-4 bg-red-50 text-red-600 rounded-lg border border-red-200">
      {{ error }}
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Mã Bill / Thời gian</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tổng tiền Bill</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Số Hóa Đơn (Ký hiệu)</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Công Ty / MST</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trạng Thái</th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Thao tác</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="taxReports.length === 0">
            <td colspan="6" class="px-6 py-12 text-center text-gray-500">
              Không có dữ liệu hóa đơn trong khoảng thời gian này
            </td>
          </tr>
          <tr v-for="item in taxReports" :key="item.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="font-medium text-gray-900">{{ item.bill_code || 'N/A' }}</div>
              <div class="text-sm text-gray-500">{{ new Date(item.created_at).toLocaleString() }}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">
              {{ formatCurrency(item.grand_total) }}
            </td>
            <!-- Nested Invoice Info (from inner join) -->
            <td class="px-6 py-4 whitespace-nowrap">
              <div v-if="item.invoices && item.invoices.length > 0">
                <div class="font-bold text-blue-600">{{ item.invoices[0].invoice_number }}</div>
                <div class="text-xs text-gray-500">{{ item.invoices[0].invoice_symbol }}</div>
              </div>
              <span v-else class="text-gray-400 italic">Chưa xuất hóa đơn</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div v-if="item.invoices && item.invoices.length > 0" class="max-w-[200px] truncate" :title="item.invoices[0].buyer_company">
                <div class="text-sm font-medium text-gray-900">{{ item.invoices[0].buyer_company || 'Khách lẻ' }}</div>
                <div class="text-sm text-gray-500">{{ item.invoices[0].buyer_tax_code || 'Không có MST' }}</div>
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span v-if="item.invoices && item.invoices.length > 0" 
                class="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full"
                :class="item.invoices[0].status === 'VALID' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'">
                {{ item.invoices[0].status }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button 
                v-if="item.invoices && item.invoices.length > 0 && item.invoices[0].status === 'VALID'"
                @click="openReplaceModal(item.id, item.invoices[0])"
                class="text-indigo-600 hover:text-indigo-900 bg-indigo-50 px-3 py-1 rounded border border-indigo-100 transition-colors"
              >
                Sửa/Thay thế
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal Replace Invoice -->
    <div v-if="showModal" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Background overlay -->
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" @click="showModal = false" aria-hidden="true"></div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        
        <!-- Modal panel -->
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg w-full">
          <form @submit.prevent="submitReplaceInvoice">
            <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div class="sm:flex sm:items-start">
                <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                  <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                    Phát hành hóa đơn thay thế
                  </h3>
                  <div class="mt-2 mb-4">
                    <p class="text-sm text-gray-500">Hệ thống sẽ khóa hóa đơn cũ (chuyển sang UPDATED) và tạo một hóa đơn mới nối vào Bill hiện tại.</p>
                  </div>
                  
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Mã Số Thuế Mới</label>
                      <input v-model="editForm.taxCode" type="text" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Tên Công Ty Mới</label>
                      <input v-model="editForm.company" type="text" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700">Ký hiệu hóa đơn</label>
                        <input v-model="editForm.symbol" type="text" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-gray-700">Số hóa đơn mới</label>
                        <input v-model="editForm.number" type="text" class="mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm" required />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button 
                type="submit" 
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
                :disabled="isSubmitting"
              >
                {{ isSubmitting ? 'Đang xử lý...' : 'Xác nhận thay thế' }}
              </button>
              <button 
                type="button" 
                @click="showModal = false"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Hủy bỏ
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAccounting } from '@/composables/useAccounting'

const { taxReports, loading, error, fetchTaxReport, replaceInvoice } = useAccounting()

// Date filters (Default to current month)
const today = new Date()
const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0)

const startDate = ref(startOfMonth.toISOString().split('T')[0])
const endDate = ref(endOfMonth.toISOString().split('T')[0])

// Modal State
const showModal = ref(false)
const isSubmitting = ref(false)
const selectedBillId = ref<string>('')

const editForm = ref({
  taxCode: '',
  company: '',
  symbol: '1C26MQV',
  number: ''
})

const loadData = async () => {
  // Ensure dates cover the whole day
  const start = `${startDate.value}T00:00:00.000Z`
  const end = `${endDate.value}T23:59:59.999Z`
  await fetchTaxReport(start, end)
}

const openReplaceModal = (billId: string, currentInvoice: any) => {
  selectedBillId.value = billId
  editForm.value = {
    taxCode: currentInvoice.buyer_tax_code || '',
    company: currentInvoice.buyer_company || '',
    symbol: currentInvoice.invoice_symbol || '1C26MQV',
    number: '' // Needs a new invoice number from the accountant
  }
  showModal.value = true
}

const submitReplaceInvoice = async () => {
  if (!selectedBillId.value) return
  
  isSubmitting.value = true
  try {
    await replaceInvoice(
      selectedBillId.value,
      editForm.value.symbol,
      editForm.value.number,
      editForm.value.taxCode,
      editForm.value.company
    )
    showModal.value = false
    alert('Thay thế hóa đơn thành công! (No Race Condition guaranteed)')
    await loadData() // Reload to see the new valid invoice and the updated old one
  } catch (err: any) {
    alert('Lỗi khi thay thế: ' + err.message)
  } finally {
    isSubmitting.value = false
  }
}

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}

onMounted(() => {
  loadData()
})
</script>
