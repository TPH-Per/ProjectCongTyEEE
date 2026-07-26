<!--
  QuickLockBar.vue
  ─────────────────────────────────────────────────────────────────────────────
  Fixed bottom bar for bulk lock/unlock operations.
  Shows count of selected items and provides lock/unlock buttons.
  Emits 'close' when the close button is clicked.
-->
<template>
  <div class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 shadow-lg p-3 z-40">
    <div class="flex items-center justify-between gap-3">
      <div class="flex items-center gap-2">
        <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider">Khóa món nhanh</h3>
        <span class="text-[11px] text-gray-500 font-medium">
          Đã chọn {{ selectedIds.length }} món
        </span>
      </div>

      <div class="flex items-center gap-2">
        <button
          @click="lockSelected"
          :disabled="selectedIds.length === 0"
          :class="[
            'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-colors',
            selectedIds.length > 0
              ? 'bg-red-600 hover:bg-red-700 text-white shadow-sm'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed',
          ]"
        >
          <Lock class="w-3.5 h-3.5" />
          Khóa ({{ selectedIds.length }})
        </button>
        <button
          @click="unlockSelected"
          :disabled="selectedIds.length === 0"
          :class="[
            'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-colors',
            selectedIds.length > 0
              ? 'bg-green-600 hover:bg-green-700 text-white shadow-sm'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed',
          ]"
        >
          <LockOpen class="w-3.5 h-3.5" />
          Mở khóa
        </button>
        <button
          @click="$emit('close')"
          class="px-3 py-1.5 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
        >
          Đóng
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Lock, LockOpen } from 'lucide-vue-next'
import { useMenuManagementStore } from '@/stores/menuManagementStore'

const props = defineProps<{
  selectedIds: string[]
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'locked'): void
}>()

const store = useMenuManagementStore()

function lockSelected(): void {
  if (props.selectedIds.length === 0) return
  store.bulkLockItems(props.selectedIds, true)
  emit('locked')
}

function unlockSelected(): void {
  if (props.selectedIds.length === 0) return
  store.bulkLockItems(props.selectedIds, false)
  emit('locked')
}
</script>
