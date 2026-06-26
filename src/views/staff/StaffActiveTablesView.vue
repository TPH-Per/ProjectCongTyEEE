<template>
  <div class="max-w-md mx-auto pb-24">

    <!-- Header -->
    <header class="bg-white border-b sticky top-0 z-30 px-4 py-3 flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold text-gray-900">{{ t('auto_b_n__ang_ph_c_v_') }}</h1>
        <p class="text-sm text-gray-500">{{ activeOrders.length }} {{ $t('auto_ban_dang_hd') }}</p>
      </div>
      <div class="flex gap-2">
        <button class="w-10 h-10 rounded-full bg-gray-50 flex items-center justify-center text-gray-600">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
        </button>
      </div>
    </header>

    <div class="p-4 space-y-4">
      <div v-if="loading" class="text-center py-10 text-gray-500">{{ t('auto_ang_t_i') }}</div>
      <div v-else-if="activeOrders.length === 0" class="text-center py-10 text-gray-500">{{ t('auto_kh_ng_c_b_n_n_o_ang_ho_t_n') }}</div>
      
      <!-- Active Table Card -->
      <RouterLink v-for="order in activeOrders" :key="order.id" :to="`/staff/table/${order.table_id}/crm`" class="block bg-white rounded-2xl border p-4 shadow-sm active:scale-[0.98] transition-transform">
        <div class="flex justify-between items-start mb-3">
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 bg-red-100 text-red-700 rounded-xl flex items-center justify-center font-bold text-lg">
              {{ order.tables?.code || (order.table_id ? order.table_id.substring(0,4) : 'N/A') }}
            </div>
            <div>
              <div class="font-bold text-gray-900">{{ $t('auto_khach') }} {{ order.guests }} {{ $t('auto_nguoi') }}</div>
              <div class="text-xs font-medium text-red-600 bg-red-50 px-2 py-0.5 rounded-md inline-flex items-center gap-1 mt-1">
                <span class="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>
                {{ t('auto_ang_d_ng_b_a') }}
              </div>
            </div>
          </div>
          <div class="text-right">
            <div class="text-xl font-bold text-gray-900">{{ formatTime(order.created_at) }}</div>
            <div class="text-xs text-gray-500">{{ timeElapsed(order.created_at) }}</div>
          </div>
        </div>

        <div class="bg-gray-50 rounded-xl p-3">
          <div class="flex justify-between text-sm mb-1">
            <span class="text-gray-500">{{ t('auto_g_i_buffer') }}</span>
            <span class="font-semibold text-gray-900">Set Biz 1200k</span>
          </div>
          <div class="flex justify-between text-sm mb-1">
            <span class="text-gray-500">{{ t('auto_m_n_g_i') }}</span>
            <span class="font-semibold text-gray-900">{{ getOrderItemsCount(order) }} món</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">{{ t('auto_y_u_c_u_g_i_nv') }}</span>
            <span class="font-bold text-red-600">0</span>
          </div>
        </div>
      </RouterLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { DEFAULT_BRANCH_ID } from '@/lib/branch-constants'

const { t } = useI18n()
const { branchId } = useAuth()
const activeOrders = ref<any[]>([])
const loading = ref(true)

let timer: ReturnType<typeof setInterval>

async function fetchActiveOrders() {
  const { data } = await supabase
    .from('reservations')
    .select('*, tables(code), orders(id, order_items(id))')
    .eq('branch_id', branchId.value || DEFAULT_BRANCH_ID)
    .in('status', ['CheckedIn', 'Seated'])
    .order('created_at', { ascending: false })
  
  if (data) activeOrders.value = data
  loading.value = false
}

onMounted(() => {
  fetchActiveOrders()
  timer = setInterval(() => {
    // Force reactivity for elapsed time
    activeOrders.value = [...activeOrders.value]
  }, 60000)
})

onUnmounted(() => {
  clearInterval(timer)
})

function formatTime(isoString: string) {
  const d = new Date(isoString)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function timeElapsed(isoString: string) {
  const d = new Date(isoString)
  const diff = Math.floor((Date.now() - d.getTime()) / 60000)
  if (diff < 60) return `${diff} phút trước` // no translation for simplicity or use $t if i18n is configured
  return `${Math.floor(diff/60)}h ${diff%60}p trước`
}

function getOrderItemsCount(order: any): number {
  if (!order.orders || !Array.isArray(order.orders)) return 0
  return order.orders.reduce((sum: number, o: any) => sum + (o.order_items?.length || 0), 0)
}
</script>

