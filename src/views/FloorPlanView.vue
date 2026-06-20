<template>
  <div class="space-y-5">
    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Sơ đồ bàn</h1>
        <p class="text-slate-500 text-sm mt-1">
          {{ mode === 'default'
            ? 'Xem tất cả các ngày theo ngày tháng — trạng thái bàn theo lịch đặt.'
            : 'Trạng thái bàn theo thời gian thực — cập nhật liên tức.' }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <div class="flex items-center bg-white rounded-xl border border-slate-200 shadow-sm p-1">
          <button
            @click="mode = 'default'"
            :class="[
              'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all',
              mode === 'default' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600'
            ]"
          >
            Theo ngày
          </button>
          <button
            @click="mode = 'realtime'"
            :class="[
              'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center gap-1.5',
              mode === 'realtime' ? 'bg-rose-500 text-white shadow-sm' : 'text-slate-600'
            ]"
          >
            <span :class="['w-1.5 h-1.5 rounded-full', mode === 'realtime' ? 'bg-white animate-pulse' : 'bg-rose-500 animate-pulse']" />
            Hiện tại
          </button>
        </div>
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

      <!-- Status Legend -->
      <div class="flex items-center gap-3 text-xs ml-auto">
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-emerald-100 border border-emerald-300" />
          <span class="font-semibold text-slate-700">{{ totalStats.available }}</span>
          <span class="text-slate-500">Trống</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-amber-100 border border-amber-300" />
          <span class="font-semibold text-slate-700">{{ totalStats.reserved }}</span>
          <span class="text-slate-500">Đã đặt</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-rose-100 border border-rose-300" />
          <span class="font-semibold text-slate-700">{{ totalStats.occupied }}</span>
          <span class="text-slate-500">Đang ngồi</span>
        </div>
      </div>
    </div>

    <!-- Main content - 2 columns: Area selector + Zone tables -->
    <div class="grid grid-cols-12 gap-5">
      <!-- Left: Area Selector Panel -->
      <div class="col-span-12 lg:col-span-4 xl:col-span-3 space-y-4">
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div class="px-4 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
            <div class="flex items-center gap-2">
              <Layers :size="15" class="text-blue-600" />
              <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Chọn khu vực</h3>
            </div>
            <span class="text-[10px] text-slate-400 font-semibold">
              {{ zones.length }} khu vực
            </span>
          </div>

          <div class="p-2">
            <button
              v-for="z in zones"
              :key="z.id"
              @click="selectedZone = z.id"
              :class="[
                'w-full text-left px-3 py-2.5 rounded-xl mb-1 transition-all flex items-center gap-3 group',
                selectedZone === z.id
                  ? 'bg-blue-50 border-2 border-blue-300 shadow-sm'
                  : 'hover:bg-slate-50 border-2 border-transparent'
              ]"
            >
              <!-- Checkbox -->
              <div
                :class="[
                  'w-5 h-5 rounded-md border-2 flex items-center justify-center shrink-0 transition-all',
                  selectedZone === z.id
                    ? 'bg-blue-600 border-blue-600'
                    : 'border-slate-300 group-hover:border-slate-400'
                ]"
              >
                <Check v-if="selectedZone === z.id" :size="12" class="text-white" :strokeWidth="3" />
              </div>

              <!-- Color dot -->
              <span
                class="w-3 h-3 rounded-full shrink-0 ring-2 ring-white"
                :style="{ backgroundColor: z.color, boxShadow: `0 0 0 2px ${z.color}30` }"
              />

              <!-- Zone name + count -->
              <div class="flex-1 min-w-0">
                <div :class="['text-sm font-semibold truncate', selectedZone === z.id ? 'text-blue-700' : 'text-slate-800']">
                  {{ z.name }}
                </div>
                <div class="text-[11px] text-slate-500 font-medium">
                  {{ zoneStats[z.id]?.total || 0 }} bàn • {{ zoneStats[z.id]?.available || 0 }} trống
                </div>
              </div>

              <!-- Status mini badges -->
              <div class="flex items-center gap-0.5 shrink-0">
                <span v-if="(zoneStats[z.id]?.available || 0) > 0" class="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded">
                  {{ zoneStats[z.id].available }}
                </span>
                <span v-if="(zoneStats[z.id]?.reserved || 0) > 0" class="text-[10px] font-bold text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded">
                  {{ zoneStats[z.id].reserved }}
                </span>
                <span v-if="(zoneStats[z.id]?.occupied || 0) > 0" class="text-[10px] font-bold text-rose-700 bg-rose-50 px-1.5 py-0.5 rounded">
                  {{ zoneStats[z.id].occupied }}
                </span>
              </div>
            </button>
          </div>
        </div>

        <!-- Selected zone summary card -->
        <div v-if="selectedZoneObj" class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div class="px-4 py-3 border-b border-slate-100 bg-slate-50/60">
            <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khu vực đang chọn</div>
          </div>
          <div class="p-4 space-y-3">
            <div class="flex items-center gap-2">
              <span
                class="w-4 h-4 rounded-full shrink-0"
                :style="{ backgroundColor: selectedZoneObj.color }"
              />
              <div class="text-base font-bold text-slate-800">{{ selectedZoneObj.name }}</div>
            </div>
            <div class="grid grid-cols-3 gap-2 text-center">
              <div class="bg-emerald-50 border border-emerald-100 rounded-lg p-2">
                <div class="text-lg font-black text-emerald-700">{{ zoneStats[selectedZoneObj.id]?.available || 0 }}</div>
                <div class="text-[10px] text-emerald-600 font-semibold uppercase">Trống</div>
              </div>
              <div class="bg-amber-50 border border-amber-100 rounded-lg p-2">
                <div class="text-lg font-black text-amber-700">{{ zoneStats[selectedZoneObj.id]?.reserved || 0 }}</div>
                <div class="text-[10px] text-amber-600 font-semibold uppercase">Đặt</div>
              </div>
              <div class="bg-rose-50 border border-rose-100 rounded-lg p-2">
                <div class="text-lg font-black text-rose-700">{{ zoneStats[selectedZoneObj.id]?.occupied || 0 }}</div>
                <div class="text-[10px] text-rose-600 font-semibold uppercase">Ngồi</div>
              </div>
            </div>
            <div class="text-xs text-slate-500 pt-1 border-t border-slate-100 flex items-center justify-between">
              <span>Tổng số bàn</span>
              <span class="font-bold text-slate-800">{{ zoneStats[selectedZoneObj.id]?.total || 0 }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Zone floor plan -->
      <div class="col-span-12 lg:col-span-8 xl:col-span-9">
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <!-- Zone header -->
          <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
            <div class="flex items-center gap-2">
              <span
                v-if="selectedZoneObj"
                class="w-3 h-3 rounded-full"
                :style="{ backgroundColor: selectedZoneObj.color }"
              />
              <h3 class="text-sm font-bold text-slate-700">
                {{ selectedZoneObj?.name || 'Khu vực' }}
              </h3>
              <span class="text-xs text-slate-400">({{ zoneTables.length }} bàn)</span>
            </div>
            <div class="text-xs text-slate-500">
              {{ formattedDate }}
            </div>
          </div>

          <!-- Floor plan canvas -->
          <div class="relative bg-gradient-to-br from-slate-50 to-slate-100 p-6 min-h-[500px]">
            <div class="absolute top-3 left-3 text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
              Khu vực chờ
            </div>
            <div class="absolute top-3 right-3 text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
              Lễ tân
            </div>

            <div v-if="zoneTables.length === 0" class="flex flex-col items-center justify-center h-[400px] text-slate-400">
              <Layers :size="32" class="mb-2 opacity-50" />
              <div class="text-sm">Khu vực này chưa có bàn nào</div>
            </div>
            <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mt-6">
              <div
                v-for="t in zoneTables"
                :key="t.id"
                @click="t.status !== 'available' && getTableReservation(t.code) ? navigateToOrder(getTableReservation(t.code)!.id) : null"
                :class="[
                  tableStatusStyle[t.status].bg,
                  tableStatusStyle[t.status].border,
                  'border-2 rounded-2xl p-3 flex flex-col items-center justify-center min-h-[120px] transition-all hover:shadow-lg cursor-pointer hover:scale-105'
                ]"
              >
                <div :class="['text-2xl font-black', tableStatusStyle[t.status].text]">{{ t.code }}</div>
                <div class="flex items-center gap-1 text-[10px] text-slate-500 mt-1">
                  <Users :size="10" /> {{ t.capacity }} chỗ
                </div>
                <span :class="['mt-1.5 px-2 py-0.5 rounded-full text-[9px] font-bold', tableStatusStyle[t.status].badge]">
                  {{ tableStatusStyle[t.status].label }}
                </span>
                
                <template v-if="getTableReservation(t.code)">
                  <div class="mt-2 text-[11px] text-slate-800 font-bold truncate w-full text-center">
                    {{ getTableReservation(t.code)!.customerName }}
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-slate-500 mt-0.5">
                    <Clock :size="9" /> {{ getTableReservation(t.code)!.time }}
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-slate-500">
                    <Users :size="9" /> {{ getTableReservation(t.code)!.guests }} khách
                  </div>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Users, Clock, Check, Layers } from 'lucide-vue-next'
import { tables as allTables, zones, reservations as allReservations } from '@/lib/mock-data'

const router = useRouter()

// Mapping table codes to reservations
const reservationByTable = computed(() => {
  const map = new Map<string, typeof allReservations[0]>()
  for (const r of allReservations) {
    if (r.status !== 'Cancelled') {
      for (const t of r.tables) {
        if (!map.has(t)) map.set(t, r)
      }
    }
  }
  return map
})

function getTableReservation(tableCode: string) {
  return reservationByTable.value.get(tableCode)
}

const tableStatusStyle: Record<string, { bg: string; border: string; text: string; label: string; badge: string }> = {
  available: { bg: 'bg-white', border: 'border-emerald-200', text: 'text-emerald-700', label: 'Trống', badge: 'bg-emerald-100 text-emerald-700' },
  reserved: { bg: 'bg-amber-50', border: 'border-amber-300', text: 'text-amber-700', label: 'Đã đặt', badge: 'bg-amber-100 text-amber-700' },
  occupied: { bg: 'bg-rose-50', border: 'border-rose-300', text: 'text-rose-700', label: 'Đang ngồi', badge: 'bg-rose-100 text-rose-700' },
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

// Reactivity
const selectedDate = ref(new Date(2026, 5, 18))
const selectedZone = ref('Z003') // Default selected: VIP area
const mode = ref<'default' | 'realtime'>('default')

const dateStr = computed(() => toDateStr(selectedDate.value))
const formattedDate = computed(() => formatDate(selectedDate.value))

// Compute table status based on date and mode
const tablesWithStatus = computed(() => {
  const reservedOnDate = new Set<string>()
  const occupiedOnDate = new Set<string>()
  for (const r of allReservations) {
    if (r.date !== dateStr.value || r.status === 'Cancelled') continue
    if (r.status === 'Pending') {
      for (const t of r.tables) reservedOnDate.add(t)
    } else if (r.status === 'Arrived' || r.status === 'Dining' || r.status === 'Completed') {
      for (const t of r.tables) occupiedOnDate.add(t)
    }
  }
  return allTables.map(t => {
    let status: 'available' | 'reserved' | 'occupied' = t.status
    if (mode.value === 'default') {
      if (occupiedOnDate.has(t.code)) status = 'occupied'
      else if (reservedOnDate.has(t.code)) status = 'reserved'
      else status = 'available'
    } else {
      status = t.status
    }
    return { ...t, status }
  })
})

// Per-zone stats
const zoneStats = computed(() => {
  const stats: Record<string, { total: number; available: number; reserved: number; occupied: number }> = {}
  for (const z of zones) {
    stats[z.id] = { total: 0, available: 0, reserved: 0, occupied: 0 }
  }
  for (const t of tablesWithStatus.value) {
    if (stats[t.zoneId]) {
      stats[t.zoneId].total++
      stats[t.zoneId][t.status]++
    }
  }
  return stats
})

const totalStats = computed(() => {
  const c = { total: 0, available: 0, reserved: 0, occupied: 0 }
  for (const t of tablesWithStatus.value) {
    c.total++
    c[t.status]++
  }
  return c
})

const selectedZoneObj = computed(() => zones.find(z => z.id === selectedZone.value))
const zoneTables = computed(() => tablesWithStatus.value.filter(t => t.zoneId === selectedZone.value))

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

function navigateToOrder(reservationId: string) {
  router.push(`/order/${reservationId}`)
}
</script>
