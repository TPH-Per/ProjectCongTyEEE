<!-- File: src/views/reception/ReceptionOrderView.vue -->
<template>
  <div
    class="h-screen w-full flex overflow-hidden font-sans select-none text-gray-800 bg-[#1e1e1e] relative"
  >
    <!-- SYSTEM TOAST QUEUE OVERLAY -->
    <div
      class="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none"
    >
      <transition-group name="toast-list">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          :class="[
            'p-4 rounded-xl shadow-lg border flex items-start gap-3 pointer-events-auto transition-all duration-300',
            toast.type === 'success'
              ? 'bg-[#e8f5e9] border-[#c8e6c9] text-[#2e7d32]'
              : toast.type === 'warning'
                ? 'bg-[#fff3e0] border-[#ffe0b2] text-[#e65100]'
                : toast.type === 'error'
                  ? 'bg-[#ffebee] border-[#ffcdd2] text-[#c62828]'
                  : 'bg-[#e3f2fd] border-[#bbdefb] text-[#1565c0]',
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
    <div
      class="flex-1 flex flex-col min-h-0 overflow-hidden bg-[#3a3a3a] text-gray-200"
    >
      <!-- 1. TOP BAR (Header) -->
      <header
        class="h-16 shrink-0 bg-[#2d2d2d] border-b border-[#1e1e1e] flex items-center justify-between px-6 select-none z-10 text-white shadow-md"
      >
        <!-- Navigation Tabs -->
        <div class="flex items-center gap-2">
          <button
            @click="showMenu = !showMenu"
            class="p-2 hover:bg-[#3a3a3a] rounded-lg transition-colors mr-2 text-gray-400 hover:text-white"
            type="button"
          >
            ☰
          </button>

          <button
            @click="activeMainTab = 'invoice'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all',
              activeMainTab === 'invoice'
                ? 'bg-[#ff8f00] text-white shadow'
                : 'text-gray-400 hover:text-white',
            ]"
            type="button"
          >
            {{ t("reception.receipt") }}
          </button>

          <button
            @click="activeMainTab = 'menu'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5',
              activeMainTab === 'menu'
                ? 'bg-[#ff8f00] text-white shadow'
                : 'text-gray-400 hover:text-white',
            ]"
            type="button"
          >
            {{ t("reception.details")
            }}<span
              class="bg-red-600 text-white text-[9px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center"
            >
              {{
                activeOrder.items
                  ? activeOrder.items.reduce(
                      (sum, item) => sum + item.quantity,
                      0,
                    )
                  : 0
              }}
            </span>
          </button>

          <!-- Tab Chưa xử lý -->
          <button
            @click="activeMainTab = 'pending'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5',
              activeMainTab === 'pending'
                ? 'bg-[#ff8f00] text-white shadow'
                : 'text-gray-400 hover:text-white',
            ]"
            type="button"
          >
            {{ t("reception.unprocessed")
            }}<span
              v-if="pendingCount > 0"
              class="bg-red-600 text-white text-[9px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center"
            >
              {{ pendingCount }}
            </span>
          </button>

          <button
            @click="activeMainTab = 'table_map'"
            :class="[
              'px-4 py-2 text-xs font-bold rounded-lg transition-all',
              activeMainTab === 'table_map'
                ? 'bg-[#ff8f00] text-white shadow'
                : 'text-gray-400 hover:text-white',
            ]"
            type="button"
          >
            {{ t("reception.floor_plan") }}
          </button>
        </div>

        <!-- Cashier info -->
        <div class="flex items-center gap-6 text-xs font-bold text-gray-300">
          <div>
            <span class="text-gray-500 mr-1">{{ t("reception.cashier") }}</span>
            <span class="text-white">{{ profile?.full_name || "mo" }}</span>
          </div>
          <div class="font-mono text-gray-400 flex items-center gap-2">
            <span>{{ formattedDate }} {{ formattedTime }}</span>
            <span
              class="bg-purple-900/60 border border-purple-800 text-purple-300 px-2 py-0.5 rounded text-[10px]"
              >Ca: 1</span
            >
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 relative">
          <!-- Search input if toggled -->
          <div v-if="showSearch" class="relative flex items-center mr-1">
            <input
              v-model="tableSearchQuery"
              type="text"
              :placeholder="t('reception.search_table_guest')"
              class="bg-[#3a3a3a] border border-[#ff8f00] text-xs text-white rounded-lg px-3 py-1.5 focus:outline-none w-48 font-bold"
            />
            <button
              v-if="tableSearchQuery"
              @click="tableSearchQuery = ''"
              class="absolute right-2 text-gray-400 hover:text-white text-xs"
              type="button"
            >
              ✕
            </button>
          </div>

          <button
            class="icon-btn search-btn mr-1"
            @click="showSearch = !showSearch"
            :title="t('reception.search')"
            type="button"
          >
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
          </button>

          <!-- More options button -->
          <div class="relative mr-2">
            <button
              class="icon-btn more-btn"
              @click="showMoreMenu = !showMoreMenu"
              :title="t('reception.more_options')"
              type="button"
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <circle cx="12" cy="5" r="2"></circle>
                <circle cx="12" cy="12" r="2"></circle>
                <circle cx="12" cy="19" r="2"></circle>
              </svg>
            </button>

            <!-- Dropdown Menu -->
            <div v-if="showMoreMenu" class="more-dropdown">
              <button type="button" @click="showOtherIncomeModal = true">
                {{ t("reception.other_income") }}
              </button>
              <button type="button" @click="openSettings">
                {{ t("reception.settings") }}
              </button>
              <button type="button" @click="openShortcuts">
                {{ t("reception.shortcuts") }}
              </button>
              <button type="button" @click="openHelp">
                {{ t("reception.help") }}
              </button>
              <button type="button" @click="openAbout">
                {{ t("reception.about") }}
              </button>
              <hr />
              <button type="button" @click="logout" class="danger">
                {{ t("reception.logout") }}
              </button>
            </div>
          </div>

          <button
            class="relative p-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] rounded-lg transition-colors mr-2"
            :title="t('reception.notifications')"
            type="button"
          >
            🔔
            <span
              class="absolute -top-1 -right-1 bg-red-650 text-white text-[8px] font-black w-4 h-4 rounded-full flex items-center justify-center animate-pulse"
              >99+</span
            >
          </button>

          <button
            @click="goBack"
            class="px-4 py-2 bg-[#E8772E] hover:bg-[#d0621f] text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow mr-1"
            type="button"
          >
            {{ t("reception.temp_exit") }}
          </button>

          <button
            @click="goBack"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow"
            type="button"
          >
            {{ t("reception.go_back") }}
          </button>
        </div>
      </header>

      <!-- Split body container -->
      <div class="flex-1 flex min-h-0 relative">
        <aside
          class="pos-traditional-layout pos-sidebar transition-all duration-300 ease-in-out sidebar-container bg-[#1a1a1a] border-r border-[#333] h-full overflow-hidden flex-shrink-0 flex flex-col w-[320px]"
          :class="
            selectedTableCode && activeMainTab !== 'invoice'
              ? 'sidebar-open'
              : 'sidebar-closed'
          "
        >
          <!-- Top Tabs -->
          <div class="top-tabs flex-shrink-0">
            <button
              :class="['tab-btn', activeMainTab === 'menu' ? 'active' : '']"
              @click="activeMainTab = 'menu'"
              type="button"
            >
              {{ t("reception.ordering")
              }}<span class="badge">{{
                activeOrder.items ? activeOrder.items.length : 0
              }}</span>
            </button>
            <button
              :class="['tab-btn', activeMainTab === 'invoice' ? 'active' : '']"
              @click="activeMainTab = 'invoice'"
              type="button"
            >
              {{ t("reception.details") }}
            </button>
            <button
              :class="['tab-btn', activeMainTab === 'pending' ? 'active' : '']"
              @click="activeMainTab = 'pending'"
              type="button"
            >
              {{ t("reception.unprocessed")
              }}<span v-if="pendingCount > 0" class="badge bg-[#F44336]">{{
                pendingCount
              }}</span>
            </button>
            <button
              class="menu-btn"
              type="button"
              @click="triggerToast('info', 'Trợ giúp nhanh')"
            >
              ❓
            </button>
            <button
              class="menu-btn"
              type="button"
              @click="triggerToast('info', 'Tổng hợp số liệu bàn')"
            >
              Σ
            </button>
            <button
              class="menu-btn"
              type="button"
              @click="showOtherIncomeModal = true"
              :title="t('reception.other_income_short')"
            >
              💸
            </button>
            <button
              class="menu-btn"
              type="button"
              @click="showMoreMenu = !showMoreMenu"
            >
              ⚙️
            </button>
          </div>

          <!-- IF activeMainTab !== 'invoice' (ĐANG ORDER / CHƯA XỬ LÝ / SƠ ĐỒ BÀN) -->
          <template v-if="activeMainTab !== 'invoice'">
            <!-- 1. Header Info (Fixed) -->
            <div
              class="flex-shrink-0 bg-[#2d2d2d] border-b border-[#444] p-2 text-white"
            >
              <div class="flex justify-between items-center text-[11px]">
                <span class="text-[#E8772E] font-bold"
                  >Vị trí: {{ selectedTableCode || "[Chưa chọn]" }}</span
                >
                <span class="text-gray-400">In: {{ printCount }}</span>
              </div>
              <div class="text-[10px] text-gray-500 mt-0.5">
                TG: {{ currentTime }}
              </div>
              <input
                type="text"
                :placeholder="t('reception.customer_dots')"
                v-model="activeOrder.customerName"
                class="w-full mt-1.5 bg-[#1a1a1a] border border-[#444] rounded px-2 py-1 text-[11px] text-white"
              />
            </div>

            <!-- 2. Order Items (Scrollable) -->
            <div
              class="flex-1 overflow-y-auto p-2 space-y-1.5 min-h-0 items-list animate-all duration-250"
              style="scrollbar-width: thin; scrollbar-color: #e8772e #2d2d2d"
            >
              <!-- Empty State -->
              <div
                v-if="!activeOrder.items || activeOrder.items.length === 0"
                class="flex flex-col items-center justify-center h-full text-gray-500 py-20"
              >
                <span class="text-3xl mb-2">🛒</span>
                <p class="text-xs font-bold">
                  {{ t("reception.empty_order") }}
                </p>
              </div>

              <!-- Items -->
              <div
                v-for="item in activeOrder.items"
                :key="item.id"
                class="bg-[#2d2d2d] border border-[#444] rounded-lg p-2 flex-shrink-0 text-white hover:border-[#555] transition-all"
              >
                <div class="flex justify-between items-center gap-2">
                  <h4
                    class="text-[11px] font-bold text-white flex-1 truncate item-name-truncate"
                    :title="item.name"
                  >
                    {{ item.name }}
                  </h4>
                  <div
                    class="flex items-center gap-1 bg-[#1a1a1a] rounded px-1.5 py-0.5 flex-shrink-0"
                  >
                    <button
                      type="button"
                      @click="updateQty(item.id, -1)"
                      class="w-5 h-5 text-xs text-white hover:bg-[#444] rounded flex items-center justify-center"
                    >
                      -
                    </button>
                    <span
                      class="text-[11px] font-bold text-white w-4 text-center"
                      >{{ item.quantity }}</span
                    >
                    <button
                      type="button"
                      @click="updateQty(item.id, 1)"
                      class="w-5 h-5 text-xs text-white hover:bg-[#444] rounded flex items-center justify-center"
                    >
                      +
                    </button>
                  </div>
                </div>
                <div
                  class="flex justify-between items-center text-[10px] pt-1 border-t border-[#444] mt-1"
                >
                  <span class="text-gray-400"
                    >{{ formatVND(item.price) }}/{{ item.unit }}</span
                  >
                  <span class="text-[#E8772E] font-bold font-mono">{{
                    formatVND(item.price * item.quantity)
                  }}</span>
                </div>
              </div>
            </div>

            <!-- 3. Billing Summary (Fixed bottom) -->
            <div
              class="flex-shrink-0 bg-[#2d2d2d] border-t border-[#444] p-2 text-white"
            >
              <div class="flex justify-between text-[11px] mb-1">
                <span class="text-gray-400">{{
                  t("reception.goods_amount")
                }}</span>
                <span class="text-white font-mono">{{
                  formatVND(summary.subtotal)
                }}</span>
              </div>
              <div class="flex justify-between text-[11px] mb-1">
                <span class="text-gray-400">{{ t("reception.discount") }}</span>
                <span class="text-red-400 font-mono"
                  >-{{ formatVND(summary.discount) }}</span
                >
              </div>
              <div class="flex justify-between text-[11px] mb-1">
                <span class="text-gray-400">VAT (8%):</span>
                <span class="text-green-400 font-mono">{{
                  formatVND(summary.vat)
                }}</span>
              </div>
              <div
                class="flex justify-between text-xs font-bold pt-1.5 border-t border-[#444] mt-1.5"
              >
                <span class="text-white">{{ t("reception.total") }}</span>
                <span class="text-[#E8772E] font-mono text-sm">{{
                  formatVND(summary.grandTotal)
                }}</span>
              </div>

              <!-- Go to Menu button -->
              <button
                class="w-full mt-2.5 py-1.5 bg-[#2980B9] hover:bg-[#1a5276] text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow font-sans"
                type="button"
                @click="activeMainTab = 'menu'"
              >
                {{ t("reception.view_menu") }}
              </button>
            </div>
          </template>

          <!-- IF activeMainTab === 'invoice' (CHI TIẾT ORDER - BẾP & GIAO HÀNG) -->
          <template v-else>
            <!-- Order List (Bếp & Giao Hàng) -->
            <div class="order-list">
              <div
                v-for="group in orderGroups"
                :key="group.id"
                class="order-group"
              >
                <div class="group-header">
                  <span
                    >{{ group.datetime }} - {{ group.code }} -
                    {{ group.customer }}</span
                  >
                </div>

                <div
                  v-for="item in group.items"
                  :key="item.id"
                  class="order-item"
                >
                  <div class="item-main">
                    <img
                      v-if="item.image"
                      :src="item.image"
                      class="item-thumb"
                    />
                    <div class="item-info">
                      <div class="item-name">{{ item.name }}</div>
                      <div class="item-status">
                        <span v-if="item.status" class="status-badge">{{
                          item.status
                        }}</span>
                        <span class="item-price">{{
                          formatVND(item.price)
                        }}</span>
                      </div>
                      <div class="kitchen-label">{{ item.kitchen }}</div>
                    </div>
                    <div class="item-qty">
                      <div class="qty-box">{{ item.quantity }}</div>
                      <div class="qty-unit">{{ item.unit }}</div>
                    </div>
                    <div
                      class="item-time bg-gray-650/10 px-2 py-0.5 rounded text-[11px] font-bold text-gray-500"
                    >
                      {{ item.waitTime }}'
                    </div>
                    <input
                      type="checkbox"
                      v-model="item.checked"
                      class="item-check w-4 h-4 accent-[#E8772E] cursor-pointer"
                    />
                  </div>
                </div>

                <div class="group-footer">
                  Số lần in: {{ group.printCount }}
                </div>
              </div>
            </div>

            <!-- Footer Actions -->
            <div class="action-footer">
              <div
                class="cart-icon bg-red-600 text-white text-[10px] font-black w-5 h-5 rounded-full flex items-center justify-center"
              >
                2
              </div>
              <div class="total-info">
                <span class="text-[10px] text-gray-300">{{
                  t("reception.total_vnd")
                }}</span>
                <span class="total-value font-mono font-black text-sm">{{
                  formatVND(1490400)
                }}</span>
              </div>
              <button
                class="btn-remind"
                type="button"
                @click="handleRemindKitchen"
              >
                {{ t("reception.remind_kitchen") }}
              </button>
              <button
                class="btn-deliver"
                type="button"
                @click="handleDeliverSelected"
              >
                Giao
              </button>
              <button
                class="btn-go-menu py-2 px-3 bg-[#2980B9] hover:bg-[#1a5276] text-white text-xs font-bold rounded-lg transition-all active:scale-95 shadow font-sans ml-1"
                type="button"
                @click="activeMainTab = 'menu'"
              >
                {{ t("reception.menu") }}
              </button>
            </div>

            <!-- NHẬT KÝ THAO TÁC -->
            <div class="activity-log">
              <div class="log-header">
                <span>{{ t("reception.action_log") }}</span>
                <span class="log-count">{{ activities.length }}</span>
              </div>

              <div class="log-table-wrapper select-none">
                <table class="log-table">
                  <thead>
                    <tr>
                      <th>{{ t("reception.date") }}</th>
                      <th>{{ t("reception.action") }}</th>
                      <th>{{ t("reception.employee") }}</th>
                      <th>{{ t("reception.amount") }}</th>
                      <th>POSID</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="act in activities"
                      :key="act.id"
                      :class="{
                        'log-row-send': act.action.includes('Gửi order'),
                        'log-row-pay': act.action.includes('Thanh toán'),
                      }"
                    >
                      <td class="log-time">{{ act.time }}</td>
                      <td class="log-action">{{ act.action }}</td>
                      <td>{{ act.staff }}</td>
                      <td class="log-money">{{ formatVND(act.amount) }}</td>
                      <td>{{ act.posId }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </template>

          <!-- Bottom Navigation -->
          <div class="bottom-nav">
            <button
              :class="[
                'nav-btn',
                activeMainTab === 'table_map' ? 'active' : '',
              ]"
              @click="activeMainTab = 'table_map'"
              type="button"
            >
              <span class="nav-icon">🗺️</span>
              <span>{{ t("reception.floor_plan") }}</span>
            </button>
            <button
              :class="['nav-btn', activeMainTab === 'menu' ? 'active' : '']"
              @click="activeMainTab = 'menu'"
              type="button"
            >
              <span class="nav-icon">🍽️</span>
              <span>{{ t("reception.menu") }}</span>
            </button>
            <button
              :class="['nav-btn', activeMainTab === 'invoice' ? 'active' : '']"
              @click="activeMainTab = 'invoice'"
              type="button"
            >
              <span class="nav-icon">📄</span>
              <span>{{ t("reception.receipt") }}</span>
            </button>
            <button
              v-if="
                selectedTableCode &&
                activeOrder.items &&
                activeOrder.items.length > 0
              "
              class="send-btn"
              @click="sendToKitchen"
              type="button"
            >
              Gửi đi
            </button>
          </div>
        </aside>

        <!-- 3. MAIN AREA -->
        <main
          class="flex-1 bg-[#3a3a3a] flex flex-col justify-between overflow-hidden relative"
        >
          <!-- TAB A: TABLE MAP (Sơ đồ bàn) -->
          <div
            v-if="activeMainTab === 'table_map'"
            class="flex-1 flex flex-col justify-between overflow-hidden p-5"
          >
            <!-- Table Map scrollable grid -->
            <div
              class="flex-1 overflow-y-auto ordering-screen-scrollbar space-y-6 pr-1"
            >
              <!-- Grid Layout of all tables -->
              <div
                class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-4"
              >
                <div
                  v-for="table in filteredTables"
                  :key="table.code"
                  @click="handleTableClick(table)"
                  @dblclick="handleTableDoubleClick(table, $event)"
                  :class="[
                    'p-3 rounded-xl border-2 transition-all cursor-pointer flex flex-col justify-between min-h-[110px] text-center hover:scale-[1.02] active:scale-[0.98] duration-200 shadow-sm relative',
                    selectedTableCode === table.code
                      ? 'border-orange-500 ring-2 ring-orange-400 bg-orange-50/5'
                      : 'border-transparent',
                    getTableStatusClass(table),
                    // Selection Mode styles
                    selectionMode !== 'none' && table.code === sourceTableCode
                      ? 'ring-4 ring-red-500 border-red-500 animate-pulse'
                      : '',
                    selectionMode !== 'none' && isValidTargetTable(table.code)
                      ? 'ring-4 ring-green-500 border-green-500 cursor-pointer animate-bounce'
                      : '',
                    selectionMode !== 'none' &&
                    !isValidTargetTable(table.code) &&
                    table.code !== sourceTableCode
                      ? 'opacity-30 cursor-not-allowed'
                      : '',
                  ]"
                >
                  <!-- Table badge for Selection Mode -->
                  <div
                    v-if="selectionMode !== 'none'"
                    class="absolute top-2 right-2 z-10"
                  >
                    <span
                      v-if="table.code === sourceTableCode"
                      class="bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full"
                      >{{ t("reception.source") }}</span
                    >
                    <span
                      v-else-if="isValidTargetTable(table.code)"
                      class="bg-green-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full animate-pulse"
                      >{{ t("reception.select") }}</span
                    >
                  </div>
                  <div class="flex justify-between items-center select-none">
                    <span class="font-extrabold text-sm">{{ table.code }}</span>
                    <span
                      v-if="
                        table.status === 'Serving' || table.status === 'Arrived'
                      "
                      class="bg-black/20 px-1.5 py-0.5 rounded text-[9px] font-black"
                    >
                      {{ table.capacity }}
                    </span>
                  </div>

                  <div
                    v-if="
                      table.status === 'Serving' || table.status === 'Arrived'
                    "
                    class="mt-2 text-[10px] space-y-0.5"
                  >
                    <div class="font-extrabold text-gray-200 truncate">
                      {{ table.customerName || "Khách" }}
                    </div>
                    <div class="text-gray-400">
                      {{ table.checkInTime || "17:00" }} —
                      {{ table.occupiedDuration || "0ph" }}
                    </div>
                    <div class="font-black text-[#ff8f00] mt-1">
                      {{ table.billAmount || "[69.660]" }}
                    </div>
                  </div>
                  <div
                    v-else-if="table.status === 'Reserved'"
                    class="mt-2 text-[10px] text-red-300"
                  >
                    <div class="font-black truncate">
                      {{ table.customerName || "Đã đặt" }}
                    </div>
                    <div class="text-xs mt-1">🔒</div>
                  </div>
                  <div v-else class="mt-2 text-[10px] text-gray-500">
                    {{ t("reception.empty") }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Bottom Controls of Sơ đồ bàn -->
            <div
              class="shrink-0 bg-[#2d2d2d] p-3 rounded-xl border border-[#4a4a4a] flex items-center justify-between mt-4"
            >
              <div class="flex items-center gap-3 relative">
                <span class="text-xs text-gray-400 font-bold uppercase">{{
                  t("reception.area")
                }}</span>
                <div class="area-selector-wrapper mr-2" ref="areaDropdownRef">
                  <button
                    class="area-btn text-xs font-bold"
                    @click="showAreaSelector = !showAreaSelector"
                    type="button"
                  >
                    <span>{{ selectedArea }}</span>
                    <span class="arrow ml-1">{{
                      showAreaSelector ? "▲" : "▼"
                    }}</span>
                  </button>

                  <Transition name="slide-up">
                    <div v-if="showAreaSelector" class="area-overlay">
                      <div class="area-grid">
                        <button
                          v-for="area in tableAreas"
                          :key="area.id"
                          class="area-card"
                          :class="{ active: selectedArea === area.name }"
                          @click="selectAreaName(area.name)"
                          type="button"
                        >
                          <span class="area-name">{{ area.name }}</span>
                          <span v-if="area.total" class="area-total">{{
                            formatVND(area.total)
                          }}</span>
                          <div
                            v-if="area.stats"
                            class="area-stats text-[9px] opacity-80 mt-1"
                          >
                            <span>{{ area.stats.bills }}x </span>
                            <span>{{ area.stats.guests }}x</span>
                          </div>
                        </button>
                      </div>
                    </div>
                  </Transition>
                </div>

                <!-- Dropdown Lọc bàn -->
                <span class="text-xs text-gray-400 font-bold uppercase ml-2">{{
                  t("reception.filter")
                }}</span>
                <div class="filter-dropdown" ref="dropdownRef">
                  <button
                    class="filter-btn text-xs font-bold"
                    @click="toggleDropdown"
                    type="button"
                    :style="{
                      backgroundColor: currentFilter.color,
                      color: currentFilter.textColor,
                    }"
                  >
                    <span>{{ currentFilter.label }}</span>
                    <span class="arrow ml-1">{{ isOpen ? "▲" : "▼" }}</span>
                  </button>

                  <Transition name="fade">
                    <div v-if="isOpen" class="dropdown-menu">
                      <button
                        v-for="filter in filters"
                        :key="filter.value"
                        class="filter-item text-xs font-bold"
                        :class="{ active: selectedFilter === filter.value }"
                        :style="{
                          backgroundColor: filter.color,
                          color: filter.textColor,
                        }"
                        @click="applyFilter(filter)"
                        type="button"
                      >
                        {{ filter.label }}
                      </button>
                    </div>
                  </Transition>
                </div>
              </div>

              <div class="flex items-center gap-2">
                <button
                  @click="selectedArea = 'Tất cả'"
                  class="px-3.5 py-1.5 bg-[#ff8f00] hover:bg-[#e07f00] text-white text-xs font-bold rounded-lg transition-all shadow font-sans"
                  type="button"
                >
                  {{ t("reception.all") }}
                </button>
                <button
                  class="p-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] rounded-lg transition-colors text-xs"
                  :title="t('reception.grid')"
                  type="button"
                >
                  📊
                </button>
                <button
                  class="close-btn"
                  type="button"
                  @click="closePanel"
                  :title="t('reception.close_panel')"
                >
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2.5"
                  >
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <!-- TAB B: MENU (Thực đơn) -->
          <div
            v-if="activeMainTab === 'menu'"
            class="flex-1 flex flex-col justify-between overflow-hidden"
          >
            <!-- Products scrollable grid container -->
            <div class="flex-1 overflow-y-auto p-5 ordering-screen-scrollbar">
              <!-- Quick filters & Preferences bar -->
              <div
                class="flex flex-wrap items-center justify-between gap-3 mb-5 select-none shrink-0 bg-[#2d2d2d] p-3 rounded-xl border border-[#4a4a4a]"
              >
                <div class="flex flex-wrap items-center gap-3">
                  <div class="flex gap-1.5">
                    <button
                      v-for="f in [
                        { id: 'favorites', label: '⭐ Yêu thích' },
                        { id: 'popular', label: '🔥 Bán chạy' },
                        { id: 'recent', label: '🕒 Gần đây' },
                      ]"
                      :key="f.id"
                      @click="
                        toggleQuickFilter(
                          activeQuickFilter === f.id ? '' : (f.id as any),
                        )
                      "
                      :class="[
                        'px-3 py-1.5 rounded-full text-xs font-bold transition-all border shrink-0 active:scale-95',
                        activeQuickFilter === f.id
                          ? 'bg-[#ff8f00] border-[#ff8f00] text-white shadow'
                          : 'bg-[#3a3a3a] border-[#4a4a4a] text-gray-400 hover:bg-[#4a4a4a] hover:text-white',
                      ]"
                    >
                      {{ f.label }}
                    </button>
                  </div>

                  <div
                    class="flex items-center gap-2 border-l border-[#4a4a4a] pl-3"
                  >
                    <select
                      v-model="activeStatusFilter"
                      class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer font-bold"
                    >
                      <option value="all">
                        {{ t("reception.all_items") }}
                      </option>
                      <option value="available">
                        {{ t("reception.available") }}
                      </option>
                      <option value="unavailable">
                        {{ t("reception.out_of_stock") }}
                      </option>
                    </select>

                    <select
                      v-model="priceSort"
                      class="bg-[#3a3a3a] text-xs text-gray-200 border border-[#4a4a4a] rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-[#ff8f00] cursor-pointer font-bold"
                    >
                      <option value="">{{ t("reception.no_sort") }}</option>
                      <option value="asc">
                        {{ t("reception.price_asc") }}
                      </option>
                      <option value="desc">
                        {{ t("reception.price_desc") }}
                      </option>
                    </select>
                  </div>
                </div>

                <!-- Search Input in menu grid -->
                <div
                  class="relative flex items-center bg-[#3a3a3a] border border-[#4a4a4a] rounded-lg px-3 py-1.5 focus-within:border-[#ff8f00] transition-colors w-48"
                >
                  <input
                    v-model="searchQuery"
                    type="text"
                    :placeholder="t('reception.search_item')"
                    class="bg-transparent border-none text-xs text-white placeholder-gray-500 focus:outline-none w-full"
                  />
                </div>
              </div>

              <!-- Product Grid -->
              <div
                v-if="finalFilteredItems.length === 0"
                class="h-64 flex flex-col items-center justify-center text-gray-500 text-center border border-dashed border-[#4a4a4a] rounded-2xl p-6 select-none"
              >
                <div class="text-4xl mb-2">🍽️</div>
                <h4 class="font-bold text-gray-400 text-xs">
                  {{ t("reception.no_matching_food") }}
                </h4>
              </div>

              <div v-else class="menu-grid">
                <div
                  v-for="product in finalFilteredItems"
                  :key="product.id"
                  @click="handleCardClick(product)"
                  :class="[
                    'menu-card border cursor-pointer transition-all duration-350 relative overflow-hidden group select-none',
                    getCartItemQty(product.id) > 0
                      ? 'in-cart border-[#ff8f00]'
                      : 'border-[#404040]',
                    !getEnrichedItem(product).isAvailable
                      ? 'opacity-40 cursor-not-allowed'
                      : '',
                  ]"
                >
                  <div v-if="getCartItemQty(product.id) > 0" class="qty-badge">
                    {{ getCartItemQty(product.id) }}
                  </div>

                  <span
                    v-if="favoriteIds.includes(product.id)"
                    class="favorite-star text-xs absolute top-1 right-1"
                    >⭐</span
                  >

                  <h3
                    class="item-name"
                    :style="{
                      color:
                        getCartItemQty(product.id) > 0 ? '#ff8f00' : '#ffffff',
                    }"
                  >
                    {{ getJpAndViNames(product.name).vi }}
                  </h3>

                  <div class="item-price">
                    {{ formatPrice(product.price) }}
                  </div>

                  <div class="card-footer">
                    <span class="unit-label">ĐVT: {{ product.unit }}</span>
                    <button class="item-add-btn" type="button">+</button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Categories Selection Bottom Navigation -->
            <div
              class="bg-[#2d2d2d] border-t border-[#1e1e1e] flex flex-col shrink-0 select-none"
            >
              <!-- Sub Categories -->
              <div
                class="p-2.5 border-b border-[#1e1e1e] category-container-sub flex gap-1.5 overflow-x-auto whitespace-nowrap"
              >
                <button
                  @click="selectSubCategory('all')"
                  :style="{
                    backgroundColor:
                      activeSubCategoryId === 'all' ? '#ff8f00' : '#f5a623',
                    border: '2px solid transparent',
                  }"
                  class="category-btn-sub px-3 py-1.5 rounded-lg text-[11px] font-extrabold text-white transition-all shadow-sm font-sans"
                >
                  {{ t("reception.all") }}
                </button>
                <button
                  v-for="sub in activeSubcategoriesList"
                  :key="sub.id"
                  @click="selectSubCategory(sub.id)"
                  :style="{
                    backgroundColor:
                      activeSubCategoryId === sub.id ? '#ff8f00' : '#f5a623',
                    border: '2px solid transparent',
                  }"
                  class="category-btn-sub px-3 py-1.5 rounded-lg text-[11px] font-extrabold text-white transition-all shadow-sm font-sans"
                >
                  {{ sub.name }}
                </button>
              </div>

              <!-- Main Categories -->
              <div
                class="p-3 category-container-main flex gap-2 overflow-x-auto whitespace-nowrap"
              >
                <button
                  v-for="cat in menuHierarchy"
                  :key="cat.id"
                  @click="selectCategory(cat.id)"
                  :style="{
                    backgroundColor:
                      activeCategoryId === cat.id ? '#c62828' : '#b56576',
                  }"
                  class="category-btn-main px-4 py-2.5 rounded-xl text-xs font-bold text-white transition-all flex items-center gap-1.5 uppercase shadow-sm shrink-0 font-sans"
                >
                  <span>
                    <span v-if="cat.id === 'buffet'">🏆</span>
                    <span v-else-if="cat.id === 'set_lunch'">🍱</span>
                    <span v-else-if="cat.id === 'set_tiec_chieu_dai'">🎉</span>
                    <span v-else-if="cat.id === 'set_tiec_chieu_dai_jp'"
                      >🗾</span
                    >
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

          <!-- TAB C: INVOICE / BILL (Phiếu) - ĐẦY ĐỦ -->
          <div
            v-if="activeMainTab === 'invoice'"
            class="flex-1 flex flex-col overflow-hidden bg-[#3a3a3a]"
          >
            <div class="flex-1 flex gap-3 p-3 overflow-hidden">
              <!-- CỘT 1: ORDER TABLE (30%) -->
              <div
                class="w-[30%] bg-white rounded-lg overflow-hidden flex flex-col shadow-lg border border-[#333]/10"
              >
                <div
                  class="bg-[#1a5276] text-white px-3 py-2 text-xs font-bold flex justify-between shrink-0"
                >
                  <span>{{ t("reception.receipt") }}</span>
                  <span>{{ t("reception.details") }}</span>
                </div>
                <div class="flex-1 overflow-y-auto">
                  <table class="w-full text-xs border-collapse text-gray-800">
                    <thead class="bg-black text-white sticky top-0 z-10">
                      <tr>
                        <th class="p-2 text-left font-bold">
                          {{ t("reception.item_name") }}
                        </th>
                        <th class="p-2 text-right font-bold">
                          {{ t("reception.unit_price") }}
                        </th>
                        <th class="p-2 text-center font-bold">% VAT</th>
                        <th class="p-2 text-right font-bold">
                          {{ t("reception.discount_short") }}
                        </th>
                        <th class="p-2 text-right font-bold">
                          {{ t("reception.total_short") }}
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        class="bg-gray-100 font-bold text-gray-800 border-b border-gray-250"
                      >
                        <td colspan="5" class="p-2">SET LUNCH (Vé)</td>
                      </tr>
                      <tr class="border-b border-gray-200 bg-white">
                        <td colspan="5" class="p-2 text-gray-800 font-semibold">
                          1
                        </td>
                      </tr>
                      <tr
                        v-for="item in activeOrder.items"
                        :key="item.id"
                        class="border-b border-gray-200 bg-white hover:bg-gray-50 transition-colors"
                      >
                        <td class="p-2 font-semibold text-gray-800">
                          {{ item.name }}
                          <div class="text-[10px] text-gray-500">
                            ({{ item.unit }})
                          </div>
                        </td>
                        <td class="p-2 text-right font-mono text-gray-700">
                          {{ formatVND(item.price) }}
                        </td>
                        <td class="p-2 text-center text-gray-600">8</td>
                        <td class="p-2 text-right text-red-600 font-mono">
                          {{
                            item.name.toLowerCase().includes("lunch")
                              ? formatVND(item.price * 0.5 * item.quantity)
                              : "0đ"
                          }}
                        </td>
                        <td
                          class="p-2 text-right font-bold font-mono text-gray-800"
                        >
                          {{ formatVND(calculateNetPrice(item)) }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- CỘT 2: PAYMENT DETAILS (45%) -->
              <div
                class="w-[45%] bg-[#2d2d2d] rounded-lg p-3 flex flex-col justify-between shadow-lg border border-[#333]/15 payment-details-container"
              >
                <div>
                  <!-- Payment Grid -->
                  <div class="grid grid-cols-2 gap-2 mb-3">
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.goods_money")
                      }}</label>
                      <div
                        class="bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono font-bold text-right text-xs"
                      >
                        {{ formatVND(summary.subtotal) }}
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.service_fee")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(serviceCharge)"
                          @input="
                            (e) =>
                              (serviceCharge =
                                parseInt(
                                  (e.target as HTMLInputElement).value.replace(
                                    /[^0-9]/g,
                                    '',
                                  ),
                                ) || 0)
                          "
                          class="flex-1 bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs focus:outline-none"
                        />
                        <button
                          @click="serviceCharge += 10000"
                          type="button"
                          class="bg-[#4CAF50] text-white px-2 rounded text-xs hover:brightness-110 active:scale-95 transition-all"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.item_discount")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(summary.discount)"
                          disabled
                          class="flex-1 bg-[#3d2d2d] border border-red-500 px-2 py-1.5 rounded text-red-500 font-mono text-right text-xs"
                        />
                        <button
                          @click="
                            triggerToast(
                              'info',
                              'Không thể xóa giảm giá chi tiết món ở đây. Vui lòng sửa ở tab Chi tiết.',
                            )
                          "
                          type="button"
                          class="bg-[#F44336] text-white px-2 rounded text-xs flex items-center justify-center"
                        >
                          ✕
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.receipt_discount")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(discountBill)"
                          @input="
                            (e) =>
                              (discountBill =
                                parseInt(
                                  (e.target as HTMLInputElement).value.replace(
                                    /[^0-9]/g,
                                    '',
                                  ),
                                ) || 0)
                          "
                          class="flex-1 bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs focus:outline-none"
                        />
                        <button
                          @click="discountBill += 10000"
                          type="button"
                          class="bg-[#4CAF50] text-white px-2 rounded text-xs hover:brightness-110 active:scale-95 transition-all"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1"
                        >TTDB</label
                      >
                      <div
                        class="bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs"
                      >
                        {{ formatVND(ttdb) }}
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.total_tax")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(summary.vat)"
                          disabled
                          class="flex-1 bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs"
                        />
                        <button
                          @click="
                            triggerToast('info', 'Không thể xóa VAT trực tiếp')
                          "
                          type="button"
                          class="bg-[#F44336] text-white px-2 rounded text-xs flex items-center justify-center"
                        >
                          ✕
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.deposit")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(depositAmount)"
                          @input="
                            (e) =>
                              (depositAmount =
                                parseInt(
                                  (e.target as HTMLInputElement).value.replace(
                                    /[^0-9]/g,
                                    '',
                                  ),
                                ) || 0)
                          "
                          class="flex-1 bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs focus:outline-none"
                        />
                        <button
                          @click="depositAmount += 50000"
                          type="button"
                          class="bg-[#4CAF50] text-white px-2 rounded text-xs hover:brightness-110 active:scale-95 transition-all"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="text-[10px] text-gray-400 block mb-1">{{
                        t("reception.delivery")
                      }}</label>
                      <div class="flex gap-1">
                        <input
                          type="text"
                          :value="formatVND(deliveryFee)"
                          @input="
                            (e) =>
                              (deliveryFee =
                                parseInt(
                                  (e.target as HTMLInputElement).value.replace(
                                    /[^0-9]/g,
                                    '',
                                  ),
                                ) || 0)
                          "
                          class="flex-1 bg-[#1a1a1a] px-2 py-1.5 rounded text-white font-mono text-right text-xs focus:outline-none"
                        />
                        <button
                          @click="deliveryFee = 0"
                          type="button"
                          class="bg-[#F44336] text-white px-2 rounded text-xs flex items-center justify-center"
                        >
                          ✕
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- Total Row -->
                  <div
                    class="bg-[#1a5276] rounded-lg p-2 flex justify-between items-center mb-3 shadow-inner"
                  >
                    <span
                      class="text-white font-bold text-xs uppercase tracking-wider"
                      >{{ t("reception.amount_to_pay") }}</span
                    >
                    <span
                      class="text-white font-bold font-mono text-sm shadow-inner"
                      >{{ formatVND(summary.grandTotal) }}</span
                    >
                  </div>

                  <!-- Customer Payment -->
                  <div
                    class="space-y-1 mb-3 p-2 bg-[#1e1e1e]/40 rounded-lg border border-[#444]/20"
                  >
                    <div class="flex justify-between items-center text-xs">
                      <span class="text-gray-400 font-bold">{{
                        t("reception.customer_gave")
                      }}</span>
                      <span class="text-white font-mono font-bold">{{
                        formatVND(customerPaid)
                      }}</span>
                    </div>
                    <div class="flex justify-between items-center text-xs">
                      <span class="text-gray-400 font-bold">{{
                        t("reception.change")
                      }}</span>
                      <span class="text-[#4CAF50] font-mono font-bold">{{
                        formatVND(changePaid)
                      }}</span>
                    </div>
                  </div>
                </div>

                <!-- Dynamic Content based on selectedPaymentMethod -->
                <div class="border-t border-[#444] pt-3 mt-auto">
                  <!-- VIP Card Section -->
                  <div v-if="selectedPaymentMethod === 'vip'" class="space-y-2">
                    <div
                      class="flex gap-2 text-xs justify-center bg-[#1e1e1e]/40 py-1.5 rounded border border-[#444]/20"
                    >
                      <label
                        class="flex items-center gap-1 text-white cursor-pointer select-none font-bold"
                      >
                        <input
                          type="radio"
                          v-model="vipMode"
                          value="points_discount"
                          class="accent-[#FF9800]"
                        />{{ t("reception.earn_points_discount") }}</label
                      >
                      <label
                        class="flex items-center gap-1 text-white cursor-pointer select-none font-bold"
                      >
                        <input
                          type="radio"
                          v-model="vipMode"
                          value="discount"
                          class="accent-[#FF9800]"
                        />{{ t("reception.discount_short") }}</label
                      >
                      <label
                        class="flex items-center gap-1 text-white cursor-pointer select-none font-bold"
                      >
                        <input
                          type="radio"
                          v-model="vipMode"
                          value="points"
                          class="accent-[#FF9800]"
                        />{{ t("reception.earn_points") }}</label
                      >
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-450 font-bold w-20">{{
                        t("reception.vip_card")
                      }}</label>
                      <input
                        v-model="vipCardNumber"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF9800]"
                        :placeholder="t('reception.enter_card_number')"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>
                    <div class="flex gap-2 justify-end">
                      <button
                        @click="checkVIP"
                        type="button"
                        class="bg-[#FF9800] hover:bg-[#e07f00] text-white px-3 py-1.5 rounded text-xs font-bold transition-all shadow active:scale-95"
                      >
                        {{ t("reception.check_vip") }}
                      </button>
                      <button
                        @click="applyVIP"
                        type="button"
                        class="bg-[#4CAF50] hover:bg-[#43a047] text-white px-3 py-1.5 rounded text-xs font-bold transition-all shadow active:scale-95"
                      >
                        {{ t("reception.apply_vip") }}
                      </button>
                      <button
                        @click="clearVIP"
                        type="button"
                        class="bg-[#F44336] hover:bg-[#e53935] text-white px-3 py-1.5 rounded text-xs font-bold transition-all shadow active:scale-95"
                      >
                        {{ t("reception.remove_vip") }}
                      </button>
                    </div>
                  </div>

                  <!-- Transfer/Card Section -->
                  <div
                    v-else-if="selectedPaymentMethod === 'transfer'"
                    class="space-y-2"
                  >
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.card_type")
                      }}</label>
                      <select
                        v-model="cardType"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      >
                        <option value="ATM">ATM</option>
                        <option value="VISA">VISA</option>
                        <option value="MASTERCARD">MASTERCARD</option>
                      </select>
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.card_number")
                      }}</label>
                      <input
                        v-model="cardNumber"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.cardholder_name")
                      }}</label>
                      <input
                        v-model="cardHolder"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>
                  </div>

                  <!-- Voucher Section -->
                  <div
                    v-else-if="selectedPaymentMethod === 'voucher'"
                    class="space-y-2"
                  >
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.card_code")
                      }}</label>
                      <input
                        v-model="voucherCode"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                      <button
                        @click="checkVoucher"
                        type="button"
                        class="text-white bg-[#1a5276] hover:bg-[#2980B9] px-2.5 py-1 rounded text-xs"
                      >
                        🔍
                      </button>
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.voucher_type")
                      }}</label>
                      <input
                        v-model="voucherType"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.quantity")
                      }}</label>
                      <div
                        class="flex items-center gap-1 bg-white rounded px-2"
                      >
                        <button
                          @click="voucherQty = Math.max(1, voucherQty - 1)"
                          type="button"
                          class="text-gray-600 px-2 font-bold"
                        >
                          -
                        </button>
                        <span class="text-xs font-bold text-gray-800">{{
                          voucherQty
                        }}</span>
                        <button
                          @click="voucherQty++"
                          type="button"
                          class="text-gray-600 px-2 font-bold"
                        >
                          +
                        </button>
                      </div>
                    </div>
                    <p
                      v-if="voucherError"
                      class="text-[#FF9800] text-xs text-center font-bold"
                    >
                      {{ voucherError }}
                    </p>
                  </div>

                  <!-- Coupon Section -->
                  <div
                    v-else-if="selectedPaymentMethod === 'coupon'"
                    class="space-y-2"
                  >
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.card_code")
                      }}</label>
                      <input
                        v-model="couponCode"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                      <button
                        type="button"
                        class="text-white bg-[#1a5276] hover:bg-[#2980B9] px-2.5 py-1 rounded text-xs"
                      >
                        🔍
                      </button>
                    </div>
                    <p
                      v-if="couponError"
                      class="text-[#FF9800] text-xs text-center font-bold"
                    >
                      {{ couponError }}
                    </p>
                  </div>

                  <!-- Deposit Section -->
                  <div
                    v-else-if="selectedPaymentMethod === 'deposit'"
                    class="space-y-2"
                  >
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.deposit_date")
                      }}</label>
                      <input
                        v-model="depositDate"
                        type="date"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                      />
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-xs text-gray-455 font-bold w-24">{{
                        t("reception.receipt_number")
                      }}</label>
                      <input
                        v-model="depositVoucher"
                        type="text"
                        class="flex-1 bg-white px-2 py-1 rounded text-xs text-gray-800 focus:outline-none"
                        :placeholder="t('reception.enter_receipt_number')"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-2 rounded text-xs py-1 hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>
                    <p
                      v-if="depositError"
                      class="text-[#FF9800] text-xs text-center font-bold"
                    >
                      {{ depositError }}
                    </p>
                  </div>

                  <!-- Discount Section - Compact -->
                  <div
                    v-else-if="selectedPaymentMethod === 'discount'"
                    class="space-y-2 discount-form-compact"
                  >
                    <!-- Radio buttons -->
                    <div class="flex gap-3 justify-end mb-1">
                      <label
                        class="flex items-center gap-1.5 text-white text-xs cursor-pointer select-none font-bold"
                      >
                        <input
                          type="radio"
                          v-model="discountType"
                          value="percent"
                          class="accent-[#FF9800] w-3.5 h-3.5"
                        />
                        %
                      </label>
                      <label
                        class="flex items-center gap-1.5 text-white text-xs cursor-pointer select-none font-bold"
                      >
                        <input
                          type="radio"
                          v-model="discountType"
                          value="value"
                          class="accent-[#FF9800] w-3.5 h-3.5"
                        />{{ t("reception.value") }}</label
                      >
                    </div>

                    <!-- Giá trị -->
                    <div class="form-row">
                      <label class="form-label">{{
                        t("reception.value")
                      }}</label>
                      <input
                        v-model="discountValue"
                        type="text"
                        class="form-input font-mono font-bold text-right"
                        placeholder="0"
                      />
                    </div>

                    <!-- Lý do -->
                    <div class="form-row">
                      <label class="form-label">{{
                        t("reception.reason")
                      }}</label>
                      <select v-model="discountReason" class="form-select">
                        <option value="">
                          {{ t("reception.select_reason") }}
                        </option>
                        <option value="khach_than_thiet">
                          {{ t("reception.loyal_customer") }}
                        </option>
                        <option value="sinh_nhat">
                          {{ t("reception.birthday") }}
                        </option>
                        <option value="khuyen_mai">
                          {{ t("reception.promotion") }}
                        </option>
                        <option value="vip">
                          {{ t("reception.vip_customer") }}
                        </option>
                        <option value="other">
                          {{ t("reception.other") }}
                        </option>
                      </select>
                    </div>

                    <!-- Quản lý -->
                    <div class="form-row">
                      <label class="form-label">{{
                        t("reception.manage")
                      }}</label>
                      <input
                        v-model="discountManager"
                        type="text"
                        class="form-input"
                        :placeholder="t('reception.manager_name')"
                      />
                      <button
                        type="button"
                        class="bg-[#444] text-white px-3 py-2 rounded text-xs hover:bg-[#555] transition-colors"
                      >
                        ...
                      </button>
                    </div>

                    <!-- Action Buttons -->
                    <div class="flex gap-2 justify-end pt-1">
                      <button
                        @click="applyDiscount"
                        type="button"
                        class="btn-apply"
                      >
                        {{ t("reception.apply") }}
                      </button>
                      <button
                        type="button"
                        class="bg-[#F44336] hover:bg-[#E53935] text-white px-4 py-2 rounded text-xs font-bold transition-all shadow active:scale-95"
                      >
                        {{ t("reception.policy_discount") }}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- CỘT 3: PRINT COUNT + KEYPAD (25%) -->
              <div class="w-[25%] flex flex-col gap-2">
                <!-- Print Count -->
                <div
                  class="bg-[#2d2d2d] rounded-lg p-2 shadow-lg border border-[#333]/15 flex flex-col"
                >
                  <div
                    class="text-[10px] text-gray-400 mb-1 flex justify-between"
                  >
                    <span
                      >{{ t("reception.print_count_label")
                      }}<span class="text-[#FF9800] font-bold">3</span></span
                    >
                    <span>{{ t("reception.denomination_vnd") }}</span>
                  </div>
                  <div class="flex gap-1 mb-2">
                    <button
                      v-for="curr in ['VND', 'EUR', 'TKHACH', 'USD']"
                      :key="curr"
                      :class="[
                        'flex-1 py-1.5 rounded text-[10px] font-bold transition-all duration-150',
                        selectedCurrency === curr
                          ? 'bg-[#FF9800] text-white shadow-md'
                          : 'bg-[#444] text-gray-300 hover:bg-[#555]',
                      ]"
                      @click="selectedCurrency = curr"
                      type="button"
                    >
                      {{ curr }}
                    </button>
                  </div>
                  <label class="text-[10px] text-gray-400 block mb-1">{{
                    t("reception.value")
                  }}</label>
                  <input
                    v-model="keypadValue"
                    type="text"
                    class="w-full bg-white px-2 py-1.5 rounded text-xs font-mono font-bold text-right text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF9800]"
                  />
                </div>

                <!-- Keypad -->
                <div
                  class="bg-[#2d2d2d] rounded-lg p-2 flex-1 flex flex-col shadow-lg border border-[#333]/15"
                >
                  <button
                    @click="handleAcceptPayment"
                    type="button"
                    class="w-full bg-[#FF9800] hover:bg-[#e07f00] active:scale-95 transition-all text-white py-1.5 rounded text-xs font-bold mb-2 shadow"
                  >
                    {{ t("reception.accept") }}
                  </button>
                  <div class="grid grid-cols-4 gap-1 flex-1">
                    <button
                      v-for="key in keypadKeys"
                      :key="key"
                      :class="[
                        'py-2 rounded text-xs font-bold transition-all active:scale-95 duration-100 hover:brightness-110 shadow-sm',
                        getKeyClass(key),
                        key === '500.000' ? 'col-span-4' : '',
                      ]"
                      @click="handleKeypad(key)"
                      type="button"
                    >
                      {{ key }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- PAYMENT METHODS BAR -->
            <div class="payment-methods-bar shrink-0">
              <button
                v-for="method in paymentMethods"
                :key="method.id"
                class="payment-btn"
                :class="[
                  `payment-${method.id}`,
                  { active: selectedPaymentMethod === method.id },
                ]"
                @click="selectedPaymentMethod = method.id"
                type="button"
              >
                <span class="payment-icon">{{ method.icon }}</span>
                <span class="payment-label">{{ method.label }}</span>
              </button>
            </div>

            <!-- BOTTOM ACTION BUTTONS -->
            <div
              class="bg-[#1a5276] border-t border-[#0e2f44] px-3 py-2 flex justify-between items-center shrink-0"
            >
              <div class="flex gap-2">
                <button
                  @click="activeMainTab = 'table_map'"
                  type="button"
                  class="flex items-center gap-1.5 px-3 py-1.5 bg-transparent text-[#BDC3C7] hover:text-white transition-colors text-xs font-bold"
                >
                  <span>🗺️</span><span>{{ t("reception.floor_plan") }}</span>
                </button>
                <button
                  @click="activeMainTab = 'menu'"
                  type="button"
                  class="flex items-center gap-1.5 px-3 py-1.5 bg-transparent text-[#BDC3C7] hover:text-white transition-colors text-xs font-bold"
                >
                  <span>🍽️</span><span>{{ t("reception.menu") }}</span>
                </button>
                <button
                  @click="activeMainTab = 'invoice'"
                  type="button"
                  class="flex items-center gap-1.5 px-3 py-1.5 bg-[#2980B9] text-white text-xs rounded font-bold shadow"
                >
                  <span>📄</span><span>{{ t("reception.receipt") }}</span>
                </button>
              </div>
              <div class="flex gap-2">
                <button
                  @click="showHistory"
                  type="button"
                  class="px-3 py-1.5 bg-[#FFC107] hover:bg-[#ffb300] active:scale-95 transition-all text-gray-800 text-xs font-bold rounded shadow"
                >
                  {{ t("reception.history") }}
                </button>
                <button
                  @click="handleDelivery"
                  type="button"
                  class="px-3 py-1.5 bg-[#FF9800] hover:bg-[#f57c00] active:scale-95 transition-all text-white text-xs font-bold rounded shadow"
                >
                  {{ t("reception.delivery_icon") }}
                </button>
                <button
                  @click="printKitchenCheck"
                  type="button"
                  class="px-3 py-1.5 bg-[#9C27B0] hover:bg-[#8e24aa] active:scale-95 transition-all text-white text-xs font-bold rounded shadow"
                >
                  {{ t("reception.print_check") }}
                </button>
                <button
                  @click="printDraftBill"
                  type="button"
                  class="px-3 py-1.5 bg-[#00BCD4] hover:bg-[#00acc1] active:scale-95 transition-all text-white text-xs font-bold rounded shadow"
                >
                  {{ t("reception.print_provisional") }}
                </button>
                <button
                  @click="finishOrder(false)"
                  type="button"
                  class="px-3 py-1.5 bg-[#F44336] hover:bg-[#d32f2f] active:scale-95 transition-all text-white text-xs font-bold rounded shadow"
                >
                  {{ t("reception.end") }}
                </button>
                <button
                  @click="finishOrder(true)"
                  type="button"
                  class="px-3 py-2 bg-[#d32f2f] hover:bg-[#c62828] active:scale-95 transition-all text-white text-xs font-bold rounded shadow"
                >
                  {{ t("reception.print_and_end") }}
                </button>
              </div>
            </div>
          </div>

          <!-- TAB D: PENDING (Chưa xử lý) -->
          <div
            v-if="activeMainTab === 'pending'"
            class="flex-1 flex flex-col justify-between overflow-hidden p-6 text-white bg-[#2d2d2d]"
          >
            <div class="max-w-3xl mx-auto w-full space-y-6">
              <div
                class="flex justify-between items-center border-b border-[#3a3a3a] pb-4"
              >
                <h3
                  class="text-lg font-black uppercase text-[#ff8f00] tracking-wider"
                >
                  {{ t("reception.unprocessed_orders_list") }}
                </h3>
                <span
                  class="bg-[#F44336] text-white text-xs font-bold px-3 py-1 rounded-full"
                  >{{ pendingCount }} Đơn chờ</span
                >
              </div>

              <!-- List of pending orders -->
              <div
                class="space-y-3 max-h-[600px] overflow-y-auto ordering-screen-scrollbar pr-2"
              >
                <div
                  v-for="order in pendingOrders"
                  :key="order.id"
                  class="p-4 bg-[#1a1a1a] rounded-xl border border-[#444] hover:border-[#ff8f00] transition-all flex justify-between items-center"
                >
                  <div class="space-y-1">
                    <div class="flex items-center gap-2">
                      <span class="font-extrabold text-[#ff8f00] text-sm"
                        >Bàn {{ order.tableCode }}</span
                      >
                      <span
                        class="bg-[#3a3a3a] text-gray-300 text-[10px] px-2 py-0.5 rounded font-mono"
                        >{{ order.id }}</span
                      >
                    </div>
                    <div class="text-xs text-gray-400">
                      {{ t("reception.customer_label")
                      }}<strong class="text-white">{{
                        order.customerName
                      }}</strong>
                      — {{ order.time }}
                    </div>
                    <div class="text-xs text-gray-500">
                      Món: {{ order.itemsSummary }}
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    <span class="font-mono text-sm font-bold text-gray-200">{{
                      formatVND(order.totalAmount)
                    }}</span>
                    <button
                      @click="handleProcessPending(order)"
                      class="px-3.5 py-1.5 bg-[#ff8f00] hover:bg-[#d0621f] text-white text-xs font-bold rounded-lg transition-all"
                      type="button"
                    >
                      Xử lý
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>

      <!-- VUNG 3: CENTERED POPUP DETAIL MODAL (SIMPLE / COMPLEX ROUTER) -->
      <transition name="fade">
        <div
          v-if="isDetailPanelOpen && selectedProductForDetail"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-950/60 backdrop-blur-xs select-none"
        >
          <!-- Dark overlay background clicks to close -->
          <div class="fixed inset-0" @click="isDetailPanelOpen = false"></div>

          <!-- Centered Container (Width 700-800px) -->
          <div
            class="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col relative z-10 animate-scale-up border border-[#e0e0e0] text-gray-800"
          >
            <!-- Header Modal with Clean Colors -->
            <header
              class="bg-gradient-to-r from-[#1976d2] to-[#1565c0] text-white px-6 py-4 flex justify-between items-center shrink-0"
            >
              <h3 class="text-base font-bold tracking-tight select-none">
                {{ t("reception_order.chi_tiet_mon_an") }}
              </h3>
              <button
                @click="isDetailPanelOpen = false"
                class="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center font-bold text-sm transition-all select-none active:scale-90"
              >
                ✕
              </button>
            </header>

            <!-- Body Area (Padding 24px) -->
            <div
              class="p-6 overflow-y-auto flex-1 min-h-0 text-left text-gray-700"
            >
              <!-- ─── CASE A: SIMPLE ITEM DETAIL MODAL ─── -->
              <div
                v-if="tempOptionGroups.length === 0"
                class="grid grid-cols-1 md:grid-cols-10 gap-6"
              >
                <!-- Column Left (40% width -> 4 cols) -->
                <div class="md:col-span-4 flex flex-col items-center gap-4">
                  <div
                    class="w-full h-52 bg-gray-100 border border-[#e0e0e0] rounded-xl flex items-center justify-center text-6xl relative overflow-hidden select-none"
                  >
                    {{ getEnrichedItem(selectedProductForDetail).emoji }}

                    <span
                      v-if="
                        !getEnrichedItem(selectedProductForDetail).isAvailable
                      "
                      class="absolute inset-0 bg-red-950/20 backdrop-blur-xs flex items-center justify-center font-black text-white text-xs uppercase"
                      >{{ t("reception_order.het_hang") }}</span
                    >
                  </div>

                  <span
                    :class="[
                      'w-full py-1 text-center font-bold text-[10px] uppercase rounded-lg tracking-wider border',
                      getEnrichedItem(selectedProductForDetail).isAvailable
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-150'
                        : 'bg-red-50 text-red-700 border-red-150',
                    ]"
                  >
                    ●
                    {{
                      getEnrichedItem(selectedProductForDetail).isAvailable
                        ? t("reception_order.con_hang_phuc_vu_text")
                        : t("reception_order.het_hang_text")
                    }}
                  </span>
                </div>

                <!-- Column Right (60% width -> 6 cols) -->
                <div
                  class="md:col-span-6 space-y-4 font-bold text-xs text-gray-700"
                >
                  <div class="space-y-1">
                    <label
                      class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                      >{{ t("reception_order.ten_mon") }}</label
                    >
                    <input
                      type="text"
                      :value="selectedProductForDetail.name"
                      readonly
                      class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                    />
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.ma_mon") }}</label
                      >
                      <input
                        type="text"
                        :value="selectedProductForDetail.id"
                        readonly
                        class="w-full bg-gray-150 border border-gray-200 rounded-lg px-3 py-2 font-mono text-gray-800 focus:outline-none"
                      />
                    </div>
                    <div class="space-y-1">
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.don_vi_tinh") }}</label
                      >
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
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.so_luong") }}</label
                      >
                      <div class="flex items-center gap-2">
                        <button
                          @click="modalItemQty = Math.max(1, modalItemQty - 1)"
                          :disabled="modalItemQty <= 1"
                          class="w-9 h-9 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700 disabled:opacity-40"
                        >
                          -
                        </button>
                        <span
                          class="w-8 text-center font-bold text-base text-gray-900"
                          >{{ modalItemQty }}</span
                        >
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
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.don_gia_vnd") }}</label
                      >
                      <input
                        type="text"
                        :value="
                          isItemInPackage(
                            selectedProductForDetail,
                            activeSettings.package,
                          )
                            ? t('reception_order.0d_trong_goi')
                            : formatVND(selectedProductForDetail.price)
                        "
                        readonly
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT and Service charges (VAT default checked, Service unchecked) -->
                  <div
                    class="flex items-center gap-6 py-1 select-none text-[#c62828]"
                  >
                    <label
                      class="flex items-center gap-2 cursor-pointer font-bold"
                    >
                      <input
                        type="checkbox"
                        v-model="modalVAT"
                        class="w-4 h-4 accent-[#1976d2]"
                      />{{ t("reception_order.bao_gom_vat") }}</label
                    >
                    <label
                      class="flex items-center gap-2 cursor-pointer font-bold"
                    >
                      <input
                        type="checkbox"
                        v-model="modalPPV"
                        class="w-4 h-4 accent-[#1976d2]"
                      />{{ t("reception_order.bao_gom_ppv") }}</label
                    >
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.loai_tien_te") }}</label
                      >
                      <select
                        v-model="modalCurrency"
                        class="w-full bg-gray-50 border border-[#e0e0e0] rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      >
                        <option value="VND">
                          {{ t("reception_order.vnd_viet_nam_dong") }}
                        </option>
                        <option value="USD">
                          {{ t("reception_order.usd_do_la_my") }}
                        </option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label
                        class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.ty_gia") }}</label
                      >
                      <input
                        type="text"
                        v-model="modalRate"
                        readonly
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-3 py-2 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label
                      class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider"
                      >{{ t("reception_order.ghi_chu") }}</label
                    >
                    <textarea
                      v-model="modalItemNote"
                      :placeholder="
                        t('reception_order.them_ghi_chu_dac_thu_it_da_nhi')
                      "
                      class="w-full border border-[#e0e0e0] rounded-lg p-2.5 font-bold text-gray-855 h-20 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5
                      class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2"
                    >
                      {{ t("reception_order.phan_nhom_thuc_don_he_thong") }}
                    </h5>
                    <div
                      class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]"
                    >
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.nhom_san_pham")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{
                            translateCategoryId(
                              selectedProductForDetail.category_id,
                            )
                          }}
                          <span
                            v-if="
                              getItemSubcategoryId(selectedProductForDetail.id)
                            "
                          >
                            &gt;
                            {{
                              translateSubCategoryId(
                                getItemSubcategoryId(
                                  selectedProductForDetail.id,
                                ),
                              )
                            }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_buffet")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{
                            getEligibleBuffetGroups(selectedProductForDetail)
                          }}
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_set_menu")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ getSetMenuGroup(selectedProductForDetail) }}
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_do_uong")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ getDrinkGroup(selectedProductForDetail) }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- ─── CASE B: COMPLEX ITEM OPTIONS DETAIL MODAL ─── -->
              <div v-else class="grid grid-cols-1 md:grid-cols-10 gap-6">
                <!-- Column Left (45% width -> 4.5 cols) -->
                <div
                  class="md:col-span-4 space-y-4 font-bold text-xs text-gray-700"
                >
                  <div
                    class="w-full h-44 bg-gray-100 border border-[#e0e0e0] rounded-xl flex items-center justify-center text-6xl relative overflow-hidden select-none"
                  >
                    {{ getEnrichedItem(selectedProductForDetail).emoji }}
                  </div>

                  <div class="space-y-1 leading-tight">
                    <h3 class="text-base font-bold text-gray-900 leading-tight">
                      {{ selectedProductForDetail.name }}
                    </h3>
                    <p
                      class="text-[10px] text-gray-400 font-bold uppercase mt-0.5"
                    >
                      {{ t("reception_order.ma") }}:
                      {{ selectedProductForDetail.id }} •
                      {{ t("reception_order.don_vi") }}:
                      {{ selectedProductForDetail.unit }}
                    </p>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <!-- Qty editor -->
                    <div class="space-y-1">
                      <label
                        class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.so_luong") }}</label
                      >
                      <div class="flex items-center gap-1">
                        <button
                          @click="modalItemQty = Math.max(1, modalItemQty - 1)"
                          :disabled="modalItemQty <= 1"
                          class="w-7 h-7 rounded-lg bg-gray-100 border border-gray-250 hover:bg-gray-200 flex items-center justify-center font-bold text-gray-700"
                        >
                          -
                        </button>
                        <span
                          class="w-6 text-center font-bold text-sm text-gray-900"
                          >{{ modalItemQty }}</span
                        >
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
                      <label
                        class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.don_gia_vnd") }}</label
                      >
                      <input
                        type="text"
                        :value="
                          isItemInPackage(
                            selectedProductForDetail,
                            activeSettings.package,
                          )
                            ? t('reception_order.0d_trong_goi')
                            : formatVND(selectedProductForDetail.price)
                        "
                        readonly
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2.5 py-1.5 font-bold text-[#c62828] focus:outline-none"
                      />
                    </div>
                  </div>

                  <!-- VAT/PPV checks -->
                  <div
                    class="flex items-center gap-3.5 select-none text-[#c62828] text-[11px]"
                  >
                    <label
                      class="flex items-center gap-1 cursor-pointer font-bold"
                    >
                      <input
                        type="checkbox"
                        v-model="modalVAT"
                        class="w-3.5 h-3.5 accent-[#1976d2]"
                      />
                      {{ t("reception_order.vat_percent") }}
                    </label>
                    <label
                      class="flex items-center gap-1 cursor-pointer font-bold"
                    >
                      <input
                        type="checkbox"
                        v-model="modalPPV"
                        class="w-3.5 h-3.5 accent-[#1976d2]"
                      />
                      {{ t("reception_order.ppv_percent") }}
                    </label>
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                      <label
                        class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.tien_te") }}</label
                      >
                      <select
                        v-model="modalCurrency"
                        class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none text-[11px]"
                      >
                        <option value="VND">VND</option>
                        <option value="USD">USD</option>
                      </select>
                    </div>
                    <div class="space-y-1">
                      <label
                        class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider"
                        >{{ t("reception_order.ty_gia") }}</label
                      >
                      <input
                        type="text"
                        v-model="modalRate"
                        readonly
                        class="w-full bg-gray-150 border border-gray-205 rounded-lg px-2 py-1.5 font-bold text-gray-800 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div class="space-y-1">
                    <label
                      class="block text-[9px] font-bold text-gray-400 uppercase tracking-wider"
                      >{{ t("reception_order.ghi_chu_chung") }}</label
                    >
                    <textarea
                      v-model="modalItemNote"
                      :placeholder="
                        t('reception_order.them_ghi_chu_cho_ca_mon_an')
                      "
                      class="w-full border border-[#e0e0e0] rounded-lg p-2 font-bold text-gray-800 h-16 resize-none focus:outline-none focus:border-[#1976d2]"
                    ></textarea>
                  </div>

                  <!-- Menu Classification Info (Requirement) -->
                  <div class="border-t border-[#f0f0f0] pt-4 mt-2">
                    <h5
                      class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-2"
                    >
                      {{ t("reception_order.phan_nhom_thuc_don_he_thong") }}
                    </h5>
                    <div
                      class="grid grid-cols-2 gap-3 bg-gray-50 p-3 rounded-xl border border-[#e0e0e0] text-[11px]"
                    >
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.nhom_san_pham")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{
                            translateCategoryId(
                              selectedProductForDetail.category_id,
                            )
                          }}
                          <span
                            v-if="
                              getItemSubcategoryId(selectedProductForDetail.id)
                            "
                          >
                            &gt;
                            {{
                              translateSubCategoryId(
                                getItemSubcategoryId(
                                  selectedProductForDetail.id,
                                ),
                              )
                            }}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_buffet")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{
                            getEligibleBuffetGroups(selectedProductForDetail)
                          }}
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_set_menu")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ getSetMenuGroup(selectedProductForDetail) }}
                        </div>
                      </div>
                      <div>
                        <span class="text-gray-400 font-semibold">{{
                          t("reception_order.goi_do_uong")
                        }}</span>
                        <div class="text-gray-800 font-bold mt-0.5">
                          {{ getDrinkGroup(selectedProductForDetail) }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Column Right (55% width -> 5.5 cols) -->
                <div
                  class="md:col-span-6 flex flex-col border border-[#e0e0e0] rounded-xl overflow-hidden min-h-0 bg-white shadow-sm"
                >
                  <!-- Option Group Tabs -->
                  <div
                    class="flex bg-gray-50 border-b border-[#e0e0e0] overflow-x-auto scrollbar-none select-none"
                  >
                    <button
                      v-for="group in tempOptionGroups"
                      :key="group.id"
                      @click="activeOptionTab = group.id"
                      :class="[
                        'px-4 py-2.5 text-xs font-bold transition-all border-r shrink-0',
                        activeOptionTab === group.id
                          ? 'bg-white text-[#ff8f00] border-b-2 border-b-[#ff8f00]'
                          : 'text-gray-400 hover:bg-gray-105',
                      ]"
                    >
                      {{ group.title }}
                    </button>
                  </div>

                  <!-- Options list container -->
                  <div
                    v-if="activeGroup"
                    class="flex-1 flex flex-col min-h-0 justify-between"
                  >
                    <!-- Header Group selection metrics -->
                    <div
                      class="p-3 border-b border-[#f0f0f0] flex justify-between items-center bg-gray-50/50 select-none"
                    >
                      <div>
                        <h5
                          class="text-xs font-bold text-gray-900 uppercase tracking-wide"
                        >
                          {{ activeGroup.title }}
                        </h5>
                        <p class="text-[10px] text-[#ff8f00] font-bold mt-0.5">
                          ({{ t("reception_order.toi_thieu") }}
                          {{ activeGroup.minSelection }} -
                          {{ t("reception_order.toi_da") }}
                          {{ activeGroup.maxSelection }})
                        </p>
                      </div>
                      <span
                        class="text-[10px] font-bold bg-[#1976d2] text-white px-2 py-0.5 rounded-full shadow-sm font-mono"
                      >
                        {{ activeGroupSelectedCount }} /
                        {{ activeGroup.maxSelection }}
                      </span>
                    </div>

                    <!-- Scrollable items options list -->
                    <div
                      class="flex-1 overflow-y-auto p-3 max-h-[300px] divide-y divide-[#f0f0f0] scrollbar-custom bg-white"
                    >
                      <div
                        v-for="option in activeGroup.options"
                        :key="option.id"
                        class="py-3 flex flex-col gap-2 transition-all hover:bg-gray-50/50"
                      >
                        <!-- Top option descriptor row -->
                        <div class="flex items-center justify-between gap-2">
                          <div class="flex-1">
                            <span class="font-bold text-xs text-gray-800">{{
                              option.name
                            }}</span>
                            <span
                              v-if="option.price > 0"
                              class="text-[10px] text-gray-400 ml-1.5 font-mono"
                            >
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
                            <div
                              v-else
                              class="flex items-center gap-1 bg-gray-50 border border-[#e0e0e0] rounded-lg p-0.5 select-none animate-scale-up"
                            >
                              <button
                                @click="subtractOptionQty(option)"
                                class="w-6 h-6 rounded bg-white border border-[#e0e0e0] flex items-center justify-center font-bold text-gray-600 active:scale-90"
                              >
                                -
                              </button>
                              <span
                                class="w-5 text-center font-bold text-gray-800 text-xs"
                                >{{ option.quantity }}</span
                              >
                              <button
                                @click="addOptionQty(option)"
                                :disabled="
                                  activeGroupSelectedCount >=
                                  activeGroup.maxSelection
                                "
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
                              :placeholder="
                                t(
                                  'reception_order.them_ghi_chu_rieng_cho_lua_cho',
                                )
                              "
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
                        activeGroupSelectedCount < activeGroup.minSelection
                          ? 'bg-[#fff3e0] text-[#e65100]'
                          : activeGroupSelectedCount > activeGroup.maxSelection
                            ? 'bg-[#ffebee] text-[#c62828]'
                            : 'bg-[#e8f5e9] text-[#2e7d32]',
                      ]"
                    >
                      <span class="text-xs">
                        <span
                          v-if="
                            activeGroupSelectedCount < activeGroup.minSelection
                          "
                          >⚠️</span
                        >
                        <span
                          v-else-if="
                            activeGroupSelectedCount > activeGroup.maxSelection
                          "
                          >🚨</span
                        >
                        <span v-else>✅</span>
                      </span>
                      <span
                        v-if="
                          activeGroupSelectedCount < activeGroup.minSelection
                        "
                      >
                        {{ t("reception_order.vui_long_chon_them_it_nhat") }}
                        {{
                          activeGroup.minSelection - activeGroupSelectedCount
                        }}
                        {{ t("reception_order.lua_chon_nua") }}
                      </span>
                      <span
                        v-else-if="
                          activeGroupSelectedCount > activeGroup.maxSelection
                        "
                      >
                        {{ t("reception_order.da_vuot_qua_gioi_han_toi_da") }}
                        {{ activeGroup.maxSelection }}
                        {{ t("reception_order.lua_chon") }}
                      </span>
                      <span v-else>
                        {{ t("reception_order.da_chon_du_so_luong") }}
                        {{ activeGroup.title }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Separated Footer Area -->
            <footer
              class="p-4 border-t border-[#f0f0f0] bg-white flex justify-end gap-3 shrink-0 select-none"
            >
              <button
                @click="isDetailPanelOpen = false"
                class="px-5 py-2.5 bg-[#f5f5f5] hover:bg-[#e0e0e0] border border-[#e0e0e0] text-gray-700 text-xs font-bold rounded-xl active:scale-95 transition-all"
              >
                {{ t("reception_order.huy_bo_esc") }}
              </button>

              <button
                @click="saveDetailPanelQty"
                :disabled="
                  !getEnrichedItem(selectedProductForDetail).isAvailable ||
                  !isSelectionValid
                "
                :class="[
                  'px-6 py-2.5 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 flex items-center gap-1.5',
                  getEnrichedItem(selectedProductForDetail).isAvailable &&
                  isSelectionValid
                    ? 'bg-[#2e7d32] hover:bg-[#1b5e20]'
                    : 'bg-gray-400 cursor-not-allowed opacity-50',
                ]"
              >
                <span>➕</span>
                <span>{{ t("reception_order.them_vao_gio_hang") }}</span>
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
        <div
          class="bg-white border border-[#e0e0e0] text-gray-800 rounded-2xl w-full max-w-2xl shadow-2xl p-6 relative animate-scale-up max-h-[90vh] overflow-y-auto scrollbar-thin"
        >
          <!-- Close button if package already exists -->
          <button
            v-if="activeSettings.package"
            @click="cancelPackageSelection"
            class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-205 text-gray-505 flex items-center justify-center text-sm font-bold active:scale-90 select-none border border-gray-150"
          >
            ✕
          </button>

          <h3
            class="text-[17px] font-bold text-gray-900 tracking-tight mb-4 flex items-center gap-2 select-none border-b border-[#f0f0f0] pb-3"
          >
            <span>🏆</span>
            <span
              >{{ t("reception_order.cau_hinh_goi_course_phuc_vu") }}
              {{ activeOrder.tableCode }}</span
            >
          </h3>

          <!-- PACKAGE GRID (2 cols) -->
          <div class="mb-4">
            <h4
              class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2.5 select-none"
            >
              {{ t("reception_order.1_chon_goi_an_phuc_vu_course_p") }}
            </h4>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 select-none">
              <div
                v-for="(price, name) in packagePrices"
                :key="name"
                @click="selectPackageOption(name)"
                :class="[
                  'p-3.5 rounded-xl border-2 transition-all cursor-pointer flex flex-col justify-between min-h-[95px] relative',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.package === name
                    ? 'border-[#c62828] bg-red-50/10 shadow-sm'
                    : 'border-gray-200 hover:border-red-300 hover:bg-gray-50/50',
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
                  <h5 class="text-sm font-bold text-gray-900 leading-tight">
                    {{ name }}
                  </h5>
                  <p class="text-[10px] text-gray-400 font-semibold mt-1">
                    {{
                      name.includes("Buffet")
                        ? t("reception_order.thoi_luong_phuc_vu_2_tieng")
                        : t("reception_order.menu_goi_theo_bua_tiec")
                    }}
                  </p>
                </div>
                <div class="text-right border-t border-[#f0f0f0] pt-2 mt-3">
                  <span class="text-sm font-bold text-[#c62828]"
                    >{{ price.toLocaleString("vi-VN") }}đ /
                    {{ t("reception_order.ve") }}</span
                  >
                </div>
              </div>
            </div>
          </div>

          <!-- DRINK GROUP SELECTOR CARDS -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4
              class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none"
            >
              {{ t("reception_order.2_chon_nhom_do_uong_kem_theo_d") }}
            </h4>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 select-none">
              <div
                @click="selectDrinkOption('A')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.drinkGroup === 'A'
                    ? 'border-[#ff8f00] bg-amber-50/10'
                    : 'border-gray-200 hover:bg-gray-50/50',
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🥤</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">
                      {{ t("reception_order.nhom_a_soft_drink") }}
                    </h6>
                    <p class="text-[9px] text-gray-400 font-medium">
                      {{ t("reception_order.nuoc_ngot_uong_khong_gioi_han") }}
                    </p>
                  </div>
                </div>
                <span
                  class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black"
                  :class="
                    tempSettings.drinkGroup === 'A'
                      ? 'bg-[#ff8f00] text-white border-[#ff8f00]'
                      : 'text-transparent'
                  "
                  >✓</span
                >
              </div>

              <div
                @click="selectDrinkOption('B')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.drinkGroup === 'B'
                    ? 'border-[#ff8f00] bg-amber-50/10'
                    : 'border-gray-200 hover:bg-gray-50/50',
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍺</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">
                      {{ t("reception_order.nhom_b_premium_drink") }}
                    </h6>
                    <p class="text-[9px] text-gray-400 font-medium">
                      {{ t("reception_order.ruou_bia_cao_cap_uong_trong_2") }}
                    </p>
                  </div>
                </div>
                <span
                  class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black"
                  :class="
                    tempSettings.drinkGroup === 'B'
                      ? 'bg-[#ff8f00] text-white border-[#ff8f00]'
                      : 'text-transparent'
                  "
                  >✓</span
                >
              </div>

              <div
                @click="selectDrinkOption('C')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.drinkGroup === 'C'
                    ? 'border-[#ff8f00] bg-amber-50/10'
                    : 'border-gray-200 hover:bg-gray-50/50',
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍶</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">
                      {{ t("reception_order.nhom_c_premium_alt") }}
                    </h6>
                    <p class="text-[9px] text-gray-400 font-medium">
                      {{ t("reception_order.ruou_bia_thay_the_dung_2_gio_f") }}
                    </p>
                  </div>
                </div>
                <span
                  class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black"
                  :class="
                    tempSettings.drinkGroup === 'C'
                      ? 'bg-[#ff8f00] text-white border-[#ff8f00]'
                      : 'text-transparent'
                  "
                  >✓</span
                >
              </div>

              <div
                @click="selectDrinkOption('D')"
                :class="[
                  'p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.drinkGroup === 'D'
                    ? 'border-[#ff8f00] bg-amber-50/10'
                    : 'border-gray-200 hover:bg-gray-50/50',
                ]"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">🍷</span>
                  <div>
                    <h6 class="text-xs font-bold text-gray-800">
                      {{ t("reception_order.nhom_d_a_la_carte") }}
                    </h6>
                    <p class="text-[9px] text-gray-400 font-medium">
                      {{ t("reception_order.goi_do_uong_le_tinh_tien_rieng") }}
                    </p>
                  </div>
                </div>
                <span
                  class="w-4 h-4 rounded-full border border-gray-300 flex items-center justify-center text-[8px] font-black"
                  :class="
                    tempSettings.drinkGroup === 'D'
                      ? 'bg-[#ff8f00] text-white border-[#ff8f00]'
                      : 'text-transparent'
                  "
                  >✓</span
                >
              </div>
            </div>
          </div>

          <!-- LANGUAGES CHOICE -->
          <div class="mb-4 border-t border-[#f0f0f0] pt-3.5">
            <h4
              class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 select-none"
            >
              {{ t("reception_order.3_ngon_ngu_giao_dien_hien_thi") }}
            </h4>
            <div class="flex flex-wrap gap-2 select-none">
              <button
                v-for="lang in ['VI', 'EN', 'JP', 'KO', 'ZH']"
                :key="lang"
                @click="tempSettings.language = lang"
                :class="[
                  'px-4 py-2 rounded-xl text-xs font-bold transition-all border shrink-0',
                  activeSettings.isLocked
                    ? 'pointer-events-none opacity-60 bg-gray-50'
                    : '',
                  tempSettings.language === lang
                    ? 'bg-[#1976d2] border-[#1976d2] text-white shadow-sm font-semibold'
                    : 'bg-gray-50 border-gray-205 text-gray-600 hover:bg-gray-100',
                ]"
              >
                <span v-if="lang === 'VI'">{{
                  t("reception_order.tieng_viet")
                }}</span>
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
              {{ t("reception_order.huy_bo_quay_lai") }}
            </button>

            <button
              v-if="activeSettings.isLocked"
              @click="openPinModal"
              class="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >
              {{ t("reception_order.pin_sua_cau_hinh") }}
            </button>
            <button
              v-else
              @click="confirmPackageSelection"
              class="flex-1 py-2.5 bg-[#c62828] hover:bg-[#b71c1c] text-white text-xs font-bold rounded-xl shadow-sm transition-all"
            >
              {{ t("reception_order.xac_nhan_khoa_course") }}
            </button>
          </div>
        </div>
      </div>

      <!-- MANAGER PIN PAD UNLOCK MODAL -->
      <div
        v-if="isPinModalOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-950/70 backdrop-blur-xs animate-fade-in text-gray-800"
      >
        <div
          class="bg-white border border-[#e0e0e0] rounded-2xl w-full max-w-xs shadow-2xl p-6 text-center animate-scale-up relative"
        >
          <button
            @click="isPinModalOpen = false"
            class="absolute top-4 right-4 w-7 h-7 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-505 flex items-center justify-center text-xs font-bold"
          >
            ✕
          </button>

          <span class="text-3xl block mb-2">🔐</span>
          <h4 class="text-sm font-bold text-gray-900 mb-1">
            {{ t("reception_order.ma_pin_xac_thuc_quan_ly") }}
          </h4>
          <p
            class="text-[10px] text-gray-400 font-semibold mb-4 leading-normal"
          >
            {{ t("reception_order.nhap_ma_pin_cua_quan_ly_de_mo") }}
          </p>

          <!-- Input dots -->
          <div class="flex justify-center gap-3.5 mb-5 select-none">
            <div
              v-for="i in 4"
              :key="i"
              :class="[
                'w-4 h-4 rounded-full border transition-all duration-100',
                enteredPin.length >= i
                  ? 'bg-red-650 border-red-700 scale-110 shadow-sm'
                  : 'bg-gray-100 border-gray-300',
              ]"
            ></div>
          </div>

          <!-- PIN Pad Grid -->
          <div
            class="grid grid-cols-3 gap-2.5 select-none mb-4 max-w-[220px] mx-auto"
          >
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

    <!-- Custom Modal other-income -->
    <Transition name="fade">
      <div
        v-if="showOtherIncomeModal"
        class="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-[9999] p-4"
      >
        <div
          class="other-income-modal w-full max-w-[600px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]"
        >
          <!-- Header -->
          <div
            class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between"
          >
            <h2 class="text-base font-black uppercase tracking-wide">
              {{ t("reception.other_income_short") }}
            </h2>
            <button
              @click="showOtherIncomeModal = false"
              class="text-white/80 hover:text-white transition-colors"
              type="button"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
          </div>

          <!-- Creator Info -->
          <div class="creator-info bg-[#f5f5f5] p-4 border-b border-gray-200">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center gap-2">
                <span
                  class="text-xs font-bold text-gray-500 uppercase min-w-[80px]"
                  >Người tạo:</span
                >
                <span class="text-xs font-bold text-gray-800">{{
                  creator
                }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span
                  class="text-xs font-bold text-gray-500 uppercase min-w-[80px]"
                  >Ngày lập:</span
                >
                <input
                  v-model="createdDate"
                  type="text"
                  class="bg-white border border-gray-300 rounded px-2.5 py-1 text-xs font-mono font-bold w-full max-w-[160px] focus:outline-none focus:border-[#E8772E]"
                />
              </div>
            </div>
          </div>

          <!-- Form Content -->
          <form
            @submit.prevent="handleSave"
            class="form-content p-5 max-h-[420px] overflow-y-auto space-y-4"
          >
            <!-- Đối tượng -->
            <div class="form-row required flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600"
                >Đối tượng <span class="text-red-500">*</span></label
              >
              <div class="input-with-button flex items-center gap-1.5">
                <input
                  v-model="form.object"
                  type="text"
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-2 focus:ring-[#E8772E]/10"
                  :placeholder="t('reception.enter_target_name')"
                  required
                />
                <button
                  type="button"
                  @click="triggerSelectObject"
                  class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all"
                >
                  ...
                </button>
              </div>
            </div>

            <!-- Loại thu & Khoản thu (Grid) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Loại thu -->
              <div class="form-row required flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600"
                  >Loại thu <span class="text-red-500">*</span></label
                >
                <select
                  v-model="form.incomeType"
                  class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  required
                >
                  <option value="other">Thu Khác</option>
                  <option value="deposit">Tiền đặt cọc</option>
                  <option value="refund">Hoàn tiền</option>
                </select>
              </div>

              <!-- Khoản thu -->
              <div class="form-row required flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600"
                  >Khoản thu <span class="text-red-500">*</span></label
                >
                <select
                  v-model="form.incomeItem"
                  class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  required
                >
                  <option value="withdraw">Rút tiền dư</option>
                  <option value="adjustment">Điều chỉnh</option>
                  <option value="other">{{ t("reception.other") }}</option>
                </select>
              </div>
            </div>

            <!-- Tiền thu (Highlight hồng nhạt) -->
            <div
              class="form-row required highlight bg-[#FFF0F0] border border-red-200/50 p-3.5 rounded-xl flex flex-col gap-1"
            >
              <label class="text-xs font-bold text-red-700"
                >Tiền thu <span class="text-red-500">*</span></label
              >
              <div class="input-with-button flex items-center gap-1.5">
                <input
                  :value="formattedAmount"
                  @input="handleAmountInput"
                  type="text"
                  class="form-input flex-1 px-3 py-2 border border-red-300 rounded-lg text-xs font-mono font-bold text-right text-red-600 focus:outline-none focus:ring-2 focus:ring-red-100"
                  placeholder="0"
                  required
                />
                <button
                  type="button"
                  class="btn-browse px-3 py-2 bg-red-100 hover:bg-red-200 border border-red-300 text-xs font-bold text-red-700 rounded-lg active:scale-95 transition-all"
                >
                  ...
                </button>
              </div>
            </div>

            <!-- Lý do -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">{{
                t("reception.reason")
              }}</label>
              <div class="input-with-button flex items-center gap-1.5">
                <input
                  v-model="form.reason"
                  type="text"
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  :placeholder="t('reception.enter_reason')"
                />
                <button
                  type="button"
                  class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all"
                >
                  ...
                </button>
              </div>
            </div>

            <!-- Số chứng từ & Mã đặt chỗ (Grid) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Số chứng từ -->
              <div class="form-row flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600"
                  >Số chứng từ</label
                >
                <input
                  v-model="form.voucherNumber"
                  type="text"
                  class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  :placeholder="t('reception.auto_generated')"
                />
              </div>

              <!-- Mã đặt chỗ -->
              <div class="form-row flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600"
                  >Mã đặt chỗ</label
                >
                <input
                  v-model="form.bookingCode"
                  type="text"
                  class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  :placeholder="t('reception.enter_booking_code')"
                />
              </div>
            </div>

            <!-- Tiền mặt -->
            <div
              class="form-row checkbox-row flex items-center gap-2 pt-2 select-none"
            >
              <input
                v-model="form.isCash"
                type="checkbox"
                id="isCash"
                class="w-4.5 h-4.5 accent-[#E8772E] cursor-pointer"
              />
              <label
                for="isCash"
                class="text-xs font-bold text-gray-700 cursor-pointer"
                >{{ t("reception.cash") }}</label
              >
            </div>
          </form>

          <!-- Footer Actions -->
          <div
            class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3"
          >
            <button
              type="button"
              class="btn btn-save-print px-4 py-2 bg-[#4CAF50] hover:bg-[#43A047] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95 flex items-center gap-1.5"
              @click="handleSaveAndPrint"
            >
              {{ t("reception.save_and_print") }}
            </button>
            <button
              type="button"
              class="btn btn-save px-4 py-2 bg-[#FF9800] hover:bg-[#F57C00] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="handleSave"
            >
              {{ t("reception.save") }}
            </button>
            <button
              type="button"
              class="btn btn-cancel px-4 py-2 bg-[#F44336] hover:bg-[#E53935] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="showOtherIncomeModal = false"
            >
              {{ t("reception.skip") }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Custom Modal settings -->
    <Transition name="fade">
      <div
        v-if="showSettingsModal"
        class="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-[9999] p-4"
      >
        <div
          class="settings-modal w-full max-w-[500px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]"
        >
          <!-- Header -->
          <div
            class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between"
          >
            <h2 class="text-base font-black uppercase tracking-wide">
              {{ t("reception.configuration") }}
            </h2>
            <button
              @click="showSettingsModal = false"
              class="text-white/80 hover:text-white transition-colors"
              type="button"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
          </div>

          <!-- Form Content -->
          <div class="modal-content p-5 space-y-4">
            <!-- Username -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">{{
                t("reception.username")
              }}</label>
              <div class="input-group flex items-center gap-1.5">
                <input
                  v-model="settingsUsername"
                  type="text"
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  :placeholder="t('reception.enter_username')"
                />
                <button
                  type="button"
                  class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all"
                >
                  ...
                </button>
              </div>
            </div>

            <!-- Password -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">{{
                t("reception.password")
              }}</label>
              <div class="input-group flex items-center gap-1.5">
                <input
                  v-model="settingsPassword"
                  type="password"
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  :placeholder="t('reception.enter_password')"
                />
                <button
                  type="button"
                  class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all"
                >
                  ...
                </button>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div
            class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3"
          >
            <button
              type="button"
              class="btn btn-confirm px-6 py-2 bg-[#4DB6AC] hover:bg-[#40a095] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="handleSaveSettings"
            >
              {{ t("reception.confirm") }}
            </button>
            <button
              type="button"
              class="btn btn-skip px-6 py-2 bg-[#E57373] hover:bg-[#d9534f] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="showSettingsModal = false"
            >
              {{ t("reception.ignore") }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Secondary Menu Overlay (Hamburger Menu) -->
    <Transition name="fade">
      <div
        v-if="showMenu"
        class="fixed inset-0 z-[990] bg-black/40 backdrop-blur-xs"
        @click="showMenu = false"
      ></div>
    </Transition>
    <Transition name="slide-left">
      <div v-if="showMenu" class="secondary-menu z-[991]">
        <div class="menu-list">
          <button
            v-for="item in menuItems"
            :key="item.id"
            class="menu-item border-b border-gray-100/10 last:border-b-0"
            :class="item.colorClass"
            @click="handleMenuClick(item)"
            type="button"
          >
            <span class="menu-icon text-lg">{{ item.icon }}</span>
            <span class="menu-label font-bold tracking-wide">{{
              item.label
            }}</span>
          </button>
        </div>
      </div>
    </Transition>

    <!-- Context Menu Overlay -->
    <Transition name="fade">
      <div
        v-if="showTableContextMenu"
        class="fixed inset-0 z-[9998] bg-black/30 backdrop-blur-xs"
        @click="showTableContextMenu = false"
      ></div>
    </Transition>

    <!-- Context Menu Popup -->
    <Transition name="scale-up">
      <div
        v-if="showTableContextMenu"
        class="fixed z-[9999] bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-200"
        :style="contextMenuStyle"
        @click.stop
      >
        <!-- Header -->
        <div
          class="bg-gradient-to-r from-blue-50 to-indigo-50 px-5 py-4 border-b border-gray-200"
        >
          <div class="flex items-center gap-3">
            <div
              class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center"
            >
              <span class="text-xl">📋</span>
            </div>
            <div>
              <div class="text-sm font-bold text-gray-800">
                Bàn {{ selectedTableForAction?.code }}
              </div>
              <div class="text-xs text-gray-500">
                {{ selectedTableForAction?.customerName || "Khách vãng lai" }}
              </div>
            </div>
          </div>
        </div>

        <!-- Menu Items -->
        <div class="p-3 space-y-2">
          <button
            v-for="action in tableActions"
            :key="action.id"
            @click="handleTableAction(action.id)"
            class="w-full flex items-center gap-3 p-3 rounded-xl transition-all group"
            :class="[
              action.isPrimary
                ? 'primary-action bg-gradient-to-r from-green-50 to-green-100/80 border-2 border-green-500 p-4 mb-3'
                : 'hover:bg-gray-50',
            ]"
            type="button"
          >
            <div
              class="w-11 h-11 rounded-xl flex items-center justify-center text-xl shadow-sm group-hover:scale-110 transition-transform shrink-0"
              :class="action.colorClass"
            >
              {{ action.icon }}
            </div>
            <div class="flex-1 text-left">
              <div
                class="font-bold text-gray-800 text-sm"
                :class="[
                  action.isPrimary
                    ? 'text-green-800 font-extrabold text-base'
                    : '',
                ]"
              >
                {{ action.label }}
              </div>
              <div
                class="text-xs text-gray-500"
                :class="[action.isPrimary ? 'text-green-700 font-medium' : '']"
              >
                {{ action.description }}
                {{
                  action.id === "select_items"
                    ? selectedTableForAction?.code
                    : ""
                }}
              </div>
            </div>
            <span
              class="text-gray-400 text-lg group-hover:translate-x-1 transition-transform"
              :class="[action.isPrimary ? 'text-green-600' : '']"
              >➡️</span
            >
          </button>
        </div>
      </div>
    </Transition>

    <!-- Modal 4: TÁCH MÔN -->
    <Transition name="fade">
      <div
        v-if="showSplitItemModal"
        class="fixed inset-0 z-[10000] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
      >
        <div
          class="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden"
        >
          <div
            class="bg-gradient-to-r from-pink-500 to-pink-600 text-white px-6 py-4"
          >
            <h3 class="text-lg font-bold flex items-center gap-2">
              <span>🍽️</span> Tách món bàn {{ selectedTableForAction?.code }}
            </h3>
            <p class="text-xs text-pink-100 mt-1">
              {{ t("reception.select_split_items") }}
            </p>
          </div>

          <div class="p-6">
            <div class="mb-4 text-sm text-gray-600">
              {{ t("reception.select_at_least_one") }}
            </div>

            <div class="space-y-2 max-h-80 overflow-y-auto">
              <div
                v-for="item in restaurantStore.tableOrders[
                  selectedTableForAction?.code
                ]?.items || []"
                :key="item.id"
                @click="toggleItemForSplit(item.id)"
                :class="[
                  'p-3 rounded-lg border-2 cursor-pointer transition-all flex items-center gap-3',
                  selectedItemsToSplit.includes(item.id)
                    ? 'border-pink-500 bg-pink-50'
                    : 'border-gray-200 hover:border-gray-300',
                ]"
              >
                <input
                  type="checkbox"
                  :checked="selectedItemsToSplit.includes(item.id)"
                  class="w-5 h-5 accent-pink-500"
                />
                <div class="flex-1">
                  <div class="font-bold text-sm text-gray-800">
                    {{ item.name }}
                  </div>
                  <div class="text-xs text-gray-500">
                    x{{ item.quantity }} {{ item.unit }} -
                    {{ formatVND(item.price * item.quantity) }}
                  </div>
                </div>
              </div>
            </div>

            <div
              v-if="selectedItemsToSplit.length === 0"
              class="mt-3 text-xs text-orange-600 bg-orange-50 p-2 rounded"
            >
              {{ t("reception.please_select_one") }}
            </div>
          </div>

          <div
            class="bg-gray-50 px-6 py-4 flex justify-end gap-3 border-t border-gray-200"
          >
            <button
              @click="showSplitItemModal = false"
              class="px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-lg font-bold text-sm"
              type="button"
            >
              {{ t("reception.cancel") }}
            </button>
            <button
              @click="executeSplitItem"
              :disabled="selectedItemsToSplit.length === 0 || splitItemLoading"
              class="px-4 py-2 bg-pink-500 hover:bg-pink-600 disabled:bg-gray-300 text-white rounded-lg font-bold text-sm flex items-center gap-2"
              type="button"
            >
              <span v-if="splitItemLoading" class="animate-spin inline-block"
                >⏳</span
              >
              <span>{{ splitItemLoading ? "Đang tách..." : "Tách món" }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Modal 5: HỦY PHIẾU -->
    <Transition name="fade">
      <div
        v-if="showCancelModal"
        class="fixed inset-0 z-[10000] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
      >
        <div
          class="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden"
        >
          <div
            class="bg-gradient-to-r from-red-500 to-red-600 text-white px-6 py-4"
          >
            <h3 class="text-lg font-bold flex items-center gap-2">
              <span>❌</span> Hủy phiếu bàn {{ selectedTableForAction?.code }}
            </h3>
            <p class="text-xs text-red-100 mt-1">
              {{ t("reception.delete_entire_order") }}
            </p>
          </div>

          <div class="p-6">
            <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
              <div class="flex items-start gap-3">
                <span class="text-2xl">⚠️</span>
                <div>
                  <div class="font-bold text-red-800 text-sm mb-1">
                    {{ t("reception.warning") }}
                  </div>
                  <div class="text-xs text-red-700">
                    {{ t("reception.this_action_will")
                    }}<strong>{{ t("reception.permanently_delete") }}</strong
                    >{{ t("reception.entire_order_of_table")
                    }}<strong>{{ selectedTableForAction?.code }}</strong
                    >{{ t("reception.cannot_be_undone") }}
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-gray-50 rounded-lg p-3 mb-4">
              <div class="text-xs text-gray-600 mb-2">
                {{ t("reception.order_info") }}
              </div>
              <div class="text-sm text-gray-800">
                <strong
                  >{{
                    restaurantStore.tableOrders[selectedTableForAction?.code]
                      ?.items?.length || 0
                  }}
                  món</strong
                >
                - Tổng:
                <strong class="text-red-600">{{
                  formatVND(summary?.grandTotal || 0)
                }}</strong>
              </div>
            </div>

            <label class="block text-sm font-bold text-gray-700 mb-2">
              Nhập "HỦY" để xác nhận:
            </label>
            <input
              v-model="cancelConfirmText"
              type="text"
              :placeholder="t('reception.type_cancel')"
              class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg text-center font-bold text-lg focus:border-red-500 focus:outline-none"
            />
          </div>

          <div
            class="bg-gray-50 px-6 py-4 flex justify-end gap-3 border-t border-gray-200"
          >
            <button
              @click="showCancelModal = false"
              class="px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-lg font-bold text-sm"
              type="button"
            >
              {{ t("reception.cancel") }}
            </button>
            <button
              @click="executeCancel"
              :disabled="cancelConfirmText !== 'HỦY' || cancelLoading"
              class="px-4 py-2 bg-red-500 hover:bg-red-600 disabled:bg-gray-300 text-white rounded-lg font-bold text-sm flex items-center gap-2"
              type="button"
            >
              <span v-if="cancelLoading" class="animate-spin inline-block"
                >⏳</span
              >
              <span>{{ cancelLoading ? "Đang hủy..." : "Xác nhận hủy" }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Selection Mode Info Bar -->
    <div
      v-if="selectionMode !== 'none'"
      class="fixed bottom-20 left-1/2 transform -translate-x-1/2 bg-blue-600 text-white px-6 py-3 rounded-xl shadow-2xl z-[10000] flex items-center gap-3 animate-slide-up"
    >
      <span class="text-xl">ℹ️</span>
      <div>
        <div class="font-bold text-sm">
          {{ getSelectionModeTitle() }}
        </div>
        <div class="text-xs text-blue-100">
          {{ t("reception.click_highlighted_table") }}
        </div>
      </div>
      <button
        @click="cancelSelectionMode"
        class="ml-4 px-3 py-1 bg-blue-700 hover:bg-blue-800 rounded-lg text-xs font-bold"
        type="button"
      >
        {{ t("reception.cancel_esc") }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useLanguageStore } from "@/stores/useLanguageStore";
const langStore = useLanguageStore();
const t = langStore.t;

import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { useRouter } from "vue-router";
import { useRestaurantStore } from "@/stores/restaurantStore";
import { storeToRefs } from "pinia";
import { menuData, type MenuItem } from "@/data/menuData";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/composables/useAuth";
import { useTable } from "@/composables/useTable";
import { useMenu } from "@/composables/useMenu";
import Swal from "sweetalert2";
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
  Eye,
} from "lucide-vue-next";

const router = useRouter();
const restaurantStore = useRestaurantStore();
const { selectedTableCode } = storeToRefs(restaurantStore);
const { listTables } = useTable();
const { getItems } = useMenu();
const { profile } = useAuth();

// ===== CONTEXT MENU STATE =====
const showTableContextMenu = ref(false)
const selectedTableForAction = ref<any>(null)
const contextMenuPosition = ref({ x: 0, y: 0 })

// Selection Mode state
const selectionMode = ref<'none' | 'transfer' | 'merge' | 'split-order' | 'split-item'>('none')
const sourceTableCode = ref<string>('')
const selectedItemsToSplit = ref<string[]>([])

// Modal states
const showTransferModal = ref(false)
const showMergeModal = ref(false)
const showSplitOrderModal = ref(false)
const showSplitItemModal = ref(false)
const showCancelModal = ref(false)

// Transfer state
const transferTargetTable = ref('')
const transferLoading = ref(false)

// Merge state
const mergeTargetTable = ref('')
const mergeLoading = ref(false)

// Split order state
const splitOrderCount = ref(2)
const splitOrderLoading = ref(false)

// Split item state
const splitItemLoading = ref(false)

// Cancel state
const cancelConfirmText = ref('')
const cancelLoading = ref(false)

// Tính toán vị trí menu tự động
// FIX: Auto placement cho context menu
const contextMenuStyle = computed(() => {
  const x = contextMenuPosition.value.x;
  const y = contextMenuPosition.value.y;

  // Ước lượng kích thước menu
  const menuWidth = 320;
  const menuHeight = 400; // 5 items ~80px + header

  // Viewport dimensions
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  // Check overflow RIGHT
  const adjustedX = (x + menuWidth > viewportWidth)
    ? viewportWidth - menuWidth - 10
    : Math.max(10, x);

  // Check overflow BOTTOM -> FLIP UP
  const spaceBelow = viewportHeight - y;
  const shouldFlipUp = spaceBelow < menuHeight;

  const adjustedY = shouldFlipUp
    ? Math.max(10, y - menuHeight - 10) // Mở lên trên
    : y; // Mở xuống dưới

  return {
    left: `${adjustedX}px`,
    top: `${adjustedY}px`,
    transformOrigin: shouldFlipUp ? 'bottom left' : 'top left',
  };
});

// Double-click handler
function handleTableDoubleClick(table: any, event: MouseEvent) {
  if (table.status === 'Available') {
    selectTable(table.code);
    activeMainTab.value = 'menu';
    triggerToast('success', `Đã chọn bàn ${table.code} - Vui lòng chọn món`);
    return;
  }
  selectedTableForAction.value = table;
  contextMenuPosition.value = { x: event.clientX, y: event.clientY };
  showTableContextMenu.value = true;
}

// Helper: Lấy class màu cho icon
const getIconColorClass = (actionId: string): string => {
  const colorMap: Record<string, string> = {
    'select_items': 'icon-green',
    'transfer': 'icon-blue',
    'merge': 'icon-purple',
    'split-order': 'icon-orange',
    'split-item': 'icon-pink',
    'cancel': 'icon-red',
  };
  return colorMap[actionId] || 'icon-blue';
};

// Context menu actions config
const tableActions = ref([
  {
    id: 'select_items',
    label: 'Chọn món',
    icon: '📝',
    colorClass: 'bg-green-500 text-white',
    description: 'Thêm món vào bàn',
    isPrimary: true
  },
  {
    id: 'transfer',
    label: 'Chuyển bàn',
    icon: '🔁',
    colorClass: 'bg-blue-500 text-white',
    description: 'Di chuyển order sang bàn khác'
  },
  {
    id: 'merge',
    label: 'Ghép phiếu',
    icon: '🔗',
    colorClass: 'bg-purple-500 text-white',
    description: 'Gộp order từ 2 bàn thành 1'
  },
  {
    id: 'split-order',
    label: 'Tách phiếu',
    icon: '✂️',
    colorClass: 'bg-orange-500 text-white',
    description: 'Chia order thành nhiều phiếu'
  },
  {
    id: 'split-item',
    label: 'Tách món',
    icon: '🍽️',
    colorClass: 'bg-pink-500 text-white',
    description: 'Tách riêng một số món'
  },
  {
    id: 'cancel',
    label: 'Hủy phiếu',
    icon: '❌',
    colorClass: 'bg-red-500 text-white',
    description: 'Xóa toàn bộ order'
  }
]);

const getTablesWithStatus = () => {
  const list: any[] = [];
  restaurantStore.areas.forEach((area) => {
    area.tables.forEach((table) => {
      list.push(table);
    });
  });
  return list;
};

// Handle table action
function handleTableAction(actionId: string) {
  showTableContextMenu.value = false;

  const table = selectedTableForAction.value;
  if (!table) return;

  switch(actionId) {
    case 'select_items':
      activeMainTab.value = 'menu';
      selectedTableCode.value = table.code;
      triggerToast('success', `Đã chọn bàn ${table.code} - Vui lòng chọn món`);
      break;
    case 'transfer':
      sourceTableCode.value = table.code;
      selectionMode.value = 'transfer';
      triggerToast('info', `Chọn bàn đích để chuyển từ bàn ${table.code}`);
      break;

    case 'merge':
      sourceTableCode.value = table.code;
      selectionMode.value = 'merge';
      triggerToast('info', `Chọn bàn để ghép với bàn ${table.code}`);
      break;

    case 'split-order':
      sourceTableCode.value = table.code;
      selectionMode.value = 'split-order';
      triggerToast('info', `Chọn bàn đích để tách phiếu từ bàn ${table.code}`);
      break;

    case 'split-item':
      sourceTableCode.value = table.code;
      selectionMode.value = 'split-item';
      triggerToast('info', `Chọn bàn đích để tách món từ bàn ${table.code}`);
      break;

    case 'cancel':
      showCancelModal.value = true;
      break;
  }
}

// Computed: Valid target tables
const validTargetTables = computed(() => {
  if (selectionMode.value === 'none') return [];

  const allTables = restaurantStore.areas.flatMap(a => a.tables);

  switch(selectionMode.value) {
    case 'transfer':
      // Only empty tables
      return allTables.filter(t => t.status === 'Available' && t.code !== sourceTableCode.value);
    case 'merge':
      // Tables with orders (not empty)
      return allTables.filter(t => {
        const order = restaurantStore.tableOrders[t.code];
        return t.status !== 'Available' &&
               t.code !== sourceTableCode.value &&
               order && order.items && order.items.length > 0;
      });
    case 'split-order':
    case 'split-item':
      // Empty tables or tables with orders
      return allTables.filter(t => t.code !== sourceTableCode.value);
    default:
      return [];
  }
});

// Check if table is valid target
function isValidTargetTable(tableCode: string): boolean {
  return validTargetTables.value.some(t => t.code === tableCode);
}

// Handle table click in Selection Mode
const handleTableClickInSelectionMode = async (targetTable: any) => {
  if (selectionMode.value === 'none') return;

  // Check if valid target
  if (!isValidTargetTable(targetTable.code)) {
    triggerToast('warning', 'Bàn chọn không hợp lệ!');
    return;
  }

  const sourceTable = restaurantStore.getTableByCode(sourceTableCode.value);
  if (!sourceTable) return;

  switch(selectionMode.value) {
    case 'transfer':
      Swal.fire({
        title: 'Xác nhận chuyển bàn?',
        text: `Chuyển toàn bộ order từ bàn ${sourceTable.code} sang bàn ${targetTable.code}?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Đồng ý',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#3b82f6'
      }).then(async (result) => {
        if (result.isConfirmed) {
          await executeTransfer(sourceTable, targetTable);
          exitSelectionMode();
        }
      });
      break;

    case 'merge':
      Swal.fire({
        title: 'Xác nhận ghép phiếu?',
        text: `Ghép phiếu bàn ${sourceTable.code} vào bàn ${targetTable.code}?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Đồng ý',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#8b5cf6'
      }).then(async (result) => {
        if (result.isConfirmed) {
          await executeMerge(sourceTable, targetTable);
          exitSelectionMode();
        }
      });
      break;

    case 'split-order':
      // Ask split count
      Swal.fire({
        title: `Tách phiếu bàn ${sourceTable.code}`,
        text: 'Tách thành bao nhiêu phiếu?',
        input: 'number',
        inputValue: '2',
        inputAttributes: { min: '2', max: '10' },
        showCancelButton: true,
        confirmButtonText: 'Tách',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#f97316'
      }).then(async (result) => {
        if (result.isConfirmed && result.value) {
          splitOrderCount.value = parseInt(result.value) || 2;
          await executeSplitOrder(sourceTable, targetTable);
          exitSelectionMode();
        }
      });
      break;

    case 'split-item':
      // Open multi-select split item modal targeting this selected targetTable
      selectedTableForAction.value = sourceTable;
      transferTargetTable.value = targetTable.code;
      showSplitItemModal.value = true;
      break;
  }
};

async function executeTransfer(sourceTable: any, targetTable: any) {
  try {
    const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);
    if (!sourceOrder.items || sourceOrder.items.length === 0) {
      throw new Error('Bàn nguồn không có order!');
    }

    const targetOrder = restaurantStore.getOrCreateOrder(targetTable.code);
    targetOrder.items = [...sourceOrder.items];
    targetOrder.customerName = sourceOrder.customerName;
    targetOrder.openedTime = sourceOrder.openedTime;

    sourceOrder.items = [];
    sourceOrder.customerName = '';

    sourceTable.status = 'Available';
    sourceTable.customerName = '';
    sourceTable.billAmount = '';

    targetTable.status = 'Serving';
    targetTable.customerName = targetOrder.customerName;

    const total = targetOrder.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    targetTable.billAmount = formatVND(total);

    triggerToast('success', `Đã chuyển bàn ${sourceTable.code} sang bàn ${targetTable.code}`);
    selectedTableCode.value = targetTable.code;
  } catch (error) {
    triggerToast('error', error instanceof Error ? error.message : 'Chuyển bàn thất bại!');
  }
}

async function executeMerge(sourceTable: any, targetTable: any) {
  try {
    const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);
    const targetOrder = restaurantStore.getOrCreateOrder(targetTable.code);

    if (!sourceOrder.items || sourceOrder.items.length === 0) {
      throw new Error('Bàn nguồn không có order!');
    }

    targetOrder.items = [
      ...targetOrder.items,
      ...sourceOrder.items
    ];

    if (!targetOrder.customerName) {
      targetOrder.customerName = sourceOrder.customerName;
    }

    sourceOrder.items = [];
    sourceOrder.customerName = '';

    sourceTable.status = 'Available';
    sourceTable.customerName = '';
    sourceTable.billAmount = '';

    const targetTotal = targetOrder.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    targetTable.billAmount = formatVND(targetTotal);

    triggerToast('success', `Đã ghép phiếu bàn ${sourceTable.code} vào bàn ${targetTable.code}`);
    selectedTableCode.value = targetTable.code;
  } catch (error) {
    triggerToast('error', error instanceof Error ? error.message : 'Ghép phiếu thất bại!');
  }
}

async function executeSplitOrder(sourceTable: any, targetTable: any) {
  try {
    const sourceOrder = restaurantStore.getOrCreateOrder(sourceTable.code);

    if (!sourceOrder.items || sourceOrder.items.length === 0) {
      throw new Error('Bàn không có order!');
    }

    const items = sourceOrder.items;
    const itemsPerSplit = Math.ceil(items.length / splitOrderCount.value);
    const assignedCodes = new Set<string>();

    // Create split orders
    for (let i = 1; i < splitOrderCount.value; i++) {
      const splitItems = items.slice(i * itemsPerSplit, (i + 1) * itemsPerSplit);

      if (splitItems.length > 0) {
        let availableTable = null;
        if (i === 1) {
          availableTable = targetTable;
        } else {
          availableTable = filteredTables.value.find(t =>
            t.status === 'Available' &&
            t.code !== sourceTable.code &&
            t.code !== targetTable.code &&
            !assignedCodes.has(t.code)
          );
        }

        if (availableTable) {
          assignedCodes.add(availableTable.code);
          const splitOrder = restaurantStore.getOrCreateOrder(availableTable.code);
          splitOrder.items = splitItems;
          splitOrder.customerName = sourceOrder.customerName;
          splitOrder.openedTime = sourceOrder.openedTime;

          const table = restaurantStore.getTableByCode(availableTable.code);
          if (table) {
            table.status = 'Serving';
            table.customerName = splitOrder.customerName;
            const total = splitItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
            table.billAmount = formatVND(total);
          }
        }
      }
    }

    // Keep remaining items in source
    sourceOrder.items = items.slice(0, itemsPerSplit);
    if (sourceTable) {
      const sourceTotal = sourceOrder.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
      sourceTable.billAmount = formatVND(sourceTotal);
    }

    triggerToast('success', `Đã tách thành ${splitOrderCount.value} phiếu!`);
    splitOrderCount.value = 2;
  } catch (error) {
    triggerToast('error', error instanceof Error ? error.message : 'Tách phiếu thất bại!');
  }
}

function toggleItemForSplit(itemId: string) {
  const index = selectedItemsToSplit.value.indexOf(itemId);
  if (index > -1) {
    selectedItemsToSplit.value.splice(index, 1);
  } else {
    selectedItemsToSplit.value.push(itemId);
  }
}

async function executeSplitItem() {
  if (selectedItemsToSplit.value.length === 0) {
    triggerToast('warning', 'Vui lòng chọn ít nhất 1 món!');
    return;
  }

  splitItemLoading.value = true;

  try {
    const sourceOrder = restaurantStore.getOrCreateOrder(selectedTableForAction.value.code);

    // Get items to split
    const itemsToSplit = sourceOrder.items.filter(item =>
      selectedItemsToSplit.value.includes(item.id)
    );

    if (itemsToSplit.length === 0) {
      throw new Error('Không tìm thấy món cần tách!');
    }

    const targetCode = transferTargetTable.value;
    if (!targetCode) {
      throw new Error('Không có bàn trống để tách!');
    }

    // Create new order
    const newOrder = restaurantStore.getOrCreateOrder(targetCode);
    newOrder.items = [...newOrder.items, ...itemsToSplit];
    newOrder.customerName = sourceOrder.customerName;
    newOrder.openedTime = sourceOrder.openedTime;

    // Remove from source
    sourceOrder.items = sourceOrder.items.filter(item =>
      !selectedItemsToSplit.value.includes(item.id)
    );

    // Update table status
    const targetTable = restaurantStore.getTableByCode(targetCode);
    if (targetTable) {
      targetTable.status = 'Serving';
      targetTable.customerName = newOrder.customerName;
      const targetTotal = newOrder.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
      targetTable.billAmount = formatVND(targetTotal);
    }

    const sourceTable = restaurantStore.getTableByCode(selectedTableForAction.value.code);
    if (sourceTable) {
      const sourceTotal = sourceOrder.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
      sourceTable.billAmount = formatVND(sourceTotal);
    }

    triggerToast('success', `Đã tách ${itemsToSplit.length} món sang bàn ${targetCode}`);
    showSplitItemModal.value = false;
    selectedItemsToSplit.value = [];
    exitSelectionMode();
  } catch (error) {
    triggerToast('error', error instanceof Error ? error.message : 'Tách món thất bại!');
  } finally {
    splitItemLoading.value = false;
  }
}

async function executeCancel() {
  if (cancelConfirmText.value !== 'HỦY') {
    triggerToast('warning', 'Vui lòng nhập "HỦY" để xác nhận!');
    return;
  }

  cancelLoading.value = true;

  try {
    const order = restaurantStore.getOrCreateOrder(selectedTableForAction.value.code);

    order.items = [];
    order.customerName = '';
    order.openedTime = '';

    const table = restaurantStore.getTableByCode(selectedTableForAction.value.code);
    if (table) {
      table.status = 'Available';
      table.customerName = '';
      table.billAmount = '';
      table.checkInTime = '';
      table.occupiedDuration = '';
    }

    triggerToast('success', `Đã hủy phiếu bàn ${selectedTableForAction.value.code}`);
    showCancelModal.value = false;
    cancelConfirmText.value = '';

    selectedTableCode.value = '';
  } catch (error) {
    triggerToast('error', error instanceof Error ? error.message : 'Hủy phiếu thất bại!');
  } finally {
    cancelLoading.value = false;
  }
}

// Exit Selection Mode
const exitSelectionMode = () => {
  selectionMode.value = 'none';
  sourceTableCode.value = '';
};

// Cancel Selection Mode
const cancelSelectionMode = () => {
  if (selectionMode.value !== 'none') {
    triggerToast('info', 'Đã hủy thao tác');
    exitSelectionMode();
  }
};

function getSelectionModeTitle(): string {
  switch(selectionMode.value) {
    case 'transfer': return `Chuyển bàn từ ${sourceTableCode.value}`;
    case 'merge': return `Ghép phiếu với bàn ${sourceTableCode.value}`;
    case 'split-order': return `Tách phiếu từ bàn ${sourceTableCode.value}`;
    case 'split-item': return `Tách món từ bàn ${sourceTableCode.value}`;
    default: return '';
  }
}

function handleTableClick(table: any) {
  if (selectionMode.value !== 'none') {
    handleTableClickInSelectionMode(table);
    return;
  }
  selectTable(table.code);
}

const closeContextMenu = () => {
  showTableContextMenu.value = false;
};

const activeMainTab = ref<"table_map" | "menu" | "invoice" | "pending">(
  selectedTableCode.value ? "menu" : "table_map",
);
const selectedArea = ref("Tất cả");

const showOtherIncomeModal = ref(false);
const showSettingsModal = ref(false);
const showMenu = ref(false);
// ===== PAYMENT METHODS STATE =====
const selectedPaymentMethod = ref("cash");
const selectedCurrency = ref("VND");
const keypadValue = ref("0");
const vipMode = ref("points_discount");
const vipCardNumber = ref("");
const cardType = ref("ATM");
const cardNumber = ref("");
const cardHolder = ref("");
const voucherCode = ref("");
const voucherType = ref("");
const voucherQty = ref(1);
const voucherError = ref("");
const couponCode = ref("");
const couponError = ref("");
const depositDate = ref("");
const depositVoucher = ref("");
const depositError = ref("");
const discountType = ref("percent");
const discountValue = ref("");
const discountReason = ref("");
const discountManager = ref("");

// New Checkout and Payment States
const serviceCharge = ref(0);
const discountBill = ref(0);
const ttdb = ref(0);
const depositAmount = ref(0);
const deliveryFee = ref(0);
const customerPaid = ref(0);

const changePaid = computed(() => {
  return Math.max(0, customerPaid.value - summary.value.grandTotal);
});

// Watch to sync keypadValue with customerPaid
watch(customerPaid, (newVal) => {
  keypadValue.value = String(newVal);
});
watch(keypadValue, (newVal) => {
  const cleanVal = parseInt(newVal.replace(/[^0-9]/g, "")) || 0;
  if (customerPaid.value !== cleanVal) {
    customerPaid.value = cleanVal;
  }
});

watch(selectedPaymentMethod, () => {
  voucherCode.value = "";
  voucherType.value = "";
  voucherQty.value = 1;
  voucherError.value = "";
});

function handleCustomerPaidInput(e: Event) {
  const target = e.target as HTMLInputElement;
  const rawValue = target.value.replace(/[^0-9]/g, "");
  customerPaid.value = rawValue ? parseInt(rawValue, 10) : 0;
}

function handleAcceptPayment() {
  customerPaid.value = summary.value.grandTotal;
  triggerToast("success", `Đã chấp nhận số tiền thanh toán: ${formatVND(customerPaid.value)}`);
}

function printKitchenCheck() {
  triggerToast("success", "Đã gửi lệnh in kiểm món!");
}

function handleDelivery() {
  triggerToast("info", "Đang xử lý giao hàng...");
}

function showHistory() {
  triggerToast("info", "Hiển thị lịch sử thao tác...");
}

function checkVoucher() {
  if (!voucherCode.value) {
    voucherError.value = "Vui lòng nhập mã thẻ voucher!";
    return;
  }
  if (voucherCode.value === "123") {
    voucherType.value = "Giảm giá 50.000đ";
    voucherError.value = "";
    triggerToast("success", "Đã tìm thấy voucher giảm giá 50.000đ!");
    discountBill.value = 50000 * voucherQty.value;
  } else {
    voucherType.value = "";
    voucherError.value = "Không tìm thấy mã giảm giá!";
  }
}

function finishOrder(printReceipt = false) {
  if (activeOrder.value.items && activeOrder.value.items.length > 0) {
    const amount = summary.value.grandTotal;
    const now = new Date();
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
    activities.value.unshift({
      id: String(activities.value.length + 1),
      time: timeStr,
      action: printReceipt ? "Thanh toán & In hóa đơn" : "Thanh toán tiền mặt",
      staff: profile.value?.full_name || "Dương Thị Mộng Mơ",
      amount: amount,
      posId: 29
    });

    // Clear items
    activeOrder.value.items = [];

    // Reset table status to empty in restaurantStore
    if (selectedTableCode.value) {
      const table = restaurantStore.getTableByCode(selectedTableCode.value);
      if (table) {
        table.status = "Available";
        table.billAmount = "";
        table.customerName = "";
      }
    }

    Swal.fire({
      title: "Thành công",
      text: printReceipt ? "Đã in hóa đơn và hoàn tất thanh toán!" : "Đã hoàn tất thanh toán thành công!",
      icon: "success",
      confirmButtonColor: "#4CAF50",
    }).then(() => {
      closePanel();
    });
  } else {
    triggerToast("warning", "Đơn hàng trống, không thể kết thúc!");
  }
}

const paymentMethods = ref([
  { id: "cash", label: "Tiền mặt", icon: "💵" },
  { id: "transfer", label: "Chuyển khoản", icon: "💳" },
  { id: "voucher", label: "Voucher", icon: "🎟️" },
  { id: "coupon", label: "Coupon", icon: "🏷️" },
  { id: "deposit", label: "Tiền cọc", icon: "💰" },
  { id: "discount", label: "Giảm phiếu", icon: "🧧" },
  { id: "vip", label: "Thẻ VIP", icon: "👑" },
]);

const keypadKeys = [
  "500",
  "1.000",
  "2.000",
  "5.000",
  "1",
  "2",
  "3",
  "10.000",
  "4",
  "5",
  "6",
  "20.000",
  "7",
  "8",
  "9",
  "50.000",
  "0",
  "00",
  "000",
  "100.000",
  "0,1",
  "0,2",
  "0,5",
  "200.000",
  ".",
  "Del",
  "OK",
  "500.000",
];

function getKeyClass(key: string): string {
  if (["Del"].includes(key)) return "bg-[#F44336] text-white";
  if (["OK"].includes(key)) return "bg-[#4CAF50] text-white";
  if (
    [
      ".",
      "500",
      "1.000",
      "2.000",
      "5.000",
      "10.000",
      "20.000",
      "50.000",
      "100.000",
      "200.000",
      "500.000",
    ].includes(key)
  )
    return "bg-[#FFB74D] text-gray-800";
  return "bg-[#1a1a1a] text-white";
}

function handleKeypad(key: string) {
  if (key === "Del") {
    const valStr = customerPaid.value.toString();
    if (valStr.length <= 1) {
      customerPaid.value = 0;
    } else {
      customerPaid.value = parseInt(valStr.slice(0, -1), 10) || 0;
    }
  } else if (key === "OK") {
    customerPaid.value = summary.value.grandTotal;
    triggerToast("success", `Đã xác nhận khách đưa: ${formatVND(customerPaid.value)}`);
  } else if (key === ".") {
    // Ignore decimal for VND
  } else if (
    ["500", "1.000", "2.000", "5.000", "10.000", "20.000", "50.000", "100.000", "200.000", "500.000"].includes(key)
  ) {
    const val = parseInt(key.replace(/\./g, ""), 10);
    customerPaid.value += val;
  } else {
    let valStr = customerPaid.value === 0 ? "" : customerPaid.value.toString();
    valStr += key;
    customerPaid.value = parseInt(valStr, 10) || 0;
  }
}

// ===== VIP FUNCTIONS =====
function checkVIP() {
  if (!vipCardNumber.value) {
    triggerToast("warning", "Vui lòng nhập số thẻ VIP!");
    return;
  }
  triggerToast("info", `Đang kiểm tra thẻ VIP: ${vipCardNumber.value}`);
}

function applyVIP() {
  if (!vipCardNumber.value) {
    triggerToast("warning", "Vui lòng nhập số thẻ VIP!");
    return;
  }
  triggerToast("success", `Đã áp dụng thẻ VIP: ${vipCardNumber.value}`);
}

function clearVIP() {
  vipCardNumber.value = "";
  triggerToast("info", "Đã xoá thông tin VIP");
}

function applyDiscount() {
  if (!discountValue.value) {
    triggerToast("warning", "Vui lòng nhập giá trị giảm!");
    return;
  }
  triggerToast(
    "success",
    `Đã áp dụng giảm ${discountValue.value}${discountType.value === "percent" ? "%" : "đ"}`,
  );
}

const menuItems = ref([
  {
    id: "menu",
    label: "Thực đơn",
    icon: "🍽️",
    colorClass: "color-green",
    action: "openMenu",
  },
  {
    id: "transfer",
    label: "Chuyển bàn",
    icon: "🔄",
    colorClass: "color-orange",
    action: "transferTable",
  },
  {
    id: "merge",
    label: "Ghép phiếu",
    icon: "🔗",
    colorClass: "color-orange",
    action: "mergeOrders",
  },
  {
    id: "split-order",
    label: "Tách phiếu",
    icon: "✂️",
    colorClass: "color-orange",
    action: "splitOrder",
  },
  {
    id: "split-item",
    label: "Tách món",
    icon: "🥞",
    colorClass: "color-orange",
    action: "splitItem",
  },
  {
    id: "reprint",
    label: "In lại bếp",
    icon: "🖨️",
    colorClass: "color-purple",
    action: "reprintKitchen",
  },
  {
    id: "welcome",
    label: "Tiếp khách",
    icon: "🤝",
    colorClass: "color-red-orange",
    action: "welcomeGuest",
  },
  {
    id: "cancel",
    label: "Huỷ phiếu",
    icon: "🗑️",
    colorClass: "color-red",
    action: "cancelOrder",
  },
]);

const handleMenuClick = (item: any) => {
  showMenu.value = false;
  switch (item.action) {
    case "openMenu":
      activeMainTab.value = "menu";
      break;
    case "transferTable":
      Swal.fire({
        title: "Chuyển bàn",
        text: "Chức năng Chuyển bàn: Chọn bàn muốn chuyển đến từ sơ đồ bàn.",
        icon: "info",
        confirmButtonColor: "#FF9800",
      });
      break;
    case "mergeOrders":
      Swal.fire({
        title: "Ghép phiếu",
        text: "Chức năng Ghép phiếu: Chọn các bàn cần ghép hóa đơn.",
        icon: "info",
        confirmButtonColor: "#FF9800",
      });
      break;
    case "splitOrder":
      Swal.fire({
        title: "Tách phiếu",
        text: "Chức năng Tách phiếu: Chia hóa đơn hiện tại thành nhiều phiếu thanh toán.",
        icon: "info",
        confirmButtonColor: "#FF9800",
      });
      break;
    case "splitItem":
      Swal.fire({
        title: "Tách món",
        text: "Chức năng Tách món: Chọn các món cần tách sang phiếu mới.",
        icon: "info",
        confirmButtonColor: "#FF9800",
      });
      break;
    case "reprintKitchen":
      Swal.fire({
        title: "In lại bếp",
        text: "Yêu cầu in lại order gửi bếp thành công!",
        icon: "success",
        confirmButtonColor: "#9C27B0",
      });
      break;
    case "welcomeGuest":
      Swal.fire({
        title: "Tiếp khách",
        text: "Tiếp nhận khách hàng mới vào bàn thành công.",
        icon: "success",
        confirmButtonColor: "#E57373",
      });
      break;
    case "cancelOrder":
      Swal.fire({
        title: "Xác nhận hủy phiếu?",
        text: "Bạn có chắc chắn muốn hủy phiếu order của bàn này không? Hành động này không thể hoàn tác.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Đồng ý hủy",
        cancelButtonText: "Bỏ qua",
        confirmButtonColor: "#F44336",
      }).then((result) => {
        if (result.isConfirmed) {
          activeOrder.value.items = [];
          Swal.fire("Đã hủy", "Hóa đơn đã được hủy sạch.", "success");
        }
      });
      break;
  }
};
const settingsUsername = ref("mo");
const settingsPassword = ref("");

const handleSaveSettings = () => {
  Swal.fire({
    title: "Thành công",
    text: `Đã cập nhật cấu hình cho tài khoản ${settingsUsername.value}!`,
    icon: "success",
    confirmButtonText: "Đóng",
    confirmButtonColor: "#4DB6AC",
  });
  showSettingsModal.value = false;
};
const creator = ref("Dương Thị Mộng");
const createdDate = ref("02/07/2026 15:08:41");

const form = ref({
  object: "",
  incomeType: "other",
  incomeItem: "withdraw",
  amount: 0,
  reason: "",
  voucherNumber: "",
  bookingCode: "",
  isCash: true,
});

const formattedAmount = computed(() => {
  if (!form.value.amount) return "";
  return Number(form.value.amount).toLocaleString("vi-VN");
});

const handleAmountInput = (e: Event) => {
  const target = e.target as HTMLInputElement;
  const rawValue = target.value.replace(/[^0-9]/g, "");
  form.value.amount = rawValue ? parseInt(rawValue, 10) : 0;
};

const triggerSelectObject = () => {
  form.value.object = "Khách vãng lai";
  triggerToast("info", "Đã tự động chọn Đối tượng: Khách vãng lai");
};

const handleSaveAndPrint = () => {
  if (!form.value.object) {
    triggerToast("error", "Vui lòng nhập Đối tượng!");
    return;
  }
  if (!form.value.amount) {
    triggerToast("error", "Vui lòng nhập Số tiền thu!");
    return;
  }
  Swal.fire({
    title: "Thành công",
    text: `Đã lưu và in phiếu thu cho ${form.value.object} với số tiền ${Number(form.value.amount).toLocaleString("vi-VN")}đ!`,
    icon: "success",
    confirmButtonText: "Đóng",
    confirmButtonColor: "#4CAF50",
  });
  showOtherIncomeModal.value = false;
};

const handleSave = () => {
  if (!form.value.object) {
    triggerToast("error", "Vui lòng nhập Đối tượng!");
    return;
  }
  if (!form.value.amount) {
    triggerToast("error", "Vui lòng nhập Số tiền thu!");
    return;
  }
  Swal.fire({
    title: "Thành công",
    text: `Đã lưu thành công phiếu thu của ${form.value.object}!`,
    icon: "success",
    confirmButtonText: "Đóng",
    confirmButtonColor: "#FF9800",
  });
  showOtherIncomeModal.value = false;
};

const tableAreas = computed(() => {
  const baseAreas = [
    { id: "catalog", name: "Catalog", total: 0, stats: null },
    { id: "A", name: "Khu A", total: 2300000, stats: { bills: 3, guests: 16 } },
    { id: "B", name: "Khu B", total: 4200000, stats: { bills: 1, guests: 10 } },
    { id: "C", name: "Khu C", total: 890000, stats: { bills: 2, guests: 8 } },
    { id: "R", name: "Khu R", total: 8100000, stats: { bills: 2, guests: 18 } },
    { id: "T", name: "Khu T", total: 1200000, stats: { bills: 2, guests: 8 } },
    { id: "capichi", name: "Capichi", total: 0, stats: null },
    { id: "shoppe", name: "Shoppe", total: 0, stats: null },
    { id: "garb", name: "Garb", total: 0, stats: null },
    { id: "BE", name: "BE", total: 0, stats: null },
    { id: "all", name: "Tất cả", total: 16690000, stats: null },
  ];

  restaurantStore.areas.forEach((area) => {
    let total = 0;
    let bills = 0;
    let guests = 0;
    area.tables.forEach((table) => {
      if (table.status === "Serving" || table.status === "Arrived") {
        bills++;
        const amtStr = (table.billAmount || "").replace(/[^0-9]/g, "");
        if (amtStr) {
          total += parseInt(amtStr, 10);
        }
        guests += table.capacity || 2;
      }
    });

    const match = baseAreas.find((b) => b.name === area.name);
    if (match) {
      if (total > 0) {
        match.total = total;
        match.stats = { bills, guests };
      }
    }
  });

  const allArea = baseAreas.find((b) => b.id === "all");
  if (allArea) {
    allArea.total = baseAreas.reduce(
      (sum, a) => (a.id !== "all" ? sum + a.total : sum),
      0,
    );
  }

  return baseAreas;
});

const currentClock = ref(new Date());
let clockInterval: any;

const formattedTime = computed(() => {
  return currentClock.value.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
});

const formattedDate = computed(() => {
  return currentClock.value.toLocaleDateString("vi-VN");
});

const printCount = ref(3);
const currentTime = computed(() => activeOrder.value.openedTime || "02/07/2026 14:09");

const pendingCount = ref(3);
const pendingOrders = ref([
  {
    id: "CN3126070200014",
    tableCode: "A04",
    customerName: "Trần Văn An",
    time: "02/07/2026 14:09",
    itemsSummary: "Mì udon xào cùng thịt bò (1), Cơm Bibimbap (1)",
    totalAmount: 342000,
  },
  {
    id: "CN3126070200015",
    tableCode: "A08",
    customerName: "Nguyễn Thị Bình",
    time: "02/07/2026 14:15",
    itemsSummary: "Lunch - Set Bò Cao Cấp (2)",
    totalAmount: 518000,
  },
  {
    id: "CN3126070200016",
    tableCode: "B02",
    customerName: "Lê Văn Cường",
    time: "02/07/2026 14:22",
    itemsSummary: "Sét Oyakodon (1), Pepsi (2)",
    totalAmount: 159000,
  },
]);
const handleProcessPending = (order: any) => {
  selectedTableCode.value = order.tableCode;
  activeMainTab.value = "menu";
  triggerToast("success", `Đang xử lý đơn hàng bàn ${order.tableCode}`);
};

const showSearch = ref(false);
const tableSearchQuery = ref("");
const showMoreMenu = ref(false);

const orderGroups = ref([
  {
    id: "g1",
    datetime: "02/07/2026 - 14:09",
    code: "CN31-1-001",
    customer: "Khách vãng lai",
    printCount: 0,
    items: [
      {
        id: "i1",
        name: "Vé Người Lớn 1380",
        image:
          "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=80&auto=format&fit=crop&q=60",
        status: "hiện",
        price: 1380000,
        kitchen: "QUẦY LỄ TÂN - In: 1",
        quantity: 1,
        unit: "Vé",
        waitTime: 47,
        checked: false,
      },
    ],
  },
  {
    id: "g2",
    datetime: "02/07/2026 - 14:10",
    code: "CN31-1-002",
    customer: "Khách vãng lai",
    printCount: 1,
    items: [
      {
        id: "i2",
        name: "Mì udon xào cùng thịt bò - Lunch",
        image:
          "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=80&auto=format&fit=crop&q=60",
        status: "hiện",
        price: 129000,
        kitchen: "BẾP NÓNG - CHECK BẾP NÓNG - In: 1",
        quantity: 1,
        unit: "Phần",
        waitTime: 46,
        checked: false,
      },
    ],
  },
]);

interface ActivityLog {
  id: string;
  time: string;
  action: string;
  staff: string;
  amount: number;
  posId: number;
  code?: string;
}

const activities = ref<ActivityLog[]>([
  {
    id: "1",
    time: "14:59:22",
    action: "In bill tạm tính",
    staff: "mo",
    amount: 69660,
    posId: 29,
  },
  {
    id: "2",
    time: "14:58:47",
    action: "Xóa chi tiết thanh toán",
    staff: "Dương Thị Mộng Mơ",
    amount: 69660,
    posId: 29,
  },
  {
    id: "3",
    time: "14:58:38",
    action: "Thanh toán tiền mặt",
    staff: "Dương Thị Mộng Mơ",
    amount: 69660,
    posId: 29,
  },
  {
    id: "4",
    time: "14:33:30",
    action: "In bill tạm tính",
    staff: "mo",
    amount: 69660,
    posId: 29,
  },
  {
    id: "5",
    time: "14:10:46",
    action: "In bill tạm tính",
    staff: "mo",
    amount: 69660,
    posId: 29,
  },
  {
    id: "6",
    time: "14:10:41",
    action: "Giảm giá",
    staff: "Dương Thị Mộng Mơ",
    amount: 69660,
    posId: 29,
  },
  {
    id: "7",
    time: "14:10:09",
    action: "Gửi order",
    staff: "Dương Thị Mộng Mơ",
    amount: 139320,
    posId: 29,
  },
]);

const handleRemindKitchen = () => {
  const checkedItems = orderGroups.value
    .flatMap((g) => g.items)
    .filter((i) => i.checked);
  if (checkedItems.length === 0) {
    triggerToast("warning", "Vui lòng chọn ít nhất một món để nhắc bếp!");
    return;
  }
  triggerToast(
    "success",
    `Đã gửi yêu cầu nhắc bếp cho ${checkedItems.length} món ăn!`,
  );
};

const handleDeliverSelected = () => {
  const checkedItems = orderGroups.value
    .flatMap((g) => g.items)
    .filter((i) => i.checked);
  if (checkedItems.length === 0) {
    triggerToast("warning", "Vui lòng chọn ít nhất một món để giao!");
    return;
  }
  checkedItems.forEach((item) => {
    item.status = "đã giao";
  });
  triggerToast(
    "success",
    `Đã xác nhận giao ${checkedItems.length} món thành công!`,
  );
};

const openSettings = () => {
  showSettingsModal.value = true;
  showMoreMenu.value = false;
};
const openShortcuts = () => {
  triggerToast("info", "Mở danh sách phím tắt");
  showMoreMenu.value = false;
};
const openHelp = () => {
  triggerToast("info", "Mở tài liệu trợ giúp");
  showMoreMenu.value = false;
};
const openAbout = () => {
  triggerToast("info", "Ngưu Cát POS v1.0.0");
  showMoreMenu.value = false;
};
const logout = () => {
  triggerToast("error", "Đăng xuất khỏi hệ thống");
  showMoreMenu.value = false;
};
const closePanel = () => {
  selectedTableCode.value = "";
  activeMainTab.value = "table_map";
};
const openTableSettings = () => {
  triggerToast(
    "info",
    "Cấu hình thông tin bàn " + (selectedTableCode.value || ""),
  );
};

const isOpen = ref(false);
const selectedFilter = ref("all");

const showAreaSelector = ref(false);

const selectAreaName = (name: string) => {
  selectedArea.value = name;
  showAreaSelector.value = false;
};

const filters = [
  { value: "all", label: "Tất cả", color: "#FFFFFF", textColor: "#333" },
  { value: "empty", label: "Trống", color: "#9E9E9E", textColor: "#fff" },
  { value: "occupied", label: "Có khách", color: "#FFB74D", textColor: "#333" },
  {
    value: "pending",
    label: "Chưa gửi order",
    color: "#4DB6AC",
    textColor: "#fff",
  },
  { value: "printed", label: "Đã in", color: "#E57373", textColor: "#fff" },
  {
    value: "multi-print",
    label: "In nhiều lần",
    color: "#BA68C8",
    textColor: "#fff",
  },
  {
    value: "multi-bill",
    label: "Nhiều phiếu",
    color: "#5C6BC0",
    textColor: "#fff",
  },
];

const currentFilter = computed(
  () => filters.find((f) => f.value === selectedFilter.value) || filters[0],
);

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
};

const applyFilter = (filter: any) => {
  selectedFilter.value = filter.value;
  isOpen.value = false;
};

const dropdownRef = ref<HTMLElement | null>(null);
const areaDropdownRef = ref<HTMLElement | null>(null);

const handleDropdownClickOutside = (e: MouseEvent) => {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
    isOpen.value = false;
  }
};

const handleAreaClickOutside = (e: MouseEvent) => {
  if (
    areaDropdownRef.value &&
    !areaDropdownRef.value.contains(e.target as Node)
  ) {
    showAreaSelector.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleDropdownClickOutside);
  document.addEventListener("click", handleAreaClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleDropdownClickOutside);
  document.removeEventListener("click", handleAreaClickOutside);
});

const filteredTables = computed(() => {
  const list: any[] = [];
  const query = tableSearchQuery.value.trim().toLowerCase();
  const filter = selectedFilter.value;

  restaurantStore.areas.forEach((area) => {
    if (selectedArea.value === "Tất cả" || area.name === selectedArea.value) {
      area.tables.forEach((table) => {
        const codeMatch = table.code.toLowerCase().includes(query);
        const nameMatch = (table.customerName || "")
          .toLowerCase()
          .includes(query);
        const billMatch = (table.billAmount || "")
          .toLowerCase()
          .includes(query);
        const queryMatches = !query || codeMatch || nameMatch || billMatch;

        if (!queryMatches) return;

        let filterMatches = true;
        switch (filter) {
          case "empty":
            filterMatches = table.status === "Available";
            break;
          case "occupied":
            filterMatches =
              table.status === "Serving" || table.status === "Arrived";
            break;
          case "pending":
            filterMatches = table.status === "Arrived";
            break;
          case "printed":
            filterMatches = table.status === "Serving" && table.capacity === 4;
            break;
          case "multi-print":
            filterMatches = table.status === "Serving" && table.capacity !== 4;
            break;
          case "multi-bill":
            filterMatches = table.status === "Reserved";
            break;
          case "all":
          default:
            filterMatches = true;
            break;
        }

        if (filterMatches) {
          list.push({
            ...table,
            areaName: area.name,
          });
        }
      });
    }
  });
  return list;
});

function getTableStatusClass(table: any): string {
  if (table.status === "Serving") {
    return "bg-emerald-950/40 border-emerald-800 text-emerald-300 hover:bg-emerald-900/30";
  } else if (table.status === "Arrived") {
    return "bg-green-950/40 border-green-800 text-green-300 hover:bg-green-900/30";
  } else if (table.status === "Reserved") {
    return "bg-red-950/40 border-red-900/50 text-red-400 hover:bg-red-900/30";
  } else if (table.status === "pending_payment") {
    return "bg-amber-950/40 border-amber-900/50 text-amber-400 hover:bg-amber-900/30";
  } else {
    return "bg-gray-800/40 border-gray-700 text-gray-400 hover:bg-gray-700/30";
  }
}

function selectTable(code: string) {
  selectedTableCode.value = code;
}

function calculateNetPrice(item: any): number {
  const inPackage = isItemInPackage(item, activeSettings.value.package);
  const price = inPackage ? 0 : item.price;
  const isLunch = item.name.toLowerCase().includes("lunch");
  const discount = isLunch ? price * 0.5 : 0;
  const base = price - discount;
  const vat = base * 0.08;
  return Math.round(base + vat) * item.quantity;
}

function getMenuItemFromCartItem(item: any): MenuItem {
  for (const cat of menuData.categories) {
    if (cat.items) {
      const match = cat.items.find((i) => i.id === item.id);
      if (match) return match;
    }
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        const match = sub.items.find((i) => i.id === item.id);
        if (match) return match;
      }
    }
  }
  return {
    id: item.id,
    name: item.name.split(" [")[0],
    unit: item.unit || t("reception_order.ve"),
    price: item.price,
    price_display: formatVND(item.price),
    category_id: item.category_id || "",
  };
}

function formatPrice(price: number): string {
  if (price === 0) return t("reception_order.0d");
  if (price >= 1000) {
    return `${Math.round(price / 1000).toLocaleString("vi-VN")}K`;
  }
  return `${price}đ`;
}

// Multilingual translations map
const uiTranslations = {
  VI: {
    table: t("reception_order.ban_text"),
    guests: t("reception_order.khach_text"),
    time: t("reception_order.gio_mo_text"),
    timeLeft: t("reception_order.con_lai_text"),
    subtotal: t("reception_order.tam_tinh_text"),
    vat: t("reception_order.thue_gtgt_10_text"),
    serviceCharge: t("reception_order.phi_phuc_vu_text"),
    grandTotal: t("reception_order.tong_cong_text"),
    checkout: t("reception_order.thanh_toan_text"),
    draftPrint: t("reception_order.xem_tam_tinh_text"),
    emptyCart: t("reception_order.gio_hang_trong_text"),
    emptyCartSub: t("reception_order.hay_chon_mon_tu_menu_text"),
    outOfStock: t("reception_order.het_hang_text"),
    favorites: t("reception_order.mon_yeu_thich_text"),
    recent: t("reception_order.moi_goi_text"),
    popular: t("reception_order.ban_chay_text"),
    searchPlaceholder: t("reception_order.tim_mon_an_theo_ten_text"),
    available: t("reception_order.con_hang_text"),
    unavailable: t("reception_order.het_hang_text"),
    all: t("reception_order.tat_ca_text"),
    back: t("reception_order.quay_lai_text"),
    saveOrder: t("reception_order.luu_thay_doi_text"),
    holdOrder: t("reception_order.tam_luu_text"),
    sendKitchen: t("reception_order.gui_vao_bep_text"),
    cancelChanges: t("reception_order.huy_thay_doi_text"),
    courseLocked: t("reception_order.khoa_course_text"),
    guestWalkIn: t("reception_order.khach_vang_lai_text"),
    courseLockedSuccess: t("reception_order.khoa_course_thanh_cong"),
  },
  EN: {
    table: "Table",
    guests: "Guests",
    time: "Open Time",
    timeLeft: "remaining",
    subtotal: "Subtotal",
    vat: "VAT (10%)",
    serviceCharge: "Service Charge",
    grandTotal: "GRAND TOTAL",
    checkout: "Checkout",
    draftPrint: "Draft Bill",
    emptyCart: "Cart is empty",
    emptyCartSub: "Select items from the menu to start ordering",
    outOfStock: "Sold Out",
    favorites: "Favorites",
    recent: "Recent",
    popular: "Popular",
    searchPlaceholder: "Search items by name...",
    available: "Available",
    unavailable: "Sold Out",
    all: "All",
    back: "Back",
    saveOrder: "Save Order",
    holdOrder: "Hold",
    sendKitchen: "Send to Kitchen",
    cancelChanges: "Cancel Changes",
    courseLocked: "Course Locked",
    guestWalkIn: "Walk-in Guest",
    courseLockedSuccess: "Course locked successfully.",
  },
  JP: {
    table: "テーブル",
    guests: "人数",
    time: "開始時間",
    timeLeft: "残り時間",
    subtotal: "小計",
    vat: "消費税 (10%)",
    serviceCharge: "サービス料",
    grandTotal: "合計金額",
    checkout: "お会計",
    draftPrint: "計算書印刷",
    emptyCart: "カートは空です",
    emptyCartSub: "メニューから商品を選択してください",
    outOfStock: "売り切れ",
    favorites: "お気に入り",
    recent: "履歴",
    popular: "人気メニュー",
    searchPlaceholder: "メニュー検索...",
    available: "注文可能",
    unavailable: "売り切れ",
    all: "全て",
    back: "戻る",
    saveOrder: "注文保存",
    holdOrder: "一時保留",
    sendKitchen: "厨房へ送信",
    cancelChanges: "変更取消",
    courseLocked: "コースロック",
    guestWalkIn: "ウォークインゲスト",
    courseLockedSuccess: "コースが正常にロックされました。",
  },
  KO: {
    table: "테이블",
    guests: "인원수",
    time: "시작 시간",
    timeLeft: "남은 시간",
    subtotal: "소계",
    vat: "부가세 (10%)",
    serviceCharge: "봉사료",
    grandTotal: "총합계",
    checkout: "결제하기",
    draftPrint: "가영수증",
    emptyCart: "장바구니가 비어 있습니다",
    emptyCartSub: "오른쪽 메뉴에서 품목을 선택하십시오",
    outOfStock: "품절",
    favorites: "즐겨찾기",
    recent: "최근 주문",
    popular: "인기 메뉴",
    searchPlaceholder: "메뉴 검색...",
    available: "주문 가능",
    unavailable: "품절",
    all: "전체",
    back: "이전",
    saveOrder: "주문 저장",
    holdOrder: "보류",
    sendKitchen: "주방으로 전송",
    cancelChanges: "변경 취소",
    courseLocked: "코스 잠금",
    guestWalkIn: "워크인 고객",
    courseLockedSuccess: "코스가 성공적으로 잠금 처리되었습니다.",
  },
  ZH: {
    table: "桌号",
    guests: "人数",
    time: "开台时间",
    timeLeft: "剩余时间",
    subtotal: "小计",
    vat: "增值税 (10%)",
    serviceCharge: "服务费",
    grandTotal: "总金额",
    checkout: "结账",
    draftPrint: "预结单",
    emptyCart: "购物车为空",
    emptyCartSub: "请从右侧菜单中选择菜品",
    outOfStock: "售罄",
    favorites: "收藏夹",
    recent: "最近点餐",
    popular: "热销推荐",
    searchPlaceholder: "搜索菜品...",
    available: "有货",
    unavailable: "售罄",
    all: "全部",
    back: "返回",
    saveOrder: "保存订单",
    holdOrder: "挂单",
    sendKitchen: "传菜下厨",
    cancelChanges: "取消修改",
    courseLocked: "已锁套餐",
    guestWalkIn: "散客",
    courseLockedSuccess: "套餐锁定成功。",
  },
};

// Course package pricing scaling
const packagePrices: Record<string, number> = {
  "Buffet 1390": 1380000,
  "Buffet 1150": 1150000,
  "Buffet 680": 680000,
  "Buffet 490": 490000,
  "Buffet 380": 380000,
  "Biz 1200": 1200000,
  "Biz 900": 900000,
  "Biz 700": 700000,
  "Kids Meal": 150000,
};

// Persistent session table course settings dictionary
const tableSettings = ref<
  Record<
    string,
    { package: string; drinkGroup: string; language: string; isLocked: boolean }
  >
>({});

function ensureTableSettings(code: string) {
  if (!tableSettings.value[code]) {
    tableSettings.value[code] = {
      package: "",
      drinkGroup: "A",
      language: "VI",
      isLocked: false,
    };
  }
}

const activeSettings = computed(() => {
  const code = selectedTableCode.value;
  if (!code)
    return { package: "", drinkGroup: "A", language: "VI", isLocked: false };
  if (!tableSettings.value[code]) {
    tableSettings.value[code] = {
      package: "",
      drinkGroup: "A",
      language: "VI",
      isLocked: false,
    };
  }
  return tableSettings.value[code];
});

// Selected course price
const selectedPackagePrice = computed(() => {
  const pkg = activeSettings.value.package;
  return packagePrices[pkg] || 0;
});

// System Toast Queue state
interface Toast {
  id: number;
  type: "success" | "warning" | "error" | "info";
  message: string;
}
const toasts = ref<Toast[]>([]);
let toastIdCounter = 0;
// Track every pending auto-dismiss timer so we can clear them on unmount;
// otherwise a router push right after `triggerToast` would leave the toast
// mutating `toasts.value` after the component is gone.
const toastTimers = new Set<number>()

function triggerToast(
  type: "success" | "warning" | "error" | "info",
  message: string,
) {
  const id = toastIdCounter++;
  toasts.value.push({ id, type, message });
  const handle = window.setTimeout(() => {
    toasts.value = toasts.value.filter((t) => t.id !== id);
  }, 3000);
  toastTimers.add(handle);
}

function clearToastTimers() {
  for (const h of toastTimers) clearTimeout(h)
  toastTimers.clear()
}

// Left cart collapsing triggers
const isCartOpen = ref(true);

// Menu State filters
const searchQuery = ref("");
const activeCategoryId = ref("buffet");
const activeSubCategoryId = ref("all");
const activeQuickFilter = ref<"favorites" | "popular" | "recent" | "">("");
const activeStatusFilter = ref<"all" | "available" | "unavailable">("all");
const priceSort = ref<"asc" | "desc" | "">("");
const showOnlyPackageItems = ref(false);
const isGridLoading = ref(false);
const favoriteIds = ref<string[]>([]);

// Session Timer ticking state
const timerSecondsLeft = ref(7200);
let timerInterval: number | null = null;

// Temporary Course configurations during modal usage
const isPackageModalOpen = ref(false);
const tempSettings = ref({
  package: "",
  drinkGroup: "A",
  language: "VI",
});

// Manager PIN pad authentications state
const isPinModalOpen = ref(false);
const enteredPin = ref("");

// Product details popup state
const isDetailPanelOpen = ref(false);
const selectedProductForDetail = ref<MenuItem | null>(null);
const modalItemQty = ref(1);
const modalItemNote = ref("");
const modalVAT = ref(true);
const modalPPV = ref(false);
const modalCurrency = ref("VND");
const modalRate = ref("1");

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
const activeOptionTab = ref("");

const activeGroup = computed(() => {
  if (tempOptionGroups.value.length === 0) return null;
  return (
    tempOptionGroups.value.find((g) => g.id === activeOptionTab.value) ||
    tempOptionGroups.value[0]
  );
});

const activeGroupSelectedCount = computed(() => {
  if (!activeGroup.value) return 0;
  return activeGroup.value.options.reduce((sum, opt) => sum + opt.quantity, 0);
});

const isSelectionValid = computed(() => {
  if (tempOptionGroups.value.length === 0) return true;
  return tempOptionGroups.value.every((group) => {
    const count = group.options.reduce((sum, opt) => sum + opt.quantity, 0);
    return count >= group.minSelection && count <= group.maxSelection;
  });
});

function getMockOptionsForItem(itemId: string): OptionGroup[] {
  if (
    itemId.includes("lau") ||
    itemId.includes("sukiyaki") ||
    itemId.includes("broth")
  ) {
    return [
      {
        id: "broth_group",
        title: t("reception_order.nuoc_lau_di_kem"),
        minSelection: 2,
        maxSelection: 2,
        options: [
          {
            id: "opt_sukiyaki",
            name: t("reception_order.lau_sukiyaki_ngot_thanh"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "opt_kimchi",
            name: t("reception_order.lau_kimchi_chua_cay"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "opt_mala",
            name: t("reception_order.lau_mala_tu_xuyen"),
            price: 30000,
            quantity: 0,
            note: "",
          },
          {
            id: "opt_mushroom",
            name: t("reception_order.lau_nam_thao_duoc"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "opt_soy",
            name: t("reception_order.lau_sua_dau_nanh"),
            price: 20000,
            quantity: 0,
            note: "",
          },
        ],
      },
    ];
  }

  if (
    itemId.includes("ticket") ||
    itemId.includes("buffet") ||
    itemId.includes("course")
  ) {
    return [
      {
        id: "soup_group",
        title: t("reception_order.chon_nuoc_lau_goi_buffet"),
        minSelection: 1,
        maxSelection: 1,
        options: [
          {
            id: "bf_suki",
            name: t("reception_order.lau_sukiyaki_tieu_chuan"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "bf_kimchi",
            name: t("reception_order.lau_kimchi_han_quoc"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "bf_mushroom",
            name: t("reception_order.lau_nam_thao_moc"),
            price: 0,
            quantity: 0,
            note: "",
          },
        ],
      },
      {
        id: "gift_group",
        title: t("reception_order.chon_mon_tang_kem"),
        minSelection: 0,
        maxSelection: 2,
        options: [
          {
            id: "gift_beef",
            name: t("reception_order.than_vai_bo_uc"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "gift_beer",
            name: t("reception_order.lon_bia_sapporo"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "gift_salad",
            name: t("reception_order.dia_salad_bap_cai"),
            price: 0,
            quantity: 0,
            note: "",
          },
        ],
      },
    ];
  }

  if (itemId.includes("lunch") || itemId.includes("set")) {
    return [
      {
        id: "lunch_side",
        title: t("reception_order.mon_an_kem_chon_1"),
        minSelection: 1,
        maxSelection: 1,
        options: [
          {
            id: "side_soup",
            name: t("reception_order.canh_rong_bien"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "side_kimchi",
            name: t("reception_order.dia_kimchi_cai_thao"),
            price: 0,
            quantity: 0,
            note: "",
          },
          {
            id: "side_tea",
            name: t("reception_order.ly_hong_tra"),
            price: 0,
            quantity: 0,
            note: "",
          },
        ],
      },
    ];
  }

  return [];
}

// Active table order
const activeTableArea = computed(() => {
  if (!selectedTableCode.value) return t("reception_order.khu_vuc");
  return restaurantStore.getTableAreaName(selectedTableCode.value);
});

const activeOrder = computed(() => {
  if (!selectedTableCode.value) {
    return {
      orderNumber: "",
      tableCode: "",
      customerName: "",
      guestCount: 0,
      openedTime: "",
      items: [],
    };
  }
  return restaurantStore.getOrCreateOrder(selectedTableCode.value);
});

const allTables = computed(() => {
  const list: { code: string; label: string }[] = [];
  restaurantStore.areas.forEach((area) => {
    area.tables.forEach((table) => {
      list.push({
        code: table.code,
        label: `${area.name} - ${table.code}`,
      });
    });
  });
  return list;
});

const activeTableStatus = computed(() => {
  const code = selectedTableCode.value;
  if (!code) return t("reception_order.trong_text");
  const tbl = restaurantStore.getTableByCode(code);
  if (!tbl) return t("reception_order.trong_text");
  if (tbl.status === "Available") return t("reception_order.trong_text");
  if (tbl.status === "Reserved") return t("reception_order.da_dat_text");
  if (tbl.status === "Arrived") return t("reception_order.khach_den_text");
  if (tbl.status === "Serving") return t("reception_order.dang_an_text");
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
  }
},
{ immediate: true }
);

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
    const timePart = openedTimeStr.split(" ")[0] || "";
    const datePart = openedTimeStr.split(" ")[1] || "";

    const now = new Date();
    const openDate = new Date();

    if (timePart.includes(":")) {
      const [h, m] = timePart.split(":").map(Number);
      openDate.setHours(h, m, 0, 0);
    }
    if (datePart.includes("/")) {
      const [d, mo, y] = datePart.split("/").map(Number);
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
  if (s <= 0) return "00:00:00";
  const hrs = Math.floor(s / 3600);
  const mins = Math.floor((s % 3600) / 60);
  const secs = s % 60;
  return `${String(hrs).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
});

// Watch countdown to show warnings
watch(timerSecondsLeft, (newVal) => {
  if (newVal === 1799) {
    // 30 mins left
    triggerToast("warning", t("reception_order.thoi_gian_an_con_lai_30_phut"));
  } else if (newVal === 599) {
    // 10 mins left
    triggerToast("error", t("reception_order.thoi_gian_sap_het_10_phut"));
  } else if (newVal === 0) {
    triggerToast("error", t("reception_order.phien_an_2_gio_da_ket_thuc"));
  }
});

// Helper to look up an item's subcategory ID from menuData
function getItemSubcategoryId(itemId: string): string {
  for (const cat of menuData.categories) {
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        if (sub.items.some((i) => i.id === itemId)) {
          return sub.id;
        }
      }
    }
  }
  return "";
}

// Check if item is included in package
function isItemInPackage(
  item: { category_id: string; id: string },
  packageName: string,
): boolean {
  if (!packageName) return false;

  const subCatId = getItemSubcategoryId(item.id);
  const parentCatId = item.category_id;

  // Surcharges (category: khac, subcategory: surcharge) are never included in packages
  if (parentCatId === "khac" && subCatId === "surcharge") return false;

  // Standard buffet-eligible menus
  const isEligibleMenu =
    parentCatId === "thuc_an" ||
    parentCatId === "thuc_uong" ||
    parentCatId === "thuc_uong_co_con" ||
    parentCatId === "buffet";

  if (packageName === "Kids Meal") {
    return (
      item.id.includes("kids") ||
      item.id.includes("egg") ||
      item.id.includes("fries") ||
      subCatId === "dessert" ||
      parentCatId === "dessert"
    );
  }

  if (packageName === "Buffet 1390") {
    return isEligibleMenu;
  }

  if (packageName === "Buffet 1150") {
    const isWagyu = item.id.includes("wagyu") || subCatId === "wagyu";
    return isEligibleMenu && !isWagyu;
  }

  if (packageName === "Buffet 680") {
    const isWagyu = item.id.includes("wagyu") || subCatId === "wagyu";
    const isPremiumBeef =
      item.id.includes("premium") ||
      item.id.includes("sirloin") ||
      item.id.includes("short_ribs") ||
      item.id.includes("tongue") ||
      subCatId === "beef_tongue";
    return isEligibleMenu && !isWagyu && !isPremiumBeef;
  }

  if (packageName === "Buffet 490" || packageName === "Buffet 380") {
    const isBeef =
      item.id.includes("beef") ||
      item.id.includes("wagyu") ||
      item.id.includes("tongue") ||
      subCatId === "beef" ||
      subCatId === "wagyu" ||
      subCatId === "beef_tongue";
    const isAlcohol =
      parentCatId === "thuc_uong_co_con" ||
      ["beer", "whisky", "shochu", "nihonshuu", "wine", "alcohol_set"].includes(
        subCatId,
      );

    return (
      isEligibleMenu &&
      !isBeef &&
      !isAlcohol &&
      (subCatId === "pork" ||
        subCatId === "chicken" ||
        subCatId === "soft_drink" ||
        subCatId === "tea" ||
        subCatId === "non_alcoholic" ||
        subCatId === "appetizer" ||
        subCatId === "salad" ||
        subCatId === "rice" ||
        subCatId === "noodle" ||
        subCatId === "soup" ||
        subCatId === "dessert" ||
        subCatId === "sauce" ||
        subCatId === "sukiyaki" ||
        subCatId === "grill_alacarte" ||
        subCatId === "alacarte")
    );
  }

  return false;
}

// Deterministic Rich Mock Item Generator
function getEnrichedItem(item: {
  id: string;
  name: string;
  category_id: string;
  price: number;
}) {
  const code = item.id;
  const isAvailable = !(code.charCodeAt(code.length - 1) % 8 === 0); // Out of stock simulation
  const isPopular = code.charCodeAt(0) % 3 === 0;
  const isSpicy =
    code.includes("spicy") || code.includes("kimchi") || code.includes("mala");
  const isVegetarian =
    code.includes("vegetable") ||
    code.includes("salad") ||
    code.includes("tofu");

  let description =
    "Nguyên liệu tươi ngon, được sơ chế tỉ mỉ từ nhà bếp Ngưu Cát, tẩm ướp nước xốt gia truyền chuẩn vị POS.";
  if (code.includes("wagyu"))
    description =
      "Thịt bò Wagyu vân mỡ cẩm thạch thượng hạng, mềm ngọt như tan chảy trong khoang miệng khi nướng.";
  if (code.includes("sake") || code.includes("wine"))
    description =
      "Thức uống hảo hạng được khuyên dùng kèm các loại thịt bò nướng giúp kích thích vị giác.";
  if (code.includes("dessert"))
    description =
      "Món tráng miệng ngọt thanh nhẹ giúp cân bằng vị giác hoàn hảo sau khi thưởng thức thịt nướng.";

  const allergens: string[] = [];
  if (
    code.includes("udon") ||
    code.includes("noodle") ||
    code.includes("gyoza") ||
    code.includes("hamburger")
  ) {
    allergens.push("Bột mì (Gluten)");
  }
  if (
    code.includes("shrimp") ||
    code.includes("octopus") ||
    code.includes("crab") ||
    code.includes("seafood")
  ) {
    allergens.push("Hải sản (Động vật vỏ cứng)");
  }
  if (code.includes("egg")) {
    allergens.push("Lòng đỏ trứng");
  }

  const hash = code
    .split("")
    .reduce((acc, char) => acc + char.charCodeAt(0), 0);
  const calories = 80 + (hash % 380);
  const protein = 2 + (hash % 28);
  const carb = 4 + (hash % 35);
  const fat = 1 + (hash % 18);

  const emojis: Record<string, string> = {
    ticket: "🎟️",
    drink: "🍹",
    soft: "🥤",
    alcohol: "🍺",
    beer: "🍺",
    lunch: "🍱",
    bibimbap: "🍲",
    udon: "🍜",
    noodle: "🍜",
    wagyu: "🥩",
    beef: "🥩",
    tongue: "🥩",
    pork: "🥓",
    chicken: "🍗",
    shrimp: "🍤",
    octopus: "🐙",
    seafood: "🍤",
    egg: "🍳",
    salad: "🥗",
    soup: "🥣",
    dessert: "🍨",
    ice: "🍨",
    cake: "🍰",
    sauce: "🍯",
    sake: "🍶",
    wine: "🍷",
    whisky: "🥃",
  };
  let emoji = "🍽️";
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
    nutrition: { calories, protein, carb, fat },
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
  let jp = "";
  let vi = name;

  if (name.includes("(") && name.includes(")")) {
    const match = name.match(/^(.*?)\((.*?)\)(.*)$/);
    if (match) {
      const part1 = match[1].trim();
      const part2 = match[2].trim();
      if (
        part1.toLowerCase().includes("set") ||
        part1.toLowerCase().includes("buffet") ||
        part1.toLowerCase().includes("drink")
      ) {
        jp = part1;
        vi = part2;
      } else {
        jp = part1.replace(/Sét|Set/gi, "").trim();
        vi = part2;
      }
    }
  } else {
    const lower = name.toLowerCase();
    if (lower.includes("wagyu")) {
      jp = "和牛 (Wagyu)";
    } else if (lower.includes("udon")) {
      jp = "うどん (Udon)";
    } else if (lower.includes("tempura")) {
      jp = "天ぷら (Tempura)";
    } else if (lower.includes("nanban")) {
      jp = "チキン南蛮 (Chicken Nanban)";
    } else if (lower.includes("bibimbap")) {
      jp = "ビビンバ (Bibimbap)";
    } else if (lower.includes("sake")) {
      jp = "日本酒 (Sake)";
    } else if (lower.includes("shochu")) {
      jp = "焼酎 (Shochu)";
    } else if (
      lower.includes("carry") ||
      lower.includes("cà ri") ||
      lower.includes("cary")
    ) {
      jp = "カレー (Curry)";
    } else if (lower.includes("guma")) {
      jp = "群馬 (Guma)";
    } else if (lower.includes("nagasaki")) {
      jp = "長崎 (Nagasaki)";
    }
  }
  return { jp: jp || "N/A", vi: vi };
}

// Menu Hierarchy Builder (Level 1 and Level 2 Categories from actual file)
const menuHierarchy = computed(() => {
  const mainCats = menuData.categories
    .filter((c) => c.color === "pink" || c.id === "buffet")
    .map((c) => {
      let subcategories: { id: string; name: string; items: MenuItem[] }[] = [];

      if (c.id === "buffet") {
        if (c.subcategories) {
          subcategories.push(...c.subcategories);
        }

        const setDrinkCat = menuData.categories.find(
          (yc) => yc.id === "set_drink",
        );
        if (setDrinkCat && setDrinkCat.items) {
          subcategories.push({
            id: "set_drink",
            name: "SET DRINK",
            items: setDrinkCat.items,
          });
        }

        const aLaCarteCat = menuData.categories.find(
          (yc) => yc.id === "a_la_carte",
        );
        if (aLaCarteCat && aLaCarteCat.items) {
          subcategories.push({
            id: "a_la_carte",
            name: "A LA CARTE",
            items: aLaCarteCat.items,
          });
        }

        const set550jpCat = menuData.categories.find(
          (yc) => yc.id === "set_550jp",
        );
        if (set550jpCat && set550jpCat.items) {
          subcategories.push({
            id: "set_550jp",
            name: "SET 550JP",
            items: set550jpCat.items,
          });
        }

        const buffetLauCat = menuData.categories.find(
          (yc) => yc.id === "buffet_lau",
        );
        if (buffetLauCat && buffetLauCat.items) {
          subcategories.push({
            id: "buffet_lau",
            name: t("reception_order.buffet_lau_upper"),
            items: buffetLauCat.items,
          });
        }
      } else if (c.subcategories && c.subcategories.length > 0) {
        subcategories = [...c.subcategories];
      } else if (c.items) {
        subcategories = [
          {
            id: c.id + "_all",
            name: c.name,
            items: c.items,
          },
        ];
      }

      return {
        id: c.id,
        name: c.name,
        subcategories,
      };
    });

  return mainCats;
});

// Category and Subcategory tabs helpers
const activeCategoryHasSubcategories = computed(() => {
  const cat = menuHierarchy.value.find((c) => c.id === activeCategoryId.value);
  return !!(cat && cat.subcategories && cat.subcategories.length > 0);
});

const shouldShowSubcategoriesRow = computed(() => {
  const cat = menuHierarchy.value.find((c) => c.id === activeCategoryId.value);
  if (!cat || !cat.subcategories) return false;
  if (
    cat.subcategories.length === 1 &&
    cat.subcategories[0].id.endsWith("_all")
  ) {
    return false;
  }
  return cat.subcategories.length > 0;
});

const activeSubcategoriesList = computed(() => {
  const cat = menuHierarchy.value.find((c) => c.id === activeCategoryId.value);
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
  const pkgs = [
    "Buffet 1390",
    "Buffet 1150",
    "Buffet 680",
    "Buffet 490",
    "Buffet 380",
    "Kids Meal",
  ];
  const matches = pkgs.filter((p) => isItemInPackage(product, p));
  return matches.length > 0
    ? matches.join(", ")
    : t("reception_order.khong_ap_dung");
}

function getSetMenuGroup(product: MenuItem) {
  if (
    [
      "set_lunch",
      "set_tiec_chieu_dai",
      "set_tiec_chieu_dai_jp",
      "set_vietravel",
    ].includes(product.category_id)
  ) {
    return translateCategoryId(product.category_id);
  }
  return t("reception_order.khong_ap_dung");
}

function getDrinkGroup(product: MenuItem) {
  if (["thuc_uong", "thuc_uong_co_con"].includes(product.category_id)) {
    const subCat = getItemSubcategoryId(product.id);
    return (
      translateSubCategoryId(subCat) || translateCategoryId(product.category_id)
    );
  }
  return t("reception_order.khong_ap_dung");
}

// Item card filter lists
const filteredItems = computed(() => {
  const cat = menuHierarchy.value.find((c) => c.id === activeCategoryId.value);
  if (!cat) return [];

  let itemsList: MenuItem[] = [];

  if (activeSubCategoryId.value === "all") {
    cat.subcategories.forEach((sub) => {
      itemsList.push(...sub.items);
    });
  } else {
    const sub = cat.subcategories.find(
      (s) => s.id === activeSubCategoryId.value,
    );
    if (sub) {
      itemsList = [...sub.items];
    }
  }

  // Real-time Text matching filter (Product Name, Code, JP, VI)
  if (searchQuery.value.trim() !== "") {
    const q = searchQuery.value.toLowerCase().trim();
    itemsList = itemsList.filter((item) => {
      const names = getJpAndViNames(item.name);
      return (
        item.name.toLowerCase().includes(q) ||
        item.id.toLowerCase().includes(q) ||
        names.jp.toLowerCase().includes(q) ||
        names.vi.toLowerCase().includes(q)
      );
    });
  }

  return itemsList;
});

const finalFilteredItems = computed(() => {
  let list = filteredItems.value;

  // Package-only items filter
  if (showOnlyPackageItems.value && activeSettings.value.package) {
    list = list.filter((item) =>
      isItemInPackage(item, activeSettings.value.package),
    );
  }

  // DRINK TIME LIMIT EXPIRED RESTRICTION
  if (
    timerSecondsLeft.value <= 0 &&
    (activeSettings.value.drinkGroup === "B" ||
      activeSettings.value.drinkGroup === "C")
  ) {
    list = list.filter((item) => {
      // Hide alcohol/premium
      const isCoCon =
        item.category_id === "thuc_uong_co_con" ||
        item.id.includes("alcohol") ||
        item.id.includes("beer") ||
        item.id.includes("wine") ||
        item.id.includes("sake");
      return !isCoCon;
    });
  }

  // Quick Action Filters
  if (activeQuickFilter.value === "favorites") {
    list = list.filter((item) => favoriteIds.value.includes(item.id));
  } else if (activeQuickFilter.value === "popular") {
    list = list.filter((item) => getEnrichedItem(item).isPopular);
  } else if (activeQuickFilter.value === "recent") {
    const cartIds = activeOrder.value.items.map((i) => i.id);
    list = list.filter((item) => cartIds.includes(item.id));
  }

  // Available / Sold out filter
  if (activeStatusFilter.value === "available") {
    list = list.filter((item) => getEnrichedItem(item).isAvailable);
  } else if (activeStatusFilter.value === "unavailable") {
    list = list.filter((item) => !getEnrichedItem(item).isAvailable);
  }

  // Price sorting filter
  if (priceSort.value === "asc") {
    list = [...list].sort((a, b) => a.price - b.price);
  } else if (priceSort.value === "desc") {
    list = [...list].sort((a, b) => b.price - a.price);
  }

  return list;
});

// Format VND
function formatVND(value: number) {
  if (value === 0) return "0đ";
  return value.toLocaleString("vi-VN") + "đ";
}

// Translations helpers
function translateCategoryId(catId: string) {
  const match = menuData.categories.find((c) => c.id === catId);
  return match ? match.name : catId;
}

function translateSubCategoryId(subId: string) {
  const cat = menuData.categories.find((c) => c.id === activeCategoryId.value);
  if (!cat || !cat.subcategories) return subId;
  const match = cat.subcategories.find((s) => s.id === subId);
  return match ? match.name : subId;
}

// Highlighting search matching text
function highlightText(text: string, query: string) {
  if (!query) return text;
  const regex = new RegExp(
    `(${query.replace(/[-\/\\^$*+?.()|[\]{}]/g, "\\$&")})`,
    "gi",
  );
  return text.replace(
    regex,
    '<mark class="bg-yellow-100 text-gray-900 rounded-sm px-0.5">$1</mark>',
  );
}

// Cart items quantity getter
function getCartItemQty(itemId: string): number {
  const item = activeOrder.value.items.find((i) => i.id === itemId);
  return item ? item.quantity : 0;
}

// Action triggers
function handleCardClick(product: MenuItem) {
  const enriched = getEnrichedItem(product);
  if (!enriched.isAvailable) {
    triggerToast(
      "error",
      t("reception_order.mon_tam_thoi_het_hang", { name: product.name }),
    );
    return;
  }
  addToCart(product);
}

function addToCart(product: MenuItem) {
  if (!selectedTableCode.value) return;

  // Validate Rule 1: Limit 10 items/round
  const currentQty = getCartItemQty(product.id);
  if (currentQty >= 10) {
    triggerToast(
      "warning",
      t("reception_order.da_dat_gioi_han_toi_da_10_phan", {
        name: product.name,
      }),
    );
    return;
  }

  restaurantStore.addOrderItem(selectedTableCode.value, product);
  triggerToast(
    "success",
    t("reception_order.da_them_vao_hoa_don", { name: product.name }),
  );
}

function updateQty(itemId: string, change: number) {
  if (!selectedTableCode.value) return;

  const currentQty = getCartItemQty(itemId);
  if (change > 0 && currentQty >= 10) {
    triggerToast("warning", t("reception_order.moi_luot_goi_toi_da_10_phan"));
    return;
  }

  restaurantStore.updateItemQuantity(selectedTableCode.value, itemId, change);
}

function removeItem(itemId: string) {
  if (!selectedTableCode.value) return;
  if (confirm(t("reception_order.xoa_mon_nay_khoi_don"))) {
    restaurantStore.removeOrderItem(selectedTableCode.value, itemId);
    triggerToast("info", t("reception_order.da_xoa_mon_khoi_gio"));
  }
}

function clearCart() {
  if (!selectedTableCode.value) return;
  if (confirm(t("reception_order.ban_co_chac_muon_xoa_toan_bo_mon"))) {
    activeOrder.value.items = [];
    triggerToast("success", t("reception_order.da_xoa_toan_bo_mon"));
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
        opt.note = "";
      }
    });
    option.quantity = 1;
  } else {
    if (count >= max) {
      triggerToast(
        "warning",
        t("reception_order.da_chon_gioi_han_toi_da", { max: String(max) }),
      );
      return;
    }
    option.quantity++;
  }
}

function subtractOptionQty(option: any) {
  if (option.quantity > 0) {
    option.quantity--;
    if (option.quantity === 0) {
      option.note = "";
    }
  }
}

// Detail popup modal triggers
function openDetailPanel(product: MenuItem) {
  selectedProductForDetail.value = product;
  const existingQty = getCartItemQty(product.id);
  modalItemQty.value = existingQty > 0 ? existingQty : 1;
  modalItemNote.value = "";
  modalVAT.value = true;
  modalPPV.value = false;
  modalCurrency.value = "VND";
  modalRate.value = "1";

  // Load option groups
  tempOptionGroups.value = getMockOptionsForItem(product.id);
  if (tempOptionGroups.value.length > 0) {
    activeOptionTab.value = tempOptionGroups.value[0].id;
  } else {
    activeOptionTab.value = "";
  }

  isDetailPanelOpen.value = true;
}

function saveDetailPanelQty() {
  if (!selectedTableCode.value || !selectedProductForDetail.value) return;

  if (modalItemQty.value > 10) {
    triggerToast("warning", t("reception_order.so_luong_goi_mon_vuot_qua"));
    return;
  }

  const product = selectedProductForDetail.value;

  if (tempOptionGroups.value.length === 0) {
    // ─── Simple Item Submission ───
    const order = activeOrder.value;
    const existing = order.items.find((i) => i.id === product.id);

    if (existing) {
      existing.quantity = modalItemQty.value;
    } else {
      restaurantStore.addOrderItem(selectedTableCode.value, product);
      const added = order.items.find((i) => i.id === product.id);
      if (added) added.quantity = modalItemQty.value;
    }

    triggerToast(
      "success",
      t("reception_order.da_them_mon_phan", {
        name: product.name,
        qty: String(modalItemQty.value),
      }),
    );
    isDetailPanelOpen.value = false;
  } else {
    // ─── Complex Item Submission ───
    if (!isSelectionValid.value) {
      triggerToast("error", t("reception_order.vui_long_hoan_thanh_lua_chon"));
      return;
    }

    const selectedOptsList: { name: string; note: string; quantity: number }[] =
      [];
    tempOptionGroups.value.forEach((group) => {
      group.options.forEach((opt: any) => {
        if (opt.quantity > 0) {
          selectedOptsList.push({
            name: opt.name,
            note: opt.note,
            quantity: opt.quantity,
          });
        }
      });
    });

    const optsString = selectedOptsList
      .map(
        (o) =>
          `${o.quantity > 1 ? o.quantity + "x " : ""}${o.name}${o.note ? ` (${o.note})` : ""}`,
      )
      .join(", ");

    // Custom price calculation based on option pricing
    const optionsAdditionPrice = tempOptionGroups.value.reduce((sum, group) => {
      return (
        sum +
        group.options.reduce(
          (oSum: number, opt: any) => oSum + opt.price * opt.quantity,
          0,
        )
      );
    }, 0);

    const totalPrice = product.price + optionsAdditionPrice;

    const customizedItem: MenuItem = {
      ...product,
      price: totalPrice,
      price_display: formatVND(totalPrice),
      name: `${product.name} [${optsString}]`,
    };

    restaurantStore.addOrderItem(selectedTableCode.value, customizedItem);

    const order = activeOrder.value;
    const addedItem = order.items.find(
      (i) => i.id === customizedItem.id && i.name === customizedItem.name,
    );
    if (addedItem) {
      addedItem.quantity = modalItemQty.value;
    }

    triggerToast(
      "success",
      t("reception_order.da_them_mon_co_tuy_chon", {
        name: customizedItem.name,
      }),
    );
    isDetailPanelOpen.value = false;
  }
}

// Favorites toggle
function toggleFavorite(itemId: string) {
  if (favoriteIds.value.includes(itemId)) {
    favoriteIds.value = favoriteIds.value.filter((id) => id !== itemId);
    triggerToast("info", t("reception_order.da_bo_yeu_thich_mon"));
  } else {
    favoriteIds.value.push(itemId);
    triggerToast("success", t("reception_order.da_luu_mon_vao_yeu_thich"));
  }
}

function toggleQuickFilter(filter: "favorites" | "popular" | "recent" | "") {
  activeQuickFilter.value = filter;
}

function clearAllFilters() {
  searchQuery.value = "";
  activeQuickFilter.value = "";
  activeStatusFilter.value = "all";
  priceSort.value = "";
}

// Config Course details modal setup
function openSettingsConfig() {
  tempSettings.value = {
    package: activeSettings.value.package,
    drinkGroup: activeSettings.value.drinkGroup,
    language: activeSettings.value.language,
  };
  isPackageModalOpen.value = true;
}

function selectPackageOption(packageName: string) {
  if (activeSettings.value.isLocked) {
    triggerToast("error", t("reception_order.cau_hinh_da_bi_khoa"));
    return;
  }
  tempSettings.value.package = packageName;
}

function selectDrinkOption(group: string) {
  if (activeSettings.value.isLocked) {
    triggerToast("error", t("reception_order.nhom_thuc_uong_da_bi_khoa"));
    return;
  }
  tempSettings.value.drinkGroup = group;
}

function confirmPackageSelection() {
  if (!tempSettings.value.package) {
    triggerToast("warning", t("reception_order.vui_long_chon_goi_buffet"));
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
    order.customerName =
      order.customerName === t("reception_order.guestWalkIn")
        ? `Khách (${tempSettings.value.package})`
        : order.customerName;

    triggerToast("success", t("reception_order.courseLockedSuccess"));
  }
  isPackageModalOpen.value = false;
}

function cancelPackageSelection() {
  if (activeSettings.value.package) {
    isPackageModalOpen.value = false;
  } else {
    // If no course is configured, reject and return to floor layouts
    router.push("/reception/floors");
  }
}

// PIN pad operations
function openPinModal() {
  enteredPin.value = "";
  isPinModalOpen.value = true;
}

function enterPinDigit(digit: string) {
  if (enteredPin.value.length < 4) {
    enteredPin.value += digit;
  }

  if (enteredPin.value.length === 4) {
    // Validate manager Pin
    if (enteredPin.value === "1234") {
      const code = selectedTableCode.value;
      if (code && tableSettings.value[code]) {
        tableSettings.value[code].isLocked = false; // Unlock course
        triggerToast(
          "success",
          t("reception_order.mo_khoa_cau_hinh_thanh_cong"),
        );
      }
      isPinModalOpen.value = false;
    } else {
      triggerToast("error", t("reception_order.ma_pin_sai"));
      enteredPin.value = ""; // Reset
    }
  }
}

function clearLastPinDigit() {
  enteredPin.value = enteredPin.value.slice(0, -1);
}

// Operational Actions
function printDraftBill() {
  alert(
    t("reception_order.hoa_don_tam_tinh_alert", {
      table: selectedTableCode.value || "",
      package: activeSettings.value.package,
      guests: String(activeOrder.value.guestCount),
      total: formatVND(summary.value.grandTotal),
    }),
  );
  triggerToast("info", t("reception_order.da_gui_lenh_in_tam_tinh"));
}

async function checkoutTable() {
  const code = selectedTableCode.value;
  if (!code) return;
  const ok = await Swal.fire({
    title: t("reception_order.xac_nhan_thanh_toan"),
    text: t("reception_order.dong_ban_tam_tinh", {
      code,
      total: formatVND(summary.value.grandTotal),
    }),
    icon: "question",
    showCancelButton: true,
    confirmButtonText: t("reception_order.tien_hanh_thanh_toan"),
    cancelButtonText: t("reception_order.huy_text"),
  });
  if (!ok.isConfirmed) return;
  try {
    // Resolve the mock table code to the real DB UUID through Hall RPC.
    const { branchId } = useAuth();
    if (!branchId.value)
      throw new Error(t("reception_order.tai_khoan_chua_gan_chi_nhanh"));
    const tableRow = (await listTables()).find(
      (table: any) => table.code === code,
    );
    if (!tableRow)
      throw new Error(t("reception_order.khong_tim_thay_ban", { code }));
    router.push(`/reception/checkout/${(tableRow as { id: string }).id}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    Swal.fire(t("reception_order.loi_text"), msg, "error");
  }
}

function cancelChanges() {
  if (confirm(t("reception_order.huy_bo_toan_bo_mon_an"))) {
    activeOrder.value.items = [];
    triggerToast("warning", t("reception_order.da_lam_trong_gio_hang"));
  }
}

function holdOrder() {
  triggerToast("info", t("reception_order.da_luu_tam_don_hang"));
  router.push("/reception/floors");
}

// Loading flag for the kitchen-send action. The local POS cart stays intact so
// the UI does not desync; persistence is handled in one DB RPC call.
const kitchenLoading = ref(false);

// menuData items carry slugs like 'set1390_ticket' — these are NOT UUIDs and
// DB order RPCs require real menu item UUIDs. Resolve the slug → DB UUID lazily
// through the menu RPC (matched by `metadata.slug`, then by `name`).
const menuDbIdCache = ref<Record<string, string>>({});

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    value,
  );
}

async function ensureMenuDbIds(
  branch: string,
  items: { id: string; name: string }[],
) {
  // Only resolve IDs that aren't already UUIDs AND aren't already cached.
  const missing = items.filter(
    (it) => !isUuid(it.id) && !menuDbIdCache.value[it.id],
  );
  if (missing.length === 0) return;
  const dbItems = await getItems(undefined, branch);

  for (const item of missing) {
    const bySlug = dbItems.find(
      (row: any) =>
        (row.metadata as { slug?: string } | null)?.slug === item.id,
    );
    if (bySlug) {
      menuDbIdCache.value[item.id] = bySlug.id;
      continue;
    }

    const byName = dbItems.find((row: any) => row.name === item.name);
    if (byName) {
      menuDbIdCache.value[item.id] = byName.id;
    }
  }
}

async function sendToKitchen() {
  if (activeOrder.value.items.length === 0) {
    triggerToast("error", t("reception_order.chua_co_mon_an_de_gui_bep"));
    return;
  }
  const code = selectedTableCode.value;
  if (!code) {
    triggerToast("error", t("reception_order.chua_chon_ban"));
    return;
  }
  kitchenLoading.value = true;
  try {
    const { branchId } = useAuth();
    if (!branchId.value)
      throw new Error(t("reception_order.tai_khoan_chua_gan_chi_nhanh"));
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
    );
    const skipped: string[] = [];
    const payload: Array<{
      menu_item_id: string;
      quantity: number;
      modifiers: unknown[];
      note: string | null;
    }> = [];

    for (const line of activeOrder.value.items) {
      const dbId = isUuid(line.id) ? line.id : menuDbIdCache.value[line.id];
      if (!dbId) {
        skipped.push(line.name);
        continue;
      }
      payload.push({
        menu_item_id: dbId,
        quantity: line.quantity,
        modifiers: [],
        note: (line as any).note || null,
      });
    }

    if (payload.length > 0) {
      const { error: rpcErr } = await supabase.rpc("hall_submit_table_order", {
        p_branch_id: branchId.value,
        p_table_id: tableId,
        p_items: payload,
        p_idempotency_key: crypto.randomUUID(),
      });
      if (rpcErr) throw rpcErr;

      // CẬP NHẬT TABLE STATUS SAU KHI GỬI THÀNH CÔNG
      const table = restaurantStore.getTableByCode(code);
      if (table) {
        table.status = "Serving";
        table.customerName = activeOrder.value.customerName || "Khách vãng lai";
        table.billAmount = formatVND(summary.value.grandTotal);
        const now = new Date();
        table.checkInTime = now.toLocaleTimeString("vi-VN", {
          hour: "2-digit",
          minute: "2-digit",
        });
        table.occupiedDuration = "0 phút";
      }

      triggerToast(
        "success",
        t("reception_order.da_gui_mon_den_kds", {
          sent: String(payload.length),
        }),
      );
    }

    if (skipped.length > 0) {
      triggerToast(
        "warning",
        t("reception_order.bo_qua_mon_chua_map_db", {
          length: String(skipped.length),
          items:
            skipped.slice(0, 3).join(", ") + (skipped.length > 3 ? "…" : ""),
        }),
      );
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
    kitchenLoading.value = false;
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
        table.status = "Serving";
        table.billAmount = formatVND(summary.value.grandTotal);
        table.customerName =
          table.customerName || activeOrder.value.customerName;
        const now = new Date();
        table.checkInTime =
          table.checkInTime ||
          now.toLocaleTimeString("vi-VN", {
            hour: "2-digit",
            minute: "2-digit",
          });
        table.occupiedDuration = t("reception_order.mot_phut");
      } else {
        table.status = "Available";
        table.billAmount = "";
        table.customerName = "";
        table.checkInTime = "";
        table.occupiedDuration = "";
      }
    }
    triggerToast("success", t("reception_order.da_luu_cau_hinh_mon_an"));
    router.push("/reception/floors");
  }
}

watch(activeSubCategoryId, (newSubId) => {
  if (activeCategoryId.value === "buffet" && newSubId !== "all") {
    const pkgMap: Record<string, string> = {
      buffet_1390: "Buffet 1390",
      buffet_1150: "Buffet 1150",
      buffet_680: "Buffet 680",
      buffet_490: "Buffet 490",
      buffet_380: "Buffet 380",
      biz_1200: "Biz 1200",
      biz_900: "Biz 900",
      biz_700: "Biz 700",
      set_drink: "SET DRINK",
      set_550jp: "Set 550JP",
      buffet_lau: t("reception_order.buffet_lau"),
      a_la_carte: "A la carte",
    };
    const pkgName = pkgMap[newSubId];
    if (pkgName && selectedTableCode.value) {
      if (!tableSettings.value[selectedTableCode.value]) {
        tableSettings.value[selectedTableCode.value] = {
          package: pkgName,
          drinkGroup: "A",
          language: "VI",
          isLocked: false,
        };
      } else {
        tableSettings.value[selectedTableCode.value].package = pkgName;
      }
      triggerToast(
        "success",
        t("reception_order.da_cau_hinh_goi", {
          pkgName,
          tableCode: selectedTableCode.value,
        }),
      );
    }
  }
});

function selectSubCategory(subId: string) {
  activeSubCategoryId.value = subId;
}

function goBack() {
  router.push({ name: "reception-dashboard" });
}

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    if (selectionMode.value !== 'none') {
      cancelSelectionMode();
    } else if (showTableContextMenu.value) {
      showTableContextMenu.value = false;
    } else if (showTransferModal.value) {
      showTransferModal.value = false;
    } else if (showMergeModal.value) {
      showMergeModal.value = false;
    } else if (showSplitOrderModal.value) {
      showSplitOrderModal.value = false;
    } else if (showSplitItemModal.value) {
      showSplitItemModal.value = false;
    } else if (showCancelModal.value) {
      showCancelModal.value = false;
    } else if (selectedTableCode.value) {
      closePanel();
    } else {
      goBack();
    }
  }
}

onMounted(() => {
  startSessionTimer();
  window.addEventListener("keydown", handleKeyDown);
  clockInterval = setInterval(() => {
    currentClock.value = new Date();
  }, 1000);
});

onUnmounted(() => {
  stopSessionTimer();
  window.removeEventListener('keydown', handleKeyDown);
  clearToastTimers()
  clearGridLoadingTimer()
  if (typeof clockInterval !== 'undefined' && clockInterval != null) {
    clearInterval(clockInterval)
  }
});
</script>

<style scoped>
@import "@/styles/orderingScreen.css";

/* Payment Methods Bar - Compact */
.payment-methods-bar {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
  padding: 8px 12px;
  background: #2d2d2d;
  border-top: 1px solid #1e1e1e;
}

.payment-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 12px;
  background: #3a3a3a;
  border: 1px solid #4a4a4a;
  border-radius: 6px;
  color: #b0b0b0;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.payment-btn:hover {
  background: #4a4a4a;
  color: white;
  transform: translateY(-1px);
}

.payment-btn.active {
  background: #2196f3;
  border-color: #2196f3;
  color: white;
  box-shadow: 0 2px 8px rgba(33, 150, 243, 0.3);
}

.payment-icon {
  font-size: 14px;
  line-height: 1;
}

.payment-label {
  line-height: 1.2;
}

/* Color coding for active states */
.payment-cash.active {
  background: #4caf50;
  border-color: #4caf50;
}
.payment-transfer.active {
  background: #2196f3;
  border-color: #2196f3;
}
.payment-voucher.active {
  background: #9c27b0;
  border-color: #9c27b0;
}
.payment-coupon.active {
  background: #ff9800;
  border-color: #ff9800;
}
.payment-deposit.active {
  background: #795548;
  border-color: #795548;
}
.payment-discount.active {
  background: #f44336;
  border-color: #f44336;
}
.payment-vip.active {
  background: #ffd700;
  border-color: #ffd700;
  color: #333;
}

/* Responsive */
@media (max-width: 1200px) {
  .payment-methods-bar {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 768px) {
  .payment-methods-bar {
    grid-template-columns: repeat(3, 1fr);
  }

  .payment-btn {
    padding: 6px 8px;
    font-size: 10px;
  }

  .payment-icon {
    font-size: 12px;
  }
}

/* Fix scrollbar cho payment details */
.payment-details-container {
  max-height: none !important; /* Bỏ giới hạn chiều cao */
  overflow-y: visible !important; /* Không scroll */
}

/* Nếu vẫn cần scroll, style scrollbar cho đẹp */
.payment-details-container::-webkit-scrollbar {
  width: 6px;
}

.payment-details-container::-webkit-scrollbar-track {
  background: #2d2d2d;
  border-radius: 3px;
}

.payment-details-container::-webkit-scrollbar-thumb {
  background: #e8772e;
  border-radius: 3px;
}

.payment-details-container::-webkit-scrollbar-thumb:hover {
  background: #f5a623;
}

/* Compact form cho payment methods */
.discount-form-compact {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.discount-form-compact .form-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.discount-form-compact .form-label {
  width: 80px;
  font-size: 11px;
  color: #9ca3af;
  font-weight: 600;
}

.discount-form-compact .form-input,
.discount-form-compact .form-select {
  flex: 1;
  padding: 6px 10px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 12px;
  color: #1f2937;
}

.discount-form-compact .form-input:focus,
.discount-form-compact .form-select:focus {
  outline: none;
  border-color: #ff9800;
  box-shadow: 0 0 0 2px rgba(255, 152, 0, 0.1);
}

.discount-form-compact .btn-apply {
  padding: 8px 16px;
  background: #ff9800;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.discount-form-compact .btn-apply:hover {
  background: #f57c00;
  transform: translateY(-1px);
}

/* Custom Menu Grid and Card Styling */
.menu-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr); /* Tăng từ 4 lên 5 cột */
  gap: 10px; /* Giảm từ 16px xuống 10px */
  padding: 16px;
  overflow-y: auto;
  max-height: calc(100vh - 280px);
}

.menu-card {
  background: #2d2d2d;
  border: 1px solid #444;
  border-radius: 8px;
  padding: 10px 12px; /* Giảm padding */
  display: flex;
  flex-direction: column;
  gap: 6px;
  transition: all 0.2s ease;
  cursor: pointer;
  position: relative;
  min-height: 110px; /* Giảm min-height */
}

.menu-card:hover {
  border-color: #e8772e;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(232, 119, 46, 0.2);
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

/* Badge số lượng - nhỏ gọn hơn */
.qty-badge {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 22px; /* Giảm size */
  height: 22px;
  border-radius: 50%;
  background: #4caf50;
  color: white;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
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

/* Tên món - compact */
.item-name {
  font-size: 12px;
  font-weight: 600;
  color: white;
  margin: 0;
  line-height: 1.3;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  min-height: 32px; /* Đảm bảo 2 dòng */
}

/* Giá tiền - nổi bật */
.item-price {
  font-size: 14px;
  font-weight: 700;
  color: #e8772e;
  margin: 0;
}

/* Footer: ĐVT + Icon Info */
.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  padding-top: 6px;
  border-top: 1px solid #444;
}

.unit-label {
  font-size: 10px;
  color: #888;
  margin: 0;
}

/* Nút thêm - nhỏ gọn */
.item-add-btn {
  position: absolute;
  bottom: 8px;
  right: 8px;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: #e8772e;
  border: none;
  color: white;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  z-index: 2;
}

.item-add-btn:hover {
  background: #f5a623;
  transform: scale(1.1);
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
@media (max-width: 1400px) {
  .menu-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 1200px) {
  .menu-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .menu-grid {
    grid-template-columns: repeat(2, 1fr);
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
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-scale-up {
  animation: scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
}
@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-slide-in {
  animation: slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.animate-slide-in-panel {
  animation: slideInPanel 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes slideInPanel {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}

.animate-pulse-slow {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
.animate-pulse-fast {
  animation: pulse 0.8s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
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

.slide-enter-active,
.slide-leave-active {
  transition: opacity 0.3s ease;
}
.slide-enter-from,
.slide-leave-to {
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

/* ===== LAYOUT CHÍNH TRUYỀN THỐNG ===== */
.pos-traditional-layout {
  width: 320px;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #1a1a1a;
  border-right: 1px solid #333333;
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  color: #333333;
}

/* ===== TOP TABS ===== */
.top-tabs {
  display: flex;
  background: #1a5276;
  border-bottom: 2px solid #0e2f44;
  flex-shrink: 0;
}

.tab-btn {
  padding: 12px 18px;
  background: transparent;
  border: none;
  color: white;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  position: relative;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.tab-btn.active {
  background: #2980b9;
  border-bottom: 3px solid #e8772e;
}

.badge {
  position: absolute;
  top: 4px;
  right: 2px;
  background: #e74c3c;
  color: white;
  padding: 1px 5px;
  border-radius: 10px;
  font-size: 9px;
  font-weight: 700;
  min-width: 14px;
  text-align: center;
}

.menu-btn {
  margin-left: auto;
  padding: 12px 16px;
  background: #0e2f44;
  border: none;
  color: white;
  font-size: 16px;
  cursor: pointer;
}

/* ===== BILL INFO HEADER ===== */
.bill-info-header {
  padding: 10px 14px;
  background: #f5f5f5;
  border-bottom: 1px solid #dddddd;
  flex-shrink: 0;
}

.info-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 6px;
}

.info-row:last-child {
  margin-bottom: 0;
}

.info-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.info-group.full-width {
  flex: 1;
}

.info-label {
  font-size: 11px;
  color: #666666;
  font-weight: 500;
}

.info-value {
  font-size: 12px;
  color: #333333;
  font-weight: 600;
}

.info-value.highlight {
  color: #e8772e;
  font-weight: 700;
  font-size: 13px;
}

.customer-input {
  flex: 1;
  padding: 4px 8px;
  border: 1px solid #bbbbbb;
  border-radius: 4px;
  font-size: 12px;
  background: white;
  color: #333333;
}

.customer-input:focus {
  outline: none;
  border-color: #2980b9;
}

/* ===== ORDER TABLE ===== */
.order-table-container {
  flex: 1;
  overflow-y: auto;
  background: white;
}

/* Custom Scrollbar for traditional table */
.order-table-container::-webkit-scrollbar {
  width: 6px;
}

.order-table-container::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.order-table-container::-webkit-scrollbar-thumb {
  background: #1a5276;
  border-radius: 3px;
}

.order-table-container::-webkit-scrollbar-thumb:hover {
  background: #2980b9;
}

.order-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.order-table thead {
  background: #000000;
  color: white;
  position: sticky;
  top: 0;
  z-index: 10;
}

.order-table th {
  padding: 8px 10px;
  text-align: left;
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #0e2f44;
}

.col-name {
  width: 35%;
}
.col-qty {
  width: 15%;
  text-align: center;
}
.col-price {
  width: 18%;
  text-align: right;
}
.col-vat {
  width: 10%;
  text-align: center;
}
.col-discount {
  width: 12%;
  text-align: right;
}
.col-total {
  width: 10%;
  text-align: right;
}

.order-table tbody tr {
  border-bottom: 1px solid #eeeeee;
}

.order-table tbody tr:hover {
  background: #f9f9f9;
}

.order-table td {
  padding: 8px 10px;
  vertical-align: top;
}

.item-name {
  font-weight: 600;
  color: #333333;
  margin-bottom: 2px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-unit {
  font-size: 10px;
  color: #999999;
}

.qty-control {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  background: #f5f5f5;
  padding: 2px 4px;
  border-radius: 4px;
  border: 1px solid #e0e0e0;
}

.qty-control button {
  width: 18px;
  height: 18px;
  border: 1px solid #bbbbbb;
  background: white;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #333333;
}

.qty-control button:hover {
  background: #2980b9;
  color: white;
  border-color: #2980b9;
}

.qty-control span {
  font-weight: 700;
  min-width: 14px;
  text-align: center;
}

.col-price,
.col-total {
  font-weight: 600;
  font-family: "Courier New", monospace;
  text-align: right;
}

.col-vat {
  text-align: center;
}

.col-discount {
  color: #c62828;
  font-weight: 600;
  text-align: right;
  font-family: "Courier New", monospace;
}

/* ===== BILLING FOOTER ===== */
.billing-footer {
  background: #1a5276;
  color: white;
  padding: 10px 14px;
  flex-shrink: 0;
  border-top: 1px solid #0e2f44;
}

.billing-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px 16px;
  margin-bottom: 8px;
}

.billing-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.billing-label {
  color: #bdc3c7;
  font-weight: 500;
}

.billing-value {
  color: white;
  font-weight: 600;
  font-family: "Courier New", monospace;
}

.billing-value.discount {
  color: #e74c3c;
}

.grand-total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 8px;
  border-top: 1px solid #2980b9;
}

.total-label {
  font-size: 14px;
  font-weight: 800;
  color: white;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.total-value {
  font-size: 20px;
  font-weight: 900;
  color: #e8772e;
  font-family: "Courier New", monospace;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
}

/* ===== BOTTOM NAV ===== */
.bottom-nav {
  display: flex;
  background: #0e2f44;
  border-top: 2px solid #1a5276;
  flex-shrink: 0;
}

.nav-btn {
  flex: 1;
  padding: 8px;
  background: transparent;
  border: none;
  color: #bdc3c7;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  transition: all 0.2s;
}

.nav-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.nav-btn.active {
  background: #2980b9;
  color: white;
}

.send-btn {
  padding: 10px 20px;
  background: #e74c3c;
  color: white;
  border: none;
  font-weight: 700;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  align-self: center;
  margin-right: 8px;
  font-size: 12px;
}

.send-btn:hover {
  background: #c0392b;
  transform: scale(1.05);
}

.send-btn:active {
  transform: scale(0.95);
}

.nav-icon {
  font-size: 18px;
}

.nav-btn span:last-child {
  font-size: 10px;
  font-weight: 600;
}

/* Icon Buttons Top Right */
.icon-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.icon-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.05);
}

/* More Dropdown Menu */
.more-dropdown {
  position: absolute;
  top: 48px;
  right: 0;
  background: #2d2d2d;
  border: 1px solid #444;
  border-radius: 8px;
  padding: 6px 0;
  min-width: 160px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 1000;
}

.more-dropdown button {
  width: 100%;
  padding: 8px 16px;
  background: transparent;
  border: none;
  color: white;
  font-size: 12px;
  text-align: left;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.more-dropdown button:hover {
  background: rgba(232, 119, 46, 0.2);
}

.more-dropdown button.danger {
  color: #f44336;
}

.more-dropdown hr {
  border: none;
  border-top: 1px solid #444;
  margin: 6px 0;
}

/* Close sidebar button (bottom right) */
.close-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: #f44336;
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  margin-left: 8px;
  flex-shrink: 0;
}

.close-btn:hover {
  background: #d32f2f;
  transform: scale(1.1);
}

.close-btn:active {
  transform: scale(0.95);
}

/* Settings Cog (Sidebar info header) */
.settings-btn {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: #b0b0b0;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.settings-btn:hover {
  background: rgba(232, 119, 46, 0.3);
  color: #e8772e;
  transform: rotate(90deg);
}

/* Custom pending orders tab badge */
.tab-badge {
  background: #f44336;
  color: white;
  padding: 1px 5px;
  border-radius: 10px;
  font-size: 9px;
  font-weight: 700;
  min-width: 14px;
  text-align: center;
  margin-left: 4px;
}

/* ===== KITCHEN & DELIVERY LIST VIEW ===== */
.order-list {
  flex: 1;
  overflow-y: auto;
  background: #ffffff;
}

.order-group {
  border-top: 2px solid #1a5276;
  background: white;
  margin-bottom: 4px;
}

.group-header {
  background: #1a5276;
  color: white;
  padding: 6px 10px;
  font-size: 11px;
  font-weight: bold;
  display: flex;
  justify-content: space-between;
}

.order-item {
  padding: 8px 10px;
  border-bottom: 1px solid #eeeeee;
}

.item-main {
  display: flex;
  align-items: center;
  gap: 10px;
}

.item-thumb {
  width: 40px;
  height: 40px;
  border-radius: 4px;
  object-fit: cover;
}

.item-info {
  flex: 1;
  min-width: 0;
}

.item-name {
  font-weight: 700;
  font-size: 12px;
  color: #333333;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-status {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  margin-top: 2px;
}

.status-badge {
  background: #4caf50;
  color: white;
  padding: 1px 5px;
  border-radius: 3px;
  font-size: 9px;
  font-weight: bold;
  text-transform: uppercase;
}

.item-price {
  font-family: "Courier New", monospace;
  font-weight: bold;
  color: #666666;
}

.kitchen-label {
  font-size: 10px;
  color: #666666;
  text-transform: uppercase;
  margin-top: 3px;
  font-weight: 500;
}

.item-qty {
  text-align: center;
  border: 1px solid #e8772e;
  padding: 2px 6px;
  border-radius: 4px;
  min-width: 45px;
}

.qty-box {
  font-weight: 800;
  font-size: 13px;
  color: #e8772e;
}

.qty-unit {
  font-size: 9px;
  color: #666666;
  font-weight: 600;
}

.item-time {
  font-size: 11px;
  color: #666666;
  font-weight: 700;
  min-width: 25px;
  text-align: center;
}

.group-footer {
  padding: 4px 10px;
  font-size: 11px;
  color: #888888;
  font-weight: 600;
  text-align: right;
  background: #fafafa;
}

/* Footer Actions */
.action-footer {
  background: #1a5276;
  color: white;
  padding: 10px 14px;
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
  border-top: 1px solid #0e2f44;
}

.cart-icon {
  font-size: 18px;
  background: #00000020;
  padding: 4px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.total-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.total-value {
  font-size: 16px;
  font-weight: 800;
  color: #e8772e;
}

.btn-remind {
  padding: 8px 14px;
  background: #e8772e;
  color: white;
  border: none;
  border-radius: 4px;
  font-weight: 700;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-remind:hover {
  background: #d0621f;
  transform: scale(1.03);
}

.btn-deliver {
  padding: 8px 14px;
  background: #4caf50;
  color: white;
  border: none;
  border-radius: 4px;
  font-weight: 700;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-deliver:hover {
  background: #43a047;
  transform: scale(1.03);
}

.sidebar-closed {
  width: 0 !important;
  min-width: 0 !important;
  opacity: 0 !important;
  pointer-events: none !important;
  transform: translateX(-100%);
  overflow: hidden;
  border-right: none !important;
}

.sidebar-open {
  width: 320px !important;
  opacity: 1 !important;
  transform: translateX(0);
  border-right: 1px solid #333333 !important;
}

/* ===== ACTIVITY LOG ===== */
.activity-log {
  background: white;
  border-top: 2px solid #1a5276;
  max-height: 200px;
  overflow-y: auto;
  flex-shrink: 0;
}

.log-header {
  background: #1a5276;
  color: white;
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  justify-content: space-between;
  position: sticky;
  top: 0;
  z-index: 5;
}

.log-count {
  background: #e74c3c;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 10px;
}

.log-table-wrapper {
  overflow-x: auto;
}

.log-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 11px;
}

.log-table th {
  background: #f5f5f5;
  padding: 6px 8px;
  text-align: left;
  font-weight: 600;
  color: #333;
  border-bottom: 1px solid #ddd;
  position: sticky;
  top: 0;
  z-index: 4;
}

.log-table td {
  padding: 6px 8px;
  border-bottom: 1px solid #eee;
  color: #333333;
}

.log-time {
  font-family: monospace;
  color: #666;
  font-size: 10px;
}

.log-action {
  font-weight: 600;
  color: #1a5276;
}

.log-money {
  font-family: monospace;
  font-weight: 600;
  text-align: right;
}

.log-row-send {
  background: #fff3e0 !important;
}

.log-row-pay {
  background: #e8f5e9 !important;
}

/* ===== FILTER DROPDOWN ===== */
.filter-dropdown {
  position: relative;
  display: inline-block;
}

.filter-btn {
  padding: 6px 12px;
  background: #3a3a3a;
  border: 1px solid #4a4a4a;
  border-radius: 6px;
  color: white;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 130px;
  justify-content: space-between;
  transition: all 0.2s ease;
}

.filter-btn:hover {
  background: #4a4a4a;
  border-color: #ff8f00;
}

.dropdown-menu {
  position: absolute;
  bottom: 100%;
  left: 0;
  margin-bottom: 6px;
  background: #ffffff;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.4);
  z-index: 100;
  width: 160px;
  border: 1px solid #dddddd;
}

.filter-item {
  width: 100%;
  padding: 10px 14px;
  border: none;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s ease;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.filter-item:last-child {
  border-bottom: none;
}

.filter-item:hover {
  opacity: 0.85;
}

.filter-item.active {
  outline: 2px solid #e8772e;
  outline-offset: -2px;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition:
    opacity 0.2s,
    transform 0.2s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* ===== AREA SELECTOR DROPDOWN & OVERLAY ===== */
.area-selector-wrapper {
  position: relative;
  display: inline-block;
}

.area-btn {
  padding: 6px 12px;
  background: #3a3a3a;
  border: 1px solid #4a4a4a;
  border-radius: 6px;
  color: white;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 120px;
  justify-content: space-between;
  transition: all 0.2s ease;
}

.area-btn:hover {
  background: #4a4a4a;
  border-color: #ff8f00;
}

.area-overlay {
  position: absolute;
  bottom: 100%;
  left: 0;
  margin-bottom: 8px;
  background: #1a5276;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.5);
  z-index: 105;
  width: 580px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.area-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.area-card {
  padding: 12px 10px;
  background: #2980b9;
  border: 2px solid transparent;
  border-radius: 8px;
  color: white;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  transition: all 0.2s ease;
}

.area-card:hover {
  background: #3498db;
  transform: translateY(-2px);
}

.area-card.active {
  background: white !important;
  color: #1a5276 !important;
  border-color: #e8772e !important;
}

.area-card.active .area-total {
  color: #e8772e !important;
}

.area-name {
  font-size: 13px;
  font-weight: 700;
}

.area-total {
  font-size: 11px;
  font-weight: 800;
  color: #e8772e;
  font-family: monospace;
}

.area-stats {
  font-size: 10px;
  opacity: 0.9;
}

/* slide-up animation */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translateY(20px);
}

/* ===== OTHER INCOME MODAL ===== */
.other-income-modal {
  width: 100%;
  max-width: 600px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.creator-info {
  background: #f5f5f5;
  padding: 12px 16px;
  border-bottom: 1px solid #ddd;
}

.form-input,
.form-select {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 13px;
  background: white;
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #e8772e;
  box-shadow: 0 0 0 2px rgba(232, 119, 46, 0.1);
}

.btn-browse {
  padding: 8px 12px;
  background: #f5f5f5;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  color: #666;
}

.btn-browse:hover {
  background: #e0e0e0;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-save-print {
  background: #4caf50;
  color: white;
}

.btn-save-print:hover {
  background: #43a047;
}

.btn-save {
  background: #ff9800;
  color: white;
}

.btn-save:hover {
  background: #f57c00;
}

.btn-cancel {
  background: #f44336;
  color: white;
}

.btn-cancel:hover {
  background: #e53935;
}

/* ===== SETTINGS MODAL ===== */
.settings-modal {
  width: 100%;
  max-width: 500px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.btn-confirm {
  background: #4db6ac;
  color: white;
}

.btn-confirm:hover {
  background: #40a095;
}

.btn-skip {
  background: #e57373;
  color: white;
}

.btn-skip:hover {
  background: #d9534f;
}

/* ===== SECONDARY HAMBURGER MENU ===== */
.secondary-menu {
  position: fixed;
  top: 64px; /* Below header */
  left: 24px;
  z-index: 1000;
}

.menu-list {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
  min-width: 210px;
}

.menu-item {
  padding: 13px 18px;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 13px;
  font-weight: 700;
  transition: all 0.2s ease;
  text-align: left;
  width: 100%;
}

.menu-item:hover {
  opacity: 0.9;
  transform: translateX(5px);
}

/* Color Classes */
.color-green {
  background: #4caf50;
  color: white;
}

.color-orange {
  background: #ff9800;
  color: white;
}

.color-purple {
  background: #9c27b0;
  color: white;
}

.color-red-orange {
  background: #e57373;
  color: white;
}

.color-red {
  background: #f44336;
  color: white;
}

.menu-icon {
  font-size: 16px;
  width: 20px;
  text-align: center;
}

.menu-label {
  flex: 1;
}

/* Animation slide-left */
.slide-left-enter-active,
.slide-left-leave-active {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-left-enter-from,
.slide-left-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}

/* Context Menu Animation */
.context-menu-enter-active,
.context-menu-leave-active {
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}

.context-menu-enter-from,
.context-menu-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(-10px);
}

/* Fix overflow cho sidebar */
.sidebar-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
}

.sidebar-container > * {
  flex-shrink: 0;
}

.sidebar-container .items-list {
  flex: 1;
  min-height: 0; /* QUAN TRỌNG: Cho phép scroll trong flex */
  overflow-y: auto;
}

/* Custom scrollbar */
.items-list::-webkit-scrollbar {
  width: 4px;
}

.items-list::-webkit-scrollbar-track {
  background: #1a1a1a;
}

.items-list::-webkit-scrollbar-thumb {
  background: #e8772e;
  border-radius: 2px;
}

/* Prevent text overflow */
.item-name-truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 160px;
}

/* FIX: Context Menu với auto placement */
.context-menu-popup {
  position: fixed;
  z-index: 9999;
  background: white;
  border-radius: 16px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
  border: 1px solid #e5e7eb;
  overflow: hidden;
  width: 280px;

  /* Fallback: Giới hạn chiều cao + scroll nếu cần */
  max-height: calc(100vh - 20px);
  overflow-y: auto;
}

/* Header của menu */
.context-menu-header {
  background: linear-gradient(135deg, #f0f4ff 0%, #e8eeff 100%);
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

/* Menu items container */
.context-menu-items {
  padding: 8px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* Individual menu item */
.context-menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0; /* Không bị co lại */
  width: 100%;
  text-align: left;
}

.context-menu-item:hover {
  background: #f3f4f6;
  transform: translateX(4px);
}

/* Icon circle */
.context-menu-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

/* Label text */
.context-menu-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  flex: 1;
}

/* Color variants */
.icon-green {
  background: #22c55e;
  color: white;
}
.icon-blue {
  background: #3b82f6;
  color: white;
}
.icon-purple {
  background: #a855f7;
  color: white;
}
.icon-orange {
  background: #f97316;
  color: white;
}
.icon-pink {
  background: #ec4899;
  color: white;
}
.icon-red {
  background: #ef4444;
  color: white;
}

.primary-action {
  background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%) !important;
  border: 2px solid #22c55e !important;
  transition: all 0.3s ease !important;
}
.primary-action:hover {
  background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%) !important;
  transform: translateX(4px) !important;
}

/* Scale up animation */
.scale-up-enter-active,
.scale-up-leave-active {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.scale-up-enter-from,
.scale-up-leave-to {
  opacity: 0;
  transform: scale(0.9);
}

/* Fade animation */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@keyframes slide-up {
  from {
    transform: translate(-50%, 100%);
    opacity: 0;
  }
  to {
    transform: translate(-50%, 0);
    opacity: 1;
  }
}
.animate-slide-up {
  animation: slide-up 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
