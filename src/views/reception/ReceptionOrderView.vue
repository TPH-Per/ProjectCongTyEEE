<!-- File: src/views/reception/ReceptionOrderView.vue -->
<template>
  <div class="h-[calc(100vh-112px)] w-full flex overflow-hidden font-sans select-none text-gray-800 bg-[#f8f9fa] rounded-2xl border border-gray-200 relative shadow-sm">
    
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
      <h2 class="text-lg font-bold text-gray-900 tracking-tight">{{ $t('auto_quyen_truy_cap_bi_tu_choi') }}</h2>
      <p class="text-sm text-gray-500 font-medium max-w-sm mt-1 mb-6">{{ $t('auto_vui_long_chon_mot_ban_an_dang') }}</p>
      <router-link 
        to="/reception/floors" 
        class="px-5 py-3 bg-[#c62828] hover:bg-[#b71c1c] text-white font-bold text-xs rounded-lg shadow-sm transition-all active:scale-95 flex items-center gap-2"
      >
        <span>{{ $t('auto_di_toi_so_do_ban') }}</span>
      </router-link>
    </div>

    <!-- ELSE: Show Order Management POS interface -->
    <div v-else class="flex-1 flex flex-col min-h-0 overflow-hidden bg-[#3a3a3a] text-gray-200">
      
      <!-- 1. Header Bar: Full width top header -->
      <header class="h-16 shrink-0 bg-[#2d2d2d] border-b border-[#1e1e1e] flex items-center justify-between px-6 select-none z-10 text-white">
        <div class="flex items-center gap-4">
          <!-- Restaurant logo -->
          <div class="flex items-center gap-2 font-bold text-base text-[#ff8f00]">
            <span class="text-xl">🐮</span>
            <span>NGƯU CÁT POS</span>
          </div>
          
          <!-- Order Number -->
          <div class="flex flex-col gap-0.5 border-l border-[#4a4a4a] pl-4">
            <span class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">{{ $t('auto_hoa_don') }}</span>
            <span class="text-xs font-bold font-mono text-gray-200">{{ activeOrder.orderNumber || 'WB_00001843' }}</span>
          </div>

          <!-- Customer Name -->
          <div class="flex flex-col gap-0.5 border-l border-[#4a4a4a] pl-4">
            <span class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">{{ $t('auto_khach_hang') }}</span>
            <span class="text-xs font-bold text-gray-200 truncate max-w-[120px]">{{ activeOrder.customerName || 'Ngoc' }}</span>
          </div>

          <!-- Open Time -->
          <div class="flex flex-col gap-0.5 border-l border-[#4a4a4a] pl-4">
            <span class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">{{ $t('auto_gio_mo') }}</span>
            <span class="text-xs font-mono text-gray-300">{{ activeOrder.openedTime || '11:30 24/06/2026' }}</span>
          </div>

          <!-- Booking Status Badge -->
          <div class="border-l border-[#4a4a4a] pl-4 flex items-center h-full">
            <span 
              :class="[
                'px-2 py-0.5 rounded text-[10px] font-bold border uppercase tracking-wider',
                activeTableStatus === 'Đang ăn' ? 'bg-emerald-950/40 text-emerald-400 border-emerald-900/50' :
                activeTableStatus === 'Đã đặt' ? 'bg-amber-950/40 text-amber-400 border-amber-900/50' :
                activeTableStatus === 'Khách đến' ? 'bg-blue-950/40 text-blue-400 border-blue-900/50' :
                'bg-gray-800 text-gray-400 border-gray-700'
              ]"
            >
              [{{ activeTableStatus }}]
            </span>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <!-- Session countdown timer -->
          <div class="flex items-center gap-2 bg-[#3a3a3a] border border-[#4a4a4a] px-3 py-1 rounded-lg text-xs font-semibold">
            <span class="text-gray-400 uppercase tracking-wide text-[10px]">{{ $t('auto_thoi_gian') }}</span>
            <span 
              :class="[
                'font-mono font-bold px-1 rounded text-xs',
                timerSecondsLeft <= 0 ? 'bg-red-950/60 text-red-400 animate-pulse' :
                timerSecondsLeft < 600 ? 'bg-red-950/30 text-red-400 animate-pulse' :
                'text-gray-200'
              ]"
            >
              🕒 {{ formattedTimeLeft }}
            </span>
          </div>

          <!-- Search Box -->
          <div class="relative flex items-center bg-[#3a3a3a] border border-[#4a4a4a] rounded-lg px-3 py-1 focus-within:border-[#ff8f00] transition-colors w-56">
            <span class="text-gray-400 mr-2 text-xs">🔍</span>
            <input 
              v-model="searchQuery" 
              type="text" 
              :placeholder="$t('auto_tim_kiem')" 
              class="bg-transparent border-none text-xs text-white placeholder-gray-500 focus:outline-none w-full"
            />
            <button v-if="searchQuery" @click="searchQuery = ''" class="text-gray-400 hover:text-white text-xs ml-1">✕</button>
          </div>

          <!-- More Actions Icon -->
          <div class="flex items-center gap-1">
            <button 
              @click="printDraftBill" 
              class="p-1.5 bg-[#3a3a3a] hover:bg-[#4a4a4a] border border-[#4a4a4a] rounded-lg transition-colors" 
              :title="$t('auto_xem_hoa_don_tam_tinh')"
            >
              🖨️
            </button>
            <button 
              @click="openSettingsConfig" 
              class="p-1.5 bg-[#3a3a3a] hover:bg-[#4a4a4a] border border-[#4a4a4a] rounded-lg transition-colors" 
              :title="$t('auto_cau_hinh_goi_ngon_ngu')"
            >
              ⚙️
            </button>
          </div>

          <!-- Area/Table Selector Dropdown -->
          <div class="relative">
            <select 
              v-model="selectedTableCode" 
              class="bg-[#3a3a3a] text-xs text-white font-bold border border-[#4a4a4a] rounded-lg px-3 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer"
            >
              <option v-for="t in allTables" :key="t.code" :value="t.code">
                {{ t.label }}
              </option>
            </select>
          </div>
        </div>
      </header>

      <!-- DRINK GROUP WARNING TIMER EXPIRATION BANNER -->
      <transition name="fade">
        <div 
          v-if="timerSecondsLeft <= 0 && (activeSettings.drinkGroup === 'B' || activeSettings.drinkGroup === 'C')"
          class="bg-amber-950/60 border-b border-amber-900/50 text-amber-400 px-6 py-2 text-xs font-bold flex items-center justify-between shadow-sm z-10 select-none"
        >
          <div class="flex items-center gap-2">
            <span>⏰</span>
            <span>{{ $t('auto_thoi_gian_do_uong_premium_da_k') }}</span>
          </div>
          <button @click="openPinModal" class="px-2.5 py-1 bg-amber-700 text-white text-[10px] rounded hover:bg-amber-600 font-bold transition-all">{{ $t('auto_mo_khoa_pin') }}</button>
        </div>
      </transition>

      <!-- 2 & 3: Middle container (Split row: Cart Left 30%, Products Right 70%) -->
      <div class="flex-1 flex min-h-0 relative">
        
        <!-- Cart Sidebar (approx 30% width) -->
        <aside class="w-[30%] bg-[#2d2d2d] border-r border-[#1e1e1e] flex flex-col justify-between overflow-hidden">
          
          <!-- Cart Header -->
          <div class="p-4 border-b border-[#3a3a3a] flex items-center justify-between shrink-0 select-none">
            <div class="flex flex-col">
              <span class="font-bold text-xs text-gray-200">BÀN PHỤC VỤ</span>
              <span class="text-sm font-black text-[#ff8f00] mt-0.5">{{ activeTableArea }} - Bàn {{ activeOrder.tableCode }}</span>
            </div>
            
            <div class="flex items-center gap-2">
              <button 
                @click="clearCart" 
                :disabled="activeOrder.items.length === 0"
                class="px-2.5 py-1 text-[11px] font-bold bg-red-950/40 hover:bg-red-900/40 border border-red-900/50 text-red-400 rounded-lg disabled:opacity-30 disabled:cursor-not-allowed transition-all"
              >{{ $t('auto_xoa_het') }}</button>
            </div>
          </div>

          <!-- Order Table Scroll area -->
          <div class="flex-1 overflow-y-auto p-4 ordering-screen-scrollbar">
            <div class="w-full text-left text-xs">
              <!-- Columns headers -->
              <div class="grid grid-cols-[45%_22%_13%_20%] font-bold text-gray-500 uppercase tracking-wider pb-2 border-b border-[#3a3a3a] px-1 select-none">
                <div>{{ $t('auto_ten_mon') }}</div>
                <div class="text-right">{{ $t('auto_don_gia') }}</div>
                <div class="text-center">VAT</div>
                <div class="text-right">{{ $t('auto_thanh_tien') }}</div>
              </div>

              <!-- Cart Empty state -->
              <div v-if="activeOrder.items.length === 0" class="py-20 text-center text-gray-500 select-none">
                <div class="text-4xl mb-3">🛒</div>
                <p class="font-bold text-gray-400">{{ $t('auto_hoa_don_trong') }}</p>
                <p class="text-[10px] text-gray-500 mt-1 max-w-[200px] mx-auto leading-relaxed">{{ $t('auto_vui_long_chon_mon_an_tu_thuc_d') }}</p>
              </div>

              <!-- Cart items rows -->
              <div v-else class="divide-y divide-[#3a3a3a] mt-1">
                <div 
                  v-for="item in activeOrder.items" 
                  :key="item.id"
                  class="grid grid-cols-[45%_22%_13%_20%] items-start py-3 hover:bg-[#333333] px-1 rounded-lg transition-colors group"
                >
                  <div class="pr-2">
                    <div class="font-bold text-gray-100 leading-tight">{{ item.name }}</div>
                    <div class="text-[10px] text-gray-500 mt-0.5">ĐVT: {{ item.unit }}</div>
                    
                    <!-- Counter Controls -->
                    <div class="flex items-center gap-1 mt-2 select-none">
                      <button 
                        @click="updateQty(item.id, -1)" 
                        class="w-5 h-5 rounded bg-[#3a3a3a] text-gray-300 hover:bg-[#ff8f00] hover:text-white flex items-center justify-center font-bold text-xs active:scale-90 transition-all"
                      >
                        -
                      </button>
                      <span class="font-bold font-mono text-xs px-2 py-0.5 text-white bg-[#1e1e1e] rounded min-w-[24px] text-center">{{ item.quantity }}</span>
                      <button 
                        @click="updateQty(item.id, 1)" 
                        class="w-5 h-5 rounded bg-[#3a3a3a] text-gray-300 hover:bg-[#ff8f00] hover:text-white flex items-center justify-center font-bold text-xs active:scale-90 transition-all"
                      >
                        +
                      </button>
                      <button 
                        @click="removeItem(item.id)" 
                        class="text-red-500 hover:text-red-400 text-xs ml-2.5 opacity-0 group-hover:opacity-100 transition-opacity"
                        :title="$t('auto_xoa_mon_khoi_gio')"
                      >
                        ✕
                      </button>
                    </div>
                  </div>

                  <div class="text-right font-mono font-bold text-gray-300 mt-0.5">
                    <span v-if="isItemInPackage(item, activeSettings.package)" class="text-emerald-500 text-[10px] block leading-tight">{{ $t('auto_trong_goi') }}</span>
                    <span v-else>{{ formatVND(item.price) }}</span>
                  </div>

                  <div class="text-center font-mono text-gray-400 mt-0.5">10%</div>

                  <div class="text-right font-mono font-bold text-[#ff8f00] mt-0.5">
                    <span v-if="isItemInPackage(item, activeSettings.package)" class="text-emerald-500 text-xs">{{ $t('auto_0d') }}</span>
                    <span v-else>{{ formatVND(item.price * item.quantity) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Sticky summary footer -->
          <div class="border-t border-[#3a3a3a] bg-[#1e1e1e] p-4 text-xs font-semibold text-gray-300 space-y-2 select-none shrink-0">
            <div class="flex justify-between items-center">
              <span class="text-gray-400">{{ $t('auto_tam_tinh_mon_goi') }}</span>
              <span class="font-mono text-gray-200">{{ formatVND(summary.subtotal) }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-400">
              <span>{{ $t('auto_phi_dich_vu_5') }}</span>
              <span class="font-mono">{{ formatVND(summary.serviceCharge) }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-400">
              <span>{{ $t('auto_thue_gtgt_vat_10') }}</span>
              <span class="font-mono">{{ formatVND(summary.vat) }}</span>
            </div>
            
            <div class="flex justify-between items-center pt-2 border-t border-[#3a3a3a]">
              <span class="text-gray-400 flex items-center gap-1.5">{{ $t('auto_tong_so_luong_mon') }}</span>
              <span class="bg-[#ff8f00] text-white font-mono px-2 py-0.5 rounded-full text-[10px] font-bold">
                {{ activeOrder.items.reduce((sum, item) => sum + item.quantity, 0) }} món
              </span>
            </div>
            
            <div class="flex justify-between items-center text-sm font-bold text-white pt-1">
              <span>TỔNG THANH TOÁN:</span>
              <span class="text-xl font-mono text-[#ff8f00]">{{ formatVND(summary.grandTotal) }}</span>
            </div>
            
            <div class="grid grid-cols-2 gap-2 pt-3">
              <button 
                @click="holdOrder"
                class="py-2 bg-[#2d2d2d] hover:bg-[#333333] border border-[#4a4a4a] text-white text-xs font-bold rounded-lg transition-all"
              >{{ $t('auto_tam_luu', '⏸️ Tạm lưu') }}</button>
              <button
                @click="sendToKitchen"
                :disabled="activeOrder.items.length === 0 || kitchenLoading"
                class="py-2 bg-[#1976d2] hover:bg-[#1565c0] text-white text-xs font-bold rounded-lg disabled:opacity-40 disabled:cursor-not-allowed transition-all"
              >{{ kitchenLoading ? '...' : $t('auto_gui_bep', '🍳 Gửi Bếp') }}</button>
            </div>
            
            <button 
              @click="checkoutTable"
              class="w-full py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-md transition-all active:scale-95 flex items-center justify-center gap-2 mt-2"
            >
              💸 IN THANH TOÁN (BILL)
            </button>
          </div>
        </aside>

        <!-- Product Grid Area (approx 70% width) -->
        <main class="w-[70%] bg-[#3a3a3a] flex flex-col justify-between overflow-hidden relative">
          


          <!-- Products scrollable grid container -->
          <div class="flex-1 overflow-y-auto p-5 ordering-screen-scrollbar">
            
            <!-- Filters & Preferences bar -->
            <div class="flex flex-wrap items-center justify-between gap-3 mb-5 select-none shrink-0 bg-[#2d2d2d] p-3 rounded-xl border border-[#4a4a4a]">
              <!-- Left: Quick filters & status/price sort -->
              <div class="flex flex-wrap items-center gap-3">
                <div class="flex gap-1.5">
                  <button 
                    v-for="f in [{id: 'favorites', label: '⭐ Yêu thích'}, {id: 'popular', label: '🔥 Bán chạy'}, {id: 'recent', label: '🕒 Mới gọi'}]"
                    :key="f.id"
                    @click="toggleQuickFilter(activeQuickFilter === f.id ? '' : (f.id as any))"
                    :class="[
                      'px-3 py-1.5 rounded-full text-xs font-bold transition-all border shrink-0 active:scale-95',
                      activeQuickFilter === f.id
                        ? 'bg-[#ff8f00] border-[#ff8f00] text-white shadow-xs'
                        : 'bg-[#3a3a3a] border-[#4a4a4a] text-gray-400 hover:bg-[#4a4a4a] hover:text-white'
                    ]"
                  >
                    {{ f.label }}
                  </button>
                </div>

                <!-- Sort & Filter Dropdowns -->
                <div class="flex items-center gap-2 border-l border-[#4a4a4a] pl-3">
                  <!-- Status Filter -->
                  <select 
                    v-model="activeStatusFilter" 
                    class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer"
                  >
                    <option value="all">{{ $t('auto_tat_ca_mon') }}</option>
                    <option value="available">{{ $t('auto_con_mon') }}</option>
                    <option value="unavailable">{{ $t('auto_het_mon') }}</option>
                  </select>

                  <!-- Price Sort -->
                  <select 
                    v-model="priceSort" 
                    class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer"
                  >
                    <option value="">{{ $t('auto_khong_sap_xep') }}</option>
                    <option value="asc">{{ $t('auto_gia_thap_cao') }}</option>
                    <option value="desc">{{ $t('auto_gia_cao_thap') }}</option>
                  </select>
                </div>
              </div>
              
              <!-- Right: Toggle to show only course package elements -->
              <div v-if="activeSettings.package" class="flex items-center gap-2 bg-[#3a3a3a] border border-[#4a4a4a] px-3 py-1 rounded-full text-xs">
                <span class="text-gray-400 font-bold text-[10px] uppercase">Chỉ món trong gói ({{ activeSettings.package }}):</span>
                <button 
                  @click="showOnlyPackageItems = !showOnlyPackageItems"
                  :class="[
                    'w-8 h-4 rounded-full transition-colors relative flex items-center',
                    showOnlyPackageItems ? 'bg-[#ff8f00]' : 'bg-[#2d2d2d]'
                  ]"
                >
                  <div 
                    :class="[
                      'w-3 h-3 rounded-full bg-white transition-transform absolute shadow-xs',
                      showOnlyPackageItems ? 'translate-x-4' : 'translate-x-0.5'
                    ]"
                  ></div>
                </button>
              </div>
            </div>

            <!-- Loading Spinner -->
            <div v-if="isGridLoading" class="h-64 flex flex-col items-center justify-center text-gray-400 select-none">
              <div class="w-8 h-8 border-4 border-[#ff8f00] border-t-transparent rounded-full animate-spin"></div>
              <p class="text-xs font-bold mt-4">{{ $t('auto_dang_loc_danh_muc_san_pham') }}</p>
            </div>

            <!-- Empty Items layout -->
            <div v-else-if="finalFilteredItems.length === 0" class="h-64 flex flex-col items-center justify-center text-gray-500 text-center border border-dashed border-[#4a4a4a] rounded-2xl p-6 select-none">
              <div class="text-4xl mb-2">🍽️</div>
              <h4 class="font-bold text-gray-400 text-xs">{{ $t('auto_khong_tim_thay_mon_an_nao_khop') }}</h4>
              <p class="text-[10px] text-gray-500 mt-1 max-w-[280px]">{{ $t('auto_thuc_don_hien_tai_khong_co_mon') }}</p>
            </div>

            <!-- Responsive Product Card Grid -->
            <div v-else class="grid gap-4" style="grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));">
              <div 
                v-for="product in finalFilteredItems" 
                :key="product.id"
                @click="handleCardClick(product)"
                :class="[
                  'bg-[#242424] border rounded-xl p-3 flex flex-col justify-between cursor-pointer hover:border-[#ff8f00] hover:shadow-lg transition-all relative overflow-hidden group select-none',
                  getCartItemQty(product.id) > 0 ? 'border-[#ff8f00] bg-[#2d2418]' : 'border-[#4a4a4a]',
                  !getEnrichedItem(product).isAvailable ? 'opacity-30 pointer-events-none' : ''
                ]"
                style="height: 140px;"
              >
                <!-- Out of stock overlay -->
                <div 
                  v-if="!getEnrichedItem(product).isAvailable"
                  class="absolute inset-0 bg-black/60 flex items-center justify-center z-10 pointer-events-none animate-fade-in"
                >
                  <span class="bg-[#d32f2f] text-white text-[11px] font-extrabold uppercase px-3 py-1 rounded shadow-md tracking-wider transform -rotate-12 border border-red-400">
                    HẾT MÓN
                  </span>
                </div>

                <!-- Qty badge overlay (top-left, green bg) -->
                <div 
                  v-if="getCartItemQty(product.id) > 0"
                  class="absolute top-2.5 left-2.5 bg-[#4CAF50] text-white font-mono text-[9px] font-black px-1.5 py-0.5 rounded shadow-sm z-10"
                >
                  {{ getCartItemQty(product.id) }} phần
                </div>

                <!-- Favorite badge overlay -->
                <button 
                  @click.stop="toggleFavorite(product.id)"
                  class="absolute top-2 right-2 w-6 h-6 rounded-full bg-[#3a3a3a] hover:bg-[#4a4a4a] text-gray-400 flex items-center justify-center text-xs transition-colors shrink-0 z-10"
                  ::title="$t('auto_favoriteids_includes_product_i', 'favoriteIds.includes(product.id) ? \'Bỏ đánh dấu món yêu thích\' : \'Đánh dấu món yêu thích\'')"
                >
                  <span :class="favoriteIds.includes(product.id) ? 'text-[#ff8f00] font-black' : 'text-gray-400'">⭐</span>
                </button>

                <!-- Product Name centered -->
                <div class="mt-4 flex-1 flex flex-col justify-start">
                  <h4 
                    :style="{ color: getCartItemQty(product.id) > 0 ? '#ff8f00' : '#f0f0f0' }"
                    class="text-sm font-semibold leading-snug line-clamp-2 min-h-[40px] transition-colors"
                    :title="product.name"
                  >
                    {{ getJpAndViNames(product.name).vi }}
                  </h4>
                  <span 
                    v-if="getJpAndViNames(product.name).jp !== 'N/A'" 
                    class="text-[9px] text-gray-500 font-bold mt-0.5 truncate"
                    :title="getJpAndViNames(product.name).jp"
                  >
                    {{ getJpAndViNames(product.name).jp }}
                  </span>
                </div>

                <!-- Card Footer metadata -->
                <div class="flex items-end justify-between border-t border-[#3a3a3a] pt-2 mt-1 shrink-0">
                  <div class="flex flex-col">
                    <span class="text-[8px] text-gray-500 font-bold uppercase leading-none">ĐVT: {{ product.unit }}</span>
                    <span class="text-xs font-mono font-bold mt-1">
                      <span v-if="isItemInPackage(product, activeSettings.package) || product.price === 0" class="text-emerald-400">{{ $t('auto_trong_goi') }}</span>
                      <span v-else class="text-[#ff8f00] font-bold text-sm">{{ product.price_display }}</span>
                    </span>
                  </div>

                  <!-- Details modal info button -->
                  <button 
                    @click.stop="openDetailPanel(product)"
                    class="w-6 h-6 rounded bg-[#3a3a3a] hover:bg-[#4a4a4a] flex items-center justify-center text-gray-400 hover:text-white transition-colors border border-[#4a4a4a]"
                    :title="$t('auto_xem_chi_tiet_tuy_chon')"
                  >
                    ℹ️
                  </button>
                </div>
              </div>
            </div>

          </div>

          <!-- Bottom Navigation Area -->
          <div class="bg-[#2d2d2d] border-t border-[#1e1e1e] flex flex-col shrink-0 select-none">
            <!-- Level 2 - Sub Categories: Directly above Main Categories -->
            <div class="p-3 border-b border-[#1e1e1e] overflow-x-auto scrollbar-none flex gap-2">
              <button 
                @click="selectSubCategory('all')"
                :style="{
                  backgroundColor: '#f5a623',
                  border: activeSubCategoryId === 'all' ? '2px solid white' : '2px solid transparent'
                }"
                class="px-4 py-2 rounded-xl text-xs font-bold text-white transition-all shrink-0 active:scale-95 shadow-sm"
              >{{ $t('auto_tat_ca') }}</button>
              
              <button 
                v-for="sub in activeSubcategoriesList"
                :key="sub.id"
                @click="selectSubCategory(sub.id)"
                :style="{
                  backgroundColor: '#f5a623',
                  border: activeSubCategoryId === sub.id ? '2px solid white' : '2px solid transparent'
                }"
                class="px-4 py-2 rounded-xl text-xs font-bold text-white transition-all shrink-0 active:scale-95 shadow-sm"
              >
                {{ sub.name }}
              </button>
            </div>

            <!-- Level 1 - Main Categories: Bottom Row -->
            <div class="p-3 overflow-x-auto scrollbar-none flex gap-2">
              <button 
                v-for="cat in menuHierarchy"
                :key="cat.id"
                @click="selectCategory(cat.id)"
                :style="{
                  backgroundColor: '#b56576',
                  border: activeCategoryId === cat.id ? '2px solid #c62828' : '2px solid transparent'
                }"
                class="px-5 py-3.5 rounded-xl text-xs font-bold text-white transition-all shrink-0 flex items-center gap-2 uppercase tracking-wide active:scale-95 shadow-sm"
              >
                <span>
                  <span v-if="cat.id === 'buffet'">🏆</span>
                  <span v-else-if="cat.id === 'set_lunch'">🍱</span>
                  <span v-else-if="cat.id === 'set_tiec_chieu_dai'">🎉</span>
                  <span v-else-if="cat.id === 'set_tiec_chieu_dai_jp'">🗾</span>
                  <span v-else-if="cat.id === 'set_vietravel'">✈️</span>
                  <span v-else-if="cat.id === 'thuc_an'">🥩</span>
                  <span v-else-if="cat.id === 'thuc_uong'">🥤</span>
                  <span v-else-if="cat.id === 'thuc_uong_co_con'">🍺</span>
                  <span v-else>🍽️</span>
                </span>
                <span>{{ cat.name }}</span>
              </button>
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
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col relative z-10 animate-scale-up border border-[#e0e0e0] text-gray-800">
            
            <!-- Header Modal with Clean Colors -->
            <header class="bg-gradient-to-r from-[#1976d2] to-[#1565c0] text-white px-6 py-4 flex justify-between items-center shrink-0">
              <h3 class="text-base font-bold tracking-tight select-none">{{ $t('auto_chi_tiet_mon_an') }}</h3>
              <button 
                @click="isDetailPanelOpen = false"
                class="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center font-bold text-sm transition-all select-none active:scale-90"
              >
                ✕
              </button>
            </header>

            <!-- Body Area (Padding 24px) -->
            <div class="p-6 overflow-y-auto flex-1 min-h-0 text-left text-gray-700">
              
              <!-- ─── CASE A: SIMPLE ITEM DETAIL MODAL ─── -->
              <div v-if="tempOptionGroups.length === 0" class="grid grid-cols-1 md:grid-cols-10 gap-6">
                <!-- Column Left (40% width -> 4 cols) -->
                <div class="md:col-span-4 flex flex-col items-center gap-4">
                  <div class="w-full h-52 bg-gray-100 border border-[#e0e0e0] rounded-xl flex items-center justify-center text-6xl relative overflow-hidden select-none">
                    {{ getEnrichedItem(selectedProductForDetail).emoji }}
                    
                    <span 
                      v-if="!getEnrichedItem(selectedProductForDetail).isAvailable"
                      class="absolute inset-0 bg-red-950/20 backdrop-blur-xs flex items-center justify-center font-black text-white text-xs uppercase"
                    >{{ $t('auto_het_hang') }}</span>
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
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ten_mon') }}</label>
                    <input 
                      type="text" 
                      :value="selectedProductForDetail.name" 
                      readonly 
                      class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                    />
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ma_mon') }}</label>
                      <input 
                        type="text" 
                        :value="selectedProductForDetail.id" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-mono text-gray-800 focus:outline-none"
                      />
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_don_vi_tinh') }}</label>
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
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_so_luong') }}</label>
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
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_don_gia_vnd') }}</label>
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
                      <input type="checkbox" v-model="modalVAT" class="w-4 h-4 accent-[#1976d2]" />{{ $t('auto_bao_gom_vat') }}</label>
                    <label class="flex items-center gap-2 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalPPV" class="w-4 h-4 accent-[#1976d2]" />{{ $t('auto_bao_gom_ppv') }}</label>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_loai_tien_te') }}</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-[#e0e0e0] rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none">
                        <option value="VND">{{ $t('auto_vnd_viet_nam_dong') }}</option>
                        <option value="USD">{{ $t('auto_usd_do_la_my') }}</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ty_gia') }}</label>
                      <input 
                        type="text" 
                        v-model="modalRate" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ghi_chu') }}</label>
                    <textarea 
                      v-model="modalItemNote" 
                      :placeholder="$t('auto_them_ghi_chu_dac_thu_it_da_nhi')" 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2.5 font-bold text-gray-855 h-20 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">{{ $t('auto_phan_nhom_thuc_don_he_thong') }}</h5>
                    <div class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]">
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_nhom_san_pham') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ translateCategoryId(selectedProductForDetail.category_id) }}
                          <span v-if="getItemSubcategoryId(selectedProductForDetail.id)">
                            &gt; {{ translateSubCategoryId(getItemSubcategoryId(selectedProductForDetail.id)) }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_buffet') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getEligibleBuffetGroups(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_set_menu') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getSetMenuGroup(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_do_uong') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getDrinkGroup(selectedProductForDetail) }}</div>
                      </div>
                    </div>
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
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_so_luong') }}</label>
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
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_don_gia_vnd') }}</label>
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
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_tien_te') }}</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2 py-1.5 font-bold text-gray-850 focus:outline-none text-[11px]">
                        <option value="VND">VND</option>
                        <option value="USD">USD</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ty_gia') }}</label>
                      <input type="text" v-model="modalRate" readonly class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none" />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ $t('auto_ghi_chu_chung') }}</label>
                    <textarea 
                      v-model="modalItemNote" 
                      :placeholder="$t('auto_them_ghi_chu_cho_ca_mon_an')" 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2 font-bold text-gray-850 h-16 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">{{ $t('auto_phan_nhom_thuc_don_he_thong') }}</h5>
                    <div class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]">
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_nhom_san_pham') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ translateCategoryId(selectedProductForDetail.category_id) }}
                          <span v-if="getItemSubcategoryId(selectedProductForDetail.id)">
                            &gt; {{ translateSubCategoryId(getItemSubcategoryId(selectedProductForDetail.id)) }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_buffet') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getEligibleBuffetGroups(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_set_menu') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getSetMenuGroup(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ $t('auto_goi_do_uong') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getDrinkGroup(selectedProductForDetail) }}</div>
                      </div>
                    </div>
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
                              :placeholder="$t('auto_them_ghi_chu_rieng_cho_lua_cho')"
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
              >{{ $t('auto_huy_bo_esc') }}</button>
              
              <button 
                @click="saveDetailPanelQty"
                :disabled="!getEnrichedItem(selectedProductForDetail).isAvailable || !isSelectionValid"
                :class="[
                  'px-6 py-2.5 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 flex items-center gap-1.5',
                  (getEnrichedItem(selectedProductForDetail).isAvailable && isSelectionValid) ? 'bg-[#2e7d32] hover:bg-[#1b5e20]' : 'bg-gray-400 cursor-not-allowed opacity-50'
                ]"
              >
                <span>➕</span>
                <span>{{ $t('auto_them_vao_gio_hang') }}</span>
              </button>
            </footer>

          </div>

        </div>
      </transition>

      <!-- COURSE CONFIGURATOR / PACKAGE SELECTOR MODAL OVERLAY -->
      <div 
        v-if="isPackageModalOpen" 
        class="fixed inset-0 z-45 flex items-center justify-center p-4 bg-gray-950/60 backdrop-blur-sm animate-fade-in"
      >
        <div class="bg-white border border-[#e0e0e0] text-gray-800 rounded-2xl w-full max-w-2xl shadow-2xl p-6 relative animate-scale-up max-h-[90vh] overflow-y-auto scrollbar-thin">
          
          <!-- Close button if package already exists -->
          <button 
            v-if="activeSettings.package"
            @click="cancelPackageSelection"
            class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-205 text-gray-505 flex items-center justify-center text-sm font-bold active:scale-90 select-none border border-gray-150"
          >
            ✕
          </button>

          <h3 class="text-[17px] font-bold text-gray-900 tracking-tight mb-4 flex items-center gap-2 select-none border-b border-[#f0f0f0] pb-3">
            <span>🏆</span> 
            <span>Cấu hình Gói Course Phục Vụ cho Bàn {{ activeOrder.tableCode }}</span>
          </h3>

          <!-- PACKAGE GRID (2 cols) -->
          <div class="mb-4">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2.5 select-none">{{ $t('auto_1_chon_goi_an_phuc_vu_course_p') }}</h4>
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
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">{{ $t('auto_2_chon_nhom_do_uong_kem_theo_d') }}</h4>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ $t('auto_nhom_a_soft_drink') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ $t('auto_nuoc_ngot_uong_khong_gioi_han') }}</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'A' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ $t('auto_nhom_b_premium_drink') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ $t('auto_ruou_bia_cao_cap_uong_trong_2') }}</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'B' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ $t('auto_nhom_c_premium_alt') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ $t('auto_ruou_bia_thay_the_dung_2_gio_f') }}</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'C' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ $t('auto_nhom_d_a_la_carte') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ $t('auto_goi_do_uong_le_tinh_tien_rieng') }}</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'D' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

            </div>
          </div>

          <!-- LANGUAGES CHOICE -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">{{ $t('auto_3_ngon_ngu_giao_dien_hien_thi') }}</h4>
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
                    : 'bg-gray-50 border-gray-205 text-gray-600 hover:bg-gray-100'
                ]"
              >
                <span v-if="lang === 'VI'">{{ $t('auto_tieng_viet') }}</span>
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
            >{{ $t('auto_huy_bo_quay_lai') }}</button>
            
            <button 
              v-if="activeSettings.isLocked"
              @click="openPinModal"
              class="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >{{ $t('auto_pin_sua_cau_hinh') }}</button>
            <button 
              v-else
              @click="confirmPackageSelection"
              class="flex-1 py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >{{ $t('auto_xac_nhan_khoa_course') }}</button>
          </div>

        </div>
      </div>

      <!-- MANAGER PIN PAD UNLOCK MODAL -->
      <div 
        v-if="isPinModalOpen" 
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-950/70 backdrop-blur-xs animate-fade-in text-gray-800"
      >
        <div class="bg-white border border-[#e0e0e0] rounded-2xl w-full max-w-xs shadow-2xl p-6 text-center animate-scale-up relative">
          
          <button 
            @click="isPinModalOpen = false"
            class="absolute top-4 right-4 w-7 h-7 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-505 flex items-center justify-center text-xs font-bold"
          >
            ✕
          </button>

          <span class="text-3xl block mb-2">🔐</span>
          <h4 class="text-sm font-bold text-gray-900 mb-1">{{ $t('auto_ma_pin_xac_thuc_quan_ly') }}</h4>
          <p class="text-[10px] text-gray-400 font-semibold mb-4 leading-normal">{{ $t('auto_nhap_ma_pin_cua_quan_ly_de_mo') }}</p>

          <!-- Input dots -->
          <div class="flex justify-center gap-3.5 mb-5 select-none">
            <div 
              v-for="i in 4" 
              :key="i"
              :class="[
                'w-4 h-4 rounded-full border transition-all duration-100',
                enteredPin.length >= i ? 'bg-red-650 border-red-700 scale-110 shadow-sm' : 'bg-gray-100 border-gray-300'
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
              class="w-12 h-12 rounded-2xl bg-amber-50 hover:bg-amber-150 border border-amber-200 text-[10px] font-bold text-amber-700 flex items-center justify-center active:scale-90 transition-all"
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
import { menuData, type MenuItem } from '@/data/menuData'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useOrder } from '@/composables/useOrder'
import Swal from 'sweetalert2'

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
    courseLocked: 'Khóa Course',
    guestWalkIn: 'Khách vãng lai',
    courseLockedSuccess: 'Khóa Course cấu hình phục vụ thành công.'
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
    courseLocked: 'Course Locked',
    guestWalkIn: 'Walk-in Guest',
    courseLockedSuccess: 'Course locked successfully.'
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
    courseLocked: 'コースロック',
    guestWalkIn: 'ウォークインゲスト',
    courseLockedSuccess: 'コースが正常にロックされました。'
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
    courseLocked: '코스 잠금',
    guestWalkIn: '워크인 고객',
    courseLockedSuccess: '코스가 성공적으로 잠금 처리되었습니다.'
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
    courseLocked: '已锁套餐',
    guestWalkIn: '散客',
    courseLockedSuccess: '套餐锁定成功。'
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
const activeCategoryId = ref('buffet');
const activeSubCategoryId = ref('all');
const activeQuickFilter = ref<'favorites' | 'popular' | 'recent' | ''>('');
const activeStatusFilter = ref<'all' | 'available' | 'unavailable'>('all');
const priceSort = ref<'asc' | 'desc' | ''>('');
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

const allTables = computed(() => {
  const list: { code: string; label: string }[] = [];
  restaurantStore.areas.forEach(area => {
    area.tables.forEach(table => {
      list.push({
        code: table.code,
        label: `${area.name} - ${table.code}`
      });
    });
  });
  return list;
});

const activeTableStatus = computed(() => {
  const code = selectedTableCode.value;
  if (!code) return 'Trống';
  const tbl = restaurantStore.getTableByCode(code);
  if (!tbl) return 'Trống';
  if (tbl.status === 'Available') return 'Trống';
  if (tbl.status === 'Reserved') return 'Đã đặt';
  if (tbl.status === 'Arrived') return 'Khách đến';
  if (tbl.status === 'Serving') return 'Đang ăn';
  return tbl.status;
});

// Watch selected table code to configure timers and load options
watch(selectedTableCode, (newCode) => {
  if (newCode) {
    // Reset timer
    updateTimer();
    startSessionTimer();
    
    // If table settings aren't set, auto-open the package selector
    if (!tableSettings.value[newCode] || !tableSettings.value[newCode].package) {
      // openSettingsConfig(); // Disabled automatic popup configurator
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

// Parsed Japanese and Vietnamese Names extractor helper
function getJpAndViNames(name: string) {
  let jp = '';
  let vi = name;

  if (name.includes('(') && name.includes(')')) {
    const match = name.match(/^(.*?)\((.*?)\)(.*)$/);
    if (match) {
      const part1 = match[1].trim();
      const part2 = match[2].trim();
      if (part1.toLowerCase().includes('set') || part1.toLowerCase().includes('buffet') || part1.toLowerCase().includes('drink')) {
        jp = part1;
        vi = part2;
      } else {
        jp = part1.replace(/Sét|Set/gi, '').trim();
        vi = part2;
      }
    }
  } else {
    const lower = name.toLowerCase();
    if (lower.includes('wagyu')) {
      jp = '和牛 (Wagyu)';
    } else if (lower.includes('udon')) {
      jp = 'うどん (Udon)';
    } else if (lower.includes('tempura')) {
      jp = '天ぷら (Tempura)';
    } else if (lower.includes('nanban')) {
      jp = 'チキン南蛮 (Chicken Nanban)';
    } else if (lower.includes('bibimbap')) {
      jp = 'ビビンバ (Bibimbap)';
    } else if (lower.includes('sake')) {
      jp = '日本酒 (Sake)';
    } else if (lower.includes('shochu')) {
      jp = '焼酎 (Shochu)';
    } else if (lower.includes('carry') || lower.includes('cà ri') || lower.includes('cary')) {
      jp = 'カレー (Curry)';
    } else if (lower.includes('guma')) {
      jp = '群馬 (Guma)';
    } else if (lower.includes('nagasaki')) {
      jp = '長崎 (Nagasaki)';
    }
  }
  return { jp: jp || 'N/A', vi: vi };
}

// Menu Hierarchy Builder (Level 1 and Level 2 Categories from actual file)
const menuHierarchy = computed(() => {
  const mainCats = menuData.categories.filter(c => c.color === 'pink').map(c => {
    let subcategories: { id: string; name: string; items: MenuItem[] }[] = [];

    if (c.id === 'buffet') {
      if (c.subcategories) {
        subcategories.push(...c.subcategories);
      }
      
      const setDrinkCat = menuData.categories.find(yc => yc.id === 'set_drink');
      if (setDrinkCat && setDrinkCat.items) {
        subcategories.push({
          id: 'set_drink',
          name: 'SET DRINK',
          items: setDrinkCat.items
        });
      }

      const aLaCarteCat = menuData.categories.find(yc => yc.id === 'a_la_carte');
      if (aLaCarteCat && aLaCarteCat.items) {
        subcategories.push({
          id: 'a_la_carte',
          name: 'A LA CARTE',
          items: aLaCarteCat.items
        });
      }

      const set550jpCat = menuData.categories.find(yc => yc.id === 'set_550jp');
      if (set550jpCat && set550jpCat.items) {
        subcategories.push({
          id: 'set_550jp',
          name: 'SET 550JP',
          items: set550jpCat.items
        });
      }
      
      const buffetLauCat = menuData.categories.find(yc => yc.id === 'buffet_lau');
      if (buffetLauCat && buffetLauCat.items) {
        subcategories.push({
          id: 'buffet_lau',
          name: 'BUFFET LẨU',
          items: buffetLauCat.items
        });
      }
    } else if (c.subcategories && c.subcategories.length > 0) {
      subcategories = [...c.subcategories];
    } else if (c.items) {
      subcategories = [{
        id: c.id + '_all',
        name: c.name,
        items: c.items
      }];
    }

    return {
      id: c.id,
      name: c.name,
      subcategories
    };
  });

  return mainCats;
});

// Category and Subcategory tabs helpers
const activeCategoryHasSubcategories = computed(() => {
  const cat = menuHierarchy.value.find(c => c.id === activeCategoryId.value);
  return !!(cat && cat.subcategories && cat.subcategories.length > 0);
});

const shouldShowSubcategoriesRow = computed(() => {
  const cat = menuHierarchy.value.find(c => c.id === activeCategoryId.value);
  if (!cat || !cat.subcategories) return false;
  if (cat.subcategories.length === 1 && cat.subcategories[0].id.endsWith('_all')) {
    return false;
  }
  return cat.subcategories.length > 0;
});

const activeSubcategoriesList = computed(() => {
  const cat = menuHierarchy.value.find(c => c.id === activeCategoryId.value);
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

function getEligibleBuffetGroups(product: MenuItem) {
  const pkgs = ['Buffet 1390', 'Buffet 1150', 'Buffet 680', 'Buffet 490', 'Buffet 380', 'Kids Meal'];
  const matches = pkgs.filter(p => isItemInPackage(product, p));
  return matches.length > 0 ? matches.join(', ') : 'Không áp dụng';
}

function getSetMenuGroup(product: MenuItem) {
  if (['set_lunch', 'set_tiec_chieu_dai', 'set_tiec_chieu_dai_jp', 'set_vietravel'].includes(product.category_id)) {
    return translateCategoryId(product.category_id);
  }
  return 'Không áp dụng';
}

function getDrinkGroup(product: MenuItem) {
  if (['thuc_uong', 'thuc_uong_co_con'].includes(product.category_id)) {
    const subCat = getItemSubcategoryId(product.id);
    return translateSubCategoryId(subCat) || translateCategoryId(product.category_id);
  }
  return 'Không áp dụng';
}

// Item card filter lists
const filteredItems = computed(() => {
  const cat = menuHierarchy.value.find(c => c.id === activeCategoryId.value);
  if (!cat) return [];

  let itemsList: MenuItem[] = [];

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

  // Real-time Text matching filter (Product Name, Code, JP, VI)
  if (searchQuery.value.trim() !== '') {
    const q = searchQuery.value.toLowerCase().trim();
    itemsList = itemsList.filter(item => {
      const names = getJpAndViNames(item.name);
      return item.name.toLowerCase().includes(q) || 
             item.id.toLowerCase().includes(q) ||
             names.jp.toLowerCase().includes(q) ||
             names.vi.toLowerCase().includes(q);
    });
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

  // Price sorting filter
  if (priceSort.value === 'asc') {
    list = [...list].sort((a, b) => a.price - b.price);
  } else if (priceSort.value === 'desc') {
    list = [...list].sort((a, b) => b.price - a.price);
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

function clearCart() {
  if (!selectedTableCode.value) return;
  if (confirm('Bạn có chắc chắn muốn xóa toàn bộ món ăn trong giỏ hàng không?')) {
    activeOrder.value.items = [];
    triggerToast('success', 'Đã xóa toàn bộ món ăn trong giỏ hàng.');
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
  priceSort.value = '';
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
    order.customerName = order.customerName === t.value.guestWalkIn ? `Khách (${tempSettings.value.package})` : order.customerName;
    
    triggerToast('success', t.value.courseLockedSuccess);
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

async function checkoutTable() {
  const code = selectedTableCode.value
  if (!code) return
  const ok = await Swal.fire({
    title: 'Xác nhận thanh toán',
    text: `Đóng bàn ${code}? Tổng tạm tính: ${formatVND(summary.value.grandTotal)}`,
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Tiến hành thanh toán',
    cancelButtonText: 'Huỷ',
  })
  if (!ok.isConfirmed) return
  try {
    // Resolve the mock table code to the real DB UUID — the checkout route
    // expects `tables.id` (UUID), not the human-readable code (e.g. 'A01').
    const { branchId } = useAuth()
    if (!branchId.value) throw new Error('Tài khoản chưa gán chi nhánh.')
    const { data: tableRow, error: tErr } = await supabase
      .from('tables')
      .select('id')
      .eq('branch_id', branchId.value)
      .eq('code', code)
      .maybeSingle()
    if (tErr) throw tErr
    if (!tableRow) throw new Error(`Không tìm thấy bàn ${code} trong DB.`)
    router.push(`/reception/checkout/${(tableRow as { id: string }).id}`)
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    Swal.fire('Lỗi', msg, 'error')
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

// Loading flag for the kitchen-send action — we still keep the local mock
// cart untouched so the POS UI doesn't desync. The Edge Function `add-order-item`
// is called once per cart item against the real `orders` row that backs this
// table.
const kitchenLoading = ref(false)

// menuData items carry slugs like 'set1390_ticket' — these are NOT UUIDs and
// the Edge Function `add-order-item` rejects them at the UUID regex check.
// We resolve the slug → DB UUID lazily from the live `menu_items` table
// (matched by `metadata.slug` first, then by `name` as a fallback).
const menuDbIdCache = ref<Record<string, string>>({})

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
}

async function ensureMenuDbIds(branch: string, items: { id: string; name: string }[]) {
  // Only resolve IDs that aren't already UUIDs AND aren't already cached.
  const missing = items.filter((it) => !isUuid(it.id) && !menuDbIdCache.value[it.id])
  if (missing.length === 0) return
  const slugs = missing.map((it) => it.id)
  const names = missing.map((it) => it.name)
  // Try matching by metadata.slug first (set during seed).
  const { data: bySlug } = await supabase
    .from('menu_items')
    .select('id, name, metadata')
    .eq('branch_id', branch)
    .eq('is_active', true)
    .in('metadata->>slug', slugs)
  for (const row of (bySlug ?? []) as Array<{ id: string; metadata: Record<string, unknown> | null }>) {
    const slug = (row.metadata as { slug?: string } | null)?.slug
    if (slug) menuDbIdCache.value[slug] = row.id
  }
  // Fallback: match remaining slugs by exact name (i18n-blind; demo data is VI).
  const stillMissing = missing.filter((it) => !menuDbIdCache.value[it.id])
  if (stillMissing.length > 0) {
    const { data: byName } = await supabase
      .from('menu_items')
      .select('id, name')
      .eq('branch_id', branch)
      .eq('is_active', true)
      .in('name', names)
    for (const row of (byName ?? []) as Array<{ id: string; name: string }>) {
      const match = stillMissing.find((it) => it.name === row.name)
      if (match) menuDbIdCache.value[match.id] = row.id
    }
  }
}

async function sendToKitchen() {
  if (activeOrder.value.items.length === 0) {
    triggerToast('error', 'Chưa có món ăn nào để gửi nhà bếp nấu.')
    return
  }
  const code = selectedTableCode.value
  if (!code) {
    triggerToast('error', 'Chưa chọn bàn.')
    return
  }
  kitchenLoading.value = true
  try {
    const { branchId } = useAuth()
    if (!branchId.value) throw new Error('Tài khoản chưa gán chi nhánh.')
    const { addItem } = useOrder()
    // 1. Resolve the real `tables.id` from the mock table code.
    const { data: tableRow, error: tableErr } = await supabase
      .from('tables')
      .select('id')
      .eq('branch_id', branchId.value)
      .eq('code', code)
      .maybeSingle()
    if (tableErr) throw tableErr
    if (!tableRow) throw new Error(`Không tìm thấy bàn với mã ${code} trong DB.`)
    const tableId: string = (tableRow as { id: string }).id

    // 2. Find-or-create the in-progress order for this table.
    //    DB enum order_status is 'Pending' | 'Preparing' | 'Served' | 'Paid'
    //    | 'Cancelled'. We must use one of the first three for in-progress
    //    orders — 'Open' / 'Serving' are NOT in the enum and would be
    //    rejected by Postgres (22P02).
    let orderId: string | null = null
    const { data: existing } = await supabase
      .from('orders')
      .select('id')
      .eq('table_id', tableId)
      .in('status', ['Pending', 'Preparing', 'Served'])
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (existing) {
      orderId = (existing as { id: string }).id
    } else {
      const { data: created, error: createErr } = await supabase
        .from('orders')
        .insert({
          branch_id: branchId.value,
          table_id: tableId,
          // 'Pending' = order exists but kitchen hasn't acknowledged yet.
          status: 'Pending',
          subtotal: 0,
          vat: 0,
          vat_rate: 0.08,
          discount: 0,
          total: 0,
        })
        .select('id')
        .single()
      if (createErr) throw createErr
      orderId = (created as { id: string }).id
    }

    // 3. Send each cart line through the Edge Function. The function validates
    // the menu item, computes the price snapshot, and inserts an `order_items`
    // row that the KDS realtime channel picks up.
    await ensureMenuDbIds(
      branchId.value,
      activeOrder.value.items.map((it) => ({ id: it.id, name: it.name })),
    )
    let sent = 0
    const skipped: string[] = []
    for (const line of activeOrder.value.items) {
      const dbId = isUuid(line.id) ? line.id : menuDbIdCache.value[line.id]
      if (!dbId) {
        // Mock item with no DB equivalent — the Edge Function would 400 it,
        // so we skip rather than send garbage. UI surfaces a clear toast.
        skipped.push(line.name)
        continue
      }
      await addItem({
        orderId,
        menuItemId: dbId,
        quantity: line.quantity,
        // CartItem doesn't carry a note field; pass undefined so the Edge
        // Function uses the default (no special instructions).
      })
      sent++
    }
    if (sent > 0) triggerToast('success', `Đã gửi ${sent} món đến KDS.`)
    if (skipped.length > 0) {
      triggerToast(
        'warning',
        `Bỏ qua ${skipped.length} món chưa map DB (${skipped.slice(0, 3).join(', ')}${skipped.length > 3 ? '…' : ''}).`,
      )
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    triggerToast('error', `Gửi bếp thất bại: ${msg}`)
  } finally {
    kitchenLoading.value = false
  }
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

watch(activeSubCategoryId, (newSubId) => {
  if (activeCategoryId.value === 'buffet' && newSubId !== 'all') {
    const pkgMap: Record<string, string> = {
      'buffet_1390': 'Buffet 1390',
      'buffet_1150': 'Buffet 1150',
      'buffet_680': 'Buffet 680',
      'buffet_490': 'Buffet 490',
      'buffet_380': 'Buffet 380',
      'biz_1200': 'Biz 1200',
      'biz_900': 'Biz 900',
      'biz_700': 'Biz 700',
      'set_drink': 'SET DRINK',
      'set_550jp': 'Set 550JP',
      'buffet_lau': 'Buffet Lẩu',
      'a_la_carte': 'A la carte'
    };
    const pkgName = pkgMap[newSubId];
    if (pkgName && selectedTableCode.value) {
      if (!tableSettings.value[selectedTableCode.value]) {
        tableSettings.value[selectedTableCode.value] = {
          package: pkgName,
          drinkGroup: 'A',
          language: 'VI',
          isLocked: false
        };
      } else {
        tableSettings.value[selectedTableCode.value].package = pkgName;
      }
      triggerToast('success', `Đã cấu hình gói ${pkgName} cho bàn ${selectedTableCode.value}`);
    }
  }
});

function selectSubCategory(subId: string) {
  activeSubCategoryId.value = subId;
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
