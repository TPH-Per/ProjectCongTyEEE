<!-- File: src/views/customer/FeedbackPopup.vue -->
<template>
  <div class="bg-white border border-gray-200 rounded-3xl p-6 md:p-8 w-full max-w-lg shadow-2xl relative flex flex-col gap-6 text-[#333333] select-none">
    
    <!-- Top-right skip button -->
    <button @click="emit('skip')" 
            class="absolute top-4 right-4 text-xs font-bold text-gray-400 hover:text-[#333333] px-3 py-1.5 rounded-lg transition-all active:scale-95 select-none">
      {{ $t('customer.feedback.skip') }}
    </button>

    <div class="text-center pt-2">
      <h3 class="text-xl font-black text-[#333333] mb-1.5 font-serif tracking-wide">{{ $t('customer.feedback.title') }}</h3>
      <p class="text-xs text-gray-500">{{ $t('customer.feedback.subtitle') }}</p>
    </div>

    <!-- Star Rating Selector -->
    <div class="flex justify-center border-b border-gray-150 pb-5">
      <StarRating :rating="rating" @update:rating="onRatingUpdate" />
    </div>

    <!-- Criteria selection (only show if rating is specified) -->
    <div v-if="rating > 0" class="flex flex-col gap-3">
      <h4 class="text-xs font-black text-gray-400 uppercase tracking-widest text-center">
        {{ $t('customer.feedback.bestAbout') }}
      </h4>
      <FeedbackCriteria :selected-criteria="criteria" @update:selected-criteria="onCriteriaUpdate" />
    </div>

    <!-- Comments input -->
    <div v-if="rating > 0" class="flex flex-col gap-1.5">
      <h4 class="text-xs font-bold text-[#666666] uppercase tracking-wider">
        {{ $t('customer.feedback.commentLabel') }}
      </h4>
      <textarea v-model="comment"
                rows="2"
                :placeholder="$t('customer.feedback.commentPlaceholder')"
                class="w-full bg-gray-50 border border-gray-250 focus:border-[#E8772E]/50 rounded-xl p-3 text-xs text-[#333333] placeholder-gray-455 focus:outline-none resize-none transition-colors">
      </textarea>
    </div>

    <!-- Actions Buttons -->
    <div class="flex justify-end gap-3 shrink-0 pt-2 border-t border-gray-100">
      <button @click="emit('skip')" 
              class="h-11 px-5 rounded-xl border border-gray-200 text-gray-500 hover:text-[#333333] font-bold text-xs transition-colors active:scale-95 select-none bg-gray-50">
        {{ $t('customer.feedback.skip') }}
      </button>
      
      <button @click="submit" 
              :disabled="isSubmitDisabled"
              class="h-11 px-6 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md select-none">
        {{ $t('customer.feedback.confirm') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import StarRating from '@/components/customer/StarRating.vue';
import FeedbackCriteria from '@/components/customer/FeedbackCriteria.vue';

const emit = defineEmits<{
  (e: 'submit', data: { rating: number; criteria: string[]; comment: string }): void;
  (e: 'skip'): void;
}>();

const rating = ref(0);
const criteria = ref<string[]>([]);
const comment = ref('');

// BR-35: Rating 1-5, BR-36: at least 1 criterion selected
const isSubmitDisabled = computed(() => {
  return rating.value < 1 || rating.value > 5 || criteria.value.length < 1;
});

function onRatingUpdate(val: number) {
  rating.value = val;
  // If rating is updated and criteria is empty, initialize default
  if (criteria.value.length === 0) {
    criteria.value = [];
  }
}

function onCriteriaUpdate(val: string[]) {
  criteria.value = val;
}

function submit() {
  if (isSubmitDisabled.value) return;
  emit('submit', {
    rating: rating.value,
    criteria: criteria.value,
    comment: comment.value.trim()
  });
}
</script>
