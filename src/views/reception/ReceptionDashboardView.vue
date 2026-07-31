<template>
  <div class="h-full bg-[#FAF3E8] text-[#3D2817] font-sans">
    
    <!-- Top Header Widget -->
    <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between bg-white rounded-2xl p-6 border border-[#E8772E]/10 shadow-sm gap-4">
      <div class="flex items-center gap-4">
        <!-- Date Time Widget -->
        <div class="p-3 bg-[#E8772E]/10 rounded-xl flex items-center justify-center text-[#E8772E]">
          <Clock class="w-8 h-8" />
        </div>
        <div>
          <div class="text-3xl font-black tracking-tight font-mono text-[#3D2817]">{{ formattedTime }}</div>
          <div class="text-sm font-bold text-gray-500">{{ formattedDate }}</div>
        </div>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="bg-gray-100 px-4 py-2 rounded-xl text-center border">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception.branch') }}</div>
          <div class="text-sm font-extrabold text-[#3D2817]">{{ activeBranchName }}</div>
        </div>
        <div class="bg-green-50 px-4 py-2 rounded-xl text-center border border-green-200">
          <div class="text-[10px] font-bold text-green-500 uppercase tracking-wider">{{ t('reception.system') }}</div>
          <div class="text-sm font-extrabold text-green-700 flex items-center gap-1">
            <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>{{ t('reception.connection') }}</div>
        </div>
      </div>
    </div>

    <!-- Error Banner -->
    <div v-if="error" class="mb-6 p-4 text-sm text-red-700 bg-red-50 border border-red-200 rounded-xl flex items-center justify-between">
      <span>{{ error }}</span>
      <button @click="error = null" class="text-red-700 font-bold hover:underline">{{ t('reception.close') }}</button>
    </div>

    <!-- Active Shift Alert -->
    <div v-if="activeShift" class="mb-6 rounded-xl border-2 border-green-200 bg-green-50 p-4 flex items-center justify-between shadow-sm">
      <div class="flex items-center gap-3">
        <div class="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse"></div>
        <div>
          <div class="text-xs font-bold text-green-700 uppercase tracking-wide">{{ t('reception.open_shift') }}</div>
          <div class="text-sm text-green-800 mt-0.5">{{ t('reception.started_at') }}<b class="font-mono">{{ formatDateTime(activeShift.opened_at) }}</b> — 
            Số dư đầu ca: <b>{{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ</b>
          </div>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <RouterLink
          to="/reception/close-shift"
          class="bg-green-600 hover:bg-green-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors shadow-sm"
        >{{ t('reception.shift_details') }}</RouterLink>
        <button
          @click="showCloseShiftModal = true"
          class="bg-red-600 hover:bg-red-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors shadow-sm"
          type="button"
        >{{ t('reception.close_shift.confirm_close_btn', 'Đóng ca') }}</button>
      </div>
    </div>
    <div v-else class="mb-6 rounded-xl border-2 border-yellow-200 bg-yellow-50 p-4 flex items-center justify-between shadow-sm">
      <div class="flex items-center gap-3">
        <div class="w-2.5 h-2.5 rounded-full bg-yellow-500 animate-pulse"></div>
        <div>
          <div class="text-xs font-bold text-yellow-700 uppercase tracking-wide">{{ t('reception.no_open_shift') }}</div>
          <div class="text-sm text-yellow-800 mt-0.5">{{ t('reception.please_open_shift') }}</div>
        </div>
      </div>
      <button
        @click="showOpenShiftModal = true"
        class="bg-yellow-600 hover:bg-yellow-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors shadow-sm"
        type="button"
      >{{ t('reception.open_shift_btn') }}</button>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
      
      <!-- Main Content (Columns 1-3) -->
      <div class="lg:col-span-3 space-y-6">
        
        <!-- Enhanced Stat Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- Card 1: Bàn đang sử dụng -->
          <div 
            @click="scrollToSection('active-tables-section')"
            class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer transition-all duration-200 flex items-center justify-between"
          >
            <div>
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.tables_in_use') }}</div>
              <div class="text-3xl font-black text-[#E8772E] mt-1">{{ diningTables.length }}</div>
              <div class="text-xs text-green-600 flex items-center gap-1 mt-1 font-bold">
                <TrendingUp class="w-3.5 h-3.5" />
                +2 so với giờ trước
              </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#E8772E]/10 text-[#E8772E] flex items-center justify-center">
              <Utensils class="w-6 h-6" />
            </div>
          </div>

          <!-- Card 2: Chờ thanh toán -->
          <div 
            @click="scrollToSection('active-tables-section')"
            class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer transition-all duration-200 flex items-center justify-between"
          >
            <div>
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.waiting_payment') }}</div>
              <div class="text-3xl font-black text-red-600 mt-1">{{ pendingPaymentsCount }}</div>
              <div class="text-xs text-red-500 mt-1 font-bold">
                Tạm tính: {{ pendingPaymentsAmount.toLocaleString('vi-VN') }}đ
              </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-red-50 text-red-500 flex items-center justify-center border border-red-100">
              <CreditCard class="w-6 h-6" />
            </div>
          </div>

          <!-- Card 3: Đặt bàn hôm nay -->
          <div 
            @click="scrollToSection('reservations-section')"
            class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer transition-all duration-200 flex items-center justify-between"
          >
            <div>
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.reservations_today') }}</div>
              <div class="text-3xl font-black text-blue-600 mt-1">{{ reservations.length }}</div>
              <div class="text-xs text-blue-500 mt-1 font-bold">
                Sắp tới: {{ upcomingBookingsCount }} đặt bàn
              </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center border border-blue-100">
              <Calendar class="w-6 h-6" />
            </div>
          </div>

          <!-- Card 4: Doanh thu hôm nay -->
          <div 
            @click="scrollToSection('revenue-chart-section')"
            class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer transition-all duration-200 flex items-center justify-between"
          >
            <div>
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">DOANH THU HÔM NAY</div>
              <div class="text-2xl font-black text-green-600 mt-1">{{ dashboardExtraStats.totalRevenue.toLocaleString('vi-VN') }}đ</div>
              <div class="text-xs text-gray-500 mt-1 font-bold">
                AOV: {{ dashboardExtraStats.averageOrderValue.toLocaleString('vi-VN') }}đ · {{ dashboardExtraStats.totalCustomers }} khách
              </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-green-50 text-green-500 flex items-center justify-center border border-green-100">
              <Wallet class="w-6 h-6" />
            </div>
          </div>
        </div>

        <!-- Quick Action Buttons -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
          <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4 flex items-center gap-2">
            <Briefcase class="w-4 h-4 text-[#E8772E]" />{{ t('reception.quick_actions') }}</h3>
          
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
            <!-- Nhóm Bán hàng -->
            <button 
              @click="handleQuickAction('Nhà hàng', '/reception/order')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-orange-100 bg-[#E8772E]/5 hover:bg-[#E8772E]/10 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#E8772E] text-white flex items-center justify-center shadow-md shrink-0">
                <Utensils class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-[#E8772E] leading-tight break-words max-w-full">{{ t('reception.restaurant') }}</span>
            </button>

            <!-- Nhóm Nghiệp vụ khác -->
            <button 
              @click="handleQuickAction('Thu khác', '/transactions/income')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-green-100 bg-green-50/50 hover:bg-green-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#4CAF50] text-white flex items-center justify-center shadow-md shrink-0">
                <BadgePlus class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-green-700 leading-tight break-words max-w-full">{{ t('reception.other_income_short') }}</span>
            </button>

            <button 
              @click="handleQuickAction('Chi khác', '/reception/other-expense')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-red-100 bg-red-50/50 hover:bg-red-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#F44336] text-white flex items-center justify-center shadow-md shrink-0">
                <BadgeMinus class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-red-600 leading-tight break-words max-w-full">{{ t('reception.other_expenses') }}</span>
            </button>

            <button 
              @click="handleQuickAction('Cấu hình', '/settings')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-purple-100 bg-purple-50/50 hover:bg-purple-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#9C27B0] text-white flex items-center justify-center shadow-md shrink-0">
                <Settings class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-purple-700 leading-tight break-words max-w-full">{{ t('reception.configuration') }}</span>
            </button>

            <!-- Nhóm Quản trị -->
            <button 
              @click="handleQuickAction('Phiếu', '/reception/reports')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-yellow-100 bg-yellow-50/30 hover:bg-yellow-50/70 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#FF9800] text-white flex items-center justify-center shadow-md shrink-0">
                <Receipt class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-yellow-700 leading-tight break-words max-w-full">{{ t('reception.receipt') }}</span>
            </button>

            <button 
              @click="handleQuickAction('Báo cáo', '/reception/revenue-overview')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-orange-100 bg-orange-50/20 hover:bg-orange-50/50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#FFB74D] text-white flex items-center justify-center shadow-md shrink-0">
                <BarChart3 class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-orange-700 leading-tight break-words max-w-full">{{ t('reception.reports') }}</span>
            </button>

            <!-- Ra ca -->
            <button 
              @click="handleQuickAction('Ra ca', '/shift/end')"
              class="flex flex-col items-center justify-center p-2.5 sm:p-4 min-h-[110px] rounded-xl border border-purple-200 bg-purple-50 hover:bg-purple-100 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2 w-full"
            >
              <div class="w-10 h-10 rounded-full bg-[#8E24AA] text-white flex items-center justify-center shadow-md shrink-0">
                <LogOut class="w-5 h-5" />
              </div>
              <span class="text-[11px] sm:text-xs font-bold text-[#8E24AA] leading-tight break-words max-w-full">Ra ca</span>
            </button>
          </div>
        </div>

        <!-- Shift Summary Section -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
          <div class="flex items-center justify-between border-b pb-3 mb-4">
            <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider flex items-center gap-2">
              <Clock class="w-4 h-4 text-[#8E24AA]" />{{ t('reception.current_shift_summary') }}</h3>
            <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-purple-100 text-purple-700 uppercase">
              {{ shiftTimeIndicator }}
            </span>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4" v-if="activeShift">
            <div class="p-3 bg-gray-50 rounded-xl border border-gray-100 text-center">
              <div class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">{{ t('reception.start_time') }}</div>
              <div class="text-sm font-extrabold text-[#3D2817] mt-1">{{ formatDateTime(activeShift.opened_at) }}</div>
            </div>
            <div class="p-3 bg-gray-50 rounded-xl border border-gray-100 text-center">
              <div class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">{{ t('reception.opening_balance') }}</div>
              <div class="text-sm font-mono font-black text-gray-700 mt-1">{{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ</div>
            </div>
            <div class="p-3 bg-green-50 border border-green-200 rounded-xl text-center">
              <div class="text-[10px] text-green-500 font-bold uppercase tracking-wider">{{ t('reception.current_revenue') }}</div>
              <div class="text-sm font-mono font-black text-green-700 mt-1">{{ shiftRevenue.toLocaleString('vi-VN') }}đ</div>
            </div>
            <div class="p-3 bg-blue-50 border border-blue-200 rounded-xl text-center">
              <div class="text-[10px] text-blue-500 font-bold uppercase tracking-wider">{{ t('reception.processed_orders') }}</div>
              <div class="text-sm font-black text-blue-700 mt-1">{{ shiftOrdersCount }} đơn</div>
            </div>
          </div>
          <div v-else class="text-sm text-gray-400 text-center py-4">{{ t('reception.no_active_shifts') }}</div>
        </div>

        <!-- Revenue Chart + Top Items -->
        <div id="revenue-chart-section" class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Revenue Chart (2 cols) -->
          <div class="lg:col-span-2 bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
            <div class="flex items-center justify-between border-b pb-3 mb-4">
              <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider flex items-center gap-2">
                <TrendingUp class="w-4 h-4 text-[#E8772E]" />Doanh thu 7 ngày gần nhất
              </h3>
              <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">
                Tổng: {{ revenueChartData.reduce((s, d) => s + d.revenue, 0).toLocaleString('vi-VN') }}đ
              </span>
            </div>
            <RevenueChart :data="revenueChartData" />
          </div>

          <!-- Top Selling Items (1 col) -->
          <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
            <div class="flex items-center justify-between border-b pb-3 mb-4">
              <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider flex items-center gap-2">
                <Award class="w-4 h-4 text-[#E8772E]" />Món bán chạy
              </h3>
            </div>
            <div class="space-y-3">
              <div
                v-for="(item, idx) in topItemsData"
                :key="item.id"
                class="flex items-center gap-3 p-2 rounded-xl hover:bg-gray-50 transition-colors"
              >
                <span
                  :class="[
                    'w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0',
                    idx === 0 ? 'bg-yellow-100 text-yellow-700' :
                    idx === 1 ? 'bg-gray-200 text-gray-600' :
                    idx === 2 ? 'bg-orange-100 text-orange-700' :
                    'bg-gray-100 text-gray-400'
                  ]"
                >{{ idx + 1 }}</span>
                <div class="flex-1 min-w-0">
                  <div class="text-xs font-bold text-[#3D2817] truncate">{{ item.name }}</div>
                  <div class="text-[10px] text-gray-500">{{ item.sold }} suất · {{ item.revenue.toLocaleString('vi-VN') }}đ</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Active Tables List -->
        <div id="active-tables-section" class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden">
          <div class="bg-gray-50 px-6 py-4 border-b flex items-center justify-between">
            <h3 class="font-extrabold text-[#3D2817] text-base flex items-center gap-2">
              <Utensils class="w-5 h-5 text-[#E8772E]" />{{ t('reception.serving_tables_list') }}</h3>
            <span class="bg-[#E8772E]/10 text-[#E8772E] px-2.5 py-1 rounded-full text-xs font-black">
              {{ diningTables.length }} bàn
            </span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50/50 border-b">
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Bàn</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.guests') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.seated_time') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.ordered_items') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-right">Tổng tiền</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-center">{{ t('reception.action_col') }}</th>
                </tr>
              </thead>
              <tbody class="text-sm divide-y">
                <tr 
                  v-for="table in diningTables" 
                  :key="table.id" 
                  class="hover:bg-gray-50/50 transition-colors"
                >
                  <td class="py-4 px-6">
                    <span class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-orange-100 text-[#E8772E] font-black text-base border border-orange-200 shadow-sm">
                      {{ table.code }}
                    </span>
                  </td>
                  <td class="py-4 px-6 font-bold text-[#3D2817]">
                    {{ getTableGuests(table) }} người
                  </td>
                  <td class="py-4 px-6">
                    <span 
                      :class="[
                        'px-2.5 py-1 rounded-full text-xs font-bold',
                        getTableDurationClass(table.id)
                      ]"
                    >
                      {{ getTableDurationText(table.id) }}
                    </span>
                  </td>
                  <td class="py-4 px-6 text-gray-600 font-semibold">
                    <span v-if="loadingDetails" class="text-xs text-gray-400">{{ t('reception.loading') }}</span>
                    <span v-else>{{ getTableItemsCount(table.id) }} món</span>
                  </td>
                  <td class="py-4 px-6 text-right font-black text-[#3D2817]">
                    <span v-if="loadingDetails" class="text-xs text-gray-400">{{ t('reception.loading') }}</span>
                    <span v-else>{{ getTableTotal(table.id).toLocaleString('vi-VN') }}đ</span>
                  </td>
                  <td class="py-4 px-6 text-center">
                    <div class="flex items-center justify-center gap-2">
                      <RouterLink
                        :to="`/reception/order`"
                        class="px-3 py-1.5 rounded-lg bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-bold transition-all flex items-center gap-1 shadow-sm border border-gray-200"
                      >
                        <Eye class="w-3.5 h-3.5" />
                        Xem
                      </RouterLink>
                      <RouterLink
                        :to="`/reception/checkout/${table.id}`"
                        class="px-3 py-1.5 rounded-lg bg-[#E8772E] hover:bg-[#d0621f] text-white text-xs font-bold transition-all flex items-center gap-1 shadow-md hover:shadow-lg"
                      >{{ t('reception.payment') }}</RouterLink>
                    </div>
                  </td>
                </tr>
                <tr v-if="diningTables.length === 0">
                  <td colspan="6" class="py-8 text-center text-gray-400">{{ t('reception.no_active_tables') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Today's reservations list -->
        <div id="reservations-section" class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden">
          <div class="bg-gray-50 px-6 py-4 border-b flex items-center justify-between">
            <h3 class="font-extrabold text-[#3D2817] text-base flex items-center gap-2">
              <Calendar class="w-5 h-5 text-blue-500" />{{ t('reception.reservations_today') }}</h3>
            <span class="bg-blue-100 text-blue-700 px-2.5 py-1 rounded-full text-xs font-black">
              {{ reservations.length }} đặt bàn
            </span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50/50 border-b">
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.reservation_code') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.customer_phone') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.reserved_time') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.number_of_people') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">{{ t('reception.status') }}</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-center">{{ t('reception.action_col') }}</th>
                </tr>
              </thead>
              <tbody class="text-sm divide-y">
                <tr 
                  v-for="res in reservations" 
                  :key="res.id" 
                  class="hover:bg-gray-50/50 transition-colors"
                >
                  <td class="py-4 px-6 font-mono font-bold text-gray-900">
                    {{ res.booking_code || '—' }}
                  </td>
                  <td class="py-4 px-6">
                    <div class="font-bold text-[#3D2817]">{{ customerNameOf(res) }}</div>
                    <div class="text-xs text-gray-500 font-semibold">{{ customerPhoneOf(res) }}</div>
                  </td>
                  <td class="py-4 px-6 font-mono text-gray-600 font-bold">
                    {{ res.reservation_time ? res.reservation_time.slice(0, 5) : '—' }}
                  </td>
                  <td class="py-4 px-6 font-bold text-gray-600">
                    {{ res.guests }} người
                  </td>
                  <td class="py-4 px-6">
                    <span
                      :class="[
                        'px-2.5 py-1 rounded-full text-xs font-bold border',
                        statusClass(res.status)
                      ]"
                    >{{ translateStatus(res.status) }}</span>
                  </td>
                  <td class="py-4 px-6 text-center">
                    <div class="flex items-center justify-center gap-1.5">
                      <RouterLink
                        :to="{ name: 'reception-reservation-detail', query: { id: res.id } }"
                        class="px-2.5 py-1.5 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-bold transition-all flex items-center gap-1 border border-blue-200"
                      >
                        👁️ Chi tiết
                      </RouterLink>
                      <button
                        v-if="res.status === 'Pending'"
                        @click="handleConfirmBooking(res)"
                        class="px-2.5 py-1.5 rounded-lg bg-green-50 hover:bg-green-100 text-green-700 text-xs font-bold transition-all flex items-center gap-1 border border-green-200"
                      >
                        <CheckCircle class="w-3.5 h-3.5" />{{ t('reception.confirm') }}</button>
                      <button
                        v-if="res.status === 'Pending'"
                        @click="handleCancelBooking(res)"
                        class="px-2.5 py-1.5 rounded-lg bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold transition-all flex items-center gap-1 border border-red-200"
                      >
                        <XCircle class="w-3.5 h-3.5" />{{ t('reception.cancel') }}</button>
                    </div>
                  </td>
                </tr>
                <tr v-if="reservations.length === 0">
                  <td colspan="6" class="py-8 text-center text-gray-400">{{ t('reception.no_reservations_today') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>


      </div>

      <!-- Right Column: Notifications Panel (Column 4) -->
      <div class="lg:col-span-1 space-y-6">

        <NotificationPanel
          :notifications="allNotifications"
          :unread-count="unreadCount"
          @notification-click="handleNotificationClick"
          @mark-read="handleMarkRead"
        />

      </div>

    </div>

    <!-- Other Income Modal -->
    <OtherIncomeModal
      :is-open="showOtherIncomeModal"
      @close="showOtherIncomeModal = false"
      @save="handleOtherIncomeSave"
      @save-and-print="handleOtherIncomeSaveAndPrint"
    />

    <!-- Settings Modal -->
    <SettingsModal
      :is-open="showSettingsModal"
      @close="showSettingsModal = false"
      @save="handleSettingsSave"
    />

    <!-- Open Shift Modal -->
    <OpenShiftModal
      :is-open="showOpenShiftModal"
      :cashier-name="cashierName"
      :loading="shiftOpening"
      @close="showOpenShiftModal = false"
      @confirm="handleOpenShiftConfirm"
    />

    <!-- Close Shift Modal -->
    <CloseShiftModal
      :is-open="showCloseShiftModal"
      :shift-start-time="activeShift?.opened_at ?? ''"
      :system-expected-cash="shiftExpectedCash"
      :card-revenue="shiftCardRevenue"
      :transfer-revenue="shiftTransferRevenue"
      :loading="shiftClosing"
      @close="showCloseShiftModal = false"
      @confirm="handleCloseShiftConfirm"
    />

  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { useReservation } from '@/composables/useReservation'
import { useNotification } from '@/composables/useNotification'
import { useRealtime } from '@/composables/useRealtime'
import { useShiftStore } from '@/stores/shiftStore'
import type { TableT, Reservation } from '@/types/database'
import {
  Clock,
  Utensils,
  Calendar,
  CreditCard,
  Briefcase,
  BadgePlus,
  BadgeMinus,
  Settings,
  Receipt,
  BarChart3,
  LogOut,
  TrendingUp,
  CheckCircle,
  XCircle,
  Eye,
  Wallet,
  Award
} from 'lucide-vue-next'
import {
  dashboardRevenueData,
  dashboardTopItems,
  dashboardExtraStats,
} from '@/data/dashboardMockData'
import OpenShiftModal from '@/components/reception/OpenShiftModal.vue'
import CloseShiftModal from '@/components/reception/CloseShiftModal.vue'
import RevenueChart from '@/components/reception/RevenueChart.vue'
import OtherIncomeModal, { type OtherIncomePayload } from '@/components/reception/OtherIncomeModal.vue'
import SettingsModal, { type SettingsPayload } from '@/components/reception/SettingsModal.vue'
import NotificationPanel, { type UINotification } from '@/components/reception/NotificationPanel.vue'

const langStore = useLanguageStore()
const t = langStore.t
const router = useRouter()
const { role, profile } = useAuth();
const { activeBranchId } = useBranch();
const { updateStatus } = useReservation()
const { listForRole, markRead } = useNotification()
const { watchTable } = useRealtime()
const shiftStore = useShiftStore()
const shiftOpening = ref(false)
const shiftClosing = ref(false)
const showOpenShiftModal = ref(false)
const showCloseShiftModal = ref(false)

async function handleOpenShiftConfirm(payload: { openingCash: number; notes: string }) {
  if (!activeBranch.value) return
  shiftOpening.value = true
  try {
    const res = await shiftStore.openShift(activeBranch.value, payload.openingCash, payload.notes)
    await Swal.fire({
      icon: 'success',
      title: res.idempotent
        ? t('reception.dashboard.shift_already_open', 'Ca đã mở từ trước')
        : t('reception.dashboard.shift_opened', 'Đã mở ca'),
      timer: 1500,
      showConfirmButton: false,
    })
    showOpenShiftModal.value = false
  } catch (e: any) {
    Swal.fire('Error', e.message || String(e), 'error')
  } finally {
    shiftOpening.value = false
  }
}

async function handleCloseShiftConfirm(payload: { actualCash: number; notes: string; managerPin?: string }) {
  if (!activeShift.value) return
  shiftClosing.value = true
  try {
    await shiftStore.closeShift(payload.actualCash, payload.notes)
    const diff = payload.actualCash - shiftExpectedCash.value
    await Swal.fire({
      icon: 'success',
      title: t('reception.close_shift.close_shift_success', 'Đóng ca thành công'),
      html: `${t('reception.close_shift.cash_diff', 'Chênh lệch')}: <b>${diff >= 0 ? '+' : ''}${diff.toLocaleString('vi-VN')}đ</b>`,
      timer: 2000,
      showConfirmButton: false,
    })
    showCloseShiftModal.value = false
    await fetchActiveShift()
    await fetchShiftPayments()
  } catch (e: any) {
    Swal.fire(
      t('reception.close_shift.error_title', 'Lỗi'),
      e.message || String(e),
      'error',
    )
  } finally {
    shiftClosing.value = false
  }
}

const showOtherIncomeModal = ref(false)
const showSettingsModal = ref(false)

function handleOtherIncomeSave(payload: OtherIncomePayload) {
  Swal.fire({
    title: 'Thành công',
    text: `Đã lưu thành công phiếu thu của ${payload.object}!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#FF9800'
  })
  showOtherIncomeModal.value = false
}

function handleOtherIncomeSaveAndPrint(payload: OtherIncomePayload) {
  Swal.fire({
    title: 'Thành công',
    text: `Đã lưu và in phiếu thu cho ${payload.object} với số tiền ${payload.amount.toLocaleString('vi-VN')}đ!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#4CAF50'
  })
  showOtherIncomeModal.value = false
}

function handleSettingsSave(payload: SettingsPayload) {
  Swal.fire({
    title: 'Thành công',
    text: `Đã cập nhật cấu hình cho tài khoản ${payload.username}!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#4DB6AC'
  })
  showSettingsModal.value = false
}

const loading = ref(false)
const loadingDetails = ref(false)
const hasLoadedOnce = ref(false)
const error = ref<string | null>(null)

const tables = ref<TableT[]>([])
const reservations = ref<Reservation[]>([])
const activeShift = computed(() => shiftStore.currentShift)
const shiftPayments = computed(() => shiftStore.shiftPayments)

// Detailed summaries map for occupied tables (quantities & total amount)
const tableDetails = ref<Record<string, { itemsCount: number; grandTotal: number; createdAt: string | null }>>({})

// Notifications states
const dbNotifications = ref<UINotification[]>([])

// Revenue chart + top items (mock data)
const revenueChartData = dashboardRevenueData
const topItemsData = dashboardTopItems

// Local mock notifications as requested
const localMockNotifications = ref<UINotification[]>([
  {
    id: 'mock-1',
    type: 'out_of_stock',
    title: 'Thông báo hết hàng',
    message: 'Dạ dày bò (tổ ong) sốt tare',
    timestamp: new Date(new Date().setHours(11, 37, 0, 0)),
    isRead: false,
    priority: 'high'
  },
  {
    id: 'mock-2',
    type: 'out_of_stock',
    title: 'Thông báo hết hàng',
    message: 'Dạ dày bò (tổ ong) sốt miso cay',
    timestamp: new Date(new Date().setHours(11, 37, 0, 0)),
    isRead: false,
    priority: 'high'
  },
  {
    id: 'mock-3',
    type: 'low_stock',
    title: 'Có thể bán',
    message: 'Dorayaki Kem Trứng',
    timestamp: new Date(new Date().setHours(11, 37, 0, 0)),
    isRead: true,
    priority: 'medium'
  },
  {
    id: 'mock-4',
    type: 'out_of_stock',
    title: 'Thông báo hết hàng',
    message: 'Dorayaki Kem Trứng',
    timestamp: new Date(new Date().setHours(11, 1, 0, 0)),
    isRead: false,
    priority: 'medium'
  }
])

const cleanups: Array<() => void> = []

const activeBranch = computed<string>(() => activeBranchId.value ?? '')

// Real active branch name
const activeBranchName = ref('Đang tải...')

// Time Date Widget Clock
const currentTime = ref(new Date())
let timerId: any
let notificationPollInterval: any

onMounted(() => {
  fetchAll()
  fetchBranchInfo()
  subscribeRealtime()
  
  // Timer interval for Date Time Widget
  timerId = setInterval(() => {
    currentTime.value = new Date()
  }, 1000)

  // Auto-refresh notifications every 30 seconds
  notificationPollInterval = setInterval(() => {
    fetchNotificationsOnly()
  }, 30000)
})

onUnmounted(() => {
  for (const fn of cleanups) fn()
  cleanups.length = 0
  clearInterval(timerId)
  clearInterval(notificationPollInterval)
})

const formattedTime = computed(() => {
  return currentTime.value.toLocaleTimeString('vi-VN', { 
    hour: '2-digit', 
    minute: '2-digit', 
    second: '2-digit',
    hour12: false 
  })
})

const formattedDate = computed(() => {
  const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy']
  const dayName = days[currentTime.value.getDay()]
  const date = currentTime.value.getDate()
  const month = currentTime.value.getMonth() + 1
  const year = currentTime.value.getFullYear()
  return `${dayName}, ${date} tháng ${month}, ${year}`
})

// Occupied tables list
const diningTables = computed(() => tables.value.filter(t => t.status === 'occupied'))

// Card 2 stats: Pending Payments
const pendingPaymentsCount = computed(() => {
  return diningTables.value.length
})

const pendingPaymentsAmount = computed(() => {
  return Object.values(tableDetails.value).reduce((sum, d) => sum + d.grandTotal, 0)
})

// Card 3 stats: Bookings stats
const upcomingBookingsCount = computed(() => {
  return reservations.value.filter(r => r.status === 'Pending').length
})

// Shift Summary stats
const shiftTimeIndicator = computed(() => {
  if (!activeShift.value) return '—'
  const openedHour = new Date(activeShift.value.opened_at).getHours()
  if (openedHour >= 6 && openedHour < 12) return 'Ca sáng'
  if (openedHour >= 12 && openedHour < 18) return 'Ca chiều'
  return 'Ca tối'
})

const shiftRevenue = computed(() => {
  return shiftPayments.value.reduce((sum, p) => sum + Number(p.amount || 0), 0)
})

const shiftOrdersCount = computed(() => {
  return shiftPayments.value.length
})

const shiftCashRevenue = computed(() => {
  return shiftPayments.value
    .filter((p) => p.method === 'cash')
    .reduce((sum, p) => sum + Number(p.amount || 0), 0)
})

const shiftCardRevenue = computed(() => {
  return shiftPayments.value
    .filter((p) => p.method === 'card')
    .reduce((sum, p) => sum + Number(p.amount || 0), 0)
})

const shiftTransferRevenue = computed(() => {
  return shiftPayments.value
    .filter((p) => p.method === 'transfer')
    .reduce((sum, p) => sum + Number(p.amount || 0), 0)
})

const shiftExpectedCash = computed(() => {
  if (!activeShift.value) return 0
  return Number(activeShift.value.opening_cash || 0) + shiftCashRevenue.value
})

const cashierName = computed(() => profile.value?.full_name || 'Thu Ngân')

// Notifications mapping & logic
const allNotifications = computed<UINotification[]>(() => {
  const list = [...dbNotifications.value, ...localMockNotifications.value]
  return list.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
})

const unreadCount = computed(() => {
  return allNotifications.value.filter(n => !n.isRead).length
})

// Play Double-Beep Web Audio API notification sound (Zero files needed, works everywhere)
function playNotificationSound() {
  try {
    const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)()
    
    // Play first beep (C5)
    const osc1 = audioCtx.createOscillator()
    const gain1 = audioCtx.createGain()
    osc1.connect(gain1)
    gain1.connect(audioCtx.destination)
    osc1.type = 'sine'
    osc1.frequency.setValueAtTime(523.25, audioCtx.currentTime)
    gain1.gain.setValueAtTime(0.08, audioCtx.currentTime)
    gain1.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15)
    osc1.start(audioCtx.currentTime)
    osc1.stop(audioCtx.currentTime + 0.15)
    
    // Play second beep (E5) after 150ms
    setTimeout(() => {
      const osc2 = audioCtx.createOscillator()
      const gain2 = audioCtx.createGain()
      osc2.connect(gain2)
      gain2.connect(audioCtx.destination)
      osc2.type = 'sine'
      osc2.frequency.setValueAtTime(659.25, audioCtx.currentTime)
      gain2.gain.setValueAtTime(0.08, audioCtx.currentTime)
      gain2.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15)
      osc2.start(audioCtx.currentTime)
      osc2.stop(audioCtx.currentTime + 0.15)
    }, 150)
  } catch (e) {
    console.error('Audio context error:', e)
  }
}

// Fetch active branch info name
async function fetchBranchInfo() {
  if (!activeBranch.value) return
  try {
    const { data, error: dbError } = await supabase
      .from('branches')
      .select('name, branch_id')
      .eq('branch_id', activeBranch.value)
      .maybeSingle()
    if (dbError) throw dbError
    if (data?.name) {
      activeBranchName.value = data.name
    } else {
      activeBranchName.value = activeBranch.value
    }
  } catch {
    // Fallback: use branch ID as display name if DB query fails
    activeBranchName.value = activeBranch.value
  }
}

// Re-load only the active shift (used after `openShift` / `closeShift` so the
// pill + payment aggregates refresh without a full dashboard re-fetch).
async function fetchActiveShift() {
  if (!activeBranch.value) return
  await shiftStore.fetchActiveShift(activeBranch.value)
}

// Main fetch function converting all table fetches to Supabase Stored Procedures (RPC)
async function fetchAll() {
  if (!activeBranch.value) {
    error.value = t('reception.dashboard.no_branch_error')
    hasLoadedOnce.value = true
    return
  }
  loading.value = true
  error.value = null
  try {
    const todayStr = new Date().toISOString().split('T')[0]
    
    // 1. Fetch tables list & active orders via RPC 'hall_list_tables'
    // 2. Fetch today reservations list via RPC 'hall_list_reservations_by_date'
    // 3. Fetch notifications for role
    // 4. Fetch active shift via RPC 'hall_get_active_shift'
    const [tablesData, resData, notifData] = await Promise.all([
      supabase.rpc('hall_list_tables', { p_branch_id: activeBranch.value }),
      supabase.rpc('hall_list_reservations_by_date', { p_branch_id: activeBranch.value, p_date: todayStr }),
      listForRole('reception-panel', 50).catch(() => [] as Notification[]),
    ])

    if (tablesData.error) throw tablesData.error
    if (resData.error) throw resData.error

    tables.value = tablesData.data as TableT[]
    reservations.value = resData.data as Reservation[]

    // Load shift from mock store
    await fetchActiveShift()

    // Map DB notifications to UINotification format
    mapDbNotifications(notifData ?? [])

    await fetchShiftPayments()
    await fetchTableDetails()
  } catch (err) {
    if (err instanceof Error) {
      error.value = err.message
    } else if (typeof err === 'object' && err !== null) {
      error.value = (err as any).message || JSON.stringify(err)
    } else {
      error.value = String(err)
    }
    console.error('[ReceptionDashboard] Fetch error:', err)
  } finally {
    loading.value = false
    hasLoadedOnce.value = true
  }
}

// Fetch notifications only (for the 30-second interval refresh)
async function fetchNotificationsOnly() {
  try {
    const notifData = await listForRole('reception-panel', 50).catch(() => [] as Notification[])
    mapDbNotifications(notifData ?? [])
  } catch (e) {
    console.error('Failed to update notifications only:', e)
  }
}

// Map database notifications into UINotification
function mapDbNotifications(notifs: Notification[]) {
  const titleMap: Record<string, string> = {
    checkout_request: 'Yêu cầu thanh toán',
    new_order: 'Đơn mới từ khách',
    new_seated: 'Khách vừa nhận bàn',
    out_of_stock: 'Thông báo hết hàng',
    low_stock: 'Thông báo sắp hết hàng',
    booking: 'Lịch đặt bàn mới'
  }

  const mapped = notifs.map(n => {
    let type: UINotification['type'] = 'payment'
    let priority: UINotification['priority'] = 'low'
    if (n.template === 'checkout_request') {
      type = 'payment'
      priority = 'high'
    } else if (n.template === 'new_order') {
      // Customer just placed an order from the tablet — high priority so the
      // dashboard's playNotificationSound() fires and the cashier can call
      // the kitchen if the KDS hasn't auto-received.
      type = 'payment'
      priority = 'high'
    } else if (n.template === 'new_seated') {
      // New walk-in just seated — medium priority (no sound, but visible).
      type = 'booking'
      priority = 'medium'
    } else if (n.template === 'out_of_stock') {
      type = 'out_of_stock'
      priority = 'high'
    } else if (n.template === 'low_stock') {
      type = 'low_stock'
      priority = 'medium'
    } else if (n.template === 'booking') {
      type = 'booking'
      priority = 'medium'
    }

    const tableCode = (n.variables as Record<string, unknown>)?.table_code as string || ''
    const title = titleMap[n.template] || 'Thông báo hệ thống'
    const message = n.template === 'checkout_request'
      ? `Bàn ${tableCode} yêu cầu thanh toán.`
      : n.template === 'new_order'
        ? `Bàn ${tableCode} vừa gọi món.`
        : n.template === 'new_seated'
          ? `Bàn ${tableCode} đã có khách.`
          : ((n.variables as Record<string, unknown>)?.message as string || '')

    return {
      id: n.id,
      type,
      title,
      message,
      timestamp: new Date(n.created_at),
      isRead: n.status === 'read',
      priority
    } as UINotification
  })

  // Sound check: play sound only if we detect a new unread high-priority notification
  const oldIds = new Set(dbNotifications.value.map(n => n.id))
  const newHighUnread = mapped.filter(n => n.priority === 'high' && !n.isRead && !oldIds.has(n.id))
  if (newHighUnread.length > 0 && hasLoadedOnce.value) {
    playNotificationSound()
  }

  dbNotifications.value = mapped
}

// Fetch summaries map (N+1 avoidance by parallelized RPC call) for occupied tables
async function fetchTableDetails() {
  const occupied = diningTables.value
  if (occupied.length === 0) {
    tableDetails.value = {}
    return
  }
  loadingDetails.value = true
  try {
    const summaries = await Promise.all(
      occupied.map(async (t) => {
        try {
          const { data, error } = await supabase.rpc('hall_get_checkout_totals', {
            p_branch_id: activeBranch.value,
            p_table_id: t.id
          })
          if (error) throw error

          const items = data?.items || []
          const qtySum = items.reduce((sum: number, item: any) => sum + Number(item.quantity || 0), 0)

          // New RPC shape (see 20260703020001_hall_get_checkout_totals.sql):
          //   { ok, order: {...}, table: {...}, items: [...], totals: { grand_total, ... }, voucher_valid }
          return {
            tableId: t.id,
            itemsCount: qtySum,
            grandTotal: data?.totals?.grand_total ?? 0,
            createdAt: data?.order?.created_at ?? null
          }
        } catch (e) {
          console.error(`Error loading summary for table ${t.code}:`, e)
          return {
            tableId: t.id,
            itemsCount: 0,
            grandTotal: 0,
            createdAt: null
          }
        }
      })
    )

    const map: typeof tableDetails.value = {}
    for (const s of summaries) {
      map[s.tableId] = s
    }
    tableDetails.value = map
  } finally {
    loadingDetails.value = false
  }
}

// Fetch active shift payments (to calculate revenue & count orders)
async function fetchShiftPayments() {
  await shiftStore.fetchShiftPayments()
}

function subscribeRealtime() {
  if (!activeBranch.value) return
  cleanups.push(
    watchTable<TableT>('tables', '*', () => fetchAll()),
    watchTable<Reservation>('reservations', '*', () => fetchAll()),
    watchTable<Notification>('notifications', '*', () => fetchAll()),
    // When the customer adds an item or starts a new order, refresh the
    // per-table totals so the dashboard's "tạm tính" column doesn't show
    // a stale number until the next manual refresh.
    watchTable<Record<string, unknown>>('orders', '*', () => fetchAll()),
    watchTable<Record<string, unknown>>('order_items', '*', () => fetchAll()),
  )
}

// Table detail helpers
function getTableGuests(table: TableT): number {
  return (table as any).active_order?.guest_count || table.capacity || 2
}

function getTableItemsCount(tableId: string): number {
  return tableDetails.value[tableId]?.itemsCount || 0
}

function getTableTotal(tableId: string): number {
  return tableDetails.value[tableId]?.grandTotal || 0
}

function getTableDurationClass(tableId: string): string {
  const detail = tableDetails.value[tableId]
  if (!detail || !detail.createdAt) return 'bg-green-100 text-green-700'
  const start = new Date(detail.createdAt)
  const diffMinutes = Math.floor((new Date().getTime() - start.getTime()) / 60000)
  
  if (diffMinutes >= 60) {
    return 'bg-red-100 text-red-700 border border-red-200'
  } else if (diffMinutes >= 30) {
    return 'bg-yellow-100 text-yellow-700 border border-yellow-200'
  } else {
    return 'bg-green-100 text-green-700 border border-green-200'
  }
}

function getTableDurationText(tableId: string): string {
  const detail = tableDetails.value[tableId]
  if (!detail || !detail.createdAt) return 'Mới ngồi'
  const start = new Date(detail.createdAt)
  const diffMinutes = Math.floor((new Date().getTime() - start.getTime()) / 60000)
  
  if (diffMinutes >= 60) {
    const hours = Math.floor(diffMinutes / 60)
    const mins = diffMinutes % 60
    return `${hours}g ${mins}ph`
  }
  return `${diffMinutes} phút`
}

// Quick action click logic
function handleQuickAction(name: string, path: string) {
  if (name === 'Ra ca') {
    Swal.fire({
      title: 'Xác nhận ra ca?',
      text: 'Bạn có chắc chắn muốn kết thúc ca làm việc hiện tại không?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
      confirmButtonColor: '#8E24AA',
      cancelButtonColor: '#aaa'
    }).then((result) => {
      if (result.isConfirmed) {
        router.push('/reception/close-shift')
      }
    })
    return
  }

  // Check auth roles for admin voucher
  if (path.startsWith('/admin') && role.value !== 'superadmin') {
    Swal.fire({
      title: 'Không có quyền truy cập',
      text: 'Chức năng này thuộc phân hệ Quản trị (chỉ dành cho Admin/Superadmin).',
      icon: 'error',
      confirmButtonText: 'Đóng',
      confirmButtonColor: '#E8772E'
    })
    return
  }

  // Other income popup modal trigger
  if (path === '/transactions/income') {
    showOtherIncomeModal.value = true;
    return;
  }

  // Settings popup modal trigger
  if (path === '/settings') {
    showSettingsModal.value = true;
    return;
  }

  // Placeholder paths
  if (path === '/admin/reports') {
    Swal.fire({
      title: 'Chức năng đang phát triển',
      text: `Phân hệ ${name} đang được tích hợp thêm. Vui lòng thử lại sau.`,
      icon: 'info',
      confirmButtonText: 'Đóng',
      confirmButtonColor: '#E8772E'
    })
    return
  }

  router.push(path)
}

// Reservation confirm / cancel actions
async function handleConfirmBooking(res: any) {
  try {
    loading.value = true
    // Set status to Arrived
    await updateStatus(res.id, 'Arrived')
    Swal.fire({
      icon: 'success',
      title: 'Đã xác nhận',
      text: `Đã xác nhận khách ${customerNameOf(res)} đến nhà hàng.`,
      timer: 1500,
      showConfirmButton: false
    })
    await fetchAll()
  } catch (e: any) {
    Swal.fire('Lỗi', e.message || String(e), 'error')
  } finally {
    loading.value = false
  }
}

async function handleCancelBooking(res: any) {
  Swal.fire({
    title: 'Hủy lịch đặt bàn?',
    text: `Bạn có chắc chắn muốn hủy đặt bàn của khách ${customerNameOf(res)} không?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Đồng ý hủy',
    cancelButtonText: 'Không hủy',
    confirmButtonColor: '#F44336',
    cancelButtonColor: '#aaa'
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        loading.value = true
        await updateStatus(res.id, 'Cancelled')
        Swal.fire({
          icon: 'success',
          title: 'Đã hủy đặt bàn',
          timer: 1500,
          showConfirmButton: false
        })
        await fetchAll()
      } catch (e: any) {
        Swal.fire('Lỗi', e.message || String(e), 'error')
      } finally {
        loading.value = false
      }
    }
  })
}

// Notification handler clicks
async function handleNotificationClick(notif: UINotification) {
  handleMarkRead(notif.id)

  // Navigate to corresponding checkout page if checkout request
  if (notif.message.includes('thanh toán') || notif.type === 'payment') {
    // Try to find if there is a table code in the message
    const match = notif.message.match(/bàn\s+([A-Z0-9]+)/i)
    if (match) {
      const tableCode = match[1]
      const foundTable = tables.value.find(t => t.code.toLowerCase() === tableCode.toLowerCase())
      if (foundTable) {
        router.push(`/reception/checkout/${foundTable.id}`)
        return
      }
    }
  }

  // Scroll to reservations if booking
  if (notif.type === 'booking') {
    scrollToSection('reservations-section')
    return
  }

  // General Toast info
  Swal.fire({
    title: notif.title,
    text: notif.message,
    icon: 'info',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#E8772E'
  })
}

async function handleMarkRead(id: string) {
  const notif = allNotifications.value.find(n => n.id === id)
  if (notif) {
    notif.isRead = true
    if (!id.startsWith('mock-')) {
      try {
        await markRead(id)
      } catch (e) {
        console.error('Failed to mark read in DB:', e)
      }
    }
  }
}

// Page smooth scrolls
function scrollToSection(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' })
}

// Type/Status UI mappings
function customerNameOf(r: Reservation): string {
  const snap = r.customer_snapshot as Record<string, unknown> | null
  const name = snap?.name
  if (typeof name === 'string' && name.trim()) return name
  return 'Khách vãng lai'
}

function customerPhoneOf(r: Reservation): string {
  const snap = r.customer_snapshot as Record<string, unknown> | null
  const phone = snap?.phone
  if (typeof phone === 'string' && phone.trim()) return phone
  return '—'
}

function statusClass(status: Reservation['status']): string {
  switch (status) {
    case 'Pending': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
    case 'Arrived': return 'bg-blue-50 text-blue-700 border-blue-200'
    case 'Dining': return 'bg-green-50 text-green-700 border-green-200'
    case 'Completed': return 'bg-gray-50 text-gray-700 border-gray-200'
    case 'Cancelled': return 'bg-red-50 text-red-700 border-red-200'
    default: return 'bg-gray-50 text-gray-700 border-gray-200'
  }
}

function translateStatus(status: Reservation['status']): string {
  switch (status) {
    case 'Pending': return 'Chờ nhận bàn'
    case 'Arrived': return 'Đã đến'
    case 'Dining': return 'Đang dùng bữa'
    case 'Completed': return 'Hoàn thành'
    case 'Cancelled': return 'Đã hủy'
    default: return status
  }
}

// DateTime formatting helpers
function formatDateTime(iso?: string | null): string {
  if (!iso) return '—'
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  })
}
</script>

<style scoped>
/* Smooth slide and pulse effects */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;  
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;  
  overflow: hidden;
}
</style>
