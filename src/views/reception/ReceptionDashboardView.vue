<template>
  <div>
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">{{ t('auto_t_ng_quan_ca_l_m_vi_c') }}</h2>
        <p class="text-sm text-gray-500">{{ t('auto_h_m_nay') }}</p>
      </div>
      <div class="flex gap-3">
        <div class="bg-white border px-4 py-2 rounded-xl text-center">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto_b_n__ang_d_ng') }}</div>
          <div class="text-xl font-black text-gray-900">{{ diningTables.length }}</div>
        </div>
        <div class="bg-white border px-4 py-2 rounded-xl text-center">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto_ch__thanh_to_n') }}</div>
          <div class="text-xl font-black text-red-600">{{ checkoutTables.length }}</div>
        </div>
        <div class="bg-white border px-4 py-2 rounded-xl text-center">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto___t_b_n_h_m_nay') }}</div>
          <div class="text-xl font-black text-blue-600">{{ reservations.length }}</div>
        </div>
      </div>
    </div>

    <!-- Alerts Section -->
    <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">{{ t('auto_c_n_x__l__ngay') }}</h3>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
      
      <!-- Checkout Alert -->
      <div v-for="table in checkoutTables" :key="table.id" class="bg-red-50 border-2 border-red-500 rounded-2xl p-5 shadow-sm relative overflow-hidden">
        <div class="absolute top-0 right-0 w-16 h-16 bg-red-100 rounded-bl-full flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500 animate-pulse translate-x-2 -translate-y-2"><path d="M22 17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9.5C2 7 4 5 6.5 5H18c2.2 0 4 1.8 4 4v8Z"/><polyline points="15,9 18,9 18,11"/><path d="M6.5 5C9 5 11 7 11 9.5V17a2 2 0 0 1-2 2v0"/><line x1="6" x2="6" y1="10" y2="10"/></svg>
        </div>
        <div class="flex items-center gap-3 mb-3">
          <div class="w-3 h-3 rounded-full bg-red-500 animate-pulse"></div>
          <span class="font-bold text-red-700">{{ t('auto_y_u_c_u_thanh_to_n') }}</span>
        </div>
        <div class="text-3xl font-black text-gray-900 mb-1">Bàn {{ table.code }}</div>
        <div class="text-sm text-gray-600 mb-6">{{ table.capacity || 4 }} Khách</div>
        <RouterLink :to="`/reception/checkout/${table.id}`" class="block w-full bg-red-600 hover:bg-red-700 text-white text-center font-bold py-3 rounded-xl transition-colors">
          Tiến Hành Thanh Toán
        </RouterLink>
      </div>

      <div v-if="checkoutTables.length === 0" class="col-span-full text-sm text-gray-400">
        Không có yêu cầu thanh toán nào.
      </div>
    </div>

    <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">{{ t('auto_danh_s_ch_b_n__ang_ph_c_v_') }}</h3>
    <div class="bg-white border rounded-2xl overflow-hidden shadow-sm">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-50 border-b">
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_m__b_n') }}</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_g_i_d_ch_v_') }}</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_kh_ch') }}</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_th_i_gian') }}</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_tr_ng_th_i') }}</th>
          </tr>
        </thead>
        <tbody class="text-sm divide-y">
          <tr v-for="table in diningTables" :key="table.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-3 px-4 font-bold text-gray-900">{{ table.code }}</td>
            <td class="py-3 px-4 text-gray-600">Mockup Package</td>
            <td class="py-3 px-4 text-gray-600">{{ table.capacity || 2 }}</td>
            <td class="py-3 px-4 text-gray-600">{{ t('auto__ang_ph_c_v_') }}</td>
            <td class="py-3 px-4"><span class="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">{{ t('auto__ang_d_ng_b_a') }}</span></td>
          </tr>
          <tr v-if="diningTables.length === 0">
            <td colspan="5" class="py-4 text-center text-gray-400">{{ t('auto_kh_ng_c__b_n__ang_ph_c_v__') }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useTable } from '@/composables/useTable'
import { useReservation } from '@/composables/useReservation'
import { useRealtime } from '@/composables/useRealtime'
import type { TableT, Reservation } from '@/types/database'

const { listTables } = useTable()
const { listByDate } = useReservation()
const { watchTable } = useRealtime()

const tables = ref<TableT[]>([])
const reservations = ref<Reservation[]>([])

const diningTables = computed(() => tables.value.filter(t => t.status === 'occupied'))
const checkoutTables = computed(() => tables.value.filter(t => t.status === 'reserved')) // or simply remove checkout tracking since TableStatus doesn't have it

const fetchData = async () => {
  try {
    const [tablesData, resData] = await Promise.all([
      listTables(),
      listByDate(new Date().toISOString().split('T')[0])
    ])
    tables.value = tablesData
    reservations.value = resData
  } catch (err) {
    console.error('Error fetching dashboard data:', err)
  }
}

onMounted(() => {
  fetchData()
  
  watchTable('tables', '*', () => {
    fetchData()
  })
  
  watchTable('reservations', '*', () => {
    fetchData()
  })
})
</script>
