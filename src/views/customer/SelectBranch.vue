<!-- File: src/views/customer/SelectBranch.vue -->
<template>
  <div class="flex flex-col items-center justify-center gap-6 w-full max-w-3xl p-6 min-h-[500px]">

    <!-- Top Header Navigation -->
    <div class="w-full max-w-2xl flex items-center justify-between border-b border-gray-800/80 pb-4 mb-4 shrink-0 relative">
      <button @click="emit('back')"
              type="button"
              class="flex items-center gap-1.5 text-xs font-bold text-gray-500 hover:text-white bg-gray-900 border border-gray-800 px-3.5 py-2 rounded-xl transition-all active:scale-95 select-none">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        {{ $t('customer.selectBranch.back') }}
      </button>
      <h3 class="text-xl font-black text-white absolute left-1/2 transform -translate-x-1/2 tracking-wider select-none">{{ $t('customer.selectBranch.title') }}</h3>
      <div class="w-20"></div> <!-- Placeholder spacer for header layout centering -->
    </div>

    <!-- Branch Grid Selector -->
    <BranchGrid :branches="branches"
                :selected-branch-id="selectedBranchId"
                @select="onSelectBranch" />
  </div>
</template>

<script setup lang="ts">
import BranchGrid from '@/components/customer/BranchGrid.vue';
import type { Branch } from '@/types/customer';

defineProps<{
  branches: Branch[];
  selectedBranchId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
  (e: 'back'): void;
}>();

function onSelectBranch(id: string) {
  emit('select', id);
}
</script>
