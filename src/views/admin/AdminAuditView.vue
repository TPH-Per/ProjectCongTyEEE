<template>
  <div class="p-6 max-w-7xl mx-auto h-full flex flex-col">

    <div class="mb-6 flex flex-col md:flex-row justify-between md:items-end gap-4">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-2 flex items-center gap-2">
          <span class="text-[#FF7B89]">🕵️</span> {{ t('auto_nh_t_k_ho_t_ng_audit_log', 'Nhật Ký Hoạt Động (Audit Log)') }}
        </h1>
        <p class="text-gray-500">{{ t('auto_gi_m_s_t_m_i_thao_t_c_v__thay_') }}</p>
      </div>
      
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost flex items-center gap-2" @click="fetchLogs">
          <span>🔄</span> {{ t('auto_l_m_m_i', 'Làm mới') }}
        </button>
        <button class="kawaii-btn-ghost flex items-center gap-2">
          <span>⬇️</span> {{ t('auto_xu_t_b_o_c_o', 'Xuất báo cáo') }}
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="kawaii-card p-4 mb-6 grid grid-cols-1 md:grid-cols-5 gap-4 shadow-sm border border-gray-50">
      <div class="md:col-span-2 relative">
        <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        <input type="text" v-model="searchQuery" :placeholder="t('auto_t_m_ki_m_theo_id_payload', 'Tìm kiếm theo ID, payload...')" class="kawaii-input w-full pl-11" />
      </div>
      <div>
        <select v-model="filterTime" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('auto_____t_t_c__th_i_gian') }}</option>
          <option value="today">{{ t('auto_h_m_nay') }}</option>
          <option value="week">{{ t('auto_tu_n_n_y') }}</option>
          <option value="month">{{ t('auto_th_ng_n_y') }}</option>
        </select>
      </div>
      <div>
        <select v-model="filterAction" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('auto___t_t_c__h_nh___ng') }}</option>
          <option value="CREATE">{{ t('auto_t_o_m_i__create_') }}</option>
          <option value="UPDATE">{{ t('auto_c_p_nh_t__update_') }}</option>
          <option value="DELETE">{{ t('auto_x_a__delete_') }}</option>
          <option value="LOGIN">{{ t('auto___ng_nh_p__login_') }}</option>
        </select>
      </div>
      <div>
        <select v-model="filterEntity" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('auto____t_t_c____i_t__ng') }}</option>
          <option value="orders">{{ t('auto___n_h_ng') }}</option>
          <option value="users">{{ t('auto_ng__i_d_ng') }}</option>
          <option value="menu_items">{{ t('auto_th_c___n') }}</option>
          <option value="tables">{{ t('auto_b_n', 'Bàn') }}</option>
        </select>
      </div>
    </div>

    <!-- Table -->
    <div class="kawaii-card flex-1 flex flex-col overflow-hidden shadow-sm border border-gray-50">
      <div class="overflow-x-auto flex-1">
        <table class="w-full text-left border-collapse min-w-[900px]">
          <thead class="bg-pink-50/30 sticky top-0 z-10 backdrop-blur-md">
            <tr class="text-gray-600 border-b border-pink-100">
              <th class="py-4 px-6 font-semibold text-sm">{{ t('auto_th_i_gian') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('auto_nh_nh') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('auto_ng__i_d_ng') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('auto_h_nh___ng') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('auto_lo_i___i_t__ng') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">ID</th>
              <th class="py-4 px-6 font-semibold text-sm w-1/3">{{ t('auto_payload__chi_ti_t_') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading" class="border-b border-gray-50">
              <td colspan="7" class="py-8 text-center text-gray-500">{{ t('auto_ang_t_i_d_li_u', 'Đang tải dữ liệu...') }}</td>
            </tr>
            <tr v-else-if="filteredLogs.length === 0" class="border-b border-gray-50">
              <td colspan="7" class="py-8 text-center text-gray-500">{{ t('auto_kh_ng_t_m_th_y_b_n_ghi_n_o', 'Không tìm thấy bản ghi nào.') }}</td>
            </tr>
            <tr v-for="log in filteredLogs" :key="log.id" class="border-b border-gray-50 hover:bg-pink-50/20 transition-colors">
              <td class="py-3 px-6 text-sm text-gray-500 whitespace-nowrap">{{ new Date(log.created_at).toLocaleString('vi-VN') }}</td>
              <td class="py-3 px-6 text-sm text-gray-800 font-medium">
                <span class="px-2.5 py-1 bg-gray-100/80 rounded-lg text-xs border border-gray-200/50">{{ log.branches?.name || 'Hệ thống' }}</span>
              </td>
              <td class="py-3 px-6 text-sm">
                <div class="flex items-center gap-2.5">
                  <div class="w-7 h-7 rounded-xl bg-gradient-to-br from-pink-100 to-pink-200 text-[#FF7B89] flex items-center justify-center font-bold text-xs shadow-sm">
                    {{ (log.users?.full_name || 'H').charAt(0).toUpperCase() }}
                  </div>
                  <span class="font-medium text-gray-700">{{ log.users?.full_name || 'Hệ thống' }}</span>
                </div>
              </td>
              <td class="py-3 px-6">
                <span :class="{
                  'px-3 py-1 rounded-full text-[11px] font-bold tracking-wide uppercase': true,
                  'bg-green-100/80 text-green-700 border border-green-200': log.action === 'CREATE' || log.action === 'INSERT',
                  'bg-blue-100/80 text-blue-700 border border-blue-200': log.action === 'UPDATE',
                  'bg-red-100/80 text-red-700 border border-red-200': log.action === 'DELETE',
                  'bg-purple-100/80 text-purple-700 border border-purple-200': log.action === 'LOGIN' || log.action === 'SELECT'
                }">
                  {{ log.action }}
                </span>
              </td>
              <td class="py-3 px-6 text-sm text-gray-700 font-medium">{{ log.entity_type || 'N/A' }}</td>
              <td class="py-3 px-6 text-sm text-gray-500 font-mono bg-gray-50/50 rounded">{{ log.entity_id || 'N/A' }}</td>
              <td class="py-3 px-6">
                <div class="bg-gray-50/80 p-2.5 rounded-xl text-xs text-gray-600 max-h-20 overflow-y-auto border border-gray-200/60 shadow-inner">
                  <div v-for="(value, key) in log.payload" :key="key" class="mb-1 last:mb-0">
                    <span class="font-medium text-gray-700">{{ key }}:</span> 
                    <span class="text-gray-500">{{ typeof value === 'object' ? JSON.stringify(value) : value }}</span>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="p-4 border-t border-gray-100 flex justify-between items-center bg-white rounded-b-3xl">
        <span class="text-sm text-gray-500 font-medium">{{ t('auto_hi_n_th__1_10_tr_n_150_k_t_qu_') }} (Mocked UI)</span>
        <div class="flex gap-1.5">
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-500 hover:bg-gray-50 hover:border-gray-300 transition-all disabled:opacity-50">&lt;</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl bg-[#FF7B89] text-white font-bold shadow-sm shadow-pink-200">1</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-500 hover:bg-gray-50 hover:border-gray-300 transition-all">&gt;</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import Swal from 'sweetalert2';

const { t } = useI18n()

const auditLogs = ref<any[]>([]);
const loading = ref(true);

const searchQuery = ref('');
const filterTime = ref('');
const filterAction = ref('');
const filterEntity = ref('');

const fetchLogs = async () => {
  loading.value = true;
  const { data, error } = await supabase
    .from('audit_events')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(100);

  if (error) {
    Swal.fire('Lỗi', 'Không thể tải nhật ký hoạt động: ' + error.message, 'error');
  } else {
    auditLogs.value = data || [];
  }
  loading.value = false;
};

onMounted(() => {
  fetchLogs();
});

const filteredLogs = computed(() => {
  return auditLogs.value.filter(log => {
    let match = true;
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      match = match && (
        (log.entity_id && log.entity_id.toLowerCase().includes(q)) ||
        JSON.stringify(log.payload).toLowerCase().includes(q)
      );
    }
    if (filterAction.value) {
      match = match && log.action === filterAction.value;
    }
    if (filterEntity.value) {
      match = match && log.entity_type === filterEntity.value;
    }
    return match;
  });
});
</script>

