<template>
  <div class="kds-container min-h-screen flex flex-col bg-[#1A1A1A] text-white">

    <!-- 1. KDS HEADER (80px) -->
    <header class="h-[80px] bg-[#1A1A1A] border-b border-[#404040] px-6 flex items-center justify-between">
      <div class="flex items-center gap-4">
        <!-- Logo / Brand -->
        <div class="flex items-center gap-2">
          <span class="text-3xl font-black text-[#ff6b35] tracking-widest">NGƯU CÁT</span>
          <span class="bg-[#ff6b35]/20 text-[#ff6b35] px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">KDS</span>
        </div>
        <div class="h-6 w-[1px] bg-[#404040]"></div>
        <!-- Active Station Display -->
        <div class="flex items-center gap-2">
          <span class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạm hiện tại:</span>
          <span class="text-xl font-bold bg-[#3D3D3D] px-3 py-1 rounded border border-[#616161]">
            {{ getStationLabel(activeStation) }}
          </span>
        </div>
      </div>

      <!-- Real-time Clock, Alerts & User Profile -->
      <div class="flex items-center gap-6">
        <!-- New Feature Trigger: Grill & Coal Change Request Button -->
        <button 
          class="flex items-center gap-2 bg-[#ff6b35] hover:bg-[#e55a2b] active:scale-95 px-4 py-2 rounded-xl text-white font-bold text-sm transition-all shadow-md touch-target"
          @click="showGrillRequestModal = true"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd" />
          </svg>
          Yêu cầu Vỉ / Than
        </button>

        <button 
          class="flex items-center gap-1.5 bg-[#3D3D3D] hover:bg-[#4A4A4A] border border-[#616161] px-3 py-2 rounded-xl text-xs font-bold transition-fast touch-target"
          @click="showGrillSidebar = !showGrillSidebar"
        >
          <span>{{ showGrillSidebar ? 'Ẩn Panel Vỉ/Than' : 'Hiện Panel Vỉ/Than' }}</span>
          <span v-if="grillRequests.length > 0" class="w-5 h-5 rounded-full bg-[#ff6b35] text-white flex items-center justify-center font-bold text-[10px]">
            {{ grillRequests.length }}
          </span>
        </button>

        <!-- New Feature: Hygiene & Safety (HACCP) Button -->
        <button 
          class="flex items-center gap-2 bg-[#2E7D32] hover:bg-[#256629] active:scale-95 px-4 py-2 rounded-xl text-white font-bold text-sm transition-all shadow-md touch-target"
          @click="showHaccpModal = true"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944a11.954 11.954 0 007.834 3.056 12.012 12.012 0 01-1.423 7.82 11.95 11.95 0 01-6.411 5.233 11.95 11.95 0 01-6.41-5.233 12.008 12.008 0 01-1.424-7.82zM10 4a1 1 0 00-1 1v4a1 1 0 102 0V5a1 1 0 00-1-1zm0 8a1 1 0 100 2 1 1 0 000-2z" clip-rule="evenodd" />
          </svg>
          An Toàn HACCP
          <span v-if="unresolvedIncidentCount > 0" class="w-5 h-5 rounded-full bg-red-600 text-white flex items-center justify-center font-bold text-[10px] animate-pulse">
            {{ unresolvedIncidentCount }}
          </span>
        </button>

        <!-- Alarm Banner / Alert Badge -->
        <div v-if="countDelayed > 0" class="flex items-center gap-2 bg-[#C62828]/20 border border-[#F44336] px-3 py-1.5 rounded-lg text-[#F44336] animate-pulse">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
          </svg>
          <span class="text-sm font-bold uppercase tracking-wider">Cảnh báo: {{ countDelayed }} đơn trễ!</span>
        </div>

        <!-- Timer / Clock -->
        <div class="flex items-center gap-2 text-gray-400 font-mono text-lg">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>{{ currentTime }}</span>
        </div>
      </div>
    </header>

    <!-- Notification Banner -->
    <div v-if="notification" class="alert-banner px-6 py-3" :class="notification.type">
      <span class="font-semibold">{{ notification.message }}</span>
    </div>

    <!-- 2. FILTER BAR (60px) -->
    <div class="h-[60px] bg-[#2D2D2D] border-b border-[#404040] px-6 flex items-center justify-between gap-4 overflow-x-auto">
      <!-- Station Filters -->
      <div class="flex items-center gap-2">
        <button 
          v-for="st in stations" 
          :key="st.key"
          class="px-4 py-1.5 rounded-lg text-sm font-bold border transition-all touch-target"
          :class="activeStation === st.key ? 'bg-[#ff6b35] border-[#ff6b35] text-white' : 'bg-[#3D3D3D] border-[#616161] text-gray-300 hover:text-white'"
          @click="activeStation = st.key"
        >
          {{ st.label }}
        </button>
      </div>

      <!-- Status Filters, Sorting & Search -->
      <div class="flex items-center gap-4">
        <!-- Sort Select -->
        <div class="flex items-center gap-2">
          <span class="text-xs text-gray-400 uppercase font-semibold">Sắp xếp:</span>
          <select 
            v-model="sortOrder"
            class="bg-[#3D3D3D] border border-[#616161] rounded-lg px-3 py-1.5 text-sm font-bold text-gray-200 focus:outline-none focus:border-[#ff6b35]"
          >
            <option value="oldest">Cũ nhất trước</option>
            <option value="newest">Mới nhất trước</option>
            <option value="priority">Độ ưu tiên</option>
          </select>
        </div>

        <!-- Search box -->
        <div class="relative w-48 lg:w-64">
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="Tìm bàn / ID đơn..."
            class="w-full bg-[#1A1A1A] border border-[#616161] rounded-lg pl-9 pr-4 py-1.5 text-sm focus:outline-none focus:border-[#ff6b35] text-white placeholder-gray-500"
          />
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-500 absolute left-3 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- 3. STATUS BAR (50px) -->
    <div class="h-[50px] bg-[#3D3D3D] border-b border-[#404040] px-6 flex items-center gap-6">
      <div class="flex items-center gap-2 text-sm">
        <span class="w-3 h-3 rounded-full bg-[#1A237E]"></span>
        <span class="font-semibold text-gray-300">Chờ chế biến:</span>
        <span class="font-bold bg-[#1A1A1A] px-2 py-0.5 rounded border border-[#616161]">{{ countPending }}</span>
      </div>
      <div class="flex items-center gap-2 text-sm">
        <span class="w-3 h-3 rounded-full bg-[#E65100]"></span>
        <span class="font-semibold text-gray-300">Đang làm:</span>
        <span class="font-bold bg-[#1A1A1A] px-2 py-0.5 rounded border border-[#616161]">{{ countPreparing }}</span>
      </div>
      <div class="flex items-center gap-2 text-sm">
        <span class="w-3 h-3 rounded-full bg-[#2E7D32]"></span>
        <span class="font-semibold text-gray-300">Hoàn thành:</span>
        <span class="font-bold bg-[#1A1A1A] px-2 py-0.5 rounded border border-[#616161]">{{ countDone }}</span>
      </div>
      <div class="h-4 w-[1px] bg-[#404040]"></div>
      <div class="flex items-center gap-2 text-sm">
        <span class="w-3 h-3 rounded-full bg-[#C62828] animate-pulse"></span>
        <span class="font-semibold text-red-400">Trễ (>15m):</span>
        <span class="font-bold bg-[#1A1A1A] px-2 py-0.5 rounded border border-[#C62828] text-red-400 animate-pulse">{{ countDelayed }}</span>
      </div>
    </div>

    <!-- 4. MAIN WORKSPACE (Flex Row for Board + Sidebar) -->
    <div class="flex-1 flex overflow-hidden">
      
      <!-- Kanban Board -->
      <main class="flex-1 flex gap-6 overflow-x-auto p-6 bg-[#1A1A1A]">
        
        <!-- Cột 1: Chờ chế biến -->
        <section class="flex-1 min-w-[310px] max-w-[420px] bg-[#2D2D2D] rounded-xl flex flex-col border border-[#404040]">
          <div class="p-4 border-b border-[#404040] bg-[#2D2D2D] rounded-t-xl flex justify-between items-center sticky top-0 z-10">
            <h2 class="text-lg font-bold text-gray-200 uppercase tracking-wider flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-[#1A237E]"></span>
              {{ t('auto_ch__ch__bi_n') }}
            </h2>
            <span class="bg-[#1A1A1A] border border-[#616161] text-gray-300 px-3 py-0.5 rounded font-bold text-sm">
              {{ pendingOrders.length }}
            </span>
          </div>
          
          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <div 
              v-for="order in pendingOrders" 
              :key="order.id" 
              class="ticket-card status-new relative transition-normal"
              :class="getTimerColorClass(order.waitTime)"
              @click="openDetail(order)"
            >
              <div v-if="order.waitTime >= 900" class="absolute top-2 right-2">
                <span class="status-badge delayed text-[10px]">TRỄ</span>
              </div>

              <div class="flex justify-between items-start mb-3">
                <div>
                  <span class="text-2xl font-black text-white block flex items-center gap-2">
                    Bàn {{ getTableCode(order.table) }}
                    <span 
                      v-if="order.id === oldestPendingOrderId" 
                      class="bg-[#2196F3] text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider animate-pulse"
                      title="Nhập trước chế biến trước (FIFO)"
                    >
                      FIFO
                    </span>
                  </span>
                  <span class="text-xs text-gray-400 font-medium">#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span>
                </div>
                <span class="timer-display" :class="getTimerTextClass(order.waitTime)">
                  {{ formatWaitTime(order.waitTime) }}
                </span>
              </div>
              
              <hr class="border-[#404040] my-3" />

              <div class="space-y-2">
                <div 
                  v-for="item in order.displayItems" 
                  :key="item.id" 
                  class="flex items-start gap-2.5 p-2 rounded bg-[#3D3D3D]/50 border border-[#404040] hover:bg-[#3D3D3D] transition-fast cursor-pointer"
                  @click.stop="toggleItemStatus(item)"
                >
                  <div class="mt-0.5">
                    <input 
                      type="checkbox" 
                      :checked="item.done" 
                      class="w-5.5 h-5.5 rounded border-gray-600 text-[#ff6b35] focus:ring-[#ff6b35] bg-[#1A1A1A] pointer-events-none"
                    >
                  </div>
                  <div class="flex-1 min-w-0">
                    <span class="text-base font-semibold block text-gray-100" :class="{ 'line-through text-gray-500': item.done }">
                      <span class="text-[#ff6b35] font-black mr-1 text-lg">{{ item.qty }}x</span>
                      {{ item.name }}
                    </span>
                    <span v-if="activeStation === 'ALL'" class="inline-block mt-1 text-[10px] bg-[#3D3D3D] text-gray-400 px-1.5 py-0.5 rounded border border-[#616161]">
                      {{ getStationLabel(getItemStation(item.name)) }}
                    </span>
                    <div v-if="item.note" class="text-xs text-[#FFA726] italic mt-1 bg-[#FFA726]/10 p-1.5 rounded border border-[#FFA726]/20 flex items-start gap-1">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 flex-shrink-0 text-[#FFA726]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                      </svg>
                      <span>{{ item.note }}</span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div v-if="hasAllergyNote(order)" class="mt-3 bg-red-950/40 border border-red-800/40 p-2 rounded text-xs text-red-400 font-bold uppercase tracking-wider flex items-center gap-1.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span>CẢNH BÁO DỊ ỨNG!</span>
              </div>

              <div class="mt-4 pt-3 border-t border-[#404040] flex justify-end">
                <button 
                  class="action-button primary w-full py-2.5 font-bold rounded-lg transition-fast touch-target"
                  @click.stop="moveToPreparing(order)"
                >
                  {{ t('auto_b_t_u_l_m') }}
                </button>
              </div>
            </div>
            
            <div v-if="pendingOrders.length === 0" class="empty-state">
              <div class="empty-state-icon">📋</div>
              <div class="empty-state-title">Trống</div>
              <div class="empty-state-description text-sm">Không có đơn hàng nào chờ chế biến.</div>
            </div>
          </div>
        </section>

        <!-- Cột 2: Đang làm -->
        <section class="flex-1 min-w-[310px] max-w-[420px] bg-[#2D2D2D] rounded-xl flex flex-col border border-[#404040]">
          <div class="p-4 border-b border-[#404040] bg-[#2D2D2D] rounded-t-xl flex justify-between items-center sticky top-0 z-10">
            <h2 class="text-lg font-bold text-blue-400 uppercase tracking-wider flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-[#E65100]"></span>
              {{ t('auto__ang_l_m') }}
            </h2>
            <span class="bg-[#1A1A1A] border border-[#616161] text-blue-300 px-3 py-0.5 rounded font-bold text-sm">
              {{ preparingOrders.length }}
            </span>
          </div>

          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <div 
              v-for="order in preparingOrders" 
              :key="order.id" 
              class="ticket-card status-cooking relative transition-normal"
              :class="getTimerColorClass(order.waitTime)"
              @click="openDetail(order)"
            >
              <div v-if="order.waitTime >= 900" class="absolute top-2 right-2">
                <span class="status-badge delayed text-[10px]">TRỄ</span>
              </div>

              <div class="flex justify-between items-start mb-3">
                <div>
                  <span class="text-2xl font-black text-white block">Bàn {{ getTableCode(order.table) }}</span>
                  <span class="text-xs text-gray-400 font-medium">#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span>
                </div>
                <span class="timer-display" :class="getTimerTextClass(order.waitTime)">
                  {{ formatWaitTime(order.waitTime) }}
                </span>
              </div>
              
              <hr class="border-[#404040] my-3" />

              <div class="space-y-2">
                <div 
                  v-for="item in order.displayItems" 
                  :key="item.id" 
                  class="flex flex-col p-2.5 rounded bg-[#3D3D3D]/50 border border-[#404040] hover:bg-[#3D3D3D]/80 transition-fast cursor-pointer"
                  @click.stop="toggleItemStatus(item)"
                >
                  <div class="flex items-start gap-2.5">
                    <div class="mt-0.5">
                      <input 
                        type="checkbox" 
                        :checked="item.done" 
                        class="w-5.5 h-5.5 rounded border-gray-600 text-green-500 focus:ring-green-500 bg-[#1A1A1A] pointer-events-none"
                      >
                    </div>
                    <div class="flex-1 min-w-0">
                      <span class="text-base font-semibold block text-gray-100" :class="{ 'line-through text-gray-500': item.done }">
                        <span class="text-[#2196F3] font-black mr-1 text-lg">{{ item.qty }}x</span>
                        {{ item.name }}
                      </span>
                      <span v-if="activeStation === 'ALL'" class="inline-block mt-1 text-[10px] bg-[#3D3D3D] text-gray-400 px-1.5 py-0.5 rounded border border-[#616161]">
                        {{ getStationLabel(getItemStation(item.name)) }}
                      </span>
                      <div v-if="item.note" class="text-xs text-[#FFA726] italic mt-1 bg-[#FFA726]/10 p-1.5 rounded border border-[#FFA726]/20 flex items-start gap-1">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 flex-shrink-0 text-[#FFA726]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                        <span>{{ item.note }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Micro checklist for cooking workflow from kitchen_cooking_flow.mmd -->
                  <div class="mt-2 pl-8 space-y-1 bg-[#1A1A1A]/40 p-2 rounded border border-[#404040]/30" @click.stop>
                    <div v-for="step in getItemSubSteps(item.name)" :key="step.key" class="flex items-center gap-1.5 py-0.5">
                      <input 
                        type="checkbox" 
                        :checked="isSubStepChecked(item.id, step.key)" 
                        @change="toggleSubStep(item.id, step.key)"
                        class="w-4.5 h-4.5 rounded border-gray-600 text-green-500 focus:ring-green-500 bg-[#2D2D2D] cursor-pointer"
                      >
                      <span class="text-xs text-gray-300 select-none" :class="{ 'line-through text-gray-500': isSubStepChecked(item.id, step.key) }">
                        {{ step.label }}
                      </span>
                    </div>
                    
                    <!-- Quick Grill / Coal Request Trigger (Only for Grill items) -->
                    <div v-if="getItemStation(item.name) === 'Grill'" class="flex items-center gap-2 mt-2 pt-1.5 border-t border-[#404040]/40">
                      <button 
                        @click="triggerQuickRequest(order.table, 'GrillChange')" 
                        class="flex items-center gap-1.5 px-2.5 py-1 bg-purple-950/60 border border-purple-800/60 rounded text-[10px] font-bold text-purple-300 hover:bg-purple-900/60 transition-fast"
                        title="Thay vỉ nướng nhanh"
                      >
                        🧹 Thay vỉ
                      </button>
                      <button 
                        @click="triggerQuickRequest(order.table, 'CoalRefill')" 
                        class="flex items-center gap-1.5 px-2.5 py-1 bg-orange-950/60 border border-[#ff6b35]/60 rounded text-[10px] font-bold text-[#ff6b35] hover:bg-orange-900/60 transition-fast"
                        title="Châm than nhanh"
                      >
                        🔥 Thêm than
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <div v-if="hasAllergyNote(order)" class="mt-3 bg-red-950/40 border border-red-800/40 p-2 rounded text-xs text-red-400 font-bold uppercase tracking-wider flex items-center gap-1.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span>CẢNH BÁO DỊ ỨNG!</span>
              </div>

              <div class="mt-4 pt-3 border-t border-[#404040] flex justify-end">
                <button 
                  class="action-button success w-full py-2.5 font-bold rounded-lg transition-fast touch-target"
                  @click.stop="moveToDone(order)"
                >
                  {{ t('auto_ho_n_t_t_n') }}
                </button>
              </div>
            </div>

            <div v-if="preparingOrders.length === 0" class="empty-state">
              <div class="empty-state-icon">🔥</div>
              <div class="empty-state-title">Trống</div>
              <div class="empty-state-description text-sm">Không có đơn hàng nào đang chế biến.</div>
            </div>
          </div>
        </section>

        <!-- Cột 3: Hoàn thành -->
        <section class="flex-1 min-w-[310px] max-w-[420px] bg-[#2D2D2D] rounded-xl flex flex-col border border-[#404040] opacity-85">
          <div class="p-4 border-b border-[#404040] bg-[#2D2D2D] rounded-t-xl flex justify-between items-center sticky top-0 z-10">
            <h2 class="text-lg font-bold text-green-400 uppercase tracking-wider flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-[#2E7D32]"></span>
              {{ t('auto_ho_n_th_nh') }}
            </h2>
            <span class="bg-[#1A1A1A] border border-[#616161] text-green-300 px-3 py-0.5 rounded font-bold text-sm">
              {{ doneOrders.length }}
            </span>
          </div>

          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <div 
              v-for="order in doneOrders" 
              :key="order.id" 
              class="ticket-card status-ready p-4 rounded-lg bg-[#2D2D2D] border border-[#4CAF50]/30 shadow-md opacity-80 cursor-pointer"
              @click="openDetail(order)"
            >
              <div class="flex justify-between items-start mb-3">
                <div>
                  <span class="text-xl font-bold text-gray-300 line-through block">Bàn {{ getTableCode(order.table) }}</span>
                  <span class="text-xs text-gray-500 font-medium">#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span>
                </div>
                <span class="bg-green-950/40 text-green-400 border border-green-800/40 px-2 py-0.5 rounded text-xs font-bold uppercase">
                  SẴN SÀNG
                </span>
              </div>

              <div class="space-y-1.5 mt-3 text-sm text-gray-400 line-through">
                <div v-for="item in order.displayItems" :key="item.id" class="flex items-center gap-2">
                  <span class="font-bold text-green-500/75">{{ item.qty }}x</span>
                  <span>{{ item.name }}</span>
                </div>
              </div>
            </div>

            <div v-if="doneOrders.length === 0" class="empty-state">
              <div class="empty-state-icon">✅</div>
              <div class="empty-state-title">Trống</div>
              <div class="empty-state-description text-sm">Chưa có đơn hàng nào hoàn tất trong ca.</div>
            </div>
          </div>
        </section>

      </main>

      <!-- NEW FEATURE: GRILL & COAL ALERTS SIDEBAR PANEL (width 320px) -->
      <aside 
        v-if="showGrillSidebar" 
        class="w-[320px] bg-[#2D2D2D] border-l border-[#404040] flex flex-col h-full transition-all duration-300"
      >
        <div class="p-4 border-b border-[#404040] bg-[#1A1A1A] flex justify-between items-center">
          <h3 class="text-base font-bold text-[#ff6b35] uppercase tracking-wider flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.655-.398-1.434-.398-2.42a1 1 0 00-1.743-.68 12.012 12.012 0 00-2.812 5.02c-.36 1.157-.507 2.3-.507 3.322 0 1.137.234 2.27.705 3.328a8.041 8.041 0 002.04 2.724c.959.837 2.1 1.432 3.31 1.75a11.93 11.93 0 006.185-.43 8.032 8.032 0 003.88-2.613 8.04 8.04 0 001.696-3.84c.328-1.22.316-2.442-.01-3.608a11.824 11.824 0 00-2.868-5.128M14 10a1 1 0 00-1.707-.707l-1 1a1 1 0 00-.293.707V12a1 1 0 002 0v-.586l.707-.707A1 1 0 0014 10z" clip-rule="evenodd" />
            </svg>
            Yêu cầu Vỉ & Than
          </h3>
          <span class="bg-[#ff6b35]/20 text-[#ff6b35] px-2.5 py-0.5 rounded-full text-xs font-bold">
            {{ grillRequests.length }}
          </span>
        </div>

        <div class="p-4 flex-1 overflow-y-auto space-y-4">
          
          <!-- Quick Guidelines from kitchen_cooking_flow.mmd -->
          <div class="p-3 bg-[#3D3D3D] border border-[#616161] rounded-xl text-xs text-gray-300 space-y-1">
            <div class="font-bold text-[#FFA726] uppercase">💡 Quy trình bếp nướng:</div>
            <p>1. Định kỳ kiểm tra vỉ nướng & than.</p>
            <p>2. Khi vỉ bẩn / than yếu $\rightarrow$ Gửi yêu cầu thay.</p>
            <p>3. Thay vỉ/châm than mất từ **2 - 3 phút**.</p>
          </div>

          <!-- Active Request list -->
          <div v-for="req in grillRequests" :key="req.id" class="p-4 rounded-xl bg-[#1A1A1A] border-l-4 shadow-md transition-fast relative" :class="req.priority === 'Urgent' ? 'border-[#C62828] bg-red-950/10' : 'border-[#FFA726]'">
            
            <button @click="cancelGrillRequest(req)" class="absolute top-2 right-2 text-gray-500 hover:text-white transition-fast">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>

            <div class="flex justify-between items-baseline mb-2">
              <span class="text-xl font-black text-white">Bàn {{ req.table }}</span>
              <span class="text-[10px] px-2 py-0.5 rounded font-bold uppercase" :class="req.priority === 'Urgent' ? 'bg-[#C62828] text-white animate-pulse' : 'bg-[#3D3D3D] text-gray-400'">
                {{ req.priority === 'Urgent' ? 'GẤP' : 'THƯỜNG' }}
              </span>
            </div>

            <!-- Type of request -->
            <div class="text-sm font-semibold text-gray-200 mb-3 flex items-center gap-1.5">
              <span class="w-2.5 h-2.5 rounded-full" :class="req.type === 'GrillChange' ? 'bg-purple-500' : 'bg-[#FFA726]'"></span>
              {{ req.type === 'GrillChange' ? 'Yêu cầu thay vỉ nướng' : 'Yêu cầu châm thêm than' }}
            </div>

            <!-- Progress & Actions -->
            <div v-if="req.status === 'Pending'" class="mt-4">
              <button 
                class="w-full bg-[#ff6b35] hover:bg-[#e55a2b] text-white text-xs font-bold py-2 rounded-lg transition-fast touch-target"
                @click="startGrillRequest(req)"
              >
                BẮT ĐẦU THỰC HIỆN
              </button>
            </div>

            <div v-else-if="req.status === 'Inprogress'" class="space-y-2 mt-3">
              <!-- Timer & Progress Bar -->
              <div class="flex justify-between text-xs text-[#4CAF50] font-bold">
                <span>Đang xử lý...</span>
                <span>{{ formatWaitTime(req.timeLeft || 0) }}</span>
              </div>
              <div class="w-full bg-gray-700 h-2 rounded-full overflow-hidden">
                <div class="bg-[#4CAF50] h-full transition-all duration-1000" :style="{ width: `${(req.timeLeft || 0) * 100 / 120}%` }"></div>
              </div>
              <button 
                class="w-full bg-[#2E7D32] hover:bg-[#256629] text-white text-xs font-bold py-2 rounded-lg transition-fast mt-2 touch-target"
                @click="completeGrillRequest(req)"
              >
                HOÀN TẤT NGAY
              </button>
            </div>

            <div class="text-[10px] text-gray-500 mt-2 font-mono">Đã gửi: {{ getRequestElapsedTime(req.createdAt) }} trước</div>
          </div>

          <div v-if="grillRequests.length === 0" class="text-center py-8 text-gray-500 text-sm">
            <div class="text-3xl mb-2">🔥</div>
            Không có yêu cầu vỉ/than nào đang hoạt động.
          </div>

        </div>
      </aside>

    </div>

    <!-- 5. TICKET DETAIL MODAL (600px max) -->
    <div v-if="selectedOrder" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in" @click.self="closeDetail">
      <div class="bg-[#2D2D2D] border border-[#404040] rounded-2xl w-full max-w-[600px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
        
        <!-- Modal Header -->
        <div class="px-6 py-4 bg-[#1A1A1A] border-b border-[#404040] flex justify-between items-center">
          <div>
            <h3 class="text-2xl font-black text-white">Chi tiết Ticket #{{ selectedOrder.id.slice(0, 8) }}</h3>
            <p class="text-xs text-gray-400 mt-1">Khởi tạo lúc: {{ selectedOrder.time }} &bull; Đã chờ {{ formatWaitTime(selectedOrder.waitTime) }}</p>
          </div>
          <button @click="closeDetail" class="w-10 h-10 rounded-full bg-[#3D3D3D] hover:bg-[#4A4A4A] flex items-center justify-center border border-[#616161] transition-fast text-white touch-target">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Modal Content -->
        <div class="p-6 overflow-y-auto space-y-6">
          
          <!-- Basic Info -->
          <div class="grid grid-cols-2 gap-4 bg-[#1A1A1A] p-4 rounded-xl border border-[#404040]">
            <div>
              <span class="text-xs text-gray-500 uppercase font-bold block">Bàn vật lý</span>
              <span class="text-2xl font-black text-white">Bàn {{ getTableCode(selectedOrder.table) }}</span>
            </div>
            <div>
              <span class="text-xs text-gray-500 uppercase font-bold block">Trạng thái hiện tại</span>
              <span class="text-lg font-bold block mt-1" :class="selectedOrder.status === 'pending' ? 'text-indigo-400' : selectedOrder.status === 'preparing' ? 'text-orange-400' : 'text-green-400'">
                {{ selectedOrder.status === 'pending' ? 'Đang chờ chế biến' : selectedOrder.status === 'preparing' ? 'Đang chế biến' : 'Đã hoàn thành' }}
              </span>
            </div>
          </div>

          <!-- Items list -->
          <div>
            <h4 class="text-xs text-gray-400 uppercase font-bold tracking-wider mb-3">Danh sách món chế biến</h4>
            <div class="space-y-3">
              <div 
                v-for="item in selectedOrder.items" 
                :key="item.id" 
                class="flex items-start gap-4 p-4 rounded-xl bg-[#1A1A1A] border border-[#404040] hover:bg-[#3D3D3D]/50 cursor-pointer transition-fast"
                @click="toggleItemStatus(item)"
              >
                <div class="mt-1">
                  <input 
                    type="checkbox" 
                    :checked="item.done" 
                    class="w-6 h-6 rounded border-gray-600 text-green-500 focus:ring-green-500 bg-[#2D2D2D] pointer-events-none"
                  >
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex justify-between items-baseline">
                    <span class="text-lg font-bold text-white block" :class="{ 'line-through text-gray-500': item.done }">
                      <span class="text-[#ff6b35] font-black text-xl mr-1">{{ item.qty }}x</span>
                      {{ item.name }}
                    </span>
                    <span class="text-xs text-gray-500 bg-[#2D2D2D] px-2 py-0.5 rounded border border-[#404040]">
                      {{ getStationLabel(getItemStation(item.name)) }}
                    </span>
                  </div>
                  <!-- Quick actions inside detail modal from kitchen_cooking_flow.mmd -->
                  <div v-if="getItemStation(item.name) === 'Grill' && selectedOrder.status === 'preparing'" class="flex items-center gap-2 mt-2">
                    <button 
                      @click.stop="triggerQuickRequest(selectedOrder.table, 'GrillChange')" 
                      class="px-2.5 py-1 bg-purple-950/60 border border-purple-800/60 rounded text-xs font-bold text-purple-300 hover:bg-purple-900/60 transition-fast touch-target"
                    >
                      🧹 Thay vỉ nướng
                    </button>
                    <button 
                      @click.stop="triggerQuickRequest(selectedOrder.table, 'CoalRefill')" 
                      class="px-2.5 py-1 bg-orange-950/60 border border-[#ff6b35]/60 rounded text-xs font-bold text-[#ff6b35] hover:bg-orange-900/60 transition-fast touch-target"
                    >
                      🔥 Châm thêm than
                    </button>
                  </div>
                  <div v-if="item.note" class="text-sm text-[#FFA726] italic mt-2 bg-[#FFA726]/10 p-2.5 rounded border border-[#FFA726]/20 flex items-start gap-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 flex-shrink-0 text-[#FFA726]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    <span>Ghi chú: {{ item.note }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Highlight notes / Allergies -->
          <div v-if="hasAllergyNote(selectedOrder)" class="bg-[#C62828]/10 border border-[#C62828]/35 p-4 rounded-xl text-[#F44336] flex items-start gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 flex-shrink-0 text-[#F44336] mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div>
              <span class="font-bold text-base block uppercase tracking-wider">Cảnh báo nghiêm trọng: Dị ứng thực phẩm!</span>
              <p class="text-sm text-red-300 mt-1">Đơn hàng này có chứa các yêu cầu đặc biệt về dị ứng hoặc loại bỏ nguyên liệu. Vui lòng đối soát kỹ lưỡng trước khi bưng món.</p>
            </div>
          </div>

        </div>

        <!-- Modal Footer Actions (Touch target large: 56px) -->
        <div class="px-6 py-4 bg-[#1A1A1A] border-t border-[#404040] flex justify-end gap-3">
          <button @click="closeDetail" class="action-button danger large border border-[#616161] bg-[#2D2D2D] hover:bg-[#3D3D3D] text-gray-200 rounded-xl font-bold transition-fast touch-target-large">
            Đóng
          </button>
          <button 
            v-if="selectedOrder.status === 'pending'"
            class="action-button primary large bg-[#ff6b35] text-white rounded-xl font-bold transition-fast touch-target-large"
            @click="modalStartCooking(selectedOrder)"
          >
            Bắt đầu chế biến
          </button>
          <button 
            v-if="selectedOrder.status === 'preparing'"
            class="action-button success large bg-[#2E7D32] text-white rounded-xl font-bold transition-fast touch-target-large"
            @click="modalFinishCooking(selectedOrder)"
          >
            Hoàn tất nấu
          </button>
        </div>

      </div>
    </div>

    <!-- NEW FEATURE: GRILL & COAL REQUEST CREATION MODAL -->
    <div v-if="showGrillRequestModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-fade-in" @click.self="showGrillRequestModal = false">
      <div class="bg-[#2D2D2D] border border-[#404040] rounded-2xl w-full max-w-[450px] shadow-2xl p-6 space-y-5">
        
        <div class="flex justify-between items-center pb-2 border-b border-[#404040]">
          <h3 class="text-xl font-black text-white">Yêu cầu Thay Vỉ / Châm Than</h3>
          <button @click="showGrillRequestModal = false" class="text-gray-400 hover:text-white transition-fast">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Form fields -->
        <div class="space-y-4">
          <!-- Table selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-gray-400 uppercase font-bold">Chọn bàn cần xử lý</label>
            <select 
              v-model="newRequestTable"
              class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-4 py-2 text-white focus:outline-none focus:border-[#ff6b35]"
            >
              <option value="" disabled>-- Chọn Bàn --</option>
              <option v-for="tbl in availableTablesForRequests" :key="tbl" :value="tbl">Bàn {{ tbl }}</option>
            </select>
          </div>

          <!-- Type selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-gray-400 uppercase font-bold">Loại yêu cầu</label>
            <div class="grid grid-cols-2 gap-3">
              <button 
                class="px-4 py-3 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="newRequestType === 'GrillChange' ? 'bg-purple-900/40 border-purple-500 text-purple-200' : 'bg-[#1A1A1A] border-[#616161] text-gray-400'"
                @click="newRequestType = 'GrillChange'"
              >
                Thay Vỉ Nướng
              </button>
              <button 
                class="px-4 py-3 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="newRequestType === 'CoalRefill' ? 'bg-orange-950/40 border-[#ff6b35] text-[#ff6b35]' : 'bg-[#1A1A1A] border-[#616161] text-gray-400'"
                @click="newRequestType = 'CoalRefill'"
              >
                Châm Thêm Than
              </button>
            </div>
          </div>

          <!-- Priority selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-gray-400 uppercase font-bold">Mức độ ưu tiên</label>
            <div class="grid grid-cols-2 gap-3">
              <button 
                class="px-4 py-2.5 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="newRequestPriority === 'Normal' ? 'bg-[#3D3D3D] border-[#616161] text-white' : 'bg-[#1A1A1A] border-[#616161] text-gray-400'"
                @click="newRequestPriority = 'Normal'"
              >
                Thường
              </button>
              <button 
                class="px-4 py-2.5 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="newRequestPriority === 'Urgent' ? 'bg-red-950/40 border-red-500 text-red-300' : 'bg-[#1A1A1A] border-[#616161] text-gray-400'"
                @click="newRequestPriority = 'Urgent'"
              >
                Gấp (Urgent)
              </button>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="flex justify-end gap-3 pt-3 border-t border-[#404040]">
          <button 
            class="px-4 py-2.5 bg-[#3D3D3D] hover:bg-[#4A4A4A] rounded-xl text-xs font-bold transition-fast text-gray-300 touch-target"
            @click="showGrillRequestModal = false"
          >
            Hủy bỏ
          </button>
          <button 
            class="px-6 py-2.5 bg-[#ff6b35] hover:bg-[#e55a2b] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-white transition-fast touch-target"
            :disabled="!newRequestTable"
            @click="createGrillRequest"
          >
            Gửi yêu cầu
          </button>
        </div>

      </div>
    </div>

    <!-- NEW FEATURE: KITCHEN HYGIENE & SAFETY (HACCP) MODAL -->
    <div v-if="showHaccpModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in" @click.self="showHaccpModal = false">
      <div class="bg-[#2D2D2D] border border-[#404040] rounded-2xl w-full max-w-[700px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
        
        <!-- Modal Header -->
        <div class="px-6 py-4 bg-[#1A1A1A] border-b border-[#404040] flex justify-between items-center">
          <div class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-[#4CAF50]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <div>
              <h3 class="text-xl font-black text-white uppercase tracking-wider">Nhật Ký An Toàn & Vệ Sinh HACCP</h3>
              <p class="text-xs text-gray-400">Giám sát chất lượng & tuân thủ quy chuẩn nhà bếp</p>
            </div>
          </div>
          <button @click="showHaccpModal = false" class="w-10 h-10 rounded-full bg-[#3D3D3D] hover:bg-[#4A4A4A] flex items-center justify-center border border-[#616161] transition-fast text-white touch-target">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Modal Tabs -->
        <div class="flex bg-[#1A1A1A]/50 border-b border-[#404040]">
          <button 
            v-for="tab in [
              { key: 'preshift', label: '1. Đầu Ca (Pre-Shift)' },
              { key: 'incidents', label: '2. Giám Sát Ca (Monitoring)' },
              { key: 'postshift', label: '3. Cuối Ca (Post-Shift)' },
              { key: 'approval', label: '4. Phê Duyệt (Sign-off)' }
            ]" 
            :key="tab.key"
            @click="haccpActiveTab = tab.key"
            class="flex-1 py-3 text-xs font-bold uppercase tracking-wider border-b-2 text-center transition-all touch-target"
            :class="haccpActiveTab === tab.key ? 'text-[#4CAF50] border-[#4CAF50] bg-[#2D2D2D]/30' : 'text-gray-400 border-transparent hover:text-gray-200'"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Modal Body Content -->
        <div class="p-6 overflow-y-auto space-y-6 flex-1 bg-[#2D2D2D]">
          
          <!-- TAB 1: PRE-SHIFT -->
          <div v-if="haccpActiveTab === 'preshift'" class="space-y-5 animate-fade-in">
            <div class="p-4 bg-[#3D3D3D]/30 border border-[#404040] rounded-xl space-y-4">
              <h4 class="text-sm font-bold text-[#4CAF50] uppercase tracking-wide">📋 Khảo sát vệ sinh đầu ngày</h4>
              
              <!-- Personal Hygiene Checkbox -->
              <label class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-[#1A1A1A]/30 border border-[#404040] hover:bg-[#1A1A1A]/50 transition-fast">
                <input 
                  type="checkbox" 
                  v-model="haccpPreHandHygiene" 
                  :disabled="haccpPreSaved"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#4CAF50] focus:ring-[#4CAF50] bg-[#1A1A1A]"
                >
                <div class="text-sm select-none">
                  <span class="font-bold text-gray-200 block">Vệ sinh cá nhân đạt chuẩn</span>
                  <span class="text-xs text-gray-400">Rửa tay sát khuẩn, đeo khẩu trang, đội mũ bếp, mặc tạp dề sạch sẽ trước khi vào khu vực chế biến.</span>
                </div>
              </label>

              <!-- FEFO Expiration Checkbox -->
              <label class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-[#1A1A1A]/30 border border-[#404040] hover:bg-[#1A1A1A]/50 transition-fast">
                <input 
                  type="checkbox" 
                  v-model="haccpPreFefoChecked" 
                  :disabled="haccpPreSaved"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#4CAF50] focus:ring-[#4CAF50] bg-[#1A1A1A]"
                >
                <div class="text-sm select-none">
                  <span class="font-bold text-gray-200 block">Kiểm tra hạn sử dụng (Áp dụng FEFO)</span>
                  <span class="text-xs text-gray-400">First Expired, First Out - Đảm bảo các nguyên liệu sắp hết hạn được xếp ra ngoài và sử dụng trước.</span>
                </div>
              </label>
            </div>

            <!-- Temperature log -->
            <div class="p-4 bg-[#3D3D3D]/30 border border-[#404040] rounded-xl space-y-4">
              <h4 class="text-sm font-bold text-[#4CAF50] uppercase tracking-wide">❄️ Đo nhiệt độ hệ thống bảo quản</h4>
              
              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-2">
                  <label class="text-xs text-gray-400 uppercase font-bold block">Tủ mát bảo quản (Chuẩn: 0 - 5°C)</label>
                  <div class="relative">
                    <input 
                      type="number" 
                      v-model="haccpPreFridgeTemp" 
                      :disabled="haccpPreSaved"
                      step="0.5"
                      class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-4 py-2 text-white text-lg font-bold focus:outline-none focus:border-[#4CAF50] pr-10"
                    />
                    <span class="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold">°C</span>
                  </div>
                </div>

                <div class="space-y-2">
                  <label class="text-xs text-gray-400 uppercase font-bold block">Tủ đông bảo quản (Chuẩn: &le; -18°C)</label>
                  <div class="relative">
                    <input 
                      type="number" 
                      v-model="haccpPreFreezerTemp" 
                      :disabled="haccpPreSaved"
                      step="0.5"
                      class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-4 py-2 text-white text-lg font-bold focus:outline-none focus:border-[#4CAF50] pr-10"
                    />
                    <span class="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold">°C</span>
                  </div>
                </div>
              </div>

              <!-- Temperature Out-of-bounds Alerts -->
              <div v-if="isTempAlertActive" class="p-4 bg-red-950/40 border border-red-800/40 rounded-xl space-y-3">
                <div class="flex items-start gap-2.5 text-red-400">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                  <div>
                    <span class="font-bold text-base block uppercase tracking-wider">⚠️ CẢNH BÁO BÁO ĐỘNG KHẨN CẤP</span>
                    <span class="text-xs text-red-300">Nhiệt độ hệ thống bảo quản vượt ngưỡng an toàn! Yêu cầu chuyển toàn bộ nguyên liệu sang tủ dự phòng để tránh hư hỏng thực phẩm.</span>
                  </div>
                </div>

                <label v-if="!haccpPreSaved" class="flex items-center gap-2 mt-2 cursor-pointer p-2 rounded bg-red-900/10 hover:bg-red-900/20 border border-red-800/30 transition-fast">
                  <input type="checkbox" v-model="tempTransferConfirmed" class="w-4.5 h-4.5 rounded border-red-600 text-red-500 focus:ring-red-500 bg-[#1A1A1A]">
                  <span class="text-xs font-bold text-red-300 select-none">Tôi xác nhận đã chuyển nguyên liệu an toàn sang tủ dự phòng khẩn cấp</span>
                </label>
              </div>
            </div>

            <!-- Save Pre-Shift Actions -->
            <div class="flex justify-end pt-2 border-t border-[#404040]">
              <button 
                v-if="!haccpPreSaved"
                @click="savePreShiftHaccp"
                class="px-6 py-2.5 bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-white transition-fast touch-target"
                :disabled="!haccpPreHandHygiene || !haccpPreFefoChecked || (isTempAlertActive && !tempTransferConfirmed)"
              >
                Ghi nhận đầu ca (HACCP)
              </button>
              <div v-else class="p-3 bg-[#4CAF50]/15 border border-[#4CAF50]/40 rounded-xl text-[#4CAF50] text-xs font-bold flex items-center gap-1.5 w-full justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                ĐÃ LƯU NHẬT KÝ ĐẦU CA - TỦ MÁT: {{ haccpPreFridgeTemp }}°C, TỦ ĐÔNG: {{ haccpPreFreezerTemp }}°C
              </div>
            </div>
          </div>

          <!-- TAB 2: MONITORING / INCIDENTS -->
          <div v-if="haccpActiveTab === 'incidents'" class="space-y-5 animate-fade-in">
            <div class="flex justify-between items-center">
              <h4 class="text-sm font-bold text-[#FFA726] uppercase tracking-wide">🚨 Nhật ký giám sát & Sự cố vệ sinh</h4>
              <button 
                v-if="!showNewIncidentForm"
                @click="showNewIncidentForm = true"
                class="bg-[#ff6b35] hover:bg-[#e55a2b] text-white px-3 py-1.5 rounded-lg text-xs font-bold transition-fast touch-target"
              >
                + Báo cáo sự cố mới
              </button>
            </div>

            <!-- New Incident Form -->
            <div v-if="showNewIncidentForm" class="p-4 bg-[#3D3D3D]/40 border border-[#FFA726]/30 rounded-xl space-y-4 animate-fade-in">
              <div class="flex justify-between items-center pb-2 border-b border-[#404040]">
                <span class="text-xs font-bold text-[#FFA726] uppercase">Báo cáo Sự cố mới</span>
                <button @click="showNewIncidentForm = false" class="text-gray-400 hover:text-white text-xs">Hủy</button>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-1.5">
                  <label class="text-[10px] text-gray-400 uppercase font-bold">Người báo cáo</label>
                  <input 
                    type="text" 
                    v-model="newIncidentReporter" 
                    placeholder="Tên nhân viên..."
                    class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#FFA726]"
                  />
                </div>
                <div class="space-y-1.5">
                  <label class="text-[10px] text-gray-400 uppercase font-bold">Phân loại sự cố</label>
                  <select 
                    v-model="newIncidentType"
                    class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#FFA726]"
                  >
                    <option value="FoodDrop">Rơi thức ăn xuống sàn (Dropped Food)</option>
                    <option value="CutHand">Tai nạn đứt tay / Chấn thương (Injury)</option>
                    <option value="CrossContamination">Nhiễm chéo thực phẩm (Cross Contamination)</option>
                    <option value="Other">Sự cố vệ sinh khác (Other)</option>
                  </select>
                </div>
              </div>

              <div class="space-y-1.5">
                <label class="text-[10px] text-gray-400 uppercase font-bold">Mô tả chi tiết & Hành động khắc phục ban đầu</label>
                <textarea 
                  v-model="newIncidentDescription" 
                  rows="3"
                  placeholder="Mô tả sự việc và các bước đã xử lý ngay lập tức..."
                  class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#FFA726]"
                ></textarea>
              </div>

              <div class="flex justify-end gap-2">
                <button 
                  @click="showNewIncidentForm = false"
                  class="px-4 py-2 bg-[#3D3D3D] hover:bg-[#4A4A4A] rounded-xl text-xs font-bold text-gray-300 touch-target"
                >
                  Hủy
                </button>
                <button 
                  @click="submitIncidentReport"
                  :disabled="!newIncidentReporter || !newIncidentDescription"
                  class="px-5 py-2 bg-[#FFA726] hover:bg-[#fb8c00] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-black transition-fast touch-target"
                >
                  Gửi báo cáo sự cố
                </button>
              </div>
            </div>

            <!-- Incidents List -->
            <div class="space-y-3">
              <div v-for="inc in haccpIncidents" :key="inc.id" class="p-4 bg-[#1A1A1A] border-l-4 rounded-xl shadow-md transition-fast relative" :class="inc.status === 'Pending' ? 'border-[#C62828] bg-red-950/5' : 'border-gray-600 opacity-70'">
                
                <button v-if="inc.status === 'Pending'" @click="haccpIncidents = haccpIncidents.filter(i => i.id !== inc.id); saveHaccpState();" class="absolute top-2 right-2 text-gray-500 hover:text-white transition-fast">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                </button>

                <div class="flex justify-between items-baseline mb-2">
                  <div class="flex items-center gap-2">
                    <span class="text-xs font-bold bg-[#3D3D3D] text-gray-300 px-2 py-0.5 rounded">
                      {{ inc.reporter }}
                    </span>
                    <span class="text-[10px] text-gray-500 font-mono">
                      {{ new Date(inc.timestamp).toLocaleTimeString() }}
                    </span>
                  </div>
                  <span class="text-[10px] px-2 py-0.5 rounded font-bold uppercase" :class="inc.status === 'Pending' ? 'bg-[#C62828] text-white animate-pulse' : 'bg-green-950 text-green-300 border border-green-800'">
                    {{ inc.status === 'Pending' ? 'Đang xử lý y tế / vệ sinh' : 'Đã xử lý xong' }}
                  </span>
                </div>

                <div class="text-sm font-semibold text-gray-200 mb-1">
                  {{ 
                    inc.type === 'FoodDrop' ? '🍕 Rơi thức ăn xuống sàn' :
                    inc.type === 'CutHand' ? '🩹 Sơ cứu chấn thương' :
                    inc.type === 'CrossContamination' ? '🧬 Nghi ngờ nhiễm chéo' : '⚠️ Sự cố vệ sinh khác'
                  }}
                </div>
                <p class="text-xs text-gray-400">{{ inc.description }}</p>

                <!-- Resolution section -->
                <div v-if="inc.status === 'Pending'" class="mt-3 pt-3 border-t border-[#404040]/40 flex justify-end">
                  <button 
                    @click="resolveIncidentPrompt(inc)"
                    class="bg-[#2E7D32] hover:bg-[#256629] text-white text-[10px] font-bold px-3 py-1.5 rounded-lg transition-fast touch-target"
                  >
                    XÁC NHẬN ĐÃ XỬ LÝ (SƠ CỨU/DỌN DẸP)
                  </button>
                </div>
                <div v-else class="mt-2 bg-[#2D2D2D]/60 p-2 rounded text-xs border border-green-800/20 text-green-400">
                  <span class="font-bold block">Biện pháp khắc phục:</span>
                  <span class="italic text-gray-300">{{ inc.resolutionNote }}</span>
                </div>
              </div>

              <div v-if="haccpIncidents.length === 0" class="text-center py-8 text-gray-500 text-sm">
                <div class="text-3xl mb-2">🍏</div>
                Không ghi nhận sự cố vệ sinh nào trong ca trực.
              </div>
            </div>
          </div>

          <!-- TAB 3: POST-SHIFT -->
          <div v-if="haccpActiveTab === 'postshift'" class="space-y-5 animate-fade-in">
            <div class="p-4 bg-[#3D3D3D]/30 border border-[#404040] rounded-xl space-y-4">
              <h4 class="text-sm font-bold text-[#4CAF50] uppercase tracking-wide">🧹 Quy trình đóng ca & Dọn dẹp vệ sinh</h4>
              
              <!-- Surface cleaning checkbox -->
              <label class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-[#1A1A1A]/30 border border-[#404040] hover:bg-[#1A1A1A]/50 transition-fast">
                <input 
                  type="checkbox" 
                  v-model="haccpPostCleaning" 
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#4CAF50] focus:ring-[#4CAF50] bg-[#1A1A1A]"
                >
                <div class="text-sm select-none">
                  <span class="font-bold text-gray-200 block">Vệ sinh bề mặt bàn bếp & Thiết bị chế biến</span>
                  <span class="text-xs text-gray-400">Lau chùi bằng hóa chất sát khuẩn được cấp phép cho thớt, bề mặt bếp inox, dao kéo và lò nướng.</span>
                </div>
              </label>

              <!-- Waste sorting checkbox -->
              <label class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-[#1A1A1A]/30 border border-[#404040] hover:bg-[#1A1A1A]/50 transition-fast">
                <input 
                  type="checkbox" 
                  v-model="haccpPostWasteSorting" 
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#4CAF50] focus:ring-[#4CAF50] bg-[#1A1A1A]"
                >
                <div class="text-sm select-none">
                  <span class="font-bold text-gray-200 block">Phân loại & Thu gom rác thải</span>
                  <span class="text-xs text-gray-400">Đổ rác hữu cơ, rửa thùng rác, thay túi đựng rác mới và mang rác đến đúng nơi tập kết quy định.</span>
                </div>
              </label>

              <!-- Leftover wrap/labels checkbox -->
              <label class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-[#1A1A1A]/30 border border-[#404040] hover:bg-[#1A1A1A]/50 transition-fast">
                <input 
                  type="checkbox" 
                  v-model="haccpPostLeftoversStored" 
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-gray-600 text-[#4CAF50] focus:ring-[#4CAF50] bg-[#1A1A1A]"
                >
                <div class="text-sm select-none">
                  <span class="font-bold text-gray-200 block">Bảo quản nguyên liệu thừa</span>
                  <span class="text-xs text-gray-400">Các phần thịt, rau tươi chưa dùng hết cần bọc kín bằng màng co thực phẩm và dán nhãn thông tin ngày dán/hạn dùng.</span>
                </div>
              </label>
            </div>

            <!-- Notes -->
            <div class="space-y-1.5">
              <label class="text-xs text-gray-400 uppercase font-bold">Ghi chú vận hành bàn giao ca tiếp theo (HACCP)</label>
              <textarea 
                v-model="haccpPostShiftNote" 
                rows="3"
                :disabled="haccpPostSaved"
                placeholder="Nhập ghi chú bàn giao hoặc các thiết bị cần bảo trì..."
                class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#4CAF50]"
              ></textarea>
            </div>

            <!-- Actions -->
            <div class="flex justify-end pt-2 border-t border-[#404040]">
              <button 
                v-if="!haccpPostSaved"
                @click="savePostShiftHaccp"
                class="px-6 py-2.5 bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-white transition-fast touch-target"
                :disabled="!haccpPostCleaning || !haccpPostWasteSorting || !haccpPostLeftoversStored || unresolvedIncidentCount > 0"
              >
                Ghi nhận cuối ca (Digital HACCP Log)
              </button>
              <div v-else class="p-3 bg-[#4CAF50]/15 border border-[#4CAF50]/40 rounded-xl text-[#4CAF50] text-xs font-bold flex items-center gap-1.5 w-full justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                ĐÃ LƯU BÁO CÁO CUỐI CA. HỒ SƠ ĐÃ SẴN SÀNG ĐỂ BẾP TRƯỞNG PHÊ DUYỆT.
              </div>
            </div>
          </div>

          <!-- TAB 4: APPROVAL / HEAD CHEF SIGN-OFF -->
          <div v-if="haccpActiveTab === 'approval'" class="space-y-5 animate-fade-in">
            <div class="p-4 bg-[#3D3D3D]/30 border border-[#404040] rounded-xl space-y-4">
              <h4 class="text-sm font-bold text-[#2196F3] uppercase tracking-wide">🔬 Báo cáo tổng hợp ca trực (HACCP Summary)</h4>
              
              <div class="space-y-2.5 text-sm text-gray-300">
                <div class="flex justify-between border-b border-[#404040] pb-2">
                  <span>Trạng thái Kiểm tra đầu ca:</span>
                  <span class="font-bold" :class="haccpPreSaved ? 'text-green-400' : 'text-yellow-500'">
                    {{ haccpPreSaved ? 'Đã hoàn thành' : 'Chưa hoàn thành' }}
                  </span>
                </div>
                <div class="flex justify-between border-b border-[#404040] pb-2">
                  <span>Nhiệt độ đo đạc (Đầu ngày):</span>
                  <span class="font-bold">Tủ mát: {{ haccpPreFridgeTemp }}°C, Tủ đông: {{ haccpPreFreezerTemp }}°C</span>
                </div>
                <div class="flex justify-between border-b border-[#404040] pb-2">
                  <span>Tổng số Sự cố vệ sinh ghi nhận:</span>
                  <span class="font-bold" :class="haccpIncidents.length > 0 ? 'text-yellow-500' : 'text-green-400'">
                    {{ haccpIncidents.length }} (Đã giải quyết: {{ haccpIncidents.filter(i => i.status === 'Resolved').length }})
                  </span>
                </div>
                <div class="flex justify-between border-b border-[#404040] pb-2">
                  <span>Trạng thái Vệ sinh đóng ca:</span>
                  <span class="font-bold" :class="haccpPostSaved ? 'text-green-400' : 'text-yellow-500'">
                    {{ haccpPostSaved ? 'Đã hoàn thành' : 'Chưa hoàn thành' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Sign-off Form -->
            <div class="p-4 bg-[#3D3D3D]/30 border border-[#404040] rounded-xl space-y-4">
              <h4 class="text-sm font-bold text-[#2196F3] uppercase tracking-wide">✍️ Chữ ký phê duyệt của Bếp Trưởng</h4>
              
              <div class="space-y-4" v-if="!haccpHeadChefApproved">
                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="text-xs text-gray-400 uppercase font-bold">Tên Bếp Trưởng / Giám sát bếp</label>
                    <input 
                      type="text" 
                      v-model="haccpChefName" 
                      placeholder="Bếp Trưởng ký tên..."
                      class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-4 py-2 text-white text-sm focus:outline-none focus:border-[#2196F3]"
                    />
                  </div>
                  <div class="space-y-1.5">
                    <label class="text-xs text-gray-400 uppercase font-bold">Đánh giá chung chất lượng vệ sinh ca</label>
                    <select 
                      v-model="haccpHaccpStatus"
                      class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-4 py-2 text-white text-sm focus:outline-none focus:border-[#2196F3]"
                    >
                      <option value="Compliant">ĐẠT CHUẨN VỆ SINH & AN TOÀN HACCP</option>
                      <option value="NonCompliant">CÓ VI PHẠM (Yêu cầu họp bàn/huấn luyện lại)</option>
                    </select>
                  </div>
                </div>

                <div class="space-y-1.5">
                  <label class="text-xs text-gray-400 uppercase font-bold">Nhận xét của Bếp Trưởng & Kế hoạch cải thiện</label>
                  <textarea 
                    v-model="haccpActionNote" 
                    rows="3"
                    placeholder="Mô tả các điểm vi phạm nếu có hoặc hành động khắc phục huấn luyện..."
                    class="w-full bg-[#1A1A1A] border border-[#616161] rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#2196F3]"
                  ></textarea>
                </div>

                <button 
                  @click="approveShiftHaccp"
                  :disabled="!haccpChefName || !haccpPreSaved || !haccpPostSaved"
                  class="w-full bg-[#2196F3] hover:bg-[#1976d2] disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-bold py-3 rounded-xl transition-fast touch-target-large"
                >
                  KÝ XÁC NHẬN & LƯU HỒ SƠ LƯU TRỮ HACCP
                </button>
              </div>

              <!-- Approved Display -->
              <div v-else class="space-y-3">
                <div class="p-4 bg-green-950/40 border border-green-800/40 rounded-xl text-green-400 text-center space-y-2">
                  <div class="text-4xl">🏆</div>
                  <div class="font-black text-lg">HỒ SƠ HACCP ĐÃ ĐƯỢC PHÊ DUYỆT & LƯU TRỮ</div>
                  <p class="text-xs text-gray-300">Được phê duyệt bởi Bếp Trưởng **{{ haccpChefName }}** vào lúc {{ new Date().toLocaleString() }}</p>
                  <span class="inline-block mt-2 bg-green-900 border border-green-700 px-3 py-1 rounded text-xs font-bold uppercase">
                    {{ haccpHaccpStatus === 'Compliant' ? 'Đạt chuẩn HACCP' : 'Có vi phạm - Họp huấn luyện lại' }}
                  </span>
                </div>
                
                <button 
                  @click="resetHaccpForNewShift" 
                  class="w-full bg-[#3D3D3D] hover:bg-[#4A4A4A] border border-[#616161] text-gray-300 text-xs font-bold py-2.5 rounded-xl transition-fast touch-target"
                >
                  BẮT ĐẦU CA TRỰC MỚI (RESET LOGS)
                </button>
              </div>
            </div>
          </div>

        </div>
        
        <!-- Modal Footer -->
        <div class="px-6 py-4 bg-[#1A1A1A] border-t border-[#404040] flex justify-end">
          <button @click="showHaccpModal = false" class="px-6 py-2.5 bg-[#3D3D3D] hover:bg-[#4A4A4A] text-gray-200 border border-[#616161] rounded-xl font-bold transition-fast touch-target">
            Đóng bảng
          </button>
        </div>

      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { useRealtime } from '@/composables/useRealtime';
import { useOrder } from '@/composables/useOrder';
import type { OrderStatus } from '@/types/database';

const { watchTable } = useRealtime();
const { loading } = useOrder();

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
  time: string; // HH:mm
  timestamp: number;
  waitTime: number; // in seconds
  items: OrderItem[];
  status: 'pending' | 'preparing' | 'done';
}

// Grill & Coal Request structure
interface GrillRequest {
  id: string;
  table: string;
  type: 'GrillChange' | 'CoalRefill';
  status: 'Pending' | 'Inprogress' | 'Completed';
  priority: 'Normal' | 'Urgent';
  createdAt: number;
  timeLeft?: number; // count down seconds
  timer?: any; // interval handler
}

// Stations config mapping
const stations = [
  { key: 'ALL', label: 'Tất cả trạm' },
  { key: 'Grill', label: 'Bếp Nướng' },
  { key: 'Hotpot', label: 'Bếp Lẩu' },
  { key: 'Cold', label: 'Bếp Lạnh' },
  { key: 'Fried', label: 'Bếp Chiên' },
  { key: 'Bar', label: 'Bar/Đồ uống' }
];

// State variables
const orders = ref<Order[]>([]);
const activeStation = ref('ALL');
const sortOrder = ref('oldest');
const searchQuery = ref('');
const currentTime = ref(new Date().toLocaleTimeString());
const selectedOrder = ref<Order | null>(null);
const notification = ref<{type: 'success' | 'error' | 'info' | 'warning', message: string} | null>(null);

// Grill & Coal Request Management state
const grillRequests = ref<GrillRequest[]>([]);
const showGrillRequestModal = ref(false);
const showGrillSidebar = ref(true);
const newRequestTable = ref('');
const newRequestType = ref<'GrillChange' | 'CoalRefill'>('GrillChange');
const newRequestPriority = ref<'Normal' | 'Urgent'>('Normal');

let clockInterval: any = null;
let timerInterval: any = null;
let requestElapsedTimeInterval: any = null;

// Table mappings UUID -> Code
const tableMap = ref<Record<string, string>>({});

const fetchTableMap = async () => {
  try {
    const { data, error } = await supabase.from('tables').select('id, code');
    if (error) throw error;
    if (data) {
      const map: Record<string, string> = {};
      data.forEach((t: any) => {
        map[t.id] = t.code;
      });
      tableMap.value = map;
    }
  } catch (e) {
    console.error('Error fetching table map:', e);
  }
};

const getTableCode = (tableId: string | null): string => {
  if (!tableId) return 'T-??';
  if (tableId.length <= 4) return tableId; // already code
  return tableMap.value[tableId] || tableId.slice(0, 4);
};

// FIFO detection for oldest pending order
const oldestPendingOrderId = computed(() => {
  const pending = pendingOrders.value;
  if (pending.length === 0) return null;
  let oldest = pending[0];
  for (let i = 1; i < pending.length; i++) {
    if (pending[i].waitTime > oldest.waitTime) {
      oldest = pending[i];
    }
  }
  return oldest.id;
});

// Item Sub-steps states
interface SubStep {
  key: string;
  label: string;
}

const itemSubStepsState = ref<Record<string, Record<string, boolean>>>({});

const loadSubSteps = () => {
  try {
    const raw = localStorage.getItem('kds_item_sub_steps');
    if (raw) {
      itemSubStepsState.value = JSON.parse(raw);
    }
  } catch (e) {
    console.error('Error loading sub steps:', e);
  }
};

const saveSubSteps = () => {
  localStorage.setItem('kds_item_sub_steps', JSON.stringify(itemSubStepsState.value));
};

const isSubStepChecked = (itemId: string, stepKey: string): boolean => {
  return !!(itemSubStepsState.value[itemId] && itemSubStepsState.value[itemId][stepKey]);
};

const toggleSubStep = (itemId: string, stepKey: string) => {
  if (!itemSubStepsState.value[itemId]) {
    itemSubStepsState.value[itemId] = {};
  }
  itemSubStepsState.value[itemId][stepKey] = !itemSubStepsState.value[itemId][stepKey];
  saveSubSteps();
  
  // Play subtle sound when step is completed
  try {
    const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = 'sine';
    oscillator.frequency.value = itemSubStepsState.value[itemId][stepKey] ? 1200 : 600; 
    gainNode.gain.setValueAtTime(0.04, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.08);
  } catch (e) {
    // Ignore audio errors
  }
};

const getItemSubSteps = (itemName: string): SubStep[] => {
  const station = getItemStation(itemName);
  if (station === 'Grill') {
    return [
      { key: 'prep', label: '1. Sơ chế / FIFO' },
      { key: 'cook', label: '2. Nướng & Canh chín' },
      { key: 'plate', label: '3. Trở mặt & Plating' }
    ];
  } else if (station === 'Hotpot') {
    return [
      { key: 'broth', label: '1. Nước dùng & Rau' },
      { key: 'plate', label: '2. Sắp lẩu lên Pass' }
    ];
  } else {
    return [
      { key: 'recipe', label: '1. Làm theo Recipe' },
      { key: 'plate', label: '2. Decor lên Pass' }
    ];
  }
};

const triggerQuickRequest = (tableIdOrCode: string, type: 'GrillChange' | 'CoalRefill') => {
  const tableCode = getTableCode(tableIdOrCode);
  const id = `REQ-${Date.now()}`;
  grillRequests.value.push({
    id,
    table: tableCode,
    type,
    status: 'Pending',
    priority: 'Normal',
    createdAt: Date.now()
  });

  saveGrillRequests();
  playNewTicketSound();
  showNotification('success', `Đã gửi yêu cầu ${type === 'GrillChange' ? 'thay vỉ' : 'châm than'} cho Bàn ${tableCode}!`);
};

// HACCP Hygiene & Safety States & Logic based on kitchen_hygiene_safety.mmd
interface IncidentReport {
  id: string;
  timestamp: number;
  reporter: string;
  type: 'FoodDrop' | 'CutHand' | 'CrossContamination' | 'Other';
  description: string;
  status: 'Pending' | 'Resolved';
  resolutionNote?: string;
  resolvedAt?: number;
}

const showHaccpModal = ref(false);
const haccpActiveTab = ref<'preshift' | 'incidents' | 'postshift' | 'approval'>('preshift');

// Pre-shift state
const haccpPreHandHygiene = ref(false);
const haccpPreFridgeTemp = ref<number | null>(4);
const haccpPreFreezerTemp = ref<number | null>(-20);
const haccpPreFefoChecked = ref(false);
const haccpPreSaved = ref(false);

const isTempAlertActive = computed(() => {
  const fridgeVal = haccpPreFridgeTemp.value;
  const freezerVal = haccpPreFreezerTemp.value;
  
  const isFridgeOut = fridgeVal !== null && (fridgeVal < 0 || fridgeVal > 5);
  const isFreezerOut = freezerVal !== null && freezerVal > -18;
  
  return isFridgeOut || isFreezerOut;
});

const tempTransferConfirmed = ref(false);

// Incidents state
const haccpIncidents = ref<IncidentReport[]>([]);
const showNewIncidentForm = ref(false);
const newIncidentReporter = ref('');
const newIncidentType = ref<'FoodDrop' | 'CutHand' | 'CrossContamination' | 'Other'>('FoodDrop');
const newIncidentDescription = ref('');

const unresolvedIncidentCount = computed(() => {
  return haccpIncidents.value.filter(i => i.status === 'Pending').length;
});

// Post-shift state
const haccpPostCleaning = ref(false);
const haccpPostWasteSorting = ref(false);
const haccpPostLeftoversStored = ref(false);
const haccpPostShiftNote = ref('');
const haccpPostSaved = ref(false);

// Head Chef Approval state
const haccpHeadChefApproved = ref(false);
const haccpChefName = ref('');
const haccpHaccpStatus = ref<'Compliant' | 'NonCompliant'>('Compliant');
const haccpActionNote = ref('');

const saveHaccpState = () => {
  const data = {
    preHandHygiene: haccpPreHandHygiene.value,
    preFridgeTemp: haccpPreFridgeTemp.value,
    preFreezerTemp: haccpPreFreezerTemp.value,
    preFefoChecked: haccpPreFefoChecked.value,
    preSaved: haccpPreSaved.value,
    incidents: haccpIncidents.value,
    postCleaning: haccpPostCleaning.value,
    postWasteSorting: haccpPostWasteSorting.value,
    postLeftoversStored: haccpPostLeftoversStored.value,
    postShiftNote: haccpPostShiftNote.value,
    postSaved: haccpPostSaved.value,
    headChefApproved: haccpHeadChefApproved.value,
    chefName: haccpChefName.value,
    haccpStatus: haccpHaccpStatus.value,
    actionNote: haccpActionNote.value
  };
  localStorage.setItem('kds_haccp_state', JSON.stringify(data));
};

const loadHaccpState = () => {
  try {
    const raw = localStorage.getItem('kds_haccp_state');
    if (raw) {
      const data = JSON.parse(raw);
      haccpPreHandHygiene.value = !!data.preHandHygiene;
      haccpPreFridgeTemp.value = data.preFridgeTemp !== undefined ? data.preFridgeTemp : 4;
      haccpPreFreezerTemp.value = data.preFreezerTemp !== undefined ? data.preFreezerTemp : -20;
      haccpPreFefoChecked.value = !!data.preFefoChecked;
      haccpPreSaved.value = !!data.preSaved;
      haccpIncidents.value = data.incidents || [];
      haccpPostCleaning.value = !!data.postCleaning;
      haccpPostWasteSorting.value = !!data.postWasteSorting;
      haccpPostLeftoversStored.value = !!data.postLeftoversStored;
      haccpPostShiftNote.value = data.postShiftNote || '';
      haccpPostSaved.value = !!data.postSaved;
      haccpHeadChefApproved.value = !!data.headChefApproved;
      haccpChefName.value = data.chefName || '';
      haccpHaccpStatus.value = data.haccpStatus || 'Compliant';
      haccpActionNote.value = data.actionNote || '';
    }
  } catch (e) {
    console.error('Error loading HACCP state:', e);
  }
};

const savePreShiftHaccp = () => {
  haccpPreSaved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification('success', 'Đã lưu kết quả kiểm tra đầu ca (HACCP) thành công!');
};

const submitIncidentReport = () => {
  if (!newIncidentReporter.value || !newIncidentDescription.value) return;
  
  const id = `INC-${Date.now()}`;
  haccpIncidents.value.push({
    id,
    timestamp: Date.now(),
    reporter: newIncidentReporter.value,
    type: newIncidentType.value,
    description: newIncidentDescription.value,
    status: 'Pending'
  });

  saveHaccpState();
  playNewTicketSound();
  showNotification('warning', 'Đã ghi nhận sự cố vệ sinh/an toàn mới! Vui lòng dọn dẹp hoặc sơ cứu.');
  
  newIncidentReporter.value = '';
  newIncidentDescription.value = '';
  showNewIncidentForm.value = false;
};

const resolveIncidentPrompt = (inc: IncidentReport) => {
  const note = prompt('Mô tả biện pháp dọn dẹp / sơ cứu y tế đã thực hiện:');
  if (note === null) return;
  
  inc.status = 'Resolved';
  inc.resolutionNote = note || 'Đã dọn dẹp vệ sinh / sơ cứu y tế đúng quy chuẩn.';
  inc.resolvedAt = Date.now();
  
  saveHaccpState();
  playNewTicketSound();
  showNotification('success', 'Đã xác nhận xử lý xong sự cố vệ sinh.');
};

const savePostShiftHaccp = () => {
  haccpPostSaved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification('success', 'Đã lưu nhật ký vệ sinh cuối ca (HACCP) thành công!');
};

const approveShiftHaccp = () => {
  if (!haccpChefName.value) return;
  
  haccpHeadChefApproved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification('success', `Bếp Trưởng ${haccpChefName.value} đã ký duyệt báo cáo HACCP ca trực.`);
};

const resetHaccpForNewShift = () => {
  const currentLog = {
    shiftDate: new Date().toLocaleDateString(),
    chefName: haccpChefName.value,
    status: haccpHaccpStatus.value,
    actionNote: haccpActionNote.value,
    fridgeTemp: haccpPreFridgeTemp.value,
    freezerTemp: haccpPreFreezerTemp.value,
    incidentCount: haccpIncidents.value.length
  };
  
  try {
    const historyRaw = localStorage.getItem('kds_haccp_history');
    const history = historyRaw ? JSON.parse(historyRaw) : [];
    history.push(currentLog);
    localStorage.setItem('kds_haccp_history', JSON.stringify(history));
  } catch (e) {
    console.error('Error saving history:', e);
  }

  haccpPreHandHygiene.value = false;
  haccpPreFridgeTemp.value = 4;
  haccpPreFreezerTemp.value = -20;
  haccpPreFefoChecked.value = false;
  haccpPreSaved.value = false;
  haccpIncidents.value = [];
  haccpPostCleaning.value = false;
  haccpPostWasteSorting.value = false;
  haccpPostLeftoversStored.value = false;
  haccpPostShiftNote.value = '';
  haccpPostSaved.value = false;
  haccpHeadChefApproved.value = false;
  haccpChefName.value = '';
  haccpHaccpStatus.value = 'Compliant';
  haccpActionNote.value = '';
  tempTransferConfirmed.value = false;

  localStorage.removeItem('kds_haccp_state');
  showNotification('info', 'Đã khởi tạo nhật ký HACCP cho ca trực mới.');
  haccpActiveTab.value = 'preshift';
};

// Helpers to get station for items
const getItemStation = (name: string): 'Grill' | 'Hotpot' | 'Cold' | 'Fried' | 'Bar' => {
  const lower = name.toLowerCase();
  if (lower.includes('nướng') || lower.includes('sườn') || lower.includes('steak') || lower.includes('ba chỉ') || lower.includes('bò') || lower.includes('wagyu')) return 'Grill';
  if (lower.includes('lẩu') || lower.includes('sukiyaki') || lower.includes('soup') || lower.includes('canh')) return 'Hotpot';
  if (lower.includes('rau') || lower.includes('gỏi') || lower.includes('salad') || lower.includes('lạnh') || lower.includes('sushi') || lower.includes('kim chi') || lower.includes('dưa')) return 'Cold';
  if (lower.includes('chiên') || lower.includes('khoai tây') || lower.includes('tempura') || lower.includes('nem') || lower.includes('gà')) return 'Fried';
  return 'Bar';
};

const getStationLabel = (key: string): string => {
  const s = stations.find(item => item.key === key);
  return s ? s.label : 'Khác';
};

// Play audio alert when a new order or request comes in
const playNewTicketSound = () => {
  try {
    const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = 'sine';
    oscillator.frequency.value = 880; // A5 note
    gainNode.gain.setValueAtTime(0.08, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.15);
  } catch (e) {
    console.warn('Audio context failed to initialize:', e);
  }
};

// Alerts display helper
const showNotification = (type: 'success' | 'error' | 'info' | 'warning', message: string) => {
  notification.value = { type, message };
  setTimeout(() => {
    notification.value = null;
  }, 4000);
};

// Check if ticket has allergy or warning notes
const hasAllergyNote = (order: Order): boolean => {
  return order.items.some(i => {
    const note = (i.note || '').toLowerCase();
    return note.includes('dị ứng') || note.includes('allergy') || note.includes('nghiêm trọng');
  });
};

// Available tables selector populated from active orders + defaults
const availableTablesForRequests = computed(() => {
  const activeTables = orders.value.map(o => getTableCode(o.table));
  const defaults = ['A01', 'A02', 'A03', 'A04', 'A05', 'B01', 'B02', 'B03', 'C01', 'C02'];
  return Array.from(new Set([...activeTables, ...defaults])).sort();
});

// Create new grill change request
const createGrillRequest = () => {
  if (!newRequestTable.value) return;
  
  const id = `REQ-${Date.now()}`;
  grillRequests.value.push({
    id,
    table: newRequestTable.value,
    type: newRequestType.value,
    status: 'Pending',
    priority: newRequestPriority.value,
    createdAt: Date.now()
  });

  // Save to localStorage
  saveGrillRequests();

  // Sounds & Alerts
  playNewTicketSound();
  showNotification(
    newRequestPriority.value === 'Urgent' ? 'warning' : 'success', 
    `Đã gửi yêu cầu ${newRequestType.value === 'GrillChange' ? 'thay vỉ' : 'châm than'} gấp cho Bàn ${newRequestTable.value}!`
  );

  // Reset form
  newRequestTable.value = '';
  showGrillRequestModal.value = false;
};

// Start treating request (simulates the 2-3 minutes process)
const startGrillRequest = (req: GrillRequest) => {
  req.status = 'Inprogress';
  req.timeLeft = 120; // 120 seconds (2 minutes)
  
  // Clear any existing timer
  if (req.timer) clearInterval(req.timer);

  const timer = setInterval(() => {
    if (req.timeLeft && req.timeLeft > 0) {
      req.timeLeft--;
      saveGrillRequests();
    } else {
      clearInterval(timer);
      completeGrillRequest(req);
    }
  }, 1000);

  req.timer = timer;
  saveGrillRequests();
  showNotification('info', `Bắt đầu thực hiện ${req.type === 'GrillChange' ? 'thay vỉ' : 'châm than'} cho Bàn ${req.table}. Dự kiến 2 phút.`);
};

// Finish request
const completeGrillRequest = (req: GrillRequest) => {
  if (req.timer) clearInterval(req.timer);
  grillRequests.value = grillRequests.value.filter(r => r.id !== req.id);
  saveGrillRequests();
  showNotification('success', `Đã hoàn tất xử lý vỉ/than cho Bàn ${req.table}!`);
  playNewTicketSound();
};

// Cancel/Delete request
const cancelGrillRequest = (req: GrillRequest) => {
  if (req.timer) clearInterval(req.timer);
  grillRequests.value = grillRequests.value.filter(r => r.id !== req.id);
  saveGrillRequests();
  showNotification('info', `Đã hủy yêu cầu vỉ/than tại Bàn ${req.table}.`);
};

// Get elapsed time in minutes:seconds
const getRequestElapsedTime = (createdAt: number): string => {
  const diffSec = Math.floor((Date.now() - createdAt) / 1000);
  return formatWaitTime(diffSec);
};

// Save requests to localStorage
const saveGrillRequests = () => {
  // Save requests without timers
  const data = grillRequests.value.map(r => ({
    id: r.id,
    table: r.table,
    type: r.type,
    status: r.status,
    priority: r.priority,
    createdAt: r.createdAt,
    timeLeft: r.timeLeft
  }));
  localStorage.setItem('kds_grill_requests', JSON.stringify(data));
};

// Load requests from localStorage
const loadGrillRequests = () => {
  try {
    const raw = localStorage.getItem('kds_grill_requests');
    if (raw) {
      const data = JSON.parse(raw) as any[];
      grillRequests.value = data.map(r => {
        let timer = null;
        if (r.status === 'Inprogress' && r.timeLeft && r.timeLeft > 0) {
          // Re-establish timer
          const timeLeftVal = ref(r.timeLeft);
          const interval = setInterval(() => {
            if (timeLeftVal.value > 0) {
              timeLeftVal.value--;
              r.timeLeft = timeLeftVal.value;
              saveGrillRequests();
            } else {
              clearInterval(interval);
              const found = grillRequests.value.find(req => req.id === r.id);
              if (found) completeGrillRequest(found);
            }
          }, 1000);
          timer = interval;
        }

        return {
          id: r.id,
          table: r.table,
          type: r.type,
          status: r.status,
          priority: r.priority,
          createdAt: r.createdAt,
          timeLeft: r.timeLeft,
          timer
        };
      });
    }
  } catch (e) {
    console.error('Error loading grill requests:', e);
  }
};

// Computed property filtering orders
const filteredOrders = computed(() => {
  let result = orders.value.map(order => {
    // Slice items by active station
    let items = order.items;
    if (activeStation.value !== 'ALL') {
      items = order.items.filter(item => getItemStation(item.name) === activeStation.value);
    }
    return {
      ...order,
      displayItems: items
    };
  });

  // Filter out orders with no items belonging to this station
  result = result.filter(order => order.displayItems.length > 0);

  // Search by search query
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(order => 
      order.table.toLowerCase().includes(q) || 
      order.id.toLowerCase().includes(q)
    );
  }

  // Sorting
  if (sortOrder.value === 'oldest') {
    result.sort((a, b) => b.waitTime - a.waitTime);
  } else if (sortOrder.value === 'newest') {
    result.sort((a, b) => a.waitTime - b.waitTime);
  } else if (sortOrder.value === 'priority') {
    const isPriority = (o: any) => {
      const isDelayed = o.waitTime >= 900;
      const hasAllergy = o.items.some((i: any) => {
        const note = (i.note || '').toLowerCase();
        return note.includes('dị ứng') || note.includes('allergy') || note.includes('vip') || note.includes('gấp') || note.includes('lại');
      });
      return (isDelayed ? 2 : 0) + (hasAllergy ? 3 : 0);
    };
    result.sort((a, b) => {
      const aPri = isPriority(a);
      const bPri = isPriority(b);
      if (aPri !== bPri) return bPri - aPri;
      return b.waitTime - a.waitTime; // fallback oldest
    });
  }

  return result;
});

// Kanban column divisions
const pendingOrders = computed(() => filteredOrders.value.filter(o => o.status === 'pending'));
const preparingOrders = computed(() => filteredOrders.value.filter(o => o.status === 'preparing'));
const doneOrders = computed(() => filteredOrders.value.filter(o => o.status === 'done'));

// Status counts
const countPending = computed(() => orders.value.filter(o => o.status === 'pending').length);
const countPreparing = computed(() => orders.value.filter(o => o.status === 'preparing').length);
const countDone = computed(() => orders.value.filter(o => o.status === 'done').length);
const countDelayed = computed(() => orders.value.filter(o => o.status !== 'done' && o.waitTime >= 900).length);

// Actions handlers
const toggleItemStatus = async (item: OrderItem) => {
  item.done = !item.done;
  const newStatus: OrderStatus = item.done ? 'Served' : 'Preparing';
  try {
    const { error: err } = await supabase.from('order_items').update({ status: newStatus }).eq('id', item.id);
    if (err) throw err;
    showNotification('success', `Đã cập nhật trạng thái món: ${item.name}`);
  } catch (e) {
    showNotification('error', `Không thể cập nhật trạng thái món: ${e instanceof Error ? e.message : String(e)}`);
    item.done = !item.done; // roll back on error
  }
};

const moveToPreparing = async (order: Order) => {
  order.status = 'preparing';
  try {
    const { error: err } = await supabase.from('orders').update({ status: 'Preparing' }).eq('id', order.id);
    if (err) throw err;
    showNotification('info', `Bàn ${getTableCode(order.table)}: Bắt đầu chế biến.`);
  } catch (e) {
    showNotification('error', `Lỗi kết nối: ${e instanceof Error ? e.message : String(e)}`);
    order.status = 'pending';
  }
};

const moveToDone = async (order: Order) => {
  order.status = 'done';
  order.items.forEach(item => item.done = true);
  try {
    const { error: err1 } = await supabase.from('orders').update({ status: 'Served' }).eq('id', order.id);
    const { error: err2 } = await supabase.from('order_items').update({ status: 'Served' }).eq('order_id', order.id);
    if (err1 || err2) throw (err1 || err2);
    showNotification('success', `Bàn ${getTableCode(order.table)}: Đơn hàng hoàn tất và sẵn sàng phục vụ.`);
  } catch (e) {
    showNotification('error', `Lỗi kết nối: ${e instanceof Error ? e.message : String(e)}`);
    order.status = 'preparing';
  }
};

// Modal functions
const openDetail = (order: Order) => {
  selectedOrder.value = order;
};

const closeDetail = () => {
  selectedOrder.value = null;
};

const modalStartCooking = (order: Order) => {
  moveToPreparing(order);
  closeDetail();
};

const modalFinishCooking = (order: Order) => {
  moveToDone(order);
  closeDetail();
};

// Timer UI helper styles
const getTimerColorClass = (seconds: number): string => {
  const minutes = seconds / 60;
  if (minutes >= 15) return 'border-red-500 bg-red-950/20 delayed-pulse';
  if (minutes >= 10) return 'border-yellow-500 bg-yellow-900/10';
  return 'border-indigo-900/50 bg-indigo-950/5';
};

const getTimerTextClass = (seconds: number): string => {
  const minutes = seconds / 60;
  if (minutes >= 20) return 'text-[#F44336] animate-blink font-black text-shadow-red';
  if (minutes >= 15) return 'text-[#F44336] font-bold';
  if (minutes >= 10) return 'text-[#FFA726]';
  return 'text-[#4CAF50]';
};

const formatWaitTime = (seconds: number): string => {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
};

onMounted(async () => {
  // Load local requests, sub-steps & HACCP states
  loadGrillRequests();
  loadSubSteps();
  loadHaccpState();

  // Fetch table mappings
  await fetchTableMap();

  // Update Clock
  clockInterval = setInterval(() => {
    currentTime.value = new Date().toLocaleTimeString();
  }, 1000);

  // Fetch initial raw orders
  try {
    const { data: rawOrders, error: err } = await supabase
      .from('orders')
      .select('id, table_id, created_at, status, order_items(id, name_snapshot, quantity, note, status)');
    if (err) throw err;

    if (rawOrders) {
      orders.value = rawOrders.map((ro: any) => {
        const d = new Date(ro.created_at);
        let st: 'pending'|'preparing'|'done' = 'pending';
        if (ro.status === 'Preparing') st = 'preparing';
        if (ro.status === 'Served' || ro.status === 'Paid') st = 'done';
        
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
    }
  } catch (e) {
    showNotification('error', `Lỗi tải dữ liệu bếp: ${e instanceof Error ? e.message : String(e)}`);
  }

  // Realtime subscription for orders
  watchTable('orders', '*', (payload) => {
    const order = payload.new as any;
    const existing = orders.value.find(o => o.id === order.id);
    if (existing) {
      if (order.status === 'Preparing') existing.status = 'preparing';
      else if (order.status === 'Served' || order.status === 'Paid') existing.status = 'done';
      else if (order.status === 'Pending') existing.status = 'pending';
    } else if (order.id && payload.eventType === 'INSERT') {
      const d = new Date(order.created_at || Date.now());
      orders.value.push({
        id: order.id,
        table: order.table_id || 'T-??',
        time: d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        timestamp: d.getTime(),
        waitTime: 0,
        status: 'pending',
        items: []
      });
      playNewTicketSound();
    }
  });

  // Realtime subscription for order_items
  watchTable('order_items', '*', (payload) => {
    const item = payload.new as any;
    if (payload.eventType === 'INSERT') {
      const existingOrder = orders.value.find(o => o.id === item.order_id);
      if (existingOrder) {
        if (!existingOrder.items.some(i => i.id === item.id)) {
          existingOrder.items.push({
            id: item.id,
            name: item.name_snapshot,
            qty: item.quantity,
            note: item.note,
            done: item.status === 'Served' || item.status === 'Paid'
          });
          playNewTicketSound();
        }
      }
    } else if (payload.eventType === 'UPDATE') {
      for (const o of orders.value) {
        const existingItem = o.items.find(i => i.id === item.id);
        if (existingItem) {
          existingItem.done = (item.status === 'Served' || item.status === 'Paid');
        }
      }
    }
  });

  // Seconds counter updates wait times
  timerInterval = setInterval(() => {
    const now = Date.now();
    orders.value.forEach(order => {
      if (order.status !== 'done') {
        order.waitTime = Math.floor((now - order.timestamp) / 1000);
      }
    });
  }, 1000);

  // Trigger state updates for request elapsed times
  requestElapsedTimeInterval = setInterval(() => {
    // Simply forces computed updates
  }, 5000);
});

onUnmounted(() => {
  if (clockInterval) clearInterval(clockInterval);
  if (timerInterval) clearInterval(timerInterval);
  if (requestElapsedTimeInterval) clearInterval(requestElapsedTimeInterval);
  grillRequests.value.forEach(r => {
    if (r.timer) clearInterval(r.timer);
  });
});
</script>

<style scoped>
/* Dark Theme Custom styling props */
.kds-container {
  font-feature-settings: "cv02", "cv03", "cv04", "cv11";
}

.ticket-card {
  background: #2D2D2D;
  border-radius: 12px;
  padding: 16px;
  min-height: 220px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.35);
  cursor: pointer;
  border: 2.5px solid #404040;
}

.ticket-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.5);
  border-color: #ff6b35;
}

.ticket-card.status-new {
  border-color: #3949AB;
}

.ticket-card.status-cooking {
  border-color: #F57C00;
}

.ticket-card.status-ready {
  border-color: #2E7D32;
  background: linear-gradient(135deg, #2D2D2D 0%, #1f3721 100%);
}

/* Animations */
@keyframes delayed-border-pulse {
  0%, 100% {
    border-color: #C62828;
    box-shadow: 0 0 0 0 rgba(198, 40, 40, 0.45);
  }
  50% {
    border-color: #F44336;
    box-shadow: 0 0 0 8px rgba(198, 40, 40, 0);
  }
}

.delayed-pulse {
  animation: delayed-border-pulse 2s infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.35; }
}

.animate-blink {
  animation: blink 0.8s infinite;
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: scale(0.96);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-fade-in {
  animation: fade-in 0.25s ease-out forwards;
}

/* Text glow */
.text-shadow-red {
  text-shadow: 0 0 8px rgba(244, 67, 54, 0.6);
}

/* Alert banner classes */
.alert-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  font-weight: 700;
  border-bottom: 1.5px solid transparent;
  animation: slide-down 0.3s ease-out;
}

.alert-banner.success {
  background: rgba(76, 175, 80, 0.2);
  border-color: #4CAF50;
  color: #4CAF50;
}

.alert-banner.error {
  background: rgba(244, 67, 54, 0.2);
  border-color: #F44336;
  color: #F44336;
}

.alert-banner.info {
  background: rgba(33, 150, 243, 0.2);
  border-color: #2196F3;
  color: #2196F3;
}

.alert-banner.warning {
  background: rgba(255, 152, 0, 0.2);
  border-color: #FF9800;
  color: #FF9800;
}

@keyframes slide-down {
  from { transform: translateY(-100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

/* Status badges */
.status-badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  color: white;
  text-transform: uppercase;
}

.status-badge.delayed {
  background: #C62828;
}

/* Scrollbars */
.overflow-y-auto::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
.overflow-y-auto::-webkit-scrollbar-track {
  background: #1A1A1A;
  border-radius: 10px;
}
.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: #404040;
  border-radius: 10px;
  border: 2px solid #1A1A1A;
}
.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background-color: #616161;
}

/* Kanban column flex layouts height overrides */
.overflow-x-auto {
  height: calc(100vh - 190px);
}
</style>
