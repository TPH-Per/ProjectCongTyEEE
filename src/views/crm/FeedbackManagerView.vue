<template>
<<<<<<< ours
  <div class="space-y-4 p-4">
    <header>
      <h1 class="text-2xl font-bold text-gray-900">Feedback Manager</h1>
      <p class="text-sm text-gray-500">Customer feedback captured from tablet, QR, staff entry, or CRM survey.</p>
    </header>

    <div class="rounded-lg border border-gray-200 bg-white">
      <div v-if="loading" class="p-6 text-sm text-gray-500">Loading...</div>
      <div v-else-if="feedbacks.length === 0" class="p-6 text-sm text-gray-500">No feedback found.</div>
      <div v-else class="divide-y divide-gray-100">
        <article v-for="fb in feedbacks" :key="fb.id" class="p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="font-black text-gray-900">Rating: {{ fb.overall_rating ?? fb.rating ?? '-' }}/5</div>
              <div class="mt-1 text-sm text-gray-600">{{ fb.comment || 'No comment' }}</div>
            </div>
            <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-xs font-bold text-gray-600">
              {{ fb.source || 'CRM' }}
            </span>
          </div>
          <div class="mt-3 text-xs text-gray-400">
            {{ formatDate(fb.created_at) }}
          </div>
        </article>
=======
  <div class="feedback-manager p-4">
    <h1 class="text-2xl font-bold mb-4">Feedback Manager</h1>
    <div class="space-y-4">
      <div v-if="loading" class="text-gray-500">Loading...</div>
      <div v-else v-for="fb in feedbacks" :key="fb.id" class="border p-4 rounded bg-white shadow">
        <div class="flex justify-between">
          <p class="font-bold">Rating: {{ fb.overall_rating }}/5</p>
          <span class="text-sm text-gray-500">{{ fb.staff_response ? 'RESPONDED' : 'RECEIVED' }}</span>
        </div>
        <p class="mt-2">{{ fb.comment || 'No comments' }}</p>
        <div v-if="!fb.staff_response" class="mt-2">
          <button @click="handleReply(fb.id)" class="text-blue-500 text-sm">Mark Responded</button>
        </div>
>>>>>>> theirs
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useCRM } from '@/composables/useCRM'

const { fetchCustomerFeedback, loading } = useCRM()
const feedbacks = ref<any[]>([])

<<<<<<< ours
function formatDate(value?: string) {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('vi-VN')
}

onMounted(async () => {
  feedbacks.value = await fetchCustomerFeedback()
})
=======
const { feedbacks, loading, listFeedback, replyToFeedback } = useFeedback()

onMounted(async () => {
  await listFeedback()
})

const handleReply = async (id: string) => {
  await replyToFeedback(id, 'Thank you for your feedback.')
  await listFeedback()
}
>>>>>>> theirs
</script>
