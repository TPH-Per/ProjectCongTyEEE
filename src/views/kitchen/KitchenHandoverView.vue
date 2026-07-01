<!-- KitchenHandoverView.vue -->
<template>
  <div class="handover-view min-h-screen flex flex-col bg-background text-foreground p-6">
    
    <!-- PAGE HEADER -->
    <header class="flex justify-between items-center mb-6 pb-4 border-b border-border">
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2">
          <span class="logo-brand text-[#FF9800] font-extrabold tracking-wider text-xl">{{ $t('kitchen_handover.brand') }}</span>
          <span class="tag-handover bg-[#9C27B0]/20 text-[#9C27B0] border border-[#9C27B0]/30 text-xs px-2.5 py-0.5 rounded font-bold">{{ $t('kitchen_handover.handover_badge') }}</span>
        </div>
        <div class="h-6 w-[1px] bg-muted"></div>
        <h2 class="text-lg font-bold text-foreground uppercase tracking-wide">{{ $t('kitchen_handover.title') }}</h2>
      </div>

      <!-- Action buttons -->
      <div class="flex items-center gap-3">
        <button 
          class="bg-muted border border-border hover:bg-muted text-xs font-bold px-4 py-2 rounded-xl transition"
          @click="activeSubTab = activeSubTab === 'wizard' ? 'history' : 'wizard'"
        >
          {{ activeSubTab === 'wizard' ? t('kitchen_handover.view_history') : t('kitchen_handover.new_handover') }}
        </button>
        <button class="bg-muted text-xs font-bold px-4 py-2 rounded-xl border border-transparent hover:border-[#FF9800] transition" @click="navigateBack">
          📺 Quay lại KDS
        </button>
      </div>
    </header>

    <!-- TAB: HISTORY LOGS VIEW -->
    <div v-if="activeSubTab === 'history'" class="animate-fade-in flex-1">
      <div class="max-w-4xl mx-auto space-y-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_handover.history_title') }}</h3>
          <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.history_desc') }}</span>
        </div>

        <div v-if="closedShifts.length === 0" class="text-center py-12 text-muted-foreground bg-card rounded-xl border border-border">
          📭 Chưa có nhật ký bàn giao ca nào được lưu.
        </div>
        
        <div v-else class="space-y-6">
          <div 
            v-for="log in closedShifts" 
            :key="log.id"
            class="bg-card rounded-xl border border-border p-6 shadow-lg"
          >
            <div class="flex justify-between items-start flex-wrap gap-2 mb-4 border-b border-border pb-3">
              <div>
                <span class="text-xs font-bold text-[#FF9800] block uppercase font-mono">Phiếu Bàn Giao: #{{ log.id.substring(0, 8) }}</span>
                <h4 class="text-base font-bold text-foreground mt-1">{{ t('shift.type.' + log.shift_type.toLowerCase()) }}</h4>
              </div>
              <div class="text-right">
                <span class="text-xs text-muted-foreground block font-mono">{{ new Date(log.ended_at || log.created_at).toLocaleString() }}</span>
                <span class="text-xs bg-[#4CAF50]/10 text-green-600 border border-[#4CAF50]/30 px-2 py-0.5 rounded-full font-bold">{{ $t('kitchen_handover.closed_shift') }}</span>
              </div>
            </div>

            <!-- Notes -->
            <div class="mb-4 text-sm text-muted-foreground bg-background p-3 rounded-lg border border-border">
              <span class="font-bold text-[#FF9800] block text-xs uppercase mb-1">{{ $t('kitchen_handover.handover_notes') }}</span>
              <p class="italic whitespace-pre-line">{{ log.handover_note || t('kitchen_handover.no_notes') }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB: NEW HANDOVER WIZARD VIEW -->
    <div v-else class="flex-1 flex flex-col justify-center items-center">
      
      <!-- START SHIFT SCREEN -->
      <div v-if="!activeShift && !handoverSuccess" class="flex-1 flex flex-col justify-center items-center w-full">
        <div class="bg-card rounded-2xl p-8 border border-border text-center max-w-[600px] w-full shadow-2xl animate-fade-in">
          <h3 class="text-2xl font-black text-foreground uppercase tracking-wider mb-2">{{ t('shift.start') }}</h3>
          <p class="text-sm text-muted-foreground mb-6">{{ $t('kitchen_handover.need_new_shift') }}</p>
          
          <div class="flex flex-col gap-4 max-w-sm mx-auto">
            <select v-model="newShiftType" class="bg-background border border-border rounded-xl px-4 py-3 text-sm text-foreground focus:outline-none focus:border-[#FF9800]">
              <option value="MORNING">{{ t('shift.type.morning') }}</option>
              <option value="AFTERNOON">{{ t('shift.type.afternoon') }}</option>
              <option value="EVENING">{{ t('shift.type.evening') }}</option>
              <option value="NIGHT">{{ $t('kitchen_handover.night_shift') }}</option>
            </select>
            <button class="bg-[#FF9800] text-sm font-bold px-5 py-3 rounded-xl text-foreground hover:bg-[#F57C00] shadow-md transition disabled:opacity-50" @click="handleStartShift" :disabled="shiftLoading">
              {{ t('shift.start') }}
            </button>
          </div>
        </div>
      </div>

      <!-- SUCCESS SCREEN -->
      <div v-else-if="handoverSuccess" class="success-panel bg-card rounded-2xl p-8 border border-border text-center max-w-[600px] w-full animate-fade-in shadow-2xl">
        <div class="success-checkmark mb-6">
          <div class="check-icon">
            <span class="icon-line line-tip animate-check-tip"></span>
            <span class="icon-line line-long animate-check-long"></span>
            <div class="icon-circle"></div>
            <div class="icon-fix"></div>
          </div>
        </div>
        
        <h3 class="text-2xl font-black text-foreground uppercase tracking-wider mb-2">{{ $t('kitchen_handover.handover_badge') }} CA THÀNH CÔNG</h3>
        <p class="text-sm text-muted-foreground mb-6">{{ $t('kitchen_handover.success_desc') }}</p>
        
        <div class="flex gap-3 justify-center">
          <button class="bg-[#FF9800] text-xs font-bold px-5 py-3 rounded-xl text-foreground hover:bg-[#F57C00] shadow-md" @click="activeSubTab = 'history'">
            ⏳ Xem danh sách lịch sử đóng ca
          </button>
          <button class="bg-muted text-xs font-bold px-5 py-3 rounded-xl text-foreground hover:bg-muted" @click="resetWizard">
            Tạo ca làm việc mới
          </button>
        </div>
      </div>

      <!-- WIZARD STAGES -->
      <div v-else class="w-full max-w-4xl flex flex-col">
        <!-- Visual pipeline tracker at top of wizard -->
        <div class="flex justify-between items-center mb-8 bg-card p-5 rounded-xl border border-border flex-wrap gap-4">
          <!-- Stepper header -->
          <div class="flex items-center gap-3">
            <span class="text-xs font-bold text-[#FF9800] uppercase tracking-wider">{{ $t('kitchen_handover.handover_progress') }}</span>
          </div>
          <div class="flex items-center gap-3 text-xs font-semibold text-muted-foreground">
            <span :class="wizardStep === 1 ? 'text-[#FF9800] font-bold' : wizardStep > 1 ? 'text-green-500 font-bold' : ''">
              {{ wizardStep > 1 ? '✓ ' : '' }}1. Vệ Sinh & Thiết Bị
            </span>
            <span>➔</span>
            <span :class="wizardStep === 2 ? 'text-[#FF9800] font-bold' : wizardStep > 2 ? 'text-green-500 font-bold' : ''">
              {{ wizardStep > 2 ? '✓ ' : '' }}2. Kiểm Kê & An Toàn
            </span>
            <span>➔</span>
            <span :class="wizardStep === 3 ? 'text-[#FF9800] font-bold' : ''">
              3. Bàn Giao Ca Sau
            </span>
          </div>
        </div>

        <div class="flex-1 bg-card rounded-2xl p-6 border border-border shadow-xl">
          
          <!-- STEP 1: END-OF-SHIFT (Vệ sinh & Thiết bị) -->
          <div v-if="wizardStep === 1" class="space-y-6 animate-fade-in">
            <div class="flex justify-between items-baseline mb-4 border-b border-border pb-3">
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_handover.step1_title') }}</h3>
              <span class="text-xs text-[#FF9800]">{{ $t('kitchen_handover.mandatory_end_shift') }}</span>
            </div>

            <div class="space-y-4">
              <!-- Check 1 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-border transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.stopOrders"
                  class="w-6 h-6 rounded border-border text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">{{ $t('kitchen_handover.stop_orders') }}</span>
                  <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.stop_orders_desc') }}</span>
                </div>
              </label>

              <!-- Check 2 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-border transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.cleanArea"
                  class="w-6 h-6 rounded border-border text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">{{ $t('kitchen_handover.clean_area') }}</span>
                  <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.clean_area_desc') }}</span>
                </div>
              </label>

              <!-- Check 3 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-border transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.powerOff"
                  class="w-6 h-6 rounded border-border text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">{{ $t('kitchen_handover.power_off') }}</span>
                  <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.power_off_desc') }}</span>
                </div>
              </label>
            </div>

            <div class="flex justify-end pt-4 border-t border-border">
              <button 
                class="px-6 py-2.5 bg-[#FF9800] hover:bg-[#F57C00] disabled:opacity-50 disabled:cursor-not-allowed text-foreground font-bold rounded-xl text-xs uppercase transition shadow-md"
                :disabled="!isStep1Complete"
                @click="wizardStep = 2"
              >
                Tiếp tục ➔
              </button>
            </div>
          </div>

          <!-- STEP 2: INVENTORY & SAFETY (Tồn kho & An toàn tủ lạnh) -->
          <div v-else-if="wizardStep === 2" class="space-y-6 animate-fade-in">
            <div class="flex justify-between items-baseline mb-4 border-b border-border pb-3">
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_handover.step2_title') }}</h3>
              <span class="text-xs text-[#FF9800]">{{ $t('kitchen_handover.input_actual_inventory') }}</span>
            </div>

            <!-- Table of stock comparison -->
            <div class="bg-background rounded-xl border border-border overflow-hidden">
              <div class="grid grid-cols-4 gap-2 bg-card p-3 text-xs font-bold text-muted-foreground uppercase tracking-wide">
                <div class="col-span-2">{{ $t('kitchen_handover.ingredient') }}</div>
                <div class="text-center">{{ $t('kitchen_handover.theoretical') }}</div>
                <div class="text-center">{{ $t('kitchen_handover.actual') }}</div>
              </div>
              <div class="divide-y divide-[#404040]">
                <div 
                  v-for="item in inventoryVerifyList" 
                  :key="item.id" 
                  class="grid grid-cols-4 gap-2 p-3 text-sm items-center"
                >
                  <div class="col-span-2 flex items-center gap-2">
                    <span class="text-xl">{{ item.icon }}</span>
                    <div>
                      <span class="font-bold text-foreground block">{{ item.name }}</span>
                      <span class="text-[10px] text-muted-foreground font-mono">Đơn vị: {{ item.unit }}</span>
                    </div>
                  </div>
                  
                  <div class="text-center font-mono font-bold text-muted-foreground">
                    {{ item.theoretical }} {{ item.unit }}
                  </div>
                  
                  <div class="flex items-center justify-center gap-2">
                    <input 
                      v-model.number="item.actual" 
                      type="number" 
                      min="0"
                      class="w-16 text-center bg-card border border-border rounded py-1 text-foreground font-mono font-bold text-xs"
                      @input="calculateDiff(item)"
                    />
                    <span class="text-xs text-muted-foreground font-bold uppercase">{{ item.unit }}</span>
                    
                    <!-- Discrepancy indicator -->
                    <span 
                      v-if="item.diff !== 0" 
                      class="text-xs font-bold font-mono px-1.5 py-0.5 rounded text-right"
                      :class="item.diff < 0 ? 'text-red-600' : 'text-green-600'"
                    >
                      {{ item.diff < 0 ? '' : '+' }}{{ item.diff }}
                    </span>
                    <span v-else class="text-green-600 text-xs">✓</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Waste Log report warning if there's significant shortage -->
            <div v-if="hasSignificantShortage" class="bg-red-100 border border-red-300 rounded-xl p-4 animate-fade-in">
              <span class="text-xs font-bold text-red-600 uppercase tracking-wider block mb-2">
                ⚠️ HỒ SƠ HAO HỤT (WASTE LOG REQUIRED)
              </span>
              <p class="text-xs text-red-700 mb-3">Phát hiện chênh lệch hao hụt lớn (&le; -0.5) so với lý thuyết. Bắt buộc ghi nhận biên bản Waste Log:</p>
              <textarea 
                v-model="wasteNotes"
                placeholder="Giải trình lý do hao hụt (ví dụ: Thịt bò Wagyu bị cháy hủy món bàn 4, Rau bị dập nát hủy bỏ 0.5kg ca sáng...)"
                rows="2"
                class="w-full bg-background border border-border rounded-lg p-3 text-xs text-foreground placeholder-gray-600 focus:outline-none focus:border-[#F44336]"
              ></textarea>
            </div>

            <!-- Safety Checklists -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <label class="flex items-start gap-3 cursor-pointer p-3.5 rounded-xl bg-background border border-border hover:border-border transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.fefoCheck"
                  class="w-5.5 h-5.5 rounded border-border text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-semibold text-foreground block text-sm">{{ $t('kitchen_handover.check_expiry') }}</span>
                  <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.check_expiry_desc') }}</span>
                </div>
              </label>

              <label class="flex items-start gap-3 cursor-pointer p-3.5 rounded-xl bg-background border border-border hover:border-border transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.wrapFood"
                  class="w-5.5 h-5.5 rounded border-border text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-semibold text-foreground block text-sm">{{ $t('kitchen_handover.wrap_food') }}</span>
                  <span class="text-xs text-muted-foreground">{{ $t('kitchen_handover.wrap_food_desc') }}</span>
                </div>
              </label>
            </div>

            <!-- Fridge and Freezer Temperature inputs -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5 p-4 bg-background rounded-xl border border-border">
              <div class="space-y-2">
                <div class="flex justify-between items-baseline">
                  <span class="text-xs font-bold text-muted-foreground uppercase">{{ $t('kitchen_handover.fridge_temp') }}</span>
                  <span class="text-sm font-bold font-mono" :class="fridgeTemp > 5 ? 'text-red-500' : 'text-green-500'">
                    {{ fridgeTemp }}°C
                  </span>
                </div>
                <div class="flex items-center gap-3">
                  <input v-model.number="fridgeTemp" type="range" min="-5" max="15" step="1" class="temp-slider flex-1" />
                  <span v-if="fridgeTemp > 5" class="text-[10px] bg-red-100 text-red-700 border border-red-300 px-1.5 py-0.5 rounded font-bold">{{ $t('kitchen_handover.error') }}</span>
                  <span v-else class="text-[10px] bg-green-100 text-green-500 border border-green-300 px-1.5 py-0.5 rounded font-bold">OK</span>
                </div>
                <span class="text-[10px] text-muted-foreground block italic">Yêu cầu tiêu chuẩn: &le; 5°C</span>
              </div>

              <div class="space-y-2">
                <div class="flex justify-between items-baseline">
                  <span class="text-xs font-bold text-muted-foreground uppercase">{{ $t('kitchen_handover.freezer_temp') }}</span>
                  <span class="text-sm font-bold font-mono" :class="freezerTemp > -15 ? 'text-red-500' : 'text-green-500'">
                    {{ freezerTemp }}°C
                  </span>
                </div>
                <div class="flex items-center gap-3">
                  <input v-model.number="freezerTemp" type="range" min="-30" max="-5" step="1" class="temp-slider flex-1" />
                  <span v-if="freezerTemp > -15" class="text-[10px] bg-red-100 text-red-700 border border-red-300 px-1.5 py-0.5 rounded font-bold">{{ $t('kitchen_handover.error') }}</span>
                  <span v-else class="text-[10px] bg-green-100 text-green-500 border border-green-300 px-1.5 py-0.5 rounded font-bold">OK</span>
                </div>
                <span class="text-[10px] text-muted-foreground block italic">Yêu cầu tiêu chuẩn: &le; -18°C</span>
              </div>
            </div>

            <div class="flex justify-between pt-4 border-t border-border">
              <button 
                class="px-6 py-2.5 bg-muted border border-border hover:bg-muted text-foreground font-bold rounded-xl text-xs uppercase transition"
                @click="wizardStep = 1"
              >
                Quay lại
              </button>
              <button 
                class="px-6 py-2.5 bg-[#FF9800] hover:bg-[#F57C00] disabled:opacity-50 disabled:cursor-not-allowed text-foreground font-bold rounded-xl text-xs uppercase transition shadow-md"
                :disabled="!isStep2Complete"
                @click="wizardStep = 3"
              >
                Tiếp tục ➔
              </button>
            </div>
          </div>

          <!-- STEP 3: HANDOVER (Sổ bàn giao, Ký xác nhận ca sau) -->
          <div v-else-if="wizardStep === 3" class="space-y-6 animate-fade-in">
            <div class="flex justify-between items-baseline mb-4 border-b border-border pb-3">
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_handover.step3') }} & Ký Xác Nhận</h3>
              <span class="text-xs text-[#FF9800]">{{ $t('kitchen_handover.chef_sign') }}</span>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Left side: note inputs -->
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label for="shift-select" class="text-xs text-muted-foreground uppercase font-bold">{{ $t('kitchen_handover.closed_shift_label') }}</label>
                  <input id="shift-select" type="text" :value="t('shift.type.' + (activeShift?.shift_type?.toLowerCase() || ''))" disabled class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-muted-foreground opacity-80" />
                </div>

                <div class="flex flex-col gap-1.5">
                  <label for="incoming-select" class="text-xs text-muted-foreground uppercase font-bold">{{ $t('kitchen_handover.incoming_chef') }}</label>
                  <select 
                    id="incoming-select" 
                    v-model="incomingChef"
                    class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none focus:border-[#FF9800]"
                  >
                    <option value="" disabled>{{ $t('kitchen_handover.select_incoming_chef') }}</option>
                    <option value="Chef Minh">{{ $t('kitchen_handover.chef_minh') }}</option>
                    <option value="Chef Luc">{{ $t('kitchen_handover.chef_luc') }}</option>
                    <option value="Chef Kien">{{ $t('kitchen_handover.chef_kien') }}</option>
                    <option value="Chef Hanh">{{ $t('kitchen_handover.chef_hanh') }}</option>
                  </select>
                </div>

                <div class="flex flex-col gap-1.5">
                  <label for="notes-handover" class="text-xs text-muted-foreground uppercase font-bold">{{ $t('kitchen_handover.handover_notes_label') }}</label>
                  <textarea 
                    id="notes-handover" 
                    v-model="handoverNotes"
                    placeholder="Nhập các sự cố bếp, thiết bị trục trặc, các lưu ý về order dở dang hoặc món sắp hết hàng để ca sau chủ động nắm bắt..."
                    rows="4"
                    class="w-full bg-background border border-border rounded-xl p-3 text-xs text-foreground placeholder-gray-600 focus:outline-none focus:border-[#FF9800]"
                  ></textarea>
                </div>
              </div>

              <!-- Right side: canvas signature -->
              <div class="space-y-4">
                <div class="flex justify-between items-baseline">
                  <span class="text-xs text-muted-foreground uppercase font-bold">{{ $t('kitchen_handover.digital_signature') }}</span>
                  <button type="button" class="text-[10px] bg-background hover:bg-card border border-border text-muted-foreground font-bold px-2 py-1 rounded" @click="clearSignature">
                    Xóa Chữ Ký
                  </button>
                </div>

                <div class="signature-canvas-container bg-background border-2 border-dashed border-border rounded-xl h-[175px] relative overflow-hidden flex items-center justify-center">
                  <canvas 
                    ref="canvasRef"
                    width="400"
                    height="175"
                    class="w-full h-full cursor-crosshair relative z-10"
                    @mousedown="startDrawing"
                    @mousemove="draw"
                    @mouseup="stopDrawing"
                    @mouseleave="stopDrawing"
                    @touchstart="startDrawing"
                    @touchmove="draw"
                    @touchend="stopDrawing"
                  ></canvas>
                  <div v-if="!hasSigned" class="absolute pointer-events-none text-xs text-muted-foreground font-bold uppercase z-0 text-center px-4">
                    Ký tên của Bếp trưởng ca sau tại đây để hoàn tất bàn giao ca bếp
                  </div>
                </div>
                
                <div class="p-3 bg-[#9C27B0]/10 border border-[#9C27B0]/20 rounded-xl text-[10px] text-[#9C27B0] leading-normal">
                  📌 <strong>Quy trình bàn giao KDS:</strong> Ký xác nhận đồng nghĩa với việc ca sau đã nhận bàn giao kho bếp sạch sẽ, thiết bị hoạt động bình thường, và số liệu tồn kho thực tế khớp với kê khai.
                </div>
              </div>
            </div>

            <div class="flex justify-between pt-4 border-t border-border">
              <button 
                class="px-6 py-2.5 bg-muted border border-border hover:bg-muted text-foreground font-bold rounded-xl text-xs uppercase transition"
                @click="wizardStep = 2"
              >
                Quay lại
              </button>
              <button 
                class="px-8 py-3 bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed text-foreground font-bold rounded-xl text-xs uppercase transition shadow-lg flex items-center gap-2"
                :disabled="!isStep3Complete"
                @click="submitHandover"
              >
                🤝 XÁC NHẬN BÀN GIAO & ĐÓNG CA
              </button>
            </div>
          </div>

        </div>
      </div>

    </div>

  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n';
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import Swal from 'sweetalert2';
import { useKitchenShift } from '@/composables/useKitchenShift';
import type { CountItem } from '@/composables/useKitchenShift';
import { useInventory } from '@/composables/useInventory';
import { useLanguageStore } from '@/stores/useLanguageStore';

const { t } = useI18n();

const router = useRouter();
const languageStore = useLanguageStore();

const { fetchShifts, startShift, closeShift, shifts, activeShift, loading: shiftLoading } = useKitchenShift();
const { fetchInventory, inventory } = useInventory();

const activeSubTab = ref<'wizard' | 'history'>('wizard');
const wizardStep = ref(1);

const closedShifts = computed(() => shifts.value.filter(s => s.status === 'CLOSED'));

// Start shift logic
const newShiftType = ref<'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT'>('MORNING');
const handleStartShift = async () => {
  try {
    await startShift(newShiftType.value);
    Swal.fire({
      title: t('common.success', { default: t('kitchen_handover.shift_opened') }),
      icon: 'success',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#4CAF50'
    });
  } catch (e: any) {
    Swal.fire({
      title: t('common.error', { default: t('kitchen_handover.error_title') }),
      text: e.message,
      icon: 'error',
      background: '#2D2D2D',
      color: '#FFF',
    });
  }
};

// Step 1 checklists
const checklist = ref({
  stopOrders: false,
  cleanArea: false,
  powerOff: false,
  fefoCheck: false,
  wrapFood: false
});

// Step 2 checklists & values
const fridgeTemp = ref(3);
const freezerTemp = ref(-18);
const wasteNotes = ref('');

interface HandoverInventoryItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  theoretical: number;
  actual: number;
  diff: number;
}

const inventoryVerifyList = ref<HandoverInventoryItem[]>([]);

onMounted(async () => {
  await fetchShifts();
  await fetchInventory();
  populateInventoryList();
});

const populateInventoryList = () => {
  inventoryVerifyList.value = inventory.value.map(item => ({
    id: item.ingredient_id,
    name: item.name_vi,
    icon: '📦',
    unit: item.unit,
    theoretical: item.quantity,
    actual: item.quantity,
    diff: 0
  }));
};

watch(inventory, () => {
  if (inventoryVerifyList.value.length === 0 && inventory.value.length > 0) {
    populateInventoryList();
  }
});

const calculateDiff = (item: HandoverInventoryItem) => {
  item.diff = (item.actual || 0) - item.theoretical;
};

const hasSignificantShortage = computed(() => {
  return inventoryVerifyList.value.some(item => item.diff <= -0.5);
});

// Validations
const isStep1Complete = computed(() => {
  return checklist.value.stopOrders && checklist.value.cleanArea && checklist.value.powerOff;
});

const isStep2Complete = computed(() => {
  const tempsValid = fridgeTemp.value <= 15 && freezerTemp.value <= 0;
  const safetyTicks = checklist.value.fefoCheck && checklist.value.wrapFood;
  const inventoryFilled = inventoryVerifyList.value.every(item => item.actual >= 0);
  const wasteLogged = !hasSignificantShortage.value || wasteNotes.value.trim().length > 5;
  return tempsValid && safetyTicks && inventoryFilled && wasteLogged;
});

// Step 3 variables
const incomingChef = ref('');
const handoverNotes = ref('');
const handoverSuccess = ref(false);

const canvasRef = ref<HTMLCanvasElement | null>(null);
let isDrawing = false;
let ctx: CanvasRenderingContext2D | null = null;
const hasSigned = ref(false);

const isStep3Complete = computed(() => {
  return incomingChef.value !== '' && handoverNotes.value.trim().length > 5 && hasSigned.value;
});

// Canvas Drawing functions
const startDrawing = (e: MouseEvent | TouchEvent) => {
  isDrawing = true;
  ctx = canvasRef.value?.getContext('2d') || null;
  if (!ctx || !canvasRef.value) return;
  ctx.beginPath();
  const rect = canvasRef.value.getBoundingClientRect();
  const x = ('touches' in e) ? (e as TouchEvent).touches[0].clientX - rect.left : (e as MouseEvent).clientX - rect.left;
  const y = ('touches' in e) ? (e as TouchEvent).touches[0].clientY - rect.top : (e as MouseEvent).clientY - rect.top;
  ctx.moveTo(x, y);
};

const draw = (e: MouseEvent | TouchEvent) => {
  if (!isDrawing || !ctx || !canvasRef.value) return;
  e.preventDefault();
  const rect = canvasRef.value.getBoundingClientRect();
  const x = ('touches' in e) ? (e as TouchEvent).touches[0].clientX - rect.left : (e as MouseEvent).clientX - rect.left;
  const y = ('touches' in e) ? (e as TouchEvent).touches[0].clientY - rect.top : (e as MouseEvent).clientY - rect.top;
  ctx.lineTo(x, y);
  ctx.strokeStyle = '#9C27B0';
  ctx.lineWidth = 3;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();
  hasSigned.value = true;
};

const stopDrawing = () => {
  isDrawing = false;
};

const clearSignature = () => {
  if (!canvasRef.value) return;
  const context = canvasRef.value.getContext('2d');
  if (context) {
    context.clearRect(0, 0, canvasRef.value.width, canvasRef.value.height);
  }
  hasSigned.value = false;
};

const submitHandover = async () => {
  if (!isStep3Complete.value || !activeShift.value) return;

  try {
    const counts: CountItem[] = inventoryVerifyList.value.map(i => ({
      ingredient_id: i.id,
      counted_quantity: i.actual,
      note: i.diff < 0 ? wasteNotes.value : undefined
    }));
    
    // Combine notes since we don't store signature image and other meta directly
    const finalNote = `t('kitchen_handover.next_shift_receives') ${incomingChef.value}\nt('kitchen_handover.fridge_temp_label') ${fridgeTemp.value}°C\nt('kitchen_handover.freezer_temp_label') ${freezerTemp.value}°C\nt('kitchen_handover.note_label') ${handoverNotes.value}${hasSignificantShortage.value ? `\nt('kitchen_handover.loss_label') ${wasteNotes.value}` : ''}`;
    
    await closeShift(activeShift.value.id, finalNote, counts);

    Swal.fire({
      title: t('common.success', { default: t('kitchen_handover.handover_success_title') }),
      text: t('kitchen_handover.handover_success_desc'),
      icon: 'success',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#4CAF50'
    });

    handoverSuccess.value = true;
  } catch (err: any) {
    Swal.fire({
      title: t('common.error', { default: t('kitchen_handover.error_title') }),
      text: err.message,
      icon: 'error',
      background: '#2D2D2D',
      color: '#FFF'
    });
  }
};

const resetWizard = () => {
  checklist.value = {
    stopOrders: false,
    cleanArea: false,
    powerOff: false,
    fefoCheck: false,
    wrapFood: false
  };
  fridgeTemp.value = 3;
  freezerTemp.value = -18;
  wasteNotes.value = '';
  handoverNotes.value = '';
  hasSigned.value = false;
  handoverSuccess.value = false;
  wizardStep.value = 1;
  activeSubTab.value = 'wizard';
  incomingChef.value = '';
  
  populateInventoryList();
};

const navigateBack = () => {
  router.push('/kitchen/kds');
};
</script>

<style scoped>
.temp-slider {
  -webkit-appearance: none;
  width: 100%;
  height: 6px;
  border-radius: 3px;
  background: #404040;
  outline: none;
}

.temp-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #9C27B0;
  cursor: pointer;
  box-shadow: 0 0 4px rgba(0,0,0,0.5);
}

/* Success Checkmark CSS */
.success-panel {
  box-shadow: 0 10px 30px rgba(0,0,0,0.4);
}
.success-checkmark {
  width: 80px;
  height: 80px;
  margin: 0 auto;
}
.check-icon {
  width: 80px;
  height: 80px;
  position: relative;
  border-radius: 50%;
  box-sizing: content-box;
  border: 4px solid #4CAF50;
}
.check-icon::after {
  content: '';
  position: absolute;
  background: #2D2D2D;
  z-index: 1;
}
.icon-line {
  height: 5px;
  background-color: #4CAF50;
  display: block;
  border-radius: 2px;
  position: absolute;
  z-index: 10;
}
.icon-line.line-tip {
  top: 46px;
  left: 19px;
  width: 25px;
  transform: rotate(45deg);
}
.icon-line.line-long {
  top: 38px;
  right: 14px;
  width: 47px;
  transform: rotate(-45deg);
}
.icon-circle {
  top: -4px;
  left: -4px;
  position: absolute;
  box-sizing: content-box;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 4px solid rgba(76, 175, 80, .5);
  z-index: 2;
}

@keyframes check-tip {
  0% { width: 0; left: 1px; top: 19px; }
  54% { width: 0; left: 1px; top: 19px; }
  70% { width: 50px; left: -8px; top: 37px; }
  84% { width: 17px; left: 21px; top: 48px; }
  100% { width: 25px; left: 19px; top: 46px; }
}

@keyframes check-long {
  0% { width: 0; right: 46px; top: 54px; }
  65% { width: 0; right: 46px; top: 54px; }
  84% { width: 55px; right: 0px; top: 35px; }
  100% { width: 47px; right: 14px; top: 38px; }
}

.animate-check-tip {
  animation: check-tip 0.8s ease-in-out forwards;
}
.animate-check-long {
  animation: check-long 0.8s ease-in-out forwards;
}

.animate-fade-in {
  animation: fadeIn 0.35s ease-out forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}

.flex-2 {
  flex: 2;
}
</style>
