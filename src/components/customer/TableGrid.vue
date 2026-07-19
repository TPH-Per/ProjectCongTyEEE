<!-- File: src/components/customer/TableGrid.vue -->
<template>
  <div class="w-full max-w-2xl px-4 flex flex-col gap-6">
    
    <!-- Table Grid (4-5 columns) -->
    <div class="grid grid-cols-4 sm:grid-cols-5 gap-3 w-full">
      <button v-for="table in tables" :key="table.id"
              type="button"
              @click="selectTable(table)"
              :disabled="table.status === 'occupied'"
              :class="[
                'p-4 rounded-xl border text-center transition-all duration-200 min-h-[90px] flex flex-col justify-between items-center active:scale-95 select-none relative',
                
                // Selected Table Highlight
                selectedTableId === table.id
                  ? 'bg-amber-500/20 border-amber-500 text-amber-400 shadow-md shadow-amber-500/10 scale-105 z-10'
                  : '',
                  
                // Available Table Style
                table.status === 'available' && selectedTableId !== table.id
                  ? 'bg-emerald-950/10 border-emerald-500/30 text-emerald-400 hover:border-emerald-500 hover:bg-emerald-950/20'
                  : '',
                  
                // Selecting Table Style
                table.status === 'selecting' && selectedTableId !== table.id
                  ? 'bg-amber-950/10 border-amber-500/30 text-amber-500'
                  : '',
                  
                // Occupied Table Style (Disabled)
                table.status === 'occupied'
                  ? 'bg-[#121212] border-rose-950 text-rose-500/40 opacity-40 cursor-not-allowed'
                  : ''
              ]">
        
        <!-- Table Code + Lock Icon -->
        <div class="flex items-center justify-between w-full text-[10px] font-bold text-gray-500">
          <span>BÀN</span>
          <span v-if="table.status !== 'available'" class="text-[10px] shrink-0" title="Đã khóa">🔒</span>
        </div>

        <!-- Table Number (e.g. A01) -->
        <span class="text-lg font-black text-white py-1">
          {{ table.number }}
        </span>

        <!-- Capacity / Dot Status -->
        <div class="flex items-center justify-between w-full text-[9px] font-bold text-gray-500">
          <span>👥 {{ table.capacity }}</span>
          <span :class="[
            'w-1.5 h-1.5 rounded-full',
            table.status === 'available' ? 'bg-emerald-500' :
            table.status === 'selecting' ? 'bg-amber-500' :
            'bg-rose-500'
          ]"></span>
        </div>
      </button>
    </div>

    <!-- Status Legend (Chú thích) -->
    <div class="flex items-center justify-center gap-6 text-xs text-gray-400 border-t border-gray-900 pt-4 mt-2 select-none shrink-0">
      <div class="flex items-center gap-2">
        <span class="w-3 h-3 rounded-full bg-emerald-500 border border-emerald-600/30"></span>
        <span>Trống</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-3 h-3 rounded-full bg-amber-500 border border-amber-600/30"></span>
        <span>Đang chọn</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-3 h-3 rounded-full bg-rose-500 border border-rose-600/30"></span>
        <span>Có khách</span>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import type { Table } from '@/types/customer';

defineProps<{
  tables: Table[];
  selectedTableId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', table: Table): void;
}>();

function selectTable(table: Table) {
  if (table.status === 'occupied') return;
  emit('select', table);
}
</script>
