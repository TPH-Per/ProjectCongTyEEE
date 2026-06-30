<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight">{{ $t('purchasing.orders') }}</h1>
        <p class="text-muted-foreground">{{ $t('purchasing.orders_desc', 'Manage and track your purchase orders.') }}</p>
      </div>
      <button class="px-4 py-2 bg-[hsl(var(--primary))] text-white rounded-lg font-medium text-sm hover:bg-[hsl(var(--primary))]/90">
        {{ $t('purchasing.new_order', 'New Order') }}
      </button>
    </div>
    
    <div class="bg-white rounded-xl border border-[hsl(var(--border))] shadow-sm overflow-hidden">
      <div v-if="loading" class="p-6 text-center text-[hsl(var(--muted-foreground))] py-12">
        Loading...
      </div>
      <div v-else-if="orders.length === 0" class="p-6 text-center text-[hsl(var(--muted-foreground))] py-12">
        {{ $t('purchasing.no_orders_found', 'No purchase orders found.') }}
      </div>
      <table v-else class="w-full text-left text-sm text-gray-600">
        <thead class="bg-gray-50 text-xs uppercase text-gray-500 border-b border-gray-100">
          <tr>
            <th class="px-6 py-4 font-semibold">PO Number</th>
            <th class="px-6 py-4 font-semibold">Status</th>
            <th class="px-6 py-4 font-semibold">Total Amount</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 bg-white">
          <tr v-for="order in orders" :key="order.id" class="hover:bg-gray-50/50 transition-colors">
            <td class="px-6 py-4 font-medium text-gray-800">{{ order.po_number }}</td>
            <td class="px-6 py-4">
              <span class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">{{ order.status }}</span>
            </td>
            <td class="px-6 py-4">{{ order.total_amount }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { usePurchasing } from '@/composables/usePurchasing'
import { useI18n } from 'vue-i18n'

const { fetchPurchaseOrders, loading } = usePurchasing()
const orders = ref<any[]>([])
const { t } = useI18n()

onMounted(async () => {
  try {
    orders.value = await fetchPurchaseOrders()
  } catch (e) {
    console.error(e)
  }
})
</script>
