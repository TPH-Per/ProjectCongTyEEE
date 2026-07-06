<template>
  <div class="p-6 space-y-5">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.cashflow.title') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-0.5">{{ i18n.t('accounting.cashflow.subtitle') }}</p>
      </div>
      <button @click="openCreate" class="kawaii-btn-primary px-4 py-2 flex items-center gap-2 text-sm">
        <PlusIcon class="w-4 h-4" />
        {{ i18n.t('accounting.cashflow.create') }}
      </button>
    </div>

    <!-- Filters -->
    <div class="kawaii-card p-4 flex flex-wrap gap-3 items-center">
      <select v-model="filters.type" class="kawaii-input py-1.5 text-sm w-40">
        <option value="">{{ i18n.t('accounting.cashflow.allTypes') }}</option>
        <option value="income">{{ i18n.t('accounting.cashflow.income') }}</option>
        <option value="expense">{{ i18n.t('accounting.cashflow.expense') }}</option>
      </select>
      <select v-model="filters.status" class="kawaii-input py-1.5 text-sm w-40">
        <option value="">{{ i18n.t('accounting.cashflow.allStatuses') }}</option>
        <option value="draft">{{ i18n.t('accounting.cashflow.status.draft') }}</option>
        <option value="pending">{{ i18n.t('accounting.cashflow.status.pending') }}</option>
        <option value="approved">{{ i18n.t('accounting.cashflow.status.approved') }}</option>
        <option value="rejected">{{ i18n.t('accounting.cashflow.status.rejected') }}</option>
      </select>
      <input v-model="filters.start" type="date" class="kawaii-input py-1.5 text-sm w-36" />
      <span class="text-[hsl(var(--muted-foreground))] text-sm">→</span>
      <input v-model="filters.end" type="date" class="kawaii-input py-1.5 text-sm w-36" />
      <button @click="loadEntries" class="kawaii-btn-primary px-4 py-1.5 text-sm">
        {{ i18n.t('common.filter') }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="text-center py-12 text-[hsl(var(--muted-foreground))]">
      <div class="inline-block w-6 h-6 border-2 border-[hsl(var(--primary))] border-t-transparent rounded-full animate-spin mb-3"></div>
      <p class="text-sm">{{ i18n.t('common.loading') }}</p>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="kawaii-card p-4 border-red-200 bg-red-50 text-red-700 text-sm">
      {{ error }}
    </div>

    <!-- Empty state -->
    <div v-else-if="cashFlowEntries.length === 0"
      class="kawaii-card flex flex-col items-center justify-center py-16 text-center">
      <div class="w-14 h-14 bg-[hsl(var(--muted))] rounded-full flex items-center justify-center mb-4">
        <ReceiptIcon class="w-7 h-7 text-[hsl(var(--muted-foreground))]" />
      </div>
      <p class="font-semibold text-[hsl(var(--foreground))]">{{ i18n.t('accounting.cashflow.empty') }}</p>
      <button @click="openCreate" class="kawaii-btn-primary px-4 py-2 text-sm mt-4">
        {{ i18n.t('accounting.cashflow.create') }}
      </button>
    </div>

    <!-- Table -->
    <div v-else class="kawaii-card overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-[hsl(var(--muted))]/50 border-b border-[hsl(var(--border))]">
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.date') }}</th>
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.description') }}</th>
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.category') }}</th>
              <th class="px-4 py-3 text-left font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.method') }}</th>
              <th class="px-4 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.amount') }}</th>
              <th class="px-4 py-3 text-center font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('accounting.cashflow.status_col') }}</th>
              <th class="px-4 py-3 text-right font-semibold text-[hsl(var(--muted-foreground))]">{{ i18n.t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-for="entry in cashFlowEntries" :key="entry.id"
              class="hover:bg-[hsl(var(--muted))]/30 transition-colors">
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="font-medium text-[hsl(var(--foreground))]">{{ formatDate(entry.entry_date) }}</div>
                <div class="text-xs text-[hsl(var(--muted-foreground))]">{{ entry.branch_name }}</div>
              </td>
              <td class="px-4 py-3">
                <div class="font-medium text-[hsl(var(--foreground))] max-w-[220px] truncate" :title="entry.description">
                  {{ entry.description }}
                </div>
                <div v-if="entry.reference_no" class="text-xs text-[hsl(var(--muted-foreground))]">
                  Ref: {{ entry.reference_no }}
                </div>
              </td>
              <td class="px-4 py-3">
                <span v-if="entry.category_name"
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                  :class="entry.type === 'income' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'">
                  {{ entry.category_name }}
                </span>
              </td>
              <td class="px-4 py-3">
                <span class="text-xs text-[hsl(var(--muted-foreground))]">{{ formatMethod(entry.payment_method) }}</span>
              </td>
              <td class="px-4 py-3 text-right whitespace-nowrap">
                <span class="font-bold text-base"
                  :class="entry.type === 'income' ? 'text-green-600' : 'text-red-600'">
                  {{ entry.type === 'income' ? '+' : '-' }}{{ formatCurrency(entry.amount) }}
                </span>
              </td>
              <td class="px-4 py-3 text-center">
                <span :class="statusClass(entry.status)"
                  class="inline-block px-2 py-0.5 rounded-full text-xs font-bold">
                  {{ i18n.t(`accounting.cashflow.status.${entry.status}`) }}
                </span>
              </td>
              <td class="px-4 py-3 text-right">
                <div class="flex items-center justify-end gap-1">
                  <button v-if="entry.status === 'draft'" @click="submitEntry(entry.id)"
                    class="text-xs px-2.5 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors">
                    {{ i18n.t('accounting.cashflow.submit') }}
                  </button>
                  <button v-if="entry.status === 'pending'" @click="approveEntry(entry.id, 'approve')"
                    class="text-xs px-2.5 py-1 bg-green-50 text-green-700 border border-green-200 rounded-lg hover:bg-green-100 transition-colors">
                    {{ i18n.t('accounting.cashflow.approve') }}
                  </button>
                  <button v-if="entry.status === 'pending'" @click="openReject(entry)"
                    class="text-xs px-2.5 py-1 bg-red-50 text-red-700 border border-red-200 rounded-lg hover:bg-red-100 transition-colors">
                    {{ i18n.t('accounting.cashflow.reject') }}
                  </button>
                  <button v-if="['draft','rejected'].includes(entry.status)" @click="openEdit(entry)"
                    class="text-xs px-2.5 py-1 bg-[hsl(var(--muted))] text-[hsl(var(--foreground))] rounded-lg hover:bg-[hsl(var(--border))] transition-colors">
                    {{ i18n.t('common.edit') }}
                  </button>
                  <button v-if="entry.status === 'draft'" @click="confirmDelete(entry.id)"
                    class="text-xs px-2.5 py-1 text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                    {{ i18n.t('common.delete') }}
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create / Edit Panel -->
    <div v-if="isPanelOpen" class="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex justify-end">
      <div class="bg-white w-[480px] h-full shadow-2xl flex flex-col">
        <div class="p-5 border-b border-[hsl(var(--border))] flex justify-between items-center bg-[hsl(var(--muted))]/50">
          <h2 class="text-lg font-bold text-[hsl(var(--foreground))]">
            {{ editingEntry ? i18n.t('accounting.cashflow.editTitle') : i18n.t('accounting.cashflow.createTitle') }}
          </h2>
          <button @click="isPanelOpen = false" class="p-2 rounded-full hover:bg-[hsl(var(--border))] transition-colors">
            <XIcon class="w-5 h-5" />
          </button>
        </div>
        <div class="flex-1 overflow-y-auto p-6 space-y-4">
          <!-- Type -->
          <div class="grid grid-cols-2 gap-3">
            <button @click="form.type = 'income'"
              :class="['kawaii-card p-3 text-sm font-bold border-2 transition-all', form.type === 'income' ? 'border-green-500 bg-green-50 text-green-700' : 'border-transparent text-[hsl(var(--muted-foreground))]']">
              <TrendingUpIcon class="w-5 h-5 mx-auto mb-1" />
              {{ i18n.t('accounting.cashflow.income') }}
            </button>
            <button @click="form.type = 'expense'"
              :class="['kawaii-card p-3 text-sm font-bold border-2 transition-all', form.type === 'expense' ? 'border-red-500 bg-red-50 text-red-700' : 'border-transparent text-[hsl(var(--muted-foreground))]']">
              <TrendingDownIcon class="w-5 h-5 mx-auto mb-1" />
              {{ i18n.t('accounting.cashflow.expense') }}
            </button>
          </div>

          <!-- Category -->
          <div>
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.category') }}</label>
            <select v-model="form.category_id" class="kawaii-input py-2.5">
              <option value="">-- {{ i18n.t('accounting.cashflow.selectCategory') }} --</option>
              <option v-for="cat in filteredCategories" :key="cat.id" :value="cat.id">
                {{ cat.name }} ({{ cat.code }})
              </option>
            </select>
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.description') }} *</label>
            <input v-model="form.description" type="text" class="kawaii-input py-2.5"
              :placeholder="i18n.t('accounting.cashflow.descPlaceholder')" />
          </div>

          <!-- Amount + Method -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.amount') }} *</label>
              <div class="relative">
                <input v-model.number="form.amount" type="number" class="kawaii-input py-2.5 pr-10" min="0" />
                <span class="absolute right-3 top-2.5 text-[hsl(var(--muted-foreground))] text-sm">đ</span>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.method') }}</label>
              <select v-model="form.payment_method" class="kawaii-input py-2.5">
                <option value="cash">{{ i18n.t('accounting.cashflow.methods.cash') }}</option>
                <option value="bank_transfer">{{ i18n.t('accounting.cashflow.methods.bank_transfer') }}</option>
                <option value="card">{{ i18n.t('accounting.cashflow.methods.card') }}</option>
              </select>
            </div>
          </div>

          <!-- Date + Reference -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.date') }}</label>
              <input v-model="form.entry_date" type="date" class="kawaii-input py-2.5" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.referenceNo') }}</label>
              <input v-model="form.reference_no" type="text" class="kawaii-input py-2.5" placeholder="PT-001..." />
            </div>
          </div>

          <!-- Notes -->
          <div>
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('accounting.cashflow.notes') }}</label>
            <textarea v-model="form.notes" rows="2" class="kawaii-input py-2.5"></textarea>
          </div>
        </div>

        <div class="p-5 border-t border-[hsl(var(--border))] flex justify-end gap-3">
          <button @click="isPanelOpen = false" class="px-4 py-2 text-sm text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]">
            {{ i18n.t('common.cancel') }}
          </button>
          <button @click="saveEntry" :disabled="isSaving"
            class="kawaii-btn-primary px-5 py-2 text-sm flex items-center gap-2">
            <span v-if="isSaving" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
            {{ i18n.t('common.save') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Reject modal -->
    <div v-if="rejectModal.open" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center">
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <h3 class="text-lg font-bold mb-3">{{ i18n.t('accounting.cashflow.rejectTitle') }}</h3>
        <textarea v-model="rejectModal.reason" rows="3" class="kawaii-input py-2.5 mb-4"
          :placeholder="i18n.t('accounting.cashflow.rejectReason')"></textarea>
        <div class="flex justify-end gap-3">
          <button @click="rejectModal.open = false" class="px-4 py-2 text-sm text-[hsl(var(--muted-foreground))]">
            {{ i18n.t('common.cancel') }}
          </button>
          <button @click="confirmReject" class="px-4 py-2 text-sm bg-red-600 text-white rounded-xl hover:bg-red-700">
            {{ i18n.t('accounting.cashflow.confirmReject') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { PlusIcon, XIcon, TrendingUpIcon, TrendingDownIcon, ReceiptIcon } from 'lucide-vue-next'
import { useAccountingModule, type CashFlowEntry, type CreateCashFlowInput } from '@/composables/useAccountingModule'
import { useAuth } from '@/composables/useAuth'
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
const { profile } = useAuth()
const {
  cashFlowEntries, categories, loading, error,
  fetchCashFlowEntries, createEntry, updateEntry,
  submitEntry: submitRPC, approveEntry: approveRPC, deleteEntry,
  fetchCategories
} = useAccountingModule()

const isPanelOpen = ref(false)
const isSaving = ref(false)
const editingEntry = ref<CashFlowEntry | null>(null)

const filters = ref({ type: '', status: '', start: '', end: '' })

const rejectModal = ref({ open: false, entryId: '', reason: '' })

const defaultForm = (): CreateCashFlowInput & { category_id: string; reference_no: string; notes: string } => ({
  branch_id: profile.value?.branch_id ?? '',
  category_id: '',
  type: 'expense',
  amount: 0,
  description: '',
  payment_method: 'cash',
  entry_date: new Date().toISOString().split('T')[0],
  reference_no: '',
  notes: '',
})

const form = ref(defaultForm())

const filteredCategories = computed(() =>
  categories.value.filter(c => c.type === form.value.type)
)

function formatCurrency(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}
function formatDate(d: string) {
  return new Date(d).toLocaleDateString('vi-VN')
}
function formatMethod(m: string) {
  const map: Record<string, string> = {
    cash: 'Tiền mặt', bank_transfer: 'Chuyển khoản', card: 'Thẻ'
  }
  return map[m] ?? m
}
function statusClass(status: string) {
  return {
    draft: 'bg-gray-100 text-gray-600',
    pending: 'bg-yellow-100 text-yellow-700',
    approved: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-700',
  }[status] ?? 'bg-gray-100 text-gray-600'
}

async function loadEntries() {
  await fetchCashFlowEntries({
    type: (filters.value.type as any) || null,
    status: filters.value.status || null,
    start: filters.value.start || null,
    end: filters.value.end || null,
  })
}

function openCreate() {
  editingEntry.value = null
  form.value = defaultForm()
  isPanelOpen.value = true
}

function openEdit(entry: CashFlowEntry) {
  editingEntry.value = entry
  form.value = {
    branch_id: entry.branch_id,
    category_id: entry.category_id ?? '',
    type: entry.type,
    amount: entry.amount,
    description: entry.description,
    payment_method: entry.payment_method,
    entry_date: entry.entry_date,
    reference_no: entry.reference_no ?? '',
    notes: entry.notes ?? '',
  }
  isPanelOpen.value = true
}

async function saveEntry() {
  if (!form.value.description || !form.value.amount) return
  isSaving.value = true
  try {
    if (editingEntry.value) {
      await updateEntry(editingEntry.value.id, form.value)
    } else {
      await createEntry(form.value)
    }
    isPanelOpen.value = false
    await loadEntries()
  } catch (e: any) {
    alert(e.message)
  } finally {
    isSaving.value = false
  }
}

async function submitEntry(id: string) {
  try {
    await submitRPC(id)
    await loadEntries()
  } catch (e: any) {
    alert(e.message)
  }
}

async function approveEntry(id: string, action: 'approve' | 'reject') {
  try {
    await approveRPC(id, action)
    await loadEntries()
  } catch (e: any) {
    alert(e.message)
  }
}

function openReject(entry: CashFlowEntry) {
  rejectModal.value = { open: true, entryId: entry.id, reason: '' }
}

async function confirmReject() {
  try {
    await approveRPC(rejectModal.value.entryId, 'reject', rejectModal.value.reason)
    rejectModal.value.open = false
    await loadEntries()
  } catch (e: any) {
    alert(e.message)
  }
}

async function confirmDelete(id: string) {
  if (!confirm(i18n.t('accounting.cashflow.confirmDelete'))) return
  try {
    await deleteEntry(id)
    await loadEntries()
  } catch (e: any) {
    alert(e.message)
  }
}

onMounted(async () => {
  await fetchCategories()
  await loadEntries()
})
</script>
