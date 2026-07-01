<!-- File: src/views/customer/CustomerMenu.vue -->
<template>
  <div class="w-full h-full flex overflow-hidden bg-[#3D2817]">
    
    <!-- LEFT SIDEBAR (200px width, light gray background) -->
    <aside class="w-[200px] bg-[#F5F5F5] border-r border-gray-300 flex shrink-0 relative overflow-hidden flex-col">
      <!-- Decorative vertical orange banner label "BUFFET" -->
      <div class="absolute top-0 bottom-0 left-0 w-8 bg-[#E8772E] flex items-center justify-center select-none shadow-sm shrink-0">
        <span class="text-white font-black text-sm tracking-[8px] uppercase font-serif [writing-mode:vertical-lr] rotate-180">
          BUFFET
        </span>
      </div>

      <!-- Category List Container -->
      <div class="flex-1 pl-10 pr-3 py-6 overflow-y-auto flex flex-col gap-2.5">
        <h3 class="text-xs font-black text-gray-400 uppercase tracking-widest mb-3 border-b border-gray-200 pb-1.5 font-serif">
          Danh mục
        </h3>

        <!-- Categories vertical list -->
        <button v-for="cat in categories" :key="cat.id"
                @click="onCategorySelect(cat.id)"
                :class="[
                  'w-full text-left px-4 py-3.5 rounded-lg text-xs font-bold transition-all border active:scale-95 flex items-center gap-2 select-none shadow-sm',
                  
                  // Active state: Orange background (#E8772E), white text
                  selectedCategory?.id === cat.id
                    ? 'bg-[#E8772E] border-[#E8772E] text-white font-extrabold shadow-md scale-102'
                    : 'bg-white border-gray-200 text-[#333333] hover:bg-gray-100 hover:border-gray-300'
                ]">
          <span class="text-sm">
            {{ getCategoryEmoji(cat.id) }}
          </span>
          <span class="truncate">{{ cat.name }}</span>
        </button>
      </div>
    </aside>

    <!-- RIGHT CONTENT AREA (dark brown wood theme background) -->
    <main class="flex-1 flex flex-col overflow-hidden relative">
      
      <!-- Hàng 2 - Subcategory Selector Bar (Pink Theme, only shows dynamically for pink categories) -->
      <MenuSubcategoryBar v-if="selectedCategory?.color === 'pink' && subcategories.length > 0"
                          :subcategories="subcategories"
                          :selected-subcategory-id="selectedSubcategory?.id || null"
                          @select="onSubcategorySelect" />

      <!-- Section Title & Grid -->
      <div class="flex-1 overflow-y-auto p-6 md:p-8 flex flex-col gap-6">
        
        <!-- Section Header (Category name + price if available) -->
        <div class="flex items-center justify-between border-b border-[#442c19] pb-4 shrink-0">
          <div class="flex items-baseline gap-3">
            <h2 class="text-xl md:text-2xl font-black text-white font-serif tracking-wide">
              {{ selectedCategory?.name }}
            </h2>
            <!-- If category is a Set, show set pricing in header -->
            <span v-if="selectedCategorySetPrice" class="text-sm font-extrabold text-[#E8772E]">
              Giá gói: {{ selectedCategorySetPrice }}
            </span>
          </div>
          <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">
            {{ filteredItems.length }} Món ăn khả dụng
          </span>
        </div>

        <!-- Menu Items List Section (3 columns grid) -->
        <div class="flex-1">
          <!-- Empty State -->
          <div v-if="filteredItems.length === 0" class="flex flex-col items-center justify-center py-20 text-center text-gray-500 gap-2">
            <span class="text-4xl">🍽️</span>
            <p class="text-sm font-bold">Không tìm thấy món ăn nào</p>
          </div>

          <!-- Items Grid -->
          <div v-else class="grid grid-cols-2 md:grid-cols-3 gap-5">
            <MenuItemCard v-for="item in filteredItems" :key="item.id"
                          :item="item"
                          :quantity-in-cart="getQuantity(item.id)"
                          :category-color="selectedCategory?.color || 'yellow'"
                          @update-quantity="onUpdateQuantity(item.id, $event)"
                          @click-detail="openDetail" />
          </div>
        </div>
      </div>

      <!-- Sticky Cart Summary bar (displays at the bottom when cart contains items) -->
      <transition name="slide-up">
        <div v-if="cartItemCount > 0" 
             class="bg-[#1a110a] border-t border-[#2d1e12] p-4 px-6 md:px-8 flex items-center justify-between shrink-0 z-20 shadow-[0_-10px_25px_rgba(0,0,0,0.5)]">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 bg-amber-500/10 border border-[#E8772E]/20 text-[#E8772E] rounded-xl flex items-center justify-center text-xl font-bold">
              🛒
            </div>
            <div>
              <h4 class="text-sm font-bold text-white">Giỏ hàng của bàn</h4>
              <p class="text-xs font-semibold text-gray-400 mt-0.5">
                Đã chọn <span class="text-[#E8772E] font-extrabold">{{ cartItemCount }} món</span> · Tổng cộng: <span class="text-amber-400 font-extrabold">{{ cartTotalDisplay }}</span>
              </p>
            </div>
          </div>

          <button @click="goToCart"
                  class="bg-[#E8772E] hover:bg-amber-600 active:scale-95 text-white font-extrabold px-8 py-3.5 rounded-xl transition-all shadow-lg shadow-amber-500/15 text-sm flex items-center gap-2 select-none">
            Xem giỏ hàng
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
              <line x1="5" y1="12" x2="19" y2="12"></line>
              <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
          </button>
        </div>
      </transition>
    </main>

    <!-- Floating "Gọi Phục Vụ" Action Button (bottom right corner) -->
    <div class="absolute bottom-6 right-6 z-30 pointer-events-none">
      <button @click="goToServiceRequest"
              class="pointer-events-auto w-14 h-14 bg-[#E8772E] hover:bg-amber-600 active:scale-95 text-white rounded-full flex items-center justify-center shadow-2xl shadow-[#E8772E]/20 border-2 border-white/10 transition-all hover:rotate-12 select-none">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
      </button>
    </div>

    <!-- Detail Modal Dialog -->
    <MenuItemDetail :item="focusedItem"
                    :initial-quantity="focusedItemQty"
                    :initial-note="focusedItemNote"
                    @close="closeDetail"
                    @confirm="confirmDetailAdd" />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import { useCustomerSession } from '@/composables/useCustomerSession';
import MenuSubcategoryBar from '@/components/customer/MenuSubcategoryBar.vue';
import MenuItemCard from '@/components/customer/MenuItemCard.vue';
import MenuItemDetail from './MenuItemDetail.vue';
import type { MenuItem } from '@/types/customer';

const store = useCustomerStore();
const router = useRouter();
const { syncCart } = useCustomerSession();

const focusedItem = ref<MenuItem | null>(null);

const categories = computed(() => store.menuData);
const selectedCategory = computed(() => store.selectedCategory);
const selectedSubcategory = computed(() => store.selectedSubcategory);
const cart = computed(() => store.cart);
const cartItemCount = computed(() => store.cartItemCount);
const cartTotalDisplay = computed(() => store.cartTotal.toLocaleString('vi-VN') + 'đ');

// Subcategories computed
const subcategories = computed(() => {
  return selectedCategory.value?.subcategories || [];
});

// Dynamic category set price search
const selectedCategorySetPrice = computed(() => {
  if (!selectedCategory.value) return '';
  // Check if category name starts with SET or contains numeric digits
  const name = selectedCategory.value.name;
  if (name.toUpperCase().startsWith('SET ')) {
    const numPart = name.replace(/[^0-9]/g, '');
    if (numPart) {
      return parseInt(numPart) * 1000 + 'đ';
    }
  }
  return '';
});

// Load menu on mount
onMounted(async () => {
  // BR-09: Must have session to view menu
  if (!store.session) {
    router.push({ name: 'CustomerHome' });
    return;
  }
  await store.loadMenu();
});

// Filter items based on subcategory selection & search queries (from store.searchQuery)
const filteredItems = computed(() => {
  let itemsToFilter: MenuItem[] = [];

  if (selectedCategory.value?.color === 'yellow') {
    // Yellow categories: return all items directly
    const subs = selectedCategory.value.subcategories || [];
    itemsToFilter = subs.reduce((all: MenuItem[], sub) => [...all, ...sub.items], []);
  } else if (selectedSubcategory.value && selectedSubcategory.value.items) {
    itemsToFilter = selectedSubcategory.value.items;
  } else if (selectedCategory.value) {
    // Fallback aggregator
    const subs = selectedCategory.value.subcategories || [];
    itemsToFilter = subs.reduce((all: MenuItem[], sub) => [...all, ...sub.items], []);
  }

  // Deduplicate items
  const uniqueItems = Array.from(new Map(itemsToFilter.map(item => [item.id, item])).values());

  // Apply search query from the store
  if (store.searchQuery.trim()) {
    const q = store.searchQuery.toLowerCase().trim();
    return uniqueItems.filter(item => 
      item.name.toLowerCase().includes(q) || 
      (item.description && item.description.toLowerCase().includes(q))
    );
  }

  return uniqueItems;
});

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

function onCategorySelect(id: string) {
  store.selectCategory(id);
}

function onSubcategorySelect(id: string) {
  store.selectSubcategory(id);
}

function onUpdateQuantity(itemId: string, qty: number) {
  store.updateCartItem(itemId, qty);
  syncCart();
}

function openDetail(item: MenuItem) {
  focusedItem.value = item;
}

function closeDetail() {
  focusedItem.value = null;
}

function confirmDetailAdd(data: { itemId: string; quantity: number; note: string }) {
  const item = filteredItems.value.find(i => i.id === data.itemId);
  if (item) {
    const existing = cart.value.find(c => c.menuItemId === item.id);
    if (existing) {
      store.updateCartItem(item.id, data.quantity);
      existing.note = data.note;
    } else {
      store.addToCart(item, data.quantity);
      const added = cart.value.find(c => c.menuItemId === item.id);
      if (added) added.note = data.note;
    }
    syncCart();
    store.addNotification(`Đã thêm ${data.quantity} x ${item.name} vào giỏ hàng`, 'success');
  }
  closeDetail();
}

function goToCart() {
  router.push({ name: 'CustomerCart' });
}

function goToServiceRequest() {
  router.push({ name: 'ServiceRequest' });
}

function getCategoryEmoji(id: string): string {
  const lower = id.toLowerCase();
  if (lower.includes('1390')) return '👑';
  if (lower.includes('1150')) return '🥩';
  if (lower.includes('680')) return '👨‍👩‍👧';
  if (lower.includes('490')) return '👩‍❤️‍👨';
  if (lower.includes('380')) return '🎓';
  if (lower.includes('drink')) return '🥤';
  if (lower.includes('carte')) return '🍽️';
  if (lower.includes('550jp')) return '🍣';
  if (lower.includes('lau') || lower.includes('lẩu')) return '🍲';
  if (lower.includes('buffet')) return '🍢';
  if (lower.includes('lunch')) return '🍱';
  if (lower.includes('tiec') || lower.includes('tiệc')) return '🎉';
  if (lower.includes('vietravel')) return '✈️';
  if (lower.includes('an') || lower.includes('ăn')) return '🍖';
  if (lower.includes('uong') || lower.includes('uống')) return '🍺';
  if (lower.includes('con') || lower.includes('cồn')) return '🍶';
  return '🌟';
}
</script>

<style scoped>
.slide-up-enter-active, .slide-up-leave-active {
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from, .slide-up-leave-to {
  transform: translateY(100%);
}
</style>
