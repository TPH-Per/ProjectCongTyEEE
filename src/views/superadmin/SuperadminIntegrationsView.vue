<template>
  <div class="space-y-6 max-w-4xl mx-auto">

    <div>
      <h2 class="text-2xl font-bold text-gray-800 mb-2">{{ t('auto_t_ch_h_p_h__th_ng__api___erp_') }}</h2>
      <p class="text-sm text-gray-500">{{ t('auto_c_u_h_nh_k_t_n_i_v_i_c_c___i_t') }}</p>
    </div>

    <!-- MISA Kế toán -->
    <div class="kawaii-card bg-white p-6">
      <div class="flex items-start justify-between mb-6">
        <div class="flex items-center">
          <div class="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center mr-4">
            <span class="font-bold text-blue-600 text-lg">MISA</span>
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-800">MISA SME / AMIS</h3>
            <p class="text-sm text-gray-500">{{ t('auto___ng_b__doanh_thu__phi_u_thu_c') }}</p>
          </div>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" v-model="integrations.misa.enabled" class="sr-only peer">
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#FF7B89]"></div>
        </label>
      </div>

      <div v-if="integrations.misa.enabled" class="space-y-4 pt-4 border-t border-gray-100">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">API Endpoint URL</label>
          <input type="text" v-model="integrations.misa.apiUrl" class="kawaii-input w-full" placeholder="https://api.misa.com.vn/..." />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">App ID</label>
            <input type="text" v-model="integrations.misa.appId" class="kawaii-input w-full" :placeholder="$t('auto_placeholder_fix', 'Nhập App ID')" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Secret Key</label>
            <div class="relative">
              <input :type="showMisaSecret ? 'text' : 'password'" v-model="integrations.misa.secretKey" class="kawaii-input w-full pr-10" placeholder="••••••••••••" />
              <button @click="showMisaSecret = !showMisaSecret" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <EyeIcon v-if="!showMisaSecret" class="w-4 h-4" />
                <EyeOffIcon v-else class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
        <div class="flex justify-end pt-2">
          <button class="kawaii-btn-ghost mr-2">{{ t('auto_ki_m_tra_k_t_n_i') }}</button>
          <button class="kawaii-btn-primary">{{ t('auto_l_u_c_u_h_nh') }}</button>
        </div>
      </div>
    </div>

    <!-- KiotViet Kho -->
    <div class="kawaii-card bg-white p-6">
      <div class="flex items-start justify-between mb-6">
        <div class="flex items-center">
          <div class="w-12 h-12 rounded-xl bg-green-50 flex items-center justify-center mr-4">
            <span class="font-bold text-green-600 text-lg">KV</span>
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-800">{{ t('auto_kiotviet_qu_n_l__kho') }}</h3>
            <p class="text-sm text-gray-500">{{ t('auto___ng_b__tr__kho_nguy_n_v_t_li_') }}</p>
          </div>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" v-model="integrations.kiotviet.enabled" class="sr-only peer">
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#FF7B89]"></div>
        </label>
      </div>

      <div v-if="integrations.kiotviet.enabled" class="space-y-4 pt-4 border-t border-gray-100">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Client ID</label>
            <input type="text" class="kawaii-input w-full" :placeholder="$t('auto_placeholder_fix', 'Nhập Client ID')" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Client Secret</label>
            <input type="password" class="kawaii-input w-full" placeholder="••••••••••••" />
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('auto_webhook_url__nh_n_th_ng_b_o_c_') }}</label>
          <div class="flex">
            <input type="text" readonly value="https://api.nguucat.vn/webhooks/kiotviet" class="kawaii-input w-full bg-gray-50 rounded-r-none border-r-0 text-gray-500" />
            <button class="px-4 bg-gray-100 border border-gray-200 rounded-r-xl hover:bg-gray-200 transition-colors">
              <CopyIcon class="w-4 h-4 text-gray-600" />
            </button>
          </div>
        </div>
        <div class="flex justify-end pt-2">
          <button class="kawaii-btn-ghost mr-2">{{ t('auto_ki_m_tra_k_t_n_i') }}</button>
          <button class="kawaii-btn-primary">{{ t('auto_l_u_c_u_h_nh') }}</button>
        </div>
      </div>
    </div>
    
    <!-- BaseHR -->
    <div class="kawaii-card bg-white p-6">
      <div class="flex items-start justify-between mb-6">
        <div class="flex items-center">
          <div class="w-12 h-12 rounded-xl bg-purple-50 flex items-center justify-center mr-4">
            <span class="font-bold text-purple-600 text-lg">Base</span>
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-800">Base HRM / Base Payroll</h3>
            <p class="text-sm text-gray-500">{{ t('auto___ng_b__nh_n_vi_n__ca_l_m_vi_c') }}</p>
          </div>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" v-model="integrations.basehr.enabled" class="sr-only peer">
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#FF7B89]"></div>
        </label>
      </div>
      
      <div v-if="integrations.basehr.enabled" class="space-y-4 pt-4 border-t border-gray-100">
         <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Access Token</label>
          <input type="password" class="kawaii-input w-full" :placeholder="$t('auto_placeholder_fix', 'Nhập mã Access Token từ Base.vn')" />
        </div>
        <div class="flex justify-end pt-2">
          <button class="kawaii-btn-primary">{{ t('auto_l_u_c_u_h_nh') }}</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, reactive } from 'vue'
import { EyeIcon, EyeOffIcon, CopyIcon } from 'lucide-vue-next'

const showMisaSecret = ref(false)

const integrations = reactive({
  misa: {
    enabled: true,
    apiUrl: 'https://actapp.misa.vn/api/v1',
    appId: 'nguucat_portal',
    secretKey: 'sk_test_123456789'
  },
  kiotviet: {
    enabled: false
  },
  basehr: {
    enabled: false
  }
})
</script>

