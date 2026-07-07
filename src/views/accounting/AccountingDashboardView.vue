<template>
  <div class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.dashboard.title') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-0.5">{{ i18n.t('accounting.dashboard.subtitle') }}</p>
      </div>
      <div class="flex items-center gap-2">
        <select v-if="isManager" v-model="selectedBranch" class="kawaii-input py-1.5 text-sm w-40 max-w-xs truncate" @change="loadDashboard">
          <option value="all">{{ i18n.t('accounting.allBranches') }}</option>
          <option v-for="b in branches" :key="b.id" :value="b.id">{{ b.name }} ({{ b.code }})</option>
        </select>
        <select v-model="selectedMonth" class="kawaii-input py-1.5 text-sm w-20">
          <option v-for="m in months" :key="m.value" :value="m.value">{{ m.label }}</option>
        </select>
        <select v-model="selectedYear" class="kawaii-input py-1.5 text-sm w-24">
          <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
        </select>
        <button @click="loadDashboard" class="kawaii-btn-primary px-3 py-1.5 text-sm flex items-center gap-2">
          <RefreshCwIcon class="w-3.5 h-3.5" />
          <span class="hidden sm:inline">{{ i18n.t('common.refresh') }}</span>
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="grid grid-cols-4 gap-4">
      <div v-for="i in 4" :key="i" class="kawaii-card p-5 animate-pulse h-28 bg-[hsl(var(--muted))]"></div>
    </div>

    <!-- KPI Cards -->
    <div v-else-if="dashboard" class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Total Income -->
      <div class="kawaii-card p-5 border-l-4 border-green-500">
        <div class="flex justify-between items-start mb-3">
          <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">
            {{ i18n.t('accounting.dashboard.totalIncome') }}
          </p>
          <span class="w-8 h-8 rounded-xl bg-green-100 flex items-center justify-center">
            <TrendingUpIcon class="w-4 h-4 text-green-600" />
          </span>
        </div>
        <p class="text-2xl font-black text-green-600">{{ formatCurrency(dashboard.total_income) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))] mt-1">{{ i18n.t('accounting.dashboard.approvedOnly') }}</p>
      </div>

      <!-- Total Expense -->
      <div class="kawaii-card p-5 border-l-4 border-red-500">
        <div class="flex justify-between items-start mb-3">
          <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">
            {{ i18n.t('accounting.dashboard.totalExpense') }}
          </p>
          <span class="w-8 h-8 rounded-xl bg-red-100 flex items-center justify-center">
            <TrendingDownIcon class="w-4 h-4 text-red-600" />
          </span>
        </div>
        <p class="text-2xl font-black text-red-600">{{ formatCurrency(dashboard.total_expense) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))] mt-1">{{ i18n.t('accounting.dashboard.approvedOnly') }}</p>
      </div>

      <!-- Net Cash Flow -->
      <div class="kawaii-card p-5 border-l-4" :class="dashboard.net_cashflow >= 0 ? 'border-blue-500' : 'border-orange-500'">
        <div class="flex justify-between items-start mb-3">
          <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">
            {{ i18n.t('accounting.dashboard.netCashflow') }}
          </p>
          <span class="w-8 h-8 rounded-xl flex items-center justify-center"
            :class="dashboard.net_cashflow >= 0 ? 'bg-blue-100' : 'bg-orange-100'">
            <DollarSignIcon class="w-4 h-4" :class="dashboard.net_cashflow >= 0 ? 'text-blue-600' : 'text-orange-600'" />
          </span>
        </div>
        <p class="text-2xl font-black" :class="dashboard.net_cashflow >= 0 ? 'text-blue-600' : 'text-orange-600'">
          {{ dashboard.net_cashflow >= 0 ? '+' : '' }}{{ formatCurrency(dashboard.net_cashflow) }}
        </p>
        <p class="text-xs text-[hsl(var(--muted-foreground))] mt-1">{{ i18n.t('accounting.dashboard.netMonthly') }}</p>
      </div>

      <!-- AP Outstanding -->
      <div class="kawaii-card p-5 border-l-4 border-amber-500">
        <div class="flex justify-between items-start mb-3">
          <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase tracking-wider">
            {{ i18n.t('accounting.dashboard.apOutstanding') }}
          </p>
          <span class="w-8 h-8 rounded-xl bg-amber-100 flex items-center justify-center">
            <AlertCircleIcon class="w-4 h-4 text-amber-600" />
          </span>
        </div>
        <p class="text-2xl font-black text-amber-600">{{ formatCurrency(dashboard.ap_unpaid_amount) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))] mt-1">
          {{ dashboard.ap_unpaid_count }} {{ i18n.t('accounting.dashboard.invoices') }}
          <span v-if="dashboard.ap_overdue_count > 0" class="text-red-500 font-bold ml-1">
            ({{ dashboard.ap_overdue_count }} {{ i18n.t('accounting.dashboard.overdue') }})
          </span>
        </p>
      </div>
    </div>

    <!-- Pending / Draft alerts -->
    <div v-if="dashboard && (dashboard.pending_count > 0 || dashboard.draft_count > 0)"
      class="flex gap-3 flex-wrap">
      <div v-if="dashboard.pending_count > 0"
        class="flex items-center gap-2 px-4 py-2 bg-yellow-50 border border-yellow-200 rounded-xl text-sm text-yellow-800">
        <ClockIcon class="w-4 h-4" />
        <span>{{ dashboard.pending_count }} {{ i18n.t('accounting.dashboard.pendingApproval') }}</span>
        <router-link to="/accounting/cashflow" class="font-bold underline">{{ i18n.t('accounting.dashboard.review') }}</router-link>
      </div>
      <div v-if="dashboard.draft_count > 0"
        class="flex items-center gap-2 px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700">
        <FileTextIcon class="w-4 h-4" />
        <span>{{ dashboard.draft_count }} {{ i18n.t('accounting.dashboard.draftEntries') }}</span>
        <router-link to="/accounting/cashflow" class="font-bold underline">{{ i18n.t('accounting.dashboard.view') }}</router-link>
      </div>
    </div>

    <!-- P&L Quick View -->
    <div class="kawaii-card overflow-hidden">
      <div class="p-5 border-b border-[hsl(var(--border))] flex justify-between items-center">
        <h2 class="font-bold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.pl.title') }}</h2>
        <router-link to="/accounting/pl-report"
          class="text-xs font-bold text-[hsl(var(--primary))] hover:underline flex items-center gap-1">
          {{ i18n.t('accounting.dashboard.viewFull') }} <ChevronRightIcon class="w-3.5 h-3.5" />
        </router-link>
      </div>
      <div v-if="plLoading" class="p-5 text-center text-sm text-[hsl(var(--muted-foreground))]">
        {{ i18n.t('common.loading') }}
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-[hsl(var(--muted))]/50">
              <th class="px-5 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.category') }}</th>
              <th class="px-5 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.thisMonth') }}</th>
              <th class="px-5 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.ytd') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <!-- Income rows -->
            <tr v-for="row in plIncome" :key="row.category_code" class="hover:bg-[hsl(var(--muted))]/30">
              <td class="px-5 py-3">
                <div class="flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-green-500 shrink-0"></span>
                  <span class="text-[hsl(var(--foreground))]">{{ row.category_name }}</span>
                  <span class="text-xs text-[hsl(var(--muted-foreground))]">{{ row.category_code }}</span>
                </div>
              </td>
              <td class="px-5 py-3 text-right font-semibold text-green-600">{{ formatCurrency(row.month_amount) }}</td>
              <td class="px-5 py-3 text-right text-green-600">{{ formatCurrency(row.ytd_amount) }}</td>
            </tr>
            <!-- Income subtotal -->
            <tr class="bg-green-50">
              <td class="px-5 py-2 font-bold text-green-700">{{ i18n.t('accounting.pl.totalIncome') }}</td>
              <td class="px-5 py-2 text-right font-bold text-green-700">
                {{ formatCurrency(plIncome.reduce((s, r) => s + Number(r.month_amount), 0)) }}
              </td>
              <td class="px-5 py-2 text-right font-bold text-green-700">
                {{ formatCurrency(plIncome.reduce((s, r) => s + Number(r.ytd_amount), 0)) }}
              </td>
            </tr>
            <!-- Expense rows -->
            <tr v-for="row in plExpense" :key="row.category_code" class="hover:bg-[hsl(var(--muted))]/30">
              <td class="px-5 py-3">
                <div class="flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-red-500 shrink-0"></span>
                  <span class="text-[hsl(var(--foreground))]">{{ row.category_name }}</span>
                  <span class="text-xs text-[hsl(var(--muted-foreground))]">{{ row.category_code }}</span>
                </div>
              </td>
              <td class="px-5 py-3 text-right font-semibold text-red-600">{{ formatCurrency(row.month_amount) }}</td>
              <td class="px-5 py-3 text-right text-red-600">{{ formatCurrency(row.ytd_amount) }}</td>
            </tr>
            <!-- Expense subtotal -->
            <tr class="bg-red-50">
              <td class="px-5 py-2 font-bold text-red-700">{{ i18n.t('accounting.pl.totalExpense') }}</td>
              <td class="px-5 py-2 text-right font-bold text-red-700">
                {{ formatCurrency(plExpense.reduce((s, r) => s + Number(r.month_amount), 0)) }}
              </td>
              <td class="px-5 py-2 text-right font-bold text-red-700">
                {{ formatCurrency(plExpense.reduce((s, r) => s + Number(r.ytd_amount), 0)) }}
              </td>
            </tr>
            <!-- Net P&L -->
            <tr class="font-extrabold text-base" :class="plNetMonth >= 0 ? 'bg-blue-50' : 'bg-orange-50'">
              <td class="px-5 py-3" :class="plNetMonth >= 0 ? 'text-blue-700' : 'text-orange-700'">
                {{ i18n.t('accounting.pl.netPL') }}
              </td>
              <td class="px-5 py-3 text-right" :class="plNetMonth >= 0 ? 'text-blue-700' : 'text-orange-700'">
                {{ plNetMonth >= 0 ? '+' : '' }}{{ formatCurrency(plNetMonth) }}
              </td>
              <td class="px-5 py-3 text-right" :class="plNetYTD >= 0 ? 'text-blue-700' : 'text-orange-700'">
                {{ plNetYTD >= 0 ? '+' : '' }}{{ formatCurrency(plNetYTD) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import {
  TrendingUpIcon, TrendingDownIcon, DollarSignIcon, AlertCircleIcon,
  ClockIcon, FileTextIcon, RefreshCwIcon, ChevronRightIcon
} from 'lucide-vue-next'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import type { Branch } from '@/types/database'
import { useAccountingModule } from '@/composables/useAccountingModule'
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
const { role } = useAuth()
const { listBranches } = useBranch()
const { dashboard, loading, fetchDashboard, plReport, plIncome, plExpense, plNetMonth, plNetYTD, fetchPLReport } = useAccountingModule()

const isManager = computed(() => role.value === 'accounting_manager' || role.value === 'superadmin' || role.value === 'admin')
const branches = ref<Branch[]>([])
const selectedBranch = ref<string>('all')

const plLoading = ref(false)
const now = new Date()
const selectedMonth = ref(now.getMonth() + 1)
const selectedYear = ref(now.getFullYear())

const months = [
  { value: 1, label: 'T1' }, { value: 2, label: 'T2' }, { value: 3, label: 'T3' },
  { value: 4, label: 'T4' }, { value: 5, label: 'T5' }, { value: 6, label: 'T6' },
  { value: 7, label: 'T7' }, { value: 8, label: 'T8' }, { value: 9, label: 'T9' },
  { value: 10, label: 'T10' }, { value: 11, label: 'T11' }, { value: 12, label: 'T12' },
]
const years = Array.from({ length: 5 }, (_, i) => now.getFullYear() - 2 + i)

function formatCurrency(val: number | null | undefined) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val ?? 0)
}

async function loadDashboard() {
  const bId = selectedBranch.value === 'all' ? null : selectedBranch.value
  await fetchDashboard(bId, selectedYear.value, selectedMonth.value)
  plLoading.value = true
  try {
    await fetchPLReport(bId, selectedYear.value, selectedMonth.value)
  } finally {
    plLoading.value = false
  }
}

onMounted(async () => {
  if (isManager.value) {
    try {
      branches.value = await listBranches()
    } catch (e) {
      console.error('Failed to list branches', e)
    }
  }
  loadDashboard()
})
</script>
