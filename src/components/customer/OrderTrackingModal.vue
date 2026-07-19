<template>
  <Transition name="fade">
    <div class="modal-overlay" @click.self="$emit('close')">
      <div class="modal-container">
        <!-- Header -->
        <div class="modal-header">
          <div class="header-left">
            <span class="logo-icon">📋</span>
            <div>
              <h2 class="modal-title">{{ $t('customer.tracking.title') }}</h2>
              <p class="modal-subtitle">Bàn {{ tableNumber }} • {{ items.length }} món</p>
            </div>
          </div>
          <button class="close-btn" @click="$emit('close')">×</button>
        </div>

        <!-- Status Summary Cards -->
        <div class="status-summary">
          <div class="status-card served">
            <div class="status-icon">
              <span class="icon">✅</span>
              <div class="glow-effect"></div>
            </div>
            <div class="status-info">
              <div class="status-count">{{ servedItems.length }}</div>
              <div class="status-label">{{ $t('customer.tracking.served') }}</div>
            </div>
          </div>

          <div class="status-card preparing">
            <div class="status-icon">
              <span class="icon">🍲</span>
              <div class="glow-effect"></div>
            </div>
            <div class="status-info">
              <div class="status-count">{{ preparingItems.length }}</div>
              <div class="status-label">{{ $t('customer.tracking.preparing') }}</div>
            </div>
          </div>

          <div class="status-card pending">
            <div class="status-icon">
              <span class="icon">⏳</span>
              <div class="glow-effect"></div>
            </div>
            <div class="status-info">
              <div class="status-count">{{ pendingItems.length }}</div>
              <div class="status-label">{{ $t('customer.tracking.pending') }}</div>
            </div>
          </div>
        </div>

        <!-- Progress Overview Bars -->
        <div class="progress-overview">
          <div class="overview-item">
            <span class="overview-label">{{ $t('customer.tracking.served') }}</span>
            <div class="overview-bar">
              <div class="overview-fill served" :style="{ width: servedPercent + '%' }"></div>
            </div>
            <span class="overview-value">{{ servedPercent }}%</span>
          </div>
          <div class="overview-item">
            <span class="overview-label">{{ $t('customer.tracking.preparing') }}</span>
            <div class="overview-bar">
              <div class="overview-fill preparing" :style="{ width: preparingPercent + '%' }"></div>
            </div>
            <span class="overview-value">{{ preparingPercent }}%</span>
          </div>
          <div class="overview-item">
            <span class="overview-label">{{ $t('customer.tracking.pending') }}</span>
            <div class="overview-bar">
              <div class="overview-fill pending" :style="{ width: pendingPercent + '%' }"></div>
            </div>
            <span class="overview-value">{{ pendingPercent }}%</span>
          </div>
        </div>

        <!-- Filter Tabs -->
        <div class="filter-tabs">
          <button 
            :class="['tab-btn', { active: activeFilter === 'all' }]"
            @click="activeFilter = 'all'"
          >
            {{ $t('customer.tracking.filterAll', { count: items.length }) }}
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'served' }]"
            @click="activeFilter = 'served'"
          >
            {{ $t('customer.tracking.filterServed', { count: servedItems.length }) }}
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'preparing' }]"
            @click="activeFilter = 'preparing'"
          >
            {{ $t('customer.tracking.filterPreparing', { count: preparingItems.length }) }}
          </button>
          <button 
            :class="['tab-btn', { active: activeFilter === 'pending' }]"
            @click="activeFilter = 'pending'"
          >
            {{ $t('customer.tracking.filterPending', { count: pendingItems.length }) }}
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
                  <span class="item-quantity">{{ $t('customer.tracking.quantityLabel') }} {{ item.quantity }}</span>
                  <span class="item-time">{{ $t('customer.tracking.orderedAt', { time: item.orderedTime }) }}</span>
                </div>
              </div>
              <div class="item-status-badge">
                <span :class="['status-badge', `badge-${item.status}`]">{{ getStatusText(item.status) }}</span>
              </div>
            </div>

            <!-- Progress Bar -->
            <div class="progress-container">
              <div class="progress-bar">
                <div 
                  class="progress-fill"
                  :class="`progress-${item.status}`"
                  :style="{ width: getItemProgress(item.status) + '%' }"
                >
                  <div class="progress-shine"></div>
                </div>
              </div>
              <span class="progress-percent">{{ getItemProgress(item.status) }}%</span>
            </div>

            <!-- Timeline -->
            <div class="timeline">
              <div class="timeline-step completed">
                <div class="step-dot completed">
                  <span class="dot-icon">✓</span>
                </div>
                <div class="step-info">
                  <div class="step-label">{{ $t('customer.tracking.stepOrdered') }}</div>
                  <div class="step-time">{{ item.orderedTime }}</div>
                </div>
              </div>

              <div class="timeline-step" :class="{ completed: item.status !== 'pending' }">
                <div class="step-dot" :class="{ completed: item.status !== 'pending' }">
                  <span class="dot-icon">✓</span>
                </div>
                <div class="step-info">
                  <div class="step-label">{{ $t('customer.tracking.preparing') }}</div>
                  <div class="step-time">{{ item.status === 'preparing' || item.status === 'served' ? formatTime(item.orderedTime) : '--:--' }}</div>
                </div>
              </div>

              <div class="timeline-step" :class="{ completed: item.status === 'served' }">
                <div class="step-dot" :class="{ completed: item.status === 'served' }">
                  <span class="dot-icon">✓</span>
                </div>
                <div class="step-info">
                  <div class="step-label">{{ $t('customer.tracking.served') }}</div>
                  <div class="step-time">{{ item.servedTime || '--:--' }}</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="filteredItems.length === 0" class="empty-state">
            <div class="empty-icon">🍽️</div>
            <p class="empty-text">{{ $t('customer.tracking.emptyTitle') }}</p>
            <p class="empty-subtext">{{ $t('customer.tracking.emptyText') }}</p>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer">
          <button class="btn-refresh" @click="refreshStatus">
            {{ $t('customer.tracking.refresh') }}
          </button>
          <button class="btn-close" @click="$emit('close')">
            {{ $t('customer.tracking.close') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'

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

const { t } = useI18n()

const activeFilter = ref<'all' | 'served' | 'preparing' | 'pending'>('all')

const servedItems = computed(() => props.items.filter(item => item.status === 'served'))
const preparingItems = computed(() => props.items.filter(item => item.status === 'preparing'))
const pendingItems = computed(() => props.items.filter(item => item.status === 'pending'))

const servedPercent = computed(() => {
  if (props.items.length === 0) return 0
  return Math.round((servedItems.value.length / props.items.length) * 100)
})
const preparingPercent = computed(() => {
  if (props.items.length === 0) return 0
  return Math.round((preparingItems.value.length / props.items.length) * 100)
})
const pendingPercent = computed(() => {
  if (props.items.length === 0) return 0
  return Math.round((pendingItems.value.length / props.items.length) * 100)
})

const filteredItems = computed(() => {
  if (activeFilter.value === 'all') return props.items
  return props.items.filter(item => item.status === activeFilter.value)
})

function getStatusText(status: string): string {
  const statusMap: Record<string, string> = {
    'served': t('customer.tracking.served'),
    'preparing': t('customer.tracking.preparing'),
    'pending': t('customer.tracking.pending')
  }
  return statusMap[status] || status
}

function getItemProgress(status: string): number {
  if (status === 'pending') return 33
  if (status === 'preparing') return 66
  return 100
}

function formatTime(time: string | null): string {
  return time || '--:--'
}

function refreshStatus() {
  emit('refresh')
}
</script>

<style scoped>
/* ===== MODAL OVERLAY ===== */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.7);
  backdrop-filter: blur(12px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

/* ===== MODAL CONTAINER - GLASSMORPHISM ===== */
.modal-container {
  background: linear-gradient(135deg, rgba(26, 26, 46, 0.95), rgba(22, 33, 62, 0.95));
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  width: 100%;
  max-width: 700px;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 
    0 25px 50px rgba(0, 0, 0, 0.5),
    0 8px 32px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.05) inset;
}

/* ===== HEADER ===== */
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: rgba(255, 255, 255, 0.02);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-icon {
  font-size: 28px;
}

.modal-title {
  font-size: 20px;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
}

.modal-subtitle {
  font-size: 12px;
  color: #94a3b8;
  margin: 4px 0 0 0;
}

.close-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #ffffff;
  font-size: 18px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: rotate(90deg);
}

/* ===== STATUS SUMMARY ===== */
.status-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 20px 24px;
  background: rgba(255, 255, 255, 0.01);
}

.status-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  transition: all 0.3s;
}

.status-card:hover {
  background: rgba(255, 255, 255, 0.05);
  transform: translateY(-2px);
}

.status-card.served {
  box-shadow: 0 0 20px rgba(74, 222, 128, 0.1);
}

.status-card.preparing {
  box-shadow: 0 0 20px rgba(96, 165, 250, 0.1);
}

.status-card.pending {
  box-shadow: 0 0 20px rgba(251, 146, 36, 0.1);
}

.status-icon {
  position: relative;
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.status-card.served .status-icon {
  background: rgba(74, 222, 128, 0.1);
  border: 1px solid rgba(74, 222, 128, 0.3);
}

.status-card.preparing .status-icon {
  background: rgba(96, 165, 250, 0.1);
  border: 1px solid rgba(96, 165, 250, 0.3);
}

.status-card.pending .status-icon {
  background: rgba(251, 146, 36, 0.1);
  border: 1px solid rgba(251, 146, 36, 0.3);
}

.glow-effect {
  position: absolute;
  inset: -2px;
  border-radius: 12px;
  opacity: 0;
  transition: opacity 0.3s;
}

.status-card.served:hover .glow-effect {
  opacity: 1;
  background: radial-gradient(circle, rgba(74, 222, 128, 0.3), transparent);
}

.status-card.preparing:hover .glow-effect {
  opacity: 1;
  background: radial-gradient(circle, rgba(96, 165, 250, 0.3), transparent);
}

.status-card.pending:hover .glow-effect {
  opacity: 1;
  background: radial-gradient(circle, rgba(251, 146, 36, 0.3), transparent);
}

.status-info {
  flex: 1;
}

.status-count {
  font-size: 24px;
  font-weight: 800;
  line-height: 1.2;
}

.status-card.served .status-count {
  color: #4ade80;
  text-shadow: 0 0 15px rgba(74, 222, 128, 0.3);
}

.status-card.preparing .status-count {
  color: #60a5fa;
  text-shadow: 0 0 15px rgba(96, 165, 250, 0.3);
}

.status-card.pending .status-count {
  color: #fb923c;
  text-shadow: 0 0 15px rgba(251, 146, 36, 0.3);
}

.status-label {
  font-size: 11px;
  color: #94a3b8;
  font-weight: 600;
}

/* ===== PROGRESS OVERVIEW ===== */
.progress-overview {
  padding: 0 24px 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.overview-item {
  display: flex;
  align-items: center;
  gap: 12px;
}

.overview-label {
  width: 90px;
  font-size: 11px;
  color: #94a3b8;
  font-weight: 600;
}

.overview-bar {
  flex: 1;
  height: 6px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 3px;
  overflow: hidden;
}

.overview-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.5s ease;
}

.overview-fill.served { background: #4ade80; }
.overview-fill.preparing { background: #60a5fa; }
.overview-fill.pending { background: #fb923c; }

.overview-value {
  width: 36px;
  text-align: right;
  font-size: 11px;
  font-weight: 700;
  color: #ffffff;
}

/* ===== FILTER TABS ===== */
.filter-tabs {
  display: flex;
  gap: 8px;
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.01);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  overflow-x: auto;
}

.tab-btn {
  padding: 6px 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 20px;
  color: #94a3b8;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.08);
  color: white;
}

.tab-btn.active {
  background: linear-gradient(135deg, #fb923c, #f97316);
  border-color: #fb923c;
  color: white;
  box-shadow: 0 4px 12px rgba(251, 146, 36, 0.2);
}

/* ===== ITEMS LIST ===== */
.items-list {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
}

.item-card {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 16px;
  margin-bottom: 16px;
  border-left: 4px solid rgba(255, 255, 255, 0.2);
  transition: all 0.3s;
}

.item-card:hover {
  background: rgba(255, 255, 255, 0.04);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
}

.item-card.status-served {
  border-left-color: #4ade80;
  box-shadow: 0 0 15px rgba(74, 222, 128, 0.05);
}

.item-card.status-preparing {
  border-left-color: #60a5fa;
  box-shadow: 0 0 15px rgba(96, 165, 250, 0.05);
}

.item-card.status-pending {
  border-left-color: #fb923c;
  box-shadow: 0 0 15px rgba(251, 146, 36, 0.05);
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 14px;
}

.item-name {
  font-size: 14px;
  font-weight: 700;
  color: white;
  margin: 0 0 6px 0;
}

.item-meta {
  display: flex;
  gap: 16px;
  font-size: 11px;
  color: #94a3b8;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: inline-block;
}

.badge-served {
  background: rgba(74, 222, 128, 0.15);
  color: #4ade80;
  border: 1px solid rgba(74, 222, 128, 0.3);
}

.badge-preparing {
  background: rgba(96, 165, 250, 0.15);
  color: #60a5fa;
  border: 1px solid rgba(96, 165, 250, 0.3);
}

.badge-pending {
  background: rgba(251, 146, 36, 0.15);
  color: #fb923c;
  border: 1px solid rgba(251, 146, 36, 0.3);
}

/* ===== PROGRESS BAR WITH SHINE ===== */
.progress-container {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.progress-bar {
  flex: 1;
  height: 8px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 4px;
  overflow: hidden;
  position: relative;
}

.progress-fill {
  height: 100%;
  border-radius: 4px;
  position: relative;
  overflow: hidden;
  transition: width 0.5s ease;
}

.progress-fill::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.25), transparent);
  animation: shine 2.5s infinite;
}

@keyframes shine {
  0% { left: -100%; }
  100% { left: 100%; }
}

.progress-served {
  background: linear-gradient(90deg, #4ade80, #22c55e);
  box-shadow: 0 0 8px rgba(74, 222, 128, 0.3);
}

.progress-preparing {
  background: linear-gradient(90deg, #60a5fa, #3b82f6);
  box-shadow: 0 0 8px rgba(96, 165, 250, 0.3);
}

.progress-pending {
  background: linear-gradient(90deg, #fb923c, #f97316);
  box-shadow: 0 0 8px rgba(251, 146, 36, 0.3);
}

.progress-percent {
  width: 36px;
  text-align: right;
  font-size: 12px;
  font-weight: 700;
  color: white;
}

/* ===== TIMELINE ===== */
.timeline {
  display: flex;
  justify-content: space-between;
  position: relative;
  padding-top: 6px;
}

.timeline::before {
  content: '';
  position: absolute;
  top: 14px;
  left: 0;
  right: 0;
  height: 2px;
  background: rgba(255, 255, 255, 0.08);
  z-index: 0;
}

.timeline-step {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 1;
}

.step-dot {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #1b1c2a;
  border: 2px solid rgba(255, 255, 255, 0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 6px;
  transition: all 0.3s;
}

.step-dot.completed {
  background: linear-gradient(135deg, #4ade80, #22c55e);
  border-color: #4ade80;
  box-shadow: 0 0 10px rgba(74, 222, 128, 0.4);
}

.dot-icon {
  font-size: 10px;
  color: #1b1c2a;
  font-weight: bold;
}

.step-dot:not(.completed) .dot-icon {
  display: none;
}

.step-info {
  text-align: center;
}

.step-label {
  font-size: 10px;
  color: #94a3b8;
  font-weight: 600;
  margin-bottom: 2px;
}

.step-time {
  font-size: 11px;
  font-weight: 700;
  color: white;
}

/* ===== EMPTY STATE ===== */
.empty-state {
  text-align: center;
  padding: 50px 20px;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 12px;
  opacity: 0.6;
}

.empty-text {
  color: white;
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 6px;
}

.empty-subtext {
  color: #94a3b8;
  font-size: 12px;
}

/* ===== FOOTER ===== */
.modal-footer {
  display: flex;
  gap: 12px;
  padding: 16px 24px;
  background: rgba(0, 0, 0, 0.15);
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.btn-refresh,
.btn-close {
  flex: 1;
  padding: 12px 20px;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-refresh {
  background: linear-gradient(135deg, #fb923c, #f97316);
  color: white;
  box-shadow: 0 4px 12px rgba(251, 146, 36, 0.2);
}

.btn-refresh:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(251, 146, 36, 0.35);
}

.btn-close {
  background: rgba(255, 255, 255, 0.08);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.btn-close:hover {
  background: rgba(255, 255, 255, 0.18);
}

/* ===== SCROLLBAR ===== */
.items-list::-webkit-scrollbar {
  width: 6px;
}

.items-list::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.02);
}

.items-list::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #fb923c, #f97316);
  border-radius: 3px;
}

/* ===== ANIMATIONS ===== */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
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
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
