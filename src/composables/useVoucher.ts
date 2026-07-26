import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from '@/composables/useBranch'
import { useAuth } from '@/composables/useAuth'

// ---- types ----
export interface Voucher {
  id: string
  branch_id: string
  code: string
  type: 'percent' | 'amount'
  value: number
  min_order_value: number
  max_discount_amount: number | null
  valid_from: string | null
  valid_until: string | null
  max_uses: number | null
  used_count: number
  usage_limit_per_customer: number
  is_active: boolean
  is_deleted: boolean
  customer_id: string | null
  description_vi: string | null
  description_en: string | null
  description_ja: string | null
  created_by: string | null
  metadata: Record<string, unknown>
  customer?: any
}

export interface CreateVoucherInput {
  code: string
  type: 'percent' | 'amount'
  value: number
  min_order_value?: number
  max_discount_amount?: number | null
  valid_from?: string | null
  valid_until?: string | null
  max_uses?: number | null
  usage_limit_per_customer?: number
  description_vi?: string
  description_en?: string
  description_ja?: string
  customer_id?: string | null
}

export interface ValidateVoucherResult {
  valid: boolean
  error?: string
  discount_amount?: number
  voucher_id?: string
  code?: string
  type?: 'percent' | 'amount'
  description_vi?: string
  description_en?: string
  description_ja?: string
  min_order_value?: number
}

export interface VoucherStats {
  total_vouchers: number
  active_vouchers: number
  expired_vouchers: number
  total_discount_given: number
  total_redemptions: number
  most_used_code: string | null
}

// ---- composable ----
export function useVoucher() {
  const vouchers = ref<Voucher[]>([])
  const stats = ref<VoucherStats | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const { activeBranchId } = useBranch()
  const { profile } = useAuth()

  // LIST — with optional filters, no N+1 (flat select)
  async function listVouchers(filters?: {
    onlyActive?: boolean
    onlyExpired?: boolean
    type?: 'percent' | 'amount'
    search?: string
  }) {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_vouchers', {
        p_branch_id: activeBranchId.value,
        p_only_active: filters?.onlyActive ?? false,
        p_only_expired: filters?.onlyExpired ?? false,
        p_type: filters?.type ?? null,
        p_search: filters?.search ?? null
      })
      if (err) throw err
      vouchers.value = data as any[]
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // CREATE
  async function createVoucher(input: CreateVoucherInput): Promise<Voucher> {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error: err } = await supabase.rpc('create_voucher', {
      p_branch_id: activeBranchId.value,
      p_code: input.code,
      p_type: input.type,
      p_value: input.value,
      p_min_order_value: input.min_order_value || 0,
      p_max_discount_amount: input.max_discount_amount || null,
      p_valid_from: input.valid_from || null,
      p_valid_until: input.valid_until || null,
      p_max_uses: input.max_uses || null,
      p_usage_limit_per_customer: input.usage_limit_per_customer || null,
      p_customer_id: input.customer_id || null,
      p_description_vi: input.description_vi || null,
      p_description_en: input.description_en || null,
      p_description_ja: input.description_ja || null
    })

    if (err) {
      if (err.message.includes('DUPLICATE_CODE')) throw new Error('DUPLICATE_CODE')
      throw err
    }
    vouchers.value.unshift(data as any)
    return data as any
  }

  // UPDATE (partial patch)
  async function updateVoucher(id: string, patch: Partial<CreateVoucherInput & { is_active: boolean }>): Promise<Voucher> {
    const { data, error: err } = await supabase.rpc('update_voucher', {
      p_id: id,
      p_patch: patch
    })

    if (err) throw err
    const idx = vouchers.value.findIndex(v => v.id === id)
    if (idx >= 0) vouchers.value[idx] = data as any
    return data as any
  }

  // TOGGLE ACTIVE
  async function toggleVoucher(id: string, isActive: boolean): Promise<void> {
    await updateVoucher(id, { is_active: isActive })
  }

  // SOFT DELETE
  async function deleteVoucher(id: string): Promise<void> {
    const { error: err } = await supabase.rpc('update_voucher', {
      p_id: id,
      p_patch: { is_deleted: true, is_active: false }
    })
    if (err) throw err
    vouchers.value = vouchers.value.filter(v => v.id !== id)
  }

  // VALIDATE (for checkout — no side effect)
  async function validateVoucherAtCheckout(
    code: string,
    orderTotal: number,
    customerId?: string
  ): Promise<ValidateVoucherResult> {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error: err } = await supabase.rpc('validate_voucher', {
      p_code: code,
      p_branch_id: activeBranchId.value,
      p_order_total: orderTotal,
      p_customer_id: customerId ?? null
    })
    if (err) throw err
    return data as ValidateVoucherResult
  }

  // REDEEM (called inside checkout RPC after invoice created)
  async function redeemVoucher(
    voucherId: string,
    invoiceId: string,
    orderTotal: number,
    customerId?: string
  ): Promise<{ discount_amount: number; code?: string; new_used_count?: number }> {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error: err } = await supabase.rpc('redeem_voucher', {
      p_voucher_id: voucherId,
      p_invoice_id: invoiceId,
      p_branch_id: activeBranchId.value,
      p_order_total: orderTotal,
      p_customer_id: customerId ?? null
    })
    if (err) {
      if (err.message.includes('P0010')) throw new Error('VOUCHER_NO_LONGER_VALID')
      throw err
    }
    return data as any
  }

  // STATS (single RPC, no N+1)
  async function fetchStats() {
    if (!activeBranchId.value) return
    const { data, error: err } = await supabase.rpc('get_voucher_stats', { p_branch_id: activeBranchId.value })
    if (err) throw err
    stats.value = data as any
  }

  // COMPUTED
  const activeVouchers = computed(() => vouchers.value.filter(v => v.is_active))
  const expiredVouchers = computed(() => vouchers.value.filter(v =>
    v.valid_until && new Date(v.valid_until) < new Date()
  ))
  const usagePercent = (v: Voucher) =>
    v.max_uses ? Math.round((v.used_count / v.max_uses) * 100) : null

  return {
    vouchers,
    stats,
    loading,
    error,
    listVouchers,
    createVoucher,
    updateVoucher,
    toggleVoucher,
    deleteVoucher,
    validateVoucherAtCheckout,
    redeemVoucher,
    fetchStats,
    activeVouchers,
    expiredVouchers,
    usagePercent
  }
}
