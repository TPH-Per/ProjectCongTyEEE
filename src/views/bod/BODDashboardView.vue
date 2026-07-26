<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('bod.dashboard') }}</h1>
        <p class="text-sm text-gray-500 mt-1">High-level enterprise metrics and KPIs.</p>
      </div>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="kawaii-card kawaii-shadow p-6">
        <h3 class="text-sm font-semibold text-gray-500 mb-2">Total Revenue (MTD)</h3>
        <p class="text-3xl font-bold text-gray-800">1,250,000,000<span class="text-base text-gray-500">đ</span></p>
      </div>
      <div class="kawaii-card kawaii-shadow p-6">
        <h3 class="text-sm font-semibold text-gray-500 mb-2">Active Branches</h3>
        <p class="text-3xl font-bold text-gray-800">12</p>
      </div>
      <div class="kawaii-card kawaii-shadow p-6">
        <h3 class="text-sm font-semibold text-gray-500 mb-2">Avg Customer Satisfaction</h3>
        <p class="text-3xl font-bold text-gray-800">4.8<span class="text-base text-gray-500">/5</span></p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>
