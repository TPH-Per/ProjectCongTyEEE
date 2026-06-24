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
            <p class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Reception POS</p>
          </div>
        </div>
      </div>
      <nav class="flex-1 px-4 space-y-2 py-6 overflow-y-auto">
        <div class="text-[11px] font-extrabold text-gray-400 uppercase tracking-wider mb-2">Hoạt động</div>
        <RouterLink to="/reception/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          Dashboard
        </RouterLink>
        <RouterLink to="/reception/close-shift" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100" active-class="bg-red-50 text-red-600 hover:bg-red-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          Tổng Kết Ca
        </RouterLink>
      </nav>
      <div class="p-4 border-t">
        <div class="flex items-center gap-3 px-3 py-2 rounded-xl bg-gray-100">
          <div class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-xs font-bold text-gray-700">TN</div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-bold text-gray-900 truncate">Thu Ngân 01</div>
          </div>
        </div>
      </div>
    </aside>
    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b bg-white flex items-center justify-between px-6 shrink-0 shadow-sm z-10">
        <div class="font-bold text-xl text-gray-800" id="reception-header-title">Bảng điều khiển</div>
        <div class="flex items-center gap-3">
           <span class="text-sm font-semibold text-gray-500">Chi nhánh 1</span>
           <button class="px-3 py-2 rounded-lg text-sm font-semibold text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors" @click="handleSignOut">
             Đăng xuất
           </button>
        </div>
      </header>
      <section class="flex-1 overflow-auto bg-gray-50 p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { RouterView, RouterLink, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const $router = useRouter()
const { signOut, profile } = useAuth()

async function handleSignOut() {
  await signOut()
  await $router.push({ name: 'login' })
}

void profile
</script>
