<!-- File: src/views/customer/MenuItemList.vue -->
<template>
  <div class="w-full">
    <!-- Empty State -->
    <div v-if="items.length === 0" class="flex flex-col items-center justify-center py-16 text-center text-gray-500 gap-2">
      <span class="text-4xl">🍽️</span>
      <p class="text-sm font-bold">Không tìm thấy món ăn nào</p>
    </div>

    <!-- Items Grid -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 md:gap-6">
      <MenuItemCard v-for="item in items" :key="item.id"
                    :item="item"
                    :quantity-in-cart="getQuantity(item.id)"
                    :category-color="categoryColor"
                    @update-quantity="onUpdateQuantity(item, $event)"
                    @click-detail="onClickDetail" />
    </div>
  </div>
</template>

<script setup lang="ts">
import MenuItemCard from '@/components/customer/MenuItemCard.vue';
import type { MenuItem, CartItem } from '@/types/customer';

const props = withDefaults(
  defineProps<{
    items: MenuItem[];
    cart: CartItem[];
    categoryColor?: 'yellow' | 'pink';
  }>(),
  {
    categoryColor: 'yellow'
  }
);

const emit = defineEmits<{
  (e: 'update-quantity', itemId: string, qty: number): void;
  (e: 'click-detail', item: MenuItem): void;
}>();

function getQuantity(itemId: string): number {
  const cartItem = props.cart.find(c => c.menuItemId === itemId);
  return cartItem ? cartItem.quantity : 0;
}

function onUpdateQuantity(item: MenuItem, qty: number) {
  emit('update-quantity', item.id, qty);
}

function onClickDetail(item: MenuItem) {
  emit('click-detail', item);
}
</script>
