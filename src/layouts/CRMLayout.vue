<template>
  <div class="flex h-screen w-full flex-col bg-gradient-to-br from-gray-900 to-black text-gray-100 pb-[env(safe-area-inset-bottom)]">
    <!-- Header -->
    <header class="flex h-14 items-center justify-between bg-gray-900/80 backdrop-blur border-b border-gray-800 px-4 shrink-0">
      <div class="flex items-center gap-2">
        <TextLogo />
      </div>
      <div class="flex items-center gap-4">
        <LanguageSwitcher />
        
        <div class="relative">
          <button
            class="flex h-8 w-8 items-center justify-center rounded-full bg-yellow-500/10 text-yellow-500 transition-colors hover:bg-yellow-500/20"
            @click="showProfileMenu = !showProfileMenu"
          >
            <span class="text-sm font-bold">{{ userInitials }}</span>
          </button>
          
          <div
            v-if="showProfileMenu"
            class="absolute right-0 top-full mt-2 w-48 rounded-xl border border-gray-700 bg-gray-900 py-1 shadow-lg z-50"
          >
            <div class="border-b border-gray-700 px-4 py-2">
              <p class="truncate text-sm font-semibold text-white">{{ session?.user?.email }}</p>
              <p class="text-xs text-gray-400 capitalize">{{ role }}</p>
            </div>
            <button
              class="w-full px-4 py-2 text-left text-sm text-red-400 hover:bg-gray-800"
              @click="handleLogout"
            >
              Sign out
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto overflow-x-hidden">
      <div class="mx-auto w-full max-w-md p-4 pb-24">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </div>
    </main>

    <!-- Bottom Navigation for CRM (Mobile First) -->
    <nav class="fixed bottom-0 left-0 right-0 z-40 bg-gray-900/90 backdrop-blur border-t border-gray-800 pb-[env(safe-area-inset-bottom)]">
      <div class="mx-auto flex h-16 max-w-md items-center justify-around px-2">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="flex flex-col items-center justify-center w-16 h-full gap-1 transition-colors"
          :class="[
            isCurrentRoute(item.path) 
              ? 'text-yellow-500' 
              : 'text-gray-500 hover:text-gray-300'
          ]"
        >
          <component :is="item.icon" class="h-6 w-6" :class="{ 'stroke-2': isCurrentRoute(item.path) }" />
          <span class="text-[10px] font-semibold" :class="{ 'font-bold': isCurrentRoute(item.path) }">
            {{ item.name }}
          </span>
        </router-link>
      </div>
    </nav>

    <!-- Click outside overlay for profile menu -->
    <div
      v-if="showProfileMenu"
      class="fixed inset-0 z-40"
      @click="showProfileMenu = false"
    ></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useI18n } from 'vue-i18n'
import TextLogo from '@/components/TextLogo.vue'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { 
  Home as HomeIcon, 
  Users as UserGroupIcon, 
  MessageSquare as ChatBubbleLeftRightIcon 
} from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()
const { session, role, signOut } = useAuth()
const { t } = useI18n()

const showProfileMenu = ref(false)

const userInitials = computed(() => {
  const email = session.value?.user?.email || ''
  return email.substring(0, 2).toUpperCase()
})

const navItems = computed(() => [
  { name: t('crm.dashboard', 'Dashboard'), path: '/crm', icon: HomeIcon },
  { name: t('crm.servingTables', 'Tables'), path: '/crm/serving-tables', icon: UserGroupIcon },
  { name: t('crm.recentFeedback', 'Feedback'), path: '/crm/feedback', icon: ChatBubbleLeftRightIcon },
])

function isCurrentRoute(path: string) {
  if (path === '/crm') {
    return route.path === '/crm' || route.path === '/crm/dashboard'
  }
  return route.path.startsWith(path)
}

async function handleLogout() {
  await signOut()
  router.push('/login')
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
</style>
