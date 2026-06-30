<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('accounting.tax') }}</h1>
        <p class="text-sm text-gray-500 mt-1">Manage VAT invoices and tax declarations</p>
      </div>
      <div class="flex items-center gap-3">
        <div class="relative">
          <SearchIcon class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Search records..." class="pl-9 pr-4 py-2 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))] focus:border-transparent w-64" />
        </div>
        <button class="flex items-center gap-2 rounded-xl bg-[hsl(var(--primary))] px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-[hsl(var(--primary))]/90 transition-colors">
          <PlusIcon class="w-4 h-4" />
          <span>New Record</span>
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-white p-4 rounded-t-2xl border-b border-gray-100 flex gap-4 overflow-x-auto border border-gray-200 border-b-0 shadow-sm">
      <button class="px-4 py-1.5 rounded-lg bg-[hsl(var(--primary))]/10 text-[hsl(var(--primary))] text-sm font-semibold whitespace-nowrap">All Records</button>
      <button class="px-4 py-1.5 rounded-lg text-gray-600 hover:bg-gray-50 text-sm font-medium whitespace-nowrap">Pending Review</button>
      <button class="px-4 py-1.5 rounded-lg text-gray-600 hover:bg-gray-50 text-sm font-medium whitespace-nowrap">Submitted</button>
      <button class="px-4 py-1.5 rounded-lg text-gray-600 hover:bg-gray-50 text-sm font-medium whitespace-nowrap">Rejected</button>
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-b-2xl shadow-sm border border-gray-200 overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-50/50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
            <th class="px-6 py-4 font-semibold">Record ID</th>
            <th class="px-6 py-4 font-semibold">Date</th>
            <th class="px-6 py-4 font-semibold">Type</th>
            <th class="px-6 py-4 font-semibold">Amount (VND)</th>
            <th class="px-6 py-4 font-semibold">Tax (VAT)</th>
            <th class="px-6 py-4 font-semibold">Status</th>
            <th class="px-6 py-4 font-semibold text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-if="loading">
            <td colspan="7" class="px-6 py-4 text-center text-gray-500">Loading records...</td>
          </tr>
          <tr v-else-if="records.length === 0">
            <td colspan="7" class="px-6 py-4 text-center text-gray-500">No tax records found.</td>
          </tr>
          <tr v-else v-for="record in records" :key="record.id" class="hover:bg-gray-50/50 transition-colors">
            <td class="px-6 py-4">
              <span class="font-semibold text-gray-800">{{ record.id.split('-')[0] }}</span>
            </td>
            <td class="px-6 py-4 text-sm text-gray-600">
              {{ record.period_start }} to {{ record.period_end }}
            </td>
            <td class="px-6 py-4">
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-700">
                <ReceiptIcon class="w-3 h-3" />
                {{ record.period_type }}
              </span>
            </td>
            <td class="px-6 py-4 font-medium text-gray-800">
              {{ Number(record.net_revenue || 0).toLocaleString() }}
            </td>
            <td class="px-6 py-4 text-sm text-gray-600">
              {{ Number(record.total_tax || 0).toLocaleString() }} ({{ record.vat_rate }}%)
            </td>
            <td class="px-6 py-4">
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700">
                {{ record.status }}
              </span>
            </td>
            <td class="px-6 py-4 text-right">
              <button class="p-1.5 text-gray-400 hover:text-gray-800 rounded-lg hover:bg-gray-100 transition-colors">
                <MoreVerticalIcon class="w-5 h-5" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      
      <!-- Pagination -->
      <div class="px-6 py-4 border-t border-gray-100 flex items-center justify-between text-sm text-gray-500">
        <span>Showing records</span>
        <div class="flex gap-1">
          <button class="px-3 py-1 rounded-md border border-gray-200 hover:bg-gray-50 disabled:opacity-50">Prev</button>
          <button class="px-3 py-1 rounded-md bg-[hsl(var(--primary))] text-white font-medium">1</button>
          <button class="px-3 py-1 rounded-md border border-gray-200 hover:bg-gray-50">Next</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { 
  SearchIcon, 
  PlusIcon, 
  ReceiptIcon, 
  MoreVerticalIcon 
} from 'lucide-vue-next'
import { useAccounting } from '@/composables/useAccounting'
import { useI18n } from 'vue-i18n'

const { fetchTaxRecords, loading } = useAccounting()
const records = ref<any[]>([])
const { t } = useI18n()

onMounted(async () => {
  try {
    records.value = await fetchTaxRecords()
  } catch (e) {
    console.error(e)
  }
})
</script>
