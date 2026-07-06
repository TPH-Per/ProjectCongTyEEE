<template>
  <div class="p-6 space-y-5">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.ap.title') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-0.5">{{ i18n.t('accounting.ap.subtitle') }}</p>
      </div>
      <button @click="isPanelOpen = true" class="kawaii-btn-primary px-4 py-2 flex items-center gap-2 text-sm">
        <PlusIcon class="w-4 h-4" />
        {{ i18n.t('accounting.ap.recordPayment') }}
      </button>
    </div>

    <!-- Summary cards -->
    <div class="grid grid-cols-3 gap-4">
      <div class="kawaii-card p-4 border-l-4 border-red-500">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.ap.unpaid') }}</p>
        <p class="text-2xl font-black text-red-600">{{ formatCurrency(summary.unpaid) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))]">{{ summary.unpaidCount }} {{ i18n.t('accounting.ap.invoices') }}</p>
      </div>
      <div class="kawaii-card p-4 border-l-4 border-yellow-500">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.ap.partial') }}</p>
        <p class="text-2xl font-black text-yellow-600">{{ formatCurrency(summary.partial) }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))]">{{ summary.partialCount }} {{ i18n.t('accounting.ap.invoices') }}</p>
      </div>
      <div class="kawaii-card p-4 border-l-4 border-orange-500">
        <p class="text-xs font-semibold text-[hsl(var(--muted-foreground))] uppercase mb-2">{{ i18n.t('accounting.ap.overdue') }}</p>
        <p class="text-2xl font-black text-orange-600">{{ summary.overdueCount }}</p>
        <p class="text-xs text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.overdueDesc') }}</p>
      </div>
    </div>

    <!-- Table -->
    <div class="kawaii-card overflow-hidden">
      <div class="p-4 border-b border-[hsl(var(--border))] flex gap-3">
        <select v-model="filterStatus" class="kawaii-input py-1.5 text-sm w-40">
          <option value="">{{ i18n.t('accounting.ap.allStatuses') }}</option>
          <option value="unpaid">{{ i18n.t('accounting.ap.statusUnpaid') }}</option>
          <option value="partial">{{ i18n.t('accounting.ap.statusPartial') }}</option>
          <option value="paid">{{ i18n.t('accounting.ap.statusPaid') }}</option>
          <option value="overdue">{{ i18n.t('accounting.ap.statusOverdue') }}</option>
        </select>
        <button @click="loadAP" class="kawaii-btn-primary px-3 py-1.5 text-sm">{{ i18n.t('common.filter') }}</button>
      </div>

      <div v-if="loading" class="p-8 text-center text-sm text-[hsl(var(--muted-foreground))]">
        {{ i18n.t('common.loading') }}
      </div>
      <div v-else-if="apRecords.length === 0" class="p-12 text-center text-[hsl(var(--muted-foreground))]">
        {{ i18n.t('accounting.ap.empty') }}
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-[hsl(var(--muted))]/50 border-b border-[hsl(var(--border))]">
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.supplier') }}</th>
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.invoiceRef') }}</th>
              <th class="px-4 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.totalAmount') }}</th>
              <th class="px-4 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.paidAmount') }}</th>
              <th class="px-4 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.outstanding') }}</th>
              <th class="px-4 py-3 text-center font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.dueDate') }}</th>
              <th class="px-4 py-3 text-center font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.ap.status_col') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-for="rec in apRecords" :key="rec.id"
              class="hover:bg-[hsl(var(--muted))]/30 transition-colors"
              :class="rec.is_overdue ? 'bg-red-50/50' : ''">
              <td class="px-4 py-3">
                <div class="font-medium text-[hsl(var(--foreground))]">{{ rec.supplier_name || i18n.t('accounting.ap.unknownSupplier') }}</div>
                <div class="text-xs text-[hsl(var(--muted-foreground))]">{{ rec.branch_name }}</div>
              </td>
              <td class="px-4 py-3 text-[hsl(var(--foreground))]">{{ rec.invoice_ref || '—' }}</td>
              <td class="px-4 py-3 text-right font-semibold text-[hsl(var(--foreground))]">{{ formatCurrency(rec.total_amount) }}</td>
              <td class="px-4 py-3 text-right text-green-600 font-medium">{{ formatCurrency(rec.paid_amount) }}</td>
              <td class="px-4 py-3 text-right font-bold" :class="rec.outstanding > 0 ? 'text-red-600' : 'text-[hsl(var(--muted-foreground))]'">
                {{ formatCurrency(rec.outstanding) }}
              </td>
              <td class="px-4 py-3 text-center">
                <span :class="rec.is_overdue ? 'text-red-600 font-bold' : 'text-[hsl(var(--foreground))]'">
                  {{ rec.due_date ? formatDate(rec.due_date) : '—' }}
                  <span v-if="rec.is_overdue" class="ml-1 text-xs">⚠️</span>
                </span>
              </td>
              <td class="px-4 py-3 text-center">
                <span :class="apStatusClass(rec.status)" class="px-2 py-0.5 rounded-full text-xs font-bold">
                  {{ i18n.t(`accounting.ap.status_${rec.status}`) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Record AP Payment Panel -->
    <div v-if="isPanelOpen" class="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex justify-end">
      <div class="bg-white w-[440px] h-full shadow-2xl flex flex-col">
        <div class="p-5 border-b border-[hsl(var(--border))] flex justify-between items-center">
          <h2 class="text-lg font-bold">{{ i18n.t('accounting.ap.recordTitle') }}</h2>
          <button @click="isPanelOpen = false" class="p-2 rounded-full hover:bg-[hsl(var(--border))]">
            <XIcon class="w-5 h-5" />
          </button>
        </div>
        <div class="flex-1 p-6 space-y-4 overflow-y-auto">
          <div>
            <label class="block text-sm font-medium mb-1.5">{{ i18n.t('accounting.ap.invoiceRef') }}</label>
            <input v-model="form.invoice_ref" class="kawaii-input py-2.5" placeholder="INV-2024-001" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1.5">{{ i18n.t('accounting.ap.totalAmount') }} *</label>
            <input v-model.number="form.total_amount" type="number" class="kawaii-input py-2.5" min="0" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1.5">{{ i18n.t('accounting.ap.paidAmount') }}</label>
            <input v-model.number="form.paid_amount" type="number" class="kawaii-input py-2.5" min="0" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1.5">{{ i18n.t('accounting.ap.dueDate') }}</label>
            <input v-model="form.due_date" type="date" class="kawaii-input py-2.5" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1.5">{{ i18n.t('common.notes') }}</label>
            <textarea v-model="form.notes" rows="2" class="kawaii-input py-2.5"></textarea>
          </div>
        </div>
        <div class="p-5 border-t border-[hsl(var(--border))] flex justify-end gap-3">
          <button @click="isPanelOpen = false" class="px-4 py-2 text-sm text-[hsl(var(--muted-foreground))]">
            {{ i18n.t('common.cancel') }}
          </button>
          <button @click="saveAP" :disabled="isSaving" class="kawaii-btn-primary px-5 py-2 text-sm">
            {{ isSaving ? i18n.t('common.saving') : i18n.t('common.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { PlusIcon, XIcon } from 'lucide-vue-next'
import { useAccountingModule } from '@/composables/useAccountingModule'
import { useAuth } from '@/composables/useAuth'
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
const { profile } = useAuth()
const { apRecords, loading, fetchAPSummary, recordAPPayment } = useAccountingModule()

const filterStatus = ref('')
const isPanelOpen = ref(false)
const isSaving = ref(false)

const form = ref({
  invoice_ref: '',
  total_amount: 0,
  paid_amount: 0,
  due_date: '',
  notes: '',
})

const summary = computed(() => ({
  unpaid: apRecords.value.filter(r => r.status === 'unpaid').reduce((s, r) => s + Number(r.outstanding), 0),
  unpaidCount: apRecords.value.filter(r => r.status === 'unpaid').length,
  partial: apRecords.value.filter(r => r.status === 'partial').reduce((s, r) => s + Number(r.outstanding), 0),
  partialCount: apRecords.value.filter(r => r.status === 'partial').length,
  overdueCount: apRecords.value.filter(r => r.is_overdue).length,
}))

function formatCurrency(v: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(v ?? 0)
}
function formatDate(d: string) {
  return new Date(d).toLocaleDateString('vi-VN')
}
function apStatusClass(s: string) {
  return {
    unpaid: 'bg-red-100 text-red-700',
    partial: 'bg-yellow-100 text-yellow-700',
    paid: 'bg-green-100 text-green-700',
    overdue: 'bg-orange-100 text-orange-700',
  }[s] ?? 'bg-gray-100 text-gray-600'
}

async function loadAP() {
  await fetchAPSummary(null, filterStatus.value || undefined)
}

async function saveAP() {
  if (!form.value.total_amount) return
  isSaving.value = true
  try {
    await recordAPPayment({
      branch_id: profile.value?.branch_id ?? '',
      supplier_id: null,
      invoice_ref: form.value.invoice_ref,
      total_amount: form.value.total_amount,
      paid_amount: form.value.paid_amount,
      due_date: form.value.due_date || undefined,
      notes: form.value.notes,
    })
    isPanelOpen.value = false
    form.value = { invoice_ref: '', total_amount: 0, paid_amount: 0, due_date: '', notes: '' }
    await loadAP()
  } catch (e: any) {
    alert(e.message)
  } finally {
    isSaving.value = false
  }
}

onMounted(loadAP)
</script>
