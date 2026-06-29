<template>
  <div class="space-y-6">

    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">{{ t('branch.title') }}</h2>
        <p class="text-sm text-gray-500">{{ t('branch.title') }}</p>
      </div>
      <button 
        class="kawaii-btn-primary flex items-center shadow-lg shadow-rose-200"
        @click="openCreatePanel"
      >
        <PlusIcon class="w-5 h-5 mr-2" />
        {{ t('branch.add') }}
      </button>
    </div>

    <!-- Filters & Search -->
    <div class="kawaii-card bg-white p-4 flex flex-col md:flex-row gap-4 justify-between items-center">
      <div class="relative w-full md:w-96">
        <SearchIcon class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input 
          type="text" 
          :placeholder="t('common.search')" 
          class="kawaii-input pl-10 w-full"
        />
      </div>
      <div class="flex gap-2 w-full md:w-auto">
        <select class="kawaii-input w-full md:w-auto bg-gray-50">
          <option>All</option>
          <option>Active</option>
          <option>Inactive</option>
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
          <div class="w-full h-full kawaii-gradient opacity-80 flex items-center justify-center text-white">
            <StoreIcon class="w-10 h-10 opacity-50" />
          </div>
          <div class="absolute top-3 right-3">
            <button 
              @click="handleToggleStatus(branch)"
              :class="[
                'px-2.5 py-1 text-xs font-semibold rounded-full shadow-sm cursor-pointer',
                branch.is_active ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
              ]"
            >
              {{ branch.is_active ? 'Active' : t('branch.deactivate') }}
            </button>
          </div>
        </div>
        <div class="p-5 flex-1 flex flex-col">
          <div class="flex justify-between items-start mb-2">
            <h3 class="text-lg font-bold text-gray-800">{{ branch.name }}</h3>
            <button class="text-gray-400 hover:text-[#FF7B89]" @click="openEditPanel(branch)">
              <MoreVerticalIcon class="w-5 h-5" />
            </button>
          </div>
          <p class="text-sm text-gray-500 mb-4 flex items-start">
            <MapPinIcon class="w-4 h-4 mr-1 mt-0.5 flex-shrink-0" />
            {{ branch.address || t('common.no_data') }}
          </p>
          
          <div class="mt-auto pt-4 border-t border-gray-100 grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ t('branch.manager') }}</p>
              <p class="text-sm font-medium text-gray-700 flex items-center">
                <UserIcon class="w-4 h-4 mr-1" /> {{ branch.manager?.full_name || t('common.no_data') }}
              </p>
            </div>
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ t('branch.capacity') }}</p>
              <p class="text-sm font-medium text-gray-700">{{ branch.capacity }}</p>
            </div>
          </div>
        </div>
        <div class="px-5 py-3 bg-gray-50 border-t border-gray-100 flex justify-between">
          <button class="text-sm font-medium text-[#FF7B89] hover:underline" @click="openEditPanel(branch)">{{ t('branch.edit') }}</button>
        </div>
      </div>
      <div v-if="loading" class="col-span-full text-center py-8 text-gray-500">
        {{ t('common.loading') }}
      </div>
    </div>

    <!-- Slide Panel -->
    <div v-if="showPanel" class="fixed inset-0 z-50 overflow-hidden">
      <div class="absolute inset-0 bg-black bg-opacity-50 transition-opacity" @click="closePanel"></div>
      <div class="absolute inset-y-0 right-0 max-w-md w-full bg-white shadow-xl flex flex-col transform transition-transform duration-250 ease-out">
        <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center bg-[#0C0B0A] text-[#F0EBE2]">
          <h2 class="text-xl font-serif font-bold text-[#C9A85C]">
            {{ editingBranch ? t('branch.edit') : t('branch.add') }}
          </h2>
          <button @click="closePanel" class="text-[#9B8E80] hover:text-white">
            ✕
          </button>
        </div>
        <div class="flex-1 overflow-y-auto p-6 bg-[#1A1815] text-[#F0EBE2]">
          <form @submit.prevent="saveBranch" class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1 font-serif">Name *</label>
              <input v-model="form.name" type="text" required class="w-full bg-[#241F1A] border border-[#3A332A] text-[#F0EBE2] rounded px-3 py-2 focus:outline-none focus:border-[#C9A85C]" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1 font-serif">Address *</label>
              <input v-model="form.address" type="text" required class="w-full bg-[#241F1A] border border-[#3A332A] text-[#F0EBE2] rounded px-3 py-2 focus:outline-none focus:border-[#C9A85C]" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1 font-serif">Phone *</label>
              <input v-model="form.phone" type="text" required class="w-full bg-[#241F1A] border border-[#3A332A] text-[#F0EBE2] rounded px-3 py-2 focus:outline-none focus:border-[#C9A85C]" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1 font-serif">{{ t('branch.capacity') }} *</label>
              <input v-model.number="form.capacity" type="number" required class="w-full bg-[#241F1A] border border-[#3A332A] text-[#F0EBE2] rounded px-3 py-2 focus:outline-none focus:border-[#C9A85C]" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1 font-serif">{{ t('branch.manager') }} (ID)</label>
              <input v-model="form.manager_id" type="text" class="w-full bg-[#241F1A] border border-[#3A332A] text-[#F0EBE2] rounded px-3 py-2 focus:outline-none focus:border-[#C9A85C]" />
            </div>
          </form>
        </div>
        <div class="px-6 py-4 border-t border-[#3A332A] bg-[#0C0B0A] flex justify-end gap-3">
          <button @click="closePanel" type="button" class="px-4 py-2 text-sm font-medium text-[#9B8E80] hover:text-[#F0EBE2] border border-[#3A332A] rounded">
            {{ t('common.cancel') }}
          </button>
          <button @click="saveBranch" :disabled="saving" class="px-4 py-2 text-sm font-medium bg-[#C9A85C] text-[#0C0B0A] rounded hover:bg-[#8A6E30] disabled:opacity-50">
            {{ saving ? t('common.loading') : t('common.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
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
import { useLanguageStore } from '@/stores/useLanguageStore'

const langStore = useLanguageStore()
const { t } = langStore

const { listBranches, createBranch, updateBranch, toggleBranchStatus } = useBranch()
const branches = ref<any[]>([])
const loading = ref(true)
const saving = ref(false)

const showPanel = ref(false)
const editingBranch = ref<any | null>(null)

const form = ref({
  name: '',
  address: '',
  phone: '',
  capacity: 0,
  manager_id: ''
})

async function fetchBranches() {
  loading.value = true
  try {
    branches.value = await listBranches()
  } catch (err) {
    console.error('Error fetching branches:', err)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await fetchBranches()
})

function openCreatePanel() {
  editingBranch.value = null
  form.value = {
    name: '',
    address: '',
    phone: '',
    capacity: 0,
    manager_id: ''
  }
  showPanel.value = true
}

function openEditPanel(branch: any) {
  editingBranch.value = branch
  form.value = {
    name: branch.name || '',
    address: branch.address || '',
    phone: branch.phone || '',
    capacity: branch.capacity || 0,
    manager_id: branch.manager_id || ''
  }
  showPanel.value = true
}

function closePanel() {
  showPanel.value = false
}

async function saveBranch() {
  if (!form.value.name || !form.value.address || !form.value.phone || form.value.capacity == null) {
    return
  }
  saving.value = true
  try {
    const payload: any = {
      name: form.value.name,
      address: form.value.address,
      phone: form.value.phone,
      capacity: form.value.capacity,
    }
    if (form.value.manager_id) {
      payload.manager_id = form.value.manager_id
    }

    if (editingBranch.value) {
      await updateBranch(editingBranch.value.id, payload)
    } else {
      await createBranch(payload)
    }
    await fetchBranches()
    closePanel()
  } catch (error) {
    console.error('Error saving branch:', error)
  } finally {
    saving.value = false
  }
}

async function handleToggleStatus(branch: any) {
  try {
    const newStatus = !branch.is_active
    await toggleBranchStatus(branch.id, newStatus)
    branch.is_active = newStatus
  } catch (error) {
    console.error('Error toggling status:', error)
  }
}
</script>
