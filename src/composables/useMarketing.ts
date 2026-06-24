import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { MarketingCost } from '@/types/database'

export function useMarketing() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listForPeriod(periodStart: string, periodEnd: string): Promise<MarketingCost[]> {
    return [] as MarketingCost[]
  }

  async function create(payload: Partial<MarketingCost>): Promise<MarketingCost> {
    return payload as MarketingCost
  }

  return { loading, error, listForPeriod, create }
}
