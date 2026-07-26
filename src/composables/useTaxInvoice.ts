import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface IssueTaxInvoicePayload {
  invoice_id: string
  tax_code: string
  customer_company: string
  customer_address?: string
  customer_email?: string
}

export interface IssueTaxInvoiceResponse {
  invoice_id: string
  vt_invoice_id: string
  vt_serial: string
  vt_number: string
  status: 'issued' | 'failed'
  pdf_path?: string
  xml_url?: string
}

export function useTaxInvoice() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function issue(
    payload: IssueTaxInvoicePayload,
  ): Promise<IssueTaxInvoiceResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<IssueTaxInvoicePayload, IssueTaxInvoiceResponse>(
        'issue-tax-invoice',
        payload,
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, issue }
}
