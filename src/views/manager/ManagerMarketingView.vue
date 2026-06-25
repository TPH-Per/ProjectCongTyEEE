<template>
  <div class="min-h-screen bg-gray-50 p-6">

    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      {{ t('auto_ang_t_i_d_li_u', 'Đang tải dữ liệu...') }}
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">{{ t('auto_ph_n_t_ch_marketing') }}</h1>
      <p class="text-sm text-gray-500 mt-1">{{ t('auto_th_ng_6___2026___t_ng_kh_ch__2') }}</p>
    </div>

    <!-- SNS Channel Attribution -->
    <h2 class="text-base font-bold text-gray-700 mb-3">{{ t('auto_ngu_n_kh_ch_theo_k_nh') }}</h2>
    <div class="grid grid-cols-5 gap-3 mb-6">
      <div
        v-for="ch in channels"
        :key="ch.name"
        class="kawaii-card p-4 flex flex-col gap-2 relative overflow-hidden"
        :class="ch.borderColor"
      >
        <!-- Subtle background glow -->
        <div class="absolute -right-4 -top-4 w-16 h-16 rounded-full opacity-10" :class="ch.glowColor"></div>
        <span class="text-2xl">{{ ch.icon }}</span>
        <p class="text-xs font-semibold text-gray-500 leading-tight">{{ ch.name }}</p>
        <p class="text-2xl font-extrabold text-gray-800">{{ ch.guests }}</p>
        <span
          class="inline-block w-fit px-2 py-0.5 rounded-full text-xs font-bold"
          :class="ch.pillClass"
        >{{ ch.pct }}</span>
        <p class="text-xs text-gray-400 mt-1 font-medium">{{ ch.revenue }}</p>
      </div>
    </div>

    <!-- Main two-col section -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <!-- Marketing Cost Input Form -->
      <div class="col-span-1 kawaii-card p-5">
        <h2 class="text-base font-bold text-gray-800 mb-4">{{ t('auto_nh_p_chi_ph__marketing') }}</h2>
        <!-- Month picker -->
        <div class="mb-4">
          <label class="block text-xs font-semibold text-gray-500 mb-1">{{ t('auto_th_ng') }}</label>
          <input
            v-model="selectedMonth"
            type="month"
            class="kawaii-input w-full text-sm"
          />
        </div>
        <div class="space-y-3 mb-4">
          <div v-for="field in costFields" :key="field.key">
            <label class="block text-xs font-semibold text-gray-500 mb-1">{{ field.label }}</label>
            <div class="relative">
              <input
                v-model="costs[field.key]"
                type="number"
                placeholder="0"
                class="kawaii-input w-full text-sm pr-6"
                @input="recalc"
              />
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-gray-400">{{ t('auto_', 'đ') }}</span>
            </div>
          </div>
        </div>
        <!-- Total display -->
        <div class="bg-pink-50 rounded-xl p-3 mb-3">
          <div class="flex justify-between items-center mb-1">
            <span class="text-xs font-semibold text-gray-600">{{ t('auto_t_ng_chi_ph_') }}</span>
            <span class="text-base font-extrabold text-pink-600">{{ formattedTotal }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-xs font-semibold text-gray-600">{{ t('auto_cpa__chi_ph____kh_ch_digital_') }}</span>
            <span class="text-sm font-bold text-gray-700">{{ formattedCPA }}</span>
          </div>
        </div>
        <button class="kawaii-btn-primary w-full py-2.5 text-sm font-semibold">
          {{ t('auto_l_u_chi_ph', '💾 Lưu Chi Phí') }}
        </button>
      </div>

      <!-- Campaign Table -->
      <div class="col-span-2 kawaii-card overflow-hidden">
        <div class="px-5 py-4 border-b border-gray-100">
          <h2 class="text-base font-bold text-gray-800">{{ t('auto_b_ng_chi_n_d_ch') }}</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th
                  v-for="col in campaignColumns"
                  :key="col"
                  class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap"
                >{{ col }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr
                v-for="(row, i) in campaigns"
                :key="i"
                class="hover:bg-orange-50 transition-colors"
              >
                <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ row.code }}</td>
                <td class="px-4 py-3 font-medium text-gray-800 whitespace-nowrap">{{ row.name }}</td>
                <td class="px-4 py-3 text-gray-500 whitespace-nowrap">{{ row.date }}</td>
                <td class="px-4 py-3">
                  <span class="px-2 py-0.5 rounded-full text-xs font-semibold" :class="row.typeBadge">{{ row.type }}</span>
                </td>
                <td class="px-4 py-3 text-center font-semibold text-gray-700">{{ row.guests }}</td>
                <td class="px-4 py-3 text-right font-semibold text-gray-800 whitespace-nowrap">{{ row.revenue }}</td>
                <td class="px-4 py-3 text-right text-gray-600 whitespace-nowrap">{{ row.cost }}</td>
                <td class="px-4 py-3 text-right font-bold" :class="row.cpaClass">{{ row.cpa }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Event Revenue Extraction -->
    <div class="kawaii-card p-5">
      <h2 class="text-base font-bold text-gray-800 mb-4">{{ t('auto_tr_ch_xu_t_doanh_thu_theo_s__k') }}</h2>
      <div class="flex flex-wrap items-end gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 mb-1">{{ t('auto_t__ng_y') }}</label>
          <input v-model="dateFrom" type="date" class="kawaii-input text-sm" />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 mb-1">{{ t('auto___n_ng_y') }}</label>
          <input v-model="dateTo" type="date" class="kawaii-input text-sm" />
        </div>
        <button
          class="kawaii-btn-primary px-5 py-2.5 text-sm font-semibold"
          @click="showResult = true"
        >
          📊 Xem Doanh Thu
        </button>
        <button
          class="kawaii-btn-ghost px-4 py-2.5 text-sm"
          @click="showResult = false"
        >
          {{ t('auto_x_a', 'Xóa') }}
        </button>
      </div>
      <!-- Result display -->
      <transition name="fade">
        <div v-if="showResult" class="mt-5 bg-gradient-to-r from-pink-50 to-orange-50 rounded-2xl p-5 border border-pink-100">
          <p class="text-xs font-semibold text-gray-500 mb-2 uppercase tracking-wider">{{ t('auto_k_t_qu_') }}</p>
          <div class="flex flex-wrap gap-8 items-center">
            <div>
              <p class="text-xs text-gray-500">{{ t('auto_ng_y_15_16_06_2026') }}</p>
              <p class="text-2xl font-extrabold text-gray-800 mt-1">34,200,000<span class="text-base font-normal text-gray-500">{{ t('auto_', 'đ') }}</span></p>
              <p class="text-xs text-green-600 font-medium mt-0.5">{{ t('auto___t_ng_doanh_thu_k__ch_n') }}</p>
            </div>
            <div class="w-px h-12 bg-pink-200"></div>
            <div>
              <p class="text-xs text-gray-500">{{ t('auto_t_ng_kh_ch') }}</p>
              <p class="text-2xl font-extrabold text-gray-800 mt-1">186</p>
              <p class="text-xs text-gray-400 font-medium mt-0.5">{{ t('auto_l__t_gh__th_m') }}</p>
            </div>
            <div class="w-px h-12 bg-pink-200"></div>
            <div>
              <p class="text-xs text-gray-500">{{ t('auto_chi_ti_u_tb___kh_ch') }}</p>
              <p class="text-2xl font-extrabold text-pink-600 mt-1">183,871<span class="text-base font-normal text-pink-400">{{ t('auto_', 'đ') }}</span></p>
            </div>
          </div>
        </div>
      </transition>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted } from 'vue'
import { useMarketing } from '@/composables/useMarketing'

const { listForPeriod } = useMarketing()

const loading = ref(true)
const selectedMonth = ref('2026-06')
const dateFrom = ref('2026-06-15')
const dateTo = ref('2026-06-16')
const showResult = ref(false)

const campaigns = ref<any[]>([])

const channels = [
  {
    icon: '🗺️',
    name: 'Google Map',
    guests: 89,
    pct: '35.9%',
    revenue: '4,450,000đ',
    borderColor: 'border-l-4 border-blue-400',
    pillClass: 'bg-blue-100 text-blue-700',
    glowColor: 'bg-blue-400',
  },
  {
    icon: '💙',
    name: 'Facebook',
    guests: 67,
    pct: '27.0%',
    revenue: '3,350,000đ',
    borderColor: 'border-l-4 border-indigo-400',
    pillClass: 'bg-indigo-100 text-indigo-700',
    glowColor: 'bg-indigo-400',
  },
  {
    icon: '🎵',
    name: 'TikTok',
    guests: 52,
    pct: '20.9%',
    revenue: '2,600,000đ',
    borderColor: 'border-l-4 border-purple-400',
    pillClass: 'bg-purple-100 text-purple-700',
    glowColor: 'bg-purple-400',
  },
  {
    icon: '💬',
    name: 'Zalo OA',
    guests: 31,
    pct: '12.5%',
    revenue: '1,550,000đ',
    borderColor: 'border-l-4 border-teal-400',
    pillClass: 'bg-teal-100 text-teal-700',
    glowColor: 'bg-teal-400',
  },
  {
    icon: '👤',
    name: 'Người quen giới thiệu',
    guests: 9,
    pct: '3.6%',
    revenue: '450,000đ',
    borderColor: 'border-l-4 border-gray-300',
    pillClass: 'bg-gray-100 text-gray-600',
    glowColor: 'bg-gray-300',
  },
]

const costFields = [
  { key: 'fb', label: 'FB Ads (đ)' },
  { key: 'tiktok', label: 'TikTok Ads (đ)' },
  { key: 'google', label: 'Google Ads (đ)' },
  { key: 'other', label: 'Khác (đ)' },
]

const costs = ref<Record<string, number>>({ fb: 5000000, tiktok: 3000000, google: 2000000, other: 500000 })

const totalCost = computed(() => Object.values(costs.value).reduce((a, b) => Number(a) + Number(b), 0))
const digitalGuests = computed(() => 89 + 67 + 52 + 31) // Google + FB + TikTok + Zalo
const cpa = computed(() => Math.round(totalCost.value / digitalGuests.value))

const formattedTotal = computed(() => totalCost.value.toLocaleString('vi-VN') + 'đ')
const formattedCPA = computed(() => cpa.value.toLocaleString('vi-VN') + 'đ / khách')

function recalc() { /* reactivity handled by computed */ }

const campaignColumns = ['Mã', 'Tên Chiến Dịch', 'Ngày', 'Loại', 'Khách', 'Doanh Thu', 'Chi Phí', 'CPA']

onMounted(async () => {
  loading.value = true
  try {
    const list = await listForPeriod('2026-06-01', '2026-06-30')
    if (list && list.length > 0) {
      campaigns.value = list.map((item: any) => ({
        code: item.id?.slice(0, 8) || 'CAMP',
        name: item.platform || 'N/A',
        date: `${item.period_start} - ${item.period_end}`,
        type: item.platform,
        typeBadge: 'bg-blue-100 text-blue-700',
        guests: 0,
        revenue: '0đ',
        cost: (item.cost || 0).toLocaleString('vi-VN') + 'đ',
        cpa: 'N/A',
        cpaClass: 'text-gray-500',
      }))
    } else {
      campaigns.value = [
        {
          code: 'CAMP-001',
          name: 'Văn Phòng Tháng 6',
          date: '01–30/06',
          type: 'Email/Zalo',
          typeBadge: 'bg-teal-100 text-teal-700',
          guests: 48,
          revenue: '9,600,000đ',
          cost: '1,200,000đ',
          cpa: '25,000đ',
          cpaClass: 'text-green-600',
        },
        {
          code: 'CAMP-002',
          name: 'Kỷ Niệm 1 Năm',
          date: '15–16/06',
          type: 'Sự Kiện',
          typeBadge: 'bg-pink-100 text-pink-700',
          guests: 186,
          revenue: '34,200,000đ',
          cost: '4,500,000đ',
          cpa: '24,193đ',
          cpaClass: 'text-green-600',
        },
        {
          code: 'CAMP-003',
          name: 'Quảng cáo TikTok',
          date: '10–25/06',
          type: 'Paid Ads',
          typeBadge: 'bg-purple-100 text-purple-700',
          guests: 52,
          revenue: '10,400,000đ',
          cost: '3,000,000đ',
          cpa: '57,692đ',
          cpaClass: 'text-orange-500',
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

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s, transform 0.3s; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(-8px); }
</style>

