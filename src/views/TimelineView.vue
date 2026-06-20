<template>
  <div class="space-y-5">
    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Lịch đặt bàn</h1>
        <p class="text-slate-500 text-sm mt-1">Theo dõi và quản lý lịch đặt bàn theo khung giờ trong ngày.</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50 shadow-sm">
          <Bell :size="16" />
          Thông báo
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
          <span class="font-semibold text-slate-800 text-sm whitespace-nowrap">{{ formatted }}</span>
        </button>
        <button @click="nextDay" class="p-1.5 hover:bg-white rounded-lg transition-colors">
          <ChevronRight :size="18" class="text-slate-600" />
        </button>
      </div>

      <!-- View Switcher -->
      <div class="flex items-center bg-slate-100 rounded-xl p-1">
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium bg-white text-blue-600 shadow-sm">
          <MapIcon :size="14" />
          Lịch
        </button>
        <RouterLink to="/list" class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-slate-500 hover:text-slate-700">
          <ListIcon :size="14" />
          Danh sách
        </RouterLink>
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

      <!-- Zone Tabs -->
      <div class="flex gap-1 bg-slate-50 rounded-xl p-1 w-full md:w-auto overflow-x-auto">
        <button
          @click="selectedTab = 'all'"
          :class="[
            'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap',
            selectedTab === 'all' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
          ]"
        >
          Tất cả ({{ totalCount }})
        </button>
        <button
          v-for="zone in zones"
          :key="zone.id"
          @click="selectedTab = zone.id"
          :class="[
            'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-1.5',
            selectedTab === zone.id ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
          ]"
        >
          <span
            class="w-2 h-2 rounded-full shrink-0"
            :style="{ backgroundColor: selectedTab === zone.id ? 'white' : zone.color }"
          />
          {{ zone.name }} ({{ zoneCounts[zone.id] || 0 }})
        </button>
      </div>
    </div>

    <!-- Timeline Grid -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div class="grid" :style="{ gridTemplateColumns: '160px repeat(4, minmax(140px, 1fr))' }">
        <!-- Header row -->
        <div class="px-4 py-3 bg-slate-50 border-b border-r border-slate-200 flex items-center">
          <span class="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khu vực</span>
        </div>
        <div v-for="slot in timeSlots" :key="slot.id" :class="[slotHeaderBg[slot.id], 'border-b border-r border-slate-200 last:border-r-0 px-3 py-3']">
          <div class="flex items-center gap-1.5 mb-0.5">
            <span :class="['w-1.5 h-1.5 rounded-full', slotDot[slot.id]]" />
            <span class="text-xs font-bold text-slate-700">{{ slot.label }}</span>
          </div>
          <div class="text-[10px] text-slate-500 font-medium">{{ slot.range }}</div>
        </div>

        <!-- Rows -->
        <template v-for="zone in filteredZones" :key="zone.id">
          <div class="contents">
            <div class="px-4 py-3 bg-slate-50/50 border-b border-r border-slate-200 flex items-center gap-2">
              <div class="w-2.5 h-2.5 rounded-full shrink-0" :style="{ backgroundColor: zone.color }" />
              <div>
                <div class="text-sm font-bold text-slate-800">{{ zone.name }}</div>
                <div class="text-[10px] text-slate-400 font-medium">{{ zoneCounts[zone.id] || 0 }} đặt bàn</div>
              </div>
            </div>
            <div
              v-for="slot in timeSlots"
              :key="slot.id"
              :class="[slotCellBg[slot.id], 'border-b border-r border-slate-100 last:border-r-0 p-2 align-top min-h-[140px]']"
            >
              <div class="flex flex-col gap-1.5 min-h-[124px]">
                <div v-if="(gridData[zone.id]?.[slot.id] || []).length === 0" class="flex-1 flex items-center justify-center min-h-[60px]">
                  <span class="text-[10px] text-slate-300 italic">—</span>
                </div>
                <template v-else>
                  <div
                    v-for="r in gridData[zone.id][slot.id]"
                    :key="r.id"
                    @click="navigateToOrder(r.id)"
                    :class="[
                      statusCardStyle[r.status].bg,
                      statusCardStyle[r.status].border,
                      'border-l-[3px] rounded-md px-2 py-1.5 cursor-pointer transition-all hover:shadow-md'
                    ]"
                  >
                    <div class="flex items-center justify-between gap-1 mb-0.5">
                      <span :class="['text-[11px] font-bold truncate leading-tight', statusCardStyle[r.status].text]">
                        {{ r.customerName }}
                      </span>
                      <span :class="['shrink-0 px-1.5 py-0.5 rounded text-[9px] font-bold leading-none', statusCardStyle[r.status].badge]">
                        {{ statusLabel[r.status] }}
                      </span>
                    </div>
                    <div class="flex items-center gap-1.5 text-[10px] text-slate-600 flex-wrap">
                      <span class="font-mono font-bold">{{ r.time }}</span>
                      <span class="text-slate-300">•</span>
                      <span>{{ r.guests}} khách</span>
                      <template v-if="r.tables.length > 0">
                        <span class="text-slate-300">•</span>
                        <span class="font-mono font-bold text-slate-700">{{ r.tables.join(',') }}</span>
                      </template>
                    </div>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus, List as ListIcon, Map as MapIcon, Bell } from 'lucide-vue-next'
import { reservations as allReservations, zones, tables } from '@/lib/mock-data'

const router = useRouter()

// Mapping code of tables to zone IDs
const tableZoneMap = new Map(tables.map(t => [t.code, t.zoneId]))

const timeSlots = [
  { id: 'morning', label: 'Sáng', range: '06:00 - 11:00', start: 6, end: 11 },
  { id: 'noon', label: 'Trưa', range: '11:00 - 14:00', start: 11, end: 14 },
  { id: 'afternoon', label: 'Chiều', range: '14:00 - 17:00', start: 14, end: 17 },
  { id: 'evening', label: 'Tối', range: '17:00 - 22:00', start: 17, end: 24 },
]

function getTimeSlot(time: string) {
  const h = parseInt(time.split(':')[0], 10)
  for (const s of timeSlots) {
    if (h >= s.start && h < s.end) return s.id
  }
  return 'evening'
}

function getReservationZoneId(tableCodes: string[]): string | null {
  for (const code of tableCodes) {
    const z = tableZoneMap.get(code)
    if (z) return z
  }
  return null
}

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

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
}

const statusCardStyle: Record<string, { bg: string; border: string; badge: string; text: string }> = {
  Pending: { bg: 'bg-amber-50', border: 'border-amber-300', badge: 'bg-amber-400 text-white', text: 'text-amber-900' },
  Arrived: { bg: 'bg-blue-50', border: 'border-blue-300', badge: 'bg-blue-500 text-white', text: 'text-blue-900' },
  Dining: { bg: 'bg-emerald-50', border: 'border-emerald-300', badge: 'bg-emerald-500 text-white', text: 'text-emerald-900' },
  Completed: { bg: 'bg-slate-50', border: 'border-slate-300', badge: 'bg-slate-400 text-white', text: 'text-slate-700' },
  Cancelled: { bg: 'bg-rose-50', border: 'border-rose-200', badge: 'bg-rose-400 text-white', text: 'text-rose-700' },
}

const slotHeaderBg: Record<string, string> = {
  morning: 'bg-amber-50',
  noon: 'bg-orange-50',
  afternoon: 'bg-sky-50',
  evening: 'bg-indigo-50',
}

const slotCellBg: Record<string, string> = {
  morning: 'bg-amber-50/30',
  noon: 'bg-orange-50/30',
  afternoon: 'bg-sky-50/30',
  evening: 'bg-indigo-50/30',
}

const slotDot: Record<string, string> = {
  morning: 'bg-amber-400',
  noon: 'bg-orange-400',
  afternoon: 'bg-sky-400',
  evening: 'bg-indigo-400',
}

// Reactivity
const selectedDate = ref(new Date(2026, 5, 18))
const selectedTab = ref('all')
const search = ref('')

const dateStr = computed(() => toDateStr(selectedDate.value))
const formatted = computed(() => formatDate(selectedDate.value))

const todayReservations = computed(() => {
  return allReservations
    .filter(r => r.date === dateStr.value && r.status !== 'Cancelled')
    .filter(r =>
      !search.value ||
      r.customerName.toLowerCase().includes(search.value.toLowerCase()) ||
      r.id.toLowerCase().includes(search.value.toLowerCase()) ||
      r.customerPhone.includes(search.value)
    )
    .sort((a, b) => a.time.localeCompare(b.time))
})

const gridData = computed(() => {
  const data: Record<string, Record<string, typeof allReservations>> = {}
  for (const zone of zones) {
    data[zone.id] = {}
    for (const slot of timeSlots) data[zone.id][slot.id] = []
  }
  for (const r of todayReservations.value) {
    const zoneId = getReservationZoneId(r.tables)
    const slot = getTimeSlot(r.time)
    if (zoneId && data[zoneId]) data[zoneId][slot].push(r)
  }
  return data
})

const zoneCounts = computed(() => {
  const counts: Record<string, number> = {}
  for (const r of todayReservations.value) {
    const zoneId = getReservationZoneId(r.tables)
    if (zoneId) counts[zoneId] = (counts[zoneId] || 0) + 1
  }
  return counts
})

const totalCount = computed(() => todayReservations.value.length)

// Date navigations
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

const filteredZones = computed(() => {
  return selectedTab.value === 'all' ? zones : zones.filter(z => z.id === selectedTab.value)
})

function navigateToOrder(reservationId: string) {
  router.push(`/order/${reservationId}`)
}
</script>
