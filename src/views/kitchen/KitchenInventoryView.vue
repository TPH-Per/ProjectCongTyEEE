<!-- KitchenInventoryView.vue -->
<template>
  <div class="inventory-app flex bg-background text-foreground min-h-[calc(100vh-80px)] font-sans">
    
    <!-- 1. SIDEBAR NAVIGATION -->
    <aside class="sidebar flex flex-col justify-between shrink-0">
      <div class="nav-list py-4">
        <div class="px-6 pb-4 mb-4 border-b border-border flex flex-col gap-3">
          <span class="text-primary text-lg font-black tracking-wider uppercase">{{ $t('kitchen_inventory.brand_pos') }}</span>
          <button class="w-full text-center bg-muted hover:bg-muted text-xs font-bold py-2 rounded-lg border border-transparent hover:border-[#FF9800] transition" @click="navigateBack">
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
      <div class="p-4 border-t border-border text-xs text-muted-foreground flex flex-col gap-1">
        <div>{{ $t('kitchen_inventory.branch') }}</div>
        <div>{{ $t('kitchen_inventory.employee') }}</div>
        <div>{{ $t('kitchen_inventory.operation_status') }}</div>
      </div>
    </aside>

    <!-- 2. MAIN CONTENT WRAPPER -->
    <main class="flex-1 p-6 flex flex-col overflow-y-auto max-h-[calc(100vh-80px)]">
      
      <!-- SUB-PAGE: DASHBOARD -->
      <div v-if="activeTab === 'dashboard'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.dashboard_title') }}</h2>
            <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.dashboard_desc') }}</p>
          </div>
          <button class="btn-primary" @click="activeTab = 'receive'">
            📥 {{ t('kitchen.receive') }} mới
          </button>
        </div>

        <!-- KPI Cards Grid -->
        <div class="dashboard-grid">
          <div class="kpi-card bg-card rounded-xl p-5 border-l-4 border-[#2196F3]">
            <div class="kpi-label">{{ $t('kitchen_inventory.total_sku') }}</div>
            <div class="kpi-value">{{ totalSkus }} món</div>
            <div class="kpi-trend up">
              <span>▲ 5%</span>
              <span class="text-muted-foreground">{{ $t('kitchen_inventory.vs_last_week') }}</span>
            </div>
          </div>

          <div class="kpi-card bg-card rounded-xl p-5 border-l-4 border-[#4CAF50]">
            <div class="kpi-label">{{ $t('kitchen_inventory.total_value') }}</div>
            <div class="kpi-value text-green-600">{{ formatCurrency(totalInventoryValue) }}</div>
            <div class="kpi-trend up">
              <span>▲ 3%</span>
              <span class="text-muted-foreground">{{ $t('kitchen_inventory.vs_last_week') }}</span>
            </div>
          </div>

          <div class="kpi-card bg-card rounded-xl p-5 border-l-4 border-[#FF9800]" :class="{ warning: expiringCount > 0 }">
            <div class="kpi-label">{{ $t('kitchen_inventory.expiring_soon') }}</div>
            <div class="kpi-value text-[#FF9800]">{{ expiringCount }} món</div>
            <div class="kpi-trend" :class="expiringCount > 0 ? 'down text-[#FF9800]' : 'text-muted-foreground'">
              <span>{{ expiringCount > 0 ? '⚠️ Cần kiểm tra' : '✓ An toàn' }}</span>
            </div>
          </div>

          <div class="kpi-card bg-card rounded-xl p-5 border-l-4 border-[#F44336]" :class="{ danger: lowStockCount > 0 }">
            <div class="kpi-label">{{ $t('kitchen_inventory.low_stock') }}</div>
            <div class="kpi-value text-red-600">{{ lowStockCount }} món</div>
            <div class="kpi-trend" :class="lowStockCount > 0 ? 'down text-red-600' : 'text-muted-foreground'">
              <span>{{ lowStockCount > 0 ? '🚨 Khẩn cấp đặt hàng' : '✓ Đầy đủ' }}</span>
            </div>
          </div>
        </div>

        <!-- Charts Row -->
        <div class="chart-grid">
          <!-- Tồn kho theo danh mục (Custom CSS/SVG Bar Chart) -->
          <div class="chart-card bg-card rounded-xl p-5 flex flex-col justify-between h-[320px]">
            <div class="chart-title text-base font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.stock_by_category') }}</div>
            <div class="flex-1 flex items-end justify-around pb-4 pt-8">
              <div v-for="cat in categoryChartData" :key="cat.name" class="flex flex-col items-center gap-2 group w-12">
                <div class="text-[10px] text-muted-foreground group-hover:text-foreground font-bold">{{ cat.count }} SKU</div>
                <div 
                  class="w-8 rounded-t-md transition-all duration-500 bg-gradient-to-t" 
                  :class="cat.color"
                  :style="{ height: `${(cat.count * 100) / 15}px` }"
                ></div>
                <div class="text-[10px] font-bold text-muted-foreground group-hover:text-muted-foreground truncate w-full text-center">{{ cat.name }}</div>
              </div>
            </div>
          </div>

          <!-- Biến động kho 7 ngày qua (Custom SVG Line Chart representation) -->
          <div class="chart-card bg-card rounded-xl p-5 flex flex-col justify-between h-[320px]">
            <div class="chart-title text-base font-bold text-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.kitchen_issue_7d') }}</div>
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
              <div class="flex justify-between text-[10px] text-muted-foreground font-mono pt-3">
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
          <div class="bg-card rounded-xl p-5 border border-border">
            <h3 class="text-sm font-bold text-foreground uppercase tracking-wider mb-4 text-[#FF9800]">⚠️ Nguyên liệu sắp hết hoặc vượt hạn dùng</h3>
            <div class="divide-y divide-[#404040]">
              <div v-for="item in topAlertItems" :key="item.id" class="flex justify-between items-center py-2.5 text-xs">
                <div class="flex items-center gap-2">
                  <span class="text-lg">{{ item.icon }}</span>
                  <div>
                    <span class="font-bold text-foreground block">{{ item.name }}</span>
                    <span class="text-[10px] text-muted-foreground">Mã: {{ item.id }}</span>
                  </div>
                </div>
                <div class="text-right">
                  <span class="font-bold block" :class="item.mainStock <= item.minKitchenStock ? 'text-red-500' : 'text-[#FF9800]'">
                    Tồn: {{ item.mainStock }} {{ item.unit }}
                  </span>
                  <span class="text-[10px] text-muted-foreground">Min yêu cầu: {{ item.minKitchenStock }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-card rounded-xl p-5 border border-border">
            <h3 class="text-sm font-bold text-foreground uppercase tracking-wider mb-4 text-blue-600">{{ $t('kitchen_inventory.recent_transactions') }}</h3>
            <div class="overflow-x-auto text-xs">
              <table class="w-full text-left">
                <thead>
                  <tr class="border-b border-border text-muted-foreground font-bold uppercase pb-2">
                    <th class="pb-2">{{ $t('kitchen_inventory.datetime') }}</th>
                    <th class="pb-2">Loại GD</th>
                    <th class="pb-2">{{ $t('kitchen_inventory.item') }}</th>
                    <th class="pb-2 text-right">{{ $t('kitchen_inventory.amount') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-[#404040]/50">
                  <tr v-for="log in recentLogs" :key="log.id" class="text-muted-foreground">
                    <td class="py-2.5 font-mono text-muted-foreground">{{ log.time }}</td>
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
            <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.ingredients_title') }}</h2>
            <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.ingredients_desc') }}</p>
          </div>
          <button class="btn-primary" @click="openAddIngredientModal">
            + Thêm nguyên liệu
          </button>
        </div>

        <!-- Filter Bar -->
        <div class="filter-bar bg-card p-4 rounded-xl border border-border flex gap-3 flex-wrap items-center">
          <input 
            v-model="searchQuery" 
            class="search-input bg-background border border-border rounded-lg px-4 py-2.5 text-sm text-foreground placeholder-gray-600 flex-1 min-w-[200px]" 
            placeholder="🔍 Tìm nguyên liệu..."
          />
          <select v-model="categoryFilter" class="filter-select bg-background border border-border rounded-lg px-4 py-2.5 text-sm text-foreground min-w-[160px]">
            <option value="">{{ $t('kitchen_inventory.all_categories') }}</option>
            <option :value="$t('kitchen_inventory.meat')">{{ $t('kitchen_inventory.beef_ribs') }}</option>
            <option :value="$t('kitchen_inventory.seafood')">{{ $t('kitchen_inventory.fresh_seafood') }}</option>
            <option :value="$t('kitchen_inventory.veg')">{{ $t('kitchen_inventory.vegetables') }}</option>
            <option :value="$t('kitchen_inventory.spices')">{{ $t('kitchen_inventory.broth_spices') }}</option>
          </select>
          <select v-model="stockFilter" class="filter-select bg-background border border-border rounded-lg px-4 py-2.5 text-sm text-foreground min-w-[160px]">
            <option value="">{{ $t('kitchen_inventory.all_status') }}</option>
            <option value="low">{{ $t('kitchen_inventory.low_stock_status') }}</option>
            <option value="good">{{ $t('kitchen_inventory.safe_stock') }}</option>
          </select>
        </div>

        <!-- Data Table -->
        <div class="bg-card rounded-xl border border-border overflow-hidden">
          <table class="w-full text-left border-collapse text-sm">
            <thead>
              <tr class="bg-background border-b border-border text-muted-foreground text-xs font-bold uppercase">
                <th class="py-3 px-4">{{ $t('kitchen_inventory.sku') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.ingredient_name') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.category') }}</th>
                <th class="py-3 px-4 text-right">{{ $t('kitchen_inventory.main_stock') }}</th>
                <th class="py-3 px-4 text-right">{{ $t('kitchen_inventory.kitchen_stock') }}</th>
                <th class="py-3 px-4 text-right">{{ $t('kitchen_inventory.min_threshold') }}</th>
                <th class="py-3 px-4 text-right">{{ $t('kitchen_inventory.cost_price') }}</th>
                <th class="py-3 px-4 text-center">{{ $t('kitchen_inventory.status') }}</th>
                <th class="py-3 px-4 text-center">{{ $t('kitchen_inventory.action') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/60">
              <tr v-for="item in filteredIngredients" :key="item.id" class="hover:bg-muted transition">
                <td class="py-3.5 px-4 font-mono text-xs text-muted-foreground">{{ item.id }}</td>
                <td class="py-3.5 px-4 font-bold text-foreground flex items-center gap-2">
                  <span class="text-lg">{{ item.icon }}</span>
                  <span>{{ item.name }}</span>
                </td>
                <td class="py-3.5 px-4 text-muted-foreground">{{ item.category }}</td>
                <td class="py-3.5 px-4 text-right font-mono font-bold">{{ item.mainStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-muted-foreground">{{ item.kitchenStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-muted-foreground">{{ item.minKitchenStock }} {{ item.unit }}</td>
                <td class="py-3.5 px-4 text-right font-mono text-[#FF9800]">{{ formatCurrency(item.unitPrice) }}</td>
                <td class="py-3.5 px-4 text-center">
                  <span 
                    class="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase"
                    :class="item.mainStock <= item.minKitchenStock ? 'bg-red-100 text-red-500 border border-red-300' : 'bg-green-100 text-green-500 border border-green-850/40'"
                  >
                    {{ item.mainStock <= item.minKitchenStock ? 'Thấp' : 'Bình thường' }}
                  </span>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex justify-center gap-2">
                    <button class="hover:bg-muted p-1.5 rounded transition" @click="editIngredient(item)" title="Chỉnh sửa">✏️</button>
                    <button class="hover:bg-muted p-1.5 rounded transition" @click="showStockHistory(item)" title="Xem Lịch sử">📋</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          
          <!-- Empty State in Table -->
          <div v-if="filteredIngredients.length === 0" class="p-12 text-center text-muted-foreground">
            📭 Không tìm thấy nguyên liệu nào khớp với bộ lọc.
          </div>
        </div>

        <!-- Pagination -->
        <div class="flex justify-between items-center text-xs text-muted-foreground font-bold px-2">
          <span>Hiển thị 1 - {{ filteredIngredients.length }} / {{ filteredIngredients.length }} nguyên liệu</span>
          <div class="flex gap-2">
            <button class="px-3 py-1.5 bg-card rounded hover:bg-muted transition disabled:opacity-50" disabled>Trước</button>
            <button class="px-3 py-1.5 bg-primary text-primary-foreground rounded hover:bg-[#F55B25] transition">1</button>
            <button class="px-3 py-1.5 bg-card rounded hover:bg-muted transition disabled:opacity-50" disabled>Sau</button>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: {{ t('kitchen.receive') }} -->
      <div v-else-if="activeTab === 'receive'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ t('kitchen.receive') }} TỪ NHÀ CUNG CẤP</h2>
          <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.receive_desc') }}</p>
        </div>

        <!-- Form fields -->
        <div class="bg-card rounded-2xl p-6 border border-border space-y-6">
          
          <!-- Invoice section -->
          <section class="space-y-4">
            <h3 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider border-b border-border pb-2">{{ $t('kitchen_inventory.invoice_info') }}</h3>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.invoice_no') }}</label>
                <input v-model="receiveForm.invoiceNumber" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none focus:border-primary" />
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.supplier') }}</label>
                <select v-model="receiveForm.supplierId" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none focus:border-primary">
                  <option v-for="s in mockSuppliers" :key="s.id" :value="s.id">{{ s.name }} ({{ s.category }})</option>
                </select>
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.received_date') }}</label>
                <input type="date" v-model="receiveForm.receiveDate" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.received_by') }}</label>
                <input v-model="receiveForm.receivedBy" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
              </div>
            </div>
          </section>

          <!-- Items section -->
          <section class="space-y-4">
            <div class="flex justify-between items-center">
              <h3 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider">{{ $t('kitchen_inventory.receive_list') }}</h3>
              <button class="bg-[#2196F3] hover:bg-[#1E88E5] text-white text-xs font-bold px-3 py-1.5 rounded-lg transition" @click="addReceiveRow">
                + Thêm hàng nhập
              </button>
            </div>

            <!-- Table of inputs -->
            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs border-collapse">
                <thead>
                  <tr class="bg-background text-muted-foreground font-bold uppercase border-b border-border">
                    <th class="py-2.5 px-3">{{ $t('kitchen_inventory.ingredient') }}</th>
                    <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.quantity') }}</th>
                    <th class="py-2.5 px-3">{{ $t('kitchen_inventory.unit_short') }}</th>
                    <th class="py-2.5 px-3 text-right">{{ $t('kitchen_inventory.unit_price') }}</th>
                    <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.expiry_date') }}</th>
                    <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.batch_no') }}</th>
                    <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.delete') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-[#404040]/40">
                  <tr v-for="(row, idx) in receiveForm.items" :key="idx" class="hover:bg-background">
                    <td class="py-2 px-1">
                      <select v-model="row.ingredientId" class="bg-background border border-border rounded px-2 py-1.5 text-xs text-foreground max-w-[200px]">
                        <option v-for="ing in mappedInventoryList" :key="ing.id" :value="ing.id">
                          {{ ing.icon }} {{ ing.name }}
                        </option>
                      </select>
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input type="number" v-model.number="row.quantity" min="1" class="w-16 bg-background border border-border rounded px-2 py-1 text-center font-bold text-xs" />
                    </td>
                    <td class="py-2 px-3 text-muted-foreground">{{ getIngredientUnit(row.ingredientId) }}</td>
                    <td class="py-2 px-1 text-right">
                      <input type="number" v-model.number="row.unitPrice" min="0" class="w-24 bg-background border border-border rounded px-2 py-1 text-right font-mono font-bold text-xs text-[#FF9800]" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input type="date" v-model="row.expiryDate" class="bg-background border border-border rounded px-2 py-1 text-xs text-muted-foreground" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <input v-model="row.batchNumber" placeholder="LOT-..." class="w-24 bg-background border border-border rounded px-2 py-1 text-center text-xs font-mono" />
                    </td>
                    <td class="py-2 px-1 text-center">
                      <button class="text-red-500 hover:text-red-700 p-1 font-bold" @click="removeReceiveRow(idx)">❌</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Empty rows alert -->
            <div v-if="receiveForm.items.length === 0" class="text-center py-6 text-muted-foreground italic bg-background rounded-xl border border-dashed border-border">
              Nhấp vào nút t('kitchen_inventory.add_incoming') ở trên để tạo phiếu nhập hàng
            </div>
          </section>

          <!-- Summary info -->
          <div class="bg-background rounded-xl p-4 flex justify-between items-center flex-wrap gap-4 text-sm font-bold border border-border">
            <div class="text-muted-foreground">
              Tổng số dòng: <span class="text-foreground">{{ receiveForm.items.length }} SKU</span>
            </div>
            <div class="text-primary text-lg">
              Tổng giá trị hóa đơn: <span>{{ formatCurrency(receiveTotalAmount) }}</span>
            </div>
          </div>

          <!-- Form actions -->
          <div class="flex justify-end gap-3 pt-4 border-t border-border">
            <button class="bg-muted hover:bg-muted text-xs font-bold px-5 py-2.5 rounded-xl text-foreground transition" @click="cancelReceive">
              Xóa Form
            </button>
            <button class="bg-[#FF9800] hover:bg-[#F57C00] text-xs font-bold px-5 py-2.5 rounded-xl text-foreground transition" @click="saveReceiveDraft">
              Lưu nháp
            </button>
            <button class="bg-primary hover:bg-[#E55F2A] disabled:opacity-50 text-xs font-bold px-6 py-2.5 rounded-xl text-foreground transition shadow-md" :disabled="receiveForm.items.length === 0" @click="submitReceive">
              ✓ Xác nhận {{ t('kitchen.receive') }}
            </button>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: XUẤT KHO -->
      <div v-else-if="activeTab === 'issue'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.issue_title') }}</h2>
          <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.issue_desc') }}</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Pending requisitions sidebar list (1/3 width) -->
          <div class="bg-card rounded-xl border border-border p-4 flex flex-col gap-3 max-h-[500px] overflow-y-auto">
            <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-wider mb-2">{{ $t('kitchen_inventory.pending_requests') }}</h3>
            
            <div v-if="pendingRequisitions.length === 0" class="text-center py-12 text-muted-foreground text-xs">
              📭 Tất cả phiếu yêu cầu đã được xử lý.
            </div>

            <div 
              v-for="req in pendingRequisitions" 
              :key="req.id"
              class="p-4 rounded-xl border cursor-pointer hover:border-primary transition text-xs"
              :class="selectedRequisitionId === req.id ? 'border-primary bg-primary/5' : 'border-border bg-background'"
              @click="selectedRequisitionId = req.id"
            >
              <div class="flex justify-between font-bold mb-1.5">
                <span class="text-foreground">{{ req.id }}</span>
                <span class="text-orange-500">{{ $t('kitchen_inventory.pending_approval') }}</span>
              </div>
              <div class="text-muted-foreground mb-1">Trạm: {{ req.station }} &bull; Người lập: {{ req.actor }}</div>
              <div class="text-muted-foreground text-[10px] font-mono">{{ req.date }}</div>
            </div>
          </div>

          <!-- Active Requisition process panel (2/3 width) -->
          <div class="lg:col-span-2 bg-card rounded-xl border border-border p-6 flex flex-col justify-between min-h-[480px]">
            <div v-if="!activeRequisition" class="flex-1 flex flex-col items-center justify-center text-center text-muted-foreground">
              <span class="text-4xl mb-3">📦</span>
              <p class="text-sm font-bold">{{ $t('kitchen_inventory.select_request') }}</p>
            </div>

            <div v-else class="space-y-6 flex-1 flex flex-col justify-between">
              <!-- Requisition header details -->
              <div class="space-y-4 flex-1">
                <div class="flex justify-between items-start border-b border-border pb-3 flex-wrap gap-2">
                  <div>
                    <span class="text-primary text-xs font-bold uppercase tracking-wider block font-mono">Đang duyệt: {{ activeRequisition.id }}</span>
                    <h3 class="text-base font-bold text-foreground mt-1">Yêu Cầu Kho Bếp - Trạm {{ activeRequisition.station }}</h3>
                  </div>
                  <div class="text-right">
                    <span class="text-xs text-muted-foreground block font-mono">{{ activeRequisition.date }}</span>
                    <span class="text-xs text-muted-foreground">{{ $t('kitchen_inventory.created_by') }} <strong>Chef {{ activeRequisition.actor }}</strong></span>
                  </div>
                </div>

                <!-- Items list -->
                <div class="space-y-3">
                  <h4 class="text-xs font-bold text-muted-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.issue_item_list') }}</h4>
                  
                  <div class="bg-background rounded-xl border border-border overflow-hidden">
                    <table class="w-full text-left text-xs">
                      <thead>
                        <tr class="bg-card text-muted-foreground font-bold uppercase border-b border-border">
                          <th class="py-2.5 px-3">{{ $t('kitchen_inventory.ingredient') }}</th>
                          <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.main_stock_remains') }}</th>
                          <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.request') }}</th>
                          <th class="py-2.5 px-3 text-center">{{ $t('kitchen_inventory.approve_issue') }}</th>
                        </tr>
                      </thead>
                      <tbody class="divide-y divide-[#404040]/40">
                        <tr v-for="item in activeRequisition.items" :key="item.id" class="text-muted-foreground">
                          <td class="py-3 px-3 font-bold flex items-center gap-1.5">
                            <span>{{ item.icon }}</span>
                            <span>{{ item.name }}</span>
                          </td>
                          <td class="py-3 px-3 text-center font-mono font-bold" :class="getMainStock(item.id) < item.requestedQty ? 'text-red-500' : 'text-muted-foreground'">
                            {{ getMainStock(item.id) }} {{ item.unit }}
                          </td>
                          <td class="py-3 px-3 text-center font-mono font-bold">{{ item.requestedQty }} {{ item.unit }}</td>
                          <td class="py-3 px-3 text-center">
                            <input 
                              type="number" 
                              v-model.number="item.deliveredQty" 
                              min="0" 
                              :max="item.requestedQty" 
                              class="w-16 bg-card border border-border rounded py-0.5 text-center font-bold text-foreground text-xs font-mono"
                            />
                            <span class="ml-1 text-muted-foreground font-bold uppercase">{{ item.unit }}</span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>

                <!-- Digital signature preview for verification -->
                <div class="p-4 bg-background rounded-xl border border-border flex justify-between items-center text-xs flex-wrap gap-4">
                  <div class="space-y-1">
                    <span class="text-muted-foreground block font-bold">Xác nhận Bếp trưởng:</span>
                    <span class="text-green-600 font-bold">✓ Đã ký xác nhận từ thiết bị phụ</span>
                  </div>
                  <div v-if="activeRequisition.signatureImage" class="border border-border bg-slate-900 rounded p-1.5 max-h-[50px] flex items-center justify-center">
                    <img :src="activeRequisition.signatureImage" alt="Chef Signature" class="max-h-[36px]" />
                  </div>
                  <div v-else class="text-muted-foreground italic">Chưa có chữ ký</div>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="flex justify-end gap-3 pt-4 border-t border-border">
                <button class="bg-red-100 border border-red-300 text-red-500 hover:bg-red-100 text-xs font-bold px-5 py-2.5 rounded-xl transition" @click="rejectRequisition">
                  Từ chối
                </button>
                <button class="bg-[#4CAF50] hover:bg-[#43a047] text-xs font-bold px-6 py-2.5 rounded-xl text-foreground transition shadow-md" @click="approveRequisition">
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
            <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.stocktake_title') }}</h2>
            <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.stocktake_desc') }}</p>
          </div>
          
          <div class="flex items-center gap-3 text-xs text-muted-foreground font-bold bg-card border border-border px-4 py-2 rounded-xl">
            <span>{{ $t('kitchen_inventory.stocktake_date') }}</span>
            <span>{{ $t('kitchen_inventory.employee') }}</span>
          </div>
        </div>

        <!-- Progress Bar Section -->
        <div class="bg-card rounded-xl p-5 border border-border space-y-3">
          <div class="flex justify-between text-xs font-bold text-muted-foreground">
            <span>{{ $t('kitchen_inventory.stocktake_progress') }}</span>
            <span class="text-[#FF9800]">{{ stocktakeCheckedCount }}/{{ stocktakeTotalCount }} SKU ({{ stocktakeProgress }}%)</span>
          </div>
          <div class="w-full bg-background h-2.5 rounded-full overflow-hidden border border-border">
            <div class="bg-gradient-to-r from-[#FF6B35] to-[#FF9800] h-full transition-all duration-300" :style="{ width: `${stocktakeProgress}%` }"></div>
          </div>
        </div>

        <!-- Filter Tab Buttons -->
        <div class="flex gap-2 border-b border-border pb-2 flex-wrap">
          <button 
            v-for="tab in stocktakeTabs" 
            :key="tab.key" 
            class="px-4 py-2 rounded-lg text-xs font-bold transition"
            :class="stocktakeFilter === tab.key ? 'bg-primary text-primary-foreground' : 'bg-card text-muted-foreground hover:text-foreground'"
            @click="stocktakeFilter = tab.key"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Stocktake inputs list -->
        <div class="bg-card rounded-xl border border-border overflow-hidden">
          <table class="w-full text-left text-sm border-collapse">
            <thead>
              <tr class="bg-background border-b border-border text-muted-foreground text-xs font-bold uppercase">
                <th class="py-3 px-4">{{ $t('kitchen_inventory.storage_location') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.ingredient') }}</th>
                <th class="py-3 px-4 text-center">{{ $t('kitchen_inventory.system_stock') }}</th>
                <th class="py-3 px-4 text-center">{{ $t('kitchen_inventory.actual_count') }}</th>
                <th class="py-3 px-4 text-center">{{ $t('kitchen_inventory.variance') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.adjust_reason') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/40">
              <tr 
                v-for="item in filteredStocktakeItems" 
                :key="item.id" 
                class="hover:bg-muted/20 transition"
                :class="item.diff > 0 ? 'bg-green-100' : item.diff < 0 ? 'bg-red-100' : ''"
              >
                <td class="py-3 px-4 text-xs font-bold text-muted-foreground">{{ item.location }}</td>
                <td class="py-3 px-4 font-bold text-foreground flex items-center gap-2">
                  <span>{{ item.icon }}</span>
                  <span>{{ item.name }}</span>
                </td>
                <td class="py-3 px-4 text-center font-mono font-bold text-muted-foreground">
                  {{ item.theoretical }} {{ item.unit }}
                </td>
                <td class="py-3 px-4 text-center">
                  <input 
                    type="number" 
                    v-model.number="item.actual" 
                    min="0"
                    class="w-20 bg-background border border-border rounded px-2.5 py-1 text-center font-mono font-bold text-foreground text-xs"
                    @input="calculateStocktakeDiff(item)"
                  />
                  <span class="ml-1.5 text-muted-foreground font-bold uppercase text-[10px]">{{ item.unit }}</span>
                </td>
                <td class="py-3 px-4 text-center font-mono font-bold text-sm">
                  <span v-if="item.diff > 0" class="text-green-500">+{{ item.diff }} {{ item.unit }}</span>
                  <span v-else-if="item.diff < 0" class="text-red-500">{{ item.diff }} {{ item.unit }}</span>
                  <span v-else class="text-muted-foreground">0</span>
                </td>
                <td class="py-3 px-4">
                  <input 
                    v-model="item.note" 
                    class="w-full bg-background border border-border rounded px-3 py-1 text-xs text-foreground placeholder-gray-600 focus:outline-none focus:border-primary" 
                    placeholder="Ghi chú điều chỉnh..."
                  />
                </td>
              </tr>
            </tbody>
          </table>

          <div v-if="filteredStocktakeItems.length === 0" class="p-8 text-center text-muted-foreground text-xs">
            📭 Không có mặt hàng nào phù hợp với bộ lọc kiểm kê.
          </div>
        </div>

        <!-- Stocktake action buttons -->
        <div class="flex justify-end gap-3 pt-2">
          <button class="bg-muted border border-border hover:bg-muted text-xs font-bold px-5 py-2.5 rounded-xl text-foreground transition" @click="resetStocktakeForm">
            Đặt lại số liệu
          </button>
          <button class="bg-[#2196F3] hover:bg-[#1E88E5] text-xs font-bold px-5 py-2.5 rounded-xl text-foreground transition" @click="exportStocktakeExcel">
            📥 Xuất File Excel
          </button>
          <button class="bg-primary hover:bg-[#E55F2A] text-xs font-bold px-6 py-2.5 rounded-xl text-foreground transition shadow-md" @click="submitStocktake">
            ✓ Hoàn tất kiểm kê
          </button>
        </div>
      </div>

      <!-- SUB-PAGE: CẢNH BÁO -->
      <div v-else-if="activeTab === 'alerts'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.alerts_title') }}</h2>
          <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.alerts_desc') }}</p>
        </div>

        <!-- Alert Tabs -->
        <div class="flex gap-3">
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'low' ? 'bg-red-100 border-red-600 text-red-500' : 'bg-card border-border text-muted-foreground'"
            @click="alertTab = 'low'"
          >
            Tồn kho thấp ({{ alertLowCount }})
          </button>
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'expiring' ? 'bg-yellow-950/20 border-yellow-600 text-[#FF9800]' : 'bg-card border-border text-muted-foreground'"
            @click="alertTab = 'expiring'"
          >
            Sắp hết hạn ({{ alertExpiringCount }})
          </button>
          <button 
            class="px-5 py-2.5 rounded-xl text-xs font-bold border transition"
            :class="alertTab === 'expired' ? 'bg-red-100 border-red-600 text-red-500' : 'bg-card border-border text-muted-foreground'"
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
            class="alert-card bg-card rounded-xl p-5 border-l-4 flex flex-col justify-between min-h-[220px]"
            :class="item.severity"
          >
            <div class="space-y-4">
              <div class="flex justify-between items-start gap-2">
                <div class="flex items-center gap-3">
                  <span class="text-3xl">{{ item.icon }}</span>
                  <div>
                    <span class="font-bold text-foreground block text-sm">{{ item.name }}</span>
                    <span class="text-[10px] text-muted-foreground font-mono">SKU: {{ item.id }}</span>
                  </div>
                </div>
                <span class="severity-badge text-[10px] font-bold uppercase px-2 py-0.5 rounded-full" :class="item.severity">
                  {{ item.severityText }}
                </span>
              </div>

              <!-- Stats box -->
              <div class="bg-background rounded-xl p-3 text-xs space-y-2 border border-border">
                <div class="flex justify-between">
                  <span class="text-muted-foreground">{{ $t('kitchen_inventory.current_stock') }}</span>
                  <span class="font-bold text-foreground">{{ item.currentStock }} {{ item.unit }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-muted-foreground">{{ $t('kitchen_inventory.min_level') }}</span>
                  <span class="font-bold text-muted-foreground">{{ item.minStock }} {{ item.unit }}</span>
                </div>
                <div v-if="item.expiryDate" class="flex justify-between">
                  <span class="text-muted-foreground">{{ $t('kitchen_inventory.fefo_expiry') }}</span>
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

          <div v-if="activeAlertItems.length === 0" class="col-span-full py-16 text-center text-muted-foreground bg-card rounded-2xl border border-dashed border-border">
            📭 Tuyệt vời! Không có cảnh báo tồn kho nào cần xử lý.
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: BÁO CÁO & PHÂN TÍCH -->
      <div v-else-if="activeTab === 'reports'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.reports_title') }}</h2>
          <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.reports_desc') }}</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          <!-- Food Cost & Variance KPI -->
          <div class="bg-card rounded-xl p-5 border border-border space-y-4">
            <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.financial_index_june') }}</h3>
            
            <div class="space-y-3">
              <div class="p-3 bg-background rounded-lg">
                <span class="text-[10px] text-muted-foreground uppercase font-bold block">{{ $t('kitchen_inventory.food_cost') }}</span>
                <span class="text-xl font-black text-foreground">28.4%</span>
                <span class="text-[10px] text-green-500 block">{{ $t('kitchen_inventory.down_1_2') }}</span>
              </div>
              <div class="p-3 bg-background rounded-lg">
                <span class="text-[10px] text-muted-foreground uppercase font-bold block">{{ $t('kitchen_inventory.loss_ratio') }}</span>
                <span class="text-xl font-black text-red-500">1.85%</span>
                <span class="text-[10px] text-red-500 block">{{ $t('kitchen_inventory.up_0_15_wagyu') }}</span>
              </div>
              <div class="p-3 bg-background rounded-lg">
                <span class="text-[10px] text-muted-foreground uppercase font-bold block">{{ $t('kitchen_inventory.turnover_rate') }}</span>
                <span class="text-xl font-black text-[#FF9800]">{{ $t('kitchen_inventory.4_2_times') }}</span>
                <span class="text-[10px] text-muted-foreground block">{{ $t('kitchen_inventory.avg_storage_time') }}</span>
              </div>
            </div>
          </div>

          <!-- ABC Analysis Widget (Value concentration) -->
          <div class="bg-card rounded-xl p-5 border border-border space-y-4">
            <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.abc_analysis') }}</h3>
            
            <div class="space-y-4">
              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-primary">{{ $t('kitchen_inventory.group_a') }}</span>
                  <span>14 SKU</span>
                </div>
                <div class="w-full bg-background h-2 rounded-full overflow-hidden">
                  <div class="bg-primary h-full" style="width: 73%"></div>
                </div>
                <span class="text-[10px] text-muted-foreground block mt-1">{{ $t('kitchen_inventory.group_a_desc') }}</span>
              </div>

              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-blue-600">{{ $t('kitchen_inventory.group_b') }}</span>
                  <span>45 SKU</span>
                </div>
                <div class="w-full bg-background h-2 rounded-full overflow-hidden">
                  <div class="bg-[#2196F3] h-full" style="width: 20%"></div>
                </div>
                <span class="text-[10px] text-muted-foreground block mt-1">{{ $t('kitchen_inventory.group_b_desc') }}</span>
              </div>

              <div>
                <div class="flex justify-between text-xs font-bold mb-1">
                  <span class="text-muted-foreground">{{ $t('kitchen_inventory.group_c') }}</span>
                  <span>186 SKU</span>
                </div>
                <div class="w-full bg-background h-2 rounded-full overflow-hidden">
                  <div class="bg-gray-600 h-full" style="width: 7%"></div>
                </div>
                <span class="text-[10px] text-muted-foreground block mt-1">{{ $t('kitchen_inventory.group_c_desc') }}</span>
              </div>
            </div>
          </div>

          <!-- Optimization suggestions -->
          <div class="bg-card rounded-xl p-5 border border-border space-y-4">
            <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-wider">{{ $t('kitchen_inventory.optimization_proposals') }}</h3>
            
            <div class="space-y-3 text-xs">
              <div class="p-3 bg-[#FF9800]/5 border-l-3 border-[#FF9800] rounded">
                <strong class="text-[#FF9800] block mb-1">{{ $t('kitchen_inventory.adj_wagyu') }}</strong>
                <p class="text-muted-foreground leading-normal">{{ $t('kitchen_inventory.adj_wagyu_desc') }}</p>
              </div>

              <div class="p-3 bg-[#4CAF50]/5 border-l-3 border-[#4CAF50] rounded">
                <strong class="text-green-600 block mb-1">{{ $t('kitchen_inventory.change_veg') }}</strong>
                <p class="text-muted-foreground leading-normal">{{ $t('kitchen_inventory.change_veg_desc') }}</p>
              </div>
            </div>
          </div>

        </div>
      </div>

      <!-- SUB-PAGE: NHÀ CUNG CẤP -->
      <div v-else-if="activeTab === 'suppliers'" class="space-y-6 animate-fade-in">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.suppliers_title') }}</h2>
            <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.suppliers_desc') }}</p>
          </div>
          <button class="btn-primary" @click="addNewSupplier">
            + Thêm đối tác
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div 
            v-for="s in mockSuppliers" 
            :key="s.id"
            class="bg-card rounded-xl border border-border p-5 space-y-4 hover:border-border transition flex flex-col justify-between"
          >
            <div class="space-y-3">
              <div class="flex justify-between items-start">
                <div>
                  <h3 class="text-base font-bold text-foreground">{{ s.name }}</h3>
                  <span class="text-[10px] text-muted-foreground font-mono">Mã đối tác: {{ s.id }}</span>
                </div>
                <span class="px-2 py-0.5 bg-[#2196F3]/10 text-blue-600 border border-[#2196F3]/20 text-[10px] font-bold rounded">
                  {{ s.category }}
                </span>
              </div>

              <div class="space-y-1.5 text-xs text-muted-foreground">
                <div>{{ $t('kitchen_inventory.contact') }} <strong class="text-foreground">{{ s.contact }}</strong></div>
                <div>{{ $t('kitchen_inventory.address') }} <span class="text-muted-foreground">{{ s.address }}</span></div>
                <div>{{ $t('kitchen_inventory.quality_rating') }} <span class="text-yellow-500">⭐⭐⭐⭐⭐ (5.0)</span></div>
              </div>
            </div>

            <div class="pt-3 border-t border-border flex justify-between items-center text-xs">
              <span class="text-muted-foreground">{{ $t('kitchen_inventory.pending_po') }} <strong class="text-foreground">0</strong></span>
              <button class="text-primary font-bold hover:underline" @click="contactSupplier(s)">{{ $t('kitchen_inventory.buy_now') }}</button>
            </div>
          </div>
        </div>
      </div>

      <!-- SUB-PAGE: LỊCH SỬ GIAO DỊCH KHO -->
      <div v-else-if="activeTab === 'history'" class="space-y-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-black uppercase text-foreground tracking-wide">{{ $t('kitchen_inventory.history_title') }}</h2>
          <p class="text-xs text-muted-foreground mt-1">{{ $t('kitchen_inventory.history_desc') }}</p>
        </div>

        <!-- History logs list -->
        <div class="bg-card rounded-xl border border-border overflow-hidden">
          <table class="w-full text-left text-sm border-collapse">
            <thead>
              <tr class="bg-background border-b border-border text-muted-foreground text-xs font-bold uppercase">
                <th class="py-3 px-4">{{ $t('kitchen_inventory.time') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.transaction') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.affected_item') }}</th>
                <th class="py-3 px-4 text-right">{{ $t('kitchen_inventory.amount_change') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.accountant') }}</th>
                <th class="py-3 px-4">{{ $t('kitchen_inventory.note_detail') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#404040]/40">
              <tr v-for="log in fullTransactionLogs" :key="log.id" class="hover:bg-muted/20 transition text-muted-foreground">
                <td class="py-3.5 px-4 font-mono text-xs text-muted-foreground">{{ log.time }}</td>
                <td class="py-3.5 px-4">
                  <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase" :class="getLogTypeClass(log.type)">
                    {{ log.typeLabel }}
                  </span>
                </td>
                <td class="py-3.5 px-4 font-bold text-foreground flex items-center gap-1.5">
                  <span>{{ log.itemIcon }}</span>
                  <span>{{ log.itemName }}</span>
                </td>
                <td class="py-3.5 px-4 text-right font-mono font-bold" :class="log.qty >= 0 ? 'text-green-500' : 'text-red-500'">
                  {{ log.qty >= 0 ? '+' : '' }}{{ log.qty }} {{ log.unit }}
                </td>
                <td class="py-3.5 px-4 text-xs font-semibold text-muted-foreground">👤 {{ log.actor }}</td>
                <td class="py-3.5 px-4 text-xs text-muted-foreground italic">"{{ log.note }}"</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </main>

    <!-- 3. DIALOGS & MODALS -->
    <!-- Modal: Add/Edit Ingredient -->
    <div v-if="showIngredientModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm" @click.self="showIngredientModal = false">
      <div class="bg-card border border-border rounded-2xl w-full max-w-[500px] shadow-2xl overflow-hidden flex flex-col">
        <div class="px-6 py-4 bg-background border-b border-border flex justify-between items-center">
          <h3 class="text-lg font-bold text-primary">{{ $t('kitchen_inventory.add_new_ingredient') }}</h3>
          <button class="text-muted-foreground hover:text-foreground" @click="showIngredientModal = false">✕</button>
        </div>
        <div class="p-6 space-y-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.ingredient_name') }}</label>
            <input v-model="ingredientForm.name" placeholder="Ví dụ: Ba chỉ bò Mỹ" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none focus:border-primary" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.emoji') }}</label>
              <input v-model="ingredientForm.icon" placeholder="🥩" class="bg-background text-center border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.unit') }}</label>
              <input v-model="ingredientForm.unit" placeholder="kg" class="bg-background text-center border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.category') }}</label>
              <select v-model="ingredientForm.category" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none">
                <option :value="$t('kitchen_inventory.meat')">{{ $t('kitchen_inventory.beef_ribs') }}</option>
                <option :value="$t('kitchen_inventory.seafood')">{{ $t('kitchen_inventory.fresh_seafood') }}</option>
                <option :value="$t('kitchen_inventory.veg')">{{ $t('kitchen_inventory.vegetables') }}</option>
                <option :value="$t('kitchen_inventory.spices')">{{ $t('kitchen_inventory.broth_spices') }}</option>
              </select>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.min_stock_level') }}</label>
              <input type="number" v-model.number="ingredientForm.minKitchenStock" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.initial_main_stock') }}</label>
              <input type="number" v-model.number="ingredientForm.mainStock" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-muted-foreground font-bold">{{ $t('kitchen_inventory.unit_cost') }}</label>
              <input type="number" v-model.number="ingredientForm.unitPrice" class="bg-background border border-border rounded-xl px-4 py-2.5 text-sm text-foreground focus:outline-none" />
            </div>
          </div>
        </div>
        <div class="px-6 py-4 bg-background border-t border-border flex justify-end gap-3">
          <button class="bg-muted hover:bg-muted text-xs font-bold px-4 py-2 rounded-lg text-foreground" @click="showIngredientModal = false">{{ $t('kitchen_inventory.cancel') }}</button>
          <button class="bg-primary hover:bg-[#E55F2A] text-xs font-bold px-5 py-2 rounded-lg text-foreground" @click="submitAddIngredient">{{ $t('kitchen_inventory.confirm_add') }}</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useKitchenStore } from '@/stores/kitchen';
import Swal from 'sweetalert2';
import { useInventory } from '@/composables/useInventory';
import { useI18n } from 'vue-i18n';
import { useUnsavedGuard } from '@/composables/useUnsavedGuard';

const router = useRouter();
const kitchenStore = useKitchenStore();
const { t } = useI18n();

const { inventory, fetchInventory, addStock, adjustStock, subscribeToStockUpdates, unsubscribe } = useInventory();

onMounted(() => {
  fetchInventory();
  subscribeToStockUpdates();
});

onUnmounted(() => {
  unsubscribe();
});

const mappedInventoryList = computed(() => {
  return inventory.value.map(item => ({
    id: item.ingredient_id,
    sku: item.sku,
    name: item.name_vi,
    icon: '🥩', 
    unit: item.unit,
    category: item.category_name_vi,
    minKitchenStock: item.low_stock_threshold,
    mainStock: item.quantity,
    kitchenStock: 0,
    unitPrice: item.unit_cost,
    isLowStock: item.is_low_stock,
    nextExpiryDate: item.next_expiry_date
  }));
});

const navigateBack = () => {
  router.push('/kitchen/kds');
};

const activeTab = ref<string>('dashboard');

// Navigation sidebar items
const navItems = [
  { key: 'dashboard', label: 'Dashboard', icon: '📊' },
  { key: 'ingredients', label: t('kitchen_inventory.ingredient'), icon: '🥩' },
  { key: 'receive', label: t('kitchen.receive'), icon: '📥' },
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
const totalSkus = computed(() => mappedInventoryList.value.length);
const totalInventoryValue = computed(() => {
  return mappedInventoryList.value.reduce((acc, item) => acc + (item.mainStock * item.unitPrice), 0);
});

const expiringCount = ref(2); // Mock count for expiring items
const lowStockCount = computed(() => {
  return mappedInventoryList.value.filter(item => item.mainStock <= item.minKitchenStock).length;
});

// Category stats SKU
const categoryChartData = computed(() => {
  const categories = [t('kitchen_inventory.meat'), t('kitchen_inventory.seafood'), t('kitchen_inventory.veg'), t('kitchen_inventory.spices')];
  const colors = [
    'from-red-500 to-red-800',
    'from-blue-500 to-blue-800',
    'from-green-500 to-green-800',
    'from-yellow-500 to-yellow-800'
  ];
  return categories.map((cat, idx) => {
    const count = mappedInventoryList.value.filter(item => item.category === cat).length;
    return {
      name: cat,
      count: count || (idx === 0 ? 9 : idx === 1 ? 5 : idx === 2 ? 12 : 7), // mock fallback if empty
      color: colors[idx]
    };
  });
});

// Top alert items in Dashboard
const topAlertItems = computed(() => {
  return mappedInventoryList.value.filter(item => item.mainStock <= item.minKitchenStock).slice(0, 5);
});

// Mock Initial Logs list
const recentLogs = ref([
  { id: 'l1', time: '27/06 10:45', type: 'receive', typeLabel: t('kitchen.receive'), itemName: 'Thịt bò Wagyu', qty: 30 },
  { id: 'l2', time: '27/06 09:30', type: 'issue', typeLabel: 'Xuất kho', itemName: 'Nước lẩu Sukiyaki', qty: -8 },
  { id: 'l3', time: '26/06 16:15', type: 'stocktake', typeLabel: 'Điều chỉnh', itemName: 'Rau thập cẩm', qty: -0.5 },
  { id: 'l4', time: '26/06 14:00', type: 'issue', typeLabel: 'Xuất kho', itemName: 'Thịt bò Wagyu', qty: -5 }
]);

const getLogTypeClass = (type: string) => {
  if (type === 'receive') return 'bg-green-100 text-green-500 border border-green-300';
  if (type === 'issue') return 'bg-orange-100 text-orange-500 border border-orange-800/40';
  return 'bg-blue-950/40 text-blue-500 border border-blue-800/40';
};

// Full transactional logs sub-page
const fullTransactionLogs = computed(() => {
  return recentLogs.value.map(log => {
    const invItem = mappedInventoryList.value.find(i => i.name === log.itemName);
    return {
      ...log,
      itemIcon: invItem?.icon || '📦',
      unit: invItem?.unit || 'kg',
      actor: 'Quản lý Nam',
      note: log.type === 'receive' ? `${t('kitchen.receive')} từ NCC Mekas Foods` : log.type === 'issue' ? 'Xuất kho phục vụ bếp ca sáng' : 'Đếm thực tế chênh lệch hao hụt'
    };
  });
});

// ─── SUB-PAGE: INGREDIENTS LIST ──────────────────────────────────────────
const searchQuery = ref('');
const categoryFilter = ref('');
const stockFilter = ref('');

const filteredIngredients = computed(() => {
  return mappedInventoryList.value.filter(item => {
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
  category: t('kitchen_inventory.meat'),
  minKitchenStock: 5,
  mainStock: 10,
  unitPrice: 150000
});

const openAddIngredientModal = () => {
  ingredientForm.value = {
    name: '',
    icon: '🥩',
    unit: 'kg',
    category: t('kitchen_inventory.meat'),
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
  mappedInventoryList.value.push({
    id: newSku,
    sku: newSku,
    name: ingredientForm.value.name,
    icon: ingredientForm.value.icon,
    unit: ingredientForm.value.unit,
    category: ingredientForm.value.category,
    minKitchenStock: ingredientForm.value.minKitchenStock,
    mainStock: ingredientForm.value.mainStock,
    kitchenStock: 0,
    unitPrice: ingredientForm.value.unitPrice,
    isLowStock: false,
    nextExpiryDate: null
  });

  // Log transaction
  recentLogs.value.unshift({
    id: `log-${Date.now()}`,
    time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
    type: 'receive',
    typeLabel: t('kitchen.receive'),
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
    html: `<div class="text-left text-xs text-muted-foreground space-y-2">
      <div>• 27/06 10:45: ${t('kitchen.receive')} +30 ${item.unit}</div>
      <div>• 26/06 14:00: Xuất bếp -5 ${item.unit}</div>
      <div>• 25/06 09:15: Đóng ca điều chỉnh -0.5 ${item.unit}</div>
    </div>`,
    icon: 'info',
    background: '#2D2D2D',
    color: '#FFF'
  });
};

// ─── SUB-PAGE: {{ t('kitchen.receive') }} (RECEIVE STOCK) ──────────────────────────────────
const mockSuppliers = ref([
  { id: 'SUP-001', name: 'Mekas Foods', category: 'Thịt tươi', contact: '0901.234.567', address: 'Bình Tân, HCM' },
  { id: 'SUP-002', name: 'Naka Seafood', category: t('kitchen_inventory.seafood'), contact: '0902.987.654', address: 'Vũng Tàu' },
  { id: 'SUP-003', name: 'GreenFarm Sạch', category: t('kitchen_inventory.vegetables'), contact: '0903.321.456', address: 'Đà Lạt, Lâm Đồng' }
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
  const found = mappedInventoryList.value.find(i => i.id === id);
  return found ? found.unit : 'kg';
};

const receiveTotalAmount = computed(() => {
  return receiveForm.value.items.reduce((acc, row) => acc + ((row.quantity || 0) * (row.unitPrice || 0)), 0);
});

const resetReceiveForm = () => {
  receiveForm.value.items = [];
};

const saveReceiveDraft = () => {
  Swal.fire({ title: 'Đã lưu nháp', text: `Bản thảo phiếu ${t('kitchen.receive')} đã được lưu cục bộ!`, icon: 'success', background: '#2D2D2D', color: '#FFF' });
};

const submitReceive = async () => {
  try {
    for (const row of receiveForm.value.items) {
      const item = mappedInventoryList.value.find(i => i.id === row.ingredientId);
      if (item && item.id) {
        // Here we pass the UUID to addStock, not the SKU
        await addStock(item.id, row.quantity, 'IN', `${t('kitchen.receive')} từ ${receiveForm.value.supplierId}`, row.expiryDate);
      }
    }
    Swal.fire({ title: `${t('kitchen.receive')} thành công`, text: 'Tồn kho tổng hệ thống đã được cập nhật cộng dồn!', icon: 'success', background: '#2D2D2D', color: '#FFF' });
    resetReceiveForm();
    activeTab.value = 'dashboard';
  } catch (err: any) {
    Swal.fire({ title: 'Lỗi', text: err.message || 'Lỗi hệ thống', icon: 'error', background: '#2D2D2D', color: '#FFF' });
  }
};

// Baseline snapshot for the goods-receipt form. Snapshot is fresh at the
// moment the user enters the receive page (so empty/in-progress drafts are
// always considered dirty, prompting before discard).
const receiveFormBaseline = ref<typeof receiveForm.value>({ ...receiveForm.value })
const { confirmIfDirty: confirmReceiveDirty } = useUnsavedGuard(
  receiveForm,
  receiveFormBaseline,
)
async function cancelReceive() {
  if (await confirmReceiveDirty()) {
    resetReceiveForm()
  }
}

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
  const found = mappedInventoryList.value.find(i => i.id === itemId);
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
    const mainInv = mappedInventoryList.value.find(i => i.id === item.id);
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
    const mainInv = mappedInventoryList.value.find(i => i.id === item.id);
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
  stocktakeItems.value = mappedInventoryList.value.map((item, idx) => ({
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
  Swal.fire({ title: 'Xuất File Thành Công', text: `Tài liệu đối soát ${t('kitchen.stocktake')} định kỳ dạng Excel đã được tải xuống!`, icon: 'success', background: '#2D2D2D', color: '#FFF' });
};

const submitStocktake = async () => {
  try {
    for (const verifyItem of stocktakeItems.value) {
      const inv = mappedInventoryList.value.find(i => i.id === verifyItem.id);
      if (inv && verifyItem.checked && verifyItem.diff !== 0) {
        // Adjust stock expects the UUID
        await adjustStock(inv.id, verifyItem.actual);
      }
    }
    Swal.fire({ title: 'Cập nhật hoàn tất', text: `Báo cáo ${t('kitchen.stocktake')} đã được lưu!`, icon: 'success', background: '#2D2D2D', color: '#FFF' });
    activeTab.value = 'dashboard';
  } catch (err: any) {
    Swal.fire({ title: 'Lỗi', text: err.message || 'Lỗi hệ thống', icon: 'error', background: '#2D2D2D', color: '#FFF' });
  }
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
  mappedInventoryList.value.forEach(item => {
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
    cancelButtonText: t('kitchen_inventory.cancel'),
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
    html: `<input id="sup-name" placeholder="Tên đối tác" class="swal2-input bg-background border-border text-foreground">
           <input id="sup-phone" placeholder="Số điện thoại liên hệ" class="swal2-input bg-background border-border text-foreground">`,
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

