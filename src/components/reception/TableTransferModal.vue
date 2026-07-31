<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import Swal from 'sweetalert2'
import { supabase, isSupabaseConfigured } from '@/lib/supabase'
import { useBranch } from '@/composables/useBranch'
import type { TableInfo, AreaInfo } from '@/stores/restaurantStore'

const props = defineProps<{
  isOpen: boolean
  sourceTable: TableInfo | null
  areas: AreaInfo[]
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'transferred'): void
}>()

const { t } = useI18n()
const { activeBranchId } = useBranch()

const isSubmitting = ref(false)
const targetTableId = ref('')
const transferMode = ref<'ALL' | 'PARTIAL'>('ALL')
const items = ref<any[]>([])
const transferQuantities = ref<Record<string, number>>({})

// When modal opens, load items if needed
watch(() => props.isOpen, async (newVal) => {
  if (newVal && props.sourceTable && props.sourceTable.table_id) {
    targetTableId.value = ''
    transferMode.value = 'ALL'
    items.value = []
    transferQuantities.value = {}
    await loadSourceItems()
  }
})

const availableTargetTables = computed(() => {
  const result: { id: string, code: string, areaName: string }[] = []
  if (!props.sourceTable) return result

  props.areas.forEach(area => {
    area.tables.forEach(table => {
      // Can transfer to any table except itself
      // In a real app we might only allow transfer to 'Available' or 'Serving', etc.
      // But merge requires target to be 'Serving' or 'Reserved'. 
      // We list all others.
      if (table.table_id && table.table_id !== props.sourceTable!.table_id) {
        result.push({ id: table.table_id, code: table.code, areaName: area.name })
      }
    })
  })
  return result
})

async function loadSourceItems() {
  if (!isSupabaseConfigured || !props.sourceTable?.table_id) return
  try {
    const { data, error } = await supabase.rpc('rpc_get_table_order_items', {
      p_table_id: props.sourceTable.table_id
    })
    if (error) throw error
    if (data && Array.isArray(data)) {
      items.value = data
      data.forEach((item: any) => {
        transferQuantities.value[item.order_detail_id] = 0 // default 0 for partial transfer
      })
    }
  } catch (err: any) {
    console.error('Failed to load items', err)
  }
}

function incrementTransfer(id: string, max: number) {
  if (transferQuantities.value[id] < max) {
    transferQuantities.value[id]++
  }
}

function decrementTransfer(id: string) {
  if (transferQuantities.value[id] > 0) {
    transferQuantities.value[id]--
  }
}

async function submitTransfer() {
  if (!targetTableId.value) {
    Swal.fire({ toast: true, position: 'top-end', icon: 'warning', title: 'Vui lòng chọn bàn đích', showConfirmButton: false, timer: 2000 })
    return
  }

  isSubmitting.value = true
  try {
    if (transferMode.value === 'ALL') {
      const { data, error } = await supabase.rpc('rpc_transfer_table_all', {
        p_branch_id: activeBranchId.value,
        p_source_table_id: props.sourceTable!.table_id,
        p_target_table_id: targetTableId.value
      })
      if (error) throw error
      if (data && data.success === false) throw new Error(data.error || 'Failed to transfer')
    } else {
      const itemsToTransfer = Object.keys(transferQuantities.value)
        .filter(id => transferQuantities.value[id] > 0)
        .map(id => ({ order_detail_id: id, quantity: transferQuantities.value[id] }))

      if (itemsToTransfer.length === 0) {
        Swal.fire({ toast: true, position: 'top-end', icon: 'warning', title: 'Vui lòng chọn ít nhất 1 món để chuyển', showConfirmButton: false, timer: 2000 })
        isSubmitting.value = false
        return
      }

      const { data, error } = await supabase.rpc('rpc_transfer_table_partial', {
        p_branch_id: activeBranchId.value,
        p_source_table_id: props.sourceTable!.table_id,
        p_target_table_id: targetTableId.value,
        p_items: itemsToTransfer
      })
      if (error) throw error
      if (data && data.success === false) throw new Error(data.error || 'Failed to transfer partial')
    }

    Swal.fire({ toast: true, position: 'top-end', icon: 'success', title: 'Chuyển bàn thành công', showConfirmButton: false, timer: 2000 })
    emit('transferred')
    emit('close')
  } catch (err: any) {
    console.error('Transfer error:', err)
    Swal.fire({ icon: 'error', title: 'Lỗi', text: err.message || 'Không thể chuyển bàn' })
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div v-if="isOpen && sourceTable" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="emit('close')"></div>
    <div class="bg-white border-2 border-amber-100 rounded-3xl w-full max-w-lg shadow-2xl p-6 z-10 relative animate-fade-in text-gray-700">
      
      <!-- Header -->
      <div class="flex items-center gap-3 mb-5 border-b border-gray-100 pb-3 select-none">
        <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-2xl">🔄</div>
        <div>
          <h3 class="text-lg font-black text-gray-900 tracking-tight">Chuyển / Ghép Bàn</h3>
          <p class="text-[10px] text-gray-400 font-bold uppercase">Từ bàn: <span class="text-amber-600">{{ sourceTable.code }}</span></p>
        </div>
        <button @click="emit('close')" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 flex items-center justify-center transition-colors font-bold text-sm">✕</button>
      </div>

      <div class="space-y-4">
        <!-- Target Table -->
        <div>
          <label class="block text-[11px] font-bold text-gray-500 uppercase mb-1">Bàn đích</label>
          <select v-model="targetTableId" class="w-full px-4 py-2.5 rounded-xl border-2 border-gray-100 bg-gray-50 font-bold text-sm outline-none focus:border-amber-400 transition-colors">
            <option value="" disabled>-- Chọn bàn đích --</option>
            <optgroup v-for="area in areas" :key="area.name" :label="area.name">
              <template v-for="tbl in availableTargetTables" :key="tbl.id">
                <option v-if="tbl.areaName === area.name" :value="tbl.id">{{ tbl.code }}</option>
              </template>
            </optgroup>
          </select>
        </div>

        <!-- Mode -->
        <div class="grid grid-cols-2 gap-2">
          <button @click="transferMode = 'ALL'" :class="[
            'py-2 rounded-xl border-2 font-bold text-xs transition-colors',
            transferMode === 'ALL' ? 'border-amber-400 bg-amber-50 text-amber-700' : 'border-gray-100 bg-white text-gray-500 hover:bg-gray-50'
          ]">
            Chuyển Toàn Bộ
          </button>
          <button @click="transferMode = 'PARTIAL'" :class="[
            'py-2 rounded-xl border-2 font-bold text-xs transition-colors',
            transferMode === 'PARTIAL' ? 'border-amber-400 bg-amber-50 text-amber-700' : 'border-gray-100 bg-white text-gray-500 hover:bg-gray-50'
          ]">
            Chuyển Một Phần
          </button>
        </div>

        <!-- Partial Items Selection -->
        <div v-if="transferMode === 'PARTIAL'" class="max-h-64 overflow-y-auto pr-1 space-y-2 custom-scrollbar">
          <div v-if="items.length === 0" class="text-center py-4 text-xs text-gray-400 font-bold">
            Không có món nào để chuyển.
          </div>
          <div v-for="item in items" :key="item.order_detail_id" class="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50">
            <div class="flex-1 min-w-0 pr-2">
              <div class="font-bold text-xs text-gray-800 truncate">{{ item.item_name }}</div>
              <div v-if="item.note" class="text-[10px] text-gray-400 truncate">{{ item.note }}</div>
              <div class="text-[10px] font-bold text-gray-500 mt-0.5">SL gốc: {{ item.quantity }}</div>
            </div>
            
            <div class="flex items-center gap-2 bg-white rounded-lg border border-gray-200 p-1">
              <button @click="decrementTransfer(item.order_detail_id)" class="w-6 h-6 rounded flex items-center justify-center hover:bg-gray-100 text-gray-600 font-bold text-sm select-none" :disabled="transferQuantities[item.order_detail_id] <= 0">-</button>
              <span class="w-4 text-center text-xs font-black text-amber-600">{{ transferQuantities[item.order_detail_id] }}</span>
              <button @click="incrementTransfer(item.order_detail_id, item.quantity)" class="w-6 h-6 rounded flex items-center justify-center hover:bg-gray-100 text-gray-600 font-bold text-sm select-none" :disabled="transferQuantities[item.order_detail_id] >= item.quantity">+</button>
            </div>
          </div>
        </div>

      </div>

      <!-- Actions -->
      <div class="flex gap-2 pt-4 border-t border-gray-100 mt-5">
        <button @click="emit('close')" class="flex-1 py-3 rounded-xl border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 text-xs font-bold transition-colors select-none" :disabled="isSubmitting">
          Hủy
        </button>
        <button @click="submitTransfer" class="flex-1 py-3 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-black transition-colors shadow-sm select-none flex items-center justify-center gap-2" :disabled="isSubmitting">
          <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
          Xác nhận chuyển
        </button>
      </div>

    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 10px;
}
</style>
