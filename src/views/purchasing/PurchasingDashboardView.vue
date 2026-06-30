<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tracking-tight">{{ $t('purchasing.dashboard') }}</h1>
      <p class="text-muted-foreground">{{ $t('purchasing.dashboard_desc', 'Overview of your purchasing activities.') }}</p>
    </div>
    
    <div class="grid gap-4 md:grid-cols-3">
      <div class="p-6 bg-white rounded-xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="font-semibold text-sm text-[hsl(var(--muted-foreground))]">{{ $t('purchasing.pending_orders', 'Pending Orders') }}</h3>
        <p class="text-2xl font-bold mt-2">12</p>
      </div>
      <div class="p-6 bg-white rounded-xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="font-semibold text-sm text-[hsl(var(--muted-foreground))]">{{ $t('purchasing.approved_orders', 'Approved Orders') }}</h3>
        <p class="text-2xl font-bold mt-2">45</p>
      </div>
      <div class="p-6 bg-white rounded-xl border border-[hsl(var(--border))] shadow-sm">
        <h3 class="font-semibold text-sm text-[hsl(var(--muted-foreground))]">{{ $t('purchasing.rejected_orders', 'Rejected Orders') }}</h3>
        <p class="text-2xl font-bold mt-2">3</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
// Scaffolding for Purchasing Dashboard
</script>
