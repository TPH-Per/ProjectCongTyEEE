<!-- File: src/components/customer/MenuSubcategoryBar.vue -->
<template>
  <div class="w-full overflow-x-auto scrollbar-hide py-3.5 px-6 md:px-8 bg-[#090909] border-b border-gray-900 shrink-0">
    <div class="flex items-center gap-3.5 min-w-max">
      <button v-for="sub in subcategories" :key="sub.id"
              @click="selectSub(sub.id)"
              :class="[
                'px-4 py-2 rounded-full font-bold text-xs md:text-sm transition-all duration-200 active:scale-95 select-none border',
                
                // Active subcategory state: Pink color (#b56576), white text
                selectedSubcategoryId === sub.id
                  ? 'bg-[#b56576] text-white border-[#b56576] shadow-md shadow-pink-500/10'
                  : 'bg-transparent text-gray-500 border-gray-850 hover:text-gray-300 hover:border-gray-800'
              ]">
        {{ sub.name }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { SubCategory } from '@/types/customer';

defineProps<{
  subcategories: SubCategory[];
  selectedSubcategoryId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
}>();

function selectSub(id: string) {
  emit('select', id);
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
</style>
