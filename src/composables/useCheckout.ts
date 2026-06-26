import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

// NOTE: payload keys MUST match the Edge Function `checkout` contract
// which uses camelCase (`orderId`, `revenueType`, `voucherCode`, ...).
// See `supabase/functions/checkout/index.ts`.
//
// `receivedAmount` is required for cash payments so the function can compute
// the change; `reference` is free-text (card last-4 / transfer ref / etc).
export interface CheckoutPayload {
  orderId: string
  revenueType: 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'
  customerId?: string
  voucherCode?: string
  taxCode?: string
  customerCompany?: string
  customerAddress?: string
  payments: {
    method: 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
    amount: number
    receivedAmount?: number
    reference?: string
  }[]
  notes?: string
}

export interface CheckoutResponse {
  invoiceId: string
  invoiceNumber: string
  total: number
  change: number
  ok?: boolean
}

export function useCheckout() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function checkout(payload: CheckoutPayload): Promise<CheckoutResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<CheckoutPayload, CheckoutResponse>(
        'checkout',
        payload,
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, checkout }
}
