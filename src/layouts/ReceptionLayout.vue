<template>
  <div class="flex h-screen overflow-hidden bg-gray-50">
    <!-- Sidebar -->
    <aside class="w-64 border-r bg-white flex flex-col shrink-0 shadow-sm">
      <div class="p-5 border-b">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-red-600 flex items-center justify-center text-white font-black text-lg shadow-md">
            🐂
          </div>
          <div>
            <h1 class="text-base font-black text-gray-900 tracking-tight">NGƯU CÁT</h1>
            <p class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Thu Ngân POS</p>
          </div>
        </div>
      </div>
      <nav class="flex-1 px-4 space-y-2 py-6 overflow-y-auto">
        <div class="text-[11px] font-extrabold text-gray-400 uppercase tracking-wider mb-2">Hoạt động</div>
        <RouterLink to="/reception/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          Bảng điều khiển
        </RouterLink>
        <RouterLink to="/reception/floors" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="9" x2="9" y1="3" y2="21"/><line x1="15" x2="15" y1="3" y2="21"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="3" x2="21" y1="15" y2="15"/></svg>
          Sơ đồ bàn
        </RouterLink>
        <RouterLink to="/reception/order" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/></svg>
          Chọn món
        </RouterLink>
        <RouterLink to="/reception/close-shift" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          Tổng Kết Ca
        </RouterLink>
      </nav>
      <div class="p-4 border-t relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <!-- Dropdown Menu -->
        <div v-if="isDropdownOpen" class="absolute bottom-full left-4 right-4 mb-2 bg-white border rounded-xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut" class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
            <span>Đăng xuất</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div @click="isDropdownOpen = !isDropdownOpen" class="flex items-center gap-3 px-3 py-2 rounded-xl bg-gray-100 cursor-pointer select-none">
          <div class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-xs font-bold text-gray-700">TN</div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-bold text-gray-900 truncate">Thu Ngân 01</div>
          </div>
        </div>
      </div>
    </aside>
    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b bg-white flex items-center justify-between px-6 shrink-0 shadow-sm z-10">
        <div class="font-bold text-xl text-gray-800" id="reception-header-title">{{ headerTitle }}</div>
        <div class="flex items-center gap-2">
           <span class="text-sm font-semibold text-gray-500">Chi nhánh 1</span>
        </div>
      </header>
      <section class="flex-1 overflow-auto bg-gray-50 p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
const route = useRoute()
const { signOut } = useAuth()
const isDropdownOpen = ref(false)

const headerTitle = computed(() => {
  if (route.path.includes('/reception/dashboard')) return 'Bảng điều khiển'
  if (route.path.includes('/reception/close-shift')) return 'Tổng Kết Ca'
  if (route.path.includes('/reception/floors')) return 'Sơ đồ bàn & Đặt chỗ'
  if (route.path.includes('/reception/order')) return 'Chọn món & Gọi đồ'
  if (route.path.includes('/reception/checkout')) return 'Thanh toán hóa đơn'
  return 'Bảng điều khiển'
})

async function handleSignOut() {
  await signOut()
  router.push({ name: 'login' })
}
</script>
