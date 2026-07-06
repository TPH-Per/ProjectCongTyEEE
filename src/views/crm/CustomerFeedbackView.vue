<template>
  <div class="space-y-4">
    <header class="flex flex-col gap-1 mb-6">
      <h1 class="text-2xl font-bold text-gray-900">{{ $t('crm.recentFeedback', 'Recent Feedback') }}</h1>
      <p class="text-sm text-gray-500">{{ $t('crm.readCustomers', 'Read what customers are saying') }}</p>
    </header>

    <div v-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
      {{ error }}
    </div>
    
    <div v-if="loading && !feedbacks.length" class="space-y-4">
      <div v-for="i in 3" :key="i" class="flex gap-4">
        <div class="h-10 w-10 shrink-0 rounded-full bg-gray-100 animate-pulse"></div>
        <div class="space-y-2 flex-1">
          <div class="h-4 w-1/3 bg-gray-100 rounded animate-pulse"></div>
          <div class="h-16 w-full bg-gray-100 rounded-2xl rounded-tl-none animate-pulse"></div>
        </div>
      </div>
    </div>

    <div v-else-if="!feedbacks.length" class="flex flex-col items-center justify-center py-16 text-center">
      <div class="mb-4 rounded-full bg-gray-50 p-5">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </div>
      <p class="text-gray-500 font-medium">{{ $t('crm.noFeedback', 'No feedback found.') }}</p>
    </div>

    <div v-else class="space-y-6">
      <div v-for="fb in feedbacks" :key="fb.survey_id" class="flex gap-3">
        <!-- Avatar -->
        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary font-bold">
          {{ fb.customer_name ? fb.customer_name.substring(0, 1).toUpperCase() : '?' }}
        </div>
        
        <!-- Bubble -->
        <div class="flex-1 space-y-1">
          <div class="flex items-baseline justify-between px-1">
            <span class="text-sm font-bold text-gray-900">{{ fb.customer_name || $t('crm.anonymous', 'Anonymous') }}</span>
            <span class="text-[10px] font-semibold text-gray-400">{{ formatDate(fb.created_at) }}</span>
          </div>
          
          <div class="rounded-2xl rounded-tl-none bg-gray-50 p-4 border border-gray-100 shadow-sm">
            <p class="text-sm text-gray-700 leading-relaxed">{{ fb.feedback || $t('crm.noComment', 'No comment provided.') }}</p>
            <div v-if="fb.improvement_note" class="mt-3 pt-3 border-t border-gray-200">
              <span class="text-xs font-bold text-primary uppercase tracking-wider block mb-1">To Improve</span>
              <p class="text-xs text-gray-600">{{ fb.improvement_note }}</p>
            </div>
          </div>
          
          <div class="flex gap-2 px-1 pt-1">
            <span v-if="fb.visit_reason" class="text-[10px] font-bold text-gray-500 uppercase bg-gray-100 px-2 py-0.5 rounded-full">
              {{ fb.visit_reason }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const feedbacks = ref<any[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

async function fetchFeedback() {
  loading.value = true
  try {
    const { data, error: err } = await supabase
      .from('crm_surveys')
      .select('survey_id, table_id, customer_name, visit_reason, feedback, improvement_note, created_at')
      .order('created_at', { ascending: false })
      .limit(50)
      
    if (err) throw err
    feedbacks.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchFeedback()
})

function formatDate(iso: string) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}
</script>
