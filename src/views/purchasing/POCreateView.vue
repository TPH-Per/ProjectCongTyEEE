<template>
  <div class="po-create p-4">
    <h1 class="text-2xl font-bold mb-4">Create Purchase Order</h1>
    <form @submit.prevent="submitPO" class="space-y-4 max-w-xl">
      <div>
        <label>Supplier ID</label>
        <input v-model="form.supplierId" class="w-full border p-2" required />
      </div>
      <div>
        <label>Expected Delivery Date</label>
        <input type="date" v-model="form.expectedDeliveryDate" class="w-full border p-2" />
      </div>
      
      <!-- Normally we would have a dynamic list of items here -->
      <div class="border p-4 bg-gray-50">
        <h3 class="font-bold mb-2">Item 1</h3>
        <input v-model="mockItem.ingredientId" placeholder="Ingredient ID" class="w-full border p-2 mb-2" required />
        <input type="number" v-model="mockItem.orderedQuantity" placeholder="Quantity" class="w-full border p-2 mb-2" required />
        <input v-model="mockItem.unit" placeholder="Unit" class="w-full border p-2 mb-2" required />
        <input type="number" v-model="mockItem.unitPrice" placeholder="Unit Price" class="w-full border p-2 mb-2" required />
      </div>

      <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded w-full">Create PO</button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { usePurchaseOrder } from '@/composables/usePurchaseOrder'

const { createPurchaseOrder } = usePurchaseOrder()

const form = ref({
  supplierId: '',
  expectedDeliveryDate: ''
})

const mockItem = ref({
  ingredientId: '',
  orderedQuantity: 1,
  unit: 'kg',
  unitPrice: 10000
})

const submitPO = async () => {
  try {
    await createPurchaseOrder({
      supplierId: form.value.supplierId,
      expectedDeliveryDate: form.value.expectedDeliveryDate,
      items: [mockItem.value]
    })
    alert('PO Created successfully!')
  } catch(e: any) {
    alert(e.message)
  }
}
</script>
