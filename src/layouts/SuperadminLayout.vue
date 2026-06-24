<template>
  <div class="flex h-screen bg-gray-50 overflow-hidden font-sans text-gray-800">
    <!-- Sidebar -->
    <aside class="w-64 bg-white kawaii-shadow flex flex-col z-20">
      <div class="h-16 flex items-center justify-center border-b border-gray-100 kawaii-gradient">
        <h1 class="text-xl font-bold text-white tracking-wide">Ngưu Cát Portal</h1>
      </div>
      <nav class="flex-1 overflow-y-auto py-4">
        <ul class="space-y-1 px-3">
          <li v-for="item in menuItems" :key="item.name">
            <router-link
              :to="item.path"
              class="flex items-center px-4 py-3 rounded-xl transition-all duration-200 text-gray-600 hover:bg-rose-50 hover:text-[#FF7B89]"
              active-class="bg-rose-100 text-[#FF7B89] font-medium"
            >
              <component :is="item.icon" class="w-5 h-5 mr-3" />
              <span>{{ item.name }}</span>
            </router-link>
          </li>
        </ul>
      </nav>
      <div class="p-4 border-t border-gray-100">
        <button class="flex items-center text-sm text-gray-500 hover:text-red-500 transition-colors w-full px-4 py-2" @click="handleSignOut">
          <LogOutIcon class="w-4 h-4 mr-2" />
          Đăng xuất
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col min-w-0 z-10 relative">
      <!-- Header -->
      <header class="h-16 bg-white/80 backdrop-blur-md kawaii-shadow flex items-center justify-between px-6 sticky top-0">
        <div class="flex items-center">
          <h2 class="text-lg font-semibold text-gray-700">{{ currentRouteName }}</h2>
        </div>
        <div class="flex items-center space-x-4">
          <button class="text-gray-400 hover:text-[#FF7B89] transition-colors relative">
            <BellIcon class="w-6 h-6" />
            <span class="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
          <div class="flex items-center space-x-2 cursor-pointer">
            <div class="w-8 h-8 rounded-full bg-rose-200 flex items-center justify-center text-[#FF7B89] font-bold">
              SA
            </div>
            <span class="text-sm font-medium hidden md:block">Superadmin</span>
            <ChevronDownIcon class="w-4 h-4 text-gray-400" />
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 overflow-y-auto p-6">
        <div class="max-w-7xl mx-auto">
          <router-view v-slot="{ Component }">
            <transition name="fade" mode="out-in">
              <component :is="Component" />
            </transition>
          </router-view>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  LayoutDashboardIcon,
  StoreIcon,
  PuzzleIcon,
  SettingsIcon,
  BellIcon,
  ChevronDownIcon,
  LogOutIcon
} from 'lucide-vue-next'
import { useAuth } from '@/composables/useAuth'

const route = useRoute()
const router = useRouter()
const { signOut, profile } = useAuth()

const menuItems = [
  { name: 'Tổng quan', path: '/superadmin/dashboard', icon: LayoutDashboardIcon },
  { name: 'Quản lý chi nhánh', path: '/superadmin/brands', icon: StoreIcon },
  { name: 'Tích hợp', path: '/superadmin/integrations', icon: PuzzleIcon },
  { name: 'Cài đặt hệ thống', path: '/superadmin/settings', icon: SettingsIcon },
]

const currentRouteName = computed(() => {
  const current = menuItems.find(item => route.path.includes(item.path))
  return current ? current.name : 'Quản lý'
})

async function handleSignOut() {
  await signOut()
  await router.push({ name: 'login' })
}

void profile
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
