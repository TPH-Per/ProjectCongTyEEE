<template>
  <div class="feedback-manager p-4">
    <h1 class="text-2xl font-bold mb-4">Feedback Manager</h1>
    <div class="space-y-4">
      <div v-if="loading" class="text-gray-500">Loading...</div>
      <div v-else v-for="fb in feedbacks" :key="fb.id" class="border p-4 rounded bg-white shadow">
        <div class="flex justify-between">
          <p class="font-bold">Rating: {{ fb.rating }}/5</p>
          <span class="text-sm text-gray-500">{{ fb.status }}</span>
        </div>
        <p class="mt-2">{{ fb.comments || 'No comments' }}</p>
        <div v-if="fb.status === 'RECEIVED'" class="mt-2">
          <button @click="handleReply(fb.id)" class="text-blue-500 text-sm">Mark Responded</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useFeedback } from '@/composables/useFeedback'

const { feedbacks, loading, listFeedbacks, replyToFeedback } = useFeedback()

onMounted(async () => {
  await listFeedbacks()
})

const handleReply = async (id: string) => {
  await replyToFeedback(id, 'Thank you for your feedback.')
  await listFeedbacks()
}
</script>
