<template>
  <div class="space-y-5">

    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">
          <span class="mr-1">🪑</span>{{ t('floor.title') }}
        </h1>
        <p class="text-[hsl(var(--muted-foreground))] text-sm mt-1 font-medium">
          {{ mode === 'default' ? t('floor.subtitle_default') : t('floor.subtitle_realtime') }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <div class="flex items-center bg-white rounded-2xl border border-[hsl(var(--border))] shadow-sm p-1">
          <button
            @click="mode = 'default'"
            :class="[
              'px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all',
              mode === 'default'
                ? 'kawaii-gradient text-white shadow-sm'
                : 'text-[hsl(var(--muted-foreground))] hover:bg-[hsl(var(--muted))]'
            ]"
          >
            {{ t('floor.mode_day') }}
          </button>
          <button
            @click="mode = 'realtime'"
            :class="[
              'px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all flex items-center gap-1.5',
              mode === 'realtime'
                ? 'kawaii-gradient text-white shadow-sm'
                : 'text-[hsl(var(--muted-foreground))] hover:bg-[hsl(var(--muted))]'
            ]"
          >
            <span :class="['w-1.5 h-1.5 rounded-full bg-[hsl(var(--primary))] animate-pulse']" />
            {{ t('floor.mode_realtime') }}
          </button>
        </div>
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
          <span class="font-extrabold text-[hsl(var(--foreground))] text-sm whitespace-nowrap">{{ formattedDate }}</span>
        </button>
        <button @click="nextDay" class="p-1.5 hover:bg-white rounded-xl transition-colors">
          <ChevronRight :size="18" class="text-[hsl(var(--muted-foreground))]" />
        </button>
      </div>

      <!-- Status Legend -->
      <div class="flex items-center gap-3 text-xs ml-auto flex-wrap">
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-emerald-100 border border-emerald-300" />
          <span class="font-extrabold text-[hsl(var(--foreground))]">{{ totalStats.available }}</span>
          <span class="text-[hsl(var(--muted-foreground))] font-semibold">{{ t('floor.available') }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-amber-100 border border-amber-300" />
          <span class="font-extrabold text-[hsl(var(--foreground))]">{{ totalStats.reserved }}</span>
          <span class="text-[hsl(var(--muted-foreground))] font-semibold">{{ t('floor.reserved') }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="w-3 h-3 rounded bg-[hsl(var(--primary))]/15 border border-[hsl(var(--primary))]/40" />
          <span class="font-extrabold text-[hsl(var(--foreground))]">{{ totalStats.occupied }}</span>
          <span class="text-[hsl(var(--muted-foreground))] font-semibold">{{ t('floor.occupied') }}</span>
        </div>
      </div>
    </div>

    <!-- Main content - 2 columns -->
    <div class="grid grid-cols-12 gap-5">
      <!-- Left: Area Selector Panel -->
      <div class="col-span-12 lg:col-span-4 xl:col-span-3 space-y-4">
        <div class="kawaii-card overflow-hidden">
          <div class="kawaii-card-header">
            <div class="flex items-center gap-2">
              <Layers :size="15" class="text-[hsl(var(--primary))]" />
              <h3 class="text-sm font-extrabold text-[hsl(var(--foreground))] uppercase tracking-wider">{{ t('floor.choose_area') }}</h3>
            </div>
            <span class="text-[10px] text-[hsl(var(--muted-foreground))] font-bold">
              {{ zones.length }} {{ t('floor.areas_count') }}
            </span>
          </div>

          <div class="p-2">
            <button
              v-for="z in zones"
              :key="z.id"
              @click="selectedZone = z.id"
              :class="[
                'w-full text-left px-3 py-2.5 rounded-2xl mb-1 transition-all flex items-center gap-3 group',
                selectedZone === z.id
                  ? 'bg-[hsl(var(--primary))]/10 border-2 border-[hsl(var(--primary))]/40 shadow-sm'
                  : 'hover:bg-[hsl(var(--muted))] border-2 border-transparent'
              ]"
            >
              <!-- Checkbox -->
              <div
                :class="[
                  'w-5 h-5 rounded-lg border-2 flex items-center justify-center shrink-0 transition-all',
                  selectedZone === z.id
                    ? 'kawaii-gradient border-transparent'
                    : 'border-[hsl(var(--border))] group-hover:border-[hsl(var(--primary))]'
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
                <div :class="['text-sm font-extrabold truncate', selectedZone === z.id ? 'text-[hsl(var(--primary))]' : 'text-[hsl(var(--foreground))]']">
                  {{ z.name }}
                </div>
                <div class="text-[11px] text-[hsl(var(--muted-foreground))] font-semibold">
                  {{ zoneStats[z.id]?.total || 0 }} {{ t('floor.tables') }} • {{ zoneStats[z.id]?.available || 0 }} {{ t('units.available') }}
                </div>
              </div>

              <!-- Status mini badges -->
              <div class="flex items-center gap-0.5 shrink-0">
                <span v-if="(zoneStats[z.id]?.available || 0) > 0" class="text-[10px] font-extrabold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded-lg">
                  {{ zoneStats[z.id].available }}
                </span>
                <span v-if="(zoneStats[z.id]?.reserved || 0) > 0" class="text-[10px] font-extrabold text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded-lg">
                  {{ zoneStats[z.id].reserved }}
                </span>
                <span v-if="(zoneStats[z.id]?.occupied || 0) > 0" class="text-[10px] font-extrabold text-[hsl(var(--primary))] bg-[hsl(var(--primary))]/10 px-1.5 py-0.5 rounded-lg">
                  {{ zoneStats[z.id].occupied }}
                </span>
              </div>
            </button>
          </div>
        </div>

        <!-- Selected zone summary card -->
        <div v-if="selectedZoneObj" class="kawaii-card overflow-hidden">
          <div class="kawaii-card-header">
            <div class="text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">
              {{ t('floor.selected_area') }}
            </div>
          </div>
          <div class="p-4 space-y-3">
            <div class="flex items-center gap-2">
              <span
                class="w-4 h-4 rounded-full shrink-0"
                :style="{ backgroundColor: selectedZoneObj.color }"
              />
              <div class="text-base font-black text-[hsl(var(--foreground))]">{{ selectedZoneObj.name }}</div>
            </div>
            <div class="grid grid-cols-3 gap-2 text-center">
              <div class="bg-emerald-50 border border-emerald-100 rounded-xl p-2">
                <div class="text-lg font-black text-emerald-700">{{ zoneStats[selectedZoneObj.id]?.available || 0 }}</div>
                <div class="text-[10px] text-emerald-600 font-extrabold uppercase">{{ t('floor.available') }}</div>
              </div>
              <div class="bg-amber-50 border border-amber-100 rounded-xl p-2">
                <div class="text-lg font-black text-amber-700">{{ zoneStats[selectedZoneObj.id]?.reserved || 0 }}</div>
                <div class="text-[10px] text-amber-600 font-extrabold uppercase">{{ t('floor.reserved') }}</div>
              </div>
              <div class="bg-[hsl(var(--primary))]/10 border border-[hsl(var(--primary))]/30 rounded-xl p-2">
                <div class="text-lg font-black text-[hsl(var(--primary))]">{{ zoneStats[selectedZoneObj.id]?.occupied || 0 }}</div>
                <div class="text-[10px] text-[hsl(var(--primary))] font-extrabold uppercase">{{ t('floor.occupied') }}</div>
              </div>
            </div>
            <div class="text-xs text-[hsl(var(--muted-foreground))] pt-1 border-t border-[hsl(var(--border))] flex items-center justify-between font-semibold">
              <span>{{ t('floor.total_tables') }}</span>
              <span class="font-black text-[hsl(var(--foreground))]">{{ zoneStats[selectedZoneObj.id]?.total || 0 }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Zone floor plan -->
      <div class="col-span-12 lg:col-span-8 xl:col-span-9">
        <div class="kawaii-card overflow-hidden">
          <!-- Zone header -->
          <div class="kawaii-card-header">
            <div class="flex items-center gap-2">
              <span
                v-if="selectedZoneObj"
                class="w-3 h-3 rounded-full"
                :style="{ backgroundColor: selectedZoneObj.color }"
              />
              <h3 class="text-sm font-extrabold text-[hsl(var(--foreground))]">
                {{ selectedZoneObj?.name || t('floor.choose_area') }}
              </h3>
              <span class="text-xs text-[hsl(var(--muted-foreground))] font-semibold">({{ zoneTables.length }} {{ t('floor.tables') }})</span>
            </div>
            <div class="text-xs text-[hsl(var(--muted-foreground))] font-bold">
              {{ formattedDate }}
            </div>
          </div>

          <!-- Floor plan canvas -->
          <div class="relative bg-gradient-to-br from-[hsl(var(--muted))] to-[hsl(var(--background))] p-6 min-h-[500px]">
            <div class="absolute top-3 left-3 text-[10px] text-[hsl(var(--muted-foreground))] font-extrabold uppercase tracking-wider">
              🛎️ {{ t('floor.zone_empty') }}
            </div>
            <div class="absolute top-3 right-3 text-[10px] text-[hsl(var(--muted-foreground))] font-extrabold uppercase tracking-wider">
              🌸 {{ t('floor.reception') }}
            </div>

            <div
              v-if="zoneTables.length === 0"
              class="flex flex-col items-center justify-center h-[400px] text-[hsl(var(--muted-foreground))]"
            >
              <Layers :size="32" class="mb-2 opacity-50" />
              <div class="text-sm font-bold">{{ t('floor.empty_in_zone') }}</div>
            </div>
            <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mt-6">
              <div
                v-for="table in zoneTables"
                :key="table.id"
                @click="table.status !== 'available' && getTableReservation(table.code) ? navigateToOrder(getTableReservation(table.code)!.id) : null"
                :class="[
                  tableStatusStyle[table.status].bg,
                  tableStatusStyle[table.status].border,
                  'border-2 rounded-2xl p-3 flex flex-col items-center justify-center min-h-[120px] transition-all hover:shadow-lg cursor-pointer hover:scale-105'
                ]"
              >
                <div :class="['text-2xl font-black', tableStatusStyle[table.status].text]">{{ table.code }}</div>
                <div class="flex items-center gap-1 text-[10px] text-[hsl(var(--muted-foreground))] mt-1 font-bold">
                  <Users :size="10" /> {{ table.capacity }} {{ t('floor.wait') }}
                </div>
                <span :class="['mt-1.5 px-2 py-0.5 rounded-full text-[9px] font-extrabold', tableStatusStyle[table.status].badge]">
                  {{ t(`floor.${table.status === 'available' ? 'available' : table.status === 'reserved' ? 'reserved' : 'occupied'}`) }}
                </span>

                <template v-if="getTableReservation(table.code)">
                  <div class="mt-2 text-[11px] text-[hsl(var(--foreground))] font-extrabold truncate w-full text-center">
                    {{ getTableReservation(table.code)!.customerName }}
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-[hsl(var(--muted-foreground))] mt-0.5 font-bold">
                    <Clock :size="9" /> {{ getTableReservation(table.code)!.time }}
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-[hsl(var(--muted-foreground))] font-bold">
                    <Users :size="9" /> {{ getTableReservation(table.code)!.guests }} {{ t('floor.guests_unit') }}
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
import { useI18n } from 'vue-i18n'
import {
  Calendar as CalendarIcon, ChevronLeft, ChevronRight, Users, Clock,
  Check, Layers,
} from 'lucide-vue-next'
import { tables as allTables, zones, reservations as allReservations } from '@/lib/mock-data'

const router = useRouter()
const { t } = useI18n()

const reservationByTable = computed(() => {
  const map = new Map<string, typeof allReservations[0]>()
  for (const r of allReservations) {
    if (r.status !== 'Cancelled') {
      for (const tc of r.tables) {
        if (!map.has(tc)) map.set(tc, r)
      }
    }
  }
  return map
})

function getTableReservation(tableCode: string) {
  return reservationByTable.value.get(tableCode)
}

const tableStatusStyle: Record<string, { bg: string; border: string; text: string; badge: string }> = {
  available: { bg: 'bg-white',                          border: 'border-emerald-200',                  text: 'text-emerald-700',  badge: 'bg-emerald-100 text-emerald-700' },
  reserved:  { bg: 'bg-amber-50',                        border: 'border-amber-300',                    text: 'text-amber-700',    badge: 'bg-amber-100 text-amber-700' },
  occupied:  { bg: 'bg-[hsl(var(--primary))]/8',         border: 'border-[hsl(var(--primary))]/40',     text: 'text-[hsl(var(--primary))]', badge: 'bg-[hsl(var(--primary))]/15 text-[hsl(var(--primary))]' },
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

const selectedDate = ref(new Date(2026, 5, 18))
const selectedZone = ref('Z003')
const mode = ref<'default' | 'realtime'>('default')

const dateStr = computed(() => toDateStr(selectedDate.value))
const formattedDate = computed(() => formatDate(selectedDate.value))

const tablesWithStatus = computed(() => {
  const reservedOnDate = new Set<string>()
  const occupiedOnDate = new Set<string>()
  for (const r of allReservations) {
    if (r.date !== dateStr.value || r.status === 'Cancelled') continue
    if (r.status === 'Pending') {
      for (const tc of r.tables) reservedOnDate.add(tc)
    } else if (r.status === 'Arrived' || r.status === 'Dining' || r.status === 'Completed') {
      for (const tc of r.tables) occupiedOnDate.add(tc)
    }
  }
  return allTables.map(tb => {
    let status: 'available' | 'reserved' | 'occupied' = tb.status
    if (mode.value === 'default') {
      if (occupiedOnDate.has(tb.code)) status = 'occupied'
      else if (reservedOnDate.has(tb.code)) status = 'reserved'
      else status = 'available'
    } else {
      status = tb.status
    }
    return { ...tb, status }
  })
})

const zoneStats = computed(() => {
  const stats: Record<string, { total: number; available: number; reserved: number; occupied: number }> = {}
  for (const z of zones) {
    stats[z.id] = { total: 0, available: 0, reserved: 0, occupied: 0 }
  }
  for (const tb of tablesWithStatus.value) {
    if (stats[tb.zoneId]) {
      stats[tb.zoneId].total++
      stats[tb.zoneId][tb.status]++
    }
  }
  return stats
})

const totalStats = computed(() => {
  const c = { total: 0, available: 0, reserved: 0, occupied: 0 }
  for (const tb of tablesWithStatus.value) {
    c.total++
    c[tb.status]++
  }
  return c
})

const selectedZoneObj = computed(() => zones.find(z => z.id === selectedZone.value))
const zoneTables = computed(() => tablesWithStatus.value.filter(tb => tb.zoneId === selectedZone.value))

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

