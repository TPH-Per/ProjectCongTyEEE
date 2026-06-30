<template>
  <div class="campaigns-view">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">{{ $t('marketing.campaigns') }}</h1>
      <button class="bg-[hsl(var(--primary))] text-white px-4 py-2 rounded-xl font-semibold">
        Create Campaign
      </button>
    </div>
    <div class="bg-white rounded-2xl border border-[hsl(var(--border))] p-6">
      <div v-if="loading" class="text-[hsl(var(--muted-foreground))]">Loading campaigns...</div>
      <div v-else-if="campaigns.length === 0" class="text-[hsl(var(--muted-foreground))]">No active campaigns found. Create one to get started.</div>
      <ul v-else class="space-y-4">
        <li v-for="c in campaigns" :key="c.id" class="p-4 border rounded-xl border-gray-100 bg-gray-50/50">
          <div class="flex justify-between items-start mb-1">
            <div class="font-bold text-gray-800">{{ c.name }}</div>
            <span class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">{{ c.status }}</span>
          </div>
          <div class="text-sm text-gray-600 mb-2">{{ c.description || 'No description provided.' }}</div>
          <div class="text-xs text-gray-500">Type: {{ c.type }} • Budget: {{ c.budget }}</div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useMarketing } from '@/composables/useMarketing'
import { useI18n } from 'vue-i18n'

const { fetchCampaigns, loading } = useMarketing()
const campaigns = ref<any[]>([])
const { t } = useI18n()

onMounted(async () => {
  try {
    campaigns.value = await fetchCampaigns()
  } catch (e) {
    console.error(e)
  }
})
</script>
