<template>
  <div class="space-y-5">

    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">
          <span class="mr-1">🗓️</span>{{ t('timeline.title') }}
        </h1>
        <p class="text-[hsl(var(--muted-foreground))] text-sm mt-1 font-medium">{{ t('timeline.subtitle') }}</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="kawaii-btn-ghost flex items-center gap-2 px-3 py-2 text-sm">
          <Bell :size="16" />
          {{ t('timeline.notify') }}
        </button>
        <button class="kawaii-btn-primary flex items-center gap-2 px-4 py-2 text-sm">
          <Plus :size="16" />
          {{ t('timeline.create_new') }}
        </button>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="kawaii-card p-3 flex flex-wrap items-center gap-3">
      <!-- Date Picker -->
      <div class="flex items-center gap-1 bg-[hsl(var(--muted))] rounded-2xl px-1 py-1">
        <button @click="prevDay" class="p-1.5 hover:bg-white rounded-xl transition-colors">
          <ChevronLeft :size="18" class="text-[hsl(var(--muted-foreground))]" />
        </button>
        <button
          @click="goToday"
          class="flex items-center gap-2 px-3 py-1.5 bg-white rounded-xl shadow-sm border border-[hsl(var(--border))]"
        >
          <CalendarIcon :size="16" class="text-[hsl(var(--primary))]" />
          <span class="font-extrabold text-[hsl(var(--foreground))] text-sm whitespace-nowrap">{{ formatted }}</span>
        </button>
        <button @click="nextDay" class="p-1.5 hover:bg-white rounded-xl transition-colors">
          <ChevronRight :size="18" class="text-[hsl(var(--muted-foreground))]" />
        </button>
      </div>

      <!-- View Switcher -->
      <div class="flex items-center bg-[hsl(var(--muted))] rounded-2xl p-1">
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-extrabold bg-white text-[hsl(var(--primary))] shadow-sm">
          <MapIcon :size="14" />
          {{ t('timeline.view_schedule') }}
        </button>
        <RouterLink to="/list" class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-bold text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]">
          <ListIcon :size="14" />
          {{ t('timeline.view_list') }}
        </RouterLink>
      </div>

      <!-- Search -->
      <div class="relative flex-1 min-w-[220px] max-w-xs">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-[hsl(var(--muted-foreground))]" :size="16" />
        <input
          type="text"
          :placeholder="t('timeline.search_placeholder')"
          v-model="search"
          class="kawaii-input pl-9 pr-3 py-2 text-sm"
        />
      </div>

      <!-- Zone Tabs -->
      <div class="flex gap-1 bg-[hsl(var(--muted))] rounded-2xl p-1 w-full md:w-auto overflow-x-auto">
        <button
          @click="selectedTab = 'all'"
          :class="[
            'px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all whitespace-nowrap',
            selectedTab === 'all'
              ? 'kawaii-gradient text-white shadow-sm'
              : 'text-[hsl(var(--muted-foreground))] hover:bg-white'
          ]"
        >
          {{ t('timeline.area') }} ({{ totalCount }})
        </button>
        <button
          v-for="zone in zones"
          :key="zone.id"
          @click="selectedTab = zone.id"
          :class="[
            'px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all whitespace-nowrap flex items-center gap-1.5',
            selectedTab === zone.id
              ? 'kawaii-gradient text-white shadow-sm'
              : 'text-[hsl(var(--muted-foreground))] hover:bg-white'
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
    <div class="kawaii-card overflow-hidden">
      <div class="grid" :style="{ gridTemplateColumns: '160px repeat(4, minmax(140px, 1fr))' }">
        <!-- Header row -->
        <div class="px-4 py-3 bg-[hsl(var(--muted))] border-b border-r border-[hsl(var(--border))] flex items-center">
          <span class="text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('timeline.area') }}</span>
        </div>
        <div
          v-for="slot in timeSlots"
          :key="slot.id"
          :class="[slotHeaderBg[slot.id], 'border-b border-r border-[hsl(var(--border))] last:border-r-0 px-3 py-3']"
        >
          <div class="flex items-center gap-1.5 mb-0.5">
            <span :class="['w-1.5 h-1.5 rounded-full', slotDot[slot.id]]" />
            <span class="text-xs font-extrabold text-[hsl(var(--foreground))]">{{ slot.label }}</span>
          </div>
          <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">{{ slot.range }}</div>
        </div>

        <!-- Rows -->
        <template v-for="zone in filteredZones" :key="zone.id">
          <div class="contents">
            <div class="px-4 py-3 bg-[hsl(var(--muted))]/60 border-b border-r border-[hsl(var(--border))] flex items-center gap-2">
              <div class="w-2.5 h-2.5 rounded-full shrink-0" :style="{ backgroundColor: zone.color }" />
              <div>
                <div class="text-sm font-extrabold text-[hsl(var(--foreground))]">{{ zone.name }}</div>
                <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">{{ zoneCounts[zone.id] || 0 }} {{ t('units.tables') }}</div>
              </div>
            </div>
            <div
              v-for="slot in timeSlots"
              :key="slot.id"
              :class="[slotCellBg[slot.id], 'border-b border-r border-[hsl(var(--border))]/50 last:border-r-0 p-2 align-top min-h-[140px]']"
            >
              <div class="flex flex-col gap-1.5 min-h-[124px]">
                <div
                  v-if="(gridData[zone.id]?.[slot.id] || []).length === 0"
                  class="flex-1 flex items-center justify-center min-h-[60px]"
                >
                  <span class="text-[10px] text-[hsl(var(--muted-foreground))] italic">—</span>
                </div>
                <template v-else>
                  <div
                    v-for="r in gridData[zone.id][slot.id]"
                    :key="r.id"
                    @click="navigateToOrder(r.id)"
                    :class="[
                      statusCardStyle[r.status].bg,
                      statusCardStyle[r.status].border,
                      'border-l-[3px] rounded-xl px-2.5 py-1.5 cursor-pointer transition-all hover:shadow-md'
                    ]"
                  >
                    <div class="flex items-center justify-between gap-1 mb-0.5">
                      <span :class="['text-[11px] font-extrabold truncate leading-tight', statusCardStyle[r.status].text]">
                        {{ r.customerName }}
                      </span>
                      <span :class="['shrink-0 px-1.5 py-0.5 rounded text-[9px] font-extrabold leading-none', statusCardStyle[r.status].badge]">
                        {{ t(`status.${r.status}`) }}
                      </span>
                    </div>
                    <div class="flex items-center gap-1.5 text-[10px] text-[hsl(var(--muted-foreground))] flex-wrap font-semibold">
                      <span class="font-mono font-extrabold text-[hsl(var(--foreground))]">{{ r.time }}</span>
                      <span class="text-[hsl(var(--border))]">•</span>
                      <span>{{ r.guests }} {{ t('units.guests') }}</span>
                      <template v-if="r.tables.length > 0">
                        <span class="text-[hsl(var(--border))]">•</span>
                        <span class="font-mono font-extrabold text-[hsl(var(--foreground))]">{{ r.tables.join(',') }}</span>
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
import { useI18n } from 'vue-i18n'
import {
  Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus,
  List as ListIcon, Map as MapIcon, Bell,
} from 'lucide-vue-next'
import { reservations as allReservations, zones, tables } from '@/lib/mock-data'

const router = useRouter()
const { t } = useI18n()

const tableZoneMap = new Map(tables.map(t => [t.code, t.zoneId]))

const timeSlots = computed(() => [
  { id: 'morning', label: t('timeline.morning'), range: '06:00 - 11:00', start: 6, end: 11 },
  { id: 'noon', label: t('timeline.noon'), range: '11:00 - 14:00', start: 11, end: 14 },
  { id: 'afternoon', label: t('timeline.afternoon'), range: '14:00 - 17:00', start: 14, end: 17 },
  { id: 'evening', label: t('timeline.evening'), range: '17:00 - 22:00', start: 17, end: 24 },
])

function getTimeSlot(time: string) {
  const h = parseInt(time.split(':')[0], 10)
  for (const s of timeSlots.value) {
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
  const dow = t('days.dows')[date.getDay()]
  return `${dow}, ${dd}/${mm}/${yyyy}`
}

function toDateStr(date: Date) {
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yyyy = date.getFullYear()
  return `${yyyy}-${mm}-${dd}`
}

const statusCardStyle: Record<string, { bg: string; border: string; badge: string; text: string }> = {
  Pending:   { bg: 'bg-amber-50',   border: 'border-amber-300',  badge: 'bg-amber-400 text-white',       text: 'text-amber-900' },
  Arrived:   { bg: 'bg-blue-50',    border: 'border-blue-300',   badge: 'bg-blue-500 text-white',        text: 'text-blue-900' },
  Dining:    { bg: 'bg-emerald-50', border: 'border-emerald-300', badge: 'bg-emerald-500 text-white',     text: 'text-emerald-900' },
  Completed: { bg: 'bg-slate-50',   border: 'border-slate-300',  badge: 'bg-slate-400 text-white',       text: 'text-slate-700' },
  Cancelled: { bg: 'bg-rose-50',    border: 'border-rose-200',   badge: 'bg-rose-400 text-white',        text: 'text-rose-700' },
}

const slotHeaderBg: Record<string, string> = {
  morning:   'bg-amber-50',
  noon:      'bg-orange-50',
  afternoon: 'bg-sky-50',
  evening:   'bg-[hsl(var(--primary))]/8',
}

const slotCellBg: Record<string, string> = {
  morning:   'bg-amber-50/40',
  noon:      'bg-orange-50/40',
  afternoon: 'bg-sky-50/40',
  evening:   'bg-[hsl(var(--primary))]/4',
}

const slotDot: Record<string, string> = {
  morning:   'bg-amber-400',
  noon:      'bg-orange-400',
  afternoon: 'bg-sky-400',
  evening:   'bg-[hsl(var(--primary))]',
}

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
    for (const slot of timeSlots.value) data[zone.id][slot.id] = []
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

