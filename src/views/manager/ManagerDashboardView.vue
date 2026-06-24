<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div v-if="loading" class="flex h-64 items-center justify-center text-gray-500 font-semibold">
      Đang tải dữ liệu...
    </div>
    <div v-else>
      <!-- Page Header -->
      <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">🍜 Bảng Điều Khiển</h1>
        <p class="text-sm text-gray-500 mt-1">Thứ 6, 20/06/2026 · Cập nhật lúc 15:49</p>
      </div>
      <div class="flex items-center gap-3">
        <span class="inline-flex items-center gap-1.5 rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700">
          <span class="h-2 w-2 rounded-full bg-green-500 animate-pulse"></span>
          Đang hoạt động
        </span>
        <button class="kawaii-btn-ghost text-sm">⚙ Cài Đặt</button>
      </div>
    </div>

    <!-- Alert Banner: KPI < 80% -->
    <div class="mb-6 flex items-center gap-3 rounded-2xl border border-orange-200 bg-orange-50 px-5 py-4 shadow-sm">
      <span class="text-2xl">⚠️</span>
      <div class="flex-1">
        <p class="font-semibold text-orange-800">KPI Tuần đang ở mức 74.4% — Cần theo dõi</p>
        <p class="text-xs text-orange-600 mt-0.5">Doanh thu tuần này thấp hơn mục tiêu 22,600,000đ. Hãy kiểm tra các ca chiều &amp; tối.</p>
      </div>
      <button class="rounded-xl bg-orange-100 px-4 py-1.5 text-xs font-semibold text-orange-700 hover:bg-orange-200 transition-colors">
        Xem Chi Tiết
      </button>
    </div>

    <!-- KPI / KGI Progress Section -->
    <div class="mb-6 grid grid-cols-1 gap-5 sm:grid-cols-3">
      <!-- KPI Ngày -->
      <div class="kawaii-card kawaii-shadow p-6 flex flex-col items-center relative overflow-hidden">
        <div class="absolute top-0 right-0 h-24 w-24 rounded-full bg-pink-50 -translate-y-8 translate-x-8 opacity-60"></div>
        <p class="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-4">KPI Ngày</p>
        <div class="relative">
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="50" fill="none" stroke="#F3F4F6" stroke-width="10"/>
            <circle
              cx="60" cy="60" r="50" fill="none"
              stroke="url(#kpiDay)" stroke-width="10"
              stroke-linecap="round"
              stroke-dasharray="259.18"
              stroke-dashoffset="44.84"
              transform="rotate(-90 60 60)"
            />
            <defs>
              <linearGradient id="kpiDay" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#FF7B89"/>
                <stop offset="100%" stop-color="#FF9FA9"/>
              </linearGradient>
            </defs>
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span class="text-2xl font-bold text-gray-800">{{ kpiDayPct }}%</span>
            <span class="text-xs text-green-500 font-semibold">✓ Đạt</span>
          </div>
        </div>
        <div class="mt-4 text-center space-y-1">
          <p class="text-xs text-gray-500">Mục tiêu: <span class="font-semibold text-gray-700">{{ kpiDayTarget.toLocaleString('vi-VN') }}đ</span></p>
          <p class="text-xs text-gray-500">Thực hiện: <span class="font-bold text-pink-500">{{ revenue.toLocaleString('vi-VN') }}đ</span></p>
        </div>
        <div class="mt-3 w-full rounded-full bg-gray-100 h-1.5">
          <div class="h-1.5 rounded-full kawaii-gradient" :style="{ width: kpiDayPct + '%' }"></div>
        </div>
      </div>

      <!-- KPI Tuần -->
      <div class="kawaii-card kawaii-shadow p-6 flex flex-col items-center relative overflow-hidden">
        <div class="absolute top-0 right-0 h-24 w-24 rounded-full bg-orange-50 -translate-y-8 translate-x-8 opacity-60"></div>
        <p class="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-4">KPI Tuần</p>
        <div class="relative">
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="50" fill="none" stroke="#F3F4F6" stroke-width="10"/>
            <circle
              cx="60" cy="60" r="50" fill="none"
              stroke="url(#kpiWeek)" stroke-width="10"
              stroke-linecap="round"
              stroke-dasharray="259.18"
              stroke-dashoffset="66.49"
              transform="rotate(-90 60 60)"
            />
            <defs>
              <linearGradient id="kpiWeek" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#F97316"/>
                <stop offset="100%" stop-color="#FB923C"/>
              </linearGradient>
            </defs>
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span class="text-2xl font-bold text-gray-800">74.4%</span>
            <span class="text-xs text-orange-500 font-semibold">⚠ Chú ý</span>
          </div>
        </div>
        <div class="mt-4 text-center space-y-1">
          <p class="text-xs text-gray-500">Mục tiêu: <span class="font-semibold text-gray-700">90,000,000đ</span></p>
          <p class="text-xs text-gray-500">Thực hiện: <span class="font-bold text-orange-500">67,000,000đ</span></p>
        </div>
        <div class="mt-3 w-full rounded-full bg-gray-100 h-1.5">
          <div class="h-1.5 rounded-full bg-gradient-to-r from-orange-400 to-orange-300" style="width: 74.4%"></div>
        </div>
      </div>

      <!-- KGI Tháng -->
      <div class="kawaii-card kawaii-shadow p-6 flex flex-col items-center relative overflow-hidden">
        <div class="absolute top-0 right-0 h-24 w-24 rounded-full bg-purple-50 -translate-y-8 translate-x-8 opacity-60"></div>
        <p class="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-4">KGI Tháng</p>
        <div class="relative">
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="50" fill="none" stroke="#F3F4F6" stroke-width="10"/>
            <circle
              cx="60" cy="60" r="50" fill="none"
              stroke="url(#kgiMonth)" stroke-width="10"
              stroke-linecap="round"
              stroke-dasharray="259.18"
              stroke-dashoffset="116.63"
              transform="rotate(-90 60 60)"
            />
            <defs>
              <linearGradient id="kgiMonth" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#A855F7"/>
                <stop offset="100%" stop-color="#C084FC"/>
              </linearGradient>
            </defs>
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span class="text-2xl font-bold text-gray-800">55%</span>
            <span class="text-xs text-purple-500 font-semibold">½ Tháng</span>
          </div>
        </div>
        <div class="mt-4 text-center space-y-1">
          <p class="text-xs text-gray-500">Mục tiêu: <span class="font-semibold text-gray-700">360,000,000đ</span></p>
          <p class="text-xs text-gray-500">Thực hiện: <span class="font-bold text-purple-500">198,000,000đ</span></p>
        </div>
        <div class="mt-3 w-full rounded-full bg-gray-100 h-1.5">
          <div class="h-1.5 rounded-full bg-gradient-to-r from-purple-500 to-purple-300" style="width: 55%"></div>
        </div>
      </div>
    </div>

    <!-- Quick Stats Row -->
    <div class="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
      <!-- Khách Hôm Nay -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-3 -top-3 text-4xl opacity-10">👥</div>
        <div class="flex items-center justify-between mb-2">
          <div class="rounded-xl bg-pink-100 p-2.5">
            <span class="text-lg">👥</span>
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
            +12%
          </span>
        </div>
        <p class="text-3xl font-bold text-gray-800 mt-2">{{ covers }}</p>
        <p class="text-xs font-medium text-gray-400 mt-0.5">Khách Hôm Nay</p>
        <div class="mt-3 flex gap-2 text-xs">
          <span class="rounded-lg bg-blue-50 px-2 py-1 text-blue-600 font-semibold">🇻🇳 210</span>
          <span class="rounded-lg bg-green-50 px-2 py-1 text-green-600 font-semibold">🌍 38</span>
        </div>
      </div>

      <!-- Doanh Thu Hôm Nay -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-3 -top-3 text-4xl opacity-10">💰</div>
        <div class="flex items-center justify-between mb-2">
          <div class="rounded-xl bg-green-100 p-2.5">
            <span class="text-lg">💰</span>
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
            +8.3%
          </span>
        </div>
        <p class="text-2xl font-bold text-gray-800 mt-2">{{ revenue.toLocaleString('vi-VN') }}<span class="text-base text-gray-500">đ</span></p>
        <p class="text-xs font-medium text-gray-400 mt-0.5">Doanh Thu Hôm Nay</p>
        <div class="mt-3">
          <div class="h-1 w-full rounded-full bg-gray-100">
            <div class="h-1 rounded-full kawaii-gradient" :style="{ width: kpiDayPct + '%' }"></div>
          </div>
          <p class="text-xs text-gray-400 mt-1">{{ kpiDayPct }}% mục tiêu ngày</p>
        </div>
      </div>

      <!-- Avg Check -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-3 -top-3 text-4xl opacity-10">🧾</div>
        <div class="flex items-center justify-between mb-2">
          <div class="rounded-xl bg-yellow-100 p-2.5">
            <span class="text-lg">🧾</span>
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-gray-500 bg-gray-100 rounded-full px-2 py-0.5">
            ─ 0%
          </span>
        </div>
        <p class="text-2xl font-bold text-gray-800 mt-2">{{ Math.round(avgCheck).toLocaleString('vi-VN') }}<span class="text-base text-gray-500">đ</span></p>
        <p class="text-xs font-medium text-gray-400 mt-0.5">Trung Bình / Khách</p>
        <div class="mt-3">
          <p class="text-xs text-gray-400">Mục tiêu: 55,000đ/khách</p>
        </div>
      </div>

      <!-- Repeater Rate -->
      <div class="kawaii-card kawaii-shadow p-5 relative overflow-hidden">
        <div class="absolute -right-3 -top-3 text-4xl opacity-10">🔄</div>
        <div class="flex items-center justify-between mb-2">
          <div class="rounded-xl bg-purple-100 p-2.5">
            <span class="text-lg">🔄</span>
          </div>
          <span class="inline-flex items-center gap-1 text-xs font-semibold text-green-600 bg-green-50 rounded-full px-2 py-0.5">
            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
            +5%
          </span>
        </div>
        <p class="text-3xl font-bold text-gray-800 mt-2">34<span class="text-base text-gray-500">%</span></p>
        <p class="text-xs font-medium text-gray-400 mt-0.5">Tỉ Lệ Khách Quay Lại</p>
        <div class="mt-3">
          <div class="h-1 w-full rounded-full bg-gray-100">
            <div class="h-1 rounded-full bg-gradient-to-r from-purple-500 to-purple-300" style="width: 34%"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Bottom Row: Revenue by Time + Reservation Rate -->
    <div class="grid grid-cols-1 gap-5 lg:grid-cols-5">
      <!-- Revenue by Time of Day -->
      <div class="kawaii-card kawaii-shadow p-6 lg:col-span-3">
        <div class="mb-5 flex items-center justify-between">
          <div>
            <h2 class="text-base font-bold text-gray-800">📊 Doanh Thu Theo Ca</h2>
            <p class="text-xs text-gray-400 mt-0.5">Phân bổ doanh thu trong ngày hôm nay</p>
          </div>
          <select class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-1.5 text-xs text-gray-600 focus:outline-none">
            <option>Hôm nay</option>
            <option>Hôm qua</option>
            <option>7 ngày qua</option>
          </select>
        </div>

        <div class="space-y-4">
          <!-- Sáng -->
          <div class="group">
            <div class="flex items-center justify-between mb-1.5">
              <div class="flex items-center gap-2">
                <span class="text-base">🌅</span>
                <span class="text-sm font-semibold text-gray-700">Sáng</span>
                <span class="text-xs text-gray-400">6h – 11h</span>
              </div>
              <span class="text-sm font-bold text-gray-800">2,100,000đ</span>
            </div>
            <div class="relative h-8 rounded-xl bg-gray-100 overflow-hidden">
              <div
                class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-yellow-300 to-yellow-400 transition-all duration-700 flex items-center justify-end pr-3"
                style="width: 28.7%"
              >
                <span class="text-xs font-bold text-yellow-800">28.7%</span>
              </div>
            </div>
          </div>

          <!-- Trưa -->
          <div class="group">
            <div class="flex items-center justify-between mb-1.5">
              <div class="flex items-center gap-2">
                <span class="text-base">☀️</span>
                <span class="text-sm font-semibold text-gray-700">Trưa</span>
                <span class="text-xs text-gray-400">11h – 14h</span>
              </div>
              <span class="text-sm font-bold text-gray-800">4,800,000đ</span>
            </div>
            <div class="relative h-8 rounded-xl bg-gray-100 overflow-hidden">
              <div
                class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-orange-400 to-orange-500 transition-all duration-700 flex items-center justify-end pr-3"
                style="width: 65.7%"
              >
                <span class="text-xs font-bold text-white">65.7%</span>
              </div>
            </div>
          </div>

          <!-- Chiều -->
          <div class="group">
            <div class="flex items-center justify-between mb-1.5">
              <div class="flex items-center gap-2">
                <span class="text-base">🌤</span>
                <span class="text-sm font-semibold text-gray-700">Chiều</span>
                <span class="text-xs text-gray-400">14h – 17h</span>
              </div>
              <span class="text-sm font-bold text-gray-800">1,200,000đ</span>
            </div>
            <div class="relative h-8 rounded-xl bg-gray-100 overflow-hidden">
              <div
                class="absolute left-0 top-0 h-full rounded-xl bg-gradient-to-r from-sky-300 to-sky-400 transition-all duration-700 flex items-center justify-end pr-3"
                style="width: 16.4%"
              >
              </div>
              <span class="absolute left-[18%] top-1/2 -translate-y-1/2 text-xs font-bold text-sky-600">16.4%</span>
            </div>
          </div>

          <!-- Tối -->
          <div class="group">
            <div class="flex items-center justify-between mb-1.5">
              <div class="flex items-center gap-2">
                <span class="text-base">🌙</span>
                <span class="text-sm font-semibold text-gray-700">Tối</span>
                <span class="text-xs text-gray-400">17h – 22h</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-xs font-semibold text-pink-500 bg-pink-50 rounded-full px-2 py-0.5">🔥 Cao nhất</span>
                <span class="text-sm font-bold text-gray-800">7,300,000đ</span>
              </div>
            </div>
            <div class="relative h-8 rounded-xl bg-gray-100 overflow-hidden">
              <div
                class="absolute left-0 top-0 h-full rounded-xl kawaii-gradient transition-all duration-700 flex items-center justify-end pr-3"
                style="width: 100%"
              >
                <span class="text-xs font-bold text-white">100%</span>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-5 pt-4 border-t border-gray-100 flex items-center justify-between text-xs text-gray-400">
          <span>Tổng doanh thu hôm nay: <strong class="text-gray-700">15,400,000đ</strong></span>
          <span>Ca tối chiếm <strong class="text-pink-500">47.4%</strong></span>
        </div>
      </div>

      <!-- Reservation Rate & Extra Info -->
      <div class="lg:col-span-2 flex flex-col gap-5">
        <!-- Reservation Rate -->
        <div class="kawaii-card kawaii-shadow p-6 flex-1">
          <h2 class="text-base font-bold text-gray-800 mb-1">🗓 Tỉ Lệ Đặt Bàn</h2>
          <p class="text-xs text-gray-400 mb-5">Đặt trước vs walk-in hôm nay</p>

          <!-- Segmented bar -->
          <div class="relative h-10 w-full rounded-2xl overflow-hidden flex">
            <div
              class="kawaii-gradient h-full flex items-center justify-center text-white text-sm font-bold transition-all"
              style="width: 68%"
            >
              68%
            </div>
            <div
              class="bg-gray-200 h-full flex items-center justify-center text-gray-600 text-sm font-bold flex-1 transition-all"
            >
              32%
            </div>
          </div>

          <div class="mt-4 flex justify-between text-xs">
            <div class="flex items-center gap-2">
              <div class="h-3 w-3 rounded-full kawaii-gradient"></div>
              <span class="font-semibold text-gray-600">Đặt Trước</span>
              <span class="font-bold text-gray-800">68%</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="h-3 w-3 rounded-full bg-gray-300"></div>
              <span class="font-semibold text-gray-600">Walk-in</span>
              <span class="font-bold text-gray-800">32%</span>
            </div>
          </div>

          <div class="mt-5 grid grid-cols-2 gap-3">
            <div class="rounded-2xl bg-pink-50 p-3 text-center">
              <p class="text-xl font-bold text-pink-500">169</p>
              <p class="text-xs text-pink-400 mt-0.5">Đặt Trước</p>
            </div>
            <div class="rounded-2xl bg-gray-50 p-3 text-center">
              <p class="text-xl font-bold text-gray-600">79</p>
              <p class="text-xs text-gray-400 mt-0.5">Walk-in</p>
            </div>
          </div>
        </div>

        <!-- Table Status Summary -->
        <div class="kawaii-card kawaii-shadow p-6">
          <h2 class="text-base font-bold text-gray-800 mb-4">🪑 Trạng Thái Bàn</h2>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="h-2.5 w-2.5 rounded-full bg-green-500"></div>
                <span class="text-sm text-gray-600">Đang phục vụ</span>
              </div>
              <span class="font-bold text-gray-800">8 bàn</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="h-2.5 w-2.5 rounded-full bg-gray-300"></div>
                <span class="text-sm text-gray-600">Trống</span>
              </div>
              <span class="font-bold text-gray-800">4 bàn</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                <span class="text-sm text-gray-600">Đã đặt trước</span>
              </div>
              <span class="font-bold text-gray-800">3 bàn</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                <span class="text-sm text-gray-600">Bảo trì</span>
              </div>
              <span class="font-bold text-gray-800">1 bàn</span>
            </div>
          </div>
          <div class="mt-4 pt-3 border-t border-gray-100">
            <div class="flex justify-between text-xs text-gray-400">
              <span>Tổng: 16 bàn</span>
              <span class="font-semibold text-green-600">Công suất: 75%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useReport } from '@/composables/useReport'
import { useKPI } from '@/composables/useKPI'

const { todayHeadline } = useReport()
const { listCurrent } = useKPI()

const loading = ref(true)

const revenue = ref(0)
const covers = ref(0)

const avgCheck = computed(() => covers.value > 0 ? revenue.value / covers.value : 0)

const kpiDayTarget = ref(15000000)
const kpiDayPct = computed(() => Math.min(Math.round((revenue.value / kpiDayTarget.value) * 100), 100))

onMounted(async () => {
  loading.value = true
  try {
    const [headline, currentKPIs] = await Promise.all([
      todayHeadline(),
      listCurrent(new Date().toISOString().slice(0, 10), new Date().toISOString().slice(0, 10))
    ])
    
    revenue.value = headline.revenue
    covers.value = headline.covers
    
    // Attempt to override target if available
    const revKpi = currentKPIs.find((k: any) => k.metric_key === 'revenue')
    if (revKpi && revKpi.target_value) {
      kpiDayTarget.value = revKpi.target_value
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>
