<template>
  <div class="space-y-6">

    <!-- Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">{{ t('auto_t_ng_k_t_ca') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">{{ t('auto_______________ng_ca___xu_t_b_o') }}</p>
      </div>
      <div class="flex gap-2">
        <button @click="handleExportCSV" class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          {{ t('auto_xu_t_csv', 'Xuất CSV') }}
        </button>
        <button @click="handleCloseShift" :disabled="loading" class="kawaii-btn-primary px-5 py-2 text-sm font-bold flex items-center gap-2 disabled:opacity-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          {{ loading ? 'Đang Đóng Ca...' : 'Xác Nhận Đóng Ca' }}
        </button>
      </div>
    </div>

    <!-- Revenue by Type -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-5">{{ t('auto_doanh_thu_theo_lo_i_h_nh______') }}</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="rounded-2xl border-2 border-red-200 bg-red-50 p-4 text-center">
          <div class="text-2xl mb-2">🍖</div>
          <div class="text-xs font-bold text-red-400 uppercase tracking-wide mb-1">{{ t('auto_b_a_t_i__dinner_') }}</div>
          <div class="text-2xl font-black text-red-700">{{ stats.dinner.revenue.toLocaleString() }}</div>
          <div class="text-xs text-red-400 mt-1">{{ stats.dinner.orders }} bill - {{ stats.dinner.guests }} khách</div>
        </div>
        <div class="rounded-2xl border-2 border-orange-200 bg-orange-50 p-4 text-center">
          <div class="text-2xl mb-2">🍱</div>
          <div class="text-xs font-bold text-orange-400 uppercase tracking-wide mb-1">{{ t('auto_b_a_tr_a__lunch_') }}</div>
          <div class="text-2xl font-black text-orange-700">{{ stats.lunch.revenue.toLocaleString() }}</div>
          <div class="text-xs text-orange-400 mt-1">{{ stats.lunch.orders }} bill - {{ stats.lunch.guests }} khách</div>
        </div>
        <div class="rounded-2xl border-2 border-purple-200 bg-purple-50 p-4 text-center">
          <div class="text-2xl mb-2">🍶</div>
          <div class="text-xs font-bold text-purple-400 uppercase tracking-wide mb-1">{{ t('auto_r__u_wine') }}</div>
          <div class="text-2xl font-black text-purple-700">{{ stats.wine.revenue.toLocaleString() }}</div>
          <div class="text-xs text-purple-400 mt-1">{{ stats.wine.orders }} bill</div>
        </div>
        <div class="rounded-2xl border-2 border-blue-200 bg-blue-50 p-4 text-center">
          <div class="text-2xl mb-2">🛵</div>
          <div class="text-xs font-bold text-blue-400 uppercase tracking-wide mb-1">{{ t('auto_giao_h_ng__delivery_') }}</div>
          <div class="text-2xl font-black text-blue-700">{{ stats.delivery.revenue.toLocaleString() }}</div>
          <div class="text-xs text-blue-400 mt-1">{{ stats.delivery.orders }} đơn</div>
        </div>
      </div>

      <div class="bg-[hsl(var(--muted))] rounded-xl p-4 flex items-center justify-between">
        <div class="font-black text-lg text-[hsl(var(--foreground))]">{{ t('auto_t_ng_doanh_thu_ng_y') }}</div>
        <div class="text-3xl font-black text-[hsl(var(--primary))]">{{ totalRevenue.toLocaleString() }}đ</div>
      </div>
    </div>

    <!-- Session Summary Table -->
    <div class="kawaii-card overflow-hidden">
      <div class="kawaii-card-header">
        <span class="font-bold text-sm">{{ t('auto_l_ch_s__thanh_to_n_trong_ca') }}</span>
        <span class="kawaii-pill bg-[hsl(var(--primary))]/10 text-[hsl(var(--primary))]">{{ orders.length }} bàn</span>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-[hsl(var(--border))]">
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_b_n') }}</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_lo_i') }}</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_kh_ch') }}</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_tr_ng_th_i', 'Trạng Thái') }}</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Doanh Thu</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_tg_thanh_to_n') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-for="order in orders" :key="order.id" class="hover:bg-[hsl(var(--muted))]/50">
              <td class="py-2.5 px-4 font-bold text-[hsl(var(--foreground))]">{{ order.reservations?.tables?.code || (order.reservations?.table_id ? order.reservations?.table_id.substring(0,4) : 'N/A') }}</td>
              <td class="py-2.5 px-4">
                <span class="kawaii-pill bg-gray-100">{{ order.order_type || 'Dinner' }}</span>
              </td>
              <td class="py-2.5 px-4 text-right text-gray-600">{{ order.reservations?.guests || 0 }}</td>
              <td class="py-2.5 px-4 text-gray-600 text-xs">{{ order.status }}</td>
              <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ order.total?.toLocaleString() }}đ</td>
              <td class="py-2.5 px-4 text-gray-500 text-xs">{{ new Date(order.created_at).toLocaleTimeString() }}</td>
            </tr>
            <tr v-if="orders.length === 0">
              <td colspan="7" class="py-4 text-center text-gray-500">{{ t('auto_ch_a_c_d_li_u', 'Chưa có dữ liệu') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2';
import { useI18n } from 'vue-i18n'
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const { t } = useI18n()
const { branchId } = useAuth()
const loading = ref(false)

const orders = ref<any[]>([])

const stats = ref({
  dinner: { revenue: 0, orders: 0, guests: 0 },
  lunch: { revenue: 0, orders: 0, guests: 0 },
  wine: { revenue: 0, orders: 0, guests: 0 },
  delivery: { revenue: 0, orders: 0, guests: 0 }
})

const totalRevenue = computed(() => {
  return stats.value.dinner.revenue + stats.value.lunch.revenue + stats.value.wine.revenue + stats.value.delivery.revenue
})

async function fetchStats() {
  const today = new Date().toISOString().split('T')[0]
  
  // Fetch today's closed orders
  const { data } = await supabase.from('orders')
    .select('*, reservations(guests, table_id, tables(code))')
    .eq('branch_id', branchId.value || 'B001')
    .eq('status', 'Paid')
    .gte('created_at', today)
    .order('created_at', { ascending: false })
    
  if (data) {
    orders.value = data
    
    // Aggregate stats
    data.forEach(o => {
      const type = (o.order_type || 'dinner').toLowerCase()
      const amt = o.total || 0
      const g = o.reservations?.guests || 0
      
      if (type === 'lunch') {
        stats.value.lunch.revenue += amt
        stats.value.lunch.orders += 1
        stats.value.lunch.guests += g
      } else if (type === 'wine') {
        stats.value.wine.revenue += amt
        stats.value.wine.orders += 1
        stats.value.wine.guests += g
      } else if (type === 'delivery') {
        stats.value.delivery.revenue += amt
        stats.value.delivery.orders += 1
        stats.value.delivery.guests += g
      } else {
        stats.value.dinner.revenue += amt
        stats.value.dinner.orders += 1
        stats.value.dinner.guests += g
      }
    })
  }
}

onMounted(() => {
  fetchStats()
})

async function handleCloseShift() {
  loading.value = true
  try {
    const { error } = await supabase.functions.invoke('close-shift', {
      body: {
        branch_id: branchId.value || 'B001'
      }
    })
    if (error) throw error
    Swal.fire('Thành công', 'Đóng ca thành công!', 'success')
  } catch (err: any) {
    Swal.fire('Lỗi', 'Lỗi đóng ca: ' + err.message, 'error')
  } finally {
    loading.value = false
  }
}

async function handleExportCSV() {
  Swal.fire('Thông báo', 'Đang gọi Export CSV Edge Function...', 'info')
  try {
    const { data, error } = await supabase.functions.invoke('export-shift-csv', {
      body: { branch_id: branchId.value || 'B001' }
    })
    if (error) throw error
    console.log('CSV Data:', data)
    Swal.fire('Thành công', 'Xuất CSV thành công (Check console)', 'success')
  } catch (err: any) {
    Swal.fire('Lỗi', 'Lỗi xuất CSV: ' + err.message, 'error')
  }
}
</script>

