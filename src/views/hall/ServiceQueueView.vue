<template>
  <div class="service-queue p-4">
    <h1 class="text-2xl font-bold mb-4">Service Queue</h1>
    <div v-if="openRequests.length === 0" class="text-gray-500">No pending requests.</div>
    <ul class="space-y-2" v-else>
      <li v-for="req in openRequests" :key="req.id" class="p-4 border rounded" :class="req.priority === 'URGENT' ? 'bg-red-50 border-red-200' : ''">
        <p class="font-bold">Table: {{ req.table_id }}</p>
        <p>Type: {{ req.type }}</p>
        <p v-if="req.message">Msg: {{ req.message }}</p>
        <p>Status: {{ req.status }}</p>
        <div class="mt-2 space-x-2">
          <button v-if="req.status === 'OPEN'" @click="startHandling(req.id)" class="px-3 py-1 bg-yellow-500 text-white rounded">Mark In Progress</button>
          <button @click="resolveRequest(req.id)" class="px-3 py-1 bg-green-500 text-white rounded">Resolve</button>
        </div>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useServiceRequest } from '@/composables/useServiceRequest'

const { openRequests, fetchOpenRequests, startHandling, resolveRequest, subscribeToRequests } = useServiceRequest()
let channel: any

onMounted(async () => {
  await fetchOpenRequests()
  channel = subscribeToRequests((newReq) => {
    fetchOpenRequests() // Refresh on update
  })
})

onUnmounted(() => {
  if (channel) channel.unsubscribe()
})
</script>
