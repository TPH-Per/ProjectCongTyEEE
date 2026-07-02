<!-- File: src/components/customer/ServiceRequestGrid.vue -->
<template>
  <div class="w-full max-w-xl px-4 flex flex-col gap-6 select-none">
    
    <!-- Title -->
    <h2 class="text-lg font-black text-white text-center font-serif tracking-wider mb-2">
      Bạn cần hỗ trợ gì?
    </h2>

    <!-- Grid of Request Types (2 columns) -->
    <div class="grid grid-cols-2 gap-4 w-full">
      <button v-for="option in requestOptions" :key="option.type"
              @click="selectType(option.type)"
              :class="[
                'p-5 rounded-2xl border text-center transition-all duration-200 flex flex-col items-center justify-center gap-2.5 min-h-[110px] active:scale-95 shadow-sm select-none',
                selectedType === option.type
                  ? 'bg-[#E8772E] border-[#E8772E] text-white shadow-md shadow-[#E8772E]/10'
                  : 'bg-white border-gray-200 text-[#333333] hover:bg-gray-50'
              ]">
        <span class="text-3xl select-none">{{ option.emoji }}</span>
        <span class="text-xs font-black">{{ option.label }}</span>
      </button>
    </div>

    <!-- Extra Text Input for "Other" or Notes -->
    <transition name="slide-fade">
      <div v-if="selectedType" class="bg-white border border-gray-200 rounded-2xl p-5 flex flex-col gap-4 shadow-md text-[#333333]">
        <h4 class="text-xs font-black text-[#333333] font-serif uppercase tracking-wider">
          {{ selectedType === 'other' ? 'Nhập chi tiết yêu cầu của bạn (Bắt buộc)' : 'Ghi chú thêm cho phục vụ (Tùy chọn)' }}
        </h4>
        
        <textarea v-model="content"
                  rows="3"
                  :placeholder="selectedType === 'other' ? 'Nhập yêu cầu tại đây... ví dụ: Lấy thêm thìa em bé' : 'Ghi chú thêm... ví dụ: Lấy cho anh khăn ướt lạnh'"
                  class="w-full bg-gray-50 border border-gray-250 focus:border-[#E8772E]/50 rounded-xl p-3 text-xs text-[#333333] placeholder-gray-400 focus:outline-none resize-none transition-colors">
        </textarea>

        <div class="flex justify-end gap-3 shrink-0">
          <button @click="cancelSelection" 
                  class="h-11 px-5 rounded-xl border border-gray-200 text-gray-500 hover:text-[#333333] font-bold text-xs transition-colors active:scale-95 bg-gray-50">
            Hủy bỏ
          </button>
          
          <button @click="submitRequest" 
                  :disabled="isSubmitDisabled"
                  class="h-11 px-6 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md">
            Gửi yêu cầu
          </button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import type { ServiceRequestType } from '@/types/customer';

const emit = defineEmits<{
  (e: 'submit', data: { type: ServiceRequestType; content: string }): void;
}>();

const selectedType = ref<ServiceRequestType | null>(null);
const content = ref('');

interface RequestOption {
  type: ServiceRequestType;
  label: string;
  emoji: string;
}

const requestOptions: RequestOption[] = [
  { type: 'tissue', label: 'Khăn giấy', emoji: '🧻' },
  { type: 'bowl', label: 'Chén/bát/đũa', emoji: '🥣' },
  { type: 'sauce', label: 'Nước chấm', emoji: '🧂' },
  { type: 'ice', label: 'Thêm đá', emoji: '🧊' },
  { type: 'grill_change', label: 'Thay vỉ nướng', emoji: '🍳' },
  { type: 'charcoal_change', label: 'Thay than', emoji: '🪵' },
  { type: 'request_bill', label: 'Tính tiền', emoji: '💵' },
  { type: 'call_waiter', label: 'Gọi phục vụ', emoji: '🙋‍♂️' },
  { type: 'other', label: 'Khác', emoji: '✍️' },
];

const isSubmitDisabled = computed(() => {
  if (!selectedType.value) return true;
  // BR-02/NV3-02: Other must have content
  if (selectedType.value === 'other') {
    return !content.value.trim();
  }
  return false;
});

function selectType(type: ServiceRequestType) {
  selectedType.value = type;
  content.value = '';
}

function cancelSelection() {
  selectedType.value = null;
  content.value = '';
}

function submitRequest() {
  if (isSubmitDisabled.value) return;
  emit('submit', {
    type: selectedType.value!,
    content: content.value.trim()
  });
  cancelSelection();
}
</script>

<style scoped>
.slide-fade-enter-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-fade-leave-active {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-fade-enter-from, .slide-fade-leave-to {
  transform: translateY(-10px);
  opacity: 0;
}
</style>
