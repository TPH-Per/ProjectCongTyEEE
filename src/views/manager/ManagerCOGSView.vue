<template>
  <div class="min-h-screen bg-gray-50 p-6">

    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      {{ $t('manager_cogs.loading_data') }}
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">{{ $t('manager_cogs.title') }}</h1>
      <p class="text-sm text-gray-500 mt-1">{{ $t('manager_cogs.subtitle') }}</p>
    </div>

    <!-- Summary Bar -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('manager_cogs.revenue') }}</p>
        <p class="text-2xl font-bold text-gray-800">{{ revenue.toLocaleString('vi-VN') }}<span class="text-base font-normal text-gray-500">{{ $t('manager_cogs.currency_symbol') }}</span></p>
        <p class="text-xs text-green-500 mt-1 font-medium">{{ $t('manager_cogs.today') }}</p>
      </div>
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ $t('manager_cogs.total_cogs') }}</p>
        <p class="text-2xl font-bold text-gray-800">69,300,000<span class="text-base font-normal text-gray-500">{{ $t('manager_cogs.currency_symbol') }}</span></p>
        <p class="text-xs text-gray-400 mt-1 font-medium">{{ $t('manager_cogs.net_ingredient_cost') }}</p>
      </div>
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">COGS Ratio</p>
        <div class="flex items-center gap-3 mt-1">
          <p class="text-2xl font-bold text-gray-800">35%</p>
          <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">{{ $t('manager_cogs.status_good') }}</span>
        </div>
        <!-- Mini progress bar -->
        <div class="mt-3 bg-gray-100 rounded-full h-2">
          <div class="h-2 rounded-full bg-green-400" style="width: 35%"></div>
        </div>
        <div class="flex justify-between text-xs text-gray-400 mt-1">
          <span>0%</span><span class="text-green-600 font-semibold">35%</span><span>100%</span>
        </div>
      </div>
    </div>

    <!-- COGS Item Table -->
    <div class="kawaii-card mb-6 overflow-hidden">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div>
          <h2 class="text-base font-bold text-gray-800">{{ $t('manager_cogs.cogs_list') }}</h2>
          <p class="text-xs text-gray-400 mt-0.5">{{ $t('manager_cogs.click_header_to_sort') }}</p>
        </div>
        <button class="kawaii-btn-primary text-sm px-4 py-2 flex items-center gap-1.5">
          <span class="text-lg leading-none">+</span> {{ $t('manager_cogs.add_item') }}
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th
                v-for="col in tableColumns"
                :key="col.key"
                class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none whitespace-nowrap"
              >
                {{ col.label }}
                <span class="ml-1 text-gray-300">↕</span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr
              v-for="(item, idx) in cogsItems"
              :key="idx"
              class="hover:bg-orange-50 transition-colors duration-100"
            >
              <td class="px-4 py-3 font-medium text-gray-800 whitespace-nowrap">{{ item.name }}</td>
              <td class="px-4 py-3">
                <input
                  :value="item.cost"
                  class="w-28 text-right bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3">
                <input
                  :value="item.price"
                  class="w-28 text-right bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3">
                <input
                  :value="item.qty"
                  class="w-20 text-center bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3 text-gray-600 text-right whitespace-nowrap">{{ item.unitCOGS }}</td>
              <td class="px-4 py-3 font-semibold text-gray-800 text-right whitespace-nowrap">{{ item.totalCOGS }}</td>
              <td class="px-4 py-3">
                <span
                  class="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold"
                  :class="item.ratioBadge"
                >
                  {{ item.ratio }}
                </span>
              </td>
            </tr>
            <!-- Footer row -->
            <tr class="bg-gray-50 font-bold">
              <td class="px-4 py-3 text-gray-700">{{ $t('manager_cogs.total') }}</td>
              <td colspan="4" class="px-4 py-3"></td>
              <td class="px-4 py-3 text-right text-gray-800">29,360,000{{ $t('manager_cogs.currency_symbol') }}</td>
              <td class="px-4 py-3"></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Bottom row: Bar chart + Note -->
    <div class="grid grid-cols-3 gap-4">
      <!-- COGS by Category Bar Chart -->
      <div class="col-span-2 kawaii-card p-5">
        <h2 class="text-base font-bold text-gray-800 mb-4">{{ $t('manager_cogs.cogs_by_category') }}</h2>
        <div class="space-y-4">
          <div v-for="cat in cogsCategories" :key="cat.label">
            <div class="flex justify-between items-center mb-1.5">
              <span class="text-sm font-medium text-gray-700">{{ cat.label }}</span>
              <span class="text-sm font-bold text-gray-800">{{ cat.pct }}%</span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
              <div
                class="h-3 rounded-full transition-all duration-700"
                :style="{ width: cat.pct + '%', backgroundColor: cat.color }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Note / Alert box -->
      <div class="flex flex-col gap-4">
        <div class="kawaii-card p-5 border-l-4 border-red-400 bg-red-50 flex-1">
          <div class="flex items-start gap-3">
            <span class="text-2xl">⚠️</span>
            <div>
              <p class="text-sm font-bold text-red-700 mb-1">{{ $t('manager_cogs.high_cogs_warning') }}</p>
              <p class="text-sm text-red-600 leading-relaxed">
                {{ $t('manager_cogs.item') }} <strong>{{ $t('manager_cogs.sake_item') }}</strong> {{ $t('manager_cogs.cogs_exceed_warning') }}
              </p>
            </div>
          </div>
        </div>
        <div class="kawaii-card p-5 bg-blue-50 border-l-4 border-blue-300">
          <p class="text-xs font-bold text-blue-700 mb-1">{{ $t('manager_cogs.suggestion') }}</p>
          <p class="text-xs text-blue-600 leading-relaxed">
            {{ $t('manager_cogs.overall_cogs_ratio') }} <strong>35%</strong> {{ $t('manager_cogs.safe_threshold_msg') }}
          </p>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted, computed } from 'vue'
import { useReport } from '@/composables/useReport'
import { useInventory } from '@/composables/useInventory'

const { todayHeadline } = useReport()
const { listLowStock } = useInventory()

const loading = ref(true)
const revenue = ref(0)

const cogsItems = ref<any[]>([])

const tableColumns = computed(() => [
  { key: 'name', label: t('manager_cogs.col_item_name') },
  { key: 'cost', label: t('manager_cogs.col_cost') },
  { key: 'price', label: t('manager_cogs.col_price') },
  { key: 'qty', label: t('manager_cogs.col_qty') },
  { key: 'unitCOGS', label: t('manager_cogs.col_unit_cogs') },
  { key: 'totalCOGS', label: t('manager_cogs.col_total_cogs') },
  { key: 'ratio', label: t('manager_cogs.col_ratio') },
])

const cogsCategories = computed(() => [
  { label: t('manager_cogs.cat_beef'), pct: 45, color: '#FF7B89' },
  { label: t('manager_cogs.cat_seafood'), pct: 22, color: '#60A5FA' },
  { label: t('manager_cogs.cat_drinks'), pct: 18, color: '#A78BFA' },
  { label: t('manager_cogs.cat_veg'), pct: 15, color: '#34D399' },
])

onMounted(async () => {
  loading.value = true
  try {
    const [headline, lowStock] = await Promise.all([
      todayHeadline(),
      listLowStock()
    ])
    revenue.value = headline.revenue
    
    if (lowStock && lowStock.length > 0) {
      cogsItems.value = lowStock.map(item => ({
        name: item.name_vi,
        cost: (item.unit_cost || 0).toLocaleString('vi-VN') + t('manager_cogs.currency_symbol'),
        price: '-',
        qty: item.quantity.toString(),
        unitCOGS: (item.unit_cost || 0).toLocaleString('vi-VN') + t('manager_cogs.currency_symbol'),
        totalCOGS: ((item.unit_cost || 0) * item.quantity).toLocaleString('vi-VN') + t('manager_cogs.currency_symbol'),
        ratio: '-',
        ratioBadge: 'bg-gray-100 text-gray-700'
      }))
    } else {
      cogsItems.value = [
        {
          name: t('manager_cogs.item_wagyu'),
          cost: '180,000' + t('manager_cogs.currency_symbol'),
          price: '500,000' + t('manager_cogs.currency_symbol'),
          qty: '45',
          unitCOGS: '180,000' + t('manager_cogs.currency_symbol'),
          totalCOGS: '8,100,000' + t('manager_cogs.currency_symbol'),
          ratio: '36%',
          ratioBadge: 'bg-yellow-100 text-yellow-700',
        },
        {
          name: t('manager_cogs.item_tongue'),
          cost: '120,000' + t('manager_cogs.currency_symbol'),
          price: '400,000' + t('manager_cogs.currency_symbol'),
          qty: '38',
          unitCOGS: '120,000' + t('manager_cogs.currency_symbol'),
          totalCOGS: '4,560,000' + t('manager_cogs.currency_symbol'),
          ratio: '30%',
          ratioBadge: 'bg-green-100 text-green-700',
        },
        {
          name: t('manager_cogs.item_ribs'),
          cost: '95,000' + t('manager_cogs.currency_symbol'),
          price: '380,000' + t('manager_cogs.currency_symbol'),
          qty: '60',
          unitCOGS: '95,000' + t('manager_cogs.currency_symbol'),
          totalCOGS: '5,700,000' + t('manager_cogs.currency_symbol'),
          ratio: '25%',
          ratioBadge: 'bg-green-100 text-green-700',
        },
        {
          name: t('manager_cogs.item_mushroom'),
          cost: '25,000' + t('manager_cogs.currency_symbol'),
          price: '120,000' + t('manager_cogs.currency_symbol'),
          qty: '80',
          unitCOGS: '25,000' + t('manager_cogs.currency_symbol'),
          totalCOGS: '2,000,000' + t('manager_cogs.currency_symbol'),
          ratio: '20.8%',
          ratioBadge: 'bg-green-100 text-green-700',
        },
        {
          name: t('manager_cogs.sake_item'),
          cost: '450,000' + t('manager_cogs.currency_symbol'),
          price: '800,000' + t('manager_cogs.currency_symbol'),
          qty: '20',
          unitCOGS: '450,000' + t('manager_cogs.currency_symbol'),
          totalCOGS: '9,000,000' + t('manager_cogs.currency_symbol'),
          ratio: '56.2%',
          ratioBadge: 'bg-red-100 text-red-700',
        },
      ]
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>

