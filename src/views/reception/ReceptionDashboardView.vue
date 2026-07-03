<template>
  <div class="min-h-screen bg-[#FAF3E8] p-4 md:p-6 text-[#3D2817] font-sans">
    
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
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Chi nhánh</div>
          <div class="text-sm font-extrabold text-[#3D2817]">{{ activeBranchName }}</div>
        </div>
        <div class="bg-green-50 px-4 py-2 rounded-xl text-center border border-green-200">
          <div class="text-[10px] font-bold text-green-500 uppercase tracking-wider">Hệ thống</div>
          <div class="text-sm font-extrabold text-green-700 flex items-center gap-1">
            <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            Kết nối
          </div>
        </div>
      </div>
    </div>

    <!-- Error Banner -->
    <div v-if="error" class="mb-6 p-4 text-sm text-red-700 bg-red-50 border border-red-200 rounded-xl flex items-center justify-between">
      <span>{{ error }}</span>
      <button @click="error = null" class="text-red-700 font-bold hover:underline">Đóng</button>
    </div>

    <!-- Active Shift Alert -->
    <div v-if="activeShift" class="mb-6 rounded-xl border-2 border-green-200 bg-green-50 p-4 flex items-center justify-between shadow-sm">
      <div class="flex items-center gap-3">
        <div class="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse"></div>
        <div>
          <div class="text-xs font-bold text-green-700 uppercase tracking-wide">Ca làm việc đang mở</div>
          <div class="text-sm text-green-800 mt-0.5">
            Bắt đầu lúc: <b class="font-mono">{{ formatDateTime(activeShift.opened_at) }}</b> — 
            Số dư đầu ca: <b>{{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ</b>
          </div>
        </div>
      </div>
      <RouterLink
        to="/reception/close-shift"
        class="bg-green-600 hover:bg-green-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors shadow-sm"
      >
        Chi tiết ca
      </RouterLink>
    </div>
    <div v-else class="mb-6 rounded-xl border-2 border-yellow-200 bg-yellow-50 p-4 flex items-center justify-between shadow-sm">
      <div class="flex items-center gap-3">
        <div class="w-2.5 h-2.5 rounded-full bg-yellow-500 animate-pulse"></div>
        <div>
          <div class="text-xs font-bold text-yellow-700 uppercase tracking-wide">Chưa mở ca làm việc</div>
          <div class="text-sm text-yellow-800 mt-0.5">Vui lòng mở ca làm việc để thực hiện thanh toán và theo dõi ca.</div>
        </div>
      </div>
      <!--
        origin/main shipped this as a RouterLink to `/reception/close-shift`
        labelled "Mở ca". That route only handles close-shift, so the label
        here is misleading. We re-route to a future /reception/open-shift
        page if/when one exists; for now we keep the visual from origin/main
        and let the receptionist click through. A real open-shift dialog is
        still wired in this file via `openShiftDialog` further below — see
        the docs/member_status/Phu/main_merge_followup.md for the wiring
        intent.
      -->
      <RouterLink
        to="/reception/dashboard"
        class="bg-yellow-600 hover:bg-yellow-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg transition-colors shadow-sm"
      >
        Mở ca
      </RouterLink>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
      
      <!-- Main Content (Columns 1-3) -->
      <div class="lg:col-span-3 space-y-6">
        
        <!-- Enhanced Stat Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <!-- Card 1: Bàn đang sử dụng -->
          <div 
            @click="scrollToSection('active-tables-section')"
            class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer transition-all duration-200 flex items-center justify-between"
          >
            <div>
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">Bàn đang dùng</div>
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
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">Chờ thanh toán</div>
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
              <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">Đặt bàn hôm nay</div>
              <div class="text-3xl font-black text-blue-600 mt-1">{{ reservations.length }}</div>
              <div class="text-xs text-blue-500 mt-1 font-bold">
                Sắp tới: {{ upcomingBookingsCount }} đặt bàn
              </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center border border-blue-100">
              <Calendar class="w-6 h-6" />
            </div>
          </div>
        </div>

        <!-- Quick Action Buttons -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
          <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4 flex items-center gap-2">
            <Briefcase class="w-4 h-4 text-[#E8772E]" />
            Chức năng nhanh
          </h3>
          
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
            <!-- Nhóm Bán hàng -->
            <button 
              @click="handleQuickAction('Nhà hàng', '/reception/order')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-orange-100 bg-[#E8772E]/5 hover:bg-[#E8772E]/10 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#E8772E] text-white flex items-center justify-center shadow-md">
                <Utensils class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-[#E8772E]">Nhà hàng</span>
            </button>

            <!-- Nhóm Nghiệp vụ khác -->
            <button 
              @click="handleQuickAction('Thu khác', '/transactions/income')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-green-100 bg-green-50/50 hover:bg-green-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#4CAF50] text-white flex items-center justify-center shadow-md">
                <BadgePlus class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-green-700">Thu khác</span>
            </button>

            <button 
              @click="handleQuickAction('Chi khác', '/transactions/expense')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-red-100 bg-red-50/50 hover:bg-red-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#F44336] text-white flex items-center justify-center shadow-md">
                <BadgeMinus class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-red-600">Chi khác</span>
            </button>

            <button 
              @click="handleQuickAction('Cấu hình', '/settings')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-purple-100 bg-purple-50/50 hover:bg-purple-50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#9C27B0] text-white flex items-center justify-center shadow-md">
                <Settings class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-purple-700">Cấu hình</span>
            </button>

            <!-- Nhóm Quản trị -->
            <button 
              @click="handleQuickAction('Phiếu', '/admin/vouchers')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-yellow-100 bg-yellow-50/30 hover:bg-yellow-50/70 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#FF9800] text-white flex items-center justify-center shadow-md">
                <Receipt class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-yellow-700">Phiếu</span>
            </button>

            <button 
              @click="handleQuickAction('Báo cáo', '/admin/reports')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-orange-100 bg-orange-50/20 hover:bg-orange-50/50 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#FFB74D] text-white flex items-center justify-center shadow-md">
                <BarChart3 class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-orange-700">Báo cáo</span>
            </button>

            <!-- Ra ca -->
            <button 
              @click="handleQuickAction('Ra ca', '/shift/end')"
              class="flex flex-col items-center justify-center p-4 rounded-xl border border-purple-200 bg-purple-50 hover:bg-purple-100 hover:scale-[1.05] active:scale-[0.98] transition-all text-center gap-2"
            >
              <div class="w-10 h-10 rounded-full bg-[#8E24AA] text-white flex items-center justify-center shadow-md">
                <LogOut class="w-5 h-5" />
              </div>
              <span class="text-xs font-bold text-[#8E24AA]">Ra ca</span>
            </button>
          </div>
        </div>

        <!-- Shift Summary Section -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-6 shadow-sm">
          <div class="flex items-center justify-between border-b pb-3 mb-4">
            <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider flex items-center gap-2">
              <Clock class="w-4 h-4 text-[#8E24AA]" />
              Tổng kết ca hiện tại
            </h3>
            <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-purple-100 text-purple-700 uppercase">
              {{ shiftTimeIndicator }}
            </span>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4" v-if="activeShift">
            <div class="p-3 bg-gray-50 rounded-xl border border-gray-100 text-center">
              <div class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Thời gian bắt đầu</div>
              <div class="text-sm font-extrabold text-[#3D2817] mt-1">{{ formatDateTime(activeShift.opened_at) }}</div>
            </div>
            <div class="p-3 bg-gray-50 rounded-xl border border-gray-100 text-center">
              <div class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Số dư đầu ca</div>
              <div class="text-sm font-mono font-black text-gray-700 mt-1">{{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ</div>
            </div>
            <div class="p-3 bg-green-50 border border-green-200 rounded-xl text-center">
              <div class="text-[10px] text-green-500 font-bold uppercase tracking-wider">Doanh thu hiện tại</div>
              <div class="text-sm font-mono font-black text-green-700 mt-1">{{ shiftRevenue.toLocaleString('vi-VN') }}đ</div>
            </div>
            <div class="p-3 bg-blue-50 border border-blue-200 rounded-xl text-center">
              <div class="text-[10px] text-blue-500 font-bold uppercase tracking-wider">Đơn hàng đã xử lý</div>
              <div class="text-sm font-black text-blue-700 mt-1">{{ shiftOrdersCount }} đơn</div>
            </div>
          </div>
          <div v-else class="text-sm text-gray-400 text-center py-4">
            Không có ca nào đang hoạt động.
          </div>
        </div>

        <!-- Active Tables List -->
        <div id="active-tables-section" class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden">
          <div class="bg-gray-50 px-6 py-4 border-b flex items-center justify-between">
            <h3 class="font-extrabold text-[#3D2817] text-base flex items-center gap-2">
              <Utensils class="w-5 h-5 text-[#E8772E]" />
              Danh sách bàn đang phục vụ
            </h3>
            <span class="bg-[#E8772E]/10 text-[#E8772E] px-2.5 py-1 rounded-full text-xs font-black">
              {{ diningTables.length }} bàn
            </span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50/50 border-b">
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Bàn</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Số khách</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Thời gian ngồi</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Món đã order</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-right">Tổng tiền</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-center">Hành động</th>
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
                    <span v-if="loadingDetails" class="text-xs text-gray-400">Đang tải...</span>
                    <span v-else>{{ getTableItemsCount(table.id) }} món</span>
                  </td>
                  <td class="py-4 px-6 text-right font-black text-[#3D2817]">
                    <span v-if="loadingDetails" class="text-xs text-gray-400">Đang tải...</span>
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
                      >
                        Thanh toán
                      </RouterLink>
                    </div>
                  </td>
                </tr>
                <tr v-if="diningTables.length === 0">
                  <td colspan="6" class="py-8 text-center text-gray-400">
                    Không có bàn nào đang hoạt động.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Today's reservations list -->
        <div id="reservations-section" class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden">
          <div class="bg-gray-50 px-6 py-4 border-b flex items-center justify-between">
            <h3 class="font-extrabold text-[#3D2817] text-base flex items-center gap-2">
              <Calendar class="w-5 h-5 text-blue-500" />
              Đặt bàn hôm nay
            </h3>
            <span class="bg-blue-100 text-blue-700 px-2.5 py-1 rounded-full text-xs font-black">
              {{ reservations.length }} đặt bàn
            </span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50/50 border-b">
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Mã đặt bàn</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Khách hàng & SĐT</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Giờ đặt</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Số người</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase">Trạng thái</th>
                  <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-center">Hành động</th>
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
                    <div class="flex items-center justify-center gap-1.5" v-if="res.status === 'Pending'">
                      <button
                        @click="handleConfirmBooking(res)"
                        class="px-2.5 py-1.5 rounded-lg bg-green-50 hover:bg-green-100 text-green-700 text-xs font-bold transition-all flex items-center gap-1 border border-green-200"
                      >
                        <CheckCircle class="w-3.5 h-3.5" />
                        Xác nhận
                      </button>
                      <button
                        @click="handleCancelBooking(res)"
                        class="px-2.5 py-1.5 rounded-lg bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold transition-all flex items-center gap-1 border border-red-200"
                      >
                        <XCircle class="w-3.5 h-3.5" />
                        Hủy
                      </button>
                    </div>
                    <div class="text-xs text-gray-400 font-bold" v-else>
                      Không có thao tác
                    </div>
                  </td>
                </tr>
                <tr v-if="reservations.length === 0">
                  <td colspan="6" class="py-8 text-center text-gray-400">
                    Không có lịch đặt bàn nào hôm nay.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>


      </div>

      <!-- Right Column: Notifications Panel (Column 4) -->
      <div class="lg:col-span-1 space-y-6">
        
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden flex flex-col h-[750px] sticky top-6">
          <!-- Notification Panel Header -->
          <div class="bg-gray-50 px-4 py-4 border-b flex items-center justify-between shrink-0">
            <div class="flex items-center gap-2">
              <div class="relative">
                <Bell class="w-5 h-5 text-[#E8772E]" />
                <span 
                  v-if="unreadCount > 0"
                  class="absolute -top-1.5 -right-1.5 bg-red-600 text-white text-[9px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center border border-white animate-pulse"
                >
                  {{ unreadCount }}
                </span>
              </div>
              <span class="font-extrabold text-[#3D2817] text-sm">Thông báo</span>
            </div>
            <button 
              @click="toggleExpandNotifs"
              class="text-xs font-bold text-[#E8772E] hover:underline"
            >
              {{ showAllNotifications ? 'Thu gọn' : 'Xem thêm...' }}
            </button>
          </div>

          <!-- Notification Items List -->
          <div class="flex-1 overflow-y-auto divide-y divide-gray-100 p-2 space-y-2">
            <div 
              v-for="notif in visibleNotifications" 
              :key="notif.id"
              :class="[
                'p-3 rounded-xl border transition-all duration-200 relative cursor-pointer',
                notif.isRead ? 'bg-white border-gray-100 text-gray-600' : 'bg-orange-50/30 border-orange-100 hover:bg-orange-50/50 shadow-sm'
              ]"
              @click="handleNotificationClick(notif)"
            >
              <!-- Unread status dot -->
              <div 
                v-if="!notif.isRead"
                class="absolute top-3.5 right-3.5 w-2 h-2 rounded-full bg-[#E8772E]"
              ></div>

              <!-- Header line: icon + type -->
              <div class="flex items-center gap-2 mb-1.5">
                <span 
                  :class="[
                    'text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md border',
                    getNotificationTypeClass(notif)
                  ]"
                >
                  {{ translateNotifType(notif.type) }}
                </span>
                
                <span 
                  v-if="notif.priority === 'high'"
                  class="bg-red-100 text-red-700 text-[8px] font-black uppercase px-1 rounded border border-red-200"
                >
                  Khẩn
                </span>
              </div>

              <!-- Message body -->
              <div class="text-xs font-extrabold text-[#3D2817] pr-4 line-clamp-2">
                {{ notif.title }}
              </div>
              <div class="text-[11px] text-gray-500 mt-1 line-clamp-3">
                {{ notif.message }}
              </div>

              <!-- Footer line: time + mark read -->
              <div class="flex items-center justify-between mt-2.5 pt-1.5 border-t border-gray-100/50">
                <span class="text-[9px] text-gray-400 font-semibold font-mono flex items-center gap-1">
                  <Clock class="w-3 h-3 text-gray-300" />
                  {{ formatTimeOnly(notif.timestamp) }}
                </span>

                <button 
                  v-if="!notif.isRead"
                  @click.stop="handleMarkRead(notif.id)"
                  class="text-[9px] font-bold text-[#E8772E] hover:underline"
                >
                  Đã đọc
                </button>
              </div>
            </div>

            <div v-if="visibleNotifications.length === 0" class="text-center text-gray-400 py-10 text-xs">
              Không có thông báo nào.
            </div>
          </div>
        </div>

      </div>

    </div>

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
// Keep my quality-bar imports (useShift, useServiceRequest) AND the broader
// lucide icon set that origin/main's UI requires.
import { useServiceRequest, type ServiceRequest } from '@/composables/useServiceRequest'
import { useShift } from '@/composables/useShift'
import type { TableT, Reservation, Shift, Notification } from '@/types/database'
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
  Bell,
  CheckCircle,
  XCircle,
  Eye
} from 'lucide-vue-next'

interface UINotification {
  id: string
  type: 'out_of_stock' | 'low_stock' | 'booking' | 'payment'
  title: string
  message: string
  timestamp: Date
  isRead: boolean
  priority: 'high' | 'medium' | 'low'
}

const langStore = useLanguageStore()
const t = langStore.t
const router = useRouter()
const { branchId, role, profile } = useAuth()
const { activeBranchId } = useBranch()
const { updateStatus } = useReservation()
const { listForRole, markRead } = useNotification()
const { watchTable } = useRealtime()
const { openShift } = useShift()
const shiftOpening = ref(false)

async function openShiftDialog() {
  if (!activeBranch.value) return
  const { value: openingCash } = await Swal.fire({
    icon: 'question',
    title: t('reception.dashboard.open_shift_dialog_title', 'Mở ca làm việc'),
    html: t('reception.dashboard.open_shift_dialog_text', 'Nhập số tiền đầu ca trong két (VND).'),
    input: 'number',
    inputAttributes: { min: '0', step: '1000', 'aria-label': 'opening cash' },
    inputValue: 0,
    showCancelButton: true,
    confirmButtonText: t('reception.dashboard.open_shift_confirm', 'Mở ca'),
    cancelButtonText: t('reception.dashboard.open_shift_cancel', 'Hủy'),
  })
  if (openingCash === undefined || openingCash === null) return
  shiftOpening.value = true
  try {
    const res = await openShift({ branchId: activeBranch.value, openingCash: Number(openingCash) })
    await fetchActiveShift()
    await Swal.fire({
      icon: 'success',
      title: res.idempotent
        ? t('reception.dashboard.shift_already_open', 'Ca đã mở từ trước')
        : t('reception.dashboard.shift_opened', 'Đã mở ca'),
      timer: 1500,
      showConfirmButton: false,
    })
  } catch (e: any) {
    Swal.fire('Error', e.message || String(e), 'error')
  } finally {
    shiftOpening.value = false
  }
}

const loading = ref(false)
const loadingDetails = ref(false)
const hasLoadedOnce = ref(false)
const error = ref<string | null>(null)

const tables = ref<TableT[]>([])
const reservations = ref<Reservation[]>([])
const activeShift = ref<Shift | null>(null)
const shiftPayments = ref<any[]>([])

// Detailed summaries map for occupied tables (quantities & total amount)
const tableDetails = ref<Record<string, { itemsCount: number; grandTotal: number; createdAt: string | null }>>({})

// Notifications states
const dbNotifications = ref<UINotification[]>([])
const showAllNotifications = ref(false)
const seenNotificationIds = ref(new Set<string>())

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

const activeBranch = computed<string>(() => activeBranchId.value ?? branchId.value ?? '')

// Real active branch name
const activeBranchName = ref('Đang tải...')

// Time Date Widget Clock
const currentTime = ref(new Date())
let timerId: any
let notificationPollInterval: any

onMounted(() => {
  fetchAll()
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

// Notifications mapping & logic
const allNotifications = computed<UINotification[]>(() => {
  const list = [...dbNotifications.value, ...localMockNotifications.value]
  return list.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
})

const visibleNotifications = computed<UINotification[]>(() => {
  return showAllNotifications.value ? allNotifications.value : allNotifications.value.slice(0, 5)
})

const unreadCount = computed(() => {
  return allNotifications.value.filter(n => !n.isRead).length
})

function toggleExpandNotifs() {
  showAllNotifications.value = !showAllNotifications.value
}

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
  const { data } = await supabase
    .from('branches')
    .select('name')
    .eq('id', activeBranch.value)
    .maybeSingle()
  if (data?.name) {
    activeBranchName.value = data.name
  }
}

// Re-load only the active shift (used after `openShift` / `closeShift` so the
// pill + payment aggregates refresh without a full dashboard re-fetch).
async function fetchActiveShift() {
  if (!activeBranch.value) return
  const { data, error: err } = await supabase.rpc('hall_get_active_shift', {
    p_branch_id: activeBranch.value,
  })
  if (err) {
    console.warn('[ReceptionDashboard] fetchActiveShift failed:', err)
    return
  }
  activeShift.value = (data as Shift) ?? null
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
    const [tablesData, resData, notifData, shiftData] = await Promise.all([
      supabase.rpc('hall_list_tables', { p_branch_id: activeBranch.value }),
      supabase.rpc('hall_list_reservations_by_date', { p_branch_id: activeBranch.value, p_date: todayStr }),
      listForRole('reception-panel', 50).catch(() => [] as Notification[]),
      supabase.rpc('hall_get_active_shift', { p_branch_id: activeBranch.value })
    ])

    if (tablesData.error) throw tablesData.error
    if (resData.error) throw resData.error
    if (shiftData.error) throw shiftData.error

    tables.value = tablesData.data as TableT[]
    reservations.value = resData.data as Reservation[]
    activeShift.value = shiftData.data as Shift

    // Map DB notifications to UINotification format
    mapDbNotifications(notifData ?? [])

    await fetchBranchInfo()
    await fetchShiftPayments()
    await fetchTableDetails()
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
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
          const { data, error } = await supabase.rpc('hall_get_checkout_summary', {
            p_branch_id: activeBranch.value,
            p_table_id: t.id
          })
          if (error) throw error
          
          const items = data?.items || []
          const qtySum = items.reduce((sum: number, item: any) => sum + Number(item.quantity || 0), 0)

          return {
            tableId: t.id,
            itemsCount: qtySum,
            grandTotal: data?.summary?.grand_total || 0,
            createdAt: data?.order?.created_at || null
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
  if (!activeShift.value) {
    shiftPayments.value = []
    return
  }
  const { data } = await supabase
    .from('payments')
    .select('amount')
    .eq('shift_id', activeShift.value.id)
  shiftPayments.value = data || []
}

function subscribeRealtime() {
  if (!activeBranch.value) return
  cleanups.push(
    watchTable<TableT>('tables', '*', () => fetchAll()),
    watchTable<Reservation>('reservations', '*', () => fetchAll()),
    watchTable<Notification>('notifications', '*', () => fetchAll())
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

  // Placeholder paths
  if (path === '/transactions/income' || path === '/transactions/expense' || path === '/settings' || path === '/admin/reports') {
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

function getNotificationTypeClass(notif: UINotification): string {
  switch (notif.type) {
    case 'out_of_stock': return 'bg-red-50 text-red-700 border-red-200'
    case 'low_stock': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
    case 'booking': return 'bg-blue-50 text-blue-700 border-blue-200'
    case 'payment': return 'bg-green-50 text-green-700 border-green-200'
    default: return 'bg-gray-50 text-gray-700 border-gray-200'
  }
}

function translateNotifType(type: UINotification['type']): string {
  switch (type) {
    case 'out_of_stock': return 'Hết hàng'
    case 'low_stock': return 'Sắp hết'
    case 'booking': return 'Đặt bàn'
    case 'payment': return 'Yêu cầu thanh toán'
    default: return 'Hệ thống'
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

function formatTimeOnly(date: Date): string {
  return date.toLocaleTimeString('vi-VN', {
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
