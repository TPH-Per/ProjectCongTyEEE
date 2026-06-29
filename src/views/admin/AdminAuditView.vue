<template>
  <div class="p-6 max-w-7xl mx-auto h-full flex flex-col">

    <div class="mb-6 flex flex-col md:flex-row justify-between md:items-end gap-4">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-2 flex items-center gap-2">
          <span class="text-[#FF7B89]">🕵️</span> {{ t('admin_audit.title') }}
        </h1>
        <p class="text-gray-500">{{ t('admin_audit.subtitle') }}</p>
      </div>
      
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost flex items-center gap-2" @click="fetchLogs">
          <span>🔄</span> {{ t('admin_audit.action.refresh') }}
        </button>
        <button class="kawaii-btn-ghost flex items-center gap-2">
          <span>⬇️</span> {{ t('admin_audit.action.export_report') }}
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="kawaii-card p-4 mb-6 grid grid-cols-1 md:grid-cols-5 gap-4 shadow-sm border border-gray-50">
      <div class="md:col-span-2 relative">
        <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        <input type="text" v-model="searchQuery" :placeholder="$t('admin_audit.search_placeholder')" class="kawaii-input w-full pl-11" />
      </div>
      <div>
        <select v-model="filterTime" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('admin_audit.filter.all_time') }}</option>
          <option value="today">{{ t('admin_audit.filter.today') }}</option>
          <option value="week">{{ t('admin_audit.filter.this_week') }}</option>
          <option value="month">{{ t('admin_audit.filter.this_month') }}</option>
        </select>
      </div>
      <div>
        <select v-model="filterAction" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('admin_audit.filter.all_actions') }}</option>
          <option value="CREATE">{{ t('admin_audit.action_type.create') }}</option>
          <option value="UPDATE">{{ t('admin_audit.action_type.update') }}</option>
          <option value="DELETE">{{ t('admin_audit.action_type.delete') }}</option>
          <option value="LOGIN">{{ t('admin_audit.action_type.login') }}</option>
        </select>
      </div>
      <div>
        <select v-model="filterEntity" class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">{{ t('admin_audit.filter.all_entities') }}</option>
          <option value="orders">{{ t('admin_audit.entity.orders') }}</option>
          <option value="users">{{ t('admin_audit.entity.users') }}</option>
          <option value="menu_items">{{ t('admin_audit.entity.menu_items') }}</option>
          <option value="tables">{{ t('admin_audit.entity.tables') }}</option>
        </select>
      </div>
    </div>

    <!-- Table -->
    <div class="kawaii-card flex-1 flex flex-col overflow-hidden shadow-sm border border-gray-50">
      <div class="overflow-x-auto flex-1">
        <table class="w-full text-left border-collapse min-w-[900px]">
          <thead class="bg-pink-50/30 sticky top-0 z-10 backdrop-blur-md">
            <tr class="text-gray-600 border-b border-pink-100">
              <th class="py-4 px-6 font-semibold text-sm">{{ t('admin_audit.table.time') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('admin_audit.table.branch') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('admin_audit.entity.users') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('admin_audit.table.actions') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">{{ t('admin_audit.table.entity_type') }}</th>
              <th class="py-4 px-6 font-semibold text-sm">ID</th>
              <th class="py-4 px-6 font-semibold text-sm w-1/3">{{ t('admin_audit.table.payload') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading" class="border-b border-gray-50">
              <td colspan="7" class="py-8 text-center text-gray-500">{{ t('admin_audit.status.loading') }}</td>
            </tr>
            <tr v-else-if="filteredLogs.length === 0" class="border-b border-gray-50">
              <td colspan="7" class="py-8 text-center text-gray-500">{{ t('admin_audit.status.no_records') }}</td>
            </tr>
            <tr v-for="log in filteredLogs" :key="log.id" class="border-b border-gray-50 hover:bg-pink-50/20 transition-colors">
              <td class="py-3 px-6 text-sm text-gray-500 whitespace-nowrap">{{ new Date(log.created_at).toLocaleString('vi-VN') }}</td>
              <td class="py-3 px-6 text-sm text-gray-800 font-medium">
                <span class="px-2.5 py-1 bg-gray-100/80 rounded-lg text-xs border border-gray-200/50">{{ log.branches?.name || t('admin_audit.system') }}</span>
              </td>
              <td class="py-3 px-6 text-sm">
                <div class="flex items-center gap-2.5">
                  <div class="w-7 h-7 rounded-xl bg-gradient-to-br from-pink-100 to-pink-200 text-[#FF7B89] flex items-center justify-center font-bold text-xs shadow-sm">
                    {{ (log.users?.full_name || 'H').charAt(0).toUpperCase() }}
                  </div>
                  <span class="font-medium text-gray-700">{{ log.users?.full_name || t('admin_audit.system') }}</span>
                </div>
              </td>
              <td class="py-3 px-6">
                
                <span :class="{
                  'px-3 py-1 rounded-full text-[11px] font-bold tracking-wide uppercase': true,
                  'bg-green-100/80 text-green-700 border border-green-200': formatActionColor(log.action) === 'green',
                  'bg-blue-100/80 text-blue-700 border border-blue-200': formatActionColor(log.action) === 'blue',
                  'bg-red-100/80 text-red-700 border border-red-200': formatActionColor(log.action) === 'red',
                  'bg-purple-100/80 text-purple-700 border border-purple-200': formatActionColor(log.action) === 'purple'
                }">
                  {{ formatActionText(log.action) }}
                </span>

              </td>
              <td class="py-3 px-6 text-sm text-gray-700 font-medium">{{ log.entity_type || 'N/A' }}</td>
              <td class="py-3 px-6 text-sm text-gray-500 font-mono bg-gray-50/50 rounded">{{ log.entity_id || 'N/A' }}</td>
              <td class="py-3 px-6 max-w-xs">
                
                <div class="bg-gray-50/80 p-2.5 rounded-xl text-xs text-gray-600 max-h-32 overflow-y-auto border border-gray-200/60 shadow-inner">
                  <div v-if="log.payload && typeof log.payload === 'object'">
                    <div v-for="(val, key) in flattenPayload(log.payload)" :key="key" class="mb-1 border-b border-gray-100/50 pb-1 last:border-0 last:pb-0">
                      <span class="font-bold text-gray-700">{{ key }}:</span>
                      <span class="ml-1 text-gray-500">{{ val }}</span>
                    </div>
                  </div>
                  <pre v-else class="whitespace-pre-wrap break-words font-mono text-[10px]">{{ log.payload }}</pre>
                </div>

              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="p-4 border-t border-gray-100 flex justify-between items-center bg-white rounded-b-3xl">
        <span class="text-sm text-gray-500 font-medium">{{ t('admin_audit.pagination_info') }} (Mocked UI)</span>
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
    Swal.fire(t('admin_audit.alert.error'), t('admin_audit.alert.load_error') + error.message, 'error');
  } else {
    auditLogs.value = data || [];
  }
  loading.value = false;
};

onMounted(() => {
  fetchLogs();
});


const formatActionColor = (action: string) => {
  const act = action.toLowerCase();
  if (act.includes('create') || act.includes('insert')) return 'green';
  if (act.includes('update')) return 'blue';
  if (act.includes('delete')) return 'red';
  return 'purple';
};

const formatActionText = (action: string) => {
  // Convert 'table_assignment.created' to 'Tạo table_assignment' 
  // Normally we'd fully translate, but for audit let's make it look cleaner.
  if (!action) return 'UNKNOWN';
  if (action.includes('.')) {
    const parts = action.split('.');
    const entity = parts[0].replace(/_/g, ' ');
    const verb = parts[1];
    
    let translatedVerb = verb;
    if (verb === 'created' || verb === 'insert') translatedVerb = t('admin_audit.action_type.create');
    else if (verb === 'updated') translatedVerb = t('admin_audit.action_type.update');
    else if (verb === 'deleted') translatedVerb = t('admin_audit.action_type.delete');
    
    return `${translatedVerb} ${entity}`;
  }
  return action;
};

const flattenPayload = (payload: any) => {
  if (!payload) return {};
  // if payload has 'after', use that instead
  const data = payload.after ? payload.after : payload;
  const result: Record<string, string> = {};
  for (const key in data) {
    if (typeof data[key] === 'object' && data[key] !== null) {
      result[key] = JSON.stringify(data[key]);
    } else {
      result[key] = String(data[key] ?? 'null');
    }
  }
  return result;
};


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

