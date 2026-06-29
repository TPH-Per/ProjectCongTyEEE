<template>
  <div class="space-y-6">

    <!-- Page Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">{{ $t('manager_inventory.daily_inventory') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">{{ $t('manager_inventory.ingredient_management') }}</p>
      </div>
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          {{ $t('manager_inventory.export_csv') }}
        </button>
        <button class="kawaii-btn-primary px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          {{ $t('manager_inventory.send_invoice') }}
        </button>
      </div>
    </div>

    <!-- Date & Summary -->
    <div class="flex gap-4">
      <div class="kawaii-card p-4 flex items-center gap-3 flex-1">
        <input type="date" value="2026-06-20" class="kawaii-input py-2 text-sm w-40" />
        <span class="text-sm text-gray-500">{{ $t('manager_inventory.export_date') }}</span>
      </div>
      <div class="kawaii-card p-4 flex items-center gap-4 flex-1">
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ $t('manager_inventory.total_ingredients') }}</div>
          <div class="text-xl font-black text-[hsl(var(--foreground))]">{{ totalInventoryCount }} SKU</div>
        </div>
        <div class="w-px h-8 bg-[hsl(var(--border))]" />
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ $t('manager_inventory.total_export_value') }}</div>
          <div class="text-xl font-black text-[hsl(var(--primary))]">{{ totalInventoryValue.toLocaleString() }}đ</div>
        </div>
        <div class="w-px h-8 bg-[hsl(var(--border))]" />
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ $t('manager_inventory.status') }}</div>
          <div class="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-bold rounded-full">{{ $t('manager_inventory.waiting_confirm') }}</div>
        </div>
      </div>
    </div>

    <!-- Inventory Categories -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div v-for="cat in categories" :key="cat.name" class="kawaii-card overflow-hidden">
        <div class="kawaii-card-header">
          <span class="font-bold text-sm text-[hsl(var(--foreground))]">{{ cat.name }}</span>
          <span class="kawaii-pill bg-blue-100 text-blue-700">{{ cat.items.length }} {{ $t('manager_inventory.type') }}</span>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-[hsl(var(--border))]">
                <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ $t('manager_inventory.ingredient') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ $t('manager_inventory.ending_inventory') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ $t('manager_inventory.unit_price') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ $t('manager_inventory.total_amount') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[hsl(var(--border))]">
              <tr v-for="item in cat.items" :key="item.ingredient_id" class="hover:bg-[hsl(var(--muted))]/50">
                <td class="py-2.5 px-4 font-semibold text-[hsl(var(--foreground))]">{{ item.name_vi }} <span class="text-xs text-gray-500 ml-1">({{ item.sku }})</span></td>
                <td class="py-2.5 px-4 text-right text-gray-600 font-bold" :class="{'text-red-600': item.is_low_stock}">{{ item.quantity }} {{ item.unit }}</td>
                <td class="py-2.5 px-4 text-right text-gray-500">{{ item.unit_cost?.toLocaleString() || 0 }}đ</td>
                <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ (item.quantity * (item.unit_cost || 0)).toLocaleString() }}đ</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="bg-[hsl(var(--muted))]/60 font-bold">
                <td class="py-2.5 px-4 text-[hsl(var(--foreground))]" colspan="3">{{ $t('manager_inventory.total') }}</td>
                <td class="py-2.5 px-4 text-right text-[hsl(var(--primary))] font-black">{{ cat.totalValue.toLocaleString() }}đ</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>

    <!-- Red Invoice Summary -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-4 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" x2="8" y1="13" y2="13"/><line x1="16" x2="8" y1="17" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        {{ $t('manager_inventory.invoice_summary') }}
      </h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-red-50 border border-red-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-red-400 uppercase mb-1">{{ $t('manager_inventory.dinner') }}</div>
          <div class="font-black text-lg text-red-700">7,200,000đ</div>
        </div>
        <div class="bg-orange-50 border border-orange-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-orange-400 uppercase mb-1">{{ $t('manager_inventory.lunch') }}</div>
          <div class="font-black text-lg text-orange-700">3,400,000đ</div>
        </div>
        <div class="bg-purple-50 border border-purple-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-purple-400 uppercase mb-1">{{ $t('manager_inventory.wine') }}</div>
          <div class="font-black text-lg text-purple-700">1,100,000đ</div>
        </div>
        <div class="bg-blue-50 border border-blue-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-blue-400 uppercase mb-1">{{ $t('manager_inventory.delivery') }}</div>
          <div class="font-black text-lg text-blue-700">700,000đ</div>
        </div>
      </div>
      <div class="flex items-center justify-between bg-[hsl(var(--muted))] rounded-xl p-4">
        <div>
          <div class="font-black text-lg text-[hsl(var(--foreground))]">{{ $t('manager_inventory.total_revenue_to_invoice') }}</div>
          <div class="text-sm text-gray-500">{{ $t('manager_inventory.include_vat') }}</div>
        </div>
        <div class="text-3xl font-black text-[hsl(var(--primary))]">12,400,000đ</div>
      </div>
      <div class="flex gap-3 mt-4">
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex-1">
          {{ $t('manager_inventory.download_xml') }}
        </button>
        <button class="kawaii-btn-primary px-6 py-2 text-sm font-bold flex-1">
          {{ $t('manager_inventory.send_tax_data') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useInventory } from '@/composables/useInventory'

const { t } = useI18n()
const { inventory, fetchInventory } = useInventory()

onMounted(() => {
  fetchInventory()
})

const categories = computed(() => {
  const map = new Map<string, typeof inventory.value>()
  for (const item of inventory.value) {
    const cat = item.category_name_vi || t('manager_inventory.category_other')
    if (!map.has(cat)) map.set(cat, [])
    map.get(cat)!.push(item)
  }
  return Array.from(map.entries()).map(([name, items]) => ({
    name,
    items,
    totalValue: items.reduce((sum, i) => sum + (i.quantity * i.unit_cost), 0)
  }))
})

const totalInventoryCount = computed(() => inventory.value.length)
const totalInventoryValue = computed(() => {
  return inventory.value.reduce((sum, item) => sum + (item.quantity * item.unit_cost), 0)
})
</script>
