<template>
  <header class="hall-header">
    <div class="header-left">
      <h1 class="view-title">{{ title }}</h1>
    </div>

    <div class="header-right">
      <!-- Date Picker -->
      <div class="date-selector">
        <button class="date-nav-btn" @click="prevDay">‹</button>
        <div class="date-display">
          <span class="calendar-icon">📅</span>
          <span class="date-text">{{ formattedDate }}</span>
        </div>
        <button class="date-nav-btn" @click="nextDay">›</button>
      </div>

      <div class="header-actions">
        <button class="btn-logout" @click="handleLogout">Đăng xuất</button>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const props = defineProps<{
  title: string
  date: string
}>()

const emit = defineEmits<{
  'date-change': [newDate: string]
}>()

const router = useRouter()
const { signOut } = useAuth()

const formattedDate = computed(() => {
  const d = new Date(props.date)
  if (isNaN(d.getTime())) return props.date
  return d.toLocaleDateString('vi-VN', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
})

function prevDay() {
  const d = new Date(props.date)
  d.setDate(d.getDate() - 1)
  emit('date-change', d.toISOString().split('T')[0])
}

function nextDay() {
  const d = new Date(props.date)
  d.setDate(d.getDate() + 1)
  emit('date-change', d.toISOString().split('T')[0])
}

async function handleLogout() {
  await signOut()
  router.push({ name: 'login' })
}
</script>

<style scoped>
.hall-header {
  height: 70px;
  background: white;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
}

.view-title {
  font-size: 20px;
  font-weight: 800;
  color: #1f2937;
  margin: 0;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.date-selector {
  display: flex;
  align-items: center;
  background: #f3f4f6;
  border-radius: 8px;
  padding: 4px;
  border: 1px solid #e5e7eb;
}

.date-nav-btn {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  font-size: 18px;
  font-weight: bold;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  color: #4b5563;
  transition: background 0.2s;
}

.date-nav-btn:hover {
  background: #e5e7eb;
}

.date-display {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 12px;
  font-weight: 600;
  font-size: 14px;
  color: #1f2937;
}

.calendar-icon {
  font-size: 16px;
}

.btn-logout {
  padding: 8px 16px;
  background: transparent;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  color: #4b5563;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout:hover {
  background: #fee2e2;
  border-color: #fca5a5;
  color: #dc2626;
}
</style>
