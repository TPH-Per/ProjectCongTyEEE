<template>
  <div class="space-y-6">

    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">{{ i18n.t('branch.title') }}</h2>
        <p class="text-sm text-gray-500">{{ i18n.t('branch.title') }}</p>
      </div>
      <button 
        class="kawaii-btn-primary flex items-center shadow-lg shadow-rose-200"
        @click="openCreatePanel"
      >
        <PlusIcon class="w-5 h-5 mr-2" />
        {{ i18n.t('branch.add') }}
      </button>
    </div>

    <!-- Filters & Search -->
    <div class="kawaii-card bg-white p-4 flex flex-col md:flex-row gap-4 justify-between items-center">
      <div class="relative w-full md:w-96">
        <SearchIcon class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input 
          type="text" 
          :placeholder="i18n.t('common.search')" 
          class="kawaii-input pl-10 w-full"
        />
      </div>

      <div class="flex gap-2 w-full md:w-auto">
        <select class="kawaii-input w-auto cursor-pointer">
          <option>{{ i18n.t('common.all') }}</option>
          <option>{{ i18n.t('common.active') }}</option>
          <option>{{ i18n.t('common.inactive') }}</option>
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
            >
              <span class="px-2 py-1 text-xs font-medium rounded-md" :class="branch.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'">
                {{ branch.is_active ? i18n.t('common.active') : i18n.t('branch.deactivate') }}
              </span>
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
            {{ branch.address || i18n.t('common.no_data') }}
          </p>
          
          <div class="mt-auto pt-4 border-t border-gray-100 grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ i18n.t('branch.manager') }}</p>
              <p class="text-sm font-medium text-gray-700 flex items-center">
                <UserIcon class="w-4 h-4 mr-1" /> {{ branch.manager?.full_name || i18n.t('common.no_data') }}
              </p>
            </div>
            <div>
              <p class="text-xs text-gray-400 mb-1">{{ i18n.t('branch.capacity') }}</p>
              <p class="text-sm font-medium text-gray-700">{{ branch.capacity }}</p>
            </div>
          </div>
        </div>
        <div class="px-5 py-3 bg-gray-50 border-t border-gray-100 flex justify-between">
          <button class="text-sm font-medium text-[#FF7B89] hover:underline" @click="openEditPanel(branch)">{{ i18n.t('branch.edit') }}</button>
        </div>
      </div>
      <div v-if="loading" class="col-span-full text-center py-8 text-gray-500">
        {{ i18n.t('common.loading') }}
      </div>
    </div>

    <!-- Slide Panel -->
    <div v-if="showPanel" class="fixed inset-0 z-50 overflow-hidden">
      <div class="absolute inset-0 bg-black/30 backdrop-blur-sm transition-opacity" @click="closePanel"></div>
      <div class="absolute inset-y-0 right-0 max-w-md w-full bg-white shadow-xl flex flex-col transform transition-transform duration-250 ease-out">
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-white">
          <h2 class="text-xl font-bold text-gray-800">
            {{ editingBranch ? i18n.t('branch.edit') : i18n.t('branch.add') }}
          </h2>
          <button @click="closePanel" class="text-gray-400 hover:text-gray-600 transition-colors">
            X
          </button>
        </div>
        <div class="flex-1 overflow-y-auto p-6 bg-gray-50/50">
          <form @submit.prevent="saveBranch" class="space-y-5">
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">{{ i18n.t('branch.name') }} *</label>
              <input v-model="form.name" type="text" required class="kawaii-input w-full" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">{{ i18n.t('branch.address') }} *</label>
              <input v-model="form.address" type="text" required class="kawaii-input w-full" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">{{ i18n.t('branch.phone') }} *</label>
              <input v-model="form.phone" type="text" required class="kawaii-input w-full" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">{{ i18n.t('branch.capacity') }} *</label>
              <input v-model.number="form.capacity" type="number" required class="kawaii-input w-full" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">{{ i18n.t('branch.manager') }} (ID)</label>
              <input v-model="form.manager_id" type="text" :placeholder="i18n.t('branch.manager_id_placeholder')" class="kawaii-input w-full" />
            </div>
          </form>
        </div>
        <div class="px-6 py-4 border-t border-gray-100 bg-white flex justify-end gap-3">
          <button @click="closePanel" type="button" class="kawaii-btn-ghost">
            {{ i18n.t('common.cancel') }}
          </button>
          <button @click="saveBranch" :disabled="saving" class="kawaii-btn-primary disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-rose-200">
            {{ saving ? i18n.t('common.loading') : i18n.t('common.save') }}
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
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()

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
