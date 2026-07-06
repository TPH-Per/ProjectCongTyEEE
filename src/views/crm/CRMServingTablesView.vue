<template>
  <div class="space-y-4">
    <header class="flex flex-col gap-1">
      <h1 class="text-2xl font-bold text-white">{{ $t('crm.servingTables', 'Serving Tables') }}</h1>
      <p class="text-sm text-yellow-500/80">{{ $t('crm.overview', 'Overview') }}</p>
    </header>

    <!-- Filters -->
    <div class="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      <button
        v-for="filter in filters"
        :key="filter.value"
        @click="activeFilter = filter.value"
        class="whitespace-nowrap rounded-full px-4 py-1.5 text-sm font-semibold transition-colors border"
        :class="
          activeFilter === filter.value
            ? 'bg-yellow-500 border-yellow-500 text-gray-900'
            : 'bg-gray-800 border-gray-700 text-gray-400 hover:bg-gray-700'
        "
      >
        {{ filter.label }}
      </button>
    </div>

    <!-- Error state -->
    <div v-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
      {{ error }}
    </div>

    <!-- Loading state -->
    <div v-if="loading && !tables.length" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-24 w-full animate-pulse rounded-2xl bg-gray-800 border border-gray-700"></div>
    </div>

    <!-- Empty state -->
    <div v-else-if="!filteredTables.length" class="flex flex-col items-center justify-center py-12 text-center">
      <div class="mb-4 rounded-full bg-gray-800 border border-gray-700 p-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 002-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
      </div>
      <p class="text-gray-400">{{ $t('crm.noTables', 'No tables found.') }}</p>
    </div>

    <!-- Table Cards -->
    <div v-else class="grid gap-3">
      <div
        v-for="table in filteredTables"
        :key="table.table_id"
        class="relative overflow-hidden rounded-2xl border border-gray-700 bg-gray-800 p-4 shadow-sm transition-all hover:border-yellow-500/50 hover:shadow-yellow-900/20 cursor-pointer"
        @click="openSurvey(table)"
      >
        <div class="flex justify-between items-start mb-2">
          <div>
            <h3 class="text-lg font-bold text-white">{{ table.table_code }}</h3>
            <p class="text-xs text-gray-400">{{ table.zone_name || 'No zone' }}</p>
          </div>
          <span :class="['px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider', statusClass(table.crm_status)]">
            {{ statusLabel(table.crm_status) }}
          </span>
        </div>
        
        <div class="flex items-center gap-4 text-sm text-gray-400 mt-4">
          <div class="flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-yellow-500/50" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
            <span>{{ table.guest_count }} {{ $t('crm.guests', 'Guests') }}</span>
          </div>
          <div class="flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-yellow-500/50" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
            </svg>
            <span>{{ formatTime(table.started_at) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Survey Modal (Bottom Sheet for Mobile) -->
    <Teleport to="body">
      <Transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="translate-y-full opacity-0"
        enter-to-class="translate-y-0 opacity-100"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="translate-y-0 opacity-100"
        leave-to-class="translate-y-full opacity-0"
      >
        <div v-if="selectedTable" class="fixed inset-0 z-50 flex items-end justify-center sm:items-center bg-gray-900/40 backdrop-blur-sm">
          <!-- Click outside to close -->
          <div class="absolute inset-0" @click="closeSurvey"></div>
          
          <div class="relative bg-gray-900 border-t border-gray-800 w-full rounded-t-3xl sm:rounded-3xl sm:max-w-md shadow-2xl shadow-yellow-900/20 flex flex-col max-h-[90vh]">
            <div class="flex justify-center pt-3 pb-2 sm:hidden" @click="closeSurvey">
              <div class="w-12 h-1.5 bg-gray-700 rounded-full"></div>
            </div>
            
            <div class="px-6 pb-4 border-b border-gray-800 flex justify-between items-center shrink-0 mt-4 sm:mt-0">
              <div>
                <h2 class="text-xl font-bold text-white">{{ $t('crm.surveyFor', 'Survey') }} {{ selectedTable.table_code }}</h2>
                <p class="text-sm text-yellow-500/80">{{ selectedTable.zone_name || '' }}</p>
              </div>
              <button @click="closeSurvey" class="rounded-full p-2 bg-gray-800 text-gray-400 hover:bg-gray-700">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
            
            <!-- Survey Content -->
            <div class="p-6 overflow-y-auto">
              <div v-if="selectedTable.crm_status === 'completed'" class="flex flex-col items-center justify-center py-8 text-center">
                <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 class="text-lg font-bold text-white mb-1">{{ $t('crm.surveyCompleted', 'Survey Completed') }}</h3>
                <p class="text-sm text-gray-500">{{ $t('crm.alreadySurveyed', 'This table has already been surveyed.') }}</p>
              </div>

              <form v-else @submit.prevent="submit" class="space-y-6">
                <!-- Customer Details -->
                <div class="space-y-4">
                  <h3 class="text-sm font-bold text-white uppercase tracking-wider">{{ $t('crm.customerDetails', 'Customer Details') }}</h3>
                  
                  <div>
                    <label class="block text-xs font-semibold text-gray-400 mb-1">{{ $t('crm.customerName', 'Customer Name') }}</label>
                    <input
                      v-model="surveyForm.customerName"
                      type="text"
                      class="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-white focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all placeholder-gray-500"
                      :placeholder="$t('crm.namePlaceholder', 'Enter name')"
                    />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-gray-400 mb-1">{{ $t('crm.phoneNumber', 'Phone Number') }}</label>
                    <input
                      v-model="surveyForm.customerPhone"
                      type="tel"
                      class="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-white focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all placeholder-gray-500"
                      :placeholder="$t('crm.phonePlaceholder', 'Enter phone')"
                    />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-gray-400 mb-1">{{ $t('crm.visitReason', 'Reason for Visit') }}</label>
                    <select
                      v-model="surveyForm.visitReason"
                      class="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-white focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all"
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
                  <h3 class="text-sm font-bold text-white uppercase tracking-wider">{{ $t('crm.generalFeedback', 'Feedback') }}</h3>
                  <div>
                    <textarea
                      v-model="surveyForm.feedback"
                      rows="3"
                      class="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-white focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all placeholder-gray-500"
                      :placeholder="$t('crm.feedbackPlaceholder', 'How was the experience?')"
                    ></textarea>
                  </div>
                  <div>
                    <label class="block text-xs font-semibold text-gray-400 mb-1">{{ $t('crm.improvementNotes', 'Improvement Notes') }}</label>
                    <textarea
                      v-model="surveyForm.improvementNote"
                      rows="2"
                      class="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-white focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all placeholder-gray-500"
                      :placeholder="$t('crm.improvementPlaceholder', 'What can we do better?')"
                    ></textarea>
                  </div>
                </div>

                <!-- Buttons -->
                <div class="pt-4 flex flex-col gap-3 pb-6 sm:pb-0">
                  <button
                    type="submit"
                    class="w-full rounded-xl bg-gradient-to-r from-yellow-500 to-yellow-600 px-4 py-3.5 text-sm font-bold text-gray-900 shadow-lg shadow-yellow-900/30 hover:opacity-90 transition-all active:scale-[0.98] disabled:opacity-50"
                    :disabled="crmStore.loading"
                  >
                    {{ crmStore.loading ? $t('crm.saving', 'Saving...') : $t('crm.submitSurvey', 'Submit Survey') }}
                  </button>
                  <button
                    v-if="selectedTable.crm_status === 'not_started' || selectedTable.crm_status === 'assigned'"
                    type="button"
                    class="w-full rounded-xl bg-gray-800 border border-gray-700 px-4 py-3.5 text-sm font-bold text-gray-300 hover:bg-gray-700 transition-all active:scale-[0.98] disabled:opacity-50"
                    :disabled="crmStore.loading"
                    @click="markInProgress"
                  >
                    {{ $t('crm.markInProgress', 'Mark as In Progress') }}
                  </button>
                  <button
                    type="button"
                    class="w-full rounded-xl bg-red-900/20 border border-red-900/50 text-red-400 px-4 py-3.5 text-sm font-bold hover:bg-red-900/40 transition-all active:scale-[0.98] disabled:opacity-50"
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
import { ref, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCrmStore } from '@/stores/crmStore'
import type { CrmServingTable, CrmSurveyInput, CrmSurveyStatus } from '@/stores/crmStore'

const { t } = useI18n()
const crmStore = useCrmStore()

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
}

onMounted(() => {
  refresh()
})

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
    case 'completed': return 'bg-green-900/30 text-green-400 border border-green-800'
    case 'in_progress': return 'bg-blue-900/30 text-blue-400 border border-blue-800'
    case 'not_started':
    case 'assigned': return 'bg-yellow-900/30 text-yellow-500 border border-yellow-700'
    case 'skipped':
    case 'customer_refused': return 'bg-gray-800 text-gray-400 border border-gray-700'
    default: return 'bg-gray-800 text-gray-400 border border-gray-700'
  }
}
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
