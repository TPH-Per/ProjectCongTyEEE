<!-- File: src/views/customer/Feedback.vue -->
<template>
  <div class="w-full h-full flex flex-col items-center justify-center p-6 bg-gradient-to-br from-[#0c0c0c] to-[#050505]">
    
    <transition name="fade-scale" mode="out-in">
      <!-- State 1: Feedback Form -->
      <div v-if="subView === 'feedback'" class="w-full flex justify-center">
        <FeedbackPopup @submit="onFeedbackSubmit" @skip="onFeedbackSkip" />
      </div>

      <!-- State 2: Session Ended Goodbye -->
      <div v-else-if="subView === 'goodbye'" class="w-full flex justify-center">
        <SessionEnd @done="onSessionEndDone" />
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import FeedbackPopup from './FeedbackPopup.vue';
import SessionEnd from './SessionEnd.vue';

const store = useCustomerStore();
const router = useRouter();

const subView = ref<'feedback' | 'goodbye'>('feedback');

onMounted(() => {
  // BR-09: Require active session to view feedback
  if (!store.session) {
    router.push({ name: 'CustomerHome' });
  }
});

async function onFeedbackSubmit(data: { rating: number; criteria: string[]; comment: string }) {
  try {
    // BR-35/36/37/38 logic handled in store actions
    await store.submitFeedback(data as { rating: 1 | 2 | 3 | 4 | 5; criteria: string[]; comment: string });
  } catch (e) {
    console.error('Feedback submit failed', e);
  }
  
  // Finalize session & release table
  await finalizeAndExit();
}

async function onFeedbackSkip() {
  // Finalize session & release table
  await finalizeAndExit();
}

async function finalizeAndExit() {
  try {
    await store.endSession();
    subView.value = 'goodbye';
  } catch (e) {
    console.error('Session end failed', e);
    // fallback
    subView.value = 'goodbye';
  }
}

function onSessionEndDone() {
  router.push({ name: 'CustomerHome' });
}
</script>

<style scoped>
.fade-scale-enter-active, .fade-scale-leave-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-scale-enter-from {
  opacity: 0;
  transform: scale(0.96);
}
.fade-scale-leave-to {
  opacity: 0;
  transform: scale(1.04);
}
</style>
