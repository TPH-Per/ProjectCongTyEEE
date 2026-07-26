<template>
  <div class="p-6 space-y-5">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.pl.title') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-0.5">{{ i18n.t('accounting.pl.subtitle') }}</p>
      </div>
      <div class="flex gap-2 items-center">
        <select v-model="selectedMonth" class="kawaii-input py-1.5 text-sm w-32">
          <option v-for="m in months" :key="m.value" :value="m.value">{{ m.label }}</option>
        </select>
        <select v-model="selectedYear" class="kawaii-input py-1.5 text-sm w-24">
          <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
        </select>
        <button @click="load" class="kawaii-btn-primary px-4 py-1.5 text-sm flex items-center gap-2">
          <RefreshCwIcon class="w-3.5 h-3.5" />
          {{ i18n.t('common.refresh') }}
        </button>
      </div>
    </div>

    <!-- Net P&L Summary -->
    <div class="grid grid-cols-3 gap-4">
      <div class="kawaii-card p-5 border-l-4 border-green-500">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.pl.totalIncome') }}</p>
        <p class="text-2xl font-black text-green-600">{{ formatCurrency(totalIncome) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.ytd') }}: {{ formatCurrency(totalIncomeYTD) }}</p>
      </div>
      <div class="kawaii-card p-5 border-l-4 border-red-500">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.pl.totalExpense') }}</p>
        <p class="text-2xl font-black text-red-600">{{ formatCurrency(totalExpense) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.ytd') }}: {{ formatCurrency(totalExpenseYTD) }}</p>
      </div>
      <div class="kawaii-card p-5 border-l-4" :class="plNetMonth >= 0 ? 'border-blue-500' : 'border-orange-500'">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.pl.netPL') }}</p>
        <p class="text-2xl font-black" :class="plNetMonth >= 0 ? 'text-blue-600' : 'text-orange-600'">
          {{ plNetMonth >= 0 ? '+' : '' }}{{ formatCurrency(plNetMonth) }}
        </p>
        <p class="text-xs" :class="plNetYTD >= 0 ? 'text-blue-600' : 'text-orange-600'">
          {{ i18n.t('accounting.pl.ytd') }}: {{ plNetYTD >= 0 ? '+' : '' }}{{ formatCurrency(plNetYTD) }}
        </p>
      </div>
    </div>

    <!-- Detailed P&L Table -->
    <div class="kawaii-card overflow-hidden">
      <div v-if="loading" class="p-8 text-center text-sm text-[hsl(var(--muted-foreground))]">{{ i18n.t('common.loading') }}</div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-[hsl(var(--muted))]/50 border-b border-[hsl(var(--border))]">
              <th class="px-5 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.category') }}</th>
              <th class="px-5 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.type') }}</th>
              <th class="px-5 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.thisMonth') }}</th>
              <th class="px-5 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.pl.ytd') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <!-- Income section -->
            <tr class="bg-green-50/60">
              <td colspan="4" class="px-5 py-2 text-xs font-extrabold uppercase tracking-wider text-green-700">
                📈 {{ i18n.t('accounting.pl.incomeSection') }}
              </td>
            </tr>
            <tr v-for="row in plIncome" :key="row.category_code"
              class="hover:bg-[hsl(var(--muted))]/30">
              <td class="px-5 py-3">
                <div class="flex items-center gap-2">
                  <span class="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                  <span class="font-medium text-[hsl(var(--foreground))]">{{ row.category_name }}</span>
                </div>
              </td>
              <td class="px-5 py-3 text-xs text-[hsl(var(--muted-foreground))]">{{ row.category_code }}</td>
              <td class="px-5 py-3 text-right font-semibold text-green-600">{{ formatCurrency(row.month_amount) }}</td>
              <td class="px-5 py-3 text-right text-green-600">{{ formatCurrency(row.ytd_amount) }}</td>
            </tr>
            <tr class="bg-green-100/70 font-bold">
              <td class="px-5 py-2.5 text-green-800">{{ i18n.t('accounting.pl.totalIncome') }}</td>
              <td></td>
              <td class="px-5 py-2.5 text-right text-green-800">{{ formatCurrency(totalIncome) }}</td>
              <td class="px-5 py-2.5 text-right text-green-800">{{ formatCurrency(totalIncomeYTD) }}</td>
            </tr>

            <!-- Expense section -->
            <tr class="bg-red-50/60">
              <td colspan="4" class="px-5 py-2 text-xs font-extrabold uppercase tracking-wider text-red-700">
                📉 {{ i18n.t('accounting.pl.expenseSection') }}
              </td>
            </tr>
            <tr v-for="row in plExpense" :key="row.category_code"
              class="hover:bg-[hsl(var(--muted))]/30">
              <td class="px-5 py-3">
                <div class="flex items-center gap-2">
                  <span class="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                  <span class="font-medium text-[hsl(var(--foreground))]">{{ row.category_name }}</span>
                </div>
              </td>
              <td class="px-5 py-3 text-xs text-[hsl(var(--muted-foreground))]">{{ row.category_code }}</td>
              <td class="px-5 py-3 text-right font-semibold text-red-600">{{ formatCurrency(row.month_amount) }}</td>
              <td class="px-5 py-3 text-right text-red-600">{{ formatCurrency(row.ytd_amount) }}</td>
            </tr>
            <tr class="bg-red-100/70 font-bold">
              <td class="px-5 py-2.5 text-red-800">{{ i18n.t('accounting.pl.totalExpense') }}</td>
              <td></td>
              <td class="px-5 py-2.5 text-right text-red-800">{{ formatCurrency(totalExpense) }}</td>
              <td class="px-5 py-2.5 text-right text-red-800">{{ formatCurrency(totalExpenseYTD) }}</td>
            </tr>

            <!-- Net -->
            <tr class="font-extrabold text-base border-t-2 border-[hsl(var(--border))]"
              :class="plNetMonth >= 0 ? 'bg-blue-50' : 'bg-orange-50'">
              <td class="px-5 py-4" :class="plNetMonth >= 0 ? 'text-blue-700' : 'text-orange-700'">
                {{ i18n.t('accounting.pl.netPL') }}
              </td>
              <td></td>
              <td class="px-5 py-4 text-right text-xl" :class="plNetMonth >= 0 ? 'text-blue-700' : 'text-orange-700'">
                {{ plNetMonth >= 0 ? '+' : '' }}{{ formatCurrency(plNetMonth) }}
              </td>
              <td class="px-5 py-4 text-right text-xl" :class="plNetYTD >= 0 ? 'text-blue-700' : 'text-orange-700'">
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
import { ref, computed, onMounted } from 'vue'
import { RefreshCwIcon } from 'lucide-vue-next'
import { useAccountingModule } from '@/composables/useAccountingModule'
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
const { plReport, plIncome, plExpense, plNetMonth, plNetYTD, loading, fetchPLReport } = useAccountingModule()

const now = new Date()
const selectedMonth = ref(now.getMonth() + 1)
const selectedYear = ref(now.getFullYear())

const months = [
  { value: 1, label: 'Tháng 1' }, { value: 2, label: 'Tháng 2' }, { value: 3, label: 'Tháng 3' },
  { value: 4, label: 'Tháng 4' }, { value: 5, label: 'Tháng 5' }, { value: 6, label: 'Tháng 6' },
  { value: 7, label: 'Tháng 7' }, { value: 8, label: 'Tháng 8' }, { value: 9, label: 'Tháng 9' },
  { value: 10, label: 'Tháng 10' }, { value: 11, label: 'Tháng 11' }, { value: 12, label: 'Tháng 12' },
]
const years = Array.from({ length: 5 }, (_, i) => now.getFullYear() - 2 + i)

const totalIncome = computed(() => plIncome.value.reduce((s, r) => s + Number(r.month_amount), 0))
const totalIncomeYTD = computed(() => plIncome.value.reduce((s, r) => s + Number(r.ytd_amount), 0))
const totalExpense = computed(() => plExpense.value.reduce((s, r) => s + Number(r.month_amount), 0))
const totalExpenseYTD = computed(() => plExpense.value.reduce((s, r) => s + Number(r.ytd_amount), 0))

function formatCurrency(v: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(v ?? 0)
}

async function load() {
  await fetchPLReport(null, selectedYear.value, selectedMonth.value)
}

onMounted(load)
</script>
