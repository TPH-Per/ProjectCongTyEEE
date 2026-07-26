<!-- File: src/components/customer/MenuCategoryBar.vue -->
<template>
  <div class="w-full overflow-x-auto scrollbar-hide py-4 px-6 md:px-8 border-b border-gray-800 shrink-0 bg-[#111111]">
    <div class="flex items-center gap-3 min-w-max">
      <button v-for="cat in categories" :key="cat.id"
              @click="selectCategory(cat.id)"
              :class="[
                'px-5 py-3 rounded-xl font-black text-xs md:text-sm transition-all duration-200 active:scale-95 flex items-center gap-2 select-none border',
                
                // Active category state: Yellow background (#f5a623), black text, and solid white border
                selectedCategoryId === cat.id
                  ? 'bg-[#f5a623] text-black border-white border-2 shadow-lg shadow-amber-500/10 scale-102 font-extrabold'
                  : 'bg-[#181818] border-gray-800 text-gray-400 hover:text-white hover:border-gray-700'
              ]">
        <span class="text-base">
          {{ getCategoryEmoji(cat.id) }}
        </span>
        {{ cat.name }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MenuCategory } from '@/types/customer';

defineProps<{
  categories: MenuCategory[];
  selectedCategoryId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
}>();

function selectCategory(id: string) {
  emit('select', id);
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
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
