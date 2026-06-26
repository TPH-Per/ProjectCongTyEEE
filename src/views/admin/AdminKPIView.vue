<template>
  <div class="p-6 max-w-7xl mx-auto">

    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-800 mb-2 flex items-center gap-2">
        <span class="text-[#FF7B89]">🎯</span> {{ t('auto_qu_n_l_kpi_kgi') }}
      </h1>
      <p class="text-gray-500">{{ t('auto_c_u_h_nh_v__theo_d_i_m_c_ti_u_') }}</p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
      <!-- Cấu hình KPI Form -->
      <div class="kawaii-card lg:col-span-1 p-6">
        <h2 class="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
          <span class="text-[#FF7B89]">⚙️</span> {{ t('auto_thi_t_l_p_m_c_ti_u') }}
        </h2>
        
        <form @submit.prevent="saveKPI" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_th_ng___n_m') }}</label>
            <input type="month" v-model="form.month" class="kawaii-input w-full" />
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_m_c_ti_u_doanh_thu__vn__') }}</label>
            <input type="number" v-model="form.revenue" :placeholder="$t('auto_placeholder_fix')" class="kawaii-input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_m_c_ti_u_s__kh_ch') }}</label>
            <input type="number" v-model="form.guests" :placeholder="$t('auto_placeholder_fix')" class="kawaii-input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_t__l__cogs_t_i__a____') }}</label>
            <input type="number" v-model="form.cogsRatio" :placeholder="$t('auto_placeholder_fix')" class="kawaii-input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_t__l__l_p___y_b_n____') }}</label>
            <input type="number" v-model="form.fillRate" :placeholder="$t('auto_placeholder_fix')" class="kawaii-input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_gi__tr__tb_h_a___n__vn__') }}</label>
            <input type="number" v-model="form.avgCheck" :placeholder="$t('auto_placeholder_fix')" class="kawaii-input w-full" />
          </div>

          <button type="submit" :disabled="loading" class="kawaii-btn-primary w-full mt-4 flex justify-center items-center gap-2 py-3 rounded-xl font-bold">
            <span>💾</span> {{ loading ? t('auto_dang_luu', 'Đang lưu...') : t('auto_luu_thiet_lap', 'Lưu Thiết Lập') }}
          </button>
        </form>
      </div>

      <!-- Hiện trạng VS Mục tiêu -->
      <div class="lg:col-span-2 space-y-6">
        <div class="kawaii-card p-6">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-gray-800 flex items-center gap-2">
              <span class="text-[#FF7B89]">📊</span> {{ t('auto_hi_n_tr_ng_vs_m_c_ti_u_th_ng') }}
            </h2>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            <!-- Revenue -->
            <div class="border rounded-2xl p-4 bg-orange-50/50 border-orange-100 hover:shadow-md transition-shadow">
              <div class="text-sm text-gray-500 font-medium mb-1">{{ t('auto_doanh_thu') }}</div>
              <div class="text-2xl font-bold text-orange-600 mb-2">320M <span class="text-sm font-normal text-gray-400">/ {{ (form.revenue / 1000000) || 0 }}M</span></div>
              <div class="w-full bg-orange-200/50 rounded-full h-3">
                <div class="kawaii-gradient h-3 rounded-full shadow-sm" :style="`width: ${Math.min(100, (320000000 / (form.revenue || 1)) * 100)}%`"></div>
              </div>
            </div>

            <!-- Guests -->
            <div class="border rounded-2xl p-4 bg-blue-50/50 border-blue-100 hover:shadow-md transition-shadow">
              <div class="text-sm text-gray-500 font-medium mb-1">{{ t('auto_s__kh_ch') }}</div>
              <div class="text-2xl font-bold text-blue-600 mb-2">850 <span class="text-sm font-normal text-gray-400">/ {{ form.guests || 0 }}</span></div>
              <div class="w-full bg-blue-200/50 rounded-full h-3">
                <div class="bg-blue-400 h-3 rounded-full shadow-sm" :style="`width: ${Math.min(100, (850 / (form.guests || 1)) * 100)}%`"></div>
              </div>
            </div>

            <!-- COGS -->
            <div class="border rounded-2xl p-4 bg-green-50/50 border-green-100 hover:shadow-md transition-shadow">
              <div class="text-sm text-gray-500 font-medium mb-1">{{ t('auto_t__l__cogs') }}</div>
              <div class="text-2xl font-bold text-green-600 mb-2">28% <span class="text-sm font-normal text-gray-400">/ {{ form.cogsRatio || 0 }}%</span></div>
              <div class="w-full bg-green-200/50 rounded-full h-3">
                <div class="bg-green-400 h-3 rounded-full shadow-sm" :style="`width: ${Math.min(100, (28 / (form.cogsRatio || 1)) * 100)}%`"></div>
              </div>
            </div>

            <!-- Fill Rate -->
            <div class="border rounded-2xl p-4 bg-purple-50/50 border-purple-100 hover:shadow-md transition-shadow">
              <div class="text-sm text-gray-500 font-medium mb-1">{{ t('auto_t__l__l_p___y') }}</div>
              <div class="text-2xl font-bold text-purple-600 mb-2">65% <span class="text-sm font-normal text-gray-400">/ {{ form.fillRate || 0 }}%</span></div>
              <div class="w-full bg-purple-200/50 rounded-full h-3">
                <div class="bg-purple-400 h-3 rounded-full shadow-sm" :style="`width: ${Math.min(100, (65 / (form.fillRate || 1)) * 100)}%`"></div>
              </div>
            </div>

            <!-- Avg Check -->
            <div class="border rounded-2xl p-4 bg-pink-50/50 border-pink-100 hover:shadow-md transition-shadow">
              <div class="text-sm text-gray-500 font-medium mb-1">{{ t('auto_gi__tr__tb_h_a___n') }}</div>
              <div class="text-2xl font-bold text-[#FF7B89] mb-2">380k <span class="text-sm font-normal text-gray-400">/ {{ (form.avgCheck / 1000) || 0 }}k</span></div>
              <div class="w-full bg-pink-200/50 rounded-full h-3">
                <div class="bg-[#FF7B89] h-3 rounded-full shadow-sm" :style="`width: ${Math.min(100, (380000 / (form.avgCheck || 1)) * 100)}%`"></div>
              </div>
            </div>
          </div>
        </div>

        <div class="kawaii-card p-6">
          <h2 class="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="text-[#FF7B89]">📋</span> {{ t('auto_l_ch_s_c_u_h_nh') }}
          </h2>
          <div class="overflow-x-auto rounded-2xl border border-gray-100">
            <table class="w-full text-left border-collapse">
              <thead class="bg-gray-50/50">
                <tr class="text-gray-500 border-b border-gray-100">
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_th_ng') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_doanh_thu') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_s__kh_ch') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_cogs') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_l_p___y') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_tb_h_') }}</th>
                  <th class="py-3 px-4 font-medium text-sm">{{ t('auto_h_nh___ng') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="kpiHistory.length === 0" class="border-b border-gray-50">
                  <td colspan="7" class="py-6 px-4 text-center text-sm text-gray-500">
                    {{ t('auto_ch_a_c_d_li_u_kpi_n_o') }}
                  </td>
                </tr>
                <tr v-for="kpi in kpiHistory" :key="kpi.month" class="border-b border-gray-50 hover:bg-pink-50/30 transition-colors">
                  <td class="py-3 px-4 text-sm font-medium text-gray-800">{{ kpi.month }}</td>
                  <td class="py-3 px-4 text-sm text-gray-600 font-medium">{{ kpi.revenue ? (kpi.revenue / 1000000) + 'M' : '-' }}</td>
                  <td class="py-3 px-4 text-sm text-gray-600">{{ kpi.guests || '-' }}</td>
                  <td class="py-3 px-4 text-sm text-gray-600">{{ kpi.cogsRatio ? kpi.cogsRatio + '%' : '-' }}</td>
                  <td class="py-3 px-4 text-sm text-gray-600">{{ kpi.fillRate ? kpi.fillRate + '%' : '-' }}</td>
                  <td class="py-3 px-4 text-sm text-gray-600">{{ kpi.avgCheck ? (kpi.avgCheck / 1000) + 'k' : '-' }}</td>
                  <td class="py-3 px-4">
                    <button @click="editKPI(kpi)" class="text-[#FF7B89] hover:bg-pink-100 p-2 rounded-full transition-colors w-8 h-8 flex items-center justify-center">
                      ✏️
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2';
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted } from 'vue'
import { useKPI } from '@/composables/useKPI'

const { listCurrent, upsert, loading, error } = useKPI()

const form = ref({
  month: new Date().toISOString().slice(0, 7),
  revenue: 500000000,
  guests: 1500,
  cogsRatio: 30,
  fillRate: 80,
  avgCheck: 350000
})

const kpiHistory = ref<any[]>([])

const fetchKPIs = async () => {
  try {
    const yearStart = new Date().getFullYear() + '-01-01'
    const yearEnd = new Date().getFullYear() + '-12-31'
    const data = await listCurrent(yearStart, yearEnd)
    
    const grouped = data.reduce((acc: any, row: any) => {
      const month = row.period_start.slice(0, 7)
      if (!acc[month]) acc[month] = { month }
      acc[month][row.metric_key] = row.target_value
      return acc
    }, {})
    
    kpiHistory.value = Object.values(grouped).sort((a: any, b: any) => b.month.localeCompare(a.month))
    
    if (kpiHistory.value.length > 0) {
      const latest = kpiHistory.value[0]
      form.value = {
        month: latest.month,
        revenue: latest.revenue || 0,
        guests: latest.guests || 0,
        cogsRatio: latest.cogsRatio || 0,
        fillRate: latest.fillRate || 0,
        avgCheck: latest.avgCheck || 0
      }
    }
  } catch (err) {
    console.error('Lỗi khi tải KPI:', err)
  }
}

onMounted(() => {
  fetchKPIs()
})

const saveKPI = async () => {
  const periodStart = `${form.value.month}-01`
  // Get last day of the month
  const [year, month] = form.value.month.split('-')
  const lastDay = new Date(Number(year), Number(month), 0).getDate()
  const periodEnd = `${form.value.month}-${lastDay}`

  try {
    const metrics = [
      { key: 'revenue', value: form.value.revenue },
      { key: 'guests', value: form.value.guests },
      { key: 'cogsRatio', value: form.value.cogsRatio },
      { key: 'fillRate', value: form.value.fillRate },
      { key: 'avgCheck', value: form.value.avgCheck }
    ]

    for (const metric of metrics) {
      await upsert({
        metric_key: metric.key,
        target_value: metric.value,
        period_start: periodStart,
        period_end: periodEnd,
        scope: 'branch'
      })
    }
    Swal.fire('Thông báo', 'Đã lưu cấu hình KPI!', 'info')
    await fetchKPIs()
  } catch (err) {
    Swal.fire('Lỗi', 'Có lỗi xảy ra: ' + (error.value || err), 'error')
  }
}

const editKPI = (kpi: any) => {
  form.value = {
    month: kpi.month,
    revenue: kpi.revenue || 0,
    guests: kpi.guests || 0,
    cogsRatio: kpi.cogsRatio || 0,
    fillRate: kpi.fillRate || 0,
    avgCheck: kpi.avgCheck || 0
  }
}
</script>

