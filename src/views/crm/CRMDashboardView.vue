<template>
  <div class="space-y-6">
    <header>
      <h1 class="text-2xl font-bold text-gray-900">{{ $t('crm.dashboard', 'Dashboard') }}</h1>
      <p class="text-sm text-gray-500">{{ $t('crm.overview', 'Overview') }}</p>
    </header>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Total Surveys Card -->
      <div class="rounded-2xl bg-white border border-gray-100 p-5 shadow-sm">
        <div class="mb-4 flex h-10 w-10 items-center justify-center rounded-full bg-blue-50 text-blue-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <p class="text-sm font-medium text-gray-500">{{ $t('crm.stats.completed', 'Total Customers') }}</p>
        <p class="mt-1 text-3xl font-bold text-gray-900">{{ crmStore.dashboardStats?.total_customers || 0 }}</p>
        <div class="mt-2 flex items-center gap-1 text-xs text-blue-600 font-medium">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
          </svg>
          <span>{{ $t('crm.stats.customersPlus', '+{n} this month', { n: crmStore.dashboardStats?.new_customers_this_month || 0 }) }}</span>
        </div>
      </div>

      <!-- Repeaters Card -->
      <div class="rounded-2xl bg-white border border-gray-100 p-5 shadow-sm">
        <div class="mb-4 flex h-10 w-10 items-center justify-center rounded-full bg-purple-50 text-purple-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z" />
          </svg>
        </div>
        <p class="text-sm font-medium text-gray-500">{{ $t('crm.stats.repeaters', 'Repeaters') }}</p>
        <p class="mt-1 text-3xl font-bold text-gray-900">{{ crmStore.dashboardStats?.repeater_customers || 0 }}</p>
        <div class="mt-2 flex items-center gap-1 text-xs text-purple-600 font-medium">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
          </svg>
          <span>{{ $t('crm.stats.vip', '{n} VIPs', { n: crmStore.dashboardStats?.vip_customers || 0 }) }}</span>
        </div>
      </div>
    </div>

    <!-- Active Tables -->
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
      <div class="flex items-end justify-between">
        <div>
          <p class="text-sm font-semibold text-gray-500">{{ $t('crm.stats.today', 'Today') }}</p>
          <div class="flex items-baseline gap-2 mt-1">
            <h2 class="text-3xl font-bold text-gray-900">{{ activeTablesCount }}</h2>
            <span class="text-sm font-medium text-gray-500">{{ $t('crm.stats.activeTables', 'active tables') }}</span>
          </div>
        </div>
        <router-link
          to="/crm/serving-tables"
          class="flex items-center gap-2 text-sm font-semibold text-[#b89722] hover:text-[#9e811d]"
        >
          {{ $t('crm.viewAll', 'View all') }} &rarr;
        </router-link>
      </div>
    </div>

    <!-- Quick Actions -->
    <div>
      <h3 class="mb-3 text-sm font-bold text-gray-900 uppercase tracking-wider">{{ $t('crm.quickActions', 'Quick Actions') }}</h3>
      <div class="grid gap-3">
        <router-link
          to="/crm/serving-tables"
          class="group flex items-center gap-4 rounded-2xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:border-[#b89722] hover:shadow-md"
        >
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-[#b89722]/10 text-[#b89722] transition-colors group-hover:bg-[#b89722] group-hover:text-white">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          </div>
          <div class="flex-1">
            <h4 class="font-bold text-gray-900">{{ $t('crm.startSurvey', 'Start a Survey') }}</h4>
            <p class="text-sm text-gray-500 mt-0.5">{{ $t('crm.viewTablesToBegin', 'View tables to begin') }}</p>
          </div>
          <div class="w-8 h-8 rounded-full bg-gray-50 flex items-center justify-center text-gray-400 group-hover:bg-[#b89722]/10 group-hover:text-[#b89722] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            </svg>
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useCrmStore } from '@/stores/crmStore'

const crmStore = useCrmStore()

const activeTablesCount = computed(() => crmStore.servingTables.length)

onMounted(() => {
  crmStore.fetchDashboardStats()
  crmStore.fetchServingTables()
})
</script>
