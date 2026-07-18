<!-- File: src/views/customer/SelectTable.vue -->
<template>
  <div class="flex flex-col items-center justify-center gap-6 w-full max-w-3xl p-6 min-h-[500px]">
    
    <!-- Top Header Navigation -->
    <div class="w-full max-w-2xl flex items-center justify-between border-b border-gray-800/80 pb-4 mb-4 shrink-0 relative">
      <button @click="emit('back')" 
              class="flex items-center gap-1.5 text-xs font-bold text-gray-500 hover:text-white bg-gray-900 border border-gray-800 px-3.5 py-2 rounded-xl transition-all active:scale-95 select-none animate-fade-in">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        {{ $t('customer.selectTable.back') }}
      </button>
      
      <!-- Dynamic Title based on selected area -->
      <h3 class="text-xl font-black text-white absolute left-1/2 transform -translate-x-1/2 tracking-wider select-none">
        {{ $t('customer.selectTable.title', { area: areaName }) }}
      </h3>
      
      <div class="w-20"></div> <!-- Placeholder spacer for header layout centering -->
    </div>

    <!-- Table Grid Selector Component -->
    <TableGrid :tables="tables" 
               :selected-table-id="selectedTableId" 
               @select="onSelectTable" />

    <!-- Centered Confirm Button at the bottom -->
    <div class="w-full max-w-xs flex justify-center mt-6">
      <button @click="emit('confirm')" 
              :disabled="!selectedTableId"
              class="w-full h-14 rounded-2xl bg-amber-500 hover:bg-amber-600 disabled:bg-gray-800 disabled:text-gray-500 disabled:border-transparent text-black border border-transparent font-black text-base transition-all active:scale-95 shadow-lg shadow-amber-500/10 disabled:shadow-none select-none uppercase tracking-widest">
        {{ $t('customer.selectTable.confirm') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import TableGrid from '@/components/customer/TableGrid.vue';
import type { Table } from '@/types/customer';

defineProps<{
  tables: Table[];
  selectedTableId: string | null;
  areaName: string;
}>();

const emit = defineEmits<{
  (e: 'select', table: Table): void;
  (e: 'confirm'): void;
  (e: 'back'): void;
}>();

function onSelectTable(table: Table) {
  emit('select', table);
}
</script>
