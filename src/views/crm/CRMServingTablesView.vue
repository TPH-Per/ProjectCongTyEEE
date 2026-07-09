<template>
  <div class="space-y-6">
    <header class="flex flex-col gap-1">
      <h1 class="text-2xl font-bold text-gray-900">{{ $t('crm.servingTables', 'Serving Tables') }}</h1>
      <p class="text-sm text-gray-500">{{ $t('crm.overview', 'Overview') }}</p>
    </header>

    <!-- Filters -->
    <div class="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      <button
        v-for="filter in filters"
        :key="filter.value"
        @click="activeFilter = filter.value"
        class="whitespace-nowrap rounded-full px-5 py-2 text-sm font-semibold transition-all border"
        :class="
          activeFilter === filter.value
            ? 'bg-[#b89722] border-[#b89722] text-white shadow-md shadow-[#b89722]/20'
            : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
        "
      >
        {{ filter.label }}
      </button>
    </div>

    <!-- Error state -->
    <div v-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
      {{ error }}
    </div>

    <!-- Loading state -->
    <div v-if="loading && !tables.length" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-28 w-full animate-pulse rounded-2xl bg-white border border-gray-100 shadow-sm"></div>
    </div>

    <!-- Empty state -->
    <div v-else-if="!filteredTables.length" class="flex flex-col items-center justify-center py-16 text-center">
      <div class="mb-5 rounded-full bg-gray-50 p-6">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 002-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
      </div>
      <p class="text-gray-500 font-medium">{{ $t('crm.noTables', 'No tables found.') }}</p>
    </div>

    <!-- Table Cards -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="table in filteredTables"
        :key="table.table_id"
        class="group relative overflow-hidden rounded-2xl border border-gray-200 bg-white p-5 shadow-sm transition-all hover:border-[#b89722] hover:shadow-md cursor-pointer"
        @click="openSurvey(table)"
      >
        <div class="flex justify-between items-start mb-3">
          <div>
            <h3 class="text-xl font-bold text-gray-900">{{ table.table_code }}</h3>
            <p class="text-sm text-gray-500 mt-0.5 font-medium">{{ table.zone_name || 'No zone' }}</p>
          </div>
          <span :class="['px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider border', statusClass(table.crm_status)]">
            {{ statusLabel(table.crm_status) }}
          </span>
        </div>
        
        <div class="flex items-center gap-5 text-sm text-gray-600 mt-5 pt-4 border-t border-gray-100">
          <div class="flex items-center gap-1.5 font-medium">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4.5 w-4.5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
            <span>{{ table.guest_count }} {{ $t('crm.guests', 'Guests') }}</span>
          </div>
          <div class="flex items-center gap-1.5 font-medium">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4.5 w-4.5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
            </svg>
            <span>{{ formatTime(table.started_at) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Survey Modal -->
    <Teleport to="body">
      <Transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div v-if="selectedTable" class="fixed inset-0 z-[100] flex items-center justify-center bg-gray-900/60 backdrop-blur-sm p-4">
          <!-- Click outside to close -->
          <div class="absolute inset-0" @click="closeSurvey"></div>
          
          <div class="relative bg-white border border-gray-100 w-full rounded-2xl max-w-md shadow-2xl flex flex-col max-h-[90vh]">
            <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center shrink-0">
              <div>
                <h2 class="text-xl font-bold text-gray-900">{{ $t('crm.surveyFor', 'Survey') }} {{ selectedTable.table_code }}</h2>
                <p class="text-sm text-gray-500 font-medium">{{ selectedTable.zone_name || '' }}</p>
              </div>
              <button @click="closeSurvey" class="rounded-full p-2 bg-gray-50 text-gray-500 hover:bg-gray-100 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
            
            <!-- Survey Content -->
            <div class="p-6 overflow-y-auto">
              <div v-if="selectedTable.crm_status === 'completed'" class="flex flex-col items-center justify-center py-8 text-center">
                <div class="w-16 h-16 bg-green-50 rounded-full flex items-center justify-center mb-4 border border-green-100">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 class="text-lg font-bold text-gray-900 mb-1">{{ $t('crm.surveyCompleted', 'Survey Completed') }}</h3>
                <p class="text-sm font-medium text-gray-500">{{ $t('crm.alreadySurveyed', 'This table has already been surveyed.') }}</p>
              </div>

              <form v-else @submit.prevent="submit" class="space-y-6">
                <!-- Customer Details -->
                <div class="space-y-4">
                  <h3 class="text-[11px] font-extrabold text-gray-400 uppercase tracking-wider">{{ $t('crm.customerDetails', 'Customer Details') }}</h3>
                  
                  <div>
                    <label class="block text-xs font-bold text-gray-600 mb-1.5">{{ $t('crm.customerName', 'Customer Name') }}</label>
                    <input
                      v-model="surveyForm.customerName"
                      type="text"
                      class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-[#b89722] focus:outline-none focus:ring-4 focus:ring-[#b89722]/10 transition-all placeholder-gray-400 font-medium"
                      :placeholder="$t('crm.namePlaceholder', 'Enter name')"
                    />
                  </div>

                  <div>
                    <label class="block text-xs font-bold text-gray-600 mb-1.5">{{ $t('crm.phoneNumber', 'Phone Number') }}</label>
                    <input
                      v-model="surveyForm.customerPhone"
                      type="tel"
                      class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-[#b89722] focus:outline-none focus:ring-4 focus:ring-[#b89722]/10 transition-all placeholder-gray-400 font-medium"
                      :placeholder="$t('crm.phonePlaceholder', 'Enter phone')"
                    />
                  </div>

                  <div>
                    <label class="block text-xs font-bold text-gray-600 mb-1.5">{{ $t('crm.visitReason', 'Reason for Visit') }}</label>
                    <select
                      v-model="surveyForm.visitReason"
                      class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-[#b89722] focus:outline-none focus:ring-4 focus:ring-[#b89722]/10 transition-all font-medium"
                    >
                      <option value="">{{ $t('crm.selectReason', 'Select reason') }}</option>
                      <option value="casual">{{ $t('crm.reason.casual', 'Casual Dining') }}</option>
                      <option value="birthday">{{ $t('crm.reason.birthday', 'Birthday') }}</option>
                      <option value="anniversary">{{ $t('crm.reason.anniversary', 'Anniversary') }}</option>
                      <option value="business">{{ $t('crm.reason.business', 'Business Meeting') }}</option>
                      <option value="other">{{ $t('crm.reason.other', 'Other') }}</option>
                    </select>
                  </div>
                </div>

                <!-- Feedback -->
                <div class="space-y-4">
                  <h3 class="text-[11px] font-extrabold text-gray-400 uppercase tracking-wider">{{ $t('crm.generalFeedback', 'Feedback') }}</h3>
                  <div>
                    <textarea
                      v-model="surveyForm.feedback"
                      rows="3"
                      class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-[#b89722] focus:outline-none focus:ring-4 focus:ring-[#b89722]/10 transition-all placeholder-gray-400 font-medium"
                      :placeholder="$t('crm.feedbackPlaceholder', 'How was the experience?')"
                    ></textarea>
                  </div>
                  <div>
                    <label class="block text-xs font-bold text-gray-600 mb-1.5">{{ $t('crm.improvementNotes', 'Improvement Notes') }}</label>
                    <textarea
                      v-model="surveyForm.improvementNote"
                      rows="2"
                      class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-[#b89722] focus:outline-none focus:ring-4 focus:ring-[#b89722]/10 transition-all placeholder-gray-400 font-medium"
                      :placeholder="$t('crm.improvementPlaceholder', 'What can we do better?')"
                    ></textarea>
                  </div>
                </div>

                <!-- Buttons -->
                <div class="pt-4 flex flex-col gap-3 pb-2">
                  <button
                    type="submit"
                    class="w-full rounded-xl bg-[#b89722] px-4 py-3 text-sm font-bold text-white shadow-md shadow-[#b89722]/30 hover:bg-[#a3851d] transition-all active:scale-[0.98] disabled:opacity-50"
                    :disabled="crmStore.loading"
                  >
                    {{ crmStore.loading ? $t('crm.saving', 'Saving...') : $t('crm.submitSurvey', 'Submit Survey') }}
                  </button>
                  <button
                    v-if="selectedTable.crm_status === 'not_started' || selectedTable.crm_status === 'assigned'"
                    type="button"
                    class="w-full rounded-xl bg-blue-50 border border-blue-100 px-4 py-3 text-sm font-bold text-blue-600 hover:bg-blue-100 transition-all active:scale-[0.98] disabled:opacity-50"
                    :disabled="crmStore.loading"
                    @click="markInProgress"
                  >
                    {{ $t('crm.markInProgress', 'Mark as In Progress') }}
                  </button>
                  <button
                    type="button"
                    class="w-full rounded-xl bg-red-50 border border-red-100 text-red-500 px-4 py-3 text-sm font-bold hover:bg-red-100 transition-all active:scale-[0.98] disabled:opacity-50"
                    :disabled="crmStore.loading"
                    @click="skipSurvey"
                  >
                    {{ $t('crm.skip', 'Customer Refused / Skip') }}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCrmStore } from '@/stores/crmStore'
import type { CrmServingTable, CrmSurveyInput, CrmSurveyStatus } from '@/stores/crmStore'
import { useRealtime } from '@/composables/useRealtime'

const { t } = useI18n()
const crmStore = useCrmStore()
const loading = computed(() => crmStore.loading)
const error = computed(() => crmStore.error)

const tables = ref<CrmServingTable[]>([])
const activeFilter = ref<string>('all')
const selectedTable = ref<CrmServingTable | null>(null)

const surveyForm = ref({
  customerName: '',
  customerPhone: '',
  visitReason: '',
  feedback: '',
  improvementNote: '',
})

const filters = computed(() => [
  { label: t('crm.status.toDo', 'All Tables'), value: 'all' },
  { label: t('crm.status.assigned', 'Action Needed'), value: 'action_needed' },
  { label: t('crm.status.inProgress', 'In Progress'), value: 'in_progress' },
  { label: t('crm.status.done', 'Completed'), value: 'completed' },
])

const filteredTables = computed(() => {
  if (activeFilter.value === 'all') return tables.value
  if (activeFilter.value === 'completed') {
    return tables.value.filter(tbl => tbl.crm_status === 'completed' || tbl.crm_status === 'skipped' || tbl.crm_status === 'customer_refused')
  }
  if (activeFilter.value === 'in_progress') {
    return tables.value.filter(tbl => tbl.crm_status === 'in_progress')
  }
  if (activeFilter.value === 'action_needed') {
    return tables.value.filter(tbl => tbl.crm_status === 'not_started' || tbl.crm_status === 'assigned')
  }
  return tables.value
})

async function refresh() {
  await crmStore.fetchServingTables()
  tables.value = crmStore.servingTables
  if (selectedTable.value) {
    selectedTable.value = tables.value.find((t) => t.table_id === selectedTable.value?.table_id) ?? null
  }
}

function openSurvey(table: CrmServingTable) {
  selectedTable.value = table
  surveyForm.value = {
    customerName: table.customer_name || '',
    customerPhone: table.customer_phone || '',
    visitReason: '',
    feedback: '',
    improvementNote: '',
  }
}

function closeSurvey() {
  selectedTable.value = null
}

async function markInProgress() {
  if (!selectedTable.value) return
  await crmStore.markSurveyInProgress({
    table_id: selectedTable.value.table_id,
    order_id: selectedTable.value.order_id,
    table_assignment_id: selectedTable.value.table_assignment_id
  })
  await refresh()
  closeSurvey()
}

async function skipSurvey() {
  if (!selectedTable.value) return
  await crmStore.skipTableSurvey({
    table_id: selectedTable.value.table_id,
    order_id: selectedTable.value.order_id,
    table_assignment_id: selectedTable.value.table_assignment_id
  })
  await refresh()
  closeSurvey()
}

async function submit() {
  if (!selectedTable.value) return
  try {
    const input: CrmSurveyInput = {
      tableId: selectedTable.value.table_id,
      orderId: selectedTable.value.order_id,
      tableAssignmentId: selectedTable.value.table_assignment_id,
      customerName: surveyForm.value.customerName || null,
      customerPhone: surveyForm.value.customerPhone || null,
      visitReason: surveyForm.value.visitReason || null,
      feedback: surveyForm.value.feedback || null,
      improvementNote: surveyForm.value.improvementNote || null,
    }
    await crmStore.submitTableSurvey(input)
    await refresh()
    closeSurvey()
  } catch (err) {
    console.error(err)
  }
}

function formatTime(iso: string) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function statusLabel(status: CrmSurveyStatus) {
  switch (status) {
    case 'not_started': return t('crm.status.toDo')
    case 'assigned': return t('crm.status.assigned')
    case 'in_progress': return t('crm.status.inProgress')
    case 'completed': return t('crm.status.done')
    case 'skipped': return t('crm.status.skipped')
    case 'customer_refused': return t('crm.status.refused')
    default: return status
  }
}

function statusClass(status: CrmSurveyStatus) {
  switch (status) {
    case 'completed': return 'bg-green-50 text-green-600 border-green-200'
    case 'in_progress': return 'bg-blue-50 text-blue-600 border-blue-200'
    case 'not_started':
    case 'assigned': return 'bg-yellow-50 text-yellow-600 border-yellow-200'
    case 'skipped':
    case 'customer_refused': return 'bg-gray-100 text-gray-500 border-gray-200'
    default: return 'bg-gray-100 text-gray-500 border-gray-200'
  }
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

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
