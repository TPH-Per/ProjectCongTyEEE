import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface CheckoutResult {
  success: boolean
  bill_id: string
  invoice_id: string
  invoice_number: string
  grand_total: number
  linked_crm_surveys?: number
}

export interface CheckoutPreview {
  subtotal: number
  voucherDiscount: number
  pointsDiscount: number
  netBeforeTax: number
  vat: number
  grandTotal: number
}

export function useCheckout() {
  const checkoutResult = ref<CheckoutResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function previewCheckout(params: {
    orderId: string;
    voucherCode?: string;
    pointsToRedeem?: number;
    orderTotal: number;
    customerId?: string;
  }): Promise<CheckoutPreview> {
    void params
    throw new Error('previewCheckout is disabled; use hall_get_checkout_summary RPC for checkout totals')
  }

  async function executeCheckout(params: {
    orderId: string;
    paymentMethod: string;
    paymentRef?: string;
    voucherCode?: string;
    pointsToRedeem?: number;
    serviceChargePct?: number;
    vatPct?: number;
    branchId: string;
    cashierId: string;
  }): Promise<CheckoutResult> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('process_checkout', {
        p_order_id: params.orderId,
        p_branch_id: params.branchId,
        p_cashier_id: params.cashierId,
        p_payment_method: params.paymentMethod,
        p_voucher_code: params.voucherCode || null,
        p_points_to_use: params.pointsToRedeem || 0
      })
      if (err) throw err
      checkoutResult.value = data as any
      return data as any
    } catch (e: any) {
      error.value = e.message || String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  async function checkout(params: any): Promise<CheckoutResult | null> {
    if (!params?.branchId || !params?.cashierId || !params?.paymentMethod) {
      throw new Error('checkout requires branchId, cashierId and paymentMethod')
    }
    return executeCheckout({
      orderId: params.orderId,
      branchId: params.branchId,
      cashierId: params.cashierId,
      paymentMethod: params.paymentMethod,
      voucherCode: params.voucherCode,
      pointsToRedeem: params.pointsToRedeem,
      paymentRef: params.paymentRef,
      serviceChargePct: params.serviceChargePct,
      vatPct: params.vatPct,
    })
  }

  function printReceipt(result: CheckoutResult): void {
    console.log('Printing receipt for', result.invoice_number)
    window.print()
  }

  return {
    checkoutResult, loading, error,
    previewCheckout, executeCheckout, checkout, printReceipt
  }
}
