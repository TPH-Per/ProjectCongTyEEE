<template>
  <div class="p-6 text-gray-100 min-h-screen bg-[#1A1A1A] font-serif">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-[#C9A85C]">{{ $t('vouchers.title') }}</h1>
      <button @click="openCreatePanel" class="bg-[#C9A85C] hover:bg-[#A88741] text-black font-semibold px-4 py-2 rounded-md shadow-lg flex items-center gap-2 transition-all">
        <component :is="getIcon('plus')" class="w-4 h-4" />
        {{ $t('vouchers.create') }}
      </button>
    </div>

    <!-- Stats Row -->
    <div class="grid grid-cols-4 gap-4 mb-6" v-if="stats">
      <div class="bg-[#262626] p-5 rounded-xl border border-[#333333] shadow-md relative overflow-hidden group">
        <div class="absolute inset-0 bg-gradient-to-br from-[#C9A85C]/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
        <p class="text-[#8C8C8C] text-sm relative z-10">{{ $t('vouchers.stats.active') }}</p>
        <p class="text-3xl text-[#C9A85C] font-bold mt-2 relative z-10">{{ stats.active_vouchers }}</p>
      </div>
      <div class="bg-[#262626] p-5 rounded-xl border border-[#333333] shadow-md relative overflow-hidden group">
        <div class="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
        <p class="text-[#8C8C8C] text-sm relative z-10">{{ $t('vouchers.stats.redeemed') }}</p>
        <p class="text-3xl text-gray-100 font-bold mt-2 relative z-10">{{ stats.total_redemptions }}</p>
      </div>
      <div class="bg-[#262626] p-5 rounded-xl border border-[#333333] shadow-md relative overflow-hidden group">
        <div class="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
        <p class="text-[#8C8C8C] text-sm relative z-10">{{ $t('vouchers.stats.discountGiven') }}</p>
        <p class="text-3xl text-gray-100 font-bold mt-2 relative z-10">{{ formatCurrency(stats.total_discount_given) }}</p>
      </div>
      <div class="bg-[#262626] p-5 rounded-xl border border-[#333333] shadow-md relative overflow-hidden group">
        <div class="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
        <p class="text-[#8C8C8C] text-sm relative z-10">{{ $t('vouchers.stats.avgDiscount') }}</p>
        <p class="text-3xl text-gray-100 font-bold mt-2 relative z-10">
          {{ stats.total_redemptions ? formatCurrency(stats.total_discount_given / stats.total_redemptions) : formatCurrency(0) }}
        </p>
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="flex items-center justify-between mb-6 border-b border-[#333333] pb-2">
      <div class="flex gap-6">
        <button v-for="tab in tabs" :key="tab.value" 
          @click="currentTab = tab.value"
          :class="['pb-2 text-sm font-medium transition-all relative', currentTab === tab.value ? 'text-[#C9A85C]' : 'text-[#8C8C8C] hover:text-[#D4D4D4]']"
        >
          {{ $t(tab.label) }}
          <div v-if="currentTab === tab.value" class="absolute bottom-0 left-0 right-0 h-[2px] bg-[#C9A85C] rounded-t-full"></div>
        </button>
      </div>
      <div class="relative">
        <component :is="getIcon('search')" class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8C8C]" />
        <input v-model="searchQuery" type="text" :placeholder="$t('vouchers.search')" class="bg-[#262626] border border-[#333333] text-white pl-9 pr-3 py-2 rounded-md text-sm w-64 focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none transition-all placeholder:text-[#8C8C8C]" />
      </div>
    </div>

    <!-- Vouchers List -->
    <div v-if="loading" class="flex justify-center items-center py-20 text-[#8C8C8C]">
      <component :is="getIcon('loader-2')" class="w-8 h-8 animate-spin" />
    </div>
    <div v-else-if="filteredVouchers.length === 0" class="bg-[#262626] border border-[#333333] rounded-xl p-16 text-center shadow-lg">
      <div class="text-[#404040] mb-4 flex justify-center">
        <component :is="getIcon('ticket')" class="w-16 h-16" />
      </div>
      <p class="text-[#D4D4D4] text-lg mb-2">{{ $t('vouchers.empty') }}</p>
      <button @click="openCreatePanel" class="text-[#C9A85C] hover:text-[#A88741] font-medium inline-flex items-center gap-1 transition-colors">
        {{ $t('vouchers.createFirst') }}
        <component :is="getIcon('arrow-right')" class="w-4 h-4" />
      </button>
    </div>
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
      <div v-for="voucher in filteredVouchers" :key="voucher.id" class="bg-[#262626] border border-[#333333] hover:border-[#C9A85C]/50 transition-colors rounded-xl p-5 relative group shadow-md flex flex-col">
        <!-- Actions -->
        <div class="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
          <button @click="openEditPanel(voucher)" class="bg-[#333333] p-1.5 rounded text-[#8C8C8C] hover:text-white hover:bg-[#404040] transition-colors" :title="$t('vouchers.edit')">
            <component :is="getIcon('pencil')" class="w-4 h-4" />
          </button>
          <button @click="confirmDelete(voucher.id)" class="bg-[#333333] p-1.5 rounded text-[#8C8C8C] hover:text-red-400 hover:bg-red-400/10 transition-colors" :title="$t('vouchers.delete')">
            <component :is="getIcon('trash')" class="w-4 h-4" />
          </button>
        </div>

        <div class="flex justify-between items-start mb-3">
          <div class="flex items-center gap-2">
            <button @click="copyCode(voucher.code)" class="font-mono font-bold text-xl tracking-wider text-white hover:text-[#C9A85C] flex items-center gap-2 transition-colors group/code" :title="$t('vouchers.copyCode')">
              {{ voucher.code }}
              <component :is="getIcon('copy')" class="w-4 h-4 text-[#8C8C8C] group-hover/code:text-[#C9A85C] opacity-0 group-hover/code:opacity-100 transition-opacity" />
            </button>
          </div>
          <div class="mr-14">
            <span v-if="voucher.type === 'percent'" class="bg-amber-500/10 text-amber-500 text-xs font-bold px-2.5 py-1 rounded-md border border-amber-500/20">%</span>
            <span v-else class="bg-blue-500/10 text-blue-400 text-xs font-bold px-2.5 py-1 rounded-md border border-blue-500/20">đ</span>
          </div>
        </div>

        <div class="mb-4">
          <span class="text-3xl font-bold text-white tracking-tight">
            {{ voucher.type === 'percent' ? voucher.value + '%' : formatCurrency(voucher.value) }}
          </span>
          <span v-if="voucher.type === 'percent' && voucher.max_discount_amount" class="block text-xs text-[#8C8C8C] mt-1">
            Max: {{ formatCurrency(voucher.max_discount_amount) }}
          </span>
        </div>

        <div class="space-y-2 mt-auto">
          <div v-if="voucher.min_order_value > 0" class="flex items-center justify-between text-sm">
            <span class="text-[#8C8C8C]">{{ $t('vouchers.minOrder') }}</span>
            <span class="text-[#D4D4D4] font-medium">{{ formatCurrency(voucher.min_order_value) }}</span>
          </div>
          <div class="flex justify-between items-center text-sm">
            <span class="text-[#8C8C8C]">{{ $t('vouchers.validity') }}</span>
            <span class="text-[#D4D4D4] font-medium">{{ formatDateRange(voucher.valid_from, voucher.valid_until) }}</span>
          </div>
          <div v-if="voucher.customer_id" class="bg-[#333333] px-2 py-1 rounded mt-2 text-[#C9A85C] text-xs flex items-center gap-1.5 inline-flex w-max">
            <component :is="getIcon('user')" class="w-3 h-3" />
            {{ $t('vouchers.personalized') }} - {{ voucher.customer?.name || voucher.customer_id }}
          </div>
        </div>

        <!-- Divider -->
        <hr class="border-[#333333] my-4" />

        <!-- Footer -->
        <div class="flex items-center justify-between mt-auto">
          <div class="flex-1 mr-4">
            <div v-if="voucher.max_uses" class="w-full">
              <div class="flex justify-between text-xs mb-1.5">
                <span class="text-[#8C8C8C]">{{ $t('vouchers.usage') }}</span>
                <span class="text-[#D4D4D4] font-medium">{{ voucher.used_count }} / {{ voucher.max_uses }}</span>
              </div>
              <div class="w-full bg-[#1A1A1A] rounded-full h-2 border border-[#333333]">
                <div class="bg-gradient-to-r from-[#A88741] to-[#C9A85C] h-full rounded-full transition-all duration-500" :style="{ width: usagePercent(voucher) + '%' }"></div>
              </div>
            </div>
            <div v-else class="text-xs text-[#8C8C8C] flex items-center gap-1.5">
              <component :is="getIcon('infinity')" class="w-3.5 h-3.5" />
              {{ voucher.used_count }} {{ $t('vouchers.usesNoLimit') }}
            </div>
          </div>
          
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" :checked="voucher.is_active" @change="handleToggle(voucher)" class="sr-only peer">
            <div class="w-10 h-5 bg-[#333333] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-green-500 border border-[#404040]"></div>
          </label>
        </div>
      </div>
    </div>

    <!-- Slide-in Panel for Create/Edit -->
    <div v-if="isPanelOpen" class="fixed inset-0 z-50 flex justify-end">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="closePanel"></div>
      <div class="relative w-[440px] bg-[#1A1A1A] border-l border-[#333333] h-full flex flex-col shadow-2xl transform transition-transform">
        <div class="p-5 border-b border-[#333333] flex justify-between items-center bg-[#262626]">
          <h2 class="text-xl font-serif text-[#C9A85C]">{{ editingVoucher ? $t('vouchers.editVoucher') : $t('vouchers.createVoucher') }}</h2>
          <button @click="closePanel" class="text-[#8C8C8C] hover:text-white bg-[#333333] p-1.5 rounded transition-colors">
            <component :is="getIcon('x')" class="w-5 h-5" />
          </button>
        </div>

        <div class="p-6 overflow-y-auto flex-1 space-y-6 form-dark">
          <!-- Form fields -->
          <div>
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5">{{ $t('vouchers.form.code') }}</label>
            <div class="relative">
              <component :is="getIcon('tag')" class="w-4 h-4 absolute left-3 top-3 text-[#8C8C8C]" />
              <input v-model="form.code" type="text" class="w-full bg-[#262626] border border-[#333333] rounded-md pl-10 pr-3 py-2.5 text-white font-mono uppercase focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none transition-all placeholder:text-[#595959]" :disabled="!!editingVoucher" placeholder="SUMMER2026" />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5">{{ $t('vouchers.form.type') }}</label>
            <div class="flex rounded-md bg-[#262626] border border-[#333333] overflow-hidden p-1 gap-1">
              <button class="flex-1 py-2 text-sm font-medium text-center transition-colors rounded" :class="form.type === 'percent' ? 'bg-[#333333] text-[#C9A85C] shadow-sm' : 'text-[#8C8C8C] hover:text-white hover:bg-[#333333]/50'" @click="form.type = 'percent'">Giảm %</button>
              <button class="flex-1 py-2 text-sm font-medium text-center transition-colors rounded" :class="form.type === 'amount' ? 'bg-[#333333] text-[#C9A85C] shadow-sm' : 'text-[#8C8C8C] hover:text-white hover:bg-[#333333]/50'" @click="form.type = 'amount'">Giảm cố định đ</button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5">{{ $t('vouchers.form.value') }}</label>
            <div class="relative">
              <input v-model.number="form.value" type="number" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none pr-10 font-medium" placeholder="0" />
              <span class="absolute right-4 top-2.5 text-[#8C8C8C] font-medium">{{ form.type === 'percent' ? '%' : 'đ' }}</span>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5 flex justify-between">
              {{ $t('vouchers.form.minOrder') }} 
              <span class="text-xs text-[#8C8C8C] font-normal">Leave 0 for no minimum</span>
            </label>
            <input v-model.number="form.min_order_value" type="number" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none" />
          </div>

          <div v-if="form.type === 'percent'">
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5 flex justify-between">
              {{ $t('vouchers.form.maxDiscount') }} 
              <span class="text-xs text-[#8C8C8C] font-normal">Optional</span>
            </label>
            <input v-model.number="form.max_discount_amount" type="number" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5 flex items-center gap-1.5">
                <component :is="getIcon('calendar')" class="w-3.5 h-3.5 text-[#8C8C8C]" />
                {{ $t('vouchers.form.validFrom') }}
              </label>
              <input v-model="form.valid_from" type="datetime-local" class="w-full bg-[#262626] border border-[#333333] rounded-md px-3 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none text-sm color-scheme-dark" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5 flex items-center gap-1.5">
                <component :is="getIcon('calendar-off')" class="w-3.5 h-3.5 text-[#8C8C8C]" />
                {{ $t('vouchers.form.validUntil') }}
              </label>
              <input v-model="form.valid_until" type="datetime-local" class="w-full bg-[#262626] border border-[#333333] rounded-md px-3 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none text-sm color-scheme-dark" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5 flex justify-between">
                {{ $t('vouchers.form.maxUses') }} 
                <span class="text-xs text-[#8C8C8C] font-normal">Optional</span>
              </label>
              <input v-model.number="form.max_uses" type="number" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none" />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5">
                {{ $t('vouchers.form.usageLimitPerCustomer') }}
              </label>
              <input v-model.number="form.usage_limit_per_customer" type="number" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none" />
            </div>
          </div>
          
          <div class="pt-2">
            <label class="flex items-center gap-3 cursor-pointer p-3 bg-[#262626] border border-[#333333] rounded-md hover:border-[#404040] transition-colors">
              <input type="checkbox" v-model="isPersonalized" class="w-4 h-4 text-[#C9A85C] bg-[#1A1A1A] border-[#333333] rounded focus:ring-[#C9A85C]/50 focus:ring-offset-[#262626]" />
              <div class="flex flex-col">
                <span class="text-sm font-medium text-white">{{ $t('vouchers.form.isPersonalized') }}</span>
                <span class="text-xs text-[#8C8C8C]">Assign this voucher to a specific customer</span>
              </div>
            </label>
          </div>

          <div v-if="isPersonalized">
            <label class="block text-sm font-medium text-[#D4D4D4] mb-1.5">{{ $t('vouchers.form.customerId') }}</label>
            <input v-model="form.customer_id" type="text" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-2.5 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none" placeholder="Customer UUID" />
          </div>

          <div class="pt-2 border-t border-[#333333]">
            <label class="block text-sm font-medium text-[#D4D4D4] mb-2">{{ $t('vouchers.form.description') }}</label>
            <div class="flex gap-1 mb-3 bg-[#262626] p-1 rounded-md border border-[#333333] w-max">
              <button @click="descTab = 'vi'" :class="['text-xs font-medium px-3 py-1.5 rounded transition-colors', descTab === 'vi' ? 'bg-[#333333] text-white shadow-sm' : 'text-[#8C8C8C] hover:text-[#D4D4D4]']">Tiếng Việt</button>
              <button @click="descTab = 'en'" :class="['text-xs font-medium px-3 py-1.5 rounded transition-colors', descTab === 'en' ? 'bg-[#333333] text-white shadow-sm' : 'text-[#8C8C8C] hover:text-[#D4D4D4]']">English</button>
              <button @click="descTab = 'ja'" :class="['text-xs font-medium px-3 py-1.5 rounded transition-colors', descTab === 'ja' ? 'bg-[#333333] text-white shadow-sm' : 'text-[#8C8C8C] hover:text-[#D4D4D4]']">日本語</button>
            </div>
            <textarea v-if="descTab === 'vi'" v-model="form.description_vi" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-3 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none h-24 resize-none placeholder:text-[#595959]" placeholder="Mô tả bằng tiếng Việt"></textarea>
            <textarea v-if="descTab === 'en'" v-model="form.description_en" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-3 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none h-24 resize-none placeholder:text-[#595959]" placeholder="Description in English"></textarea>
            <textarea v-if="descTab === 'ja'" v-model="form.description_ja" class="w-full bg-[#262626] border border-[#333333] rounded-md px-4 py-3 text-white focus:border-[#C9A85C] focus:ring-1 focus:ring-[#C9A85C]/50 outline-none h-24 resize-none placeholder:text-[#595959]" placeholder="日本語での説明"></textarea>
          </div>

        </div>

        <div class="p-5 border-t border-[#333333] bg-[#262626]">
          <button @click="saveVoucher" :disabled="isSaving" class="w-full bg-[#C9A85C] hover:bg-[#A88741] disabled:bg-[#333333] disabled:text-[#8C8C8C] text-black font-bold py-3 px-4 rounded-md shadow-lg transition-all flex justify-center items-center gap-2">
            <component v-if="isSaving" :is="getIcon('loader-2')" class="w-5 h-5 animate-spin" />
            <span v-else>{{ editingVoucher ? $t('common.saveChanges') : $t('common.create') }}</span>
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
import { useI18n } from 'vue-i18n'
import { useUnsavedGuard } from '@/composables/useUnsavedGuard'
import type { Voucher, CreateVoucherInput } from '@/composables/useVoucher'

const getIcon = (name: string) => {
  const pascalName = name.split('-').map(p => p.charAt(0).toUpperCase() + p.slice(1)).join('')
  return (lucideIcons as any)[pascalName] || (lucideIcons as any).HelpCircle
}

const { t: $t } = useI18n()
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

// Baseline snapshot for unsaved-change detection. Updated every time we
// open the panel; cleared when the save succeeds.
const voucherFormBaseline = ref<CreateVoucherInput>(defaultForm())
function snapshotVoucherBaseline() {
  voucherFormBaseline.value = { ...form.value, isPersonalized: isPersonalized.value } as any
}
const { confirmIfDirty: confirmVoucherDirty } = useUnsavedGuard(
  form,
  voucherFormBaseline,
)

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
  if (!from && !until) return $t('vouchers.noExpiry')
  
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}`
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
  snapshotVoucherBaseline()
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
  snapshotVoucherBaseline()
}

async function closePanel() {
  if (await confirmVoucherDirty()) {
    isPanelOpen.value = false
  }
}

async function saveVoucher() {
  try {
    if (!form.value.code) {
      alert($t('vouchers.errors.codeRequired'))
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
    // Save succeeded — close the panel directly (no unsaved-changes prompt).
    isPanelOpen.value = false
    snapshotVoucherBaseline()
    await fetchStats()
  } catch (err: any) {
    console.error('Error saving voucher:', err)
    if (err.message === 'DUPLICATE_CODE') {
      alert($t('vouchers.errors.duplicateCode'))
    } else {
      alert($t('vouchers.errors.saveFailed'))
    }
  } finally {
    isSaving.value = false
  }
}

async function confirmDelete(id: string) {
  if (confirm($t('vouchers.confirmDelete'))) {
    try {
      await deleteVoucher(id)
      await fetchStats()
    } catch (err) {
      console.error('Error deleting voucher', err)
      alert($t('vouchers.errors.deleteFailed'))
    }
  }
}

async function handleToggle(voucher: Voucher) {
  try {
    await toggleVoucher(voucher.id, !voucher.is_active)
    await fetchStats()
  } catch (err) {
    console.error('Error toggling voucher', err)
    alert($t('vouchers.errors.updateFailed'))
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
