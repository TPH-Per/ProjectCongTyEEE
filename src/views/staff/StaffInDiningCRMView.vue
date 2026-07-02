<template>
  <div class="min-h-full bg-gray-50 p-4">
    <div class="mb-5 flex items-center gap-3">
      <RouterLink to="/staff/active-tables" class="flex h-9 w-9 items-center justify-center rounded-lg bg-white text-gray-600 shadow-sm">
        ‹
      </RouterLink>
      <div>
        <h1 class="text-xl font-black text-gray-900">{{ currentTable?.table_code || 'CRM Survey' }}</h1>
        <p class="text-xs font-semibold text-gray-500">
          {{ currentTable ? `Order ${currentTable.order_id.slice(0, 8)}` : 'No serving order found' }}
        </p>
      </div>
    </div>

    <div v-if="error" class="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700">
      {{ error }}
    </div>

    <div v-if="!currentTable && !loading" class="rounded-lg border border-gray-200 bg-white p-8 text-center text-sm text-gray-500">
      This table has no active serving order.
    </div>

    <form v-else class="space-y-4 rounded-lg border border-gray-200 bg-white p-4" @submit.prevent="submitSurvey">
      <div class="rounded-lg bg-gray-50 p-3 text-sm font-bold text-gray-700">
        CRM status: {{ currentTable?.crm_status || 'not_started' }}
      </div>

      <label class="block">
        <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Source</span>
        <select v-model="form.sourceCode" class="h-11 w-full rounded-lg border border-gray-200 bg-gray-50 px-3 text-sm font-semibold">
          <option value="">Select source</option>
          <option value="google_map">Google Map</option>
          <option value="facebook">Facebook</option>
          <option value="tiktok">TikTok</option>
          <option value="friend_referral">Friend referral</option>
          <option value="walk_by">Walk by</option>
          <option value="returning_customer">Returning customer</option>
          <option value="other">Other</option>
        </select>
      </label>

      <label class="block">
        <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Visit reason</span>
        <select v-model="form.visitReason" class="h-11 w-full rounded-lg border border-gray-200 bg-gray-50 px-3 text-sm font-semibold">
          <option value="">Select reason</option>
          <option value="family_meal">Family meal</option>
          <option value="birthday">Birthday</option>
          <option value="date">Date</option>
          <option value="company">Company</option>
          <option value="friends">Friends</option>
          <option value="first_try">First try</option>
          <option value="regular">Regular customer</option>
          <option value="other">Other</option>
        </select>
      </label>

      <label class="block">
        <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Feedback</span>
        <textarea v-model="form.feedback" rows="3" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm" />
      </label>

      <label class="block">
        <span class="mb-1 block text-xs font-bold uppercase text-gray-500">Improvement note</span>
        <textarea v-model="form.improvementNote" rows="3" class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm" />
      </label>

      <div class="grid gap-3 sm:grid-cols-2">
        <input v-model="form.customerName" placeholder="Customer name optional" class="h-11 rounded-lg border border-gray-200 bg-gray-50 px-3 text-sm" />
        <input v-model="form.customerPhone" placeholder="Phone optional" inputmode="tel" class="h-11 rounded-lg border border-gray-200 bg-gray-50 px-3 text-sm" />
      </div>

      <label class="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-semibold text-gray-700">
        <input v-model="form.marketingConsent" type="checkbox" class="h-4 w-4 accent-red-600" />
        Marketing consent
      </label>

      <div class="grid gap-2 sm:grid-cols-3">
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-3 text-sm font-black text-white disabled:opacity-50" :disabled="loading || !currentTable">
          {{ loading ? 'Saving...' : 'Submit' }}
        </button>
        <button type="button" class="rounded-lg border border-gray-300 bg-white px-4 py-3 text-sm font-black text-gray-700" @click="markRefused">
          Refused
        </button>
        <button type="button" class="rounded-lg border border-gray-300 bg-white px-4 py-3 text-sm font-black text-gray-700" @click="skipSurvey">
          Skip
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useCRM, type CrmServingTable } from '@/composables/useCRM'

const route = useRoute()
const router = useRouter()
const tableId = route.params.id as string
const { loading, error, listServingTables, markSurveyInProgress, submitTableSurvey, refuseTableSurvey, skipTableSurvey } = useCRM()

const servingTables = ref<CrmServingTable[]>([])
const currentTable = computed(() => servingTables.value.find((table) => table.table_id === tableId) ?? null)

const form = ref({
  sourceCode: '',
  visitReason: '',
  feedback: '',
  improvementNote: '',
  customerName: '',
  customerPhone: '',
  marketingConsent: false,
})

async function load() {
  servingTables.value = await listServingTables()
  if (currentTable.value?.crm_status === 'not_started') {
    await markSurveyInProgress(currentTable.value)
    servingTables.value = await listServingTables()
  }
}

async function submitSurvey() {
  if (!currentTable.value) return
  await submitTableSurvey({
    tableId: currentTable.value.table_id,
    orderId: currentTable.value.order_id,
    tableAssignmentId: currentTable.value.table_assignment_id,
    sourceCode: form.value.sourceCode,
    visitReason: form.value.visitReason,
    feedback: form.value.feedback,
    improvementNote: form.value.improvementNote,
    customerName: form.value.customerName,
    customerPhone: form.value.customerPhone,
    marketingConsent: form.value.marketingConsent,
  })
  router.push('/staff/active-tables')
}

async function markRefused() {
  if (!currentTable.value) return
  await refuseTableSurvey(currentTable.value)
  router.push('/staff/active-tables')
}

async function skipSurvey() {
  if (!currentTable.value) return
  await skipTableSurvey(currentTable.value)
  router.push('/staff/active-tables')
}

onMounted(load)
</script>
