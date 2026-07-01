<template>
  <div class="min-h-screen bg-gray-50 p-6">

    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      {{ $t('manager_crm.loading_data') }}
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('crm.total_customers') }} Dashboard</h1>
        <p class="text-sm text-gray-500 mt-1">{{ $t('manager_crm.subtitle') }}</p>
      </div>

      <!-- Summary Row -->
      <div class="grid grid-cols-4 gap-4 mb-6">
        <div class="kawaii-card p-5">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('crm.total_customers') }}</p>
          <p class="text-2xl font-extrabold text-gray-800">{{ stats?.total_customers || 0 }}</p>
          <p class="text-xs mt-1 font-medium text-green-500">+{{ stats?.new_customers_this_month || 0 }} this month</p>
        </div>
        <div class="kawaii-card p-5">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('crm.repeat_rate') }}</p>
          <p class="text-2xl font-extrabold text-pink-600">{{ repeatRate }}%</p>
          <p class="text-xs mt-1 font-medium text-pink-400">{{ stats?.repeater_customers || 0 }} repeaters</p>
        </div>
        <div class="kawaii-card p-5">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('crm.avg_spent') }}</p>
          <p class="text-2xl font-extrabold text-gray-800">{{ formatCurrency(stats?.avg_spent_per_customer || 0) }}</p>
          <p class="text-xs mt-1 font-medium text-gray-400">per customer</p>
        </div>
        <div class="kawaii-card p-5">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('crm.points_circulating') }}</p>
          <p class="text-2xl font-extrabold text-blue-600">{{ (stats?.total_points_in_circulation || 0).toLocaleString() }}</p>
          <p class="text-xs mt-1 font-medium text-blue-400">{{ (stats?.total_points_redeemed || 0).toLocaleString() }} redeemed</p>
        </div>
      </div>

      <!-- Tier Distribution Chart & Top Customers -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <!-- SVG Donut Chart -->
        <div class="kawaii-card p-6 flex flex-col items-center justify-center">
          <p class="text-sm font-bold text-gray-600 mb-4">{{ $t('crm.tier_distribution') }}</p>
          <div class="relative w-40 h-40">
            <svg class="w-40 h-40 -rotate-90" viewBox="0 0 160 160">
              <circle cx="80" cy="80" r="62" fill="none" stroke="#F3F4F6" stroke-width="16" />
              <!-- Render pie slices based on tier_distribution -->
              <circle
                v-for="(slice, index) in chartSlices"
                :key="index"
                cx="80" cy="80" r="62" fill="none"
                :stroke="slice.color"
                stroke-width="16"
                stroke-linecap="butt"
                :stroke-dasharray="slice.dasharray"
                :stroke-dashoffset="slice.dashoffset"
              />
            </svg>
            <div class="absolute inset-0 flex flex-col items-center justify-center">
              <span class="text-2xl font-extrabold text-gray-800">{{ stats?.total_customers || 0 }}</span>
              <span class="text-xs text-gray-400 font-medium">members</span>
            </div>
          </div>
          <div class="mt-4 flex flex-wrap justify-center gap-3 text-xs text-gray-500">
            <div v-for="(tier, i) in stats?.tier_distribution" :key="i" class="flex items-center gap-1.5">
              <span class="w-3 h-3 rounded-full inline-block" :style="{ backgroundColor: tier.color || '#ccc' }"></span>
              {{ getTierName(tier) }} ({{ tier.count }})
            </div>
          </div>
        </div>

        <!-- Top Customers -->
        <div class="kawaii-card p-5 col-span-2">
          <h2 class="text-sm font-bold text-gray-800 mb-4">{{ $t('crm.top_customers') }}</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Name</th>
                  <th class="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Phone</th>
                  <th class="px-4 py-2 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Visits</th>
                  <th class="px-4 py-2 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Spent</th>
                  <th class="px-4 py-2 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Points</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50">
                <tr v-for="c in stats?.top_customers" :key="c.id" class="hover:bg-orange-50 transition-colors">
                  <td class="px-4 py-2 font-semibold text-gray-800">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full" :style="{ backgroundColor: c.tier_color || '#ccc' }"></span>
                      {{ c.name || 'Unknown' }}
                    </div>
                  </td>
                  <td class="px-4 py-2 font-mono text-gray-600">{{ c.phone || 'N/A' }}</td>
                  <td class="px-4 py-2 text-center font-bold text-gray-800">{{ c.total_visits }}</td>
                  <td class="px-4 py-2 text-right font-semibold text-gray-800">{{ formatCurrency(c.total_spent) }}</td>
                  <td class="px-4 py-2 text-right font-bold text-blue-600">{{ c.current_points }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Customer List -->
      <div class="kawaii-card overflow-hidden">
        <div class="px-5 py-4 border-b border-gray-100">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 class="text-base font-bold text-gray-800">{{ $t('manager_crm.customer_list') }}</h2>
              <p class="text-xs text-gray-400 mt-0.5">{{ $t('manager_crm.showing_customers') }} {{ customers.length }} / {{ totalCustomers }}</p>
            </div>
            <!-- Search -->
            <div class="relative">
              <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
              <input
                v-model="searchQuery"
                @input="onSearch"
                type="text"
                :placeholder="$t('auto_placeholder_fix')"
                class="kawaii-input pl-8 text-sm w-64 border rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-pink-300"
              />
            </div>
          </div>
          <!-- Filter pills -->
          <div class="flex gap-2 mt-3 flex-wrap">
            <button
              class="px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all duration-150"
              :class="!activeTierId ? 'bg-pink-500 text-white shadow-md' : 'bg-gray-100 text-gray-600 hover:bg-pink-50 hover:text-pink-600'"
              @click="setTierFilter(null)"
            >
              {{ $t('manager_crm.all') }}
            </button>
            <button
              v-for="tier in stats?.tier_distribution"
              :key="tier.tier_id"
              class="px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all duration-150"
              :class="activeTierId === tier.tier_id ? 'bg-pink-500 text-white shadow-md' : 'bg-gray-100 text-gray-600 hover:bg-pink-50 hover:text-pink-600'"
              @click="setTierFilter(tier.tier_id)"
            >
              {{ getTierName(tier) }}
            </button>
          </div>
        </div>
        <!-- Table -->
        <div class="overflow-x-auto relative min-h-[200px]">
          <div v-if="loadingList" class="absolute inset-0 bg-white/50 flex items-center justify-center z-10">
            <span class="text-gray-500 font-medium">{{ $t('manager_crm.loading_data') }}</span>
          </div>
          <table class="w-full text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase cursor-pointer hover:bg-gray-100" @click="toggleSort('name')">{{ $t('manager_crm.col_name') }} + {{ $t('manager_crm.col_phone') }}</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">{{ $t('membership.tier') }}</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase cursor-pointer hover:bg-gray-100" @click="toggleSort('total_spent')">{{ $t('manager_crm.col_spent') }}</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase cursor-pointer hover:bg-gray-100" @click="toggleSort('current_points')">{{ $t('membership.points') }}</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase cursor-pointer hover:bg-gray-100" @click="toggleSort('last_visit_at')">{{ $t('manager_crm.col_last_visit') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr
                v-for="c in customers"
                :key="c.id"
                class="hover:bg-orange-50 transition-colors duration-100"
              >
                <td class="px-4 py-3">
                  <div class="font-semibold text-gray-800 whitespace-nowrap">{{ c.name || 'Unknown' }}</div>
                  <div class="font-mono text-xs text-gray-500 mt-0.5">{{ c.phone || 'N/A' }}</div>
                </td>
                <td class="px-4 py-3">
                  <span
                    v-if="c.tier && c.tier.id"
                    class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold shadow-sm"
                    :style="{ backgroundColor: (c.tier.color || '#ccc') + '20', color: c.tier.color || '#333', border: `1px solid ${c.tier.color || '#ccc'}40` }"
                  >
                    <span class="w-1.5 h-1.5 rounded-full" :style="{ backgroundColor: c.tier.color || '#ccc' }"></span>
                    {{ getTierName(c.tier) }}
                  </span>
                  <span v-else class="text-xs text-gray-400">N/A</span>
                </td>
                <td class="px-4 py-3 text-right font-semibold text-gray-800 whitespace-nowrap">
                  {{ formatCurrency(c.total_spent) }}
                  <div class="text-xs text-gray-400 font-normal mt-0.5">{{ c.total_visits }} {{ $t('manager_crm.col_visits') }}</div>
                </td>
                <td class="px-4 py-3 text-right font-bold text-blue-600">{{ c.current_points || 0 }}</td>
                <td class="px-4 py-3 text-gray-500 text-xs whitespace-nowrap">
                  {{ c.last_visit_at ? new Date(c.last_visit_at).toLocaleDateString() : 'N/A' }}
                </td>
              </tr>
              <tr v-if="customers.length === 0 && !loadingList">
                <td colspan="5" class="px-4 py-8 text-center text-gray-500">No customers found.</td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Footer Pagination -->
        <div class="px-5 py-3 bg-gray-50 flex items-center justify-between">
          <p class="text-xs text-gray-400">{{ $t('manager_crm.showing_pagination') }} {{ customers.length }} / {{ totalCustomers }}</p>
          <div class="flex gap-2">
            <button
              class="kawaii-btn-ghost text-xs px-3 py-1.5"
              :disabled="offset === 0"
              @click="changePage(-1)"
            >{{ $t('manager_crm.prev') }}</button>
            <button
              class="kawaii-btn-primary text-xs px-3 py-1.5"
              :disabled="offset + limit >= totalCustomers"
              @click="changePage(1)"
            >{{ $t('manager_crm.next') }}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, computed, onMounted } from 'vue'
import { useCustomer } from '@/composables/useCustomer'

const { t, locale } = useI18n()
const { fetchCrmStats, listCustomers } = useCustomer()

const loading = ref(true)
const loadingList = ref(false)
const stats = ref<any>(null)

// Customer List State
const customers = ref<any[]>([])
const totalCustomers = ref(0)
const searchQuery = ref('')
const activeTierId = ref<string | null>(null)
const limit = ref(30)
const offset = ref(0)
const sortBy = ref('total_spent')
const sortDir = ref('desc')

let searchTimeout: ReturnType<typeof setTimeout>

onMounted(async () => {
  loading.value = true
  try {
    stats.value = await fetchCrmStats()
    await loadCustomerList()
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
})

// Computed stats
const repeatRate = computed(() => {
  if (!stats.value || stats.value.total_customers === 0) return 0
  return Math.round((stats.value.repeater_customers / stats.value.total_customers) * 100)
})

// Donut chart calculations
const chartSlices = computed(() => {
  if (!stats.value?.tier_distribution) return []
  const total = stats.value.total_customers || 1
  let currentOffset = 0
  const circumference = 2 * Math.PI * 62 // ~389.55
  
  return stats.value.tier_distribution.map((tier: any) => {
    const fraction = tier.count / total
    const dash = fraction * circumference
    const slice = {
      color: tier.color || '#ccc',
      dasharray: `${dash} ${circumference}`,
      dashoffset: -currentOffset
    }
    currentOffset += dash
    return slice
  })
})

function formatCurrency(val: number) {
  return (val || 0).toLocaleString('vi-VN') + t('manager_dashboard.currency_symbol', 'đ')
}

function getTierName(tierObj: any) {
  if (!tierObj) return ''
  if (locale.value === 'vi') return tierObj.name_vi
  if (locale.value === 'ja') return tierObj.name_ja
  return tierObj.name_en || tierObj.name_vi
}

// List fetching
async function loadCustomerList() {
  loadingList.value = true
  try {
    const res = await listCustomers({
      search: searchQuery.value || undefined,
      tierId: activeTierId.value || undefined,
      limit: limit.value,
      offset: offset.value,
      sortBy: sortBy.value
    })
    customers.value = res.customers || []
    totalCustomers.value = res.total || 0
  } catch (err) {
    console.error(err)
  } finally {
    loadingList.value = false
  }
}

function onSearch() {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    offset.value = 0
    loadCustomerList()
  }, 300)
}

function setTierFilter(tierId: string | null) {
  activeTierId.value = tierId
  offset.value = 0
  loadCustomerList()
}

function toggleSort(col: string) {
  if (sortBy.value === col) {
    sortDir.value = sortDir.value === 'desc' ? 'asc' : 'desc'
  } else {
    sortBy.value = col
    sortDir.value = 'desc'
  }
  offset.value = 0
  loadCustomerList()
}

function changePage(direction: number) {
  const newOffset = offset.value + direction * limit.value
  if (newOffset >= 0 && newOffset < totalCustomers.value) {
    offset.value = newOffset
    loadCustomerList()
  }
}
</script>


