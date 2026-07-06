<template>
  <div class="p-6 text-[hsl(var(--foreground))] min-h-screen font-sans">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-[hsl(var(--foreground))]">{{ i18n.t('vouchers.title') }}</h1>
      <button @click="openCreatePanel" class="kawaii-btn-primary px-4 py-2 flex items-center gap-2">
        <component :is="getIcon('plus')" class="w-4 h-4" />
        {{ i18n.t('vouchers.create') }}
      </button>
    </div>

    <!-- Stats Row -->
    <div class="grid grid-cols-4 gap-4 mb-6" v-if="stats">
      <div class="kawaii-card p-5 relative overflow-hidden group">
        <p class="text-[hsl(var(--muted-foreground))] text-sm relative z-10">{{ i18n.t('vouchers.stats.active') }}</p>
        <p class="text-3xl font-bold mt-2 relative z-10 text-[hsl(var(--foreground))]">{{ stats.active_vouchers }}</p>
      </div>
      <div class="kawaii-card p-5 relative overflow-hidden group">
        <p class="text-[hsl(var(--muted-foreground))] text-sm relative z-10">{{ i18n.t('vouchers.stats.redeemed') }}</p>
        <p class="text-3xl font-bold mt-2 relative z-10 text-[hsl(var(--foreground))]">{{ stats.total_redemptions }}</p>
      </div>
      <div class="kawaii-card p-5 relative overflow-hidden group">
        <p class="text-[hsl(var(--muted-foreground))] text-sm relative z-10">{{ i18n.t('vouchers.stats.discountGiven') }}</p>
        <p class="text-3xl font-bold mt-2 relative z-10 text-[hsl(var(--foreground))]">{{ formatCurrency(stats.total_discount_given) }}</p>
      </div>
      <div class="kawaii-card p-5 relative overflow-hidden group">
        <p class="text-[hsl(var(--muted-foreground))] text-sm relative z-10">{{ i18n.t('vouchers.stats.avgDiscount') }}</p>
        <p class="text-3xl font-bold mt-2 relative z-10 text-[hsl(var(--foreground))]">
          {{ stats.total_redemptions ? formatCurrency(stats.total_discount_given / stats.total_redemptions) : formatCurrency(0) }}
        </p>
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="flex items-center justify-between mb-6 border-b border-[hsl(var(--border))] pb-2">
      <div class="flex gap-6">
        <button v-for="tab in tabs" :key="tab.value" 
          @click="currentTab = tab.value"
          :class="['pb-2 text-sm font-medium transition-all relative', currentTab === tab.value ? 'text-[hsl(var(--primary))]' : 'text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]']"
        >
          {{ i18n.t(tab.label) }}
          <div v-if="currentTab === tab.value" class="absolute bottom-0 left-0 right-0 h-[2px] bg-[hsl(var(--primary))] rounded-t-full"></div>
        </button>
      </div>
      <div class="relative">
        <component :is="getIcon('search')" class="w-4 h-4 absolute left-3 top-2.5 text-[hsl(var(--muted-foreground))]" />
        <input v-model="searchQuery" type="text" :placeholder="i18n.t('vouchers.search')" class="kawaii-input py-2 pl-9 pr-3 text-sm w-64" />
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="filteredVouchers.length === 0" class="text-center py-16 kawaii-card flex flex-col items-center justify-center h-64">
      <div class="w-16 h-16 bg-[hsl(var(--muted))] rounded-full flex items-center justify-center mb-4">
        <component :is="getIcon('ticket')" class="w-8 h-8 text-[hsl(var(--muted-foreground))]" />
      </div>
      <p class="text-[hsl(var(--foreground))] font-medium mb-1">{{ i18n.t('vouchers.empty') }}</p>
      <button @click="openCreatePanel" class="text-[hsl(var(--primary))] text-sm font-semibold hover:underline mt-2">
        {{ i18n.t('vouchers.createFirst') }}
      </button>
    </div>

    <!-- Vouchers Grid -->
    <div v-else class="grid grid-cols-3 gap-4">
      <div v-for="v in filteredVouchers" :key="v.id" class="kawaii-card relative group flex flex-col h-full hover:shadow-md transition-shadow">
        <div class="p-5 flex-1">
          <div class="flex justify-between items-start mb-3">
            <div class="flex items-center gap-2">
              <span class="font-bold text-lg text-[hsl(var(--foreground))]">{{ v.code }}</span>
              <button @click.stop="copyCode(v.code)" class="text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--primary))] p-1 rounded transition-colors" title="Copy code">
                <component :is="getIcon('copy')" class="w-4 h-4" />
              </button>
            </div>
            <span :class="['px-2.5 py-1 text-xs font-bold rounded-full', v.is_active ? 'bg-green-100 text-green-700' : 'bg-[hsl(var(--muted))] text-[hsl(var(--muted-foreground))]']">
              {{ v.is_active ? i18n.t('vouchers.stats.active') : i18n.t('vouchers.tabs.inactive') }}
            </span>
          </div>
          
          <div class="text-3xl font-black text-[hsl(var(--primary))] mb-1">
            {{ v.type === 'percent' ? `${v.value}%` : formatCurrency(v.value) }}
          </div>
          <div class="text-sm font-semibold text-[hsl(var(--muted-foreground))] mb-4">
            {{ v.min_order_value > 0 ? `${i18n.t('vouchers.form.minOrder')} ${formatCurrency(v.min_order_value)}` : i18n.t('vouchers.form.allOrders') }}
            <span v-if="v.type === 'percent' && v.max_discount_amount">
              ({{ i18n.t('vouchers.form.maxDiscount') }} {{ formatCurrency(v.max_discount_amount) }})
            </span>
          </div>
          
          <div class="space-y-2 text-sm text-[hsl(var(--foreground))] mb-4">
            <div class="flex justify-between">
              <span class="text-[hsl(var(--muted-foreground))]">{{ i18n.t('vouchers.form.validity') }}</span>
              <span class="font-medium text-right">{{ formatDateRange(v.valid_from, v.valid_until) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-[hsl(var(--muted-foreground))]">{{ i18n.t('vouchers.form.used') }}</span>
              <span class="font-medium text-right">{{ v.used_count }} {{ v.max_uses ? `/ ${v.max_uses}` : '' }}</span>
            </div>
          </div>
        </div>
        
        <div class="border-t border-[hsl(var(--border))] p-3 flex justify-end gap-2 bg-[hsl(var(--muted))]/30 rounded-b-xl">
          <button @click="handleToggle(v)" class="text-xs font-bold px-3 py-1.5 kawaii-btn-ghost">
            {{ v.is_active ? i18n.t('vouchers.card.suspend') : i18n.t('vouchers.card.activate') }}
          </button>
          <button @click="openEditPanel(v)" class="text-xs font-bold px-3 py-1.5 kawaii-btn-ghost">{{ i18n.t('vouchers.card.edit') }}</button>
          <button @click="confirmDelete(v.id)" class="text-xs font-bold px-3 py-1.5 text-red-600 border border-red-200 bg-red-50 hover:bg-red-100 rounded-xl transition-colors">{{ i18n.t('vouchers.card.delete') }}</button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Slide-over Panel -->
    <div v-if="isPanelOpen" class="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex justify-end transition-all">
      <div class="bg-white w-[500px] h-full shadow-2xl flex flex-col transform transition-transform overflow-hidden">
        <div class="p-5 border-b border-[hsl(var(--border))] flex justify-between items-center bg-[hsl(var(--muted))]/50">
          <h2 class="text-lg font-bold text-[hsl(var(--foreground))]">{{ editingVoucher ? i18n.t('vouchers.card.edit') : i18n.t('vouchers.createVoucher') }}</h2>
          <button @click="closePanel" class="p-2 hover:bg-[hsl(var(--border))] rounded-full text-[hsl(var(--muted-foreground))] transition-colors">
            <component :is="getIcon('x')" class="w-5 h-5" />
          </button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-6 space-y-5">
          <div>
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('vouchers.form.code') }} *</label>
            <input v-model="form.code" type="text" class="kawaii-input py-2.5 uppercase font-mono tracking-wider" :placeholder="i18n.t('vouchers.form.codePlaceholder')" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('vouchers.form.type') }}</label>
              <select v-model="form.type" class="kawaii-input py-2.5">
                <option value="percent">{{ i18n.t('vouchers.form.percent') }}</option>
                <option value="amount">{{ i18n.t('vouchers.form.amount') }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('vouchers.form.discountValue') }} *</label>
              <div class="relative">
                <input v-model.number="form.value" type="number" class="kawaii-input py-2.5 pr-8" />
                <span class="absolute right-3 top-2.5 text-[hsl(var(--muted-foreground))] font-medium">{{ form.type === 'percent' ? '%' : 'đ' }}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('vouchers.form.minOrder') }} *</label>
              <input v-model.number="form.min_order_value" type="number" class="kawaii-input py-2.5" placeholder="0" />
            </div>
            <div v-if="form.type === 'percent'">
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5 flex justify-between">{{ i18n.t('vouchers.form.maxDiscount') }} <span class="text-xs text-[hsl(var(--muted-foreground))] font-normal">{{ i18n.t('vouchers.form.optional') }}</span></label>
              <input v-model.number="form.max_discount_amount" type="number" class="kawaii-input py-2.5" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5 flex items-center gap-1.5">
                <component :is="getIcon('calendar')" class="w-3.5 h-3.5 text-[hsl(var(--muted-foreground))]" />
                {{ i18n.t('vouchers.form.validFrom') }}
              </label>
              <input v-model="form.valid_from" type="datetime-local" class="kawaii-input py-2.5" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5 flex items-center gap-1.5">
                <component :is="getIcon('calendar-off')" class="w-3.5 h-3.5 text-[hsl(var(--muted-foreground))]" />
                {{ i18n.t('vouchers.form.validUntil') }}
              </label>
              <input v-model="form.valid_until" type="datetime-local" class="kawaii-input py-2.5" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5 flex justify-between">
                {{ i18n.t('vouchers.form.maxUses') }} 
                <span class="text-xs text-[hsl(var(--muted-foreground))] font-normal">{{ i18n.t('vouchers.form.optional') }}</span>
              </label>
              <input v-model.number="form.max_uses" type="number" class="kawaii-input py-2.5" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">
                {{ i18n.t('vouchers.form.usageLimitPerCustomer') }}
              </label>
              <input v-model.number="form.usage_limit_per_customer" type="number" class="kawaii-input py-2.5" />
            </div>
          </div>
          
          <div class="pt-2">
            <label class="flex items-center gap-3 cursor-pointer p-3 kawaii-card hover:border-[hsl(var(--primary))] transition-colors">
              <input type="checkbox" v-model="isPersonalized" class="w-4 h-4 text-[hsl(var(--primary))] bg-white border-[hsl(var(--border))] rounded focus:ring-[hsl(var(--primary))]/50" />
              <div class="flex flex-col">
                <span class="text-sm font-bold text-[hsl(var(--foreground))]">{{ i18n.t('vouchers.form.isPersonalized') }}</span>
                <span class="text-xs text-[hsl(var(--muted-foreground))]">{{ i18n.t('vouchers.form.assignToCustomer') }}</span>
              </div>
            </label>
          </div>

          <div v-if="isPersonalized">
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-1.5">{{ i18n.t('vouchers.form.customerId') }}</label>
            <input v-model="form.customer_id" type="text" class="kawaii-input py-2.5" :placeholder="i18n.t('vouchers.form.customerUuid')" />
          </div>

          <div class="pt-2 border-t border-[hsl(var(--border))]">
            <label class="block text-sm font-medium text-[hsl(var(--foreground))] mb-2">{{ i18n.t('vouchers.form.description') }}</label>
            <div class="flex gap-1 mb-3 bg-[hsl(var(--muted))] p-1 rounded-md border border-[hsl(var(--border))] w-max">
              <button @click="descTab = 'vi'" :class="['text-xs font-bold px-3 py-1.5 rounded transition-colors', descTab === 'vi' ? 'bg-white text-[hsl(var(--foreground))] shadow-sm' : 'text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]']">{{ i18n.t('common.lang.vi') }}</button>
              <button @click="descTab = 'en'" :class="['text-xs font-bold px-3 py-1.5 rounded transition-colors', descTab === 'en' ? 'bg-white text-[hsl(var(--foreground))] shadow-sm' : 'text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]']">{{ i18n.t('common.lang.en') }}</button>
              <button @click="descTab = 'ja'" :class="['text-xs font-bold px-3 py-1.5 rounded transition-colors', descTab === 'ja' ? 'bg-white text-[hsl(var(--foreground))] shadow-sm' : 'text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]']">{{ i18n.t('common.lang.ja') }}</button>
            </div>
            
            <textarea v-if="descTab === 'vi'" v-model="form.description_vi" rows="3" class="kawaii-input py-3" :placeholder="i18n.t('vouchers.form.descPlaceholderVi')"></textarea>
            <textarea v-if="descTab === 'en'" v-model="form.description_en" rows="3" class="kawaii-input py-3" :placeholder="i18n.t('vouchers.form.descPlaceholderEn')"></textarea>
            <textarea v-if="descTab === 'ja'" v-model="form.description_ja" rows="3" class="kawaii-input py-3" :placeholder="i18n.t('vouchers.form.descPlaceholderJa')"></textarea>
          </div>
        </div>
        
        <div class="p-5 border-t border-[hsl(var(--border))] bg-white flex justify-end gap-3">
          <button @click="closePanel" class="px-5 py-2.5 text-sm font-bold text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))] transition-colors">
            {{ i18n.t('vouchers.form.cancel') }}
          </button>
          <button @click="saveVoucher" :disabled="isSaving" class="kawaii-btn-primary px-5 py-2.5 text-sm flex items-center gap-2">
            <span v-if="isSaving" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
            {{ editingVoucher ? i18n.t('vouchers.form.update') : i18n.t('vouchers.form.create') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import * as lucideIcons from 'lucide-vue-next'
import { useVoucher } from '@/composables/useVoucher'
import { useI18nStore } from '@/stores/i18n'
import type { Voucher, CreateVoucherInput } from '@/composables/useVoucher'

const getIcon = (name: string) => {
  const pascalName = name.split('-').map(p => p.charAt(0).toUpperCase() + p.slice(1)).join('')
  return (lucideIcons as any)[pascalName] || (lucideIcons as any).HelpCircle
}

const i18n = useI18nStore()
const { 
  vouchers, stats, loading, error, 
  listVouchers, createVoucher, updateVoucher, 
  toggleVoucher, deleteVoucher, fetchStats,
  activeVouchers, expiredVouchers, usagePercent 
} = useVoucher()

const currentTab = ref('all')
const tabs = [
  { label: 'vouchers.tabs.all', value: 'all' },
  { label: 'vouchers.tabs.active', value: 'active' },
  { label: 'vouchers.tabs.expiringSoon', value: 'expiringSoon' },
  { label: 'vouchers.tabs.expired', value: 'expired' },
  { label: 'vouchers.tabs.personalized', value: 'personalized' }
]

const searchQuery = ref('')
const isPanelOpen = ref(false)
const isSaving = ref(false)
const editingVoucher = ref<Voucher | null>(null)
const descTab = ref('vi')

const defaultForm = (): CreateVoucherInput => ({
  code: '',
  type: 'percent',
  value: 0,
  min_order_value: 0,
  max_discount_amount: null,
  valid_from: '',
  valid_until: '',
  max_uses: null,
  usage_limit_per_customer: 1,
  customer_id: null,
  description_vi: '',
  description_en: '',
  description_ja: ''
})

const form = ref<CreateVoucherInput>(defaultForm())
const isPersonalized = ref(false)

const filteredVouchers = computed(() => {
  let list = vouchers.value
  
  if (currentTab.value === 'active') {
    list = activeVouchers.value
  } else if (currentTab.value === 'expired') {
    list = expiredVouchers.value
  } else if (currentTab.value === 'expiringSoon') {
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    list = list.filter(v => v.valid_until && new Date(v.valid_until) < nextWeek && new Date(v.valid_until) >= new Date())
  } else if (currentTab.value === 'personalized') {
    list = list.filter(v => v.customer_id)
  }
  
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(v => v.code.toLowerCase().includes(q))
  }
  
  return list
})

onMounted(async () => {
  try {
    await fetchStats()
    await listVouchers()
  } catch (err) {
    console.error('Failed to initialize vouchers view', err)
  }
})

function formatCurrency(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

function formatDateRange(from: string | null, until: string | null) {
  if (!from && !until) return i18n.t('vouchers.noExpiry')
  
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return `${date.getDate().toString().padStart(2)}/${(date.getMonth() + 1).toString().padStart(2)}`
  }
  
  const f = from ? formatDate(from) : '...'
  const u = until ? formatDate(until) : '...'
  return `${f} – ${u}`
}

function openCreatePanel() {
  editingVoucher.value = null
  form.value = defaultForm()
  isPersonalized.value = false
  isPanelOpen.value = true
  descTab.value = 'vi'
}

function openEditPanel(voucher: Voucher) {
  editingVoucher.value = voucher
  
  form.value = {
    code: voucher.code,
    type: voucher.type,
    value: voucher.value,
    min_order_value: voucher.min_order_value || 0,
    max_discount_amount: voucher.max_discount_amount,
    valid_from: voucher.valid_from ? new Date(voucher.valid_from).toISOString().slice(0, 16) : '',
    valid_until: voucher.valid_until ? new Date(voucher.valid_until).toISOString().slice(0, 16) : '',
    max_uses: voucher.max_uses,
    usage_limit_per_customer: voucher.usage_limit_per_customer || 1,
    customer_id: voucher.customer_id,
    description_vi: voucher.description_vi || '',
    description_en: voucher.description_en || '',
    description_ja: voucher.description_ja || ''
  }
  isPersonalized.value = !!voucher.customer_id
  isPanelOpen.value = true
  descTab.value = 'vi'
}

function closePanel() {
  isPanelOpen.value = false
}

async function saveVoucher() {
  try {
    if (!form.value.code) {
      alert(i18n.t('vouchers.errors.codeRequired'))
      return
    }
    
    isSaving.value = true
    const payload = { ...form.value }
    
    if (!payload.valid_from) payload.valid_from = null
    if (!payload.valid_until) payload.valid_until = null
    if (!payload.max_uses) payload.max_uses = null
    if (!payload.max_discount_amount) payload.max_discount_amount = null
    if (!isPersonalized.value) payload.customer_id = null
    
    if (payload.valid_from) payload.valid_from = new Date(payload.valid_from).toISOString()
    if (payload.valid_until) payload.valid_until = new Date(payload.valid_until).toISOString()

    if (editingVoucher.value) {
      await updateVoucher(editingVoucher.value.id, payload)
    } else {
      await createVoucher(payload)
    }
    closePanel()
    await fetchStats()
  } catch (err: any) {
    console.error('Error saving voucher:', err)
    if (err.message === 'DUPLICATE_CODE') {
      alert(i18n.t('vouchers.errors.duplicateCode'))
    } else {
      alert(i18n.t('vouchers.errors.saveFailed'))
    }
  } finally {
    isSaving.value = false
  }
}

async function confirmDelete(id: string) {
  if (confirm(i18n.t('vouchers.confirmDelete'))) {
    try {
      await deleteVoucher(id)
      await fetchStats()
    } catch (err) {
      console.error('Error deleting voucher', err)
      alert(i18n.t('vouchers.errors.deleteFailed'))
    }
  }
}

async function handleToggle(voucher: Voucher) {
  try {
    await toggleVoucher(voucher.id, !voucher.is_active)
    await fetchStats()
  } catch (err) {
    console.error('Error toggling voucher', err)
    alert(i18n.t('vouchers.errors.updateFailed'))
  }
}

function copyCode(code: string) {
  navigator.clipboard.writeText(code)
}
</script>

<style scoped>
.color-scheme-dark {
  color-scheme: dark;
}
input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type="number"] {
  -moz-appearance: textfield;
}
</style>
