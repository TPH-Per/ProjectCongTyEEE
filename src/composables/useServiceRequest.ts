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
    const { data, error } = await supabase.rpc('hall_list_service_requests', {
      p_branch_id: activeBranchId.value,
      p_statuses: ['OPEN', 'IN_PROGRESS'],
    })
    if (error) throw error
    openRequests.value = (data ?? []) as ServiceRequest[]
    return openRequests.value
  }

  async function createRequest(params: {
    branchId: string;
    tableId: string;
    type: 'CALL_WAITER' | 'REQUEST_BILL' | 'REQUEST_CONDIMENT' | 'COMPLAINT' | 'OTHER';
    orderId?: string;
    sessionId?: string;
    message?: string;
    priority?: 'NORMAL' | 'URGENT';
  }): Promise<string> {
    const { data, error } = await supabase.rpc('create_service_request', {
      p_branch_id: params.branchId,
      p_table_id: params.tableId,
      p_type: params.type,
      p_message: params.message || null,
      p_order_id: params.orderId || null,
      p_priority: params.priority || 'NORMAL',
      p_session_id: params.sessionId || null,
    })
    if (error) throw error
    return (data as ServiceRequest).id
  }

  async function startHandling(requestId: string): Promise<void> {
    const { error } = await supabase.rpc('hall_ack_service_request', {
      p_request_id: requestId,
    })
    if (error) throw error
  }

  async function resolveRequest(requestId: string): Promise<void> {
    const { error } = await supabase.rpc('hall_complete_service_request', {
      p_request_id: requestId,
    })
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
