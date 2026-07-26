import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { KPITarget } from '@/types/database'

export function useKPI() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listCurrent(periodStart: string, periodEnd: string): Promise<KPITarget[]> {
    return [] as KPITarget[]
  }

  async function upsert(payload: Partial<KPITarget>): Promise<KPITarget> {
    return payload as KPITarget
  }

  return { loading, error, listCurrent, upsert }
}
