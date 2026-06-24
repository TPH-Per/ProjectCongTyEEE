<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">{{ t('auto_qu_n_l__chi_nh_nh') }}</h2>
        <p class="text-sm text-gray-500">{{ t('auto_qu_n_l__th_ng_tin_v__tr_ng_th_') }}</p>
      </div>
      <button class="kawaii-btn-primary flex items-center shadow-lg shadow-rose-200">
        <PlusIcon class="w-5 h-5 mr-2" />
        Thêm chi nhánh mới
      </button>
    </div>

    <!-- Filters & Search -->
    <div class="kawaii-card bg-white p-4 flex flex-col md:flex-row gap-4 justify-between items-center">
      <div class="relative w-full md:w-96">
        <SearchIcon class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input 
          type="text" 
          placeholder="Tìm kiếm chi nhánh, quản lý..." 
          class="kawaii-input pl-10 w-full"
        />
      </div>
      <div class="flex gap-2 w-full md:w-auto">
        <select class="kawaii-input w-full md:w-auto bg-gray-50">
          <option>{{ t('auto_t_t_c__tr_ng_th_i') }}</option>
          <option>{{ t('auto__ang_ho_t___ng') }}</option>
          <option>{{ t('auto_t_m_ng_ng') }}</option>
        </select>
        <button class="kawaii-btn-ghost flex items-center justify-center p-3">
          <FilterIcon class="w-5 h-5" />
        </button>
      </div>
    </div>

    <!-- Grid List -->
    <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
      <div v-for="branch in branches" :key="branch.id" class="kawaii-card bg-white overflow-hidden flex flex-col">
        <div class="h-24 bg-gray-100 relative group">
          <img v-if="branch.image" :src="branch.image" class="w-full h-full object-cover" />
          <div v-else class="w-full h-full kawaii-gradient opacity-80 flex items-center justify-center text-white">
            <StoreIcon class="w-10 h-10 opacity-50" />
          </div>
          <div class="absolute top-3 right-3">
            <span :class="[
              'px-2.5 py-1 text-xs font-semibold rounded-full shadow-sm',
              branch.status === 'active' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
            ]">
              {{ branch.status === 'active' ? 'Hoạt động' : 'Tạm ngưng' }}
            </span>
          </div>
        </div>
        <div class="p-5 flex-1 flex flex-col">
          <div class="flex justify-between items-start mb-2">
            <h3 class="text-lg font-bold text-gray-800">{{ branch.name }}</h3>
            <button class="text-gray-400 hover:text-[#FF7B89]">
              <MoreVerticalIcon class="w-5 h-5" />
            </button>
          </div>
          <p class="text-sm text-gray-500 mb-4 flex items-start">
            <MapPinIcon class="w-4 h-4 mr-1 mt-0.5 flex-shrink-0" />
            {{ branch.address }}
          </p>
          
          <div class="mt-auto pt-4 border-t border-gray-100 grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ t('auto_qu_n_l_') }}</p>
              <p class="text-sm font-medium text-gray-700 flex items-center">
                <UserIcon class="w-4 h-4 mr-1" /> {{ branch.manager }}
              </p>
            </div>
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ t('auto_s_c_ch_a') }}</p>
              <p class="text-sm font-medium text-gray-700">{{ branch.capacity }} bàn</p>
            </div>
          </div>
        </div>
        <div class="px-5 py-3 bg-gray-50 border-t border-gray-100 flex justify-between">
          <button class="text-sm font-medium text-[#FF7B89] hover:underline">{{ t('auto_c_u_h_nh') }}</button>
          <button class="text-sm font-medium text-gray-600 hover:text-gray-800">{{ t('auto_th_ng_k_') }}</button>
        </div>
      </div>
      <div v-if="loading" class="col-span-full text-center py-8 text-gray-500">
        Đang tải...
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted } from 'vue'
import { 
  PlusIcon, 
  SearchIcon, 
  FilterIcon,
  StoreIcon,
  MoreVerticalIcon,
  MapPinIcon,
  UserIcon
} from 'lucide-vue-next'
import { useBranch } from '@/composables/useBranch'

const { listBranches } = useBranch()
const branches = ref<any[]>([])
const loading = ref(true)

onMounted(async () => {
  loading.value = true
  try {
    const data = await listBranches()
    branches.value = data.map((b: any) => ({
      id: b.id,
      name: b.name,
      address: b.address || 'Chưa cập nhật địa chỉ',
      manager: 'Chưa cập nhật',
      capacity: 0,
      status: b.is_active ? 'active' : 'inactive',
      image: null
    }))
  } catch (err) {
    console.error('Lỗi khi tải danh sách chi nhánh:', err)
  } finally {
    loading.value = false
  }
})
</script>
