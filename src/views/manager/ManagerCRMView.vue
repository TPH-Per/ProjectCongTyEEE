<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      Đang tải dữ liệu...
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">{{ t('auto_qu_n_l__kh_ch_h_ng__crm_') }}</h1>
      <p class="text-sm text-gray-500 mt-1">{{ t('auto_t_ng_quan_to_n_th_i_gian___c_p') }}</p>
    </div>

    <!-- Summary Row -->
    <div class="grid grid-cols-4 gap-4 mb-6">
      <div
        v-for="stat in summaryStats"
        :key="stat.label"
        class="kawaii-card p-5"
      >
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">{{ stat.label }}</p>
        <p class="text-2xl font-extrabold" :class="stat.valueColor">{{ stat.value }}</p>
        <p v-if="stat.sub" class="text-xs mt-1 font-medium" :class="stat.subColor">{{ stat.sub }}</p>
      </div>
    </div>

    <!-- Repeat Rate + Channel Breakdown -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <!-- SVG Ring -->
      <div class="kawaii-card p-6 flex flex-col items-center justify-center">
        <p class="text-sm font-bold text-gray-600 mb-4">{{ t('auto_kh_ch_quay_l_i') }}</p>
        <div class="relative w-40 h-40">
          <svg class="w-40 h-40 -rotate-90" viewBox="0 0 160 160">
            <!-- Background ring -->
            <circle cx="80" cy="80" r="62" fill="none" stroke="#F3F4F6" stroke-width="16" />
            <!-- Progress ring: circumference = 2π×62 ≈ 389.6 -->
            <circle
              cx="80" cy="80" r="62" fill="none"
              stroke="#FF7B89"
              stroke-width="16"
              stroke-linecap="round"
              stroke-dasharray="389.6"
              :stroke-dashoffset="389.6 * (1 - 0.34)"
            />
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span class="text-3xl font-extrabold text-gray-800">34%</span>
            <span class="text-xs text-gray-400 font-medium">repeater</span>
          </div>
        </div>
        <div class="mt-4 flex gap-4 text-xs text-gray-500">
          <div class="flex items-center gap-1.5">
            <span class="w-3 h-3 rounded-full inline-block" style="background:#FF7B89"></span>
            Quay lại
          </div>
          <div class="flex items-center gap-1.5">
            <span class="w-3 h-3 rounded-full inline-block bg-gray-200"></span>
            Lần đầu
          </div>
        </div>
      </div>

      <!-- Channel Breakdown bars -->
      <div class="kawaii-card p-5">
        <h2 class="text-sm font-bold text-gray-800 mb-4">{{ t('auto_k_nh_ti_p_c_n__to_n_th_i_gian_') }}</h2>
        <div class="space-y-3">
          <div v-for="ch in channelBars" :key="ch.label">
            <div class="flex justify-between items-center mb-1">
              <span class="text-xs text-gray-600">{{ ch.icon }} {{ ch.label }}</span>
              <span class="text-xs font-bold text-gray-700">{{ ch.pct }}%</span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-2">
              <div
                class="h-2 rounded-full"
                :style="{ width: ch.pct + '%', backgroundColor: ch.color }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Demographics by Age -->
      <div class="kawaii-card p-5">
        <h2 class="text-sm font-bold text-gray-800 mb-4">{{ t('auto____tu_i_kh_ch_h_ng') }}</h2>
        <div class="space-y-3">
          <div v-for="age in ageBars" :key="age.label">
            <div class="flex justify-between items-center mb-1">
              <span class="text-xs font-semibold text-gray-700">{{ age.label }}</span>
              <span class="text-xs font-bold text-gray-700">{{ age.pct }}%</span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3">
              <div
                class="h-3 rounded-full transition-all duration-700"
                :style="{ width: age.pct + '%' }"
                :class="age.barClass"
              ></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Business Use Tags Filter + Customer Table -->
    <div class="kawaii-card overflow-hidden">
      <div class="px-5 py-4 border-b border-gray-100">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 class="text-base font-bold text-gray-800">{{ t('auto_danh_s_ch_kh_ch_h_ng') }}</h2>
            <p class="text-xs text-gray-400 mt-0.5">{{ t('auto_1_240_kh_ch____ang_hi_n_th__6') }}</p>
          </div>
          <!-- Search -->
          <div class="relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Tìm theo SĐT hoặc tên..."
              class="kawaii-input pl-8 text-sm w-64"
            />
          </div>
        </div>
        <!-- Filter pills -->
        <div class="flex gap-2 mt-3 flex-wrap">
          <button
            v-for="tag in businessTags"
            :key="tag"
            class="px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all duration-150"
            :class="activeTag === tag
              ? 'kawaii-gradient text-white kawaii-shadow'
              : 'bg-gray-100 text-gray-600 hover:bg-pink-50 hover:text-pink-600'"
            @click="activeTag = tag"
          >
            {{ tag }}
          </button>
        </div>
      </div>
      <!-- Table -->
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th
                v-for="col in crmColumns"
                :key="col"
                class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap"
              >{{ col }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr
              v-for="(c, i) in filteredCustomers"
              :key="i"
              class="hover:bg-orange-50 transition-colors duration-100"
            >
              <td class="px-4 py-3 font-mono text-sm text-gray-600">{{ c.phone }}</td>
              <td class="px-4 py-3 font-semibold text-gray-800 whitespace-nowrap">{{ c.name }}</td>
              <td class="px-4 py-3 text-center">
                <span class="font-bold text-gray-800">{{ c.visits }}</span>
              </td>
              <td class="px-4 py-3 text-right font-semibold text-gray-800 whitespace-nowrap">{{ c.totalSpend }}</td>
              <td class="px-4 py-3 text-gray-500 whitespace-nowrap">{{ c.lastVisit }}</td>
              <td class="px-4 py-3 whitespace-nowrap">
                <span class="flex items-center gap-1 text-xs text-gray-600">
                  <span>{{ c.channelIcon }}</span>{{ c.channel }}
                </span>
              </td>
              <td class="px-4 py-3">
                <span class="px-2 py-0.5 rounded-full text-xs font-semibold bg-purple-50 text-purple-700">{{ c.group }}</span>
              </td>
              <td class="px-4 py-3">
                <button class="text-xs text-teal-600 hover:underline font-medium">{{ t('auto____nh_n') }}</button>
              </td>
              <td class="px-4 py-3">
                <span
                  class="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold"
                  :class="c.badge === 'Repeater' ? 'bg-pink-100 text-pink-700' : 'bg-green-100 text-green-700'"
                >{{ c.badge }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <!-- Footer -->
      <div class="px-5 py-3 bg-gray-50 flex items-center justify-between">
        <p class="text-xs text-gray-400">{{ t('auto_hi_n_th__6___1_240_kh_ch') }}</p>
        <div class="flex gap-2">
          <button class="kawaii-btn-ghost text-xs px-3 py-1.5">{{ t('auto___tr__c') }}</button>
          <button class="kawaii-btn-primary text-xs px-3 py-1.5">{{ t('auto_ti_p__') }}</button>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted } from 'vue'
import { useCustomer } from '@/composables/useCustomer'

const { listVip } = useCustomer()

const loading = ref(true)
const searchQuery = ref('')
const activeTag = ref('Tất cả')

const summaryStats = [
  { label: 'Tổng Khách Hàng', value: '1,240', sub: '+87 tháng này', valueColor: 'text-gray-800', subColor: 'text-green-500' },
  { label: 'Khách Repeater', value: '421', sub: '34% tỷ lệ quay lại', valueColor: 'text-pink-600', subColor: 'text-pink-400' },
  { label: 'TB Lần Ghé / KH', value: '2.8', sub: 'lần / khách', valueColor: 'text-gray-800', subColor: 'text-gray-400' },
  { label: 'Khách Mới Tháng Này', value: '87', sub: '▲ 12% so tháng trước', valueColor: 'text-green-600', subColor: 'text-green-500' },
]

const channelBars = [
  { icon: '🗺️', label: 'Google Map', pct: 36, color: '#60A5FA' },
  { icon: '💙', label: 'Facebook', pct: 27, color: '#818CF8' },
  { icon: '🎵', label: 'TikTok', pct: 21, color: '#A78BFA' },
  { icon: '💬', label: 'Zalo OA', pct: 12, color: '#2DD4BF' },
  { icon: '👤', label: 'Người quen', pct: 4, color: '#9CA3AF' },
]

const ageBars = [
  { label: '20–30 tuổi', pct: 35, barClass: 'bg-pink-400' },
  { label: '30–40 tuổi', pct: 42, barClass: 'bg-orange-400' },
  { label: '40–50 tuổi', pct: 16, barClass: 'bg-yellow-400' },
  { label: '50+ tuổi', pct: 7, barClass: 'bg-gray-300' },
]

const businessTags = ['Tất cả', 'Cá Nhân', 'Công Ty', 'Gia Đình', 'Nhóm Bạn']

const crmColumns = ['SĐT', 'Tên', 'Lần Đến', 'Tổng Chi', 'Lần Cuối', 'Kênh', 'Nhóm', 'Zalo', 'Loại']

interface CustomerUI {
  phone: string
  name: string
  visits: number
  totalSpend: string
  lastVisit: string
  channelIcon: string
  channel: string
  group: string
  badge: 'Repeater' | 'Mới'
}

const customers = ref<CustomerUI[]>([])

onMounted(async () => {
  loading.value = true
  try {
    const vips = await listVip()
    if (vips && vips.length > 0) {
      customers.value = vips.map((c: any) => ({
        phone: c.phone || 'N/A',
        name: c.name || 'Khách Hàng',
        visits: c.visits_count || 1,
        totalSpend: (c.total_spent || 0).toLocaleString('vi-VN') + 'đ',
        lastVisit: c.last_visit_at ? new Date(c.last_visit_at).toLocaleDateString('vi-VN') : 'N/A',
        channelIcon: '👤',
        channel: 'Hệ Thống',
        group: 'Cá Nhân',
        badge: (c.visits_count || 1) > 1 ? 'Repeater' : 'Mới',
      }))
    } else {
      customers.value = [
        {
          phone: '09**654321',
          name: 'Nguyễn Thị Lan',
          visits: 8,
          totalSpend: '3,200,000đ',
          lastVisit: '18/06/2026',
          channelIcon: '🗺️',
          channel: 'Google Map',
          group: 'Công Ty',
          badge: 'Repeater',
        },
        {
          phone: '09**112233',
          name: 'Trần Minh Quân',
          visits: 5,
          totalSpend: '1,750,000đ',
          lastVisit: '17/06/2026',
          channelIcon: '🎵',
          channel: 'TikTok',
          group: 'Nhóm Bạn',
          badge: 'Repeater',
        },
        {
          phone: '09**887766',
          name: 'Phạm Thu Hương',
          visits: 1,
          totalSpend: '480,000đ',
          lastVisit: '15/06/2026',
          channelIcon: '💙',
          channel: 'Facebook',
          group: 'Cá Nhân',
          badge: 'Mới',
        },
        {
          phone: '09**445566',
          name: 'Lê Văn Bình',
          visits: 12,
          totalSpend: '5,640,000đ',
          lastVisit: '14/06/2026',
          channelIcon: '👤',
          channel: 'Người quen',
          group: 'Gia Đình',
          badge: 'Repeater',
        },
        {
          phone: '09**334455',
          name: 'Đỗ Thị Mai',
          visits: 3,
          totalSpend: '960,000đ',
          lastVisit: '12/06/2026',
          channelIcon: '💬',
          channel: 'Zalo OA',
          group: 'Cá Nhân',
          badge: 'Repeater',
        },
        {
          phone: '09**221100',
          name: 'Hoàng Đức Thắng',
          visits: 1,
          totalSpend: '620,000đ',
          lastVisit: '10/06/2026',
          channelIcon: '🗺️',
          channel: 'Google Map',
          group: 'Công Ty',
          badge: 'Mới',
        },
      ]
    }
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
})

const filteredCustomers = computed(() => {
  let list = customers.value
  if (activeTag.value !== 'Tất cả') {
    list = list.filter((c) => c.group === activeTag.value)
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(
      (c) => c.phone.includes(q) || c.name.toLowerCase().includes(q),
    )
  }
  return list
})
</script>
