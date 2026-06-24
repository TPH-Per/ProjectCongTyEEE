<template>
  <div>
    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/reception/dashboard" class="w-10 h-10 rounded-xl bg-white border flex items-center justify-center text-gray-600 hover:bg-gray-50 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </RouterLink>
      <div>
        <h2 class="text-2xl font-bold text-gray-900">{{ t('auto_thanh_to_n__b_n_t2_a1') }}</h2>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          <p class="text-sm text-red-600 font-bold">{{ t('auto_y_u_c_u_thanh_to_n_l_c_15_20') }}</p>
        </div>
      </div>
    </div>

    <!-- Communication Script -->
    <div class="bg-blue-50 border border-blue-200 rounded-2xl p-5 mb-6 flex gap-4 shadow-sm">
      <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center shrink-0">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-600"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      </div>
      <div>
        <h3 class="text-sm font-bold text-blue-900 mb-1">{{ t('auto_k_ch_b_n_l__t_n__thu_ng_n_h_i_') }}</h3>
        <p class="text-blue-800 font-medium italic">{{ t('auto__d__em_ch_o_anh_ch___h_m_nay_a') }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      <!-- Left Column: CRM & Info -->
      <div class="lg:col-span-2 space-y-6">
        
        <!-- Member Check -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">{{ t('auto_1____nh_danh_kh_ch_h_ng__membe') }}</h3>
          
          <div class="flex gap-3 mb-6">
            <input type="text" placeholder="Nhập số điện thoại khách hàng..." class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold" value="0987654321" />
            <button class="bg-gray-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-black transition-colors">
              Tra Cứu
            </button>
          </div>

          <!-- Member Found State -->
          <div class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4">
            <div class="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl shrink-0">
              V
            </div>
            <div class="flex-1">
              <div class="flex justify-between items-start">
                <div>
                  <h4 class="font-bold text-gray-900 text-lg">{{ t('auto_nguy_n_v_n_a') }}</h4>
                  <div class="text-sm text-gray-600 mb-2">{{ t('auto_s_t__0987654321___zalo_oa_____') }}</div>
                </div>
                <div class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-bold border border-red-200">
                  Khách Quen (Repeater)
                </div>
              </div>
              
              <div class="grid grid-cols-2 gap-4 mt-2">
                <div class="bg-white p-2 rounded border border-green-100">
                  <span class="text-xs text-gray-500 block">{{ t('auto_s__l_n___n') }}</span>
                  <span class="font-bold text-gray-900">{{ t('auto_4_l_n') }}</span>
                </div>
                <div class="bg-white p-2 rounded border border-green-100">
                  <span class="text-xs text-gray-500 block">{{ t('auto__u___i_hi_n_c_') }}</span>
                  <span class="font-bold text-green-600">{{ t('auto_gi_m_10__bill') }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Promo & Revenue Type -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">{{ t('auto_2__ph_n_lo_i_h_a___n___voucher') }}</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-2">{{ t('auto_lo_i_doanh_thu__b_t_bu_c_') }}</label>
              <select class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base font-semibold focus:outline-none focus:border-red-500 text-gray-900 appearance-none">
                <option value="dinner" selected>{{ t('auto_b_a_t_i__dinner_') }}</option>
                <option value="lunch">{{ t('auto_b_a_tr_a__lunch_') }}</option>
                <option value="wine">{{ t('auto_ch__u_ng_r__u_cocktail') }}</option>
                <option value="delivery">{{ t('auto_giao_h_ng__delivery_') }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-2">{{ t('auto_nh_p_qu_t_m__voucher') }}</label>
              <div class="flex gap-2">
                <input type="text" placeholder="VD: TET2024..." class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 uppercase font-semibold text-gray-900" />
                <button class="bg-gray-200 text-gray-700 px-4 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors shrink-0">
                  Áp Dụng
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- In-Dining CRM Data -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">{{ t('auto_3__d__li_u_thu_th_p_t_i_b_n__b') }}</h3>
          <div class="grid grid-cols-2 gap-y-4">
            <div>
              <span class="text-sm text-gray-500 block">{{ t('auto_k_nh_marketing') }}</span>
              <span class="font-bold text-gray-900">{{ t('auto_ng__i_quen_gi_i_thi_u') }}</span>
            </div>
            <div>
              <span class="text-sm text-gray-500 block">{{ t('auto_xin_ph_p_ch_p__nh') }}</span>
              <span class="font-bold text-green-600">{{ t('auto___ng__') }}</span>
            </div>
            <div>
              <span class="text-sm text-gray-500 block">{{ t('auto_tr_ng_th_i_voucher') }}</span>
              <span class="font-bold text-blue-600">{{ t('auto_nv____t_ng_voucher_gi_y_10_') }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Bill Summary -->
      <div class="bg-white border rounded-2xl p-0 shadow-sm flex flex-col overflow-hidden">
        <div class="p-6 border-b bg-gray-50">
          <h3 class="text-lg font-bold text-gray-900">{{ t('auto_t_ng_k_t_h_a___n') }}</h3>
          <p class="text-sm text-gray-500">{{ t('auto_b_n_t2_a1___4_kh_ch') }}</p>
        </div>
        
        <div class="p-6 flex-1 overflow-y-auto">
          <div class="space-y-3 mb-6">
            <div class="flex justify-between items-center">
              <span class="font-bold text-gray-700">4 x Set Biz 1200k</span>
              <span class="font-bold text-gray-900">{{ t('auto_4_800_000_') }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600 pl-4">{{ t('auto_th_n_ngo_i_wagyu__x4_') }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600 pl-4">{{ t('auto_l__i_b__th__ng_h_ng__x2_') }}</span>
            </div>
            <div class="flex justify-between items-center pt-3 border-t border-dashed">
              <span class="font-bold text-gray-700">4 x Drink A</span>
              <span class="font-bold text-gray-900">0đ</span>
            </div>
          </div>

          <div class="space-y-3 pt-4 border-t">
            <div class="flex justify-between items-center">
              <span class="text-gray-500">{{ t('auto_t_m_t_nh') }}</span>
              <span class="font-semibold text-gray-900">{{ t('auto_4_800_000_') }}</span>
            </div>
            <div class="flex justify-between items-center text-green-600">
              <span class="font-bold">{{ t('auto_gi_m_gi__repeater__10__') }}</span>
              <span class="font-bold">{{ t('auto__480_000_') }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-500">
              <span>VAT (8%)</span>
              <span>{{ t('auto_345_600_') }}</span>
            </div>
          </div>
        </div>

        <div class="p-6 bg-gray-50 border-t">
          <div class="flex justify-between items-end mb-6">
            <span class="text-gray-700 font-bold">{{ t('auto_th_nh_ti_n') }}</span>
            <span class="text-3xl font-black text-red-600">{{ t('auto_4_665_600_') }}</span>
          </div>
          
          <button @click="handleCheckout" :disabled="loading" class="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-xl shadow-lg transition-colors text-lg flex items-center justify-center gap-2 mb-3 disabled:opacity-50">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect width="12" height="8" x="6" y="14"/></svg>
            {{ loading ? 'Đang xử lý...' : 'In Hóa Đơn & Đóng Bàn' }}
          </button>

          <p class="text-xs text-center text-gray-500 font-medium">{{ t('auto_nh__nh__kh_ch___nh_gi__google_') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useCheckout } from '@/composables/useCheckout'

const route = useRoute()
const router = useRouter()
const { checkout, loading } = useCheckout()

const handleCheckout = async () => {
  try {
    // In real app, we would fetch the order to get the correct order_id
    // Here we use the table id from the route as a fallback mock
    const orderId = (route.params.id as string) || 'mock-order-id'
    
    await checkout({
      order_id: orderId,
      payments: [{ method: 'cash', amount: 4665600 }],
    })
    router.push('/reception/dashboard')
  } catch (err) {
    console.error('Checkout failed:', err)
  }
}
</script>
