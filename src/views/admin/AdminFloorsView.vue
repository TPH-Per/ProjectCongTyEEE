<template>
  <div class="p-4 max-w-[1600px] mx-auto flex flex-col gap-4 pb-28 select-none bg-gray-50/50 min-h-screen text-gray-800 font-sans">
    
    <!-- Title & Status Legend Row -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-3 border-b border-gray-200/80 pb-3">
      <div>
        <h1 class="text-2xl font-black text-gray-900 tracking-tight flex items-center gap-2">
          <span>🖥️</span> Trung Tâm Điều Phối & Sơ Đồ Bàn
        </h1>
        <p class="text-xs text-gray-500 font-medium mt-0.5">Màn hình kiểm soát vận hành thời gian thực dành cho Lễ tân và Thu ngân</p>
      </div>

      <!-- Compact Status Legend -->
      <div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-wider">
        <div class="flex items-center gap-1 bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-xl border border-emerald-100/50">
          <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
          Trống
        </div>
        <div class="flex items-center gap-1 bg-amber-50 text-amber-700 px-2.5 py-1 rounded-xl border border-amber-100/50">
          <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
          Đặt trước
        </div>
        <div class="flex items-center gap-1 bg-blue-50 text-blue-700 px-2.5 py-1 rounded-xl border border-blue-100/50">
          <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
          Đã đến
        </div>
        <div class="flex items-center gap-1 bg-rose-50 text-rose-700 px-2.5 py-1 rounded-xl border border-rose-100/50">
          <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
          Phục vụ
        </div>
      </div>
    </div>

    <!-- 1.5 TIME SIMULATION DASHBOARD CONTROL -->
    <div class="bg-white border border-gray-200 rounded-2xl p-3 shadow-sm shrink-0 flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div class="flex items-center gap-3 select-none font-sans">
        <div class="w-9 h-9 rounded-xl bg-pink-50 flex items-center justify-center text-lg">🕒</div>
        <div>
          <h2 class="text-xs font-black text-gray-800 uppercase tracking-wide">Mốc Thời Gian Giả Lập</h2>
          <p class="text-[10px] text-gray-400 font-semibold mt-0.5">Kéo thanh trượt để xem lịch sử hoạt động và trạng thái bàn tương ứng</p>
        </div>
      </div>

      <!-- Time slider and current value -->
      <div class="flex-1 flex items-center gap-4 bg-gray-50 border border-gray-150 px-4 py-2 rounded-xl">
        <input 
          type="time" 
          v-model="inputSimulatedTime"
          class="text-xs font-black text-rose-600 bg-rose-50 border border-rose-250 px-2 py-1 rounded-lg shrink-0 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] cursor-pointer"
        />
        <div class="flex-1 flex items-center gap-2">
          <span class="text-[9px] text-gray-400 font-bold select-none">06:00</span>
          <input 
            type="range" 
            min="360" 
            max="1410" 
            step="15" 
            v-model="simulatedMinutes" 
            class="flex-1 accent-[#FF7B89] h-1.5 bg-gray-200 rounded-lg cursor-pointer"
          />
          <span class="text-[9px] text-gray-400 font-bold select-none">23:30</span>
        </div>
      </div>

      <!-- Fast Time Presets -->
      <div class="flex items-center gap-1.5 flex-wrap">
        <button 
          v-for="preset in ['09:00', '12:00', '15:00', '18:30', '21:00']"
          :key="preset"
          @click="setSimulatedTimePreset(preset)"
          :class="[
            'px-2.5 py-1 rounded-lg text-[10px] font-black border transition-all active:scale-95',
            selectedSimulatedTime === preset 
              ? 'bg-[#FF7B89] border-[#FF7B89] text-white' 
              : 'bg-white border-gray-200 text-gray-650 hover:bg-gray-50'
          ]"
        >
          {{ preset }}
        </button>
        <button 
          @click="resetToRealTimeOnly"
          class="px-3 py-1 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-[10px] font-black shadow-sm active:scale-95 transition-all"
        >
          Đặt về Hiện tại
        </button>
      </div>
    </div>

    <!-- 1. TOP ZONE NAVIGATION BAR -->
    <div class="bg-white border border-gray-200 rounded-2xl p-2 shadow-sm shrink-0 flex items-center gap-3">
      <!-- Nút Chọn khu vực Dropdown (được đặt ngoài thẻ div overflow để tránh lỗi bị cắt/che khuất menu) -->
      <div class="relative shrink-0 z-50">
        <button 
          @click="isZoneDropdownOpen = !isZoneDropdownOpen"
          class="px-3.5 py-2 bg-white border border-gray-200 rounded-xl text-xs font-black text-gray-700 hover:bg-gray-50 flex items-center gap-1.5 shadow-sm active:scale-95"
        >
          <span>🗺️ Chọn khu vực</span>
          <span class="text-gray-400 text-[10px]">▼</span>
        </button>
        
        <!-- Dropdown backdrop click catcher -->
        <div v-if="isZoneDropdownOpen" class="fixed inset-0 z-40" @click="isZoneDropdownOpen = false"></div>
        
        <!-- Dropdown menu -->
        <div v-if="isZoneDropdownOpen" class="absolute left-0 mt-1.5 w-56 bg-white border border-gray-200 rounded-xl shadow-xl py-1.5 z-50 animate-fade-in max-h-64 overflow-y-auto">
          <button
            v-for="zone in zoneOptions"
            :key="zone.value"
            @click="selectedZone = zone.value; isZoneDropdownOpen = false"
            :class="[
              'w-full text-left px-4 py-2 text-xs font-bold transition-colors flex items-center justify-between',
              selectedZone === zone.value ? 'bg-pink-50 text-[#FF7B89]' : 'text-gray-600 hover:bg-gray-50'
            ]"
          >
            <span>{{ zone.label }}</span>
            <span class="text-[9px] bg-gray-150 text-gray-500 px-1.5 py-0.5 rounded-full font-bold">
              {{ getZoneTableCount(zone.value) }}
            </span>
          </button>
        </div>
      </div>
      
      <!-- Divider vertical -->
      <div class="h-6 w-px bg-gray-200 shrink-0"></div>

      <!-- Khu vực đang chọn hiện tại -->
      <div class="flex items-center gap-2 select-none">
        <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">Đang xem:</span>
        <div class="bg-pink-50 border border-pink-100 text-[#FF7B89] px-3 py-1.5 rounded-xl text-xs font-black flex items-center gap-2 shadow-sm">
          <span>📍 {{ selectedZoneLabel }}</span>
          <span class="text-[9px] bg-[#FF7B89] text-white px-1.5 py-0.5 rounded-full font-black">
            {{ getZoneTableCount(selectedZone) }} bàn
          </span>
        </div>
      </div>
    </div>

    <!-- 2. REORGANIZED MAIN CONTENT AREA -->
    <div class="grid grid-cols-1 lg:grid-cols-10 gap-4 items-start">
      
      <!-- LEFT PANEL (70% - Table Management Area) -->
      <div class="lg:col-span-7 flex flex-col gap-4">
        <div class="bg-white border border-gray-200 rounded-3xl p-4 shadow-sm min-h-[580px]">
          
          <div class="flex justify-between items-center mb-3.5 border-b border-gray-100 pb-2">
            <h2 class="text-sm font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              🪑 Bản đồ phân khu: 
              <span class="text-[#FF7B89] font-black text-sm">{{ selectedZoneLabel }}</span>
            </h2>
            <span class="text-[10px] text-gray-400 font-bold">Lưới bàn tự động căn chỉnh</span>
          </div>

          <!-- Grid display of tables -->
          <div class="space-y-6 max-h-[500px] overflow-y-auto pr-1">
            <div 
              v-for="area in filteredAreas" 
              :key="area.name"
              class="flex flex-col gap-3"
            >
              <!-- Sub-header if All is active -->
              <div v-if="selectedZone === 'All'" class="flex items-center gap-1.5 mt-2">
                <span class="w-1.5 h-3 bg-[#FF7B89] rounded-full"></span>
                <h3 class="text-[11px] font-black text-gray-500 uppercase tracking-wider">{{ area.name }} ({{ area.description }})</h3>
              </div>

              <!-- 3. COMPACT OPERATIONAL TABLE CARDS GRID -->
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                <div 
                  v-for="table in area.tables" 
                  :key="table.code"
                  @click="openTableModal(area.name, table)"
                  :class="[
                    'p-3 rounded-xl border transition-all duration-150 cursor-pointer shadow-sm relative flex flex-col justify-between h-24 hover:-translate-y-0.5 hover:shadow-md select-none',
                    getTableColorClass(table.status)
                  ]"
                >
                  <!-- Card Header: Code & Badge -->
                  <div class="flex justify-between items-start gap-1">
                    <span class="font-black text-base text-gray-900 leading-none">{{ table.code }}</span>
                    <span :class="['text-[8px] font-black uppercase px-1.5 py-0.5 rounded leading-none border', getBadgeColorClass(table.status)]">
                      {{ translateTableStatus(table.status) }}
                    </span>
                  </div>

                  <!-- Card Body: Custom contents based on status -->
                  <div class="flex-1 flex flex-col justify-center mt-1 leading-tight">
                    
                    <!-- CASE: Available (TRỐNG) -->
                    <template v-if="table.status === 'Available'">
                      <span class="text-[9px] text-emerald-600 font-extrabold flex items-center gap-0.5">🟢 Sẵn sàng phục vụ</span>
                      <span class="text-[9px] text-gray-400 font-medium mt-0.5">Sức chứa: {{ table.capacity }} ghế</span>
                    </template>

                    <!-- CASE: Reserved (ĐẶT TRƯỚC) -->
                    <template v-else-if="table.status === 'Reserved'">
                      <div class="text-[10px] font-black text-gray-800 truncate">👤 {{ table.customerName || 'Khách đặt trước' }}</div>
                      <div class="flex items-center justify-between text-[9px] text-gray-400 font-bold mt-1">
                        <span>👥 {{ table.capacity }} khách</span>
                        <span class="text-amber-600 font-extrabold">🕒 {{ getTableReservationTime(table.code) || '18:30' }}</span>
                      </div>
                    </template>

                    <!-- CASE: Arrived (ĐÃ ĐẾN) -->
                    <template v-else-if="table.status === 'Arrived'">
                      <div class="text-[10px] font-black text-blue-800 truncate">👤 {{ table.customerName || 'Khách check-in' }}</div>
                      <div class="text-[9px] text-blue-500 font-bold mt-1 flex items-center gap-0.5">
                        <span>🚶 Giờ đến: {{ getTableArrivalTime(table.code) || '18:05' }}</span>
                      </div>
                    </template>

                    <!-- CASE: Serving (PHỤC VỤ) -->
                    <template v-else-if="table.status === 'Serving'">
                      <div class="text-[10px] font-black text-gray-800 truncate">👤 {{ table.customerName || 'Khách vãng lai' }}</div>
                      <div class="flex items-center justify-between text-[9px] mt-1 font-extrabold">
                        <span class="text-rose-600 font-black bg-rose-50 px-1 rounded border border-rose-100/50">💰 {{ table.billAmount || '0đ' }}</span>
                        <span class="text-gray-400 font-bold text-[8px] flex items-center gap-0.5">🕒 {{ table.checkInTime || '17:15' }}</span>
                      </div>
                    </template>

                  </div>

                </div>
              </div>
            </div>
            
            <div v-if="filteredAreas.length === 0" class="py-12 text-center text-gray-400 font-medium text-xs">
              Không tìm thấy bàn nào thuộc phân khu này.
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT PANEL (30% - Reservation Management Area) -->
      <div class="lg:col-span-3 flex flex-col gap-4">
        <div class="bg-white border border-gray-200 rounded-3xl p-4 shadow-sm flex flex-col min-h-[580px]">
          
          <!-- Calendar Title -->
          <div class="flex justify-between items-center mb-2 pb-1 border-b border-gray-100">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1">
              📅 Lịch Trình Đặt Bàn
            </h3>
            <span class="text-[9px] text-gray-400 font-bold">Tháng trực quan</span>
          </div>

          <!-- Calendar Widget -->
          <div class="bg-gray-50 border border-gray-150 rounded-xl p-2.5 shadow-inner">
            <div class="flex justify-between items-center mb-2">
              <button @click="prevMonth" class="p-0.5 rounded hover:bg-gray-200 text-gray-600 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/></svg>
              </button>
              <span class="text-[10px] font-black text-gray-800 tracking-tight">{{ monthNames[currentMonth] }} {{ currentYear }}</span>
              <button @click="nextMonth" class="p-0.5 rounded hover:bg-gray-200 text-gray-600 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/></svg>
              </button>
            </div>
            
            <div class="grid grid-cols-7 gap-0.5 text-[8px] font-extrabold text-gray-400 text-center uppercase tracking-wider mb-1">
              <span>T2</span><span>T3</span><span>T4</span><span>T5</span><span>T6</span><span>T7</span><span class="text-red-500">CN</span>
            </div>
            
            <div class="grid grid-cols-7 gap-0.5 text-[9px] text-center font-bold">
              <button
                v-for="d in calendarDays"
                :key="`${d.year}-${d.month}-${d.day}`"
                @click="selectCalendarDay(d)"
                :class="[
                  'py-0.5 rounded transition-all focus:outline-none flex items-center justify-center h-6 w-full',
                  d.isCurrentMonth ? 'text-gray-700' : 'text-gray-300 font-normal',
                  isSameDate(selectedDate, d.year, d.month, d.day) 
                    ? 'bg-[#FF7B89] text-white shadow-sm font-black scale-105' 
                    : 'hover:bg-white hover:text-[#FF7B89]'
                ]"
              >
                {{ d.day }}
              </button>
            </div>
            
            <div class="text-center text-[9px] font-extrabold text-[#FF7B89] mt-2 border-t border-gray-200/50 pt-1.5 select-none uppercase tracking-wide">
              {{ selectedDateLabelFormatted }}
            </div>
          </div>

          <!-- Shift Tabs -->
          <div class="flex gap-1 overflow-x-auto p-0.5 bg-gray-50 border border-gray-150 rounded-lg text-[9px] font-black tracking-wide mb-3 shrink-0 scrollbar-none">
            <button 
              @click="activeShift = 'all'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'all' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Tất cả ({{ getShiftCount('all') }})
            </button>
            <button 
              @click="activeShift = 'morning'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'morning' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Sáng ({{ getShiftCount('morning') }})
            </button>
            <button 
              @click="activeShift = 'lunch'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'lunch' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Trưa ({{ getShiftCount('lunch') }})
            </button>
            <button 
              @click="activeShift = 'afternoon'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'afternoon' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Chiều ({{ getShiftCount('afternoon') }})
            </button>
            <button 
              @click="activeShift = 'evening'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'evening' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Tối ({{ getShiftCount('evening') }})
            </button>
          </div>

          <!-- Reservation List -->
          <div class="flex-1 overflow-y-auto space-y-2 pr-1 max-h-[300px]">
            <div 
              v-for="booking in filteredBookings" 
              :key="booking.id"
              :class="[
                'border rounded-xl p-3 transition-all hover:shadow relative bg-white flex flex-col gap-1.5 text-xs',
                booking.status === 'Waiting' ? 'border-l-4 border-l-amber-400 border-gray-250' : '',
                booking.status === 'Arrived' ? 'border-l-4 border-l-blue-400 border-gray-250' : '',
                booking.status === 'Seated' ? 'border-l-4 border-l-rose-400 border-gray-250 opacity-80' : '',
                booking.status === 'Completed' ? 'border-l-4 border-l-emerald-400 border-gray-250 opacity-60' : '',
                booking.status === 'Cancelled' ? 'border-l-4 border-l-gray-300 border-gray-250 opacity-50 bg-gray-50/50' : '',
                isBookingInActiveZone(booking) ? 'ring-2 ring-[#FF7B89]/40 border-[#FF7B89] bg-[#FFF5F7]' : ''
              ]"
            >
              <div class="flex justify-between items-center text-[9px] font-black uppercase">
                <span class="text-gray-400 font-mono tracking-tight">{{ booking.bookingNumber }}</span>
                <span :class="['px-1.5 py-0.5 rounded border text-[8px]', getReservationBadgeClass(booking.status)]">
                  {{ translateReservationStatus(booking.status) }}
                </span>
              </div>

              <div class="flex justify-between items-start gap-2">
                <div>
                  <h4 class="font-extrabold text-gray-800 text-xs">👤 {{ booking.customerName }}</h4>
                  <p class="text-[10px] text-gray-400 font-semibold mt-0.5">📞 {{ booking.phone }}</p>
                </div>
                <div class="text-right select-none leading-none">
                  <span class="text-sm font-black text-gray-850">{{ booking.reservationTime }}</span>
                  <span class="block text-[7.5px] text-gray-400 font-bold uppercase mt-0.5">HẸN GIỜ</span>
                </div>
              </div>

              <div class="flex flex-wrap gap-1.5 text-[9px] font-extrabold select-none">
                <span class="bg-gray-100 border border-gray-200 text-gray-500 px-1.5 py-0.5 rounded">👥 {{ booking.adults }} Lớn | {{ booking.children }} Trẻ</span>
                <span :class="['px-1.5 py-0.5 rounded border', booking.assignedTable ? 'bg-pink-50 border-pink-100 text-[#FF7B89]' : 'bg-red-50 border-red-100 text-red-600']">
                  🪑 Bàn: {{ booking.assignedTable || 'Chưa gán' }}
                </span>
              </div>

              <div v-if="booking.notes" class="bg-gray-50 border border-gray-100 text-[9px] text-gray-500 italic p-1.5 rounded-lg leading-tight">
                <strong>Ghi chú:</strong> {{ booking.notes }}
              </div>

              <!-- Icon buttons for card actions -->
              <div class="flex justify-between items-center border-t border-gray-100 pt-2 mt-1 shrink-0">
                <span class="text-[8px] text-gray-400 font-extrabold uppercase">Thao tác:</span>
                <div class="flex items-center gap-1">
                  <button @click="showBookingDetails(booking)" class="p-1 bg-gray-50 hover:bg-gray-150 text-gray-600 rounded border border-gray-200 text-[10px]" title="Chi tiết">👁️</button>
                  <button @click="openEditBookingModal(booking)" v-if="booking.status !== 'Cancelled' && booking.status !== 'Completed'" class="p-1 bg-gray-50 hover:bg-gray-150 text-gray-600 rounded border border-gray-200 text-[10px]" title="Chỉnh sửa">✏️</button>
                  <button @click="openAssignTableModal(booking)" v-if="booking.status !== 'Cancelled' && booking.status !== 'Completed' && booking.status !== 'Seated'" class="p-1 bg-pink-50 hover:bg-pink-100 text-[#FF7B89] rounded border border-pink-100 text-[10px]" title="Xếp bàn">🪑</button>
                  <button @click="markBookingArrived(booking)" v-if="booking.status === 'Waiting'" class="p-1 bg-blue-50 hover:bg-blue-100 text-blue-700 rounded border border-blue-200 text-[10px]" title="Đón khách">🚶</button>
                  <button @click="openTableFromBooking(booking)" v-if="booking.status === 'Arrived'" class="p-1 bg-rose-50 hover:bg-rose-100 text-rose-700 rounded border border-rose-250 text-[10px] animate-pulse" title="Mở bàn">🍽️</button>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- 4. BOTTOM ZONE SUMMARY DASHBOARD -->
    <div class="bg-white border border-gray-200 rounded-3xl p-4 shadow-sm shrink-0">
      <h3 class="text-xs font-black text-gray-400 uppercase tracking-wider mb-3">📊 Bảng Tổng Quan Ca Theo Khu Vực:</h3>
      <div class="grid grid-cols-3 sm:grid-cols-6 lg:grid-cols-11 gap-2.5 select-none">
        <div 
          v-for="zone in dashboardZoneList"
          :key="zone.value"
          @click="selectedZone = zone.value"
          :class="[
            'p-2.5 rounded-2xl border transition-all duration-150 text-center cursor-pointer flex flex-col justify-between gap-1 shadow-sm',
            selectedZone === zone.value ? 'bg-[#FF7B89]/5 border-[#FF7B89] ring-1 ring-[#FF7B89]' : 'bg-gray-50 border-gray-150 hover:bg-white'
          ]"
        >
          <span class="block text-[10px] font-black text-gray-700 truncate" :title="zone.label">{{ zone.label }}</span>
          
          <div class="flex flex-col gap-0.5 text-[9px] font-extrabold text-left border-t border-gray-100 pt-1.5 mt-0.5">
            <span class="text-rose-600">⚡ {{ getZoneActiveTablesCount(zone.value) }} ăn</span>
            <span class="text-amber-600">📅 {{ getZoneBookingsCount(zone.value) }} đặt</span>
            <span class="text-gray-500 truncate">💰 {{ getZoneRevenue(zone.value) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 5. REDESIGNED FIXED ACTION BAR (BOTTOM) -->
    <div class="fixed bottom-0 left-0 right-0 xl:left-64 bg-white/95 backdrop-blur-md border-t border-gray-200 py-3.5 px-6 grid grid-cols-1 md:grid-cols-3 items-center gap-4 z-40 shadow-2xl">
      
      <!-- Left Section (Operational stats) -->
      <div class="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[10px] font-black border-r border-gray-150 pr-4 select-none">
        <div class="flex items-center gap-1 text-gray-500">
          🕒 HỆ THỐNG: <span class="bg-gray-100 border border-gray-150 px-2 py-0.5 rounded text-gray-700 font-mono tracking-wider">{{ currentTime }}</span>
        </div>
        <div class="flex items-center gap-2">
          <span>BÀN:</span>
          <span class="text-emerald-600 bg-emerald-50 border border-emerald-100 px-1.5 py-0.5 rounded">{{ stats.availableTables }}/{{ stats.totalTables }} trống</span>
        </div>
        <div class="flex items-center gap-2">
          <span>GHẾ:</span>
          <span class="text-blue-600 bg-blue-50 border border-blue-100 px-1.5 py-0.5 rounded">{{ stats.availableSeats }}/{{ stats.totalSeats }} trống</span>
        </div>
      </div>

      <!-- Center Section (Booking statistics) -->
      <div class="flex flex-wrap items-center justify-center gap-x-4 gap-y-1.5 text-[10px] font-black border-r border-gray-150 px-4 select-none">
        <div class="flex items-center gap-1.5">
          <span>📅 TỔNG HẸN HÔM NAY:</span>
          <span class="bg-gray-100 px-2 py-0.5 rounded border border-gray-200 text-gray-700 text-xs">{{ sidebarStats.total }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="text-blue-600">ĐÃ CHECK-IN:</span>
          <span class="bg-blue-50 text-blue-700 px-2 py-0.5 rounded border border-blue-200 text-xs">{{ sidebarStats.arrived }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="text-amber-600">ĐANG CHỜ BÀN:</span>
          <span class="bg-amber-50 text-amber-700 px-2 py-0.5 rounded border border-amber-200 text-xs">{{ sidebarStats.waiting }}</span>
        </div>
      </div>

      <!-- Right Section (Primary Actions) -->
      <div class="flex gap-2.5 justify-end w-full">
        <button @click="resetToCurrentState" class="flex-1 text-center py-2.5 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 font-extrabold text-xs transition-colors shadow-sm select-none flex items-center justify-center gap-1 active:scale-95">
          🕒 Hiện tại
        </button>
        <button @click="openQuickArrivedModal" class="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-black text-xs py-2.5 rounded-xl transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95">
          🚶 Đón Khách Đến
        </button>
        <button @click="openQuickOpenModal" class="flex-1 bg-rose-600 hover:bg-rose-700 text-white font-black text-xs py-2.5 rounded-xl transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95 animate-pulse">
          🍽️ Khai Bàn Nhanh
        </button>
        <button @click="openCreateBookingModal" class="flex-1 bg-[#FF7B89] hover:bg-[#FF5A6E] text-white font-black text-xs py-2.5 rounded-xl transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95">
          + Đặt Bàn
        </button>
      </div>

    </div>

    <!-- MODAL 1: TABLE DETAILS & MANUAL STATE CHANGE -->
    <div v-if="isTableModalOpen && selectedTableForModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="closeTableModal"></div>
      
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="closeTableModal" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <div class="flex items-center gap-3 mb-5 border-b border-gray-100 pb-3 select-none">
          <div class="w-12 h-12 rounded-2xl bg-pink-50 flex items-center justify-center text-2xl">🪑</div>
          <div>
            <h3 class="text-lg font-black text-gray-900 tracking-tight">Chi Tiết Bàn {{ selectedTableForModal.code }}</h3>
            <p class="text-[10px] text-gray-400 font-bold uppercase">Phân khu: {{ selectedTableForModal.areaName }}</p>
          </div>
        </div>

        <div class="space-y-4 mb-5">
          <div class="grid grid-cols-2 gap-4 select-none">
            <div class="bg-gray-50 p-3 rounded-xl border border-gray-100">
              <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-0.5">Sức chứa</span>
              <span class="font-extrabold text-xs text-gray-800">{{ selectedTableForModal.capacity }} ghế ngồi</span>
            </div>
            <div class="bg-gray-50 p-3 rounded-xl border border-gray-100">
              <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-0.5">Trạng thái hiện thời</span>
              <span :class="['inline-block text-[8px] font-black uppercase px-2 py-0.5 rounded border mt-0.5 tracking-wide', getBadgeColorClass(selectedTableForModal.status)]">
                {{ translateTableStatus(selectedTableForModal.status) }}
              </span>
            </div>
          </div>

          <div class="bg-gray-50 p-3.5 rounded-xl border border-gray-100 space-y-2.5">
            <h4 class="text-[10px] font-black text-gray-400 uppercase">Thông Tin Chi Tiết Ca Phục Vụ:</h4>
            
            <div class="space-y-1">
              <label class="text-[8px] font-black text-gray-400 uppercase">Tên Khách Hàng</label>
              <input 
                type="text" 
                v-model="tableModalForm.customerName" 
                placeholder="Nhập tên khách dùng bàn"
                class="w-full bg-white border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>

            <div class="grid grid-cols-2 gap-3.5">
              <div class="space-y-1">
                <label class="text-[8px] font-black text-gray-400 uppercase">Hóa Đơn Tạm Tính</label>
                <input 
                  type="text" 
                  v-model="tableModalForm.billAmount" 
                  placeholder="0đ"
                  class="w-full bg-white border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
                />
              </div>
              <div class="space-y-1">
                <label class="text-[8px] font-black text-gray-400 uppercase">Giờ Khai Bàn / Vào</label>
                <input 
                  type="text" 
                  v-model="tableModalForm.occupiedDuration" 
                  placeholder="Ví dụ: 17:15"
                  class="w-full bg-white border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-3">
          <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-2 select-none">Đổi Trạng Thái Bàn Nhanh:</span>
          
          <div class="grid grid-cols-2 gap-2 select-none">
            <button 
              @click="setTableModalStatus('Available')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Available' ? 'bg-emerald-500 border-emerald-600 text-white shadow-sm' : 'bg-emerald-50 text-emerald-800 border-emerald-100 hover:bg-emerald-100']"
            >
              🟢 Thiết lập Trống
            </button>
            
            <button 
              @click="setTableModalStatus('Reserved')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Reserved' ? 'bg-amber-500 border-amber-600 text-white shadow-sm' : 'bg-amber-50 text-amber-800 border-amber-100 hover:bg-amber-100']"
            >
              📅 Thiết lập Đặt Trước
            </button>
            
            <button 
              @click="setTableModalStatus('Arrived')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Arrived' ? 'bg-blue-600 border-blue-700 text-white shadow-sm' : 'bg-blue-50 text-blue-800 border-blue-100 hover:bg-blue-100']"
            >
              🚶 Đón Check-in
            </button>
            
            <button 
              @click="setTableModalStatus('Serving')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Serving' ? 'bg-rose-600 border-rose-700 text-white shadow-sm' : 'bg-rose-50 text-rose-800 border-rose-100 hover:bg-rose-100']"
            >
              🔥 Mở Phục Vụ
            </button>
          </div>

          <div class="flex gap-2 pt-3.5 border-t border-gray-100 mt-4">
            <button 
              @click="closeTableModal"
              class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors select-none"
            >
              Đóng
            </button>
            <button 
              @click="goToOrderScreen(selectedTableForModal.code)"
              class="flex-1 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-[11px] font-black transition-colors shadow-sm select-none"
            >
              🍽️ Chọn Món
            </button>
            <button 
              @click="saveTableModal"
              class="flex-1 py-2 rounded-xl bg-[#FF7B89] hover:bg-[#FF5A6E] text-white text-[11px] font-black transition-colors shadow-sm select-none"
            >
              Lưu Lại
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL 2: CREATE / EDIT BOOKING -->
    <div v-if="isCreateBookingModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isCreateBookingModalOpen = false"></div>
      
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isCreateBookingModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">
          <span>📅</span> {{ isEditMode ? 'Cập Nhật Đơn Đặt Bàn' : 'Tạo Đơn Đặt Bàn Mới' }}
        </h3>

        <div class="space-y-3.5 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Tên Khách Hàng *</label>
            <input 
              type="text" 
              v-model="newBookingForm.customerName"
              placeholder="Nhập tên khách hàng"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            />
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Số Điện Thoại *</label>
              <input 
                type="text" 
                v-model="newBookingForm.phone"
                placeholder="Nhập số điện thoại"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Giờ Khách Đến *</label>
              <input 
                type="text" 
                v-model="newBookingForm.reservationTime"
                placeholder="Ví dụ: 19:30"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Tổng Số Khách</label>
              <input 
                type="number" 
                v-model="newBookingForm.guestCount"
                placeholder="Ví dụ: 4"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Chỉ Định Bàn Ăn</label>
              <select 
                v-model="newBookingForm.assignedTable"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              >
                <option value="">-- Chưa chỉ định --</option>
                <optgroup v-for="area in areas" :key="area.name" :label="area.name">
                  <option 
                    v-for="tbl in area.tables" 
                    :key="tbl.code" 
                    :value="tbl.code"
                    :disabled="tbl.status !== 'Available' && tbl.code !== newBookingForm.assignedTable"
                  >
                    {{ tbl.code }} (Sức chứa: {{ tbl.capacity }} chỗ)
                  </option>
                </optgroup>
              </select>
            </div>
          </div>

          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Ghi Chú Đặc Biệt</label>
            <textarea 
              v-model="newBookingForm.notes"
              placeholder="Ghi chú thêm: bàn gần cửa sổ, ăn buffet chay, cốc nến trang trí..."
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] h-16 resize-none"
            ></textarea>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button 
            @click="isCreateBookingModalOpen = false"
            class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors"
          >
            Hủy Bỏ
          </button>
          <button 
            @click="saveNewBooking"
            class="flex-1 py-2 rounded-xl bg-[#FF7B89] hover:bg-[#FF5A6E] text-white text-[11px] font-black transition-colors shadow-sm"
          >
            {{ isEditMode ? 'Cập Nhật' : 'Tạo Đơn Đặt' }}
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL 3: QUICK OPEN TABLE (WALK-IN) -->
    <div v-if="isQuickOpenModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isQuickOpenModalOpen = false"></div>
      
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isQuickOpenModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">
          <span>🍽️</span> Khai Bàn Khách Vãng Lai (Walk-in)
        </h3>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Lựa Chọn Bàn Ăn Còn Trống *</label>
            <select 
              v-model="quickOpenForm.tableCode"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            >
              <option value="">-- Click chọn bàn trống --</option>
              <optgroup v-for="area in areas" :key="area.name" :label="area.name">
                <option 
                  v-for="tbl in area.tables" 
                  :key="tbl.code" 
                  :value="tbl.code"
                  v-show="tbl.status === 'Available'"
                >
                  Bàn {{ tbl.code }} ({{ tbl.capacity }} ghế)
                </option>
              </optgroup>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Tên Khách Hàng (Tùy Chọn)</label>
            <input 
              type="text" 
              v-model="quickOpenForm.customerName"
              placeholder="Ví dụ: Khách vãng lai / Anh Nam"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            />
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Số Khách Thực Tế</label>
              <input 
                type="number" 
                v-model="quickOpenForm.guestCount"
                placeholder="Ví dụ: 4"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Hóa Đơn Tạm Tính Khởi Điểm</label>
              <input 
                type="text" 
                v-model="quickOpenForm.billAmount"
                placeholder="0đ"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button 
            @click="isQuickOpenModalOpen = false"
            class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors"
          >
            Đóng Lại
          </button>
          <button 
            @click="saveQuickOpen"
            class="flex-1 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-[11px] font-black transition-colors shadow-sm"
          >
            Khai Bàn Phục Vụ
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL 4: QUICK CHECK-IN (ARRIVED) -->
    <div v-if="isQuickArrivedModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isQuickArrivedModalOpen = false"></div>
      
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isQuickArrivedModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">
          <span>🚶</span> Nhận Khách Đã Đến (Check-in)
        </h3>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Lựa Chọn Lượt Hẹn Khách Vừa Đến *</label>
            <select 
              v-model="quickArrivedForm.bookingId"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            >
              <option value="">-- Click chọn lượt đặt hôm nay --</option>
              <option 
                v-for="b in bookings.filter(b => b.date === getFormattedSelectedDate && b.status === 'Waiting')" 
                :key="b.id" 
                :value="b.id"
              >
                {{ b.reservationTime }} - {{ b.customerName }} (Bàn: {{ b.assignedTable || 'Chưa xếp' }})
              </option>
            </select>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button 
            @click="isQuickArrivedModalOpen = false"
            class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors"
          >
            Hủy Bỏ
          </button>
          <button 
            @click="saveQuickArrived"
            class="flex-1 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[11px] font-black transition-colors shadow-sm"
          >
            Đón Khách Đến
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL 5: BOOKING DETAILS DRAWER -->
    <div v-if="isBookingDetailsOpen && selectedBookingForDetails" class="fixed inset-0 z-50 flex items-center justify-end">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isBookingDetailsOpen = false"></div>
      
      <div class="bg-white border-l border-pink-100 h-full w-full max-w-md shadow-2xl p-6 z-10 relative flex flex-col justify-between animate-slide-in text-xs font-bold text-gray-700">
        <div>
          <!-- Header -->
          <div class="flex items-center justify-between border-b border-gray-100 pb-3 mb-5 select-none">
            <h3 class="text-lg font-black text-gray-900 flex items-center gap-1.5">
              <span>📋</span> Nhật Ký Đặt Bàn Chi Tiết
            </h3>
            <button @click="isBookingDetailsOpen = false" class="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 flex items-center justify-center font-bold text-sm">
              ✕
            </button>
          </div>

          <!-- Profile Info Card -->
          <div class="space-y-5">
            <div class="flex items-center gap-3 bg-gray-50 p-3 rounded-xl border border-gray-150 select-none">
              <div class="w-10 h-10 bg-pink-100 rounded-full flex items-center justify-center text-lg text-[#FF7B89] font-black">
                {{ selectedBookingForDetails.customerName.charAt(0) }}
              </div>
              <div>
                <h4 class="font-extrabold text-gray-800 text-sm leading-none">{{ selectedBookingForDetails.customerName }}</h4>
                <span class="text-[9px] text-gray-400 font-bold font-mono">Mã đặt: {{ selectedBookingForDetails.bookingNumber }}</span>
              </div>
            </div>

            <!-- Grid Details -->
            <div class="grid grid-cols-2 gap-3.5">
              <div class="bg-gray-50 p-2.5 rounded-lg border border-gray-100">
                <span class="block text-[9px] text-gray-400 uppercase tracking-wider mb-0.5 select-none">Số điện thoại liên lạc</span>
                <span class="text-gray-800 text-xs font-black">{{ selectedBookingForDetails.phone }}</span>
              </div>
              <div class="bg-gray-50 p-2.5 rounded-lg border border-gray-100">
                <span class="block text-[9px] text-gray-400 uppercase tracking-wider mb-0.5 select-none">Lịch hẹn khách đến</span>
                <span class="text-gray-800 text-xs font-black">📅 {{ selectedBookingForDetails.date }} lúc {{ selectedBookingForDetails.reservationTime }}</span>
              </div>
              <div class="bg-gray-50 p-2.5 rounded-lg border border-gray-100">
                <span class="block text-[9px] text-gray-400 uppercase tracking-wider mb-0.5 select-none">Khách dùng tiệc</span>
                <span class="text-gray-800 text-xs font-black">👥 {{ selectedBookingForDetails.adults }} Lớn | {{ selectedBookingForDetails.children }} Trẻ</span>
              </div>
              <div class="bg-gray-50 p-2.5 rounded-lg border border-gray-100">
                <span class="block text-[9px] text-gray-400 uppercase tracking-wider mb-0.5 select-none">Bàn đã chỉ định</span>
                <span class="text-gray-800 text-xs font-black">🪑 Bàn: {{ selectedBookingForDetails.assignedTable || 'Chưa gán' }}</span>
              </div>
            </div>

            <!-- Status selector -->
            <div class="bg-gray-50 p-3.5 rounded-xl border border-gray-100 space-y-2">
              <span class="block text-[9px] text-gray-400 uppercase tracking-wider font-extrabold select-none">Trạng thái hiện tại:</span>
              <div class="flex flex-wrap gap-1 select-none">
                <button 
                  v-for="st in ['Waiting', 'Arrived', 'Seated', 'Completed', 'Cancelled'] as const"
                  :key="st"
                  @click="updateBookingStatus(selectedBookingForDetails.id, st)"
                  :class="[
                    'flex-1 min-w-[60px] py-1.5 rounded-lg border text-[9px] font-black transition-all text-center',
                    selectedBookingForDetails.status === st 
                      ? 'bg-rose-500 border-rose-600 text-white shadow-sm' 
                      : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                  ]"
                >
                  {{ translateReservationStatus(st) }}
                </button>
              </div>
            </div>

            <!-- Note section -->
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase select-none">Yêu cầu đặc biệt</label>
              <p class="text-xs text-gray-600 bg-gray-50 p-3 rounded-lg border border-gray-100 min-h-[50px] italic">
                {{ selectedBookingForDetails.notes || 'Không có ghi chú nào khác.' }}
              </p>
            </div>
          </div>
        </div>

        <!-- Buttons Drawer footer -->
        <div class="space-y-2 pt-4 border-t border-gray-100 select-none">
          <button 
            v-if="selectedBookingForDetails.status === 'Waiting'"
            @click="markBookingArrived(selectedBookingForDetails); isBookingDetailsOpen = false;"
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-black text-sm py-2.5 rounded-xl transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95"
          >
            Đón Khách Đến (Check-in)
          </button>
          
          <button 
            v-if="selectedBookingForDetails.status === 'Arrived'"
            @click="openTableFromBooking(selectedBookingForDetails); isBookingDetailsOpen = false;"
            class="w-full bg-rose-600 hover:bg-rose-700 text-white font-black text-sm py-2.5 rounded-xl transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95 animate-pulse"
          >
            Khai Bàn Mở Phục Vụ (Serving)
          </button>

          <div class="flex gap-2">
            <button 
              @click="cancelBooking(selectedBookingForDetails.id)"
              class="flex-1 py-2 rounded-xl border border-red-200 bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold transition-all flex items-center justify-center gap-1 active:scale-95"
            >
              🗑️ Hủy Đặt
            </button>
            <button 
              @click="isBookingDetailsOpen = false"
              class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-xs font-bold transition-colors"
            >
              Đóng Lại
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL 6: ASSIGN TABLE DIRECTLY -->
    <div v-if="isAssignTableModalOpen && selectedBookingForAssign" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isAssignTableModalOpen = false"></div>
      
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-sm shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isAssignTableModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <h3 class="text-base font-black text-gray-900 tracking-tight mb-3 flex items-center gap-1 border-b border-gray-100 pb-2 select-none">
          <span>🪑</span> Gán Chỉ Định Bàn Cho Lượt Đặt
        </h3>
        
        <p class="text-xs text-gray-500 font-semibold mb-4 select-none">
          Khách hàng: <strong>{{ selectedBookingForAssign.customerName }}</strong> (Khung giờ hẹn: {{ selectedBookingForAssign.reservationTime }})
        </p>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase select-none">Chọn Bàn Đang Trống</label>
            <select 
              v-model="assignTableForm.tableCode"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            >
              <option value="">-- Chưa chỉ định bàn ăn --</option>
              <optgroup v-for="area in areas" :key="area.name" :label="area.name">
                <option 
                  v-for="tbl in area.tables" 
                  :key="tbl.code" 
                  :value="tbl.code"
                  :disabled="tbl.status !== 'Available' && tbl.code !== selectedBookingForAssign.assignedTable"
                >
                  Bàn {{ tbl.code }} (Chỗ ngồi: {{ tbl.capacity }} ghế) - {{ translateTableStatus(tbl.status) }}
                </option>
              </optgroup>
            </select>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button 
            @click="isAssignTableModalOpen = false"
            class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-xs font-bold transition-colors"
          >
            Đóng Lại
          </button>
          <button 
            @click="saveAssignTable"
            class="flex-1 py-2 rounded-xl bg-[#FF7B89] hover:bg-[#FF5A6E] text-white text-xs font-black transition-colors shadow-sm active:scale-95"
          >
            Xác Nhận Xếp
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useRestaurantStore } from '@/stores/restaurantStore';
import { storeToRefs } from 'pinia';

interface TableInfo {
  code: string;
  status: 'Available' | 'Reserved' | 'Arrived' | 'Serving';
  capacity: number;
  customerName?: string;
  billAmount?: string;
  occupiedDuration?: string;
  checkInTime?: string;
}

interface AreaInfo {
  name: string;
  description: string;
  tables: TableInfo[];
}

interface Booking {
  id: string;
  bookingNumber: string;
  customerName: string;
  phone: string;
  adults: number;
  children: number;
  reservationTime: string;
  assignedTable: string;
  notes: string;
  status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled';
  date: string; // YYYY-MM-DD
  guestCount?: number;
}

// System Zone options
const zoneOptions = [
  { label: 'Tất cả', value: 'All' },
  { label: 'Khu A', value: 'Khu A' },
  { label: 'Khu B', value: 'Khu B' },
  { label: 'Khu C', value: 'Khu C' },
  { label: 'Khu VIP R', value: 'Khu R' },
  { label: 'Sân thượng T', value: 'Khu T' },
  { label: 'Capichi', value: 'Khu Capichi' },
  { label: 'Shopee', value: 'Khu Shopee' },
  { label: 'beFood', value: 'Khu BE' },
  { label: 'GrabFood', value: 'Khu Grab' },
  { label: 'Mang đi', value: 'Khu Catalog' },
];

// Bottom Dashboard Zone list order
const dashboardZoneList = [
  { label: 'Tất cả', value: 'All' },
  { label: 'Mang đi', value: 'Khu Catalog' },
  { label: 'Khu A', value: 'Khu A' },
  { label: 'Khu B', value: 'Khu B' },
  { label: 'Khu C', value: 'Khu C' },
  { label: 'Khu R', value: 'Khu R' },
  { label: 'Khu T', value: 'Khu T' },
  { label: 'Capichi', value: 'Khu Capichi' },
  { label: 'Shopee', value: 'Khu Shopee' },
  { label: 'beFood', value: 'Khu BE' },
  { label: 'GrabFood', value: 'Khu Grab' }
];

// Active layout state refs
const selectedZone = ref('All');
const isZoneDropdownOpen = ref(false);
const activeShift = ref<'all' | 'morning' | 'lunch' | 'afternoon' | 'evening'>('all');
const searchBookingQuery = ref('');

// Simulated time state refs & presets
const simulatedMinutes = ref(1080); // Default to 18:00 (6:00 PM)
const selectedSimulatedTime = computed(() => {
  const h = Math.floor(simulatedMinutes.value / 60);
  const m = simulatedMinutes.value % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
});

const inputSimulatedTime = computed({
  get() {
    const h = Math.floor(simulatedMinutes.value / 60);
    const m = simulatedMinutes.value % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  },
  set(val: string) {
    if (!val) return;
    const [h, m] = val.split(':').map(Number);
    simulatedMinutes.value = h * 60 + m;
  }
});

const resetToRealTimeOnly = () => {
  const now = new Date();
  const currentHour = now.getHours();
  const currentMin = now.getMinutes();
  simulatedMinutes.value = currentHour * 60 + currentMin;
};

const setSimulatedTimePreset = (presetStr: string) => {
  const [h, m] = presetStr.split(':').map(Number);
  simulatedMinutes.value = h * 60 + m;
};

// Date Navigation Setup
const selectedDate = ref(new Date(2026, 5, 24)); // June 24, 2026
const currentYear = ref(2026);
const currentMonth = ref(5); // 0-indexed, 5 = June
const monthNames = [
  'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
  'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
];

const router = useRouter();
const restaurantStore = useRestaurantStore();
const { areas, bookings } = storeToRefs(restaurantStore);

// ----------------------------------------------------
// CALENDAR COMPUTED & NAVIGATION
// ----------------------------------------------------

const getFormattedSelectedDate = computed(() => {
  const y = selectedDate.value.getFullYear();
  const m = String(selectedDate.value.getMonth() + 1).padStart(2, '0');
  const d = String(selectedDate.value.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
});

const selectedDateLabelFormatted = computed(() => {
  return selectedDate.value.toLocaleDateString('vi-VN', {
    weekday: 'long',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric'
  });
});

const prevMonth = () => {
  if (currentMonth.value === 0) {
    currentMonth.value = 11;
    currentYear.value--;
  } else {
    currentMonth.value--;
  }
};

const nextMonth = () => {
  if (currentMonth.value === 11) {
    currentMonth.value = 0;
    currentYear.value++;
  } else {
    currentMonth.value++;
  }
};

const calendarDays = computed(() => {
  const year = currentYear.value;
  const month = currentMonth.value;
  const firstDayIndex = new Date(year, month, 1).getDay();
  const adjustedFirstDayIndex = (firstDayIndex + 6) % 7;

  const totalDays = new Date(year, month + 1, 0).getDate();
  const prevMonthTotalDays = new Date(year, month, 0).getDate();

  const days = [];

  // Previous month filling
  for (let i = adjustedFirstDayIndex - 1; i >= 0; i--) {
    days.push({
      day: prevMonthTotalDays - i,
      month: month === 0 ? 11 : month - 1,
      year: month === 0 ? year - 1 : year,
      isCurrentMonth: false
    });
  }

  // Current month
  for (let i = 1; i <= totalDays; i++) {
    days.push({
      day: i,
      month: month,
      year: year,
      isCurrentMonth: true
    });
  }

  // Next month filling to 42 cells
  const remaining = 42 - days.length;
  for (let i = 1; i <= remaining; i++) {
    days.push({
      day: i,
      month: month === 11 ? 0 : month + 1,
      year: month === 11 ? year + 1 : year,
      isCurrentMonth: false
    });
  }

  return days;
});

const selectCalendarDay = (dayObj: { day: number, month: number, year: number }) => {
  selectedDate.value = new Date(dayObj.year, dayObj.month, dayObj.day);
};

const isSameDate = (date1: Date, year: number, month: number, day: number) => {
  return date1.getFullYear() === year && date1.getMonth() === month && date1.getDate() === day;
};

// ----------------------------------------------------
// SHIFT & SEARCH LOGIC
// ----------------------------------------------------

const getBookingShift = (timeStr: string): 'morning' | 'lunch' | 'afternoon' | 'evening' => {
  const [hour] = timeStr.split(':').map(Number);
  if (hour >= 6 && hour < 11) return 'morning';
  if (hour >= 11 && hour < 14) return 'lunch';
  if (hour >= 14 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 23) return 'evening';
  return 'evening';
};

const getShiftCount = (shift: string) => {
  const formattedDate = getFormattedSelectedDate.value;
  let list = bookings.value.filter(b => b.date === formattedDate);
  
  if (selectedZone.value !== 'All') {
    list = list.filter(b => {
      if (!b.assignedTable) return false;
      return getTableArea(b.assignedTable) === selectedZone.value;
    });
  }

  if (shift === 'all') return list.length;
  return list.filter(b => getBookingShift(b.reservationTime) === shift).length;
};

// ----------------------------------------------------
// DYNAMIC STATISTICS & SEARCH CO-ORDINATION
// ----------------------------------------------------

const selectedZoneLabel = computed(() => {
  const zone = zoneOptions.find(o => o.value === selectedZone.value);
  return zone ? zone.label : '';
});

// Simulated Areas reflecting live state at simulatedMinutes
const simulatedAreas = computed<AreaInfo[]>(() => {
  const formattedToday = getFormattedSelectedDate.value;
  const todaysBookings = bookings.value.filter(b => b.date === formattedToday);

  return areas.value.map((area): AreaInfo => {
    return {
      ...area,
      tables: area.tables.map((table): TableInfo => {
        const tableBookings = todaysBookings.filter(b => b.assignedTable === table.code && b.status !== 'Cancelled');
        
        if (tableBookings.length === 0) {
          return { ...table };
        }
        
        let computedStatus: 'Available' | 'Reserved' | 'Arrived' | 'Serving' = table.status;
        let computedCustomer = table.customerName;
        let computedBill = table.billAmount;
        let computedCheckIn = table.checkInTime;
        let computedDuration = table.occupiedDuration;
        let foundActive = false;
        
        for (const booking of tableBookings) {
          const [h, m] = booking.reservationTime.split(':').map(Number);
          const bookingMin = h * 60 + m;
          const currentMin = simulatedMinutes.value;
          
          if (currentMin >= bookingMin - 60 && currentMin < bookingMin) {
            computedStatus = 'Reserved';
            computedCustomer = booking.customerName;
            computedBill = '';
            computedCheckIn = '';
            computedDuration = '';
            foundActive = true;
            break;
          } else if (currentMin >= bookingMin && currentMin < bookingMin + 15) {
            computedStatus = 'Arrived';
            computedCustomer = booking.customerName;
            computedBill = '';
            computedCheckIn = '';
            computedDuration = '';
            foundActive = true;
            break;
          } else if (currentMin >= bookingMin + 15 && currentMin < bookingMin + 120) {
            computedStatus = 'Serving';
            computedCustomer = booking.customerName;
            const guests = booking.adults + booking.children;
            const price = guests * 200000 + 150000;
            computedBill = price.toLocaleString('vi-VN') + 'đ';
            computedCheckIn = booking.reservationTime;
            computedDuration = `${currentMin - bookingMin} phút`;
            foundActive = true;
            break;
          }
        }
        
        if (foundActive) {
          return {
            ...table,
            status: computedStatus,
            customerName: computedCustomer,
            billAmount: computedBill,
            checkInTime: computedCheckIn,
            occupiedDuration: computedDuration
          };
        } else {
          return {
            ...table,
            status: 'Available',
            customerName: '',
            billAmount: '',
            checkInTime: '',
            occupiedDuration: ''
          };
        }
      })
    };
  });
});

const filteredAreas = computed(() => {
  if (selectedZone.value === 'All') {
    return simulatedAreas.value;
  }
  return simulatedAreas.value.filter(a => a.name === selectedZone.value);
});

const getTableArea = (tableCode: string) => {
  for (const area of areas.value) {
    if (area.tables.some(t => t.code === tableCode)) {
      return area.name;
    }
  }
  return null;
};

const isBookingInActiveZone = (booking: Booking) => {
  if (selectedZone.value === 'All') return false;
  if (!booking.assignedTable) return false;
  return getTableArea(booking.assignedTable) === selectedZone.value;
};

// Main Timeline Filtered Reservation List
const filteredBookings = computed(() => {
  let list = bookings.value;
  
  // 1. Date filter
  list = list.filter(b => b.date === getFormattedSelectedDate.value);
  
  // 2. Zone View Integration (filter reservation list by assigned table in that zone)
  if (selectedZone.value !== 'All') {
    list = list.filter(b => {
      if (!b.assignedTable) return false;
      return getTableArea(b.assignedTable) === selectedZone.value;
    });
  }
  
  // 3. Shift Filter
  if (activeShift.value !== 'all') {
    list = list.filter(b => getBookingShift(b.reservationTime) === activeShift.value);
  }
  
  // 4. Query text Match
  if (searchBookingQuery.value.trim() !== '') {
    const q = searchBookingQuery.value.toLowerCase().trim();
    list = list.filter(b => 
      b.customerName.toLowerCase().includes(q) ||
      b.phone.includes(q) ||
      b.bookingNumber.toLowerCase().includes(q) ||
      (b.assignedTable && b.assignedTable.toLowerCase().includes(q))
    );
  }
  
  return list.sort((a, b) => a.reservationTime.localeCompare(b.reservationTime));
});

// Dynamic full-store statistics for Bottom Bar
const stats = computed(() => {
  let totalT = 0;
  let availT = 0;
  let servingT = 0;
  let totalS = 0;
  let availS = 0;

  simulatedAreas.value.forEach(area => {
    area.tables.forEach(table => {
      totalT++;
      totalS += table.capacity;
      if (table.status === 'Available') {
        availT++;
        availS += table.capacity;
      } else if (table.status === 'Serving') {
        servingT++;
      }
    });
  });

  const formattedToday = getFormattedSelectedDate.value;
  const todayB = bookings.value.filter(b => b.date === formattedToday).length;
  const checkedInToday = bookings.value.filter(b => b.date === formattedToday && (b.status === 'Arrived' || b.status === 'Seated')).length;

  return {
    totalTables: totalT,
    availableTables: availT,
    servingTables: servingT,
    totalSeats: totalS,
    availableSeats: availS,
    todayBookingsCount: todayB,
    arrivedBookingsCount: checkedInToday
  };
});

// Sidebar dynamic summary metrics for bottom bar center
const sidebarStats = computed(() => {
  const formattedToday = getFormattedSelectedDate.value;
  let list = bookings.value.filter(b => b.date === formattedToday);
  
  if (selectedZone.value !== 'All') {
    list = list.filter(b => {
      if (!b.assignedTable) return false;
      return getTableArea(b.assignedTable) === selectedZone.value;
    });
  }

  const total = list.length;
  const arrived = list.filter(b => b.status === 'Arrived').length;
  const waiting = list.filter(b => b.status === 'Waiting' || b.status === 'Arrived').length;

  return { total, arrived, waiting };
});

// Utility helpers
function getZoneTableCount(zoneValue: string) {
  if (zoneValue === 'All') {
    return areas.value.reduce((acc, a) => acc + a.tables.length, 0);
  }
  const area = areas.value.find(a => a.name === zoneValue);
  return area ? area.tables.length : 0;
}

function getTableReservationTime(tableCode: string) {
  const formattedToday = getFormattedSelectedDate.value;
  const match = bookings.value.find(b => b.date === formattedToday && b.assignedTable === tableCode && b.status !== 'Seated' && b.status !== 'Completed' && b.status !== 'Cancelled');
  return match ? match.reservationTime : null;
}

function getTableArrivalTime(tableCode: string) {
  const formattedToday = getFormattedSelectedDate.value;
  // Get arrival time from Arrived bookings
  const match = bookings.value.find(b => b.date === formattedToday && b.assignedTable === tableCode && b.status === 'Arrived');
  return match ? match.reservationTime : null;
}

function getTableColorClass(status: 'Available' | 'Reserved' | 'Arrived' | 'Serving') {
  switch (status) {
    case 'Available': return 'bg-emerald-50/40 border-emerald-200 hover:border-emerald-400'
    case 'Reserved': return 'bg-amber-50/40 border-amber-200 hover:border-amber-400'
    case 'Arrived': return 'bg-blue-50/40 border-blue-200 hover:border-blue-400'
    case 'Serving': return 'bg-rose-50/40 border-rose-200 hover:border-rose-450'
    default: return 'bg-gray-50 border-gray-200'
  }
}

function getBadgeColorClass(status: 'Available' | 'Reserved' | 'Arrived' | 'Serving') {
  switch (status) {
    case 'Available': return 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20'
    case 'Reserved': return 'bg-amber-500/10 text-amber-600 border-amber-500/20'
    case 'Arrived': return 'bg-blue-500/10 text-blue-600 border-blue-500/20'
    case 'Serving': return 'bg-rose-500/10 text-rose-600 border-rose-500/20'
    default: return 'bg-gray-500/10 text-gray-600 border-gray-500/20'
  }
}

function translateTableStatus(status: string) {
  switch (status) {
    case 'Available': return 'Trống'
    case 'Reserved': return 'Đặt trước'
    case 'Arrived': return 'Đã đến'
    case 'Serving': return 'Phục vụ'
    default: return status
  }
}

function translateReservationStatus(status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled') {
  switch (status) {
    case 'Waiting': return 'Chờ xếp'
    case 'Arrived': return 'Đã đến'
    case 'Seated': return 'Đã ngồi'
    case 'Completed': return 'Hoàn tất'
    case 'Cancelled': return 'Đã hủy'
  }
}

function getReservationBadgeClass(status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled') {
  switch (status) {
    case 'Waiting': return 'bg-amber-50 text-amber-700 border-amber-200'
    case 'Arrived': return 'bg-blue-50 text-blue-700 border-blue-200'
    case 'Seated': return 'bg-rose-50 text-rose-700 border-rose-250'
    case 'Completed': return 'bg-emerald-50 text-emerald-700 border-emerald-250'
    case 'Cancelled': return 'bg-gray-50 text-gray-500 border-gray-250'
  }
}

function getTableByCode(code: string): TableInfo | null {
  for (const area of areas.value) {
    const found = area.tables.find(t => t.code === code);
    if (found) return found;
  }
  return null;
}

// ----------------------------------------------------
// DYNAMIC BOTTOM TILE STATS (active tables, revenue, bookings)
// ----------------------------------------------------

function getZoneActiveTablesCount(zoneName: string) {
  let count = 0;
  simulatedAreas.value.forEach(area => {
    if (zoneName === 'All' || area.name === zoneName) {
      area.tables.forEach(t => {
        if (t.status === 'Serving') {
          count++;
        }
      });
    }
  });
  return count;
}

function getZoneBookingsCount(zoneName: string) {
  const formattedToday = getFormattedSelectedDate.value;
  let list = bookings.value.filter(b => b.date === formattedToday);
  if (zoneName !== 'All') {
    list = list.filter(b => {
      if (!b.assignedTable) return false;
      return getTableArea(b.assignedTable) === zoneName;
    });
  }
  return list.length;
}

function getZoneRevenue(zoneName: string) {
  let sum = 0;
  simulatedAreas.value.forEach(area => {
    if (zoneName === 'All' || area.name === zoneName) {
      area.tables.forEach(t => {
        if (t.status === 'Serving' && t.billAmount) {
          const val = parseInt(t.billAmount.replace(/\D/g, '')) || 0;
          sum += val;
        }
      });
    }
  });
  if (sum === 0) return '0đ';
  if (sum >= 1000000) return (sum / 1000000).toFixed(1) + 'M';
  return (sum / 1000).toFixed(0) + 'K';
}

// ----------------------------------------------------
// OPERATIONAL MOVEMENT LOGIC
// ----------------------------------------------------

function markBookingArrived(booking: Booking) {
  booking.status = 'Arrived';
  
  if (booking.assignedTable) {
    const table = getTableByCode(booking.assignedTable);
    if (table) {
      table.status = 'Arrived';
      table.customerName = booking.customerName;
    }
  }
}

function openTableFromBooking(booking: Booking) {
  booking.status = 'Seated';
  
  if (booking.assignedTable) {
    const table = getTableByCode(booking.assignedTable);
    if (table) {
      table.status = 'Serving';
      table.customerName = booking.customerName;
      table.billAmount = '350.000đ';
      table.occupiedDuration = '1 phút';
      
      const now = new Date();
      table.checkInTime = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });

      // Automatically open the order screen (Chọn món) for this table
      goToOrderScreen(table.code);
    }
  }
}

// System Time Clock
const currentTime = ref('');
let systemClockInterval: number | null = null;
const updateSystemClock = () => {
  const now = new Date();
  currentTime.value = now.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
};

onMounted(() => {
  updateSystemClock();
  systemClockInterval = setInterval(updateSystemClock, 1000) as unknown as number;
  resetToRealTimeOnly();
});

onUnmounted(() => {
  if (systemClockInterval) clearInterval(systemClockInterval);
});

// ----------------------------------------------------
// MODAL FORMS STATE & CONTROLLERS
// ----------------------------------------------------

// Modal 1: Individual Table detailed state editor
const isTableModalOpen = ref(false);
const selectedTableForModal = ref<(TableInfo & { areaName: string }) | null>(null);
const tableModalForm = ref({
  customerName: '',
  billAmount: '',
  occupiedDuration: '',
  status: 'Available' as 'Available' | 'Reserved' | 'Arrived' | 'Serving'
});

function openTableModal(areaName: string, table: TableInfo) {
  selectedTableForModal.value = { ...table, areaName };
  tableModalForm.value = {
    customerName: table.customerName || '',
    billAmount: table.billAmount || '',
    occupiedDuration: table.occupiedDuration || '',
    status: table.status
  };
  isTableModalOpen.value = true;
}

function setTableModalStatus(status: 'Available' | 'Reserved' | 'Arrived' | 'Serving') {
  tableModalForm.value.status = status;
}

function saveTableModal() {
  if (selectedTableForModal.value) {
    const origTable = getTableByCode(selectedTableForModal.value.code);
    if (origTable) {
      origTable.status = tableModalForm.value.status;
      origTable.customerName = tableModalForm.value.customerName;
      origTable.billAmount = tableModalForm.value.billAmount;
      origTable.occupiedDuration = tableModalForm.value.occupiedDuration;
      
      if (origTable.status === 'Available') {
        origTable.customerName = '';
        origTable.billAmount = '';
        origTable.occupiedDuration = '';
        origTable.checkInTime = '';
      } else if (origTable.status === 'Serving') {
        const now = new Date();
        origTable.checkInTime = origTable.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
      }
    }
  }
  closeTableModal();
}

function closeTableModal() {
  isTableModalOpen.value = false;
  selectedTableForModal.value = null;
}

// Modal 2: Create / Edit Booking
const isCreateBookingModalOpen = ref(false);
const isEditMode = ref(false);
const editingBookingId = ref('');
const newBookingForm = ref({
  customerName: '',
  phone: '',
  guestCount: 4,
  reservationTime: '',
  assignedTable: '',
  notes: ''
});

function openCreateBookingModal() {
  isEditMode.value = false;
  editingBookingId.value = '';
  newBookingForm.value = {
    customerName: '',
    phone: '',
    guestCount: 4,
    reservationTime: '18:30',
    assignedTable: '',
    notes: ''
  };
  isCreateBookingModalOpen.value = true;
}

function openEditBookingModal(booking: Booking) {
  isEditMode.value = true;
  editingBookingId.value = booking.id;
  newBookingForm.value = {
    customerName: booking.customerName,
    phone: booking.phone,
    guestCount: booking.adults + booking.children,
    reservationTime: booking.reservationTime,
    assignedTable: booking.assignedTable,
    notes: booking.notes
  };
  isCreateBookingModalOpen.value = true;
}

function saveNewBooking() {
  if (!newBookingForm.value.customerName || !newBookingForm.value.phone || !newBookingForm.value.reservationTime) {
    alert('Vui lòng nhập đầy đủ thông tin: Tên khách, SĐT và Giờ hẹn.');
    return;
  }

  if (isEditMode.value) {
    const booking = bookings.value.find(b => b.id === editingBookingId.value);
    if (booking) {
      const oldTableCode = booking.assignedTable;
      const newTableCode = newBookingForm.value.assignedTable;
      
      if (oldTableCode !== newTableCode && oldTableCode) {
        const oldTable = getTableByCode(oldTableCode);
        if (oldTable) {
          oldTable.status = 'Available';
          oldTable.customerName = '';
          oldTable.billAmount = '';
          oldTable.occupiedDuration = '';
          oldTable.checkInTime = '';
        }
      }

      booking.customerName = newBookingForm.value.customerName;
      booking.phone = newBookingForm.value.phone;
      const total = newBookingForm.value.guestCount;
      booking.adults = Math.max(1, total - 1);
      booking.children = Math.max(0, total - booking.adults);
      booking.reservationTime = newBookingForm.value.reservationTime;
      booking.assignedTable = newTableCode;
      booking.notes = newBookingForm.value.notes;

      if (newTableCode) {
        const newTable = getTableByCode(newTableCode);
        if (newTable) {
          if (booking.status === 'Waiting') newTable.status = 'Reserved';
          else if (booking.status === 'Arrived') newTable.status = 'Arrived';
          else if (booking.status === 'Seated') newTable.status = 'Serving';
          newTable.customerName = booking.customerName;
        }
      }
    }
  } else {
    const newId = 'b' + (bookings.value.length + 1);
    const newNumber = 'NC-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-' + String(bookings.value.length + 1).padStart(3, '0');
    
    const total = newBookingForm.value.guestCount;
    const ad = Math.max(1, total - 1);
    const ch = Math.max(0, total - ad);

    const created: Booking = {
      id: newId,
      bookingNumber: newNumber,
      customerName: newBookingForm.value.customerName,
      phone: newBookingForm.value.phone,
      adults: ad,
      children: ch,
      reservationTime: newBookingForm.value.reservationTime,
      assignedTable: newBookingForm.value.assignedTable,
      notes: newBookingForm.value.notes,
      status: 'Waiting',
      date: getFormattedSelectedDate.value
    };

    bookings.value.push(created);

    if (created.assignedTable) {
      const table = getTableByCode(created.assignedTable);
      if (table) {
        table.status = 'Reserved';
        table.customerName = created.customerName;
      }
    }
  }

  isCreateBookingModalOpen.value = false;
}

// Modal 3: Quick Open (Walk-in)
const isQuickOpenModalOpen = ref(false);
const quickOpenForm = ref({
  tableCode: '',
  customerName: '',
  guestCount: 2,
  billAmount: '0đ'
});

function openQuickOpenModal() {
  quickOpenForm.value = {
    tableCode: '',
    customerName: 'Khách vãng lai',
    guestCount: 2,
    billAmount: '0đ'
  };
  isQuickOpenModalOpen.value = true;
}

function goToOrderScreen(tableCode: string) {
  // If editing in modal, apply those values first
  if (isTableModalOpen.value && selectedTableForModal.value && selectedTableForModal.value.code === tableCode) {
    tableModalForm.value.status = 'Serving';
    saveTableModal();
  }

  const table = getTableByCode(tableCode);
  if (table) {
    if (table.status !== 'Serving') {
      table.status = 'Serving';
      table.customerName = table.customerName || 'Khách vãng lai';
      table.billAmount = table.billAmount || '0đ';
      table.occupiedDuration = table.occupiedDuration || '1 phút';
      const now = new Date();
      table.checkInTime = table.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    }
    
    restaurantStore.setSelectedTable(table.code);
    router.push({ name: 'reception-order' });
  }
}

function saveQuickOpen() {
  if (!quickOpenForm.value.tableCode) {
    alert('Vui lòng chọn bàn cần mở.');
    return;
  }

  const table = getTableByCode(quickOpenForm.value.tableCode);
  if (table) {
    table.status = 'Serving';
    table.customerName = quickOpenForm.value.customerName || 'Khách vãng lai';
    table.billAmount = quickOpenForm.value.billAmount || '0đ';
    table.occupiedDuration = '1 phút';
    const now = new Date();
    table.checkInTime = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    
    // Auto redirect to order page
    goToOrderScreen(table.code);
  }

  isQuickOpenModalOpen.value = false;
}

// Modal 4: Quick Check-in (Mark Arrived)
const isQuickArrivedModalOpen = ref(false);
const quickArrivedForm = ref({
  bookingId: ''
});

function openQuickArrivedModal() {
  quickArrivedForm.value = {
    bookingId: ''
  };
  isQuickArrivedModalOpen.value = true;
}

function saveQuickArrived() {
  if (!quickArrivedForm.value.bookingId) {
    alert('Vui lòng chọn khách hàng.');
    return;
  }

  const booking = bookings.value.find(b => b.id === quickArrivedForm.value.bookingId);
  if (booking) {
    markBookingArrived(booking);
  }

  isQuickArrivedModalOpen.value = false;
}

// Modal 5: Booking details Drawer
const isBookingDetailsOpen = ref(false);
const selectedBookingForDetails = ref<Booking | null>(null);

function showBookingDetails(booking: Booking) {
  selectedBookingForDetails.value = booking;
  isBookingDetailsOpen.value = true;
}

function updateBookingStatus(id: string, newStatus: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled') {
  const b = bookings.value.find(bk => bk.id === id);
  if (b) {
    const oldStatus = b.status;
    b.status = newStatus;
    
    if (b.assignedTable) {
      const table = getTableByCode(b.assignedTable);
      if (table) {
        if (newStatus === 'Waiting') {
          table.status = 'Reserved';
          table.customerName = b.customerName;
        } else if (newStatus === 'Arrived') {
          table.status = 'Arrived';
          table.customerName = b.customerName;
        } else if (newStatus === 'Seated') {
          table.status = 'Serving';
          table.customerName = b.customerName;
          table.billAmount = table.billAmount || '350.000đ';
          table.occupiedDuration = table.occupiedDuration || '1 phút';
          const now = new Date();
          table.checkInTime = table.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
        } else if (newStatus === 'Completed' || newStatus === 'Cancelled') {
          table.status = 'Available';
          table.customerName = '';
          table.billAmount = '';
          table.occupiedDuration = '';
          table.checkInTime = '';
        }
      }
    }
    
    if (newStatus === 'Completed' || newStatus === 'Cancelled') {
      isBookingDetailsOpen.value = false;
    }
  }
}

function cancelBooking(id: string) {
  if (confirm('Bạn có chắc chắn muốn hủy lượt đặt bàn này không?')) {
    updateBookingStatus(id, 'Cancelled');
  }
}

// Modal 6: Assign Table Directly
const isAssignTableModalOpen = ref(false);
const selectedBookingForAssign = ref<Booking | null>(null);
const assignTableForm = ref({
  tableCode: ''
});

function openAssignTableModal(booking: Booking) {
  selectedBookingForAssign.value = booking;
  assignTableForm.value.tableCode = booking.assignedTable || '';
  isAssignTableModalOpen.value = true;
}

function saveAssignTable() {
  if (selectedBookingForAssign.value) {
    const booking = bookings.value.find(b => b.id === selectedBookingForAssign.value!.id);
    if (booking) {
      const oldTableCode = booking.assignedTable;
      const newTableCode = assignTableForm.value.tableCode;
      
      if (oldTableCode !== newTableCode) {
        if (oldTableCode) {
          const oldTable = getTableByCode(oldTableCode);
          if (oldTable) {
            oldTable.status = 'Available';
            oldTable.customerName = '';
            oldTable.billAmount = '';
            oldTable.occupiedDuration = '';
            oldTable.checkInTime = '';
          }
        }
        
        booking.assignedTable = newTableCode;
        
        if (newTableCode) {
          const newTable = getTableByCode(newTableCode);
          if (newTable) {
            if (booking.status === 'Waiting') newTable.status = 'Reserved';
            else if (booking.status === 'Arrived') newTable.status = 'Arrived';
            else if (booking.status === 'Seated') newTable.status = 'Serving';
            newTable.customerName = booking.customerName;
          }
        }
      }
    }
  }
  isAssignTableModalOpen.value = false;
}

const resetToCurrentState = () => {
  selectedDate.value = new Date(2026, 5, 24);
  currentYear.value = 2026;
  currentMonth.value = 5;
  selectedZone.value = 'All';
  activeShift.value = 'all';
  searchBookingQuery.value = '';
  
  // Set simulated minutes to the actual real-time hour & minute
  const now = new Date();
  const currentHour = now.getHours();
  const currentMin = now.getMinutes();
  simulatedMinutes.value = currentHour * 60 + currentMin;
};
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.animate-slide-in {
  animation: slideIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.96); }
  to { opacity: 1; transform: scale(1); }
}

@keyframes slideIn {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

/* Custom scrollbars */
::-webkit-scrollbar {
  width: 5px;
}
::-webkit-scrollbar-track {
  background: #f7fafc;
  border-radius: 4px;
}
::-webkit-scrollbar-thumb {
  background: #cbd5e0;
  border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
  background: #a0aec0;
}
.scrollbar-none::-webkit-scrollbar {
  display: none;
}
</style>
