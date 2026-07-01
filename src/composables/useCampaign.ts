import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Campaign {
  id: string
  name: string
  type: string
  start_date: string
  end_date: string
  budget: number
  status: 'DRAFT' | 'PENDING_APPROVAL' | 'APPROVED' | 'ACTIVE' | 'REJECTED' | 'COMPLETED'
  config: Record<string, any>
  created_at: string
}

export function useCampaign() {
  const campaigns = ref<Campaign[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listCampaigns(): Promise<Campaign[]> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.from('campaigns').select('*').order('created_at', { ascending: false })
      if (err) throw err
      campaigns.value = data as Campaign[]
      return campaigns.value
    } catch (e: any) {
      error.value = e.message
      return []
    } finally {
      loading.value = false
    }
  }

  async function createCampaign(params: {
    name: string
    type: string
    startDate: string
    endDate: string
    budget: number
    config: Record<string, any>
  }): Promise<string> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('create_campaign', {
        p_name: params.name,
        p_type: params.type,
        p_start_date: params.startDate,
        p_end_date: params.endDate,
        p_budget: params.budget,
        p_config: params.config
      })
      if (err) throw err
      return data as string
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function submitForApproval(id: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const { error: err } = await supabase.rpc('submit_campaign_for_approval', {
        p_campaign_id: id
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
    campaigns, loading, error,
    listCampaigns, createCampaign, submitForApproval
  }
}
