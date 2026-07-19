<!-- File: src/components/customer/BranchGrid.vue -->
<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-2xl px-4">
    <button v-for="branch in branches" :key="branch.id"
            type="button"
            @click="selectBranch(branch.id)"
            :class="[
              'p-5 rounded-2xl border text-left transition-all duration-200 relative overflow-hidden group min-h-[120px] flex items-center gap-4 active:scale-95 shadow-md',
              selectedBranchId === branch.id
                ? 'bg-amber-500/10 border-amber-500 text-amber-500 shadow-amber-500/5'
                : 'bg-[#161616] border-gray-800 text-gray-400 hover:border-gray-700 hover:text-white'
            ]">

      <!-- Glow effect for selected -->
      <div v-if="selectedBranchId === branch.id"
           class="absolute -top-10 -right-10 w-20 h-20 bg-amber-500/10 rounded-full blur-2xl pointer-events-none">
      </div>

      <!-- Icon -->
      <span class="text-3xl select-none shrink-0 bg-gray-900 border border-gray-800 w-12 h-12 rounded-xl flex items-center justify-center">
        🏢
      </span>

      <!-- Branch Info -->
      <div class="flex-1 min-w-0">
        <h4 class="text-base font-extrabold text-white group-hover:text-amber-500 transition-colors truncate">
          {{ branch.name }}
        </h4>
        <span v-if="branch.address" class="text-[10px] text-gray-500 block mt-0.5 truncate">
          {{ branch.address }}
        </span>
        <span v-if="branch.phone" class="text-[10px] text-gray-600 block mt-0.5">
          📞 {{ branch.phone }}
        </span>
      </div>

      <!-- Active Indicator dot -->
      <span v-if="selectedBranchId === branch.id"
            class="w-2 h-2 rounded-full bg-amber-500 shrink-0">
      </span>
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Branch } from '@/types/customer';

defineProps<{
  branches: Branch[];
  selectedBranchId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', id: string): void;
}>();

function selectBranch(id: string) {
  emit('select', id);
}
</script>
