<template>
  <div class="active-tables-view p-4">
    <h1 class="text-2xl font-bold mb-4">Active Tables</h1>
    <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <div v-for="table in tables" :key="table.id" class="border p-4 rounded shadow bg-white">
        <h2 class="text-lg font-semibold">{{ table.code || table.name }}</h2>
        <p>Status: <span class="font-bold">{{ table.status }}</span></p>
        <p v-if="table.current_order_id">Order: {{ table.current_order_id }}</p>
        <!-- Mock timers and requests -->
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useTable } from '@/composables/useTable'

const tables = ref<any[]>([])
const { listTables } = useTable()

onMounted(async () => {
  tables.value = await listTables()
})
</script>
