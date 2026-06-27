<!-- KitchenHandoverView.vue -->
<template>
  <div class="handover-view min-h-screen flex flex-col bg-background text-foreground p-6">
    
    <!-- PAGE HEADER -->
    <header class="flex justify-between items-center mb-6 pb-4 border-b border-border">
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2">
          <span class="logo-brand text-[#FF9800] font-extrabold tracking-wider text-xl">NGƯU CÁT</span>
          <span class="tag-handover bg-[#9C27B0]/20 text-[#9C27B0] border border-[#9C27B0]/30 text-xs px-2.5 py-0.5 rounded font-bold">BÀN GIAO</span>
        </div>
        <div class="h-6 w-[1px] bg-muted"></div>
        <h2 class="text-lg font-bold text-gray-200 uppercase tracking-wide">Bàn Giao Ca Bếp (Shift Handover)</h2>
      </div>

      <!-- Action buttons -->
      <div class="flex items-center gap-3">
        <button 
          class="bg-gray-800 border border-gray-700 hover:bg-gray-700 text-xs font-bold px-4 py-2 rounded-xl transition"
          @click="activeSubTab = activeSubTab === 'wizard' ? 'history' : 'wizard'"
        >
          {{ activeSubTab === 'wizard' ? '⏳ Xem Lịch Sử Ca' : '✍️ Bàn Giao Ca Mới' }}
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
          <h3 class="text-lg font-bold text-foreground uppercase tracking-wider">Lịch Sử Nhật Ký Bàn Giao Ca</h3>
          <span class="text-xs text-gray-400">Ghi nhận hoạt động đóng ca bếp</span>
        </div>

        <div v-if="kitchenStore.handoverLogs.length === 0" class="text-center py-12 text-gray-500 bg-card rounded-xl border border-border">
          📭 Chưa có nhật ký bàn giao ca nào được lưu.
        </div>
        
        <div v-else class="space-y-6">
          <div 
            v-for="log in kitchenStore.handoverLogs" 
            :key="log.id"
            class="bg-card rounded-xl border border-border p-6 shadow-lg"
          >
            <div class="flex justify-between items-start flex-wrap gap-2 mb-4 border-b border-border pb-3">
              <div>
                <span class="text-xs font-bold text-[#FF9800] block uppercase font-mono">Phiếu Bàn Giao: #{{ log.id }}</span>
                <h4 class="text-base font-bold text-foreground mt-1">{{ log.shift }}</h4>
              </div>
              <div class="text-right">
                <span class="text-xs text-gray-400 block font-mono">{{ log.date }}</span>
                <span class="text-xs bg-[#4CAF50]/10 text-[#4CAF50] border border-[#4CAF50]/30 px-2 py-0.5 rounded-full font-bold">Hoàn tất đóng ca</span>
              </div>
            </div>

            <!-- Handover detail details -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4 bg-background p-4 rounded-xl border border-border text-xs">
              <div>
                <span class="text-gray-500 block">Chef bàn giao:</span>
                <strong class="text-foreground text-sm">👤 {{ log.outgoingChef }}</strong>
              </div>
              <div>
                <span class="text-gray-500 block">Chef ca sau nhận:</span>
                <strong class="text-foreground text-sm">👤 {{ log.incomingChef }}</strong>
              </div>
              <div>
                <span class="text-gray-500 block">Nhiệt độ Tủ mát:</span>
                <strong class="text-sm" :class="log.fridgeTemp > 5 ? 'text-red-500' : 'text-green-500'">🌡️ {{ log.fridgeTemp }}°C</strong>
              </div>
              <div>
                <span class="text-gray-500 block">Nhiệt độ Tủ đông:</span>
                <strong class="text-sm" :class="log.freezerTemp > -15 ? 'text-red-500' : 'text-green-500'">🌡️ {{ log.freezerTemp }}°C</strong>
              </div>
            </div>

            <!-- Notes -->
            <div class="mb-4 text-sm text-gray-300 bg-background/40 p-3 rounded-lg border border-border">
              <span class="font-bold text-[#FF9800] block text-xs uppercase mb-1">Ghi chú bàn giao:</span>
              <p class="italic">"{{ log.notes }}"</p>
            </div>

            <!-- Waste notes if any -->
            <div v-if="log.wasteNotes" class="mb-4 text-sm text-red-300 bg-red-950/20 p-3 rounded-lg border border-red-800/40">
              <span class="font-bold text-[#F44336] block text-xs uppercase mb-1">Hao hụt ghi nhận (Waste Log):</span>
              <p>{{ log.wasteNotes }}</p>
            </div>

            <!-- Inventory state -->
            <div class="mb-4">
              <span class="font-bold text-gray-400 block text-xs uppercase mb-2">Số liệu kiểm kê tồn kho bếp đóng ca:</span>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                <div v-for="item in log.items" :key="item.id" class="flex justify-between items-center p-2 bg-background rounded border border-border text-xs">
                  <span class="text-foreground">{{ item.icon }} {{ item.name }}</span>
                  <span class="font-mono text-gray-300">
                    {{ item.actual }} {{ item.unit }}
                    <span v-if="item.diff !== 0" :class="item.diff < 0 ? 'text-red-500' : 'text-green-500'" class="ml-1 font-bold">
                      ({{ item.diff < 0 ? '' : '+' }}{{ item.diff }})
                    </span>
                  </span>
                </div>
              </div>
            </div>

            <!-- Digital Signature image -->
            <div v-if="log.signatureImage" class="flex flex-col items-center pt-3 border-t border-border">
              <span class="text-[10px] text-gray-500 uppercase font-bold mb-1">Chữ ký số Bếp trưởng ca sau:</span>
              <img :src="log.signatureImage" alt="Incoming Chef Signature" class="max-h-[60px] bg-slate-900 border border-border rounded px-3 py-0.5" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB: NEW HANDOVER WIZARD VIEW -->
    <div v-else class="flex-1 flex flex-col justify-center items-center">
      
      <!-- SUCCESS SCREEN -->
      <div v-if="handoverSuccess" class="success-panel bg-card rounded-2xl p-8 border border-border text-center max-w-[600px] w-full animate-fade-in shadow-2xl">
        <div class="success-checkmark mb-6">
          <div class="check-icon">
            <span class="icon-line line-tip animate-check-tip"></span>
            <span class="icon-line line-long animate-check-long"></span>
            <div class="icon-circle"></div>
            <div class="icon-fix"></div>
          </div>
        </div>
        
        <h3 class="text-2xl font-black text-foreground uppercase tracking-wider mb-2">BÀN GIAO CA THÀNH CÔNG</h3>
        <p class="text-sm text-gray-400 mb-6">Phiếu bàn giao ca đóng bếp đã được đồng bộ lên POS và lưu trữ nhật ký hoạt động.</p>
        
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
            <span class="text-xs font-bold text-[#FF9800] uppercase tracking-wider">Tiến trình bàn giao ca:</span>
          </div>
          <div class="flex items-center gap-3 text-xs font-semibold text-gray-400">
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
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">1. Kết Thúc Ca Làm Việc & Vệ Sinh Bếp</h3>
              <span class="text-xs text-[#FF9800]">Bắt buộc thực hiện cuối ca</span>
            </div>

            <div class="space-y-4">
              <!-- Check 1 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-gray-500 transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.stopOrders"
                  class="w-6 h-6 rounded border-gray-600 text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">Dừng tiếp nhận Order mới (Trừ khách đang ăn dở)</span>
                  <span class="text-xs text-gray-400">Đóng cổng tiếp nhận đơn hàng trên POS trạm, đảm bảo không phát sinh món mới.</span>
                </div>
              </label>

              <!-- Check 2 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-gray-500 transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.cleanArea"
                  class="w-6 h-6 rounded border-gray-600 text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">Vệ sinh sạch sẽ khu vực chế biến</span>
                  <span class="text-xs text-gray-400">Lau chùi bề mặt bếp nướng/lẩu, vệ sinh thớt cắt thái, quét dọn và lau sàn sạch sẽ.</span>
                </div>
              </label>

              <!-- Check 3 -->
              <label class="flex items-start gap-3 cursor-pointer p-4 rounded-xl bg-background border border-border hover:border-gray-500 transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.powerOff"
                  class="w-6 h-6 rounded border-gray-600 text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-bold text-foreground block">Tắt các thiết bị điện không sử dụng</span>
                  <span class="text-xs text-gray-400">Ngắt điện lò nướng, lò chiên, tắt máy xay, lò vi sóng để đảm bảo phòng chống cháy nổ.</span>
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
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">2. Kiểm Kê Kho Trạm Bếp & An Toàn Thực Phẩm</h3>
              <span class="text-xs text-[#FF9800]">Nhập số liệu kiểm kê thực tế</span>
            </div>

            <!-- Table of stock comparison -->
            <div class="bg-background rounded-xl border border-border overflow-hidden">
              <div class="grid grid-cols-4 gap-2 bg-card p-3 text-xs font-bold text-gray-400 uppercase tracking-wide">
                <div class="col-span-2">Nguyên Liệu</div>
                <div class="text-center">Lý Thuyết</div>
                <div class="text-center">Thực Tế</div>
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
                      <span class="text-[10px] text-gray-500 font-mono">Đơn vị: {{ item.unit }}</span>
                    </div>
                  </div>
                  
                  <div class="text-center font-mono font-bold text-gray-300">
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
                    <span class="text-xs text-gray-500 font-bold uppercase">{{ item.unit }}</span>
                    
                    <!-- Discrepancy indicator -->
                    <span 
                      v-if="item.diff !== 0" 
                      class="text-xs font-bold font-mono px-1.5 py-0.5 rounded text-right"
                      :class="item.diff < 0 ? 'text-[#F44336]' : 'text-[#4CAF50]'"
                    >
                      {{ item.diff < 0 ? '' : '+' }}{{ item.diff }}
                    </span>
                    <span v-else class="text-[#4CAF50] text-xs">✓</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Waste Log report warning if there's significant shortage -->
            <div v-if="hasSignificantShortage" class="bg-red-950/20 border border-red-800/40 rounded-xl p-4 animate-fade-in">
              <span class="text-xs font-bold text-[#F44336] uppercase tracking-wider block mb-2">
                ⚠️ HỒ SƠ HAO HỤT (WASTE LOG REQUIRED)
              </span>
              <p class="text-xs text-red-300 mb-3">Phát hiện chênh lệch hao hụt lớn (&le; -0.5) so với lý thuyết. Bắt buộc ghi nhận biên bản Waste Log:</p>
              <textarea 
                v-model="wasteNotes"
                placeholder="Giải trình lý do hao hụt (ví dụ: Thịt bò Wagyu bị cháy hủy món bàn 4, Rau bị dập nát hủy bỏ 0.5kg ca sáng...)"
                rows="2"
                class="w-full bg-background border border-border rounded-lg p-3 text-xs text-foreground placeholder-gray-600 focus:outline-none focus:border-[#F44336]"
              ></textarea>
            </div>

            <!-- Safety Checklists -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <label class="flex items-start gap-3 cursor-pointer p-3.5 rounded-xl bg-background border border-border hover:border-gray-500 transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.fefoCheck"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-semibold text-foreground block text-sm">Kiểm tra hạn sử dụng (FEFO)</span>
                  <span class="text-xs text-gray-400">Rà soát ngày, xếp các khay hạn sử dụng ngắn ra ngoài để ca sau dùng trước.</span>
                </div>
              </label>

              <label class="flex items-start gap-3 cursor-pointer p-3.5 rounded-xl bg-background border border-border hover:border-gray-500 transition">
                <input 
                  type="checkbox" 
                  v-model="checklist.wrapFood"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#FF9800] focus:ring-[#FF9800] bg-card mt-0.5"
                />
                <div>
                  <span class="font-semibold text-foreground block text-sm">Bọc màng co & dán nhãn ngày</span>
                  <span class="text-xs text-gray-400">Toàn bộ khay thịt/rau củ thừa bọc màng thực phẩm kín, dán nhãn ca và ngày sơ chế.</span>
                </div>
              </label>
            </div>

            <!-- Fridge and Freezer Temperature inputs -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5 p-4 bg-background rounded-xl border border-border">
              <div class="space-y-2">
                <div class="flex justify-between items-baseline">
                  <span class="text-xs font-bold text-gray-400 uppercase">🌡️ Nhiệt độ Tủ Mát</span>
                  <span class="text-sm font-bold font-mono" :class="fridgeTemp > 5 ? 'text-red-500' : 'text-green-500'">
                    {{ fridgeTemp }}°C
                  </span>
                </div>
                <div class="flex items-center gap-3">
                  <input v-model.number="fridgeTemp" type="range" min="-5" max="15" step="1" class="temp-slider flex-1" />
                  <span v-if="fridgeTemp > 5" class="text-[10px] bg-red-950/40 text-red-400 border border-red-800/40 px-1.5 py-0.5 rounded font-bold">LỖI!</span>
                  <span v-else class="text-[10px] bg-green-950/40 text-green-500 border border-green-800/40 px-1.5 py-0.5 rounded font-bold">OK</span>
                </div>
                <span class="text-[10px] text-gray-500 block italic">Yêu cầu tiêu chuẩn: &le; 5°C</span>
              </div>

              <div class="space-y-2">
                <div class="flex justify-between items-baseline">
                  <span class="text-xs font-bold text-gray-400 uppercase">🌡️ Nhiệt độ Tủ Đông</span>
                  <span class="text-sm font-bold font-mono" :class="freezerTemp > -15 ? 'text-red-500' : 'text-green-500'">
                    {{ freezerTemp }}°C
                  </span>
                </div>
                <div class="flex items-center gap-3">
                  <input v-model.number="freezerTemp" type="range" min="-30" max="-5" step="1" class="temp-slider flex-1" />
                  <span v-if="freezerTemp > -15" class="text-[10px] bg-red-950/40 text-red-400 border border-red-800/40 px-1.5 py-0.5 rounded font-bold">LỖI!</span>
                  <span v-else class="text-[10px] bg-green-950/40 text-green-500 border border-green-800/40 px-1.5 py-0.5 rounded font-bold">OK</span>
                </div>
                <span class="text-[10px] text-gray-500 block italic">Yêu cầu tiêu chuẩn: &le; -18°C</span>
              </div>
            </div>

            <div class="flex justify-between pt-4 border-t border-border">
              <button 
                class="px-6 py-2.5 bg-gray-800 border border-gray-700 hover:bg-gray-700 text-foreground font-bold rounded-xl text-xs uppercase transition"
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
              <h3 class="text-base font-bold text-foreground uppercase tracking-wider">3. Bàn Giao Ca Sau & Ký Xác Nhận</h3>
              <span class="text-xs text-[#FF9800]">Chef ca sau ký nhận bàn giao</span>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Left side: note inputs -->
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label for="shift-select" class="text-xs text-gray-400 uppercase font-bold">Ca làm việc đóng cửa</label>
                  <input id="shift-select" type="text" v-model="shiftName" disabled class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-gray-300 opacity-80" />
                </div>

                <div class="flex flex-col gap-1.5">
                  <label for="incoming-select" class="text-xs text-gray-400 uppercase font-bold">Bếp trưởng ca sau tiếp quản</label>
                  <select 
                    id="incoming-select" 
                    v-model="incomingChef"
                    class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none focus:border-[#FF9800]"
                  >
                    <option value="" disabled>-- Chọn Bếp Trưởng Ca Sau --</option>
                    <option value="Chef Minh">Chef Minh (Bếp chính)</option>
                    <option value="Chef Luc">Chef Luc (Bếp trưởng)</option>
                    <option value="Chef Kien">Chef Kiên (Quầy Bar)</option>
                    <option value="Chef Hanh">Chef Hạnh (Bếp Lạnh)</option>
                  </select>
                </div>

                <div class="flex flex-col gap-1.5">
                  <label for="notes-handover" class="text-xs text-gray-400 uppercase font-bold">Sổ bàn giao / Ghi chú ca sau (Notes)</label>
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
                  <span class="text-xs text-gray-400 uppercase font-bold">✍️ Chữ ký số Chef ca sau (Chef Minh)</span>
                  <button type="button" class="text-[10px] bg-background hover:bg-card border border-border text-gray-300 font-bold px-2 py-1 rounded" @click="clearSignature">
                    Xóa Chữ Ký
                  </button>
                </div>

                <div class="signature-canvas-container bg-background/40 border-2 border-dashed border-border rounded-xl h-[175px] relative overflow-hidden flex items-center justify-center">
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
                  <div v-if="!hasSigned" class="absolute pointer-events-none text-xs text-gray-500 font-bold uppercase z-0 text-center px-4">
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
                class="px-6 py-2.5 bg-gray-800 border border-gray-700 hover:bg-gray-700 text-foreground font-bold rounded-xl text-xs uppercase transition"
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
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useKitchenStore } from '@/stores/kitchen';
import Swal from 'sweetalert2';

const router = useRouter();
const kitchenStore = useKitchenStore();

const activeSubTab = ref<'wizard' | 'history'>('wizard');
const wizardStep = ref(1);

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

// Populate initial list from store
onMounted(() => {
  inventoryVerifyList.value = kitchenStore.inventoryList.map(item => ({
    id: item.id,
    name: item.name,
    icon: item.icon,
    unit: item.unit,
    theoretical: item.kitchenStock,
    actual: item.kitchenStock, // defaults to theoretical
    diff: 0
  }));
});

const calculateDiff = (item: HandoverInventoryItem) => {
  item.diff = (item.actual || 0) - item.theoretical;
};

// Check if there is significant shortage (diff <= -0.5)
const hasSignificantShortage = computed(() => {
  return inventoryVerifyList.value.some(item => item.diff <= -0.5);
});

// Validations
const isStep1Complete = computed(() => {
  return checklist.value.stopOrders && checklist.value.cleanArea && checklist.value.powerOff;
});

const isStep2Complete = computed(() => {
  // Check if temperatures are safe
  const tempsValid = fridgeTemp.value <= 15 && freezerTemp.value <= 0;
  
  // Check if food safety checks ticked
  const safetyTicks = checklist.value.fefoCheck && checklist.value.wrapFood;
  
  // Check if inventory has any negative fields and waste notes are filled if shortage
  const inventoryFilled = inventoryVerifyList.value.every(item => item.actual >= 0);
  const wasteLogged = !hasSignificantShortage.value || wasteNotes.value.trim().length > 5;
  
  return tempsValid && safetyTicks && inventoryFilled && wasteLogged;
});

// Step 3 variables
const shiftName = ref('Ca Sáng (06:00 - 14:00)');
const incomingChef = ref('Chef Minh');
const handoverNotes = ref('');
const handoverSuccess = ref(false);

// Canvas signature board
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
  const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
  const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
  
  ctx.moveTo(x, y);
};

const draw = (e: MouseEvent | TouchEvent) => {
  if (!isDrawing || !ctx || !canvasRef.value) return;
  e.preventDefault();
  const rect = canvasRef.value.getBoundingClientRect();
  const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
  const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
  
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

const submitHandover = () => {
  if (!isStep3Complete.value) return;

  const sigImgUrl = canvasRef.value ? canvasRef.value.toDataURL() : undefined;

  // Save log in Pinia store
  kitchenStore.addHandoverLog({
    shift: shiftName.value,
    outgoingChef: 'Chef Luc',
    incomingChef: incomingChef.value,
    fridgeTemp: fridgeTemp.value,
    freezerTemp: freezerTemp.value,
    notes: handoverNotes.value,
    wasteNotes: hasSignificantShortage.value ? wasteNotes.value : undefined,
    items: inventoryVerifyList.value.map(item => ({
      id: item.id,
      name: item.name,
      icon: item.icon,
      unit: item.unit,
      theoretical: item.theoretical,
      actual: item.actual,
      diff: item.diff
    })),
    signatureImage: sigImgUrl
  });

  // Apply new physical stocks to Pinia store inventory list (automatically syncs stocks)
  inventoryVerifyList.value.forEach(verifyItem => {
    const inv = kitchenStore.inventoryList.find(i => i.id === verifyItem.id);
    if (inv) {
      inv.kitchenStock = verifyItem.actual;
    }
  });

  Swal.fire({
    title: 'Bàn giao ca thành công',
    text: 'Nhật ký ca làm việc đã được đóng và ghi sổ!',
    icon: 'success',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#4CAF50'
  });

  handoverSuccess.value = true;
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
  
  // Re-populate inventory theoretical numbers
  inventoryVerifyList.value = kitchenStore.inventoryList.map(item => ({
    id: item.id,
    name: item.name,
    icon: item.icon,
    unit: item.unit,
    theoretical: item.kitchenStock,
    actual: item.kitchenStock,
    diff: 0
  }));
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
