<!-- File: src/components/customer/MenuItemCard.vue -->
<template>
  <div class="bg-white border border-gray-200 rounded-lg overflow-hidden flex flex-col shadow-sm transition-all hover:shadow-md relative select-none">
    
    <!-- Image (aspect ratio 4:3) -->
    <div class="w-full aspect-[4/3] overflow-hidden bg-gray-150 relative cursor-pointer" @click="emit('click-detail', item)">
      <img v-if="item.image_url" 
           :src="item.image_url" 
           :alt="item.name" 
           class="w-full h-full object-cover" />
      <div v-else class="w-full h-full flex flex-col items-center justify-center text-gray-400 gap-1 bg-gray-100">
        <span class="text-3xl">🍲</span>
      </div>

      <!-- In-Package Badge (Trong gói) -->
      <span v-if="item.price === 0" 
            class="absolute top-2 left-2 text-[9px] font-black uppercase tracking-wider bg-[#E8772E] text-white px-2 py-0.5 rounded shadow">
        Trong gói
      </span>
    </div>

    <!-- Details Body -->
    <div class="p-3.5 flex-1 flex flex-col justify-between gap-2.5">
      <div class="cursor-pointer" @click="emit('click-detail', item)">
        <!-- Name: 2 lines max, bold, size 13px -->
        <h3 class="text-[13px] font-bold text-[#333333] line-clamp-2 min-h-[38px] leading-tight hover:text-[#E8772E] transition-colors">
          {{ item.name }}
        </h3>
        
        <!-- Price: format XXX.XXX, size 14px bold, color #C62828 -->
        <div class="mt-1 flex items-baseline gap-1">
          <span class="text-sm font-black text-[#C62828]">
            {{ formatPrice(item.price) }}
          </span>
          <span v-if="item.price === 0" class="text-[9px] text-[#666666] font-bold">
            (Trong gói buffet)
          </span>
        </div>
      </div>

      <!-- Bottom Row: Unit (Left) & Actions (Right) -->
      <div class="flex items-center justify-between border-t border-gray-100 pt-2 mt-0.5 shrink-0">
        <!-- Unit on the left, color #666666 -->
        <span class="text-[10px] font-bold text-[#666666] uppercase tracking-wider bg-gray-100 px-2 py-0.5 rounded">
          {{ item.unit }}
        </span>

        <!-- Quantity Controls / Add Button on the right -->
        <div v-if="quantityInCart > 0" 
             class="flex items-center gap-1.5 bg-gray-50 border border-gray-200 rounded-lg p-0.5">
          <button @click="decrease" 
                  class="w-6.5 h-6.5 rounded bg-gray-200 active:bg-gray-300 text-gray-600 transition-colors flex items-center justify-center font-black select-none text-xs">
            -
          </button>
          
          <span class="font-extrabold text-xs w-4 text-center text-[#333333] select-none">
            {{ quantityInCart }}
          </span>

          <button @click="increase" 
                  class="w-6.5 h-6.5 rounded bg-[#E8772E] hover:bg-amber-600 active:scale-95 text-white transition-all flex items-center justify-center font-black select-none text-xs">
            +
          </button>
        </div>

        <!-- Quick Add [+] Button (Orange) -->
        <button v-else 
                @click="increase" 
                class="w-7 h-7 rounded bg-[#E8772E] hover:bg-amber-600 active:scale-90 text-white font-extrabold transition-all flex items-center justify-center select-none shadow-sm">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
        </button>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import type { MenuItem } from '@/types/customer';

const props = withDefaults(
  defineProps<{
    item: MenuItem;
    quantityInCart?: number;
    categoryColor?: 'yellow' | 'pink';
  }>(),
  {
    quantityInCart: 0,
    categoryColor: 'yellow'
  }
);

const emit = defineEmits<{
  (e: 'add', item: MenuItem): void;
  (e: 'update-quantity', quantity: number): void;
  (e: 'click-detail', item: MenuItem): void;
}>();

function increase() {
  emit('update-quantity', props.quantityInCart + 1);
}

function decrease() {
  if (props.quantityInCart > 0) {
    emit('update-quantity', props.quantityInCart - 1);
  }
}

// Format: 80.000 instead of 80K
function formatPrice(val: number): string {
  return val.toLocaleString('vi-VN');
}
</script>
