<template>
  <div class="p-4">

    <div class="flex items-center justify-between mb-6">
      <h2 class="text-xl font-bold text-gray-800">{{ t('auto_s_____b_n') }}</h2>
      <div class="bg-red-50 text-red-600 px-3 py-1 rounded-full text-xs font-bold">
        {{ activeCount }} {{ $t('auto_dang_phuc_vu') }}
      </div>
    </div>

    <div class="grid grid-cols-2 gap-4">
      <template v-for="table in tables" :key="table.id">
        <!-- Active Table (Occupied) -->
        <RouterLink v-if="table.status === 'occupied'" :to="`/staff/table/${table.id}/crm`" class="bg-white border-2 border-red-500 rounded-2xl p-4 shadow-sm relative overflow-hidden flex flex-col h-32">
          <div class="absolute top-0 left-0 w-full h-1 bg-red-500"></div>
          <div class="flex justify-between items-start mb-2">
            <span class="font-bold text-lg text-gray-900">{{ table.code }}</span>
            <span class="bg-red-100 text-red-700 text-[10px] font-bold px-2 py-0.5 rounded">{{ t('auto_ang_d_ng_b_a') }}</span>
          </div>
          <div class="text-xs text-gray-500 font-medium mt-auto">{{ $t('auto_suc_chua') }} {{ table.capacity }} {{ $t('auto_ghe', 'ghế') }}</div>
        </RouterLink>

        <!-- Needs Cleaning Table -->
        <RouterLink v-else-if="table.status === 'needs_cleaning'" :to="`/staff/table/${table.id}/crm`" class="bg-yellow-50 border-2 border-yellow-400 rounded-2xl p-4 shadow-sm relative flex flex-col h-32 animate-pulse">
          <div class="flex justify-between items-start mb-2">
            <span class="font-bold text-lg text-yellow-900">{{ table.code }}</span>
            <span class="bg-yellow-200 text-yellow-800 text-[10px] font-bold px-2 py-0.5 rounded">{{ t('auto_d_n_b_n') }}</span>
          </div>
          <div class="text-xs text-gray-500 font-medium mt-auto">{{ $t('auto_suc_chua') }} {{ table.capacity }} {{ $t('auto_ghe', 'ghế') }}</div>
        </RouterLink>

        <!-- Reserved Table -->
        <RouterLink v-else-if="table.status === 'reserved'" :to="`/staff/table/${table.id}/crm`" class="bg-blue-50 border-2 border-blue-400 rounded-2xl p-4 shadow-sm relative flex flex-col h-32">
          <div class="flex justify-between items-start mb-2">
            <span class="font-bold text-lg text-blue-900">{{ table.code }}</span>
            <span class="bg-blue-200 text-blue-800 text-[10px] font-bold px-2 py-0.5 rounded">{{ t('auto_t') }}</span>
          </div>
          <div class="text-xs text-gray-500 font-medium mt-auto">{{ $t('auto_suc_chua') }} {{ table.capacity }} {{ $t('auto_ghe', 'ghế') }}</div>
        </RouterLink>

        <!-- Maintenance Table -->
        <RouterLink v-else-if="table.status === 'maintenance'" :to="`/staff/table/${table.id}/crm`" class="bg-gray-50 border-2 border-gray-400 rounded-2xl p-4 shadow-sm relative flex flex-col h-32">
          <div class="flex justify-between items-start mb-2">
            <span class="font-bold text-lg text-gray-600">{{ table.code }}</span>
            <span class="bg-gray-200 text-gray-700 text-[10px] font-bold px-2 py-0.5 rounded">{{ t('auto_b_o_tr') }}</span>
          </div>
          <div class="text-xs text-gray-500 font-medium mt-auto">{{ $t('auto_suc_chua') }} {{ table.capacity }} {{ $t('auto_ghe', 'ghế') }}</div>
        </RouterLink>

        <!-- Idle Table (available) -->
        <RouterLink v-else :to="`/staff/table/${table.id}/open`" class="bg-white border border-gray-200 rounded-2xl p-4 shadow-sm relative flex flex-col h-32 opacity-80 hover:opacity-100 hover:border-gray-300 transition-all">
          <div class="flex justify-between items-start mb-2">
            <span class="font-bold text-lg text-gray-900">{{ table.code }}</span>
            <span class="bg-gray-100 text-gray-500 text-[10px] font-bold px-2 py-0.5 rounded">{{ t('auto_tr_ng') }}</span>
          </div>
          <div class="text-xs text-gray-500 font-medium mt-auto">{{ $t('auto_suc_chua') }} {{ table.capacity }} {{ $t('auto_ghe', 'ghế') }}</div>
          <div class="mt-2 flex justify-center">
            <div class="text-xs font-bold text-red-600 flex items-center gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
              {{ t('auto_m_b_n') }}
            </div>
          </div>
        </RouterLink>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import { ref, onMounted, computed, watch } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useTable } from '@/composables/useTable'
import type { TableT } from '@/types/database'
import { useRealtime } from '@/composables/useRealtime'

const { t } = useI18n()
const { watchTable } = useRealtime()
const { branchId } = useAuth()
const { listTables } = useTable()

const tables = ref<TableT[]>([])

const activeCount = computed(() => tables.value.filter(t => t.status === 'occupied').length)

const fetchTables = async () => {
  if (!branchId.value) return
  tables.value = await listTables()
}

onMounted(() => {
  fetchTables()
  watchTable('tables', '*', () => {
    fetchTables()
  })
})

watch(branchId, () => {
  fetchTables()
})
</script>
