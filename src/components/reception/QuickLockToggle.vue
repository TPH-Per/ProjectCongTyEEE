<!--
  QuickLockToggle.vue
  ─────────────────────────────────────────────────────────────────────────────
  Button-style toggle for quickly locking/unlocking a menu item (sold-out).
  Shows "Đang bán" (green) when available, "Đã khóa" (red) when locked.
  Calls store.toggleSoldOut on click.
-->
<template>
  <button
    @click.stop="handleToggle"
    :disabled="disabled"
    :class="[
      'inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg font-bold text-[11px] transition-all border',
      isLocked
        ? 'bg-red-50 text-red-700 hover:bg-red-100 border-red-200'
        : 'bg-green-50 text-green-700 hover:bg-green-100 border-green-200',
      disabled && 'opacity-50 cursor-not-allowed',
    ]"
    :title="isLocked ? 'Món đang khóa — Click để mở' : 'Món đang bán — Click để khóa'"
  >
    <Lock v-if="isLocked" class="w-3.5 h-3.5 shrink-0" />
    <LockOpen v-else class="w-3.5 h-3.5 shrink-0" />
    <span>{{ isLocked ? 'Đã khóa' : 'Đang bán' }}</span>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Lock, LockOpen } from 'lucide-vue-next'
import { useMenuManagementStore } from '@/stores/menuManagementStore'

const props = withDefaults(
  defineProps<{
    itemId: string
    disabled?: boolean
  }>(),
  { disabled: false },
)

const store = useMenuManagementStore()

const item = computed(() => store.getItemById(props.itemId))
const isLocked = computed(() => item.value?.is_sold_out || false)

function handleToggle(): void {
  if (props.disabled) return
  store.toggleSoldOut(props.itemId)
}
</script>
