<template>
  <div class="flex h-screen overflow-hidden bg-[hsl(var(--background))]">
    <!-- Mobile backdrop -->
    <div v-if="isMobileMenuOpen" class="fixed inset-0 bg-black/50 z-40 lg:hidden" @click="isMobileMenuOpen = false"></div>

    <!-- Sidebar – Luxury dark theme -->
    <aside :class="[
      'flex flex-col shrink-0 w-64 fixed inset-y-0 left-0 z-50 transform transition-transform duration-300 lg:relative lg:translate-x-0',
      isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full',
      'bg-gradient-to-b from-[#0f0f0f] to-[#1a1208] border-r border-[#b8972233]'
    ]">
      <!-- Logo -->
      <div class="p-5 border-b border-[#b8972233]">
        <TextLogo size="md" color="gold" />
        <div class="mt-2 text-[10px] font-bold uppercase tracking-widest text-[#b89722]/60">
          {{ i18n.t('accounting.roleLabel') }}
        </div>
      </div>

      <!-- Nav -->
      <nav class="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        <div class="text-[9px] font-extrabold text-[#b89722]/50 uppercase tracking-widest px-3 mb-2">
          {{ i18n.t('accounting.nav.section') }}
        </div>

        <RouterLink
          v-for="item in navItems" :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all text-sm font-semibold"
          :class="$route.path.startsWith(item.to)
            ? 'bg-[#b89722]/20 text-[#e8c84a] border border-[#b89722]/30 shadow-[0_0_12px_rgba(184,151,34,0.15)]'
            : 'text-[#b89722]/70 hover:text-[#e8c84a] hover:bg-[#b89722]/10'"
        >
          <component :is="item.icon" class="w-4 h-4 shrink-0" />
          <span>{{ i18n.t(item.label) }}</span>
          <span v-if="item.badge" class="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-red-500/20 text-red-400">
            {{ item.badge }}
          </span>
        </RouterLink>
      </nav>

      <!-- User Card -->
      <div class="p-3 border-t border-[#b89722]/20 relative">
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <div v-if="isDropdownOpen"
          class="absolute bottom-full left-3 right-3 mb-2 bg-[#1a1208] border border-[#b89722]/30 rounded-xl shadow-2xl py-1.5 z-50">
          <button @click="handleSignOut"
            class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-400 hover:bg-red-900/20 transition-colors">
            <LogOutIcon class="w-4 h-4" />
            <span>{{ i18n.t('layout.logout') }}</span>
          </button>
        </div>

        <div @click="isDropdownOpen = !isDropdownOpen"
          class="flex items-center gap-2.5 px-3 py-2 rounded-xl bg-[#b89722]/10 border border-[#b89722]/20 cursor-pointer select-none">
          <img :src="stickerUrl" alt="Avatar" class="w-10 h-10 object-contain rounded-full bg-[#b89722]/10 border border-[#b89722]/20" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-[#e8c84a] truncate">{{ profile?.full_name || 'Kế toán' }}</div>
            <div class="text-[10px] text-[#b89722]/70 font-semibold">{{ roleLabel }}</div>
          </div>
          <ChevronUpIcon class="w-3.5 h-3.5 text-[#b89722]/50 shrink-0" />
        </div>
      </div>
    </aside>

    <!-- Main content -->
    <main class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0 z-40">
        <div class="flex items-center gap-3">
          <button @click="isMobileMenuOpen = true" class="lg:hidden p-2 -ml-2 rounded-xl hover:bg-[hsl(var(--muted))]">
            <MenuIcon class="w-5 h-5" />
          </button>
          <div v-if="branchLabel" class="flex items-center gap-2 px-3 py-1.5 bg-[hsl(var(--muted))] border border-[hsl(var(--border))] rounded-xl text-sm">
            <div class="w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
            <span class="font-extrabold text-[hsl(var(--foreground))]">{{ branchLabel }}</span>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <button class="relative p-2 rounded-xl hover:bg-[hsl(var(--muted))] transition-colors" aria-label="notifications">
            <BellIcon class="w-4 h-4" />
            <span class="absolute top-1 right-1 w-2 h-2 rounded-full bg-amber-500" />
          </button>
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
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import {
  LayoutDashboardIcon, ReceiptIcon, BuildingIcon, TrendingUpIcon,
  LogOutIcon, BellIcon, MenuIcon, ChevronUpIcon, FileTextIcon
} from 'lucide-vue-next'
import { useI18nStore } from '@/stores/i18n'

const $route = useRoute()
const $router = useRouter()
const { signOut, profile, role } = useAuth()
const { stickerUrl } = useUserSticker()
const i18n = useI18nStore()

const isMobileMenuOpen = ref(false)
const isDropdownOpen = ref(false)

const navItems: { to: string, label: string, icon: any, badge?: string }[] = [
  { to: '/accounting/dashboard', label: 'accounting.nav.dashboard', icon: LayoutDashboardIcon },
  { to: '/accounting/cashflow',  label: 'accounting.nav.cashflow',  icon: ReceiptIcon },
  { to: '/accounting/ap',        label: 'accounting.nav.ap',        icon: BuildingIcon },
  { to: '/accounting/pl-report', label: 'accounting.nav.plReport',  icon: TrendingUpIcon },
  { to: '/accounting/invoices',  label: 'accounting.nav.invoices',  icon: FileTextIcon },
]

const ROLE_LABELS: Record<string, string> = {
  accounting: 'Kế toán chi nhánh',
  accounting_manager: 'Kế toán trưởng',
  admin: 'Quản trị viên',
  manager: 'Quản lý',
}

const roleLabel = computed(() => ROLE_LABELS[role.value ?? ''] ?? 'Kế toán')

const branchLabel = computed(() => {
  if (role.value === 'accounting_manager' || role.value === 'superadmin' || role.value === 'admin') {
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
