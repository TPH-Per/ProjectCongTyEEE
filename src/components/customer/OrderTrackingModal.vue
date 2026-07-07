<template>
  <Transition name="fade">
    <div class="modal-overlay" @click.self="$emit('close')">
      <div class="modal-container">
        <!-- Header -->
        <div class="modal-header">
          <div class="header-left">
            <span class="modal-icon">📋</span>
            <div>
              <h2 class="modal-title">Theo dõi món ăn</h2>
              <p class="modal-subtitle">Bàn {{ tableNumber }} • {{ items.length }} món</p>
            </div>
          </div>
          <button class="close-btn" @click="$emit('close')">×</button>
        </div>

        <!-- Status Summary -->
        <div class="status-summary">
          <div class="status-card status-served">
            <div class="status-icon"></div>
            <div class="status-info">
              <div class="status-count">{{ servedItems.length }}</div>
              <div class="status-label">Đã phục vụ</div>
            </div>
          </div>
          <div class="status-card status-preparing">
            <div class="status-icon"></div>
            <div class="status-info">
              <div class="status-count">{{ preparingItems.length }}</div>
              <div class="status-label">Đang chế biến</div>
            </div>
          </div>
          <div class="status-card status-pending">
            <div class="status-icon"></div>
            <div class="status-info">
              <div class="status-count">{{ pendingItems.length }}</div>
              <div class="status-label">Chờ xử lý</div>
            </div>
          </div>
        </div>

        <!-- Filter Tabs -->
        <div class="filter-tabs">
          <button 
            :class="['tab-btn', { active: activeFilter === 'all' }]"
            @click="activeFilter = 'all'"
          >
            Tất cả ({{ items.length }})
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'served' }]"
            @click="activeFilter = 'served'"
          >
            Đã phục vụ ({{ servedItems.length }})
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'preparing' }]"
            @click="activeFilter = 'preparing'"
          >
            Đang chế biến ({{ preparingItems.length }})
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'pending' }]"
            @click="activeFilter = 'pending'"
          >
            Chờ xử lý ({{ pendingItems.length }})
          </button>
        </div>

        <!-- Items List -->
        <div class="items-list scrollbar-hide">
          <div 
            v-for="item in filteredItems" 
            :key="item.id"
            :class="['item-card', `status-${item.status}`]"
          >
            <div class="item-header">
              <div class="item-info">
                <h3 class="item-name">{{ item.name }}</h3>
                <div class="item-meta">
                  <span class="item-quantity">SL: {{ item.quantity }}</span>
                  <span class="item-time">Đặt lúc {{ item.orderedTime }}</span>
                </div>
              </div>
              <div class="item-status-badge">
                <span v-if="item.status === 'served'" class="badge badge-served">Đã phục vụ</span>
                <span v-else-if="item.status === 'preparing'" class="badge badge-preparing">Đang chế biến</span>
                <span v-else class="badge badge-pending">Chờ xử lý</span>
              </div>
            </div>

            <!-- Progress Bar -->
            <div class="progress-bar">
              <div 
                class="progress-fill"
                :class="`progress-${item.status}`"
                :style="{ width: getProgressWidth(item.status) }"
              ></div>
            </div>

            <!-- Timeline -->
            <div class="timeline">
              <div class="timeline-item completed">
                <div class="timeline-dot">✓</div>
                <div class="timeline-label">Đã đặt</div>
                <div class="timeline-time">{{ item.orderedTime }}</div>
              </div>
              <div class="timeline-item" :class="{ completed: item.status !== 'pending' }">
                <div class="timeline-dot">✓</div>
                <div class="timeline-label">Đang chế biến</div>
                <div class="timeline-time">{{ item.status === 'preparing' || item.status === 'served' ? '...' : '--:--' }}</div>
              </div>
              <div class="timeline-item" :class="{ completed: item.status === 'served' }">
                <div class="timeline-dot">✓</div>
                <div class="timeline-label">Đã phục vụ</div>
                <div class="timeline-time">{{ item.servedTime || '--:--' }}</div>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="filteredItems.length === 0" class="empty-state">
            <div class="empty-icon">🍽️</div>
            <p class="empty-text">Không có món nào</p>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer">
          <button class="btn-refresh" @click="refreshStatus">
            Làm mới
          </button>
          <button class="btn-close" @click="$emit('close')">
            Đóng
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{
  items: Array<{
    id: string | number
    name: string
    quantity: number
    status: 'pending' | 'preparing' | 'served'
    orderedTime: string
    servedTime: string | null
  }>
  tableNumber: string
}>()

const emit = defineEmits<{
  close: []
  refresh: []
}>()

const activeFilter = ref<'all' | 'served' | 'preparing' | 'pending'>('all')

const servedItems = computed(() => props.items.filter(item => item.status === 'served'))
const preparingItems = computed(() => props.items.filter(item => item.status === 'preparing'))
const pendingItems = computed(() => props.items.filter(item => item.status === 'pending'))

const filteredItems = computed(() => {
  if (activeFilter.value === 'all') return props.items
  return props.items.filter(item => item.status === activeFilter.value)
})

function getProgressWidth(status: string): string {
  if (status === 'pending') return '33%'
  if (status === 'preparing') return '66%'
  return '100%'
}

function refreshStatus() {
  emit('refresh')
}
</script>

<style scoped>
/* Modal Overlay */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(8px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-container {
  background: #23170e;
  border: 1px solid #442c19;
  border-radius: 16px;
  width: 100%;
  max-width: 600px;
  max-height: 85vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.6);
}

/* Header */
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: linear-gradient(135deg, #1a110a 0%, #2a1c11 100%);
  border-bottom: 1px solid #442c19;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.modal-icon {
  font-size: 28px;
}

.modal-title {
  font-size: 18px;
  font-weight: 900;
  color: #ff9800;
  margin: 0;
  font-family: serif;
}

.modal-subtitle {
  font-size: 12px;
  color: #a8a8a8;
  margin: 4px 0 0 0;
  font-weight: bold;
}

.close-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #3a2517;
  border: 1px solid #5a3d25;
  color: #c8c8c8;
  font-size: 20px;
  font-weight: bold;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #d32f2f;
  color: white;
  border-color: #d32f2f;
  transform: rotate(90deg);
}

/* Status Summary */
.status-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px 24px;
  background: #1a110a;
  border-bottom: 1px solid #442c19;
}

.status-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  background: #2a1c11;
  border: 1px solid #3d2817;
}

.status-icon {
  width: 24px;
  height: 24px;
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.status-served .status-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%234CAF50' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='20 6 9 17 4 12'%3E%3C/polyline%3E%3C/svg%3E");
}

.status-preparing .status-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23FF9800' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6'/%3E%3C/svg%3E");
}

.status-pending .status-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23f44336' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='10'%3E%3C/circle%3E%3Cpolyline points='12 6 12 12 16 14'%3E%3C/polyline%3E%3C/svg%3E");
}

.status-count {
  font-size: 18px;
  font-weight: 900;
}

.status-label {
  font-size: 10px;
  color: #a8a8a8;
  margin-top: 1px;
  font-weight: bold;
}

.status-served .status-count { color: #4CAF50; }
.status-preparing .status-count { color: #FF9800; }
.status-pending .status-count { color: #f44336; }

/* Filter Tabs */
.filter-tabs {
  display: flex;
  gap: 8px;
  padding: 12px 24px;
  border-bottom: 1px solid #442c19;
  overflow-x: auto;
}

.tab-btn {
  padding: 8px 16px;
  background: #2a1c11;
  border: 1px solid #3d2817;
  border-radius: 20px;
  color: #a8a8a8;
  font-size: 11px;
  font-weight: bold;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: #3d2817;
  color: white;
}

.tab-btn.active {
  background: #E8772E;
  border-color: #E8772E;
  color: white;
}

/* Items List */
.items-list {
  flex: 1;
  overflow-y: auto;
  padding: 16px 24px;
  background: #1d120a;
}

.item-card {
  background: #2a1c11;
  border: 1px solid #3d2817;
  border-radius: 12px;
  padding: 14px 16px;
  margin-bottom: 12px;
  border-left: 4px solid #444;
}

.item-card.status-served {
  border-left-color: #4CAF50;
}

.item-card.status-preparing {
  border-left-color: #FF9800;
}

.item-card.status-pending {
  border-left-color: #F44336;
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.item-name {
  font-size: 13px;
  font-weight: bold;
  color: white;
  margin: 0 0 4px 0;
}

.item-meta {
  display: flex;
  gap: 12px;
  font-size: 10px;
  color: #a8a8a8;
  font-weight: bold;
}

.item-status-badge .badge {
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 9px;
  font-weight: 800;
  display: inline-block;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.badge-served {
  background: rgba(76, 175, 80, 0.15);
  color: #4CAF50;
  border: 1px solid rgba(76, 175, 80, 0.2);
}

.badge-preparing {
  background: rgba(255, 152, 0, 0.15);
  color: #FF9800;
  border: 1px solid rgba(255, 152, 0, 0.2);
}

.badge-pending {
  background: rgba(244, 67, 54, 0.15);
  color: #F44336;
  border: 1px solid rgba(244, 67, 54, 0.2);
}

/* Progress Bar */
.progress-bar {
  height: 5px;
  background: #1a110a;
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 12px;
}

.progress-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.5s ease;
}

.progress-pending { background: #F44336; }
.progress-preparing { background: #FF9800; }
.progress-served { background: #4CAF50; }

/* Timeline */
.timeline {
  display: flex;
  justify-content: space-between;
  position: relative;
  padding-top: 6px;
}

.timeline::before {
  content: '';
  position: absolute;
  top: 13px;
  left: 0;
  right: 0;
  height: 2px;
  background: #1a110a;
  z-index: 0;
}

.timeline-item {
  flex: 1;
  text-align: center;
  position: relative;
  z-index: 1;
}

.timeline-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #1a110a;
  border: 1px solid #3d2817;
  color: #555;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 4px;
  font-size: 8px;
  font-weight: bold;
}

.timeline-item.completed .timeline-dot {
  background: #4CAF50;
  border-color: #4CAF50;
  color: white;
}

.timeline-label {
  font-size: 9px;
  color: #a8a8a8;
  margin-bottom: 1px;
  font-weight: bold;
}

.timeline-time {
  font-size: 10px;
  font-weight: bold;
  color: white;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 40px 20px;
}

.empty-icon {
  font-size: 40px;
  margin-bottom: 8px;
}

.empty-text {
  color: #a8a8a8;
  font-size: 13px;
  font-weight: bold;
}

/* Footer */
.modal-footer {
  display: flex;
  gap: 12px;
  padding: 16px 24px;
  background: #1a110a;
  border-top: 1px solid #442c19;
}

.btn-refresh,
.btn-close {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-weight: 800;
  font-size: 12px;
  cursor: pointer;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  transition: all 0.2s;
}

.btn-refresh {
  background: #E8772E;
  color: white;
}

.btn-refresh:hover {
  background: #ff9800;
}

.btn-close {
  background: #3d2817;
  border: 1px solid #5a3d25;
  color: #c8c8c8;
}

.btn-close:hover {
  background: #4e341f;
  color: white;
}

/* Animations */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Scrollbar hide */
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}
</style>
