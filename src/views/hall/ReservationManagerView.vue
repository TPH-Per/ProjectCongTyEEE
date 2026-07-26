<template>
  <div class="reservation-manager p-4">
    <h1 class="text-2xl font-bold mb-4">Reservation Manager</h1>
    <div v-if="loading" class="text-gray-500">Loading...</div>
    <div v-else>
      <ul class="space-y-2">
        <li v-for="res in reservations" :key="res.id" class="p-4 border rounded">
          <p class="font-bold">{{ (res.customer_snapshot as any)?.name || 'Guest' }} - {{ res.guests }} guests</p>
          <p>Time: {{ res.reservation_time }}</p>
          <p>Status: {{ res.status }}</p>
          <div class="mt-2 space-x-2">
            <button @click="handleSeat(res.id)" class="px-3 py-1 bg-blue-500 text-white rounded">Seat</button>
            <button @click="handleCancel(res.id)" class="px-3 py-1 bg-red-500 text-white rounded">Cancel</button>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useReservation } from '@/composables/useReservation'

const { reservations, loading, listReservations, seatReservation, cancelReservation } = useReservation()

onMounted(async () => {
  await listReservations()
})

const handleSeat = async (id: string) => {
  try {
    await seatReservation(id)
    await listReservations()
  } catch (e: any) {
    alert(e.message)
  }
}

const handleCancel = async (id: string) => {
  try {
    await cancelReservation(id, 'Staff cancelled')
    await listReservations()
  } catch (e: any) {
    alert(e.message)
  }
}
</script>
