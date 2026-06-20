<template>
  <div class="space-y-5">
    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Danh sách đặt bàn</h1>
        <p class="text-slate-500 text-sm mt-1">Tra cứu và quản lý toàn bộ đặt bàn theo ngày.</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50 shadow-sm">
          <Download :size="16" />
          Xuất Excel
        </button>
        <button class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 shadow-sm shadow-blue-600/20">
          <Plus :size="16" />
          Tạo đặt bàn mới
        </button>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-3 flex flex-wrap items-center gap-3">
      <!-- Date Picker -->
      <div class="flex items-center gap-1 bg-slate-50 rounded-xl px-1 py-1">
        <button @click="prevDay" class="p-1.5 hover:bg-white rounded-lg transition-colors">
          <ChevronLeft :size="18" class="text-slate-600" />
        </button>
        <button
          @click="goToday"
          class="flex items-center gap-2 px-3 py-1.5 bg-white rounded-lg shadow-sm border border-slate-200"
        >
          <CalendarIcon :size="16" class="text-blue-600" />
          <span class="font-semibold text-slate-800 text-sm whitespace-nowrap">{{ formattedDate }}</span>
        </button>
        <button @click="nextDay" class="p-1.5 hover:bg-white rounded-lg transition-colors">
          <ChevronRight :size="18" class="text-slate-600" />
        </button>
      </div>

      <!-- View Switcher -->
      <div class="flex items-center bg-slate-100 rounded-xl p-1">
        <RouterLink to="/" class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-slate-500 hover:text-slate-700">
          <MapIcon :size="14" />
          Lịch
        </RouterLink>
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium bg-white text-blue-600 shadow-sm">
          <ListIcon :size="14" />
          Danh sách
        </button>
      </div>

      <!-- Search -->
      <div class="relative flex-1 min-w-[220px] max-w-xs">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" :size="16" />
        <input
          type="text"
          placeholder="Tìm tên, SĐT, mã đặt..."
          v-model="search"
          class="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
        />
      </div>

      <!-- Status Filter -->
      <div class="flex gap-1 bg-slate-50 rounded-xl p-1 overflow-x-auto">
        <button
          v-for="s in filters"
          :key="s.id"
          @click="statusFilter = s.id"
          :class="[
            'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-1.5',
            statusFilter === s.id ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
          ]"
        >
          <span 
            v-if="s.id !== 'all'" 
            :class="['w-1.5 h-1.5 rounded-full', statusFilter === s.id ? 'bg-white' : statusDotStyle[s.id]]" 
          />
          {{ s.label }} ({{ counts[s.id] || 0 }})
        </button>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <table class="w-full">
        <thead>
          <tr class="bg-slate-50 border-b border-slate-200">
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider w-[40px]">
              <input type="checkbox" class="rounded border-slate-300" />
            </th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Mã đặt</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khách hàng</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Liên hệ</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Thời gian</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khách</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Bàn</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Loại</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Nguồn</th>
            <th class="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Trạng thái</th>
            <th class="px-4 py-3 text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider w-[60px]"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-if="filteredReservations.length === 0">
            <td colspan="11" class="py-16 text-center text-slate-400 text-sm">
              Không có dữ liệu
            </td>
          </tr>
          <tr v-else v-for="r in filteredReservations" :key="r.id" class="hover:bg-slate-50/60 transition-colors group">
            <td class="px-4 py-3">
              <input type="checkbox" class="rounded border-slate-300" />
            </td>
            <td class="px-4 py-3">
              <RouterLink :to="`/order/${r.id}`" class="text-blue-600 font-mono text-xs font-semibold hover:underline">
                {{ r.id }}
              </RouterLink>
            </td>
            <td class="px-4 py-3">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
                  {{ r.customerName.charAt(r.customerName.length - 1) }}
                </div>
                <div>
                  <div class="text-sm font-semibold text-slate-800">{{ r.customerName }}</div>
                  <div v-if="r.note" class="text-[11px] text-slate-400 truncate max-w-[180px]">{{ r.note }}</div>
                </div>
              </div>
            </td>
            <td class="px-4 py-3 text-xs text-slate-600">
              <div class="flex items-center gap-1">
                <Phone :size="11" class="text-slate-400" />
                {{ r.customerPhone }}
              </div>
            </td>
            <td class="px-4 py-3">
              <span class="font-mono text-sm font-bold text-slate-800">{{ r.time }}</span>
            </td>
            <td class="px-4 py-3">
              <span class="inline-flex items-center gap-1 text-xs text-slate-700">
                <Users :size="11" class="text-slate-400" />
                {{ r.guests }}
              </span>
            </td>
            <td class="px-4 py-3">
              <span v-if="r.tables.length > 0" class="inline-flex items-center gap-1 px-2 py-0.5 bg-slate-100 rounded text-xs font-mono font-bold text-slate-700">
                <MapPin :size="10" class="text-slate-400" />
                {{ r.tables.join(', ') }}
              </span>
              <span v-else class="text-slate-300">—</span>
            </td>
            <td class="px-4 py-3">
              <span class="text-xs text-slate-600">{{ r.type || '—' }}</span>
            </td>
            <td class="px-4 py-3">
              <span class="text-xs text-slate-600">{{ r.source || '—' }}</span>
            </td>
            <td class="px-4 py-3">
              <span :class="['inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold', statusStyle[r.status]]">
                <span :class="['w-1.5 h-1.5 rounded-full', statusDotStyle[r.status]]" />
                {{ statusLabel[r.status] }}
              </span>
            </td>
            <td class="px-4 py-3 text-right">
              <RouterLink :to="`/order/${r.id}`" class="inline-flex items-center justify-center w-7 h-7 rounded-lg hover:bg-slate-100 text-slate-500 hover:text-blue-600">
                <MoreHorizontal :size="16" />
              </RouterLink>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Footer -->
      <div class="px-4 py-3 border-t border-slate-200 bg-slate-50/60 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-500">
        <span>Hiển thị <b class="text-slate-700">{{ filteredReservations.length }}</b> / {{ counts.all || 0 }} kết quả</span>
        <div class="flex items-center gap-1">
          <button class="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50 disabled:opacity-50">Trước</button>
          <button class="px-2.5 py-1 border border-slate-200 rounded-md bg-blue-600 text-white font-semibold">1</button>
          <button class="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50">2</button>
          <button class="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50">Sau</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus, List as ListIcon, Map as MapIcon, Download, Phone, Users, MapPin, MoreHorizontal } from 'lucide-vue-next'
import { reservations as allReservations } from '@/lib/mock-data'

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
}

const statusStyle: Record<string, string> = {
  Pending: 'bg-amber-100 text-amber-700',
  Arrived: 'bg-blue-100 text-blue-700',
  Dining: 'bg-emerald-100 text-emerald-700',
  Completed: 'bg-slate-200 text-slate-600',
  Cancelled: 'bg-rose-100 text-rose-700',
}

const statusDotStyle: Record<string, string> = {
  Pending: 'bg-amber-400',
  Arrived: 'bg-blue-500',
  Dining: 'bg-emerald-500',
  Completed: 'bg-slate-400',
  Cancelled: 'bg-rose-400',
}

const filters = [
  { id: 'all', label: 'Tất cả' },
  { id: 'Pending', label: 'Chờ đến' },
  { id: 'Arrived', label: 'Đã đến' },
  { id: 'Dining', label: 'Đang dùng' },
  { id: 'Completed', label: 'Hoàn tất' },
  { id: 'Cancelled', label: 'Đã hủy' },
]

function formatDate(date: Date) {
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yyyy = date.getFullYear()
  const dow = ['CN', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'][date.getDay()]
  return `${dow}, ${dd}/${mm}/${yyyy}`
}

function toDateStr(date: Date) {
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yyyy = date.getFullYear()
  return `${yyyy}-${mm}-${dd}`
}

// Reactivity
const selectedDate = ref(new Date(2026, 5, 18))
const search = ref('')
const statusFilter = ref('all')

const dateStr = computed(() => toDateStr(selectedDate.value))
const formattedDate = computed(() => formatDate(selectedDate.value))

const filteredReservations = computed(() => {
  return allReservations
    .filter(r => r.date === dateStr.value)
    .filter(r => statusFilter.value === 'all' || r.status === statusFilter.value)
    .filter(r =>
      !search.value ||
      r.customerName.toLowerCase().includes(search.value.toLowerCase()) ||
      r.id.toLowerCase().includes(search.value.toLowerCase()) ||
      r.customerPhone.includes(search.value)
    )
    .sort((a, b) => a.time.localeCompare(b.time))
})

const counts = computed(() => {
  const c: Record<string, number> = { all: 0 }
  for (const r of allReservations.filter(r => r.date === dateStr.value)) {
    c.all++
    c[r.status] = (c[r.status] || 0) + 1
  }
  return c
})

const prevDay = () => {
  const d = selectedDate.value
  selectedDate.value = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1)
}
const nextDay = () => {
  const d = selectedDate.value
  selectedDate.value = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1)
}
const goToday = () => {
  selectedDate.value = new Date(2026, 5, 18)
}
</script>
