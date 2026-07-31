<!--
  NotificationPanel.vue
  ─────────────────────────────────────────────────────────────────────────────
  Sticky notifications sidebar for the Reception Dashboard.  Receives
  pre-computed notifications + unread count via props and emits click /
  mark-read events back to the parent for routing / API calls.
-->
<template>
  <div class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden flex flex-col h-[calc(100vh-12rem)] sticky top-6">

    <!-- Header -->
    <div class="bg-gray-50 px-4 py-4 border-b flex items-center justify-between shrink-0">
      <div class="flex items-center gap-2">
        <div class="relative">
          <Bell class="w-5 h-5 text-[#E8772E]" />
          <span
            v-if="unreadCount > 0"
            class="absolute -top-1.5 -right-1.5 bg-red-600 text-white text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center border border-white animate-pulse"
          >
            {{ unreadCount }}
          </span>
        </div>
        <span class="font-extrabold text-[#3D2817] text-sm">{{ t('reception.notifications') }}</span>
      </div>
      <button
        @click="showAll = !showAll"
        class="text-xs font-bold text-[#E8772E] hover:underline"
      >
        {{ showAll ? 'Thu gọn' : 'Xem thêm...' }}
      </button>
    </div>

    <!-- Items -->
    <div class="flex-1 overflow-y-auto divide-y divide-gray-100 p-2 space-y-2">
      <div
        v-for="notif in visibleNotifications"
        :key="notif.id"
        :class="[
          'p-3 rounded-xl border transition-all duration-200 relative cursor-pointer',
          notif.isRead ? 'bg-white border-gray-100 text-gray-600' : 'bg-orange-50/30 border-orange-100 hover:bg-orange-50/50 shadow-sm'
        ]"
        @click="$emit('notificationClick', notif)"
      >
        <!-- Unread dot -->
        <div
          v-if="!notif.isRead"
          class="absolute top-3.5 right-3.5 w-2 h-2 rounded-full bg-[#E8772E]"
        ></div>

        <!-- Type badge + priority -->
        <div class="flex items-center gap-2 mb-1.5">
          <span
            :class="[
              'text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md border',
              typeClass(notif.type)
            ]"
          >
            {{ typeLabel(notif.type) }}
          </span>
          <span
            v-if="notif.priority === 'high'"
            class="bg-red-100 text-red-700 text-[8px] font-black uppercase px-1 rounded border border-red-200"
          >{{ t('reception.urgent') }}</span>
        </div>

        <!-- Body -->
        <div class="text-xs font-extrabold text-[#3D2817] pr-4 line-clamp-2">
          {{ notif.title }}
        </div>
        <div class="text-[11px] text-gray-500 mt-1 line-clamp-3">
          {{ notif.message }}
        </div>

        <!-- Footer -->
        <div class="flex items-center justify-between mt-2.5 pt-1.5 border-t border-gray-100/50">
          <span class="text-[9px] text-gray-400 font-semibold font-mono flex items-center gap-1">
            <Clock class="w-3 h-3 text-gray-300" />
            {{ formatTime(notif.timestamp) }}
          </span>
          <button
            v-if="!notif.isRead"
            @click.stop="$emit('markRead', notif.id)"
            class="text-[9px] font-bold text-[#E8772E] hover:underline"
          >{{ t('reception.read') }}</button>
        </div>
      </div>

      <div v-if="visibleNotifications.length === 0" class="text-center text-gray-400 py-10 text-xs">
        {{ t('reception.no_notifications') }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Bell, Clock } from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'

export interface UINotification {
  id: string
  type: 'out_of_stock' | 'low_stock' | 'booking' | 'payment'
  title: string
  message: string
  timestamp: Date
  isRead: boolean
  priority: 'high' | 'medium' | 'low'
}

const props = defineProps<{
  notifications: UINotification[]
  unreadCount: number
}>()

defineEmits<{
  (e: 'notificationClick', notif: UINotification): void
  (e: 'markRead', id: string): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const showAll = ref(false)

const visibleNotifications = computed(() => {
  return showAll.value ? props.notifications : props.notifications.slice(0, 5)
})

function typeClass(type: UINotification['type']): string {
  switch (type) {
    case 'out_of_stock': return 'bg-red-50 text-red-700 border-red-200'
    case 'low_stock': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
    case 'booking': return 'bg-blue-50 text-blue-700 border-blue-200'
    case 'payment': return 'bg-green-50 text-green-700 border-green-200'
    default: return 'bg-gray-50 text-gray-700 border-gray-200'
  }
}

function typeLabel(type: UINotification['type']): string {
  switch (type) {
    case 'out_of_stock': return 'Hết hàng'
    case 'low_stock': return 'Sắp hết'
    case 'booking': return 'Đặt bàn'
    case 'payment': return 'Yêu cầu thanh toán'
    default: return 'Hệ thống'
  }
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  })
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
