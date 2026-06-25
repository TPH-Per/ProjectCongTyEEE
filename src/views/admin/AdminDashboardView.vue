<template>
  <div class="space-y-6 max-w-7xl mx-auto">

    <!-- Header -->
    <div>
      <h1 class="text-3xl font-extrabold text-gray-900 tracking-tight">{{ t('auto_t_ng_quan_h__th_ng') }}</h1>
      <p class="text-sm text-gray-500 mt-1">{{ t('auto_tr_ng_th_i_ho_t___ng_c_a_h__th') }}</p>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex justify-center items-center py-20">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <template v-else>
      <!-- Quick Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        
        <!-- Revenue Card -->
        <div class="bg-gradient-to-br from-white to-gray-50 rounded-2xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center gap-4 mb-4">
            <div class="w-12 h-12 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center shadow-inner">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
            </div>
            <span class="text-sm font-semibold text-gray-500 uppercase tracking-wider">{{ t('auto_doanh_thu_t_ng', 'Tổng Doanh Thu') }}</span>
          </div>
          <div class="text-3xl font-black text-gray-900">{{ formatCurrency(stats.totalRevenue) }}</div>
          <p class="text-xs text-green-600 font-medium mt-2 flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 7-7 7 7"/><path d="M12 19V5"/></svg>
            {{ t('auto_t_h_a_n', 'Từ hóa đơn') }}
          </p>
        </div>

        <!-- Payments Card -->
        <div class="bg-gradient-to-br from-white to-gray-50 rounded-2xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center gap-4 mb-4">
            <div class="w-12 h-12 rounded-full bg-green-100 text-green-600 flex items-center justify-center shadow-inner">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
            </div>
            <span class="text-sm font-semibold text-gray-500 uppercase tracking-wider">{{ t('auto_t_ng_chi', 'Tổng Chi Trả') }}</span>
          </div>
          <div class="text-3xl font-black text-gray-900">{{ formatCurrency(stats.totalPayments) }}</div>
          <p class="text-xs text-blue-600 font-medium mt-2 flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 7-7 7 7"/><path d="M12 19V5"/></svg>
            {{ t('auto_ph_i_tr_ncc', 'Phí trả NCC') }}
          </p>
        </div>

        <!-- Staff Costs Card -->
        <div class="bg-gradient-to-br from-white to-gray-50 rounded-2xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center gap-4 mb-4">
            <div class="w-12 h-12 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center shadow-inner">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            </div>
            <span class="text-sm font-semibold text-gray-500 uppercase tracking-wider">{{ t('auto_l_ng_nh_n_s_', 'Chi Phí Nhân Sự') }}</span>
          </div>
          <div class="text-3xl font-black text-gray-900">{{ formatCurrency(stats.totalStaffCosts) }}</div>
          <p class="text-xs text-gray-500 font-medium mt-2 flex items-center gap-1">
            {{ t('auto_t_m_t_nh_theo_ca', 'Tạm tính theo ca') }}
          </p>
        </div>

        <!-- Profit Card -->
        <div class="bg-gradient-to-br from-white to-gray-50 rounded-2xl border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center gap-4 mb-4">
            <div class="w-12 h-12 rounded-full flex items-center justify-center shadow-inner" :class="stats.profit >= 0 ? 'bg-emerald-100 text-emerald-600' : 'bg-red-100 text-red-600'">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            </div>
            <span class="text-sm font-semibold text-gray-500 uppercase tracking-wider">{{ t('auto_l_i_nhu_n', 'Lợi Nhuận Ước Tính') }}</span>
          </div>
          <div class="text-3xl font-black text-gray-900" :class="stats.profit >= 0 ? 'text-green-600' : 'text-red-600'">
            {{ formatCurrency(stats.profit) }}
          </div>
          <p class="text-xs font-medium mt-2 flex items-center gap-1" :class="stats.profit >= 0 ? 'text-green-600' : 'text-red-600'">
            {{ t('auto_doanh_thu_chi_ph_', 'Doanh thu - Chi phí') }}
          </p>
        </div>
      </div>

      <!-- Recent Audit Logs -->
      <div class="bg-white border border-gray-200 rounded-3xl shadow-sm overflow-hidden mt-8">
        <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <h3 class="font-extrabold text-gray-900 text-lg">{{ t('auto_nh_t_k__ho_t___ng_m_i_nh_t') }}</h3>
          <RouterLink to="/admin/audit" class="text-sm font-bold text-blue-600 hover:text-blue-800 transition-colors bg-blue-50 px-4 py-2 rounded-full">{{ t('auto_xem_t_t_c_') }}</RouterLink>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead class="bg-gray-50/80 text-gray-500 font-semibold border-b">
              <tr>
                <th class="px-6 py-4">Time</th>
                <th class="px-6 py-4">Actor ID</th>
                <th class="px-6 py-4">Action</th>
                <th class="px-6 py-4">IP Address</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="log in auditLogs" :key="log.id" class="hover:bg-gray-50/80 transition-colors">
                <td class="px-6 py-4 text-gray-500">{{ formatDate(log.created_at) }}</td>
                <td class="px-6 py-4 font-medium text-gray-900">
                  <div class="flex items-center gap-2">
                    <div class="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-600">
                      {{ (log.actor_id || '?').substring(0, 1).toUpperCase() }}
                    </div>
                    {{ log.actor_id ? log.actor_id.substring(0, 8) + '...' : 'System' }}
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {{ log.action }}
                  </span>
                </td>
                <td class="px-6 py-4 text-gray-400 font-mono text-xs">{{ log.ip_address || 'localhost' }}</td>
              </tr>
              <tr v-if="auditLogs.length === 0">
                <td colspan="4" class="px-6 py-8 text-center text-gray-500">
                  No recent audit logs found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { supabase } from '@/lib/supabase';
import type { AuditEvent } from '@/types/database';

const { t } = useI18n();

const isLoading = ref(true);

const stats = ref({
  totalRevenue: 0,
  totalPayments: 0,
  totalStaffCosts: 0,
  profit: 0
});

const auditLogs = ref<AuditEvent[]>([]);

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);
};

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const fetchDashboardData = async () => {
  isLoading.value = true;
  try {
    // 1. Fetch total revenue from paid invoices
    const { data: invoices, error: invoiceError } = await supabase
      .from('invoices')
      .select('total')
      .eq('status', 'paid');
    
    if (invoiceError) throw invoiceError;
    const totalRevenue = invoices?.reduce((sum, inv) => sum + (inv.total || 0), 0) || 0;

    // 2. Fetch total payments
    const { data: payments, error: paymentError } = await supabase
      .from('payments')
      .select('amount');
      
    if (paymentError) throw paymentError;
    const totalPayments = payments?.reduce((sum, pay) => sum + (pay.amount || 0), 0) || 0;

    // 3. Fetch shifts to estimate staff costs (Assuming 500,000 VND per shift as an example)
    const { data: shifts, error: shiftError } = await supabase
      .from('shifts')
      .select('id');
      
    if (shiftError) throw shiftError;
    const SHIFT_COST = 500000;
    const totalStaffCosts = (shifts?.length || 0) * SHIFT_COST;

    // 4. Calculate profit
    const profit = totalRevenue - totalStaffCosts;

    stats.value = {
      totalRevenue,
      totalPayments,
      totalStaffCosts,
      profit
    };

    // 5. Fetch recent audit logs
    const { data: logs, error: logsError } = await supabase
      .from('audit_events')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
      
    if (logsError) throw logsError;
    auditLogs.value = logs as AuditEvent[];

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchDashboardData();
});
</script>

