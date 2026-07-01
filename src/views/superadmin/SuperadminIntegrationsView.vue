<template>
  <div class="space-y-6 max-w-5xl mx-auto">
    <div>
      <h2 class="text-2xl font-bold text-gray-800 mb-2">{{ langStore.t('integration.title') }}</h2>
      <p class="text-sm text-gray-500">{{ langStore.t('auto_c_u_h_nh_k_t_n_i_v_i_c_c___i_t') || 'Configure connections to payment and delivery platforms' }}</p>
    </div>

    <!-- Tabs -->
    <div class="flex border-b border-gray-200 mb-6">
      <button 
        class="py-2 px-6 font-medium text-sm border-b-2 transition-colors"
        :class="activeTab === 'payment' ? 'border-[#C9A85C] text-[#C9A85C]' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'payment'"
      >
        {{ langStore.t('integration.payment') }}
      </button>
      <button 
        class="py-2 px-6 font-medium text-sm border-b-2 transition-colors"
        :class="activeTab === 'delivery' ? 'border-[#C9A85C] text-[#C9A85C]' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'delivery'"
      >
        {{ langStore.t('integration.delivery') }}
      </button>
    </div>

    <div v-if="isFetching" class="text-gray-500 text-center py-8">
      {{ langStore.t('common.loading') }}
    </div>
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Payment Providers -->
      <template v-if="activeTab === 'payment'">
        <div v-for="provider in paymentProviders" :key="provider" class="kawaii-card bg-white p-6 shadow-sm border border-gray-100 rounded-xl relative overflow-hidden">
          <div class="flex items-start justify-between">
            <div class="flex items-center">
              <div class="w-12 h-12 rounded-xl bg-gray-50 flex items-center justify-center mr-4 border border-gray-200">
                <span class="font-bold text-gray-600 text-sm">{{ provider }}</span>
              </div>
              <div>
                <h3 class="text-lg font-bold text-gray-800">{{ provider }}</h3>
                <span :class="isPaymentEnabled(provider) ? 'text-green-600 bg-green-50' : 'text-gray-500 bg-gray-100'" class="px-2 py-0.5 text-xs rounded-full mt-1 inline-block">
                  {{ isPaymentEnabled(provider) ? 'Enabled' : 'Disabled' }}
                </span>
              </div>
            </div>
            <button @click="openPaymentConfig(provider)" class="text-sm font-medium text-[#C9A85C] hover:text-[#8A6E30] transition-colors">
              Configure
            </button>
          </div>
        </div>
      </template>

      <!-- Delivery Providers -->
      <template v-else>
        <div v-for="provider in deliveryProviders" :key="provider" class="kawaii-card bg-white p-6 shadow-sm border border-gray-100 rounded-xl relative overflow-hidden">
          <div class="flex items-start justify-between">
            <div class="flex items-center">
              <div class="w-12 h-12 rounded-xl bg-gray-50 flex items-center justify-center mr-4 border border-gray-200">
                <span class="font-bold text-gray-600 text-sm">{{ provider }}</span>
              </div>
              <div>
                <h3 class="text-lg font-bold text-gray-800">{{ provider }}</h3>
                <span :class="isDeliveryEnabled(provider) ? 'text-green-600 bg-green-50' : 'text-gray-500 bg-gray-100'" class="px-2 py-0.5 text-xs rounded-full mt-1 inline-block">
                  {{ isDeliveryEnabled(provider) ? 'Enabled' : 'Disabled' }}
                </span>
              </div>
            </div>
            <button @click="openDeliveryConfig(provider)" class="text-sm font-medium text-[#C9A85C] hover:text-[#8A6E30] transition-colors">
              Configure
            </button>
          </div>
        </div>
      </template>
    </div>

    <!-- Side Panel -->
    <div v-if="editingProvider" class="fixed inset-0 z-50 flex justify-end">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-black bg-opacity-50 transition-opacity" @click="closePanel"></div>
      
      <!-- Panel -->
      <div class="relative w-full max-w-md bg-[#1A1815] text-[#F0EBE2] h-full shadow-2xl flex flex-col transform transition-transform">
        <div class="p-6 border-b border-[#3A332A] flex justify-between items-center">
          <h3 class="text-xl font-serif text-[#C9A85C]">Configure {{ editingProvider }}</h3>
          <button @click="closePanel" class="text-[#9B8E80] hover:text-white transition-colors">✕</button>
        </div>
        
        <div class="p-6 flex-1 overflow-y-auto space-y-6">
          <!-- Enable Toggle -->
          <div class="flex items-center justify-between pb-4 border-b border-[#3A332A]">
            <span class="text-sm font-medium">Enable Integration</span>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="editForm.isEnabled" class="sr-only peer">
              <div class="w-11 h-6 bg-[#3A332A] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E8B6A]"></div>
            </label>
          </div>

          <!-- Configuration Fields -->
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1">{{ langStore.t('integration.api_key') }}</label>
              <input type="password" v-model="editForm.apiKey" class="w-full bg-[#241F1A] border border-[#3A332A] rounded-lg px-4 py-2 text-[#F0EBE2] focus:outline-none focus:border-[#C9A85C] transition-colors" placeholder="••••••••" />
            </div>
            
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1">Secret Key</label>
              <input type="password" v-model="editForm.secretKey" class="w-full bg-[#241F1A] border border-[#3A332A] rounded-lg px-4 py-2 text-[#F0EBE2] focus:outline-none focus:border-[#C9A85C] transition-colors" placeholder="••••••••" />
            </div>
            
            <div v-if="editingType === 'payment'">
              <label class="block text-sm font-medium text-[#9B8E80] mb-1">Merchant ID (Optional)</label>
              <input type="text" v-model="editForm.merchantId" class="w-full bg-[#241F1A] border border-[#3A332A] rounded-lg px-4 py-2 text-[#F0EBE2] focus:outline-none focus:border-[#C9A85C] transition-colors" />
            </div>
            
            <div v-if="editingType === 'delivery'">
              <label class="block text-sm font-medium text-[#9B8E80] mb-1">Store ID</label>
              <input type="text" v-model="editForm.storeId" class="w-full bg-[#241F1A] border border-[#3A332A] rounded-lg px-4 py-2 text-[#F0EBE2] focus:outline-none focus:border-[#C9A85C] transition-colors" />
            </div>
            
            <div>
              <label class="block text-sm font-medium text-[#9B8E80] mb-1">{{ langStore.t('integration.webhook') }}</label>
              <div class="flex">
                <input type="text" v-model="editForm.webhookUrl" class="w-full bg-[#241F1A] border border-[#3A332A] rounded-l-lg px-4 py-2 text-[#5A4E43]" readonly />
                <button @click="copyWebhook" class="px-3 bg-[#3A332A] text-[#F0EBE2] border-y border-r border-[#3A332A] rounded-r-lg hover:bg-[#4A433A] transition-colors" title="Copy Webhook URL">
                  <span class="font-mono text-xs">COPY</span>
                </button>
              </div>
            </div>
          </div>
          
          <div v-if="testResult" :class="testResult.success ? 'bg-[#3E8B6A]/10 text-[#3E8B6A] border-[#3E8B6A]/30' : 'bg-[#B93333]/10 text-[#B93333] border-[#B93333]/30'" class="px-4 py-3 text-sm font-medium rounded-lg border">
            {{ testResult.message }}
          </div>
        </div>

        <div class="p-6 border-t border-[#3A332A] flex justify-between bg-[#0C0B0A] items-center">
          <button v-if="editingType === 'payment'" @click="runTestConnection" class="px-4 py-2 bg-[#241F1A] text-[#F0EBE2] border border-[#3A332A] rounded-lg hover:bg-[#3A332A] font-medium transition-colors text-sm">
            {{ langStore.t('integration.test_connection') }}
          </button>
          <div v-else></div>
          <div class="flex gap-3">
            <button @click="closePanel" class="px-4 py-2 text-[#9B8E80] hover:text-[#F0EBE2] font-medium transition-colors text-sm">
              {{ langStore.t('common.cancel') }}
            </button>
            <button @click="saveConfig" :disabled="isSaving" class="px-6 py-2 bg-[#C9A85C] text-[#0C0B0A] rounded-lg font-bold hover:bg-[#8A6E30] transition-colors disabled:opacity-50 text-sm">
              {{ isSaving ? langStore.t('common.loading') : langStore.t('common.save') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { useIntegrations } from '@/composables/useIntegrations'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'

const langStore = useLanguageStore()
const { activeBranchId } = useBranch()
const { isFetching, fetchAllIntegrations, savePaymentConfig, saveDeliveryConfig, testPaymentConnection, toggleIntegration } = useIntegrations()

const activeTab = ref<'payment' | 'delivery'>('payment')
const paymentProviders = ['ZALOPAY', 'MOMO', 'VNPAY', 'CARD', 'CASH']
const deliveryProviders = ['GRAB', 'SHOPEEFOOD', 'BAEMIN', 'MANUAL']

const paymentIntegrations = ref<any[]>([])
const deliveryIntegrations = ref<any[]>([])

const editingProvider = ref<string | null>(null)
const editingType = ref<'payment' | 'delivery' | null>(null)
const isSaving = ref(false)

const editForm = reactive({
  isEnabled: false,
  apiKey: '',
  secretKey: '',
  merchantId: '',
  storeId: '',
  webhookUrl: ''
})
const testResult = ref<{success: boolean, message: string} | null>(null)

onMounted(async () => {
  await loadData()
})

async function loadData() {
  const branchId = activeBranchId.value ?? throwBranchGuard()
  try {
    const res = await fetchAllIntegrations(branchId)
    paymentIntegrations.value = res.payments || []
    deliveryIntegrations.value = res.deliveries || []
  } catch (error) {
    console.error('Failed to load integrations', error)
  }
}

function isPaymentEnabled(provider: string) {
  const integration = paymentIntegrations.value.find(i => i.provider === provider)
  return integration?.is_enabled || false
}

function isDeliveryEnabled(provider: string) {
  const integration = deliveryIntegrations.value.find(i => i.provider === provider)
  return integration?.is_enabled || false
}

function openPaymentConfig(provider: string) {
  const integration = paymentIntegrations.value.find(i => i.provider === provider)
  editingProvider.value = provider
  editingType.value = 'payment'
  testResult.value = null
  
  editForm.isEnabled = integration?.is_enabled || false
  editForm.apiKey = integration?.config?.api_key || ''
  editForm.secretKey = integration?.config?.secret_key || ''
  editForm.merchantId = integration?.config?.merchant_id || ''
  editForm.storeId = ''
  editForm.webhookUrl = integration?.webhook_url || `${window.location.origin}/api/webhooks/payment/${provider.toLowerCase()}`
}

function openDeliveryConfig(provider: string) {
  const integration = deliveryIntegrations.value.find(i => i.provider === provider)
  editingProvider.value = provider
  editingType.value = 'delivery'
  testResult.value = null
  
  editForm.isEnabled = integration?.is_enabled || false
  editForm.apiKey = integration?.config?.api_key || ''
  editForm.secretKey = integration?.config?.secret_key || ''
  editForm.merchantId = ''
  editForm.storeId = integration?.store_id || ''
  editForm.webhookUrl = integration?.webhook_url || `${window.location.origin}/api/webhooks/delivery/${provider.toLowerCase()}`
}

function closePanel() {
  editingProvider.value = null
  editingType.value = null
}

async function copyWebhook() {
  try {
    await navigator.clipboard.writeText(editForm.webhookUrl)
    alert(langStore.t('common.success'))
  } catch (e) {
    console.error('Failed to copy', e)
  }
}

async function runTestConnection() {
  const branchId = activeBranchId.value ?? throwBranchGuard()
  if (!editingProvider.value) return;
  
  isSaving.value = true
  try {
    const success = await testPaymentConnection(branchId, editingProvider.value)
    if (success) {
      testResult.value = { success: true, message: langStore.t('common.success') }
    } else {
      testResult.value = { success: false, message: langStore.t('common.error') }
    }
  } catch (error) {
    testResult.value = { success: false, message: langStore.t('common.error') }
  } finally {
    isSaving.value = false
  }
}

async function saveConfig() {
  const branchId = activeBranchId.value ?? throwBranchGuard()
  if (!editingProvider.value || !editingType.value) return;
  
  isSaving.value = true
  try {
    if (editingType.value === 'payment') {
      await savePaymentConfig(
        branchId,
        editingProvider.value,
        {
          api_key: editForm.apiKey,
          secret_key: editForm.secretKey,
          merchant_id: editForm.merchantId
        },
        editForm.webhookUrl
      )
      await toggleIntegration(branchId, editingProvider.value, 'payment', editForm.isEnabled)
    } else {
      await saveDeliveryConfig(
        branchId,
        editingProvider.value,
        {
          api_key: editForm.apiKey,
          secret_key: editForm.secretKey
        },
        editForm.webhookUrl,
        editForm.storeId
      )
      await toggleIntegration(branchId, editingProvider.value, 'delivery', editForm.isEnabled)
    }
    
    await loadData()
    closePanel()
  } catch (error) {
    console.error('Failed to save integration config', error)
    alert(langStore.t('common.error'))
  } finally {
    isSaving.value = false
  }
}
</script>
