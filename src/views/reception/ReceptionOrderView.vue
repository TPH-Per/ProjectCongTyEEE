<!-- File: src/views/reception/ReceptionOrderView.vue -->
<template>
  <div class="h-screen w-screen flex overflow-hidden font-sans select-none text-gray-800 bg-[#f8f9fa] relative">
    
    <!-- SYSTEM TOAST QUEUE OVERLAY -->
    <div class="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none">
      <transition-group name="toast-list">
        <div 
          v-for="toast in toasts" 
          :key="toast.id"
          :class="[
            'p-4 rounded-xl shadow-lg border flex items-start gap-3 pointer-events-auto transition-all duration-300',
            toast.type === 'success' ? 'bg-[#e8f5e9] border-[#c8e6c9] text-[#2e7d32]' :
            toast.type === 'warning' ? 'bg-[#fff3e0] border-[#ffe0b2] text-[#e65100]' :
            toast.type === 'error' ? 'bg-[#ffebee] border-[#ffcdd2] text-[#c62828]' :
            'bg-[#e3f2fd] border-[#bbdefb] text-[#1565c0]'
          ]"
        >
          <span class="text-lg">
            <span v-if="toast.type === 'success'">✅</span>
            <span v-else-if="toast.type === 'warning'">⚠️</span>
            <span v-else-if="toast.type === 'error'">🚨</span>
            <span v-else>ℹ️</span>
          </span>
          <div class="flex-1">
            <p class="text-xs font-bold leading-tight">{{ toast.message }}</p>
          </div>
        </div>
      </transition-group>
    </div>

    <!-- IF NO TABLE IS SELECTED: Show direct access block screen -->
    <div v-if="!selectedTableCode" class="flex-1 flex flex-col items-center justify-center p-8 text-center bg-white border border-[#e0e0e0] rounded-xl m-6 shadow-sm">
      <div class="w-16 h-16 rounded-full bg-red-50 flex items-center justify-center text-3xl mb-4 text-[#c62828] animate-bounce">
        ⚠️
      </div>
      <h2 class="text-lg font-bold text-gray-900 tracking-tight">Quyền truy cập bị từ chối</h2>
      <p class="text-sm text-gray-500 font-medium max-w-sm mt-1 mb-6">
        Vui lòng chọn một bàn ăn đang mở từ Sơ đồ bàn trước khi thực hiện chọn món.
      </p>
      <router-link 
        to="/reception/floors" 
        class="px-5 py-3 bg-[#c62828] hover:bg-[#b71c1c] text-white font-bold text-xs rounded-lg shadow-sm transition-all active:scale-95 flex items-center gap-2"
      >
        <span>🗺️ Đi tới Sơ đồ bàn</span>
      </router-link>
    </div>

    <!-- ELSE: Show Order Management POS interface -->
    <div v-else class="flex-1 flex overflow-hidden min-h-0 relative">
      
      <!-- Sidebar trái (width 240px, fixed) -->
      <aside class="sidebar-pos">
        <!-- Logo area (cao 80px) -->
        <div class="sidebar-pos__logo">
          <div class="sidebar-pos__logo-icon">
            <span>🐮</span>
          </div>
          <div class="sidebar-pos__logo-text">
            <span class="sidebar-pos__logo-text-main">NGƯU CÁT</span>
            <span class="sidebar-pos__logo-text-sub">THU NGÂN POS</span>
          </div>
        </div>

        <!-- Navigation menu -->
        <nav class="sidebar-pos__nav">
          <div class="sidebar-pos__nav-section-label">HOẠT ĐỘNG</div>
          
          <router-link to="/reception/dashboard" class="sidebar-pos__nav-item">
            <span class="sidebar-pos__nav-item-icon">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
              </svg>
            </span>
            <span>Bảng điều khiển</span>
          </router-link>
          
          <router-link to="/reception/floors" class="sidebar-pos__nav-item">
            <span class="sidebar-pos__nav-item-icon">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M3 14h18m-9-4v8m-7 0h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </span>
            <span>Sơ đồ bàn</span>
          </router-link>
          
          <div class="sidebar-pos__nav-item sidebar-pos__nav-item--active">
            <span class="sidebar-pos__nav-item-icon">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </span>
            <span>Chọn món</span>
          </div>
          
          <router-link to="/reception/close-shift" class="sidebar-pos__nav-item">
            <span class="sidebar-pos__nav-item-icon">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </span>
            <span>Tổng Kết Ca</span>
          </router-link>
        </nav>

        <!-- Footer sidebar (fixed bottom) -->
        <div class="sidebar-pos__footer">
          <div class="sidebar-pos__footer-avatar">TN</div>
          <div class="sidebar-pos__footer-name">Thu Ngân 01</div>
        </div>
      </aside>

      <!-- Main Layout wrapper (contains header top and main content) -->
      <div class="flex-1 flex flex-col min-w-0">
        
        <!-- Header top (cao 60px, fixed style layout) -->
        <header class="header-pos">
          <div class="flex items-center gap-3">
            <h1 class="header-pos__title">Chọn món & Gọi đồ</h1>
            <span class="badge-pos badge-pos--secondary bg-[#f5f5f5] text-[#757575] text-[13px] py-1.5 px-3 rounded-full font-semibold">Chi nhánh 1</span>
          </div>

          <!-- Session settings configurations & Timer -->
          <div class="flex items-center gap-3">
            
            <!-- Timer countdown container -->
            <div class="flex items-center gap-2 bg-gray-50 border border-[#e0e0e0] px-3 py-1.5 rounded-lg text-xs font-semibold">
              <span class="text-gray-500 uppercase tracking-wide">Thời gian:</span>
              <span 
                :class="[
                  'font-mono font-bold px-1.5 py-0.5 rounded text-sm',
                  timerSecondsLeft <= 0 ? 'bg-red-100 text-red-700 animate-pulse' :
                  timerSecondsLeft < 600 ? 'bg-red-50 text-red-600 animate-pulse' :
                  'text-gray-800'
                ]"
              >
                🕒 {{ formattedTimeLeft }}
              </span>
            </div>

            <!-- Package selector display -->
            <div class="flex items-center gap-2 bg-gray-50 border border-[#e0e0e0] px-3 py-1.5 rounded-lg text-xs font-semibold">
              <span class="text-gray-500 uppercase tracking-wide">Course:</span>
              <span class="text-[#c62828] font-bold text-sm uppercase">🏆 {{ activeSettings.package || 'Chưa Chọn' }}</span>
              <button 
                @click="openSettingsConfig"
                class="ml-1 text-gray-400 hover:text-[#c62828] transition-colors"
                title="Thay đổi gói / thiết lập"
              >
                ⚙️
              </button>
            </div>
            
          </div>
        </header>

        <!-- DRINK GROUP WARNING TIMER EXPIRATION BANNER -->
        <transition name="fade">
          <div 
            v-if="timerSecondsLeft <= 0 && (activeSettings.drinkGroup === 'B' || activeSettings.drinkGroup === 'C')"
            class="absolute top-[60px] left-[240px] right-0 z-20 bg-[#fff3e0] border-b border-[#ffe0b2] text-[#e65100] px-6 py-2.5 text-xs font-bold flex items-center justify-between shadow-sm"
          >
            <div class="flex items-center gap-2">
              <span>⏰</span>
              <span>Thời gian đồ uống premium đã kết thúc. Chỉ có thể gọi nước ngọt nhóm A.</span>
            </div>
            <button @click="openPinModal" class="px-2.5 py-1 bg-[#e65100] text-white text-[10px] rounded hover:bg-[#d84315] font-bold">Mở khóa bằng mã PIN</button>
          </div>
        </transition>

        <!-- Main content area (margin top and left handled in CSS) -->
        <main class="main-content-pos">
          <div class="main-content-pos__grid">
            
            <!-- ─── Component Cart/Invoice Panel (Bên trái) ─── -->
            <div class="card-pos bg-white rounded-xl shadow-sm border border-[#e0e0e0] overflow-hidden min-h-[calc(100vh-108px)] flex flex-col justify-between">
              
              <!-- Section 1 - Header Card -->
              <div class="p-5 border-b border-[#f0f0f0]">
                <div class="flex flex-col gap-1">
                  <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider">MÃ HÓA ĐƠN</span>
                  <span class="text-[16px] font-bold text-gray-900 leading-none">{{ activeOrder.orderNumber || 'SF_00005290' }}</span>
                </div>
                <div class="flex justify-between items-center mt-3 pt-3 border-t border-[#f7f7f7]">
                  <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider">BÀN PHỤC VỤ</span>
                  <span class="badge-pos badge-pos--primary bg-[#ffebee] text-[#c62828] px-3 py-1 rounded-full font-bold text-[13px]">
                     {{ activeTableArea }} - {{ activeOrder.tableCode }}
                  </span>
                </div>
              </div>

              <!-- Section 2 - Customer Info -->
              <div class="p-5 border-b border-[#f0f0f0] bg-white">
                <div class="grid grid-cols-3 gap-4">
                  <div>
                    <span class="block text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-0.5">KHÁCH HÀNG</span>
                    <span class="block text-sm font-semibold text-gray-800 truncate">{{ activeOrder.customerName || 'Phạm Hùng' }}</span>
                  </div>
                  <div>
                    <span class="block text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-0.5">SỐ KHÁCH</span>
                    <span class="block text-sm font-semibold text-gray-800">{{ activeOrder.guestCount || 4 }} ghế</span>
                  </div>
                  <div>
                    <span class="block text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-0.5">GIỜ MỞ BÀN</span>
                    <span class="block text-sm font-semibold text-gray-800">{{ activeOrder.openedTime || '17:45' }}</span>
                  </div>
                </div>
              </div>

              <!-- Section 3 - Order Items -->
              <div class="flex-1 overflow-y-auto p-5 min-h-0 bg-white border-b border-[#f0f0f0] ordering-screen-scrollbar">
                
                <!-- EMPTY STATE -->
                <div v-if="activeOrder.items.length === 0" class="h-full flex flex-col items-center justify-center text-center text-gray-400 py-16">
                  <div class="w-16 h-16 rounded-full bg-gray-50 flex items-center justify-center text-3xl mb-3 text-gray-300">
                    🛒
                  </div>
                  <p class="text-xs font-bold text-gray-800">Chưa có món nào trong hóa đơn</p>
                  <p class="text-[10px] text-gray-400 mt-1 max-w-[200px] leading-relaxed">Hãy chọn món từ danh mục bên phải để bắt đầu order</p>
                </div>

                <!-- CARDS LIST -->
                <div v-else class="space-y-3">
                  <div 
                    v-for="item in activeOrder.items" 
                    :key="item.id"
                    class="p-4 border border-[#e0e0e0] rounded-lg bg-white flex flex-col justify-between"
                  >
                    <!-- Row 1: Tên món + Info icon -->
                    <div class="flex justify-between items-start">
                      <h4 class="font-bold text-[15px] text-gray-900 pr-3 leading-snug">
                        {{ item.name }}
                      </h4>
                      <button 
                        @click="openDetailPanel(getMenuItemFromCartItem(item))"
                        class="w-5 h-5 rounded-full hover:bg-gray-100 flex items-center justify-center text-gray-400 hover:text-[#c62828] transition-colors shrink-0"
                        title="Xem chi tiết"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </button>
                    </div>

                    <!-- Row 2: Đơn giá và thuế -->
                    <div class="text-[12px] text-gray-400 mt-1 font-medium">
                      {{ isItemInPackage(item, activeSettings.package) ? '0đ (Trong gói)' : formatVND(item.price) }} / {{ item.unit }} • Thuế: 10%
                    </div>

                    <!-- Row 3: Control Số lượng + Giá tiền + Xóa -->
                    <div class="flex justify-between items-center mt-3">
                      <!-- Controls số lượng -->
                      <div class="flex items-center gap-2 select-none">
                        <button 
                          @click="updateQty(item.id, -1)" 
                          class="w-8 h-8 rounded border border-[#e0e0e0] bg-white hover:bg-gray-50 text-gray-700 font-bold flex items-center justify-center transition-colors active:scale-95"
                        >
                          -
                        </button>
                        <span class="w-10 text-center font-bold text-base text-gray-900">
                          {{ item.quantity }}
                        </span>
                        <button 
                          @click="updateQty(item.id, 1)" 
                          :disabled="item.quantity >= 10"
                          :class="[
                            'w-8 h-8 rounded border border-[#e0e0e0] bg-white text-gray-700 font-bold flex items-center justify-center transition-colors active:scale-95',
                            item.quantity >= 10 ? 'opacity-40 cursor-not-allowed bg-gray-50' : 'hover:bg-gray-50'
                          ]"
                          :title="item.quantity >= 10 ? 'Đã đạt giới hạn 10 món/lượt' : ''"
                        >
                          +
                        </button>
                      </div>

                      <!-- Giá tiền và Xóa -->
                      <div class="flex items-center gap-4">
                        <span class="font-bold text-[16px] text-gray-950">
                          {{ isItemInPackage(item, activeSettings.package) ? '0đ' : formatVND(item.price * item.quantity) }}
                        </span>
                        <button 
                          @click="removeItem(item.id)" 
                          class="px-2 py-1 text-xs font-bold text-[#c62828] hover:bg-[#ffebee] rounded transition-colors"
                        >
                          XÓA
                        </button>
                      </div>
                    </div>

                  </div>
                </div>

              </div>

              <!-- Section 4 - Total Calculation -->
              <div class="bg-[#f8f9fa] border-t border-[#f0f0f0] p-5 text-sm font-medium text-[#757575] space-y-2">
                <div class="flex justify-between items-center">
                  <span>Tạm tính (Subtotal):</span>
                  <span class="text-gray-900 font-semibold">{{ formatVND(summary.subtotal) }}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span>Phí phục vụ (Service Charge 5%):</span>
                  <span class="text-gray-900 font-semibold">{{ formatVND(summary.serviceCharge) }}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span>Thuế GTGT (VAT 10%):</span>
                  <span class="text-gray-900 font-semibold">{{ formatVND(summary.vat) }}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span>Chiết khấu / Giảm giá (Discounts):</span>
                  <span class="text-[#2e7d32] font-semibold">-0đ</span>
                </div>
                
                <div class="border-t border-[#e0e0e0] my-2 pt-2"></div>
                
                <div class="flex justify-between items-center">
                  <span class="font-bold text-gray-950">TỔNG CỘNG (GRAND TOTAL):</span>
                  <span class="text-[20px] font-bold text-[#c62828]">{{ formatVND(summary.grandTotal) }}</span>
                </div>

                <!-- Footer buttons -->
                <div class="grid grid-cols-2 gap-3 pt-3">
                  <button 
                    @click="printDraftBill"
                    class="py-2.5 bg-white border border-[#e0e0e0] text-gray-700 text-xs font-bold rounded-lg hover:bg-gray-50 active:scale-95 transition-all"
                  >
                    Xem tạm tính 📑
                  </button>
                  <button 
                    @click="checkoutTable"
                    class="py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-lg shadow-sm active:scale-95 transition-all"
                  >
                    Thanh toán 💳
                  </button>
                </div>
              </div>

            </div>

            <!-- ─── Component Menu Selection Panel (Bên phải) ─── -->
            <div class="card-pos bg-white rounded-xl shadow-sm border border-[#e0e0e0] overflow-hidden min-h-[calc(100vh-108px)] flex flex-col justify-between">
              
              <!-- Section 1 - Search & Info Bar -->
              <div class="p-5 border-b border-[#f0f0f0] bg-white flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
                <!-- Search Box -->
                <div class="relative flex-1">
                  <span class="absolute inset-y-0 left-3.5 flex items-center text-gray-400 select-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                  </span>
                  <input 
                    type="text" 
                    placeholder="Tìm tên món ăn hoặc phân loại..."
                    v-model="searchQuery"
                    class="w-full bg-white border border-[#e0e0e0] rounded-lg pl-10 pr-10 py-2.5 text-sm font-medium text-gray-800 focus:outline-none focus:border-[#1976d2] focus:ring-1 focus:ring-[#1976d2] shadow-sm transition-all"
                  />
                  <button 
                    v-if="searchQuery"
                    @click="searchQuery = ''"
                    class="absolute inset-y-0 right-3.5 flex items-center text-gray-400 hover:text-gray-600 font-bold"
                  >
                    ✕
                  </button>
                </div>

                <div class="flex items-center gap-3 flex-wrap">
                  <!-- Toggle show only package items -->
                  <label 
                    v-if="activeSettings.package"
                    class="flex items-center gap-2 cursor-pointer select-none text-xs font-bold text-gray-700 bg-gray-50 border border-[#e0e0e0] px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    <input type="checkbox" v-model="showOnlyPackageItems" class="w-4 h-4 accent-[#c62828]" />
                    <span>Chỉ món trong gói (🏆 {{ activeSettings.package }})</span>
                  </label>

                  <!-- Table indicator Badge -->
                  <div class="badge-pos badge-pos--secondary bg-[#f5f5f5] text-[#757575] py-2.5 px-3 rounded-lg font-semibold text-xs whitespace-nowrap self-start md:self-auto">
                    BÀN ĐANG CHỌN: <span class="font-bold text-gray-900 ml-1">Khu A • Bàn {{ activeOrder.tableCode }}</span>
                  </div>
                </div>
              </div>

              <!-- Section 2 - Quick Filter Chips (dynamic categories subcategory filter) -->
              <div 
                v-if="activeCategoryHasSubcategories && activeSubcategoriesList.length > 0"
                class="px-5 py-4 border-b border-[#f0f0f0] bg-white overflow-x-auto scrollbar-none flex gap-2 select-none"
              >
                <button 
                  @click="activeSubCategoryId = 'all'"
                  :class="[
                    'chip-pos font-semibold text-[13px] tracking-wide whitespace-nowrap px-4 py-2 rounded-full border transition-all',
                    activeSubCategoryId === 'all'
                      ? 'chip-pos--active bg-[#c62828] text-white border-[#c62828] font-bold'
                      : 'bg-white border-[#e0e0e0] text-[#757575] hover:border-[#c62828] hover:text-[#c62828]'
                  ]"
                >
                  Tất cả
                </button>
                <button 
                  v-for="sub in activeSubcategoriesList"
                  :key="sub.id"
                  @click="activeSubCategoryId = sub.id"
                  :class="[
                    'chip-pos font-semibold text-[13px] tracking-wide whitespace-nowrap px-4 py-2 rounded-full border transition-all',
                    activeSubCategoryId === sub.id
                      ? 'chip-pos--active bg-[#c62828] text-white border-[#c62828] font-bold'
                      : 'bg-white border-[#e0e0e0] text-[#757575] hover:border-[#c62828] hover:text-[#c62828]'
                  ]"
                >
                  {{ sub.name }}
                </button>
              </div>

              <!-- Section 3 - Menu Grid (padding 20px, scrollable, cards height 140px) -->
              <div class="flex-1 overflow-y-auto p-5 bg-[#f8f9fa] min-h-0 ordering-screen-scrollbar">
                
                <!-- Loading State -->
                <div v-if="isGridLoading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  <div v-for="i in 6" :key="i" class="bg-white border border-[#e0e0e0] rounded-xl p-4 h-[140px] animate-pulse flex flex-col justify-between shadow-sm">
                    <div class="flex justify-between items-start">
                      <div class="h-3 bg-gray-200 rounded w-16"></div>
                      <div class="h-4 bg-gray-200 rounded-full w-4"></div>
                    </div>
                    <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                    <div class="flex justify-between items-end">
                      <div class="h-3 bg-gray-200 rounded w-8"></div>
                      <div class="h-4 bg-gray-200 rounded w-20"></div>
                    </div>
                  </div>
                </div>

                <!-- Products list -->
                <div v-else-if="finalFilteredItems.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  <div 
                    v-for="product in finalFilteredItems" 
                    :key="product.id"
                    @click="handleCardClick(product)"
                    class="menu-card-pos"
                  >
                    <!-- Category name & info click overlay -->
                    <div class="flex justify-between items-start select-none">
                      <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                        {{ translateCategoryId(product.category_id) }}
                      </span>
                      <button 
                        @click.stop="openDetailPanel(product)"
                        class="w-5 h-5 rounded-full hover:bg-gray-100 flex items-center justify-center text-gray-400 hover:text-[#c62828] transition-colors"
                        title="Thông tin chi tiết"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </button>
                    </div>

                    <!-- Name -->
                    <h4 
                      class="font-bold text-sm text-gray-900 mt-2 line-clamp-2 leading-tight flex-1"
                      v-html="highlightText(product.name, searchQuery)"
                    ></h4>

                    <!-- Unit -->
                    <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider mt-1">
                      {{ product.unit }}
                    </span>

                    <!-- Price -->
                    <div class="mt-auto pt-1 flex justify-between items-end select-none">
                      <span class="text-sm font-bold text-gray-900">
                        {{ activeSettings.package && isItemInPackage(product, activeSettings.package) ? '0đ' : formatVND(product.price) }}
                      </span>
                      <span 
                        v-if="getCartItemQty(product.id) > 0" 
                        class="bg-[#1976d2] text-white text-[10px] font-bold px-2 py-0.5 rounded"
                      >
                        {{ getCartItemQty(product.id) }} x
                      </span>
                    </div>

                  </div>
                </div>

                <!-- Empty Grid search state -->
                <div v-else class="h-full flex flex-col items-center justify-center text-center text-gray-400 py-16 select-none">
                  <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center text-3xl mb-3 text-gray-300">
                    🔍
                  </div>
                  <p class="text-xs font-bold text-gray-800">Không tìm thấy món ăn nào</p>
                  <p class="text-[10px] text-gray-400 mt-1 max-w-[220px] leading-relaxed">
                    Không khớp món nào cho từ khóa "{{ searchQuery }}".
                  </p>
                  <button 
                    @click="clearAllFilters"
                    class="mt-4 px-4 py-1.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-lg transition-all"
                  >
                    Reset Bộ lọc
                  </button>
                </div>

              </div>

              <!-- Section 4 - Category Tabs -->
              <div class="border-t border-[#f0f0f0] p-5 bg-white shrink-0 space-y-3">
                
                <!-- Group 1: Yellow Categories -->
                <div>
                  <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">VÉ & GÓI DỊCH VỤ:</div>
                  <div class="overflow-x-auto scrollbar-none flex gap-2 select-none">
                    <button 
                      v-for="cat in menuData.categories.filter(c => c.color === 'yellow')"
                      :key="cat.id"
                      @click="selectCategory(cat.id)"
                      :class="[
                        'flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all shrink-0 border whitespace-nowrap',
                        activeCategoryId === cat.id
                          ? 'bg-[#c62828] border-[#c62828] text-white font-bold shadow-sm'
                          : 'bg-white border-[#e0e0e0] text-gray-700 hover:border-[#c62828] hover:text-[#c62828]'
                      ]"
                    >
                      <span class="text-xs">🎟️</span>
                      <span>{{ cat.name }}</span>
                    </button>
                  </div>
                </div>

                <!-- Group 2: Pink Categories -->
                <div>
                  <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">THỰC ĐƠN GỌI MÓN:</div>
                  <div class="overflow-x-auto scrollbar-none flex gap-2 select-none">
                    <button 
                      v-for="cat in menuData.categories.filter(c => c.color === 'pink')"
                      :key="cat.id"
                      @click="selectCategory(cat.id)"
                      :class="[
                        'flex items-center gap-1.5 px-4 py-2.5 rounded-full text-xs font-semibold transition-all shrink-0 border whitespace-nowrap',
                        activeCategoryId === cat.id
                          ? 'bg-[#c62828] border-[#c62828] text-white font-bold shadow-sm'
                          : 'bg-white border-[#e0e0e0] text-gray-700 hover:border-[#c62828] hover:text-[#c62828]'
                      ]"
                    >
                      <span class="text-xs">
                        <span v-if="cat.id === 'buffet'">🏆</span>
                        <span v-else-if="cat.id === 'set_lunch'">🍱</span>
                        <span v-else-if="cat.id.includes('tiec_chieu_dai')">🏮</span>
                        <span v-else-if="cat.id === 'thuc_an'">🥩</span>
                        <span v-else-if="cat.id === 'thuc_uong'">🥤</span>
                        <span v-else-if="cat.id === 'thuc_uong_co_con'">🍺</span>
                        <span v-else>🍽️</span>
                      </span>
                      <span>{{ cat.name }}</span>
                    </button>
                  </div>
                </div>

              </div>

              <!-- Section 5 - Action Buttons -->
              <div class="p-5 border-t border-[#f0f0f0] bg-white flex justify-end gap-3 shrink-0">
                <button 
                  @click="cancelChanges"
                  class="btn-pos btn-pos--default hover:bg-gray-50 border border-[#e0e0e0] text-[#424242] px-5 py-2.5 rounded-lg text-sm transition-all"
                >
                  Hủy Thay Đổi
                </button>
                <button 
                  @click="holdOrder"
                  class="btn-pos btn-pos--warning bg-[#fff9c4] hover:bg-[#fff59d] text-[#f57f17] px-5 py-2.5 rounded-lg text-sm font-semibold transition-all"
                >
                  Tạm Lưu Đơn (Hold)
                </button>
                <button 
                  @click="sendToKitchen"
                  class="btn-pos btn-pos--secondary bg-[#1976d2] hover:bg-[#1565c0] text-white px-6 py-2.5 rounded-lg text-sm font-bold transition-all flex items-center gap-1.5 shadow-sm"
                >
                  <span>Gửi Vào Bếp</span>
                  <span>🍳</span>
                </button>
                <button 
                  @click="saveOrder"
                  class="btn-pos btn-pos--primary bg-[#c62828] hover:bg-[#b71c1c] text-white px-6 py-2.5 rounded-lg text-sm font-bold transition-all shadow-md"
                >
                  Lưu Gọi Món (Save)
                </button>
              </div>

            </div>

          </div>
        </main>

      </div>

      <!-- VUNG 3: CENTERED POPUP DETAIL MODAL (SIMPLE / COMPLEX ROUTER) -->
      <transition name="fade">
        <div v-if="isDetailPanelOpen && selectedProductForDetail" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-950/60 backdrop-blur-xs select-none">
          
          <!-- Dark overlay background clicks to close -->
          <div class="fixed inset-0" @click="isDetailPanelOpen = false"></div>
          
          <!-- Centered Container (Width 700-800px) -->
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col relative z-10 animate-scale-up border border-[#e0e0e0]">
            
            <!-- Header Modal with Clean Colors -->
            <header class="bg-gradient-to-r from-[#1976d2] to-[#1565c0] text-white px-6 py-4 flex justify-between items-center shrink-0">
              <h3 class="text-base font-bold tracking-tight select-none">ℹ️ Chi tiết món ăn</h3>
              <button 
                @click="isDetailPanelOpen = false"
                class="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center font-bold text-sm transition-all select-none active:scale-90"
              >
                ✕
              </button>
            </header>

            <!-- Body Area (Padding 24px) -->
            <div class="p-6 overflow-y-auto flex-1 min-h-0">
              
              <!-- ─── CASE A: SIMPLE ITEM DETAIL MODAL ─── -->
              <div v-if="tempOptionGroups.length === 0" class="grid grid-cols-1 md:grid-cols-10 gap-6">
                <!-- Column Left (40% width -> 4 cols) -->
                <div class="md:col-span-4 flex flex-col items-center gap-4">
                  <div class="w-full h-52 bg-gray-100 border border-[#e0e0e0] rounded-xl flex items-center justify-center text-6xl relative overflow-hidden select-none">
                    {{ getEnrichedItem(selectedProductForDetail).emoji }}
                    
                    <span 
                      v-if="!getEnrichedItem(selectedProductForDetail).isAvailable"
                      class="absolute inset-0 bg-red-950/20 backdrop-blur-xs flex items-center justify-center font-black text-white text-xs uppercase"
                    >
                      Hết hàng
                    </span>
                  </div>
                  
                  <span 
                    :class="[
                      'w-full py-1 text-center font-bold text-[10px] uppercase rounded-lg tracking-wider border',
                      getEnrichedItem(selectedProductForDetail).isAvailable ? 'bg-emerald-50 text-emerald-700 border-emerald-150' : 'bg-red-50 text-red-700 border-red-150'
                    ]"
                  >
                    ● {{ getEnrichedItem(selectedProductForDetail).isAvailable ? 'Còn hàng phục vụ' : 'Hết hàng' }}
                  </span>
                </div>

                <!-- Column Right (60% width -> 6 cols) -->
                <div class="md:col-span-6 space-y-4 font-bold text-xs text-gray-700">
                  <div class="space-y-1">
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Tên món</label>
                    <input 
                      type="text" 
                      :value="selectedProductForDetail.name" 
                      readonly 
                      class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                    />
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Mã món</label>
                      <input 
                        type="text" 
                        :value="selectedProductForDetail.id" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-mono text-gray-800 focus:outline-none"
                      />
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Đơn vị tính</label>
                      <input 
                        type="text" 
                        :value="selectedProductForDetail.unit" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <!-- Qty Editor -->
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Số lượng</label>
                      <div class="flex items-center gap-2">
                        <button 
                          @click="modalItemQty = Math.max(1, modalItemQty - 1)" 
                          :disabled="modalItemQty <= 1"
                          class="w-9 h-9 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700 disabled:opacity-40"
                        >
                          -
                        </button>
                        <span class="w-8 text-center font-bold text-base text-gray-900">{{ modalItemQty }}</span>
                        <button 
                          @click="modalItemQty = Math.min(10, modalItemQty + 1)" 
                          :disabled="modalItemQty >= 10"
                          class="w-9 h-9 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700 disabled:opacity-40"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Đơn giá (VNĐ)</label>
                      <input 
                        type="text" 
                        :value="isItemInPackage(selectedProductForDetail, activeSettings.package) ? '0đ (Trong gói)' : formatVND(selectedProductForDetail.price)" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT and Service charges (VAT default checked, Service unchecked) -->
                  <div class="flex items-center gap-6 py-1 select-none text-[#c62828]">
                    <label class="flex items-center gap-2 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalVAT" class="w-4 h-4 accent-[#1976d2]" />
                      Bao gồm VAT (%)
                    </label>
                    <label class="flex items-center gap-2 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalPPV" class="w-4 h-4 accent-[#1976d2]" />
                      Bao gồm PPV (%)
                    </label>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Loại tiền tệ</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-[#e0e0e0] rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none">
                        <option value="VND">VND (Việt Nam Đồng)</option>
                        <option value="USD">USD (Đô la Mỹ)</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Tỷ giá</label>
                      <input 
                        type="text" 
                        v-model="modalRate" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Ghi chú</label>
                    <textarea 
                      v-model="modalItemNote" 
                      placeholder="Thêm ghi chú đặc thù (ít đá, nhiều nước, không hành...)..." 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2.5 font-bold text-gray-850 h-20 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>
                </div>
              </div>

              <!-- ─── CASE B: COMPLEX ITEM OPTIONS DETAIL MODAL ─── -->
              <div v-else class="grid grid-cols-1 md:grid-cols-10 gap-6">
                <!-- Column Left (45% width -> 4.5 cols) -->
                <div class="md:col-span-4 space-y-4 font-bold text-xs text-gray-700">
                  <div class="w-full h-44 bg-gray-100 border border-[#e0e0e0] rounded-xl flex items-center justify-center text-6xl relative overflow-hidden select-none">
                    {{ getEnrichedItem(selectedProductForDetail).emoji }}
                  </div>

                  <div class="space-y-1 leading-tight">
                    <h3 class="text-base font-bold text-gray-900 leading-tight">
                      {{ selectedProductForDetail.name }}
                    </h3>
                    <p class="text-[10px] text-gray-400 font-bold uppercase mt-0.5">
                      Mã: {{ selectedProductForDetail.id }} • Đơn vị: {{ selectedProductForDetail.unit }}
                    </p>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <!-- Qty editor -->
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Số lượng</label>
                      <div class="flex items-center gap-1">
                        <button 
                          @click="modalItemQty = Math.max(1, modalItemQty - 1)" 
                          :disabled="modalItemQty <= 1"
                          class="w-7 h-7 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700"
                        >
                          -
                        </button>
                        <span class="w-6 text-center font-bold text-sm text-gray-900">{{ modalItemQty }}</span>
                        <button 
                          @click="modalItemQty = Math.min(10, modalItemQty + 1)" 
                          :disabled="modalItemQty >= 10"
                          class="w-7 h-7 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Đơn giá (VNĐ)</label>
                      <input 
                        type="text" 
                        :value="isItemInPackage(selectedProductForDetail, activeSettings.package) ? '0đ (Trong gói)' : formatVND(selectedProductForDetail.price)" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2.5 py-1.5 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT/PPV checks -->
                  <div class="flex items-center gap-3.5 select-none text-[#c62828] text-[11px]">
                    <label class="flex items-center gap-1 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalVAT" class="w-3.5 h-3.5 accent-[#1976d2]" />
                      VAT (%)
                    </label>
                    <label class="flex items-center gap-1 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalPPV" class="w-3.5 h-3.5 accent-[#1976d2]" />
                      PPV (%)
                    </label>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Tiền tệ</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none text-[11px]">
                        <option value="VND">VND</option>
                        <option value="USD">USD</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Tỷ giá</label>
                      <input type="text" v-model="modalRate" readonly class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none" />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Ghi chú chung</label>
                    <textarea 
                      v-model="modalItemNote" 
                      placeholder="Thêm ghi chú cho cả món ăn..." 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2 font-bold text-gray-850 h-16 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>
                </div>

                <!-- Column Right (55% width -> 5.5 cols) -->
                <div class="md:col-span-6 flex flex-col border border-[#e0e0e0] rounded-xl overflow-hidden min-h-0 bg-white shadow-sm">
                  
                  <!-- Option Group Tabs -->
                  <div class="flex bg-gray-50 border-b border-[#e0e0e0] overflow-x-auto scrollbar-none select-none">
                    <button 
                      v-for="group in tempOptionGroups"
                      :key="group.id"
                      @click="activeOptionTab = group.id"
                      :class="[
                        'px-4 py-2.5 text-xs font-bold transition-all border-r shrink-0',
                        activeOptionTab === group.id 
                          ? 'bg-white text-[#ff8f00] border-b-2 border-b-[#ff8f00]' 
                          : 'text-gray-400 hover:bg-gray-105'
                      ]"
                    >
                      {{ group.title }}
                    </button>
                  </div>

                  <!-- Options list container -->
                  <div v-if="activeGroup" class="flex-1 flex flex-col min-h-0 justify-between">
                    
                    <!-- Header Group selection metrics -->
                    <div class="p-3 border-b border-[#f0f0f0] flex justify-between items-center bg-gray-50/50 select-none">
                      <div>
                        <h5 class="text-xs font-bold text-gray-900 uppercase tracking-wide">{{ activeGroup.title }}</h5>
                        <p class="text-[10px] text-[#ff8f00] font-bold mt-0.5">
                          (Tối thiểu {{ activeGroup.minSelection }} - Tối đa {{ activeGroup.maxSelection }})
                        </p>
                      </div>
                      <span class="text-[10px] font-bold bg-[#1976d2] text-white px-2 py-0.5 rounded-full shadow-sm font-mono">
                        {{ activeGroupSelectedCount }} / {{ activeGroup.maxSelection }}
                      </span>
                    </div>

                    <!-- Scrollable items options list -->
                    <div class="flex-1 overflow-y-auto p-3 max-h-[300px] divide-y divide-[#f0f0f0] scrollbar-custom bg-white">
                      
                      <div 
                        v-for="option in activeGroup.options"
                        :key="option.id"
                        class="py-3 flex flex-col gap-2 transition-all hover:bg-gray-50/50"
                      >
                        <!-- Top option descriptor row -->
                        <div class="flex items-center justify-between gap-2">
                          <div class="flex-1">
                            <span class="font-bold text-xs text-gray-800">{{ option.name }}</span>
                            <span v-if="option.price > 0" class="text-[10px] text-gray-400 ml-1.5 font-mono">
                              (+{{ formatVND(option.price) }})
                            </span>
                          </div>

                          <!-- Options counters / select buttons -->
                          <div class="shrink-0">
                            <!-- Select button if quantity is 0 -->
                            <button 
                              v-if="option.quantity === 0"
                              @click="addOptionQty(option)"
                              class="w-7 h-7 rounded-lg bg-[#2e7d32] hover:bg-[#1b5e20] text-white flex items-center justify-center font-bold text-base shadow-sm active:scale-95 transition-all"
                            >
                              +
                            </button>
                            
                            <!-- Editor controls if quantity is > 0 -->
                            <div v-else class="flex items-center gap-1 bg-gray-50 border border-[#e0e0e0] rounded-lg p-0.5 select-none animate-scale-up">
                              <button 
                                @click="subtractOptionQty(option)"
                                class="w-6 h-6 rounded bg-white border border-[#e0e0e0] flex items-center justify-center font-bold text-gray-600 active:scale-90"
                              >
                                -
                              </button>
                              <span class="w-5 text-center font-bold text-gray-800 text-xs">{{ option.quantity }}</span>
                              <button 
                                @click="addOptionQty(option)"
                                :disabled="activeGroupSelectedCount >= activeGroup.maxSelection"
                                class="w-6 h-6 rounded bg-white border border-[#e0e0e0] flex items-center justify-center font-bold text-gray-600 active:scale-90 disabled:opacity-40"
                              >
                                +
                              </button>
                            </div>
                          </div>
                        </div>

                        <!-- Notes text input for this option row -->
                        <transition name="fade">
                          <div v-if="option.quantity > 0" class="w-full">
                            <input 
                              type="text" 
                              v-model="option.note"
                              placeholder="Thêm ghi chú riêng cho lựa chọn này (ví dụ: Không hành, Ít cay...)..."
                              class="w-full bg-white border border-[#e0e0e0] rounded-lg px-2.5 py-1.5 text-[11px] font-semibold text-gray-800 focus:outline-none focus:border-[#ff8f00]"
                            />
                          </div>
                        </transition>

                      </div>

                    </div>

                    <!-- Alert Indicator Validation Bar -->
                    <div 
                      :class="[
                        'p-3 border-t text-[11px] font-bold flex items-center gap-2 select-none shrink-0 border-[#f0f0f0]',
                        activeGroupSelectedCount < activeGroup.minSelection ? 'bg-[#fff3e0] text-[#e65100]' :
                        activeGroupSelectedCount > activeGroup.maxSelection ? 'bg-[#ffebee] text-[#c62828]' :
                        'bg-[#e8f5e9] text-[#2e7d32]'
                      ]"
                    >
                      <span class="text-xs">
                        <span v-if="activeGroupSelectedCount < activeGroup.minSelection">⚠️</span>
                        <span v-else-if="activeGroupSelectedCount > activeGroup.maxSelection">🚨</span>
                        <span v-else>✅</span>
                      </span>
                      <span v-if="activeGroupSelectedCount < activeGroup.minSelection">
                        Vui lòng chọn thêm ít nhất {{ activeGroup.minSelection - activeGroupSelectedCount }} lựa chọn nữa
                      </span>
                      <span v-else-if="activeGroupSelectedCount > activeGroup.maxSelection">
                        Đã vượt quá giới hạn tối đa cho phép {{ activeGroup.maxSelection }} lựa chọn
                      </span>
                      <span v-else>
                        Đã chọn đủ số lượng yêu cầu cho nhóm {{ activeGroup.title }}
                      </span>
                    </div>

                  </div>
                </div>
              </div>

            </div>

            <!-- Separated Footer Area -->
            <footer class="p-4 border-t border-[#f0f0f0] bg-white flex justify-end gap-3 shrink-0 select-none">
              <button 
                @click="isDetailPanelOpen = false"
                class="px-5 py-2.5 bg-[#f5f5f5] hover:bg-[#e0e0e0] border border-[#e0e0e0] text-gray-700 text-xs font-bold rounded-xl active:scale-95 transition-all"
              >
                Hủy bỏ (Esc)
              </button>
              
              <button 
                @click="saveDetailPanelQty"
                :disabled="!getEnrichedItem(selectedProductForDetail).isAvailable || !isSelectionValid"
                :class="[
                  'px-6 py-2.5 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 flex items-center gap-1.5',
                  (getEnrichedItem(selectedProductForDetail).isAvailable && isSelectionValid) ? 'bg-[#2e7d32] hover:bg-[#1b5e20]' : 'bg-gray-400 cursor-not-allowed opacity-50'
                ]"
              >
                <span>➕</span>
                <span>Thêm Vào Giỏ Hàng</span>
              </button>
            </footer>

          </div>

        </div>
      </transition>

      <!-- COURSE CONFIGURATOR / PACKAGE SELECTOR MODAL OVERLAY -->
      <div 
        v-if="isPackageModalOpen || !activeSettings.package" 
        class="fixed inset-0 z-40 flex items-center justify-center p-4 bg-gray-950/60 backdrop-blur-sm animate-fade-in"
      >
        <div class="bg-white border border-[#e0e0e0] rounded-2xl w-full max-w-2xl shadow-2xl p-6 relative animate-scale-up max-h-[90vh] overflow-y-auto scrollbar-thin">
          
          <!-- Close button if package already exists -->
          <button 
            v-if="activeSettings.package"
            @click="cancelPackageSelection"
            class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 flex items-center justify-center text-sm font-bold active:scale-90 select-none border border-gray-150"
          >
            ✕
          </button>

          <h3 class="text-[17px] font-bold text-gray-900 tracking-tight mb-4 flex items-center gap-2 select-none border-b border-[#f0f0f0] pb-3">
            <span>🏆</span> 
            <span>Cấu hình Gói Course Phục Vụ cho Bàn {{ activeOrder.tableCode }}</span>
          </h3>

          <!-- PACKAGE GRID (2 cols) -->
          <div class="mb-4">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2.5 select-none">1. Chọn Gói Ăn Phục Vụ (Course Pack):</h4>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 select-none">
              <div 
                v-for="(price, name) in packagePrices" 
                :key="name"
                @click="selectPackageOption(name)"
                :class="[
                  'p-3.5 rounded-xl border-2 transition-all cursor-pointer flex flex-col justify-between min-h-[95px] relative',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.package === name 
                    ? 'border-[#c62828] bg-red-50/10 shadow-sm' 
                    : 'border-gray-200 hover:border-red-300 hover:bg-gray-50/50'
                ]"
              >
                <!-- Popular tag -->
                <span 
                  v-if="name === 'Buffet 1390' || name === 'Buffet 680'" 
                  class="absolute top-2.5 right-2.5 bg-[#ff8f00] text-white text-[8px] font-bold uppercase px-1.5 py-0.5 rounded"
                >
                  Best
                </span>

                <div>
                  <h5 class="text-sm font-bold text-gray-900 leading-tight">{{ name }}</h5>
                  <p class="text-[10px] text-gray-400 font-semibold mt-1">
                    {{ name.includes('Buffet') ? 'Thời lượng phục vụ 2 tiếng tiêu chuẩn' : 'Menu gọi theo bữa tiệc chọn lọc' }}
                  </p>
                </div>
                <div class="text-right border-t border-[#f0f0f0] pt-2 mt-3">
                  <span class="text-sm font-bold text-[#c62828]">{{ price.toLocaleString('vi-VN') }}đ / Vé</span>
                </div>
              </div>
            </div>
          </div>

          <!-- DRINK GROUP SELECTOR CARDS -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">2. Chọn Nhóm Đồ Uống Kèm Theo (Drink Group):</h4>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 select-none">
              
              <div 
                @click="selectDrinkOption('A')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.drinkGroup === 'A' ? 'border-[#ff8f00] bg-amber-50/10' : 'border-gray-200 hover:bg-gray-50/50'
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🥤</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">Nhóm A - Soft Drink</h6>
                    <p class="text-[9px] text-gray-400 font-medium">Nước ngọt uống không giới hạn (Free)</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-305 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'A' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

              <div 
                @click="selectDrinkOption('B')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.drinkGroup === 'B' ? 'border-[#ff8f00] bg-amber-50/10' : 'border-gray-200 hover:bg-gray-50/50'
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍺</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">Nhóm B - Premium Drink</h6>
                    <p class="text-[9px] text-gray-400 font-medium">Rượu bia cao cấp uống trong 2 giờ (Free)</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-305 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'B' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

              <div 
                @click="selectDrinkOption('C')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.drinkGroup === 'C' ? 'border-[#ff8f00] bg-amber-50/10' : 'border-gray-200 hover:bg-gray-50/50'
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍶</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">Nhóm C - Premium Alt</h6>
                    <p class="text-[9px] text-gray-400 font-medium">Rượu bia thay thế dùng 2 giờ (Free)</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-305 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'C' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

              <div 
                @click="selectDrinkOption('D')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.drinkGroup === 'D' ? 'border-[#ff8f00] bg-amber-50/10' : 'border-gray-200 hover:bg-gray-50/50'
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍷</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">Nhóm D - A La Carte</h6>
                    <p class="text-[9px] text-gray-400 font-medium">Gọi đồ uống lẻ tính tiền riêng lẻ</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-305 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'D' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

            </div>
          </div>

          <!-- LANGUAGES CHOICE -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">3. Ngôn ngữ Giao diện hiển thị trên Máy tính bảng:</h4>
            <div class="flex flex-wrap gap-2 select-none">
              <button 
                v-for="lang in ['VI', 'EN', 'JP', 'KO', 'ZH']"
                :key="lang"
                @click="tempSettings.language = lang"
                :class="[
                  'px-4 py-2 rounded-xl text-xs font-bold transition-all border shrink-0',
                  activeSettings.isLocked ? 'pointer-events-none opacity-60 bg-gray-50' : '',
                  tempSettings.language === lang 
                    ? 'bg-[#1976d2] border-[#1976d2] text-white shadow-sm font-semibold' 
                    : 'bg-gray-50 border-gray-200 text-gray-600 hover:bg-gray-100'
                ]"
              >
                <span v-if="lang === 'VI'">🇻🇳 Tiếng Việt</span>
                <span v-else-if="lang === 'EN'">🇺🇸 English</span>
                <span v-else-if="lang === 'JP'">🇯🇵 日本語</span>
                <span v-else-if="lang === 'KO'">🇰🇷 한국어</span>
                <span v-else>🇨🇳 中文</span>
              </button>
            </div>
          </div>

          <!-- Actions Buttons footer -->
          <div class="flex gap-3 border-t border-[#f0f0f0] pt-4 mt-4">
            <button 
              @click="cancelPackageSelection"
              class="flex-1 py-2.5 bg-gray-50 border border-[#e0e0e0] hover:bg-gray-100 text-gray-700 text-xs font-bold rounded-xl transition-all"
            >
              Hủy bỏ / Quay lại
            </button>
            
            <button 
              v-if="activeSettings.isLocked"
              @click="openPinModal"
              class="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >
              🔓 Nhập mã PIN sửa cấu hình
            </button>
            <button 
              v-else
              @click="confirmPackageSelection"
              class="flex-1 py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >
              🔒 Xác nhận & Khóa Course
            </button>
          </div>

        </div>
      </div>

      <!-- MANAGER PIN PAD UNLOCK MODAL -->
      <div 
        v-if="isPinModalOpen" 
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-950/70 backdrop-blur-xs animate-fade-in"
      >
        <div class="bg-white border border-[#e0e0e0] rounded-2xl w-full max-w-xs shadow-2xl p-6 text-center animate-scale-up relative">
          
          <button 
            @click="isPinModalOpen = false"
            class="absolute top-4 right-4 w-7 h-7 rounded-full bg-gray-100 hover:bg-gray-250 text-gray-500 flex items-center justify-center text-xs font-bold"
          >
            ✕
          </button>

          <span class="text-3xl block mb-2">🔐</span>
          <h4 class="text-sm font-bold text-gray-900 mb-1">Mã PIN xác thực Quản lý</h4>
          <p class="text-[10px] text-gray-400 font-semibold mb-4 leading-normal">
            Nhập mã PIN của Quản lý để mở khóa sửa đổi cấu hình gói Course ăn uống.
          </p>

          <!-- Input dots -->
          <div class="flex justify-center gap-3.5 mb-5 select-none">
            <div 
              v-for="i in 4" 
              :key="i"
              :class="[
                'w-4 h-4 rounded-full border transition-all duration-100',
                enteredPin.length >= i ? 'bg-red-650 border-red-700 scale-110 shadow-sm' : 'bg-gray-105 border-gray-300'
              ]"
            ></div>
          </div>

          <!-- PIN Pad Grid -->
          <div class="grid grid-cols-3 gap-2.5 select-none mb-4 max-w-[220px] mx-auto">
            <button 
              v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]" 
              :key="num"
              @click="enterPinDigit(String(num))"
              class="w-12 h-12 rounded-2xl bg-gray-50 hover:bg-gray-200 border border-gray-200 text-base font-bold text-gray-800 flex items-center justify-center active:scale-90 transition-all shadow-xs"
            >
              {{ num }}
            </button>
            <button 
              @click="clearLastPinDigit"
              class="w-12 h-12 rounded-2xl bg-amber-50 hover:bg-amber-100 border border-amber-200 text-[10px] font-bold text-amber-700 flex items-center justify-center active:scale-90 transition-all"
            >
              ⌫
            </button>
            <button 
              @click="enterPinDigit('0')"
              class="w-12 h-12 rounded-2xl bg-gray-50 hover:bg-gray-200 border border-gray-200 text-base font-bold text-gray-800 flex items-center justify-center active:scale-90 transition-all"
            >
              0
            </button>
            <button 
              @click="enteredPin = ''"
              class="w-12 h-12 rounded-2xl bg-red-50 hover:bg-red-100 border border-red-100 text-[10px] font-bold text-red-700 flex items-center justify-center active:scale-90 transition-all"
            >
              C
            </button>
          </div>

        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useRestaurantStore } from '@/stores/restaurantStore';
import { storeToRefs } from 'pinia';
import { menuData, type MenuItem } from '@/data/menuData';

const router = useRouter();
const restaurantStore = useRestaurantStore();
const { selectedTableCode } = storeToRefs(restaurantStore);

function getMenuItemFromCartItem(item: any): MenuItem {
  for (const cat of menuData.categories) {
    if (cat.items) {
      const match = cat.items.find(i => i.id === item.id);
      if (match) return match;
    }
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        const match = sub.items.find(i => i.id === item.id);
        if (match) return match;
      }
    }
  }
  return {
    id: item.id,
    name: item.name.split(' [')[0],
    unit: item.unit || 'Vé',
    price: item.price,
    price_display: formatVND(item.price),
    category_id: item.category_id || ''
  };
}

// Multilingual translations map
const uiTranslations = {
  VI: {
    table: 'Bàn',
    guests: 'Khách',
    time: 'Giờ mở',
    timeLeft: 'còn lại',
    subtotal: 'Tạm tính',
    vat: 'Thuế GTGT (10%)',
    serviceCharge: 'Phí phục vụ',
    grandTotal: 'TỔNG CỘNG',
    checkout: 'Thanh toán',
    draftPrint: 'Xem tạm tính',
    emptyCart: 'Giỏ hàng trống',
    emptyCartSub: 'Hãy chọn món từ menu bên phải để bắt đầu order',
    outOfStock: 'Hết hàng',
    favorites: 'Món yêu thích',
    recent: 'Mới gọi',
    popular: 'Bán chạy',
    searchPlaceholder: 'Tìm món ăn theo tên hoặc phân loại...',
    available: 'Còn hàng',
    unavailable: 'Hết hàng',
    all: 'Tất cả',
    back: 'Quay lại',
    saveOrder: 'Lưu thay đổi',
    holdOrder: 'Tạm lưu',
    sendKitchen: 'Gửi vào bếp',
    cancelChanges: 'Hủy thay đổi',
    courseLocked: 'Khóa Course'
  },
  EN: {
    table: 'Table',
    guests: 'Guests',
    time: 'Open Time',
    timeLeft: 'remaining',
    subtotal: 'Subtotal',
    vat: 'VAT (10%)',
    serviceCharge: 'Service Charge',
    grandTotal: 'GRAND TOTAL',
    checkout: 'Checkout',
    draftPrint: 'Draft Bill',
    emptyCart: 'Cart is empty',
    emptyCartSub: 'Select items from the menu to start ordering',
    outOfStock: 'Sold Out',
    favorites: 'Favorites',
    recent: 'Recent',
    popular: 'Popular',
    searchPlaceholder: 'Search items by name...',
    available: 'Available',
    unavailable: 'Sold Out',
    all: 'All',
    back: 'Back',
    saveOrder: 'Save Order',
    holdOrder: 'Hold',
    sendKitchen: 'Send to Kitchen',
    cancelChanges: 'Cancel Changes',
    courseLocked: 'Course Locked'
  },
  JP: {
    table: 'テーブル',
    guests: '人数',
    time: '開始時間',
    timeLeft: '残り時間',
    subtotal: '小計',
    vat: '消費税 (10%)',
    serviceCharge: 'サービス料',
    grandTotal: '合計金額',
    checkout: 'お会計',
    draftPrint: '計算書印刷',
    emptyCart: 'カートは空です',
    emptyCartSub: 'メニューから商品を選択してください',
    outOfStock: '売り切れ',
    favorites: 'お気に入り',
    recent: '履歴',
    popular: '人気メニュー',
    searchPlaceholder: 'メニュー検索...',
    available: '注文可能',
    unavailable: '売り切れ',
    all: '全て',
    back: '戻る',
    saveOrder: '注文保存',
    holdOrder: '一時保留',
    sendKitchen: '厨房へ送信',
    cancelChanges: '変更取消',
    courseLocked: 'コースロック'
  },
  KO: {
    table: '테이블',
    guests: '인원수',
    time: '시작 시간',
    timeLeft: '남은 시간',
    subtotal: '소계',
    vat: '부가세 (10%)',
    serviceCharge: '봉사료',
    grandTotal: '총합계',
    checkout: '결제하기',
    draftPrint: '가영수증',
    emptyCart: '장바구니가 비어 있습니다',
    emptyCartSub: '오른쪽 메뉴에서 품목을 선택하십시오',
    outOfStock: '품절',
    favorites: '즐겨찾기',
    recent: '최근 주문',
    popular: '인기 메뉴',
    searchPlaceholder: '메뉴 검색...',
    available: '주문 가능',
    unavailable: '품절',
    all: '전체',
    back: '이전',
    saveOrder: '주문 저장',
    holdOrder: '보류',
    sendKitchen: '주방으로 전송',
    cancelChanges: '변경 취소',
    courseLocked: '코스 잠금'
  },
  ZH: {
    table: '桌号',
    guests: '人数',
    time: '开台时间',
    timeLeft: '剩余时间',
    subtotal: '小计',
    vat: '增值税 (10%)',
    serviceCharge: '服务费',
    grandTotal: '总金额',
    checkout: '结账',
    draftPrint: '预结单',
    emptyCart: '购物车为空',
    emptyCartSub: '请从右侧菜单中选择菜品',
    outOfStock: '售罄',
    favorites: '收藏夹',
    recent: '最近点餐',
    popular: '热销推荐',
    searchPlaceholder: '搜索菜品...',
    available: '有货',
    unavailable: '售罄',
    all: '全部',
    back: '返回',
    saveOrder: '保存订单',
    holdOrder: '挂单',
    sendKitchen: '传菜下厨',
    cancelChanges: '取消修改',
    courseLocked: '已锁套餐'
  }
};

// Course package pricing scaling
const packagePrices: Record<string, number> = {
  'Buffet 1390': 1380000,
  'Buffet 1150': 1150000,
  'Buffet 680': 680000,
  'Buffet 490': 490000,
  'Buffet 380': 380000,
  'Biz 1200': 1200000,
  'Biz 900': 900000,
  'Biz 700': 700000,
  'Kids Meal': 150000
};

// Persistent session table course settings dictionary
const tableSettings = ref<Record<string, { package: string; drinkGroup: string; language: string; isLocked: boolean }>>({});

const activeSettings = computed(() => {
  const code = selectedTableCode.value;
  if (!code) return { package: '', drinkGroup: 'A', language: 'VI', isLocked: false };
  if (!tableSettings.value[code]) {
    tableSettings.value[code] = {
      package: '',
      drinkGroup: 'A',
      language: 'VI',
      isLocked: false
    };
  }
  return tableSettings.value[code];
});

// Translation reactive reference
const t = computed(() => {
  const lang = activeSettings.value.language || 'VI';
  return uiTranslations[lang as keyof typeof uiTranslations] || uiTranslations.VI;
});

// Selected course price
const selectedPackagePrice = computed(() => {
  const pkg = activeSettings.value.package;
  return packagePrices[pkg] || 0;
});

// System Toast Queue state
interface Toast {
  id: number;
  type: 'success' | 'warning' | 'error' | 'info';
  message: string;
}
const toasts = ref<Toast[]>([]);
let toastIdCounter = 0;

function triggerToast(type: 'success' | 'warning' | 'error' | 'info', message: string) {
  const id = toastIdCounter++;
  toasts.value.push({ id, type, message });
  setTimeout(() => {
    toasts.value = toasts.value.filter(t => t.id !== id);
  }, 3000);
}

// Left cart collapsing triggers
const isCartOpen = ref(true);

// Menu State filters
const searchQuery = ref('');
const activeCategoryId = ref('set_1390');
const activeSubCategoryId = ref('all');
const activeQuickFilter = ref<'favorites' | 'popular' | 'recent' | ''>('');
const activeStatusFilter = ref<'all' | 'available' | 'unavailable'>('all');
const showOnlyPackageItems = ref(false);
const isGridLoading = ref(false);
const favoriteIds = ref<string[]>([]);

// Session Timer ticking state
const timerSecondsLeft = ref(7200);
let timerInterval: number | null = null;

// Temporary Course configurations during modal usage
const isPackageModalOpen = ref(false);
const tempSettings = ref({
  package: '',
  drinkGroup: 'A',
  language: 'VI'
});

// Manager PIN pad authentications state
const isPinModalOpen = ref(false);
const enteredPin = ref('');

// Product details popup state
const isDetailPanelOpen = ref(false);
const selectedProductForDetail = ref<MenuItem | null>(null);
const modalItemQty = ref(1);
const modalItemNote = ref('');
const modalVAT = ref(true);
const modalPPV = ref(false);
const modalCurrency = ref('VND');
const modalRate = ref('1');

interface OptionItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
  note: string;
}

interface OptionGroup {
  id: string;
  title: string;
  minSelection: number;
  maxSelection: number;
  options: OptionItem[];
}

const tempOptionGroups = ref<OptionGroup[]>([]);
const activeOptionTab = ref('');

const activeGroup = computed(() => {
  if (tempOptionGroups.value.length === 0) return null;
  return tempOptionGroups.value.find(g => g.id === activeOptionTab.value) || tempOptionGroups.value[0];
});

const activeGroupSelectedCount = computed(() => {
  if (!activeGroup.value) return 0;
  return activeGroup.value.options.reduce((sum, opt) => sum + opt.quantity, 0);
});

const isSelectionValid = computed(() => {
  if (tempOptionGroups.value.length === 0) return true;
  return tempOptionGroups.value.every(group => {
    const count = group.options.reduce((sum, opt) => sum + opt.quantity, 0);
    return count >= group.minSelection && count <= group.maxSelection;
  });
});

function getMockOptionsForItem(itemId: string): OptionGroup[] {
  if (itemId.includes('lau') || itemId.includes('sukiyaki') || itemId.includes('broth')) {
    return [
      {
        id: 'broth_group',
        title: 'Nước Lẩu Đi Kèm',
        minSelection: 2,
        maxSelection: 2,
        options: [
          { id: 'opt_sukiyaki', name: 'Lẩu Sukiyaki ngọt thanh', price: 0, quantity: 0, note: '' },
          { id: 'opt_kimchi', name: 'Lẩu Kimchi chua cay', price: 0, quantity: 0, note: '' },
          { id: 'opt_mala', name: 'Lẩu Mala Tứ Xuyên cay nồng', price: 30000, quantity: 0, note: '' },
          { id: 'opt_mushroom', name: 'Lẩu Nấm thảo dược bổ dưỡng', price: 0, quantity: 0, note: '' },
          { id: 'opt_soy', name: 'Lẩu Sữa Đậu Nành thơm ngậy', price: 20000, quantity: 0, note: '' }
        ]
      }
    ];
  }
  
  if (itemId.includes('ticket') || itemId.includes('buffet') || itemId.includes('course')) {
    return [
      {
        id: 'soup_group',
        title: 'Chọn Nước Lẩu Gói Buffet',
        minSelection: 1,
        maxSelection: 1,
        options: [
          { id: 'bf_suki', name: 'Lẩu Sukiyaki tiêu chuẩn', price: 0, quantity: 0, note: '' },
          { id: 'bf_kimchi', name: 'Lẩu Kimchi Hàn Quốc', price: 0, quantity: 0, note: '' },
          { id: 'bf_mushroom', name: 'Lẩu Nấm thảo mộc thanh đạm', price: 0, quantity: 0, note: '' }
        ]
      },
      {
        id: 'gift_group',
        title: 'Chọn Món Tặng Kèm (Tối đa 2)',
        minSelection: 0,
        maxSelection: 2,
        options: [
          { id: 'gift_beef', name: 'Thăn vai bò Úc tươi ngọt', price: 0, quantity: 0, note: '' },
          { id: 'gift_beer', name: 'Lon bia Sapporo mát lạnh', price: 0, quantity: 0, note: '' },
          { id: 'gift_salad', name: 'Đĩa Salad bắp cải giòn ngon', price: 0, quantity: 0, note: '' }
        ]
      }
    ];
  }

  if (itemId.includes('lunch') || itemId.includes('set')) {
    return [
      {
        id: 'lunch_side',
        title: 'Món Ăn Kèm (Chọn 1)',
        minSelection: 1,
        maxSelection: 1,
        options: [
          { id: 'side_soup', name: 'Canh Rong Biển nóng hổi', price: 0, quantity: 0, note: '' },
          { id: 'side_kimchi', name: 'Đĩa Kimchi cải thảo chua cay', price: 0, quantity: 0, note: '' },
          { id: 'side_tea', name: 'Ly Hồng trà ngọt mát', price: 0, quantity: 0, note: '' }
        ]
      }
    ];
  }

  return [];
}

// Active table order
const activeTableArea = computed(() => {
  if (!selectedTableCode.value) return 'Khu vực';
  return restaurantStore.getTableAreaName(selectedTableCode.value);
});

const activeOrder = computed(() => {
  if (!selectedTableCode.value) {
    return { orderNumber: '', tableCode: '', customerName: '', guestCount: 0, openedTime: '', items: [] };
  }
  return restaurantStore.getOrCreateOrder(selectedTableCode.value);
});

// Watch selected table code to configure timers and load options
watch(selectedTableCode, (newCode) => {
  if (newCode) {
    // Reset timer
    updateTimer();
    startSessionTimer();
    
    // If table settings aren't set, auto-open the package selector
    if (!tableSettings.value[newCode] || !tableSettings.value[newCode].package) {
      openSettingsConfig();
    }
  } else {
    stopSessionTimer();
  }
}, { immediate: true });

// Session timer tick updates
function startSessionTimer() {
  stopSessionTimer();
  updateTimer();
  timerInterval = setInterval(updateTimer, 1000) as unknown as number;
}

function stopSessionTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

function updateTimer() {
  if (!activeOrder.value.openedTime) {
    timerSecondsLeft.value = 7200;
    return;
  }
  timerSecondsLeft.value = getSessionSecondsLeft(activeOrder.value.openedTime);
}

function getSessionSecondsLeft(openedTimeStr: string): number {
  if (!openedTimeStr) return 7200;
  try {
    const timePart = openedTimeStr.split(' ')[0] || '';
    const datePart = openedTimeStr.split(' ')[1] || '';
    
    const now = new Date();
    const openDate = new Date();
    
    if (timePart.includes(':')) {
      const [h, m] = timePart.split(':').map(Number);
      openDate.setHours(h, m, 0, 0);
    }
    if (datePart.includes('/')) {
      const [d, mo, y] = datePart.split('/').map(Number);
      openDate.setDate(d);
      openDate.setMonth(mo - 1);
      openDate.setFullYear(y);
    }
    
    const diffMs = now.getTime() - openDate.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const totalSec = 7200; // 2 hours Limit
    const left = totalSec - diffSec;
    return left > 0 ? left : 0;
  } catch (e) {
    return 7200;
  }
}

const formattedTimeLeft = computed(() => {
  const s = timerSecondsLeft.value;
  if (s <= 0) return '00:00:00';
  const hrs = Math.floor(s / 3600);
  const mins = Math.floor((s % 3600) / 60);
  const secs = s % 60;
  return `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
});

// Watch countdown to show warnings
watch(timerSecondsLeft, (newVal) => {
  if (newVal === 1799) {
    // 30 mins left
    triggerToast('warning', 'Thời gian ăn còn lại 30 phút. Vui lòng hoàn thành món gọi!');
  } else if (newVal === 599) {
    // 10 mins left
    triggerToast('error', 'Thời gian sắp hết (Còn 10 phút)! Premium drinks sẽ bị ẩn sau khi hết giờ.');
  } else if (newVal === 0) {
    triggerToast('error', 'Phiên ăn 2 giờ đã kết thúc. Gói Premium Drinks đã được tự động khóa.');
  }
});

// Helper to look up an item's subcategory ID from menuData
function getItemSubcategoryId(itemId: string): string {
  for (const cat of menuData.categories) {
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        if (sub.items.some(i => i.id === itemId)) {
          return sub.id;
        }
      }
    }
  }
  return '';
}

// Check if item is included in package
function isItemInPackage(item: { category_id: string; id: string }, packageName: string): boolean {
  if (!packageName) return false;
  
  const subCatId = getItemSubcategoryId(item.id);
  const parentCatId = item.category_id;

  // Surcharges (category: khac, subcategory: surcharge) are never included in packages
  if (parentCatId === 'khac' && subCatId === 'surcharge') return false;

  // Standard buffet-eligible menus
  const isEligibleMenu = parentCatId === 'thuc_an' || parentCatId === 'thuc_uong' || parentCatId === 'thuc_uong_co_con' || parentCatId === 'buffet';

  if (packageName === 'Kids Meal') {
    return item.id.includes('kids') || item.id.includes('egg') || item.id.includes('fries') || subCatId === 'dessert' || parentCatId === 'dessert';
  }
  
  if (packageName === 'Buffet 1390') {
    return isEligibleMenu;
  }
  
  if (packageName === 'Buffet 1150') {
    const isWagyu = item.id.includes('wagyu') || subCatId === 'wagyu';
    return isEligibleMenu && !isWagyu;
  }

  if (packageName === 'Buffet 680') {
    const isWagyu = item.id.includes('wagyu') || subCatId === 'wagyu';
    const isPremiumBeef = item.id.includes('premium') || item.id.includes('sirloin') || item.id.includes('short_ribs') || item.id.includes('tongue') || subCatId === 'beef_tongue';
    return isEligibleMenu && !isWagyu && !isPremiumBeef;
  }

  if (packageName === 'Buffet 490' || packageName === 'Buffet 380') {
    const isBeef = item.id.includes('beef') || item.id.includes('wagyu') || item.id.includes('tongue') || subCatId === 'beef' || subCatId === 'wagyu' || subCatId === 'beef_tongue';
    const isAlcohol = parentCatId === 'thuc_uong_co_con' || ['beer', 'whisky', 'shochu', 'nihonshuu', 'wine', 'alcohol_set'].includes(subCatId);
    
    return isEligibleMenu && !isBeef && !isAlcohol && (
      subCatId === 'pork' ||
      subCatId === 'chicken' ||
      subCatId === 'soft_drink' ||
      subCatId === 'tea' ||
      subCatId === 'non_alcoholic' ||
      subCatId === 'appetizer' ||
      subCatId === 'salad' ||
      subCatId === 'rice' ||
      subCatId === 'noodle' ||
      subCatId === 'soup' ||
      subCatId === 'dessert' ||
      subCatId === 'sauce' ||
      subCatId === 'sukiyaki' ||
      subCatId === 'grill_alacarte' ||
      subCatId === 'alacarte'
    );
  }

  return false;
}

// Deterministic Rich Mock Item Generator
function getEnrichedItem(item: { id: string; name: string; category_id: string; price: number }) {
  const code = item.id;
  const isAvailable = !(code.charCodeAt(code.length - 1) % 8 === 0); // Out of stock simulation
  const isPopular = code.charCodeAt(0) % 3 === 0;
  const isSpicy = code.includes('spicy') || code.includes('kimchi') || code.includes('mala');
  const isVegetarian = code.includes('vegetable') || code.includes('salad') || code.includes('tofu');
  
  let description = "Nguyên liệu tươi ngon, được sơ chế tỉ mỉ từ nhà bếp Ngưu Cát, tẩm ướp nước xốt gia truyền chuẩn vị POS.";
  if (code.includes('wagyu')) description = "Thịt bò Wagyu vân mỡ cẩm thạch thượng hạng, mềm ngọt như tan chảy trong khoang miệng khi nướng.";
  if (code.includes('sake') || code.includes('wine')) description = "Thức uống hảo hạng được khuyên dùng kèm các loại thịt bò nướng giúp kích thích vị giác.";
  if (code.includes('dessert')) description = "Món tráng miệng ngọt thanh nhẹ giúp cân bằng vị giác hoàn hảo sau khi thưởng thức thịt nướng.";

  const allergens: string[] = [];
  if (code.includes('udon') || code.includes('noodle') || code.includes('gyoza') || code.includes('hamburger')) {
    allergens.push("Bột mì (Gluten)");
  }
  if (code.includes('shrimp') || code.includes('octopus') || code.includes('crab') || code.includes('seafood')) {
    allergens.push("Hải sản (Động vật vỏ cứng)");
  }
  if (code.includes('egg')) {
    allergens.push("Lòng đỏ trứng");
  }

  const hash = code.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  const calories = 80 + (hash % 380);
  const protein = 2 + (hash % 28);
  const carb = 4 + (hash % 35);
  const fat = 1 + (hash % 18);

  const emojis: Record<string, string> = {
    ticket: '🎟️',
    drink: '🍹',
    soft: '🥤',
    alcohol: '🍺',
    beer: '🍺',
    lunch: '🍱',
    bibimbap: '🍲',
    udon: '🍜',
    noodle: '🍜',
    wagyu: '🥩',
    beef: '🥩',
    tongue: '🥩',
    pork: '🥓',
    chicken: '🍗',
    shrimp: '🍤',
    octopus: '🐙',
    seafood: '🍤',
    egg: '🍳',
    salad: '🥗',
    soup: '🥣',
    dessert: '🍨',
    ice: '🍨',
    cake: '🍰',
    sauce: '🍯',
    sake: '🍶',
    wine: '🍷',
    whisky: '🥃'
  };
  let emoji = '🍽️';
  for (const [key, val] of Object.entries(emojis)) {
    if (code.toLowerCase().includes(key)) {
      emoji = val;
      break;
    }
  }

  return {
    isAvailable,
    isPopular,
    isSpicy,
    isVegetarian,
    description,
    allergens,
    emoji,
    nutrition: { calories, protein, carb, fat }
  };
}

// Summary Calculation
const summary = computed(() => {
  const guestCount = activeOrder.value.guestCount || 2;
  const ticketSubtotal = guestCount * selectedPackagePrice.value;
  
  const items = activeOrder.value.items || [];
  const itemsSubtotal = items.reduce((sum, item) => {
    const inPackage = isItemInPackage(item, activeSettings.value.package);
    const charge = inPackage ? 0 : item.price;
    return sum + (charge * item.quantity);
  }, 0);
  
  const subtotal = ticketSubtotal + itemsSubtotal;
  const serviceCharge = Math.round(subtotal * 0.05); // 5% Service Charge
  const vat = Math.round((subtotal + serviceCharge) * 0.1); // 10% VAT
  const grandTotal = subtotal + serviceCharge + vat;
  
  return { subtotal, serviceCharge, vat, grandTotal };
});

// Category and Subcategory tabs helpers
const activeCategoryHasSubcategories = computed(() => {
  const cat = menuData.categories.find(c => c.id === activeCategoryId.value);
  return !!(cat && cat.subcategories && cat.subcategories.length > 0);
});

const activeSubcategoriesList = computed(() => {
  const cat = menuData.categories.find(c => c.id === activeCategoryId.value);
  return cat?.subcategories || [];
});

function selectCategory(catId: string) {
  activeCategoryId.value = catId;
  activeSubCategoryId.value = 'all';
  
  isGridLoading.value = true;
  setTimeout(() => {
    isGridLoading.value = false;
  }, 350);
}

// Item card filter lists
const filteredItems = computed(() => {
  const cat = menuData.categories.find(c => c.id === activeCategoryId.value);
  if (!cat) return [];

  let itemsList: MenuItem[] = [];

  if (cat.items) {
    itemsList = [...cat.items];
  } else if (cat.subcategories) {
    if (activeSubCategoryId.value === 'all') {
      cat.subcategories.forEach(sub => {
        itemsList.push(...sub.items);
      });
    } else {
      const sub = cat.subcategories.find(s => s.id === activeSubCategoryId.value);
      if (sub) {
        itemsList = [...sub.items];
      }
    }
  }

  // Real-time Text matching filter
  if (searchQuery.value.trim() !== '') {
    const q = searchQuery.value.toLowerCase().trim();
    itemsList = itemsList.filter(item => 
      item.name.toLowerCase().includes(q) || 
      item.price_display.toLowerCase().includes(q)
    );
  }

  return itemsList;
});

const finalFilteredItems = computed(() => {
  let list = filteredItems.value;
  
  // Package-only items filter
  if (showOnlyPackageItems.value && activeSettings.value.package) {
    list = list.filter(item => isItemInPackage(item, activeSettings.value.package));
  }
  
  // DRINK TIME LIMIT EXPIRED RESTRICTION
  if (timerSecondsLeft.value <= 0 && (activeSettings.value.drinkGroup === 'B' || activeSettings.value.drinkGroup === 'C')) {
    list = list.filter(item => {
      // Hide alcohol/premium
      const isCoCon = item.category_id === 'thuc_uong_co_con' || item.id.includes('alcohol') || item.id.includes('beer') || item.id.includes('wine') || item.id.includes('sake');
      return !isCoCon;
    });
  }

  // Quick Action Filters
  if (activeQuickFilter.value === 'favorites') {
    list = list.filter(item => favoriteIds.value.includes(item.id));
  } else if (activeQuickFilter.value === 'popular') {
    list = list.filter(item => getEnrichedItem(item).isPopular);
  } else if (activeQuickFilter.value === 'recent') {
    const cartIds = activeOrder.value.items.map(i => i.id);
    list = list.filter(item => cartIds.includes(item.id));
  }

  // Available / Sold out filter
  if (activeStatusFilter.value === 'available') {
    list = list.filter(item => getEnrichedItem(item).isAvailable);
  } else if (activeStatusFilter.value === 'unavailable') {
    list = list.filter(item => !getEnrichedItem(item).isAvailable);
  }

  return list;
});

// Format VND
function formatVND(value: number) {
  if (value === 0) return '0đ';
  return value.toLocaleString('vi-VN') + 'đ';
}

// Translations helpers
function translateCategoryId(catId: string) {
  const match = menuData.categories.find(c => c.id === catId);
  return match ? match.name : catId;
}

function translateSubCategoryId(subId: string) {
  const cat = menuData.categories.find(c => c.id === activeCategoryId.value);
  if (!cat || !cat.subcategories) return subId;
  const match = cat.subcategories.find(s => s.id === subId);
  return match ? match.name : subId;
}

// Highlighting search matching text
function highlightText(text: string, query: string) {
  if (!query) return text;
  const regex = new RegExp(`(${query.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')})`, 'gi');
  return text.replace(regex, '<mark class="bg-yellow-100 text-gray-900 rounded-sm px-0.5">$1</mark>');
}

// Cart items quantity getter
function getCartItemQty(itemId: string): number {
  const item = activeOrder.value.items.find(i => i.id === itemId);
  return item ? item.quantity : 0;
}

// Action triggers
function handleCardClick(product: MenuItem) {
  const enriched = getEnrichedItem(product);
  if (!enriched.isAvailable) {
    triggerToast('error', `Món ${product.name} tạm thời hết hàng.`);
    return;
  }
  addToCart(product);
}

function addToCart(product: MenuItem) {
  if (!selectedTableCode.value) return;
  
  // Validate Rule 1: Limit 10 items/round
  const currentQty = getCartItemQty(product.id);
  if (currentQty >= 10) {
    triggerToast('warning', `Đã đạt giới hạn tối đa 10 phần món ${product.name} mỗi lượt gọi.`);
    return;
  }

  restaurantStore.addOrderItem(selectedTableCode.value, product);
  triggerToast('success', `Đã thêm ${product.name} vào hóa đơn`);
}

function updateQty(itemId: string, change: number) {
  if (!selectedTableCode.value) return;
  
  const currentQty = getCartItemQty(itemId);
  if (change > 0 && currentQty >= 10) {
    triggerToast('warning', 'Mỗi lượt gọi tối đa 10 phần/món ăn.');
    return;
  }
  
  restaurantStore.updateItemQuantity(selectedTableCode.value, itemId, change);
}

function removeItem(itemId: string) {
  if (!selectedTableCode.value) return;
  if (confirm('Xóa món này khỏi đơn của bàn?')) {
    restaurantStore.removeOrderItem(selectedTableCode.value, itemId);
    triggerToast('info', 'Đã xóa món ăn khỏi giỏ hàng.');
  }
}

// Option group control modifiers helpers
function addOptionQty(option: any) {
  if (!activeGroup.value) return;
  
  const count = activeGroupSelectedCount.value;
  const max = activeGroup.value.maxSelection;

  if (max === 1) {
    // Radio behavior for single choice option groups
    activeGroup.value.options.forEach((opt: any) => {
      if (opt.id !== option.id) {
        opt.quantity = 0;
        opt.note = '';
      }
    });
    option.quantity = 1;
  } else {
    if (count >= max) {
      triggerToast('warning', `Đã chọn giới hạn tối đa ${max} lựa chọn.`);
      return;
    }
    option.quantity++;
  }
}

function subtractOptionQty(option: any) {
  if (option.quantity > 0) {
    option.quantity--;
    if (option.quantity === 0) {
      option.note = '';
    }
  }
}

// Detail popup modal triggers
function openDetailPanel(product: MenuItem) {
  selectedProductForDetail.value = product;
  const existingQty = getCartItemQty(product.id);
  modalItemQty.value = existingQty > 0 ? existingQty : 1;
  modalItemNote.value = '';
  modalVAT.value = true;
  modalPPV.value = false;
  modalCurrency.value = 'VND';
  modalRate.value = '1';

  // Load option groups
  tempOptionGroups.value = getMockOptionsForItem(product.id);
  if (tempOptionGroups.value.length > 0) {
    activeOptionTab.value = tempOptionGroups.value[0].id;
  } else {
    activeOptionTab.value = '';
  }

  isDetailPanelOpen.value = true;
}

function saveDetailPanelQty() {
  if (!selectedTableCode.value || !selectedProductForDetail.value) return;
  
  if (modalItemQty.value > 10) {
    triggerToast('warning', 'Số lượng gọi món vượt quá giới hạn 10 phần.');
    return;
  }

  const product = selectedProductForDetail.value;

  if (tempOptionGroups.value.length === 0) {
    // ─── Simple Item Submission ───
    const order = activeOrder.value;
    const existing = order.items.find(i => i.id === product.id);
    
    if (existing) {
      existing.quantity = modalItemQty.value;
    } else {
      restaurantStore.addOrderItem(selectedTableCode.value, product);
      const added = order.items.find(i => i.id === product.id);
      if (added) added.quantity = modalItemQty.value;
    }
    
    triggerToast('success', `Đã thêm: ${product.name} (${modalItemQty.value} phần)`);
    isDetailPanelOpen.value = false;
  } else {
    // ─── Complex Item Submission ───
    if (!isSelectionValid.value) {
      triggerToast('error', 'Vui lòng hoàn thành các lựa chọn bắt buộc.');
      return;
    }

    const selectedOptsList: { name: string; note: string; quantity: number }[] = [];
    tempOptionGroups.value.forEach(group => {
      group.options.forEach((opt: any) => {
        if (opt.quantity > 0) {
          selectedOptsList.push({
            name: opt.name,
            note: opt.note,
            quantity: opt.quantity
          });
        }
      });
    });

    const optsString = selectedOptsList.map(o => `${o.quantity > 1 ? o.quantity + 'x ' : ''}${o.name}${o.note ? ` (${o.note})` : ''}`).join(', ');
    
    // Custom price calculation based on option pricing
    const optionsAdditionPrice = tempOptionGroups.value.reduce((sum, group) => {
      return sum + group.options.reduce((oSum: number, opt: any) => oSum + (opt.price * opt.quantity), 0);
    }, 0);
    
    const totalPrice = product.price + optionsAdditionPrice;

    const customizedItem: MenuItem = {
      ...product,
      price: totalPrice,
      price_display: formatVND(totalPrice),
      name: `${product.name} [${optsString}]`
    };

    restaurantStore.addOrderItem(selectedTableCode.value, customizedItem);
    
    const order = activeOrder.value;
    const addedItem = order.items.find(i => i.id === customizedItem.id && i.name === customizedItem.name);
    if (addedItem) {
      addedItem.quantity = modalItemQty.value;
    }

    triggerToast('success', `Đã thêm món có tùy chọn: ${customizedItem.name}`);
    isDetailPanelOpen.value = false;
  }
}

// Favorites toggle
function toggleFavorite(itemId: string) {
  if (favoriteIds.value.includes(itemId)) {
    favoriteIds.value = favoriteIds.value.filter(id => id !== itemId);
    triggerToast('info', 'Đã bỏ yêu thích món.');
  } else {
    favoriteIds.value.push(itemId);
    triggerToast('success', 'Đã lưu món vào danh mục yêu thích.');
  }
}

function toggleQuickFilter(filter: 'favorites' | 'popular' | 'recent' | '') {
  activeQuickFilter.value = filter;
}

function clearAllFilters() {
  searchQuery.value = '';
  activeQuickFilter.value = '';
  activeStatusFilter.value = 'all';
}

// Config Course details modal setup
function openSettingsConfig() {
  tempSettings.value = {
    package: activeSettings.value.package,
    drinkGroup: activeSettings.value.drinkGroup,
    language: activeSettings.value.language
  };
  isPackageModalOpen.value = true;
}

function selectPackageOption(packageName: string) {
  if (activeSettings.value.isLocked) {
    triggerToast('error', 'Cấu hình đã bị khóa. Vui lòng nhập mã PIN để đổi.');
    return;
  }
  tempSettings.value.package = packageName;
}

function selectDrinkOption(group: string) {
  if (activeSettings.value.isLocked) {
    triggerToast('error', 'Nhóm thức uống đã được khóa. Hãy nhập PIN để thay đổi.');
    return;
  }
  tempSettings.value.drinkGroup = group;
}

function confirmPackageSelection() {
  if (!tempSettings.value.package) {
    triggerToast('warning', 'Vui lòng lựa chọn một gói buffet/set phục vụ.');
    return;
  }
  
  const code = selectedTableCode.value;
  if (code && tableSettings.value[code]) {
    tableSettings.value[code].package = tempSettings.value.package;
    tableSettings.value[code].drinkGroup = tempSettings.value.drinkGroup;
    tableSettings.value[code].language = tempSettings.value.language;
    tableSettings.value[code].isLocked = true; // Lock course
    
    // Update order header name to show package
    const order = activeOrder.value;
    order.customerName = order.customerName === 'Khách vãng lai' ? `Khách (${tempSettings.value.package})` : order.customerName;
    
    triggerToast('success', 'Khóa Course cấu hình phục vụ thành công.');
  }
  isPackageModalOpen.value = false;
}

function cancelPackageSelection() {
  if (activeSettings.value.package) {
    isPackageModalOpen.value = false;
  } else {
    // If no course is configured, reject and return to floor layouts
    router.push('/reception/floors');
  }
}

// PIN pad operations
function openPinModal() {
  enteredPin.value = '';
  isPinModalOpen.value = true;
}

function enterPinDigit(digit: string) {
  if (enteredPin.value.length < 4) {
    enteredPin.value += digit;
  }
  
  if (enteredPin.value.length === 4) {
    // Validate manager Pin
    if (enteredPin.value === '1234') {
      const code = selectedTableCode.value;
      if (code && tableSettings.value[code]) {
        tableSettings.value[code].isLocked = false; // Unlock course
        triggerToast('success', 'Mở khóa cấu hình thành công! Bạn có thể sửa đổi gói course.');
      }
      isPinModalOpen.value = false;
    } else {
      triggerToast('error', 'Mã PIN sai! Vui lòng thử lại.');
      enteredPin.value = ''; // Reset
    }
  }
}

function clearLastPinDigit() {
  enteredPin.value = enteredPin.value.slice(0, -1);
}

// Operational Actions
function printDraftBill() {
  alert(`=== HÓA ĐƠN TẠM TÍNH (DRAFT) ===\nBàn: ${selectedTableCode.value}\nGói: ${activeSettings.value.package}\nSố lượng khách: ${activeOrder.value.guestCount}\nTổng cộng tạm tính: ${formatVND(summary.value.grandTotal)}\n\n(In thử POS nháp thành công)`);
  triggerToast('info', 'Đã gửi lệnh in tạm tính hóa đơn.');
}

function checkoutTable() {
  if (confirm(`Xác nhận thanh toán và đóng bàn ${selectedTableCode.value}? Tổng tiền: ${formatVND(summary.value.grandTotal)}`)) {
    // Navigate to checkout screen
    router.push(`/reception/checkout/${selectedTableCode.value}`);
  }
}

function cancelChanges() {
  if (confirm('Hủy bỏ toàn bộ món ăn đã chọn trong giỏ hàng hiện tại?')) {
    activeOrder.value.items = [];
    triggerToast('warning', 'Đã làm trống giỏ hàng món.');
  }
}

function holdOrder() {
  triggerToast('info', 'Đã lưu tạm đơn hàng (Hold).');
  router.push('/reception/floors');
}

function sendToKitchen() {
  if (activeOrder.value.items.length === 0) {
    triggerToast('error', 'Chưa có món ăn nào để gửi nhà bếp nấu.');
    return;
  }
  triggerToast('success', 'Đã gửi yêu cầu chế biến món ăn đến màn hình Bếp KDS.');
}

function saveOrder() {
  const code = selectedTableCode.value;
  if (code) {
    const table = restaurantStore.getTableByCode(code);
    if (table) {
      if (activeOrder.value.items.length > 0) {
        table.status = 'Serving';
        table.billAmount = formatVND(summary.value.grandTotal);
        table.customerName = table.customerName || activeOrder.value.customerName;
        const now = new Date();
        table.checkInTime = table.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
        table.occupiedDuration = '1 phút';
      } else {
        table.status = 'Available';
        table.billAmount = '';
        table.customerName = '';
        table.checkInTime = '';
        table.occupiedDuration = '';
      }
    }
    triggerToast('success', 'Đã lưu cấu hình món ăn của bàn thành công.');
    router.push('/reception/floors');
  }
}

onMounted(() => {
  startSessionTimer();
});

onUnmounted(() => {
  stopSessionTimer();
});
</script>

<style scoped>
@import '@/styles/orderingScreen.css';

.scrollbar-none::-webkit-scrollbar {

  display: none;
}
.scrollbar-custom::-webkit-scrollbar {
  width: 5px;
  height: 5px;
}
.scrollbar-custom::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 4px;
}
.scrollbar-custom::-webkit-scrollbar-track {
  background: transparent;
}

/* Animations */
.animate-fade-in {
  animation: fadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.97); }
  to { opacity: 1; transform: scale(1); }
}

.animate-scale-up {
  animation: scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
}
@keyframes scaleUp {
  from { opacity: 0; transform: scale(0.9); }
  to { opacity: 1; transform: scale(1); }
}

.animate-slide-in {
  animation: slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

.animate-slide-in-panel {
  animation: slideInPanel 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes slideInPanel {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.animate-pulse-slow {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
.animate-pulse-fast {
  animation: pulse 0.8s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: .6; }
}

/* Transition Lists */
.toast-list-enter-active,
.toast-list-leave-active {
  transition: all 0.3s ease;
}
.toast-list-enter-from {
  transform: translateX(100%);
  opacity: 0;
}
.toast-list-leave-to {
  transform: translateX(100%);
  opacity: 0;
}

.cart-list-enter-active,
.cart-list-leave-active {
  transition: all 0.2s ease;
}
.cart-list-enter-from {
  opacity: 0;
  transform: translateY(10px);
}
.cart-list-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.slide-enter-active, .slide-leave-active {
  transition: opacity 0.3s ease;
}
.slide-enter-from, .slide-leave-to {
  opacity: 0;
}
</style>
