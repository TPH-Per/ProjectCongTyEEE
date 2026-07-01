<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ $t('bod.approvals') }}</h1>
        <p class="text-sm text-gray-500 mt-1">Pending requests requiring Board of Directors approval.</p>
      </div>
    </div>

    <div class="kawaii-card kawaii-shadow overflow-hidden">
      <table class="w-full text-left text-sm text-gray-600">
        <thead class="bg-gray-50 text-xs uppercase text-gray-500 border-b border-gray-100">
          <tr>
            <th class="px-6 py-4 font-semibold">Request Title</th>
            <th class="px-6 py-4 font-semibold">Type</th>
            <th class="px-6 py-4 font-semibold">Status</th>
            <th class="px-6 py-4 font-semibold text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 bg-white">
          <tr v-if="loading">
            <td colspan="4" class="px-6 py-4 text-center text-gray-500">Loading approvals...</td>
          </tr>
          <tr v-else-if="approvals.length === 0">
            <td colspan="4" class="px-6 py-4 text-center text-gray-500">No pending approvals.</td>
          </tr>
          <tr v-else v-for="app in approvals" :key="app.id" class="hover:bg-gray-50/50 transition-colors">
            <td class="px-6 py-4 font-medium text-gray-800">{{ app.title || 'Untitled Request' }}</td>
            <td class="px-6 py-4">{{ app.entity_type }}</td>
            <td class="px-6 py-4">
              <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                :class="{
                  'bg-yellow-100 text-yellow-800': app.status === 'PENDING',
                  'bg-green-100 text-green-800': app.status === 'APPROVED',
                  'bg-red-100 text-red-800': app.status === 'REJECTED'
                }">
                {{ app.status }}
              </span>
            </td>
            <td class="px-6 py-4 text-right">
              <button class="kawaii-btn-primary py-1.5 px-4 text-xs rounded-xl text-white font-semibold shadow-sm transition hover:brightness-105 active:scale-95 bg-[hsl(var(--primary))]">Review</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useBOD } from '@/composables/useBOD'
import { useI18n } from 'vue-i18n'

const { fetchBODApprovals, loading } = useBOD()
const approvals = ref<any[]>([])
const { t } = useI18n()

onMounted(async () => {
  try {
    approvals.value = await fetchBODApprovals()
  } catch (e) {
    console.error(e)
  }
})
</script>
