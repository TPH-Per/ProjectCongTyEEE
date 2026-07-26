<!-- File: src/components/customer/FeedbackCriteria.vue -->
<template>
  <div class="w-full">
    <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
      <button v-for="criterion in criteriaOptions" :key="criterion.key"
              type="button"
              @click="toggleCriterion(criterion.key)"
              :class="[
                'px-4 py-3 rounded-xl border font-bold text-xs md:text-sm transition-all duration-200 active:scale-95 flex items-center justify-center gap-2 select-none text-center',
                selectedCriteria.includes(criterion.key)
                  ? 'bg-[#E8772E] border-[#E8772E] text-white shadow shadow-[#E8772E]/10'
                  : 'bg-white border-gray-200 text-[#333333] hover:bg-gray-50'
              ]">
        <span class="text-base">{{ criterion.icon }}</span>
        {{ $t(criterion.label) }}
      </button>
    </div>
    
    <!-- Error/Helper text -->
    <p class="text-[11px] text-gray-500 mt-3 text-center">
      {{ $t('customer.feedback.requireCriteria') }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useI18nStore } from '@/stores/i18n';

const i18nStore = useI18nStore();
const t = i18nStore.t;

const props = withDefaults(
  defineProps<{
    selectedCriteria: string[];
  }>(),
  {
    selectedCriteria: () => []
  }
);

const emit = defineEmits<{
  (e: 'update:selectedCriteria', value: string[]): void;
}>();

interface CriterionOption {
  key: string;
  label: string;
  icon: string;
}

const criteriaOptions: CriterionOption[] = [
  { key: 'food_quality', label: 'customer.feedback.criteria.foodQuality', icon: '🥩' },
  { key: 'service_time', label: 'customer.feedback.criteria.serviceTime', icon: '⚡' },
  { key: 'hygiene', label: 'customer.feedback.criteria.hygiene', icon: '✨' },
  { key: 'staff_attitude', label: 'customer.feedback.criteria.staffAttitude', icon: '😊' },
  { key: 'value_for_money', label: 'customer.feedback.criteria.valueForMoney', icon: '🏷️' },
  { key: 'ambiance', label: 'customer.feedback.criteria.ambiance', icon: '🛋️' }
];

function toggleCriterion(key: string) {
  const updated = [...props.selectedCriteria];
  const index = updated.indexOf(key);
  if (index > -1) {
    updated.splice(index, 1);
  } else {
    updated.push(key);
  }
  emit('update:selectedCriteria', updated);
}
</script>
