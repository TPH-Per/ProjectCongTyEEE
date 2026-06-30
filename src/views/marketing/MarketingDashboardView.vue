<template>
  <div class="marketing-dashboard">
    <h1 class="text-2xl font-bold mb-4">{{ $t('marketing.dashboard') }}</h1>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white p-6 rounded-2xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="text-[hsl(var(--muted-foreground))] font-semibold text-sm">Active Campaigns</h3>
        <p class="text-3xl font-extrabold mt-2">12</p>
      </div>
      <div class="bg-white p-6 rounded-2xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="text-[hsl(var(--muted-foreground))] font-semibold text-sm">Total Reach</h3>
        <p class="text-3xl font-extrabold mt-2">45.2K</p>
      </div>
      <div class="bg-white p-6 rounded-2xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="text-[hsl(var(--muted-foreground))] font-semibold text-sm">Conversion Rate</h3>
        <p class="text-3xl font-extrabold mt-2">4.8%</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>
