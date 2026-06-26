import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

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
  ok: boolean
  invoiceId: string
  invoiceNumber: string
  total: number
  change: number
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
