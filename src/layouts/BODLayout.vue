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
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">BOD Portal</div>

        <RouterLink to="/bod/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/bod/dashboard' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          <span>{{ $t('bod.dashboard') }}</span>
        </RouterLink>

        <RouterLink to="/bod/approvals" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/bod/approvals' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>
          <span>{{ $t('bod.approvals') }}</span>
        </RouterLink>
      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <!-- Dropdown Menu -->
        <div v-if="isDropdownOpen" class="absolute bottom-full left-3 right-3 mb-2 bg-white border border-[hsl(var(--border))] rounded-2xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut" class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
            <span>Logout</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div @click="isDropdownOpen = !isDropdownOpen" class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-[hsl(var(--muted))] cursor-pointer select-none">
          <img :src="stickerUrl" alt="Avatar" class="w-10 h-10 object-contain drop-shadow-sm bg-white/10 rounded-full" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-[hsl(var(--foreground))] truncate">
              {{ profile?.full_name || 'BOD Member' }}
            </div>
            <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">
              Board of Directors
            </div>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0 z-40">
        <div class="flex items-center gap-3">
          <button @click="isMobileMenuOpen = true" class="lg:hidden p-2 rounded-xl hover:bg-[hsl(var(--muted))] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>
          </button>
        </div>
        <div class="flex items-center gap-3">
          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] transition-colors" aria-label="notifications">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            <span class="absolute top-1 right-1 w-2 h-2 rounded-full bg-[hsl(var(--primary))]" />
          </button>
          <!-- Single LanguageSwitcher + avatar pair -->
          <div class="flex items-center gap-2 ml-2 border-l pl-4 border-[hsl(var(--border))]">
            <LanguageSwitcher />
            <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
          </div>
        </div>
      </header>
      <section class="flex-1 overflow-auto p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { ref } from 'vue'
import { RouterView, RouterLink, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import { useI18n } from 'vue-i18n'

const $router = useRouter()
const { signOut, profile } = useAuth()
const { stickerUrl } = useUserSticker()
const { t } = useI18n()

const isMobileMenuOpen = ref(false)
const isDropdownOpen = ref(false)

async function handleSignOut() {
  await signOut()
  await $router.push({ name: 'login' })
}
</script>
