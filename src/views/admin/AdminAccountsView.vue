<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 tracking-tight">{{ t('auto_qu_n_l__t_i_kho_n') }}</h1>
        <p class="text-sm text-gray-500 mt-1">{{ t('auto_thi_t_l_p_t_i_kho_n_v__ph_n_qu') }}</p>
      </div>
      <button class="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl font-bold transition-colors flex items-center gap-2 text-sm shadow-md">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
        Tạo Tài Khoản
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm flex items-center gap-4">
      <div class="flex-1 relative">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
        <input type="text" placeholder="Tìm tên, mã nhân viên..." class="w-full bg-gray-50 border border-gray-200 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:border-gray-400 font-medium" />
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
            <th class="px-5 py-3">{{ t('auto_vai_tr___role_') }}</th>
            <th class="px-5 py-3">{{ t('auto_tr_ng_th_i') }}</th>
            <th class="px-5 py-3">{{ t('auto_h_nh___ng') }}</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">{{ user.id.slice(0, 8) }}</td>
            <td class="px-5 py-3 font-medium text-gray-900">{{ user.full_name }}</td>
            <td class="px-5 py-3">
              <span v-if="user.role === 'admin'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-gray-900 text-white">Admin</span>
              <span v-else-if="user.role === 'manager'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-blue-100 text-blue-700 border border-blue-200">Manager</span>
              <span v-else-if="user.role === 'reception'" class="px-2.5 py-1 rounded-md text-xs font-bold bg-purple-100 text-purple-700 border border-purple-200">{{ t('auto_thu_ng_n') }}</span>
              <span v-else class="px-2.5 py-1 rounded-md text-xs font-bold bg-orange-100 text-orange-700 border border-orange-200">{{ t('auto_ph_c_v_') }}</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs" v-if="user.is_active">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> Đang hoạt động
              </span>
              <span class="flex items-center gap-1.5 text-red-600 font-medium text-xs" v-else>
                <span class="w-2 h-2 rounded-full bg-red-500"></span> Ngừng hoạt động
              </span>
            </td>
            <td class="px-5 py-3">
              <button class="text-blue-600 hover:text-blue-800 font-medium">{{ t('auto_s_a') }}</button>
            </td>
          </tr>
          <tr v-if="loading">
            <td colspan="5" class="px-5 py-4 text-center text-gray-500">{{ t('auto__ang_t_i___') }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type { AppUser } from '@/types/database'

const { branchId, isAdmin } = useAuth()
const users = ref<AppUser[]>([])
const loading = ref(true)

onMounted(async () => {
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
})
</script>
