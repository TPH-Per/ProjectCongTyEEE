import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import { useAuth } from './useAuth'

export type RequisitionType = 'OUTBOUND' | 'INBOUND' | 'RETURN'
export type RequisitionStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'PROCESSING' | 'COMPLETED' | 'CANCELLED'

export interface RequisitionItem {
  id: string
  requisition_id: string
  ingredient_id: string
  requested_quantity: number
  approved_quantity: number | null
  actual_quantity: number | null
  unit: string
  note: string | null
  ingredients?: {
    id: string
    name_vi: string
    name_en: string | null
    name_ja: string | null
    sku: string
  }
}

export interface Requisition {
  id: string
  branch_id: string
  requisition_number: string
  type: RequisitionType
  status: RequisitionStatus
  requested_by: string
  approved_by: string | null
  approved_at: string | null
  rejection_reason: string | null
  needed_by_date: string | null
  note: string | null
  created_at: string
  updated_at: string
  requested_by_profile?: { id: string, raw_user_meta_data: any }
  approved_by_profile?: { id: string, raw_user_meta_data: any }
  requisition_items?: RequisitionItem[]
}

export function useRequisition() {
  const { activeBranchId } = useBranch()
  const { profile } = useAuth()
  
  const requisitions = ref<Requisition[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const pendingCount = computed(() => {
    return requisitions.value.filter(r => r.status === 'PENDING').length
  })

  async function fetchRequisitions(filters?: { status?: RequisitionStatus, type?: RequisitionType }) {
    if (!activeBranchId.value) return
    
    loading.value = true
    error.value = null
    
    try {
      let query = supabase
        .from('requisitions')
        .select(`
          *,
          requested_by_profile:requested_by (
            id, raw_user_meta_data
          ),
          approved_by_profile:approved_by (
            id, raw_user_meta_data
          ),
          requisition_items (
            id, requested_quantity, approved_quantity, actual_quantity, unit, note, ingredient_id,
            ingredients (id, name_vi, name_en, name_ja, sku)
          )
        `)
        .eq('branch_id', activeBranchId.value)
        .order('created_at', { ascending: false })

      if (filters?.status) {
        query = query.eq('status', filters.status)
      }
      if (filters?.type) {
        query = query.eq('type', filters.type)
      }

      const { data, error: err } = await query
      
      if (err) throw err
      
      requisitions.value = data as unknown as Requisition[]
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createRequisition(
    type: RequisitionType,
    items: Array<{ ingredient_id: string; requested_quantity: number; unit: string; note?: string }>,
    neededByDate?: string,
    note?: string
  ) {
    if (!activeBranchId.value) throw new Error('No active branch')
    if (!profile.value?.id) throw new Error('Not authenticated')

    loading.value = true
    error.value = null

    try {
      const { data, error: err } = await supabase.rpc('create_requisition_with_items', {
        p_branch_id: activeBranchId.value,
        p_type: type,
        p_requested_by: profile.value.id,
        p_items: items,
        p_needed_by_date: neededByDate || null,
        p_note: note || null
      })

      if (err) throw err
      await fetchRequisitions()
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function approveRequisition(
    id: string,
    approvedQtys?: Array<{ requisition_item_id: string; approved_quantity: number }>
  ) {
    if (!profile.value?.id) throw new Error('Not authenticated')

    loading.value = true
    error.value = null

    try {
      const { error: err } = await supabase.rpc('approve_reject_requisition', {
        p_requisition_id: id,
        p_action: 'APPROVE',
        p_performed_by: profile.value.id,
        p_note: null,
        p_approved_qtys: approvedQtys || null
      })

      if (err) throw err
      await fetchRequisitions()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function rejectRequisition(id: string, reason: string) {
    if (!profile.value?.id) throw new Error('Not authenticated')

    loading.value = true
    error.value = null

    try {
      const { error: err } = await supabase.rpc('approve_reject_requisition', {
        p_requisition_id: id,
        p_action: 'REJECT',
        p_performed_by: profile.value.id,
        p_note: reason,
        p_approved_qtys: null
      })

      if (err) throw err
      await fetchRequisitions()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function confirmDelivery(
    id: string,
    actualQtys: Array<{ requisition_item_id: string; actual_quantity: number; expiry_date?: string }>
  ) {
    if (!profile.value?.id) throw new Error('Not authenticated')

    loading.value = true
    error.value = null

    try {
      const { error: err } = await supabase.rpc('complete_requisition_delivery', {
        p_requisition_id: id,
        p_completed_by: profile.value.id,
        p_actual_qtys: actualQtys
      })

      if (err) throw err
      await fetchRequisitions()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    requisitions,
    loading,
    error,
    pendingCount,
    fetchRequisitions,
    createRequisition,
    approveRequisition,
    rejectRequisition,
    confirmDelivery
  }
}
