<template>
  <div class="calendar-container">
    <div class="calendar-header">
      <button class="nav-btn" @click="previousDay">‹</button>
      <h2>{{ formattedDate }}</h2>
      <button class="nav-btn" @click="nextDay">›</button>
    </div>

    <div class="time-slots">
      <div 
        :class="['time-slot', { active: selectedTime === 'all' }]"
        @click="selectedTime = 'all'"
      >
        <div class="slot-time">Tất cả</div>
        <div class="slot-label">Tổng số</div>
        <div class="slot-count">{{ reservations.length }}</div>
      </div>
      <div 
        v-for="slot in computedTimeSlots" 
        :key="slot.time"
        :class="['time-slot', { active: selectedTime === slot.time }]"
        @click="selectedTime = slot.time"
      >
        <div class="slot-time">{{ slot.time === 'morning' ? 'Sáng' : slot.time === 'lunch' ? 'Trưa' : slot.time === 'afternoon' ? 'Chiều' : 'Tối' }}</div>
        <div class="slot-label">{{ slot.label }}</div>
        <div class="slot-count">{{ slot.count }}</div>
      </div>
    </div>

    <div class="reservations-list">
      <div v-if="filteredReservations.length === 0" class="no-reservations">
        Chưa có lượt đặt bàn nào trong khung giờ này.
      </div>
      <div 
        v-else
        v-for="reservation in filteredReservations" 
        :key="reservation.id"
        class="reservation-card"
        @click="$emit('selectReservation', reservation.id)"
      >
        <div class="reservation-time">{{ reservation.time }}</div>
        <div class="reservation-info">
          <div class="customer-name">{{ reservation.customerName }}</div>
          <div class="reservation-details">
            {{ reservation.guests }} khách • {{ reservation.tables }} bàn
          </div>
          <div v-if="reservation.notes" class="reservation-notes">
            📝 {{ reservation.notes }}
          </div>
        </div>
        <div :class="['status-badge', `status-${reservation.status}`]">
          {{ reservation.status === 'confirmed' ? 'Đã xác nhận' : reservation.status === 'dining' ? 'Đang dùng bữa' : 'Chờ xác nhận' }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useHallStore } from '@/stores/hallStore'

const props = defineProps<{
  reservations: any[]
}>()

defineEmits<{
  selectReservation: [id: string]
}>()

const hallStore = useHallStore()
const selectedTime = ref('all')

const formattedDate = computed(() => {
  const d = new Date(hallStore.selectedDate)
  if (isNaN(d.getTime())) return hallStore.selectedDate
  return d.toLocaleDateString('vi-VN', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
})

const computedTimeSlots = computed(() => {
  const slots = [
    { time: 'morning', label: 'Sáng', count: 0 },
    { time: 'lunch', label: 'Trưa', count: 0 },
    { time: 'afternoon', label: 'Chiều', count: 0 },
    { time: 'evening', label: 'Tối', count: 0 }
  ]
  props.reservations.forEach(r => {
    const slot = slots.find(s => s.time === r.timeSlot)
    if (slot) slot.count++
  })
  return slots
})

const filteredReservations = computed(() => {
  if (selectedTime.value === 'all') return props.reservations
  return props.reservations.filter(r => r.timeSlot === selectedTime.value)
})

function previousDay() {
  const d = new Date(hallStore.selectedDate)
  d.setDate(d.getDate() - 1)
  hallStore.setSelectedDate(d.toISOString().split('T')[0])
}

function nextDay() {
  const d = new Date(hallStore.selectedDate)
  d.setDate(d.getDate() + 1)
  hallStore.setSelectedDate(d.toISOString().split('T')[0])
}
</script>

<style scoped>
.calendar-container {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.calendar-header h2 {
  font-size: 18px;
  font-weight: 800;
  color: #111827;
  margin: 0;
}

.nav-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #f3f4f6;
  border: none;
  font-size: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #4b5563;
  transition: all 0.2s;
}

.nav-btn:hover {
  background: #e5e7eb;
  color: #111827;
}

.time-slots {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-bottom: 24px;
}

.time-slot {
  padding: 12px 8px;
  background: #f9fafb;
  border-radius: 8px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid #e5e7eb;
}

.time-slot:hover {
  border-color: #f97316;
  background: #fff7ed;
}

.time-slot.active {
  background: #f97316;
  color: white;
  border-color: #f97316;
}

.slot-time {
  font-size: 11px;
  opacity: 0.8;
  font-weight: 600;
}

.slot-label {
  font-size: 13px;
  font-weight: 700;
  margin: 2px 0;
}

.slot-count {
  font-size: 20px;
  font-weight: 800;
}

.reservations-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.no-reservations {
  text-align: center;
  padding: 40px 20px;
  color: #6b7280;
  font-weight: 600;
  background: #f9fafb;
  border-radius: 8px;
  border: 1px dashed #d1d5db;
}

.reservation-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid #e5e7eb;
}

.reservation-card:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
  transform: translateY(-1px);
}

.reservation-time {
  font-size: 16px;
  font-weight: 800;
  color: #f97316;
  min-width: 70px;
}

.reservation-info {
  flex: 1;
}

.customer-name {
  font-size: 15px;
  font-weight: 700;
  color: #111827;
}

.reservation-details {
  font-size: 13px;
  color: #6b7280;
  margin-top: 2px;
  font-weight: 600;
}

.reservation-notes {
  font-size: 12px;
  color: #4b5563;
  margin-top: 4px;
  font-style: italic;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 700;
  text-transform: capitalize;
}

.status-confirmed {
  background: #d1fae5;
  color: #065f46;
}

.status-dining {
  background: #dbeafe;
  color: #1e40af;
}

.status-pending {
  background: #fef3c7;
  color: #92400e;
}
</style>
