<!-- File: src/components/reception/SidebarNavigation.vue -->
<template>
  <!-- Overlay khi sidebar mở -->
  <Transition name="fade">
    <div 
      v-if="isOpen" 
      class="sidebar-overlay"
      @click="closeSidebar"
    ></div>
  </Transition>

  <!-- Sidebar -->
  <Transition name="slide-left">
    <aside v-if="isOpen" class="sidebar-navigation">
      <!-- Header -->
      <div class="sidebar-header">
        <div class="logo-section">
          <span class="logo-icon">📊</span>
          <span class="logo-text">NGƯU CÁT</span>
        </div>
        <button class="close-btn" @click="closeSidebar">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>

      <!-- Menu Items -->
      <nav class="sidebar-menu">
        <button
          v-for="item in menuItems"
          :key="item.id"
          :class="['menu-item', { active: activeItem === item.id }]"
          @click="handleMenuClick(item)"
        >
          <span class="menu-icon">{{ item.icon }}</span>
          <span class="menu-label">{{ t('reception.sidebar.' + item.id) }}</span>
          <span v-if="item.badge" class="menu-badge">{{ item.badge }}</span>
        </button>
      </nav>
 
      <!-- Footer -->
      <div class="sidebar-footer">
        <div class="user-info">
          <div class="user-avatar">🧑‍💼</div>
          <div class="user-details">
            <div class="user-name">{{ profile?.full_name || 'Thu Ngân' }}</div>
            <div class="user-role">{{ t('reception.cashier_receptionist') }}</div>
          </div>
        </div>
      </div>
    </aside>
  </Transition>
</template>
 
<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useLanguageStore } from '@/stores/useLanguageStore'
 
const router = useRouter()
const route = useRoute()
const { profile } = useAuth()
const { t } = useLanguageStore()

// Props
const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

// Menu items
const menuItems = ref([
  { 
    id: 'revenue', 
    label: 'DT Tổng thể', 
    icon: '📈', 
    route: '/reception/revenue-overview',
    badge: null
  },
  { 
    id: 'shift', 
    label: 'Giao ca', 
    icon: '⏱️', 
    route: '/reception/shift-handover',
    badge: null
  },
  { 
    id: 'inventory', 
    label: 'Tồn kho tức thời', 
    icon: '📦', 
    route: '/reception/inventory',
    badge: null
  },
  { 
    id: 'process', 
    label: 'Xử lý món', 
    icon: '🍳', 
    route: '/reception/process-items',
    badge: null
  }
])

// Active item based on current route
const activeItem = computed(() => {
  const currentPath = route.path
  if (currentPath.includes('revenue-overview')) return 'revenue'
  if (currentPath.includes('shift-handover')) return 'shift'
  if (currentPath.includes('inventory')) return 'inventory'
  if (currentPath.includes('process-items')) return 'process'
  return 'revenue'
})

// Methods
function handleMenuClick(item: any) {
  closeSidebar()
  router.push(item.route)
}

function closeSidebar() {
  isOpen.value = false
}
</script>

<style scoped>
/* Overlay */
.sidebar-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 998;
}

/* Sidebar */
.sidebar-navigation {
  position: fixed;
  top: 0;
  left: 0;
  width: 280px;
  height: 100vh;
  background: white;
  box-shadow: 4px 0 24px rgba(0, 0, 0, 0.15);
  z-index: 999;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Header */
.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e0e0e0;
  background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-icon {
  font-size: 28px;
}

.logo-text {
  font-size: 18px;
  font-weight: 800;
  color: #E8772E;
  letter-spacing: 0.5px;
}

.close-btn {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: rgba(232, 119, 46, 0.1);
  border: none;
  color: #E8772E;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-btn:hover {
  background: rgba(232, 119, 46, 0.2);
  transform: rotate(90deg);
}

/* Menu */
.sidebar-menu {
  flex: 1;
  padding: 16px 12px;
  overflow-y: auto;
}

.menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  background: transparent;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
  margin-bottom: 6px;
  position: relative;
}

.menu-item:hover {
  background: #f5f5f5;
  transform: translateX(4px);
}

.menu-item.active {
  background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
  border-left: 4px solid #E8772E;
}

.menu-item.active .menu-label {
  color: #E8772E;
  font-weight: 700;
}

.menu-icon {
  font-size: 22px;
  width: 32px;
  text-align: center;
  flex-shrink: 0;
}

.menu-label {
  flex: 1;
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.menu-badge {
  background: #F44336;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
}

/* Footer */
.sidebar-footer {
  padding: 16px 20px;
  border-top: 1px solid #e0e0e0;
  background: #f9f9f9;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #E8772E 0%, #F5A623 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: white;
}

.user-details {
  flex: 1;
}

.user-name {
  font-size: 13px;
  font-weight: 700;
  color: #333;
}

.user-role {
  font-size: 11px;
  color: #666;
  margin-top: 2px;
}

/* Animations */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-left-enter-active,
.slide-left-leave-active {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-left-enter-from,
.slide-left-leave-to {
  transform: translateX(-100%);
}
</style>
