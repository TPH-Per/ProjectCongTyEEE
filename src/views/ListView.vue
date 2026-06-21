<template>
  <div class="space-y-5">
    <!-- Page Header -->
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">
          <span class="mr-1">📋</span>{{ t('list.title') }}
        </h1>
        <p class="text-[hsl(var(--muted-foreground))] text-sm mt-1 font-medium">{{ t('list.subtitle') }}</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="kawaii-btn-ghost flex items-center gap-2 px-3 py-2 text-sm">
          <Download :size="16" />
          {{ t('list.export_excel') }}
        </button>
        <button class="kawaii-btn-primary flex items-center gap-2 px-4 py-2 text-sm">
          <Plus :size="16" />
          {{ t('list.create_new') }}
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
          <span class="font-extrabold text-[hsl(var(--foreground))] text-sm whitespace-nowrap">{{ formattedDate }}</span>
        </button>
        <button @click="nextDay" class="p-1.5 hover:bg-white rounded-xl transition-colors">
          <ChevronRight :size="18" class="text-[hsl(var(--muted-foreground))]" />
        </button>
      </div>

      <!-- View Switcher -->
      <div class="flex items-center bg-[hsl(var(--muted))] rounded-2xl p-1">
        <RouterLink to="/" class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-bold text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]">
          <MapIcon :size="14" />
          {{ t('list.view_schedule') }}
        </RouterLink>
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-extrabold bg-white text-[hsl(var(--primary))] shadow-sm">
          <ListIcon :size="14" />
          {{ t('list.view_list') }}
        </button>
      </div>

      <!-- Search -->
      <div class="relative flex-1 min-w-[220px] max-w-xs">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-[hsl(var(--muted-foreground))]" :size="16" />
        <input
          type="text"
          :placeholder="t('list.search_placeholder')"
          v-model="search"
          class="kawaii-input pl-9 pr-3 py-2 text-sm"
        />
      </div>

      <!-- Status Filter -->
      <div class="flex gap-1 bg-[hsl(var(--muted))] rounded-2xl p-1 overflow-x-auto">
        <button
          v-for="s in filters"
          :key="s.id"
          @click="statusFilter = s.id"
          :class="[
            'px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all whitespace-nowrap flex items-center gap-1.5',
            statusFilter === s.id
              ? 'kawaii-gradient text-white shadow-sm'
              : 'text-[hsl(var(--muted-foreground))] hover:bg-white'
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
    <div class="kawaii-card overflow-hidden">
      <table class="w-full">
        <thead>
          <tr class="bg-[hsl(var(--muted))] border-b border-[hsl(var(--border))]">
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider w-[40px]">
              <input type="checkbox" class="rounded border-[hsl(var(--border))]" />
            </th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_code') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_customer') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_contact') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_time') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_guests') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_table') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_type') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_source') }}</th>
            <th class="px-4 py-3 text-left text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">{{ t('list.th_status') }}</th>
            <th class="px-4 py-3 text-right text-[11px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider w-[60px]"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-[hsl(var(--border))]">
          <tr v-if="filteredReservations.length === 0">
            <td colspan="11" class="py-16 text-center text-[hsl(var(--muted-foreground))] text-sm font-bold">
              {{ t('list.empty') }}
            </td>
          </tr>
          <tr
            v-else
            v-for="r in filteredReservations"
            :key="r.id"
            class="hover:bg-[hsl(var(--muted))]/60 transition-colors group"
          >
            <td class="px-4 py-3">
              <input type="checkbox" class="rounded border-[hsl(var(--border))]" />
            </td>
            <td class="px-4 py-3">
              <RouterLink :to="`/order/${r.id}`" class="text-[hsl(var(--primary))] font-mono text-xs font-extrabold hover:underline">
                {{ r.id }}
              </RouterLink>
            </td>
            <td class="px-4 py-3">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-full kawaii-gradient flex items-center justify-center text-white text-xs font-black">
                  {{ r.customerName.charAt(r.customerName.length - 1) }}
                </div>
                <div>
                  <div class="text-sm font-extrabold text-[hsl(var(--foreground))]">{{ r.customerName }}</div>
                  <div v-if="r.note" class="text-[11px] text-[hsl(var(--muted-foreground))] truncate max-w-[180px] font-medium">{{ r.note }}</div>
                </div>
              </div>
            </td>
            <td class="px-4 py-3 text-xs text-[hsl(var(--muted-foreground))] font-semibold">
              <div class="flex items-center gap-1">
                <Phone :size="11" class="text-[hsl(var(--muted-foreground))]" />
                {{ r.customerPhone }}
              </div>
            </td>
            <td class="px-4 py-3">
              <span class="font-mono text-sm font-extrabold text-[hsl(var(--foreground))]">{{ r.time }}</span>
            </td>
            <td class="px-4 py-3">
              <span class="inline-flex items-center gap-1 text-xs text-[hsl(var(--foreground))] font-bold">
                <Users :size="11" class="text-[hsl(var(--muted-foreground))]" />
                {{ r.guests }}
              </span>
            </td>
            <td class="px-4 py-3">
              <span
                v-if="r.tables.length > 0"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-[hsl(var(--muted))] rounded-lg text-xs font-mono font-extrabold text-[hsl(var(--foreground))]"
              >
                <MapPin :size="10" class="text-[hsl(var(--muted-foreground))]" />
                {{ r.tables.join(', ') }}
              </span>
              <span v-else class="text-[hsl(var(--muted-foreground))]">—</span>
            </td>
            <td class="px-4 py-3">
              <span class="text-xs text-[hsl(var(--muted-foreground))] font-semibold">{{ r.type || '—' }}</span>
            </td>
            <td class="px-4 py-3">
              <span class="text-xs text-[hsl(var(--muted-foreground))] font-semibold">{{ r.source || '—' }}</span>
            </td>
            <td class="px-4 py-3">
              <span :class="['kawaii-pill', statusStyle[r.status]]">
                <span :class="['w-1.5 h-1.5 rounded-full', statusDotStyle[r.status]]" />
                {{ t(`status.${r.status}`) }}
              </span>
            </td>
            <td class="px-4 py-3 text-right">
              <RouterLink
                :to="`/order/${r.id}`"
                class="inline-flex items-center justify-center w-7 h-7 rounded-xl hover:bg-[hsl(var(--muted))] text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--primary))]"
              >
                <MoreHorizontal :size="16" />
              </RouterLink>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Footer -->
      <div class="px-4 py-3 border-t border-[hsl(var(--border))] bg-[hsl(var(--muted))]/60 flex flex-wrap items-center justify-between gap-2 text-xs text-[hsl(var(--muted-foreground))] font-semibold">
        <span>
          {{ t('list.showing') }}
          <b class="text-[hsl(var(--foreground))]">{{ filteredReservations.length }}</b>
          {{ t('list.of') }} {{ counts.all || 0 }} {{ t('list.results') }}
        </span>
        <div class="flex items-center gap-1">
          <button class="px-2.5 py-1 border border-[hsl(var(--border))] rounded-lg bg-white hover:bg-[hsl(var(--muted))] disabled:opacity-50 font-bold">
            {{ t('list.prev') }}
          </button>
          <button class="px-2.5 py-1 kawaii-gradient text-white rounded-lg font-extrabold">1</button>
          <button class="px-2.5 py-1 border border-[hsl(var(--border))] rounded-lg bg-white hover:bg-[hsl(var(--muted))] font-bold">2</button>
          <button class="px-2.5 py-1 border border-[hsl(var(--border))] rounded-lg bg-white hover:bg-[hsl(var(--muted))] font-bold">
            {{ t('list.next') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import {
  Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus,
  List as ListIcon, Map as MapIcon, Download, Phone, Users, MapPin, MoreHorizontal,
} from 'lucide-vue-next'
import { reservations as allReservations } from '@/lib/mock-data'

const { t } = useI18n()

const statusStyle: Record<string, string> = {
  Pending:   'bg-amber-100 text-amber-700',
  Arrived:   'bg-blue-100 text-blue-700',
  Dining:    'bg-emerald-100 text-emerald-700',
  Completed: 'bg-slate-200 text-slate-600',
  Cancelled: 'bg-rose-100 text-rose-700',
}

const statusDotStyle: Record<string, string> = {
  Pending:   'bg-amber-400',
  Arrived:   'bg-blue-500',
  Dining:    'bg-emerald-500',
  Completed: 'bg-slate-400',
  Cancelled: 'bg-rose-400',
}

const filters = computed(() => [
  { id: 'all', label: t('timeline.area') },
  { id: 'Pending', label: t('status.Pending') },
  { id: 'Arrived', label: t('status.Arrived') },
  { id: 'Dining', label: t('status.Dining') },
  { id: 'Completed', label: t('status.Completed') },
  { id: 'Cancelled', label: t('status.Cancelled') },
])

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
