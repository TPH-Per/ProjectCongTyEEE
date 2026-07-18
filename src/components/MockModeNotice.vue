<template>
  <div
    v-if="isMockMode"
    class="fixed top-0 left-0 right-0 z-[9999] bg-gradient-to-r from-amber-500 to-red-500 text-white text-center font-bold text-xs py-1.5 px-4 animate-pulse select-none"
  >
    <span class="inline-flex items-center gap-1.5">
      <span>⚠️</span>
      <span>MOCK MODE — Không gọi API/Database</span>
    </span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { isSupabaseConfigured } from '@/lib/supabase'

const isMockMode = computed(() => !isSupabaseConfigured)
</script>