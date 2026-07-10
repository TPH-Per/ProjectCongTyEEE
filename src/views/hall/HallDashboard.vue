<template>
  <div class="hall-container">
    <!-- Sidebar -->
    <HallSidebar 
      :current-view="currentView"
      @navigate="setCurrentView"
    />

    <!-- Main Content -->
    <main class="hall-main">
      <HallHeader 
        :title="currentViewTitle"
        :date="selectedDate"
        @date-change="setSelectedDate"
      />

      <div class="hall-content">
        <!-- Calendar View -->
        <ReservationCalendar 
          v-if="currentView === 'calendar'"
          :reservations="todayReservations"
          @select-reservation="goToDetail"
        />

        <!-- Reservation Detail -->
        <ReservationDetail 
          v-else-if="currentView === 'detail'"
          :reservation-id="selectedReservationId"
        />

        <!-- Floor Plan (Cloned from Reception) -->
        <FloorPlanView 
          v-else-if="currentView === 'floor-plan'"
          :tables="tables"
          @select-table="goToOrderMenu"
        />

        <!-- Order Menu (Cloned from Reception) -->
        <OrderMenuView 
          v-else-if="currentView === 'order-menu'"
          :menu-items="menuItems"
          :table-code="selectedTableCode"
        />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useHallStore } from '@/stores/hallStore'
import HallSidebar from './components/HallSidebar.vue'
import HallHeader from './components/HallHeader.vue'
import ReservationCalendar from './ReservationCalendar.vue'
import ReservationDetail from './ReservationDetail.vue'
import FloorPlanView from './FloorPlanView.vue'
import OrderMenuView from './OrderMenuView.vue'

const router = useRouter()
const route = useRoute()
const hallStore = useHallStore()

const currentView = computed(() => hallStore.currentView)
const selectedDate = computed(() => hallStore.selectedDate)
const todayReservations = computed(() => hallStore.todayReservations)
const tables = computed(() => hallStore.tables)
const menuItems = computed(() => hallStore.menuItems)

// Extract params/query from URL to keep state on refresh
const selectedReservationId = computed(() => {
  return (route.params.id as string) || null
})

const selectedTableCode = computed(() => {
  return (route.query.table as string) || null
})

const currentViewTitle = computed(() => {
  const titles = {
    'calendar': 'Lịch đặt bàn',
    'detail': 'Chi tiết đặt bàn',
    'floor-plan': 'Sơ đồ bàn',
    'order-menu': 'Chọn món'
  }
  return titles[currentView.value] || 'Hall Dashboard'
})

// Sync URL route name to store state
watch(
  () => route.name,
  (newName) => {
    if (newName === 'hall.calendar') {
      hallStore.setCurrentView('calendar')
    } else if (newName === 'hall.reservation-detail') {
      hallStore.setCurrentView('detail')
    } else if (newName === 'hall.floor-plan') {
      hallStore.setCurrentView('floor-plan')
    } else if (newName === 'hall.order-menu') {
      hallStore.setCurrentView('order-menu')
    } else {
      hallStore.setCurrentView('calendar')
    }
  },
  { immediate: true }
)

function setCurrentView(view: any) {
  hallStore.setCurrentView(view)
  router.push({ name: `hall.${view}` })
}

function setSelectedDate(date: string) {
  hallStore.setSelectedDate(date)
}

function goToDetail(reservationId: string) {
  router.push({ name: 'hall.reservation-detail', params: { id: reservationId } })
}

function goToOrderMenu(tableCode: string) {
  router.push({ name: 'hall.order-menu', query: { table: tableCode } })
}

onMounted(() => {
  hallStore.fetchReservations()
  hallStore.fetchTables()
  hallStore.fetchMenuItems()
})
</script>

<style scoped>
.hall-container {
  display: flex;
  height: 100vh;
  background: #f3f4f6;
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

.hall-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.hall-content {
  flex: 1;
  overflow: auto;
  padding: 24px;
}
</style>
