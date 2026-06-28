<template>
  <div class="min-h-screen bg-gray-50 p-6">

    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      {{ $t('manager_revenue.loading') }}
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('manager_revenue.title') }}</h1>
        <p class="text-sm text-gray-500 mt-1">{{ $t('manager_revenue.subtitle') }}</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="kawaii-btn-ghost text-sm flex items-center gap-1.5">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
          {{ $t('manager_revenue.export_csv') }}
        </button>
        <button class="kawaii-btn-primary text-sm flex items-center gap-1.5">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          {{ $t('manager_revenue.export_excel') }}
        </button>
      </div>
    </div>

    <!-- Tab Switcher -->
    <div class="mb-5 inline-flex rounded-2xl border border-gray-200 bg-white p-1 shadow-sm">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        :class="[
          'rounded-xl px-5 py-2 text-sm font-semibold transition-all duration-200',
          activeTab === tab.key
            ? 'kawaii-gradient text-white shadow-md'
            : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
        ]"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Filter Row -->
    <div class="kawaii-card kawaii-shadow mb-6 flex flex-wrap items-center gap-3 p-4">
      <div class="flex items-center gap-2">
        <label class="text-xs font-semibold text-gray-500 whitespace-nowrap">{{ $t('manager_revenue.from_date') }}</label>
        <input type="date" value="2026-06-14" class="kawaii-input text-sm py-2 px-3" />
      </div>
      <div class="flex items-center gap-2">
        <label class="text-xs font-semibold text-gray-500 whitespace-nowrap">{{ $t('manager_revenue.to_date') }}</label>
        <input type="date" value="2026-06-20" class="kawaii-input text-sm py-2 px-3" />
      </div>
      <button class="kawaii-btn-primary text-sm flex items-center gap-1.5 py-2 px-4">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z"/></svg>
        {{ $t('manager_revenue.filter') }}
      </button>
      <button class="kawaii-btn-ghost text-sm flex items-center gap-1 py-2 px-3 ml-auto">
        <span>🔁</span> {{ $t('manager_revenue.reload') }}
      </button>
    </div>

    <!-- Summary Cards -->
    <div class="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
      <!-- Tổng Doanh Thu -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-2 -top-2 text-5xl opacity-5">💵</div>
        <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">{{ $t('manager_revenue.total_revenue') }}</p>
        <p class="text-2xl font-bold text-gray-900">{{ revenue.toLocaleString('vi-VN') }}<span class="text-sm text-gray-400">đ</span></p>
        <div class="mt-2 flex items-center gap-1.5">
          <span class="inline-flex items-center gap-0.5 text-xs font-bold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
            +8.3%
          </span>
          <span class="text-xs text-gray-400">{{ $t('manager_revenue.vs_yesterday') }}</span>
        </div>
        <div class="mt-3 h-1 w-full rounded-full bg-gray-100">
          <div class="h-1 rounded-full kawaii-gradient" style="width: 82.7%"></div>
        </div>
        <p class="text-xs text-gray-400 mt-1">{{ $t('manager_revenue.goal_progress') }}</p>
      </div>

      <!-- Tổng Khách -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-2 -top-2 text-5xl opacity-5">🧑‍🤝‍🧑</div>
        <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">{{ $t('manager_revenue.total_guests') }}</p>
        <p class="text-2xl font-bold text-gray-900">{{ covers }}</p>
        <div class="mt-2 flex gap-2 text-xs">
          <span class="rounded-lg bg-blue-50 px-2 py-1 text-blue-600 font-semibold">🇻🇳 210 Việt</span>
          <span class="rounded-lg bg-green-50 px-2 py-1 text-green-600 font-semibold">✈️ 38 Nước ngoài</span>
        </div>
        <div class="mt-3 flex gap-1 h-1.5 rounded-full overflow-hidden">
          <div class="bg-blue-400 rounded-full" style="width: 84.7%"></div>
          <div class="bg-green-400 rounded-full flex-1"></div>
        </div>
      </div>

      <!-- Avg Check -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-2 -top-2 text-5xl opacity-5">🧾</div>
        <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">{{ $t('manager_revenue.avg_per_guest') }}</p>
        <p class="text-2xl font-bold text-gray-900">{{ Math.round(avgCheck).toLocaleString('vi-VN') }}<span class="text-sm text-gray-400">đ</span></p>
        <div class="mt-2 flex items-center gap-1.5">
          <span class="inline-flex items-center text-xs font-bold text-gray-50 bg-gray-100 rounded-full px-2 py-0.5">
            {{ $t('manager_revenue.stable') }}
          </span>
        </div>
        <p class="text-xs text-gray-400 mt-3">Mục tiêu: 55,000đ/khách</p>
      </div>

      <!-- Doanh Thu Trên Bàn -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-2 -top-2 text-5xl opacity-5">🍽</div>
        <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">{{ $t('manager_revenue.revenue_per_table') }}</p>
        <p class="text-2xl font-bold text-gray-900">1,033,333<span class="text-sm text-gray-400">đ</span></p>
        <div class="mt-2 flex items-center gap-1.5">
          <span class="inline-flex items-center gap-0.5 text-xs font-bold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
            +3.2%
          </span>
          <span class="text-xs text-gray-400">{{ $t('manager_revenue.vs_yesterday') }}</span>
        </div>
        <p class="text-xs text-gray-400 mt-3">Dựa trên 12 bàn hoạt động</p>
      </div>
    </div>

    <!-- Revenue by Type + Demographics -->
    <div class="mb-6 grid grid-cols-1 gap-5 lg:grid-cols-5">
      <!-- Revenue by Type -->
      <div class="kawaii-card kawaii-shadow p-6 lg:col-span-3">
        <h2 class="text-base font-bold text-gray-800 mb-1">{{ $t('manager_revenue.revenue_breakdown') }}</h2>
        <p class="text-xs text-gray-400 mb-5">{{ $t('manager_revenue.service_proportion') }}</p>

        <div class="space-y-5">
          <!-- Bữa Tối -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <div class="h-3 w-3 rounded-full bg-red-700"></div>
                <span class="text-sm font-semibold text-gray-700">{{ $t('manager_revenue.dinner') }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-xs text-gray-400 font-medium">58%</span>
                <span class="text-sm font-bold text-gray-800">7,200,000đ</span>
              </div>
            </div>
            <div class="relative h-7 rounded-xl bg-gray-100 overflow-hidden">
              <div class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-red-800 to-red-600 flex items-center justify-end pr-3 transition-all duration-700" style="width: 58%">
                <span class="text-xs font-bold text-red-100">58%</span>
              </div>
            </div>
          </div>

          <!-- Bữa Trưa -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <div class="h-3 w-3 rounded-full bg-orange-500"></div>
                <span class="text-sm font-semibold text-gray-700">{{ $t('manager_revenue.lunch') }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-xs text-gray-400 font-medium">27.4%</span>
                <span class="text-sm font-bold text-gray-800">3,400,000đ</span>
              </div>
            </div>
            <div class="relative h-7 rounded-xl bg-gray-100 overflow-hidden">
              <div class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-orange-500 to-orange-400 flex items-center justify-end pr-3 transition-all duration-700" style="width: 27.4%">
                <span class="text-xs font-bold text-white">27%</span>
              </div>
            </div>
          </div>

          <!-- Rượu/Cocktail -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <div class="h-3 w-3 rounded-full bg-purple-600"></div>
                <span class="text-sm font-semibold text-gray-700">{{ $t('manager_revenue.alcohol') }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-xs text-gray-400 font-medium">8.9%</span>
                <span class="text-sm font-bold text-gray-800">1,100,000đ</span>
              </div>
            </div>
            <div class="relative h-7 rounded-xl bg-gray-100 overflow-hidden">
              <div class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-purple-700 to-purple-500 flex items-center justify-end pr-3 transition-all duration-700" style="width: 8.9%">
              </div>
              <span class="absolute left-[11%] top-1/2 -translate-y-1/2 text-xs font-bold text-purple-600">8.9%</span>
            </div>
          </div>

          <!-- Giao Hàng -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <div class="h-3 w-3 rounded-full bg-blue-500"></div>
                <span class="text-sm font-semibold text-gray-700">{{ $t('manager_revenue.delivery') }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-xs text-gray-400 font-medium">5.6%</span>
                <span class="text-sm font-bold text-gray-800">700,000đ</span>
              </div>
            </div>
            <div class="relative h-7 rounded-xl bg-gray-100 overflow-hidden">
              <div class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-blue-600 to-blue-400 flex items-center justify-end pr-3 transition-all duration-700" style="width: 5.6%">
              </div>
              <span class="absolute left-[8%] top-1/2 -translate-y-1/2 text-xs font-bold text-blue-600">5.6%</span>
            </div>
          </div>
        </div>

        <div class="mt-5 pt-4 border-t border-gray-100">
          <div class="flex flex-wrap gap-3">
            <div v-for="item in revenueTypes" :key="item.label" class="flex items-center gap-1.5 text-xs text-gray-500">
              <div :class="['h-2.5 w-2.5 rounded-full', item.color]"></div>
              <span>{{ item.label }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Guest Demographics -->
      <div class="kawaii-card kawaii-shadow p-6 lg:col-span-2">
        <h2 class="text-base font-bold text-gray-800 mb-1">{{ $t('manager_revenue.customers') }}</h2>
        <p class="text-xs text-gray-400 mb-4">{{ $t('manager_revenue.demographics') }}</p>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-xs text-gray-400 uppercase">
                <th class="pb-3 text-left font-semibold">{{ $t('manager_revenue.type') }}</th>
                <th class="pb-3 text-right font-semibold">{{ $t('manager_revenue.quantity') }}</th>
                <th class="pb-3 text-right font-semibold">{{ $t('manager_revenue.ratio') }}</th>
                <th class="pb-3 text-right font-semibold">{{ $t('manager_revenue.avg_revenue') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr v-for="demo in demographics" :key="demo.type" class="hover:bg-gray-50 transition-colors">
                <td class="py-3 flex items-center gap-2">
                  <span class="text-base">{{ demo.icon }}</span>
                  <span class="font-medium text-gray-700">{{ demo.type }}</span>
                </td>
                <td class="py-3 text-right font-semibold text-gray-800">{{ demo.count }}</td>
                <td class="py-3 text-right">
                  <span :class="['inline-block rounded-lg px-2 py-0.5 text-xs font-bold', demo.badgeClass]">
                    {{ demo.rate }}
                  </span>
                </td>
                <td class="py-3 text-right text-xs font-semibold text-gray-700">{{ demo.avgRevenue }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="mt-4 pt-3 border-t border-gray-100">
          <p class="text-xs text-gray-400">{{ $t('manager_revenue.total') }}: {{ covers }} {{ $t('manager_revenue.guest').toLowerCase() }} · {{ $t('manager_revenue.average') }} {{ Math.round(avgCheck).toLocaleString('vi-VN') }}đ/{{ $t('manager_revenue.guest').toLowerCase() }}</p>
        </div>
      </div>
    </div>

    <!-- Period Comparison + Weekday/Weekend -->
    <div class="grid grid-cols-1 gap-5 lg:grid-cols-2">
      <!-- Period Comparison Table -->
      <div class="kawaii-card kawaii-shadow p-6">
        <h2 class="text-base font-bold text-gray-800 mb-1">{{ $t('manager_revenue.period_comparison') }}</h2>
        <p class="text-xs text-gray-400 mb-5">{{ $t('manager_revenue.period_vs_prev') }}</p>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr>
                <th class="pb-3 text-left text-xs text-gray-400 uppercase font-semibold">{{ $t('manager_revenue.metric') }}</th>
                <th class="pb-3 text-right text-xs text-gray-400 uppercase font-semibold">{{ $t('manager_revenue.prev_period') }}</th>
                <th class="pb-3 text-right text-xs text-gray-400 uppercase font-semibold">{{ $t('manager_revenue.this_period') }}</th>
                <th class="pb-3 text-right text-xs text-gray-400 uppercase font-semibold">+/- %</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr v-for="comp in comparisons" :key="comp.metric" class="hover:bg-gray-50 transition-colors">
                <td class="py-3.5 font-semibold text-gray-700 flex items-center gap-2">
                  <span>{{ comp.icon }}</span>
                  {{ comp.metric }}
                </td>
                <td class="py-3.5 text-right text-gray-500">{{ comp.prev }}</td>
                <td class="py-3.5 text-right font-bold text-gray-800">{{ comp.current }}</td>
                <td class="py-3.5 text-right">
                  <span :class="[
                    'inline-flex items-center gap-0.5 rounded-full px-2 py-0.5 text-xs font-bold',
                    comp.delta.startsWith('+') ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-500'
                  ]">
                    {{ comp.delta.startsWith('+') ? '▲' : '▼' }} {{ comp.delta }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Weekday vs Weekend -->
      <div class="kawaii-card kawaii-shadow p-6">
        <h2 class="text-base font-bold text-gray-800 mb-1">{{ $t('manager_revenue.weekday_vs_weekend') }}</h2>
        <p class="text-xs text-gray-400 mb-5">{{ $t('manager_revenue.avg_revenue_by_day_type') }}</p>

        <div class="grid grid-cols-2 gap-4">
          <!-- Weekday -->
          <div class="relative rounded-2xl border-2 border-gray-100 bg-gradient-to-br from-slate-50 to-gray-100 p-5 text-center overflow-hidden">
            <div class="absolute -bottom-4 -right-4 text-7xl opacity-5">📅</div>
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-gray-200 mb-3">
              <span class="text-2xl">🗓</span>
            </div>
            <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-1">{{ $t('manager_revenue.weekday') }}</p>
            <p class="text-xs text-gray-400 mb-3">{{ $t('manager_revenue.mon_to_fri') }}</p>
            <p class="text-2xl font-bold text-gray-800">11,200,000<span class="text-sm text-gray-500">đ</span></p>
            <p class="text-xs text-gray-400 mt-1">{{ $t('manager_revenue.per_day') }}</p>
            <div class="mt-4 flex items-center justify-center gap-1.5 text-xs">
              <div class="h-2 w-2 rounded-full bg-gray-400"></div>
              <span class="text-gray-500">Tỷ lệ lấp đầy: 62%</span>
            </div>
          </div>

          <!-- Weekend -->
          <div class="relative rounded-2xl border-2 border-pink-100 bg-gradient-to-br from-pink-50 to-rose-50 p-5 text-center overflow-hidden">
            <div class="absolute -bottom-4 -right-4 text-7xl opacity-5">🎉</div>
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-pink-200 mb-3">
              <span class="text-2xl">🎉</span>
            </div>
            <p class="text-xs font-semibold uppercase tracking-wider text-pink-400 mb-1">{{ $t('manager_revenue.weekend') }}</p>
            <p class="text-xs text-pink-300 mb-3">{{ $t('manager_revenue.sat_sun') }}</p>
            <p class="text-2xl font-bold text-pink-600">18,600,000<span class="text-sm text-pink-400">đ</span></p>
            <p class="text-xs text-pink-400 mt-1">{{ $t('manager_revenue.per_day') }}</p>
            <div class="mt-4 flex items-center justify-center gap-1.5 text-xs">
              <div class="h-2 w-2 rounded-full bg-pink-400"></div>
              <span class="text-pink-500">Tỷ lệ lấp đầy: 94%</span>
            </div>
          </div>
        </div>

        <!-- Difference callout -->
        <div class="mt-5 rounded-2xl bg-pink-50 border border-pink-100 px-4 py-3 flex items-center gap-3">
          <span class="text-xl">🚀</span>
          <div>
            <p class="text-sm font-bold text-pink-700">{{ $t('manager_revenue.weekend_higher') }} <span class="text-pink-500">66%</span> {{ $t('manager_revenue.than_weekday') }}</p>
            <p class="text-xs text-pink-400 mt-0.5">{{ $t('manager_revenue.consider_increase_staff') }}</p>
          </div>
        </div>

        <!-- Mini bar comparison -->
        <div class="mt-4 space-y-2">
          <div class="flex items-center gap-3">
            <span class="w-24 text-xs text-gray-500 text-right">{{ $t('manager_revenue.weekday') }}</span>
            <div class="flex-1 h-5 rounded-lg bg-gray-100 overflow-hidden">
              <div class="h-full bg-gray-400 rounded-lg flex items-center justify-end pr-2" style="width: 60.2%">
                <span class="text-xs text-white font-bold">60%</span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <span class="w-24 text-xs text-gray-500 text-right">{{ $t('manager_revenue.weekend') }}</span>
            <div class="flex-1 h-5 rounded-lg bg-gray-100 overflow-hidden">
              <div class="h-full kawaii-gradient rounded-lg flex items-center justify-end pr-2" style="width: 100%">
                <span class="text-xs text-white font-bold">100%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, onMounted, computed } from 'vue'
import { useReport } from '@/composables/useReport'

const { t } = useI18n()
const { todayHeadline } = useReport()

const loading = ref(true)
const revenue = ref(0)
const covers = ref(0)

const avgCheck = computed(() => covers.value > 0 ? revenue.value / covers.value : 0)

onMounted(async () => {
  loading.value = true
  try {
    const headline = await todayHeadline()
    revenue.value = headline.revenue
    covers.value = headline.covers
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
})

// Tab state
const activeTab = ref<'day' | 'week' | 'month'>('day')

const tabs = computed(() => [
  { key: 'day' as const, label: t('manager_revenue.by_day') },
  { key: 'week' as const, label: t('manager_revenue.by_week') },
  { key: 'month' as const, label: t('manager_revenue.by_month') },
])

const revenueTypes = computed(() => [
  { label: t('manager_revenue.dinner_label'), color: 'bg-red-700' },
  { label: t('manager_revenue.lunch_label'), color: 'bg-orange-500' },
  { label: t('manager_revenue.alcohol_label'), color: 'bg-purple-600' },
  { label: t('manager_revenue.delivery_label'), color: 'bg-blue-500' },
])

const demographics = computed(() => [
  { icon: '👨', type: t('manager_revenue.male'), count: 118, rate: '47.6%', avgRevenue: '54,000đ', badgeClass: 'bg-blue-50 text-blue-600' },
  { icon: '👩', type: t('manager_revenue.female'), count: 96, rate: '38.7%', avgRevenue: '48,000đ', badgeClass: 'bg-pink-50 text-pink-600' },
  { icon: '👶', type: t('manager_revenue.children'), count: 34, rate: '13.7%', avgRevenue: '22,000đ', badgeClass: 'bg-yellow-50 text-yellow-600' },
  { icon: '✈️', type: t('manager_revenue.foreigners'), count: 38, rate: '15.3%', avgRevenue: '78,000đ', badgeClass: 'bg-green-50 text-green-600' },
])

const comparisons = computed(() => [
  { icon: '💰', metric: t('manager_revenue.revenue_metric'), prev: '11,456,000đ', current: '12,400,000đ', delta: '+8.3%' },
  { icon: '👥', metric: t('manager_revenue.guests_metric'), prev: '229', current: '248', delta: '+8.3%' },
  { icon: '🧾', metric: t('manager_revenue.avg_check_metric'), prev: '50,025đ', current: '50,000đ', delta: '-0.05%' },
])
</script>

