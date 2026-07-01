<template>
  <div class="po-list-view p-4">
    <h1 class="text-2xl font-bold mb-4">Purchase Orders</h1>
    <div v-if="loading" class="text-gray-500">Loading...</div>
    <table v-else class="w-full border-collapse">
      <thead>
        <tr class="bg-gray-100">
          <th class="border p-2">PO Number</th>
          <th class="border p-2">Supplier</th>
          <th class="border p-2">Total Amount</th>
          <th class="border p-2">Status</th>
          <th class="border p-2">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="po in purchaseOrders" :key="po.id" class="hover:bg-gray-50">
          <td class="border p-2">{{ po.po_number }}</td>
          <td class="border p-2">{{ po.supplier?.name || 'N/A' }}</td>
          <td class="border p-2">{{ po.total_amount }}</td>
          <td class="border p-2">{{ po.status }}</td>
          <td class="border p-2 space-x-2">
            <button @click="viewDetails(po.id)" class="text-blue-500">View</button>
            <button v-if="po.status === 'SUBMITTED'" @click="handleCancel(po.id)" class="text-red-500">Cancel</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { usePurchaseOrder } from '@/composables/usePurchaseOrder'

const { purchaseOrders, listPurchaseOrders, cancelPurchaseOrder } = usePurchaseOrder()
const loading = false // Simplified

onMounted(async () => {
  await listPurchaseOrders()
})

const viewDetails = (id: string) => {
  console.log('View details', id)
}

const handleCancel = async (id: string) => {
  await cancelPurchaseOrder(id, 'Cancelled by user')
  await listPurchaseOrders()
}
</script>
