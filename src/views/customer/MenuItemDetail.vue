<!-- File: src/views/customer/MenuItemDetail.vue -->
<template>
  <transition name="modal-fade">
    <div v-if="item" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/90 backdrop-blur-sm select-none">
      <div class="bg-[#141414] border border-gray-808 rounded-3xl w-full max-w-lg overflow-hidden shadow-2xl relative flex flex-col max-h-[95vh] animate-fade-scale">
        
        <!-- Image Cover with Actions -->
        <div class="h-60 bg-gray-900 relative shrink-0">
          <img v-if="item.image_url" :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
          <div v-else class="w-full h-full flex items-center justify-center text-gray-700 text-6xl">
            🍲
          </div>
          
          <!-- Top-left: Back Button -->
          <button @click="emit('close')" 
                  class="absolute top-4 left-4 w-10 h-10 rounded-full bg-black/60 hover:bg-black/80 text-white flex items-center justify-center border border-gray-800 transition-all active:scale-90">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>

          <!-- Top-right: Quick Cart Button with Badge -->
          <button @click="goToCart" 
                  class="absolute top-4 right-4 bg-amber-500 hover:bg-amber-600 text-black font-extrabold px-4 py-2 rounded-full text-xs flex items-center gap-1.5 shadow-lg shadow-amber-500/20 transition-all active:scale-90">
            Giỏ ({{ store.cartItemCount }})
          </button>

          <!-- Unit badge -->
          <span class="absolute bottom-4 left-4 text-xs font-bold bg-black/60 text-gray-200 border border-gray-800 px-3 py-1 rounded-full">
            Đơn vị: {{ item.unit }}
          </span>
        </div>

        <!-- Details Body -->
        <div class="p-6 flex-1 overflow-y-auto flex flex-col gap-4">
          <div>
            <h2 class="text-xl md:text-2xl font-black text-white leading-tight">
              {{ item.name }}
            </h2>
            <span class="text-xl font-extrabold text-amber-500 block mt-1.5">
              {{ item.price === 0 ? '0K (Trong gói buffet)' : item.price_display }}
            </span>
          </div>

          <!-- Description -->
          <div class="bg-black/30 p-3.5 rounded-xl border border-gray-900">
            <h4 class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Mô tả</h4>
            <p class="text-xs text-gray-300 leading-relaxed">
              {{ item.description || 'Chưa có thông tin mô tả chi tiết cho món ăn này. Nguồn nguyên liệu được tuyển chọn kỹ lưỡng, bảo quản nghiêm ngặt.' }}
            </p>
          </div>

          <!-- Additional Information (Allergen, Spicy, Cooking Time) -->
          <div class="grid grid-cols-3 gap-2 text-[11px] font-bold text-gray-400">
            <div class="bg-gray-900/60 border border-gray-850 p-2.5 rounded-xl text-center flex flex-col items-center justify-center gap-1">
              <span class="text-gray-500">🚫 Dị ứng</span>
              <span class="text-white truncate max-w-full" title="Không chứa đậu phộng">Không đậu phộng</span>
            </div>
            <div class="bg-gray-900/60 border border-gray-850 p-2.5 rounded-xl text-center flex flex-col items-center justify-center gap-1">
              <span class="text-gray-500">🔥 Độ cay</span>
              <span class="text-amber-500">Nhẹ</span>
            </div>
            <div class="bg-gray-900/60 border border-gray-850 p-2.5 rounded-xl text-center flex flex-col items-center justify-center gap-1">
              <span class="text-gray-500">⏱️ Thời gian</span>
              <span class="text-white">8-10 phút</span>
            </div>
          </div>

          <!-- Special Notes -->
          <div>
            <h4 class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1.5">Ghi chú cho bếp</h4>
            <textarea v-model="note"
                      rows="2"
                      placeholder="Không cay, không hành, chín kỹ..."
                      class="w-full bg-black/40 border border-gray-800 focus:border-amber-500/50 rounded-xl p-3 text-xs text-gray-200 placeholder-gray-600 focus:outline-none resize-none transition-colors">
            </textarea>
          </div>

          <!-- Quantity Selector -->
          <div class="flex items-center justify-between border-t border-gray-900 pt-3 mt-1 shrink-0">
            <span class="text-xs font-bold text-gray-400">Số lượng:</span>
            
            <div class="flex items-center gap-3.5 bg-black/60 border border-gray-800 rounded-full p-1">
              <button @click="decrease" 
                      class="w-9 h-9 rounded-full bg-gray-800 active:bg-gray-700 hover:text-white transition-colors flex items-center justify-center text-gray-400 select-none">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
              </button>
              
              <span class="font-black text-base w-5 h-5 flex items-center justify-center text-white select-none">
                {{ qty }}
              </span>

              <button @click="increase" 
                      class="w-9 h-9 rounded-full bg-amber-500 text-black hover:bg-amber-600 active:scale-95 transition-all flex items-center justify-center select-none shadow-lg shadow-amber-500/10">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="12" y1="5" x2="12" y2="19"></line>
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Confirm Add to Cart Footer -->
        <div class="p-6 border-t border-gray-900 bg-[#0f0f0f] shrink-0">
          <button @click="confirm"
                  class="w-full h-14 rounded-2xl bg-amber-500 hover:bg-amber-600 text-black font-black text-sm tracking-wider uppercase transition-all active:scale-95 shadow-lg shadow-amber-500/20 flex items-center justify-center gap-2">
            Thêm vào giỏ hàng
          </button>
        </div>

      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import type { MenuItem } from '@/types/customer';

const props = withDefaults(
  defineProps<{
    item: MenuItem | null;
    initialQuantity?: number;
    initialNote?: string;
  }>(),
  {
    initialQuantity: 1,
    initialNote: ''
  }
);

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'confirm', data: { itemId: string; quantity: number; note: string }): void;
}>();

const store = useCustomerStore();
const router = useRouter();

const qty = ref(props.initialQuantity);
const note = ref(props.initialNote);

watch(() => props.item, () => {
  qty.value = props.initialQuantity;
  note.value = props.initialNote;
});

function increase() {
  if (qty.value < 99) {
    qty.value++;
  }
}

function decrease() {
  if (qty.value > 1) {
    qty.value--;
  }
}

function confirm() {
  if (!props.item) return;
  emit('confirm', {
    itemId: props.item.id,
    quantity: qty.value,
    note: note.value.trim()
  });
}

function goToCart() {
  emit('close');
  router.push({ name: 'CustomerCart' });
}
</script>

<style scoped>
.modal-fade-enter-active, .modal-fade-leave-active {
  transition: opacity 0.25s ease;
}
.modal-fade-enter-from, .modal-fade-leave-to {
  opacity: 0;
}
</style>
