<template>
  <div class="space-y-4">
    <header class="flex flex-col gap-1 mb-6">
      <h1 class="text-2xl font-bold bg-gradient-to-r from-[#d4af37] to-[#f3e5ab] bg-clip-text text-transparent">{{ $t('crm.recentFeedback', 'Recent Feedback') }}</h1>
      <p class="text-sm text-white/50">{{ $t('crm.readCustomers', 'Read what customers are saying') }}</p>
    </header>

    <div v-if="error" class="rounded-xl border border-red-500/20 bg-red-500/10 p-4 text-sm font-semibold text-red-400">
      {{ error }}
    </div>
    
    <div v-if="loading && !feedbacks.length" class="space-y-4">
      <div v-for="i in 3" :key="i" class="flex gap-4">
        <div class="h-10 w-10 shrink-0 rounded-full bg-white/5 animate-pulse"></div>
        <div class="space-y-2 flex-1">
          <div class="h-4 w-1/3 bg-white/5 rounded animate-pulse"></div>
          <div class="h-16 w-full bg-white/5 rounded-2xl rounded-tl-none animate-pulse"></div>
        </div>
      </div>
    </div>

    <div v-else-if="!feedbacks.length" class="flex flex-col items-center justify-center py-16 text-center">
      <div class="mb-4 rounded-full bg-white/5 p-5">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </div>
      <p class="text-white/50 font-medium">{{ $t('crm.noFeedback', 'No feedback found.') }}</p>
    </div>

    <div v-else class="space-y-6">
      <div v-for="fb in feedbacks" :key="fb.survey_id" class="flex gap-3">
        <!-- Avatar -->
        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-[#d4af37]/20 to-[#f3e5ab]/10 border border-[#d4af37]/30 text-[#d4af37] font-bold">
          {{ fb.customer_name ? fb.customer_name.substring(0, 1).toUpperCase() : '?' }}
        </div>
        
        <!-- Bubble -->
        <div class="flex-1 space-y-1">
          <div class="flex items-baseline justify-between px-1">
            <span class="text-sm font-bold text-white/90">{{ fb.customer_name || $t('crm.anonymous', 'Anonymous') }}</span>
            <span class="text-[10px] font-semibold text-white/40">{{ formatDate(fb.created_at) }}</span>
          </div>
          
          <div class="rounded-2xl rounded-tl-none bg-white/5 p-4 border border-white/10 shadow-sm backdrop-blur-sm">
            <p class="text-sm text-white/80 leading-relaxed">{{ fb.feedback || $t('crm.noComment', 'No comment provided.') }}</p>
            <div v-if="fb.improvement_note" class="mt-3 pt-3 border-t border-white/10">
              <span class="text-xs font-bold text-[#d4af37] uppercase tracking-wider block mb-1">To Improve</span>
              <p class="text-xs text-white/60">{{ fb.improvement_note }}</p>
            </div>
          </div>
          
          <div class="flex gap-2 px-1 pt-1">
            <span v-if="fb.visit_reason" class="text-[10px] font-bold text-white/50 uppercase bg-white/5 px-2 py-0.5 rounded-full border border-white/10">
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
