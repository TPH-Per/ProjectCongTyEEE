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
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">{{ $t('auto_he_thong', 'Hệ Thống') }}</div>

        <RouterLink to="/admin/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/dashboard' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          <span>{{ $t('auto_tong_quan_he_thong', 'Tổng Quan Hệ Thống') }}</span>
        </RouterLink>

        <RouterLink to="/admin/accounts" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/accounts' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <span>{{ $t('auto_quan_ly_tai_khoan', 'Quản Lý Tài Khoản') }}</span>
        </RouterLink>

        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1 mt-5">{{ $t('auto_cau_hinh_du_lieu', 'Cấu Hình Dữ Liệu') }}</div>

        <RouterLink to="/admin/menus" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/menus' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></svg>
          <span>{{ $t('auto_thuc_don_goi_menu', 'Thực Đơn & Gói Menu') }}</span>
        </RouterLink>

        <RouterLink to="/admin/floors" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/floors' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="9" x2="9" y1="21" y2="9"/></svg>
          <span>{{ $t('auto_so_do_ban', 'Sơ Đồ Bàn') }}</span>
        </RouterLink>

        <RouterLink to="/admin/kpi" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/kpi' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>
          <span>{{ $t('auto_cau_hinh_kpi_kgi', 'Cấu Hình KPI/KGI') }}</span>
        </RouterLink>
        
        <RouterLink to="/admin/audit" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/audit' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M7 7h.01"/><path d="M7 12h.01"/><path d="M7 17h.01"/><path d="M11 7h6"/><path d="M11 12h6"/><path d="M11 17h6"/></svg>
          <span>{{ $t('auto_nhat_ky_he_thong_audit', 'Nhật Ký Hệ Thống (Audit)') }}</span>
        </RouterLink>
      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <!-- Dropdown Menu -->
        <div v-if="isDropdownOpen" class="absolute bottom-full left-3 right-3 mb-2 bg-white border border-[hsl(var(--border))] rounded-2xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut" class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
            <span>{{ $t('auto_dang_xuat', 'Đăng xuất') }}</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div @click="isDropdownOpen = !isDropdownOpen" class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-gray-900 cursor-pointer select-none">
          <img :src="stickerUrl" alt="Avatar" class="w-10 h-10 object-contain drop-shadow-sm bg-white/10 rounded-full" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-white truncate">System Admin</div>
            <div class="text-[10px] text-gray-400 font-semibold">Super User</div>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
          <button @click="isMobileMenuOpen = true" class="lg:hidden mr-3 p-2 rounded-lg hover:bg-gray-100"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>
          <h2 class="text-lg font-bold text-gray-800">{{ $t('auto_quan_tri_he_thong', 'Quản Trị Hệ Thống') }}</h2>
        </div>
        <!-- Logos in Header -->
        <div class="flex items-center gap-4 ml-auto mr-4">
        </div>

        <div class="flex items-center gap-3">
          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
          </button>
          <button class="px-3 py-2 rounded-2xl text-sm font-semibold text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors" @click="handleSignOut">{{ $t('auto_dang_xuat', 'Đăng xuất') }}</button>
        
        <div class="flex items-center gap-2 ml-4 border-l pl-4 border-[hsl(var(--border))]">
          <LanguageSwitcher />
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        </div>
      </div>
      </header>
      <section class="flex-1 overflow-auto p-6 bg-gray-50/50">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
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
