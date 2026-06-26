<template>
  <div class="flex h-screen overflow-hidden bg-[hsl(var(--background))]">
    <!-- Sidebar -->
    <aside class="w-60 border-r border-[hsl(var(--border))] bg-white flex flex-col shrink-0">
      <div class="p-5 border-b border-[hsl(var(--border))]">
        <div class="flex items-center gap-2.5">
          <TextLogo size="md" />
        </div>
      </div>

      <nav class="flex-1 px-3 space-y-1 py-4 overflow-y-auto">
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">
          {{ t('nav.section_ops') }}
        </div>
        <RouterLink
          to="/"
          :class="[
            'flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm',
            route.path === '/'
              ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border border-[hsl(var(--primary))]/30'
              : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))] font-semibold border border-transparent'
          ]"
        >
          <LayoutDashboard :size="16" />
          <span>{{ t('nav.timeline') }}</span>
        </RouterLink>
        <RouterLink
          to="/list"
          :class="[
            'flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm',
            route.path === '/list'
              ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border border-[hsl(var(--primary))]/30'
              : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))] font-semibold border border-transparent'
          ]"
        >
          <List :size="16" />
          <span>{{ t('nav.list') }}</span>
        </RouterLink>
        <RouterLink
          to="/floor-plan"
          :class="[
            'flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm',
            route.path === '/floor-plan'
              ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border border-[hsl(var(--primary))]/30'
              : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))] font-semibold border border-transparent'
          ]"
        >
          <Map :size="16" />
          <span>{{ t('nav.floor_plan') }}</span>
        </RouterLink>

        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1 mt-5">
          {{ t('nav.section_service') }}
        </div>
        <RouterLink
          to="/order/SF_00001729"
          :class="[
            'flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm',
            route.path.startsWith('/order')
              ? 'bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border border-[hsl(var(--primary))]/30'
              : 'text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))] font-semibold border border-transparent'
          ]"
        >
          <Utensils :size="16" />
          <span>{{ t('nav.order') }}</span>
        </RouterLink>

        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1 mt-5">
          {{ t('nav.section_system') }}
        </div>
        <button class="w-full flex items-center gap-3 px-3 py-2.5 text-[hsl(var(--foreground))] rounded-2xl hover:bg-[hsl(var(--muted))] transition-all text-sm font-semibold text-left">
          <Settings :size="16" />
          <span>{{ t('nav.settings') }}</span>
        </button>
      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] space-y-1">
        <div class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-[hsl(var(--muted))]">
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-[hsl(var(--foreground))] truncate">{{ t('header.profile_name') }}</div>
            <div class="text-[10px] text-[hsl(var(--muted-foreground))] font-semibold">{{ t('header.profile_role') }}</div>
          </div>
          <button class="p-1 rounded-lg hover:bg-white text-[hsl(var(--muted-foreground))]">
            <LogOut :size="13" />
          </button>
        </div>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 px-3 py-1.5 bg-[hsl(var(--muted))] border border-[hsl(var(--border))] rounded-2xl text-sm">
            <div class="w-2 h-2 rounded-full bg-[hsl(var(--primary))] animate-pulse" />
            <span class="font-extrabold text-[hsl(var(--foreground))]">{{ t('header.branch_label') }} {{ t('branch') }}</span>
            <ChevronDown :size="14" class="text-[hsl(var(--muted-foreground))]" />
          </div>
        </div>

        <div class="flex items-center gap-2">
          <div class="relative">
            <Search :size="14" class="absolute left-3 top-1/2 -translate-y-1/2 text-[hsl(var(--muted-foreground))]" />
            <input
              type="text"
              :placeholder="t('header.search_placeholder')"
              class="kawaii-input pl-9 pr-3 py-1.5 text-sm w-56"
            />
          </div>

          <!-- Language switcher -->
          <div ref="langWrap" class="relative">
            <button
              @click="openLang = !openLang"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl border-2 border-[hsl(var(--border))] bg-white text-sm font-extrabold text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))] transition-colors"
            >
              <span class="text-base">{{ i18n.currentMeta.flag }}</span>
              <span>{{ i18n.locale.toUpperCase() }}</span>
              <ChevronDown :size="14" class="text-[hsl(var(--muted-foreground))]" />
            </button>
            <div
              v-if="openLang"
              class="absolute right-0 mt-2 w-40 bg-white rounded-2xl border border-[hsl(var(--border))] shadow-lg z-50 overflow-hidden"
            >
              <button
                v-for="lang in i18n.availableLocales"
                :key="lang"
                @click="setLang(lang)"
                :class="[
                  'w-full flex items-center gap-2 px-3 py-2.5 text-sm transition-colors',
                  i18n.locale === lang
                    ? 'bg-[hsl(var(--primary))]/10 text-[hsl(var(--primary))] font-extrabold'
                    : 'hover:bg-[hsl(var(--muted))] font-semibold text-[hsl(var(--foreground))]'
                ]"
              >
                <span class="text-base">{{ LANGUAGE_META[lang].flag }}</span>
                <span>{{ LANGUAGE_META[lang].nativeLabel }}</span>
                <Check v-if="i18n.locale === lang" :size="14" class="ml-auto" />
              </button>
            </div>
          </div>

          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] text-[hsl(var(--foreground))] transition-colors">
            <Bell :size="16" />
            <span class="absolute top-1 right-1 w-2 h-2 rounded-full bg-[hsl(var(--primary))]" />
          </button>
          <div class="w-px h-6 bg-[hsl(var(--border))]" />
          <div class="flex items-center gap-2">
            <ChevronDown :size="14" class="text-[hsl(var(--muted-foreground))]" />
          </div>
        </div>
        <!-- Header User Avatar -->
        <div class="flex items-center gap-2 ml-4">
          <LanguageSwitcher />
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        </div>
      </header>

      <!-- Scrollable Content -->
      <section class="flex-1 overflow-auto p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, RouterView, RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import {
  LayoutDashboard, List, Map, Utensils, Settings, LogOut, ChevronDown,
  Bell, Search, Check,
} from 'lucide-vue-next'
import { useI18nStore, LANGUAGE_META } from '@/stores/i18n'
import type { AppLocale } from '@/locales'

const { stickerUrl } = useUserSticker()
const route = useRoute()
const { t } = useI18n()
const i18n = useI18nStore()

const openLang = ref(false)
const langWrap = ref<HTMLElement | null>(null)

function setLang(lang: AppLocale) {
  i18n.setLocale(lang)
  openLang.value = false
}

function onDocClick(e: MouseEvent) {
  if (!openLang.value) return
  const target = e.target as Node | null
  if (langWrap.value && target && !langWrap.value.contains(target)) {
    openLang.value = false
  }
}

onMounted(() => document.addEventListener('mousedown', onDocClick))
onBeforeUnmount(() => document.removeEventListener('mousedown', onDocClick))
</script>
