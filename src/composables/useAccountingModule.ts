/**
 * useAccountingModule.ts
 * Composable for the full Accounting Module.
 * All data access goes through Supabase RPC (no direct table queries).
 */
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

// ──────────────── Types ────────────────────────────────────
export interface AccountingCategory {
  id: string
  name: string
  name_en: string | null
  name_ja: string | null
  type: 'income' | 'expense'
  code: string | null
  is_system: boolean
  is_active: boolean
  created_at: string
}

export interface CashFlowEntry {
  id: string
  branch_id: string
  branch_name: string
  category_id: string | null
  category_name: string | null
  category_code: string | null
  type: 'income' | 'expense'
  amount: number
  description: string
  reference_no: string | null
  payment_method: 'cash' | 'bank_transfer' | 'card'
  status: 'draft' | 'pending' | 'approved' | 'rejected'
  entry_date: string
  approved_by: string | null
  approved_at: string | null
  reject_reason: string | null
  created_by: string | null
  creator_name: string | null
  created_at: string
  notes: string | null
  total_count?: number
}

export interface APRecord {
  id: string
  branch_id: string
  branch_name: string
  supplier_id: string | null
  supplier_name: string | null
  invoice_ref: string | null
  total_amount: number
  paid_amount: number
  outstanding: number
  due_date: string | null
  payment_date: string | null
  status: 'unpaid' | 'partial' | 'paid' | 'overdue'
  is_overdue: boolean
  notes: string | null
  created_at: string
}

export interface AccountingDashboard {
  period: { year: number; month: number }
  total_income: number
  total_expense: number
  net_cashflow: number
  pending_count: number
  draft_count: number
  ap_unpaid_count: number
  ap_unpaid_amount: number
  ap_overdue_count: number
}

export interface PLReportRow {
  category_code: string
  category_name: string
  type: 'income' | 'expense'
  month_amount: number
  ytd_amount: number
}

export interface CreateCashFlowInput {
  branch_id: string
  category_id: string | null
  type: 'income' | 'expense'
  amount: number
  description: string
  payment_method: 'cash' | 'bank_transfer' | 'card'
  entry_date: string
  reference_no?: string
  notes?: string
}

export interface CreateAPInput {
  branch_id: string
  supplier_id: string | null
  invoice_ref: string
  total_amount: number
  paid_amount: number
  due_date?: string
  notes?: string
}

// ──────────────── Composable ───────────────────────────────
export function useAccountingModule() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  // State
  const dashboard = ref<AccountingDashboard | null>(null)
  const cashFlowEntries = ref<CashFlowEntry[]>([])
  const categories = ref<AccountingCategory[]>([])
  const apRecords = ref<APRecord[]>([])
  const plReport = ref<PLReportRow[]>([])
  const totalEntries = ref(0)

  // Computed
  const incomeCategories = computed(() => categories.value.filter(c => c.type === 'income'))
  const expenseCategories = computed(() => categories.value.filter(c => c.type === 'expense'))

  const plIncome = computed(() => plReport.value.filter(r => r.type === 'income'))
  const plExpense = computed(() => plReport.value.filter(r => r.type === 'expense'))
  const plNetMonth = computed(() =>
    plIncome.value.reduce((s, r) => s + Number(r.month_amount), 0) -
    plExpense.value.reduce((s, r) => s + Number(r.month_amount), 0)
  )
  const plNetYTD = computed(() =>
    plIncome.value.reduce((s, r) => s + Number(r.ytd_amount), 0) -
    plExpense.value.reduce((s, r) => s + Number(r.ytd_amount), 0)
  )

  async function fetchDashboard(branchId?: string | null, year?: number, month?: number) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_accounting_dashboard', {
        p_branch_id: branchId ?? null,
        p_year: year ?? null,
        p_month: month ?? null,
      })
      if (err) throw err
      dashboard.value = data as AccountingDashboard
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function fetchCashFlowEntries(params: {
    branchId?: string | null
    start?: string | null
    end?: string | null
    type?: 'income' | 'expense' | null
    status?: string | null
    limit?: number
    offset?: number
  } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_cash_flow_entries', {
        p_branch_id: params.branchId ?? null,
        p_start: params.start ?? null,
        p_end: params.end ?? null,
        p_type: params.type ?? null,
        p_status: params.status ?? null,
        p_limit: params.limit ?? 50,
        p_offset: params.offset ?? 0,
      })
      if (err) throw err
      const rows = (data ?? []) as CashFlowEntry[]
      cashFlowEntries.value = rows
      totalEntries.value = rows.length > 0 ? Number(rows[0].total_count ?? 0) : 0
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function createEntry(input: CreateCashFlowInput) {
    const { data, error: err } = await supabase.rpc('create_cash_flow_entry', {
      p_branch_id: input.branch_id,
      p_category_id: input.category_id,
      p_type: input.type,
      p_amount: input.amount,
      p_description: input.description,
      p_payment_method: input.payment_method,
      p_entry_date: input.entry_date,
      p_reference_no: input.reference_no ?? null,
      p_notes: input.notes ?? null,
    })
    if (err) throw err
    return data
  }

  async function updateEntry(id: string, payload: Partial<CreateCashFlowInput>) {
    const { data, error: err } = await supabase.rpc('update_cash_flow_entry', {
      p_id: id,
      p_category_id: payload.category_id ?? null,
      p_amount: payload.amount ?? null,
      p_description: payload.description ?? null,
      p_payment_method: payload.payment_method ?? null,
      p_entry_date: payload.entry_date ?? null,
      p_reference_no: payload.reference_no ?? null,
      p_notes: payload.notes ?? null,
    })
    if (err) throw err
    return data
  }

  async function submitEntry(id: string) {
    const { data, error: err } = await supabase.rpc('submit_cash_flow_entry', { p_id: id })
    if (err) throw err
    return data
  }

  async function approveEntry(id: string, action: 'approve' | 'reject', reason?: string) {
    const { data, error: err } = await supabase.rpc('approve_cash_flow_entry', {
      p_id: id,
      p_action: action,
      p_reason: reason ?? null,
    })
    if (err) throw err
    return data
  }

  async function deleteEntry(id: string) {
    const { error: err } = await supabase.rpc('delete_cash_flow_entry', { p_id: id })
    if (err) throw err
  }

  async function fetchCategories(type?: 'income' | 'expense') {
    const { data, error: err } = await supabase.rpc('get_accounting_categories', {
      p_type: type ?? null,
    })
    if (err) throw err
    categories.value = (data ?? []) as AccountingCategory[]
  }

  async function fetchAPSummary(branchId?: string | null, status?: string) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_ap_summary', {
        p_branch_id: branchId ?? null,
        p_status: status ?? null,
      })
      if (err) throw err
      apRecords.value = (data ?? []) as APRecord[]
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function recordAPPayment(input: CreateAPInput) {
    const { data, error: err } = await supabase.rpc('record_ap_payment', {
      p_branch_id: input.branch_id,
      p_supplier_id: input.supplier_id,
      p_invoice_ref: input.invoice_ref,
      p_total_amount: input.total_amount,
      p_paid_amount: input.paid_amount,
      p_due_date: input.due_date ?? null,
      p_notes: input.notes ?? null,
    })
    if (err) throw err
    return data
  }

  async function fetchPLReport(branchId?: string | null, year?: number, month?: number) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_pl_report', {
        p_branch_id: branchId ?? null,
        p_year: year ?? null,
        p_month: month ?? null,
      })
      if (err) throw err
      plReport.value = (data ?? []) as PLReportRow[]
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  return {
    // State
    loading, error,
    dashboard, cashFlowEntries, categories,
    apRecords, plReport, totalEntries,
    // Computed
    incomeCategories, expenseCategories,
    plIncome, plExpense, plNetMonth, plNetYTD,
    // Actions
    fetchDashboard,
    fetchCashFlowEntries,
    createEntry, updateEntry, submitEntry, approveEntry, deleteEntry,
    fetchCategories,
    fetchAPSummary, recordAPPayment,
    fetchPLReport,
  }
}
