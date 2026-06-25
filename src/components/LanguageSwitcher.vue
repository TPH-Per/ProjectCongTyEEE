<template>
  <div class="relative inline-block text-left">
    <button
      type="button"
      @click="isOpen = !isOpen"
      class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white border border-gray-200 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
    >
      <span class="text-lg leading-none">{{ currentFlag }}</span>
    </button>

    <!-- Dropdown menu -->
    <div
      v-if="isOpen"
      class="origin-top-right absolute right-0 mt-2 w-48 rounded-xl shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50 overflow-hidden border border-gray-100"
      @click.away="isOpen = false"
    >
      <div class="py-1">
        <button
          v-for="locale in availableLocales"
          :key="locale"
          @click="selectLocale(locale)"
          class="w-full text-left px-4 py-2 text-sm flex items-center gap-3 hover:bg-gray-50 transition-colors"
          :class="currentLocale === locale ? 'bg-blue-50/50 text-blue-700 font-medium' : 'text-gray-700'"
        >
          <span class="text-xl leading-none">{{ getFlag(locale) }}</span>
          {{ getNativeLabel(locale) }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useI18nStore, LANGUAGE_META } from '@/stores/i18n'
import type { AppLocale } from '@/locales'

const i18nStore = useI18nStore()
const isOpen = ref(false)

const currentLocale = computed(() => i18nStore.locale)
const currentFlag = computed(() => i18nStore.currentMeta.flag)
const availableLocales = computed(() => i18nStore.availableLocales)

function getFlag(code: AppLocale) {
  return LANGUAGE_META[code]?.flag || '🌐'
}

function getNativeLabel(code: AppLocale) {
  return LANGUAGE_META[code]?.nativeLabel || code
}

function selectLocale(code: AppLocale) {
  i18nStore.setLocale(code)
  isOpen.value = false
}

// Click away handling
const closeDropdown = (e: MouseEvent) => {
  const target = e.target as HTMLElement
  if (!target.closest('.relative')) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', closeDropdown)
})

onUnmounted(() => {
  document.removeEventListener('click', closeDropdown)
})
</script>
