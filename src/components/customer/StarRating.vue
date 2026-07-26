<!-- File: src/components/customer/StarRating.vue -->
<template>
  <div class="flex flex-col items-center gap-3">
    <!-- Star Row -->
    <div class="flex items-center gap-3.5">
      <button v-for="star in 5" :key="star"
              type="button"
              @click="setRating(star)"
              @mouseenter="hoverRating = star"
              @mouseleave="hoverRating = 0"
              class="transition-all duration-150 transform hover:scale-125 focus:outline-none select-none">
        <svg xmlns="http://www.w3.org/2000/svg" 
             :class="[
               'w-12 h-12',
               isStarred(star) ? 'text-amber-500 fill-amber-500 filter drop-shadow-[0_0_8px_rgba(245,158,11,0.4)]' : 'text-gray-700'
             ]" 
             viewBox="0 0 24 24" 
             fill="none" 
             stroke="currentColor" 
             stroke-width="1.5" 
             stroke-linecap="round" 
             stroke-linejoin="round">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
        </svg>
      </button>
    </div>

    <!-- Rating Label Description -->
    <span class="text-sm font-bold text-amber-500 mt-1 min-h-[20px]">
      {{ getRatingLabel(hoverRating || rating) }}
    </span>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useI18nStore } from '@/stores/i18n';

const i18nStore = useI18nStore();
const t = i18nStore.t;

const props = withDefaults(
  defineProps<{
    rating: number;
  }>(),
  {
    rating: 0
  }
);

const emit = defineEmits<{
  (e: 'update:rating', value: number): void;
}>();

const hoverRating = ref(0);

function setRating(val: number) {
  emit('update:rating', val);
}

function isStarred(star: number): boolean {
  if (hoverRating.value > 0) {
    return star <= hoverRating.value;
  }
  return star <= props.rating;
}

function getRatingLabel(val: number): string {
  if (val >= 1 && val <= 5) {
    return t(`customer.feedback.ratingNames.${val}`);
  }
  return '';
}
</script>
