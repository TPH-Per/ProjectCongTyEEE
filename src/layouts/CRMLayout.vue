<template>
  <div class="flex h-screen overflow-hidden bg-gray-50 flex-col md:flex-row">
    <!-- Mobile Header -->
    <header class="md:hidden h-14 bg-white border-b border-gray-200 flex items-center justify-between px-4 shrink-0 shadow-sm z-30">
      <div class="flex items-center gap-2">
        <TextLogo size="sm" />
      </div>
      <div class="flex items-center gap-3">
        <button class="relative p-2 rounded-xl text-gray-500 hover:bg-gray-100 transition-colors">
          <BellIcon class="w-5 h-5" />
          <span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-red-500" />
        </button>
        <img :src="stickerUrl" alt="Avatar" class="w-8 h-8 rounded-full border border-gray-200 object-contain bg-gray-100" />
      </div>
    </header>

    <!-- Desktop Sidebar -->
    <aside class="hidden md:flex flex-col w-64 border-r border-gray-200 bg-white shrink-0 shadow-sm z-40">
      <div class="p-5 border-b border-gray-100">
        <TextLogo size="md" />
        <div class="mt-2 text-[10px] font-bold uppercase tracking-widest text-gray-400">
          {{ i18n.t('role.crm_manager') }}
        </div>
      </div>

      <!-- Nav -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <div class="text-[10px] font-extrabold text-gray-400 uppercase tracking-widest px-3 mb-2">
          {{ i18n.t('crm.dashboard') }}
        </div>

        <RouterLink
          v-for="item in navItems" :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all text-sm font-semibold"
          :class="isRouteActive(item.to)
            ? 'bg-orange-50 text-[#E8772E] border border-orange-100 shadow-sm'
            : 'text-gray-500 hover:text-gray-900 hover:bg-gray-50'"
        >
          <component :is="item.icon" class="w-[18px] h-[18px] shrink-0" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <!-- User Card -->
      <div class="p-4 border-t border-gray-100 relative">
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>
        <div v-if="isDropdownOpen"
          class="absolute bottom-full left-4 right-4 mb-2 bg-white border border-gray-200 rounded-xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut"
            class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <LogOutIcon class="w-[18px] h-[18px]" />
            <span>{{ i18n.t('layout.logout') }}</span>
          </button>
        </div>

        <div @click="isDropdownOpen = !isDropdownOpen"
          class="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-gray-50 border border-gray-100 cursor-pointer select-none hover:bg-gray-100 transition-colors">
          <img :src="stickerUrl" alt="Avatar" class="w-9 h-9 object-contain rounded-full bg-white border border-gray-200" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-bold text-gray-900 truncate">{{ profile?.full_name || 'CRM Manager' }}</div>
            <div class="text-[10px] text-gray-500 font-semibold">{{ roleLabel }}</div>
          </div>
          <ChevronUpIcon class="w-4 h-4 text-gray-400 shrink-0" />
        </div>
      </div>
    </aside>

    <!-- Main content -->
    <main class="flex-1 flex flex-col min-w-0 overflow-hidden relative">
      <!-- Desktop Header -->
      <header class="hidden md:flex h-16 border-b border-gray-200 bg-white items-center justify-between px-6 shrink-0 z-30 shadow-sm">
        <div class="font-bold text-xl text-gray-800">{{ headerTitle }}</div>
        <div class="flex items-center gap-4">
          <div v-if="branchLabel" class="flex items-center gap-2 px-3 py-1.5 bg-gray-100 border border-gray-200 rounded-xl text-sm">
            <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span class="font-bold text-gray-700">{{ branchLabel }}</span>
          </div>
          <div class="flex items-center gap-2 border-l pl-4 border-gray-200">
            <button class="relative p-2 rounded-xl text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors">
              <BellIcon class="w-5 h-5" />
              <span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-red-500" />
            </button>
            <LanguageSwitcher />
          </div>
        </div>
      </header>

      <section class="flex-1 overflow-auto bg-gray-50 p-4 md:p-6 pb-20 md:pb-6">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </section>
      
      <!-- Mobile Bottom Navigation -->
      <nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 flex items-center justify-around pb-safe z-40 shadow-[0_-2px_10px_rgba(0,0,0,0.05)]">
        <RouterLink
          v-for="item in navItems" :key="item.to"
          :to="item.to"
          class="flex flex-col items-center gap-1 flex-1 py-3 transition-colors"
          :class="isRouteActive(item.to) ? 'text-[#E8772E]' : 'text-gray-400 hover:text-gray-600'"
        >
          <component :is="item.icon" class="w-6 h-6 shrink-0" :class="isRouteActive(item.to) ? 'stroke-2' : 'stroke-[1.5]'" />
          <span class="text-[10px] font-bold">{{ item.label }}</span>
        </RouterLink>
        
        <button @click="handleSignOut" class="flex flex-col items-center gap-1 flex-1 py-3 text-gray-400 hover:text-red-500 transition-colors">
          <LogOutIcon class="w-6 h-6 shrink-0 stroke-[1.5]" />
          <span class="text-[10px] font-bold">{{ i18n.t('layout.logout') }}</span>
        </button>
      </nav>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import {
  LayoutDashboard as LayoutDashboardIcon, 
  Users as UserGroupIcon, 
  MessageSquare as ChatBubbleLeftRightIcon,
  LogOut as LogOutIcon, 
  Bell as BellIcon, 
  ChevronUp as ChevronUpIcon
} from 'lucide-vue-next'
import { useI18nStore } from '@/stores/i18n'

const $route = useRoute()
const $router = useRouter()
const { signOut, profile, role } = useAuth()
const { stickerUrl } = useUserSticker()
const i18n = useI18nStore()

const isDropdownOpen = ref(false)

const navItems = computed(() => [
  { to: '/crm/dashboard', label: i18n.t('crm.dashboard'), icon: LayoutDashboardIcon },
  { to: '/crm/serving-tables', label: i18n.t('crm.servingTables'), icon: UserGroupIcon },
  { to: '/crm/feedback', label: i18n.t('crm.recentFeedback'), icon: ChatBubbleLeftRightIcon },
])

const isRouteActive = (path: string) => {
  return $route.path === path || ($route.path.startsWith(path) && path !== '/crm/dashboard')
}

const headerTitle = computed(() => {
  const currentItem = navItems.value.find(item => isRouteActive(item.to))
  return currentItem ? currentItem.label : i18n.t('crm.dashboard')
})

const ROLE_LABELS: Record<string, string> = {
  crm: 'Chăm sóc khách hàng',
  crm_manager: 'Quản lý CRM',
  admin: 'Quản trị viên',
  manager: 'Quản lý',
}

const roleLabel = computed(() => ROLE_LABELS[role.value ?? ''] ?? 'CRM')

const branchLabel = computed(() => {
  if (role.value === 'superadmin' || role.value === 'admin') {
    return 'Toàn hệ thống'
  }
  const bid = profile.value?.branch_id
  if (!bid) return ''
  return `Branch #${bid.slice(0, 6)}`
})

async function handleSignOut() {
  await signOut()
  await $router.push({ name: 'login' })
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.pb-safe {
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
</style>

