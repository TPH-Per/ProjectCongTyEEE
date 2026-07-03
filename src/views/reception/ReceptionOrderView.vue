<!-- File: src/views/reception/ReceptionOrderView.vue -->
<template>
  <div class="h-screen w-full flex overflow-hidden font-sans select-none text-gray-800 bg-[#1e1e1e] relative">
    
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

    <!-- MAIN POS CONTAINER -->
    <div class="flex-1 flex flex-col min-h-0 overflow-hidden bg-[#3a3a3a] text-gray-200">
      
      <!-- 1. TOP BAR (Header) -->
      <header class="h-16 shrink-0 bg-[#2d2d2d] border-b border-[#1e1e1e] flex items-center justify-between px-6 select-none z-10 text-white shadow-md">
        <!-- Navigation Tabs -->
        <div class="flex items-center gap-2">
          <button class="p-2 hover:bg-[#3a3a3a] rounded-lg transition-colors mr-2 text-gray-400 hover:text-white">
            ☰
          </button>
          
          <button 
            @click="activeMainTab = 'invoice'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all', 
              activeMainTab === 'invoice' ? 'bg-[#ff8f00] text-white shadow' : 'text-gray-400 hover:text-white'
            ]"
          >
            Phiếu
          </button>
          
          <button 
            @click="activeMainTab = 'menu'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5', 
              activeMainTab === 'menu' ? 'bg-[#ff8f00] text-white shadow' : 'text-gray-400 hover:text-white'
            ]"
          >
            Chi tiết
            <span class="bg-red-650 bg-red-600 text-white text-[9px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center">
              {{ activeOrder.items ? activeOrder.items.reduce((sum, item) => sum + item.quantity, 0) : 0 }}
            </span>
          </button>
          
          <button 
            @click="activeMainTab = 'table_map'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all', 
              activeMainTab === 'table_map' ? 'bg-[#ff8f00] text-white shadow' : 'text-gray-400 hover:text-white'
            ]"
          >
            Sơ đồ bàn
          </button>
        </div>

        <!-- Cashier info -->
        <div class="flex items-center gap-6 text-xs font-bold text-gray-300">
          <div>
            <span class="text-gray-500 mr-1">Thu Ngân:</span>
            <span class="text-white">{{ profile?.full_name || 'mo' }}</span>
          </div>
          <div class="font-mono text-gray-400 flex items-center gap-2">
            <span>{{ formattedDate }} {{ formattedTime }}</span>
            <span class="bg-purple-900/60 border border-purple-800 text-purple-300 px-2 py-0.5 rounded text-[10px]">Ca: 1</span>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2">
          <button class="relative p-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] rounded-lg transition-colors mr-2" title="Thông báo">
            🔔
            <span class="absolute -top-1 -right-1 bg-red-650 text-white text-[8px] font-black w-4 h-4 rounded-full flex items-center justify-center animate-pulse">99+</span>
          </button>
          
          <button 
            @click="goBack"
            class="px-4 py-2 bg-[#E8772E] hover:bg-[#d0621f] text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow"
          >
            Tạm thoát
          </button>
          
          <button 
            @click="goBack"
            class="px-4 py-2 bg-red-650 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow"
          >
            Quay về
          </button>
        </div>
      </header>

      <!-- Split body container -->
      <div class="flex-1 flex min-h-0 relative">
        
        <!-- 2. LEFT PANEL - ORDER DETAILS (30% width) -->
        <aside class="w-[30%] bg-[#2d2d2d] border-r border-[#1e1e1e] flex flex-col justify-between overflow-hidden">
          
          <!-- Header thông tin bàn -->
          <div class="p-4 border-b border-[#3a3a3a] shrink-0 bg-[#232323] text-xs space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-sm font-black text-[#ff8f00]">Vị trí: {{ selectedTableCode || '[Chưa chọn]' }}</span>
              <span class="text-[10px] text-gray-500 font-bold">Số lần in: 3</span>
            </div>
            <div class="flex justify-between items-center text-[10px] text-gray-400">
              <span>TG tạo: {{ activeOrder.openedTime || '02/07/2026 14:09' }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-gray-400 shrink-0">Khách hàng:</span>
              <input 
                v-model="activeOrder.customerName"
                placeholder="Nhập tên khách..." 
                class="bg-[#3a3a3a] border border-[#4a4a4a] rounded px-2 py-0.5 text-xs text-white placeholder-gray-600 focus:outline-none focus:border-[#ff8f00] flex-1 font-bold"
              />
            </div>
          </div>

          <!-- Bảng món ăn scroll area -->
          <div class="flex-1 overflow-y-auto p-3 ordering-screen-scrollbar text-xs">
            <!-- Columns headers -->
            <div class="grid grid-cols-[38%_20%_10%_14%_18%] font-bold text-gray-500 uppercase tracking-wider pb-2 border-b border-[#3a3a3a] px-1 select-none text-[9px] text-center">
              <div class="text-left">Tên hàng</div>
              <div class="text-right">Đơn giá</div>
              <div>VAT</div>
              <div class="text-right">Giảm</div>
              <div class="text-right">Tổng</div>
            </div>

            <!-- Empty cart state -->
            <div v-if="!activeOrder.items || activeOrder.items.length === 0" class="py-20 text-center text-gray-500 select-none">
              <div class="text-4xl mb-3">🛒</div>
              <p class="font-bold text-gray-400">Đơn hàng trống</p>
              <p class="text-[10px] text-gray-500 mt-1 max-w-[180px] mx-auto leading-relaxed">Chọn bàn rồi chọn món từ thực đơn để thêm.</p>
            </div>

            <!-- Cart items rows -->
            <div v-else class="divide-y divide-[#3a3a3a]/40 mt-1">
              <div 
                v-for="item in activeOrder.items" 
                :key="item.id"
                class="grid grid-cols-[38%_20%_10%_14%_18%] items-start py-2.5 hover:bg-[#333333] px-1 rounded-lg transition-colors group relative"
              >
                <div class="pr-1">
                  <div class="font-bold text-gray-100 leading-tight">{{ item.name }}</div>
                  <div class="text-[9px] text-gray-505 text-gray-500 mt-0.5">({{ item.unit }})</div>
                  
                  <!-- Counter controls -->
                  <div class="flex items-center gap-1 mt-1.5 select-none">
                    <button 
                      @click="updateQty(item.id, -1)" 
                      class="w-4 h-4 rounded bg-[#3a3a3a] text-gray-300 hover:bg-[#ff8f00] hover:text-white flex items-center justify-center font-bold text-[10px] transition-all"
                    >-</button>
                    <span class="font-bold font-mono text-[9px] px-1 py-0.5 text-white bg-[#1e1e1e] rounded min-w-[16px] text-center">{{ item.quantity }}</span>
                    <button 
                      @click="updateQty(item.id, 1)" 
                      class="w-4 h-4 rounded bg-[#3a3a3a] text-gray-300 hover:bg-[#ff8f00] hover:text-white flex items-center justify-center font-bold text-[10px] transition-all"
                    >+</button>
                    <button 
                      @click="removeItem(item.id)" 
                      class="text-red-505 text-red-500 hover:text-red-400 text-[10px] ml-2 opacity-0 group-hover:opacity-100 transition-opacity"
                    >✕</button>
                  </div>
                </div>

                <div class="text-right font-mono font-bold text-gray-300 text-[11px] mt-0.5">
                  {{ formatVND(item.price) }}
                </div>

                <div class="text-center font-mono text-gray-400 text-[11px] mt-0.5">8%</div>

                <div class="text-right font-mono text-[11px] text-gray-400 mt-0.5">
                  {{ item.name.toLowerCase().includes('lunch') ? formatVND(item.price * 0.5) : '0đ' }}
                </div>

                <div class="text-right font-mono font-bold text-[#ff8f00] text-[11px] mt-0.5">
                  {{ formatVND(calculateNetPrice(item)) }}
                </div>
              </div>
            </div>
          </div>

          <!-- Pricing summary / Footer info -->
          <div class="border-t border-[#3a3a3a] bg-[#1e1e1e] p-4 text-xs font-semibold text-gray-300 space-y-2 shrink-0">
            <div class="flex justify-between items-center text-gray-400">
              <span>Tiền hàng:</span>
              <span class="font-mono text-gray-200">{{ formatVND(summary.subtotal) }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-400">
              <span>Giảm:</span>
              <span class="font-mono text-red-400">{{ formatVND(summary.discount) }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-400">
              <span>VAT (8%):</span>
              <span class="font-mono text-gray-300">{{ formatVND(summary.vat) }}</span>
            </div>
            <div class="flex justify-between items-center text-gray-400">
              <span>Phí phục vụ:</span>
              <span class="font-mono">0đ</span>
            </div>

            <div class="flex justify-between items-center text-sm font-bold text-white pt-2 border-t border-[#3a3a3a]">
              <span>TỔNG TIỀN:</span>
              <span class="text-lg font-mono text-[#ff8f00]">{{ formatVND(summary.grandTotal) }}</span>
            </div>
          </div>

          <!-- Bottom Navigation (Sơ đồ bàn, Thực đơn, Phiếu) -->
          <div class="border-t border-[#3a3a3a] bg-[#1a1a1a] p-2 flex gap-1 shrink-0 select-none">
            <button 
              @click="activeMainTab = 'table_map'"
              :class="[
                'flex-1 py-2 text-xs font-bold rounded-lg text-center transition-all',
                activeMainTab === 'table_map' ? 'bg-[#ff8f00] text-white shadow' : 'bg-[#2d2d2d] text-gray-400 hover:text-white'
              ]"
            >
              Sơ đồ bàn
            </button>
            <button 
              @click="activeMainTab = 'menu'"
              :class="[
                'flex-1 py-2 text-xs font-bold rounded-lg text-center transition-all',
                activeMainTab === 'menu' ? 'bg-[#ff8f00] text-white shadow' : 'bg-[#2d2d2d] text-gray-400 hover:text-white'
              ]"
            >
              Thực đơn
            </button>
            <button 
              @click="activeMainTab = 'invoice'"
              :class="[
                'flex-1 py-2 text-xs font-bold rounded-lg text-center transition-all',
                activeMainTab === 'invoice' ? 'bg-[#ff8f00] text-white shadow' : 'bg-[#2d2d2d] text-gray-400 hover:text-white'
              ]"
            >
              Phiếu
            </button>
          </div>
        </aside>

        <!-- 3. MAIN AREA (70% width) -->
        <main class="w-[70%] bg-[#3a3a3a] flex flex-col justify-between overflow-hidden relative">
          
          <!-- TAB A: TABLE MAP (Sơ đồ bàn) -->
          <div v-if="activeMainTab === 'table_map'" class="flex-1 flex flex-col justify-between overflow-hidden p-5">
            <!-- Table Map scrollable grid -->
            <div class="flex-1 overflow-y-auto ordering-screen-scrollbar space-y-6 pr-1">
              
              <!-- Grid Layout of all tables -->
              <div class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-4">
                <div 
                  v-for="table in filteredTables" 
                  :key="table.code"
                  @click="selectTable(table.code)"
                  :class="[
                    'p-3 rounded-xl border-2 transition-all cursor-pointer flex flex-col justify-between min-h-[110px] text-center hover:scale-[1.02] active:scale-[0.98] duration-200 shadow-sm',
                    selectedTableCode === table.code ? 'border-orange-500 ring-2 ring-orange-400 bg-orange-50/5' : 'border-transparent',
                    getTableStatusClass(table)
                  ]"
                >
                  <div class="flex justify-between items-center select-none">
                    <span class="font-extrabold text-sm">{{ table.code }}</span>
                    <span v-if="table.status === 'Serving' || table.status === 'Arrived'" class="bg-black/20 px-1.5 py-0.5 rounded text-[9px] font-black">
                      {{ table.capacity }}
                    </span>
                  </div>

                  <div v-if="table.status === 'Serving' || table.status === 'Arrived'" class="mt-2 text-[10px] space-y-0.5">
                    <div class="font-extrabold text-gray-200 truncate">{{ table.customerName || 'Khách' }}</div>
                    <div class="text-gray-400">{{ table.checkInTime || '17:00' }} — {{ table.occupiedDuration || '0ph' }}</div>
                    <div class="font-black text-[#ff8f00] mt-1">{{ table.billAmount || '[69.660]' }}</div>
                  </div>
                  <div v-else-if="table.status === 'Reserved'" class="mt-2 text-[10px] text-red-300">
                    <div class="font-black truncate">{{ table.customerName || 'Đã đặt' }}</div>
                    <div class="text-xs mt-1">🔒</div>
                  </div>
                  <div v-else class="mt-2 text-[10px] text-gray-500">
                    Trống
                  </div>
                </div>
              </div>
            </div>

            <!-- Bottom Controls of Sơ đồ bàn -->
            <div class="shrink-0 bg-[#2d2d2d] p-3 rounded-xl border border-[#4a4a4a] flex items-center justify-between mt-4">
              <div class="flex items-center gap-3">
                <span class="text-xs text-gray-400 font-bold uppercase">Khu vực:</span>
                <select 
                  v-model="selectedArea" 
                  class="bg-[#3a3a3a] text-xs text-white border border-[#4a4a4a] rounded-lg px-3 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer font-bold"
                >
                  <option value="Tất cả">Tất cả khu</option>
                  <option v-for="area in restaurantStore.areas" :key="area.name" :value="area.name">
                    {{ area.name }}
                  </option>
                </select>
              </div>

              <div class="flex items-center gap-2">
                <button 
                  @click="selectedArea = 'Tất cả'" 
                  class="px-3.5 py-1.5 bg-[#ff8f00] hover:bg-[#e07f00] text-white text-xs font-bold rounded-lg transition-all shadow font-sans"
                >
                  Tất cả
                </button>
                <button class="p-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] rounded-lg transition-colors text-xs" title="Lưới">
                  📊
                </button>
              </div>
            </div>
          </div>

          <!-- TAB B: MENU (Thực đơn) -->
          <div v-if="activeMainTab === 'menu'" class="flex-1 flex flex-col justify-between overflow-hidden">
            <!-- Products scrollable grid container -->
            <div class="flex-1 overflow-y-auto p-5 ordering-screen-scrollbar">
              
              <!-- Quick filters & Preferences bar -->
              <div class="flex flex-wrap items-center justify-between gap-3 mb-5 select-none shrink-0 bg-[#2d2d2d] p-3 rounded-xl border border-[#4a4a4a]">
                <div class="flex flex-wrap items-center gap-3">
                  <div class="flex gap-1.5">
                    <button 
                      v-for="f in [{id: 'favorites', label: '⭐ Yêu thích'}, {id: 'popular', label: '🔥 Bán chạy'}, {id: 'recent', label: '🕒 Gần đây'}]"
                      :key="f.id"
                      @click="toggleQuickFilter(activeQuickFilter === f.id ? '' : (f.id as any))"
                      :class="[
                        'px-3 py-1.5 rounded-full text-xs font-bold transition-all border shrink-0 active:scale-95',
                        activeQuickFilter === f.id
                          ? 'bg-[#ff8f00] border-[#ff8f00] text-white shadow'
                          : 'bg-[#3a3a3a] border-[#4a4a4a] text-gray-400 hover:bg-[#4a4a4a] hover:text-white'
                      ]"
                    >
                      {{ f.label }}
                    </button>
                  </div>

                  <div class="flex items-center gap-2 border-l border-[#4a4a4a] pl-3">
                    <select 
                      v-model="activeStatusFilter" 
                      class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer font-bold"
                    >
                      <option value="all">Tất cả món</option>
                      <option value="available">Còn món</option>
                      <option value="unavailable">Hết món</option>
                    </select>

                    <select 
                      v-model="priceSort" 
                      class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer font-bold"
                    >
                      <option value="">Không sắp xếp</option>
                      <option value="asc">Giá: Thấp -> Cao</option>
                      <option value="desc">Giá: Cao -> Thấp</option>
                    </select>
                  </div>
                </div>

                <!-- Search Input in menu grid -->
                <div class="relative flex items-center bg-[#3a3a3a] border border-[#4a4a4a] rounded-lg px-3 py-1.5 focus-within:border-[#ff8f00] transition-colors w-48">
                  <input 
                    v-model="searchQuery" 
                    type="text" 
                    placeholder="Tìm món..." 
                    class="bg-transparent border-none text-xs text-white placeholder-gray-500 focus:outline-none w-full"
                  />
                </div>
              </div>

              <!-- Product Grid -->
              <div v-if="finalFilteredItems.length === 0" class="h-64 flex flex-col items-center justify-center text-gray-500 text-center border border-dashed border-[#4a4a4a] rounded-2xl p-6 select-none">
                <div class="text-4xl mb-2">🍽️</div>
                <h4 class="font-bold text-gray-400 text-xs">Không tìm thấy món ăn phù hợp</h4>
              </div>

              <div v-else class="menu-grid">
                <div 
                  v-for="product in finalFilteredItems" 
                  :key="product.id"
                  @click="handleCardClick(product)"
                  :class="[
                    'menu-card border cursor-pointer transition-all duration-350 relative overflow-hidden group select-none',
                    getCartItemQty(product.id) > 0 ? 'in-cart border-[#ff8f00]' : 'border-[#404040]',
                    !getEnrichedItem(product).isAvailable ? 'opacity-40 cursor-not-allowed' : ''
                  ]"
                >
                  <div v-if="getCartItemQty(product.id) > 0" class="qty-badge">
                    {{ getCartItemQty(product.id) }}
                  </div>
                  
                  <span v-if="favoriteIds.includes(product.id)" class="favorite-star text-xs absolute top-1 right-1">⭐</span>

                  <h3 class="item-name text-xs font-bold text-white mt-1 pr-4 truncate" :style="{ color: getCartItemQty(product.id) > 0 ? '#ff8f00' : '#ffffff' }">
                    {{ getJpAndViNames(product.name).vi }}
                  </h3>

                  <div class="item-price text-xs font-black text-[#ff8f00] mt-2">
                    {{ formatPrice(product.price) }}
                  </div>

                  <div class="card-footer mt-auto pt-2 flex items-center justify-between text-[10px] text-gray-400">
                    <span>ĐVT: {{ product.unit }}</span>
                    <span class="w-4 h-4 rounded bg-[#3a3a3a] text-white flex items-center justify-center font-bold">+</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Categories Selection Bottom Navigation -->
            <div class="bg-[#2d2d2d] border-t border-[#1e1e1e] flex flex-col shrink-0 select-none">
              <!-- Sub Categories -->
              <div class="p-2.5 border-b border-[#1e1e1e] category-container-sub flex gap-1.5 overflow-x-auto whitespace-nowrap">
                <button 
                  @click="selectSubCategory('all')"
                  :style="{
                    backgroundColor: activeSubCategoryId === 'all' ? '#ff8f00' : '#f5a623',
                    border: '2px solid transparent'
                  }"
                  class="category-btn-sub px-3 py-1.5 rounded-lg text-[11px] font-extrabold text-white transition-all shadow-sm font-sans"
                >
                  Tất cả
                </button>
                <button 
                  v-for="sub in activeSubcategoriesList"
                  :key="sub.id"
                  @click="selectSubCategory(sub.id)"
                  :style="{
                    backgroundColor: activeSubCategoryId === sub.id ? '#ff8f00' : '#f5a623',
                    border: '2px solid transparent'
                  }"
                  class="category-btn-sub px-3 py-1.5 rounded-lg text-[11px] font-extrabold text-white transition-all shadow-sm font-sans"
                >
                  {{ sub.name }}
                </button>
              </div>

              <!-- Main Categories -->
              <div class="p-3 category-container-main flex gap-2 overflow-x-auto whitespace-nowrap">
                <button 
                  v-for="cat in menuHierarchy"
                  :key="cat.id"
                  @click="selectCategory(cat.id)"
                  :style="{
                    backgroundColor: activeCategoryId === cat.id ? '#c62828' : '#b56576',
                  }"
                  class="category-btn-main px-4 py-2.5 rounded-xl text-xs font-bold text-white transition-all flex items-center gap-1.5 uppercase shadow-sm shrink-0 font-sans"
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
          </div>

          <!-- TAB C: INVOICE / BILL (Phiếu) -->
          <div v-if="activeMainTab === 'invoice'" class="flex-1 overflow-y-auto p-6 ordering-screen-scrollbar text-xs">
            <div class="max-w-xl mx-auto bg-[#2d2d2d] rounded-2xl p-6 border border-[#4a4a4a] space-y-6 shadow-lg">
              <div class="text-center border-b border-[#3a3a3a] pb-4">
                <h3 class="text-lg font-black text-white tracking-wide uppercase">Hóa đơn thanh toán</h3>
                <p class="text-[10px] text-gray-500 font-bold uppercase tracking-wider mt-1">Bàn: {{ selectedTableCode || '[Chưa chọn]' }} — Số: CN3126070200014</p>
              </div>

              <div class="grid grid-cols-2 gap-4 text-xs font-bold">
                <div class="space-y-1">
                  <span class="text-gray-400 block">Ngày lập:</span>
                  <span class="text-white">{{ activeOrder.openedTime || '02/07/2026 14:09' }}</span>
                </div>
                <div class="space-y-1">
                  <span class="text-gray-400 block">Nhân viên phục vụ:</span>
                  <span class="text-white">{{ profile?.full_name || 'mo' }}</span>
                </div>
              </div>

              <!-- Cart summary block inside invoice -->
              <div class="border border-[#3a3a3a] rounded-xl overflow-hidden bg-[#232323]">
                <div class="bg-gray-800/40 p-3 font-bold border-b border-[#3a3a3a] flex justify-between">
                  <span>Chi tiết món ăn</span>
                  <span class="text-gray-400">{{ activeOrder.items ? activeOrder.items.length : 0 }} món</span>
                </div>
                <div class="p-3 divide-y divide-[#3a3a3a]/40 max-h-48 overflow-y-auto ordering-screen-scrollbar">
                  <div v-for="item in activeOrder.items" :key="item.id" class="py-2 flex justify-between items-center text-xs">
                    <div>
                      <div class="font-bold text-gray-205 text-gray-200">{{ item.name }}</div>
                      <div class="text-[10px] text-gray-505 text-gray-500">x{{ item.quantity }} {{ item.unit }}</div>
                    </div>
                    <div class="font-mono text-gray-300">{{ formatVND(calculateNetPrice(item)) }}</div>
                  </div>
                </div>
              </div>

              <!-- Total calculation and actions -->
              <div class="space-y-3 pt-3 border-t border-[#3a3a3a]">
                <div class="flex justify-between items-center font-bold">
                  <span class="text-gray-400">Tiền hàng:</span>
                  <span class="font-mono text-gray-200">{{ formatVND(summary.subtotal) }}</span>
                </div>
                <div class="flex justify-between items-center font-bold">
                  <span class="text-gray-400">Giảm giá:</span>
                  <span class="font-mono text-red-400">{{ formatVND(summary.discount) }}</span>
                </div>
                <div class="flex justify-between items-center font-bold">
                  <span class="text-gray-400">VAT (8%):</span>
                  <span class="font-mono text-gray-300">{{ formatVND(summary.vat) }}</span>
                </div>
                <div class="flex justify-between items-center font-bold text-sm text-white pt-2 border-t border-[#3a3a3a]">
                  <span>Tổng thanh toán:</span>
                  <span class="text-xl font-mono text-[#ff8f00]">{{ formatVND(summary.grandTotal) }}</span>
                </div>
              </div>

              <!-- Button actions -->
              <div class="grid grid-cols-2 gap-4 pt-4">
                <button 
                  @click="printDraftBill"
                  :disabled="!selectedTableCode"
                  class="py-3 bg-[#4a4a4a] hover:bg-[#5a5a5a] text-white text-xs font-bold rounded-xl transition-all shadow-md active:scale-95 font-sans"
                >
                  🖨️ In hóa đơn tạm
                </button>
                <button 
                  @click="checkoutTable"
                  :disabled="!selectedTableCode || !activeOrder.items || activeOrder.items.length === 0"
                  class="py-3 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-md transition-all active:scale-95 font-sans"
                >
                  💸 Thanh toán & In Bill
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
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col relative z-10 animate-scale-up border border-[#e0e0e0] text-gray-800">
            
            <!-- Header Modal with Clean Colors -->
            <header class="bg-gradient-to-r from-[#1976d2] to-[#1565c0] text-white px-6 py-4 flex justify-between items-center shrink-0">
              <h3 class="text-base font-bold tracking-tight select-none">{{ t('reception_order.chi_tiet_mon_an') }}</h3>
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
                    >{{ t('reception_order.het_hang') }}</span>
                  </div>
                  
                  <span 
                    :class="[
                      'w-full py-1 text-center font-bold text-[10px] uppercase rounded-lg tracking-wider border',
                      getEnrichedItem(selectedProductForDetail).isAvailable ? 'bg-emerald-50 text-emerald-700 border-emerald-150' : 'bg-red-50 text-red-700 border-red-150'
                    ]"
                  >
                    ● {{ getEnrichedItem(selectedProductForDetail).isAvailable ? t('reception_order.con_hang_phuc_vu_text') : t('reception_order.het_hang_text') }}
                  </span>
                </div>

                <!-- Column Right (60% width -> 6 cols) -->
                <div class="md:col-span-6 space-y-4 font-bold text-xs text-gray-700">
                  <div class="space-y-1">
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ten_mon') }}</label>
                    <input 
                      type="text" 
                      :value="selectedProductForDetail.name" 
                      readonly 
                      class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                    />
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ma_mon') }}</label>
                      <input 
                        type="text" 
                        :value="selectedProductForDetail.id" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-mono text-gray-800 focus:outline-none"
                      />
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.don_vi_tinh') }}</label>
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
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.so_luong') }}</label>
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
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.don_gia_vnd') }}</label>
                      <input 
                        type="text" 
                        :value="isItemInPackage(selectedProductForDetail, activeSettings.package) ? t('reception_order.0d_trong_goi') : formatVND(selectedProductForDetail.price)" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT and Service charges (VAT default checked, Service unchecked) -->
                  <div class="flex items-center gap-6 py-1 select-none text-[#c62828]">
                    <label class="flex items-center gap-2 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalVAT" class="w-4 h-4 accent-[#1976d2]" />{{ t('reception_order.bao_gom_vat') }}</label>
                    <label class="flex items-center gap-2 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalPPV" class="w-4 h-4 accent-[#1976d2]" />{{ t('reception_order.bao_gom_ppv') }}</label>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.loai_tien_te') }}</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-[#e0e0e0] rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none">
                        <option value="VND">{{ t('reception_order.vnd_viet_nam_dong') }}</option>
                        <option value="USD">{{ t('reception_order.usd_do_la_my') }}</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ty_gia') }}</label>
                      <input 
                        type="text" 
                        v-model="modalRate" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ghi_chu') }}</label>
                    <textarea 
                      v-model="modalItemNote" 
                      :placeholder="t('reception_order.them_ghi_chu_dac_thu_it_da_nhi')" 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2.5 font-bold text-gray-855 h-20 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">{{ t('reception_order.phan_nhom_thuc_don_he_thong') }}</h5>
                    <div class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]">
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.nhom_san_pham') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ translateCategoryId(selectedProductForDetail.category_id) }}
                          <span v-if="getItemSubcategoryId(selectedProductForDetail.id)">
                            &gt; {{ translateSubCategoryId(getItemSubcategoryId(selectedProductForDetail.id)) }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_buffet') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getEligibleBuffetGroups(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_set_menu') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getSetMenuGroup(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_do_uong') }}</span>
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
                      {{ t('reception_order.ma') }}: {{ selectedProductForDetail.id }} • {{ t('reception_order.don_vi') }}: {{ selectedProductForDetail.unit }}
                    </p>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <!-- Qty editor -->
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.so_luong') }}</label>
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
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.don_gia_vnd') }}</label>
                      <input 
                        type="text" 
                        :value="isItemInPackage(selectedProductForDetail, activeSettings.package) ? t('reception_order.0d_trong_goi') : formatVND(selectedProductForDetail.price)" 
                        readonly 
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2.5 py-1.5 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT/PPV checks -->
                  <div class="flex items-center gap-3.5 select-none text-[#c62828] text-[11px]">
                    <label class="flex items-center gap-1 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalVAT" class="w-3.5 h-3.5 accent-[#1976d2]" />
                      {{ t('reception_order.vat_percent') }}
                    </label>
                    <label class="flex items-center gap-1 cursor-pointer font-bold">
                      <input type="checkbox" v-model="modalPPV" class="w-3.5 h-3.5 accent-[#1976d2]" />
                      {{ t('reception_order.ppv_percent') }}
                    </label>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.tien_te') }}</label>
                      <select v-model="modalCurrency" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2 py-1.5 font-bold text-gray-850 focus:outline-none text-[11px]">
                        <option value="VND">VND</option>
                        <option value="USD">USD</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ty_gia') }}</label>
                      <input type="text" v-model="modalRate" readonly class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none" />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">{{ t('reception_order.ghi_chu_chung') }}</label>
                    <textarea 
                      v-model="modalItemNote" 
                      :placeholder="t('reception_order.them_ghi_chu_cho_ca_mon_an')" 
                      class="w-full border border-[#e0e0e0] rounded-lg p-2 font-bold text-gray-850 h-16 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2">{{ t('reception_order.phan_nhom_thuc_don_he_thong') }}</h5>
                    <div class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]">
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.nhom_san_pham') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ translateCategoryId(selectedProductForDetail.category_id) }}
                          <span v-if="getItemSubcategoryId(selectedProductForDetail.id)">
                            &gt; {{ translateSubCategoryId(getItemSubcategoryId(selectedProductForDetail.id)) }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_buffet') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getEligibleBuffetGroups(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_set_menu') }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">{{ getSetMenuGroup(selectedProductForDetail) }}</div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{ t('reception_order.goi_do_uong') }}</span>
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
                          ({{ t('reception_order.toi_thieu') }} {{ activeGroup.minSelection }} - {{ t('reception_order.toi_da') }} {{ activeGroup.maxSelection }})
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
                              :placeholder="t('reception_order.them_ghi_chu_rieng_cho_lua_cho')"
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
                        {{ t('reception_order.vui_long_chon_them_it_nhat') }} {{ activeGroup.minSelection - activeGroupSelectedCount }} {{ t('reception_order.lua_chon_nua') }}
                      </span>
                      <span v-else-if="activeGroupSelectedCount > activeGroup.maxSelection">
                        {{ t('reception_order.da_vuot_qua_gioi_han_toi_da') }} {{ activeGroup.maxSelection }} {{ t('reception_order.lua_chon') }}
                      </span>
                      <span v-else>
                        {{ t('reception_order.da_chon_du_so_luong') }} {{ activeGroup.title }}
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
              >{{ t('reception_order.huy_bo_esc') }}</button>
              
              <button 
                @click="saveDetailPanelQty"
                :disabled="!getEnrichedItem(selectedProductForDetail).isAvailable || !isSelectionValid"
                :class="[
                  'px-6 py-2.5 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 flex items-center gap-1.5',
                  (getEnrichedItem(selectedProductForDetail).isAvailable && isSelectionValid) ? 'bg-[#2e7d32] hover:bg-[#1b5e20]' : 'bg-gray-400 cursor-not-allowed opacity-50'
                ]"
              >
                <span>➕</span>
                <span>{{ t('reception_order.them_vao_gio_hang') }}</span>
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
            <span>{{ t('reception_order.cau_hinh_goi_course_phuc_vu') }} {{ activeOrder.tableCode }}</span>
          </h3>

          <!-- PACKAGE GRID (2 cols) -->
          <div class="mb-4">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2.5 select-none">{{ t('reception_order.1_chon_goi_an_phuc_vu_course_p') }}</h4>
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
                    {{ name.includes('Buffet') ? t('reception_order.thoi_luong_phuc_vu_2_tieng') : t('reception_order.menu_goi_theo_bua_tiec') }}
                  </p>
                </div>
                <div class="text-right border-t border-[#f0f0f0] pt-2 mt-3">
                  <span class="text-sm font-bold text-[#c62828]">{{ price.toLocaleString('vi-VN') }}đ / {{ t('reception_order.ve') }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- DRINK GROUP SELECTOR CARDS -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">{{ t('reception_order.2_chon_nhom_do_uong_kem_theo_d') }}</h4>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ t('reception_order.nhom_a_soft_drink') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ t('reception_order.nuoc_ngot_uong_khong_gioi_han') }}</p>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ t('reception_order.nhom_b_premium_drink') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ t('reception_order.ruou_bia_cao_cap_uong_trong_2') }}</p>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ t('reception_order.nhom_c_premium_alt') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ t('reception_order.ruou_bia_thay_the_dung_2_gio_f') }}</p>
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
                    <h6 class="text-xs font-bold text-gray-800">{{ t('reception_order.nhom_d_a_la_carte') }}</h6>
                    <p class="text-[9px] text-gray-400 font-medium">{{ t('reception_order.goi_do_uong_le_tinh_tien_rieng') }}</p>
                  </div>
                </div>
                <span class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black" :class="tempSettings.drinkGroup === 'D' ? 'bg-[#ff8f00] text-white border-[#ff8f00]' : 'text-transparent'">✓</span>
              </div>

            </div>
          </div>

          <!-- LANGUAGES CHOICE -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none">{{ t('reception_order.3_ngon_ngu_giao_dien_hien_thi') }}</h4>
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
                <span v-if="lang === 'VI'">{{ t('reception_order.tieng_viet') }}</span>
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
            >{{ t('reception_order.huy_bo_quay_lai') }}</button>
            
            <button 
              v-if="activeSettings.isLocked"
              @click="openPinModal"
              class="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >{{ t('reception_order.pin_sua_cau_hinh') }}</button>
            <button 
              v-else
              @click="confirmPackageSelection"
              class="flex-1 py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >{{ t('reception_order.xac_nhan_khoa_course') }}</button>
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
          <h4 class="text-sm font-bold text-gray-900 mb-1">{{ t('reception_order.ma_pin_xac_thuc_quan_ly') }}</h4>
          <p class="text-[10px] text-gray-400 font-semibold mb-4 leading-normal">{{ t('reception_order.nhap_ma_pin_cua_quan_ly_de_mo') }}</p>

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
import { useLanguageStore } from '@/stores/useLanguageStore';
const langStore = useLanguageStore()
  const t = langStore.t;


import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useRestaurantStore } from '@/stores/restaurantStore';
import { storeToRefs } from 'pinia';
import { menuData, type MenuItem } from '@/data/menuData'
import { supabase } from '@/lib/supabase'
import { applyPackage, calculateItemUnitPrice } from '@/utils/packageRules'
import { useAuth } from '@/composables/useAuth'
import { useTable } from '@/composables/useTable'
import { useMenu } from '@/composables/useMenu'
import Swal from 'sweetalert2'
import { 
  Utensils, 
  Grid, 
  Store, 
  Clock, 
  Calendar, 
  CreditCard, 
  Briefcase, 
  BadgePlus, 
  BadgeMinus, 
  Receipt, 
  BarChart3, 
  LogOut, 
  CheckCircle, 
  XCircle, 
  Eye 
} from 'lucide-vue-next'

const router = useRouter();
const restaurantStore = useRestaurantStore();
const { selectedTableCode } = storeToRefs(restaurantStore);
const { listTables } = useTable()
const { getItems } = useMenu()
const { profile } = useAuth();

const activeMainTab = ref<'table_map' | 'menu' | 'invoice'>(selectedTableCode.value ? 'menu' : 'table_map');
const selectedArea = ref('Tất cả');

const currentClock = ref(new Date());
let clockInterval: any;

const formattedTime = computed(() => {
  return currentClock.value.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false })
});

const formattedDate = computed(() => {
  return currentClock.value.toLocaleDateString('vi-VN')
});

const filteredTables = computed(() => {
  const list: any[] = [];
  restaurantStore.areas.forEach(area => {
    if (selectedArea.value === 'Tất cả' || area.name === selectedArea.value) {
      area.tables.forEach(table => {
        list.push({
          ...table,
          areaName: area.name
        });
      });
    }
  });
  return list;
});

function getTableStatusClass(table: any): string {
  if (table.status === 'Serving') {
    return 'bg-emerald-950/40 border-emerald-800 text-emerald-300 hover:bg-emerald-900/30'
  } else if (table.status === 'Arrived') {
    return 'bg-green-950/40 border-green-800 text-green-300 hover:bg-green-900/30'
  } else if (table.status === 'Reserved') {
    return 'bg-red-950/40 border-red-900/50 text-red-400 hover:bg-red-900/30'
  } else if (table.status === 'pending_payment') {
    return 'bg-amber-950/40 border-amber-900/50 text-amber-400 hover:bg-amber-900/30'
  } else {
    return 'bg-gray-800/40 border-gray-700 text-gray-400 hover:bg-gray-700/30'
  }
}

function selectTable(code: string) {
  selectedTableCode.value = code;
  activeMainTab.value = 'menu';
}

function calculateNetPrice(item: any): number {
  // Unit price is resolved by the shared package-rule engine (handles
  // package = free and lunch 50% in one place). VAT per-line is a UI
  // concern of this row, so it stays local.
  const price = calculateItemUnitPrice(
    {
      id: item.id,
      name: item.name,
      category_id: item.category_id ?? '',
      subCatId: getItemSubcategoryId(item.id),
      price: item.price,
    },
    activeSettings.value.package,
  )
  const vat = price * 0.08;
  return Math.round(price + vat) * item.quantity;
}

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
    unit: item.unit || t('reception_order.ve'),
    price: item.price,
    price_display: formatVND(item.price),
    category_id: item.category_id || ''
  };
}

function formatPrice(price: number): string {
  if (price === 0) return t('reception_order.0d');
  if (price >= 1000) {
    return `${Math.round(price / 1000).toLocaleString('vi-VN')}K`;
  }
  return `${price}đ`;
}

// Multilingual translations map
const uiTranslations = {
  VI: {
    table: t('reception_order.ban_text'),
    guests: t('reception_order.khach_text'),
    time: t('reception_order.gio_mo_text'),
    timeLeft: t('reception_order.con_lai_text'),
    subtotal: t('reception_order.tam_tinh_text'),
    vat: t('reception_order.thue_gtgt_8_text'),
    serviceCharge: t('reception_order.phi_phuc_vu_text'),
    grandTotal: t('reception_order.tong_cong_text'),
    checkout: t('reception_order.thanh_toan_text'),
    draftPrint: t('reception_order.xem_tam_tinh_text'),
    emptyCart: t('reception_order.gio_hang_trong_text'),
    emptyCartSub: t('reception_order.hay_chon_mon_tu_menu_text'),
    outOfStock: t('reception_order.het_hang_text'),
    favorites: t('reception_order.mon_yeu_thich_text'),
    recent: t('reception_order.moi_goi_text'),
    popular: t('reception_order.ban_chay_text'),
    searchPlaceholder: t('reception_order.tim_mon_an_theo_ten_text'),
    available: t('reception_order.con_hang_text'),
    unavailable: t('reception_order.het_hang_text'),
    all: t('reception_order.tat_ca_text'),
    back: t('reception_order.quay_lai_text'),
    saveOrder: t('reception_order.luu_thay_doi_text'),
    holdOrder: t('reception_order.tam_luu_text'),
    sendKitchen: t('reception_order.gui_vao_bep_text'),
    cancelChanges: t('reception_order.huy_thay_doi_text'),
    courseLocked: t('reception_order.khoa_course_text'),
    guestWalkIn: t('reception_order.khach_vang_lai_text'),
    courseLockedSuccess: t('reception_order.khoa_course_thanh_cong')
  },
  EN: {
    table: 'Table',
    guests: 'Guests',
    time: 'Open Time',
    timeLeft: 'remaining',
    subtotal: 'Subtotal',
    vat: 'VAT (8%)',
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
    vat: '消費税 (8%)',
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
    vat: '부가세 (8%)',
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
    vat: '增值税 (8%)',
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

// Persistent session table course settings dictionary.
// The settings are seeded lazily via `ensureTableSettings(code)` whenever a
// table is selected. We deliberately do NOT mutate state inside the
// `activeSettings` computed — that's an anti-pattern that re-runs on every
// reactive read and causes unnecessary re-renders.
const tableSettings = ref<Record<string, { package: string; drinkGroup: string; language: string; isLocked: boolean }>>({});
const EMPTY_SETTINGS = { package: '', drinkGroup: 'A', language: 'VI', isLocked: false };

function ensureTableSettings(code: string) {
  if (!tableSettings.value[code]) {
    tableSettings.value = {
      ...tableSettings.value,
      [code]: { package: '', drinkGroup: 'A', language: 'VI', isLocked: false },
    }
  }
}

const activeSettings = computed(() => {
  const code = selectedTableCode.value
  if (!code) return EMPTY_SETTINGS
  return tableSettings.value[code] ?? EMPTY_SETTINGS
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
// Track every pending auto-dismiss timer so we can clear them on unmount;
// otherwise a router push right after `triggerToast` would leave the toast
// mutating `toasts.value` after the component is gone.
const toastTimers = new Set<number>()

function triggerToast(type: 'success' | 'warning' | 'error' | 'info', message: string) {
  const id = toastIdCounter++;
  toasts.value.push({ id, type, message });
  const handle = window.setTimeout(() => {
    toastTimers.delete(handle)
    toasts.value = toasts.value.filter(t => t.id !== id);
  }, 3000);
  toastTimers.add(handle)
}

function clearToastTimers() {
  for (const h of toastTimers) clearTimeout(h)
  toastTimers.clear()
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
        title: t('reception_order.nuoc_lau_di_kem'),
        minSelection: 2,
        maxSelection: 2,
        options: [
          { id: 'opt_sukiyaki', name: t('reception_order.lau_sukiyaki_ngot_thanh'), price: 0, quantity: 0, note: '' },
          { id: 'opt_kimchi', name: t('reception_order.lau_kimchi_chua_cay'), price: 0, quantity: 0, note: '' },
          { id: 'opt_mala', name: t('reception_order.lau_mala_tu_xuyen'), price: 30000, quantity: 0, note: '' },
          { id: 'opt_mushroom', name: t('reception_order.lau_nam_thao_duoc'), price: 0, quantity: 0, note: '' },
          { id: 'opt_soy', name: t('reception_order.lau_sua_dau_nanh'), price: 20000, quantity: 0, note: '' }
        ]
      }
    ];
  }
  
  if (itemId.includes('ticket') || itemId.includes('buffet') || itemId.includes('course')) {
    return [
      {
        id: 'soup_group',
        title: t('reception_order.chon_nuoc_lau_goi_buffet'),
        minSelection: 1,
        maxSelection: 1,
        options: [
          { id: 'bf_suki', name: t('reception_order.lau_sukiyaki_tieu_chuan'), price: 0, quantity: 0, note: '' },
          { id: 'bf_kimchi', name: t('reception_order.lau_kimchi_han_quoc'), price: 0, quantity: 0, note: '' },
          { id: 'bf_mushroom', name: t('reception_order.lau_nam_thao_moc'), price: 0, quantity: 0, note: '' }
        ]
      },
      {
        id: 'gift_group',
        title: t('reception_order.chon_mon_tang_kem'),
        minSelection: 0,
        maxSelection: 2,
        options: [
          { id: 'gift_beef', name: t('reception_order.than_vai_bo_uc'), price: 0, quantity: 0, note: '' },
          { id: 'gift_beer', name: t('reception_order.lon_bia_sapporo'), price: 0, quantity: 0, note: '' },
          { id: 'gift_salad', name: t('reception_order.dia_salad_bap_cai'), price: 0, quantity: 0, note: '' }
        ]
      }
    ];
  }

  if (itemId.includes('lunch') || itemId.includes('set')) {
    return [
      {
        id: 'lunch_side',
        title: t('reception_order.mon_an_kem_chon_1'),
        minSelection: 1,
        maxSelection: 1,
        options: [
          { id: 'side_soup', name: t('reception_order.canh_rong_bien'), price: 0, quantity: 0, note: '' },
          { id: 'side_kimchi', name: t('reception_order.dia_kimchi_cai_thao'), price: 0, quantity: 0, note: '' },
          { id: 'side_tea', name: t('reception_order.ly_hong_tra'), price: 0, quantity: 0, note: '' }
        ]
      }
    ];
  }

  return [];
}

// Active table order
const activeTableArea = computed(() => {
  if (!selectedTableCode.value) return t('reception_order.khu_vuc');
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
  if (!code) return t('reception_order.trong_text');
  const tbl = restaurantStore.getTableByCode(code);
  if (!tbl) return t('reception_order.trong_text');
  if (tbl.status === 'Available') return t('reception_order.trong_text');
  if (tbl.status === 'Reserved') return t('reception_order.da_dat_text');
  if (tbl.status === 'Arrived') return t('reception_order.khach_den_text');
  if (tbl.status === 'Serving') return t('reception_order.dang_an_text');
  return tbl.status;
});

// Watch selected table code to configure timers and load options.
// When the user switches tables with a non-empty cart we MUST prompt before
// clearing — otherwise a cashier mid-order could lose an entire ticket by
// accidentally clicking a different table. Items stay on the source table
// until the cashier confirms the discard.
watch(selectedTableCode, async (newCode, oldCode) => {
  if (newCode && oldCode && newCode !== oldCode) {
    const prev = activeOrder.value
    const hasItems = prev && Array.isArray(prev.items) && prev.items.length > 0
    if (hasItems) {
      const r = await Swal.fire({
        icon: 'warning',
        title: t('reception_order.switch_table_prompt_title', 'Đổi bàn?'),
        text: t(
          'reception_order.switch_table_prompt_text',
          `Giỏ hàng hiện tại có ${prev!.items.length} món. Nếu đổi bàn mà KHÔNG gửi bếp, các món sẽ bị hủy.`,
        ),
        showCancelButton: true,
        confirmButtonText: t('reception_order.discard_cart', 'Hủy giỏ & đổi bàn'),
        cancelButtonText: t('common.keep_editing', 'Ở lại'),
        reverseButtons: true,
      })
      if (!r.isConfirmed) {
        // Restore the old code so state matches user intent.
        selectedTableCode.value = oldCode
        return
      }
      prev!.items = []
    } else if (prev) {
      prev.items = []
    }
  }
  if (newCode) {
    // Reset timer
    updateTimer();
    startSessionTimer();

    // Seed default settings for this table (lazy, no side-effects inside
    // the `activeSettings` computed).
    ensureTableSettings(newCode)

    // If table settings aren't set, auto-open the package selector
    if (!tableSettings.value[newCode] || !tableSettings.value[newCode].package) {
      // openSettingsConfig(); // Disabled automatic popup configurator
    }
  } else {
    stopSessionTimer();
  }
}, { immediate: true });

// Session timer tick updates. We tick every 2 s (not 1 s) because the
// formatted display rounds to HH:MM:SS and the extra wake-up only served to
// pin a CPU core; 2 s still gives the cashier a live countdown feel.
function startSessionTimer() {
  stopSessionTimer();
  updateTimer();
  timerInterval = setInterval(updateTimer, 2000) as unknown as number;
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

// Countdown warnings — fire ONCE per crossing instead of every tick.
// Implemented as a setTimeout chain so the toast never fires twice if the
// cashier pauses the timer or the value briefly bounces past the threshold.
const TIMER_WARNING_THRESHOLDS = [
  { at: 1800, type: 'warning' as const, messageKey: 'reception_order.thoi_gian_an_con_lai_30_phut' },
  { at: 600,  type: 'error'   as const, messageKey: 'reception_order.thoi_gian_sap_het_10_phut' },
  { at: 0,    type: 'error'   as const, messageKey: 'reception_order.phien_an_2_gio_da_ket_thuc' },
]
let timerWarningHandle: number | null = null
function clearTimerWarningTimer() {
  if (timerWarningHandle != null) {
    clearTimeout(timerWarningHandle)
    timerWarningHandle = null
  }
}

function scheduleTimerWarnings(secondsLeft: number) {
  clearTimerWarningTimer()
  const next = TIMER_WARNING_THRESHOLDS.find(t => t.at <= secondsLeft)
  if (!next) return
  const delayMs = Math.max(0, (secondsLeft - next.at) * 1000)
  timerWarningHandle = window.setTimeout(() => {
    timerWarningHandle = null
    triggerToast(next.type, t(next.messageKey))
  }, delayMs)
}

watch(timerSecondsLeft, (newVal) => {
  scheduleTimerWarnings(newVal)
})

// Helper to look up an item's subcategory ID from menuData.
// `menuData` is a static import; we build the lookup Map ONCE so per-render
// reads are O(1) instead of walking all subcategories × items every time
// `isItemInPackage` is called from a v-for.
const subcategoryIdByItemId = (() => {
  const out = new Map<string, { subCatId: string; parentCatId: string }>()
  for (const cat of menuData.categories) {
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        for (const item of sub.items) {
          if (!out.has(item.id)) {
            out.set(item.id, { subCatId: sub.id, parentCatId: cat.id })
          }
        }
      }
    }
    if (cat.items) {
      // Items that live directly on the category (no subcategory)
      for (const item of cat.items) {
        if (!out.has(item.id)) {
          out.set(item.id, { subCatId: '', parentCatId: cat.id })
        }
      }
    }
  }
  return out
})()

function getItemSubcategoryId(itemId: string): string {
  return subcategoryIdByItemId.get(itemId)?.subCatId ?? ''
}

// Check if item is included in package — delegates to the shared
// `@/utils/packageRules` engine so the cashier and the customer menu
// never disagree on which item is free inside a buffet.
function isItemInPackage(
  item: { id: string; name: string; category_id: string; price?: number },
  packageName: string,
): boolean {
  const subCatId = getItemSubcategoryId(item.id)
  return applyPackage(
    {
      id: item.id,
      name: item.name,
      category_id: item.category_id,
      subCatId,
      price: Number(item.price ?? 0),
    },
    packageName,
  ).price === 0
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

// Summary Calculation. Memoized per (packageName, items signature) so each
// item mutation only invalidates the cached subtotal rather than forcing a
// full reload across the whole items list.
const summary = computed(() => {
  const guestCount = activeOrder.value.guestCount || 2;
  const ticketSubtotal = guestCount * selectedPackagePrice.value;
  // Take HEAD: matches the DB `process_checkout` math (5% service + 10% VAT).
  // origin/main's variant dropped service_charge entirely (was a quality-bar
  // regression) so the cashier preview disagreed with the bill.
  const pkg = activeSettings.value.package;

  const items = activeOrder.value.items || [];
  let itemsSubtotal = 0;
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const charge = isItemInPackage(item, pkg) ? 0 : item.price;
    itemsSubtotal += charge * item.quantity;
  }

  const subtotal = ticketSubtotal + itemsSubtotal;
  const serviceCharge = Math.round(subtotal * 0.05); // 5% Service Charge
  // Ishii spec (02/07/2026): VAT = 8%, NOT 10%. This is the cashier-side
  // preview only; the authoritative number comes from `hall_get_checkout_totals`
  // RPC at checkout time (which the DB-side `process_checkout` also computes).
  const vat = Math.round((subtotal + serviceCharge) * 0.08); // 8% VAT
  const grandTotal = subtotal + serviceCharge + vat;
  // `discount` is exposed (currently 0) so the cashier-side preview matches
  // the template layout from origin/main. The real discount path is wired
  // through `process_checkout` (voucher + manual) — see Phase A in the
  // quality-bar plan.
  const discount = 0;

  return { subtotal, serviceCharge, vat, grandTotal, discount };
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
          name: t('reception_order.buffet_lau_upper'),
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

// Stale-token cancellation — rapid category clicks fire overlapping timers;
// we only honour the most recent one so the spinner finishes when the user
// settles on a category.
let gridLoadingToken = 0
let gridLoadingHandle: number | null = null
function clearGridLoadingTimer() {
  if (gridLoadingHandle != null) {
    clearTimeout(gridLoadingHandle)
    gridLoadingHandle = null
  }
}

function selectCategory(catId: string) {
  activeCategoryId.value = catId;
  activeSubCategoryId.value = 'all';

  clearGridLoadingTimer()
  const myToken = ++gridLoadingToken
  isGridLoading.value = true
  gridLoadingHandle = window.setTimeout(() => {
    if (myToken === gridLoadingToken) {
      isGridLoading.value = false
    }
    gridLoadingHandle = null
  }, 350)
}

function getEligibleBuffetGroups(product: MenuItem) {
  const pkgs = ['Buffet 1390', 'Buffet 1150', 'Buffet 680', 'Buffet 490', 'Buffet 380', 'Kids Meal'];
  const matches = pkgs.filter(p => isItemInPackage(product, p));
  return matches.length > 0 ? matches.join(', ') : t('reception_order.khong_ap_dung');
}

function getSetMenuGroup(product: MenuItem) {
  if (['set_lunch', 'set_tiec_chieu_dai', 'set_tiec_chieu_dai_jp', 'set_vietravel'].includes(product.category_id)) {
    return translateCategoryId(product.category_id);
  }
  return t('reception_order.khong_ap_dung');
}

function getDrinkGroup(product: MenuItem) {
  if (['thuc_uong', 'thuc_uong_co_con'].includes(product.category_id)) {
    const subCat = getItemSubcategoryId(product.id);
    return translateSubCategoryId(subCat) || translateCategoryId(product.category_id);
  }
  return t('reception_order.khong_ap_dung');
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
    triggerToast('error', t('reception_order.mon_tam_thoi_het_hang', { name: product.name }));
    return;
  }
  addToCart(product);
}

function addToCart(product: MenuItem) {
  if (!selectedTableCode.value) return;
  
  // Validate Rule 1: Limit 10 items/round
  const currentQty = getCartItemQty(product.id);
  if (currentQty >= 10) {
    triggerToast('warning', t('reception_order.da_dat_gioi_han_toi_da_10_phan', { name: product.name }));
    return;
  }

  restaurantStore.addOrderItem(selectedTableCode.value, product);
  triggerToast('success', t('reception_order.da_them_vao_hoa_don', { name: product.name }));
}

function updateQty(itemId: string, change: number) {
  if (!selectedTableCode.value) return;
  
  const currentQty = getCartItemQty(itemId);
  if (change > 0 && currentQty >= 10) {
    triggerToast('warning', t('reception_order.moi_luot_goi_toi_da_10_phan'));
    return;
  }
  
  restaurantStore.updateItemQuantity(selectedTableCode.value, itemId, change);
}

function removeItem(itemId: string) {
  if (!selectedTableCode.value) return;
  if (confirm(t('reception_order.xoa_mon_nay_khoi_don'))) {
    restaurantStore.removeOrderItem(selectedTableCode.value, itemId);
    triggerToast('info', t('reception_order.da_xoa_mon_khoi_gio'));
  }
}

function clearCart() {
  if (!selectedTableCode.value) return;
  if (confirm(t('reception_order.ban_co_chac_muon_xoa_toan_bo_mon'))) {
    activeOrder.value.items = [];
    triggerToast('success', t('reception_order.da_xoa_toan_bo_mon'));
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
      triggerToast('warning', t('reception_order.da_chon_gioi_han_toi_da', { max: String(max) }));
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
    triggerToast('warning', t('reception_order.so_luong_goi_mon_vuot_qua'));
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
    
    triggerToast('success', t('reception_order.da_them_mon_phan', { name: product.name, qty: String(modalItemQty.value) }));
    isDetailPanelOpen.value = false;
  } else {
    // ─── Complex Item Submission ───
    if (!isSelectionValid.value) {
      triggerToast('error', t('reception_order.vui_long_hoan_thanh_lua_chon'));
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

    triggerToast('success', t('reception_order.da_them_mon_co_tuy_chon', { name: customizedItem.name }));
    isDetailPanelOpen.value = false;
  }
}

// Favorites toggle
function toggleFavorite(itemId: string) {
  if (favoriteIds.value.includes(itemId)) {
    favoriteIds.value = favoriteIds.value.filter(id => id !== itemId);
    triggerToast('info', t('reception_order.da_bo_yeu_thich_mon'));
  } else {
    favoriteIds.value.push(itemId);
    triggerToast('success', t('reception_order.da_luu_mon_vao_yeu_thich'));
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
    triggerToast('error', t('reception_order.cau_hinh_da_bi_khoa'));
    return;
  }
  tempSettings.value.package = packageName;
}

function selectDrinkOption(group: string) {
  if (activeSettings.value.isLocked) {
    triggerToast('error', t('reception_order.nhom_thuc_uong_da_bi_khoa'));
    return;
  }
  tempSettings.value.drinkGroup = group;
}

function confirmPackageSelection() {
  if (!tempSettings.value.package) {
    triggerToast('warning', t('reception_order.vui_long_chon_goi_buffet'));
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
    order.customerName = order.customerName === t('reception_order.guestWalkIn') ? `Khách (${tempSettings.value.package})` : order.customerName;
    
    triggerToast('success', t('reception_order.courseLockedSuccess'));
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
        triggerToast('success', t('reception_order.mo_khoa_cau_hinh_thanh_cong'));
      }
      isPinModalOpen.value = false;
    } else {
      triggerToast('error', t('reception_order.ma_pin_sai'));
      enteredPin.value = ''; // Reset
    }
  }
}

function clearLastPinDigit() {
  enteredPin.value = enteredPin.value.slice(0, -1);
}

// Operational Actions
function printDraftBill() {
  alert(t('reception_order.hoa_don_tam_tinh_alert', { table: selectedTableCode.value || "", package: activeSettings.value.package, guests: String(activeOrder.value.guestCount), total: formatVND(summary.value.grandTotal) }));
  triggerToast('info', t('reception_order.da_gui_lenh_in_tam_tinh'));
}

async function checkoutTable() {
  const code = selectedTableCode.value
  if (!code) return
  const ok = await Swal.fire({
    title: t('reception_order.xac_nhan_thanh_toan'),
    text: t('reception_order.dong_ban_tam_tinh', { code, total: formatVND(summary.value.grandTotal) }),
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: t('reception_order.tien_hanh_thanh_toan'),
    cancelButtonText: t('reception_order.huy_text'),
  })
  if (!ok.isConfirmed) return
  try {
    // Resolve the mock table code to the real DB UUID through Hall RPC.
    const { branchId } = useAuth()
    if (!branchId.value) throw new Error(t('reception_order.tai_khoan_chua_gan_chi_nhanh'))
    const tableRow = (await listTables()).find((table: any) => table.code === code)
    if (!tableRow) throw new Error(t('reception_order.khong_tim_thay_ban', { code }))
    router.push(`/reception/checkout/${(tableRow as { id: string }).id}`)
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    Swal.fire(t('reception_order.loi_text'), msg, 'error')
  }
}

function cancelChanges() {
  if (confirm(t('reception_order.huy_bo_toan_bo_mon_an'))) {
    activeOrder.value.items = [];
    triggerToast('warning', t('reception_order.da_lam_trong_gio_hang'));
  }
}

function holdOrder() {
  triggerToast('info', t('reception_order.da_luu_tam_don_hang'));
  router.push('/reception/floors');
}

// Loading flag for the kitchen-send action. The local POS cart stays intact so
// the UI does not desync; persistence is handled in one DB RPC call.
const kitchenLoading = ref(false)

// menuData items carry slugs like 'set1390_ticket' — these are NOT UUIDs and
// DB order RPCs require real menu item UUIDs. Resolve the slug → DB UUID lazily
// through the menu RPC (matched by `metadata.slug`, then by `name`).
const menuDbIdCache = ref<Record<string, string>>({})

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
}

async function ensureMenuDbIds(branch: string, items: { id: string; name: string }[]) {
  // Only resolve IDs that aren't already UUIDs AND aren't already cached.
  const missing = items.filter((it) => !isUuid(it.id) && !menuDbIdCache.value[it.id])
  if (missing.length === 0) return
  const dbItems = await getItems(undefined, branch)

  for (const item of missing) {
    const bySlug = dbItems.find((row: any) => (row.metadata as { slug?: string } | null)?.slug === item.id)
    if (bySlug) {
      menuDbIdCache.value[item.id] = bySlug.id
      continue
    }

    const byName = dbItems.find((row: any) => row.name === item.name)
    if (byName) {
      menuDbIdCache.value[item.id] = byName.id
    }
  }
}

async function sendToKitchen() {
  if (activeOrder.value.items.length === 0) {
    triggerToast('error', t('reception_order.chua_co_mon_an_de_gui_bep'))
    return
  }
  const code = selectedTableCode.value
  if (!code) {
    triggerToast('error', t('reception_order.chua_chon_ban'))
    return
  }
  kitchenLoading.value = true
  try {
    const { branchId } = useAuth()
    if (!branchId.value) throw new Error(t('reception_order.tai_khoan_chua_gan_chi_nhanh'))
    // 1. Resolve the real `tables.id` from the mock table code through Hall RPC.
    //    Always re-fetch (not cached) so we see the server's authoritative
    //    status — if the table is still `available` we have to open it first
    //    or hall_submit_table_order will 400 with "Hall can submit orders
    //    only for occupied tables".
    const tableRow = (await listTables()).find((table: any) => table.code === code)
    if (!tableRow) throw new Error(t('reception_order.khong_tim_thay_ban', { code }))
    const tableId: string = (tableRow as { id: string }).id
    const tableStatus: string = (tableRow as { status?: string }).status ?? 'available'

    // 2. If the table isn't yet `occupied`, flip it with the lightweight
    //    `hall_open_table` RPC. We deliberately do NOT call the heavy
    //    `check-in` Edge Function here — that path creates a fresh walk-in
    //    reservation on every click and (after a previous checkout) can
    //    400 on duplicate customers / cross-branch tables. The dedicated
    //    Reservation / Quick-Open modals in AdminFloorsView still go
    //    through check-in for the full ceremonial flow.
    if (tableStatus !== 'occupied') {
      const { data: openData, error: openErr } = await supabase.rpc(
        'hall_open_table',
        { p_branch_id: branchId.value, p_table_id: tableId },
      )
      if (openErr) {
        throw new Error(
          `Không thể mở bàn trước khi gửi bếp: ${(openErr as any).message ?? String(openErr)}`,
        )
      }
      // Surface the actual server reason in console so 400s are debuggable.
      if (openData && (openData as any).ok === false) {
        throw new Error(
          `Bàn ${code} mở thất bại: ${(openData as any).reason ?? 'unknown'}`,
        )
      }
    }

    await ensureMenuDbIds(
      branchId.value,
      activeOrder.value.items.map((it) => ({ id: it.id, name: it.name })),
    )
    const skipped: string[] = []
    const payload: Array<{ menu_item_id: string; quantity: number; modifiers: unknown[]; note: string | null }> = []

    for (const line of activeOrder.value.items) {
      const dbId = isUuid(line.id) ? line.id : menuDbIdCache.value[line.id]
      if (!dbId) {
        skipped.push(line.name)
        continue
      }
      payload.push({
        menu_item_id: dbId,
        quantity: line.quantity,
        modifiers: [],
        note: (line as any).note || null,
      })
    }

    if (payload.length > 0) {
      const { error: rpcErr } = await supabase.rpc('hall_submit_table_order', {
        p_branch_id: branchId.value,
        p_table_id: tableId,
        p_items: payload,
        p_idempotency_key: crypto.randomUUID(),
      })
      if (rpcErr) throw rpcErr
      triggerToast('success', t('reception_order.da_gui_mon_den_kds', { sent: String(payload.length) }))
    }

    if (skipped.length > 0) {
      triggerToast(
        'warning',
        t('reception_order.bo_qua_mon_chua_map_db', { length: String(skipped.length), items: skipped.slice(0, 3).join(', ') + (skipped.length > 3 ? '…' : '') }),
      )
    }
  } catch (err) {
    // Surface the full Postgres / Edge Function message — the previous code
    // collapsed it into a generic "send to kitchen failed" toast, hiding the
    // real cause (table not occupied, item unavailable, etc.). We pop a
    // modal Swal so the cashier actually has time to read the message.
    const msg = err instanceof Error ? err.message : String(err)
    // Postgres RPC errors embed JSON-like text inside the .message field;
    // try to extract the human `message`/`detail`/`hint` lines so the cashier
    // sees the cause, not `{"code":"P0001","message":"..."}`.
    const pretty = extractReadableDbError(msg)
    Swal.fire({
      icon: 'error',
      title: t('reception_order.gui_bep_that_bai_title', 'Gửi bếp thất bại'),
      text: pretty,
      footer: msg !== pretty ? `<pre class="text-left text-xs whitespace-pre-wrap">${msg}</pre>` : undefined,
    })
  } finally {
    kitchenLoading.value = false
  }
}

/**
 * Pull the human-readable cause out of a Postgres RPC error string.
 * Examples:
 *   `{"code":"P0001","message":"Table is occupied"}` → "Table is occupied"
 *   `function hall_open_table(uuid,uuid) does not exist` → unchanged
 * Returns the input unchanged when no JSON is detected.
 */
function extractReadableDbError(raw: string): string {
  if (!raw) return raw
  const jsonStart = raw.indexOf('{')
  const jsonEnd = raw.lastIndexOf('}')
  if (jsonStart >= 0 && jsonEnd > jsonStart) {
    try {
      const obj = JSON.parse(raw.slice(jsonStart, jsonEnd + 1))
      const parts: string[] = []
      if (obj.message) parts.push(String(obj.message))
      if (obj.detail && obj.detail !== obj.message) parts.push(String(obj.detail))
      if (obj.hint && obj.hint !== obj.message) parts.push(`Hint: ${obj.hint}`)
      if (parts.length) return parts.join('\n')
    } catch {
      // not valid JSON — fall through to returning the raw string
    }
  }
  return raw
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
        table.occupiedDuration = t('reception_order.mot_phut');
      } else {
        table.status = 'Available';
        table.billAmount = '';
        table.customerName = '';
        table.checkInTime = '';
        table.occupiedDuration = '';
      }
    }
    triggerToast('success', t('reception_order.da_luu_cau_hinh_mon_an'));
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
      'buffet_lau': t('reception_order.buffet_lau'),
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
      triggerToast('success', t('reception_order.da_cau_hinh_goi', { pkgName, tableCode: selectedTableCode.value }));
    }
  }
});

function selectSubCategory(subId: string) {
  activeSubCategoryId.value = subId;
}

function goBack() {
  router.push({ name: 'reception-dashboard' });
}

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    goBack();
  }
}

onMounted(() => {
  startSessionTimer();
  window.addEventListener('keydown', handleKeyDown);
  clockInterval = setInterval(() => {
    currentClock.value = new Date();
  }, 1000);
});

onUnmounted(() => {
  stopSessionTimer();
  window.removeEventListener('keydown', handleKeyDown);
  clearToastTimers()
  clearGridLoadingTimer()
  clearTimerWarningTimer()
  if (typeof clockInterval !== 'undefined' && clockInterval != null) {
    clearInterval(clockInterval)
  }
});
</script>

<style scoped>
@import '@/styles/orderingScreen.css';

/* Custom Menu Grid and Card Styling */
.menu-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
  padding: 12px;
}

.menu-card {
  background: linear-gradient(145deg, #2d2d2d 0%, #252525 100%);
  border: 1px solid #404040;
  border-radius: 8px;
  padding: 10px;
  min-height: 130px;
  max-height: 140px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
}

.menu-card:hover {
  border-color: #ff8f00;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 143, 0, 0.2);
}

.menu-card.in-cart {
  border-color: #4caf50;
  background: linear-gradient(145deg, #2d3d2d 0%, #253525 100%);
}

.menu-card.out-of-stock {
  opacity: 0.4;
  cursor: not-allowed;
  pointer-events: none;
}

/* Badge số lượng */
.qty-badge {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 24px;
  height: 24px;
  background: #4caf50;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  z-index: 2;
}

/* Favorite star */
.favorite-star {
  position: absolute;
  top: 6px;
  left: 6px;
  font-size: 14px;
  z-index: 2;
}

/* Tên món */
.item-name {
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  line-height: 1.3;
  margin: 14px 0 4px 0; /* Clear space for absolute badges at the top */
  
  /* 1 dòng, ellipsis */
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Tooltip khi hover */
.menu-card:hover .item-name {
  overflow: visible;
  white-space: normal;
  position: relative;
  z-index: 10;
}

/* Badge {{ t('reception_order.trong_goi_upper') }} */
.badge-included {
  display: inline-block;
  background: #2e7d32;
  color: white;
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin: 4px 0;
  align-self: flex-start;
}

/* Giá món */
.item-price {
  color: #ff8f00;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.3px;
  margin: 4px 0;
}

/* Footer: ĐVT + Icon Info */
.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  padding-top: 6px;
  border-top: 1px solid #404040;
}

.unit-label {
  color: #888;
  font-size: 11px;
}

/* Nút chi tiết dạng icon */
.info-btn {
  width: 28px;
  height: 28px;
  background: #1976d2;
  color: white;
  border: none;
  border-radius: 50%;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
}

.info-btn:hover {
  background: #1565c0;
  transform: scale(1.1);
}

.info-btn::before {
  content: "ℹ";
}

/* Stamp HẾT MÓN */
.out-of-stock-stamp {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) rotate(-15deg);
  background: #d32f2f;
  color: white;
  padding: 4px 10px;
  border-radius: 4px;
  font-weight: 700;
  font-size: 10px;
  letter-spacing: 0.5px;
  z-index: 3;
}

/* Responsive configurations for Menu */
@media (min-width: 1920px) {
  .menu-grid {
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 14px;
  }
  
  .menu-card {
    min-height: 130px;
    max-height: 150px;
  }
}

@media (max-width: 1366px) {
  .menu-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 10px;
  }
  
  .menu-card {
    min-height: 110px;
    max-height: 130px;
    padding: 10px;
  }
  
  .item-name {
    font-size: 12px;
  }
}

.category-container-main {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  width: 100%;
}

.category-btn-main {
  flex: 1 0 calc(20% - 8px);
  justify-content: center;
  box-sizing: border-box;
  min-width: 140px;
}

@media (max-width: 1024px) {
  .category-btn-main {
    flex: 1 0 calc(33.333% - 8px);
  }
}

.category-container-sub {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  width: 100%;
}

.category-btn-sub {
  flex: 1 0 calc(12.5% - 8px);
  justify-content: center;
  box-sizing: border-box;
  min-width: 90px;
  text-align: center;
}

@media (max-width: 1200px) {
  .category-btn-sub {
    flex: 1 0 calc(16.666% - 8px);
  }
}

@media (max-width: 768px) {
  .category-btn-sub {
    flex: 1 0 calc(25% - 8px);
  }
}

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

/* Quay lai Button Scoped Styles */
.back-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #1976d2;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.back-btn:hover {
  background: #1565c0;
  transform: translateX(-4px);
}

.back-btn:active {
  transform: translateX(-2px);
}

.back-icon {
  font-size: 14px;
}

@media (max-width: 1366px) {
  .back-btn .back-text {
    display: none;
  }
}
</style>
