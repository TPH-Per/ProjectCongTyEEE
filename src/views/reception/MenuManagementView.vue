<!--
  MenuManagementView.vue
  ─────────────────────────────────────────────────────────────────────────────
  3-Pane layout for Menu Management (Phase 1).

   ┌──────────┬──────────────────────┬────────────────────┐
   │ LEFT 25% │ MIDDLE 45%           │ RIGHT 30%          │
   │ Category │ Item Grid            │ Item Detail Form   │
   │ Tree     │ (thumbnail, badge,   │ (tabs: Basic,      │
   │ + DnD    │  toggle, actions)    │  Price & Tax,      │
   │          │                      │  Kitchen)          │
   └──────────┴──────────────────────┴────────────────────┘

  Hierarchy: Category → SubCategory (nullable) → Item
  Soft-delete only. Status changes broadcast via window.dispatchEvent.
-->
<template>
  <div class="flex flex-col gap-4 h-[calc(100vh-7.5rem)] select-none">

    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <!-- HEADER BAR                                                          -->
    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <div class="shrink-0 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
      <div class="flex items-start gap-3">
        <button
          @click="goBack"
          class="shrink-0 inline-flex items-center gap-1.5 px-3 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg text-xs font-bold transition-colors"
        >
          <ArrowLeft class="w-3.5 h-3.5" />
          Quay lại
        </button>
        <div>
          <h1 class="text-xl font-black text-gray-900 tracking-tight flex items-center gap-2">
            <Utensils class="w-5 h-5 text-[#E8772E]" />
            Quản lý Món
          </h1>
          <p class="text-xs text-gray-500 font-medium mt-0.5">
            Phân cấp: Category → SubCategory (tùy chọn) → Item · Soft delete · POS realtime sync
          </p>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <button
          @click="toggleAllItemsView"
          :class="[
            'inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-bold transition-colors',
            showAllItems
              ? 'bg-blue-600 hover:bg-blue-700 text-white shadow-sm'
              : 'bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200',
          ]"
        >
          <LayoutGrid class="w-3.5 h-3.5" />
          {{ showAllItems ? 'Xem theo danh mục' : 'Xem tất cả' }}
        </button>

        <div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-wider">
          <div class="flex items-center gap-1.5 bg-green-50 text-green-700 px-2.5 py-1.5 rounded-xl border border-green-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-green-500"></span>
            {{ activeItemCount }} đang bán
          </div>
          <div class="flex items-center gap-1.5 bg-amber-50 text-amber-700 px-2.5 py-1.5 rounded-xl border border-amber-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
            {{ soldOutCount }} hết hàng
          </div>
          <div class="flex items-center gap-1.5 bg-red-50 text-red-700 px-2.5 py-1.5 rounded-xl border border-red-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-red-500"></span>
            {{ inactiveCount }} đã khóa
          </div>
          <div class="flex items-center gap-1.5 bg-sky-50 text-sky-700 px-2.5 py-1.5 rounded-xl border border-sky-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-sky-500"></span>
            {{ totalItems }} tổng
          </div>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <!-- 3-PANE LAYOUT                                                        -->
    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <div class="flex-1 flex gap-4 min-h-0">

      <!-- ─────────────────────────────────────────────────────────────── -->
      <!-- LEFT PANE (25%): Category Tree                                  -->
      <!-- ─────────────────────────────────────────────────────────────── -->
      <aside class="w-[25%] shrink-0 bg-white border border-gray-200 rounded-2xl shadow-sm flex flex-col min-h-0 overflow-hidden">
        <!-- Tree header -->
        <div class="px-4 py-3 border-b border-gray-100 bg-gray-50/60 flex items-center justify-between shrink-0">
          <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
            <FolderTree class="w-3.5 h-3.5 text-[#E8772E]" />
            Danh mục
          </h3>
          <button
            @click="handleAddCategory"
            class="inline-flex items-center gap-1 px-2 py-1 text-[11px] font-bold text-[#E8772E] hover:bg-orange-50 rounded-lg transition-colors"
          >
            <FolderPlus class="w-3.5 h-3.5" />
            Thêm
          </button>
        </div>

        <!-- Tree body -->
        <div class="flex-1 overflow-y-auto p-2">
          <VueDraggable
            v-model="dragCategoryList"
            :animation="150"
            handle=".drag-handle"
            @end="onCategoryDragEnd"
          >
            <div
              v-for="cat in dragCategoryList"
              :key="cat.id"
              class="mb-0.5"
            >
              <!-- Category row -->
              <div
                :class="[
                  'group flex items-center gap-1.5 px-2 py-2 rounded-lg cursor-pointer transition-colors',
                  isSelectedCategory(cat.id)
                    ? 'bg-orange-50 text-[#E8772E]'
                    : 'hover:bg-gray-50 text-gray-700',
                  !cat.is_active && 'opacity-50',
                ]"
                @click="selectCategory(cat.id)"
              >
                <!-- Drag handle -->
                <GripVertical class="w-3.5 h-3.5 text-gray-300 drag-handle cursor-grab active:cursor-grabbing shrink-0 group-hover:text-gray-400" />

                <!-- Expand/collapse -->
                <button
                  v-if="store.subCategoriesByCategory(cat.id).length > 0"
                  @click.stop="toggleExpand(cat.id)"
                  class="shrink-0 p-0.5 hover:bg-gray-200 rounded"
                >
                  <ChevronDown v-if="isExpanded(cat.id)" class="w-3.5 h-3.5" />
                  <ChevronRight v-else class="w-3.5 h-3.5" />
                </button>
                <span v-else class="w-4 shrink-0"></span>

                <!-- Icon + name -->
                <span class="text-base shrink-0">{{ cat.icon }}</span>
                <span class="text-sm font-bold truncate flex-1">{{ cat.name }}</span>

                <!-- Item count -->
                <span class="text-[10px] font-bold text-gray-400 shrink-0">
                  {{ store.itemCountByCategory(cat.id) }}
                </span>

                <!-- POS visibility toggle -->
                <div @click.stop>
                  <ToggleSwitch
                    :model-value="cat.is_visible_on_pos"
                    @update:model-value="() => store.toggleCategoryPosVisibility(cat.id)"
                    size="sm"
                    aria-label="Hiển thị trên POS"
                  />
                </div>
              </div>

              <!-- SubCategory rows (expanded) -->
              <div v-if="isExpanded(cat.id)" class="ml-6 mt-0.5 space-y-0.5">
                <div
                  v-for="sub in store.subCategoriesByCategory(cat.id)"
                  :key="sub.id"
                  :class="[
                    'group flex items-center gap-1.5 px-2 py-1.5 rounded-lg cursor-pointer transition-colors text-sm',
                    isSelectedSubCategory(cat.id, sub.id)
                      ? 'bg-orange-50 text-[#E8772E] font-bold'
                      : 'hover:bg-gray-50 text-gray-600 font-medium',
                    !sub.is_active && 'opacity-50',
                  ]"
                  @click="selectSubCategory(cat.id, sub.id)"
                >
                  <Folder class="w-3 h-3 text-gray-400 shrink-0" />
                  <span class="truncate flex-1">{{ sub.name }}</span>
                  <span class="text-[10px] font-bold text-gray-400 shrink-0">
                    {{ store.itemCountBySubCategory(sub.id) }}
                  </span>
                  <button
                    @click.stop="handleDeleteSubCategory(sub.id, sub.name)"
                    class="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-red-500 transition-all shrink-0"
                  >
                    <Trash2 class="w-3 h-3" />
                  </button>
                </div>

                <!-- "Trực thuộc Category" virtual node -->
                <div
                  :class="[
                    'group flex items-center gap-1.5 px-2 py-1.5 rounded-lg cursor-pointer transition-colors text-sm',
                    isSelectedDirect(cat.id)
                      ? 'bg-orange-50 text-[#E8772E] font-bold'
                      : 'hover:bg-gray-50 text-gray-500 font-medium',
                  ]"
                  @click="selectDirect(cat.id)"
                >
                  <FileText class="w-3 h-3 text-gray-400 shrink-0" />
                  <span class="truncate flex-1 italic">Trực thuộc {{ cat.name }}</span>
                  <span class="text-[10px] font-bold text-gray-400 shrink-0">
                    {{ directItemCount(cat.id) }}
                  </span>
                </div>

                <!-- Add SubCategory button -->
                <button
                  @click="handleAddSubCategory(cat.id, cat.name)"
                  class="flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-xs font-medium text-gray-400 hover:text-[#E8772E] hover:bg-orange-50 transition-colors w-full"
                >
                  <Plus class="w-3 h-3" />
                  Thêm danh mục con
                </button>
              </div>
            </div>
          </VueDraggable>

          <!-- Empty state -->
          <div v-if="dragCategoryList.length === 0" class="py-10 text-center text-xs text-gray-400 font-medium">
            <FolderTree class="w-8 h-8 mx-auto mb-2 opacity-30" />
            Chưa có danh mục nào
          </div>
        </div>
      </aside>

      <!-- ─────────────────────────────────────────────────────────────── -->
      <!-- MIDDLE PANE (45%): Item Data Grid                              -->
      <!-- ─────────────────────────────────────────────────────────────── -->
      <section class="flex-1 bg-white border border-gray-200 rounded-2xl shadow-sm flex flex-col min-h-0 overflow-hidden">
        <!-- Grid header -->
        <div class="px-4 py-3 border-b border-gray-100 bg-gray-50/60 shrink-0 space-y-2">
          <div class="flex items-center justify-between gap-2">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              <Package class="w-3.5 h-3.5 text-[#E8772E]" />
              {{ currentSelectionLabel }}
              <span class="text-[10px] text-gray-400 font-bold normal-case tracking-normal">
                ({{ filteredItems.length }} món)
              </span>
            </h3>
            <button
              @click="startCreate"
              :disabled="!showAllItems && !selectedCategoryId"
              :class="[
                'inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold rounded-lg transition-colors',
                showAllItems || selectedCategoryId
                  ? 'bg-[#E8772E] hover:bg-[#D4660B] text-white shadow-sm'
                  : 'bg-gray-100 text-gray-400 cursor-not-allowed',
              ]"
            >
              <Plus class="w-3.5 h-3.5" />
              Thêm món
            </button>
          </div>

          <!-- Search -->
          <div class="relative">
            <Search class="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Tìm theo tên, SKU, barcode..."
              class="w-full pl-8 pr-3 py-1.5 text-xs rounded-lg border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] placeholder:text-gray-400"
            />
          </div>
        </div>

        <!-- Items table -->
        <div class="flex-1 overflow-y-auto">
          <template v-if="filteredItems.length > 0">
            <table class="w-full text-left">
              <thead class="sticky top-0 bg-gray-50/95 backdrop-blur-sm z-10">
                <tr class="text-[10px] font-black text-gray-500 uppercase tracking-wider">
                  <th class="px-3 py-2 font-black">Món</th>
                  <th v-if="showAllItems" class="px-3 py-2 font-black">Danh mục</th>
                  <th v-if="showAllItems" class="px-3 py-2 font-black">Danh mục con</th>
                  <th class="px-3 py-2 font-black">SKU</th>
                  <th class="px-3 py-2 font-black text-right">Giá</th>
                  <th class="px-3 py-2 font-black text-center">Trạng thái</th>
                  <th class="px-3 py-2 font-black text-center">Hết hàng</th>
                  <th class="px-3 py-2 font-black text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="item in filteredItems"
                  :key="item.id"
                  :class="[
                    'transition-colors hover:bg-gray-50/60',
                    !item.is_active && 'bg-gray-50/40 opacity-60',
                    item.is_active && item.is_sold_out && 'bg-amber-50/30',
                  ]"
                >
                  <!-- Thumbnail + Name -->
                  <td class="px-3 py-2.5">
                    <div class="flex items-center gap-2.5">
                      <div
                        class="w-9 h-9 rounded-lg overflow-hidden shrink-0 flex items-center justify-center"
                        :style="{ backgroundColor: item.button_color + '15' }"
                      >
                        <img
                          v-if="item.image_url"
                          :src="item.image_url"
                          :alt="item.name"
                          class="w-full h-full object-cover"
                        />
                        <span
                          v-else
                          class="text-sm font-black"
                          :style="{ color: item.button_color }"
                        >{{ item.name.charAt(0) }}</span>
                      </div>
                      <div class="min-w-0">
                        <div class="text-sm font-bold text-gray-900 truncate">{{ item.name }}</div>
                        <div class="text-[10px] text-gray-400 font-medium truncate">
                          {{ item.name_en || '—' }}
                        </div>
                      </div>
                    </div>
                  </td>

                  <!-- Category (all-items view) -->
                  <td v-if="showAllItems" class="px-3 py-2.5">
                    <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-100 text-blue-700">
                      {{ store.getCategoryById(item.category_id)?.icon }}
                      {{ store.getCategoryById(item.category_id)?.name ?? '—' }}
                    </span>
                  </td>
                  <!-- SubCategory (all-items view) -->
                  <td v-if="showAllItems" class="px-3 py-2.5">
                    <span v-if="item.sub_category_id" class="inline-flex px-2 py-0.5 rounded-full text-[10px] font-bold bg-purple-100 text-purple-700">
                      {{ store.getSubCategoryById(item.sub_category_id)?.name ?? '—' }}
                    </span>
                    <span v-else class="text-[10px] text-gray-400 font-medium">—</span>
                  </td>

                  <!-- SKU -->
                  <td class="px-3 py-2.5">
                    <span class="text-xs font-mono font-medium text-gray-500">{{ item.sku || '—' }}</span>
                  </td>

                  <!-- Price -->
                  <td class="px-3 py-2.5 text-right">
                    <span class="text-sm font-bold text-gray-900">{{ formatPrice(item.base_price) }}</span>
                    <div class="text-[10px] text-gray-400 font-medium">VAT {{ item.tax_rate }}%</div>
                  </td>

                  <!-- Status badge -->
                  <td class="px-3 py-2.5 text-center">
                    <span
                      :class="[
                        'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold',
                        statusBadge(item).class,
                      ]"
                    >
                      <span :class="['w-1.5 h-1.5 rounded-full', statusBadge(item).dot]"></span>
                      {{ statusBadge(item).label }}
                    </span>
                  </td>

                  <!-- Sold out toggle -->
                  <td class="px-3 py-2.5 text-center" @click.stop>
                    <ToggleSwitch
                      :model-value="item.is_sold_out"
                      :disabled="!item.is_active"
                      @update:model-value="() => store.toggleSoldOut(item.id)"
                      size="sm"
                      aria-label="Tạm hết hàng"
                    />
                  </td>

                  <!-- Actions -->
                  <td class="px-3 py-2.5">
                    <div class="flex items-center justify-end gap-1">
                      <button
                        @click="startEdit(item)"
                        class="p-1.5 text-gray-400 hover:text-[#E8772E] hover:bg-orange-50 rounded-lg transition-colors"
                        title="Sửa"
                      >
                        <Pencil class="w-3.5 h-3.5" />
                      </button>
                      <button
                        @click="handleCopyItem(item.id)"
                        class="p-1.5 text-gray-400 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-colors"
                        title="Nhân bản"
                      >
                        <Copy class="w-3.5 h-3.5" />
                      </button>
                      <button
                        @click="handleDeleteItem(item.id, item.name)"
                        class="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                        title="Xóa (ẩn)"
                      >
                        <Trash2 class="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </template>

          <!-- Empty states -->
          <div v-else class="py-16 text-center text-xs text-gray-400 font-medium">
            <template v-if="showAllItems">
              <Package class="w-10 h-10 mx-auto mb-3 opacity-20" />
              Không tìm thấy món nào{{ searchQuery ? ' khớp với từ khóa' : '' }}
            </template>
            <template v-else-if="!selectedCategoryId">
              <FolderTree class="w-10 h-10 mx-auto mb-3 opacity-20" />
              Chọn một danh mục bên trái để xem danh sách món
            </template>
            <template v-else>
              <Package class="w-10 h-10 mx-auto mb-3 opacity-20" />
              Không tìm thấy món nào{{ searchQuery ? ' khớp với từ khóa' : '' }}
            </template>
          </div>
        </div>
      </section>

      <!-- ─────────────────────────────────────────────────────────────── -->
      <!-- RIGHT PANE (30%): Item Detail Form                              -->
      <!-- ─────────────────────────────────────────────────────────────── -->
      <aside class="w-[30%] shrink-0 bg-white border border-gray-200 rounded-2xl shadow-sm flex flex-col min-h-0 overflow-hidden">
        <!-- Form header with tabs -->
        <div class="px-4 py-3 border-b border-gray-100 bg-gray-50/60 shrink-0">
          <div class="flex items-center justify-between mb-2">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              <ClipboardList class="w-3.5 h-3.5 text-[#E8772E]" />
              {{ formMode === 'edit' ? 'Chỉnh sửa món' : formMode === 'create' ? 'Thêm món mới' : 'Chi tiết món' }}
            </h3>
          </div>

          <!-- Tab buttons -->
          <div class="flex gap-1 bg-gray-100 p-1 rounded-lg">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              @click="activeTab = tab.key"
              :class="[
                'flex-1 px-2 py-1.5 text-[11px] font-bold rounded-md transition-all',
                activeTab === tab.key
                  ? 'bg-white text-[#E8772E] shadow-sm'
                  : 'text-gray-500 hover:text-gray-700',
              ]"
            >
              {{ tab.label }}
            </button>
          </div>
        </div>

        <!-- Form body / empty state -->
        <div v-if="formMode" class="flex-1 overflow-y-auto p-4 space-y-4">
          <!-- ── Template: Copy from existing item (create mode only) ── -->
          <div v-if="formMode === 'create'" class="p-3 bg-blue-50 border border-blue-200 rounded-lg space-y-2">
            <label class="text-[11px] font-bold text-blue-900 uppercase tracking-wide flex items-center gap-1">
              <Lightbulb class="w-3 h-3" />
              Sao chép từ món có sẵn
            </label>
            <div class="flex gap-2">
              <select
                v-model="templateItemId"
                class="flex-1 px-3 py-2 text-sm border border-blue-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-400 bg-white"
              >
                <option value="">— Nhập thủ công —</option>
                <option v-for="item in store.items" :key="item.id" :value="item.id">
                  {{ item.name }} ({{ store.getCategoryById(item.category_id)?.name ?? '—' }})
                </option>
              </select>
              <button
                v-if="templateItemId"
                @click="clearTemplate"
                class="px-3 py-2 text-xs font-bold text-blue-700 hover:bg-blue-100 rounded-lg transition-colors whitespace-nowrap"
              >
                Xóa
              </button>
            </div>
          </div>
          <!-- ── Category & SubCategory (always visible) ── -->
          <div class="space-y-2 pb-3 border-b border-gray-100">
            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">
                Danh mục <span class="text-red-500">*</span>
              </label>
              <select
                v-model="formData.category_id"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] bg-white"
              >
                <option value="" disabled>— Chọn danh mục —</option>
                <option v-for="cat in store.activeCategories" :key="cat.id" :value="cat.id">
                  {{ cat.icon }} {{ cat.name }}
                </option>
                <option value="__temp__">📎 Danh mục chưa phân loại</option>
              </select>

              <!-- TEMP category suggestion -->
              <div v-if="formData.category_id === '__temp__'" class="mt-2 p-2.5 bg-amber-50 border border-amber-200 rounded-lg">
                <label class="text-[11px] font-bold text-amber-800 uppercase tracking-wide">
                  Đề xuất tên danh mục mới
                </label>
                <input
                  v-model="suggestedCategoryName"
                  type="text"
                  class="mt-1 w-full px-3 py-2 text-sm border border-amber-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-200 bg-white"
                  placeholder="VD: Đồ ăn nhanh, Món lẩu..."
                />
                <p class="mt-1 text-[10px] text-amber-600 font-medium">
                  Để trống nếu muốn dùng danh mục "Khác"
                </p>
              </div>
            </div>

            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">
                Danh mục con <span class="text-gray-400 font-normal">(tùy chọn)</span>
              </label>
              <select
                v-model="formData.sub_category_id"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] bg-white"
              >
                <option :value="null">— Trực thuộc danh mục chính —</option>
                <option v-for="sub in formSubCategories" :key="sub.id" :value="sub.id">
                  {{ sub.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- ── Tab: Cơ bản ── -->
          <div v-show="activeTab === 'basic'" class="space-y-3">
            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">
                Tên món (VN) <span class="text-red-500">*</span>
              </label>
              <input
                v-model="formData.name"
                type="text"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                placeholder="Nhập tên món..."
              />
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Tên (EN)</label>
                <input
                  v-model="formData.name_en"
                  type="text"
                  class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="English name"
                />
              </div>
              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Tên (JP)</label>
                <input
                  v-model="formData.name_jp"
                  type="text"
                  class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="日本語名"
                />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide flex items-center gap-1">
                  <Tag class="w-3 h-3" /> SKU
                </label>
                <input
                  v-model="formData.sku"
                  type="text"
                  class="mt-1 w-full px-3 py-2 text-sm font-mono border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="VD: WGY-SL-150"
                />
              </div>
              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide flex items-center gap-1">
                  <Barcode class="w-3 h-3" /> Barcode
                </label>
                <input
                  v-model="formData.barcode"
                  type="text"
                  class="mt-1 w-full px-3 py-2 text-sm font-mono border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="8935..."
                />
              </div>
            </div>

            <!-- Image upload (mock) -->
            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide flex items-center gap-1">
                <ImageIcon class="w-3 h-3" /> Ảnh món
              </label>
              <div class="mt-1 flex items-center gap-3">
                <div
                  class="w-14 h-14 rounded-xl border-2 border-dashed border-gray-200 flex items-center justify-center overflow-hidden shrink-0 bg-gray-50"
                >
                  <img v-if="formData.image_url" :src="formData.image_url" class="w-full h-full object-cover" />
                  <ImageIcon v-else class="w-5 h-5 text-gray-300" />
                </div>
                <input
                  v-model="formData.image_url"
                  type="text"
                  class="flex-1 px-3 py-2 text-xs border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="Dán URL ảnh..."
                />
              </div>
            </div>

            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Mô tả</label>
              <textarea
                v-model="formData.description"
                rows="3"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] resize-none"
                placeholder="Mô tả ngắn về món..."
              ></textarea>
            </div>
          </div>

          <!-- ── Tab: Giá & Thuế ── -->
          <div v-show="activeTab === 'price'" class="space-y-3">
            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">
                Giá gốc (VNĐ) <span class="text-red-500">*</span>
              </label>
              <div class="relative mt-1">
                <input
                  :value="formData.base_price"
                  @input="formData.base_price = parseInt(($event.target as HTMLInputElement).value) || 0"
                  type="number"
                  min="0"
                  step="1000"
                  class="w-full px-3 py-2 pr-10 text-sm font-bold text-right border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                  placeholder="0"
                />
                <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-gray-400 font-medium">đ</span>
              </div>
              <p class="mt-1 text-[10px] text-gray-400 font-medium">
                Hiển thị: <span class="font-bold text-gray-600">{{ formatPrice(formData.base_price) }}</span>
              </p>
            </div>

            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Mức thuế VAT</label>
              <select
                v-model="formData.tax_rate"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] bg-white"
              >
                <option v-for="opt in taxRateOptions" :key="opt.value" :value="opt.value">
                  {{ opt.label }}
                </option>
              </select>
            </div>

            <div class="pt-2 border-t border-gray-100 space-y-3">
              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Kích thước nút (POS)</label>
                <div class="mt-1 grid grid-cols-3 gap-2">
                  <button
                    v-for="opt in buttonSizeOptions"
                    :key="opt.value"
                    @click="formData.button_size = opt.value"
                    :class="[
                      'px-2 py-1.5 text-xs font-bold rounded-lg border transition-colors',
                      formData.button_size === opt.value
                        ? 'border-[#E8772E] bg-orange-50 text-[#E8772E]'
                        : 'border-gray-200 text-gray-500 hover:bg-gray-50',
                    ]"
                  >
                    {{ opt.label }}
                  </button>
                </div>
              </div>

              <div>
                <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Màu nút (POS)</label>
                <div class="mt-1 flex flex-wrap gap-2">
                  <button
                    v-for="opt in buttonColorOptions"
                    :key="opt.value"
                    @click="formData.button_color = opt.value"
                    :class="[
                      'w-7 h-7 rounded-lg border-2 transition-all',
                      formData.button_color === opt.value
                        ? 'border-gray-800 scale-110 ring-2 ring-gray-300'
                        : 'border-gray-200',
                    ]"
                    :style="{ backgroundColor: opt.value }"
                    :title="opt.label"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- ── Tab: Bếp ── -->
          <div v-show="activeTab === 'kitchen'" class="space-y-3">
            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide flex items-center gap-1">
                <Printer class="w-3 h-3" /> Máy in bếp
              </label>
              <select
                v-model="formData.kitchen_printer_id"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E] bg-white"
              >
                <option :value="null">— Không in bếp —</option>
                <option v-for="p in kitchenPrinters" :key="p.id" :value="p.id">
                  {{ p.name }} ({{ p.name_en }})
                </option>
              </select>
              <p class="mt-1 text-[10px] text-gray-400 font-medium">
                Đơn hàng sẽ được gửi đến máy in được chọn khi khách gọi món.
              </p>
            </div>

            <div>
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Thứ tự hiển thị</label>
              <input
                v-model.number="formData.sort_order"
                type="number"
                min="0"
                class="mt-1 w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200 focus:border-[#E8772E]"
                placeholder="1"
              />
              <p class="mt-1 text-[10px] text-gray-400 font-medium">
                Số nhỏ hơn hiển thị trước trên POS.
              </p>
            </div>

            <div class="pt-2 border-t border-gray-100">
              <label class="text-[11px] font-bold text-gray-600 uppercase tracking-wide">Trạng thái hiển thị</label>
              <div class="mt-2 space-y-2">
                <label class="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 cursor-pointer">
                  <span class="text-xs font-medium text-gray-700">Đang bán</span>
                  <div @click.stop>
                    <ToggleSwitch
                      :model-value="formData.is_active"
                      @update:model-value="(val: boolean) => formData.is_active = val"
                      size="sm"
                    />
                  </div>
                </label>
                <label class="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 cursor-pointer">
                  <span class="text-xs font-medium text-gray-700">Tạm hết hàng</span>
                  <div @click.stop>
                    <ToggleSwitch
                      :model-value="formData.is_sold_out"
                      @update:model-value="(val: boolean) => formData.is_sold_out = val"
                      size="sm"
                    />
                  </div>
                </label>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty state (no form active) -->
        <div v-else class="flex-1 flex flex-col items-center justify-center text-center px-6">
          <ClipboardList class="w-12 h-12 text-gray-200 mb-3" />
          <p class="text-sm font-bold text-gray-400">Chưa chọn món</p>
          <p class="text-xs text-gray-400 mt-1 max-w-[200px]">
            Chọn một món để chỉnh sửa hoặc nhấn "Thêm món" để tạo mới
          </p>
        </div>

        <!-- Form footer -->
        <div v-if="formMode" class="px-4 py-3 border-t border-gray-100 bg-gray-50/60 shrink-0 flex gap-2">
          <button
            @click="saveForm"
            class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-[#E8772E] hover:bg-[#D4660B] text-white text-sm font-bold rounded-lg shadow-sm transition-colors"
          >
            <Save class="w-4 h-4" />
            Lưu
          </button>
          <button
            @click="cancelForm"
            class="px-4 py-2 bg-white border border-gray-200 hover:bg-gray-50 text-gray-700 text-sm font-bold rounded-lg transition-colors"
          >
            Hủy
          </button>
        </div>
      </aside>

    </div>

    <!-- Manager PIN Modal -->
    <ManagerAuthModal
      v-if="showPinModal"
      :action-type="pinAction === 'delete' ? 'VOID_ITEM' : 'EDIT_PRICE'"
      :target-name="formData.name || 'Món mới'"
      @confirm="handlePinConfirm"
      @close="showPinModal = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { VueDraggable } from 'vue-draggable-plus'
import Swal from 'sweetalert2'
import ToggleSwitch from '@/components/ToggleSwitch.vue'
import ManagerAuthModal from '@/components/reception/ManagerAuthModal.vue'
import { useMenuManagementStore } from '@/stores/menuManagementStore'
import {
  kitchenPrinters,
  taxRateOptions,
  buttonSizeOptions,
  buttonColorOptions,
  type MenuCategory,
  type MenuItem,
} from '@/data/mockMenuData'
import {
  Utensils,
  FolderTree,
  FolderPlus,
  Folder,
  FileText,
  GripVertical,
  ChevronRight,
  ChevronDown,
  Plus,
  Pencil,
  Trash2,
  Copy,
  Search,
  Package,
  ClipboardList,
  Tag,
  Barcode,
  Printer,
  Save,
  Image as ImageIcon,
  Lightbulb,
  ArrowLeft,
  LayoutGrid,
} from 'lucide-vue-next'

const store = useMenuManagementStore()
const router = useRouter()

// ── View mode ────────────────────────────────────────────────────────────────
const showAllItems = ref(false)

function goBack(): void {
  router.push('/reception/dashboard')
}

function toggleAllItemsView(): void {
  showAllItems.value = !showAllItems.value
}

// ── Tabs ────────────────────────────────────────────────────────────────────
const tabs = [
  { key: 'basic' as const, label: 'Cơ bản' },
  { key: 'price' as const, label: 'Giá & Thuế' },
  { key: 'kitchen' as const, label: 'Bếp' },
]
const activeTab = ref<'basic' | 'price' | 'kitchen'>('basic')

// ── Selection state ──────────────────────────────────────────────────────────
const selectedCategoryId = ref<string | null>(null)
/** undefined = all items in category · null = direct items · string = subcategory */
const selectedSubCategoryId = ref<string | null | undefined>(undefined)

// ── Tree expand/collapse ─────────────────────────────────────────────────────
const expandedCategoryIds = ref<Set<string>>(new Set())

function isExpanded(id: string): boolean {
  return expandedCategoryIds.value.has(id)
}

function toggleExpand(id: string): void {
  const set = new Set(expandedCategoryIds.value)
  if (set.has(id)) set.delete(id)
  else set.add(id)
  expandedCategoryIds.value = set
}

// ── Search ───────────────────────────────────────────────────────────────────
const searchQuery = ref('')

// ── Template copy (pre-fill form from existing item) ──────────────────────────
const templateItemId = ref<string>('')

// ── PIN protection ───────────────────────────────────────────────────────────
const showPinModal = ref(false)
const pinAction = ref<'save' | 'delete' | null>(null)
const pendingDeleteId = ref<string>('')

// ── TEMP unclassified category ────────────────────────────────────────────────
const suggestedCategoryName = ref('')

// ── Drag & Drop (local list synced with store) ───────────────────────────────
const dragCategoryList = ref<MenuCategory[]>([])

function syncCategoryList(): void {
  dragCategoryList.value = [...store.categories].sort((a, b) => a.sort_order - b.sort_order)
}

syncCategoryList()
watch(() => store.categories.length, syncCategoryList)

function onCategoryDragEnd(): void {
  store.reorderCategories(dragCategoryList.value.map((c) => c.id))
}

// ── Form state ────────────────────────────────────────────────────────────────
const formMode = ref<'create' | 'edit' | null>(null)

function createEmptyForm(): MenuItem {
  return {
    id: '',
    name: '',
    name_en: '',
    name_jp: '',
    sku: '',
    barcode: '',
    image_url: '',
    description: '',
    category_id: '',
    sub_category_id: null,
    base_price: 0,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 0,
    button_size: 'md',
    button_color: '#F54C0D',
  }
}

const formData = reactive<MenuItem>(createEmptyForm())

const formSubCategories = computed(() => {
  if (!formData.category_id) return []
  return store.subCategoriesByCategory(formData.category_id)
})

// Reset sub_category_id when category changes
watch(
  () => formData.category_id,
  () => {
    formData.sub_category_id = null
  },
)

// Pre-fill form from selected template item (create mode only)
watch(templateItemId, (newId) => {
  if (newId && formMode.value === 'create') {
    const source = store.getItemById(newId)
    if (source) {
      const sourceSubCatId = source.sub_category_id
      Object.assign(formData, JSON.parse(JSON.stringify(source)))
      formData.id = ''
      formData.name = `${source.name} (Bản sao)`
      formData.sku = source.sku ? `${source.sku}-COPY` : ''
      formData.barcode = ''
      formData.is_active = true
      formData.is_sold_out = false
      // Restore sub_category_id after the category watcher resets it
      if (sourceSubCatId !== null) {
        nextTick(() => {
          formData.sub_category_id = sourceSubCatId
        })
      }
    }
  }
})

// ── Computed: stats ──────────────────────────────────────────────────────────
const totalItems = computed(() => store.items.length)
const activeItemCount = computed(() => store.items.filter((i) => i.is_active && !i.is_sold_out).length)
const soldOutCount = computed(() => store.items.filter((i) => i.is_active && i.is_sold_out).length)
const inactiveCount = computed(() => store.items.filter((i) => !i.is_active).length)

// ── Computed: filtered items ─────────────────────────────────────────────────
const filteredItems = computed(() => {
  let result: MenuItem[]

  if (showAllItems.value) {
    result = [...store.items]
  } else {
    if (!selectedCategoryId.value) return []
    const catId = selectedCategoryId.value
    const subCatId = selectedSubCategoryId.value
    result = store.itemsByCategory(catId, subCatId === undefined ? undefined : subCatId)
  }

  const q = searchQuery.value.trim().toLowerCase()
  if (q) {
    result = result.filter(
      (item) =>
        item.name.toLowerCase().includes(q) ||
        item.name_en.toLowerCase().includes(q) ||
        item.name_jp.toLowerCase().includes(q) ||
        item.sku.toLowerCase().includes(q) ||
        item.barcode.includes(q),
    )
  }

  return result.sort((a, b) => a.sort_order - b.sort_order)
})

// ── Computed: current selection label ────────────────────────────────────────
const currentSelectionLabel = computed(() => {
  if (showAllItems.value) return 'Tất cả món'
  if (!selectedCategoryId.value) return 'Tất cả món'
  const cat = store.getCategoryById(selectedCategoryId.value)
  if (!cat) return 'Tất cả món'

  if (selectedSubCategoryId.value === undefined) {
    return `${cat.icon} ${cat.name}`
  }
  if (selectedSubCategoryId.value === null) {
    return `Trực thuộc ${cat.name}`
  }
  const sub = store.getSubCategoryById(selectedSubCategoryId.value)
  return sub ? `${cat.icon} ${cat.name} / ${sub.name}` : `${cat.icon} ${cat.name}`
})

// ── Selection helpers ────────────────────────────────────────────────────────
function isSelectedCategory(catId: string): boolean {
  return selectedCategoryId.value === catId && selectedSubCategoryId.value === undefined
}

function isSelectedSubCategory(catId: string, subId: string): boolean {
  return selectedCategoryId.value === catId && selectedSubCategoryId.value === subId
}

function isSelectedDirect(catId: string): boolean {
  return selectedCategoryId.value === catId && selectedSubCategoryId.value === null
}

function directItemCount(catId: string): number {
  return store.items.filter((i) => i.category_id === catId && i.sub_category_id === null).length
}

// ── Selection actions ────────────────────────────────────────────────────────
function selectCategory(catId: string): void {
  selectedCategoryId.value = catId
  selectedSubCategoryId.value = undefined
  // Auto-expand
  if (!isExpanded(catId)) toggleExpand(catId)
}

function selectSubCategory(catId: string, subId: string): void {
  selectedCategoryId.value = catId
  selectedSubCategoryId.value = subId
}

function selectDirect(catId: string): void {
  selectedCategoryId.value = catId
  selectedSubCategoryId.value = null
}

// ── Form actions ─────────────────────────────────────────────────────────────
function startCreate(): void {
  formMode.value = 'create'
  activeTab.value = 'basic'
  templateItemId.value = ''
  suggestedCategoryName.value = ''
  Object.assign(formData, createEmptyForm())
  // Pre-fill with current selection
  if (selectedCategoryId.value) {
    formData.category_id = selectedCategoryId.value
    if (selectedSubCategoryId.value !== undefined) {
      formData.sub_category_id = selectedSubCategoryId.value
    }
  }
}

function startEdit(item: MenuItem): void {
  formMode.value = 'edit'
  activeTab.value = 'basic'
  templateItemId.value = ''
  Object.assign(formData, JSON.parse(JSON.stringify(item)))
}

function cancelForm(): void {
  formMode.value = null
  templateItemId.value = ''
  suggestedCategoryName.value = ''
  Object.assign(formData, createEmptyForm())
}

function clearTemplate(): void {
  templateItemId.value = ''
  suggestedCategoryName.value = ''
  Object.assign(formData, createEmptyForm())
  if (selectedCategoryId.value) {
    formData.category_id = selectedCategoryId.value
    if (selectedSubCategoryId.value !== undefined) {
      formData.sub_category_id = selectedSubCategoryId.value
    }
  }
}

function saveForm(): void {
  // Validation
  if (!formData.name.trim()) {
    toast('error', 'Vui lòng nhập tên món')
    return
  }
  if (!formData.category_id) {
    toast('error', 'Vui lòng chọn danh mục')
    return
  }

  // Require PIN for save
  pinAction.value = 'save'
  showPinModal.value = true
}

function resolveTempCategory(): string {
  const suggested = suggestedCategoryName.value.trim()
  if (suggested) {
    const existing = store.categories.find(
      (c) => c.name.toLowerCase() === suggested.toLowerCase(),
    )
    if (existing) return existing.id
    const newCat = store.addCategory({
      name: suggested,
      name_en: '',
      name_jp: '',
      icon: '📎',
      color: '#6B7280',
      is_active: true,
      is_visible_on_pos: true,
    })
    return newCat.id
  }
  return store.categories.find((c) => c.id === 'cat-other')?.id ?? ''
}

function doSave(): void {
  const payload = { ...formData }

  // Resolve TEMP category
  if (payload.category_id === '__temp__') {
    payload.category_id = resolveTempCategory()
    if (!payload.category_id) {
      toast('error', 'Không thể tạo danh mục')
      return
    }
  }

  if (formMode.value === 'create') {
    const { id: _omit, ...createData } = payload
    void _omit
    store.addItem(createData as Omit<MenuItem, 'id'>)
    toast('success', 'Đã thêm món mới')
  } else if (formMode.value === 'edit') {
    store.updateItem(formData.id, payload)
    toast('success', 'Đã cập nhật món')
  }

  cancelForm()
}

// ── Item actions ─────────────────────────────────────────────────────────────
async function handleDeleteItem(id: string, name: string): Promise<void> {
  const result = await Swal.fire({
    title: 'Xóa món?',
    html: `<span class="font-bold">"${name}"</span> sẽ bị ẩn khỏi POS (soft delete).<br>Bạn có thể kích hoạt lại bất cứ lúc nào.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
    confirmButtonColor: '#EF4444',
    cancelButtonColor: '#aaa',
  })
  if (result.isConfirmed) {
    pendingDeleteId.value = id
    pinAction.value = 'delete'
    showPinModal.value = true
  }
}

function doDelete(): void {
  const id = pendingDeleteId.value
  if (!id) return
  store.softDeleteItem(id)
  toast('success', 'Đã ẩn món')
  if (formData.id === id) cancelForm()
  pendingDeleteId.value = ''
}

function handlePinConfirm(): void {
  showPinModal.value = false
  if (pinAction.value === 'save') {
    doSave()
  } else if (pinAction.value === 'delete') {
    doDelete()
  }
  pinAction.value = null
}

function handleCopyItem(id: string): void {
  const copy = store.copyItem(id)
  if (copy) {
    toast('success', `Đã nhân bản: ${copy.name}`)
    startEdit(copy)
  }
}

// ── Category actions ─────────────────────────────────────────────────────────
async function handleAddCategory(): Promise<void> {
  const { value: name } = await Swal.fire({
    title: 'Thêm danh mục mới',
    input: 'text',
    inputPlaceholder: 'Nhập tên danh mục...',
    showCancelButton: true,
    confirmButtonText: 'Thêm',
    cancelButtonText: 'Hủy',
    confirmButtonColor: '#E8772E',
    cancelButtonColor: '#aaa',
    inputValidator: (val) => (!val?.trim() ? 'Vui lòng nhập tên danh mục' : undefined),
  })
  if (name?.trim()) {
    store.addCategory({
      name: name.trim(),
      name_en: '',
      name_jp: '',
      icon: '📁',
      color: '#6B7280',
      is_active: true,
      is_visible_on_pos: true,
    })
    toast('success', 'Đã thêm danh mục')
  }
}

async function handleAddSubCategory(categoryId: string, categoryName: string): Promise<void> {
  const { value: name } = await Swal.fire({
    title: `Thêm danh mục con vào "${categoryName}"`,
    input: 'text',
    inputPlaceholder: 'Nhập tên danh mục con...',
    showCancelButton: true,
    confirmButtonText: 'Thêm',
    cancelButtonText: 'Hủy',
    confirmButtonColor: '#E8772E',
    cancelButtonColor: '#aaa',
    inputValidator: (val) => (!val?.trim() ? 'Vui lòng nhập tên' : undefined),
  })
  if (name?.trim()) {
    store.addSubCategory({
      category_id: categoryId,
      name: name.trim(),
      is_active: true,
    })
    if (!isExpanded(categoryId)) toggleExpand(categoryId)
    toast('success', 'Đã thêm danh mục con')
  }
}

async function handleDeleteSubCategory(id: string, name: string): Promise<void> {
  const result = await Swal.fire({
    title: 'Xóa danh mục con?',
    text: `"${name}" sẽ bị ẩn.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
    confirmButtonColor: '#EF4444',
    cancelButtonColor: '#aaa',
  })
  if (result.isConfirmed) {
    const res = store.deleteSubCategory(id)
    if (res.success) {
      toast('success', res.message)
    } else {
      Swal.fire({
        icon: 'error',
        title: 'Không thể xóa',
        text: res.message,
        confirmButtonColor: '#E8772E',
      })
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
function formatPrice(price: number): string {
  return new Intl.NumberFormat('vi-VN').format(price) + 'đ'
}

function statusBadge(item: MenuItem): { label: string; class: string; dot: string } {
  if (!item.is_active) {
    return { label: 'Đã khóa', class: 'bg-red-100 text-red-700', dot: 'bg-red-500' }
  }
  if (item.is_sold_out) {
    return { label: 'Hết hàng', class: 'bg-amber-100 text-amber-700', dot: 'bg-amber-500' }
  }
  return { label: 'Đang bán', class: 'bg-green-100 text-green-700', dot: 'bg-green-500' }
}

function toast(type: 'success' | 'error' | 'info' | 'warning', text: string): void {
  Swal.fire({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 2500,
    timerProgressBar: true,
    icon: type,
    title: text,
  })
}
</script>
