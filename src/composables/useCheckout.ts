import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface CheckoutPayload {
  order_id: string
  payments: { method: string; amount: number; reference?: string }[]
  voucher_code?: string
  customer_tax_code?: string
}

export interface CheckoutResponse {
  invoice_id: string
  invoice_number: string
  total: number
  change_amount: number
  status: 'paid' | 'partial'
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
