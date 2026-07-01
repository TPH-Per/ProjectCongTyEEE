<template>
  <div class="tax-export p-4">
    <h1 class="text-2xl font-bold mb-4">Tax Export</h1>
    <div class="bg-white border rounded shadow p-4">
      <p class="text-gray-600 mb-4">Generate and finalize VAT records for government portals.</p>
      <div class="flex space-x-2">
        <button @click="handleGenerate" class="px-4 py-2 bg-blue-600 text-white rounded">Generate Daily Record</button>
      </div>
      <ul class="mt-4 space-y-2">
        <li v-for="record in taxRecords" :key="record.id" class="p-2 border rounded flex justify-between">
          <span>{{ record.period_start }} to {{ record.period_end }} - Status: {{ record.status }}</span>
          <button v-if="record.status !== 'FINALIZED'" @click="handleFinalize(record.id)" class="text-green-600">Finalize</button>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAccounting } from '@/composables/useAccounting'

const { taxRecords, listTaxRecords, generateTaxRecord, finalizeTaxRecord } = useAccounting()

onMounted(async () => {
  await listTaxRecords(new Date().getFullYear())
})

const handleGenerate = async () => {
  try {
    await generateTaxRecord('DAILY', '2026-06-29', '2026-06-29')
    await listTaxRecords()
  } catch (e: any) {
    alert(e.message)
  }
}

const handleFinalize = async (id: string) => {
  try {
    await finalizeTaxRecord(id)
    await listTaxRecords()
  } catch (e: any) {
    alert(e.message)
  }
}
</script>
