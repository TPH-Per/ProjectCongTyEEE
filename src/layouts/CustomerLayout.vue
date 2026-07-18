<!-- File: src/layouts/CustomerLayout.vue -->
<template>
  <div class="w-full h-screen bg-[#3D2817] text-white flex flex-col font-sans overflow-hidden select-none">
    
    <!-- Active Session Layout -->
    <template v-if="session">
      <!-- Header Bar (60px Height) -->
      <header class="h-[60px] bg-[#1a110a] border-b border-[#2d1e12] flex items-center justify-between px-6 shrink-0 z-30 shadow-md z-40">
        
        <!-- Logo Branding -->
        <div class="flex items-center gap-3 cursor-pointer shrink-0" @click="goToView('CustomerMenu')">
          <div class="w-9 h-9 rounded-full bg-rose-600/10 border border-rose-500/20 flex items-center justify-center text-lg text-rose-500 shadow-md">
            🌸
          </div>
          <h1 class="text-lg font-black text-amber-500 uppercase tracking-widest font-serif">NGƯU CÁT</h1>
        </div>

        <!-- Search Bar (syncs directly with store) -->
        <div class="relative w-64 md:w-80 mx-4 hidden sm:block">
          <input type="text" 
                 v-model="store.searchQuery" 
                 placeholder="Tìm kiếm..." 
                 class="w-full bg-[#2a1b10] border border-[#442c19] focus:border-[#E8772E]/50 rounded-lg py-1.5 pl-9 pr-4 text-xs text-gray-200 placeholder-gray-550 focus:outline-none transition-colors" />
          <svg xmlns="http://www.w3.org/2000/svg" class="absolute left-3 top-2.5 w-3.5 h-3.5 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
        </div>

        <!-- Header Actions & Table Number -->
        <div class="flex items-center gap-4">
          <!-- Active Table Code -->
          <div class="bg-[#2a1b10] border border-[#442c19] text-[#E8772E] px-3.5 py-1.5 rounded-lg text-sm font-black tracking-wider select-none shrink-0">
            {{ session.tableNumber }}
          </div>

          <!-- Icons Actions Row -->
          <div class="flex items-center gap-2">
            <!-- 1. Cart Button with badge -->
            <button @click="goToView('CustomerCart')"
                    :class="[
                      'w-9 h-9 rounded-lg flex items-center justify-center border relative transition-all active:scale-90',
                      isCurrentRoute('CustomerCart') 
                        ? 'bg-[#E8772E] border-[#E8772E] text-black' 
                        : 'bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white'
                    ]"
                    title="Giỏ hàng">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="9" cy="21" r="1"></circle>
                <circle cx="20" cy="21" r="1"></circle>
                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
              </svg>
              <!-- Badge -->
              <span v-if="cartItemCount > 0" 
                    class="absolute -top-1.5 -right-1.5 min-w-4 h-4 bg-rose-500 text-white text-[9px] font-black rounded-full flex items-center justify-center px-1 border border-[#1a110a]">
                {{ cartItemCount }}
              </span>
            </button>

            <!-- NEW: Order Tracking button with badge -->
            <button @click="showOrderTracking = true"
                    :class="[
                      'w-9 h-9 rounded-lg flex items-center justify-center border relative transition-all active:scale-90',
                      showOrderTracking 
                        ? 'bg-[#E8772E] border-[#E8772E] text-black' 
                        : 'bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white'
                    ]"
                    title="Theo dõi món ăn">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
                <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
              </svg>
              <!-- Badge -->
              <span v-if="pendingItemsCount > 0" 
                    class="absolute -top-1.5 -right-1.5 min-w-4 h-4 bg-amber-500 text-black text-[9px] font-black rounded-full flex items-center justify-center px-1 border border-[#1a110a] animate-pulse">
                {{ pendingItemsCount }}
              </span>
            </button>

            <!-- 2. Service Requests button with badge -->
            <button @click="goToView('ServiceRequest')"
                    :class="[
                      'w-9 h-9 rounded-lg flex items-center justify-center border relative transition-all active:scale-90',
                      isCurrentRoute('ServiceRequest')
                        ? 'bg-[#E8772E] border-[#E8772E] text-black'
                        : 'bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white'
                    ]"
                    title="Gọi phục vụ">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
              </svg>
              <!-- Alert Dot badge -->
              <span v-if="activeServiceRequests.length > 0" 
                    class="absolute -top-1.5 -right-1.5 min-w-4 h-4 bg-amber-500 text-black text-[9px] font-black rounded-full flex items-center justify-center px-1 border border-[#1a110a] animate-pulse">
                {{ activeServiceRequests.length }}
              </span>
            </button>

            <!-- 3. Profile / Order History button -->
            <button @click="goToView('OrderHistory')"
                    :class="[
                      'w-9 h-9 rounded-lg flex items-center justify-center border transition-all active:scale-90',
                      isCurrentRoute('OrderHistory')
                        ? 'bg-[#E8772E] border-[#E8772E] text-black'
                        : 'bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white'
                    ]"
                    title="Lịch sử gọi món">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
              </svg>
            </button>

            <!-- 4. Exit Table button -->
            <button @click="handleExitTable"
                    class="w-9 h-9 rounded-lg flex items-center justify-center border border-rose-950 bg-rose-950/30 text-rose-400 hover:bg-rose-600 hover:text-white transition-all active:scale-90"
                    title="Thoát bàn">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                <polyline points="16 17 21 12 16 7"></polyline>
                <line x1="21" y1="12" x2="9" y2="12"></line>
              </svg>
            </button>
          </div>

          <!-- Language flags selector -->
          <div class="flex items-center gap-1.5 bg-[#2a1b10] border border-[#442c19] px-2 py-1 rounded-lg shrink-0">
            <button @click="setLanguage('vi')" 
                    :class="['text-sm transition-all grayscale active:scale-90', store.currentLanguage === 'vi' ? 'grayscale-0 scale-110 font-bold' : 'opacity-60']" 
                    title="Tiếng Việt">🇻🇳</button>
            <button @click="setLanguage('en')" 
                    :class="['text-sm transition-all grayscale active:scale-90', store.currentLanguage === 'en' ? 'grayscale-0 scale-110 font-bold' : 'opacity-60']" 
                    title="English">🇬🇧</button>
            <button @click="setLanguage('ja')" 
                    :class="['text-sm transition-all grayscale active:scale-90', store.currentLanguage === 'ja' ? 'grayscale-0 scale-110 font-bold' : 'opacity-60']" 
                    title="日本語">🇯🇵</button>
          </div>
        </div>
      </header>

      <!-- Main Layout Body (Router view spans full height below header) -->
      <div class="flex-1 flex overflow-hidden">
        <main class="flex-1 bg-[#3D2817] overflow-hidden relative">
          <RouterView />
        </main>
      </div>

      <!-- Quick Toast Notifications overlay -->
      <transition-group name="fade" tag="div" class="fixed bottom-6 right-6 z-50 flex flex-col gap-3 pointer-events-none">
        <div v-for="notif in notifications" :key="notif.id"
             :class="[
               'px-5 py-3.5 rounded-xl shadow-2xl flex items-center gap-3 border pointer-events-auto backdrop-blur-md',
               notif.type === 'success' ? 'bg-emerald-950/80 border-emerald-500/30 text-emerald-300' :
               notif.type === 'error' ? 'bg-rose-950/80 border-rose-500/30 text-rose-300' :
               notif.type === 'warning' ? 'bg-amber-950/80 border-amber-500/30 text-amber-300' :
               'bg-[#1a1a1a]/80 border-gray-700 text-gray-300'
             ]">
          <span v-if="notif.type === 'success'" class="text-emerald-500">✓</span>
          <span v-else-if="notif.type === 'error'" class="text-rose-500">✗</span>
          <span v-else-if="notif.type === 'warning'" class="text-amber-500">⚠</span>
          <p class="text-sm font-semibold">{{ notif.message }}</p>
        </div>
      </transition-group>

      <!-- Order Tracking Modal -->
      <OrderTrackingModal 
        v-if="showOrderTracking"
        :items="trackingItems"
        :table-number="session?.tableNumber || ''"
        @close="showOrderTracking = false"
        @refresh="store.loadOrderHistory()"
      />
    </template>

    <!-- Inactive Session Layout (Authentication Flow) -->
    <template v-else>
      <div class="flex-1 bg-[#090909] flex flex-col overflow-hidden justify-center items-center">
        <RouterView />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import Swal from 'sweetalert2';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';
import { isSupabaseConfigured } from '@/lib/supabase';
import OrderTrackingModal from '@/components/customer/OrderTrackingModal.vue';

const store = useCustomerStore();
const router = useRouter();
const route = useRoute();
const { restoreSessionFromLocalStorage, clearSession } = useCustomerSession();

const session = computed(() => store.session);
const cartItemCount = computed(() => store.cartItemCount);
const activeServiceRequests = computed(() => store.activeServiceRequests);
const notifications = computed(() => store.notifications);

const showOrderTracking = ref(false);

const trackingItems = computed(() => {
  const list: any[] = [];
  for (const order of store.orders) {
    let trackingStatus: 'pending' | 'preparing' | 'served' = 'pending';
    if (order.status === 'cooking') {
      trackingStatus = 'preparing';
    } else if (order.status === 'served' || order.status === 'completed') {
      trackingStatus = 'served';
    }
    
    const date = new Date(order.createdAt);
    const orderedTime = date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    
    let servedTime: string | null = null;
    if (trackingStatus === 'served') {
      const servedDate = new Date(date.getTime() + 10 * 60000);
      servedTime = servedDate.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    }

    for (const item of order.items) {
      list.push({
        id: `${order.id}-${item.menuItemId}`,
        name: item.name,
        quantity: item.quantity,
        status: trackingStatus,
        orderedTime,
        servedTime
      });
    }
  }
  return list;
});

const pendingItemsCount = computed(() => {
  return trackingItems.value.filter(item => item.status !== 'served').length;
});

// Restore session synchronously before child components mount
restoreSessionFromLocalStorage();

onMounted(() => {
  // If not authenticated or no session, redirect to the customer home page (passcode screen).
  // Khi chưa cấu hình Supabase (offline mode), cho phép truy cập trực tiếp
  // trang cart để test UI tĩnh.
  const allowDirectAccess = !isSupabaseConfigured && route.name === 'CustomerCart';
  if (!store.session && route.name !== 'CustomerHome' && route.path.startsWith('/customer') && !allowDirectAccess) {
    router.push({ name: 'CustomerHome' });
  } else if (store.session) {
    store.loadOrderHistory();
  }
});

// Watch session state to redirect home on session termination
watch(session, (newVal) => {
  if (!newVal && route.path.startsWith('/customer') && route.name !== 'CustomerHome' && route.name !== 'SessionEnd') {
    router.push({ name: 'CustomerHome' });
  } else if (newVal) {
    store.loadOrderHistory();
  }
});

function isCurrentRoute(routeName: string): boolean {
  return route.name === routeName;
}

function goToView(routeName: string) {
  router.push({ name: routeName });
}

function setLanguage(lang: 'vi' | 'en' | 'ja') {
  store.currentLanguage = lang;
  store.addNotification(`Đã chuyển sang ngôn ngữ: ${lang === 'vi' ? 'Tiếng Việt' : lang === 'en' ? 'English' : '日本語'}`, 'info');
}

async function handleExitTable() {
  const result = await Swal.fire({
    title: 'Xác nhận thoát bàn?',
    text: 'Bạn có chắc chắn muốn thoát phiên làm việc của bàn này không?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#E8772E',
    cancelButtonColor: '#d33',
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy'
  });

  if (result.isConfirmed) {
    clearSession();
    Swal.fire({
      title: 'Đã thoát bàn!',
      text: 'Đã giải phóng phiên làm việc thành công.',
      icon: 'success',
      timer: 1500,
      showConfirmButton: false
    });
  }
}
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-enter-from {
  opacity: 0;
  transform: translateY(20px) scale(0.95);
}
.fade-leave-to {
  opacity: 0;
  transform: translateY(-20px) scale(0.95);
}
</style>
