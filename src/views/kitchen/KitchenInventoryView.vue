<!-- KitchenInventoryView.vue -->
<template>
  <div class="inventory-app flex bg-[#1A1A1A] text-white min-h-[calc(100vh-80px)] font-sans">
    
    <!-- 1. SIDEBAR NAVIGATION -->
    <aside class="sidebar flex flex-col justify-between shrink-0">
      <div class="nav-list py-4">
        <div class="px-6 pb-4 mb-4 border-b border-[#333] flex flex-col gap-3">
          <span class="text-[#FF6B35] text-lg font-black tracking-wider uppercase">NGƯU CÁT POS</span>
          <button class="w-full text-center bg-gray-800 hover:bg-gray-700 text-xs font-bold py-2 rounded-lg border border-transparent hover:border-[#FF9800] transition" @click="navigateBack">
            📺 Quay lại KDS
          </button>
        </div>

        <button 
          v-for="item in navItems" 
          :key="item.key" 
          class="w-full nav-item text-left" 
          :class="{ active: activeTab === item.key }"
          @click="activeTab = item.key"
        >
          <span class="icon">{{ item.icon }}</span>
          <span>{{ item.label }}</span>
          <span v-if="item.badgeCount && item.badgeCount() > 0" class="badge">
            {{ item.badgeCount() }}
          </span>
        </button>
      </div>

      <!-- App Info/Status -->
      <div class="p-4 border-t border-[#333] text-xs text-gray-500 flex flex-col gap-1">
        <div>📍 Chi nhánh: Quận 1, Tp.HCM</div>
        <div>👤 Nhân viên: Quản lý Nam</div>
        <div>🕒 Vận hành: Đang kết nối</div>
      </div>
    </aside>

    <!-- 2. MAIN CONTENT WRAPPER -->
    <main class="flex-1 p-6 flex flex-col overflow-y-auto max-h-[calc(100vh-80px)]">
      
      <!-- SUB-PAGE: DASHBOARD -->
      <div v-if="activeTab === 'dashboard'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-2xl font-black uppercase text-white tracking-wide">DASHBOARD TỒN KHO</h2>
            <p class="text-xs text-gray-400 mt-1">Tổng quan giá trị và biến động kho hàng thời gian thực</p>
          </div>
          <button class="btn-primary" @click="activeTab = 'receive'">
            📥 Nhập kho mới
          </button>
        </div>

        <!-- KPI Cards Grid -->
        <div class="dashboard-grid">
          <div class="kpi-card bg-[#2D2D2D] rounded-xl p-5 border-l-4 border-[#2196F3]">
            <div class="kpi-label">Tổng số SKU nguyên liệu</div>
            <div class="kpi-value">{{ totalSkus }} món</div>
            <div class="kpi-trend up">
              <span>▲ 5%</span>
              <span class="text-gray-500">so với tuần trước</span>
            </div>
          </div>

          <div class="kpi-card bg-[#2D2D2D] rounded-xl p-5 border-l-4 border-[#4CAF50]">
            <div class="kpi-label">Tổng giá trị kho tổng</div>
            <div class="kpi-value text-[#4CAF50]">{{ formatCurrency(totalInventoryValue) }}</div>
            <div class="kpi-trend up">
              <span>▲ 3%</span>
              <span class="text-gray-500">so với tuần trước</span>
            </div>
          </div>

          <div class="kpi-card bg-[#2D2D2D] rounded-xl p-5 border-l-4 border-[#FF9800]" :class="{ warning: expiringCount > 0 }">
            <div class="kpi-label">Nguyên liệu sắp hết hạn (&le; 7 ngày)</div>
            <div class="kpi-value text-[#FF9800]">{{ expiringCount }} món</div>
            <div class="kpi-trend" :class="expiringCount > 0 ? 'down text-[#FF9800]' : 'text-gray-500'">
              <span>{{ expiringCount > 0 ? '⚠️ Cần kiểm tra' : '✓ An toàn' }}</span>
            </div>
          </div>

          <div class="kpi-card bg-[#2D2D2D] rounded-xl p-5 border-l-4 border-[#F44336]" :class="{ danger: lowStockCount > 0 }">
            <div class="kpi-label">Nguyên liệu tồn thấp (&le; min)</div>
            <div class="kpi-value text-[#F44336]">{{ lowStockCount }} món</div>
            <div class="kpi-trend" :class="lowStockCount > 0 ? 'down text-[#F44336]' : 'text-gray-500'">
              <span>{{ lowStockCount > 0 ? '🚨 Khẩn cấp đặt hàng' : '✓ Đầy đủ' }}</span>
            </div>
          </div>
        </div>

        <!-- Charts Row -->
        <div class="chart-grid">
          <!-- Tồn kho theo danh mục (Custom CSS/SVG Bar Chart) -->
          <div class="chart-card bg-[#2D2D2D] rounded-xl p-5 flex flex-col justify-between h-[320px]">
            <div class="chart-title text-base font-bold text-white uppercase tracking-wider">Tồn kho theo danh mục hàng hóa (SKU)</div>
            <div class="flex-1 flex items-end justify-around pb-4 pt-8">
              <div v-for="cat in categoryChartData" :key="cat.name" class="flex flex-col items-center gap-2 group w-12">
                <div class="text-[10px] text-gray-400 group-hover:text-white font-bold">{{ cat.count }} SKU</div>
                <div 
                  class="w-8 rounded-t-md transition-all duration-500 bg-gradient-to-t" 
                  :class="cat.color"
                  :style="{ height: `${(cat.count * 100) / 15}px` }"
                ></div>
                <div class="text-[10px] font-bold text-gray-500 group-hover:text-gray-300 truncate w-full text-center">{{ cat.name }}</div>
              </div>
            </div>
          </div>

          <!-- Biến động kho 7 ngày qua (Custom SVG Line Chart representation) -->
          <div class="chart-card bg-[#2D2D2D] rounded-xl p-5 flex flex-col justify-between h-[320px]">
            <div class="chart-title text-base font-bold text-white uppercase tracking-wider">Giá trị xuất kho bếp 7 ngày qua</div>
            <div class="flex-1 flex flex-col justify-end pt-6 relative">
              
              <!-- Draw SVG Grid & line -->
              <svg viewBox="0 0 400 120" class="w-full h-[120px] overflow-visible">
                <!-- Grid Lines -->
                <line x1="0" y1="20" x2="400" y2="20" stroke="#333" stroke-dasharray="3,3" />
                <line x1="0" y1="60" x2="400" y2="60" stroke="#333" stroke-dasharray="3,3" />
                <line x1="0" y1="100" x2="400" y2="100" stroke="#444" />

                <!-- Line Path -->
                <path 
                  d="M 10 90 L 70 85 L 130 50 L 190 60 L 250 40 L 310 75 L 370 25" 
                  fill="none" 
                  stroke="#FF6B35" 
                  stroke-width="3" 
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />

                <!-- Point Circles -->
                <circle cx="10" cy="90" r="4" fill="#FF9800" />
                <circle cx="70" cy="85" r="4" fill="#FF9800" />
                <circle cx="130" cy="50" r="4" fill="#FF9800" />
                <circle cx="190" cy="60" r="4" fill="#FF9800" />
                <circle cx="250" cy="40" r="4" fill="#FF9800" />
                <circle cx="310" cy="75" r="4" fill="#FF9800" />
                <circle cx="370" cy="25" r="4" fill="#FF9800" />
                
                <!-- Values above points -->
                <text x="130" y="38" font-size="8" fill="#FFF" text-anchor="middle" font-weight="bold">8.5M</text>
                <text x="250" y="28" font-size="8" fill="#FFF" text-anchor="middle" font-weight="bold">11M</text>
                <text x="370" y="15" font-size="8" fill="#FF6B35" text-anchor="middle" font-weight="bold">14.2M</text>
              </svg>

              <!-- X Axis Days -->
              <div class="flex justify-between text-[10px] text-gray-500 font-mono pt-3">
                <span>T7 (20/6)</span>
                <span>CN (21/6)</span>
                <span>T2 (22/6)</span>
                <span>T3 (23/6)</span>
                <span>T4 (24/6)</span>
                <span>T5 (25/6)</span>
                <span>T6 (26/6)</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Low stock and Recent Log list view -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040]">
            <h3 class="text-sm font-bold text-white uppercase tracking-wider mb-4 text-[#FF9800]">⚠️ Nguyên liệu sắp hết hoặc vượt hạn dùng</h3>
            <div class="divide-y divide-[#404040]">
              <div v-for="item in topAlertItems" :key="item.id" class="flex justify-between items-center py-2.5 text-xs">
                <div class="flex items-center gap-2">
                  <span class="text-lg">{{ item.icon }}</span>
                  <div>
                    <span class="font-bold text-gray-200 block">{{ item.name }}</span>
                    <span class="text-[10px] text-gray-500">Mã: {{ item.id }}</span>
                  </div>
                </div>
                <div class="text-right">
                  <span class="font-bold block" :class="item.mainStock <= item.minKitchenStock ? 'text-red-500' : 'text-[#FF9800]'">
                    Tồn: {{ item.mainStock }} {{ item.unit }}
                  </span>
                  <span class="text-[10px] text-gray-400">Min yêu cầu: {{ item.minKitchenStock }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040]">
            <h3 class="text-sm font-bold text-white uppercase tracking-wider mb-4 text-[#2196F3]">📜 Giao dịch kho gần nhất</h3>
            <div class="overflow-x-auto text-xs">
              <table class="w-full text-left">
                <thead>
                  <tr class="border-b border-[#404040] text-gray-500 font-bold uppercase pb-2">
                    <th class="pb-2">Ngày giờ</th>
                    <th class="pb-2">Loại GD</th>
                    <th class="pb-2">Mặt hàng</th>
                    <th class="pb-2 text-right">Lượng</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-[#404040]/50">
                  <tr v-for="log in recentLogs" :key="log.id" class="text-gray-300">
                    <td class="py-2.5 font-mono text-gray-500">{{ log.time }}</td>
                    <td class="py-2.5">
                      <span class="px-2 py-0.5 rounded text-[10px] font-bold" :class="getLogTypeClass(log.type)">
                        {{ log.typeLabel }}
                      </span>
                    </td>
                    <td class="py-2.5 font-bold">{{ log.itemName }}</td>
                    <td class="py-2.5 text-right font-mono" :class="log.qty >= 0 ? 'text-green-500' : 'text-red-500'">
                      {{ log.qty >= 0 ? '+' : '' }}{{ log.qty }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: DANH SÁCH NGUYÊN LIỆU -->
      <div v-else-if="activeTab === 'ingredients'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-2xl font-black uppercase text-white tracking-wide">QUẢN LÝ DANH MỤC NGUYÊN LIỆU</h2>
            <p class="text-xs text-gray-400 mt-1">Tra cứu tồn kho, hạn dùng và thiết lập ngưỡng tồn tối thiểu</p>
          </div>
          <button class="btn-primary" @click="openAddIngredientModal">
            + Thêm nguyên liệu
          </button>
        </div>

        <!-- Filter Bar -->
        <div class="filter-bar bg-[#2D2D2D] p-4 rounded-xl border border-[#404040] flex gap-3 flex-wrap items-center">
          <input 
            v-model="searchQuery" 
            class="search-input bg-[#1A1A1A] border border-[#404040] rounded-lg px-4 py-2.5 text-sm text-white placeholder-gray-600 flex-1 min-w-[200px]" 
            placeholder="🔍 Tìm nguyên liệu..."
          />
          <select v-model="categoryFilter" class="filter-select bg-[#1A1A1A] border border-[#404040] rounded-lg px-4 py-2.5 text-sm text-white min-w-[160px]">
            <option value="">Tất cả danh mục</option>
            <option value="Thịt">Thịt bò & sườn</option>
            <option value="Hải sản">Hải sản tươi</option>
            <option value="Rau củ">Rau củ quả</option>
            <option value="Gia vị">Nước dùng & Gia vị</option>
          </select>
          <select v-model="stockFilter" class="filter-select bg-[#1A1A1A] border border-[#404040] rounded-lg px-4 py-2.5 text-sm text-white min-w-[160px]">
            <option value="">Tất cả trạng thái</option>
            <option value="low">Tồn kho thấp</option>
            <option value="good">Tồn an toàn</option>
          </select>
        </div>

        <!-- Data Table -->
        <div class="bg-[#2D2D2D] rounded-xl border border-[#404040] overflow-hidden">
          <table class="w-full text-left border-collapse text-sm">
            <thead>
              <tr class="bg-[#1A1A1A] border-b border-[#404040] text-gray-400 text-xs font-bold uppercase">
                <th class="py-3 px-4">Mã SKU</th>
                <th class="py-3 px-4">Tên nguyên liệu</th>
                <th class="py-3 px-4">Danh mục</th>
                <th class="py-3 px-4 text-right">Kho Tổng</th>
                <th class="py-3 px-4 text-right">Kho Bếp</th>
                <th class="py-3 px-4 text-right">Min Ngưỡng</th>
                <th class="py-3 px-4 text-right">Giá Vốn</th>
                <th class="py-3 px-4 text-center">Trạng Thái</th>
                <th class="py-3 px-4 text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/60">
              <tr v-for="item in filteredIngredients" :key="item.id" class="hover:bg-[#3D3D3D]/30 transition">
                <td class="py-3.5 px-4 font-mono text-xs text-gray-500">{{ item.id }}</td>
                <td class="py-3.5 px-4 font-bold text-white flex items-center gap-2">
                  <span class="text-lg">{{ item.icon }}</span>
                  <span>{{ item.name }}</span>
                </td>
                <td class="py-3.5 px-4 text-gray-400">{{ item.category }}</td>
                <td class="py-3.5 px-4 text-right font-mono font-bold">{{ item.mainStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-gray-300">{{ item.kitchenStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-gray-500">{{ item.minKitchenStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-[#FF9800]">{{ formatCurrency(item.unitPrice) }}</td>
                <td class="py-3.5 px-4 text-center">
                  <span 
                    class="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase"
                    :class="item.mainStock <= item.minKitchenStock ? 'bg-red-950/40 text-red-500 border border-red-800/40' : 'bg-green-950/40 text-green-500 border border-green-850/40'"
                  >
                    {{ item.mainStock <= item.minKitchenStock ? 'Thấp' : 'Bình thường' }}
                  </span>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex justify-center gap-2">
                    <button class="hover:bg-[#404040] p-1.5 rounded transition" @click="editIngredient(item)" title="Chỉnh sửa">✏️</button>
                    <button class="hover:bg-[#404040] p-1.5 rounded transition" @click="showStockHistory(item)" title="Xem Lịch sử">📋</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          
          <!-- Empty State in Table -->
          <div v-if="filteredIngredients.length === 0" class="p-12 text-center text-gray-500">
            📭 Không tìm thấy nguyên liệu nào khớp với bộ lọc.
          </div>
        </div>

        <!-- Pagination -->
        <div class="flex justify-between items-center text-xs text-gray-500 font-bold px-2">
          <span>Hiển thị 1 - {{ filteredIngredients.length }} / {{ filteredIngredients.length }} nguyên liệu</span>
          <div class="flex gap-2">
            <button class="px-3 py-1.5 bg-[#2D2D2D] rounded hover:bg-[#3D3D3D] transition disabled:opacity-50" disabled>Trước</button>
            <button class="px-3 py-1.5 bg-[#FF6B35] text-white rounded hover:bg-[#F55B25] transition">1</button>
            <button class="px-3 py-1.5 bg-[#2D2D2D] rounded hover:bg-[#3D3D3D] transition disabled:opacity-50" disabled>Sau</button>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: NHẬP KHO -->
      <div v-else-if="activeTab === 'receive'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-white tracking-wide">NHẬP KHO TỪ NHÀ CUNG CẤP</h2>
          <p class="text-xs text-gray-400 mt-1">Ghi nhận lô hàng nhập từ đối tác giao hàng, in tem nhãn và phân bổ kho</p>
        </div>

        <!-- Form fields -->
        <div class="bg-[#2D2D2D] rounded-2xl p-6 border border-[#404040] space-y-6">
          
          <!-- Invoice section -->
          <section class="space-y-4">
            <h3 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider border-b border-[#404040] pb-2">📋 Thông tin hóa đơn nhập</h3>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-gray-400 font-bold">Số hóa đơn / Phiếu nhập</label>
                <input v-model="receiveForm.invoiceNumber" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#FF6B35]" />
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-gray-400 font-bold">Nhà cung cấp (NCC)</label>
                <select v-model="receiveForm.supplierId" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#FF6B35]">
                  <option v-for="s in mockSuppliers" :key="s.id" :value="s.id">{{ s.name }} ({{ s.category }})</option>
                </select>
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-gray-400 font-bold">Ngày nhận thực tế</label>
                <input type="date" v-model="receiveForm.receiveDate" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-gray-400 font-bold">Thủ kho tiếp nhận</label>
                <input v-model="receiveForm.receivedBy" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
              </div>
            </div>
          </section>

          <!-- Items section -->
          <section class="space-y-4">
            <div class="flex justify-between items-center">
              <h3 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider">🥩 Danh mục nguyên liệu nhập</h3>
              <button class="bg-[#2196F3] hover:bg-[#1E88E5] text-white text-xs font-bold px-3 py-1.5 rounded-lg transition" @click="addReceiveRow">
                + Thêm hàng nhập
              </button>
            </div>

            <!-- Table of inputs -->
            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs border-collapse">
                <thead>
                  <tr class="bg-[#1A1A1A] text-gray-400 font-bold uppercase border-b border-[#404040]">
                    <th class="py-2.5 px-3">Nguyên liệu</th>
                    <th class="py-2.5 px-3 text-center">Số lượng</th>
                    <th class="py-2.5 px-3">Đơn vị</th>
                    <th class="py-2.5 px-3 text-right">Đơn giá (VND)</th>
                    <th class="py-2.5 px-3 text-center">Hạn sử dụng</th>
                    <th class="py-2.5 px-3 text-center">Số Lô</th>
                    <th class="py-2.5 px-3 text-center">Xóa</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-[#404040]/40">
                  <tr v-for="(row, idx) in receiveForm.items" :key="idx" class="hover:bg-[#1A1A1A]/30">
                    <td class="py-2 px-1">
                      <select v-model="row.ingredientId" class="bg-[#1A1A1A] border border-[#404040] rounded px-2 py-1.5 text-xs text-white max-w-[200px]">
                        <option v-for="ing in kitchenStore.inventoryList" :key="ing.id" :value="ing.id">
                          {{ ing.icon }} {{ ing.name }}
                        </option>
                      </select>
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input type="number" v-model.number="row.quantity" min="1" class="w-16 bg-[#1A1A1A] border border-[#404040] rounded px-2 py-1 text-center font-bold text-xs" />
                    </td>
                    <td class="py-2 px-3 text-gray-400">{{ getIngredientUnit(row.ingredientId) }}</td>
                    <td class="py-2 px-1 text-right">
                      <input type="number" v-model.number="row.unitPrice" min="0" class="w-24 bg-[#1A1A1A] border border-[#404040] rounded px-2 py-1 text-right font-mono font-bold text-xs text-[#FF9800]" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input type="date" v-model="row.expiryDate" class="bg-[#1A1A1A] border border-[#404040] rounded px-2 py-1 text-xs text-gray-300" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input v-model="row.batchNumber" placeholder="LOT-..." class="w-24 bg-[#1A1A1A] border border-[#404040] rounded px-2 py-1 text-center text-xs font-mono" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <button class="text-red-500 hover:text-red-400 p-1 font-bold" @click="removeReceiveRow(idx)">❌</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Empty rows alert -->
            <div v-if="receiveForm.items.length === 0" class="text-center py-6 text-gray-500 italic bg-[#1A1A1A]/40 rounded-xl border border-dashed border-[#404040]">
              Nhấp vào nút "+ Thêm hàng nhập" ở trên để tạo phiếu nhập hàng
            </div>
          </section>

          <!-- Summary info -->
          <div class="bg-[#1A1A1A] rounded-xl p-4 flex justify-between items-center flex-wrap gap-4 text-sm font-bold border border-[#404040]">
            <div class="text-gray-400">
              Tổng số dòng: <span class="text-white">{{ receiveForm.items.length }} SKU</span>
            </div>
            <div class="text-[#FF6B35] text-lg">
              Tổng giá trị hóa đơn: <span>{{ formatCurrency(receiveTotalAmount) }}</span>
            </div>
          </div>

          <!-- Form actions -->
          <div class="flex justify-end gap-3 pt-4 border-t border-[#404040]">
            <button class="bg-[#424242] hover:bg-[#505050] text-xs font-bold px-5 py-2.5 rounded-xl text-white transition" @click="resetReceiveForm">
              Xóa Form
            </button>
            <button class="bg-[#FF9800] hover:bg-[#F57C00] text-xs font-bold px-5 py-2.5 rounded-xl text-white transition" @click="saveReceiveDraft">
              Lưu nháp
            </button>
            <button class="bg-[#FF6B35] hover:bg-[#E55F2A] disabled:opacity-50 text-xs font-bold px-6 py-2.5 rounded-xl text-white transition shadow-md" :disabled="receiveForm.items.length === 0" @click="submitReceive">
              ✓ Xác nhận Nhập Kho
            </button>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: XUẤT KHO -->
      <div v-else-if="activeTab === 'issue'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-white tracking-wide">YÊU CẦU XUẤT KHO CHO BẾP</h2>
          <p class="text-xs text-gray-400 mt-1">Duyệt phiếu xuất nguyên liệu từ kho tổng sang kho trạm bếp nấu</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Pending requisitions sidebar list (1/3 width) -->
          <div class="bg-[#2D2D2D] rounded-xl border border-[#404040] p-4 flex flex-col gap-3 max-h-[500px] overflow-y-auto">
            <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Phiếu yêu cầu chờ xuất kho</h3>
            
            <div v-if="pendingRequisitions.length === 0" class="text-center py-12 text-gray-500 text-xs">
              📭 Tất cả phiếu yêu cầu đã được xử lý.
            </div>

            <div 
              v-for="req in pendingRequisitions" 
              :key="req.id"
              class="p-4 rounded-xl border cursor-pointer hover:border-[#FF6B35] transition text-xs"
              :class="selectedRequisitionId === req.id ? 'border-[#FF6B35] bg-[#FF6B35]/5' : 'border-[#404040] bg-[#1A1A1A]/40'"
              @click="selectedRequisitionId = req.id"
            >
              <div class="flex justify-between font-bold mb-1.5">
                <span class="text-white">{{ req.id }}</span>
                <span class="text-orange-500">Chờ duyệt</span>
              </div>
              <div class="text-gray-400 mb-1">Trạm: {{ req.station }} &bull; Người lập: {{ req.actor }}</div>
              <div class="text-gray-500 text-[10px] font-mono">{{ req.date }}</div>
            </div>
          </div>

          <!-- Active Requisition process panel (2/3 width) -->
          <div class="lg:col-span-2 bg-[#2D2D2D] rounded-xl border border-[#404040] p-6 flex flex-col justify-between min-h-[480px]">
            <div v-if="!activeRequisition" class="flex-1 flex flex-col items-center justify-center text-center text-gray-500">
              <span class="text-4xl mb-3">📦</span>
              <p class="text-sm font-bold">Vui lòng chọn một phiếu yêu cầu bên trái để xử lý xuất kho</p>
            </div>

            <div v-else class="space-y-6 flex-1 flex flex-col justify-between">
              <!-- Requisition header details -->
              <div class="space-y-4 flex-1">
                <div class="flex justify-between items-start border-b border-[#404040] pb-3 flex-wrap gap-2">
                  <div>
                    <span class="text-[#FF6B35] text-xs font-bold uppercase tracking-wider block font-mono">Đang duyệt: {{ activeRequisition.id }}</span>
                    <h3 class="text-base font-bold text-white mt-1">Yêu Cầu Kho Bếp - Trạm {{ activeRequisition.station }}</h3>
                  </div>
                  <div class="text-right">
                    <span class="text-xs text-gray-400 block font-mono">{{ activeRequisition.date }}</span>
                    <span class="text-xs text-gray-400">Người lập: <strong>Chef {{ activeRequisition.actor }}</strong></span>
                  </div>
                </div>

                <!-- Items list -->
                <div class="space-y-3">
                  <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Danh sách mặt hàng xuất:</h4>
                  
                  <div class="bg-[#1A1A1A] rounded-xl border border-[#404040] overflow-hidden">
                    <table class="w-full text-left text-xs">
                      <thead>
                        <tr class="bg-[#2D2D2D] text-gray-400 font-bold uppercase border-b border-[#404040]">
                          <th class="py-2.5 px-3">Nguyên liệu</th>
                          <th class="py-2.5 px-3 text-center">Kho tổng còn</th>
                          <th class="py-2.5 px-3 text-center">Yêu cầu</th>
                          <th class="py-2.5 px-3 text-center">Duyệt xuất</th>
                        </tr>
                      </thead>
                      <tbody class="divide-y divide-[#404040]/40">
                        <tr v-for="item in activeRequisition.items" :key="item.id" class="text-gray-300">
                          <td class="py-3 px-3 font-bold flex items-center gap-1.5">
                            <span>{{ item.icon }}</span>
                            <span>{{ item.name }}</span>
                          </td>
                          <td class="py-3 px-3 text-center font-mono font-bold" :class="getMainStock(item.id) < item.requestedQty ? 'text-red-500' : 'text-gray-400'">
                            {{ getMainStock(item.id) }} {{ item.unit }}
                          </td>
                          <td class="py-3 px-3 text-center font-mono font-bold">{{ item.requestedQty }} {{ item.unit }}</td>
                          <td class="py-3 px-3 text-center">
                            <input 
                              type="number" 
                              v-model.number="item.deliveredQty" 
                              min="0" 
                              :max="item.requestedQty" 
                              class="w-16 bg-[#2D2D2D] border border-[#404040] rounded py-0.5 text-center font-bold text-white text-xs font-mono"
                            />
                            <span class="ml-1 text-gray-500 font-bold uppercase">{{ item.unit }}</span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>

                <!-- Digital signature preview for verification -->
                <div class="p-4 bg-[#1A1A1A] rounded-xl border border-[#404040] flex justify-between items-center text-xs flex-wrap gap-4">
                  <div class="space-y-1">
                    <span class="text-gray-400 block font-bold">Xác nhận Bếp trưởng:</span>
                    <span class="text-[#4CAF50] font-bold">✓ Đã ký xác nhận từ thiết bị phụ</span>
                  </div>
                  <div v-if="activeRequisition.signatureImage" class="border border-[#404040] bg-slate-900 rounded p-1.5 max-h-[50px] flex items-center justify-center">
                    <img :src="activeRequisition.signatureImage" alt="Chef Signature" class="max-h-[36px]" />
                  </div>
                  <div v-else class="text-gray-500 italic">Chưa có chữ ký</div>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="flex justify-end gap-3 pt-4 border-t border-[#404040]">
                <button class="bg-red-950/20 border border-red-800/40 text-red-500 hover:bg-red-950/40 text-xs font-bold px-5 py-2.5 rounded-xl transition" @click="rejectRequisition">
                  Từ chối
                </button>
                <button class="bg-[#4CAF50] hover:bg-[#43a047] text-xs font-bold px-6 py-2.5 rounded-xl text-white transition shadow-md" @click="approveRequisition">
                  ✓ Phê Duyệt Xuất Kho
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: KIỂM KÊ -->
      <div v-else-if="activeTab === 'stocktake'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-baseline flex-wrap gap-3">
          <div>
            <h2 class="text-2xl font-black uppercase text-white tracking-wide">KIỂM KÊ TỒN KHO ĐỊNH KỲ</h2>
            <p class="text-xs text-gray-400 mt-1">Đối chiếu khối lượng đếm thực tế với số liệu lý thuyết trên hệ thống</p>
          </div>
          
          <div class="flex items-center gap-3 text-xs text-gray-400 font-bold bg-[#2D2D2D] border border-[#404040] px-4 py-2 rounded-xl">
            <span>📅 Ngày kiểm kê: 27/06/2026</span>
            <span>👤 Nhân viên: Quản lý Nam</span>
          </div>
        </div>

        <!-- Progress Bar Section -->
        <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040] space-y-3">
          <div class="flex justify-between text-xs font-bold text-gray-300">
            <span>Tiến độ kiểm đếm nguyên liệu</span>
            <span class="text-[#FF9800]">{{ stocktakeCheckedCount }}/{{ stocktakeTotalCount }} SKU ({{ stocktakeProgress }}%)</span>
          </div>
          <div class="w-full bg-[#1A1A1A] h-2.5 rounded-full overflow-hidden border border-[#404040]">
            <div class="bg-gradient-to-r from-[#FF6B35] to-[#FF9800] h-full transition-all duration-300" :style="{ width: `${stocktakeProgress}%` }"></div>
          </div>
        </div>

        <!-- Filter Tab Buttons -->
        <div class="flex gap-2 border-b border-[#404040] pb-2 flex-wrap">
          <button 
            v-for="tab in stocktakeTabs" 
            :key="tab.key" 
            class="px-4 py-2 rounded-lg text-xs font-bold transition"
            :class="stocktakeFilter === tab.key ? 'bg-[#FF6B35] text-white' : 'bg-[#2D2D2D] text-gray-400 hover:text-white'"
            @click="stocktakeFilter = tab.key"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Stocktake inputs list -->
        <div class="bg-[#2D2D2D] rounded-xl border border-[#404040] overflow-hidden">
          <table class="w-full text-left text-sm border-collapse">
            <thead>
              <tr class="bg-[#1A1A1A] border-b border-[#404040] text-gray-500 text-xs font-bold uppercase">
                <th class="py-3 px-4">Vị trí lưu kho</th>
                <th class="py-3 px-4">Nguyên liệu</th>
                <th class="py-3 px-4 text-center">Tồn hệ thống (Lý thuyết)</th>
                <th class="py-3 px-4 text-center">Đếm thực tế</th>
                <th class="py-3 px-4 text-center">Chênh lệch</th>
                <th class="py-3 px-4">Lý do/Ghi chú điều chỉnh</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/40">
              <tr 
                v-for="item in filteredStocktakeItems" 
                :key="item.id" 
                class="hover:bg-[#3D3D3D]/20 transition"
                :class="item.diff > 0 ? 'bg-green-950/10' : item.diff < 0 ? 'bg-red-950/10' : ''"
              >
                <td class="py-3 px-4 text-xs font-bold text-gray-400">{{ item.location }}</td>
                <td class="py-3 px-4 font-bold text-white flex items-center gap-2">
                  <span>{{ item.icon }}</span>
                  <span>{{ item.name }}</span>
                </td>
                <td class="py-3 px-4 text-center font-mono font-bold text-gray-300">
                  {{ item.theoretical }} {{ item.unit }}
                </td>
                <td class="py-3 px-4 text-center">
                  <input 
                    type="number" 
                    v-model.number="item.actual" 
                    min="0"
                    class="w-20 bg-[#1A1A1A] border border-[#404040] rounded px-2.5 py-1 text-center font-mono font-bold text-white text-xs"
                    @input="calculateStocktakeDiff(item)"
                  />
                  <span class="ml-1.5 text-gray-500 font-bold uppercase text-[10px]">{{ item.unit }}</span>
                </td>
                <td class="py-3 px-4 text-center font-mono font-bold text-sm">
                  <span v-if="item.diff > 0" class="text-green-500">+{{ item.diff }} {{ item.unit }}</span>
                  <span v-else-if="item.diff < 0" class="text-red-500">{{ item.diff }} {{ item.unit }}</span>
                  <span v-else class="text-gray-500">0</span>
                </td>
                <td class="py-3 px-4">
                  <input 
                    v-model="item.note" 
                    class="w-full bg-[#1A1A1A] border border-[#404040] rounded px-3 py-1 text-xs text-white placeholder-gray-600 focus:outline-none focus:border-[#FF6B35]" 
                    placeholder="Ghi chú điều chỉnh..."
                  />
                </td>
              </tr>
            </tbody>
          </table>

          <div v-if="filteredStocktakeItems.length === 0" class="p-8 text-center text-gray-500 text-xs">
            📭 Không có mặt hàng nào phù hợp với bộ lọc kiểm kê.
          </div>
        </div>

        <!-- Stocktake action buttons -->
        <div class="flex justify-end gap-3 pt-2">
          <button class="bg-gray-800 border border-gray-700 hover:bg-gray-700 text-xs font-bold px-5 py-2.5 rounded-xl text-white transition" @click="resetStocktakeForm">
            Đặt lại số liệu
          </button>
          <button class="bg-[#2196F3] hover:bg-[#1E88E5] text-xs font-bold px-5 py-2.5 rounded-xl text-white transition" @click="exportStocktakeExcel">
            📥 Xuất File Excel
          </button>
          <button class="bg-[#FF6B35] hover:bg-[#E55F2A] text-xs font-bold px-6 py-2.5 rounded-xl text-white transition shadow-md" @click="submitStocktake">
            ✓ Hoàn tất kiểm kê
          </button>
        </div>
      </div>

      <!-- SUB-PAGE: CẢNH BÁO -->
      <div v-else-if="activeTab === 'alerts'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-white tracking-wide">CẢNH BÁO TỒN KHO & HẠN DÙNG</h2>
          <p class="text-xs text-gray-400 mt-1">Thông báo tức thời các nguyên liệu dưới ngưỡng tối thiểu hoặc gần hết hạn</p>
        </div>

        <!-- Alert Tabs -->
        <div class="flex gap-3">
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'low' ? 'bg-red-950/20 border-red-600 text-red-500' : 'bg-[#2D2D2D] border-[#404040] text-gray-400'"
            @click="alertTab = 'low'"
          >
            Tồn kho thấp ({{ alertLowCount }})
          </button>
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'expiring' ? 'bg-yellow-950/20 border-yellow-600 text-[#FF9800]' : 'bg-[#2D2D2D] border-[#404040] text-gray-400'"
            @click="alertTab = 'expiring'"
          >
            Sắp hết hạn ({{ alertExpiringCount }})
          </button>
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'expired' ? 'bg-red-950/20 border-red-600 text-red-500' : 'bg-[#2D2D2D] border-[#404040] text-gray-400'"
            @click="alertTab = 'expired'"
          >
            Đã hết hạn (0)
          </button>
        </div>

        <!-- Alert Cards Grid -->
        <div class="alert-grid">
          <div 
            v-for="item in activeAlertItems" 
            :key="item.id" 
            class="alert-card bg-[#2D2D2D] rounded-xl p-5 border-l-4 flex flex-col justify-between min-h-[220px]"
            :class="item.severity"
          >
            <div class="space-y-4">
              <div class="flex justify-between items-start gap-2">
                <div class="flex items-center gap-3">
                  <span class="text-3xl">{{ item.icon }}</span>
                  <div>
                    <span class="font-bold text-white block text-sm">{{ item.name }}</span>
                    <span class="text-[10px] text-gray-500 font-mono">SKU: {{ item.id }}</span>
                  </div>
                </div>
                <span class="severity-badge text-[10px] font-bold uppercase px-2 py-0.5 rounded-full" :class="item.severity">
                  {{ item.severityText }}
                </span>
              </div>

              <!-- Stats box -->
              <div class="bg-[#1A1A1A] rounded-xl p-3 text-xs space-y-2 border border-[#404040]">
                <div class="flex justify-between">
                  <span class="text-gray-500">Tồn kho hiện tại:</span>
                  <span class="font-bold text-white">{{ item.currentStock }} {{ item.unit }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-500">Mức tối thiểu:</span>
                  <span class="font-bold text-gray-400">{{ item.minStock }} {{ item.unit }}</span>
                </div>
                <div v-if="item.expiryDate" class="flex justify-between">
                  <span class="text-gray-500">Hạn sử dụng (FEFO):</span>
                  <span class="font-bold text-yellow-500">{{ item.expiryDate }}</span>
                </div>
              </div>
            </div>

            <!-- Actions inside card -->
            <div class="flex gap-2 pt-4">
              <button class="btn-outline text-xs py-2 rounded-lg" @click="viewAlertDetail(item)">
                Chi tiết
              </button>
              <button class="btn-primary text-xs py-2 rounded-lg" @click="createPurchaseOrder(item)">
                ⚡ Tạo đơn mua (PO)
              </button>
            </div>
          </div>

          <div v-if="activeAlertItems.length === 0" class="col-span-full py-16 text-center text-gray-500 bg-[#2D2D2D] rounded-2xl border border-dashed border-[#404040]">
            📭 Tuyệt vời! Không có cảnh báo tồn kho nào cần xử lý.
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: BÁO CÁO & PHÂN TÍCH -->
      <div v-else-if="activeTab === 'reports'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-white tracking-wide">BÁO CÁO & PHÂN TÍCH HẠCH TOÁN KHO</h2>
          <p class="text-xs text-gray-400 mt-1">Tổng hợp các chỉ số hạch toán giá vốn, tỷ lệ hao hụt và đề xuất tối ưu hóa</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          <!-- Food Cost & Variance KPI -->
          <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040] space-y-4">
            <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Chỉ số tài chính tháng 6</h3>
            
            <div class="space-y-3">
              <div class="p-3 bg-[#1A1A1A] rounded-lg">
                <span class="text-[10px] text-gray-500 uppercase font-bold block">Tỷ lệ giá vốn (Food Cost)</span>
                <span class="text-xl font-black text-white">28.4%</span>
                <span class="text-[10px] text-green-500 block">▼ 1.2% so với tháng trước</span>
              </div>
              <div class="p-3 bg-[#1A1A1A] rounded-lg">
                <span class="text-[10px] text-gray-500 uppercase font-bold block">Tỷ lệ hao hụt (Loss Ratio)</span>
                <span class="text-xl font-black text-red-500">1.85%</span>
                <span class="text-[10px] text-red-500 block">▲ 0.15% (Chênh lệch lớn ở Bò Wagyu)</span>
              </div>
              <div class="p-3 bg-[#1A1A1A] rounded-lg">
                <span class="text-[10px] text-gray-500 uppercase font-bold block">Vòng quay tồn kho (Turnover Rate)</span>
                <span class="text-xl font-black text-[#FF9800]">4.2 lần/tháng</span>
                <span class="text-[10px] text-gray-500 block">Thời gian lưu kho trung bình: 7.1 ngày</span>
              </div>
            </div>
          </div>

          <!-- ABC Analysis Widget (Value concentration) -->
          <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040] space-y-4">
            <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Phân tích ABC giá trị kho tổng</h3>
            
            <div class="space-y-4">
              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-[#FF6B35]">Nhóm A (Giá trị cao - 73%)</span>
                  <span>14 SKU</span>
                </div>
                <div class="w-full bg-[#1A1A1A] h-2 rounded-full overflow-hidden">
                  <div class="bg-[#FF6B35] h-full" style="width: 73%"></div>
                </div>
                <span class="text-[10px] text-gray-500 block mt-1">Bò Wagyu, Tôm sú tươi, Rượu Sake Nhật.</span>
              </div>

              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-[#2196F3]">Nhóm B (Giá trị trung bình - 20%)</span>
                  <span>45 SKU</span>
                </div>
                <div class="w-full bg-[#1A1A1A] h-2 rounded-full overflow-hidden">
                  <div class="bg-[#2196F3] h-full" style="width: 20%"></div>
                </div>
                <span class="text-[10px] text-gray-500 block mt-1">Rau nấm các loại, nước sốt lẩu pha sẵn.</span>
              </div>

              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-gray-400">Nhóm C (Giá trị thấp - 7%)</span>
                  <span>186 SKU</span>
                </div>
                <div class="w-full bg-[#1A1A1A] h-2 rounded-full overflow-hidden">
                  <div class="bg-gray-600 h-full" style="width: 7%"></div>
                </div>
                <span class="text-[10px] text-gray-500 block mt-1">Gia vị khô, tăm muối, khăn giấy, than củi.</span>
              </div>
            </div>
          </div>

          <!-- Optimization suggestions -->
          <div class="bg-[#2D2D2D] rounded-xl p-5 border border-[#404040] space-y-4">
            <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider">💡 Đề xuất tối ưu hóa tồn kho</h3>
            
            <div class="space-y-3 text-xs">
              <div class="p-3 bg-[#FF9800]/5 border-l-3 border-[#FF9800] rounded">
                <strong class="text-[#FF9800] block mb-1">Điều chỉnh Min/Max Bò Wagyu</strong>
                <p class="text-gray-300 leading-normal">Mức tiêu thụ Wagyu đang tăng nhẹ ca tối. Đề xuất nâng mức Min kho tổng từ 5kg lên 8kg để tránh đứt hàng khi khách gọi thêm buffet.</p>
              </div>

              <div class="p-3 bg-[#4CAF50]/5 border-l-3 border-[#4CAF50] rounded">
                <strong class="text-[#4CAF50] block mb-1">Thay đổi lịch đặt hàng Rau nấm</strong>
                <p class="text-gray-300 leading-normal">Rau củ dập nát chiếm 80% waste log. Đề xuất đổi NCC sang GreenFarm để giao mỗi buổi sáng thay vì giao 2 ngày/lần.</p>
              </div>
            </div>
          </div>

        </div>
      </div>

      <!-- SUB-PAGE: NHÀ CUNG CẤP -->
      <div v-else-if="activeTab === 'suppliers'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-2xl font-black uppercase text-white tracking-wide">DANH SÁCH NHÀ CUNG CẤP (NCC)</h2>
            <p class="text-xs text-gray-400 mt-1">Quản lý danh sách đối tác cung cấp thực phẩm tươi sống và thiết bị cho nhà hàng Ngưu Cát</p>
          </div>
          <button class="btn-primary" @click="addNewSupplier">
            + Thêm đối tác
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div 
            v-for="s in mockSuppliers" 
            :key="s.id"
            class="bg-[#2D2D2D] rounded-xl border border-[#404040] p-5 space-y-4 hover:border-gray-500 transition flex flex-col justify-between"
          >
            <div class="space-y-3">
              <div class="flex justify-between items-start">
                <div>
                  <h3 class="text-base font-bold text-white">{{ s.name }}</h3>
                  <span class="text-[10px] text-gray-500 font-mono">Mã đối tác: {{ s.id }}</span>
                </div>
                <span class="px-2 py-0.5 bg-[#2196F3]/10 text-[#2196F3] border border-[#2196F3]/20 text-[10px] font-bold rounded">
                  {{ s.category }}
                </span>
              </div>

              <div class="space-y-1.5 text-xs text-gray-400">
                <div>📞 Liên hệ: <strong class="text-gray-200">{{ s.contact }}</strong></div>
                <div>📍 Địa chỉ: <span class="text-gray-300">{{ s.address }}</span></div>
                <div>📊 Đánh giá chất lượng: <span class="text-yellow-500">⭐⭐⭐⭐⭐ (5.0)</span></div>
              </div>
            </div>

            <div class="pt-3 border-t border-[#404040] flex justify-between items-center text-xs">
              <span class="text-gray-500">Đơn mua chờ giao: <strong class="text-white">0</strong></span>
              <button class="text-[#FF6B35] font-bold hover:underline" @click="contactSupplier(s)">Đặt mua nhanh ➔</button>
            </div>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: LỊCH SỬ GIAO DỊCH KHO -->
      <div v-else-if="activeTab === 'history'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-white tracking-wide">LỊCH SỬ HOẠT ĐỘNG KHO</h2>
          <p class="text-xs text-gray-400 mt-1">Nhật ký đối soát tất cả các giao dịch Nhập, Xuất, Điều chỉnh số lượng kho hàng</p>
        </div>

        <!-- History logs list -->
        <div class="bg-[#2D2D2D] rounded-xl border border-[#404040] overflow-hidden">
          <table class="w-full text-left text-sm border-collapse">
            <thead>
              <tr class="bg-[#1A1A1A] border-b border-[#404040] text-gray-500 text-xs font-bold uppercase">
                <th class="py-3 px-4">Thời gian</th>
                <th class="py-3 px-4">Giao dịch</th>
                <th class="py-3 px-4">Đối tượng tác động</th>
                <th class="py-3 px-4 text-right">Lượng đổi</th>
                <th class="py-3 px-4">Nhân viên hạch toán</th>
                <th class="py-3 px-4">Chi tiết biên bản/Ghi chú</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/40">
              <tr v-for="log in fullTransactionLogs" :key="log.id" class="hover:bg-[#3D3D3D]/20 transition text-gray-300">
                <td class="py-3.5 px-4 font-mono text-xs text-gray-500">{{ log.time }}</td>
                <td class="py-3.5 px-4">
                  <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase" :class="getLogTypeClass(log.type)">
                    {{ log.typeLabel }}
                  </span>
                </td>
                <td class="py-3.5 px-4 font-bold text-white flex items-center gap-1.5">
                  <span>{{ log.itemIcon }}</span>
                  <span>{{ log.itemName }}</span>
                </td>
                <td class="py-3.5 px-4 text-right font-mono font-bold" :class="log.qty >= 0 ? 'text-green-500' : 'text-red-500'">
                  {{ log.qty >= 0 ? '+' : '' }}{{ log.qty }} {{ log.unit }}
                </td>
                <td class="py-3.5 px-4 text-xs font-semibold text-gray-400">👤 {{ log.actor }}</td>
                <td class="py-3.5 px-4 text-xs text-gray-500 italic">"{{ log.note }}"</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </main>

    <!-- 3. DIALOGS & MODALS -->
    <!-- Modal: Add/Edit Ingredient -->
    <div v-if="showIngredientModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm" @click.self="showIngredientModal = false">
      <div class="bg-[#2D2D2D] border border-[#404040] rounded-2xl w-full max-w-[500px] shadow-2xl overflow-hidden flex flex-col">
        <div class="px-6 py-4 bg-[#1A1A1A] border-b border-[#404040] flex justify-between items-center">
          <h3 class="text-lg font-bold text-[#FF6B35]">➕ THÊM NGUYÊN LIỆU MỚI</h3>
          <button class="text-gray-400 hover:text-white" @click="showIngredientModal = false">✕</button>
        </div>
        <div class="p-6 space-y-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-gray-400 font-bold">Tên nguyên liệu</label>
            <input v-model="ingredientForm.name" placeholder="Ví dụ: Ba chỉ bò Mỹ" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#FF6B35]" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Biểu tượng (Emoji)</label>
              <input v-model="ingredientForm.icon" placeholder="🥩" class="bg-[#1A1A1A] text-center border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Đơn vị tính</label>
              <input v-model="ingredientForm.unit" placeholder="kg" class="bg-[#1A1A1A] text-center border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Danh mục</label>
              <select v-model="ingredientForm.category" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none">
                <option value="Thịt">Thịt bò & sườn</option>
                <option value="Hải sản">Hải sản tươi</option>
                <option value="Rau củ">Rau củ quả</option>
                <option value="Gia vị">Nước dùng & Gia vị</option>
              </select>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Ngưỡng tồn thấp (Min)</label>
              <input type="number" v-model.number="ingredientForm.minKitchenStock" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Tồn Kho Tổng ban đầu</label>
              <input type="number" v-model.number="ingredientForm.mainStock" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-gray-400 font-bold">Giá vốn (VND/đơn vị)</label>
              <input type="number" v-model.number="ingredientForm.unitPrice" class="bg-[#1A1A1A] border border-[#404040] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none" />
            </div>
          </div>
        </div>
        <div class="px-6 py-4 bg-[#1A1A1A] border-t border-[#404040] flex justify-end gap-3">
          <button class="bg-[#424242] hover:bg-[#505050] text-xs font-bold px-4 py-2 rounded-lg text-white" @click="showIngredientModal = false">Hủy</button>
          <button class="bg-[#FF6B35] hover:bg-[#E55F2A] text-xs font-bold px-5 py-2 rounded-lg text-white" @click="submitAddIngredient">Xác nhận Thêm</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useKitchenStore } from '@/stores/kitchen';
import Swal from 'sweetalert2';

const router = useRouter();
const kitchenStore = useKitchenStore();

const navigateBack = () => {
  router.push('/kitchen/kds');
};

const activeTab = ref<string>('dashboard');

// Navigation sidebar items
const navItems = [
  { key: 'dashboard', label: 'Dashboard', icon: '📊' },
  { key: 'ingredients', label: 'Nguyên liệu', icon: '🥩' },
  { key: 'receive', label: 'Nhập kho', icon: '📥' },
  { key: 'issue', label: 'Xuất kho', icon: '📤', badgeCount: () => pendingRequisitions.value.length },
  { key: 'stocktake', label: 'Kiểm kê', icon: '📝' },
  { key: 'alerts', label: 'Cảnh báo', icon: '⚠️', badgeCount: () => alertLowCount.value + alertExpiringCount.value },
  { key: 'reports', label: 'Báo cáo', icon: '📈' },
  { key: 'suppliers', label: 'Nhà cung cấp', icon: '🤝' },
  { key: 'history', label: 'Lịch sử', icon: '📜' }
];

// Formatting helper
const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
};

// Global Store integration computes
const totalSkus = computed(() => kitchenStore.inventoryList.length);
const totalInventoryValue = computed(() => {
  return kitchenStore.inventoryList.reduce((acc, item) => acc + (item.mainStock * item.unitPrice), 0);
});

const expiringCount = ref(2); // Mock count for expiring items
const lowStockCount = computed(() => {
  return kitchenStore.inventoryList.filter(item => item.mainStock <= item.minKitchenStock).length;
});

// Category stats SKU
const categoryChartData = computed(() => {
  const categories = ['Thịt', 'Hải sản', 'Rau củ', 'Gia vị'];
  const colors = [
    'from-red-500 to-red-800',
    'from-blue-500 to-blue-800',
    'from-green-500 to-green-800',
    'from-yellow-500 to-yellow-800'
  ];
  return categories.map((cat, idx) => {
    const count = kitchenStore.inventoryList.filter(item => item.category === cat).length;
    return {
      name: cat,
      count: count || (idx === 0 ? 9 : idx === 1 ? 5 : idx === 2 ? 12 : 7), // mock fallback if empty
      color: colors[idx]
    };
  });
});

// Top alert items in Dashboard
const topAlertItems = computed(() => {
  return kitchenStore.inventoryList.filter(item => item.mainStock <= item.minKitchenStock).slice(0, 5);
});

// Mock Initial Logs list
const recentLogs = ref([
  { id: 'l1', time: '27/06 10:45', type: 'receive', typeLabel: 'Nhập kho', itemName: 'Thịt bò Wagyu', qty: 30 },
  { id: 'l2', time: '27/06 09:30', type: 'issue', typeLabel: 'Xuất kho', itemName: 'Nước lẩu Sukiyaki', qty: -8 },
  { id: 'l3', time: '26/06 16:15', type: 'stocktake', typeLabel: 'Điều chỉnh', itemName: 'Rau thập cẩm', qty: -0.5 },
  { id: 'l4', time: '26/06 14:00', type: 'issue', typeLabel: 'Xuất kho', itemName: 'Thịt bò Wagyu', qty: -5 }
]);

const getLogTypeClass = (type: string) => {
  if (type === 'receive') return 'bg-green-950/40 text-green-500 border border-green-800/40';
  if (type === 'issue') return 'bg-orange-950/40 text-orange-500 border border-orange-800/40';
  return 'bg-blue-950/40 text-blue-500 border border-blue-800/40';
};

// Full transactional logs sub-page
const fullTransactionLogs = computed(() => {
  return recentLogs.value.map(log => {
    const invItem = kitchenStore.inventoryList.find(i => i.name === log.itemName);
    return {
      ...log,
      itemIcon: invItem?.icon || '📦',
      unit: invItem?.unit || 'kg',
      actor: 'Quản lý Nam',
      note: log.type === 'receive' ? 'Nhập kho từ NCC Mekas Foods' : log.type === 'issue' ? 'Xuất kho phục vụ bếp ca sáng' : 'Đếm thực tế chênh lệch hao hụt'
    };
  });
});

// ─── SUB-PAGE: INGREDIENTS LIST ──────────────────────────────────────────
const searchQuery = ref('');
const categoryFilter = ref('');
const stockFilter = ref('');

const filteredIngredients = computed(() => {
  return kitchenStore.inventoryList.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.value.toLowerCase()) || item.id.toLowerCase().includes(searchQuery.value.toLowerCase());
    const matchesCategory = categoryFilter.value === '' || item.category === categoryFilter.value;
    const matchesStock = stockFilter.value === '' || (stockFilter.value === 'low' && item.mainStock <= item.minKitchenStock) || (stockFilter.value === 'good' && item.mainStock > item.minKitchenStock);
    return matchesSearch && matchesCategory && matchesStock;
  });
});

// Add Ingredient Modal
const showIngredientModal = ref(false);
const ingredientForm = ref({
  name: '',
  icon: '🥩',
  unit: 'kg',
  category: 'Thịt',
  minKitchenStock: 5,
  mainStock: 10,
  unitPrice: 150000
});

const openAddIngredientModal = () => {
  ingredientForm.value = {
    name: '',
    icon: '🥩',
    unit: 'kg',
    category: 'Thịt',
    minKitchenStock: 5,
    mainStock: 10,
    unitPrice: 150000
  };
  showIngredientModal.value = true;
};

const submitAddIngredient = () => {
  if (ingredientForm.value.name.trim() === '') {
    Swal.fire({ title: 'Lỗi', text: 'Tên nguyên liệu không được để trống!', icon: 'error', background: '#2D2D2D', color: '#FFF' });
    return;
  }
  
  const newSku = `inv-${Date.now().toString().slice(-4)}`;
  kitchenStore.inventoryList.push({
    id: newSku,
    name: ingredientForm.value.name,
    icon: ingredientForm.value.icon,
    unit: ingredientForm.value.unit,
    category: ingredientForm.value.category,
    minKitchenStock: ingredientForm.value.minKitchenStock,
    mainStock: ingredientForm.value.mainStock,
    kitchenStock: 0,
    unitPrice: ingredientForm.value.unitPrice
  });

  // Log transaction
  recentLogs.value.unshift({
    id: `log-${Date.now()}`,
    time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
    type: 'receive',
    typeLabel: 'Nhập kho',
    itemName: ingredientForm.value.name,
    qty: ingredientForm.value.mainStock
  });

  showIngredientModal.value = false;
  Swal.fire({ title: 'Thành công', text: 'Đã thêm nguyên liệu mới!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
};

const editIngredient = (item: any) => {
  Swal.fire({
    title: 'Chỉnh sửa nguyên liệu',
    text: `Tính năng chỉnh sửa cho ${item.name} sẽ được hỗ trợ trong phiên bản POS tiếp theo!`,
    icon: 'info',
    background: '#2D2D2D',
    color: '#FFF'
  });
};

const showStockHistory = (item: any) => {
  Swal.fire({
    title: `Lịch sử thẻ kho: ${item.name}`,
    html: `<div class="text-left text-xs text-gray-300 space-y-2">
      <div>• 27/06 10:45: Nhập kho +30 ${item.unit}</div>
      <div>• 26/06 14:00: Xuất bếp -5 ${item.unit}</div>
      <div>• 25/06 09:15: Đóng ca điều chỉnh -0.5 ${item.unit}</div>
    </div>`,
    icon: 'info',
    background: '#2D2D2D',
    color: '#FFF'
  });
};

// ─── SUB-PAGE: NHẬP KHO (RECEIVE STOCK) ──────────────────────────────────
const mockSuppliers = ref([
  { id: 'SUP-001', name: 'Mekas Foods', category: 'Thịt tươi', contact: '0901.234.567', address: 'Bình Tân, HCM' },
  { id: 'SUP-002', name: 'Naka Seafood', category: 'Hải sản', contact: '0902.987.654', address: 'Vũng Tàu' },
  { id: 'SUP-003', name: 'GreenFarm Sạch', category: 'Rau củ quả', contact: '0903.321.456', address: 'Đà Lạt, Lâm Đồng' }
]);

const receiveForm = ref({
  invoiceNumber: 'INV-2026-003',
  supplierId: 'SUP-001',
  receiveDate: new Date().toISOString().substring(0, 10),
  receivedBy: 'Quản lý Nam',
  items: [
    { ingredientId: 'inv-1', quantity: 20, unitPrice: 850000, expiryDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10), batchNumber: 'LOT-WG20' },
    { ingredientId: 'inv-2', quantity: 40, unitPrice: 90000, expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10), batchNumber: 'LOT-SK40' }
  ]
});

const addReceiveRow = () => {
  receiveForm.value.items.push({
    ingredientId: 'inv-1',
    quantity: 10,
    unitPrice: 150000,
    expiryDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
    batchNumber: 'LOT-NEW'
  });
};

const removeReceiveRow = (idx: number) => {
  receiveForm.value.items.splice(idx, 1);
};

const getIngredientUnit = (id: string) => {
  const found = kitchenStore.inventoryList.find(i => i.id === id);
  return found ? found.unit : 'kg';
};

const receiveTotalAmount = computed(() => {
  return receiveForm.value.items.reduce((acc, row) => acc + ((row.quantity || 0) * (row.unitPrice || 0)), 0);
});

const resetReceiveForm = () => {
  receiveForm.value.items = [];
};

const saveReceiveDraft = () => {
  Swal.fire({ title: 'Đã lưu nháp', text: 'Bản thảo phiếu nhập kho đã được lưu cục bộ!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
};

const submitReceive = () => {
  receiveForm.value.items.forEach(row => {
    const item = kitchenStore.inventoryList.find(i => i.id === row.ingredientId);
    if (item) {
      item.mainStock += row.quantity;
      
      // Log transaction
      recentLogs.value.unshift({
        id: `log-${Date.now()}`,
        time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
        type: 'receive',
        typeLabel: 'Nhập kho',
        itemName: item.name,
        qty: row.quantity
      });
    }
  });

  Swal.fire({ title: 'Nhập kho thành công', text: 'Tồn kho tổng hệ thống đã được cập nhật cộng dồn!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
  resetReceiveForm();
  activeTab.value = 'dashboard';
};

// ─── SUB-PAGE: XUẤT KHO (ISSUE TO KITCHEN) ────────────────────────────────
const pendingRequisitions = computed(() => {
  return kitchenStore.requisitions.filter(r => r.status === 'pending');
});

const selectedRequisitionId = ref('');

const activeRequisition = computed(() => {
  if (selectedRequisitionId.value === '' && pendingRequisitions.value.length > 0) {
    return pendingRequisitions.value[0];
  }
  return pendingRequisitions.value.find(r => r.id === selectedRequisitionId.value);
});

const getMainStock = (itemId: string) => {
  const found = kitchenStore.inventoryList.find(i => i.id === itemId);
  return found ? found.mainStock : 0;
};

const rejectRequisition = () => {
  if (!activeRequisition.value) return;
  
  kitchenStore.updateRequisitionStatus(activeRequisition.value.id, 'rejected', 'Quản lý Nam', 'Kho từ chối xuất hàng do thông tin không đầy đủ');
  Swal.fire({ title: 'Đã từ chối', text: 'Yêu cầu xuất kho đã bị từ chối phê duyệt!', icon: 'warning', background: '#2D2D2D', color: '#FFF' });
};

const approveRequisition = () => {
  if (!activeRequisition.value) return;

  const req = activeRequisition.value;
  let isShortage = false;

  req.items.forEach(item => {
    const mainInv = kitchenStore.inventoryList.find(i => i.id === item.id);
    if (mainInv && mainInv.mainStock < item.deliveredQty) {
      isShortage = true;
    }
  });

  if (isShortage) {
    Swal.fire({
      title: 'Thiếu hàng trong kho tổng',
      text: 'Số lượng duyệt xuất vượt quá tồn kho thực tế của kho tổng! Vui lòng kiểm tra lại.',
      icon: 'error',
      background: '#2D2D2D',
      color: '#FFF'
    });
    return;
  }

  req.items.forEach(item => {
    const mainInv = kitchenStore.inventoryList.find(i => i.id === item.id);
    if (mainInv) {
      mainInv.mainStock = Math.max(0, mainInv.mainStock - item.deliveredQty);
      mainInv.kitchenStock += item.deliveredQty;

      // Log transaction
      recentLogs.value.unshift({
        id: `log-${Date.now()}`,
        time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
        type: 'issue',
        typeLabel: 'Xuất kho',
        itemName: mainInv.name,
        qty: -item.deliveredQty
      });
    }
  });

  kitchenStore.updateRequisitionStatus(req.id, 'delivered', 'Quản lý Nam');
  Swal.fire({ title: 'Xuất kho thành công', text: 'Hàng hóa đã được trừ tồn kho tổng và bổ sung trạm bếp!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
  selectedRequisitionId.value = '';
};

// ─── SUB-PAGE: KIỂM KÊ (STOCKTAKE) ───────────────────────────────────────
interface StocktakeItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  location: string;
  theoretical: number;
  actual: number;
  diff: number;
  note: string;
  checked: boolean;
}

const stocktakeItems = ref<StocktakeItem[]>([]);

// Populate initial list from kitchenStore
onMounted(() => {
  stocktakeItems.value = kitchenStore.inventoryList.map((item, idx) => ({
    id: item.id,
    name: item.name,
    icon: item.icon,
    unit: item.unit,
    location: idx % 2 === 0 ? 'Tủ đông phụ 1' : 'Kệ mát trạm',
    theoretical: item.mainStock,
    actual: item.mainStock,
    diff: 0,
    note: '',
    checked: false
  }));
});

const stocktakeTabs = [
  { key: 'all', label: 'Tất cả' },
  { key: 'unchecked', label: 'Chưa kiểm' },
  { key: 'variance', label: 'Có chênh lệch' }
];

const stocktakeFilter = ref('all');

const filteredStocktakeItems = computed(() => {
  return stocktakeItems.value.filter(item => {
    if (stocktakeFilter.value === 'unchecked') return !item.checked;
    if (stocktakeFilter.value === 'variance') return item.diff !== 0;
    return true;
  });
});

const stocktakeCheckedCount = computed(() => stocktakeItems.value.filter(i => i.checked).length);
const stocktakeTotalCount = computed(() => stocktakeItems.value.length);
const stocktakeProgress = computed(() => {
  return stocktakeTotalCount.value > 0 ? Math.round((stocktakeCheckedCount.value * 100) / stocktakeTotalCount.value) : 0;
});

const calculateStocktakeDiff = (item: StocktakeItem) => {
  item.diff = (item.actual || 0) - item.theoretical;
  item.checked = true;
};

const resetStocktakeForm = () => {
  stocktakeItems.value.forEach(item => {
    item.actual = item.theoretical;
    item.diff = 0;
    item.note = '';
    item.checked = false;
  });
};

const exportStocktakeExcel = () => {
  Swal.fire({ title: 'Xuất File Thành Công', text: 'Tài liệu đối soát kiểm kê kho định kỳ dạng Excel đã được tải xuống!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
};

const submitStocktake = () => {
  stocktakeItems.value.forEach(verifyItem => {
    const inv = kitchenStore.inventoryList.find(i => i.id === verifyItem.id);
    if (inv && verifyItem.checked) {
      inv.mainStock = verifyItem.actual;
      
      if (verifyItem.diff !== 0) {
        recentLogs.value.unshift({
          id: `log-${Date.now()}`,
          time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
          type: 'adjust',
          typeLabel: 'Điều chỉnh',
          itemName: inv.name,
          qty: verifyItem.diff
        });
      }
    }
  });

  Swal.fire({ title: 'Cập nhật hoàn tất', text: 'Báo cáo kiểm kê kho đã được lưu. Hệ thống tự động cân đối tồn kho!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
  activeTab.value = 'dashboard';
};

// ─── SUB-PAGE: CẢNH BÁO (ALERTS) ─────────────────────────────────────────
const alertTab = ref('low');

interface AlertItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  currentStock: number;
  minStock: number;
  expiryDate?: string;
  severity: 'critical' | 'warning';
  severityText: string;
}

const mockAlerts = computed(() => {
  // Generate alerts dynamically from kitchenStore
  const alerts: AlertItem[] = [];
  kitchenStore.inventoryList.forEach(item => {
    if (item.mainStock <= item.minKitchenStock) {
      alerts.push({
        id: item.id,
        name: item.name,
        icon: item.icon,
        unit: item.unit,
        currentStock: item.mainStock,
        minStock: item.minKitchenStock,
        severity: item.mainStock === 0 ? 'critical' : 'warning',
        severityText: item.mainStock === 0 ? 'Hết hàng' : 'Tồn thấp'
      });
    }
  });
  
  // Add a mock expiring item for demonstration
  alerts.push({
    id: 'inv-3',
    name: 'Rau thập cẩm',
    icon: '🥬',
    unit: 'kg',
    currentStock: 20,
    minStock: 4,
    expiryDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toLocaleDateString('vi-VN'),
    severity: 'warning',
    severityText: 'Cận hạn'
  });

  return alerts;
});

const alertLowCount = computed(() => {
  return mockAlerts.value.filter(a => a.currentStock <= a.minStock).length;
});

const alertExpiringCount = computed(() => {
  return mockAlerts.value.filter(a => a.expiryDate !== undefined).length;
});

const activeAlertItems = computed(() => {
  if (alertTab.value === 'expiring') {
    return mockAlerts.value.filter(a => a.expiryDate !== undefined);
  }
  if (alertTab.value === 'expired') {
    return [];
  }
  return mockAlerts.value.filter(a => a.currentStock <= a.minStock);
});

const viewAlertDetail = (item: any) => {
  Swal.fire({
    title: `Chi tiết cảnh báo: ${item.name}`,
    text: `Mặt hàng đang ở mức ${item.severityText}. Tồn kho hiện tại: ${item.currentStock} ${item.unit} so với mức tối thiểu ${item.minStock} ${item.unit}.`,
    icon: 'warning',
    background: '#2D2D2D',
    color: '#FFF'
  });
};

const createPurchaseOrder = (item: any) => {
  Swal.fire({
    title: 'Xác nhận tạo đơn mua hàng',
    text: `Hệ thống Ngưu Cát sẽ tự động gửi PO đặt hàng khẩn cấp tới nhà cung cấp cho mặt hàng ${item.name}!`,
    icon: 'question',
    showCancelButton: true,
    confirmButtonColor: '#FF6B35',
    cancelButtonColor: '#424242',
    confirmButtonText: '⚡ Đặt hàng ngay',
    cancelButtonText: 'Hủy',
    background: '#2D2D2D',
    color: '#FFF'
  }).then((result) => {
    if (result.isConfirmed) {
      Swal.fire({
        title: 'Đặt hàng thành công',
        text: `Phiếu đặt mua hàng khẩn cấp (PO) đã được chuyển tiếp thành công đến NCC!`,
        icon: 'success',
        background: '#2D2D2D',
        color: '#FFF'
      });
    }
  });
};

// ─── SUB-PAGE: NHÀ CUNG CẤP & MORE ───────────────────────────────────────
const addNewSupplier = () => {
  Swal.fire({
    title: 'Thêm nhà cung cấp mới',
    html: `<input id="sup-name" placeholder="Tên đối tác" class="swal2-input bg-[#1A1A1A] border-[#404040] text-white">
           <input id="sup-phone" placeholder="Số điện thoại liên hệ" class="swal2-input bg-[#1A1A1A] border-[#404040] text-white">`,
    confirmButtonText: 'Thêm',
    showCancelButton: true,
    background: '#2D2D2D',
    color: '#FFF',
    preConfirm: () => {
      const name = (document.getElementById('sup-name') as HTMLInputElement).value;
      const phone = (document.getElementById('sup-phone') as HTMLInputElement).value;
      return { name, phone };
    }
  }).then((result) => {
    if (result.isConfirmed && result.value?.name) {
      mockSuppliers.value.push({
        id: `SUP-${String(mockSuppliers.value.length + 1).padStart(3, '0')}`,
        name: result.value.name,
        category: 'Thực phẩm sạch',
        contact: result.value.phone || '0901.xxx.xxx',
        address: 'Quận 1, TP. Hồ Chí Minh'
      });
      Swal.fire({ title: 'Thành công', text: 'Đã bổ sung nhà cung cấp mới!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
    }
  });
};

const contactSupplier = (s: any) => {
  Swal.fire({
    title: `Đặt mua hàng nhanh`,
    text: `Đang kết nối tới ${s.name} qua hotline: ${s.contact}...`,
    icon: 'info',
    background: '#2D2D2D',
    color: '#FFF'
  });
};
</script>

<style scoped>
/* Sidebar design overrides */
.sidebar {
  width: 240px;
  background: #1A1A1A;
  border-right: 1px solid #333;
  padding: 16px 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  color: #B0B0B0;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border-left: 3px solid transparent;
  background: transparent;
  border-top: none;
  border-right: none;
  border-bottom: none;
}

.nav-item:hover {
  background: #2D2D2D;
  color: #FFFFFF;
}

.nav-item.active {
  background: #2D2D2D;
  color: #FF6B35;
  border-left-color: #FF6B35;
  font-weight: 600;
}

.nav-item .icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.nav-item .badge {
  margin-left: auto;
  background: #F44336;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
  border: 1px solid #1A1A1A;
}

/* Dashboard KPI layouts */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

@media (max-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}

.kpi-card {
  transition: transform 0.2s ease;
}

.kpi-card:hover {
  transform: translateY(-2px);
}

.kpi-label {
  font-size: 13px;
  color: #B0B0B0;
  margin-bottom: 8px;
}

.kpi-value {
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 8px;
}

.kpi-trend {
  font-size: 11px;
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 700;
}

.kpi-trend.up { color: #4CAF50; }
.kpi-trend.down { color: #F44336; }

.chart-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

@media (max-width: 768px) {
  .chart-grid {
    grid-template-columns: 1fr;
  }
}

.chart-card {
  border: 1px solid #404040;
}

/* Button variants */
.btn-primary {
  padding: 10px 20px;
  background: #FF6B35;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  font-size: 13px;
  transition: background 0.15s;
}

.btn-primary:hover {
  background: #F55B25;
}

.btn-outline {
  padding: 10px;
  background: transparent;
  border: 1px solid #404040;
  color: #E0E0E0;
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-outline:hover {
  background: #404040;
  color: white;
}

/* Alert sub-page cards layout */
.alert-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.alert-card {
  border: 1px solid #404040;
}

.alert-card.critical {
  border-left-color: #F44336;
  animation: pulse-border 2s infinite;
}

.alert-card.warning {
  border-left-color: #FF9800;
}

@keyframes pulse-border {
  0%, 100% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4); }
  50% { box-shadow: 0 0 0 8px rgba(244, 67, 54, 0); }
}

.severity-badge.critical {
  background: rgba(244, 67, 54, 0.15);
  color: #F44336;
  border: 1px solid rgba(244, 67, 54, 0.3);
}

.severity-badge.warning {
  background: rgba(255, 152, 0, 0.15);
  color: #FF9800;
  border: 1px solid rgba(255, 152, 0, 0.3);
}

/* Stocktake sub-page classes */
.stocktake-table tr.variance-positive {
  background: rgba(76, 175, 80, 0.06);
}

.stocktake-table tr.variance-negative {
  background: rgba(244, 67, 54, 0.06);
}

.qty-input {
  width: 100px;
  text-align: right;
  font-weight: 600;
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
