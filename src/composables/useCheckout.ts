import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface CheckoutResult {
  success: boolean
  bill_id: string
  invoice_id: string
  invoice_number: string
  grand_total: number
  linked_crm_surveys?: number
  subtotal?: number
  discount_total?: number
  voucher_discount?: number
  points_discount?: number
  service_charge_amount?: number
  vat_amount?: number
}

export interface CheckoutTotals {
  subtotal: number
  tier_discount: number
  voucher_discount: number
  points_discount: number
  total_discount: number
  net_before_tax: number
  service_charge_percent: number
  service_charge_amount: number
  vat_rate: number
  vat_amount: number
  grand_total: number
}

export interface CheckoutPreview {
  ok: boolean
  order?: Record<string, unknown>
  table?: Record<string, unknown>
  items?: Array<Record<string, unknown>>
  totals: CheckoutTotals
  voucher_valid: boolean
  error?: string
}

export function useCheckout() {
  const checkoutResult = ref<CheckoutResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  /**
   * Preview the EXACT totals process_checkout will compute. Frontend display
   * matches the eventual bill byte-for-byte — no more 10% UI vs 8% DB drift.
   */
  async function previewCheckout(params: {
    branchId: string
    tableId: string
    orderId?: string
    voucherCode?: string
    pointsToRedeem?: number
    customerId?: string
  }): Promise<CheckoutPreview> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('hall_get_checkout_totals', {
        p_branch_id: params.branchId,
        p_table_id: params.tableId,
        p_order_id: params.orderId ?? null,
        p_voucher_code: params.voucherCode ?? null,
        p_points_to_use: params.pointsToRedeem ?? 0,
        p_customer_id: params.customerId ?? null,
      })
      if (err) throw err
      const row = (data ?? {}) as { ok?: boolean; error?: string } & Record<string, unknown>
      return {
        ok: row.ok === true,
        order: row.order as Record<string, unknown> | undefined,
        table: row.table as Record<string, unknown> | undefined,
        items: row.items as Array<Record<string, unknown>> | undefined,
        totals: row.totals as CheckoutTotals,
        voucher_valid: row.voucher_valid === true,
        error: row.error,
      }
    } catch (e: any) {
      error.value = e.message || String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  /**
   * Single-table summary for floor-plan / table-modal previews.
   * Caches by tableId to avoid re-querying when switching back.
   */
  const _tableCache = new Map<string, CheckoutPreview>()
  async function previewTableSummary(branchId: string, tableId: string): Promise<CheckoutPreview> {
    const cached = _tableCache.get(tableId)
    if (cached) return cached
    const fresh = await previewCheckout({ branchId, tableId })
    _tableCache.set(tableId, fresh)
    return fresh
  }
  function clearTableCache(tableId?: string) {
    if (tableId) _tableCache.delete(tableId)
    else _tableCache.clear()
  }

  async function executeCheckout(params: {
    orderId: string
    paymentMethod: string
    paymentRef?: string
    voucherCode?: string
    pointsToRedeem?: number
    serviceChargePct?: number
    vatPct?: number
    branchId: string
    cashierId: string
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
        p_points_to_use: params.pointsToRedeem || 0,
      })
      if (err) throw err
      checkoutResult.value = data as CheckoutResult
      // After successful checkout, drop the cached preview for this table
      // (the table's bill is now Paid — preview is stale).
      _tableCache.clear()
      return data as CheckoutResult
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
    checkoutResult,
    loading,
    error,
    previewCheckout,
    previewTableSummary,
    clearTableCache,
    executeCheckout,
    checkout,
    printReceipt,
  }
}