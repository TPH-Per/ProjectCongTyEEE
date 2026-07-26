<template>
  <div class="h-full flex flex-col space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-extrabold text-[hsl(var(--foreground))] tracking-tight">{{ $t('purchasing.ingredients.title') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">
          {{ $t('purchasing.ingredients.subtitle') }}
        </p>
      </div>
      <button @click="openModal()" class="flex items-center gap-2 px-4 py-2 bg-[hsl(var(--primary))] text-white rounded-xl font-bold hover:bg-[hsl(var(--primary))]/90 transition-colors shadow-sm">
        <Plus class="w-4 h-4" /> {{ $t('purchasing.ingredients.addIngredient') }}
      </button>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-2xl border border-[hsl(var(--border))] kawaii-shadow overflow-hidden flex-1 flex flex-col">
      <div class="p-4 border-b border-[hsl(var(--border))] flex items-center justify-between bg-gray-50/50">
        <div class="relative w-64">
          <Search class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input v-model="searchQuery" type="text" :placeholder="$t('purchasing.ingredients.searchPlaceholder')" class="w-full pl-9 pr-4 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))] transition-shadow" />
        </div>
      </div>
      
      <div class="flex-1 overflow-auto">
        <table class="w-full text-left text-sm whitespace-nowrap">
          <thead class="bg-gray-50/50 text-[hsl(var(--muted-foreground))] font-semibold sticky top-0 z-10 backdrop-blur-sm">
            <tr>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))] cursor-pointer hover:bg-gray-100 transition-colors" @click="sortBy('code')">
                <div class="flex items-center gap-2">
                  {{ $t('purchasing.ingredients.code') }}
                  <span v-if="sortField === 'code'" class="text-gray-400">
                    <component :is="sortDirection === 'asc' ? ArrowUp : ArrowDown" class="w-3 h-3" />
                  </span>
                </div>
              </th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))] cursor-pointer hover:bg-gray-100 transition-colors" @click="sortBy('name')">
                <div class="flex items-center gap-2">
                  {{ $t('purchasing.ingredients.name') }}
                  <span v-if="sortField === 'name'" class="text-gray-400">
                    <component :is="sortDirection === 'asc' ? ArrowUp : ArrowDown" class="w-3 h-3" />
                  </span>
                </div>
              </th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))]">{{ $t('purchasing.ingredients.unit') }}</th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))] cursor-pointer hover:bg-gray-100 transition-colors" @click="sortBy('imported_this_week')">
                <div class="flex items-center gap-2">
                  {{ $t('purchasing.ingredients.importedThisWeek') }}
                  <span v-if="sortField === 'imported_this_week'" class="text-gray-400">
                    <component :is="sortDirection === 'asc' ? ArrowUp : ArrowDown" class="w-3 h-3" />
                  </span>
                </div>
              </th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))] cursor-pointer hover:bg-gray-100 transition-colors" @click="sortBy('imported_this_month')">
                <div class="flex items-center gap-2">
                  {{ $t('purchasing.ingredients.importedThisMonth') }}
                  <span v-if="sortField === 'imported_this_month'" class="text-gray-400">
                    <component :is="sortDirection === 'asc' ? ArrowUp : ArrowDown" class="w-3 h-3" />
                  </span>
                </div>
              </th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))]">{{ $t('purchasing.ingredients.status') }}</th>
              <th class="px-6 py-4 border-b border-[hsl(var(--border))] text-right">{{ $t('purchasing.ingredients.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-if="loading" class="animate-pulse">
              <td colspan="7" class="px-6 py-4 text-center text-gray-400">{{ $t('purchasing.ingredients.loading') }}</td>
            </tr>
            <tr v-else-if="filteredIngredients.length === 0">
              <td colspan="7" class="px-6 py-12 text-center text-gray-400 flex flex-col items-center">
                <Box class="w-12 h-12 mb-3 text-gray-200" />
                {{ $t('purchasing.ingredients.notFound') }}
              </td>
            </tr>
            <tr v-else v-for="ing in filteredIngredients" :key="ing.id" class="hover:bg-gray-50/50 transition-colors">
              <td class="px-6 py-4 text-gray-500 font-mono text-xs">{{ ing.code }}</td>
              <td class="px-6 py-4 font-bold text-[hsl(var(--foreground))]">{{ ing.name }}</td>
              <td class="px-6 py-4 text-gray-600">{{ ing.unit }}</td>
              <td class="px-6 py-4 font-medium text-emerald-600">{{ ing.imported_this_week?.toLocaleString('vi-VN') || 0 }}</td>
              <td class="px-6 py-4 font-medium text-blue-600">{{ ing.imported_this_month?.toLocaleString('vi-VN') || 0 }}</td>
              <td class="px-6 py-4">
                <span :class="ing.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'" class="px-2.5 py-1 rounded-lg text-xs font-bold">
                  {{ ing.is_active ? $t('purchasing.ingredients.statusActive') : $t('purchasing.ingredients.statusInactive') }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <button @click="openModal(ing)" class="text-blue-600 hover:bg-blue-50 p-2 rounded-lg transition-colors inline-flex items-center">
                  <Edit class="w-4 h-4" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal Form -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col">
        <div class="px-6 py-4 border-b border-[hsl(var(--border))] flex items-center justify-between bg-gray-50/50">
          <h2 class="text-lg font-extrabold text-[hsl(var(--foreground))]">
            {{ isEditing ? $t('purchasing.ingredients.updateIngredient', 'Cập nhật Nguyên liệu') : $t('purchasing.ingredients.addIngredient', 'Thêm Nguyên liệu mới') }}
          </h2>
          <button @click="isModalOpen = false" class="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors">
            <X class="w-5 h-5" />
          </button>
        </div>
        
        <div class="p-6 space-y-4 overflow-y-auto max-h-[70vh]">
          <div>
            <label class="block text-xs font-bold text-[hsl(var(--muted-foreground))] uppercase mb-1.5">{{ $t('purchasing.ingredients.ingredientName', 'Tên Nguyên liệu') }} <span class="text-red-500">*</span></label>
            <input v-model="form.name" type="text" class="w-full px-3 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))]" :placeholder="$t('purchasing.ingredients.nameExample', 'VD: Cà phê hạt Arabica')" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-[hsl(var(--muted-foreground))] uppercase mb-1.5">{{ $t('purchasing.ingredients.productCode', 'Mã Sản phẩm') }}</label>
              <input v-model="form.code" type="text" class="w-full px-3 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))]" :placeholder="$t('purchasing.ingredients.leaveEmptyToAutoGenerate', 'Để trống tự sinh')" />
            </div>
            <div>
              <label class="block text-xs font-bold text-[hsl(var(--muted-foreground))] uppercase mb-1.5">{{ $t('purchasing.ingredients.unit', 'Đơn vị tính') }} <span class="text-red-500">*</span></label>
              <input v-model="form.unit" type="text" class="w-full px-3 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))]" :placeholder="$t('purchasing.ingredients.unitExample', 'kg, lít, cái...')" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-[hsl(var(--muted-foreground))] uppercase mb-1.5">{{ $t('purchasing.ingredients.refPrice', 'Đơn giá tham khảo') }}</label>
              <input v-model.number="form.cost_per_unit" type="number" class="w-full px-3 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))]" placeholder="0" />
            </div>
            <div>
              <label class="block text-xs font-bold text-[hsl(var(--muted-foreground))] uppercase mb-1.5">{{ $t('purchasing.ingredients.minStock', 'Tồn kho tối thiểu') }}</label>
              <input v-model.number="form.min_stock_level" type="number" class="w-full px-3 py-2 bg-white border border-[hsl(var(--border))] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]/20 focus:border-[hsl(var(--primary))]" placeholder="0" />
            </div>
          </div>
          
          <div class="flex items-center justify-between pt-4">
            <label class="text-sm font-bold text-gray-700">{{ $t('purchasing.ingredients.activeStatus', 'Trạng thái Hoạt động') }}</label>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="form.is_active" class="sr-only peer">
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-[hsl(var(--primary))]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[hsl(var(--primary))]"></div>
            </label>
          </div>
        </div>

        <div class="px-6 py-4 bg-gray-50/50 border-t border-[hsl(var(--border))] flex justify-end gap-3">
          <button @click="isModalOpen = false" type="button" class="px-5 py-2.5 text-sm font-bold text-gray-600 hover:bg-gray-100 rounded-xl transition-colors">
            {{ $t('purchasing.ingredients.cancel', 'Hủy') }}
          </button>
          <button @click="handleSave" :disabled="saving" class="px-5 py-2.5 text-sm font-bold text-white bg-[hsl(var(--primary))] hover:bg-[hsl(var(--primary))]/90 rounded-xl transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2">
            <svg v-if="saving" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            {{ saving ? $t('purchasing.ingredients.saving', 'Đang lưu...') : $t('purchasing.ingredients.saveInfo', 'Lưu thông tin') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Plus, Search, Edit, X, Box, ArrowUp, ArrowDown } from 'lucide-vue-next'
import { getIngredientStats, saveIngredient, type Ingredient, type IngredientStats } from '@/api/procurement.api'
import { useAuth } from '@/composables/useAuth'
import Swal from 'sweetalert2'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
const { profile } = useAuth()
const userBranchId = computed(() => profile.value?.branch_id || '')

const ingredients = ref<IngredientStats[]>([])
const loading = ref(true)
const searchQuery = ref('')

const sortField = ref<'name' | 'code' | 'imported_this_week' | 'imported_this_month'>('name')
const sortDirection = ref<'asc' | 'desc'>('asc')

const isModalOpen = ref(false)
const isEditing = ref(false)
const saving = ref(false)

const form = ref<Partial<Ingredient>>({
  id: '',
  branch_id: '',
  code: '',
  name: '',
  unit: '',
  cost_per_unit: 0,
  min_stock_level: 0,
  is_active: true
})

const sortBy = (field: 'name' | 'code' | 'imported_this_week' | 'imported_this_month') => {
  if (sortField.value === field) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortField.value = field
    sortDirection.value = 'desc' // default to desc for stats
    if (field === 'name' || field === 'code') sortDirection.value = 'asc'
  }
}

const filteredIngredients = computed(() => {
  let result = ingredients.value

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter((i: any) => 
      (i.name && i.name.toLowerCase().includes(q)) || 
      (i.code && i.code.toLowerCase().includes(q))
    )
  }

  return result.sort((a, b) => {
    let valA = a[sortField.value]
    let valB = b[sortField.value]
    
    // Handle string comparisons
    if (typeof valA === 'string' && typeof valB === 'string') {
      const cmp = valA.localeCompare(valB)
      return sortDirection.value === 'asc' ? cmp : -cmp
    }
    
    // Handle number comparisons
    valA = Number(valA) || 0
    valB = Number(valB) || 0
    return sortDirection.value === 'asc' ? valA - valB : valB - valA
  })
})

const loadData = async () => {
  try {
    loading.value = true
    ingredients.value = await getIngredientStats(userBranchId.value)
  } catch (e: any) {
    Swal.fire({ title: 'Lỗi', text: e.message || 'Lỗi tải danh mục', icon: 'error' })
  } finally {
    loading.value = false
  }
}

const openModal = (ing?: IngredientStats) => {
  if (ing) {
    isEditing.value = true
    form.value = { ...ing }
  } else {
    isEditing.value = false
    form.value = {
      id: '',
      branch_id: userBranchId.value,
      code: '',
      name: '',
      unit: '',
      cost_per_unit: 0,
      min_stock_level: 0,
      is_active: true
    }
  }
  isModalOpen.value = true
}

const handleSave = async () => {
  if (!form.value.name || !form.value.unit) {
    Swal.fire({ title: 'Thiếu thông tin', text: 'Vui lòng nhập Tên và Đơn vị tính.', icon: 'warning', confirmButtonColor: '#ff8a00' })
    return
  }

  try {
    saving.value = true
    await saveIngredient(form.value)
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: 'success',
      title: isEditing.value ? 'Cập nhật thành công' : 'Thêm nguyên liệu thành công',
      showConfirmButton: false,
      timer: 2000
    })
    isModalOpen.value = false
    await loadData()
  } catch (e: any) {
    Swal.fire({ title: 'Lỗi', text: e.message || 'Lỗi lưu nguyên liệu', icon: 'error' })
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>
