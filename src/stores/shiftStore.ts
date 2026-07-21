import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Shift } from '@/types/database'

// Threshold above which a manager PIN is required to close shift
export const VARIANCE_PIN_THRESHOLD = 100_000

const STORAGE_KEY = 'mock_current_shift'
const PAYMENTS_KEY = 'mock_shift_payments'

// ─── Mock payments (generated when a shift is opened) ───────────────
const MOCK_PAYMENTS: Array<{ amount: number; method: string }> = [
  { amount: 350000, method: 'cash' },
  { amount: 200000, method: 'cash' },
  { amount: 500000, method: 'card' },
  { amount: 300000, method: 'transfer' },
  { amount: 150000, method: 'cash' },
  { amount: 425000, method: 'card' },
  { amount: 180000, method: 'cash' },
]

function createMockShift(branchId: string, openingCash: number, userId: string): Shift {
  const now = new Date().toISOString()
  return {
    id: `mock-shift-${Date.now()}`,
    branch_id: branchId,
    user_id: userId,
    status: 'open',
    opened_at: now,
    closed_at: null,
    opening_cash: openingCash,
    closing_cash: null,
    expected_cash: null,
    cash_difference: null,
    notes: { handover_notes: '' } as any,
    metadata: { opened_via: 'mock' },
    created_at: now,
    updated_at: now,
  }
}

function loadFromStorage(): Shift | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? (JSON.parse(raw) as Shift) : null
  } catch {
    return null
  }
}

function saveToStorage(shift: Shift | null) {
  try {
    if (shift) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(shift))
    } else {
      localStorage.removeItem(STORAGE_KEY)
    }
  } catch {
    // ignore
  }
}

function loadPaymentsFromStorage(): any[] {
  try {
    const raw = localStorage.getItem(PAYMENTS_KEY)
    return raw ? (JSON.parse(raw) as any[]) : []
  } catch {
    return []
  }
}

function savePaymentsToStorage(payments: any[]) {
  try {
    localStorage.setItem(PAYMENTS_KEY, JSON.stringify(payments))
  } catch {
    // ignore
  }
}

export const useShiftStore = defineStore('shift', () => {
  // ─── State ─────────────────────────────────────────────────────────
  const currentShift = ref<Shift | null>(loadFromStorage())
  const shiftPayments = ref<any[]>(loadPaymentsFromStorage())
  const loading = ref(false)
  const error = ref<string | null>(null)

  // ─── Computed: revenue breakdown ───────────────────────────────────
  const cashRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.method === 'cash')
      .reduce((sum, p) => sum + Number(p.amount || 0), 0),
  )

  const cardRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.method === 'card')
      .reduce((sum, p) => sum + Number(p.amount || 0), 0),
  )

  const transferRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => p.method === 'transfer')
      .reduce((sum, p) => sum + Number(p.amount || 0), 0),
  )

  const otherRevenue = computed(() =>
    shiftPayments.value
      .filter((p) => !['cash', 'card', 'transfer'].includes(p.method))
      .reduce((sum, p) => sum + Number(p.amount || 0), 0),
  )

  const totalRevenue = computed(
    () => cashRevenue.value + cardRevenue.value + transferRevenue.value + otherRevenue.value,
  )

  const expectedCash = computed(() => {
    if (!currentShift.value) return 0
    return Number(currentShift.value.opening_cash || 0) + cashRevenue.value
  })

  const orderCount = computed(() => shiftPayments.value.length)

  const isOpen = computed(() => currentShift.value?.status === 'open')

  const openingCash = computed(() =>
    currentShift.value ? Number(currentShift.value.opening_cash || 0) : 0,
  )

  // ─── Actions (mock — no API calls) ─────────────────────────────────
  async function fetchActiveShift(_branchId: string) {
    // Load from localStorage (already loaded on init, but refresh in case
    // another tab modified it)
    currentShift.value = loadFromStorage()
  }

  async function fetchShiftPayments() {
    shiftPayments.value = loadPaymentsFromStorage()
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

  async function openShift(branchId: string, openingCash: number) {
    loading.value = true
    error.value = null
    try {
      // Simulate async delay
      await new Promise((r) => setTimeout(r, 300))

      const userId = 'mock-user-0001'
      const shift = createMockShift(branchId, openingCash, userId)
      currentShift.value = shift
      saveToStorage(shift)

      // Generate mock payments for this shift
      shiftPayments.value = [...MOCK_PAYMENTS]
      savePaymentsToStorage(shiftPayments.value)

      return {
        ok: true,
        idempotent: false,
        shift: { id: shift.id },
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
      // Simulate async delay
      await new Promise((r) => setTimeout(r, 300))

      const diff = closingCash - expectedCash.value

      const closed: Shift = {
        ...currentShift.value,
        status: 'closed',
        closed_at: new Date().toISOString(),
        closing_cash: closingCash,
        expected_cash: expectedCash.value,
        cash_difference: diff,
        notes: { handover_notes: notes ?? '' } as any,
      }

      currentShift.value = null
      shiftPayments.value = []
      saveToStorage(null)
      savePaymentsToStorage([])

      return {
        ok: true,
        shift: { id: closed.id, closed_at: closed.closed_at },
        expectedCash: closed.expected_cash,
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
    saveToStorage(null)
    savePaymentsToStorage([])
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
