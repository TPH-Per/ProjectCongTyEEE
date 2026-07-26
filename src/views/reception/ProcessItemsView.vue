<!-- File: src/views/reception/ProcessItemsView.vue -->
<template>
  <div class="revenue-container">
    <!-- Hamburger Menu Button -->
    <HamburgerMenu 
      :is-active="showSidebar"
      @toggle="showSidebar = !showSidebar"
    />

    <!-- Sidebar Navigation -->
    <SidebarNavigation v-model="showSidebar" />

    <!-- Header -->
    <header class="revenue-header flex-shrink-0">
      <div class="header-left">
        <span class="logo-icon">📊</span>
        <h1 class="page-title">Xử lý món | <span class="branch-name">NGƯU CÁT</span></h1>
      </div>
      <div class="header-actions">
        <button class="btn btn-back" @click="goBack">
          <span>⬅️</span> Quay về
        </button>
      </div>
    </header>

    <div class="content-section flex-1 overflow-y-auto">
      <div class="status-card">
        <h2>🍳 Xử lý món</h2>
        <p>Tính năng theo dõi và cập nhật trạng thái chế biến món ăn đang được phát triển.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import HamburgerMenu from '@/components/reception/HamburgerMenu.vue'
import SidebarNavigation from '@/components/reception/SidebarNavigation.vue'

const router = useRouter()
const showSidebar = ref(false)
function goBack() { router.push('/reception/dashboard') }
</script>

<style scoped>
.revenue-container {
  height: 100vh;
  width: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  position: relative;
}

.revenue-header {
  background: white;
  padding: 12px 20px 12px 76px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e0e0e0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-icon {
  font-size: 24px;
}

.page-title {
  font-size: 18px;
  font-weight: 700;
  color: #333;
  margin: 0;
}

.branch-name {
  color: #E8772E;
}

.btn {
  padding: 8px 14px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-back {
  background: #ef4444;
  color: white;
}

.content-section {
  padding: 24px;
}

.status-card {
  background: white;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  text-align: center;
}

.status-card h2 {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 12px;
  color: #333;
}

.status-card p {
  color: #666;
}
</style>
<style>
.revenue-container .hamburger-btn {
  position: absolute;
  top: 12px;
  left: 20px;
  z-index: 997;
}
</style>
