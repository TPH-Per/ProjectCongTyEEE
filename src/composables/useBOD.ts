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

  const branchPerformance = ref<any[]>([])

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

  async function fetchBranchPerformance(startDate: string, endDate: string) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_executive_dashboard', {
        p_period_start: startDate,
        p_period_end: endDate
      })
      if (err) throw err
      branchPerformance.value = (data as any)?.branches || []
      return branchPerformance.value
    } catch (e: any) {
      error.value = e.message
      return []
    } finally {
      loading.value = false
    }
  }

  async function getAuditLogs() {
    loading.value = true
    error.value = null
    try {
      // Temporarily use direct query until RPC is added, or assume RPC get_audit_events
      const { data, error: err } = await supabase.rpc('get_audit_events')
      if (err) {
        // Fallback if RPC not ready
        const { data: fbData, error: fbErr } = await supabase.from('audit_events').select('*').order('created_at', { ascending: false }).limit(50)
        if (fbErr) throw fbErr
        return fbData
      }
      return data || []
    } catch (e: any) {
      error.value = e.message
      return []
    } finally {
      loading.value = false
    }
  }

  async function fetchBODApprovals() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_bod_approvals')
      if (err) {
        // Fallback
        const { data: fbData, error: fbErr } = await supabase.from('bod_approvals').select('*').order('created_at', { ascending: false })
        if (fbErr) throw fbErr
        return fbData
      }
      return data || []
    } catch (e: any) {
      error.value = e.message
      return []
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
    dashboard, loading, error, branchPerformance,
    fetchDashboard, reviewCampaign,
    getAuditLogs, fetchBODApprovals, fetchBranchPerformance
  }
}
