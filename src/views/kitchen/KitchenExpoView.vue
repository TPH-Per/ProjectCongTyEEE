<template>
  <div class="min-h-screen bg-background text-foreground flex flex-col font-sans kds-container">
    
    <!-- 1. EXPO HEADER (70px) -->
    <header class="expo-header">
      <div class="flex items-center gap-4">
        <!-- Logo / Brand -->
        <div class="flex items-center gap-2">
          <span class="logo-brand text-[#FF9800] font-extrabold tracking-wider text-xl">NGƯU CÁT</span>
          <span class="tag-kds text-xs bg-gray-800 text-gray-400 border border-gray-700 px-2 py-0.5 rounded font-bold uppercase">EXPO</span>
        </div>
      </div>

      <!-- Header Navigation Links -->
      <HeaderButtons />

      <div class="flex items-center gap-6">
        <!-- Chef Info -->
        <div class="chef-info">
          <div class="chef-avatar">L</div>
          <div>
            <div class="chef-name font-bold">Chef Luc</div>
            <div class="chef-role">Bếp trưởng</div>
          </div>
        </div>

        <!-- Clock -->
        <div class="expo-clock font-mono">
          {{ currentTime }}
        </div>

        <!-- Notification Bell -->
        <div class="notification-bell" @click="clearLocalNotifications">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          <span v-if="notificationCount > 0" class="notification-badge">{{ notificationCount }}</span>
        </div>
      </div>
    </header>

    <!-- 2. QC QUEUE BAR (60px) -->
    <div class="qc-queue-bar">
      <div 
        class="qc-counter waiting" 
        :class="{ active: qcActiveFilter === 'waiting' }"
        @click="qcActiveFilter = 'waiting'"
      >
        <span>Chờ QC:</span>
        <span class="counter-number">{{ activeQcCount }}</span>
      </div>
      <div 
        class="qc-counter passed bg-[#2E7D32]" 
        :class="{ active: qcActiveFilter === 'passed' }"
        @click="qcActiveFilter = 'passed'"
      >
        <span>Đạt:</span>
        <span class="counter-number">{{ passedQcOrderIds.length }}</span>
      </div>
      <div 
        class="qc-counter remake" 
        :class="{ active: qcActiveFilter === 'remake' }"
        @click="qcActiveFilter = 'remake'"
      >
        <span>Remake:</span>
        <span class="counter-number">{{ remakeOrdersCount }}</span>
      </div>
      <div 
        class="qc-counter allergy bg-[#FF5722]" 
        :class="{ active: qcActiveFilter === 'allergy' }"
        @click="qcActiveFilter = 'allergy'"
      >
        <span>⚠️ Dị ứng:</span>
        <span class="counter-number">{{ allergyQcCount }}</span>
      </div>
      
      <!-- Demo Tools (Convenient for local check/validation) -->
      <div class="ml-auto flex items-center gap-2">
        <button 
          @click="insertMockOrder" 
          class="bg-blue-600 hover:bg-blue-500 text-xs px-3 py-1.5 rounded font-semibold border border-blue-400/20"
        >
          ➕ Thêm Mock Order QC
        </button>
        <button 
          @click="insertMockAllergyOrder" 
          class="bg-red-600 hover:bg-red-500 text-xs px-3 py-1.5 rounded font-semibold border border-red-400/20"
        >
          ⚠️ Thêm Mock Dị Ứng
        </button>
      </div>
    </div>

    <!-- 3. MAIN WORKSPACE (2 Columns) -->
    <div class="flex-1 flex overflow-hidden p-6 gap-6">
      
      <!-- Cột Trái (60%): Món cần kiểm tra (QC Active List) -->
      <div class="w-[60%] flex flex-col overflow-y-auto space-y-4 pr-2">
        <h2 class="text-lg font-bold text-gray-200 uppercase tracking-wider flex items-center gap-2">
          📋 QC Active Queue
          <span class="text-xs font-semibold px-2 py-0.5 bg-gray-700 text-gray-400 rounded-full">
            {{ filteredQcOrders.length }} đơn hàng
          </span>
        </h2>

        <div v-if="filteredQcOrders.length === 0" class="flex-1 flex flex-col items-center justify-center bg-[#252525] rounded-2xl border border-border/50 p-8 text-center">
          <span class="text-5xl mb-3">🛎️</span>
          <h3 class="text-lg font-bold text-gray-300">Không có đơn hàng nào cần kiểm tra</h3>
          <p class="text-sm text-gray-500 mt-1">Đơn hàng hoàn tất sơ chế & chế biến tại KDS sẽ tự động hiển thị tại đây.</p>
        </div>

        <div 
          v-for="order in filteredQcOrders" 
          :key="order.id" 
          class="qc-active-card new"
          :class="{ 'has-allergy': hasOrderAllergy(order) }"
        >
          <!-- Card Header -->
          <div class="qc-card-header">
            <div class="qc-ticket-info">
              <span class="qc-ticket-number">Bàn {{ getTableCode(order.table) }}</span>
              <span class="qc-table-info">#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span>
            </div>

            <div class="flex items-center gap-3">
              <span v-if="hasOrderAllergy(order)" class="allergy-badge">
                ⚠️ DỊ ỨNG
              </span>
              <span v-if="isOrderRemake(order.id)" class="bg-[#9C27B0] text-white px-2 py-1 rounded text-xs font-bold uppercase animate-pulse">
                REMAKE P1
              </span>
              <span class="qc-timer" :class="{ urgent: order.waitTime >= 900 }">
                ⏳ {{ formatWaitTime(order.waitTime) }}
              </span>
            </div>
          </div>

          <!-- Allergy Warning Block -->
          <div v-if="hasOrderAllergy(order)" class="allergy-warning">
            🛑 CẢNH BÁO DỊ ỨNG NGHIÊM TRỌNG: {{ getOrderAllergyNotes(order) }}
          </div>

          <!-- Items List -->
          <div class="qc-items-list space-y-3">
            <div 
              v-for="item in order.items" 
              :key="item.id" 
              class="qc-item"
              :class="{ 'has-allergy': isItemAllergen(item.name) || item.note }"
            >
              <div class="qc-item-header">
                <span class="qc-item-name flex items-center gap-2">
                  <span class="qc-item-qty">{{ item.qty }}x</span>
                  {{ item.name }}
                </span>
                <span class="qc-item-status" :class="item.done ? 'status-passed' : 'status-pending'">
                  {{ item.done ? 'Đã nấu' : 'Chờ nấu' }}
                </span>
              </div>
              <div v-if="item.note" class="text-sm text-[#FF9800] italic font-bold bg-[#FF9800]/10 p-2 rounded border border-[#FF9800]/20 mt-1">
                Ghi chú đặc biệt: {{ item.note }}
              </div>
              <div class="qc-specs mt-2">
                <span class="qc-spec"><span class="qc-spec-icon">🌡️</span>Nhiệt độ: ≥ 60°C</span>
                <span class="qc-spec"><span class="qc-spec-icon">⚖️</span>Định lượng: Đúng dĩa</span>
                <span class="qc-spec"><span class="qc-spec-icon">🎨</span>Trình bày: Đẹp</span>
              </div>
            </div>
          </div>

          <!-- Checklist -->
          <div class="qc-checklist">
            <div class="checklist-title">Checklist tiêu chuẩn món ăn (Expo QC)</div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2">
              <label 
                v-for="(label, key) in qcCriteriaLabels" 
                :key="key"
                class="checklist-item select-none"
                :class="{ checked: orderChecklistState[order.id]?.[key] }"
              >
                <div class="checklist-checkbox">
                  <input 
                    type="checkbox" 
                    v-model="orderChecklistState[order.id][key]"
                    class="hidden"
                  >
                  <span v-if="orderChecklistState[order.id]?.[key]" class="text-foreground text-xs">✓</span>
                </div>
                <span class="checklist-label">{{ label }}</span>
              </label>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="qc-actions">
            <button @click="openQcFail(order)" class="qc-btn fail">
              ❌ Không Đạt QC
            </button>
            <button @click="openQcPass(order)" class="qc-btn pass">
              ✅ Đạt - Ra Món
            </button>
          </div>
        </div>
      </div>

      <!-- Cột Phải (40%): Remake Queue & Statistics Panel -->
      <div class="w-[40%] flex flex-col space-y-6 overflow-y-auto pl-2">
        
        <!-- Remake Queue -->
        <div class="remake-queue">
          <h2 class="remake-queue-title">
            <span>🚨 REMAKE QUEUE (ƯU TIÊN CAO)</span>
            <span class="bg-[#9C27B0]/20 text-[#CE93D8] px-2 py-0.5 rounded text-xs">
              {{ activeRemakes.length }} món
            </span>
          </h2>

          <div v-if="activeRemakes.length === 0" class="p-6 bg-background rounded-lg border border-border/30 text-center text-gray-500 text-sm">
            Không có món nào đang làm lại.
          </div>

          <div 
            v-for="remake in activeRemakes" 
            :key="remake.id" 
            class="remake-card border-l-4"
          >
            <div class="remake-card-header">
              <span class="remake-ticket">Bàn {{ getTableCode(remake.table) }}</span>
              <span class="remake-priority">P1 - HIGH</span>
            </div>

            <div class="text-sm text-gray-200 mt-2">
              <div v-for="item in remake.items" :key="item.name" class="font-semibold">
                {{ item.qty }}x {{ item.name }}
              </div>
            </div>

            <div class="remake-reason">
              Lý do: {{ remake.reason || 'Lỗi chế biến' }} ({{ remake.severity || 'Medium' }})
            </div>

            <div class="flex justify-between items-center mt-3 pt-2 border-t border-border/50">
              <span class="text-xs text-gray-400 font-mono">
                Bắt đầu: {{ formatWaitTime(remake.elapsedTime || 0) }}
              </span>
              <span class="remake-status" :class="remake.status === 'Preparing' ? 'cooking' : 'waiting'">
                {{ remake.status === 'Preparing' ? 'Đang chế biến' : 'Chờ chế biến' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Statistics Panel -->
        <div class="statistics-panel">
          <h3 class="statistics-title">Thông số vận hành hôm nay</h3>
          <div class="statistics-grid">
            <div class="stat-box">
              <div class="stat-value good">{{ stats.passRate }}%</div>
              <div class="stat-label">Tỉ lệ đạt</div>
            </div>
            <div class="stat-box">
              <div class="stat-value warning">{{ stats.remakeRate }}%</div>
              <div class="stat-label">Tỉ lệ remake</div>
            </div>
            <div class="stat-box">
              <div class="stat-value info">{{ stats.avgQCTime }}m</div>
              <div class="stat-label">Thời gian QC TB</div>
            </div>
          </div>

          <div class="mt-4 p-3 bg-card rounded-lg border border-border/50 text-xs text-gray-400">
            <div class="flex justify-between mb-1">
              <span>Tổng số lượng QC:</span>
              <span class="text-gray-200 font-bold">{{ stats.totalQC }} món</span>
            </div>
            <div class="flex justify-between mb-1">
              <span>Đạt tiêu chuẩn lần đầu:</span>
              <span class="text-green-400 font-bold">{{ stats.firstPass }} món</span>
            </div>
            <div class="flex justify-between">
              <span>Waste logged:</span>
              <span class="text-red-400 font-bold">{{ wasteLog.length }} món</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 4. MODAL "KHÔNG ĐẠT" (REMAKE WORKFLOW) -->
    <div v-if="showQcFailModal && selectedQcOrder" class="modal-overlay remake-modal" @click.self="showQcFailModal = false">
      <div class="modal-content max-w-[600px] overflow-hidden rounded-2xl border border-red-800">
        <div class="modal-header">
          <h3 class="text-lg font-bold">🚨 Món không đạt QC - Bàn {{ getTableCode(selectedQcOrder.table) }}</h3>
          <p class="text-xs opacity-90 mt-1">Ticket #{{ selectedQcOrder.id.slice(0, 8) }}</p>
        </div>

        <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
          <!-- Item Summary -->
          <div>
            <label class="text-xs text-gray-400 uppercase font-bold block mb-1">Món ăn không đạt</label>
            <div class="p-3 bg-background border border-border rounded-xl text-sm font-semibold">
              <div v-for="item in selectedQcOrder.items" :key="item.id">
                {{ item.qty }}x {{ item.name }}
              </div>
            </div>
          </div>

          <!-- QC Failure Reasons -->
          <div class="reason-group">
            <label class="reason-group-title">Lý do không đạt</label>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-2 mt-2">
              <div 
                v-for="r in qcFailureReasons" 
                :key="r"
                @click="qcFailSelectedReason = r"
                class="reason-option"
                :class="{ selected: qcFailSelectedReason === r }"
              >
                <div class="reason-radio"></div>
                <span class="reason-label">{{ r }}</span>
              </div>
            </div>

            <!-- Custom text if Other -->
            <input 
              v-if="qcFailSelectedReason === 'Khác'"
              v-model="qcFailCustomReason"
              type="text"
              placeholder="Nhập chi tiết nguyên nhân khác..."
              class="w-full bg-background border border-border rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-[#C62828] mt-2"
            >
          </div>

          <!-- Severity selection -->
          <div>
            <label class="text-xs text-gray-400 uppercase font-bold block mb-2">Mức độ nghiêm trọng</label>
            <div class="severity-group">
              <div 
                @click="qcFailSeverity = 'Thấp'"
                class="severity-option"
                :class="{ selected: qcFailSeverity === 'Thấp', low: true }"
              >
                <div class="severity-icon">🟢</div>
                <div class="severity-label">Thấp</div>
              </div>
              <div 
                @click="qcFailSeverity = 'Trung bình'"
                class="severity-option"
                :class="{ selected: qcFailSeverity === 'Trung bình', medium: true }"
              >
                <div class="severity-icon">🟡</div>
                <div class="severity-label">Trung bình</div>
              </div>
              <div 
                @click="qcFailSeverity = 'Cao'"
                class="severity-option"
                :class="{ selected: qcFailSeverity === 'Cao', high: true }"
              >
                <div class="severity-icon">🔴</div>
                <div class="severity-label">Cao (Dị ứng/Dị vật)</div>
              </div>
            </div>
          </div>

          <!-- Notes -->
          <div>
            <label class="text-xs text-gray-400 uppercase font-bold block mb-1">Ghi chú thêm</label>
            <textarea 
              v-model="qcFailNotes" 
              rows="3" 
              placeholder="Nhập lưu ý thêm cho bếp khi chế biến lại (ví dụ: chú ý làm chín kỹ hơn, không bỏ đậu phộng...)"
              class="w-full bg-background border border-border rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-red-600 resize-none"
            ></textarea>
          </div>

          <div class="priority-notice">
            ⚡ REMAKE SẼ ĐƯỢC TỰ ĐỘNG ĐẨY LÊN ĐẦU HÀNG ĐỢI BẾP VỚI ƯU TIÊN P1
          </div>
        </div>

        <div class="bg-card p-6 border-t border-border flex gap-3 justify-end">
          <button @click="showQcFailModal = false" class="modal-btn cancel">
            Hủy
          </button>
          <button @click="submitQcFail(false)" class="modal-btn bg-[#FF9800] hover:bg-[#ffaa2b] text-white">
            Ghi nhận Waste (Hủy món)
          </button>
          <button @click="submitQcFail(true)" class="modal-btn bg-[#9C27B0] hover:bg-[#a631ba] text-white">
            Tạo Remake P1
          </button>
        </div>
      </div>
    </div>

    <!-- 5. MODAL "ĐẠT" (SERVICE HANDOFF) -->
    <div v-if="showQcPassModal && selectedQcOrder" class="modal-overlay" @click.self="showQcPassModal = false">
      <div class="modal-content max-w-[500px]">
        <div class="modal-header border-b border-border pb-4 mb-4">
          <h3 class="text-lg font-bold text-green-400 flex items-center gap-2">
            🎉 Món đã đạt chuẩn QC!
          </h3>
          <p class="text-xs text-gray-400 mt-0.5">Bàn {{ getTableCode(selectedQcOrder.table) }} &bull; Ticket #{{ selectedQcOrder.id.slice(0, 8) }}</p>
        </div>

        <div class="space-y-4">
          <div>
            <label class="text-xs text-gray-400 uppercase font-bold block mb-1">Tóm tắt các món ra bàn</label>
            <div class="p-3 bg-background border border-green-900/30 rounded-xl space-y-1">
              <div v-for="item in selectedQcOrder.items" :key="item.id" class="flex justify-between text-sm text-gray-200">
                <span>{{ item.qty }}x {{ item.name }}</span>
                <span class="text-green-500 font-semibold">Đạt chuẩn ✓</span>
              </div>
            </div>
          </div>

          <!-- Time statistics -->
          <div class="bg-background p-3 rounded-xl border border-border">
            <div class="flex justify-between text-xs mb-1">
              <span class="text-gray-400">Thời gian chế biến:</span>
              <span class="text-gray-200 font-bold font-mono">{{ formatWaitTime(selectedQcOrder.waitTime) }}</span>
            </div>
            <div class="flex justify-between text-xs mb-1">
              <span class="text-gray-400">Thời gian tiêu chuẩn:</span>
              <span class="text-gray-200 font-bold font-mono">15:00</span>
            </div>
            <div class="flex justify-between text-xs pt-1.5 border-t border-border">
              <span class="text-green-400 font-bold">Trạng thái:</span>
              <span class="text-green-400 font-bold">
                {{ selectedQcOrder.waitTime < 900 ? 'SỚM HƠN ' + formatWaitTime(900 - selectedQcOrder.waitTime) : 'TRỄ' }}
              </span>
            </div>
          </div>

          <!-- Runner actions -->
          <div class="space-y-2">
            <label class="text-xs text-gray-400 uppercase font-bold block">Gọi staff/runner lấy món</label>
            <div class="grid grid-cols-3 gap-2">
              <button @click="triggerRunnerCall('bell')" class="py-2.5 px-2 bg-muted hover:bg-[#4d4d4d] border border-border text-xs font-bold rounded-lg transition-all flex flex-col items-center justify-center gap-1.5">
                <span>🔔</span>
                <span>BẤM CHUÔNG</span>
              </button>
              <button @click="triggerRunnerCall('notify')" class="py-2.5 px-2 bg-muted hover:bg-[#4d4d4d] border border-border text-xs font-bold rounded-lg transition-all flex flex-col items-center justify-center gap-1.5">
                <span>📱</span>
                <span>GỬI NOTIFY</span>
              </button>
              <button @click="triggerRunnerCall('voice')" class="py-2.5 px-2 bg-muted hover:bg-[#4d4d4d] border border-border text-xs font-bold rounded-lg transition-all flex flex-col items-center justify-center gap-1.5">
                <span>🗣️</span>
                <span>GỌI TÊN</span>
              </button>
            </div>
            
            <div class="mt-2 text-xs text-gray-400 flex justify-between items-center bg-card p-2.5 rounded-lg border border-border">
              <span>Staff phụ trách (Runner):</span>
              <span class="text-gray-200 font-bold">Nguyễn Văn A (Runner)</span>
            </div>
          </div>
        </div>

        <div class="modal-actions mt-6 border-t border-border pt-4">
          <button @click="showQcPassModal = false" class="modal-btn cancel">
            HỦY
          </button>
          <button @click="submitQcPass" class="modal-btn bg-[#2E7D32] hover:bg-[#348a39] text-white">
            XÁC NHẬN ĐÃ GIAO
          </button>
        </div>
      </div>
    </div>

    <!-- Delayed Orders Modal -->
    <div v-if="kitchenStore.showDelayedOrdersModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in" @click.self="kitchenStore.showDelayedOrdersModal = false">
      <div class="bg-card border border-border rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl animate-scale-up">
        <!-- Header -->
        <div class="p-6 bg-[#C62828] text-white flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="text-2xl">⚠️</span>
            <div>
              <h3 class="text-lg font-bold">CẢNH BÁO: ĐƠN CHẾ BIẾN TRỄ</h3>
              <p class="text-xs text-red-100">Các đơn hàng vượt quá thời gian chuẩn (15 phút)</p>
            </div>
          </div>
          <button @click="kitchenStore.showDelayedOrdersModal = false" class="text-foreground/80 hover:text-foreground text-xl font-bold">&times;</button>
        </div>
        
        <!-- Body -->
        <div class="p-6 max-h-[400px] overflow-y-auto space-y-4">
          <div v-if="kitchenStore.delayedTickets.length === 0" class="text-center py-8 text-gray-400">
            Không có đơn hàng nào bị trễ.
          </div>
          <div v-else v-for="ticket in kitchenStore.delayedTickets" :key="ticket.id" class="p-4 bg-background border border-red-500/30 rounded-xl flex items-center justify-between gap-4">
            <div class="space-y-1">
              <div class="flex items-center gap-2">
                <span class="bg-[#C62828] text-white text-xs px-2.5 py-0.5 rounded-full font-bold">Bàn {{ ticket.table }}</span>
                <span class="text-gray-400 text-xs font-mono">{{ ticket.time }}</span>
              </div>
              <div class="text-sm font-semibold text-gray-200">
                <div v-for="item in ticket.items" :key="item.id" class="inline-block mr-3">
                  {{ item.name }} x{{ item.qty }}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-red-500 font-bold text-sm">{{ Math.floor(ticket.waitTime / 60) }} phút</div>
              <div class="text-xs text-gray-500">Thời gian chờ</div>
            </div>
          </div>
        </div>
        
        <!-- Footer -->
        <div class="p-4 bg-background border-t border-border flex justify-end">
          <button @click="kitchenStore.showDelayedOrdersModal = false" class="px-5 py-2 rounded-xl bg-gray-700 hover:bg-gray-600 text-foreground font-bold text-sm transition-all">Đóng</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';
import { supabase } from '@/lib/supabase';
import { useRealtime } from '@/composables/useRealtime';
import { mockQCOrders, mockRemakeQueue, mockStatistics } from '@/data/mockExpoData';
import { useKitchenStore } from '@/stores/kitchen';
import HeaderButtons from '@/components/HeaderButtons.vue';

const { watchTable } = useRealtime();
const kitchenStore = useKitchenStore();


// Types
interface OrderItem {
  id: string;
  name: string;
  qty: number;
  note?: string;
  done: boolean;
}

interface Order {
  id: string;
  table: string;
  time: string;
  timestamp: number;
  waitTime: number;
  items: OrderItem[];
  status: 'pending' | 'preparing' | 'ready' | 'done';
}

interface RemakeItem {
  id: string;
  table: string;
  items: Array<{ name: string; qty: number }>;
  reason: string;
  severity: string;
  status: 'Pending' | 'Preparing' | 'Completed';
  elapsedTime: number;
  timestamp: number;
}

// State
const currentTime = ref('');
const orders = ref<Order[]>([]);
const tableMap = ref<Record<string, string>>({});
const qcActiveFilter = ref<'waiting' | 'passed' | 'remake' | 'allergy'>('waiting');

// Session trackings to override database state on frontend
const passedQcOrderIds = ref<string[]>([]);
const localRemakeOrderIds = ref<string[]>([]);
const remakeQueue = ref<RemakeItem[]>([]);
const wasteLog = ref<any[]>([]);

// Active Checklists per order
const orderChecklistState = ref<Record<string, Record<string, boolean>>>({});

// Modals State
const showQcFailModal = ref(false);
const showQcPassModal = ref(false);
const selectedQcOrder = ref<Order | null>(null);

const qcFailSelectedReason = ref('Cháy / Quá chín');
const qcFailCustomReason = ref('');
const qcFailSeverity = ref('Trung bình');
const qcFailNotes = ref('');

const notificationCount = ref(1);

// Static definitions
const qcCriteriaLabels = {
  plating: 'Hình thức trình bày đẹp, đúng dĩa quy định',
  temperature: 'Nhiệt độ món ăn đạt chuẩn (≥ 60°C đối với đồ nóng)',
  portion: 'Định lượng đúng chuẩn định mức (sai số tối đa ±10%)',
  allergy: 'Đáp ứng các lưu ý dị ứng của khách (Đã kiểm tra kỹ)',
  taste: 'Mùi vị đạt tiêu chuẩn (đặc biệt các món nướng tái/chín)'
};

const qcFailureReasons = [
  'Cháy / Quá chín',
  'Sống / Chưa đạt độ chín',
  'Sai định lượng',
  'Sai ghi chú (Không hành, ít cay...)',
  'Dị ứng / Kiêng kỵ (NGHIÊM TRỌNG)',
  'Hình thức không đạt',
  'Nhiệt độ không đạt',
  'Khác'
];

let clockInterval: any = null;
let secondsInterval: any = null;

// Sound Effects (Web Audio API Synthesizer)
const playSound = (type: 'newTicket' | 'allergyAlert' | 'passed' | 'failed' | 'bell' | 'remakeCreated') => {
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    
    if (type === 'newTicket') {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, ctx.currentTime);
      gain.gain.setValueAtTime(0.08, ctx.currentTime);
      osc.start();
      osc.stop(ctx.currentTime + 0.12);
      
      setTimeout(() => {
        const osc2 = ctx.createOscillator();
        const gain2 = ctx.createGain();
        osc2.connect(gain2);
        gain2.connect(ctx.destination);
        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(880, ctx.currentTime);
        gain2.gain.setValueAtTime(0.08, ctx.currentTime);
        osc2.start();
        osc2.stop(ctx.currentTime + 0.2);
      }, 120);
    } else if (type === 'allergyAlert') {
      const now = ctx.currentTime;
      for (let i = 0; i < 3; i++) {
        const t = now + i * 0.35;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(987.77, t);
        gain.gain.setValueAtTime(0.12, t);
        gain.gain.exponentialRampToValueAtTime(0.01, t + 0.22);
        osc.start(t);
        osc.stop(t + 0.25);
      }
    } else if (type === 'passed') {
      const notes = [523.25, 659.25, 783.99, 1046.5];
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, ctx.currentTime + idx * 0.08);
        gain.gain.setValueAtTime(0.06, ctx.currentTime + idx * 0.08);
        gain.gain.exponentialRampToValueAtTime(0.005, ctx.currentTime + idx * 0.08 + 0.2);
        osc.start(ctx.currentTime + idx * 0.08);
        osc.stop(ctx.currentTime + idx * 0.08 + 0.22);
      });
    } else if (type === 'failed') {
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gain = ctx.createGain();
      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(ctx.destination);
      osc1.type = 'triangle';
      osc2.type = 'sine';
      osc1.frequency.setValueAtTime(220, ctx.currentTime);
      osc2.frequency.setValueAtTime(216, ctx.currentTime);
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.35);
      osc1.start();
      osc2.start();
      osc1.stop(ctx.currentTime + 0.4);
      osc2.stop(ctx.currentTime + 0.4);
    } else if (type === 'bell') {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1480, ctx.currentTime);
      gain.gain.setValueAtTime(0.12, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.7);
      osc.start();
      osc.stop(ctx.currentTime + 0.8);
    } else if (type === 'remakeCreated') {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(329.63, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(440.00, ctx.currentTime + 0.28);
      gain.gain.setValueAtTime(0.1, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.32);
      osc.start();
      osc.stop(ctx.currentTime + 0.35);
    }
  } catch (e) {
    console.warn('Synthesis failed:', e);
  }
};

// Table Translation
const fetchTableMap = async () => {
  try {
    const { data } = await supabase.from('tables').select('id, code');
    if (data) {
      const map: Record<string, string> = {};
      data.forEach((t: any) => {
        map[t.id] = t.code;
      });
      tableMap.value = map;
    }
  } catch (e) {
    console.error('Error table mappings:', e);
  }
};

const getTableCode = (tableId: string): string => {
  return tableMap.value[tableId] || tableId;
};

// Check if an item contains allergen triggers
const isItemAllergen = (name: string): boolean => {
  const n = name.toLowerCase();
  return n.includes('sườn') || n.includes('bò') || n.includes('lẩu') || n.includes('đậu') || n.includes('hải sản');
};

const hasOrderAllergy = (order: Order): boolean => {
  return order.items.some(i => i.note && (
    i.note.toLowerCase().includes('dị ứng') || 
    i.note.toLowerCase().includes('không hành') || 
    i.note.toLowerCase().includes('đậu phộng') || 
    i.note.toLowerCase().includes('allergy')
  ));
};

const getOrderAllergyNotes = (order: Order): string => {
  const notes = order.items.filter(i => i.note).map(i => `${i.name}: ${i.note}`).join('; ');
  return notes || 'Khách dị ứng thành phần món ăn';
};

// Remake checkings
const isOrderRemake = (orderId: string): boolean => {
  return localRemakeOrderIds.value.includes(orderId);
};

// Counters
const activeQcCount = computed(() => {
  return orders.value.filter(o => o.status === 'ready' && !passedQcOrderIds.value.includes(o.id)).length;
});

const allergyQcCount = computed(() => {
  return orders.value.filter(o => o.status === 'ready' && !passedQcOrderIds.value.includes(o.id) && hasOrderAllergy(o)).length;
});

const remakeOrdersCount = computed(() => {
  return remakeQueue.value.length;
});

const pendingOrdersCount = computed(() => {
  return orders.value.filter(o => (o.status === 'pending' || o.status === 'preparing') && !passedQcOrderIds.value.includes(o.id)).length;
});

// Computed list based on active filter
const filteredQcOrders = computed(() => {
  const activeList = orders.value.filter(o => o.status === 'ready' && !passedQcOrderIds.value.includes(o.id));
  
  if (qcActiveFilter.value === 'allergy') {
    return activeList.filter(o => hasOrderAllergy(o));
  }
  if (qcActiveFilter.value === 'passed') {
    return orders.value.filter(o => passedQcOrderIds.value.includes(o.id));
  }
  if (qcActiveFilter.value === 'remake') {
    return activeList.filter(o => isOrderRemake(o.id));
  }
  return activeList;
});

const activeRemakes = computed(() => {
  return remakeQueue.value;
});

// Sound alerts on incoming allergy ticket
const checkIncomingTicketsForAllergy = (order: Order) => {
  if (hasOrderAllergy(order)) {
    playSound('allergyAlert');
    notificationCount.value++;
  } else {
    playSound('newTicket');
  }
};

// QC Pass logic
const openQcPass = (order: Order) => {
  selectedQcOrder.value = order;
  // Pre-fill checklist state if not fully checked
  if (!orderChecklistState.value[order.id]) {
    orderChecklistState.value[order.id] = { plating: true, temperature: true, portion: true, allergy: true, taste: true };
  } else {
    // Force set checkmarks
    orderChecklistState.value[order.id] = { plating: true, temperature: true, portion: true, allergy: true, taste: true };
  }
  showQcPassModal.value = true;
};

const submitQcPass = () => {
  if (!selectedQcOrder.value) return;
  const order = selectedQcOrder.value;
  
  // Save to passed local array
  passedQcOrderIds.value.push(order.id);
  localStorage.setItem('expo_passed_orders', JSON.stringify(passedQcOrderIds.value));
  
  // If order was in remake queue, mark as completed
  const remakeIdx = remakeQueue.value.findIndex(r => r.id === order.id);
  if (remakeIdx !== -1) {
    remakeQueue.value.splice(remakeIdx, 1);
    saveRemakeQueue();
  }
  
  // Update stats
  stats.value.totalQC++;
  stats.value.firstPass++;
  stats.value.passRate = Math.round((stats.value.firstPass / stats.value.totalQC) * 100);
  
  // Sound
  playSound('passed');
  
  showQcPassModal.value = false;
  selectedQcOrder.value = null;
};

// QC Fail logic
const openQcFail = (order: Order) => {
  selectedQcOrder.value = order;
  qcFailSelectedReason.value = 'Cháy / Quá chín';
  qcFailCustomReason.value = '';
  qcFailSeverity.value = 'Trung bình';
  qcFailNotes.value = '';
  showQcFailModal.value = true;
};

const submitQcFail = async (shouldRemake: boolean) => {
  if (!selectedQcOrder.value) return;
  const order = selectedQcOrder.value;
  
  const finalReason = qcFailSelectedReason.value === 'Khác' ? qcFailCustomReason.value : qcFailSelectedReason.value;
  
  // Add to waste logs
  const wasteItem = {
    id: Math.random().toString(),
    orderId: order.id,
    table: order.table,
    items: order.items.map(i => ({ name: i.name, qty: i.qty })),
    reason: finalReason,
    severity: qcFailSeverity.value,
    notes: qcFailNotes.value,
    timestamp: Date.now()
  };
  wasteLog.value.push(wasteItem);
  localStorage.setItem('expo_waste_log', JSON.stringify(wasteLog.value));
  
  if (shouldRemake) {
    // 1. Move database status back to preparing so kitchen cooks it again
    try {
      await supabase.from('orders').update({ status: 'Preparing' }).eq('id', order.id);
      await supabase.from('order_items').update({ status: 'Preparing' }).eq('order_id', order.id);
    } catch (e) {
      console.error('Error database update:', e);
    }
    
    // 2. Mark as remake in localStorage
    if (!localRemakeOrderIds.value.includes(order.id)) {
      localRemakeOrderIds.value.push(order.id);
      localStorage.setItem('kds_remake_orders', JSON.stringify(localRemakeOrderIds.value));
    }
    
    // 3. Add to local remake queue (Expo screen display)
    const newRemake: RemakeItem = {
      id: order.id,
      table: order.table,
      items: order.items.map(i => ({ name: i.name, qty: i.qty })),
      reason: finalReason,
      severity: qcFailSeverity.value,
      status: 'Preparing',
      elapsedTime: 0,
      timestamp: Date.now()
    };
    // Prepend (High priority remake P1 pushes to top)
    remakeQueue.value.unshift(newRemake);
    saveRemakeQueue();
    
    // Play sound
    playSound('remakeCreated');
  } else {
    // Just cancel/waste it, remove from active list
    passedQcOrderIds.value.push(order.id);
    localStorage.setItem('expo_passed_orders', JSON.stringify(passedQcOrderIds.value));
    playSound('failed');
  }
  
  // Update stats
  stats.value.totalQC++;
  stats.value.remakeRate = Math.round((wasteLog.value.length / stats.value.totalQC) * 1000) / 10;
  stats.value.passRate = Math.round((stats.value.firstPass / stats.value.totalQC) * 100);
  
  showQcFailModal.value = false;
  selectedQcOrder.value = null;
};

// Runner calling behaviors
const triggerRunnerCall = (method: 'bell' | 'notify' | 'voice') => {
  if (method === 'bell') {
    playSound('bell');
  } else if (method === 'notify') {
    playSound('newTicket');
  } else {
    playSound('bell');
  }
};

const clearLocalNotifications = () => {
  notificationCount.value = 0;
};

const formatWaitTime = (seconds: number): string => {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
};

// Local storage save/load helpers
const saveRemakeQueue = () => {
  localStorage.setItem('expo_remake_queue', JSON.stringify(remakeQueue.value));
};

const loadState = () => {
  // Remake IDs
  const rawRemakeIds = localStorage.getItem('kds_remake_orders');
  if (rawRemakeIds) {
    localRemakeOrderIds.value = JSON.parse(rawRemakeIds);
  }
  
  // Passed IDs
  const rawPassedIds = localStorage.getItem('expo_passed_orders');
  if (rawPassedIds) {
    passedQcOrderIds.value = JSON.parse(rawPassedIds);
  }
  
  // Remake queue details
  const rawQueue = localStorage.getItem('expo_remake_queue');
  if (rawQueue) {
    remakeQueue.value = JSON.parse(rawQueue);
  }
  
  // Waste log
  const rawWaste = localStorage.getItem('expo_waste_log');
  if (rawWaste) {
    wasteLog.value = JSON.parse(rawWaste);
  }
};

// Mock Order generators for local demo & verification
const insertMockOrder = () => {
  const mockId = 'demo-' + Math.floor(Math.random() * 10000);
  const mockOrder: Order = {
    id: mockId,
    table: 'table-A01',
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    timestamp: Date.now(),
    waitTime: 0,
    status: 'ready',
    items: [
      { id: mockId + '-1', name: 'Sườn Wagyu Xốt Ushiyoshi', qty: 2, done: true },
      { id: mockId + '-2', name: 'Lẩu Sukiyaki', qty: 1, done: true }
    ]
  };
  
  orders.value.push(mockOrder);
  orderChecklistState.value[mockId] = { plating: false, temperature: false, portion: false, allergy: false, taste: false };
  checkIncomingTicketsForAllergy(mockOrder);
};

const insertMockAllergyOrder = () => {
  const mockId = 'demo-' + Math.floor(Math.random() * 10000);
  const mockOrder: Order = {
    id: mockId,
    table: 'table-B02',
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    timestamp: Date.now(),
    waitTime: 0,
    status: 'ready',
    items: [
      { id: mockId + '-1', name: 'Thăn Ngoại Wagyu Chọn Lọc', qty: 1, note: 'DỊ ỨNG ĐẬU PHỘNG', done: true },
      { id: mockId + '-2', name: 'Lưỡi bò cắt dày', qty: 2, done: true }
    ]
  };
  
  orders.value.push(mockOrder);
  orderChecklistState.value[mockId] = { plating: false, temperature: false, portion: false, allergy: false, taste: false };
  checkIncomingTicketsForAllergy(mockOrder);
};

const stats = ref({
  passRate: mockStatistics.passRate,
  remakeRate: mockStatistics.remakeRate,
  avgQCTime: mockStatistics.avgQCTime,
  totalQC: mockStatistics.totalQC,
  firstPass: mockStatistics.firstPass
});

const loadMockExpoData = () => {
  mockQCOrders.forEach((order: any) => {
    const d = new Date(order.createdAt);
    const mappedOrder: Order = {
      id: order.id,
      table: order.tableNumber,
      time: d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      timestamp: d.getTime(),
      waitTime: Math.floor((Date.now() - d.getTime()) / 1000),
      status: 'ready',
      items: order.items.map((i: any) => ({
        id: i.id,
        name: i.name,
        qty: i.quantity,
        note: order.allergyInfo || '',
        done: i.status === 'cooked'
      }))
    };
    if (!orders.value.some(existing => existing.id === mappedOrder.id)) {
      orders.value.push(mappedOrder);
      orderChecklistState.value[mappedOrder.id] = { ...order.checklist };
    }
  });

  mockRemakeQueue.forEach((remake: any) => {
    const existing = remakeQueue.value.find(r => r.id === remake.id);
    if (!existing) {
      remakeQueue.value.push({
        id: remake.id,
        table: remake.tableNumber,
        items: [{ name: remake.itemName, qty: remake.quantity }],
        reason: remake.reason,
        severity: remake.severity,
        status: remake.status === 'cooking' ? 'Preparing' : 'Pending',
        elapsedTime: Math.floor((Date.now() - remake.createdAt.getTime()) / 1000),
        timestamp: remake.createdAt.getTime()
      });
    }
  });
};

// Sync lists to kitchenStore
watch(orders, (newOrders) => {
  kitchenStore.qcQueue = newOrders.filter(o => o.status === 'ready' && !passedQcOrderIds.value.includes(o.id));
  kitchenStore.delayedTickets = newOrders.filter(o => o.status !== 'done' && o.status !== 'ready' && o.waitTime >= 900);
}, { deep: true, immediate: true });

watch(passedQcOrderIds, (newPassed) => {
  kitchenStore.qcQueue = orders.value.filter(o => o.status === 'ready' && !newPassed.includes(o.id));
}, { deep: true });

onMounted(async () => {
  loadState();
  await fetchTableMap();
  
  // Set mock data
  loadMockExpoData();
  insertMockOrder();
  
  // Update clocks & times
  clockInterval = setInterval(() => {
    currentTime.value = new Date().toLocaleTimeString('vi-VN');
  }, 1000);

  secondsInterval = setInterval(() => {
    const now = Date.now();
    orders.value.forEach(order => {
      order.waitTime = Math.floor((now - order.timestamp) / 1000);
    });
    remakeQueue.value.forEach(remake => {
      remake.elapsedTime = Math.floor((now - remake.timestamp) / 1000);
    });
  }, 1000);

  // Realtime Database fetch
  try {
    const { data: rawOrders } = await supabase
      .from('orders')
      .select('id, table_id, created_at, status, order_items(id, name_snapshot, quantity, note, status)');
    
    if (rawOrders && rawOrders.length > 0) {
      const dbOrders = rawOrders.map((ro: any) => {
        const d = new Date(ro.created_at);
        let st: 'pending'|'preparing'|'ready'|'done' = 'pending';
        if (ro.status === 'Preparing') st = 'preparing';
        if (ro.status === 'Served') st = 'ready';
        if (ro.status === 'Paid') st = 'done';
        
        return {
          id: ro.id,
          table: ro.table_id || 'T-??',
          time: d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          timestamp: d.getTime(),
          waitTime: Math.floor((Date.now() - d.getTime()) / 1000),
          status: st,
          items: (ro.order_items || []).map((ri: any) => ({
            id: ri.id,
            name: ri.name_snapshot,
            qty: ri.quantity,
            note: ri.note,
            done: ri.status === 'Served' || ri.status === 'Paid'
          }))
        };
      });
      // Append to local list
      dbOrders.forEach((o: Order) => {
        if (!orders.value.some(existing => existing.id === o.id)) {
          orders.value.push(o);
          orderChecklistState.value[o.id] = { plating: false, temperature: false, portion: false, allergy: false, taste: false };
        }
      });
    }
  } catch (e) {
    console.warn('Realtime fetch failed, relying on mock data:', e);
  }

  // Subscribe to realtime updates
  watchTable('orders', '*', (payload) => {
    const order = payload.new as any;
    if (!order || !order.id) return;
    
    const existing = orders.value.find(o => o.id === order.id);
    const d = new Date(order.created_at || Date.now());
    let st: 'pending'|'preparing'|'ready'|'done' = 'pending';
    if (order.status === 'Preparing') st = 'preparing';
    if (order.status === 'Served') st = 'ready';
    if (order.status === 'Paid') st = 'done';

    if (existing) {
      existing.status = st;
      if (st === 'ready') {
        checkIncomingTicketsForAllergy(existing);
      }
    } else {
      const newOrder: Order = {
        id: order.id,
        table: order.table_id || 'T-??',
        time: d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        timestamp: d.getTime(),
        waitTime: 0,
        status: st,
        items: []
      };
      orders.value.push(newOrder);
      orderChecklistState.value[order.id] = { plating: false, temperature: false, portion: false, allergy: false, taste: false };
      if (st === 'ready') {
        checkIncomingTicketsForAllergy(newOrder);
      }
    }
  });

  watchTable('order_items', '*', (payload) => {
    const item = payload.new as any;
    if (!item) return;
    
    for (const o of orders.value) {
      if (o.id === item.order_id) {
        const existingItem = o.items.find(i => i.id === item.id);
        if (existingItem) {
          existingItem.done = (item.status === 'Served' || item.status === 'Paid');
        } else {
          o.items.push({
            id: item.id,
            name: item.name_snapshot,
            qty: item.quantity,
            note: item.note,
            done: item.status === 'Served' || item.status === 'Paid'
          });
        }
      }
    }
  });
});

onUnmounted(() => {
  if (clockInterval) clearInterval(clockInterval);
  if (secondsInterval) clearInterval(secondsInterval);
});
</script>

<style scoped>
/* Header Navigation Styles */
.header-navigation {
  display: flex;
  gap: 12px;
  margin-left: 24px;
}

.nav-btn {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  border: 2px solid transparent;
  min-height: 38px;
}

.nav-btn.expo {
  background: #9C27B0; /* Tím */
  color: white;
}

.nav-btn.expo:hover {
  background: #7B1FA2;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(156, 39, 176, 0.3);
}

.nav-btn.kds {
  background: #2196F3; /* Xanh dương */
  color: white;
}

.nav-btn.kds:hover {
  background: #1976D2;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(33, 150, 243, 0.3);
}

.nav-btn.active {
  border-color: #FFFFFF;
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.2);
}

.notification-badge {
  background: #F44336;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
  margin-left: 4px;
}

/* 1. EXPO HEADER (70px) */
.expo-header {
  background: linear-gradient(135deg, #1A1A1A 0%, #2D2D2D 100%);
  height: 70px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  border-bottom: 2px solid #FF6B35;
  box-shadow: 0 2px 8px rgba(0,0,0,0.4);
}

.expo-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.expo-title-icon {
  font-size: 28px;
}

.expo-title-text {
  font-size: 22px;
  font-weight: 700;
  color: #FF6B35;
  letter-spacing: 1px;
}

.expo-badge {
  background: #9C27B0;
  color: white;
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  margin-left: 8px;
}

.chef-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #3D3D3D;
  border-radius: 8px;
}

.chef-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #FF6B35;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  color: white;
  font-weight: 700;
}

.chef-name {
  font-size: 14px;
  color: #E0E0E0;
}

.chef-role {
  font-size: 11px;
  color: #B0B0B0;
}

.expo-clock {
  font-family: 'Courier New', monospace;
  font-size: 22px;
  color: #FFFFFF;
  font-weight: 700;
}

.notification-bell {
  position: relative;
  padding: 12px;
  background: #3D3D3D;
  border-radius: 8px;
  cursor: pointer;
}

.notification-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #F44336;
  color: white;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
}

/* 2. QC QUEUE BAR (60px) */
.qc-queue-bar {
  background: #2D2D2D;
  height: 60px;
  display: flex;
  align-items: center;
  padding: 0 24px;
  gap: 16px;
  border-bottom: 1px solid #404040;
}

.qc-counter {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid transparent;
}

.qc-counter:hover {
  transform: translateY(-2px);
}

.qc-counter.active {
  border-color: rgba(255, 255, 255, 0.4);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
}

.qc-counter.waiting {
  background: #1A237E;
  color: white;
}

.qc-counter.passed {
  background: #2E7D32;
  color: white;
}

.qc-counter.remake {
  background: #9C27B0;
  color: white;
  animation: pulse-remake 2s infinite;
}

.qc-counter.allergy {
  background: #FF5722;
  color: white;
  animation: blink 1.2s infinite;
}

.counter-number {
  background: rgba(255,255,255,0.3);
  padding: 2px 12px;
  border-radius: 12px;
  font-size: 18px;
  font-weight: 700;
}

/* 3. QC ACTIVE CARD */
.qc-active-card {
  background: #2D2D2D;
  border: 3px solid #FF9800; /* Cam - đang chờ QC */
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 16px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  transition: all 0.3s ease;
}

.qc-active-card.has-allergy {
  border-color: #F44336; /* Đỏ - có dị ứng */
  background: linear-gradient(135deg, #2D2D2D 0%, #3D1F1F 100%);
  animation: pulse-border-red 2s infinite;
}

.qc-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 16px;
  border-bottom: 2px solid #404040;
  margin-bottom: 16px;
}

.qc-ticket-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.qc-ticket-number {
  font-size: 24px;
  font-weight: 900;
  color: #FFFFFF;
}

.qc-table-info {
  font-size: 14px;
  color: #B0B0B0;
}

.qc-timer {
  font-family: 'Courier New', monospace;
  font-size: 22px;
  font-weight: 700;
  color: #FF9800;
}

.qc-timer.urgent {
  color: #F44336;
  animation: blink 1s infinite;
}

.allergy-badge {
  background: #F44336;
  color: white;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  animation: blink 1s infinite;
}

/* Items List */
.qc-items-list {
  margin-bottom: 20px;
}

.qc-item {
  background: #1A1A1A;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 12px;
  border-left: 4px solid #FF9800;
}

.qc-item.has-allergy {
  border-left-color: #F44336;
  background: linear-gradient(90deg, #1A1A1A 0%, #2D1515 100%);
}

.qc-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.qc-item-name {
  font-size: 18px;
  font-weight: 700;
  color: #FFFFFF;
}

.qc-item-qty {
  font-size: 20px;
  font-weight: 900;
  color: #FF9800;
}

.qc-item-status {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.status-pending {
  background: #FF9800;
  color: white;
}

.status-passed {
  background: #4CAF50;
  color: white;
}

.status-failed {
  background: #F44336;
  color: white;
}

/* Allergy Warning */
.allergy-warning {
  background: rgba(244, 67, 54, 0.2);
  border: 2px solid #F44336;
  color: #F44336;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 700;
  margin: 12px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

/* QC Specs */
.qc-specs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}

.qc-spec {
  background: #3D3D3D;
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  color: #B0B0B0;
}

.qc-spec-icon {
  margin-right: 4px;
}

/* Checklist */
.qc-checklist {
  background: #1A1A1A;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 20px;
}

.checklist-title {
  font-size: 14px;
  font-weight: 600;
  color: #E0E0E0;
  margin-bottom: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.checklist-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #404040;
  cursor: pointer;
  transition: all 0.2s;
}

.checklist-item:last-child {
  border-bottom: none;
}

.checklist-item:hover {
  background: rgba(255,255,255,0.05);
  border-radius: 6px;
  padding-left: 8px;
}

.checklist-checkbox {
  width: 24px;
  height: 24px;
  border: 2px solid #616161;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.checklist-item.checked .checklist-checkbox {
  background: #4CAF50;
  border-color: #4CAF50;
}

.checklist-label {
  font-size: 14px;
  color: #E0E0E0;
  flex: 1;
}

.checklist-item.checked .checklist-label {
  color: #4CAF50;
  text-decoration: line-through;
}

/* Action Buttons */
.qc-actions {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 12px;
}

.qc-btn {
  padding: 16px 24px;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.qc-btn.fail {
  background: #C62828;
  color: white;
}

.qc-btn.fail:hover {
  background: #B71C1C;
  transform: scale(1.02);
}

.qc-btn.pass {
  background: #2E7D32;
  color: white;
}

.qc-btn.pass:hover {
  background: #1B5E20;
  transform: scale(1.02);
}

.qc-btn:active {
  transform: scale(0.98);
}

/* 4. REMAKE QUEUE */
.remake-queue {
  background: #252525;
  border-radius: 12px;
  padding: 16px;
  border: 2px solid #9C27B0;
}

.remake-queue-title {
  font-size: 16px;
  font-weight: 700;
  color: #CE93D8;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.remake-card {
  background: #1A1A1A;
  border: 2px solid #9C27B0;
  border-radius: 10px;
  padding: 14px;
  margin-bottom: 12px;
  position: relative;
}

.remake-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.remake-ticket {
  font-size: 16px;
  font-weight: 800;
  color: #FFFFFF;
}

.remake-priority {
  background: #F44336;
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
}

.remake-reason {
  font-size: 12px;
  color: #FF9800;
  margin-top: 6px;
  font-style: italic;
}

.remake-status {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.remake-status.cooking {
  background: #E65100;
  color: white;
}

.remake-status.waiting {
  background: #1A237E;
  color: white;
}

/* Statistics Panel */
.statistics-panel {
  background: #1A1A1A;
  border-radius: 10px;
  padding: 16px;
  border: 1px solid #333;
}

.statistics-title {
  font-size: 12px;
  font-weight: 600;
  color: #B0B0B0;
  margin-bottom: 12px;
  text-transform: uppercase;
}

.statistics-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.stat-box {
  background: #2D2D2D;
  padding: 10px;
  border-radius: 8px;
  text-align: center;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: #FFFFFF;
}

.stat-value.good { color: #4CAF50; }
.stat-value.warning { color: #FF9800; }
.stat-value.info { color: #2196F3; }

.stat-label {
  font-size: 10px;
  color: #B0B0B0;
  margin-top: 4px;
  text-transform: uppercase;
}

/* Modals General */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.modal-content {
  background: #2D2D2D;
  border-radius: 16px;
  width: 90%;
  max-height: 90vh;
  border: 1px solid #404040;
  box-shadow: 0 10px 25px rgba(0,0,0,0.5);
  animation: fade-in 0.2s ease;
}

.modal-header {
  padding: 20px 24px;
  border-bottom: 2px solid #404040;
}

.modal-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  min-width: 120px;
  min-height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-btn.cancel {
  background: #424242;
  color: white;
}

.modal-btn.cancel:hover {
  background: #4f4f4f;
  transform: scale(1.02);
}

/* Remake Modal Specific */
.remake-modal .modal-header {
  background: linear-gradient(135deg, #C62828 0%, #B71C1C 100%);
  color: white;
}

.reason-group {
  margin-bottom: 20px;
}

.reason-group-title {
  font-size: 13px;
  font-weight: 700;
  color: #FF9800;
  margin-bottom: 12px;
  text-transform: uppercase;
}

.reason-option {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: #1A1A1A;
  border-radius: 8px;
  margin-bottom: 4px;
  cursor: pointer;
  transition: all 0.2s;
  border: 2px solid transparent;
}

.reason-option:hover {
  background: #2D2D2D;
  border-color: #FF9800;
}

.reason-option.selected {
  background: rgba(244, 67, 54, 0.2);
  border-color: #F44336;
}

.reason-radio {
  width: 20px;
  height: 20px;
  border: 2px solid #616161;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.reason-option.selected .reason-radio {
  border-color: #F44336;
  background: #F44336;
}

.reason-option.selected .reason-radio::after {
  content: "";
  width: 8px;
  height: 8px;
  background: white;
  border-radius: 50%;
}

.reason-label {
  font-size: 14px;
  color: #E0E0E0;
  flex: 1;
}

.reason-option.selected .reason-label {
  color: #FFFFFF;
  font-weight: 600;
}

.severity-group {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-bottom: 20px;
}

.severity-option {
  padding: 16px;
  background: #1A1A1A;
  border: 2px solid #404040;
  border-radius: 10px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.severity-option:hover {
  border-color: #FF9800;
}

.severity-option.selected.low {
  background: rgba(76, 175, 80, 0.2);
  border-color: #4CAF50;
}

.severity-option.selected.medium {
  background: rgba(255, 152, 0, 0.2);
  border-color: #FF9800;
}

.severity-option.selected.high {
  background: rgba(244, 67, 54, 0.2);
  border-color: #F44336;
}

.severity-icon {
  font-size: 24px;
  margin-bottom: 6px;
}

.severity-label {
  font-size: 12px;
  font-weight: 600;
  color: #E0E0E0;
}

.priority-notice {
  background: rgba(156, 39, 176, 0.2);
  border: 2px solid #9C27B0;
  color: #CE93D8;
  padding: 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 700;
  text-align: center;
  margin-bottom: 20px;
}

/* Animations */
@keyframes pulse-border-red {
  0%, 100% {
    border-color: #F44336;
    box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4);
  }
  50% {
    border-color: #FF5722;
    box-shadow: 0 0 0 12px rgba(244, 67, 54, 0);
  }
}

@keyframes pulse-remake {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(156, 39, 176, 0.4);
  }
  50% {
    box-shadow: 0 0 0 12px rgba(156, 39, 176, 0);
  }
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

@keyframes slide-in-right {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes fade-in {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

/* Responsive Grid */
@media (min-width: 1366px) {
  .main-workspace {
    display: flex;
  }
}

/* Accessibility Focus States */
button:focus-visible,
input:focus-visible,
textarea:focus-visible {
  outline: 3px solid #2196F3;
  outline-offset: 2px;
}

@media (prefers-contrast: high) {
  .qc-active-card {
    border-width: 4px;
  }
  .qc-btn {
    border: 2px solid currentColor;
  }
}

@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Nav Tabs redesign */
.nav-tabs {
  display: flex;
  gap: 4px;
  background: #1A1A1A;
  padding: 4px;
  border-radius: 10px;
  margin-left: 20px;
}

.nav-tab {
  padding: 8px 16px;
  border-radius: 8px;
  color: #B0B0B0;
  font-weight: 600;
  font-size: 13px;
  text-decoration: none;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
  cursor: pointer;
}

.nav-tab:hover {
  color: white;
  background: rgba(255, 255, 255, 0.05);
}

.nav-tab.active {
  background: #2196F3;
  color: white;
}

.nav-tab.expo.active {
  background: #9C27B0;
}

.nav-tab .badge {
  background: #F44336;
  color: white;
  padding: 1px 6px;
  border-radius: 10px;
  font-size: 10px;
  font-weight: 700;
}
</style>
