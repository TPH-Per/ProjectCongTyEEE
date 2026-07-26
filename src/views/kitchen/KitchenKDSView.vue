<template>
  <div
    class="kds-container min-h-screen flex flex-col bg-background text-foreground"
  >
    <!-- 1. KDS HEADER (80px) -->
    <header
      class="h-[80px] bg-background border-b border-border px-6 flex items-center justify-between"
    >
      <div class="flex items-center gap-4">
        <!-- Logo / Brand -->
        <div class="flex items-center gap-2">
          <span class="logo-brand">NGƯU CÁT</span>
          <span class="tag-kds">KDS</span>
        </div>
        <div class="h-6 w-[1px] bg-muted"></div>
        <!-- Active Station Display -->
        <div class="flex items-center gap-2">
          <span
            class="text-xs font-semibold text-muted-foreground uppercase tracking-wider"
            >Trạm hiện tại:</span
          >
          <span class="station-badge">
            {{ getStationLabel(activeStation) }}
          </span>
        </div>
      </div>

      <!-- Shared Header Buttons component -->
      <HeaderButtons />

      <!-- Real-time Clock -->
      <div class="flex items-center gap-4">
        <!-- Timer / Clock -->
        <div class="digital-clock">
          {{ currentTime }}
        </div>
      </div>
    </header>

    <!-- Notification Banner -->
    <div
      v-if="notification"
      class="alert-banner px-6 py-3"
      :class="notification.type"
    >
      <span class="font-semibold">{{ notification.message }}</span>
    </div>

    <!-- 2. FILTER BAR (60px) -->
    <div
      class="h-[60px] bg-card border-b border-border px-6 flex items-center justify-between gap-4 overflow-x-auto"
    >
      <!-- Station Filters -->
      <div class="flex items-center gap-2">
        <button
          v-for="st in stations"
          :key="st.key"
          class="station-btn"
          :class="{ active: activeStation === st.key }"
          @click="activeStation = st.key"
        >
          {{ st.label }}
        </button>
      </div>

      <!-- Status Filters, Sorting & Search -->
      <div class="flex items-center gap-4">
        <!-- Sort Select -->
        <div class="flex items-center gap-2">
          <span class="text-xs text-muted-foreground uppercase font-semibold"
            >Sắp xếp:</span
          >
          <select v-model="sortOrder" class="sort-dropdown">
            <option value="oldest">FIFO (Cũ nhất trước)</option>
            <option value="newest">Mới nhất trước</option>
            <option value="priority">Độ ưu tiên</option>
          </select>
        </div>

        <!-- Search box -->
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Tìm bàn / ID Ticket..."
            class="search-input"
          />
        </div>
      </div>
    </div>

    <!-- 3. STATUS BAR (50px) -->
    <div
      class="h-[50px] bg-background border-b border-border px-6 flex items-center gap-6"
    >
      <div class="status-counter status-waiting">
        <span>Chờ chế biến:</span>
        <span class="count-badge">{{ countPending }}</span>
      </div>
      <div class="status-counter status-preparing">
        <span>Đang làm:</span>
        <span class="count-badge">{{ countPreparing }}</span>
      </div>
      <div class="status-counter status-done">
        <span>Hoàn thành:</span>
        <span class="count-badge">{{ countDone }}</span>
      </div>
      <div class="status-counter status-delayed">
        <span>Trễ (>15 phút):</span>
        <span class="count-badge">{{ countDelayed }}</span>
      </div>
    </div>

    <!-- 4. MAIN WORKSPACE (Flex Row for Board + Sidebar) -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Kanban Board -->
      <main class="kanban-container">
        <!-- Cột 1: Chờ xác nhận (Pending Orders) -->
        <section class="kanban-column pending animate-fade-in">
          <div class="kanban-header pending">
            <span>CHỜ XÁC NHẬN</span>
            <span class="column-count">{{ pendingOrders.length }}</span>
          </div>

          <div
            v-for="order in pendingOrders"
            :key="order.id"
            class="ticket-card status-pending"
            :class="{
              remake: isOrderRemake(order),
              delayed: order.waitTime >= 900,
            }"
            @click="openDetail(order)"
          >
            <div v-if="order.waitTime >= 900" class="absolute top-2 right-2">
              <span class="status-badge delayed text-[10px]">TRỄ</span>
            </div>

            <div class="flex justify-between items-start mb-3">
              <div>
                <span
                  class="text-2xl font-black text-foreground block flex items-center gap-2"
                >
                  Bàn {{ getTableCode(order.table) }}
                  <span
                    v-if="order.id === oldestPendingOrderId"
                    class="bg-[#2196F3] text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider animate-pulse"
                    title="Nhập trước chế biến trước (FIFO)"
                  >
                    FIFO
                  </span>
                </span>
                <div class="flex items-center gap-1.5 mt-1">
                  <div class="badges">
                    <span
                      v-if="isOrderRemake(order)"
                      class="badge badge-remake"
                    >
                      TRẢ MÓN (REMAKE)
                    </span>
                    <span
                      v-else-if="getOrderClassification(order) === 'Round1'"
                      class="badge badge-buffet-1"
                    >
                      VÒNG 1 (BUFFET)
                    </span>
                    <span
                      v-else-if="getOrderClassification(order) === 'RoundN'"
                      class="badge badge-buffet-add"
                    >
                      GỌI THÊM (BUFFET)
                    </span>
                    <span class="badge badge-alacarte"> A LA CARTE </span>
                  </div>
                </div>
                <span class="text-xs text-muted-foreground font-medium block mt-1.5"
                  >#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span
                >
              </div>
              <span
                class="timer-display"
                :class="getTimerTextClass(order.waitTime)"
              >
                {{ formatWaitTime(order.waitTime) }}
              </span>
            </div>

            <hr class="border-border my-3" />

            <div class="space-y-2">
              <div
                v-for="item in order.displayItems"
                :key="item.id"
                class="flex items-start gap-2.5 p-2 rounded transition-fast cursor-pointer border"
                :class="[
                  item.done
                    ? 'bg-muted border-transparent opacity-60'
                    : isItem86d(item.name)
                      ? 'bg-red-100 border-[#D32F2F] hover:bg-red-950/30'
                      : 'bg-muted/50 border-border hover:bg-muted',
                ]"
                @click.stop="toggleItemStatus(item)"
              >
                <div class="mt-0.5">
                  <input
                    type="checkbox"
                    :checked="item.done"
                    class="w-5.5 h-5.5 rounded border-border text-primary focus:ring-[#ff6b35] bg-background pointer-events-none"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <span
                    class="text-base font-semibold block text-foreground"
                    :class="{ 'line-through text-muted-foreground': item.done }"
                  >
                    <span class="text-primary font-black mr-1 text-lg"
                      >{{ item.qty }}x</span
                    >
                    {{ item.name }}
                  </span>
                  <span
                    v-if="activeStation === 'ALL'"
                    class="inline-block mt-1 text-[10px] bg-muted text-muted-foreground px-1.5 py-0.5 rounded border border-border"
                  >
                    {{ getStationLabel(getItemStation(item.name)) }}
                  </span>

                  <!-- Out of stock warning inside KDS list -->
                  <div
                    v-if="isItem86d(item.name) && !item.done"
                    class="sold-out-warning"
                  >
                    HẾT MÓN (86'd)
                  </div>

                  <div
                    v-if="item.note"
                    class="text-xs text-orange-600 italic mt-1 bg-orange-100 p-1.5 rounded border border-orange-300 flex items-start gap-1"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 flex-shrink-0 text-orange-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                      />
                    </svg>
                    <span>{{ item.note }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4 pt-3 border-t border-border">
              <button
                class="acknowledge-btn"
                @click.stop="moveToPreparing(order)"
              >
                XÁC NHẬN
              </button>
            </div>
          </div>

          <div v-if="pendingOrders.length === 0" class="empty-state">
            <div class="empty-icon">📋</div>
            <div class="empty-title">Không có order mới</div>
            <div class="empty-desc">Order từ POS sẽ xuất hiện ở đây</div>
          </div>
        </section>

        <!-- Cột 2: Đang chế biến (Cooking Orders) -->
        <section class="kanban-column cooking animate-fade-in">
          <div class="kanban-header preparing">
            <span>ĐANG CHẾ BIẾN</span>
            <span class="column-count">{{ preparingOrders.length }}</span>
          </div>

          <div
            v-for="order in preparingOrders"
            :key="order.id"
            class="ticket-card preparing"
            :class="{
              remake: isOrderRemake(order),
              delayed: order.waitTime >= 900,
            }"
            @click="openDetail(order)"
          >
            <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-2xl font-black text-foreground block"
                  >Bàn {{ getTableCode(order.table) }}</span
                >
                <span class="text-xs text-muted-foreground font-medium block mt-1.5"
                  >#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span
                >
              </div>
              <span
                class="timer-display"
                :class="getTimerTextClass(order.waitTime)"
              >
                {{ formatWaitTime(order.waitTime) }}
              </span>
            </div>

            <hr class="border-border my-3" />

            <!-- Items list -->
            <div class="space-y-2">
              <div
                v-for="item in order.displayItems"
                :key="item.id"
                class="flex flex-col p-2.5 rounded transition-fast cursor-pointer border"
                :class="[
                  item.done
                    ? 'bg-muted border-transparent opacity-60'
                    : isItem86d(item.name)
                      ? 'bg-red-100 border-[#D32F2F] hover:bg-red-950/30'
                      : 'bg-muted/50 border-border hover:bg-muted/80',
                ]"
                @click.stop="toggleItemStatus(item)"
              >
                <div class="flex items-start gap-2.5">
                  <div class="mt-0.5">
                    <input
                      type="checkbox"
                      :checked="item.done"
                      class="w-5.5 h-5.5 rounded border-border text-green-500 focus:ring-green-500 bg-background pointer-events-none"
                    />
                  </div>
                  <div class="flex-1 min-w-0">
                    <span
                      class="text-base font-semibold block text-foreground"
                      :class="{ 'line-through text-muted-foreground': item.done }"
                    >
                      <span class="text-blue-600 font-black mr-1 text-lg"
                        >{{ item.qty }}x</span
                      >
                      {{ item.name }}
                    </span>
                  </div>
                </div>

                <!-- Micro checklist for cooking workflow -->
                <div
                  v-if="startedOrders.includes(order.id)"
                  class="micro-checklist"
                  @click.stop
                >
                  <div
                    v-for="step in getItemSubSteps(item.name)"
                    :key="step.key"
                    class="checklist-item"
                    :class="{ completed: isSubStepChecked(item.id, step.key) }"
                  >
                    <input
                      type="checkbox"
                      :checked="isSubStepChecked(item.id, step.key)"
                      @change="toggleSubStep(item.id, step.key)"
                      class="w-5.5 h-5.5 rounded border-border text-green-500 focus:ring-green-500 bg-card cursor-pointer"
                    />
                    <span class="select-none">
                      {{ step.label }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div
              v-if="hasAllergyNote(order)"
              class="mt-3 bg-red-100 border border-red-300 p-2 rounded text-xs text-red-700 font-bold uppercase tracking-wider flex items-center gap-1.5"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              <span>CẢNH BÁO DỊ ỨNG!</span>
            </div>

            <!-- Start / Complete buttons -->
            <div class="mt-4 pt-3 border-t border-border">
              <button
                v-if="!startedOrders.includes(order.id)"
                class="acknowledge-btn bg-amber-600 hover:bg-amber-500"
                @click.stop="openIngredientCheck(order)"
              >
                BẮT ĐẦU
              </button>
              <button
                v-else
                class="complete-btn"
                @click.stop="openQcCheck(order)"
              >
                HOÀN TẤT
              </button>
            </div>
          </div>

          <div v-if="preparingOrders.length === 0" class="empty-state">
            <div class="empty-icon">🔥</div>
            <div class="empty-title">Bếp đang trống</div>
            <div class="empty-desc">Nhấn "Xác Nhận" để bắt đầu</div>
          </div>
        </section>

        <!-- Cột 3: Sẵn sàng ra món (Ready Orders) -->
        <section class="kanban-column ready animate-fade-in">
          <div class="kanban-header ready">
            <span>SẴN SÀNG RA MÓN</span>
            <span class="column-count">{{ readyOrders.length }}</span>
          </div>

          <div
            v-for="order in readyOrders"
            :key="order.id"
            class="ticket-card status-ready"
            @click="openDetail(order)"
          >
            <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-xl font-bold text-foreground block"
                  >Bàn {{ getTableCode(order.table) }}</span
                >
                <span class="text-xs text-muted-foreground font-medium"
                  >#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span
                >
              </div>
              <span
                class="bg-green-100 text-green-700 border border-green-300 px-2 py-0.5 rounded text-xs font-bold uppercase"
              >
                SẴN SÀNG
              </span>
            </div>

            <div class="space-y-1.5 mt-3 text-sm text-muted-foreground">
              <div
                v-for="item in order.displayItems"
                :key="item.id"
                class="flex items-center gap-2"
              >
                <span class="font-bold text-green-500">{{ item.qty }}x</span>
                <span>{{ item.name }}</span>
              </div>
            </div>

            <div class="mt-4 pt-3 border-t border-border">
              <button
                class="complete-btn bg-green-600 hover:bg-green-500"
                @click.stop="moveToDone(order)"
              >
                HOÀN TẤT TICKET
              </button>
            </div>
          </div>

          <div v-if="readyOrders.length === 0" class="empty-state">
            <div class="empty-icon">🛎️</div>
            <div class="empty-title">Chưa có món xong</div>
            <div class="empty-desc">Món nấu xong chuyển sang đây</div>
          </div>
        </section>

        <!-- Cột 4: Hoàn tất (Done Orders) -->
        <section class="kanban-column done animate-fade-in">
          <div class="kanban-header done">
            <span>HOÀN TẤT</span>
            <span class="column-count">{{ doneOrders.length }}</span>
          </div>

          <div
            v-for="order in doneOrders"
            :key="order.id"
            class="ticket-card done"
            @click="openDetail(order)"
          >
            <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-xl font-bold text-muted-foreground line-through block"
                  >Bàn {{ getTableCode(order.table) }}</span
                >
                <span class="text-xs text-muted-foreground font-medium"
                  >#{{ order.id.slice(0, 8) }} &bull; {{ order.time }}</span
                >
              </div>
              <span
                class="bg-muted text-muted-foreground border border-border px-2 py-0.5 rounded text-xs font-bold uppercase"
              >
                ĐÃ PHỤC VỤ
              </span>
            </div>

            <div class="space-y-1.5 mt-3 text-sm text-muted-foreground line-through">
              <div
                v-for="item in order.displayItems"
                :key="item.id"
                class="flex items-center gap-2"
              >
                <span class="font-bold text-foreground">{{ item.qty }}x</span>
                <span>{{ item.name }}</span>
              </div>
            </div>
          </div>

          <div v-if="doneOrders.length === 0" class="empty-state">
            <div class="empty-icon">✅</div>
            <div class="empty-title">Chưa có món hoàn tất</div>
            <div class="empty-desc">Món đã QC duyệt hiển thị ở đây</div>
          </div>
        </section>
      </main>

      <!-- COLLAPSIBLE GRILL & COAL ALERTS SIDEBAR PANEL -->
      <aside
        class="grill-sidebar bg-card border-l border-border flex flex-col h-full"
        :class="{ collapsed: !kitchenStore.isGrillPanelVisible }"
      >
        <button
          class="toggle-sidebar-btn"
          @click="
            kitchenStore.isGrillPanelVisible = !kitchenStore.isGrillPanelVisible
          "
          aria-label="Toggle Grill Sidebar"
        >
          <span class="icon">🔥</span>
          <span
            v-if="!kitchenStore.isGrillPanelVisible"
            class="sidebar-badge"
            >{{ grillRequests.length }}</span
          >
          <span v-else class="label font-bold uppercase tracking-wider text-xs"
            >Yêu cầu Vỉ & Than ({{ grillRequests.length }})</span
          >
        </button>

        <div
          v-if="kitchenStore.isGrillPanelVisible"
          class="sidebar-content flex-1 flex flex-col overflow-hidden"
        >
          <div
            class="p-4 border-b border-border bg-background flex justify-between items-center"
          >
            <h3
              class="text-base font-bold text-primary uppercase tracking-wider flex items-center gap-2"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.655-.398-1.434-.398-2.42a1 1 0 00-1.743-.68 12.012 12.012 0 00-2.812 5.02c-.36 1.157-.507 2.3-.507 3.322 0 1.137.234 2.27.705 3.328a8.041 8.041 0 002.04 2.724c.959.837 2.1 1.432 3.31 1.75a11.93 11.93 0 006.185-.43 8.032 8.032 0 003.88-2.613 8.04 8.04 0 001.696-3.84c.328-1.22.316-2.442-.01-3.608a11.824 11.824 0 00-2.868-5.128M14 10a1 1 0 00-1.707-.707l-1 1a1 1 0 00-.293.707V12a1 1 0 002 0v-.586l.707-.707A1 1 0 0014 10z"
                  clip-rule="evenodd"
                />
              </svg>
              Yêu cầu Vỉ & Than
            </h3>
            <span
              class="bg-primary/20 text-primary px-2.5 py-0.5 rounded-full text-xs font-bold"
            >
              {{ grillRequests.length }}
            </span>
          </div>

          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <!-- Quick Guidelines from kitchen_cooking_flow.mmd -->
            <div
              class="p-3 bg-muted border border-border rounded-xl text-xs text-muted-foreground space-y-1"
            >
              <div class="font-bold text-orange-600 uppercase">
                💡 Quy trình bếp nướng:
              </div>
              <p>1. Định kỳ kiểm tra vỉ nướng & than.</p>
              <p>2. Khi vỉ bẩn / than yếu $\rightarrow$ Gửi yêu cầu thay.</p>
              <p>3. Thay vỉ/châm than mất từ **2 - 3 phút**.</p>
            </div>

            <!-- Active Request list -->
            <div
              v-for="req in grillRequests"
              :key="req.id"
              class="p-4 rounded-xl bg-background border-l-4 shadow-md transition-fast relative"
              :class="
                req.priority === 'Urgent'
                  ? 'border-[#C62828] bg-red-100'
                  : 'border-[#FFA726]'
              "
            >
              <button
                @click="cancelGrillRequest(req)"
                class="absolute top-2 right-2 text-muted-foreground hover:text-foreground transition-fast"
                aria-label="Cancel Grill Request"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>

              <div class="flex justify-between items-baseline mb-2">
                <span class="text-xl font-black text-foreground"
                  >Bàn {{ req.table }}</span
                >
                <span
                  class="text-[10px] px-2 py-0.5 rounded font-bold uppercase"
                  :class="
                    req.priority === 'Urgent'
                      ? 'bg-[#C62828] text-white animate-pulse'
                      : 'bg-muted text-muted-foreground'
                  "
                >
                  {{ req.priority === "Urgent" ? "GẤP" : "THƯỜNG" }}
                </span>
              </div>

              <!-- Type of request -->
              <div
                class="text-sm font-semibold text-foreground mb-3 flex items-center gap-1.5"
              >
                <span
                  class="w-2.5 h-2.5 rounded-full"
                  :class="
                    req.type === 'GrillChange'
                      ? 'bg-purple-500'
                      : 'bg-[#FFA726]'
                  "
                ></span>
                {{
                  req.type === "GrillChange"
                    ? "Yêu cầu thay vỉ nướng"
                    : "Yêu cầu châm thêm than"
                }}
              </div>

              <!-- Progress & Actions -->
              <div v-if="req.status === 'Pending'" class="mt-4">
                <button
                  class="w-full bg-primary hover:bg-[#e55a2b] text-white text-xs font-bold py-2 rounded-lg transition-fast touch-target"
                  @click="startGrillRequest(req)"
                >
                  BẮT ĐẦU THỰC HIỆN
                </button>
              </div>

              <div
                v-else-if="req.status === 'Inprogress'"
                class="space-y-2 mt-3"
              >
                <!-- Timer & Progress Bar -->
                <div
                  class="flex justify-between text-xs text-green-600 font-bold"
                >
                  <span>Đang xử lý...</span>
                  <span>{{ formatWaitTime(req.timeLeft || 0) }}</span>
                </div>
                <div
                  class="w-full bg-muted h-2 rounded-full overflow-hidden"
                >
                  <div
                    class="bg-[#4CAF50] h-full transition-all duration-1000"
                    :style="{ width: `${((req.timeLeft || 0) * 100) / 120}%` }"
                  ></div>
                </div>
                <button
                  class="w-full bg-[#2E7D32] hover:bg-[#256629] text-white text-xs font-bold py-2 rounded-lg transition-fast mt-2 touch-target"
                  @click="completeGrillRequest(req)"
                >
                  HOÀN TẤT NGAY
                </button>
              </div>

              <div class="text-[10px] text-muted-foreground mt-2 font-mono">
                Đã gửi: {{ getRequestElapsedTime(req.createdAt) }} trước
              </div>
            </div>

            <div
              v-if="grillRequests.length === 0"
              class="text-center py-8 text-muted-foreground text-sm"
            >
              <div class="text-3xl mb-2">🔥</div>
              Không có yêu cầu vỉ/than nào đang hoạt động.
            </div>
          </div>
        </div>
      </aside>
    </div>

    <!-- 5. TICKET DETAIL MODAL (600px max) -->
    <div
      v-if="selectedOrder"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="closeDetail"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-[600px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]"
      >
        <!-- Modal Header -->
        <div
          class="px-6 py-4 bg-background border-b border-border flex justify-between items-center"
        >
          <div>
            <h3 class="text-2xl font-black text-foreground">
              Chi tiết Ticket #{{ selectedOrder.id.slice(0, 8) }}
            </h3>
            <p class="text-xs text-muted-foreground mt-1">
              Khởi tạo lúc: {{ selectedOrder.time }} &bull; Đã chờ
              {{ formatWaitTime(selectedOrder.waitTime) }}
            </p>
          </div>
          <button
            @click="closeDetail"
            class="w-10 h-10 rounded-full bg-muted hover:bg-accent flex items-center justify-center border border-border transition-fast text-foreground touch-target"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Modal Content -->
        <div class="p-6 overflow-y-auto space-y-6">
          <!-- Basic Info -->
          <div
            class="grid grid-cols-2 gap-4 bg-background p-4 rounded-xl border border-border"
          >
            <div>
              <span class="text-xs text-muted-foreground uppercase font-bold block"
                >Bàn vật lý</span
              >
              <span class="text-2xl font-black text-foreground"
                >Bàn {{ getTableCode(selectedOrder.table) }}</span
              >
            </div>
            <div>
              <span class="text-xs text-muted-foreground uppercase font-bold block"
                >Trạng thái hiện tại</span
              >
              <span
                class="text-lg font-bold block mt-1"
                :class="
                  selectedOrder.status === 'pending'
                    ? 'text-indigo-400'
                    : selectedOrder.status === 'preparing'
                      ? 'text-orange-700'
                      : 'text-green-700'
                "
              >
                {{
                  selectedOrder.status === "pending"
                    ? "Đang chờ chế biến"
                    : selectedOrder.status === "preparing"
                      ? "Đang chế biến"
                      : "Đã hoàn thành"
                }}
              </span>
            </div>
          </div>

          <!-- Items list -->
          <div>
            <h4
              class="text-xs text-muted-foreground uppercase font-bold tracking-wider mb-3"
            >
              Danh sách món chế biến
            </h4>
            <div class="space-y-3">
              <div
                v-for="item in selectedOrder.items"
                :key="item.id"
                class="flex items-start gap-4 p-4 rounded-xl transition-fast cursor-pointer border"
                :class="[
                  item.done
                    ? 'bg-background border-transparent opacity-60'
                    : isItem86d(item.name)
                      ? 'bg-red-100 border-[#D32F2F] hover:bg-red-950/30'
                      : 'bg-background border-border hover:bg-muted/50',
                ]"
                @click="toggleItemStatus(item)"
              >
                <div class="mt-1">
                  <input
                    type="checkbox"
                    :checked="item.done"
                    class="w-6 h-6 rounded border-border text-green-500 focus:ring-green-500 bg-card pointer-events-none"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex justify-between items-baseline">
                    <span
                      class="text-lg font-bold text-foreground block"
                      :class="{ 'line-through text-muted-foreground': item.done }"
                    >
                      <span class="text-primary font-black text-xl mr-1"
                        >{{ item.qty }}x</span
                      >
                      {{ item.name }}
                      <span
                        v-if="isItem86d(item.name) && !item.done"
                        class="ml-2 inline-block px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase bg-[#D32F2F] text-white animate-pulse"
                      >
                        ⚠️ HẾT MÓN (86'd)
                      </span>
                    </span>
                    <span
                      class="text-xs text-muted-foreground bg-card px-2 py-0.5 rounded border border-border"
                    >
                      {{ getStationLabel(getItemStation(item.name)) }}
                    </span>
                  </div>
                  <!-- 86'd call staff action button -->
                  <div
                    v-if="isItem86d(item.name) && !item.done"
                    class="mt-2 flex gap-2"
                  >
                    <button
                      @click.stop="
                        notifyStaffAbout86d(
                          item.name,
                          getTableCode(selectedOrder.table),
                        )
                      "
                      class="px-3 py-1 bg-red-800 hover:bg-red-700 text-foreground rounded-lg text-xs font-bold uppercase transition-fast flex items-center gap-1.5 shadow-sm touch-target"
                      title="Báo phục vụ thay món khác cho khách"
                    >
                      📢 Báo Phục Vụ Đổi Món
                    </button>
                  </div>
                  <!-- Quick actions inside detail modal from kitchen_cooking_flow.mmd -->
                  <div
                    v-if="
                      getItemStation(item.name) === 'Grill' &&
                      selectedOrder.status === 'preparing'
                    "
                    class="flex items-center gap-2 mt-2"
                  >
                    <button
                      @click.stop="
                        triggerQuickRequest(selectedOrder.table, 'GrillChange')
                      "
                      class="px-2.5 py-1 bg-purple-100 border border-purple-300 rounded text-xs font-bold text-purple-700 hover:bg-purple-100 transition-fast touch-target"
                    >
                      🧹 Thay vỉ nướng
                    </button>
                    <button
                      @click.stop="
                        triggerQuickRequest(selectedOrder.table, 'CoalRefill')
                      "
                      class="px-2.5 py-1 bg-orange-100 border border-orange-300 rounded text-xs font-bold text-primary hover:bg-orange-100 transition-fast touch-target"
                    >
                      🔥 Châm thêm than
                    </button>
                  </div>
                  <div
                    v-if="item.note"
                    class="text-sm text-orange-600 italic mt-2 bg-orange-100 p-2.5 rounded border border-orange-300 flex items-start gap-1.5"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5 flex-shrink-0 text-orange-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                      />
                    </svg>
                    <span>Ghi chú: {{ item.note }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Highlight notes / Allergies -->
          <div
            v-if="hasAllergyNote(selectedOrder)"
            class="bg-red-100 border border-red-300 p-4 rounded-xl text-red-600 flex items-start gap-3"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 flex-shrink-0 text-red-600 mt-0.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
            <div>
              <span class="font-bold text-base block uppercase tracking-wider"
                >Cảnh báo nghiêm trọng: Dị ứng thực phẩm!</span
              >
              <p class="text-sm text-red-700 mt-1">
                Đơn hàng này có chứa các yêu cầu đặc biệt về dị ứng hoặc loại bỏ
                nguyên liệu. Vui lòng đối soát kỹ lưỡng trước khi bưng món.
              </p>
            </div>
          </div>
        </div>

        <!-- Modal Footer Actions (Touch target large: 56px) -->
        <div
          class="px-6 py-4 bg-background border-t border-border flex justify-between items-center gap-3"
        >
          <div>
            <button
              class="px-4 py-2 rounded-xl text-xs font-bold border transition-fast touch-target"
              :class="
                isOrderRemake(selectedOrder)
                  ? 'bg-[#C62828]/20 border-red-500 text-red-700'
                  : 'bg-muted border-border text-muted-foreground hover:text-foreground'
              "
              @click="toggleOrderRemake(selectedOrder.id)"
            >
              {{
                isOrderRemake(selectedOrder)
                  ? "🚨 Hủy Trả Món (Remake)"
                  : "⚠️ Đánh dấu Trả Món (Remake)"
              }}
            </button>
          </div>
          <div class="flex gap-3">
            <button
              @click="closeDetail"
              class="action-button danger large border border-border bg-card hover:bg-muted text-foreground rounded-xl font-bold transition-fast touch-target-large"
            >
              Đóng
            </button>
            <button
              v-if="selectedOrder.status === 'pending'"
              class="action-button primary large bg-primary text-primary-foreground rounded-xl font-bold transition-fast touch-target-large"
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
    </div>

    <!-- NEW FEATURE: GRILL & COAL REQUEST CREATION MODAL -->
    <div
      v-if="showGrillRequestModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-fade-in"
      @click.self="showGrillRequestModal = false"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-[450px] shadow-2xl p-6 space-y-5"
      >
        <div
          class="flex justify-between items-center pb-2 border-b border-border"
        >
          <h3 class="text-xl font-black text-foreground">
            Yêu cầu Thay Vỉ / Châm Than
          </h3>
          <button
            @click="showGrillRequestModal = false"
            class="text-muted-foreground hover:text-foreground transition-fast"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Form fields -->
        <div class="space-y-4">
          <!-- Table selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold"
              >Chọn bàn cần xử lý</label
            >
            <select
              v-model="newRequestTable"
              class="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:outline-none focus:border-primary"
            >
              <option value="" disabled>-- Chọn Bàn --</option>
              <option
                v-for="tbl in availableTablesForRequests"
                :key="tbl"
                :value="tbl"
              >
                Bàn {{ tbl }}
              </option>
            </select>
          </div>

          <!-- Type selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold"
              >Loại yêu cầu</label
            >
            <div class="grid grid-cols-2 gap-3">
              <button
                class="px-4 py-3 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="
                  newRequestType === 'GrillChange'
                    ? 'bg-purple-100 border-purple-500 text-purple-200'
                    : 'bg-background border-border text-muted-foreground'
                "
                @click="newRequestType = 'GrillChange'"
              >
                Thay Vỉ Nướng
              </button>
              <button
                class="px-4 py-3 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="
                  newRequestType === 'CoalRefill'
                    ? 'bg-orange-100 border-primary text-primary'
                    : 'bg-background border-border text-muted-foreground'
                "
                @click="newRequestType = 'CoalRefill'"
              >
                Châm Thêm Than
              </button>
            </div>
          </div>

          <!-- Priority selector -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold"
              >Mức độ ưu tiên</label
            >
            <div class="grid grid-cols-2 gap-3">
              <button
                class="px-4 py-2.5 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="
                  newRequestPriority === 'Normal'
                    ? 'bg-muted border-border text-foreground'
                    : 'bg-background border-border text-muted-foreground'
                "
                @click="newRequestPriority = 'Normal'"
              >
                Thường
              </button>
              <button
                class="px-4 py-2.5 rounded-xl border text-sm font-bold transition-fast touch-target"
                :class="
                  newRequestPriority === 'Urgent'
                    ? 'bg-red-100 border-red-500 text-red-700'
                    : 'bg-background border-border text-muted-foreground'
                "
                @click="newRequestPriority = 'Urgent'"
              >
                Gấp (Urgent)
              </button>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="flex justify-end gap-3 pt-3 border-t border-border">
          <button
            class="px-4 py-2.5 bg-muted hover:bg-accent rounded-xl text-xs font-bold transition-fast text-muted-foreground touch-target"
            @click="showGrillRequestModal = false"
          >
            Hủy bỏ
          </button>
          <button
            class="px-6 py-2.5 bg-primary hover:bg-[#e55a2b] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-foreground transition-fast touch-target"
            :disabled="!newRequestTable"
            @click="createGrillRequest"
          >
            Gửi yêu cầu
          </button>
        </div>
      </div>
    </div>

    <!-- NEW FEATURE: KITCHEN HYGIENE & SAFETY (HACCP) MODAL -->
    <div
      v-if="showHaccpModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="showHaccpModal = false"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-[700px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]"
      >
        <!-- Modal Header -->
        <div
          class="px-6 py-4 bg-background border-b border-border flex justify-between items-center"
        >
          <div class="flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-green-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
              />
            </svg>
            <div>
              <h3
                class="text-xl font-black text-foreground uppercase tracking-wider"
              >
                Nhật Ký An Toàn & Vệ Sinh HACCP
              </h3>
              <p class="text-xs text-muted-foreground">
                Giám sát chất lượng & tuân thủ quy chuẩn nhà bếp
              </p>
            </div>
          </div>
          <button
            @click="showHaccpModal = false"
            class="w-10 h-10 rounded-full bg-muted hover:bg-accent flex items-center justify-center border border-border transition-fast text-foreground touch-target"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Modal Tabs -->
        <div class="flex bg-background border-b border-border">
          <button
            v-for="tab in [
              { key: 'preshift', label: '1. Đầu Ca (Pre-Shift)' },
              { key: 'incidents', label: '2. Giám Sát Ca (Monitoring)' },
              { key: 'postshift', label: '3. Cuối Ca (Post-Shift)' },
              { key: 'approval', label: '4. Phê Duyệt (Sign-off)' },
            ]"
            :key="tab.key"
            @click="haccpActiveTab = tab.key"
            class="flex-1 py-3 text-xs font-bold uppercase tracking-wider border-b-2 text-center transition-all touch-target"
            :class="
              haccpActiveTab === tab.key
                ? 'text-green-600 border-[#4CAF50] bg-card/30'
                : 'text-muted-foreground border-transparent hover:text-foreground'
            "
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Modal Body Content -->
        <div class="p-6 overflow-y-auto space-y-6 flex-1 bg-card">
          <!-- TAB 1: PRE-SHIFT -->
          <div
            v-if="haccpActiveTab === 'preshift'"
            class="space-y-5 animate-fade-in"
          >
            <div
              class="p-4 bg-muted border border-border rounded-xl space-y-4"
            >
              <h4
                class="text-sm font-bold text-green-600 uppercase tracking-wide"
              >
                📋 Khảo sát vệ sinh đầu ngày
              </h4>

              <!-- Personal Hygiene Checkbox -->
              <label
                class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-background border border-border hover:bg-background transition-fast"
              >
                <input
                  type="checkbox"
                  v-model="haccpPreHandHygiene"
                  :disabled="haccpPreSaved"
                  class="w-5.5 h-5.5 rounded border-border text-green-600 focus:ring-[#4CAF50] bg-background"
                />
                <div class="text-sm select-none">
                  <span class="font-bold text-foreground block"
                    >Vệ sinh cá nhân đạt chuẩn</span
                  >
                  <span class="text-xs text-muted-foreground"
                    >Rửa tay sát khuẩn, đeo khẩu trang, đội mũ bếp, mặc tạp dề
                    sạch sẽ trước khi vào khu vực chế biến.</span
                  >
                </div>
              </label>

              <!-- FEFO Expiration Checkbox -->
              <label
                class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-background border border-border hover:bg-background transition-fast"
              >
                <input
                  type="checkbox"
                  v-model="haccpPreFefoChecked"
                  :disabled="haccpPreSaved"
                  class="w-5.5 h-5.5 rounded border-border text-green-600 focus:ring-[#4CAF50] bg-background"
                />
                <div class="text-sm select-none">
                  <span class="font-bold text-foreground block"
                    >Kiểm tra hạn sử dụng (Áp dụng FEFO)</span
                  >
                  <span class="text-xs text-muted-foreground"
                    >First Expired, First Out - Đảm bảo các nguyên liệu sắp hết
                    hạn được xếp ra ngoài và sử dụng trước.</span
                  >
                </div>
              </label>
            </div>

            <!-- Temperature log -->
            <div
              class="p-4 bg-muted border border-border rounded-xl space-y-4"
            >
              <h4
                class="text-sm font-bold text-green-600 uppercase tracking-wide"
              >
                ❄️ Đo nhiệt độ hệ thống bảo quản
              </h4>

              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-2">
                  <label class="text-xs text-muted-foreground uppercase font-bold block"
                    >Tủ mát bảo quản (Chuẩn: 0 - 5°C)</label
                  >
                  <div class="relative">
                    <input
                      type="number"
                      v-model="haccpPreFridgeTemp"
                      :disabled="haccpPreSaved"
                      step="0.5"
                      class="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground text-lg font-bold focus:outline-none focus:border-[#4CAF50] pr-10"
                    />
                    <span
                      class="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold"
                      >°C</span
                    >
                  </div>
                </div>

                <div class="space-y-2">
                  <label class="text-xs text-muted-foreground uppercase font-bold block"
                    >Tủ đông bảo quản (Chuẩn: &le; -18°C)</label
                  >
                  <div class="relative">
                    <input
                      type="number"
                      v-model="haccpPreFreezerTemp"
                      :disabled="haccpPreSaved"
                      step="0.5"
                      class="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground text-lg font-bold focus:outline-none focus:border-[#4CAF50] pr-10"
                    />
                    <span
                      class="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold"
                      >°C</span
                    >
                  </div>
                </div>
              </div>

              <!-- Temperature Out-of-bounds Alerts -->
              <div
                v-if="isTempAlertActive"
                class="p-4 bg-red-100 border border-red-300 rounded-xl space-y-3"
              >
                <div class="flex items-start gap-2.5 text-red-700">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6 flex-shrink-0"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    />
                  </svg>
                  <div>
                    <span
                      class="font-bold text-base block uppercase tracking-wider"
                      >⚠️ CẢNH BÁO BÁO ĐỘNG KHẨN CẤP</span
                    >
                    <span class="text-xs text-red-700"
                      >Nhiệt độ hệ thống bảo quản vượt ngưỡng an toàn! Yêu cầu
                      chuyển toàn bộ nguyên liệu sang tủ dự phòng để tránh hư
                      hỏng thực phẩm.</span
                    >
                  </div>
                </div>

                <label
                  v-if="!haccpPreSaved"
                  class="flex items-center gap-2 mt-2 cursor-pointer p-2 rounded bg-red-100 hover:bg-red-100 border border-red-300 transition-fast"
                >
                  <input
                    type="checkbox"
                    v-model="tempTransferConfirmed"
                    class="w-4.5 h-4.5 rounded border-red-600 text-red-500 focus:ring-red-500 bg-background"
                  />
                  <span class="text-xs font-bold text-red-700 select-none"
                    >Tôi xác nhận đã chuyển nguyên liệu an toàn sang tủ dự phòng
                    khẩn cấp</span
                  >
                </label>
              </div>
            </div>

            <!-- Save Pre-Shift Actions -->
            <div class="flex justify-end pt-2 border-t border-border">
              <button
                v-if="!haccpPreSaved"
                @click="savePreShiftHaccp"
                class="px-6 py-2.5 bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-foreground transition-fast touch-target"
                :disabled="
                  !haccpPreHandHygiene ||
                  !haccpPreFefoChecked ||
                  (isTempAlertActive && !tempTransferConfirmed)
                "
              >
                Ghi nhận đầu ca (HACCP)
              </button>
              <div
                v-else
                class="p-3 bg-[#4CAF50]/15 border border-[#4CAF50]/40 rounded-xl text-green-600 text-xs font-bold flex items-center gap-1.5 w-full justify-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"
                  />
                </svg>
                ĐÃ LƯU NHẬT KÝ ĐẦU CA - TỦ MÁT: {{ haccpPreFridgeTemp }}°C, TỦ
                ĐÔNG: {{ haccpPreFreezerTemp }}°C
              </div>
            </div>
          </div>

          <!-- TAB 2: MONITORING / INCIDENTS -->
          <div
            v-if="haccpActiveTab === 'incidents'"
            class="space-y-5 animate-fade-in"
          >
            <div class="flex justify-between items-center">
              <h4
                class="text-sm font-bold text-orange-600 uppercase tracking-wide"
              >
                🚨 Nhật ký giám sát & Sự cố vệ sinh
              </h4>
              <button
                v-if="!showNewIncidentForm"
                @click="showNewIncidentForm = true"
                class="bg-primary hover:bg-[#e55a2b] text-white px-3 py-1.5 rounded-lg text-xs font-bold transition-fast touch-target"
              >
                + Báo cáo sự cố mới
              </button>
            </div>

            <!-- New Incident Form -->
            <div
              v-if="showNewIncidentForm"
              class="p-4 bg-muted border border-[#FFA726]/30 rounded-xl space-y-4 animate-fade-in"
            >
              <div
                class="flex justify-between items-center pb-2 border-b border-border"
              >
                <span class="text-xs font-bold text-orange-600 uppercase"
                  >Báo cáo Sự cố mới</span
                >
                <button
                  @click="showNewIncidentForm = false"
                  class="text-muted-foreground hover:text-foreground text-xs"
                >
                  Hủy
                </button>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-1.5">
                  <label class="text-[10px] text-muted-foreground uppercase font-bold"
                    >Người báo cáo</label
                  >
                  <input
                    type="text"
                    v-model="newIncidentReporter"
                    placeholder="Tên nhân viên..."
                    class="w-full bg-background border border-border rounded-xl px-3 py-2 text-foreground text-sm focus:outline-none focus:border-[#FFA726]"
                  />
                </div>
                <div class="space-y-1.5">
                  <label class="text-[10px] text-muted-foreground uppercase font-bold"
                    >Phân loại sự cố</label
                  >
                  <select
                    v-model="newIncidentType"
                    class="w-full bg-background border border-border rounded-xl px-3 py-2 text-foreground text-sm focus:outline-none focus:border-[#FFA726]"
                  >
                    <option value="FoodDrop">
                      Rơi thức ăn xuống sàn (Dropped Food)
                    </option>
                    <option value="CutHand">
                      Tai nạn đứt tay / Chấn thương (Injury)
                    </option>
                    <option value="CrossContamination">
                      Nhiễm chéo thực phẩm (Cross Contamination)
                    </option>
                    <option value="Other">Sự cố vệ sinh khác (Other)</option>
                  </select>
                </div>
              </div>

              <div class="space-y-1.5">
                <label class="text-[10px] text-muted-foreground uppercase font-bold"
                  >Mô tả chi tiết & Hành động khắc phục ban đầu</label
                >
                <textarea
                  v-model="newIncidentDescription"
                  rows="3"
                  placeholder="Mô tả sự việc và các bước đã xử lý ngay lập tức..."
                  class="w-full bg-background border border-border rounded-xl px-3 py-2 text-foreground text-sm focus:outline-none focus:border-[#FFA726]"
                ></textarea>
              </div>

              <div class="flex justify-end gap-2">
                <button
                  @click="showNewIncidentForm = false"
                  class="px-4 py-2 bg-muted hover:bg-accent rounded-xl text-xs font-bold text-muted-foreground touch-target"
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
              <div
                v-for="inc in haccpIncidents"
                :key="inc.id"
                class="p-4 bg-background border-l-4 rounded-xl shadow-md transition-fast relative"
                :class="
                  inc.status === 'Pending'
                    ? 'border-[#C62828] bg-red-950/5'
                    : 'border-border opacity-70'
                "
              >
                <button
                  v-if="inc.status === 'Pending'"
                  @click="
                    haccpIncidents = haccpIncidents.filter(
                      (i) => i.id !== inc.id,
                    );
                    saveHaccpState();
                  "
                  class="absolute top-2 right-2 text-muted-foreground hover:text-foreground transition-fast"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>

                <div class="flex justify-between items-baseline mb-2">
                  <div class="flex items-center gap-2">
                    <span
                      class="text-xs font-bold bg-muted text-muted-foreground px-2 py-0.5 rounded"
                    >
                      {{ inc.reporter }}
                    </span>
                    <span class="text-[10px] text-muted-foreground font-mono">
                      {{ new Date(inc.timestamp).toLocaleTimeString() }}
                    </span>
                  </div>
                  <span
                    class="text-[10px] px-2 py-0.5 rounded font-bold uppercase"
                    :class="
                      inc.status === 'Pending'
                        ? 'bg-[#C62828] text-white animate-pulse'
                        : 'bg-green-950 text-green-700 border border-green-800'
                    "
                  >
                    {{
                      inc.status === "Pending"
                        ? "Đang xử lý y tế / vệ sinh"
                        : "Đã xử lý xong"
                    }}
                  </span>
                </div>

                <div class="text-sm font-semibold text-foreground mb-1">
                  {{
                    inc.type === "FoodDrop"
                      ? "🍕 Rơi thức ăn xuống sàn"
                      : inc.type === "CutHand"
                        ? "🩹 Sơ cứu chấn thương"
                        : inc.type === "CrossContamination"
                          ? "🧬 Nghi ngờ nhiễm chéo"
                          : "⚠️ Sự cố vệ sinh khác"
                  }}
                </div>
                <p class="text-xs text-muted-foreground">{{ inc.description }}</p>

                <!-- Resolution section -->
                <div
                  v-if="inc.status === 'Pending'"
                  class="mt-3 pt-3 border-t border-border/40 flex justify-end"
                >
                  <button
                    @click="resolveIncidentPrompt(inc)"
                    class="bg-[#2E7D32] hover:bg-[#256629] text-white text-[10px] font-bold px-3 py-1.5 rounded-lg transition-fast touch-target"
                  >
                    XÁC NHẬN ĐÃ XỬ LÝ (SƠ CỨU/DỌN DẸP)
                  </button>
                </div>
                <div
                  v-else
                  class="mt-2 bg-card/60 p-2 rounded text-xs border border-green-300 text-green-700"
                >
                  <span class="font-bold block">Biện pháp khắc phục:</span>
                  <span class="italic text-muted-foreground">{{
                    inc.resolutionNote
                  }}</span>
                </div>
              </div>

              <div
                v-if="haccpIncidents.length === 0"
                class="text-center py-8 text-muted-foreground text-sm"
              >
                <div class="text-3xl mb-2">🍏</div>
                Không ghi nhận sự cố vệ sinh nào trong ca trực.
              </div>
            </div>
          </div>

          <!-- TAB 3: POST-SHIFT -->
          <div
            v-if="haccpActiveTab === 'postshift'"
            class="space-y-5 animate-fade-in"
          >
            <div
              class="p-4 bg-muted border border-border rounded-xl space-y-4"
            >
              <h4
                class="text-sm font-bold text-green-600 uppercase tracking-wide"
              >
                🧹 Quy trình đóng ca & Dọn dẹp vệ sinh
              </h4>

              <!-- Surface cleaning checkbox -->
              <label
                class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-background border border-border hover:bg-background transition-fast"
              >
                <input
                  type="checkbox"
                  v-model="haccpPostCleaning"
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-border text-green-600 focus:ring-[#4CAF50] bg-background"
                />
                <div class="text-sm select-none">
                  <span class="font-bold text-foreground block"
                    >Vệ sinh bề mặt bàn bếp & Thiết bị chế biến</span
                  >
                  <span class="text-xs text-muted-foreground"
                    >Lau chùi bằng hóa chất sát khuẩn được cấp phép cho thớt, bề
                    mặt bếp inox, dao kéo và lò nướng.</span
                  >
                </div>
              </label>

              <!-- Waste sorting checkbox -->
              <label
                class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-background border border-border hover:bg-background transition-fast"
              >
                <input
                  type="checkbox"
                  v-model="haccpPostWasteSorting"
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-border text-green-600 focus:ring-[#4CAF50] bg-background"
                />
                <div class="text-sm select-none">
                  <span class="font-bold text-foreground block"
                    >Phân loại & Thu gom rác thải</span
                  >
                  <span class="text-xs text-muted-foreground"
                    >Đổ rác hữu cơ, rửa thùng rác, thay túi đựng rác mới và mang
                    rác đến đúng nơi tập kết quy định.</span
                  >
                </div>
              </label>

              <!-- Leftover wrap/labels checkbox -->
              <label
                class="flex items-start gap-3 cursor-pointer p-3 rounded-lg bg-background border border-border hover:bg-background transition-fast"
              >
                <input
                  type="checkbox"
                  v-model="haccpPostLeftoversStored"
                  :disabled="haccpPostSaved"
                  class="w-5.5 h-5.5 rounded border-border text-green-600 focus:ring-[#4CAF50] bg-background"
                />
                <div class="text-sm select-none">
                  <span class="font-bold text-foreground block"
                    >Bảo quản nguyên liệu thừa</span
                  >
                  <span class="text-xs text-muted-foreground"
                    >Các phần thịt, rau tươi chưa dùng hết cần bọc kín bằng màng
                    co thực phẩm và dán nhãn thông tin ngày dán/hạn dùng.</span
                  >
                </div>
              </label>
            </div>

            <!-- Notes -->
            <div class="space-y-1.5">
              <label class="text-xs text-muted-foreground uppercase font-bold"
                >Ghi chú vận hành bàn giao ca tiếp theo (HACCP)</label
              >
              <textarea
                v-model="haccpPostShiftNote"
                rows="3"
                :disabled="haccpPostSaved"
                placeholder="Nhập ghi chú bàn giao hoặc các thiết bị cần bảo trì..."
                class="w-full bg-background border border-border rounded-xl px-3 py-2 text-foreground text-sm focus:outline-none focus:border-[#4CAF50]"
              ></textarea>
            </div>

            <!-- Actions -->
            <div class="flex justify-end pt-2 border-t border-border">
              <button
                v-if="!haccpPostSaved"
                @click="savePostShiftHaccp"
                class="px-6 py-2.5 bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl text-xs font-bold text-foreground transition-fast touch-target"
                :disabled="
                  !haccpPostCleaning ||
                  !haccpPostWasteSorting ||
                  !haccpPostLeftoversStored ||
                  unresolvedIncidentCount > 0
                "
              >
                Ghi nhận cuối ca (Digital HACCP Log)
              </button>
              <div
                v-else
                class="p-3 bg-[#4CAF50]/15 border border-[#4CAF50]/40 rounded-xl text-green-600 text-xs font-bold flex items-center gap-1.5 w-full justify-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"
                  />
                </svg>
                ĐÃ LƯU BÁO CÁO CUỐI CA. HỒ SƠ ĐÃ SẴN SÀNG ĐỂ BẾP TRƯỞNG PHÊ
                DUYỆT.
              </div>
            </div>
          </div>

          <!-- TAB 4: APPROVAL / HEAD CHEF SIGN-OFF -->
          <div
            v-if="haccpActiveTab === 'approval'"
            class="space-y-5 animate-fade-in"
          >
            <div
              class="p-4 bg-muted border border-border rounded-xl space-y-4"
            >
              <h4
                class="text-sm font-bold text-blue-600 uppercase tracking-wide"
              >
                🔬 Báo cáo tổng hợp ca trực (HACCP Summary)
              </h4>

              <div class="space-y-2.5 text-sm text-muted-foreground">
                <div class="flex justify-between border-b border-border pb-2">
                  <span>Trạng thái Kiểm tra đầu ca:</span>
                  <span
                    class="font-bold"
                    :class="
                      haccpPreSaved ? 'text-green-700' : 'text-yellow-500'
                    "
                  >
                    {{ haccpPreSaved ? "Đã hoàn thành" : "Chưa hoàn thành" }}
                  </span>
                </div>
                <div class="flex justify-between border-b border-border pb-2">
                  <span>Nhiệt độ đo đạc (Đầu ngày):</span>
                  <span class="font-bold"
                    >Tủ mát: {{ haccpPreFridgeTemp }}°C, Tủ đông:
                    {{ haccpPreFreezerTemp }}°C</span
                  >
                </div>
                <div class="flex justify-between border-b border-border pb-2">
                  <span>Tổng số Sự cố vệ sinh ghi nhận:</span>
                  <span
                    class="font-bold"
                    :class="
                      haccpIncidents.length > 0
                        ? 'text-yellow-500'
                        : 'text-green-700'
                    "
                  >
                    {{ haccpIncidents.length }} (Đã giải quyết:
                    {{
                      haccpIncidents.filter((i) => i.status === "Resolved")
                        .length
                    }})
                  </span>
                </div>
                <div class="flex justify-between border-b border-border pb-2">
                  <span>Trạng thái Vệ sinh đóng ca:</span>
                  <span
                    class="font-bold"
                    :class="
                      haccpPostSaved ? 'text-green-700' : 'text-yellow-500'
                    "
                  >
                    {{ haccpPostSaved ? "Đã hoàn thành" : "Chưa hoàn thành" }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Sign-off Form -->
            <div
              class="p-4 bg-muted border border-border rounded-xl space-y-4"
            >
              <h4
                class="text-sm font-bold text-blue-600 uppercase tracking-wide"
              >
                ✍️ Chữ ký phê duyệt của Bếp Trưởng
              </h4>

              <div class="space-y-4" v-if="!haccpHeadChefApproved">
                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="text-xs text-muted-foreground uppercase font-bold"
                      >Tên Bếp Trưởng / Giám sát bếp</label
                    >
                    <input
                      type="text"
                      v-model="haccpChefName"
                      placeholder="Bếp Trưởng ký tên..."
                      class="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground text-sm focus:outline-none focus:border-[#2196F3]"
                    />
                  </div>
                  <div class="space-y-1.5">
                    <label class="text-xs text-muted-foreground uppercase font-bold"
                      >Đánh giá chung chất lượng vệ sinh ca</label
                    >
                    <select
                      v-model="haccpHaccpStatus"
                      class="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground text-sm focus:outline-none focus:border-[#2196F3]"
                    >
                      <option value="Compliant">
                        ĐẠT CHUẨN VỆ SINH & AN TOÀN HACCP
                      </option>
                      <option value="NonCompliant">
                        CÓ VI PHẠM (Yêu cầu họp bàn/huấn luyện lại)
                      </option>
                    </select>
                  </div>
                </div>

                <div class="space-y-1.5">
                  <label class="text-xs text-muted-foreground uppercase font-bold"
                    >Nhận xét của Bếp Trưởng & Kế hoạch cải thiện</label
                  >
                  <textarea
                    v-model="haccpActionNote"
                    rows="3"
                    placeholder="Mô tả các điểm vi phạm nếu có hoặc hành động khắc phục huấn luyện..."
                    class="w-full bg-background border border-border rounded-xl px-3 py-2 text-foreground text-sm focus:outline-none focus:border-[#2196F3]"
                  ></textarea>
                </div>

                <button
                  @click="approveShiftHaccp"
                  :disabled="
                    !haccpChefName || !haccpPreSaved || !haccpPostSaved
                  "
                  class="w-full bg-[#2196F3] hover:bg-[#1976d2] disabled:opacity-50 disabled:cursor-not-allowed text-foreground text-sm font-bold py-3 rounded-xl transition-fast touch-target-large"
                >
                  KÝ XÁC NHẬN & LƯU HỒ SƠ LƯU TRỮ HACCP
                </button>
              </div>

              <!-- Approved Display -->
              <div v-else class="space-y-3">
                <div
                  class="p-4 bg-green-100 border border-green-300 rounded-xl text-green-700 text-center space-y-2"
                >
                  <div class="text-4xl">🏆</div>
                  <div class="font-black text-lg">
                    HỒ SƠ HACCP ĐÃ ĐƯỢC PHÊ DUYỆT & LƯU TRỮ
                  </div>
                  <p class="text-xs text-muted-foreground">
                    Được phê duyệt bởi Bếp Trưởng **{{ haccpChefName }}** vào
                    lúc {{ new Date().toLocaleString() }}
                  </p>
                  <span
                    class="inline-block mt-2 bg-green-100 border border-green-300 px-3 py-1 rounded text-xs font-bold uppercase"
                  >
                    {{
                      haccpHaccpStatus === "Compliant"
                        ? "Đạt chuẩn HACCP"
                        : "Có vi phạm - Họp huấn luyện lại"
                    }}
                  </span>
                </div>

                <button
                  @click="resetHaccpForNewShift"
                  class="w-full bg-muted hover:bg-accent border border-border text-muted-foreground text-xs font-bold py-2.5 rounded-xl transition-fast touch-target"
                >
                  BẮT ĐẦU CA TRỰC MỚI (RESET LOGS)
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="px-6 py-4 bg-background border-t border-border flex justify-end"
        >
          <button
            @click="showHaccpModal = false"
            class="px-6 py-2.5 bg-muted hover:bg-accent text-foreground border border-border rounded-xl font-bold transition-fast touch-target"
          >
            Đóng bảng
          </button>
        </div>
      </div>
    </div>

    <!-- NEW FEATURE: PREP LIST (SƠ CHẾ ĐẦU CA) MODAL -->
    <div
      v-if="showPrepModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="showPrepModal = false"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-[650px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]"
      >
        <!-- Modal Header -->
        <div
          class="px-6 py-4 bg-background border-b border-border flex justify-between items-center"
        >
          <div class="flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-blue-700"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
            <div>
              <h3
                class="text-xl font-black text-foreground uppercase tracking-wider"
              >
                Bảng Sơ Chế Đầu Ca (Prep List)
              </h3>
              <p class="text-xs text-muted-foreground">
                Dự báo định lượng dựa trên danh sách đặt bàn hôm nay
              </p>
            </div>
          </div>
          <button
            @click="showPrepModal = false"
            class="w-10 h-10 rounded-full bg-muted hover:bg-accent flex items-center justify-center border border-border transition-fast text-foreground touch-target"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Modal Body Content -->
        <div class="p-6 overflow-y-auto space-y-6 flex-1 bg-card">
          <!-- Booking & expected guest forecast card -->
          <div
            class="grid grid-cols-3 gap-4 bg-background p-4 rounded-xl border border-border"
          >
            <div>
              <span class="text-xs text-muted-foreground uppercase font-bold block"
                >Tổng đặt bàn</span
              >
              <span class="text-2xl font-black text-foreground"
                >{{ todayBookingsCount }} bàn</span
              >
            </div>
            <div>
              <span class="text-xs text-muted-foreground uppercase font-bold block"
                >Số khách dự kiến</span
              >
              <span class="text-2xl font-black text-foreground"
                >{{ todayExpectedGuests }} khách</span
              >
            </div>
            <div>
              <span class="text-xs text-muted-foreground uppercase font-bold block"
                >Trạng thái bếp</span
              >
              <span
                class="text-lg block mt-1"
                :class="kitchenPrepStatus.colorClass"
              >
                {{ kitchenPrepStatus.label }}
              </span>
            </div>
          </div>

          <!-- Forecast quantity table -->
          <div class="space-y-3">
            <h4
              class="text-xs text-muted-foreground uppercase font-bold tracking-wider"
            >
              🥩 Dự báo định lượng sơ chế (Expected Ingredients)
            </h4>
            <div class="grid grid-cols-2 gap-3">
              <div
                class="p-3 bg-muted border border-border rounded-xl flex justify-between items-center"
              >
                <div>
                  <span class="text-xs text-muted-foreground block"
                    >Thịt bò Wagyu lẩu</span
                  >
                  <span class="text-sm font-bold text-foreground"
                    >Chuẩn bị thái mỏng</span
                  >
                </div>
                <span class="text-lg font-black text-primary"
                  >{{ (todayExpectedGuests * 0.3).toFixed(1) }} kg</span
                >
              </div>
              <div
                class="p-3 bg-muted border border-border rounded-xl flex justify-between items-center"
              >
                <div>
                  <span class="text-xs text-muted-foreground block"
                    >Sườn bò Ngưu Cát</span
                  >
                  <span class="text-sm font-bold text-foreground"
                    >Ướp sốt nướng</span
                  >
                </div>
                <span class="text-lg font-black text-primary"
                  >{{ (todayExpectedGuests * 0.2).toFixed(1) }} kg</span
                >
              </div>
              <div
                class="p-3 bg-muted border border-border rounded-xl flex justify-between items-center"
              >
                <div>
                  <span class="text-xs text-muted-foreground block"
                    >Rau nấm tổng hợp</span
                  >
                  <span class="text-sm font-bold text-foreground"
                    >Nhặt sạch, phân mâm</span
                  >
                </div>
                <span class="text-lg font-black text-primary"
                  >{{ (todayExpectedGuests * 0.15).toFixed(1) }} kg</span
                >
              </div>
              <div
                class="p-3 bg-muted border border-border rounded-xl flex justify-between items-center"
              >
                <div>
                  <span class="text-xs text-muted-foreground block"
                    >Nước lẩu Sukiyaki</span
                  >
                  <span class="text-sm font-bold text-foreground"
                    >Đun hầm sẵn tủ mát</span
                  >
                </div>
                <span class="text-lg font-black text-primary"
                  >{{ (todayExpectedGuests * 0.4).toFixed(1) }} L</span
                >
              </div>
            </div>
          </div>

          <!-- Tasks list & Assignment section -->
          <div class="space-y-4">
            <div
              class="flex justify-between items-center border-t border-border pt-4"
            >
              <h4
                class="text-xs text-muted-foreground uppercase font-bold tracking-wider"
              >
                📋 Phân công sơ chế đầu ca
              </h4>
              <span
                class="bg-background border border-border text-muted-foreground px-2 py-0.5 rounded text-xs font-bold"
              >
                Cần làm: {{ pendingPrepTaskCount }}
              </span>
            </div>

            <!-- New task inputs -->
            <div
              class="flex gap-2 bg-background p-3 rounded-xl border border-border"
            >
              <input
                type="text"
                v-model="newPrepTaskName"
                placeholder="Tên công việc sơ chế..."
                class="flex-1 bg-background border border-border rounded-lg px-3 py-1.5 text-xs text-foreground focus:outline-none focus:border-[#1976d2]"
              />
              <input
                type="text"
                v-model="newPrepTaskAssigned"
                placeholder="Tên đầu bếp..."
                class="w-32 bg-background border border-border rounded-lg px-3 py-1.5 text-xs text-foreground focus:outline-none focus:border-[#1976d2]"
              />
              <button
                @click="addPrepTask"
                :disabled="!newPrepTaskName"
                class="bg-[#1976d2] hover:bg-[#1565c0] disabled:opacity-50 text-foreground text-xs font-bold px-4 py-1.5 rounded-lg transition-fast touch-target"
              >
                Thêm
              </button>
            </div>

            <!-- Tasks list -->
            <div class="space-y-2">
              <div
                v-for="task in prepTasks"
                :key="task.id"
                class="p-3 bg-background border border-border rounded-xl flex justify-between items-center hover:border-border transition-fast"
              >
                <div class="flex items-center gap-3">
                  <input
                    type="checkbox"
                    :checked="task.status === 'Completed'"
                    @change="togglePrepTaskStatus(task)"
                    class="w-5 h-5 rounded border-border text-blue-700 focus:ring-[#1976d2] bg-card cursor-pointer"
                  />
                  <div>
                    <span
                      class="text-sm font-semibold text-foreground block"
                      :class="{
                        'line-through text-muted-foreground':
                          task.status === 'Completed',
                      }"
                    >
                      {{ task.name }}
                    </span>
                    <span class="text-xs text-muted-foreground"
                      >Phân công: {{ task.assignedTo }}</span
                    >
                  </div>
                </div>

                <div class="flex items-center gap-3">
                  <span
                    class="text-[10px] px-2 py-0.5 rounded font-bold uppercase cursor-pointer"
                    :class="
                      task.status === 'Pending'
                        ? 'bg-[#C62828]/20 text-red-700 border border-[#C62828]/40'
                        : task.status === 'InProgress'
                          ? 'bg-orange-100 text-orange-700 border border-orange-800/40'
                          : 'bg-green-100 text-green-700 border border-green-300'
                    "
                    @click="togglePrepTaskStatus(task)"
                  >
                    {{
                      task.status === "Pending"
                        ? "Chưa làm"
                        : task.status === "InProgress"
                          ? "Đang làm"
                          : "Xong"
                    }}
                  </span>
                  <button
                    @click="deletePrepTask(task.id)"
                    class="text-muted-foreground hover:text-red-700 transition-fast"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4.5 w-4.5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="px-6 py-4 bg-background border-t border-border flex justify-end"
        >
          <button
            @click="showPrepModal = false"
            class="px-6 py-2.5 bg-muted hover:bg-accent text-foreground border border-border rounded-xl font-bold transition-fast touch-target"
          >
            Đóng bảng
          </button>
        </div>
      </div>
    </div>

    <!-- NEW FEATURE: 86'd MENU ITEMS MANAGEMENT MODAL -->
    <div
      v-if="show86dModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="show86dModal = false"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-[650px] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]"
      >
        <!-- Modal Header -->
        <div
          class="px-6 py-4 bg-background border-b border-border flex justify-between items-center"
        >
          <div class="flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-[#ff5252]"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13.477 14.89A6 6 0 015.11 6.524l8.367 8.368zm1.414-1.414L6.524 5.11a6 6 0 018.367 8.367zM18 10a8 8 0 11-16 0 8 8 0 0116 0z"
              />
            </svg>
            <div>
              <h3
                class="text-xl font-black text-foreground uppercase tracking-wider"
              >
                Quản lý Món Tạm Ngưng (86'd List)
              </h3>
              <p class="text-xs text-muted-foreground">
                Kiểm tra tồn kho & Đánh dấu món hết hàng để thông báo cho POS /
                Phục vụ
              </p>
            </div>
          </div>
          <button
            @click="show86dModal = false"
            class="w-10 h-10 rounded-full bg-muted hover:bg-accent flex items-center justify-center border border-border transition-fast text-foreground touch-target"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Search & Quick Filters -->
        <div class="p-6 pb-2 bg-card space-y-4">
          <div class="flex gap-4">
            <!-- Search field -->
            <div class="relative flex-1">
              <input
                v-model="search86dQuery"
                type="text"
                placeholder="Tìm món ăn..."
                class="w-full bg-background border border-border rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:border-[#ff5252] text-foreground placeholder-gray-500"
              />
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 text-muted-foreground absolute left-3 top-1/2 -translate-y-1/2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>
            <!-- Quick Filter Select -->
            <select
              v-model="filter86dStatus"
              class="bg-background border border-border rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-[#ff5252]"
            >
              <option value="all">Tất cả món</option>
              <option value="available">Còn hàng</option>
              <option value="unavailable">Hết hàng (86'd)</option>
            </select>
          </div>
        </div>

        <!-- Modal Body Content -->
        <div class="p-6 pt-2 overflow-y-auto space-y-4 flex-1 bg-card">
          <div class="space-y-2">
            <div
              v-for="item in filtered86dItems"
              :key="item.id"
              class="p-4 bg-background border border-border rounded-xl flex justify-between items-center hover:border-border transition-fast"
            >
              <div>
                <span class="text-base font-bold text-foreground block">{{
                  item.name
                }}</span>
                <span class="text-xs text-muted-foreground"
                  >Trạm: {{ getStationLabel(getItemStation(item.name)) }}</span
                >
              </div>

              <div class="flex items-center gap-4">
                <span
                  class="text-[10px] px-2 py-0.5 rounded font-bold uppercase"
                  :class="
                    item.is_available
                      ? 'bg-green-100 text-green-700 border border-green-300'
                      : 'bg-red-100 text-red-700 border border-red-300'
                  "
                >
                  {{ item.is_available ? "Còn hàng" : "Hết hàng (86'd)" }}
                </span>

                <!-- Switch button -->
                <button
                  @click="toggleMenuItemAvailability(item)"
                  class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none"
                  :class="item.is_available ? 'bg-green-600' : 'bg-red-600'"
                >
                  <span
                    class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                    :class="
                      item.is_available ? 'translate-x-5' : 'translate-x-0'
                    "
                  />
                </button>
              </div>
            </div>

            <div
              v-if="filtered86dItems.length === 0"
              class="text-center py-8 text-muted-foreground text-sm"
            >
              <div class="text-3xl mb-2">🔍</div>
              Không tìm thấy món ăn nào.
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="px-6 py-4 bg-background border-t border-border flex justify-end"
        >
          <button
            @click="show86dModal = false"
            class="px-6 py-2.5 bg-muted hover:bg-accent text-foreground border border-border rounded-xl font-bold transition-fast touch-target"
          >
            Đóng
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL KIỂM TRA NGUYÊN LIỆU -->
    <div
      v-if="showIngredientCheckModal && ingredientCheckOrder"
      class="modal-overlay"
      @click.self="showIngredientCheckModal = false"
    >
      <div class="modal-content">
        <div class="modal-header">
          <h3 class="modal-title">
            KIỂM TRA NGUYÊN LIỆU - Bàn
            {{ getTableCode(ingredientCheckOrder.table) }}
          </h3>
          <button
            @click="showIngredientCheckModal = false"
            class="text-muted-foreground hover:text-foreground transition-fast"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="mb-4">
          <p
            class="text-xs text-muted-foreground uppercase font-bold tracking-wider mb-3"
          >
            DANH SÁCH NGUYÊN LIỆU CẦN THIẾT
          </p>
          <div class="ingredient-list">
            <div
              v-for="ing in ingredientCheckList"
              :key="ing.name"
              class="ingredient-item"
            >
              <div class="ingredient-info">
                <span class="ingredient-icon">{{ ing.icon }}</span>
                <span class="ingredient-name font-bold">{{ ing.name }}</span>
                <span class="ingredient-qty font-mono text-muted-foreground"
                  >({{ ing.qty }})</span
                >
              </div>
              <span
                class="ingredient-status"
                :class="{
                  'status-ok': ing.status === 'ok',
                  'status-low': ing.status === 'low',
                  'status-out': ing.status === 'out',
                }"
              >
                {{
                  ing.status === "ok"
                    ? "Còn đủ"
                    : ing.status === "low"
                      ? "Sắp hết"
                      : "HẾT HÀNG"
                }}
              </span>
            </div>
          </div>
        </div>

        <!-- Warning Box -->
        <div
          v-if="
            ingredientCheckList.some(
              (i) => i.status === 'low' || i.status === 'out',
            )
          "
          class="warning-box"
        >
          ⚠️ CẢNH BÁO:
          <span v-if="ingredientCheckList.some((i) => i.status === 'out')"
            >Có nguyên liệu HẾT HÀNG!</span
          >
          <span v-else>Có nguyên liệu sắp hết.</span>
          Bạn có muốn tiếp tục?
        </div>

        <div class="modal-actions">
          <button
            @click="showIngredientCheckModal = false"
            class="modal-btn cancel"
          >
            HỦY
          </button>
          <button
            @click="openReportOutFromCheck()"
            class="modal-btn report-out"
            v-if="ingredientCheckList.some((i) => i.status === 'out')"
          >
            BÁO HẾT MÓN (86'd)
          </button>
          <button @click="confirmStartCooking()" class="modal-btn continue">
            TIẾP TỤC
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL BÁO HẾT MÓN (86'd) -->
    <div
      v-if="showReportOutModal"
      class="modal-overlay"
      @click.self="showReportOutModal = false"
    >
      <div class="modal-content max-w-[500px]">
        <div class="modal-header">
          <h3 class="modal-title uppercase text-red-700">
            Báo hết món (86'd)
          </h3>
          <button
            @click="showReportOutModal = false"
            class="text-muted-foreground hover:text-foreground transition-fast"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="space-y-4">
          <!-- Item Select -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold"
              >Món cần báo hết</label
            >
            <select
              v-model="reportOutItem"
              class="w-full bg-background border border-border rounded-xl px-4 py-2.5 text-foreground focus:outline-none focus:border-[#C62828]"
            >
              <option :value="null" disabled>-- Chọn món --</option>
              <option v-for="item in menuItems" :key="item.id" :value="item">
                {{ item.name }}
              </option>
            </select>
          </div>

          <!-- Reason -->
          <div class="space-y-2">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >Lý do hết món</label
            >
            <div
              class="grid grid-cols-1 gap-2 bg-background p-3 rounded-xl border border-border"
            >
              <label
                v-for="reason in [
                  'Hết nguyên liệu',
                  'Nguyên liệu hỏng',
                  'Không thể chế biến',
                  'Khác',
                ]"
                :key="reason"
                class="flex items-center gap-2.5 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="radio"
                  v-model="reportOutReason"
                  :value="reason"
                  class="w-4 h-4 text-red-700 bg-card border-border focus:ring-[#C62828]"
                />
                <span>{{ reason }}</span>
              </label>
            </div>
            <input
              v-if="reportOutReason === 'Khác'"
              v-model="reportOutCustomReason"
              type="text"
              placeholder="Nhập lý do khác..."
              class="w-full bg-background border border-border rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-[#C62828] mt-2"
            />
          </div>

          <!-- Expected restore time -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold"
              >Thời gian dự kiến có lại</label
            >
            <select
              v-model="reportOutRestoreTime"
              class="w-full bg-background border border-border rounded-xl px-4 py-2.5 text-foreground focus:outline-none focus:border-[#C62828]"
            >
              <option value="30 phút">30 phút</option>
              <option value="1 giờ">1 giờ</option>
              <option value="Cuối ca">Cuối ca</option>
              <option value="Ngày mai">Ngày mai</option>
            </select>
          </div>
        </div>

        <div class="modal-actions mt-6">
          <button @click="showReportOutModal = false" class="modal-btn cancel">
            HỦY
          </button>
          <button
            @click="submitReportOut()"
            :disabled="!reportOutItem"
            class="modal-btn report-out disabled:opacity-50"
          >
            XÁC NHẬN BÁO HẾT
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL THÔNG BÁO STAFF (ĐỔI MÓN) -->
    <div
      v-if="showStaffNotificationModal"
      class="modal-overlay"
      @click.self="showStaffNotificationModal = false"
    >
      <div class="modal-content">
        <div class="modal-header">
          <h3
            class="modal-title uppercase text-orange-600 flex items-center gap-2"
          >
            📢 Thông báo Staff đổi món
          </h3>
          <button
            @click="showStaffNotificationModal = false"
            class="text-muted-foreground hover:text-foreground transition-fast"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="space-y-5">
          <div
            class="p-3 bg-orange-100 border border-orange-300 rounded-xl text-sm text-orange-600 font-bold"
          >
            MÓN HẾT HÀNG: {{ staffNotificationItemName }} (Lý do:
            {{ staffNotificationReason }})
          </div>

          <!-- Affected orders -->
          <div class="space-y-2">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >Các order bị ảnh hưởng ({{
                staffNotificationAffectedOrders.length
              }})</label
            >
            <div
              v-if="staffNotificationAffectedOrders.length > 0"
              class="max-h-[150px] overflow-y-auto space-y-2"
            >
              <div
                v-for="ord in staffNotificationAffectedOrders"
                :key="ord.id"
                class="p-3 bg-background border border-border rounded-xl flex justify-between items-center text-sm"
              >
                <span class="font-bold text-foreground"
                  >#{{ ord.id.slice(0, 8) }} - Bàn {{ ord.table }}</span
                >
                <span class="text-orange-700 font-bold"
                  >Số lượng: x{{ ord.itemQty }}</span
                >
              </div>
            </div>
            <p
              v-else
              class="text-sm text-muted-foreground italic bg-background p-3 rounded-xl text-center border border-border/50"
            >
              Không có order nào bị ảnh hưởng trực tiếp.
            </p>
          </div>

          <!-- Suggested replacements -->
          <div class="space-y-2">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >Gợi ý món thay thế</label
            >
            <div class="flex gap-2 flex-wrap">
              <span
                v-for="rep in staffNotificationReplacements"
                :key="rep"
                class="px-3 py-1.5 bg-muted border border-border text-foreground rounded-full text-xs font-bold"
              >
                {{ rep }}
              </span>
            </div>
          </div>

          <!-- Extra notes -->
          <div class="space-y-1.5">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >Ghi chú thêm</label
            >
            <textarea
              v-model="staffNotificationNotes"
              rows="3"
              placeholder="Nhập thêm ghi chú dặn dò phục vụ..."
              class="w-full bg-background border border-border rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-[#FFA726] resize-none"
            ></textarea>
          </div>
        </div>

        <div class="modal-actions mt-6">
          <button
            @click="showStaffNotificationModal = false"
            class="modal-btn cancel"
          >
            HỦY
          </button>
          <button
            @click="sendStaffNotification()"
            class="modal-btn continue bg-[#FFA726] hover:bg-[#ff9100]"
          >
            GỬI THÔNG BÁO
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL KIỂM TRA CHẤT LƯỢNG (QC) -->
    <div
      v-if="showQcModal && qcOrder"
      class="modal-overlay"
      @click.self="showQcModal = false"
    >
      <div class="modal-content">
        <div class="modal-header">
          <h3 class="modal-title">
            KIỂM TRA CHẤT LƯỢNG (QC) - Bàn {{ getTableCode(qcOrder.table) }}
          </h3>
          <button
            @click="showQcModal = false"
            class="text-muted-foreground hover:text-foreground transition-fast"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="space-y-5">
          <!-- Checklist -->
          <div class="space-y-2">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >CHECKLIST TIÊU CHUẨN MÓN ĂN (Expo QC)</label
            >
            <div
              class="space-y-2.5 bg-background p-4 rounded-xl border border-border"
            >
              <label
                class="flex items-center gap-3 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="checkbox"
                  v-model="qcChecklist.plating"
                  class="w-5 h-5 rounded border-border text-green-500 focus:ring-green-500 bg-card"
                />
                <span>Hình thức trình bày đẹp, đúng dĩa quy định</span>
              </label>
              <label
                class="flex items-center gap-3 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="checkbox"
                  v-model="qcChecklist.temperature"
                  class="w-5 h-5 rounded border-border text-green-500 focus:ring-green-500 bg-card"
                />
                <span>Nhiệt độ món ăn đạt chuẩn (≥ 60°C đối với đồ nóng)</span>
              </label>
              <label
                class="flex items-center gap-3 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="checkbox"
                  v-model="qcChecklist.weight"
                  class="w-5 h-5 rounded border-border text-green-500 focus:ring-green-500 bg-card"
                />
                <span>Định lượng đúng chuẩn định mức (sai số tối đa ±10%)</span>
              </label>
              <label
                class="flex items-center gap-3 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="checkbox"
                  v-model="qcChecklist.allergy"
                  class="w-5 h-5 rounded border-border text-green-500 focus:ring-green-500 bg-card"
                />
                <span
                  >Đáp ứng các lưu ý dị ứng của khách (Ví dụ: Không hành, ít
                  cay)</span
                >
              </label>
              <label
                class="flex items-center gap-3 cursor-pointer text-sm text-muted-foreground"
              >
                <input
                  type="checkbox"
                  v-model="qcChecklist.taste"
                  class="w-5 h-5 rounded border-border text-green-500 focus:ring-green-500 bg-card"
                />
                <span
                  >Mùi vị và độ chín đạt tiêu chuẩn thương hiệu Ngưu Cát</span
                >
              </label>
            </div>
          </div>

          <!-- Result selectors -->
          <div class="space-y-2">
            <label class="text-xs text-muted-foreground uppercase font-bold block"
              >Kết quả kiểm tra</label
            >
            <div class="grid grid-cols-2 gap-4">
              <button
                @click="qcResult = 'pass'"
                class="py-3 rounded-xl border-2 text-base font-bold transition-all flex items-center justify-center gap-2 touch-target"
                :class="
                  qcResult === 'pass'
                    ? 'bg-green-100 border-[#4CAF50] text-green-600'
                    : 'bg-background border-border text-muted-foreground'
                "
              >
                ✅ ĐẠT TIÊU CHUẨN
              </button>
              <button
                @click="qcResult = 'fail'"
                class="py-3 rounded-xl border-2 text-base font-bold transition-all flex items-center justify-center gap-2 touch-target"
                :class="
                  qcResult === 'fail'
                    ? 'bg-red-100 border-[#F44336] text-red-600'
                    : 'bg-background border-border text-muted-foreground'
                "
              >
                ❌ KHÔNG ĐẠT YÊU CẦU
              </button>
            </div>
          </div>

          <!-- If fail reason -->
          <div v-if="qcResult === 'fail'" class="space-y-1.5 animate-fade-in">
            <label class="text-xs text-red-600 uppercase font-bold block"
              >Ghi chú nguyên nhân không đạt</label
            >
            <textarea
              v-model="qcFailReason"
              rows="3"
              placeholder="Nhập lý do không đạt (Ví dụ: bị cháy xém, thiếu dĩa đi kèm...)"
              class="w-full bg-background border border-[#F44336]/40 rounded-xl px-4 py-2 text-sm text-foreground focus:outline-none focus:border-[#F44336] resize-none"
            ></textarea>
          </div>
        </div>

        <div class="modal-actions mt-6">
          <button @click="showQcModal = false" class="modal-btn cancel">
            HỦY
          </button>
          <button
            v-if="qcResult === 'pass'"
            @click="submitQcResult()"
            class="modal-btn continue bg-green-600 hover:bg-green-500"
          >
            XÁC NHẬN ĐẠT & LÊN PASS
          </button>
          <button
            v-if="qcResult === 'fail'"
            @click="submitQcResult()"
            class="modal-btn report-out"
          >
            YÊU CẦU LÀM LẠI (REMAKE)
          </button>
        </div>
      </div>
    </div>

    <!-- Delayed Orders Modal -->
    <div
      v-if="kitchenStore.showDelayedOrdersModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in"
      @click.self="kitchenStore.showDelayedOrdersModal = false"
    >
      <div
        class="bg-card border border-border rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl animate-scale-up"
      >
        <!-- Header -->
        <div
          class="p-6 bg-[#C62828] text-white flex items-center justify-between"
        >
          <div class="flex items-center gap-3">
            <span class="text-2xl">⚠️</span>
            <div>
              <h3 class="text-lg font-bold">CẢNH BÁO: ĐƠN CHẾ BIẾN TRỄ</h3>
              <p class="text-xs text-red-100">
                Các đơn hàng vượt quá thời gian chuẩn (15 phút)
              </p>
            </div>
          </div>
          <button
            @click="kitchenStore.showDelayedOrdersModal = false"
            class="text-foreground/80 hover:text-foreground text-xl font-bold"
          >
            &times;
          </button>
        </div>

        <!-- Body -->
        <div class="p-6 max-h-[400px] overflow-y-auto space-y-4">
          <div
            v-if="kitchenStore.delayedTickets.length === 0"
            class="text-center py-8 text-muted-foreground"
          >
            Không có đơn hàng nào bị trễ.
          </div>
          <div
            v-else
            v-for="ticket in kitchenStore.delayedTickets"
            :key="ticket.id"
            class="p-4 bg-background border border-red-500/30 rounded-xl flex items-center justify-between gap-4"
          >
            <div class="space-y-1">
              <div class="flex items-center gap-2">
                <span
                  class="bg-[#C62828] text-white text-xs px-2.5 py-0.5 rounded-full font-bold"
                  >Bàn {{ ticket.table }}</span
                >
                <span class="text-muted-foreground text-xs font-mono">{{
                  ticket.time
                }}</span>
              </div>
              <div class="text-sm font-semibold text-foreground">
                <div
                  v-for="item in ticket.items"
                  :key="item.id"
                  class="inline-block mr-3"
                >
                  {{ item.name }} x{{ item.qty }}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-red-500 font-bold text-sm">
                {{ Math.floor(ticket.waitTime / 60) }} phút
              </div>
              <div class="text-xs text-muted-foreground">Thời gian chờ</div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-4 bg-background border-t border-border flex justify-end">
          <button
            @click="kitchenStore.showDelayedOrdersModal = false"
            class="px-5 py-2 rounded-xl bg-muted hover:bg-gray-600 text-foreground font-bold text-sm transition-all"
          >
            Đóng
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n";
const { t } = useI18n();
import { ref, onMounted, onUnmounted, computed, watch } from "vue";
import { supabase } from "@/lib/supabase";
import { useRealtime } from "@/composables/useRealtime";
import { useOrder } from "@/composables/useOrder";
import { useBranch } from "@/composables/useBranch";
import type { OrderStatus } from "@/types/database";
import { useKitchenStore } from "@/stores/kitchen";
import HeaderButtons from "@/components/HeaderButtons.vue";

const { watchTable } = useRealtime();
const { loading } = useOrder();

const kitchenStore = useKitchenStore();

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
  status: "pending" | "preparing" | "ready" | "done";
}

// Grill & Coal Request structure
interface GrillRequest {
  id: string;
  table: string;
  type: "GrillChange" | "CoalRefill";
  status: "Pending" | "Inprogress" | "Completed";
  priority: "Normal" | "Urgent";
  createdAt: number;
  timeLeft?: number; // count down seconds
  timer?: any; // interval handler
}

// Stations config mapping
const stations = [
  { key: "ALL", label: "Tất cả trạm" },
  { key: "Grill", label: "Bếp Nướng" },
  { key: "Hotpot", label: "Bếp Lẩu" },
  { key: "Cold", label: "Bếp Lạnh" },
  { key: "Fried", label: "Bếp Chiên" },
  { key: "Bar", label: "Bar/Đồ uống" },
];

// State variables
const orders = ref<Order[]>([]);
const activeStation = ref("ALL");
const sortOrder = ref("oldest");
const searchQuery = ref("");
const currentTime = ref(new Date().toLocaleTimeString());
const selectedOrder = ref<Order | null>(null);
const notification = ref<{
  type: "success" | "error" | "info" | "warning";
  message: string;
} | null>(null);

// Grill & Coal Request Management state
const grillRequests = ref<GrillRequest[]>([]);
const showGrillRequestModal = computed({
  get: () => kitchenStore.showGrillRequestModal,
  set: (val) => (kitchenStore.showGrillRequestModal = val),
});
const showGrillSidebar = computed({
  get: () => kitchenStore.isGrillPanelVisible,
  set: (val) => (kitchenStore.isGrillPanelVisible = val),
});
const newRequestTable = ref("");
const newRequestType = ref<"GrillChange" | "CoalRefill">("GrillChange");
const newRequestPriority = ref<"Normal" | "Urgent">("Normal");

// Local operational tracking
const completedOrders = ref<string[]>([]);
const startedOrders = ref<string[]>([]);

// Modals State
const showIngredientCheckModal = ref(false);
const ingredientCheckOrder = ref<Order | null>(null);
const ingredientCheckList = ref<
  { name: string; qty: string; status: "ok" | "low" | "out"; icon: string }[]
>([]);

const showReportOutModal = ref(false);
const reportOutItem = ref<MenuItem | null>(null);
const reportOutReason = ref("Hết nguyên liệu");
const reportOutCustomReason = ref("");
const reportOutRestoreTime = ref("30 phút");

const showStaffNotificationModal = ref(false);
const staffNotificationItemName = ref("");
const staffNotificationReason = ref("");
const staffNotificationAffectedOrders = ref<
  { id: string; table: string; itemQty: number }[]
>([]);
const staffNotificationReplacements = ref<string[]>([
  "Hành phi",
  "Ớt băm",
  "Gừng băm",
]);
const staffNotificationNotes = ref("");

const showQcModal = ref(false);
const qcOrder = ref<Order | null>(null);
const qcChecklist = ref({
  plating: false,
  temperature: false,
  weight: false,
  allergy: false,
  taste: false,
});
const qcResult = ref<"pass" | "fail" | null>(null);
const qcFailReason = ref("");

let clockInterval: any = null;
let timerInterval: any = null;
let requestElapsedTimeInterval: any = null;

// Table mappings UUID -> Code
const tableMap = ref<Record<string, string>>({});

const fetchTableMap = async () => {
  try {
    const { data, error } = await supabase.from("tables").select("id, code");
    if (error) throw error;
    if (data) {
      const map: Record<string, string> = {};
      data.forEach((t: any) => {
        map[t.id] = t.code;
      });
      tableMap.value = map;
    }
  } catch (e) {
    console.error("Error fetching table map:", e);
  }
};

const getTableCode = (tableId: string | null): string => {
  if (!tableId) return "T-??";
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
    const raw = localStorage.getItem("kds_item_sub_steps");
    if (raw) {
      itemSubStepsState.value = JSON.parse(raw);
    }
  } catch (e) {
    console.error("Error loading sub steps:", e);
  }
};

const saveSubSteps = () => {
  localStorage.setItem(
    "kds_item_sub_steps",
    JSON.stringify(itemSubStepsState.value),
  );
};

const isSubStepChecked = (itemId: string, stepKey: string): boolean => {
  return !!(
    itemSubStepsState.value[itemId] && itemSubStepsState.value[itemId][stepKey]
  );
};

const toggleSubStep = (itemId: string, stepKey: string) => {
  if (!itemSubStepsState.value[itemId]) {
    itemSubStepsState.value[itemId] = {};
  }
  itemSubStepsState.value[itemId][stepKey] =
    !itemSubStepsState.value[itemId][stepKey];
  saveSubSteps();

  // Play subtle sound when step is completed
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "sine";
    oscillator.frequency.value = itemSubStepsState.value[itemId][stepKey]
      ? 1200
      : 600;
    gainNode.gain.setValueAtTime(0.04, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.08);
  } catch (e) {
    // Ignore audio errors
  }
};

const getItemSubSteps = (itemName: string): SubStep[] => {
  const station = getItemStation(itemName);
  if (station === "Grill") {
    return [
      { key: "prep", label: "1. Sơ chế / FIFO" },
      { key: "cook", label: "2. Nướng & Canh chín" },
      { key: "plate", label: "3. Trở mặt & Plating" },
    ];
  } else if (station === "Hotpot") {
    return [
      { key: "broth", label: "1. Nước dùng & Rau" },
      { key: "plate", label: "2. Sắp lẩu lên Pass" },
    ];
  } else {
    return [
      { key: "recipe", label: "1. Làm theo Recipe" },
      { key: "plate", label: "2. Decor lên Pass" },
    ];
  }
};

const triggerQuickRequest = (
  tableIdOrCode: string,
  type: "GrillChange" | "CoalRefill",
) => {
  const tableCode = getTableCode(tableIdOrCode);
  const id = `REQ-${Date.now()}`;
  grillRequests.value.push({
    id,
    table: tableCode,
    type,
    status: "Pending",
    priority: "Normal",
    createdAt: Date.now(),
  });

  saveGrillRequests();
  playNewTicketSound();
  showNotification(
    "success",
    `Đã gửi yêu cầu ${type === "GrillChange" ? "thay vỉ" : "châm than"} cho Bàn ${tableCode}!`,
  );
};

// 86'd Menu Items States & Logic based on kitchen_order_receiving.mmd
interface MenuItem {
  id: string;
  name: string;
  is_available: boolean;
}

const show86dModal = computed({
  get: () => kitchenStore.show86dModal,
  set: (val) => (kitchenStore.show86dModal = val),
});
const search86dQuery = ref("");
const filter86dStatus = ref<"all" | "available" | "unavailable">("all");
const menuItems = ref<MenuItem[]>([]);

const defaultMenuItemsList = [
  { id: "def-item-1", name: "Sườn bò Ngưu Cát", is_available: true },
  { id: "def-item-2", name: "Thịt bò Wagyu lẩu", is_available: true },
  { id: "def-item-3", name: "Rau nấm tổng hợp", is_available: true },
  { id: "def-item-4", name: "Nước lẩu Sukiyaki", is_available: true },
  { id: "def-item-5", name: "Gỏi xoài hải sản", is_available: true },
  { id: "def-item-6", name: "Khoai tây chiên", is_available: true },
  { id: "def-item-7", name: "Gà chiên giòn", is_available: true },
  { id: "def-item-8", name: "Bia Sapporo", is_available: true },
];

const unavailableItemsCount = computed(() => {
  return menuItems.value.filter((item) => !item.is_available).length;
});

const filtered86dItems = computed(() => {
  let result = menuItems.value;
  if (search86dQuery.value) {
    const q = search86dQuery.value.toLowerCase();
    result = result.filter((item) => item.name.toLowerCase().includes(q));
  }
  if (filter86dStatus.value === "available") {
    result = result.filter((item) => item.is_available);
  } else if (filter86dStatus.value === "unavailable") {
    result = result.filter((item) => !item.is_available);
  }
  return result;
});

const fetchMenuItems = async () => {
  try {
    const { data, error } = await supabase
      .from("menu_items")
      .select("id, name, is_available");
    if (error) throw error;
    if (data && data.length > 0) {
      menuItems.value = data.map((d: any) => ({
        id: d.id,
        name: d.name,
        is_available: d.is_available,
      }));
    } else {
      menuItems.value = [...defaultMenuItemsList];
    }
  } catch (e) {
    console.error("Error fetching menu items:", e);
    menuItems.value = [...defaultMenuItemsList];
  }
  mergeOrderItemsToMenu();
};

const mergeOrderItemsToMenu = () => {
  const existingNames = new Set(
    menuItems.value.map((i) => i.name.toLowerCase()),
  );
  orders.value.forEach((order) => {
    order.items.forEach((item) => {
      const nameLower = item.name.toLowerCase();
      if (!existingNames.has(nameLower)) {
        menuItems.value.push({
          id: `ext-${item.id}`,
          name: item.name,
          is_available: true,
        });
        existingNames.add(nameLower);
      }
    });
  });
};

const toggleMenuItemAvailability = async (item: MenuItem) => {
  const originalValue = item.is_available;
  item.is_available = !item.is_available;

  if (item.id.startsWith("ext-") || item.id.startsWith("def-")) {
    showNotification(
      item.is_available ? "success" : "warning",
      `Đã cập nhật (Local): ${item.name} là ${item.is_available ? "CÒN MÓN" : "HẾT MÓN (86'd)"}`,
    );
    playNewTicketSound();
    return;
  }

  try {
    const { error } = await supabase
      .from("menu_items")
      .update({ is_available: item.is_available })
      .eq("id", item.id);
    if (error) throw error;

    showNotification(
      item.is_available ? "success" : "warning",
      `Đã cập nhật: ${item.name} là ${item.is_available ? "CÒN MÓN" : "HẾT MÓN (86'd)"}`,
    );
    playNewTicketSound();
  } catch (e) {
    console.error("Error updating menu item availability:", e);
    item.is_available = originalValue;
    showNotification(
      "error",
      `Không thể cập nhật trạng thái món: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
};

const isItem86d = (itemName: string): boolean => {
  const item = menuItems.value.find(
    (i) => i.name.toLowerCase() === itemName.toLowerCase(),
  );
  return item ? !item.is_available : false;
};

const { activeBranchId } = useBranch();

const notifyStaffAbout86d = async (itemName: string, tableCode: string) => {
  try {
    const { error } = await supabase.from("notifications").insert({
      branch_id: activeBranchId.value || null,
      channel: "staff",
      recipient: "all",
      template: "item_sold_out",
      variables: { itemName, tableCode },
      status: "unread",
      metadata: {
        source: "kds",
        tableCode,
        itemName,
        time: new Date().toISOString(),
      },
    });
    if (error) throw error;
    showNotification(
      "success",
      `Đã phát thông báo đổi món [${itemName}] cho Bàn ${tableCode} tới Phục vụ!`,
    );
    playNewTicketSound();
  } catch (e) {
    console.error("Error notifying staff:", e);
    showNotification(
      "warning",
      `Đã gửi yêu cầu đổi món [${itemName}] tại Bàn ${tableCode} cho nhân viên phục vụ.`,
    );
    playNewTicketSound();
  }
};

// HACCP Hygiene & Safety States & Logic based on kitchen_hygiene_safety.mmd
interface IncidentReport {
  id: string;
  timestamp: number;
  reporter: string;
  type: "FoodDrop" | "CutHand" | "CrossContamination" | "Other";
  description: string;
  status: "Pending" | "Resolved";
  resolutionNote?: string;
  resolvedAt?: number;
}

// Prep List & Tasks States based on kitchen_preprouting.mmd
interface PrepTask {
  id: string;
  name: string;
  assignedTo: string;
  status: "Pending" | "InProgress" | "Completed";
  createdAt: number;
}

const showPrepModal = computed({
  get: () => kitchenStore.showPrepListModal,
  set: (val) => (kitchenStore.showPrepListModal = val),
});
const prepTasks = ref<PrepTask[]>([]);
const newPrepTaskName = ref("");
const newPrepTaskAssigned = ref("");

const todayBookingsCount = ref(0);
const todayExpectedGuests = ref(0);

const pendingPrepTaskCount = computed(() => {
  return prepTasks.value.filter((t) => t.status !== "Completed").length;
});

const kitchenPrepStatus = computed(() => {
  if (!haccpPreSaved.value) {
    return {
      label: "Chưa KT Nhiệt độ (HACCP)",
      colorClass: "text-red-700 font-bold",
    };
  }
  if (pendingPrepTaskCount.value > 0) {
    return {
      label: `Đang sơ chế (${prepTasks.value.filter((t) => t.status === "Completed").length}/${prepTasks.value.length})`,
      colorClass: "text-orange-600 font-bold",
    };
  }
  return {
    label: "Sẵn sàng đón Order",
    colorClass: "text-green-700 font-bold",
  };
});

const loadPrepTasks = () => {
  try {
    const raw = localStorage.getItem("kds_prep_tasks");
    if (raw) {
      prepTasks.value = JSON.parse(raw);
    } else {
      prepTasks.value = [
        {
          id: "prep-1",
          name: "Thái mỏng thịt bò Wagyu (đĩa lẩu)",
          assignedTo: "Đầu bếp Hải",
          status: "Pending",
          createdAt: Date.now(),
        },
        {
          id: "prep-2",
          name: "Tẩm ướp Sườn bò Ngưu Cát",
          assignedTo: "Đầu bếp Sơn",
          status: "Pending",
          createdAt: Date.now(),
        },
        {
          id: "prep-3",
          name: "Rửa sạch & xếp set rau lẩu tổng hợp",
          assignedTo: "Đầu bếp Chi",
          status: "Pending",
          createdAt: Date.now(),
        },
        {
          id: "prep-4",
          name: "Chuẩn bị nước cốt lẩu Sukiyaki",
          assignedTo: "Đầu bếp Hải",
          status: "Pending",
          createdAt: Date.now(),
        },
      ];
      savePrepTasks();
    }
  } catch (e) {
    console.error("Error loading prep tasks:", e);
  }
};

const savePrepTasks = () => {
  localStorage.setItem("kds_prep_tasks", JSON.stringify(prepTasks.value));
};

const addPrepTask = () => {
  if (!newPrepTaskName.value) return;
  prepTasks.value.push({
    id: `prep-${Date.now()}`,
    name: newPrepTaskName.value,
    assignedTo: newPrepTaskAssigned.value || "Chưa phân công",
    status: "Pending",
    createdAt: Date.now(),
  });
  savePrepTasks();
  newPrepTaskName.value = "";
  newPrepTaskAssigned.value = "";
  showNotification("success", "Đã thêm nhiệm vụ sơ chế mới!");
};

const togglePrepTaskStatus = (task: PrepTask) => {
  if (task.status === "Pending") task.status = "InProgress";
  else if (task.status === "InProgress") task.status = "Completed";
  else task.status = "Pending";
  savePrepTasks();
  playNewTicketSound();
};

const deletePrepTask = (taskId: string) => {
  prepTasks.value = prepTasks.value.filter((t) => t.id !== taskId);
  savePrepTasks();
};

const fetchTodayBookingsForPrep = async () => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const { data, error } = await supabase
      .from("reservations")
      .select("guests")
      .eq("reservation_date", today);
    if (error) throw error;
    if (data) {
      todayBookingsCount.value = data.length;
      todayExpectedGuests.value = data.reduce(
        (sum: number, r: any) => sum + (r.guests || 0),
        0,
      );
    }
  } catch (e) {
    console.error("Error fetching today bookings for prep:", e);
    todayBookingsCount.value = 8;
    todayExpectedGuests.value = 32;
  }
};

const localRemakeOrderIds = ref<string[]>([]);
const toggleOrderRemake = (orderId: string) => {
  const index = localRemakeOrderIds.value.indexOf(orderId);
  if (index >= 0) {
    localRemakeOrderIds.value.splice(index, 1);
    showNotification(
      "info",
      `Đã bỏ đánh dấu trả món cho Đơn #${orderId.slice(0, 8)}`,
    );
  } else {
    localRemakeOrderIds.value.push(orderId);
    showNotification(
      "warning",
      `Đơn #${orderId.slice(0, 8)} đã được đánh dấu KHÁCH TRẢ MÓN - ƯU TIÊN CAO NHẤT!`,
    );
    playNewTicketSound();
  }
  localStorage.setItem(
    "kds_remake_orders",
    JSON.stringify(localRemakeOrderIds.value),
  );
};

const loadRemakeOrders = () => {
  try {
    const raw = localStorage.getItem("kds_remake_orders");
    if (raw) {
      localRemakeOrderIds.value = JSON.parse(raw);
    }
  } catch (e) {
    console.error("Error loading remake orders:", e);
  }
};

const isOrderRemake = (order: Order | null): boolean => {
  if (!order) return false;
  if (localRemakeOrderIds.value.includes(order.id)) return true;
  return order.items.some((i) => {
    const note = (i.note || "").toLowerCase();
    return (
      note.includes("remake") ||
      note.includes("làm lại") ||
      note.includes("trả món") ||
      note.includes("đổi món")
    );
  });
};

const getOrderClassification = (
  order: Order,
): "Remake" | "Round1" | "RoundN" | "Alacarte" => {
  if (isOrderRemake(order)) return "Remake";

  const hasBuffetItem = order.items.some((i) => {
    const name = i.name.toLowerCase();
    return (
      name.includes("buffet") || name.includes("gói") || name.includes("set")
    );
  });

  if (!hasBuffetItem) return "Alacarte";

  const tableOrders = orders.value.filter((o) => o.table === order.table);
  if (tableOrders.length === 0) return "Round1";

  const sorted = [...tableOrders].sort((a, b) => a.timestamp - b.timestamp);
  if (sorted[0].id === order.id) {
    return "Round1";
  } else {
    return "RoundN";
  }
};

const showHaccpModal = computed({
  get: () => kitchenStore.showHACCPModal,
  set: (val) => (kitchenStore.showHACCPModal = val),
});
const haccpActiveTab = ref<"preshift" | "incidents" | "postshift" | "approval">(
  "preshift",
);

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
const newIncidentReporter = ref("");
const newIncidentType = ref<
  "FoodDrop" | "CutHand" | "CrossContamination" | "Other"
>("FoodDrop");
const newIncidentDescription = ref("");

const unresolvedIncidentCount = computed(() => {
  return haccpIncidents.value.filter((i) => i.status === "Pending").length;
});

// Post-shift state
const haccpPostCleaning = ref(false);
const haccpPostWasteSorting = ref(false);
const haccpPostLeftoversStored = ref(false);
const haccpPostShiftNote = ref("");
const haccpPostSaved = ref(false);

// Head Chef Approval state
const haccpHeadChefApproved = ref(false);
const haccpChefName = ref("");
const haccpHaccpStatus = ref<"Compliant" | "NonCompliant">("Compliant");
const haccpActionNote = ref("");

// Sync lists to kitchenStore
watch(
  orders,
  (newOrders) => {
    kitchenStore.qcQueue = newOrders.filter((o) => o.status === "ready");
    kitchenStore.delayedTickets = newOrders.filter(
      (o) => o.status !== "done" && o.status !== "ready" && o.waitTime >= 900,
    );
  },
  { deep: true, immediate: true },
);

watch(
  grillRequests,
  (newRequests) => {
    kitchenStore.grillRequests = newRequests;
  },
  { deep: true, immediate: true },
);

watch(
  prepTasks,
  (newPrepTasks) => {
    kitchenStore.prepList = newPrepTasks.map((t) => ({
      ...t,
      completed: t.status === "Completed",
    }));
  },
  { deep: true, immediate: true },
);

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
    actionNote: haccpActionNote.value,
  };
  localStorage.setItem("kds_haccp_state", JSON.stringify(data));
};

const loadHaccpState = () => {
  try {
    const raw = localStorage.getItem("kds_haccp_state");
    if (raw) {
      const data = JSON.parse(raw);
      haccpPreHandHygiene.value = !!data.preHandHygiene;
      haccpPreFridgeTemp.value =
        data.preFridgeTemp !== undefined ? data.preFridgeTemp : 4;
      haccpPreFreezerTemp.value =
        data.preFreezerTemp !== undefined ? data.preFreezerTemp : -20;
      haccpPreFefoChecked.value = !!data.preFefoChecked;
      haccpPreSaved.value = !!data.preSaved;
      haccpIncidents.value = data.incidents || [];
      haccpPostCleaning.value = !!data.postCleaning;
      haccpPostWasteSorting.value = !!data.postWasteSorting;
      haccpPostLeftoversStored.value = !!data.postLeftoversStored;
      haccpPostShiftNote.value = data.postShiftNote || "";
      haccpPostSaved.value = !!data.postSaved;
      haccpHeadChefApproved.value = !!data.headChefApproved;
      haccpChefName.value = data.chefName || "";
      haccpHaccpStatus.value = data.haccpStatus || "Compliant";
      haccpActionNote.value = data.actionNote || "";
    }
  } catch (e) {
    console.error("Error loading HACCP state:", e);
  }
};

const savePreShiftHaccp = () => {
  haccpPreSaved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification(
    "success",
    "Đã lưu kết quả kiểm tra đầu ca (HACCP) thành công!",
  );
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
    status: "Pending",
  });

  saveHaccpState();
  playNewTicketSound();
  showNotification(
    "warning",
    "Đã ghi nhận sự cố vệ sinh/an toàn mới! Vui lòng dọn dẹp hoặc sơ cứu.",
  );

  newIncidentReporter.value = "";
  newIncidentDescription.value = "";
  showNewIncidentForm.value = false;
};

const resolveIncidentPrompt = (inc: IncidentReport) => {
  const note = prompt("Mô tả biện pháp dọn dẹp / sơ cứu y tế đã thực hiện:");
  if (note === null) return;

  inc.status = "Resolved";
  inc.resolutionNote =
    note || "Đã dọn dẹp vệ sinh / sơ cứu y tế đúng quy chuẩn.";
  inc.resolvedAt = Date.now();

  saveHaccpState();
  playNewTicketSound();
  showNotification("success", "Đã xác nhận xử lý xong sự cố vệ sinh.");
};

const savePostShiftHaccp = () => {
  haccpPostSaved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification(
    "success",
    "Đã lưu nhật ký vệ sinh cuối ca (HACCP) thành công!",
  );
};

const approveShiftHaccp = () => {
  if (!haccpChefName.value) return;

  haccpHeadChefApproved.value = true;
  saveHaccpState();
  playNewTicketSound();
  showNotification(
    "success",
    `Bếp Trưởng ${haccpChefName.value} đã ký duyệt báo cáo HACCP ca trực.`,
  );
};

const resetHaccpForNewShift = () => {
  const currentLog = {
    shiftDate: new Date().toLocaleDateString(),
    chefName: haccpChefName.value,
    status: haccpHaccpStatus.value,
    actionNote: haccpActionNote.value,
    fridgeTemp: haccpPreFridgeTemp.value,
    freezerTemp: haccpPreFreezerTemp.value,
    incidentCount: haccpIncidents.value.length,
  };

  try {
    const historyRaw = localStorage.getItem("kds_haccp_history");
    const history = historyRaw ? JSON.parse(historyRaw) : [];
    history.push(currentLog);
    localStorage.setItem("kds_haccp_history", JSON.stringify(history));
  } catch (e) {
    console.error("Error saving history:", e);
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
  haccpPostShiftNote.value = "";
  haccpPostSaved.value = false;
  haccpHeadChefApproved.value = false;
  haccpChefName.value = "";
  haccpHaccpStatus.value = "Compliant";
  haccpActionNote.value = "";
  tempTransferConfirmed.value = false;

  localStorage.removeItem("kds_haccp_state");
  showNotification("info", "Đã khởi tạo nhật ký HACCP cho ca trực mới.");
  haccpActiveTab.value = "preshift";
};

// Helpers to get station for items
const getItemStation = (
  name: string,
): "Grill" | "Hotpot" | "Cold" | "Fried" | "Bar" => {
  const lower = name.toLowerCase();
  if (
    lower.includes("nướng") ||
    lower.includes("sườn") ||
    lower.includes("steak") ||
    lower.includes("ba chỉ") ||
    lower.includes("bò") ||
    lower.includes("wagyu")
  )
    return "Grill";
  if (
    lower.includes("lẩu") ||
    lower.includes("sukiyaki") ||
    lower.includes("soup") ||
    lower.includes("canh")
  )
    return "Hotpot";
  if (
    lower.includes("rau") ||
    lower.includes("gỏi") ||
    lower.includes("salad") ||
    lower.includes("lạnh") ||
    lower.includes("sushi") ||
    lower.includes("kim chi") ||
    lower.includes("dưa")
  )
    return "Cold";
  if (
    lower.includes("chiên") ||
    lower.includes("khoai tây") ||
    lower.includes("tempura") ||
    lower.includes("nem") ||
    lower.includes("gà")
  )
    return "Fried";
  return "Bar";
};

const getStationLabel = (key: string): string => {
  const s = stations.find((item) => item.key === key);
  return s ? s.label : "Khác";
};

// Play audio alert when a new order or request comes in
const playNewTicketSound = () => {
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "sine";
    oscillator.frequency.value = 880; // A5 note
    gainNode.gain.setValueAtTime(0.08, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.15);
  } catch (e) {
    console.warn("Audio context failed to initialize:", e);
  }
};

const playAcknowledgeSound = () => {
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "sine";
    oscillator.frequency.setValueAtTime(600, audioCtx.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(
      1000,
      audioCtx.currentTime + 0.1,
    );
    gainNode.gain.setValueAtTime(0.06, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.12);
  } catch (e) {
    console.warn(e);
  }
};

const playCompleteSound = () => {
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "triangle";
    oscillator.frequency.setValueAtTime(523.25, audioCtx.currentTime); // C5
    oscillator.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.08); // E5
    oscillator.frequency.setValueAtTime(783.99, audioCtx.currentTime + 0.16); // G5
    gainNode.gain.setValueAtTime(0.08, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.3);
  } catch (e) {
    console.warn(e);
  }
};

const playAlertSound = () => {
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "sawtooth";
    oscillator.frequency.setValueAtTime(440, audioCtx.currentTime);
    oscillator.frequency.setValueAtTime(880, audioCtx.currentTime + 0.1);
    gainNode.gain.setValueAtTime(0.04, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.2);
  } catch (e) {
    console.warn(e);
  }
};

const playWarningSound = () => {
  try {
    const audioCtx = new (
      window.AudioContext || (window as any).webkitAudioContext
    )();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.type = "square";
    oscillator.frequency.setValueAtTime(150, audioCtx.currentTime);
    oscillator.frequency.linearRampToValueAtTime(
      300,
      audioCtx.currentTime + 0.25,
    );
    gainNode.gain.setValueAtTime(0.05, audioCtx.currentTime);
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.3);
  } catch (e) {
    console.warn(e);
  }
};

// Alerts display helper
const showNotification = (
  type: "success" | "error" | "info" | "warning",
  message: string,
) => {
  notification.value = { type, message };
  setTimeout(() => {
    notification.value = null;
  }, 4000);
};

// Check if ticket has allergy or warning notes
const hasAllergyNote = (order: Order): boolean => {
  return order.items.some((i) => {
    const note = (i.note || "").toLowerCase();
    return (
      note.includes("dị ứng") ||
      note.includes("allergy") ||
      note.includes("nghiêm trọng")
    );
  });
};

// Available tables selector populated from active orders + defaults
const availableTablesForRequests = computed(() => {
  const activeTables = orders.value.map((o) => getTableCode(o.table));
  const defaults = [
    "A01",
    "A02",
    "A03",
    "A04",
    "A05",
    "B01",
    "B02",
    "B03",
    "C01",
    "C02",
  ];
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
    status: "Pending",
    priority: newRequestPriority.value,
    createdAt: Date.now(),
  });

  // Save to localStorage
  saveGrillRequests();

  // Sounds & Alerts
  playNewTicketSound();
  showNotification(
    newRequestPriority.value === "Urgent" ? "warning" : "success",
    `Đã gửi yêu cầu ${newRequestType.value === "GrillChange" ? "thay vỉ" : "châm than"} gấp cho Bàn ${newRequestTable.value}!`,
  );

  // Reset form
  newRequestTable.value = "";
  showGrillRequestModal.value = false;
};

// Start treating request (simulates the 2-3 minutes process)
const startGrillRequest = (req: GrillRequest) => {
  req.status = "Inprogress";
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
  showNotification(
    "info",
    `Bắt đầu thực hiện ${req.type === "GrillChange" ? "thay vỉ" : "châm than"} cho Bàn ${req.table}. Dự kiến 2 phút.`,
  );
};

// Finish request
const completeGrillRequest = (req: GrillRequest) => {
  if (req.timer) clearInterval(req.timer);
  grillRequests.value = grillRequests.value.filter((r) => r.id !== req.id);
  saveGrillRequests();
  showNotification(
    "success",
    `Đã hoàn tất xử lý vỉ/than cho Bàn ${req.table}!`,
  );
  playNewTicketSound();
};

// Cancel/Delete request
const cancelGrillRequest = (req: GrillRequest) => {
  if (req.timer) clearInterval(req.timer);
  grillRequests.value = grillRequests.value.filter((r) => r.id !== req.id);
  saveGrillRequests();
  showNotification("info", `Đã hủy yêu cầu vỉ/than tại Bàn ${req.table}.`);
};

// Get elapsed time in minutes:seconds
const getRequestElapsedTime = (createdAt: number): string => {
  const diffSec = Math.floor((Date.now() - createdAt) / 1000);
  return formatWaitTime(diffSec);
};

// Save requests to localStorage
const saveGrillRequests = () => {
  // Save requests without timers
  const data = grillRequests.value.map((r) => ({
    id: r.id,
    table: r.table,
    type: r.type,
    status: r.status,
    priority: r.priority,
    createdAt: r.createdAt,
    timeLeft: r.timeLeft,
  }));
  localStorage.setItem("kds_grill_requests", JSON.stringify(data));
};

// Load requests from localStorage
const loadGrillRequests = () => {
  try {
    const raw = localStorage.getItem("kds_grill_requests");
    if (raw) {
      const data = JSON.parse(raw) as any[];
      grillRequests.value = data.map((r) => {
        let timer = null;
        if (r.status === "Inprogress" && r.timeLeft && r.timeLeft > 0) {
          // Re-establish timer
          const timeLeftVal = ref(r.timeLeft);
          const interval = setInterval(() => {
            if (timeLeftVal.value > 0) {
              timeLeftVal.value--;
              r.timeLeft = timeLeftVal.value;
              saveGrillRequests();
            } else {
              clearInterval(interval);
              const found = grillRequests.value.find((req) => req.id === r.id);
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
          timer,
        };
      });
    }
  } catch (e) {
    console.error("Error loading grill requests:", e);
  }
};

// Computed property filtering orders
const filteredOrders = computed(() => {
  let result = orders.value.map((order) => {
    // Slice items by active station
    let items = order.items;
    if (activeStation.value !== "ALL") {
      items = order.items.filter(
        (item) => getItemStation(item.name) === activeStation.value,
      );
    }
    return {
      ...order,
      displayItems: items,
    };
  });

  // Filter out orders with no items belonging to this station
  result = result.filter((order) => order.displayItems.length > 0);

  // Search by search query
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(
      (order) =>
        order.table.toLowerCase().includes(q) ||
        order.id.toLowerCase().includes(q),
    );
  }

  // Sorting: Remake always bypasses normal queue and goes to the absolute top based on kitchen_preprouting.mmd
  result.sort((a, b) => {
    const aRemake = isOrderRemake(a) ? 1 : 0;
    const bRemake = isOrderRemake(b) ? 1 : 0;
    if (aRemake !== bRemake) {
      return bRemake - aRemake; // Remake first
    }

    if (sortOrder.value === "oldest") {
      return b.waitTime - a.waitTime;
    } else if (sortOrder.value === "newest") {
      return a.waitTime - b.waitTime;
    } else if (sortOrder.value === "priority") {
      const isPriority = (o: any) => {
        const isDelayed = o.waitTime >= 900;
        const hasAllergy = o.items.some((i: any) => {
          const note = (i.note || "").toLowerCase();
          return (
            note.includes("dị ứng") ||
            note.includes("allergy") ||
            note.includes("vip") ||
            note.includes("gấp") ||
            note.includes("lại")
          );
        });
        return (isDelayed ? 2 : 0) + (hasAllergy ? 3 : 0);
      };
      const aPri = isPriority(a);
      const bPri = isPriority(b);
      if (aPri !== bPri) return bPri - aPri;
      return b.waitTime - a.waitTime;
    }
    return 0;
  });

  return result;
});

// Kanban column divisions
const pendingOrders = computed(() =>
  filteredOrders.value.filter((o) => o.status === "pending"),
);
const preparingOrders = computed(() =>
  filteredOrders.value.filter((o) => o.status === "preparing"),
);
const readyOrders = computed(() =>
  filteredOrders.value.filter(
    (o) => o.status === "ready" && !completedOrders.value.includes(o.id),
  ),
);
const doneOrders = computed(() =>
  filteredOrders.value.filter(
    (o) => o.status === "done" || completedOrders.value.includes(o.id),
  ),
);

// Status counts
const countPending = computed(
  () => orders.value.filter((o) => o.status === "pending").length,
);
const countPreparing = computed(
  () => orders.value.filter((o) => o.status === "preparing").length,
);
const countReady = computed(
  () =>
    orders.value.filter(
      (o) => o.status === "ready" && !completedOrders.value.includes(o.id),
    ).length,
);
const countDone = computed(
  () =>
    orders.value.filter(
      (o) => o.status === "done" || completedOrders.value.includes(o.id),
    ).length,
);
const countDelayed = computed(
  () =>
    orders.value.filter(
      (o) => o.status !== "done" && o.status !== "ready" && o.waitTime >= 900,
    ).length,
);
const qcQueueCount = computed(() => countReady.value);

// Actions handlers
const toggleItemStatus = async (item: OrderItem) => {
  item.done = !item.done;
  const newStatus: OrderStatus = item.done ? "Served" : "Preparing";
  try {
    const { error: err } = await supabase
      .from("order_items")
      .update({ status: newStatus })
      .eq("id", item.id);
    if (err) throw err;
    showNotification("success", `Đã cập nhật trạng thái món: ${item.name}`);
  } catch (e) {
    showNotification(
      "error",
      `Không thể cập nhật trạng thái món: ${e instanceof Error ? e.message : String(e)}`,
    );
    item.done = !item.done; // roll back on error
  }
};

const moveToPreparing = async (order: Order) => {
  order.status = "preparing";
  try {
    const { error: err } = await supabase
      .from("orders")
      .update({ status: "Preparing" })
      .eq("id", order.id);
    if (err) throw err;
    showNotification(
      "info",
      `Bàn ${getTableCode(order.table)}: Bắt đầu chế biến.`,
    );
    playAcknowledgeSound();
  } catch (e) {
    showNotification(
      "error",
      `Lỗi kết nối: ${e instanceof Error ? e.message : String(e)}`,
    );
    order.status = "pending";
  }
};

const moveToReady = async (order: Order) => {
  order.status = "ready";
  try {
    const { error: err1 } = await supabase
      .from("orders")
      .update({ status: "Served" })
      .eq("id", order.id);
    const { error: err2 } = await supabase
      .from("order_items")
      .update({ status: "Served" })
      .eq("order_id", order.id);
    if (err1 || err2) throw err1 || err2;
    showNotification(
      "success",
      `Bàn ${getTableCode(order.table)}: Đã kiểm tra QC đạt chuẩn và đưa lên Pass.`,
    );
    playCompleteSound();
  } catch (e) {
    showNotification(
      "error",
      `Lỗi kết nối: ${e instanceof Error ? e.message : String(e)}`,
    );
    order.status = "preparing";
  }
};

const moveToDone = async (order: Order) => {
  if (!completedOrders.value.includes(order.id)) {
    completedOrders.value.push(order.id);
  }
  order.status = "done";
  order.items.forEach((item) => (item.done = true));
  try {
    const { error: err1 } = await supabase
      .from("orders")
      .update({ status: "Served" })
      .eq("id", order.id);
    const { error: err2 } = await supabase
      .from("order_items")
      .update({ status: "Served" })
      .eq("order_id", order.id);
    if (err1 || err2) throw err1 || err2;
    showNotification(
      "success",
      `Bàn ${getTableCode(order.table)}: Đơn hàng hoàn tất và sẵn sàng phục vụ.`,
    );
    playCompleteSound();
  } catch (e) {
    showNotification(
      "error",
      `Lỗi kết nối: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
};

// Ingredient Check & QC Log Helper logic
const getIngredientsForOrder = (order: Order) => {
  const list: {
    name: string;
    qty: string;
    status: "ok" | "low" | "out";
    icon: string;
  }[] = [];
  order.items.forEach((item) => {
    const isOut = isItem86d(item.name);
    if (
      item.name.toLowerCase().includes("sườn") ||
      item.name.toLowerCase().includes("wagyu") ||
      item.name.toLowerCase().includes("thịt")
    ) {
      list.push({
        name: "Thịt bò Wagyu",
        qty: `${item.qty * 250}g`,
        status: isOut ? "out" : "ok",
        icon: "🥩",
      });
      list.push({
        name: "Nước xốt gia vị",
        qty: `${item.qty * 50}ml`,
        status: "ok",
        icon: "🏺",
      });
    } else if (
      item.name.toLowerCase().includes("lẩu") ||
      item.name.toLowerCase().includes("sukiyaki")
    ) {
      list.push({
        name: "Nước lẩu Sukiyaki",
        qty: `${item.qty * 1}L`,
        status: "ok",
        icon: "🍲",
      });
      list.push({
        name: "Rau lẩu tổng hợp",
        qty: `${item.qty * 300}g`,
        status: isOut ? "out" : "low",
        icon: "🥬",
      });
    } else if (
      item.name.toLowerCase().includes("rau") ||
      item.name.toLowerCase().includes("cải") ||
      item.name.toLowerCase().includes("nấm")
    ) {
      list.push({
        name: "Rau cải sạch",
        qty: `${item.qty * 150}g`,
        status: isOut ? "out" : "ok",
        icon: "🥦",
      });
      list.push({
        name: "Nấm đùi gà",
        qty: `${item.qty * 100}g`,
        status: "ok",
        icon: "🍄",
      });
    } else {
      list.push({
        name: `Nguyên liệu ${item.name}`,
        qty: `${item.qty * 1} phần`,
        status: isOut ? "out" : "ok",
        icon: "📦",
      });
    }
  });
  if (order.items.length > 0) {
    const isGarlic86d = isItem86d("Tỏi băm") || isItem86d("Tỏi");
    list.push({
      name: "Tỏi băm",
      qty: "50g",
      status: isGarlic86d
        ? "out"
        : order.timestamp % 7 === 0
          ? "out"
          : order.timestamp % 5 === 0
            ? "low"
            : "ok",
      icon: "🧄",
    });
  }
  return list;
};

const openIngredientCheck = (order: Order) => {
  ingredientCheckOrder.value = order;
  ingredientCheckList.value = getIngredientsForOrder(order);
  showIngredientCheckModal.value = true;
};

const confirmStartCooking = () => {
  if (ingredientCheckOrder.value) {
    const orderId = ingredientCheckOrder.value.id;
    if (!startedOrders.value.includes(orderId)) {
      startedOrders.value.push(orderId);
    }
  }
  showIngredientCheckModal.value = false;
  playAcknowledgeSound();
};

const openReportOutFromCheck = () => {
  const outIng = ingredientCheckList.value.find((i) => i.status === "out");
  if (outIng) {
    const mItem = menuItems.value.find(
      (mi) =>
        mi.name.toLowerCase().includes(outIng.name.toLowerCase()) ||
        outIng.name.toLowerCase().includes(mi.name.toLowerCase()),
    );
    reportOutItem.value = mItem || null;
  }
  showIngredientCheckModal.value = false;
  showReportOutModal.value = true;
};

const submitReportOut = async () => {
  if (!reportOutItem.value) return;
  const item = reportOutItem.value;

  item.is_available = false;
  try {
    if (!item.id.startsWith("ext-") && !item.id.startsWith("def-")) {
      await supabase
        .from("menu_items")
        .update({ is_available: false })
        .eq("id", item.id);
    }
  } catch (e) {
    console.error("Error updating DB menu item:", e);
  }

  showNotification("warning", `Đã đánh dấu hết hàng: ${item.name}`);
  playWarningSound();

  staffNotificationItemName.value = item.name;
  staffNotificationReason.value =
    reportOutReason.value === "Khác"
      ? reportOutCustomReason.value
      : reportOutReason.value;

  const affected: { id: string; table: string; itemQty: number }[] = [];
  orders.value.forEach((ord) => {
    if (ord.status !== "done") {
      const match = ord.items.find(
        (i) =>
          i.name.toLowerCase().includes(item.name.toLowerCase()) ||
          item.name.toLowerCase().includes(i.name.toLowerCase()),
      );
      if (match) {
        affected.push({
          id: ord.id,
          table: getTableCode(ord.table),
          itemQty: match.qty,
        });
      }
    }
  });
  staffNotificationAffectedOrders.value = affected;

  if (item.name.toLowerCase().includes("tỏi")) {
    staffNotificationReplacements.value = ["Hành phi", "Ớt băm", "Gừng băm"];
  } else if (
    item.name.toLowerCase().includes("thịt") ||
    item.name.toLowerCase().includes("sườn")
  ) {
    staffNotificationReplacements.value = ["Thịt heo Iberico", "Dẻ sườn bò Mỹ"];
  } else {
    staffNotificationReplacements.value = [
      "Món tương tự trong menu",
      "Salad trộn",
      "Đậu hũ",
    ];
  }

  staffNotificationNotes.value = `Khách có thể đổi sang ${staffNotificationReplacements.value[0]} hoặc món khác tương đương.`;

  showReportOutModal.value = false;
  showStaffNotificationModal.value = true;
};

const sendStaffNotification = () => {
  showNotification(
    "success",
    `Đã gửi thông báo đổi món đến POS & Phục vụ của ${staffNotificationAffectedOrders.value.length} bàn.`,
  );
  playAlertSound();
  showStaffNotificationModal.value = false;
};

const openQcCheck = (order: Order) => {
  qcOrder.value = order;
  qcChecklist.value = {
    plating: false,
    temperature: false,
    weight: false,
    allergy: false,
    taste: false,
  };
  qcResult.value = null;
  qcFailReason.value = "";
  showQcModal.value = true;
};

const submitQcResult = async () => {
  if (!qcOrder.value) return;
  const order = qcOrder.value;

  if (qcResult.value === "pass") {
    await moveToReady(order);
  } else if (qcResult.value === "fail") {
    toggleOrderRemake(order.id);
    startedOrders.value = startedOrders.value.filter((id) => id !== order.id);
    showNotification(
      "error",
      `Bàn ${getTableCode(order.table)}: QC KHÔNG ĐẠT. Đã yêu cầu làm lại (Remake) với ưu tiên cao.`,
    );
    playWarningSound();
  }
  showQcModal.value = false;
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
  if (minutes >= 15) return "border-red-500 bg-red-100 delayed-pulse";
  if (minutes >= 10) return "border-yellow-500 bg-yellow-900/10";
  return "border-indigo-900/50 bg-indigo-950/5";
};

const getTimerTextClass = (seconds: number): string => {
  const minutes = seconds / 60;
  if (minutes >= 20)
    return "text-red-600 animate-blink font-black text-shadow-red";
  if (minutes >= 15) return "text-red-600 font-bold";
  if (minutes >= 10) return "text-orange-600";
  return "text-green-600";
};

const formatWaitTime = (seconds: number): string => {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
};

onMounted(async () => {
  // Load local requests, sub-steps, HACCP, remake & prep states
  loadGrillRequests();
  loadSubSteps();
  loadHaccpState();
  loadRemakeOrders();
  loadPrepTasks();
  await fetchTodayBookingsForPrep();
  await fetchMenuItems();

  // Fetch table mappings
  await fetchTableMap();

  // Update Clock
  clockInterval = setInterval(() => {
    currentTime.value = new Date().toLocaleTimeString();
  }, 1000);

  // Fetch initial raw orders
  try {
    const { data: rawOrders, error: err } = await supabase
      .from("orders")
      .select(
        "id, table_id, created_at, status, order_items(id, name_snapshot, quantity, note, status)",
      );
    if (err) throw err;

    if (rawOrders) {
      orders.value = rawOrders.map((ro: any) => {
        const d = new Date(ro.created_at);
        let st: "pending" | "preparing" | "ready" | "done" = "pending";
        if (ro.status === "Preparing") st = "preparing";
        if (ro.status === "Served") st = "ready";
        if (ro.status === "Paid") st = "done";

        return {
          id: ro.id,
          table: ro.table_id || "T-??",
          time: d.toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          }),
          timestamp: d.getTime(),
          waitTime: Math.floor((Date.now() - d.getTime()) / 1000),
          status: st,
          items: (ro.order_items || []).map((ri: any) => ({
            id: ri.id,
            name: ri.name_snapshot,
            qty: ri.quantity,
            note: ri.note,
            done: ri.status === "Served" || ri.status === "Paid",
          })),
        };
      });
      mergeOrderItemsToMenu();
    }
  } catch (e) {
    showNotification(
      "error",
      `Lỗi tải dữ liệu bếp: ${e instanceof Error ? e.message : String(e)}`,
    );
  }

  // Realtime subscription for orders
  watchTable("orders", "*", (payload) => {
    const order = payload.new as any;
    const existing = orders.value.find((o) => o.id === order.id);
    if (existing) {
      if (order.status === "Preparing") existing.status = "preparing";
      else if (order.status === "Served") existing.status = "ready";
      else if (order.status === "Paid") existing.status = "done";
      else if (order.status === "Pending") existing.status = "pending";
    } else if (order.id && payload.eventType === "INSERT") {
      const d = new Date(order.created_at || Date.now());
      orders.value.push({
        id: order.id,
        table: order.table_id || "T-??",
        time: d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
        timestamp: d.getTime(),
        waitTime: 0,
        status: "pending",
        items: [],
      });
      playNewTicketSound();
    }
  });

  // Realtime subscription for order_items
  watchTable("order_items", "*", (payload) => {
    const item = payload.new as any;
    if (payload.eventType === "INSERT") {
      const existingOrder = orders.value.find((o) => o.id === item.order_id);
      if (existingOrder) {
        if (!existingOrder.items.some((i) => i.id === item.id)) {
          existingOrder.items.push({
            id: item.id,
            name: item.name_snapshot,
            qty: item.quantity,
            note: item.note,
            done: item.status === "Served" || item.status === "Paid",
          });
          mergeOrderItemsToMenu();
          playNewTicketSound();
        }
      }
    } else if (payload.eventType === "UPDATE") {
      for (const o of orders.value) {
        const existingItem = o.items.find((i) => i.id === item.id);
        if (existingItem) {
          existingItem.done =
            item.status === "Served" || item.status === "Paid";
        }
      }
    }
  });

  // Realtime subscription for menu_items
  watchTable("menu_items", "*", (payload) => {
    const updatedItem = payload.new as any;
    if (updatedItem && updatedItem.id) {
      const existing = menuItems.value.find((i) => i.id === updatedItem.id);
      if (existing) {
        existing.is_available = updatedItem.is_available;
      } else if (payload.eventType === "INSERT") {
        menuItems.value.push({
          id: updatedItem.id,
          name: updatedItem.name,
          is_available: updatedItem.is_available,
        });
      }
    }
  });

  // Seconds counter updates wait times
  timerInterval = setInterval(() => {
    const now = Date.now();
    orders.value.forEach((order) => {
      if (order.status !== "done") {
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
  grillRequests.value.forEach((r) => {
    if (r.timer) clearInterval(r.timer);
  });
});
</script>

<style scoped>
/* Design Tokens */
.kds-container {
  font-feature-settings: "cv02", "cv03", "cv04", "cv11";
  background: #1a1a1a;
  color: #ffffff;
}

/* Header Styles */
.logo-brand {
  font-size: 24px;
  font-weight: 700;
  color: #ff6b35; /* Cam đỏ nổi bật */
  letter-spacing: 1px;
}

.tag-kds {
  background: #2196f3;
  color: white;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
  margin-left: 12px;
}

.station-badge {
  font-size: 16px;
  color: #e0e0e0;
  margin-left: 24px;
  padding: 8px 16px;
  background: #2d2d2d;
  border-radius: 8px;
  border: 1px solid #404040;
}

.digital-clock {
  font-family: "Courier New", monospace;
  font-size: 20px;
  color: #ffffff;
  font-weight: 700;
  letter-spacing: 1px;
}

/* Filter Bar Styles */
.station-btn {
  padding: 10px 20px;
  background: #3d3d3d;
  color: #b0b0b0;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  margin-right: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.station-btn.active {
  background: #2196f3;
  color: white;
  font-weight: 600;
}

.station-btn:hover {
  background: #4a4a4a;
}

.sort-dropdown {
  padding: 8px 16px;
  background: #3d3d3d;
  color: white;
  border: 1px solid #404040;
  border-radius: 6px;
  font-size: 13px;
  margin-left: 16px;
  outline: none;
}

.sort-dropdown:focus {
  border-color: #2196f3;
}

.search-input {
  padding: 8px 16px;
  background: #1a1a1a;
  border: 1px solid #404040;
  border-radius: 6px;
  color: white;
  font-size: 13px;
  margin-left: 16px;
  width: 200px;
  outline: none;
}

.search-input:focus {
  border-color: #2196f3;
}

.search-input::placeholder {
  color: #666666;
}

/* Status Bar Counters */
.status-counter {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 24px;
  margin-right: 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
}

.status-waiting {
  background: #1a237e; /* Xanh Navy */
  color: white;
}

.status-preparing {
  background: #e65100; /* Cam đậm */
  color: white;
}

.status-done {
  background: #2e7d32; /* Xanh lá */
  color: white;
}

.status-delayed {
  background: #c62828; /* Đỏ */
  color: white;
  animation: blink 1s infinite;
}

.count-badge {
  background: rgba(255, 255, 255, 0.3);
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 16px;
}

/* Kanban Board Columns */
.kanban-container {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  padding: 20px;
  overflow-x: auto;
  height: calc(100vh - 270px); /* Trừ header + filter + status */
  background: #1a1a1a;
}

.kanban-column {
  background: #252525;
  border-radius: 12px;
  padding: 16px;
  overflow-y: auto;
  min-height: 400px;
}

.kanban-column h3 {
  font-size: 16px;
  font-weight: 600;
  color: #e0e0e0;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #404040;
}

/* Ticket Cards */
.ticket-card {
  background: #2d2d2d;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease;
  border: 2px solid #404040;
  cursor: pointer;
  position: relative;
}

.ticket-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
}

.ticket-card.new,
.ticket-card.status-pending {
  border-color: #1a237e; /* Xanh đậm - Mới */
  animation: slide-in 0.3s ease;
}

.ticket-card.preparing,
.ticket-card.status-cooking {
  border-color: #e65100; /* Cam - Đang nấu */
  background: linear-gradient(135deg, #2d2d2d 0%, #3d2817 100%);
}

.ticket-card.status-ready {
  border-color: #2e7d32;
  background: linear-gradient(135deg, #2d2d2d 0%, #1a3d1a 100%);
}

.ticket-card.done,
.ticket-card.status-done {
  opacity: 0.8;
  background: #252525;
  border-color: #2e7d32; /* Xanh lá - Sẵn sàng */
}

.ticket-card.done .ticket-header,
.ticket-card.status-done .ticket-header,
.ticket-card.done .table-info,
.ticket-card.status-done .table-info {
  text-decoration: line-through;
  color: #888888;
}

.ticket-card.remake,
.ticket-card.status-remake {
  border-color: #9c27b0 !important; /* Tím - Ưu tiên cao */
  border-width: 3px !important;
  background: linear-gradient(135deg, #2d2d2d 0%, #341e3d 100%) !important;
  animation: pulse-border 1.5s infinite !important;
}

.ticket-card.delayed,
.ticket-card.status-delayed {
  border-color: #c62828 !important; /* Đỏ - Trễ */
  animation: pulse-border 2s infinite !important;
}

/* === HEADER BUTTON DESIGN SYSTEM === */
.header-btn {
  /* Kích thước chuẩn */
  height: 48px;
  min-width: 120px;
  padding: 0 20px;

  /* Typography */
  font-size: 14px;
  font-weight: 600;
  font-family: "Inter", sans-serif;
  letter-spacing: 0.3px;

  /* Layout */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;

  /* Visual */
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;

  /* Text */
  color: #ffffff;
  text-transform: none; /* Không viết hoa tất cả */
  text-decoration: none;
}

/* Hover State */
.header-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  filter: brightness(1.1);
}

/* Active State */
.header-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
}

/* Focus State (Accessibility) */
.header-btn:focus-visible {
  outline: 3px solid #2196f3;
  outline-offset: 2px;
}

/* === BUTTON VARIANTS === */

/* Primary Action (Xanh dương - Navigation chính / Sơ chế) */
.header-btn.btn-kitchen-kds,
.header-btn.btn-prep-list {
  background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%);
}

/* Secondary Action (Tím - Expo QC) */
.header-btn.btn-expo-qc {
  background: linear-gradient(135deg, #9c27b0 0%, #7b1fa2 100%);
}

/* Warning Action (Cam - Yêu cầu Vỉ/Than) */
.header-btn.btn-grill-request {
  background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);
}

/* Success Action (Xanh lá - HACCP) */
.header-btn.btn-haccp {
  background: linear-gradient(135deg, #4caf50 0%, #388e3c 100%);
}

/* Danger Action (Đỏ - 86'd) */
.header-btn.btn-86d {
  background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%);
}

/* Neutral Action (Xám - Ẩn Panel) */
.header-btn.btn-hide-panel {
  background: linear-gradient(135deg, #616161 0%, #424242 100%);
}

/* Urgent Alert (Đỏ đậm - Cảnh báo trễ) */
.header-btn.btn-alert-delayed {
  background: linear-gradient(135deg, #c62828 0%, #b71c1c 100%);
  animation: pulse-urgent 2s infinite;
  height: 56px; /* Lớn hơn để nổi bật */
  font-size: 15px;
  font-weight: 700;
  cursor: default;
}

/* Active State for Routing link */
.header-btn.active {
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.5);
  filter: brightness(1.2);
  transform: scale(1.02);
}

/* === ICON STYLES === */
.header-btn .btn-icon {
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
}

/* === BADGE STYLES === */
.header-btn .badge {
  /* Vị trí */
  position: absolute;
  top: -6px;
  right: -6px;

  /* Kích thước */
  min-width: 22px;
  height: 22px;
  padding: 0 6px;

  /* Visual */
  background: #f44336;
  color: #ffffff;
  border-radius: 11px;
  border: 2px solid #1a1a1a; /* Viền đồng màu với header */

  /* Typography */
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;

  /* Animation */
  transition: all 0.3s ease;
}

/* Badge với số lượng lớn */
.header-btn .badge.large {
  background: #ff5722;
  animation: badge-pulse 1.5s infinite;
}

@keyframes pulse-urgent {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(198, 40, 40, 0.7);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(198, 40, 40, 0);
  }
}

@keyframes badge-pulse {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
}

/* Buttons */
.acknowledge-btn {
  width: 100%;
  padding: 12px;
  background: #2196f3;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.acknowledge-btn:hover {
  background: #1976d2;
  transform: scale(1.02);
}

.complete-btn {
  width: 100%;
  padding: 12px;
  background: #2e7d32;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.complete-btn:hover {
  background: #256629;
  transform: scale(1.02);
}

/* Micro Checklist */
.micro-checklist {
  margin: 12px 0;
  padding: 12px;
  background: #1a1a1a;
  border-radius: 8px;
}

.checklist-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 0;
  font-size: 12px;
  color: #b0b0b0;
}

.checklist-item.completed {
  color: #4caf50;
}

/* Quick Actions */
.quick-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.quick-action-btn {
  flex: 1;
  padding: 8px;
  background: #3d3d3d;
  color: white;
  border: 1px solid #404040;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  transition: all 0.2s;
}

.quick-action-btn:hover {
  background: #4a4a4a;
  border-color: #ff9800;
}

/* Badges */
.badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-right: 6px;
  border: 1px solid transparent;
}

.badge-remake {
  background: #9c27b0;
  color: white;
  animation: blink 1s infinite;
}

.badge-buffet-1 {
  background: #ff9800;
  color: white;
}

.badge-buffet-add {
  background: #ffc107;
  color: #333;
}

.badge-alacarte {
  background: #2196f3;
  color: white;
}

/* 86'd Out of Stock warning */
.sold-out-warning {
  background: rgba(244, 67, 54, 0.2);
  border: 1px solid #f44336;
  color: #f44336;
  padding: 8px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  text-align: center;
  margin: 8px 0;
  animation: blink 1s infinite;
}

/* Modals Overlay */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.modal-content {
  background: #2d2d2d;
  border-radius: 16px;
  padding: 24px;
  max-width: 800px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  border: 1px solid #404040;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}

.sold-out-list {
  margin-top: 20px;
}

.sold-out-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background: #1a1a1a;
  border-radius: 8px;
  margin-bottom: 12px;
  border: 1px solid #333;
}

.toggle-switch {
  width: 60px;
  height: 32px;
  background: #c62828; /* Đỏ - Hết hàng */
  border-radius: 16px;
  position: relative;
  cursor: pointer;
  transition: all 0.3s;
}

.toggle-switch.active {
  background: #4caf50; /* Xanh lá - Còn hàng */
}

.toggle-switch::after {
  content: "";
  position: absolute;
  width: 24px;
  height: 24px;
  background: white;
  border-radius: 50%;
  top: 4px;
  left: 4px;
  transition: all 0.3s;
}

.toggle-switch.active::after {
  left: 32px;
}

/* Alert Banners */
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
  border-color: #4caf50;
  color: #4caf50;
}

.alert-banner.error {
  background: rgba(244, 67, 54, 0.2);
  border-color: #f44336;
  color: #f44336;
}

.alert-banner.info {
  background: rgba(33, 150, 243, 0.2);
  border-color: #2196f3;
  color: #2196f3;
}

.alert-banner.warning {
  background: rgba(255, 152, 0, 0.2);
  border-color: #ff9800;
  color: #ff9800;
}

/* Animations */
@keyframes blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

@keyframes pulse {
  0%,
  100% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.02);
    opacity: 0.8;
  }
}

@keyframes pulse-border {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(0, 0, 0, 0);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(255, 152, 0, 0.25);
  }
}

@keyframes slide-in {
  from {
    transform: translateX(-100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes slide-down {
  from {
    transform: translateY(-100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

/* Accessibility */
button:focus-visible,
input:focus-visible,
select:focus-visible {
  outline: 3px solid #2196f3;
  outline-offset: 2px;
}

/* Minimum Touch Targets */
button,
select,
input {
  min-height: 48px;
}

.quick-action-btn {
  min-height: 40px; /* specific sub buttons */
}

.acknowledge-btn,
.complete-btn {
  min-height: 56px;
  font-size: 16px;
}

/* Responsive Design */
/* Large screens (>1920px) */
@media (min-width: 1920px) {
  .kanban-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 24px;
  }

  .ticket-card {
    min-height: 240px;
  }
}

/* Standard POS (1366-1920px) */
@media (min-width: 1366px) and (max-width: 1919px) {
  .kanban-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
  }
}

/* Tablet (768-1366px) */
@media (min-width: 768px) and (max-width: 1365px) {
  .kanban-container {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Mobile (<768px) */
@media (max-width: 767px) {
  .kanban-container {
    grid-template-columns: 1fr;
  }

  header {
    flex-direction: column;
    height: auto;
    padding: 12px;
    gap: 12px;
  }
}

/* High Contrast Mode */
@media (prefers-contrast: high) {
  .ticket-card {
    border-width: 3px;
  }

  .badge {
    border: 2px solid currentColor;
  }
}

/* Reduced Motion Mode */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Custom Modal Styles for Kitchen Operations */
.ingredient-list {
  margin-bottom: 24px;
}

.ingredient-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #1a1a1a;
  border-radius: 8px;
  margin-bottom: 12px;
}

.ingredient-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.ingredient-icon {
  font-size: 24px;
}

.ingredient-name {
  font-size: 16px;
  color: #e0e0e0;
}

.ingredient-qty {
  font-size: 14px;
  color: #b0b0b0;
  margin-left: 12px;
}

.ingredient-status {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.status-ok {
  background: #2e7d32;
  color: white;
}

.status-low {
  background: #ff9800;
  color: white;
}

.status-out {
  background: #c62828;
  color: white;
  animation: blink 1s infinite;
}

.warning-box {
  background: rgba(255, 152, 0, 0.2);
  border: 2px solid #ff9800;
  color: #ff9800;
  padding: 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 24px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.modal-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-width: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-btn.cancel {
  background: #424242;
  color: white;
}

.modal-btn.cancel:hover {
  background: #4f4f4f;
  transform: scale(1.05);
}

.modal-btn.continue {
  background: #ff9800;
  color: white;
}

.modal-btn.continue:hover {
  background: #ffaa2b;
  transform: scale(1.05);
}

.modal-btn.report-out {
  background: #c62828;
  color: white;
}

.modal-btn.report-out:hover {
  background: #d32f2f;
  transform: scale(1.05);
}

/* Touch target helpers */
.touch-target {
  min-height: 48px;
}

/* DESIGN OVERRIDES FOR KITCHEN KDS REDESIGN */

/* Design Tokens & Colors */
:root {
  --font-family: "Inter", -apple-system, sans-serif;
  --text-xs: 11px;
  --text-sm: 13px;
  --text-base: 14px;
  --text-lg: 16px;
  --text-xl: 20px;

  --font-regular: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --bg-tertiary: #3d3d3d;

  --color-pending: #1a237e;
  --color-cooking: #e65100;
  --color-ready: #2e7d32;
  --color-done: #616161;

  --color-accent: #2196f3;
  --color-danger: #f44336;
  --color-warning: #ff9800;
}

/* 1. Columns border-top styles */
.kanban-column.pending {
  border-top: 4px solid var(--color-pending);
}
.kanban-column.cooking {
  border-top: 4px solid var(--color-cooking);
}
.kanban-column.ready {
  border-top: 4px solid var(--color-ready);
}
.kanban-column.done {
  border-top: 4px solid var(--color-done);
}

/* 2. Unified ticket card styling */
.ticket-card {
  min-height: 180px;
  background: var(--bg-secondary) !important;
  border-radius: 10px !important;
  padding: 14px !important;
  margin-bottom: 10px !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
  border: none !important;
  border-left: 4px solid var(--color-pending) !important;
  transition: all 0.2s ease !important;
  font-family: var(--font-family) !important;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.ticket-card:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4) !important;
}

/* Card header - same style */
.ticket-card .flex.justify-between.items-start {
  display: flex !important;
  justify-content: space-between !important;
  align-items: center !important;
  margin-bottom: 10px !important;
  padding-bottom: 8px !important;
  border-bottom: 1px solid #404040 !important;
}

/* Ticket card table and title */
.ticket-card .logo-brand,
.ticket-card .text-xl,
.ticket-card .text-2xl {
  font-size: var(--text-lg) !important;
  font-weight: var(--font-bold) !important;
  color: white !important;
  font-family: var(--font-family) !important;
}

/* Wait timer styling */
.ticket-card .timer-display {
  font-family: "Courier New", monospace !important;
  font-size: var(--text-lg) !important;
  font-weight: var(--font-bold) !important;
}

.ticket-card .timer-display.normal {
  color: #4caf50 !important;
}
.ticket-card .timer-display.warning {
  color: #ff9800 !important;
}
.ticket-card .timer-display.danger {
  color: #f44336 !important;
  animation: blink-red-timer 1s infinite !important;
}

@keyframes blink-red-timer {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.4;
  }
}

/* Classification type badge styling */
.ticket-card .badge {
  display: inline-block !important;
  padding: 3px 10px !important;
  border-radius: 12px !important;
  font-size: var(--text-xs) !important;
  font-weight: var(--font-bold) !important;
  text-transform: uppercase !important;
  margin-bottom: 10px !important;
  position: static !important; /* overrides header button badges absolute */
  border: none !important;
}

.ticket-card .badge.badge-remake {
  background: #9c27b0 !important;
  color: white !important;
  animation: blink-red-timer 1s infinite !important;
}
.ticket-card .badge.badge-buffet-1 {
  background: #ff9800 !important;
  color: white !important;
}
.ticket-card .badge.badge-buffet-add {
  background: #e65100 !important;
  color: white !important;
}
.ticket-card .badge.badge-alacarte {
  background: #2196f3 !important;
  color: white !important;
}

/* Item list spacing and typography */
.ticket-card .space-y-1,
.ticket-card .space-y-2 {
  margin-bottom: 10px !important;
}

.ticket-card .flex.justify-between.items-center.text-sm,
.ticket-card .flex.flex-col.p-2\.5 {
  display: flex !important;
  align-items: flex-start !important;
  gap: 8px !important;
  padding: 6px 0 !important;
  border-bottom: 1px solid #333 !important;
  background: transparent !important;
  border-radius: 0 !important;
}

.ticket-card .text-\[\#FF9800\] {
  font-size: var(--text-base) !important;
  font-weight: var(--font-bold) !important;
  color: #ff9800 !important;
  min-width: 30px !important;
}

.ticket-card .text-muted-foreground {
  flex: 1 !important;
  font-size: var(--text-base) !important;
  color: #e0e0e0 !important;
  font-family: var(--font-family) !important;
}

/* Allergy warning / notes styling */
.ticket-card .bg-red-950\/40,
.ticket-card .ticket-note {
  background: rgba(255, 152, 0, 0.15) !important;
  border-left: 3px solid #ff9800 !important;
  padding: 6px 10px !important;
  border-radius: 4px !important;
  font-size: var(--text-xs) !important;
  color: #ffb74d !important;
  margin-bottom: 10px !important;
  border-top: none !important;
  border-right: none !important;
  border-bottom: none !important;
}

/* Action button styling */
.ticket-card .acknowledge-btn,
.ticket-card .complete-btn,
.ticket-card .complete-btn.bg-green-600 {
  width: 100% !important;
  padding: 10px !important;
  border: none !important;
  border-radius: 8px !important;
  font-size: var(--text-base) !important;
  font-weight: var(--font-bold) !important;
  color: white !important;
  cursor: pointer !important;
  text-transform: uppercase !important;
  min-height: auto !important;
  display: block !important;
  text-align: center !important;
}

.ticket-card .acknowledge-btn {
  background: #2196f3 !important;
}
.ticket-card .acknowledge-btn.bg-amber-600 {
  background: #ff9800 !important;
}
.ticket-card .complete-btn {
  background: #4caf50 !important;
}

/* Status-specific card borders */
.ticket-card.status-pending {
  border-left-color: var(--color-pending) !important;
}
.ticket-card.preparing {
  border-left-color: var(--color-cooking) !important;
}
.ticket-card.status-ready {
  border-left-color: var(--color-ready) !important;
}
.ticket-card.done {
  border-left-color: var(--color-done) !important;
  opacity: 0.7 !important;
}

/* Collapsible Grill Sidebar */
.grill-sidebar {
  width: 300px;
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  background: var(--bg-secondary);
  border-left: 1px solid #404040;
  display: flex;
  flex-direction: column;
}

.grill-sidebar.collapsed {
  width: 50px;
}

.toggle-sidebar-btn {
  width: 100%;
  padding: 12px;
  background: #ff9800;
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 48px;
  transition: background 0.2s;
}

.toggle-sidebar-btn:hover {
  background: #e65100;
}

.toggle-sidebar-btn .sidebar-badge {
  background: #f44336;
  color: white;
  padding: 1px 6px;
  border-radius: 10px;
  font-size: 10px;
  font-weight: 700;
  border: 1px solid white;
}

.sidebar-content {
  padding: 0;
  display: flex;
  flex-direction: column;
  height: calc(100% - 48px);
  overflow: hidden;
}

/* Nav typography overrides */
.kanban-header {
  font-size: var(--text-sm) !important;
  font-weight: var(--font-bold) !important;
  font-family: var(--font-family) !important;
}

/* Empty State styling */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  text-align: center;
  color: #616161;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.empty-title {
  font-size: 16px;
  font-weight: 600;
  color: #888;
  margin-bottom: 8px;
}

.empty-desc {
  font-size: 13px;
  color: #666;
}
</style>
