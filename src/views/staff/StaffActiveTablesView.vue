<template>
  <div class="p-4 space-y-4">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-bold text-gray-900">{{ t('auto__ang_ph_c_v_') }}</h2>
      <span class="bg-red-100 text-red-700 text-xs font-bold px-2.5 py-1 rounded-full">{{ activeTables.length }} bàn</span>
    </div>

    <!-- Active Tables List -->
    <div class="space-y-3">
      <div
        v-for="table in activeTables"
        :key="table.id"
        class="bg-white rounded-2xl border shadow-sm overflow-hidden"
        :class="table.status === 'checkout' ? 'border-yellow-400' : 'border-gray-200'"
      >
        <!-- Status bar top -->
        <div class="h-1" :class="table.status === 'checkout' ? 'bg-yellow-400 animate-pulse' : 'bg-red-500'"></div>

        <div class="p-4">
          <div class="flex items-start justify-between mb-3">
            <div>
              <div class="flex items-center gap-2">
                <span class="font-black text-xl text-gray-900">{{ table.code }}</span>
                <span
                  class="text-[10px] font-bold px-2 py-0.5 rounded-full"
                  :class="table.status === 'checkout' ? 'bg-yellow-100 text-yellow-800' : 'bg-green-100 text-green-700'"
                >
                  {{ table.status === 'checkout' ? '⚡ Checkout' : '🍽️ Dining' }}
                </span>
              </div>
              <div class="text-xs text-gray-500 mt-0.5">{{ table.course }}</div>
            </div>
            <div class="text-right">
              <div class="text-xs font-semibold text-gray-400">{{ t('auto____ng_i') }}</div>
              <div class="font-bold text-gray-700">{{ table.duration }}</div>
            </div>
          </div>

          <!-- Guest info -->
          <div class="flex items-center gap-3 text-xs text-gray-500 mb-4">
            <span class="flex items-center gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
              {{ table.guests }} khách
            </span>
            <span>•</span>
            <span>{{ table.channel }}</span>
            <span>•</span>
            <span class="font-semibold" :class="table.repeater ? 'text-red-500' : 'text-gray-400'">
              {{ table.repeater ? '⭐ Repeater' : 'Khách mới' }}
            </span>
          </div>

          <!-- CRM Status chips -->
          <div class="flex items-center gap-2 mb-4 flex-wrap">
            <span class="text-[10px] px-2 py-0.5 rounded-full font-semibold" :class="table.crm.channel ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-400'">
              {{ table.crm.channel ? '✓ Kênh' : '○ Kênh' }}
            </span>
            <span class="text-[10px] px-2 py-0.5 rounded-full font-semibold" :class="table.crm.media ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'">
              {{ table.crm.media ? '✓ Chụp ảnh' : '○ Chụp ảnh' }}
            </span>
            <span class="text-[10px] px-2 py-0.5 rounded-full font-semibold" :class="table.crm.voucher ? 'bg-orange-100 text-orange-700' : 'bg-gray-100 text-gray-400'">
              {{ table.crm.voucher ? '✓ Voucher' : '○ Voucher' }}
            </span>
          </div>

          <!-- Actions -->
          <div class="flex gap-2">
            <RouterLink
              :to="`/staff/table/${table.id}/crm`"
              class="flex-1 bg-red-50 border border-red-200 text-red-700 font-bold text-sm py-2.5 rounded-xl text-center hover:bg-red-100 transition-colors"
            >
              CRM Tại Bàn
            </RouterLink>
            <RouterLink
              :to="`/staff/table/${table.id}/open`"
              class="bg-gray-100 border border-gray-200 text-gray-600 font-bold text-sm py-2.5 px-4 rounded-xl hover:bg-gray-200 transition-colors"
            >
              Chi tiết
            </RouterLink>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="activeTables.length === 0" class="text-center py-16 text-gray-400">
      <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-3 text-gray-300"><path d="M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/><rect width="20" height="14" x="2" y="6" rx="2"/></svg>
      <p class="font-semibold">{{ t('auto_ch_a_c__b_n_n_o__ang_ph_c_v_') }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { RouterLink } from 'vue-router'
import { ref, onMounted } from 'vue'
import { useTable } from '@/composables/useTable'
import { useRealtime } from '@/composables/useRealtime'
import type { TableT as TableRow } from '@/types/database'

const { listTables } = useTable()
const { watchTable } = useRealtime()

const activeTables = ref<any[]>([])

const fetchTables = async () => {
  const tables = await listTables()
  activeTables.value = tables.filter(t => t.status !== 'available').map(t => ({
    id: t.id,
    code: t.code,
    status: t.status === 'reserved' ? 'checkout' : 'dining',
    course: 'Premium Buffet 1380k + Drink A',
    guests: t.capacity || 4,
    duration: '1h 15m',
    channel: 'Zalo OA',
    repeater: true,
    crm: { channel: true, media: false, voucher: false }
  }))
}

onMounted(() => {
  fetchTables()
  watchTable('tables', '*', () => {
    fetchTables()
  })
})
</script>
