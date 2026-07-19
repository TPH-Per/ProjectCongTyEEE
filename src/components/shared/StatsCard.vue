<!--
  StatsCard.vue
  -------------
  Reusable statistics card for dashboard-style summary grids.
  Consistent across Reservation Detail, Order, and Dashboard pages.

  Usage:
    <StatsCard label="TỔNG ĐẶT" :value="15" description="+3 so với hôm qua"
               icon="📅" iconBgClass="bg-blue-100" />
    <StatsCard label="ĐÃ XÁC NHẬN" :value="12"
               icon="✅" iconBgClass="bg-green-100"
               valueClass="text-3xl font-bold text-green-600" />
-->
<script setup lang="ts">
withDefaults(
  defineProps<{
    /** Label text (usually uppercase). */
    label: string
    /** Numeric or string value. */
    value: string | number
    /** Optional description below the value. */
    description?: string
    /** Emoji or icon string. */
    icon?: string
    /** Tailwind bg class for the icon container. */
    iconBgClass?: string
    /** Tailwind classes to override the default value styling. */
    valueClass?: string
  }>(),
  { description: '', icon: '📊', iconBgClass: 'bg-orange-100', valueClass: '' },
)
</script>

<template>
  <div
    class="bg-white rounded-xl p-6 border border-gray-200 shadow-sm hover:shadow-md transition-shadow"
  >
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm font-medium text-gray-600">{{ label }}</p>
        <p :class="['mt-1', valueClass || 'text-3xl font-bold text-gray-900']">
          {{ value }}
        </p>
        <p v-if="description" class="text-xs text-gray-500 mt-1">
          {{ description }}
        </p>
      </div>
      <div
        :class="[
          'w-12 h-12 rounded-xl flex items-center justify-center',
          iconBgClass,
        ]"
      >
        <span class="text-2xl">{{ icon }}</span>
      </div>
    </div>
  </div>
</template>
