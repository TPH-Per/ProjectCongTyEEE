import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface CloseShiftPayload {
  shift_id: string
  closing_cash: number
  notes?: string
}

export interface CloseShiftResponse {
  shift_id: string
  cash_difference: number
  total_revenue: number
  total_cash: number
}

export interface ExportShiftCsvResponse {
  csv: string
  row_count: number
}

export function useShift() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function closeShift(
    payload: CloseShiftPayload,
  ): Promise<CloseShiftResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<CloseShiftPayload, CloseShiftResponse>(
        'close-shift',
        payload,
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  async function exportCsv(shiftId: string): Promise<ExportShiftCsvResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<{ shift_id: string }, ExportShiftCsvResponse>(
        'export-shift-csv',
        { shift_id: shiftId },
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, closeShift, exportCsv }
}
