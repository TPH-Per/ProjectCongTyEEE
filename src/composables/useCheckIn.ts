import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface CheckInWalkIn {
  party_size: number
  customer?: { name?: string; phone?: string }
  zone_id?: string
  table_id?: string
}

export interface CheckInPayload {
  reservation_id?: string
  walk_in?: CheckInWalkIn
}

export interface CheckInResponse {
  reservation_id: string
  table_assignment_id: string
  status: 'Arrived' | 'Dining'
}

/**
 * Wraps the `check-in` Edge Function (POST /functions/v1/check-in).
 *
 * Either `reservation_id` (for guests with a booking) or `walk_in` (for
 * walk-in guests) must be provided. Returns the assignment id so the
 * caller can navigate the waiter straight to the table.
 */
export function useCheckIn() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function checkIn(payload: CheckInPayload): Promise<CheckInResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<CheckInPayload, CheckInResponse>(
        'check-in',
        payload,
      )
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e)
      error.value = message
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, checkIn }
}
