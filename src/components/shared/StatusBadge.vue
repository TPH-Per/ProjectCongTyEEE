<!--
  StatusBadge.vue
  ---------------
  Reusable status badge with optional colored dot indicator.
  Supports both reservation statuses (PENDING/CONFIRMED/COMPLETED/CANCELLED)
  and table statuses (AVAILABLE/OCCUPIED/RESERVED) for cross-page consistency.

  Usage:
    <StatusBadge status="CONFIRMED" :showDot="true" />
    <StatusBadge status="AVAILABLE" />
-->
<script setup lang="ts">
withDefaults(
  defineProps<{
    /** Status key — reservation or table status. */
    status: string
    /** Show a colored dot before the label. */
    showDot?: boolean
    /** Custom label override; falls back to default text map. */
    label?: string
  }>(),
  { showDot: false, label: '' },
)

const STATUS_CLASSES: Record<string, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800',
  CONFIRMED: 'bg-green-100 text-green-800',
  COMPLETED: 'bg-blue-100 text-blue-800',
  CANCELLED: 'bg-red-100 text-red-800',
  AVAILABLE: 'bg-green-100 text-green-800',
  OCCUPIED: 'bg-red-100 text-red-800',
  RESERVED: 'bg-purple-100 text-purple-800',
}

const DOT_COLORS: Record<string, string> = {
  PENDING: 'bg-yellow-500',
  CONFIRMED: 'bg-green-500',
  COMPLETED: 'bg-blue-500',
  CANCELLED: 'bg-red-500',
  AVAILABLE: 'bg-green-500',
  OCCUPIED: 'bg-red-500',
  RESERVED: 'bg-purple-500',
}

const TEXTS: Record<string, string> = {
  PENDING: 'Chờ xác nhận',
  CONFIRMED: 'Đã xác nhận',
  COMPLETED: 'Hoàn thành',
  CANCELLED: 'Đã hủy',
  AVAILABLE: 'Trống',
  OCCUPIED: 'Đang dùng',
  RESERVED: 'Đã đặt',
}
</script>

<template>
  <span
    :class="[
      'px-3 py-1 rounded-full text-xs font-semibold inline-flex items-center gap-1',
      STATUS_CLASSES[status] || 'bg-gray-100 text-gray-800',
    ]"
  >
    <span
      v-if="showDot"
      :class="['w-1.5 h-1.5 rounded-full', DOT_COLORS[status] || 'bg-gray-500']"
    />
    {{ label || TEXTS[status] || status }}
  </span>
</template>
