<template>
  <div class="space-y-5">
    <header class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">CRM Customer Care</h1>
        <p class="text-sm text-gray-500">Serving tables</p>
      </div>
      <button
        type="button"
        class="rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-700 hover:bg-gray-50 disabled:opacity-50"
        :disabled="loading"
        @click="refresh"
      >
        {{ loading ? 'Loading...' : 'Refresh' }}
      </button>
    </header>

    <div v-if="error" class="rounded-lg border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700">
      {{ error }}
    </div>

    <section class="grid gap-5 xl:grid-cols-[minmax(0,1.35fr)_minmax(380px,0.65fr)]">
      <div class="space-y-4">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="status in filters"
            :key="status.value"
            type="button"
            class="rounded-lg border px-3 py-2 text-xs font-bold transition-colors"
            :class="activeFilter === status.value
              ? 'border-red-300 bg-red-50 text-red-700'
              : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50'"
            @click="activeFilter = status.value"
          >
            {{ status.label }}
          </button>
        </div>

        <div class="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table class="w-full border-collapse text-left text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-500">
              <tr>
                <th class="px-4 py-3 font-bold">Table</th>
                <th class="px-4 py-3 font-bold">Order</th>
                <th class="px-4 py-3 font-bold">Guests</th>
                <th class="px-4 py-3 font-bold">Started</th>
                <th class="px-4 py-3 font-bold">CRM</th>
                <th class="px-4 py-3 text-right font-bold">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr
                v-for="table in filteredTables"
                :key="table.order_id"
                class="hover:bg-gray-50"
                :class="selectedTable?.order_id === table.order_id ? 'bg-red-50/60' : ''"
              >
                <td class="px-4 py-3">
                  <div class="font-black text-gray-900">{{ table.table_code }}</div>
                  <div class="text-xs text-gray-500">{{ table.zone_name || 'No zone' }}</div>
                </td>
                <td class="px-4 py-3 font-mono text-xs text-gray-500">
                  {{ shortId(table.order_id) }}
                </td>
                <td class="px-4 py-3 font-semibold text-gray-700">
                  {{ table.guest_count || '-' }}
                </td>
                <td class="px-4 py-3 text-gray-600">
                  {{ formatTime(table.started_at) }}
                </td>
                <td class="px-4 py-3">
                  <span class="inline-flex rounded-lg px-2.5 py-1 text-xs font-black" :class="statusClass(table.crm_status)">
                    {{ statusLabel(table.crm_status) }}
                  </span>
                </td>
                <td class="px-4 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      v-if="canUndo(table)"
                      type="button"
                      class="rounded-lg border border-amber-300 bg-amber-50 px-2.5 py-1 text-[10px] font-bold text-amber-700 hover:bg-amber-100"
                      :title="`Hoàn tác về ${lastChangeFor(table)?.from}`"
                      @click="undoLast(table)"
                    >
                      ↺ Hoàn tác
                    </button>
                    <button
                      type="button"
                      class="rounded-lg bg-gray-900 px-3 py-2 text-xs font-bold text-white hover:bg-black"
                      @click="selectTable(table)"
                    >
                      {{ actionLabel(table.crm_status) }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredTables.length === 0">
                <td colspan="6" class="px-4 py-8 text-center text-gray-400">
                  No serving tables for this filter.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <aside class="rounded-lg border border-gray-200 bg-white p-5">
        <div v-if="!selectedTable" class="py-16 text-center text-sm text-gray-400">
          Select a serving table to start CRM survey.
        </div>

        <form v-else-if="isReadOnlySurvey(selectedTable)" class="space-y-4" @submit.prevent>
          <div class="flex items-start justify-between gap-3 border-b pb-4">
            <div>
              <h2 class="text-lg font-black text-gray-900">{{ selectedTable.table_code }}</h2>
              <p class="text-xs text-gray-500">
                Order {{ shortId(selectedTable.order_id) }} · Submitted
                {{ selectedTable.crm_submitted_at ? formatTime(selectedTable.crm_submitted_at) : '' }}
              </p>
            </div>
            <span class="rounded-lg px-2.5 py-1 text-xs font-black bg-green-100 text-green-700">
              View-only (submitted)
            </span>
          </div>
          <p class="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-xs text-gray-500">
            Survey đã gửi — chỉ xem. Để chỉnh sửa sau khi gửi, liên hệ quản lý.
          </p>
          <dl class="grid gap-2 text-sm">
            <div v-if="selectedTable.customer_name" class="flex justify-between border-b border-gray-100 py-2">
              <dt class="text-gray-500">Customer</dt><dd class="font-semibold text-gray-800">{{ selectedTable.customer_name }}</dd>
            </div>
            <div v-if="selectedTable.customer_phone" class="flex justify-between border-b border-gray-100 py-2">
              <dt class="text-gray-500">Phone</dt><dd class="font-mono text-gray-800">{{ selectedTable.customer_phone }}</dd>
            </div>
          </dl>
        </form>

        <form v-else class="space-y-4" @submit.prevent="submitSurvey">
          <div class="flex items-start justify-between gap-3 border-b pb-4">
            <div>
              <h2 class="text-lg font-black text-gray-900">{{ selectedTable.table_code }}</h2>
              <p class="text-xs text-gray-500">
                Order {{ shortId(selectedTable.order_id) }} · {{ statusLabel(selectedTable.crm_status) }}
              </p>
            </div>
            <span class="rounded-lg px-2.5 py-1 text-xs font-black" :class="statusClass(selectedTable.crm_status)">
              {{ statusLabel(selectedTable.crm_status) }}
            </span>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Source</span>
              <select v-model="form.sourceCode" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-semibold outline-none focus:border-red-400">
                <option value="">Select source</option>
                <option v-for="source in sourceOptions" :key="source.value" :value="source.value">{{ source.label }}</option>
              </select>
            </label>

            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Visit reason</span>
              <select v-model="form.visitReason" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-semibold outline-none focus:border-red-400">
                <option value="">Select reason</option>
                <option v-for="reason in reasonOptions" :key="reason.value" :value="reason.value">{{ reason.label }}</option>
              </select>
            </label>
          </div>

          <label class="block">
            <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Feedback</span>
            <textarea v-model="form.feedback" rows="3" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
          </label>

          <label class="block">
            <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Improvement note</span>
            <textarea v-model="form.improvementNote" rows="3" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
          </label>

          <div class="grid gap-3 sm:grid-cols-2">
            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Customer name</span>
              <input v-model="form.customerName" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
            </label>
            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Phone</span>
              <input v-model="form.customerPhone" inputmode="tel" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
            </label>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Zalo</span>
              <input v-model="form.zalo" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
            </label>
            <label class="block">
              <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Tags</span>
              <input v-model="tagText" placeholder="vip, birthday, family" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
            </label>
          </div>

          <label class="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-semibold text-gray-700">
            <input v-model="form.marketingConsent" type="checkbox" class="h-4 w-4 accent-red-600" />
            Marketing consent
          </label>

          <label class="block">
            <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Internal note</span>
            <input v-model="form.note" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm outline-none focus:border-red-400" />
          </label>

          <div class="grid gap-2 sm:grid-cols-3">
            <button
              type="submit"
              class="rounded-lg bg-red-600 px-4 py-3 text-sm font-black text-white hover:bg-red-700 disabled:opacity-50"
              :disabled="loading || !canSubmit"
            >
              Submit
            </button>
            <button
              type="button"
              class="rounded-lg border border-gray-300 bg-white px-4 py-3 text-sm font-black text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              :disabled="loading"
              @click="markRefused"
            >
              Refused
            </button>
            <button
              type="button"
              class="rounded-lg border border-gray-300 bg-white px-4 py-3 text-sm font-black text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              :disabled="loading"
              @click="skipSurvey"
            >
              Skip
            </button>
          </div>
        </form>
      </aside>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useCRM, type CrmServingTable, type CrmSurveyStatus } from '@/composables/useCRM'
import { useRealtime } from '@/composables/useRealtime'

const {
  loading,
  error,
  listServingTables,
  submitTableSurvey,
  markSurveyInProgress,
  skipTableSurvey,
  refuseTableSurvey,
  setSurveyStatus,
} = useCRM()

const tables = ref<CrmServingTable[]>([])
const selectedTable = ref<CrmServingTable | null>(null)
const activeFilter = ref<'all' | CrmSurveyStatus>('all')
const tagText = ref('')

// Recent status changes per table — kept for 10 s so the UI can offer an
// "undo last action" affordance. Cleared after either TTL or undo.
interface StatusChange {
  orderId: string
  from: CrmSurveyStatus
  to: CrmSurveyStatus
  changedAt: number
}
const recentChanges = ref<StatusChange[]>([])
const RECENT_TTL_MS = 10_000

function recordChange(orderId: string, from: CrmSurveyStatus, to: CrmSurveyStatus) {
  if (from === to) return
  recentChanges.value = [
    ...recentChanges.value.filter((c) => c.orderId !== orderId),
    { orderId, from, to, changedAt: Date.now() },
  ]
  // Garbage-collect expired entries so the map doesn't grow unbounded.
  setTimeout(() => {
    recentChanges.value = recentChanges.value.filter(
      (c) => Date.now() - c.changedAt < RECENT_TTL_MS,
    )
  }, RECENT_TTL_MS + 1000)
}

function lastChangeFor(table: CrmServingTable): StatusChange | undefined {
  return recentChanges.value.find((c) => c.orderId === table.order_id)
}
function canUndo(table: CrmServingTable): boolean {
  const c = lastChangeFor(table)
  // Don't surface an undo option when reverting would require un-doing a
  // submit (`completed` is not reversible through `setSurveyStatus`).
  if (!c) return false
  if (c.to === 'completed') return false
  return Date.now() - c.changedAt < RECENT_TTL_MS
}

async function undoLast(table: CrmServingTable) {
  const c = lastChangeFor(table)
  if (!c) return
  // `setSurveyStatus` only accepts the 4 reversible workflow statuses.
  // `not_started` is the implicit "no row" state — there is no row to
  // update to that status, so the undo button is hidden in `canUndo` and we
  // additionally guard here as a safety net.
  const reversible = ['assigned', 'in_progress', 'skipped', 'customer_refused'] as const
  if (!(reversible as readonly string[]).includes(c.from)) return
  try {
    await setSurveyStatus(table, c.from as (typeof reversible)[number])
    // Drop the entry immediately so the UI doesn't show "undo" again.
    recentChanges.value = recentChanges.value.filter((x) => x.orderId !== table.order_id)
    await refresh()
  } catch (e: any) {
    error.value = e?.message ?? String(e)
  }
}

function isReadOnlySurvey(table: CrmServingTable | null): boolean {
  if (!table) return false
  return table.crm_status === 'completed'
}

const form = ref({
  sourceCode: '',
  visitReason: '',
  feedback: '',
  improvementNote: '',
  customerName: '',
  customerPhone: '',
  zalo: '',
  marketingConsent: false,
  note: '',
})

const filters: Array<{ value: 'all' | CrmSurveyStatus; label: string }> = [
  { value: 'all', label: 'All' },
  { value: 'not_started', label: 'Not asked' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'completed', label: 'Completed' },
  { value: 'customer_refused', label: 'Refused' },
  { value: 'skipped', label: 'Skipped' },
]

const sourceOptions = [
  { value: 'google_map', label: 'Google Map' },
  { value: 'facebook', label: 'Facebook' },
  { value: 'tiktok', label: 'TikTok' },
  { value: 'instagram', label: 'Instagram' },
  { value: 'friend_referral', label: 'Friend referral' },
  { value: 'walk_by', label: 'Walk by' },
  { value: 'returning_customer', label: 'Returning customer' },
  { value: 'booking_platform', label: 'Booking platform' },
  { value: 'other', label: 'Other' },
]

const reasonOptions = [
  { value: 'family_meal', label: 'Family meal' },
  { value: 'birthday', label: 'Birthday' },
  { value: 'date', label: 'Date' },
  { value: 'company', label: 'Company' },
  { value: 'friends', label: 'Friends' },
  { value: 'first_try', label: 'First try' },
  { value: 'regular', label: 'Regular customer' },
  { value: 'other', label: 'Other' },
]

const filteredTables = computed(() => {
  if (activeFilter.value === 'all') return tables.value
  return tables.value.filter((table) => table.crm_status === activeFilter.value)
})

const canSubmit = computed(() => {
  if (!selectedTable.value?.order_id) return false
  return Boolean(
    form.value.sourceCode ||
      form.value.visitReason ||
      form.value.feedback.trim() ||
      form.value.improvementNote.trim() ||
      form.value.customerPhone.trim(),
  )
})

function shortId(id?: string | null): string {
  return id ? id.slice(0, 8) : '-'
}

function formatTime(value?: string | null): string {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime())
    ? '-'
    : date.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' })
}

function statusLabel(status: CrmSurveyStatus): string {
  switch (status) {
    case 'not_started': return 'Not asked'
    case 'assigned': return 'Assigned'
    case 'in_progress': return 'In progress'
    case 'completed': return 'Completed'
    case 'skipped': return 'Skipped'
    case 'customer_refused': return 'Refused'
    case 'expired': return 'Expired'
    case 'late_submitted': return 'Late submitted'
    default: return status
  }
}

function statusClass(status: CrmSurveyStatus): string {
  switch (status) {
    case 'completed': return 'bg-green-100 text-green-700'
    case 'in_progress':
    case 'assigned': return 'bg-blue-100 text-blue-700'
    case 'customer_refused': return 'bg-red-100 text-red-700'
    case 'skipped': return 'bg-gray-100 text-gray-700'
    case 'expired':
    case 'late_submitted': return 'bg-purple-100 text-purple-700'
    default: return 'bg-orange-100 text-orange-700'
  }
}

function actionLabel(status: CrmSurveyStatus): string {
  if (status === 'completed') return 'View'
  if (status === 'in_progress' || status === 'assigned') return 'Continue'
  return 'Start'
}

function resetForm() {
  form.value = {
    sourceCode: '',
    visitReason: '',
    feedback: '',
    improvementNote: '',
    customerName: '',
    customerPhone: '',
    zalo: '',
    marketingConsent: false,
    note: '',
  }
  tagText.value = ''
}

async function refresh() {
  tables.value = await listServingTables()
  if (selectedTable.value) {
    selectedTable.value = tables.value.find((table) => table.order_id === selectedTable.value?.order_id) ?? null
  }
}

async function selectTable(table: CrmServingTable) {
  selectedTable.value = table
  resetForm()
  if (table.crm_status === 'not_started') {
    const before = table.crm_status
    await markSurveyInProgress(table)
    await refresh()
    const after = tables.value.find((t) => t.order_id === table.order_id)
    if (after) recordChange(table.order_id, before, after.crm_status)
  }
}

function parsedTags(): string[] {
  return tagText.value
    .split(',')
    .map((tag) => tag.trim())
    .filter(Boolean)
}

async function submitSurvey() {
  if (!selectedTable.value) return
  const before = selectedTable.value.crm_status
  await submitTableSurvey({
    tableId: selectedTable.value.table_id,
    orderId: selectedTable.value.order_id,
    tableAssignmentId: selectedTable.value.table_assignment_id,
    sourceCode: form.value.sourceCode,
    visitReason: form.value.visitReason,
    feedback: form.value.feedback.trim(),
    improvementNote: form.value.improvementNote.trim(),
    customerName: form.value.customerName.trim(),
    customerPhone: form.value.customerPhone.trim(),
    zalo: form.value.zalo.trim(),
    marketingConsent: form.value.marketingConsent,
    tags: parsedTags(),
    note: form.value.note.trim(),
  })
  await refresh()
  const after = tables.value.find((t) => t.order_id === selectedTable.value?.order_id)
  if (after) recordChange(selectedTable.value.order_id, before, after.crm_status)
}

async function markRefused() {
  if (!selectedTable.value) return
  const before = selectedTable.value.crm_status
  await refuseTableSurvey(selectedTable.value, form.value.note.trim())
  await refresh()
  const after = tables.value.find((t) => t.order_id === selectedTable.value?.order_id)
  if (after) recordChange(selectedTable.value.order_id, before, after.crm_status)
}

async function skipSurvey() {
  if (!selectedTable.value) return
  const before = selectedTable.value.crm_status
  await skipTableSurvey(selectedTable.value, form.value.note.trim())
  await refresh()
  const after = tables.value.find((t) => t.order_id === selectedTable.value?.order_id)
  if (after) recordChange(selectedTable.value.order_id, before, after.crm_status)
}

// Realtime: any new survey or order change auto-refreshes the list.
const realtime = useRealtime()
let refreshWatcherA: (() => void) | null = null
let refreshWatcherB: (() => void) | null = null

onMounted(async () => {
  await refresh()
  refreshWatcherA = realtime.watchTable('crm_surveys', '*', () => {
    refresh().catch(() => {})
  })
  refreshWatcherB = realtime.watchTable('orders', '*', () => {
    refresh().catch(() => {})
  })
})

onBeforeUnmount(() => {
  refreshWatcherA?.()
  refreshWatcherB?.()
})
</script>
