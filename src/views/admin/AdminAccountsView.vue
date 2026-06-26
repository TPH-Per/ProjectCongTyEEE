<template>
  <div class="space-y-6 max-w-7xl mx-auto">

    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 tracking-tight">{{ t('auto_qu_n_l__t_i_kho_n') }}</h1>
        <p class="text-sm text-gray-500 mt-1">{{ t('auto_thi_t_l_p_t_i_kho_n_v__ph_n_qu') }}</p>
      </div>
      <button @click="openCreateModal" class="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl font-bold transition-colors flex items-center gap-2 text-sm shadow-md">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
        {{ t('auto_t_o_t_i_kho_n') }}
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm flex items-center gap-4">
      <div class="flex-1 relative">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
        <input type="text" :placeholder="$t('auto_placeholder_fix')" class="w-full bg-gray-50 border border-gray-200 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:border-gray-400 font-medium" />
      </div>
      <select class="bg-gray-50 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-gray-400 font-medium">
        <option value="all">{{ t('auto_t_t_c__vai_tr_') }}</option>
        <option value="admin">System Admin</option>
        <option value="manager">Manager</option>
        <option value="reception">{{ t('auto_thu_ng_n') }}</option>
        <option value="staff">{{ t('auto_ph_c_v_') }}</option>
      </select>
    </div>

    <!-- Accounts Table -->
    <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
      <table class="w-full text-left text-sm">
        <thead class="bg-gray-50 text-gray-500 font-semibold border-b">
          <tr>
            <th class="px-5 py-3">ID</th>
            <th class="px-5 py-3">{{ t('auto_h__t_n') }}</th>
            <th class="px-5 py-3">Email</th>
            <th class="px-5 py-3">{{ t('auto_vai_tr___role_') }}</th>
            <th class="px-5 py-3">{{ t('auto_tr_ng_th_i') }}</th>
            <th class="px-5 py-3">{{ t('auto_h_nh___ng') }}</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">{{ user.id.slice(0, 8) }}</td>
            <td class="px-5 py-3 font-medium text-gray-900">{{ user.full_name }}</td>
            <td class="px-5 py-3 text-gray-500">{{ user.email }}</td>
            <td class="px-5 py-3">
              <span v-if="user.role === 'admin'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-gray-900 text-white">Admin</span>
              <span v-else-if="user.role === 'manager'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-blue-100 text-blue-700 border border-blue-200">Manager</span>
              <span v-else-if="user.role === 'reception'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-purple-100 text-purple-700 border border-purple-200">{{ t('auto_thu_ng_n') }}</span>
              <span v-else class="px-2.5 py-1 rounded-md text-xs font-bold bg-orange-100 text-orange-700 border border-orange-200">{{ t('auto_ph_c_v_') }}</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs" v-if="user.is_active">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> {{ t('auto_ang_ho_t_ng') }}
              </span>
              <span class="flex items-center gap-1.5 text-red-600 font-medium text-xs" v-else>
                <span class="w-2 h-2 rounded-full bg-red-500"></span> {{ t('auto_ng_ng_ho_t_ng') }}
              </span>
            </td>
            <td class="px-5 py-3">
              <div class="flex gap-2">
                <button @click="openEditModal(user)" class="text-blue-600 hover:text-blue-800 font-medium">{{ t('auto_s_a') }}</button>
                <button @click="openPasswordModal(user)" class="text-orange-600 hover:text-orange-800 font-medium ml-2">{{ t('auto_i_mk') }}</button>
              </div>
            </td>
          </tr>
          <tr v-if="loading">
            <td colspan="6" class="px-5 py-4 text-center text-gray-500">{{ t('auto__ang_t_i___') }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- User Modal (Create / Edit) -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl">
        <h3 class="text-lg font-bold mb-4">{{ modalMode === 'create' ? 'Tạo Tài Khoản Mới' : 'Sửa Tài Khoản' }}</h3>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_h_t_n') }}</label>
            <input v-model="form.full_name" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" />
          </div>
          <div v-if="modalMode === 'create'">
            <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input v-model="form.email" type="email" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" />
          </div>
          <div v-if="modalMode === 'create'">
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_m_t_kh_u') }}</label>
            <input v-model="form.password" type="password" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_vai_tr') }}</label>
            <select v-model="form.role" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900">
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="reception">Reception</option>
              <option value="staff">Staff</option>
              <option value="kitchen">Kitchen</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_chi_nhanh_branch') }}</label>
            <select v-model="form.branch_id" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 bg-white">
              <option value="" disabled>{{ t('auto_chon_chi_nhanh', 'Chọn chi nhánh') }}</option>
              <option v-for="b in branches" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>
          </div>
          <div v-if="modalMode === 'edit'" class="flex items-center gap-2 mt-4">
            <input type="checkbox" id="isActive" v-model="form.is_active" class="rounded text-gray-900 focus:ring-gray-900 w-4 h-4" />
            <label for="isActive" class="text-sm font-medium text-gray-700">{{ t('auto_t_i_kho_n_ang_ho_t_ng') }}</label>
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <button @click="isModalOpen = false" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
            {{ t('auto_h_y') }}
          </button>
          <button @click="saveUser" :disabled="saving" class="px-4 py-2 text-sm font-bold text-white bg-gray-900 hover:bg-black rounded-lg transition-colors disabled:opacity-50">
            {{ saving ? 'Đang lưu...' : 'Lưu Tài Khoản' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Password Modal -->
    <div v-if="isPwdModalOpen" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-2xl w-full max-w-sm p-6 shadow-xl">
        <h3 class="text-lg font-bold mb-4">{{ t('auto_i_m_t_kh_u') }}</h3>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_m_t_kh_u_m_i') }}</label>
            <input v-model="newPassword" type="password" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" />
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <button @click="isPwdModalOpen = false" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
            {{ t('auto_h_y') }}
          </button>
          <button @click="resetPassword" :disabled="saving" class="px-4 py-2 text-sm font-bold text-white bg-orange-600 hover:bg-orange-700 rounded-lg transition-colors disabled:opacity-50">
            {{ saving ? 'Đang lưu...' : 'Cập Nhật' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2';
import { useI18n } from 'vue-i18n'
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { DEFAULT_BRANCH_ID } from '@/lib/branch-constants'
import type { AppUser } from '@/types/database'

const { t } = useI18n()
const { branchId, isAdmin } = useAuth()
const users = ref<AppUser[]>([])
const loading = ref(true)

const isModalOpen = ref(false)
const isPwdModalOpen = ref(false)
const modalMode = ref<'create' | 'edit'>('create')
const saving = ref(false)

const form = ref({
  id: '',
  email: '',
  password: '',
  full_name: '',
  role: 'staff',
  branch_id: branchId.value || DEFAULT_BRANCH_ID,
  is_active: true
})
const branches = ref<any[]>([])


const newPassword = ref('')
const selectedUserId = ref('')

async function fetchUsers() {
  loading.value = true
  let query = supabase.from('users').select('*')
  
  if (!isAdmin.value && branchId.value) {
    query = query.eq('branch_id', branchId.value)
  }
  
  const { data } = await query.order('created_at', { ascending: false })
  if (data) {
    users.value = data as AppUser[]
  }
  loading.value = false
}


const fetchBranches = async () => {
  try {
    const { data, error: err } = await supabase.from('branches').select('id, name').order('name')
    if (err) throw err
    branches.value = data || []
  } catch (e: any) {
    console.error('Error fetching branches:', e.message)
  }
}

onMounted(() => {
  fetchUsers()
  fetchBranches()
})


function openCreateModal() {
  modalMode.value = 'create'
  form.value = {
    id: '',
    email: '',
    password: '',
    full_name: '',
    role: 'staff',
    branch_id: branchId.value || DEFAULT_BRANCH_ID,
    is_active: true
  }
  isModalOpen.value = true
}

function openEditModal(user: AppUser) {
  modalMode.value = 'edit'
  form.value = {
    id: user.id,
    email: user.email,
    password: '',
    full_name: user.full_name,
    role: user.role,
    branch_id: user.branch_id || '',
    is_active: user.is_active
  }
  isModalOpen.value = true
}

function openPasswordModal(user: AppUser) {
  selectedUserId.value = user.id
  newPassword.value = ''
  isPwdModalOpen.value = true
}

async function saveUser() {
  saving.value = true
  try {
    if (modalMode.value === 'create') {
      const { data, error } = await supabase.functions.invoke('admin-user-manager', {
        body: {
          action: 'create_user',
          payload: {
            email: form.value.email,
            password: form.value.password,
            full_name: form.value.full_name,
            role: form.value.role,
            branch_id: form.value.branch_id || null
          }
        }
      })
      if (error) throw error
    } else {
      const { data, error } = await supabase.functions.invoke('admin-user-manager', {
        body: {
          action: 'update_user',
          payload: {
            userId: form.value.id,
            role: form.value.role,
            branch_id: form.value.branch_id || null,
              is_active: form.value.is_active
          }
        }
      })
      if (error) throw error
      
      // Update local state without fetching
      const index = users.value.findIndex(u => u.id === form.value.id)
      if (index !== -1) {
        users.value[index] = {
          ...users.value[index],
          full_name: form.value.full_name,
          role: form.value.role as any,
          branch_id: form.value.branch_id,
          is_active: form.value.is_active
        }
      }
    }
    isModalOpen.value = false
    if (modalMode.value === 'create') fetchUsers()
  } catch (err: any) {
    Swal.fire('Lỗi', 'Lỗi: ' + err.message, 'error')
  } finally {
    saving.value = false
  }
}

async function resetPassword() {
  if (!newPassword.value) return
  saving.value = true
  try {
    const { error } = await supabase.functions.invoke('admin-user-manager', {
      body: {
        action: 'reset_password',
        payload: {
          userId: selectedUserId.value,
          password: newPassword.value
        }
      }
    })
    if (error) throw error
    Swal.fire('Thành công', 'Đổi mật khẩu thành công!', 'success')
    isPwdModalOpen.value = false
  } catch (err: any) {
    Swal.fire('Lỗi', 'Lỗi: ' + err.message, 'error')
  } finally {
    saving.value = false
  }
}
</script>

