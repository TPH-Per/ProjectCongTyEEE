<template>
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
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useCRM } from '@/composables/useCRM'

const { fetchCustomerFeedback, loading } = useCRM()
const feedbacks = ref<any[]>([])

function formatDate(value?: string) {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('vi-VN')
}

onMounted(async () => {
  feedbacks.value = await fetchCustomerFeedback()
})
</script>
