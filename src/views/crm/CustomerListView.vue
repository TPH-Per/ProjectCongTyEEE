<template>
  <div class="customer-list p-4">
    <h1 class="text-2xl font-bold mb-4">Customer Directory</h1>
    <div class="bg-white border shadow p-4 rounded">
      <p class="text-gray-500 mb-4">List of all registered customers with tier information and loyalty points.</p>
      <!-- Example list -->
      <table class="w-full border-collapse">
        <thead class="bg-gray-50">
          <tr>
            <th class="border p-2">Name</th>
            <th class="border p-2">Phone</th>
            <th class="border p-2">Tier</th>
            <th class="border p-2">Points</th>
            <th class="border p-2">Total Spent</th>
            <th class="border p-2">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td colspan="6" class="p-4 text-center text-gray-500">To be implemented using `useCustomer.ts` or similar</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
</script>
