import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Shift } from '@/types/database'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

export const VARIANCE_PIN_THRESHOLD = 100_000

function mapShift(dbShift: any): Shift {
  return {
    id: dbShift.shift_id,
    branch_id: dbShift.branch_id,
    user_id: dbShift.opened_by_profile_id,
    status: dbShift.status as 'open' | 'closed',
    opened_at: dbShift.opened_at,
    closed_at: dbShift.closed_at,
    opening_cash: Number(dbShift.opening_cash_vnd) || 0,
    closing_cash: dbShift.counted_cash_vnd != null ? Number(dbShift.counted_cash_vnd) : null,
    expected_cash: dbShift.expected_cash_vnd != null ? Number(dbShift.expected_cash_vnd) : null,
    cash_difference: dbShift.variance_cash_vnd != null ? Number(dbShift.variance_cash_vnd) : null,
    notes: { handover_notes: dbShift.note || '' } as any,
    metadata: {},
    created_at: dbShift.created_at,
    updated_at: dbShift.created_at
  }
}

export const useShiftStore = defineStore('shift', () => {
  // ─── State ─────────────────────────────────────────────────────────
  const currentShift = ref<Shift | null>(null)
  const shiftPayments = ref<any[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // ─── Computed: revenue breakdown ───────────────────────────────────
  const cashRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.payment_method === 'cash' && p.transaction_type === 'payment')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0) -
    shiftPayments.value
      .filter((p) => p.payment_method === 'cash' && p.transaction_type === 'refund')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0)
  )

  const cardRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.payment_method === 'card' && p.transaction_type === 'payment')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0) -
    shiftPayments.value
      .filter((p) => p.payment_method === 'card' && p.transaction_type === 'refund')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0)
  )

  const transferRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.payment_method === 'transfer' && p.transaction_type === 'payment')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0) -
    shiftPayments.value
      .filter((p) => p.payment_method === 'transfer' && p.transaction_type === 'refund')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0)
  )

  const otherRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => !['cash', 'card', 'transfer'].includes(p.payment_method) && p.transaction_type === 'payment')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0) -
    shiftPayments.value
      .filter((p) => !['cash', 'card', 'transfer'].includes(p.payment_method) && p.transaction_type === 'refund')
      .reduce((sum, p) => sum + Number(p.amount_vnd || 0), 0)
  )

  const totalRevenue = computed(
    () => cashRevenue.value + cardRevenue.value + transferRevenue.value + otherRevenue.value,
  )

  const expectedCash = computed(() => {
    if (!currentShift.value) return 0
    return Number(currentShift.value.opening_cash || 0) + cashRevenue.value
  })

  const orderCount = computed(() => shiftPayments.value.filter(p => p.transaction_type === 'payment').length)

  const isOpen = computed(() => currentShift.value?.status === 'open')

  const openingCash = computed(() =>
    currentShift.value ? Number(currentShift.value.opening_cash || 0) : 0,
  )

  // ─── Actions ─────────────────────────────────
  async function fetchActiveShift(branchId: string) {
    const { data, error: err } = await supabase
      .from('shifts')
      .select('*')
      .eq('branch_id', branchId)
      .eq('status', 'open')
      .maybeSingle()
    if (err) throw err
    currentShift.value = data ? mapShift(data) : null
  }

  async function fetchShiftPayments() {
    if (!currentShift.value) {
      shiftPayments.value = []
      return
    }
    const { data, error: err } = await supabase
      .from('payments')
      .select('amount_vnd, payment_method, transaction_type')
      .eq('shift_id', currentShift.value.id)
    if (err) throw err
    shiftPayments.value = data || []
  }

  async function refresh(branchId: string) {
    loading.value = true
    error.value = null
    try {
      await fetchActiveShift(branchId)
      await fetchShiftPayments()
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
    } finally {
      loading.value = false
    }
  }

  async function openShift(branchId: string, openingCashAmount: number) {
    loading.value = true
    error.value = null
    try {
      const auth = useAuth()
      if (!auth.profile.value?.id) throw new Error('User not logged in')

      const { data, error: err } = await supabase.rpc('rpc_open_shift', {
        p_branch_id: branchId,
        p_opened_by_profile_id: auth.profile.value.id,
        p_opening_cash_vnd: openingCashAmount
      })
      if (err) throw err

      await refresh(branchId)
      return {
        ok: true,
        idempotent: false,
        shift: { id: data.shift_id },
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  async function closeShift(closingCash: number, notes?: string) {
    if (!currentShift.value) throw new Error('No active shift')
    loading.value = true
    error.value = null
    try {
      const auth = useAuth()
      if (!auth.profile.value?.id) throw new Error('User not logged in')
      
      const expectedBank = cardRevenue.value + transferRevenue.value + otherRevenue.value
      
      const { data, error: err } = await supabase.rpc('rpc_close_shift', {
        p_branch_id: currentShift.value.branch_id,
        p_shift_id: currentShift.value.id,
        p_closed_by_profile_id: auth.profile.value.id,
        p_counted_cash_vnd: closingCash,
        p_counted_bank_vnd: expectedBank,
        p_note: notes || ''
      })
      if (err) throw err
      
      const closedId = currentShift.value.id
      const expected = data.expected_cash
      const diff = data.variance_cash
      currentShift.value = null
      shiftPayments.value = []

      return {
        ok: true,
        shift: { id: closedId, closed_at: new Date().toISOString() },
        expectedCash: expected,
        closingCash,
        cashDifference: diff,
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  function reset() {
    currentShift.value = null
    shiftPayments.value = []
    error.value = null
  }

  return {
    // State
    currentShift,
    shiftPayments,
    loading,
    error,
    // Computed
    cashRevenue,
    cardRevenue,
    transferRevenue,
    otherRevenue,
    totalRevenue,
    expectedCash,
    orderCount,
    isOpen,
    openingCash,
    // Actions
    fetchActiveShift,
    fetchShiftPayments,
    refresh,
    openShift,
    closeShift,
    reset,
  }
})
