<!-- File: src/views/customer/CustomerMenu.vue -->
<template>
  <div class="menu-layout">
    <!-- 1. SIDEBAR: Cấp 1 & Cấp 2 danh mục chính -->
    <aside class="sidebar scrollbar-hide">
      <!-- Section: Danh Mục Món -->
      <div class="sidebar-section full-height">
        <h3 class="section-title pink-text">DANH MỤC MÓN</h3>
        
        <button
          v-for="cat in menuCategories"
          :key="cat.id"
          :class="['category-btn', 'pink', { active: selectedCategory?.id === cat.id }]"
          @click="selectCategory(cat)"
        >
          {{ cat.name }}
        </button>
      </div>
    </aside>

    <!-- 2. MAIN AREA -->
    <div class="main-area">
      <!-- Scrollable Content -->
      <main :class="['main-content', 'scrollbar-hide', { 'has-tabs': hasSubcategories, 'has-cart': cartItemCount > 0 }]">
        
        <!-- Package Purchase Banner (Only for set packages) -->
        <div v-if="selectedCategory && selectedCategory.id.startsWith('buffet-') && !selectedCategory.id.includes('drink') && !selectedCategory.id.includes('alacarte')"
             class="bg-gradient-to-r from-amber-950/40 to-amber-900/20 border border-amber-500/20 rounded-2xl p-5 mb-6 flex flex-col sm:flex-row items-center justify-between gap-4 shrink-0">
          <div class="flex items-center gap-4">
            <div class="text-4xl">👑</div>
            <div>
              <h3 class="text-base font-bold text-white">Bạn đang xem thực đơn của gói: {{ selectedCategory.name }}</h3>
              <p class="text-xs text-amber-200/70 mt-1">Hãy thêm vé buffet này vào giỏ hàng để chọn các món ăn kèm giá 0đ nhé!</p>
            </div>
          </div>
          <div class="flex items-center gap-3 shrink-0">
            <span class="text-lg font-black text-amber-400">{{ getSetPriceDisplay(selectedCategory) }}</span>
            <button @click="addSetToCart(selectedCategory)"
                    :class="[
                      'px-5 py-2.5 rounded-xl font-bold text-xs transition-all duration-200 active:scale-95 flex items-center gap-1.5 shadow-md shadow-amber-500/10',
                      isSetInCart(selectedCategory.id)
                        ? 'bg-amber-600/20 text-amber-300 border border-amber-500/30 cursor-default pointer-events-none'
                        : 'bg-[#ff9800] hover:bg-amber-600 text-white border-none'
                    ]">
              {{ isSetInCart(selectedCategory.id) ? '✓ Đã chọn gói' : '+ Chọn gói này' }}
            </button>
          </div>
        </div>

        <div v-if="selectedCategory" class="category-content">
          <!-- Header -->
          <div class="category-header">
            <h1>{{ selectedCategory.name }}</h1>
            <span class="item-count">{{ displayedItems.length }} món</span>
          </div>

          <!-- Loading State -->
          <div v-if="false /* store.loading */" class="flex flex-col gap-4 py-8">
            <div v-for="i in 3" :key="i" class="h-24 bg-gray-800/40 animate-pulse rounded-xl"></div>
          </div>

          <!-- Empty State -->
          <div v-else-if="displayedItems.length === 0" class="empty-state">
            <div class="empty-icon">🍽️</div>
            <h2>Không có món nào</h2>
            <p>Danh mục này hiện chưa có món</p>
          </div>

          <!-- Items Grid -->
          <div v-else class="items-grid">
            <MenuItemCard
              v-for="item in displayedItems"
              :key="item.id"
              :item="item"
              :quantity-in-cart="getQuantity(item.id)"
              @add="handleAddToCart"
              @click-detail="openDetail"
            />
          </div>
        </div>

        <!-- Empty State (No Category selected) -->
        <div v-else class="empty-state">
          <div class="empty-icon">🍽️</div>
          <h2>Chọn danh mục để xem món</h2>
          <p>Vui lòng chọn một danh mục từ menu bên trái</p>
        </div>
      </main>

      <!-- Fixed bottom layout container -->
      <div v-if="!isModalOpen" class="fixed-bottom-container">
        <!-- CartBar (above Tabs or at the bottom if no tabs) -->
        <CartBar
          v-if="cartItemCount > 0"
          :cart-count="cartItemCount"
          :cart-total="store.cartTotal"
          :style="{ bottom: hasSubcategories ? '' : '0px' }"
          @view-cart="goToCart"
        />

        <!-- CategoryTabs (always at bottom if available) -->
        <CategoryTabs
          v-if="hasSubcategories && selectedCategory"
          :subcategories="selectedCategory.subcategories || []"
          :selected-tab="selectedSubId"
          :total-items="totalItems"
          @update:selected-tab="selectedSubId = $event"
        />
      </div>
    </div>

    <!-- Floating "Gọi Phục Vụ" Action Button (bottom right corner) -->
    <div class="fixed bottom-24 right-6 z-30">
      <button
        @click="goToServiceRequest"
        class="w-14 h-14 bg-[#E8772E] hover:bg-amber-600 active:scale-95 text-white rounded-full flex items-center justify-center shadow-2xl shadow-[#E8772E]/20 border-2 border-white/10 transition-all hover:rotate-12 select-none animate-bounce"
        title="Gọi phục vụ"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
      </button>
    </div>

    <!-- Modal Detail - Teleport to body -->
    <MenuItemDetailModal
      :item="focusedItem"
      :is-open="isModalOpen"
      :cart-count="store.cartItemCount"
      @close="closeDetail"
      @add="confirmDetailAdd"
      @go-to-cart="goToCart"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';
import MenuItemDetailModal from '@/components/customer/MenuItemDetailModal.vue';
import MenuItemCard from '@/components/customer/MenuItemCard.vue';
import CategoryTabs from '@/components/customer/CategoryTabs.vue';
import CartBar from '@/components/customer/CartBar.vue';
import type { MenuCategory, MenuItem } from '@/types/customer';
import { applyPackage, calculateItemUnitPrice } from '@/utils/packageRules';

const store = useCustomerStore();
const router = useRouter();
const { syncCart } = useCustomerSession();

const focusedItem = ref<MenuItem | null>(null);
const isModalOpen = computed(() => focusedItem.value !== null);

// State
const selectedCategory = ref<MenuCategory | null>(null);
const selectedYellowCategoryId = ref<string | null>(null);
const selectedSubId = ref<string>('all');

const cart = computed(() => store.cart);
const cartItemCount = computed(() => store.cartItemCount);
const cartTotalDisplay = computed(() => store.cartTotal.toLocaleString('vi-VN') + 'đ');

// Computed: Categories of Gói dịch vụ (Used for price calculation mapping)
const yellowCategories = computed(() => {
  const buffetCat = store.menuData.find(c => c.id === 'buffet');
  return buffetCat?.subcategories || [];
});

// Computed: Menu Categories in Sidebar (Only 9 items)
const menuCategories = computed(() => {
  const list: any[] = [];
  const buffetCat = store.menuData.find(c => c.id === 'buffet');
  if (buffetCat) {
    list.push(buffetCat);
  }
  const others = store.menuData.filter(c => c.color === 'pink');
  list.push(...others);
  return list;
});

// Computed: Check if has subcategories
const hasSubcategories = computed(() => 
  selectedCategory.value?.subcategories && 
  selectedCategory.value.subcategories.length > 0
);

const subcategories = computed(() => {
  return selectedCategory.value?.subcategories || [];
});

// Computed: Total items in category
const totalItems = computed(() => {
  if (!selectedCategory.value) return 0;
  if (selectedCategory.value.items) return selectedCategory.value.items.length;
  return selectedCategory.value.subcategories?.reduce(
    (sum, sub) => sum + sub.items.length, 0
  ) || 0;
});

// Computed: Displayed items
const displayedItems = computed(() => {
  if (!selectedCategory.value) return [];
  
  let rawItems: MenuItem[] = [];
  
  if (selectedCategory.value.items) {
    rawItems = selectedCategory.value.items;
  }
  else if (selectedCategory.value.subcategories) {
    if (selectedSubId.value === 'all') {
      rawItems = selectedCategory.value.subcategories.flatMap(sub => sub.items);
    } else {
      const sub = selectedCategory.value.subcategories.find(s => s.id === selectedSubId.value);
      rawItems = sub ? sub.items : [];
    }
  }
  
  const uniqueItems = Array.from(new Map(rawItems.map(item => [item.id, item])).values());
  
  const activePackage = yellowCategories.value.find(c => c.id === selectedYellowCategoryId.value);
  const packageName = activePackage?.name || '';
  
  if (store.searchQuery.trim()) {
    const q = store.searchQuery.toLowerCase().trim();
    return uniqueItems
      .filter(item => 
        item.name.toLowerCase().includes(q) || 
        (item.description && item.description.toLowerCase().includes(q))
      )
      .map(item => getModifiedItem(item, packageName));
  }
  
  return uniqueItems.map(item => getModifiedItem(item, packageName));
});

// Watch subcategory selection to sync active yellow package when browsing BUFFET
watch(() => selectedSubId.value, (newSubId) => {
  const cat = selectedCategory.value
  if (!cat || !newSubId || newSubId === 'all') return
  // BUFFET-shaped categories are surfaced by the banner; their ids
  // start with `buffet-` (e.g. `buffet-1390`, `buffet-1150`,
  // `buffet-kids`, `buffet-lau`). When the customer enters one, the
  // SET ticket must be in the cart — otherwise `tạm tính` collapses
  // to 0đ (only in-pkg items carry price=0).
  const isBuffetLike =
    cat.id === 'buffet' ||
    cat.id.startsWith('buffet-') ||
    !!cat.subcategories?.some((s) => s.id === 'set-' + cat.id || s.id.startsWith('set-'))
  if (!isBuffetLike) return
  selectedYellowCategoryId.value = newSubId
  if (!isSetInCart(cat.id)) {
    addSetToCart(cat)
  }
});

// Initialize defaults
const initDefaults = () => {
  const buffet = store.menuData.find(c => c.id === 'buffet');
  if (buffet && !selectedCategory.value) {
    selectedCategory.value = buffet;
    if (buffet.subcategories && buffet.subcategories.length > 0) {
      selectedSubId.value = buffet.subcategories[0].id;
      selectedYellowCategoryId.value = buffet.subcategories[0].id;
    }
  }
};

// Load menu on mount
onMounted(async () => {
  if (!store.session) {
    router.push({ name: 'CustomerHome' });
    return;
  }
  await store.loadMenu();
  initDefaults();
});

// ---- Package pricing rules ----
// The shared engine lives in `@/utils/packageRules`. We just build a
// one-shot subcategory lookup here so the rule can resolve tier
// membership without us walking the menu tree for every item on every
// render.  Performance: O(items) build once, O(1) per call.
const subCatIdByItemId = computed(() => {
  const out = new Map<string, string>()
  for (const cat of store.menuData) {
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        for (const item of sub.items) {
          if (!out.has(item.id)) out.set(item.id, sub.id)
        }
      }
    }
  }
  return out
})

function isItemInPackage(item: MenuItem, mainCategoryName: string): boolean {
  // Delegates to the shared package-rule engine so customer and cashier
  // never disagree on which item is free inside a buffet.
  return applyPackage(item, mainCategoryName).price === 0
}

function getModifiedItem(item: MenuItem, packageName: string): MenuItem {
  // Apply package rule (free inside buffet), then re-apply lunch 50%
  // via the shared rule engine — same math as the cashier preview.
  const inPkg = applyPackage(
    { ...item, subCatId: subCatIdByItemId.value.get(item.id) },
    packageName,
  )
  if (inPkg.price === 0) return inPkg
  // Preserve `price` and `price_display` semantics:
  // - in-pkg → 0 / "0K (Trong gói)"  (returned by applyPackage)
  // - lunch  → half price / updated display
  const unit = calculateItemUnitPrice(item, packageName)
  if (unit === Number(item.price ?? 0)) return item
  const half = Math.round(Number(item.price ?? 0) * 0.5)
  return {
    ...item,
    price: unit,
    price_display: `${half.toLocaleString('vi-VN')}đ (Lunch 50%)`,
  }
}

// Focus item details states
const focusedItemQty = computed(() => {
  if (!focusedItem.value) return 1;
  const inCart = cart.value.find(c => c.menuItemId === focusedItem.value?.id);
  return inCart ? inCart.quantity : 1;
});

const focusedItemNote = computed(() => {
  if (!focusedItem.value) return '';
  const inCart = cart.value.find(c => c.menuItemId === focusedItem.value?.id);
  return inCart ? inCart.note || '' : '';
});

function getQuantity(itemId: string): number {
  const inCart = cart.value.find(c => c.menuItemId === itemId);
  return inCart ? inCart.quantity : 0;
}

// Actions
const selectCategory = (cat: MenuCategory) => {
  selectedCategory.value = cat;
  selectedSubId.value = 'all'; // Reset to "Tất cả"
};

const handleAddToCart = (item: MenuItem) => {
  const activePackage = yellowCategories.value.find(c => c.id === selectedYellowCategoryId.value);
  const modifiedItem = getModifiedItem(item, activePackage?.name || '');
  const existing = cart.value.find(c => c.menuItemId === modifiedItem.id);
  if (existing) {
    store.updateCartItem(modifiedItem.id, existing.quantity + 1);
  } else {
    store.addToCart(modifiedItem, 1);
  }
  syncCart();
  store.addNotification(`Đã thêm 1 x ${modifiedItem.name} vào giỏ hàng`, 'success');
};

// Update cart quantity from modal
function onUpdateQuantity(item: MenuItem, qty: number) {
  const activePackage = yellowCategories.value.find(c => c.id === selectedYellowCategoryId.value);
  const modifiedItem = getModifiedItem(item, activePackage?.name || '');
  store.updateCartItem(modifiedItem.id, qty);
  if (qty > getQuantity(modifiedItem.id)) {
    const existing = cart.value.find(c => c.menuItemId === modifiedItem.id);
    if (!existing) {
      store.addToCart(modifiedItem, qty);
    }
  }
  syncCart();
}

function openDetail(item: MenuItem) {
  const activePackage = yellowCategories.value.find(c => c.id === selectedYellowCategoryId.value);
  focusedItem.value = getModifiedItem(item, activePackage?.name || '');
}

function closeDetail() {
  focusedItem.value = null;
}

function confirmDetailAdd(item: MenuItem, quantity: number, note: string) {
  if (item) {
    const existing = cart.value.find(c => c.menuItemId === item.id);
    if (existing) {
      store.updateCartItem(item.id, quantity);
      existing.note = note;
    } else {
      store.addToCart(item, quantity);
      const added = cart.value.find(c => c.menuItemId === item.id);
      if (added) added.note = note;
    }
    syncCart();
    store.addNotification(`Đã thêm ${quantity} x ${item.name} vào giỏ hàng`, 'success');
  }
  closeDetail();
}

function goToCart() {
  router.push({ name: 'CustomerCart' });
}

function goToServiceRequest() {
  router.push({ name: 'ServiceRequest' });
}

// Set/Package helper functions
function getSetPriceDisplay(cat: MenuCategory): string {
  if (cat.id.includes('1390')) return '1.390.000đ';
  if (cat.id.includes('1150')) return '1.150.000đ';
  if (cat.id.includes('680')) return '680.000đ';
  if (cat.id.includes('490')) return '490.000đ';
  if (cat.id.includes('380')) return '380.000đ';
  if (cat.id.includes('550jp')) return '550.000đ';
  return '';
}

const isSetInCart = (catId: string): boolean => {
  // `catId` is the buffet subcategory id (e.g. `buffet-1390`). The
  // SET ticket is whichever first item belongs to that subcategory in
  // the live menu (matched via `subCatIdByItemId`). After the
  // loadMenu() id remap, item ids are real UUIDs so a substring
  // check on the menuItemId would fail — we use the resolved map.
  const ticket = store.menuData
    .flatMap((c) => c.subcategories ?? [])
    .find((s) => s.id === catId)
    ?.items?.[0]
  if (!ticket) return false
  return cart.value.some((c) => c.menuItemId === ticket.id)
};

function addSetToCart(cat: MenuCategory) {
  // The SET ticket is always the first item in the first subcategory
  // (per Ishii 02/07_2026 spec: each buffet tier has one `Vé` ticket
  //  listed first, then the eligible items). Take that one.
  const subs = cat.subcategories || []
  const setItem = subs[0]?.items?.[0] ?? null

  if (setItem) {
    store.addToCart(setItem, 1)
    syncCart()
    store.addNotification(`Đã chọn gói ${cat.name}`, 'success')
  }
}
</script>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.slide-up-enter-active, .slide-up-leave-active {
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from, .slide-up-leave-to {
  transform: translateY(100%);
}

/* ===== LAYOUT CHÍNH ===== */
.menu-layout {
  display: flex;
  height: calc(100vh - 60px);
  background-color: #121212;
  color: white;
  overflow: hidden;
}

/* ===== SIDEBAR ===== */
.sidebar {
  width: 260px;
  background: #1a1a1a;
  border-right: 1px solid #333;
  overflow-y: auto;
  padding: 20px 15px;
  height: calc(100vh - 60px);
  flex-shrink: 0;
}

.sidebar-section.full-height {
  display: flex;
  flex-direction: column;
}

.section-title {
  font-size: 13px;
  font-weight: 700;
  margin-bottom: 16px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.pink-text { 
  color: #e91e63; 
}

.category-btn {
  width: 100%;
  padding: 16px 18px;
  margin-bottom: 10px;
  border-radius: 10px;
  border: none;
  text-align: left;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: #b56576;
  color: white;
  display: block;
}

.category-btn:hover {
  background: #c67889;
  transform: translateX(4px);
}

.category-btn.active {
  background: #c62828;
  border: 2px solid white;
  box-shadow: 0 4px 12px rgba(198, 40, 40, 0.3);
}

/* ===== MAIN AREA ===== */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}

.main-content {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  padding-bottom: 24px;
  transition: padding-bottom 0.2s ease;
}

.main-content.has-cart {
  padding-bottom: 94px; /* 70px cart bar + 24px default margin */
}

.main-content.has-tabs {
  padding-bottom: 112px; /* ~88px CategoryTabs + 24px default margin */
}

.main-content.has-cart.has-tabs {
  padding-bottom: 182px; /* 70px cart bar + ~88px CategoryTabs + 24px default margin */
}

.fixed-bottom-container {
  position: fixed;
  bottom: 0;
  left: 260px; /* Sidebar width */
  right: 0;
  z-index: 100;
  display: flex;
  flex-direction: column;
  background: transparent;
  pointer-events: none;
}

@media (max-width: 768px) {
  .fixed-bottom-container {
    left: 0;
  }
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid #333;
}

.category-header h1 {
  font-size: 28px;
  margin: 0;
  font-weight: 800;
}

.item-count {
  color: #888;
  font-size: 14px;
}

/* ===== ITEMS GRID ===== */
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(285px, 1fr));
  gap: 16px;
}

.item-card {
  background: #1e1e1e;
  border: 1px solid #333;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: all 0.2s;
}

.item-card:hover {
  border-color: #ff9800;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.2);
}

.item-info {
  flex: 1;
}

.item-name {
  margin: 0 0 4px 0;
  font-size: 15px;
  font-weight: 600;
}

.item-unit {
  font-size: 12px;
  color: #888;
}

.item-action {
  display: flex;
  align-items: center;
  gap: 12px;
}

.item-price {
  font-size: 16px;
  font-weight: 700;
  color: #ff9800;
}

.item-price.free {
  color: #4caf50;
}

.add-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #ff9800;
  border: none;
  color: white;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
}

.add-btn:hover {
  background: #ffb74d;
  transform: scale(1.1);
}

/* ===== EMPTY STATE ===== */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 100px 20px;
  color: #666;
}

.empty-icon {
  font-size: 80px;
  margin-bottom: 20px;
}

.empty-state h2 {
  font-size: 24px;
  margin-bottom: 10px;
  color: white;
  font-weight: 700;
}

/* ===== RESPONSIVE ===== */
@media (max-width: 768px) {
  .sidebar {
    width: 200px;
  }
}
</style>
