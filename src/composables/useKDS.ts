import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface KDSPushPayload {
  order_item_ids: string[]
  station?: 'hot' | 'cold' | 'bar'
}

export interface KDSPushResponse {
  pushed: number
  station: string
  queued_at: string
}

export function useKDS() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function pushToKDS(payload: KDSPushPayload): Promise<KDSPushResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<KDSPushPayload, KDSPushResponse>(
        'kds-push',
        payload,
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, pushToKDS }
}
