<template>
  <div class="flex h-screen overflow-hidden bg-[hsl(var(--background))]">
    <!-- Sidebar -->
    <div v-if="isMobileMenuOpen" class="fixed inset-0 bg-black/50 z-40 lg:hidden" @click="isMobileMenuOpen = false"></div>
    <aside :class="['border-r border-[hsl(var(--border))] bg-white flex flex-col shrink-0 w-64 fixed inset-y-0 left-0 z-50 transform transition-transform duration-300 lg:relative lg:translate-x-0', isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full']">
      <div class="p-5 border-b border-[hsl(var(--border))]">
        <div class="flex items-center gap-2.5">
          <TextLogo size="md" />
        </div>
      </div>

      <nav class="flex-1 px-3 space-y-1 py-4 overflow-y-auto">
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">
          Báo cáo & Phân tích
        </div>

        <RouterLink to="/manager/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/dashboard' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          <span>Bảng Điều Khiển</span>
        </RouterLink>

        <RouterLink to="/manager/revenue" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/revenue' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" x2="12" y1="20" y2="10"/><line x1="18" x2="18" y1="20" y2="4"/><line x1="6" x2="6" y1="20" y2="16"/></svg>
          <span>Báo Cáo Doanh Thu</span>
        </RouterLink>

        <RouterLink to="/manager/cogs" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/cogs' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>
          <span>Giá Vốn (COGS)</span>
        </RouterLink>

        <RouterLink to="/manager/marketing" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/marketing' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
          <span>Phân Tích Marketing</span>
        </RouterLink>

        <RouterLink to="/manager/crm" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/crm' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <span>Khách Hàng (CRM)</span>
        </RouterLink>

        <RouterLink to="/manager/inventory" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/manager/inventory' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>
          <span>Tồn Kho</span>
        </RouterLink>

        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1 mt-5">
          Nghiệp vụ
        </div>

        <RouterLink to="/reception/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/><rect width="20" height="14" x="2" y="6" rx="2"/></svg>
          <span>Thu Ngân</span>
        </RouterLink>

        <RouterLink to="/staff/floor-plan" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="9" x2="9" y1="21" y2="9"/></svg>
          <span>Ứng dụng Phục vụ</span>
        </RouterLink>
      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <!-- Dropdown Menu -->
        <div v-if="isDropdownOpen" class="absolute bottom-full left-3 right-3 mb-2 bg-white border border-[hsl(var(--border))] rounded-2xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut" class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
            <span>Đăng xuất</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div @click="isDropdownOpen = !isDropdownOpen" class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-[hsl(var(--muted))] cursor-pointer select-none">
          <img :src="stickerUrl" alt="Avatar" class="w-10 h-10 object-contain drop-shadow-sm bg-white/10 rounded-full" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-[hsl(var(--foreground))] truncate">Quản Lý Ca</div>
            <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">Manager</div>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 px-3 py-1.5 bg-[hsl(var(--muted))] border border-[hsl(var(--border))] rounded-2xl text-sm">
            <div class="w-2 h-2 rounded-full bg-[hsl(var(--primary))] animate-pulse" />
            <span class="font-extrabold text-[hsl(var(--foreground))]">Chi nhánh: Ngưu Cát Q.1</span>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <div class="flex gap-2">
            <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border-2 border-[hsl(var(--border))] bg-white text-sm font-bold text-gray-700 hover:bg-[hsl(var(--muted))]">
              <span>🇻🇳</span> <span>VI</span>
            </button>
            <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[hsl(var(--border))] bg-white text-sm font-semibold text-gray-500 hover:bg-[hsl(var(--muted))]">
              <span>🇯🇵</span> <span>JA</span>
            </button>
          </div>
          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            <span class="absolute top-1 right-1 w-2 h-2 rounded-full bg-[hsl(var(--primary))]" />
          </button>
          <button class="px-3 py-2 rounded-2xl text-sm font-semibold text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors" @click="handleSignOut">
            Đăng xuất
          </button>
        </div>
      <LanguageSwitcher />
        <!-- Header User Avatar -->
        <div class="flex items-center gap-2 ml-4">
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        </div>
      </header>
      <section class="flex-1 overflow-auto p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { RouterView, RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'

const $route = useRoute()
const $router = useRouter()
const { signOut, profile } = useAuth()
const { stickerUrl } = useUserSticker()

const isMobileMenuOpen = ref(false)
const isDropdownOpen = ref(false)

async function handleSignOut() {
  await signOut()
  await $router.push({ name: 'login' })
}

void profile
</script>
