<template>
  <div class="hq-dashboard p-6">
    <h1 class="text-2xl font-bold mb-6 text-gray-800">{{ t('bod.dashboard') }}</h1>
    
    <div v-if="loading" class="text-center py-10">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
    </div>
    
    <div v-else-if="error" class="bg-red-50 text-red-600 p-4 rounded-lg shadow">
      {{ error }}
    </div>

    <div v-else-if="dashboard" class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white p-6 rounded-xl shadow border border-gray-100 flex flex-col items-center justify-center">
        <span class="text-gray-500 text-sm font-medium uppercase tracking-wider mb-2">{{ t('accounting.revenue') }}</span>
        <span class="text-3xl font-bold text-green-600">{{ formatCurrency(dashboard.revenue) }}</span>
      </div>
      
      <div class="bg-white p-6 rounded-xl shadow border border-gray-100 flex flex-col items-center justify-center">
        <span class="text-gray-500 text-sm font-medium uppercase tracking-wider mb-2">{{ t('accounting.expense') }}</span>
        <span class="text-3xl font-bold text-red-500">{{ formatCurrency(dashboard.expense) }}</span>
      </div>
      
      <div class="bg-white p-6 rounded-xl shadow border border-gray-100 flex flex-col items-center justify-center">
        <span class="text-gray-500 text-sm font-medium uppercase tracking-wider mb-2">{{ t('bod.kpi') }} (Campaigns)</span>
        <span class="text-3xl font-bold text-blue-600">{{ dashboard.active_campaigns }} Active</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useBOD } from '@/composables/useBOD'
import { useLanguageStore } from '@/stores/useLanguageStore'

const { t } = useLanguageStore()
const { dashboard, loading, error, fetchDashboard } = useBOD()

function formatCurrency(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

onMounted(() => {
  fetchDashboard()
})
</script>
