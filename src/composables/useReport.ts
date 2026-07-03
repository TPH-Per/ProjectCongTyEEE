import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'
import { useAuth } from './useAuth'

export interface RevenueByHourRow {
  hour_bucket: number
  total: number
}

/**
 * Aggregate reporting helpers — read-only RPC calls for KPI / COGS / revenue.
 *
 * For very large aggregates use the database views defined in the Supabase
 * setup rather than pulling raw rows into the browser.
 */
export function useReport() {
  const { activeBranchId } = useBranch()
  const { role } = useAuth()
  const loading = ref(false)
  const error = ref<string | null>(null)

  function guardManager() {
    // `superadmin` covers the legacy DB `admin` enum value via the
    // normaliseRole() mapping in useAuth.ts.
    if (role.value !== 'manager' && role.value !== 'superadmin') {
      throw new Error('Forbidden: manager role required for reports')
    }
  }

  async function revenueByHour(date: string): Promise<RevenueByHourRow[]> {
    guardManager()
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase.rpc('revenue_by_hour', {
      p_branch_id: (activeBranchId.value ?? throwBranchGuard()),
      p_date: date,
    })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as RevenueByHourRow[]
  }

  async function todayHeadline(): Promise<{
    revenue: number
    orders: number
    covers: number
  }> {
    guardManager()
    loading.value = true
    error.value = null
    const today = new Date().toISOString().slice(0, 10)
    // Rebuilt invoices (schema_hardening_v2) use status in (VALID, UPDATED) and
    // created_at (no issued_at). The legacy invoices table also has these columns
    // but the rebuilt path is the one created by process_checkout.
    const { data: invoices, error: err } = await supabase
      .from('invoices')
      .select('grand_total, order_id')
      .eq('branch_id', (activeBranchId.value ?? throwBranchGuard()))
      .in('status', ['VALID', 'UPDATED'])
      .gte('created_at', `${today}T00:00:00Z`)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const revenue = (invoices ?? []).reduce((acc, r) => acc + Number(r.grand_total), 0)
    const orders = new Set((invoices ?? []).map((r) => r.order_id)).size
    return { revenue, orders, covers: orders * 2 } // placeholder covers estimate
  }

  return { loading, error, revenueByHour, todayHeadline }
}

