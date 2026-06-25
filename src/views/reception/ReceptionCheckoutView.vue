<template>
  <div>

    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/reception/dashboard" class="w-10 h-10 rounded-xl bg-white border flex items-center justify-center text-gray-600 hover:bg-gray-50 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </RouterLink>
      <div>
        <h2 class="text-2xl font-bold text-gray-900">{{ t('auto_thanh_to_n__b_n_t2_a1', { table_name: tableInfo?.name || route.params.id }) }}</h2>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          <p class="text-sm text-red-600 font-bold">{{ orderInfo ? 'Sẵn sàng thanh toán' : 'Đang tải...' }}</p>
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
            <input v-model="customerPhone" type="text" :placeholder="t('auto_nh_p_s_i_n_tho_i_kh_ch_h_ng', 'Nhập số điện thoại khách hàng...')" class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold" />
            <button @click="findCustomer" class="bg-gray-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-black transition-colors">
              {{ t('auto_tra_c_u', 'Tra Cứu') }}
            </button>
          </div>
          <!-- Member Found State -->
          <div v-if="customerInfo" class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4">
            <div class="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl shrink-0">
              V
            </div>
            <div class="flex-1">
              <div class="flex justify-between items-start">
                <div>
                  <h4 class="font-bold text-gray-900 text-lg">{{ customerInfo.full_name }}</h4>
                  <div class="text-sm text-gray-600 mb-2">SĐT: {{ customerInfo.phone }}</div>
                </div>
                <div class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-bold border border-red-200">
                  {{ t('auto_th_nh_vi_n', 'Thành Viên') }}
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
              </select>
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-2">{{ t('auto_nh_p_qu_t_m__voucher') }}</label>
              <div class="flex gap-2">
                <input v-model="voucherCode" type="text" placeholder="VD: TET2024..." class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 uppercase font-semibold text-gray-900" />
                <button @click="applyVoucher" class="bg-gray-200 text-gray-700 px-4 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors shrink-0">
                  {{ t('auto_p_d_ng', 'Áp Dụng') }}
                </button>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Right Column: Bill Summary -->
      <div class="bg-white border rounded-2xl p-0 shadow-sm flex flex-col overflow-hidden">
        <div class="p-6 border-b bg-gray-50">
          <h3 class="text-lg font-bold text-gray-900">{{ t('auto_t_ng_k_t_h_a___n') }}</h3>
          <p class="text-sm text-gray-500">{{ tableInfo?.name }} - {{ orderInfo?.guests_count || 1 }} khách</p>
        </div>
        
        <div class="p-6 flex-1 overflow-y-auto">
          <div class="space-y-3 mb-6">
            <div v-for="item in orderItems" :key="item.id" class="flex justify-between items-center border-b pb-2">
              <span class="font-bold text-gray-700">{{ item.quantity }} x {{ item.name_snapshot }}</span>
              <span class="font-bold text-gray-900">{{ (item.unit_price * item.quantity).toLocaleString('vi-VN') }}đ</span>
            </div>
            <div v-if="orderItems.length === 0" class="text-center text-gray-500">{{ t('auto_ch_a_c_m_n_n_o', 'Chưa có món nào') }}</div>
          </div>

          <div class="space-y-3 pt-4 border-t" v-if="orderItems.length > 0">
            <div class="flex justify-between items-center">
              <span class="text-gray-500">{{ t('auto_t_m_t_nh') }}</span>
              <span class="font-semibold text-gray-900">{{ subTotal.toLocaleString('vi-VN') }}đ</span>
            </div>
            <div class="flex justify-between items-center text-green-600" v-if="discount > 0">
              <span class="font-bold">{{ t('auto_gi_m_gi', 'Giảm giá') }}</span>
              <span class="font-bold">-{{ discount.toLocaleString('vi-VN') }}đ</span>
            </div>
            <div class="flex justify-between items-center text-gray-500">
              <span>VAT (8%)</span>
              <span>{{ vat.toLocaleString('vi-VN') }}đ</span>
            </div>
          </div>
        </div>

        <div class="p-6 bg-gray-50 border-t">
          <div class="flex justify-between items-end mb-6">
            <span class="text-gray-700 font-bold">{{ t('auto_th_nh_ti_n') }}</span>
            <span class="text-3xl font-black text-red-600">{{ totalAmount.toLocaleString('vi-VN') }}đ</span>
          </div>
          
          <button @click="handleCheckout" :disabled="loading || !orderInfo || orderItems.length === 0" class="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-xl shadow-lg transition-colors text-lg flex items-center justify-center gap-2 mb-3 disabled:opacity-50">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect width="12" height="8" x="6" y="14"/></svg>
            {{ loading ? 'Đang xử lý...' : 'In Hóa Đơn & Đóng Bàn' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2';
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useCheckout } from '@/composables/useCheckout'
import type { AppUser } from '@/types/database'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { checkout, loading } = useCheckout()

const tableId = route.params.id as string
const tableInfo = ref<any>(null)
const orderInfo = ref<any>(null)
const orderItems = ref<any[]>([])

const customerPhone = ref('')
const customerInfo = ref<any>(null)
const voucherCode = ref('')
const discount = ref(0)

const subTotal = computed(() => orderItems.value.reduce((acc, item) => acc + (item.unit_price * item.quantity), 0))
const vat = computed(() => Math.round(subTotal.value * 0.08))
const totalAmount = computed(() => subTotal.value + vat.value - discount.value)

onMounted(async () => {
  // 1. Fetch table info
  const { data: tableData } = await supabase.from('tables').select('*').eq('id', tableId).single()
  tableInfo.value = tableData

  // 2. Fetch active order for this table
  const { data: orderData } = await supabase.from('orders')
    .select('*')
    .eq('table_id', tableId)
    .in('status', ['Open', 'Serving'])
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  if (orderData) {
    orderInfo.value = orderData
    // 3. Fetch order items
    const { data: items } = await supabase.from('order_items')
      .select('*')
      .eq('order_id', orderData.id)
    if (items) orderItems.value = items
  }
})

async function findCustomer() {
  if (!customerPhone.value) return
  const { data } = await supabase.from('customers').select('*').eq('phone', customerPhone.value).single()
  if (data) {
    customerInfo.value = data
  } else {
    Swal.fire('Thông báo', 'Không tìm thấy khách hàng!', 'info')
  }
}

async function applyVoucher() {
  if (!voucherCode.value || !orderInfo.value) return
  Swal.fire('Thông báo', 'Đã áp dụng voucher (Mocked)', 'info')
  discount.value = 100000 // Mock 100k discount
}

const handleCheckout = async () => {
  if (!orderInfo.value) return
  
  try {
    await checkout({
      order_id: orderInfo.value.id,
      payments: [{ method: 'cash', amount: totalAmount.value }],
    })
    Swal.fire('Thành công', 'Thanh toán thành công!', 'success')
    router.push('/reception/dashboard')
  } catch (err: any) {
    Swal.fire('Lỗi', 'Lỗi: ' + err.message, 'error')
    console.error('Checkout failed:', err)
  }
}
</script>

