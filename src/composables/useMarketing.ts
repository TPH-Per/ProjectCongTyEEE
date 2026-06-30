import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'

export function useMarketing() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchCampaigns() {
    loading.value = true
    error.value = null
    try {
      if (!activeBranchId.value) throwBranchGuard()
      const { data, error: err } = await supabase
        .from('campaigns')
        .select('*')
        .eq('branch_id', activeBranchId.value)
        .order('created_at', { ascending: false })
      if (err) throw err
      return data || []
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createCampaign(payload: any) {
    loading.value = true
    error.value = null
    try {
      if (!activeBranchId.value) throwBranchGuard()
      const { data, error: err } = await supabase
        .from('campaigns')
        .insert({ ...payload, branch_id: activeBranchId.value })
        .select()
        .single()
      if (err) throw err
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  // legacy method for compatibility if needed elsewhere
  async function listForPeriod(periodStart: string, periodEnd: string) {
    return [] 
  }
  async function create(payload: any) {
    return createCampaign(payload)
  }

  return {
    loading,
    error,
    fetchCampaigns,
    createCampaign,
    listForPeriod,
    create
  }
}
