<template>
  <div class="w-full h-screen bg-[#111111] text-white flex flex-col font-sans overflow-hidden relative">
    <div class="absolute top-4 right-4 z-50">
      <LanguageSwitcher />
    </div>
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useUserSticker } from '@/composables/useUserSticker'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'

const { stickerUrl } = useUserSticker()
</script>
