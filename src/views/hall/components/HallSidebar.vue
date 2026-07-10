<template>
  <aside class="hall-sidebar">
    <div class="sidebar-header">
      <div class="logo">🏛️</div>
      <h2 class="branch-name">NGƯU CÁT</h2>
    </div>

    <nav class="sidebar-nav">
      <button 
        v-for="item in menuItems"
        :key="item.id"
        :class="['nav-item', { active: currentView === item.id }]"
        @click="$emit('navigate', item.id)"
      >
        <span class="nav-icon">{{ item.icon }}</span>
        <span class="nav-label">{{ item.label }}</span>
        <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
      </button>
    </nav>

    <div class="sidebar-footer">
      <div class="user-info">
        <div class="user-avatar">👤</div>
        <div class="user-details">
          <div class="user-name">Hall Staff</div>
          <div class="user-role">Nhân viên sảnh</div>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup lang="ts">
defineProps<{
  currentView: string
}>()

defineEmits<{
  navigate: [view: string]
}>()

const menuItems = [
  { id: 'calendar', label: 'Lịch đặt bàn', icon: '📅', badge: null },
  { id: 'detail', label: 'Chi tiết đặt', icon: '📋', badge: 'WIP' },
  { id: 'floor-plan', label: 'Sơ đồ bàn', icon: '⊞', badge: null },
  { id: 'order-menu', label: 'Chọn món', icon: '🍽️', badge: null }
]
</script>

<style scoped>
.hall-sidebar {
  width: 240px;
  background: #1a1a2e;
  color: white;
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.sidebar-header {
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid rgba(255,255,255,0.1);
}

.logo {
  font-size: 32px;
}

.branch-name {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
}

.sidebar-nav {
  flex: 1;
  padding: 20px 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  background: transparent;
  border: none;
  color: rgba(255,255,255,0.7);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
  width: 100%;
}

.nav-item:hover {
  background: rgba(255,255,255,0.1);
  color: white;
}

.nav-item.active {
  background: #f97316;
  color: white;
  font-weight: 600;
}

.nav-icon {
  font-size: 20px;
}

.nav-label {
  flex: 1;
}

.nav-badge {
  background: #ef4444;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 10px;
  font-weight: 700;
}

.sidebar-footer {
  padding: 20px;
  border-top: 1px solid rgba(255,255,255,0.1);
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
  background: #f97316;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.user-name {
  font-weight: 600;
  font-size: 14px;
}

.user-role {
  font-size: 12px;
  color: rgba(255,255,255,0.6);
}
</style>
