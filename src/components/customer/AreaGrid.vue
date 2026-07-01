<!-- File: src/components/customer/AreaGrid.vue -->
<template>
  <div class="grid grid-cols-2 gap-4 w-full max-w-2xl px-4">
    <button v-for="area in areas" :key="area.id"
            @click="selectArea(area.id)"
            :class="[
              'p-5 rounded-2xl border text-left transition-all duration-200 relative overflow-hidden group min-h-[90px] flex items-center gap-4 active:scale-95 shadow-md',
              selectedAreaId === area.id
                ? 'bg-amber-500/10 border-amber-500 text-amber-500 shadow-amber-500/5'
                : 'bg-[#161616] border-gray-800 text-gray-400 hover:border-gray-700 hover:text-white'
            ]">
      
      <!-- Glow effect for selected -->
      <div v-if="selectedAreaId === area.id" 
           class="absolute -top-10 -right-10 w-20 h-20 bg-amber-500/10 rounded-full blur-2xl pointer-events-none">
      </div>

      <!-- Icon -->
      <span class="text-3xl select-none shrink-0 bg-gray-900 border border-gray-800 w-12 h-12 rounded-xl flex items-center justify-center">
        {{ getAreaIcon(area.id) }}
      </span>

      <!-- Area Name -->
      <div class="flex-1 min-w-0">
        <h4 class="text-base font-extrabold text-white group-hover:text-amber-500 transition-colors truncate">
          {{ area.name }}
        </h4>
        <span class="text-[10px] text-gray-500 block mt-0.5">Mở danh sách bàn</span>
      </div>

      <!-- Active Indicator dot -->
      <span v-if="selectedAreaId === area.id" 
            class="w-2 h-2 rounded-full bg-amber-500 shrink-0">
      </span>
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Area } from '@/types/customer';

defineProps<{
  areas: Area[];
  selectedAreaId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
}>();

function selectArea(id: string) {
  emit('select', id);
}

function getAreaIcon(areaId: string): string {
  const areaLower = areaId.toLowerCase();
  if (areaLower.includes('vip')) return '🍷';
  if (areaLower.includes('a')) return '🅰️';
  if (areaLower.includes('b')) return '🅱️';
  if (areaLower.includes('c')) return '🇨';
  if (areaLower.includes('r')) return '🇷';
  if (areaLower.includes('t')) return '🇹';
  if (areaLower.includes('capichi')) return '🛵';
  if (areaLower.includes('shopee')) return '🧡';
  if (areaLower.includes('be')) return '💛';
  if (areaLower.includes('grab')) return '💚';
  if (areaLower.includes('catalog')) return '📖';
  return '🍽️';
}
</script>
