import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface ExecutiveDashboard {
  revenue: number
  expense: number
  active_campaigns: number
}

export interface BODApproval {
  id: string
  target_type: string
  target_id: string
  approver_id: string
  status: 'PENDING' | 'APPROVED' | 'REJECTED'
  notes?: string
  created_at: string
}

export function useBOD() {
  const dashboard = ref<ExecutiveDashboard | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDashboard(): Promise<ExecutiveDashboard | null> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_executive_dashboard')
      if (err) throw err
      dashboard.value = data as ExecutiveDashboard
      return dashboard.value
    } catch (e: any) {
      error.value = e.message
      return null
    } finally {
      loading.value = false
    }
  }

  async function reviewCampaign(campaignId: string, isApproved: boolean, approverId: string, notes?: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const { error: err } = await supabase.rpc('approve_reject_campaign', {
        p_campaign_id: campaignId,
        p_is_approved: isApproved,
        p_approver_id: approverId,
        p_notes: notes || null
      })
      if (err) throw err
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    dashboard, loading, error,
    fetchDashboard, reviewCampaign
  }
}
