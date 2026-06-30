import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { RealtimeChannel } from '@supabase/supabase-js'

export interface ServiceRequest {
  id: string
  branch_id: string
  table_id: string
  type: 'CALL_WAITER' | 'REQUEST_BILL' | 'REQUEST_CONDIMENT' | 'COMPLAINT' | 'OTHER'
  message?: string
  priority?: 'NORMAL' | 'URGENT'
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED'
  created_at: string
}

export function useServiceRequest() {
  const openRequests = ref<ServiceRequest[]>([])
  const { activeBranchId } = useBranch()

  async function fetchOpenRequests(): Promise<ServiceRequest[]> {
    const { data, error } = await supabase
      .from('service_requests')
      .select('*')
      .eq('branch_id', activeBranchId.value)
      .in('status', ['OPEN', 'IN_PROGRESS'])
      .order('created_at', { ascending: false })
    if (error) throw error
    openRequests.value = data as ServiceRequest[]
    return data as ServiceRequest[]
  }

  async function createRequest(params: {
    branchId: string;
    tableId: string;
    type: 'CALL_WAITER' | 'REQUEST_BILL' | 'REQUEST_CONDIMENT' | 'COMPLAINT' | 'OTHER';
    orderId?: string;
    message?: string;
    priority?: 'NORMAL' | 'URGENT';
  }): Promise<string> {
    const { data, error } = await supabase.rpc('create_service_request', {
      p_branch_id: params.branchId,
      p_table_id: params.tableId,
      p_type: params.type,
      p_message: params.message
    })
    if (error) throw error
    return data.request_id
  }

  async function startHandling(requestId: string): Promise<void> {
    const { error } = await supabase.from('service_requests').update({ status: 'IN_PROGRESS' }).eq('id', requestId)
    if (error) throw error
  }

  async function resolveRequest(requestId: string): Promise<void> {
    const { error } = await supabase.from('service_requests').update({ status: 'RESOLVED', resolved_at: new Date().toISOString() }).eq('id', requestId)
    if (error) throw error
  }

  function subscribeToRequests(callback: (req: ServiceRequest) => void): RealtimeChannel {
    return supabase.channel('service_requests_changes')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'service_requests', filter: `branch_id=eq.${activeBranchId.value}` }, (payload) => callback(payload.new as ServiceRequest))
      .subscribe()
  }

  const urgentCount = computed(() =>
    openRequests.value.filter(r => r.priority === 'URGENT' && r.status === 'OPEN').length
  )

  return {
    openRequests, urgentCount,
    fetchOpenRequests, createRequest, startHandling, resolveRequest,
    subscribeToRequests
  }
}
