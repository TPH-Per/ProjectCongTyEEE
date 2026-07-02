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
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">Accounting</div>

        <RouterLink to="/accounting/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/accounting/dashboard' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <LayoutDashboardIcon class="w-4 h-4" />
          <span>{{ $t('accounting.dashboard') }}</span>
        </RouterLink>

        <RouterLink to="/accounting/tax-records" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/accounting/tax-records' ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30' : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]'">
          <FileTextIcon class="w-4 h-4" />
          <span>{{ $t('accounting.tax') }}</span>
        </RouterLink>

      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div v-if="isDropdownOpen" class="fixed inset-0 z-40" @click="isDropdownOpen = false"></div>

        <!-- Dropdown Menu -->
        <div v-if="isDropdownOpen" class="absolute bottom-full left-3 right-3 mb-2 bg-white border border-[hsl(var(--border))] rounded-2xl shadow-lg py-1.5 z-50">
          <button @click="handleSignOut" class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors">
            <LogOutIcon class="w-4 h-4" />
            <span>Sign Out</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div @click="isDropdownOpen = !isDropdownOpen" class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-[hsl(var(--muted))] cursor-pointer select-none">
          <img :src="stickerUrl" alt="Avatar" class="w-10 h-10 object-contain drop-shadow-sm bg-white/10 rounded-full" />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-[hsl(var(--foreground))] truncate">
              {{ profile?.full_name || 'Accountant' }}
            </div>
            <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">
              {{ roleLabel }}
            </div>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
           <button @click="isMobileMenuOpen = true" class="lg:hidden p-2 -ml-2 rounded-xl hover:bg-[hsl(var(--muted))]">
            <MenuIcon class="w-5 h-5" />
          </button>
          <div v-if="branchLabel" class="flex items-center gap-2 px-3 py-1.5 bg-[hsl(var(--muted))] border border-[hsl(var(--border))] rounded-2xl text-sm">
            <div class="w-2 h-2 rounded-full bg-[hsl(var(--primary))] animate-pulse" />
            <span class="font-extrabold text-[hsl(var(--foreground))]">{{ branchLabel }}</span>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] transition-colors" aria-label="notifications">
            <BellIcon class="w-4 h-4" />
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
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { LayoutDashboardIcon, FileTextIcon, LogOutIcon, BellIcon, MenuIcon } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'

const $route = useRoute()
const $router = useRouter()
const { signOut, profile, role } = useAuth()
const { stickerUrl } = useUserSticker()
const { t } = useI18n()

const isMobileMenuOpen = ref(false)
const isDropdownOpen = ref(false)

const ROLE_LABELS: Record<string, string> = {
  superadmin: 'Quản trị viên (Superadmin)',
  manager: 'Quản lý',
  reception: 'Thu ngân / Lễ tân',
  staff: 'Nhân viên',
  procurement_manager: 'Quản lý Mua hàng',
  procurement_staff: 'Nhân viên Mua hàng',
  accountant: 'Kế toán',
  customer: 'Khách hàng',
  crm_manager: 'Quản lý CRM',
  marketing: 'Marketing'
};

const roleLabel = computed(() => {
  const r = role.value ?? profile.value?.role
  if (!r) return 'Accountant'
  return ROLE_LABELS[r] ?? r
})

const branchLabel = computed(() => {
  const bid = profile.value?.branch_id
  if (!bid) return ''
  return `Branch ${bid.slice(0, 8)}`
})

async function handleSignOut() {
  await signOut()
  await $router.push({ name: 'login' })
}
</script>

