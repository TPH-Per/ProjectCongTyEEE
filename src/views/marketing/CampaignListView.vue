<template>
  <div class="campaign-list p-4">
    <h1 class="text-2xl font-bold mb-4">Marketing Campaigns</h1>
    <div class="bg-white border p-4 shadow rounded">
      <button class="bg-blue-600 text-white px-4 py-2 rounded mb-4">Create Campaign</button>
      <table class="w-full text-left border-collapse">
        <thead class="bg-gray-100">
          <tr>
            <th class="border p-2">Name</th>
            <th class="border p-2">Type</th>
            <th class="border p-2">Start Date</th>
            <th class="border p-2">End Date</th>
            <th class="border p-2">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in campaigns" :key="c.id" class="hover:bg-gray-50">
            <td class="border p-2">{{ c.name }}</td>
            <td class="border p-2">{{ c.type }}</td>
            <td class="border p-2">{{ c.start_date }}</td>
            <td class="border p-2">{{ c.end_date }}</td>
            <td class="border p-2">{{ c.status }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useCampaign } from '@/composables/useCampaign'

const { campaigns, listCampaigns } = useCampaign()

onMounted(async () => {
  await listCampaigns()
})
</script>
