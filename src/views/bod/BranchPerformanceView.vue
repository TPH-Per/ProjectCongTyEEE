<template>
  <div class="branch-performance p-4">
    <h1 class="text-2xl font-bold mb-4">Branch Performance</h1>
    <div class="bg-white border p-4 shadow rounded">
      <p class="text-gray-500 mb-4">Compare branch revenue, wait times, and satisfaction scores.</p>
      <ul>
        <li v-for="branch in branchPerformance" :key="branch.branch_id" class="border p-2 mb-2 rounded">
          <span class="font-bold">Branch ID: {{ branch.branch_id }}</span> - Revenue: {{ branch.revenue }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useBOD } from '@/composables/useBOD'

const { branchPerformance, fetchBranchPerformance } = useBOD()

onMounted(async () => {
  try {
    await fetchBranchPerformance('2026-06-01', '2026-06-30')
  } catch(e) {
    console.log('RPC not fully set up', e)
  }
})
</script>
