<template>
  <div class="audit-logs p-4">
    <h1 class="text-2xl font-bold mb-4">Audit Logs</h1>
    <div class="bg-white border p-4 shadow rounded">
      <p class="text-gray-500 mb-4">System activity monitoring and security review.</p>
      <table class="w-full text-left border-collapse">
        <thead class="bg-gray-100">
          <tr>
            <th class="border p-2">Time</th>
            <th class="border p-2">Action</th>
            <th class="border p-2">User ID</th>
            <th class="border p-2">Details</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in logs" :key="log.id">
            <td class="border p-2">{{ log.created_at }}</td>
            <td class="border p-2">{{ log.action }}</td>
            <td class="border p-2">{{ log.user_id }}</td>
            <td class="border p-2"><pre class="text-xs">{{ log.old_data }} -> {{ log.new_data }}</pre></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useBOD } from '@/composables/useBOD'

const { getAuditLogs } = useBOD()
const logs = ref<any[]>([])

onMounted(async () => {
  logs.value = await getAuditLogs()
})
</script>
