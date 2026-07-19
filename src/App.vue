<template>
  <div id="app" :lang="currentLang">
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { setApplicationLanguage } from '@/helpers/i18n'

const store = useLanguageStore()
const currentLang = computed(() => store.lang)

onMounted(() => {
  const savedLang = localStorage.getItem('app_lang') as 'vi' | 'en' | 'ja'
  if (savedLang && ['vi', 'en', 'ja'].includes(savedLang)) {
    setApplicationLanguage(savedLang)
  }
})
</script>
