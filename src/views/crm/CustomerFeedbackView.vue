<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-4 text-[hsl(var(--foreground))]">{{ $t('crm.feedback') }}</h1>
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-[hsl(var(--border))]">
      <div v-if="loading" class="text-[hsl(var(--muted-foreground))]">Loading feedback...</div>
      <div v-else-if="feedbacks.length === 0" class="text-[hsl(var(--muted-foreground))]">No feedback found.</div>
      <ul v-else class="space-y-4">
        <li v-for="fb in feedbacks" :key="fb.id" class="p-4 border rounded-xl border-gray-100 bg-gray-50/50">
          <div class="flex justify-between items-start mb-2">
            <div class="font-bold text-gray-800">Rating: {{ fb.overall_rating }}/5</div>
            <span class="text-xs text-gray-400">{{ new Date(fb.created_at).toLocaleDateString() }}</span>
          </div>
          <div class="text-sm text-gray-600 mb-2">{{ fb.comment || 'No comment provided.' }}</div>
          <div class="text-xs text-gray-500">Source: {{ fb.source }}</div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useCRM } from '@/composables/useCRM'
import { useI18n } from 'vue-i18n'

const { fetchCustomerFeedback, loading } = useCRM()
const feedbacks = ref<any[]>([])
const { t } = useI18n()

onMounted(async () => {
  try {
    feedbacks.value = await fetchCustomerFeedback()
  } catch (e) {
    console.error(e)
  }
})
</script>
