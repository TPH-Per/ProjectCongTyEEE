<!-- File: src/views/customer/CustomerMenu.vue -->
<template>
  <div class="menu-layout relative min-h-screen overflow-x-hidden overflow-y-auto">
    <!-- Background Decorative Circles (z-0, pointer-events-none) -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none z-0">
      <!-- Circle 1 - Top right -->
      <div class="absolute -top-20 -right-20 w-96 h-96 max-w-[400px] max-h-[400px] bg-amber-500/10 rounded-full blur-3xl opacity-10"></div>
      <!-- Circle 2 - Bottom left -->
      <div class="absolute bottom-0 -left-20 w-72 h-72 max-w-[300px] max-h-[300px] bg-amber-600/10 rounded-full blur-2xl opacity-5"></div>
      <!-- Circle 3 - Center -->
      <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 max-w-[260px] max-h-[260px] bg-amber-500/5 rounded-full blur-3xl opacity-5"></div>
    </div>

    <!-- 1. SIDEBAR: Cấp 1 & Cấp 2 danh mục chính -->
    <aside class="sidebar scrollbar-hide z-10">
      <div class="sidebar-section full-height flex flex-col h-full">
        <h3 class="section-title pink-text">{{ $t('customer.menu.categories') }}</h3>
        
        <div class="flex-1 overflow-y-auto scrollbar-hide space-y-1.5 pr-1">
          <button
            v-for="cat in menuCategories"
            :key="cat.id"
            :class="['category-btn', { active: selectedCategory?.id === cat.id }]"
            @click="selectCategory(cat)"
          >
            {{ cat.name }}
          </button>
        </div>
      </div>
    </aside>

    <!-- 2. MAIN AREA -->
    <div class="main-area z-10">
      <!-- Mobile Category Bar (Visible only on screens <= 768px) -->
      <MenuCategoryBar
        v-if="menuCategories.length > 0"
        :categories="menuCategories"
        :selected-category-id="selectedCategory?.id || null"
        @select="onMobileCategorySelect"
        class="md:hidden border-b border-white/10 shrink-0"
      />

      <!-- Scrollable Content -->
      <main :class="['main-content', 'scrollbar-hide', { 'has-tabs': hasSubcategories, 'has-cart': cartItemCount > 0 }]">
        
        <!-- Package Purchase Banner (Only for set packages) -->
        <div v-if="selectedCategory && selectedCategory.id.startsWith('buffet-') && !selectedCategory.id.includes('drink') && !selectedCategory.id.includes('alacarte')"
             class="bg-gradient-to-r from-amber-950/60 via-amber-900/40 to-amber-950/60 border border-amber-500/30 rounded-2xl p-5 mb-6 flex flex-col sm:flex-row items-center justify-between gap-4 shrink-0 shadow-2xl backdrop-blur-md">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-3xl shadow-inner shrink-0">
              👑
            </div>
            <div>
              <h3 class="text-base font-black text-white tracking-wide">{{ $t('customer.menu.packageBannerTitle', { name: selectedCategory.name }) }}</h3>
              <p class="text-xs text-amber-200/80 mt-1 font-medium">{{ $t('customer.menu.packageBannerText') }}</p>
            </div>
          </div>
          <div class="flex items-center gap-4 shrink-0">
            <span class="text-xl font-black text-amber-400 tracking-tight">{{ getSetPriceDisplay(selectedCategory) }}</span>
            <button @click="addSetToCart(selectedCategory)"
                    :class="[
                      'px-5 py-2.5 rounded-xl font-extrabold text-xs transition-all duration-200 active:scale-95 flex items-center gap-1.5 shadow-lg shadow-amber-500/20',
                      isSetInCart(selectedCategory.id)
                        ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40 cursor-default pointer-events-none'
                        : 'bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-black border-none'
                    ]">
              {{ isSetInCart(selectedCategory.id) ? $t('customer.menu.packageSelected') : $t('customer.menu.selectPackage') }}
            </button>
          </div>
        </div>

        <div v-if="selectedCategory" class="category-content">
          <!-- Header -->
          <div class="category-header">
            <h1>{{ selectedCategory.name }}</h1>
            <span class="item-count">{{ $t('customer.menu.itemCount', { count: displayedItems.length }) }}</span>
          </div>

          <!-- Empty State -->
          <div v-if="displayedItems.length === 0" class="text-center py-16">
            <div class="text-8xl mb-6">📭</div>
            <h2 class="text-2xl font-bold text-gray-200 mb-2">Không có món nào</h2>
            <p class="text-gray-400">
              {{ store.searchQuery ? 'Không tìm thấy món phù hợp' : 'Menu đang được cập nhật' }}
            </p>
            <button 
              v-if="store.searchQuery" 
              @click="store.searchQuery = ''"
              class="mt-4 px-6 py-2 bg-amber-500 hover:bg-amber-400 text-black font-extrabold rounded-lg transition-colors text-sm shadow-lg shadow-amber-500/20"
            >
              Xóa bộ lọc
            </button>
          </div>

          <!-- Menu Grid - z-10 -->
          <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 relative z-10">
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
          <h2>{{ $t('customer.menu.selectCategoryTitle') }}</h2>
          <p>{{ $t('customer.menu.selectCategoryText') }}</p>
        </div>
      </main>

      <!-- Fixed bottom layout container -->
      <div v-if="!isModalOpen" class="fixed-bottom-container">
        <!-- CartBar (above Tabs or at bottom) -->
        <CartBar
          v-if="cartItemCount > 0"
          :cart-count="cartItemCount"
          :cart-total="store.cartTotal"
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

    <!-- Floating "Gọi Phục Vụ" Action Button (bottom right corner, safe from overlapping bottom bars) -->
    <div :class="[
      'fixed right-6 z-30 transition-all duration-300',
      hasSubcategories && cartItemCount > 0 ? 'bottom-36' : (hasSubcategories || cartItemCount > 0 ? 'bottom-24' : 'bottom-6')
    ]">
      <button
        @click="goToServiceRequest"
        class="w-14 h-14 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 active:scale-95 text-black rounded-full flex items-center justify-center shadow-2xl shadow-amber-500/30 border-2 border-amber-300/40 transition-all hover:rotate-12 select-none"
        :title="$t('customer.menu.callService')"
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

    <!-- Dev Mode Debug Overlay Panel -->
    <div v-if="isDevMode" class="fixed top-4 right-4 bg-rose-950/90 text-white p-4 rounded-2xl z-50 text-xs border border-rose-500/40 shadow-2xl backdrop-blur-md max-w-xs space-y-2 select-none">
      <div class="flex items-center justify-between font-black tracking-wider border-b border-rose-700/50 pb-1.5">
        <h3 class="font-bold flex items-center gap-1.5"><span class="animate-pulse">🐛</span> Debug Info</h3>
        <button @click="isDevMode = false" class="text-[10px] bg-rose-800 hover:bg-rose-700 px-2 py-0.5 rounded-lg text-rose-200 hover:text-white transition-colors">✕ Off</button>
      </div>
      <ul class="space-y-1.5 text-rose-200 text-[11px] font-medium">
        <li class="flex justify-between"><span>Menu items:</span> <span class="font-bold text-emerald-400">{{ debugState.itemCount }}</span></li>
        <li class="flex justify-between"><span>Grid visible:</span> <span class="font-bold">{{ debugState.gridVisible ? '✅' : '❌' }}</span></li>
        <li class="flex justify-between"><span>Background size:</span> <span class="font-mono text-white text-[10px]">{{ debugState.backgroundSize }}</span></li>
        <li class="flex justify-between border-t border-rose-800/60 pt-1"><span>Bàn:</span> <span class="font-bold text-white">{{ store.session?.tableNumber || 'A01' }}</span></li>
      </ul>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';
import { useI18nStore } from '@/stores/i18n';
import MenuItemDetailModal from '@/components/customer/MenuItemDetailModal.vue';
import MenuItemCard from '@/components/customer/MenuItemCard.vue';
import CategoryTabs from '@/components/customer/CategoryTabs.vue';
import CartBar from '@/components/customer/CartBar.vue';
import MenuCategoryBar from '@/components/customer/MenuCategoryBar.vue';
import type { MenuCategory, MenuItem } from '@/types/customer';
import { applyPackage, calculateItemUnitPrice } from '@/utils/packageRules';
import { mockSession } from '@/data/mockCartData';

const router = useRouter()
const store = useCustomerStore()
const i18nStore = useI18nStore()
const { syncCart } = useCustomerSession();

const isDevMode = ref(import.meta.env.DEV);

const debugState = computed(() => {
  const circle = typeof document !== 'undefined' ? document.querySelector('.bg-amber-500\\/10.rounded-full') : null;
  let bgSize = '384px x 384px';
  if (circle) {
    const styles = window.getComputedStyle(circle);
    bgSize = `${styles.width} x ${styles.height}`;
  }
  return {
    itemCount: displayedItems.value.length,
    gridVisible: displayedItems.value.length > 0,
    backgroundSize: bgSize,
  };
});

const focusedItem = ref<MenuItem | null>(null);
const isModalOpen = computed(() => focusedItem.value !== null);

// State
const selectedCategory = ref<MenuCategory | null>(null);
const selectedYellowCategoryId = ref<string | null>(null);
const selectedSubId = ref<string>('all');

const cart = computed(() => store.cart);
const cartItemCount = computed(() => store.cartItemCount);

// Computed: Categories of Gói dịch vụ (Used for price calculation mapping)
const yellowCategories = computed(() => {
  const buffetCat = store.menuData.find(c => c.id === 'buffet');
  return buffetCat?.subcategories || [];
});

// Computed: Menu Categories in Sidebar (Ensures categories are never empty)
const menuCategories = computed(() => {
  if (!store.menuData || store.menuData.length === 0) return [];
  
  const list: any[] = [];
  const buffetCat = store.menuData.find(c => c.id === 'buffet');
  if (buffetCat && store.session?.serviceMode === 'buffet') {
    list.push(buffetCat);
  }
  
  const others = store.menuData.filter(c => c.id !== 'buffet' || store.session?.serviceMode !== 'buffet');
  list.push(...others);
  
  return list.length > 0 ? list : store.menuData;
});

// Watch menuCategories to automatically select first category when data loads
watch(menuCategories, (newCats) => {
  if (newCats && newCats.length > 0) {
    if (!selectedCategory.value || !newCats.some(c => c.id === selectedCategory.value?.id)) {
      selectedCategory.value = newCats[0];
      if (newCats[0].subcategories && newCats[0].subcategories.length > 0) {
        selectedSubId.value = newCats[0].subcategories[0].id;
        selectedYellowCategoryId.value = newCats[0].id === 'buffet' ? newCats[0].subcategories[0].id : null;
      } else {
        selectedSubId.value = 'all';
      }
    }
  }
}, { immediate: true });

// Computed: Check if has subcategories
const hasSubcategories = computed(() => 
  selectedCategory.value?.subcategories && 
  selectedCategory.value.subcategories.length > 0
);

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
  const firstCat = menuCategories.value[0];
  if (firstCat && !selectedCategory.value) {
    selectedCategory.value = firstCat;
    if (firstCat.subcategories && firstCat.subcategories.length > 0) {
      selectedSubId.value = firstCat.subcategories[0].id;
      selectedYellowCategoryId.value = firstCat.id === 'buffet' ? firstCat.subcategories[0].id : null;
    }
  }
};

// Listen for real-time sold-out changes from Menu Management
const handleMenuItemStatusChanged = (event: Event) => {
  const detail = (event as CustomEvent).detail;
  if (!detail) return;
  const { id, name, is_sold_out } = detail;

  const findAndUpdate = (items: MenuItem[]): boolean => {
    const item = items.find((i) => i.id === id || i.name === name);
    if (item) {
      item.is_sold_out = is_sold_out;
      return true;
    }
    return false;
  };

  for (const cat of store.menuData) {
    if (cat.items && findAndUpdate(cat.items)) return;
    if (cat.subcategories) {
      for (const sub of cat.subcategories) {
        if (findAndUpdate(sub.items)) return;
      }
    }
  }
};

// Load menu on mount
onMounted(async () => {
  // If no session exists, create a default mock session so direct access for testing works seamlessly
  if (!store.session) {
    store.session = mockSession;
  }
  
  await store.loadMenu();
  initDefaults();
  window.addEventListener('menu:item-status-changed', handleMenuItemStatusChanged);

  console.log('📦 CustomerMenu loaded - categories:', menuCategories.value.length, 'displayedItems:', displayedItems.value.length);
});

onUnmounted(() => {
  window.removeEventListener('menu:item-status-changed', handleMenuItemStatusChanged);
});

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

function getModifiedItem(item: MenuItem, packageName: string): MenuItem {
  const inPkg = applyPackage(
    { ...item, subCatId: subCatIdByItemId.value.get(item.id) },
    packageName,
  )
  if (inPkg.price === 0) return inPkg
  const unit = calculateItemUnitPrice(item, packageName)
  if (unit === Number(item.price ?? 0)) return item
  const half = Math.round(Number(item.price ?? 0) * 0.5)
  return {
    ...item,
    price: unit,
    price_display: i18nStore.t('customer.menuItem.lunchPrice', { price: `${half.toLocaleString('vi-VN')}đ` }),
  }
}

function getQuantity(itemId: string): number {
  const inCart = cart.value.find(c => c.menuItemId === itemId);
  return inCart ? inCart.quantity : 0;
}

// Actions
const selectCategory = (cat: MenuCategory) => {
  selectedCategory.value = cat;
  selectedSubId.value = 'all'; // Reset to "Tất cả"
};

const onMobileCategorySelect = (catId: string) => {
  const cat = menuCategories.value.find(c => c.id === catId);
  if (cat) {
    selectCategory(cat);
  }
};

const handleAddToCart = (item: MenuItem) => {
  if (item.is_sold_out) return;
  const activePackage = yellowCategories.value.find(c => c.id === selectedYellowCategoryId.value);
  const modifiedItem = getModifiedItem(item, activePackage?.name || '');
  const existing = cart.value.find(c => c.menuItemId === modifiedItem.id);
  if (existing) {
    store.updateCartItem(modifiedItem.id, existing.quantity + 1);
  } else {
    store.addToCart(modifiedItem, 1);
  }
  syncCart();
  store.addNotification(i18nStore.t('customer.menu.addedToCart', { qty: 1, name: modifiedItem.name }), 'success');
};

function openDetail(item: MenuItem) {
  if (item.is_sold_out) return;
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
    store.addNotification(i18nStore.t('customer.menu.addedToCart', { qty: quantity, name: item.name }), 'success');
  }
  closeDetail();
}

function goToCart() {
  router.push({ name: 'CustomerCart' });
}

function goToServiceRequest() {
  router.push({ name: 'ServiceRequest' });
}

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
  const ticket = store.menuData
    .flatMap((c) => c.subcategories ?? [])
    .find((s) => s.id === catId)
    ?.items?.[0]
  if (!ticket) return false
  return cart.value.some((c) => c.menuItemId === ticket.id)
};

function addSetToCart(cat: MenuCategory) {
  const subs = cat.subcategories || []
  const setItem = subs[0]?.items?.[0] ?? null

  if (setItem) {
    store.addToCart(setItem, 1)
    syncCart()
    store.addNotification(i18nStore.t('customer.menu.packageSelectedNotif', { name: cat.name }), 'success')
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

/* ===== LAYOUT CHÍNH ===== */
.menu-layout {
  display: flex;
  height: 100%;
  width: 100%;
  background-color: #0d0d0f;
  color: white;
  overflow: hidden;
}

/* ===== SIDEBAR ===== */
.sidebar {
  width: 250px;
  background: #141417;
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  overflow-y: auto;
  padding: 20px 14px;
  height: 100%;
  flex-shrink: 0;
}

.section-title {
  font-size: 11px;
  font-weight: 900;
  margin-bottom: 14px;
  text-transform: uppercase;
  letter-spacing: 1.5px;
}

.pink-text { 
  color: #f59e0b; 
}

.category-btn {
  width: 100%;
  padding: 13px 16px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.05);
  text-align: left;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  background: #1e1e24;
  color: #a1a1aa;
  display: block;
}

.category-btn:hover {
  background: #27272a;
  color: white;
  border-color: rgba(245, 158, 11, 0.3);
  transform: translateX(4px);
}

.category-btn.active {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #000000;
  font-weight: 900;
  border: none;
  box-shadow: 0 4px 14px rgba(245, 158, 11, 0.35);
}

/* ===== MAIN AREA ===== */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  height: 100%;
}

.main-content {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  padding-bottom: 24px;
  transition: padding-bottom 0.2s ease;
}

.main-content.has-cart {
  padding-bottom: 90px;
}

.main-content.has-tabs {
  padding-bottom: 90px;
}

.main-content.has-cart.has-tabs {
  padding-bottom: 160px;
}

.fixed-bottom-container {
  position: fixed;
  bottom: 0;
  left: 250px;
  right: 0;
  z-index: 50;
  display: flex;
  flex-direction: column;
  background: transparent;
  pointer-events: none;
}

@media (max-width: 768px) {
  .sidebar {
    display: none;
  }
  .fixed-bottom-container {
    left: 0;
  }
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 14px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.category-header h1 {
  font-size: 24px;
  margin: 0;
  font-weight: 800;
  color: #ffffff;
}

.item-count {
  color: #a1a1aa;
  font-size: 13px;
  font-weight: 600;
}

/* ===== ITEMS GRID ===== */
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 16px;
}

/* ===== EMPTY STATE ===== */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 20px;
  color: #71717a;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.empty-state h2 {
  font-size: 20px;
  margin-bottom: 8px;
  color: white;
  font-weight: 700;
}
</style>


