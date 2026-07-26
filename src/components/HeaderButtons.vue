<!-- HeaderButtons.vue -->
<template>
  <div class="header-actions">
    <!-- Primary: Navigation -->
    <router-link to="/kitchen/kds" class="nav-tab" :class="{ active: isKDS }">
      KDS
    </router-link>
    <router-link to="/kitchen/expo" class="nav-tab" :class="{ active: isExpo }">
      Expo
      <span v-if="qcCount > 0" class="badge">{{ qcCount }}</span>
    </router-link>
    <router-link to="/kitchen/inventory" class="nav-tab" :class="{ active: isInventory }">
      Kho
    </router-link>
    
    <div class="separator"></div>
    
    <!-- Secondary: Actions chính -->
    <button 
      class="action-btn" 
      :class="{ 'has-badge': pendingGrillRequests > 0 }" 
      @click="openGrill"
      data-tooltip="Gửi yêu cầu thay vỉ/than"
    >
      🔥 Vỉ/Than
      <span v-if="pendingGrillRequests > 0" class="badge">{{ pendingGrillRequests }}</span>
    </button>
    
    <button 
      class="action-btn" 
      :class="{ 'has-badge': prepTasksCount > 0 }" 
      @click="openPrep"
      data-tooltip="Xem danh sách sơ chế nguyên liệu"
    >
      🔪 Sơ Chế
      <span v-if="prepTasksCount > 0" class="badge">{{ prepTasksCount }}</span>
    </button>
    
    <button 
      class="action-btn danger" 
      @click="open86d"
      data-tooltip="Xem danh mục món đã hết hàng"
    >
      🛑 86'd
    </button>
    
    <div class="separator"></div>
    
    <!-- More menu -->
    <button 
      class="action-btn more" 
      @click="showMore = !showMore"
      data-tooltip="Thêm chức năng khác"
    >
      •••
    </button>
    
    <div v-if="showMore" class="dropdown-menu">
      <button @click="triggerHACCP">🛡️ HACCP</button>
      <button @click="triggerHandover">🤝 Bàn Giao Ca</button>
      <button @click="triggerRequest">📦 Yêu Cầu Kho <span v-if="pendingRequisitionsCount > 0" class="ml-1 px-1.5 py-0.5 bg-[#F44336] text-white text-[10px] rounded-full font-bold">{{ pendingRequisitionsCount }}</span></button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useKitchenStore } from '@/stores/kitchen';

const router = useRouter();
const route = useRoute();
const kitchenStore = useKitchenStore();

const showMore = ref(false);

const isKDS = computed(() => route.path.includes('/kitchen/kds'));
const isExpo = computed(() => route.path.includes('/kitchen/expo'));
const isInventory = computed(() => route.path.includes('/kitchen/inventory'));

const qcCount = computed(() => kitchenStore.qcQueue.length);
const pendingRequisitionsCount = computed(() => kitchenStore.requisitions.filter(r => r.status === 'pending').length);
const pendingGrillRequests = computed(() => kitchenStore.grillRequests.filter(r => r.status === 'pending').length);
const prepTasksCount = computed(() => kitchenStore.prepList.filter(t => !t.completed).length);

const openGrill = () => {
  showMore.value = false;
  if (!isKDS.value) {
    router.push('/kitchen/kds').then(() => {
      setTimeout(() => {
        kitchenStore.showGrillRequestModal = true;
      }, 100);
    });
  } else {
    kitchenStore.showGrillRequestModal = true;
  }
};

const openPrep = () => {
  showMore.value = false;
  if (!isKDS.value) {
    router.push('/kitchen/kds').then(() => {
      setTimeout(() => {
        kitchenStore.showPrepListModal = true;
      }, 100);
    });
  } else {
    kitchenStore.showPrepListModal = true;
  }
};

const open86d = () => {
  showMore.value = false;
  if (!isKDS.value) {
    router.push('/kitchen/kds').then(() => {
      setTimeout(() => {
        kitchenStore.show86dModal = true;
      }, 100);
    });
  } else {
    kitchenStore.show86dModal = true;
  }
};

const triggerHACCP = () => {
  showMore.value = false;
  if (!isKDS.value) {
    router.push('/kitchen/kds').then(() => {
      setTimeout(() => {
        kitchenStore.showHACCPModal = true;
      }, 100);
    });
  } else {
    kitchenStore.showHACCPModal = true;
  }
};

const triggerHandover = () => {
  showMore.value = false;
  router.push('/kitchen/handover');
};

const triggerRequest = () => {
  showMore.value = false;
  router.push('/kitchen/requisition');
};
</script>

<style scoped>
:root {
  --font-family: 'Inter', -apple-system, sans-serif;
  --text-xs: 11px;
  --text-sm: 13px;
  --text-base: 14px;
  --text-lg: 16px;
  --text-xl: 20px;
  --font-regular: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  
  --bg-primary: #1A1A1A;
  --bg-secondary: #2D2D2D;
  --bg-tertiary: #3D3D3D;
  --color-accent: #2196F3;
  --color-danger: #F44336;
  --color-warning: #FF9800;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 16px;
  position: relative;
  font-family: 'Inter', -apple-system, sans-serif;
}

.nav-tab {
  height: 40px;
  padding: 0 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #B0B0B0;
  text-decoration: none;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
  background: #3D3D3D;
}

.nav-tab:hover {
  color: white;
  background: #4A4A4A;
}

.nav-tab.active {
  background: #2196F3;
  color: white;
}

.action-btn {
  height: 40px;
  padding: 0 14px;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #E0E0E0;
  background: #3D3D3D;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  position: relative;
  transition: all 0.2s;
}

.action-btn:hover {
  filter: brightness(1.15);
  transform: translateY(-1px);
}

.action-btn.has-badge {
  background: #FF9800;
  color: white;
}

.action-btn.danger {
  background: #F44336;
  color: white;
}

.action-btn.more {
  background: #616161;
  padding: 0 16px;
  font-weight: bold;
  font-size: 16px;
  color: white;
}

.separator {
  width: 1px;
  height: 24px;
  background: #404040;
  margin: 0 4px;
}

.badge {
  position: absolute;
  top: -6px;
  right: -6px;
  background: #F44336;
  min-width: 18px;
  height: 18px;
  border-radius: 9px;
  font-size: 10px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #2D2D2D;
  color: white;
}

.dropdown-menu {
  position: absolute;
  top: 50px;
  right: 16px;
  background: #2D2D2D;
  border: 1px solid #404040;
  border-radius: 8px;
  padding: 8px;
  z-index: 1000;
  min-width: 180px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.6);
}

.dropdown-menu button {
  display: block;
  width: 100%;
  padding: 10px 12px;
  background: none;
  border: none;
  color: #E0E0E0;
  text-align: left;
  cursor: pointer;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  transition: background 0.15s;
}

.dropdown-menu button:hover {
  background: #3D3D3D;
  color: white;
}
</style>
