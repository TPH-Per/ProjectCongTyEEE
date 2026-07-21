import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { callEdgeFunction } from '@/utils/edge'

// NOTE: payload keys MUST match the Edge Function contract (camelCase):
// `supabase/functions/close-shift/index.ts` takes `{ shiftId, closingCash, notes }`
// `supabase/functions/open-shift/index.ts` takes `{ branchId, openingCash, notes }`
// `supabase/functions/export-shift-csv/index.ts` reads `?shiftId=<uuid>` from the
// URL (returns raw CSV text, not JSON).
export interface OpenShiftPayload {
  branchId: string
  openingCash: number
  notes?: Record<string, unknown>
}

export interface ShiftOpenResponse {
  ok: boolean
  idempotent?: boolean
  shift: {
    id: string
    branch_id: string
    user_id: string
    status: 'open' | 'closed'
    opened_at: string
    opening_cash: string | number
  }
}

export interface CloseShiftPayload {
  shiftId: string
  closingCash: number
  notes?: string
}

export interface CloseShiftResponse {
  ok?: boolean
  shift?: { id: string; closed_at: string }
  summary?: Record<string, { count: number; total: number }>
  expectedCash?: number
  closingCash?: number
  cashDifference?: number
  error?: string
}

export interface ExportShiftCsvResponse {
  csv: string
  rowCount: number
}

export function useShift() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function openShift(payload: OpenShiftPayload): Promise<ShiftOpenResponse> {
    loading.value = true
    error.value = null
    try {
      // 1. Try Edge Function first
      return await callEdgeFunction<OpenShiftPayload, ShiftOpenResponse>(
        'open-shift',
        payload,
      )
    } catch (edgeErr) {
      console.warn('[useShift] Edge Function open-shift failed, trying direct RPC:', edgeErr)
      // 2. Fallback: call shift_open RPC directly via Supabase client
      try {
        const { data, error: rpcErr } = await supabase.rpc('shift_open', {
          p_branch_id: payload.branchId,
          p_opening_cash: payload.openingCash,
          p_notes: payload.notes ?? {},
        })
        if (rpcErr) throw rpcErr
        if (!data) throw new Error('shift_open RPC returned no data')
        return data as ShiftOpenResponse
      } catch (rpcErr) {
        error.value = rpcErr instanceof Error ? rpcErr.message : String(rpcErr)
        throw rpcErr
      }
    } finally {
      loading.value = false
    }
  }

  async function closeShift(
    payload: CloseShiftPayload,
  ): Promise<CloseShiftResponse> {
    loading.value = true
    error.value = null
    try {
      const res = await callEdgeFunction<CloseShiftPayload, CloseShiftResponse>(
        'close-shift',
        payload,
      )
      // Edge Function may return 200 with { ok: false } for business errors
      // (e.g. unsettled orders)
      if (res && res.ok === false && res.error) {
        throw new Error(res.error)
      }
      return res
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e)
      // Provide a more helpful message for common failures
      if (msg.includes('Failed to fetch') || msg.includes('fetch')) {
        error.value = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.'
      } else if (msg.includes('unsettled_orders') || msg.includes('chưa thanh toán')) {
        error.value = msg
      } else {
        error.value = msg
      }
      throw e
    } finally {
      loading.value = false
    }
  }

  async function exportCsv(shiftId: string): Promise<string> {
    const { data: sessionData } = await supabase.auth.getSession()
    const token = sessionData.session?.access_token
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
    if (!token || !supabaseUrl) {
      throw new Error('Không có session — vui lòng đăng nhập lại.')
    }
    loading.value = true
    error.value = null
    try {
      const url = `${supabaseUrl}/functions/v1/export-shift-csv?shiftId=${encodeURIComponent(shiftId)}`
      const res = await fetch(url, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
          apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '',
        },
      })
      if (!res.ok) {
        const text = await res.text().catch(() => '')
        throw new Error(text || `Export CSV thất bại (HTTP ${res.status})`)
      }
      return await res.text()
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, openShift, closeShift, exportCsv }
}