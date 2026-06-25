<template>
  <div class="w-full h-screen bg-[#111111] text-white flex flex-col font-sans overflow-hidden">
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useUserSticker } from '@/composables/useUserSticker'

const { stickerUrl } = useUserSticker()
</script>
