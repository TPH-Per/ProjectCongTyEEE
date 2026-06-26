<template>
  <div class="p-4 flex flex-col min-h-full">

    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/staff/active-tables" class="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-600">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </RouterLink>
      <div>
        <h2 class="text-xl font-bold text-gray-900">{{ tableInfo?.name || t('auto_b_n__t1_a4') }}</h2>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          <p class="text-xs text-red-600 font-bold">{{ t('auto__ang_d_ng_b_a') }}</p>
        </div>
      </div>
    </div>

    <!-- Order Summary -->
    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-200 mb-4" v-if="orderInfo">
      <div class="flex justify-between items-center mb-2">
        <div class="text-sm font-bold text-gray-800">{{ t('auto_g_i_hi_n_t_i') }}</div>
        <button class="text-xs text-blue-600 font-bold">{{ t('auto_s_a') }}</button>
      </div>
      <div class="text-sm font-medium text-gray-600">{{ $t('auto_khach', 'Khách:') }} {{ orderInfo.guests_count }} {{ $t('auto_nguoi', 'người') }}</div>
      <div class="text-xs text-gray-500 mt-1">Order ID: {{ orderInfo.id.substring(0,8) }}</div>
    </div>

    <!-- In-Dining CRM -->
    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-200 mb-4 flex-1">
      <div class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
        {{ t('auto_crm_t_i_b_n_in_dining', 'CRM Tại Bàn (In-Dining)') }}
      </div>
      
      <div class="space-y-5">
        <div>
          <label class="text-xs text-gray-500 font-bold block mb-2">{{ t('auto_k_nh_marketing__kh_ch_bi_t_qua') }}</label>
          <select v-model="form.marketing_channel" class="w-full h-12 bg-gray-50 border border-gray-200 rounded-xl px-3 text-sm font-semibold text-gray-900">
            <option value="" disabled selected>{{ t('auto_ch_n_k_nh___') }}</option>
            <option value="facebook">Facebook Ads</option>
            <option value="tiktok">Tiktok Reviewer</option>
            <option value="friend">{{ t('auto_ng__i_quen_gi_i_thi_u') }}</option>
            <option value="walkin">{{ t('auto__i_ngang_qua') }}</option>
            <option value="google">Google Map</option>
          </select>
        </div>

        <div>
          <label class="text-xs text-gray-500 font-bold block mb-2">{{ t('auto_xin_ph_p_truy_n_th_ng__photo_v') }}</label>
          <div class="flex items-center gap-4 bg-gray-50 p-3 rounded-xl border border-gray-200">
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="radio" value="yes" v-model="form.media_consent" class="text-red-600 accent-red-600 w-4 h-4" />
              <span class="text-sm font-medium">{{ t('auto___ng__') }}</span>
            </label>
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="radio" value="no" v-model="form.media_consent" class="text-red-600 accent-red-600 w-4 h-4" />
              <span class="text-sm font-medium">{{ t('auto_t__ch_i') }}</span>
            </label>
          </div>
        </div>

        <div>
          <label class="text-xs text-gray-500 font-bold block mb-2">{{ t('auto_qu__t_ng_gi__ch_n__voucher_') }}</label>
          <label class="flex items-center gap-3 p-3 border border-gray-200 bg-gray-50 rounded-xl cursor-pointer">
            <input type="checkbox" v-model="form.given_voucher" class="w-5 h-5 text-red-600 accent-red-600" />
            <span class="text-sm font-bold text-gray-800">{{ t('auto____t_ng_voucher_10__cho_l_n_sa') }}</span>
          </label>
        </div>
      </div>
    </div>

    <button @click="saveCRM" :disabled="saving" class="mt-auto w-full bg-gray-900 hover:bg-black text-white font-bold py-4 rounded-2xl shadow-lg transition-colors text-lg disabled:opacity-50">
      {{ saving ? $t('auto_dang_luu', 'Đang lưu...') : $t('auto_cap_nhat_tt', 'Cập nhật Thông tin') }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()

const tableId = route.params.id as string
const tableInfo = ref<any>(null)
const orderInfo = ref<any>(null)
const saving = ref(false)

const form = ref({
  marketing_channel: '',
  media_consent: '',
  given_voucher: false
})

onMounted(async () => {
  const { data: tData } = await supabase.from('tables').select('*').eq('id', tableId).single()
  tableInfo.value = tData

  const { data: oData } = await supabase.from('orders')
    .select('*')
    .eq('table_id', tableId)
    .in('status', ['Open', 'Serving'])
    .order('created_at', { ascending: false })
    .limit(1)
    .single()
    
  if (oData) {
    orderInfo.value = oData
    if (oData.metadata) {
      form.value.marketing_channel = oData.metadata.marketing_channel || ''
      form.value.media_consent = oData.metadata.media_consent || ''
      form.value.given_voucher = oData.metadata.given_voucher || false
    }
  }
})

async function saveCRM() {
  if (!orderInfo.value) return
  saving.value = true
  const newMeta = {
    ...(orderInfo.value.metadata || {}),
    ...form.value
  }
  
  await supabase.from('orders')
    .update({ metadata: newMeta })
    .eq('id', orderInfo.value.id)
    
  saving.value = false
  router.push('/staff/active-tables')
}
</script>

