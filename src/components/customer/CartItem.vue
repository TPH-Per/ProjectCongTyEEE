<!-- File: src/components/customer/CartItem.vue -->
<template>
  <div class="bg-white border border-gray-200 rounded-2xl p-4 md:p-5 flex items-center justify-between gap-4 transition-all hover:shadow-md select-none">
    
    <!-- Multi-select Checkbox on the left -->
    <div class="flex items-center justify-center shrink-0 pr-1">
      <input type="checkbox" 
             :checked="isSelected" 
             @change="emit('toggle-select')" 
             class="w-5 h-5 rounded-lg border-gray-350 text-[#E8772E] focus:ring-[#E8772E]/50 focus:ring-2 cursor-pointer transition-colors" />
    </div>

    <!-- Item Details -->
    <div class="flex-1 flex gap-3 min-w-0 items-center">
      <div class="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center text-2xl shrink-0 select-none border border-gray-200">
        🥩
      </div>
      
      <div class="flex-1 min-w-0">
        <h3 class="text-sm font-bold text-[#333333] truncate leading-tight">{{ item.name }}</h3>
        
        <!-- Format: 170K x 1 = 170.000đ style -->
        <p class="text-[11px] font-bold text-[#C62828] mt-0.5">
          {{ formatPriceDisplay(item.price) }} × {{ item.quantity }} = {{ lineTotalDisplay }}
        </p>

        <!-- Cooking Note Input -->
        <div class="mt-2 flex items-center gap-1.5 w-full">
          <span class="text-[10px] text-[#E8772E] font-black shrink-0">Ghi chú:</span>
          <input type="text" 
                 :value="item.note"
                 @input="updateNote(($event.target as HTMLInputElement).value)"
                 placeholder="Không hành, chín kỹ..." 
                 class="bg-gray-50 border border-gray-200 rounded-lg px-2 py-0.5 text-[11px] text-[#333333] placeholder-gray-400 focus:outline-none focus:border-[#E8772E]/50 flex-1 min-w-0" />
        </div>
      </div>
    </div>

    <!-- Right Controls: Quantity Modifier & Single Delete -->
    <div class="flex items-center gap-4 shrink-0">
      <!-- Quantity Controls -->
      <div class="flex items-center gap-1.5 bg-gray-50 border border-gray-250 rounded-lg p-0.5 shrink-0">
        <button @click="decrease" 
                class="w-6.5 h-6.5 rounded bg-gray-200 active:bg-gray-300 text-[#333333] transition-colors flex items-center justify-center font-black select-none text-xs">
          -
        </button>
        <span class="font-extrabold text-xs w-4 text-center text-[#333333] select-none">
          {{ item.quantity }}
        </span>
        <button @click="increase" 
                class="w-6.5 h-6.5 rounded bg-[#E8772E] hover:bg-amber-600 active:scale-95 text-white transition-all flex items-center justify-center font-black select-none text-xs">
          +
        </button>
      </div>

      <!-- Delete Bin button -->
      <button @click="emit('remove')" 
              class="w-8 h-8 rounded-lg border border-gray-200 text-gray-400 hover:text-rose-500 hover:border-rose-550/20 transition-all flex items-center justify-center active:scale-90 bg-gray-50 hover:bg-rose-500/5 shrink-0">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="3 6 5 6 21 6"></polyline>
          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
        </svg>
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { CartItem } from '@/types/customer';

const props = defineProps<{
  item: CartItem;
  isSelected: boolean;
}>();

const emit = defineEmits<{
  (e: 'update-quantity', quantity: number): void;
  (e: 'update-note', note: string): void;
  (e: 'remove'): void;
  (e: 'toggle-select'): void;
}>();

const lineTotalDisplay = computed(() => {
  const lineTotal = props.item.price * props.item.quantity;
  if (lineTotal === 0) return '0đ';
  return lineTotal.toLocaleString('vi-VN') + 'đ';
});

function increase() {
  emit('update-quantity', props.item.quantity + 1);
}

function decrease() {
  if (props.item.quantity > 1) {
    emit('update-quantity', props.item.quantity - 1);
  } else {
    emit('remove');
  }
}

function updateNote(value: string) {
  emit('update-note', value);
}

function formatPriceDisplay(val: number): string {
  if (val === 0) return '0K';
  if (val >= 1000) return (val / 1000) + 'K';
  return val.toLocaleString('vi-VN') + 'đ';
}
</script>
