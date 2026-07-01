<template>
  <div class="space-y-6">

    <!-- Stats Row -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="kawaii-card bg-white p-6 relative overflow-hidden">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500 mb-1">{{ t('auto_t_ng_doanh_thu_to_n_h__th_ng') }}</p>
            <h3 class="text-2xl font-bold text-gray-800">{{ formatCurrency(totalRevenue) }}</h3>
            <p class="text-xs text-green-500 mt-2 flex items-center">
              <TrendingUpIcon class="w-3 h-3 mr-1" /> {{ t('auto_12_5_so_v_i_th_ng_tr_c') }}
            </p>
          </div>
          <div class="w-12 h-12 rounded-full bg-rose-100 flex items-center justify-center text-[#FF7B89]">
            <BanknoteIcon class="w-6 h-6" />
          </div>
        </div>
        <div class="absolute -right-4 -bottom-4 opacity-5 text-[#FF7B89]">
           <BanknoteIcon class="w-32 h-32" />
        </div>
      </div>
      
      <div class="kawaii-card bg-white p-6 relative overflow-hidden">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500 mb-1">{{ t('auto_t_ng_b_n__ang_ph_c_v_') }}</p>
            <h3 class="text-2xl font-bold text-gray-800">{{ activeTables }} / {{ totalTables }}</h3>
            <p class="text-xs text-blue-500 mt-2 flex items-center">
              <ActivityIcon class="w-3 h-3 mr-1" /> {{ $t('auto_cong_suat') }} {{ totalTables > 0 ? Math.round((activeTables / totalTables) * 100) : 0 }}%
            </p>
          </div>
          <div class="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-500">
            <UsersIcon class="w-6 h-6" />
          </div>
        </div>
      </div>

      <div class="kawaii-card bg-white p-6 relative overflow-hidden">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500 mb-1">{{ t('auto_tr_ng_th_i_h__th_ng') }}</p>
            <h3 class="text-2xl font-bold text-green-500">{{ t('auto_ho_t___ng_t_t') }}</h3>
            <p class="text-xs text-gray-500 mt-2 flex items-center">
              <CheckCircleIcon class="w-3 h-3 mr-1 text-green-500" /> {{ t('auto_api_erp_ng_b') }}
            </p>
          </div>
          <div class="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-500">
            <ServerIcon class="w-6 h-6" />
          </div>
        </div>
      </div>
    </div>

    <!-- Branch Performance -->
    <div class="kawaii-card bg-white p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-bold text-gray-800">{{ t('auto_hi_u_su_t_chi_nh_nh') }}</h3>
        <select class="kawaii-input text-sm py-1 px-3 w-auto bg-gray-50 border-none">
          <option>{{ t('auto_h_m_nay') }}</option>
          <option>{{ t('auto_tu_n_n_y') }}</option>
          <option>{{ t('auto_th_ng_n_y') }}</option>
        </select>
      </div>
      
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-gray-400 text-sm border-b border-gray-100">
              <th class="py-3 px-4 font-medium">{{ t('auto_chi_nh_nh') }}</th>
              <th class="py-3 px-4 font-medium">Doanh thu</th>
              <th class="py-3 px-4 font-medium">{{ t('auto___n_h_ng') }}</th>
              <th class="py-3 px-4 font-medium">{{ t('auto___nh_gi_') }}</th>
              <th class="py-3 px-4 font-medium">{{ t('auto_tr_ng_th_i') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading" class="border-b border-gray-50">
              <td colspan="5" class="py-6 px-4 text-center text-sm text-gray-500">
                {{ t('auto_ang_t_i_d_li_u') }}
              </td>
            </tr>
            <tr v-for="branch in branchPerformance" :key="branch.id" class="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-4 font-medium text-gray-700 flex items-center">
                <div class="w-8 h-8 rounded bg-rose-100 text-[#FF7B89] flex items-center justify-center mr-3 text-xs font-bold">
                  {{ branch.code }}
                </div>
                {{ branch.name }}
              </td>
              <td class="py-4 px-4 font-semibold text-gray-800">{{ branch.revenue }}</td>
              <td class="py-4 px-4 text-gray-600">{{ branch.orders }}</td>
              <td class="py-4 px-4 text-gray-600 flex items-center">
                <StarIcon class="w-4 h-4 text-yellow-400 mr-1 fill-current" /> {{ branch.rating }}
              </td>
              <td class="py-4 px-4">
                <span v-if="branch.isActive" class="px-2 py-1 bg-green-100 text-green-600 rounded-full text-xs font-medium">
                  {{ t('auto_ang_ho_t_ng') }}
                </span>
                <span v-else class="px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs font-medium">
                  {{ t('auto_t_m_ng_ng') }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted } from 'vue'
import { 
  TrendingUpIcon, 
  BanknoteIcon, 
  ActivityIcon, 
  UsersIcon,
  ServerIcon,
  CheckCircleIcon,
  StarIcon
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useBranch } from '@/composables/useBranch'

const { listBranches } = useBranch()

const loading = ref(true)
const totalRevenue = ref(0)
const activeTables = ref(0)
const totalTables = ref(0)
const branchPerformance = ref<any[]>([])

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

onMounted(async () => {
  loading.value = true
  try {
    const branches = await listBranches()
    const today = new Date().toISOString().slice(0, 10)
    let sysRev = 0
    let sysActiveTables = 0
    let sysTotalTables = 0
    const performance = []

    for (const branch of branches) {
      // Get invoices for revenue & orders
      const { data: invoices } = await supabase
        .from('invoices')
        .select('total, order_id')
        .eq('branch_id', branch.id)
        .eq('status', 'paid')
        .gte('issued_at', `${today}T00:00:00Z`)

      const rev = (invoices || []).reduce((sum, inv) => sum + Number(inv.total), 0)
      const orders = new Set((invoices || []).map(inv => inv.order_id)).size
      
      sysRev += rev

      performance.push({
        id: branch.id,
        code: branch.code,
        name: branch.name,
        revenue: formatCurrency(rev),
        orders,
        rating: 5.0, // Mocked rating
        isActive: branch.is_active
      })

      // Get table capacity
      const { data: tables } = await supabase
        .from('tables')
        .select('status')
        .eq('branch_id', branch.id)

      if (tables) {
        sysTotalTables += tables.length
        sysActiveTables += tables.filter(t => t.status === 'occupied').length
      }
    }

    totalRevenue.value = sysRev
    activeTables.value = sysActiveTables
    totalTables.value = sysTotalTables
    branchPerformance.value = performance

  } catch (err) {
    console.error('Error fetching dashboard data', err)
  } finally {
    loading.value = false
  }
})
</script>

