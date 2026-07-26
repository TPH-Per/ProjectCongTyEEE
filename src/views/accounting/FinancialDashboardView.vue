<template>
  <div class="financial-dashboard p-4">
    <h1 class="text-2xl font-bold mb-4">Financial Dashboard</h1>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
      <div class="p-4 bg-white shadow rounded border">
        <h2 class="text-gray-500 text-sm">Total Revenue</h2>
        <p class="text-2xl font-bold text-green-600">₫0</p>
      </div>
      <div class="p-4 bg-white shadow rounded border">
        <h2 class="text-gray-500 text-sm">Total COGS</h2>
        <p class="text-2xl font-bold text-red-600">₫0</p>
      </div>
      <div class="p-4 bg-white shadow rounded border">
        <h2 class="text-gray-500 text-sm">Net Profit</h2>
        <p class="text-2xl font-bold text-blue-600">₫0</p>
      </div>
    </div>
    
    <div class="bg-white p-4 border rounded shadow">
      <h2 class="text-xl font-bold mb-2">P&L Report</h2>
      <p class="text-gray-500">Run RPC `get_profit_loss` to populate data here.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAccounting } from '@/composables/useAccounting'

const { fetchProfitLoss } = useAccounting()

onMounted(async () => {
  try {
    await fetchProfitLoss('2026-06-01', '2026-06-30')
  } catch (e) {
    console.warn('RPC not ready yet', e)
  }
})
</script>
