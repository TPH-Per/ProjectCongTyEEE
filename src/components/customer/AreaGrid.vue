<template>
  <div class="w-full max-w-2xl px-4 flex flex-col gap-4">

    <!-- Stats Summary -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 w-full shrink-0">
      <div class="bg-[#161616] border border-gray-800 rounded-xl p-3 text-center">
        <p class="text-[9px] text-gray-500 uppercase tracking-wider mb-1">{{ $t('customer.selectArea.totalAreas') }}</p>
        <p class="text-xl font-black text-white">{{ areas.length }}</p>
      </div>
      <div class="bg-[#161616] border border-gray-800 rounded-xl p-3 text-center">
        <p class="text-[9px] text-gray-500 uppercase tracking-wider mb-1">{{ $t('customer.selectArea.totalTables') }}</p>
        <p class="text-xl font-black text-amber-500">{{ totalTables }}</p>
      </div>
      <div class="bg-[#161616] border border-gray-800 rounded-xl p-3 text-center">
        <p class="text-[9px] text-gray-500 uppercase tracking-wider mb-1">{{ $t('customer.selectArea.availableTables') }}</p>
        <p class="text-xl font-black text-emerald-500">{{ availableCount }}</p>
      </div>
      <div class="bg-[#161616] border border-gray-800 rounded-xl p-3 text-center">
        <p class="text-[9px] text-gray-500 uppercase tracking-wider mb-1">{{ $t('customer.selectArea.occupiedTables') }}</p>
        <p class="text-xl font-black text-rose-500">{{ occupiedCount }}</p>
      </div>
    </div>

    <!-- Area Grid -->
    <div class="grid grid-cols-2 gap-4 w-full">
      <button v-for="area in areas" :key="area.id"
              type="button"
              @click="selectArea(area.id)"
              :class="[
                'p-4 rounded-2xl border text-left transition-all duration-200 relative overflow-hidden group min-h-[100px] flex flex-col gap-3 active:scale-95 shadow-md',
                selectedAreaId === area.id
                  ? 'bg-amber-500/10 border-amber-500 text-amber-500 shadow-amber-500/5'
                  : 'bg-[#161616] border-gray-800 text-gray-400 hover:border-gray-700 hover:text-white'
              ]">

        <!-- Glow effect for selected -->
        <div v-if="selectedAreaId === area.id"
             class="absolute -top-10 -right-10 w-20 h-20 bg-amber-500/10 rounded-full blur-2xl pointer-events-none">
        </div>

        <!-- Header: Icon + Name + Table Count -->
        <div class="flex items-center gap-3">
          <span class="text-2xl select-none shrink-0 bg-gray-900 border border-gray-800 w-11 h-11 rounded-xl flex items-center justify-center">
            {{ getAreaIcon(area.id) }}
          </span>

          <div class="flex-1 min-w-0">
            <h4 class="text-base font-extrabold text-white group-hover:text-amber-500 transition-colors truncate">
              {{ area.name }}
            </h4>
            <span class="text-[10px] text-gray-500 block mt-0.5">
              {{ area.tables.length }} {{ $t('customer.selectArea.tables') }}
            </span>
          </div>

          <!-- Active Indicator dot -->
          <span v-if="selectedAreaId === area.id"
                class="w-2 h-2 rounded-full bg-amber-500 shrink-0">
          </span>
        </div>

        <!-- Table Preview Chips -->
        <div v-if="area.tables.length > 0" class="flex flex-wrap gap-1.5">
          <span v-for="table in area.tables.slice(0, 6)" :key="table.id"
                :class="[
                  'px-2 py-0.5 rounded-md text-[10px] font-bold border',
                  table.status === 'available'
                    ? 'bg-emerald-950/30 text-emerald-500/70 border-emerald-900/50'
                    : 'bg-rose-950/30 text-rose-500/70 border-rose-900/50'
                ]">
            {{ table.number }}
          </span>
          <span v-if="area.tables.length > 6"
                class="px-2 py-0.5 rounded-md text-[10px] font-bold text-gray-500">
            +{{ area.tables.length - 6 }}
          </span>
        </div>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { Area } from '@/types/customer';

const props = defineProps<{
  areas: Area[];
  selectedAreaId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
}>();

const totalTables = computed(() =>
  props.areas.reduce((sum, area) => sum + area.tables.length, 0)
);

const availableCount = computed(() =>
  props.areas.reduce(
    (sum, area) => sum + area.tables.filter(t => t.status === 'available').length,
    0
  )
);

const occupiedCount = computed(() =>
  props.areas.reduce(
    (sum, area) => sum + area.tables.filter(t => t.status !== 'available').length,
    0
  )
);

function selectArea(id: string) {
  emit('select', id);
}

const areaIconMap: Record<string, string> = {
  'area_a': '🅰️',
  'area_b': '🅱️',
  'area_c': '🇨',
  'area_r': '🇷',
  'area_t': '🇹',
  'area_capichi': '🛵',
  'area_shopee': '🧡',
  'area_be': '💛',
  'area_grab': '💚',
  'area_catalog': '📖',
  'zone-a': '🅰️',
  'zone-b': '🅱️',
  'zone-c': '🇨',
  'zone-r': '🇷',
  'zone-t': '🇹',
};

function getAreaIcon(areaId: string): string {
  return areaIconMap[areaId.toLowerCase()] || '🍽️';
}
</script>
