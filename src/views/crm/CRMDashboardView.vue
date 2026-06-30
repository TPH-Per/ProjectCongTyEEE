<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-4 text-[hsl(var(--foreground))]">{{ $t('crm.dashboard') }}</h1>
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-[hsl(var(--border))]">
      <p class="text-[hsl(var(--muted-foreground))]">Welcome to the CRM Dashboard overview.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>
