<!--
  PageHeader.vue
  --------------
  Reusable page header bar with title, subtitle, and action slot.
  Provides consistent top-bar styling across reception pages.

  Usage:
    <PageHeader title="Chi tiết đặt" subtitle="Reservation Details">
      <template #actions>
        <button class="...">Tạo mới</button>
      </template>
    </PageHeader>
-->
<script setup lang="ts">
withDefaults(
  defineProps<{
    /** Main page title. */
    title: string
    /** Optional subtitle / English name. */
    subtitle?: string
    /** Extra Tailwind classes for the title element. */
    titleClass?: string
  }>(),
  { subtitle: '', titleClass: '' },
)
</script>

<template>
  <div class="bg-white border-b border-gray-200 px-6 py-4">
    <div class="flex items-center justify-between">
      <div>
        <h1 :class="['text-2xl font-bold text-gray-900', titleClass]">
          {{ title }}
        </h1>
        <p v-if="subtitle" class="text-sm text-gray-500 mt-1">
          {{ subtitle }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>
