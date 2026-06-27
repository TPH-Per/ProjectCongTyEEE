<!-- KitchenRequisitionView.vue -->
<template>
  <div class="requisition-view min-h-screen flex flex-col bg-[#1A1A1A] text-white">
    <!-- Requisition Header (60px) -->
    <header class="h-[60px] bg-[#1A1A1A] border-b border-[#404040] px-6 flex items-center justify-between">
      <div class="flex items-center gap-4">
        <!-- Logo -->
        <div class="flex items-center gap-2">
          <span class="logo-brand text-[#FF9800] font-extrabold tracking-wider">NGƯU CÁT</span>
          <span class="tag-req bg-gray-800 text-[#FF9800] border border-[#FF9800]/30 text-xs px-2.5 py-0.5 rounded font-bold">KHO</span>
        </div>
        <div class="h-6 w-[1px] bg-[#404040]"></div>
        <span class="text-sm font-bold text-gray-200 uppercase tracking-wide">Yêu cầu xuất kho bếp (Kitchen Requisition)</span>
        <div class="h-6 w-[1px] bg-[#404040]"></div>
        <span class="text-xs text-gray-400 font-bold uppercase">Trạm: Bếp Nướng</span>
      </div>

      <!-- Chef Info & Clock -->
      <div class="flex items-center gap-4 text-sm font-semibold">
        <div class="chef-badge flex items-center gap-2 bg-[#2D2D2D] px-3 py-1 rounded-full border border-[#404040]">
          <span class="w-6 h-6 rounded-full bg-[#FF9800] text-white flex items-center justify-center font-bold text-xs">L</span>
          <span>Chef Luc (Bếp trưởng)</span>
        </div>
        <button class="bg-[#424242] text-xs font-bold px-4 py-2 rounded-xl border border-transparent hover:border-[#FF9800] transition" @click="navigateBack">
          📺 Quay lại KDS
        </button>
      </div>
    </header>

    <!-- Tab Navigation (50px) -->
    <div class="h-[50px] bg-[#2D2D2D] border-b border-[#404040] px-6 flex items-center justify-between">
      <div class="flex gap-4">
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'chef' }"
          @click="switchToTab('chef')"
        >
          👨‍🍳 1. Yêu Cầu Bếp (Chef View)
        </button>
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'warehouse' }"
          @click="switchToTab('warehouse')"
        >
          🏢 2. Xử Lý Kho (Storekeeper View)
        </button>
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'stats' }"
          @click="switchToTab('stats')"
        >
          📈 3. Thống Kê & Nhật Ký
        </button>
      </div>

      <button class="btn-new-requisition" @click="showCreateModal = true">
        ➕ Tạo Phiếu Mới
      </button>
    </div>

    <!-- Main Workspace (Sidebar + Content) -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Left Sidebar (300px) -->
      <aside class="w-[320px] bg-[#1A1A1A] border-r border-[#404040] p-5 overflow-y-auto flex flex-col gap-6">
        <!-- Section: Kitchen Inventory -->
        <div class="inventory-section">
          <h3 class="sidebar-title text-xs font-bold text-[#FF9800] uppercase tracking-wider mb-3">
            Tồn Kho Bếp Hiện Tại
          </h3>
          <div class="space-y-3">
            <div 
              v-for="item in kitchenStore.inventoryList" 
              :key="item.id"
              class="inventory-item flex items-center justify-between p-2.5 rounded-lg bg-[#2D2D2D]/40 border border-[#404040] text-sm"
            >
              <div class="flex items-center gap-2">
                <span>{{ item.icon }}</span>
                <span>{{ item.name }}</span>
              </div>
              <span class="font-mono font-bold" :class="getStockLevelClass(item.kitchenStock, item.minKitchenStock)">
                {{ item.kitchenStock }} / {{ item.minKitchenStock }}{{ item.unit }}
              </span>
            </div>
          </div>
        </div>

        <!-- Section: Prep List (Linked to KDS) -->
        <div class="prep-section">
          <h3 class="sidebar-title text-xs font-bold text-[#FF9800] uppercase tracking-wider mb-3">
            Prep List & Tiến Độ Sơ Chế
          </h3>
          <div class="space-y-2.5">
            <div 
              v-for="task in kitchenStore.prepList" 
              :key="task.id"
              class="prep-task flex items-center justify-between text-xs p-2 rounded-lg bg-[#2D2D2D]/20 border border-[#404040]/70"
            >
              <span class="text-gray-300 font-medium truncate flex-1 pr-2">{{ task.name }}</span>
              <span 
                class="font-bold px-2 py-0.5 rounded text-[10px] uppercase font-mono"
                :class="task.completed ? 'bg-green-950/40 text-green-500' : 'bg-yellow-950/40 text-yellow-500'"
              >
                {{ task.completed ? 'Đã xong' : 'Sơ chế' }}
              </span>
            </div>
          </div>
        </div>
      </aside>

      <!-- Main Content Area -->
      <main class="flex-1 overflow-y-auto bg-[#1E1E1E]">
        <!-- Unified Requisition Workflow Detail View -->
        <div v-if="activeActionReq" class="p-6">
          <div class="max-w-[900px] mx-auto mb-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-lg font-bold text-white uppercase font-mono tracking-wide flex items-center gap-2">
                <span>📋 Details:</span>
                <span class="text-[#FF9800]">#{{ activeActionReq.id }}</span>
              </h2>
              <button class="bg-[#424242] text-xs font-bold px-4 py-2 rounded-xl border border-transparent hover:border-[#FF9800] transition" @click="activeActionReq = null">
                🔙 Trở về danh sách
              </button>
            </div>

            <!-- Visual Stepper Tracker (Based on kitchen_requisition.mmd) -->
            <div class="workflow-stepper flex flex-wrap justify-between items-center bg-[#2D2D2D] p-5 rounded-xl border border-[#404040] gap-4 md:gap-2">
              <div class="step-item" :class="getStepClass(1, activeActionReq)">
                <div class="step-circle">1</div>
                <div class="step-label">Tạo Phiếu (Bếp)</div>
              </div>
              <div class="step-line" :class="getLineClass(1, activeActionReq)"></div>
              
              <div class="step-item" :class="getStepClass(2, activeActionReq)">
                <div class="step-circle">2</div>
                <div class="step-label">Xử Lý Tại Kho (Kho)</div>
              </div>
              <div class="step-line" :class="getLineClass(2, activeActionReq)"></div>
              
              <div class="step-item" :class="getStepClass(3, activeActionReq)">
                <div class="step-circle">3</div>
                <div class="step-label">Giao Nhận Bếp (Bếp)</div>
              </div>
              <div class="step-line" :class="getLineClass(3, activeActionReq)"></div>
              
              <div class="step-item" :class="getStepClass(4, activeActionReq)">
                <div class="step-circle">4</div>
                <div class="step-label">Hệ Thống Cập Nhật</div>
              </div>
            </div>
          </div>

          <!-- Dynamic Panel Content depending on state and user role context -->
          <div class="detail-content">

            <!-- 1. PENDING: Warehouse must review and process stock -->
            <div v-if="activeActionReq.status === 'pending'">
              <!-- If storekeeper view, load WarehouseProcessing -->
              <div v-if="activeTab === 'warehouse'">
                <WarehouseProcessing 
                  :requisition="activeActionReq"
                  @back="activeActionReq = null"
                  @success="handleActionSuccess"
                />
              </div>
              <!-- If chef view, display waiting screen -->
              <div v-else class="status-waiting-panel bg-[#2D2D2D] rounded-xl p-8 text-center max-w-[600px] mx-auto border border-[#404040]">
                <div class="text-4xl mb-4">⌛</div>
                <h3 class="text-lg font-bold text-white uppercase mb-2">Đang chờ xử lý kho</h3>
                <p class="text-sm text-gray-400 mb-6">Yêu cầu đã gửi tới Bộ phận Kho chính. Thủ kho Nam đang chuẩn bị soạn hàng (picking).</p>
                <div class="flex gap-3 justify-center">
                  <button class="bg-[#FF9800] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#F57C00]" @click="activeTab = 'warehouse'">
                    🏢 Đóng vai thủ kho để xử lý ➔
                  </button>
                  <button class="bg-[#424242] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#505050]" @click="activeActionReq = null">
                    Quay lại
                  </button>
                </div>
              </div>
            </div>

            <!-- 2. SUBSTITUTE PROPOSED: Chef must approve/reject proposed alternate ingredient -->
            <div v-else-if="activeActionReq.status === 'substitute_proposed'">
              <!-- If Chef view, show the approval screen -->
              <div v-if="activeTab === 'chef'" class="substitute-approval bg-[#2D2D2D] rounded-xl p-6 border border-[#404040] max-w-[800px] mx-auto animate-fade-in">
                <div class="text-center mb-6">
                  <span class="text-4xl">⚠️</span>
                  <h3 class="text-xl font-bold text-white mt-3 uppercase tracking-wide">PHÊ DUYỆT PHƯƠNG ÁN THAY THẾ</h3>
                  <p class="text-sm text-gray-400 mt-1">Kho thiếu hàng và đề xuất sản phẩm thay thế. Bếp trưởng cần phê duyệt phương án:</p>
                </div>
                
                <div class="bg-[#1A1A1A] p-4 rounded-xl border border-[#404040] mb-6">
                  <span class="text-xs text-gray-400 block uppercase font-bold mb-1">Ghi chú từ thủ kho Nam:</span>
                  <p class="text-red-400 font-semibold italic">"{{ activeActionReq.rejectionReason || 'Hết hàng chính tại kho' }}"</p>
                </div>

                <div class="space-y-4 mb-6">
                  <div v-for="item in activeActionReq.items" :key="item.id" class="bg-[#1A1A1A] p-4 rounded-lg border border-[#404040] flex justify-between items-center">
                    <div class="flex items-center gap-3">
                      <span class="text-2xl">{{ item.icon }}</span>
                      <div>
                        <span class="font-bold text-white text-base block">{{ item.name }}</span>
                        <span class="text-xs text-gray-400">Yêu cầu gốc: {{ item.requestedQty }} {{ item.unit }}</span>
                      </div>
                    </div>
                    <div class="text-right">
                      <span class="text-xs text-[#FF9800] uppercase font-bold block">Phương án đề xuất:</span>
                      <span class="text-sm text-yellow-100 font-medium font-mono">{{ item.rejectionReason || 'Không thay đổi' }}</span>
                    </div>
                  </div>
                </div>

                <div class="flex gap-3 justify-end">
                  <button class="bg-[#424242] hover:bg-[#505050] text-xs font-bold text-white px-5 py-2.5 rounded-xl" @click="rejectSubstitute(activeActionReq.id)">
                    ❌ Từ chối phiếu yêu cầu
                  </button>
                  <button class="bg-[#FF9800] hover:bg-[#F57C00] text-xs font-bold text-white px-5 py-2.5 rounded-xl shadow-md" @click="approveSubstitute(activeActionReq.id)">
                    ✓ Đồng ý phương án thay thế
                  </button>
                </div>
              </div>

              <!-- If Warehouse view, show waiting screen -->
              <div v-else class="status-waiting-panel bg-[#2D2D2D] rounded-xl p-8 text-center max-w-[600px] mx-auto border border-[#404040]">
                <div class="text-4xl mb-4">⌛</div>
                <h3 class="text-lg font-bold text-white uppercase mb-2">Đang chờ Bếp trưởng duyệt</h3>
                <p class="text-sm text-gray-400 mb-6">Đã gửi phương án thay thế nguyên liệu. Chờ Chef Luc phê duyệt duyệt để chuẩn bị hàng.</p>
                <div class="flex gap-3 justify-center">
                  <button class="bg-[#FF9800] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#F57C00]" @click="activeTab = 'chef'">
                    👨‍🍳 Đóng vai Chef Luc để duyệt ➔
                  </button>
                  <button class="bg-[#424242] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#505050]" @click="activeActionReq = null">
                    Quay lại
                  </button>
                </div>
              </div>
            </div>

            <!-- 3. APPROVED: Warehouse picking done, Chef needs to inspect quality, temperature, and sign receipt -->
            <div v-else-if="activeActionReq.status === 'approved'">
              <!-- If Chef view, load DeliveryConfirmation -->
              <DeliveryConfirmation 
                v-if="activeTab === 'chef'"
                :requisition="activeActionReq"
                @back="activeActionReq = null"
                @success="handleActionSuccess"
              />
              <!-- If Warehouse view, display delivering progress -->
              <div v-else class="status-waiting-panel bg-[#2D2D2D] rounded-xl p-8 text-center max-w-[600px] mx-auto border border-[#404040]">
                <div class="text-4xl mb-4">🚚</div>
                <h3 class="text-lg font-bold text-white uppercase mb-2">Đang bàn giao nhận hàng</h3>
                <p class="text-sm text-gray-400 mb-6">Nguyên vật liệu đã xuất kho. Chờ Bếp trưởng Chef Luc nghiệm nghiệm chất lượng, số lượng, nhiệt độ và ký nhận bàn giao.</p>
                <div class="flex gap-3 justify-center">
                  <button class="bg-[#FF9800] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#F57C00]" @click="activeTab = 'chef'">
                    👨‍🍳 Đóng vai Chef Luc để nhận hàng ➔
                  </button>
                  <button class="bg-[#424242] text-xs font-bold px-4 py-2.5 rounded-xl text-white hover:bg-[#505050]" @click="activeActionReq = null">
                    Quay lại
                  </button>
                </div>
              </div>
            </div>

            <!-- 4. DELIVERED / REJECTED: Final summaries, signatures, and COGS statistics -->
            <div v-else class="summary-final bg-[#2D2D2D] rounded-xl p-6 border border-[#404040] max-w-[800px] mx-auto">
              <div class="text-center mb-6">
                <span class="text-4xl">{{ activeActionReq.status === 'delivered' ? '✅' : '❌' }}</span>
                <h3 class="text-xl font-bold text-white mt-3 uppercase tracking-wide">
                  PHIẾU YÊU CẦU {{ activeActionReq.status === 'delivered' ? 'ĐÃ HOÀN TẤT' : 'BỊ TỪ CHỐI' }}
                </h3>
                <p class="text-sm text-gray-400 mt-1 font-mono">Mã số: #{{ activeActionReq.id }}</p>
              </div>

              <!-- General info -->
              <div class="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-[#1A1A1A] rounded-xl border border-[#404040] mb-6 text-sm">
                <div>
                  <span class="text-[10px] text-gray-500 block uppercase font-bold">Người tạo:</span>
                  <span class="text-white font-semibold">{{ activeActionReq.actor }}</span>
                </div>
                <div>
                  <span class="text-[10px] text-gray-500 block uppercase font-bold">Bộ phận:</span>
                  <span class="text-white font-semibold">{{ activeActionReq.station }}</span>
                </div>
                <div>
                  <span class="text-[10px] text-gray-500 block uppercase font-bold">Ngày giờ:</span>
                  <span class="text-white font-semibold font-mono">{{ activeActionReq.date }}</span>
                </div>
                <div>
                  <span class="text-[10px] text-gray-500 block uppercase font-bold">Trạng thái:</span>
                  <span class="font-bold uppercase text-xs" :class="activeActionReq.status === 'delivered' ? 'text-green-500' : 'text-red-500'">
                    {{ activeActionReq.status === 'delivered' ? 'Đã Giao Nhận' : 'Bị Từ Chối' }}
                  </span>
                </div>
              </div>

              <!-- Rejection Reason if any -->
              <div v-if="activeActionReq.status === 'rejected'" class="p-4 bg-red-950/20 text-red-400 border border-red-800/40 rounded-xl mb-6 text-sm">
                <strong>Lý do từ chối:</strong> {{ activeActionReq.rejectionReason || 'Chưa cập nhật lý do từ chối.' }}
              </div>

              <!-- Items list -->
              <div class="space-y-4 mb-6">
                <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Danh sách nguyên vật liệu:</h4>
                <div v-for="item in activeActionReq.items" :key="item.id" class="bg-[#1A1A1A] p-3.5 rounded-lg border border-[#404040] flex justify-between items-center">
                  <div class="flex items-center gap-3">
                    <span class="text-2xl">{{ item.icon }}</span>
                    <div>
                      <span class="font-bold text-white block">{{ item.name }}</span>
                      <span class="text-xs text-gray-400">Yêu cầu: {{ item.requestedQty }} {{ item.unit }}</span>
                    </div>
                  </div>
                  <div class="text-right">
                    <span class="text-xs text-gray-400 block font-mono">Thực giao:</span>
                    <span class="text-sm font-bold" :class="item.deliveredQty > 0 ? 'text-green-500' : 'text-red-500'">
                      {{ item.deliveredQty }} {{ item.unit }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Financial impact (COGS Update node: U2) -->
              <div v-if="activeActionReq.status === 'delivered' && getCogsValue(activeActionReq) > 0" class="p-4 bg-[#FF9800]/10 border border-[#FF9800]/20 rounded-xl mb-6 flex justify-between items-center text-sm">
                <span class="text-gray-300 font-medium">💰 Giá vốn COGS ghi nhận vào bếp:</span>
                <span class="text-[#FF9800] text-lg font-black font-mono">+{{ formatCurrency(getCogsValue(activeActionReq)) }} VND</span>
              </div>

              <!-- Digital signature display -->
              <div v-if="activeActionReq.status === 'delivered' && activeActionReq.signatureImage" class="p-4 bg-[#1A1A1A] rounded-xl border border-[#404040] mb-6 flex flex-col items-center">
                <span class="text-xs text-gray-400 uppercase font-bold mb-2">Chữ ký xác nhận kỹ thuật số (Digital Signature):</span>
                <img :src="activeActionReq.signatureImage" alt="Chef Signature" class="max-h-[80px] bg-slate-900 border border-[#333] rounded px-3 py-1" />
              </div>

              <!-- Timeline of audits -->
              <div class="bg-[#1A1A1A] rounded-xl border border-[#404040] p-4 text-xs space-y-3">
                <span class="text-gray-400 block font-bold uppercase mb-1">⏳ LỊCH SỬ PHÊ DUYỆT (AUDIT LOGS)</span>
                <div v-for="log in activeActionReq.auditLogs" :key="log.id" class="flex justify-between border-b border-[#2D2D2D] pb-2 last:border-0 last:pb-0">
                  <span class="text-gray-300">👤 {{ log.actor }}: {{ log.action }}</span>
                  <span class="text-gray-500 font-mono">{{ log.timestamp }}</span>
                </div>
              </div>

              <div class="flex justify-end mt-6">
                <button class="bg-[#424242] hover:bg-[#505050] text-xs font-bold text-white px-6 py-2.5 rounded-xl" @click="activeActionReq = null">
                  Đóng chi tiết
                </button>
              </div>
            </div>

          </div>
        </div>

        <!-- Tab contents -->
        <div v-else>
          <!-- Tab 1: Chef list -->
          <div v-if="activeTab === 'chef'">
            <RequisitionList 
              :requisitions="kitchenStore.requisitions"
              @create="showCreateModal = true"
              @select="handleChefRequisitionSelect"
            />
          </div>

          <!-- Tab 2: Warehouse list -->
          <div v-if="activeTab === 'warehouse'" class="p-6 animate-fade-in">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-xl font-bold text-white uppercase">Xử Lý Phiếu Kho (Storekeeper)</h2>
              <span class="text-xs text-gray-400 font-medium">Bếp trưởng gửi yêu cầu, thủ kho phê duyệt</span>
            </div>
            
            <div class="space-y-4">
              <div v-if="pendingRequisitions.length === 0" class="text-center py-12 text-gray-500 bg-[#2D2D2D] rounded-xl border border-[#404040]">
                ☕ Không có phiếu yêu cầu nào đang chờ xử lý.
              </div>
              <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div 
                  v-for="req in pendingRequisitions" 
                  :key="req.id"
                  class="p-4 bg-[#2D2D2D] border-l-4 border-yellow-500 hover:border-yellow-400 rounded-xl cursor-pointer hover:scale-[1.01] transition-all relative"
                  @click="openWarehouseProcessing(req)"
                >
                  <div class="flex justify-between items-center">
                    <span class="text-sm font-bold text-white font-mono">#{{ req.id }}</span>
                    <span class="text-xs font-bold text-yellow-500 uppercase">{{ getPriorityLabel(req.priority) }}</span>
                  </div>
                  <div class="text-xs text-gray-400 mt-1">
                    Trạm: {{ req.station }} | Người tạo: {{ req.actor }}
                  </div>
                  <div class="text-sm text-gray-300 mt-2 line-clamp-1 italic">
                    "{{ req.notes || 'Không có ghi chú' }}"
                  </div>
                  <div class="mt-3 flex justify-end">
                    <button class="bg-[#FF9800] hover:bg-[#F57C00] text-xs font-bold px-3 py-1.5 rounded-lg text-white">
                      Xử lý ngay ➔
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Tab 3: Stats -->
          <div v-if="activeTab === 'stats'" class="animate-fade-in">
            <RequisitionStats :requisitions="kitchenStore.requisitions" />
          </div>
        </div>
      </main>
    </div>

    <!-- Create Requisition Modal Overlay -->
    <div 
      v-if="showCreateModal" 
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="showCreateModal = false"
    >
      <CreateRequisition 
        @close="showCreateModal = false"
        @success="handleCreateSuccess"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useKitchenStore, type Requisition } from '@/stores/kitchen';
import RequisitionList from '@/components/requisition/RequisitionList.vue';
import CreateRequisition from '@/components/requisition/CreateRequisition.vue';
import WarehouseProcessing from '@/components/requisition/WarehouseProcessing.vue';
import DeliveryConfirmation from '@/components/requisition/DeliveryConfirmation.vue';
import RequisitionStats from '@/components/requisition/RequisitionStats.vue';
import Swal from 'sweetalert2';

const router = useRouter();
const kitchenStore = useKitchenStore();

const activeTab = ref<'chef' | 'warehouse' | 'stats'>('chef');
const showCreateModal = ref(false);

// Active detail view settings
const activeActionReq = ref<Requisition | null>(null);

const pendingRequisitions = computed(() => {
  // pending or substitute_proposed requisitions are visible in warehouse tab
  return kitchenStore.requisitions.filter(r => r.status === 'pending' || r.status === 'substitute_proposed');
});

const switchToTab = (tab: 'chef' | 'warehouse' | 'stats') => {
  activeTab.value = tab;
  activeActionReq.value = null; // reset detail view
};

const getStockLevelClass = (stock: number, min: number) => {
  if (stock === 0) return 'text-red-500';
  if (stock < min) return 'text-[#FF9800]';
  return 'text-green-500';
};

const getPriorityLabel = (pri: string) => {
  if (pri === 'low') return 'Ưu tiên thấp';
  if (pri === 'high') return 'Ưu tiên cao';
  return 'Ưu tiên trung bình';
};

const handleChefRequisitionSelect = (req: Requisition) => {
  activeActionReq.value = req;
};

const openWarehouseProcessing = (req: Requisition) => {
  activeActionReq.value = req;
};

const handleCreateSuccess = () => {
  showCreateModal.value = false;
  switchToTab('chef');
};

const handleActionSuccess = () => {
  // Kept selected so user can see step 4 completed
};

const navigateBack = () => {
  router.push('/kitchen/kds');
};

const getCogsValue = (req: Requisition) => {
  return req.items.reduce((sum, item) => {
    const invItem = kitchenStore.inventoryList.find(i => i.id === item.id);
    const price = invItem ? invItem.unitPrice : 100000;
    return sum + (item.deliveredQty * price);
  }, 0);
};

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN').format(val);
};

// Stepper helpers
const getStepClass = (stepNum: number, req: Requisition) => {
  if (req.status === 'rejected') {
    if (stepNum === 1) return 'completed';
    // Find if warehouse or chef rejected
    const isWarehouseReject = req.auditLogs.some(l => l.action.includes('Từ chối yêu cầu'));
    const isChefReject = req.auditLogs.some(l => l.action.includes('Từ chối nhận'));
    if (stepNum === 2) return isWarehouseReject ? 'rejected' : 'completed';
    if (stepNum === 3) return isChefReject ? 'rejected' : '';
    return '';
  }

  if (req.status === 'delivered') {
    return 'completed';
  }

  if (req.status === 'approved') {
    if (stepNum < 3) return 'completed';
    if (stepNum === 3) return 'active';
    return '';
  }

  if (req.status === 'substitute_proposed') {
    if (stepNum < 2) return 'completed';
    if (stepNum === 2) return 'active';
    return '';
  }

  if (req.status === 'pending') {
    if (stepNum === 1) return 'completed';
    if (stepNum === 2) return 'active';
    return '';
  }

  return '';
};

const getLineClass = (stepNum: number, req: Requisition) => {
  if (req.status === 'rejected') {
    // Show where the break occurred
    if (stepNum === 1) return 'completed'; // Phase 1 to 2 line
    return '';
  }
  if (req.status === 'delivered') return 'completed';
  if (req.status === 'approved' && stepNum < 3) return 'completed';
  if (req.status === 'substitute_proposed' && stepNum < 2) return 'completed';
  if (req.status === 'pending' && stepNum < 2) return 'completed';
  return '';
};

const approveSubstitute = (id: string) => {
  kitchenStore.updateRequisitionStatus(id, 'approved', 'Chef Luc', 'Đã duyệt phương án thay thế của thủ kho Nam. Hàng sẵn sàng bàn giao.');
  
  // Refresh activeActionReq
  const updated = kitchenStore.requisitions.find(r => r.id === id);
  if (updated) activeActionReq.value = updated;

  Swal.fire({
    title: 'Đã phê duyệt thay thế',
    text: 'Đồng ý nhận sản phẩm thay thế. Phiếu đã chuyển sang giai đoạn 3: Giao Nhận!',
    icon: 'success',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#4CAF50'
  });
};

const rejectSubstitute = (id: string) => {
  kitchenStore.updateRequisitionStatus(id, 'rejected', 'Chef Luc', 'Từ chối phương án nguyên liệu thay thế.');
  
  // Refresh activeActionReq
  const updated = kitchenStore.requisitions.find(r => r.id === id);
  if (updated) activeActionReq.value = updated;

  Swal.fire({
    title: 'Đã từ chối',
    text: 'Đã từ chối đề xuất thay thế. Phiếu yêu cầu đã bị hủy.',
    icon: 'error',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#F44336'
  });
};
</script>

<style scoped>
.requisition-view {
  background: #1A1A1A;
}

.logo-brand {
  font-size: 18px;
}

/* Tabs */
.tab-btn {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 700;
  color: #B0B0B0;
  background: transparent;
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tab-btn:hover {
  color: white;
}

.tab-btn.active {
  background: #FF9800;
  color: white;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.25);
}

.btn-new-requisition {
  background: #FF9800;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-new-requisition:hover {
  background: #F57C00;
  transform: translateY(-1px);
}

.sidebar-title {
  border-left: 3px solid #FF9800;
  padding-left: 8px;
}

/* Stepper styles */
.workflow-stepper {
  display: flex;
  align-items: center;
  gap: 8px;
}
.step-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}
.step-circle {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #1A1A1A;
  border: 2px solid #404040;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 13px;
  color: #B0B0B0;
  transition: all 0.3s ease;
}
.step-label {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  color: #B0B0B0;
  margin-top: 6px;
  text-align: center;
}
.step-line {
  height: 3px;
  background: #404040;
  flex: 1;
  border-radius: 2px;
}

/* Active states */
.step-item.active .step-circle {
  border-color: #FF9800;
  background: rgba(255, 152, 0, 0.1);
  color: #FF9800;
  box-shadow: 0 0 10px rgba(255, 152, 0, 0.3);
}
.step-item.active .step-label {
  color: #FF9800;
}

/* Completed states */
.step-item.completed .step-circle {
  border-color: #4CAF50;
  background: rgba(76, 175, 80, 0.1);
  color: #4CAF50;
}
.step-item.completed .step-label {
  color: #4CAF50;
}
.step-line.completed {
  background: #4CAF50;
}

/* Rejected states */
.step-item.rejected .step-circle {
  border-color: #F44336;
  background: rgba(244, 67, 54, 0.1);
  color: #F44336;
}
.step-item.rejected .step-label {
  color: #F44336;
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

.flex-2 {
  flex: 2;
}
</style>
