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
        <!-- BottomCartBar (above Tabs or at the bottom if no tabs) -->
        <BottomCartBar
          v-if="cartItemCount > 0"
          :cart-item-count="cartItemCount"
          :cart-total="store.cartTotal"
          @go-to-cart="goToCart"
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
import BottomCartBar from '@/components/customer/BottomCartBar.vue';
import { menuData, type MenuCategory, type MenuItem } from '@/data/menuData';

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
  const buffetCat = menuData.categories.find(c => c.id === 'buffet');
  return buffetCat?.subcategories || [];
});

// Computed: Menu Categories in Sidebar (Only 9 items)
const menuCategories = computed(() => {
  const list: any[] = [];
  const buffetCat = menuData.categories.find(c => c.id === 'buffet');
  if (buffetCat) {
    list.push(buffetCat);
  }
  const others = menuData.categories.filter(c => c.color === 'pink');
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
  if (selectedCategory.value?.id === 'buffet' && newSubId !== 'all') {
    selectedYellowCategoryId.value = newSubId;
  }
});

// Initialize defaults
const initDefaults = () => {
  const buffet = menuData.categories.find(c => c.id === 'buffet');
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

// Dynamic Package Pricing Rule
function isItemInPackage(item: MenuItem, mainCategoryName: string): boolean {
  if (!mainCategoryName) return false;
  const name = mainCategoryName.toUpperCase();
  const lowerItemName = item.name.toLowerCase();
  const lowerItemId = item.id.toLowerCase();
  const lowerCatId = item.category_id.toLowerCase();

  if (name.includes('A LA CARTE')) return false;

  if (name.includes('DRINK')) {
    return lowerCatId.includes('uong') || lowerCatId.includes('con');
  }

  if (name.includes('LẨU')) {
    return lowerItemName.includes('lẩu') || lowerItemName.includes('lau') || lowerItemName.includes('rau') || lowerItemName.includes('nước') || lowerItemName.includes('coca') || lowerItemName.includes('bia') || lowerItemName.includes('nấm');
  }

  if (name.includes('550JP')) {
    return lowerItemName.includes('bento') || lowerItemName.includes('sashimi') || lowerItemName.includes('tempura') || lowerItemName.includes('miso');
  }

  if (name.includes('1390')) {
    return true;
  }

  if (name.includes('1150')) {
    const isWagyu = lowerItemName.includes('wagyu') || lowerItemId.includes('wagyu');
    return !isWagyu;
  }

  if (name.includes('680')) {
    const isWagyu = lowerItemName.includes('wagyu') || lowerItemId.includes('wagyu');
    const isPremium = lowerItemName.includes('premium') || lowerItemName.includes('sirloin') || lowerItemName.includes('thăn ngoại') || lowerItemName.includes('dẻ sườn') || lowerItemName.includes('lưỡi') || lowerItemName.includes('tongue');
    return !isWagyu && !isPremium;
  }

  if (name.includes('490') || name.includes('380')) {
    const isWagyu = lowerItemName.includes('wagyu') || lowerItemId.includes('wagyu');
    const isBeef = lowerItemName.includes('bò') || lowerItemName.includes('beef') || lowerItemName.includes('sirloin') || lowerItemName.includes('sườn') || lowerItemName.includes('thăn') || lowerItemName.includes('lưỡi') || lowerItemName.includes('tongue');
    const isAlcohol = lowerCatId.includes('con') || lowerItemName.includes('rượu') || lowerItemName.includes('soju') || lowerItemName.includes('beer') || lowerItemName.includes('bia');
    return !isWagyu && !isBeef && !isAlcohol;
  }

  return false;
}

function getModifiedItem(item: MenuItem, packageName: string): MenuItem {
  const inPkg = isItemInPackage(item, packageName);
  if (inPkg) {
    return {
      ...item,
      price: 0,
      price_display: '0K (Trong gói)'
    };
  }
  return item;
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

const isSetInCart = (id: string): boolean => {
  return cart.value.some(c => c.menuItemId.includes(id));
};

function addSetToCart(cat: MenuCategory) {
  const subs = cat.subcategories || [];
  const setItem = subs.reduce((found: MenuItem | null, sub) => {
    if (found) return found;
    return sub.items.find(i => i.id.includes(cat.id)) || null;
  }, null);

  if (setItem) {
    store.addToCart(setItem, 1);
    syncCart();
    store.addNotification(`Đã chọn gói ${cat.name}`, 'success');
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
