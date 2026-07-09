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
      <button 
        class="py-2 px-6 font-medium text-sm border-b-2 transition-colors"
        :class="activeTab === 'flowchart' ? 'border-[#C9A85C] text-[#C9A85C]' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'flowchart'"
      >
        {{ langStore.t('integration.diagrams') }}
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

      
      <!-- Flowchart / Diagram Viewer -->
      <template v-else-if="activeTab === 'flowchart'">
        <div class="col-span-1 md:col-span-2 flex justify-center mb-4">
          <div class="bg-gray-100 p-1 rounded-lg inline-flex">
            <button 
              @click="diagramType = 'role'" 
              :class="diagramType === 'role' ? 'bg-white shadow-sm text-gray-800' : 'text-gray-500 hover:text-gray-700'"
              class="px-4 py-2 text-sm font-medium rounded-md transition-all"
            >
              {{ langStore.t('integration.role_diagram') }}
            </button>
            <button 
              @click="diagramType = 'dataflow'" 
              :class="diagramType === 'dataflow' ? 'bg-white shadow-sm text-gray-800' : 'text-gray-500 hover:text-gray-700'"
              class="px-4 py-2 text-sm font-medium rounded-md transition-all"
            >
              {{ langStore.t('integration.dataflow_diagram') }}
            </button>
          </div>
        </div>

        <div class="col-span-1 md:col-span-2 h-[700px] flex flex-col bg-white border border-gray-100 rounded-xl p-4 shadow-sm relative overflow-hidden">
          <template v-if="diagramType === 'role'">
            <div class="flex justify-between items-center mb-4 z-10">
              <h3 class="font-bold text-lg text-gray-800">{{ DIAGRAMS[currentDiagramId]?.title }}</h3>
              <button 
                v-if="currentDiagramId !== 'root'"
                @click="currentDiagramId = 'root'"
                class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
              >
                {{ langStore.t('integration.back_to_main_diagram') }}
              </button>
            </div>
            <div class="flex-1 w-full relative">
              <MermaidViewer 
                v-if="DIAGRAMS[currentDiagramId]"
                :id="'diagram-' + currentDiagramId"
                :code="DIAGRAMS[currentDiagramId].code"
                @node-click="handleNodeClick"
              />
            </div>
          </template>
          
          <template v-else>
            <div class="flex-1 w-full relative">
              <SvgZoomViewer src="/dataflow.svg" />
            </div>
          </template>
        </div>
      </template>

      <!-- Delivery Providers -->
      <template v-else-if="activeTab === 'delivery'">
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
import { ref, onMounted, reactive, computed } from 'vue'
import MermaidViewer from '@/components/MermaidViewer.vue'
import SvgZoomViewer from '@/components/SvgZoomViewer.vue'
import { useIntegrations } from '@/composables/useIntegrations'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'

const langStore = useLanguageStore()
const { activeBranchId } = useBranch()
const { isFetching, fetchAllIntegrations, savePaymentConfig, saveDeliveryConfig, testPaymentConnection, toggleIntegration } = useIntegrations()


const activeTab = ref<'payment' | 'delivery' | 'flowchart'>('payment')

const currentDiagramId = ref<string>('root')
const diagramType = ref<'role'|'dataflow'>('role')

const DIAGRAMS: Record<string, { title: string, code: string }> = {
  root: {
    title: 'Mindmap Tổng Quát',
    code: `mindmap
  root((Hệ Thống Ngưu Cát ERP<br/>システム Ngưu Cát ERP))
    (Khối Giám Đốc & Quản Trị<br/>役員・管理ブロック)
      node_bod[BOD - Phân tích chiến lược & KPI<br/>戦略分析・KPI]
      node_superadmin[Superadmin - Quản trị toàn hệ thống<br/>システム全体管理]
    (Khối Tiếp Thị & Chăm Sóc<br/>マーケティング・顧客ケア)
      node_marketing[Marketing - Phân tích chiến dịch & CPA<br/>キャンペーン分析・CPA]
      node_crm[CRM - Quản lý Voucher & Thành viên<br/>バウチャー・会員管理]
    (Khối Tiền Sảnh - Hall<br/>ホール・フロント)
      node_manager[Quản lý Chi nhánh - Điều hành ca<br/>支店長 - シフト運営]
      node_reception[Lễ Tân - Xếp bàn & Đón khách<br/>受付 - 席割り・接客]
      node_staff[Phục vụ - Order & Chăm sóc<br/>ホールスタッフ - 注文・ケア]
      node_tablet[Tablet - Self-order tại bàn<br/>タブレット - セルフオーダー]
    (Khối Bếp & Cung Ứng<br/>厨房・サプライ)
      node_kitchen[Bếp - Chế biến & Quản lý món<br/>厨房 - 調理・メニュー管理]
      node_procurement[Thu Mua - Nhập hàng & Tồn kho<br/>購買 - 仕入れ・在庫]
    (Khối Tài Chính<br/>財務ブロック)
      node_accounting[Kế toán - Doanh thu & Chi phí<br/>経理 - 売上・経費]
`
  },
  node_crm: {
    title: 'Hành trình Khách hàng & CRM',
    code: `flowchart TD
        %% --- Định nghĩa Style ---
        style CustomerFlow fill:#ffffff,stroke:#ff9900,stroke-width:2px,stroke-dasharray:5 5
        style HALL fill:#fff2cc,stroke:#333,stroke-width:2px
        style KITCHEN fill:#e2f0d9,stroke:#333,stroke-width:2px
        style CRM_MKT fill:#f9d0c4,stroke:#333,stroke-width:2px
        style DEVICES fill:#f2f2f2,stroke:#666,stroke-width:2px

        %% --- 1. KHỐI TIỀN SẢNH (HALL) ---
        subgraph HALL [Khối Tiền Sảnh - Hall<br/>ホール・フロント]
            R[Lễ Tân / Thu Ngân<br/>受付・レジ]
            S[Nhân viên Phục vụ<br/>ホールスタッフ]
        end

        %% --- 2. HÀNH TRÌNH KHÁCH HÀNG ---
        subgraph CustomerFlow [Hành trình Khách hàng<br/>カスタマージャーニー]
            C1([Khách hàng vào quán<br/>お客様が来店])
            C2(Xem Menu giấy<br/>紙のメニューを見る)
            C3(Khách ngồi tại bàn<br/>席に着く)
            C4([Khách đang dùng bữa<br/>食事中])
            C5([Khách xuống quầy Thanh toán<br/>レジへ支払いに行く])
        end

        %% --- 3. HỆ THỐNG & THIẾT BỊ ---
        subgraph DEVICES [Thiết bị & Hệ thống ERP<br/>デバイス・ERPシステム]
            DB[(Hệ thống Database Ngưu Cát<br/>データベースシステム)]
            TAB["Máy tính bảng Tablet<br/>タブレット<br/><i>(Đã định danh Account Bàn)</i>"]
            PRN[[Máy in ZyWell ZY-Q822<br/>プリンター]]
        end

        %% --- 4. KHỐI BẾP ---
        subgraph KITCHEN [Khối Bếp<br/>厨房]
            K[Đầu Bếp / Bếp trưởng<br/>シェフ・料理長]
        end

        %% --- 5. KHỐI CRM ---
        subgraph CRM_MKT [Khối CRM<br/>CRMブロック]
            CRM_STAFF[Nhân viên CRM<br/>CRMスタッフ]
        end

        %% ==========================================
        %% CÁC BƯỚC NGHIỆP VỤ (FLOW)
        %% ==========================================

        %% Bước Đón khách & Chọn hình thức
        C1 -->|1. Đón khách<br/>1. 接客| R
        R -->|2. Tư vấn & Đưa menu giấy<br/>2. 案内・紙メニューを渡す| C2
        C2 -->|3. Chọn Buffet / Alacarte<br/>3. ビュッフェ・アラカルトを選択| R

        %% Bước Mở bàn & Định danh
        R ==>|4. Mở bàn & Cài đặt thông số<br/>4. テーブルを開く・設定| DB
        DB -.->|5. Đồng bộ Session<br/>5. セッション同期| TAB
        R -->|6. Điều phối<br/>6. コーディネート| S
        S -->|7. Dẫn khách lên bàn<br/>7. お客様を席へ案内| C3

        %% Bước Khách tự Order
        C3 -->|8. Khách thao tác chạm chọn món<br/>8. お客様が料理を選ぶ| TAB
        TAB ==>|9. Gửi Data Order lên Cloud<br/>9. クラウドへ注文データを送信| DB
        DB ==>|10. Truyền lệnh In Server<br/>10. サーバーから印刷コマンドを送信| PRN
        PRN -.->|11. In phiếu Order giấy<br/>11. 紙の注文票を印刷| K

        %% Bước Phục vụ
        K -->|12. Nấu xong & Kẹp phiếu In<br/>12. 調理完了・注文票を添付| S
        S -->|13. Bưng món + Phiếu Order lên bàn<br/>13. 料理と注文票を席へ運ぶ| C4

        %% Bước CRM thu thập data
        C4 -.->|14. Trong lúc khách ăn<br/>14. お客様が食事中| CRM_STAFF
        CRM_STAFF -->|15. Trò chuyện & Xin thông tin<br/>15. 会話・情報収集| C4
        CRM_STAFF ==>|16. Nhập Data Khách - SĐT, Sinh nhật<br/>16. 顧客データを入力| DB

        %% Bước Check-out
        C4 -->|17. Khách dùng bữa xong<br/>17. 食事終了| C5
        C5 -->|18. Đi xuống quầy yêu cầu tính tiền<br/>18. レジで支払いを求める| R
        R ==>|19. Chọn đúng Bàn & Nhấn Check-out<br/>19. テーブルを選び、チェックアウト| DB
        DB -.->|20. Giải phóng Bàn & Sinh Hóa đơn<br/>20. テーブルを解放し、請求書を発行| R
        R -->|21. Thu tiền & Đưa hóa đơn<br/>21. 支払いを受け取り、領収書を渡す| C5`
  }
}

function handleNodeClick(nodeId: string) {
  console.log("Clicked node:", nodeId)
  const cleanId = nodeId.replace(/^mindmap-node-/, '')
  
  if (DIAGRAMS[cleanId]) {
    currentDiagramId.value = cleanId
  }
}

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
