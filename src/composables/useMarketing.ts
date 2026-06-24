import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { MarketingCost } from '@/types/database'

export function useMarketing() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listForPeriod(periodStart: string, periodEnd: string): Promise<MarketingCost[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('marketing_costs')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .lte('period_start', periodEnd)
      .gte('period_end', periodStart)
      .order('period_start', { ascending: false })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as MarketingCost[]
  }

  async function create(payload: Partial<MarketingCost>): Promise<MarketingCost> {
    const insert = { ...payload, branch_id: activeBranchId.value }
    const { data, error: err } = await supabase
      .from('marketing_costs')
      .insert(insert)
      .select('*')
      .single<MarketingCost>()
    if (err) throw err
    return data!
  }

  return { loading, error, listForPeriod, create }
}
