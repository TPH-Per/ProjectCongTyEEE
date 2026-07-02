<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <!-- Page Header -->
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('accounting.dashboard') }}</h1>
        <p class="text-sm text-gray-500 mt-1">Financial overview and key metrics</p>
      </div>
      <div class="flex items-center gap-3">
        <button class="flex items-center gap-2 rounded-xl bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors">
          <CalendarIcon class="w-4 h-4" />
          <span>This Month</span>
          <ChevronDownIcon class="w-4 h-4" />
        </button>
        <button class="flex items-center gap-2 rounded-xl bg-[hsl(var(--primary))] px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-[hsl(var(--primary))]/90 transition-colors">
          <DownloadIcon class="w-4 h-4" />
          <span>Export Report</span>
        </button>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
      <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex flex-col relative overflow-hidden group hover:shadow-md transition-shadow">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-blue-50 rounded-full opacity-50 group-hover:scale-110 transition-transform"></div>
        <div class="flex items-center justify-between mb-4">
          <div class="p-2.5 bg-blue-100 text-blue-600 rounded-xl">
            <DollarSignIcon class="w-6 h-6" />
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <TrendingUpIcon class="w-3 h-3" /> +12.5%
          </span>
        </div>
        <p class="text-sm font-medium text-gray-500 mb-1">Total Revenue</p>
        <h3 class="text-2xl font-bold text-gray-800">{{ loading ? '...' : formatCurrency(profitLossData.revenue) }}</h3>
      </div>

      <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex flex-col relative overflow-hidden group hover:shadow-md transition-shadow">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-red-50 rounded-full opacity-50 group-hover:scale-110 transition-transform"></div>
        <div class="flex items-center justify-between mb-4">
          <div class="p-2.5 bg-red-100 text-red-600 rounded-xl">
            <CreditCardIcon class="w-6 h-6" />
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-red-600 bg-red-50 rounded-full px-2 py-0.5">
            <TrendingUpIcon class="w-3 h-3" /> +4.2%
          </span>
        </div>
        <p class="text-sm font-medium text-gray-500 mb-1">Total Expenses</p>
        <h3 class="text-2xl font-bold text-gray-800">{{ loading ? '...' : formatCurrency(profitLossData.expense) }}</h3>
      </div>

      <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex flex-col relative overflow-hidden group hover:shadow-md transition-shadow">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-green-50 rounded-full opacity-50 group-hover:scale-110 transition-transform"></div>
        <div class="flex items-center justify-between mb-4">
          <div class="p-2.5 bg-green-100 text-green-600 rounded-xl">
            <BriefcaseIcon class="w-6 h-6" />
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <TrendingUpIcon class="w-3 h-3" /> +18.7%
          </span>
        </div>
        <p class="text-sm font-medium text-gray-500 mb-1">Net Profit</p>
        <h3 class="text-2xl font-bold text-gray-800">{{ loading ? '...' : formatCurrency(profitLossData.profit) }}</h3>
      </div>

      <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex flex-col relative overflow-hidden group hover:shadow-md transition-shadow">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-purple-50 rounded-full opacity-50 group-hover:scale-110 transition-transform"></div>
        <div class="flex items-center justify-between mb-4">
          <div class="p-2.5 bg-purple-100 text-purple-600 rounded-xl">
            <ActivityIcon class="w-6 h-6" />
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <TrendingUpIcon class="w-3 h-3" /> +2.1%
          </span>
        </div>
        <p class="text-sm font-medium text-gray-500 mb-1">Profit Margin</p>
        <h3 class="text-2xl font-bold text-gray-800">{{ loading ? '...' : (profitLossData.revenue ? ((profitLossData.profit / profitLossData.revenue) * 100).toFixed(1) : 0) }}%</h3>
      </div>
    </div>

    <!-- Charts & Details -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-lg font-bold text-gray-800">Cash Flow Overview</h2>
          <button class="text-sm font-semibold text-[hsl(var(--primary))] hover:underline">View Report</button>
        </div>
        <div class="h-64 flex items-end justify-between gap-2 px-2 pb-2 relative">
          <div class="absolute inset-0 flex flex-col justify-between py-2 text-xs text-gray-400">
            <span>500k</span>
            <span>400k</span>
            <span>300k</span>
            <span>200k</span>
            <span>100k</span>
            <span>0</span>
          </div>
          <div class="w-full h-full flex items-end justify-around pl-10 z-10">
            <div v-for="bar in chartBars" :key="bar.label" class="w-12 group flex gap-1 items-end">
              <div class="w-1/2 bg-blue-400 rounded-t-sm group-hover:bg-blue-500 transition-colors" :style="`height: ${bar.revenue}%`"></div>
              <div class="w-1/2 bg-red-400 rounded-t-sm group-hover:bg-red-500 transition-colors" :style="`height: ${bar.expense}%`"></div>
            </div>
          </div>
        </div>
        <div class="flex justify-around pl-10 mt-3 text-xs font-medium text-gray-500">
          <span v-for="bar in chartBars" :key="bar.label">{{ bar.label }}</span>
        </div>
      </div>

      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h2 class="text-lg font-bold text-gray-800 mb-6">Recent Transactions</h2>
        <div class="rounded-xl border border-dashed border-gray-200 p-6 text-sm text-gray-500">
          No recent transaction feed is connected yet. Revenue and expense totals above come from the accounting RPC.
        </div>
        <button class="w-full mt-6 py-2 border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
          View All Activity
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { 
  CalendarIcon, 
  ChevronDownIcon, 
  DownloadIcon, 
  DollarSignIcon, 
  TrendingUpIcon, 
  CreditCardIcon, 
  BriefcaseIcon, 
  ActivityIcon,
} from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { useAccounting } from '@/composables/useAccounting'

const { t } = useLanguageStore()
const { getProfitLoss, loading } = useAccounting()

const profitLossData = ref({ revenue: 0, expense: 0, profit: 0 })
const chartBars = computed(() => {
  const revenue = Math.max(4, Math.min(100, profitLossData.value.revenue ? 72 : 4))
  const expense = Math.max(4, Math.min(100, profitLossData.value.expense && profitLossData.value.revenue
    ? (profitLossData.value.expense / profitLossData.value.revenue) * 72
    : profitLossData.value.expense ? 48 : 4))
  return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((label) => ({
    label,
    revenue,
    expense,
  }))
})

function formatCurrency(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

onMounted(async () => {
  const start = new Date()
  start.setDate(1) // Start of month
  const end = new Date() // Today
  
  const data = await getProfitLoss(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  profitLossData.value = data
})
</script>
