import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { KPITarget } from '@/types/database'

export function useKPI() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listCurrent(periodStart: string, periodEnd: string): Promise<KPITarget[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('kpi_targets')
      .select('*')
      .or(`branch_id.eq.${activeBranchId.value!},branch_id.is.null`)
      .lte('period_start', periodEnd)
      .gte('period_end', periodStart)
      .order('period_start', { ascending: false })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as KPITarget[]
  }

  async function upsert(payload: Partial<KPITarget>): Promise<KPITarget> {
    const insert = { ...payload, branch_id: payload.branch_id ?? activeBranchId.value }
    const { data, error: err } = await supabase
      .from('kpi_targets')
      .upsert(insert)
      .select('*')
      .single<KPITarget>()
    if (err) throw err
    return data!
  }

  return { loading, error, listCurrent, upsert }
}
