<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getRequisitions, createRequisition, approveRequisition, type Requisition, type RequisitionItem, type QuoteItem } from '@/api/procurement.api'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import Swal from 'sweetalert2'

const { role, isAdmin } = useAuth()
const isProcurementManager = computed(() => role.value === 'procurement_manager' || isAdmin.value)

const requisitions = ref<Requisition[]>([])
const loading = ref(true)
const errorMsg = ref('')

// For creating new requisition
const showCreateModal = ref(false)
const newNotes = ref('')
const selectedBranchId = ref('')
const branches = ref<any[]>([])
const newItems = ref<RequisitionItem[]>([
  { ingredient_id: '00000000-0000-0000-0000-000000000000', ingredient_name: 'Sample Item', quantity: 10 }
])
const newQuotes = ref<QuoteItem[]>([
  { id: 'q1', supplier_name: 'Supplier A', product_url: 'https://example.com/item1' },
  { id: 'q2', supplier_name: 'Supplier B', product_url: 'https://example.com/item2' },
  { id: 'q3', supplier_name: 'Supplier C', product_url: 'https://example.com/item3' }
])

const loadData = async () => {
  try {
    loading.value = true
    requisitions.value = await getRequisitions()
    if (isProcurementManager.value && branches.value.length === 0) {
      const { data } = await supabase.from('branches').select('id, name').order('name')
      if (data) branches.value = data
    }

    // Fetch a real ingredient for demo purposes to avoid foreign key errors on approval
    const { data: ingData } = await supabase.from('ingredients').select('id, name').limit(1)
    if (ingData && ingData.length > 0) {
      newItems.value[0].ingredient_id = ingData[0].id
      newItems.value[0].ingredient_name = ingData[0].name
    }
  } catch (e: any) {
    errorMsg.value = e.message || 'Lỗi tải phiếu đề xuất'
  } finally {
    loading.value = false
  }
}

const handleCreate = async () => {
  try {
    if (isProcurementManager.value && !selectedBranchId.value) {
      Swal.fire('Lỗi', 'Vui lòng chọn chi nhánh', 'error')
      return
    }
    await createRequisition(newItems.value, newQuotes.value, newNotes.value, selectedBranchId.value || undefined)
    showCreateModal.value = false
    selectedBranchId.value = ''
    newNotes.value = ''
    await loadData()
    Swal.fire({
      icon: 'success',
      title: 'Tạo phiếu đề xuất thành công',
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 2000
    })
  } catch (e: any) {
    Swal.fire('Lỗi tạo phiếu', e.message, 'error')
  }
}

const handleApprove = async (reqId: string, quoteId: string) => {
  try {
    const result = await Swal.fire({
      title: 'Duyệt phiếu đề xuất?',
      text: 'Bạn có chắc chắn duyệt phiếu đề xuất với báo giá này không?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy'
    })
    
    if (!result.isConfirmed) return
    
    await approveRequisition(reqId, quoteId)
    await loadData()
    
    Swal.fire({
      icon: 'success',
      title: 'Duyệt phiếu thành công',
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 2000
    })
  } catch (e: any) {
    Swal.fire('Lỗi duyệt phiếu', e.message, 'error')
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">{{ $t('purchasing.requisitions.title', 'Quản lý Đề xuất mua hàng (3-way)') }}</h1>
      <button 
        @click="showCreateModal = true"
        class="px-4 py-2 bg-blue-600 text-white rounded-md shadow hover:bg-blue-700"
      >
        {{ $t('purchasing.requisitions.createNew', '+ Tạo đề xuất mới') }}
      </button>
    </div>

    <div v-if="errorMsg" class="mb-4 p-4 bg-red-50 text-red-700 rounded-md">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-gray-500">{{ $t('purchasing.requisitions.loading', 'Đang tải...') }}</div>

    <div v-else class="grid gap-6">
      <div 
        v-for="req in requisitions" 
        :key="req.id"
        class="p-4 bg-white border rounded-lg shadow-sm"
      >
        <div class="flex justify-between mb-4 border-b pb-2">
          <div>
            <div class="font-semibold text-lg">{{ req.req_number }} <span class="text-sm font-normal text-gray-500 ml-2">({{ req.branch_name || $t('purchasing.requisitions.defaultBranch', 'Chi nhánh mặc định') }})</span></div>
            <div class="text-sm text-gray-500">{{ new Date(req.created_at).toLocaleString() }}</div>
          </div>
          <div>
            <span 
              class="px-3 py-1 rounded-full text-xs font-medium"
              :class="{
                'bg-yellow-100 text-yellow-800': req.status === 'PENDING',
                'bg-green-100 text-green-800': req.status === 'APPROVED',
                'bg-red-100 text-red-800': req.status === 'REJECTED'
              }"
            >
              {{ 
                req.status === 'PENDING' ? $t('purchasing.requisitions.status.pending', 'CHỜ DUYỆT') : 
                req.status === 'APPROVED' ? $t('purchasing.requisitions.status.approved', 'ĐÃ DUYỆT') : 
                req.status === 'REJECTED' ? $t('purchasing.requisitions.status.rejected', 'TỪ CHỐI') : req.status 
              }}
            </span>
          </div>
        </div>

        <div class="mb-4">
          <p class="text-sm font-medium mb-1">{{ $t('purchasing.requisitions.notes', 'Ghi chú:') }}</p>
          <p class="text-gray-700 bg-gray-50 p-2 rounded">{{ req.notes || $t('purchasing.requisitions.noNotes', 'Không có ghi chú') }}</p>
        </div>

        <!-- 3-way Quotes -->
        <div v-if="req.status === 'PENDING'" class="mt-4">
          <p class="text-sm font-medium mb-2">{{ $t('purchasing.requisitions.quotesSuggested', '3 Báo giá đề xuất:') }}</p>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div 
              v-for="quote in req.quotes_jsonb" 
              :key="quote.id"
              class="border rounded p-3 bg-gray-50"
            >
              <p class="font-medium truncate">{{ quote.supplier_name }}</p>
              <a :href="quote.product_url" target="_blank" class="text-sm text-blue-600 hover:underline block truncate mb-3">
                {{ quote.product_url }}
              </a>
              <button 
                v-if="isProcurementManager"
                @click="handleApprove(req.id, quote.id)"
                class="w-full px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 transition"
              >
                {{ $t('purchasing.requisitions.approveQuote', 'Duyệt chọn NCC này') }}
              </button>
            </div>
          </div>
        </div>

        <div v-else-if="req.status === 'APPROVED'" class="mt-4 p-3 bg-green-50 border border-green-200 rounded">
          {{ $t('purchasing.requisitions.quoteConfirmed', 'Đã chốt báo giá:') }} <strong>{{ req.quotes_jsonb?.find(q => q.id === req.selected_quote_id)?.supplier_name }}</strong>
          <br>
          <span class="text-sm text-gray-600">{{ $t('purchasing.requisitions.autoCreatedReceipt', '(Đã tự động tạo Phiếu nhập kho & Lưu vào DB NCC)') }}</span>
        </div>
      </div>
      
      <div v-if="!requisitions.length" class="text-center py-10 text-gray-500 bg-white rounded shadow-sm">
        {{ $t('purchasing.requisitions.empty', 'Chưa có phiếu đề xuất nào.') }}
      </div>
    </div>

    <!-- Modal Tạo Đề xuất -->
    <div v-if="showCreateModal" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl w-full max-w-2xl overflow-hidden">
        <div class="px-6 py-4 border-b flex justify-between items-center">
          <h2 class="text-lg font-bold">{{ $t('purchasing.requisitions.modalTitle', 'Tạo Đề xuất Mua hàng (3 Báo giá)') }}</h2>
          <button @click="showCreateModal = false" class="text-gray-500 hover:text-black">✕</button>
        </div>
        <div class="p-6">
          <div class="mb-4" v-if="isProcurementManager">
            <label class="block text-sm font-medium mb-1">{{ $t('purchasing.requisitions.branchLabel', 'Chi nhánh (bắt buộc chọn)') }}</label>
            <select v-model="selectedBranchId" class="w-full p-2 border rounded">
              <option value="">{{ $t('purchasing.requisitions.selectBranch', '-- Chọn chi nhánh --') }}</option>
              <option v-for="b in branches" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>
          </div>

          <div class="mb-4">
            <label class="block text-sm font-medium mb-1">{{ $t('purchasing.requisitions.notesLabel', 'Ghi chú / Mục đích mua') }}</label>
            <input v-model="newNotes" type="text" class="w-full p-2 border rounded" :placeholder="$t('purchasing.requisitions.notesPlaceholder', 'Nhập lý do mua hàng...')">
          </div>

          <div class="mb-4">
            <label class="block text-sm font-medium mb-2">{{ $t('purchasing.requisitions.quotesLabel', '3 Nhà cung cấp tham khảo') }}</label>
            <div v-for="(q, idx) in newQuotes" :key="q.id" class="flex gap-2 mb-2">
              <span class="py-2 text-gray-500 font-medium">#{{ idx + 1 }}</span>
              <input v-model="q.supplier_name" type="text" class="w-1/3 p-2 border rounded" :placeholder="$t('purchasing.requisitions.supplierNamePlaceholder', 'Tên NCC')">
              <input v-model="q.product_url" type="text" class="flex-1 p-2 border rounded" :placeholder="$t('purchasing.requisitions.productUrlPlaceholder', 'Link sản phẩm')">
            </div>
          </div>
          
          <div class="bg-blue-50 p-4 rounded text-sm text-blue-800">
            {{ $t('purchasing.requisitions.demoNote', '* Tính năng demo: Sản phẩm cần mua đang được fix cứng trong code. Khi áp dụng thực tế sẽ có form chọn nguyên liệu.') }}
          </div>
        </div>
        <div class="px-6 py-4 bg-gray-50 border-t flex justify-end gap-3">
          <button @click="showCreateModal = false" class="px-4 py-2 border bg-white rounded shadow-sm hover:bg-gray-50">{{ $t('purchasing.requisitions.cancel', 'Hủy') }}</button>
          <button @click="handleCreate" class="px-4 py-2 bg-blue-600 text-white rounded shadow-sm hover:bg-blue-700">{{ $t('purchasing.requisitions.create', 'Tạo Phiếu') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
