import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'

export type CrmSurveyStatus =
  | 'not_started'
  | 'assigned'
  | 'in_progress'
  | 'completed'
  | 'skipped'
  | 'customer_refused'
  | 'expired'
  | 'late_submitted'

export interface CrmServingTable {
  table_id: string
  table_code: string
  zone_name: string | null
  order_id: string
  table_assignment_id: string | null
  reservation_id: string | null
  started_at: string
  guest_count: number
  crm_survey_id: string | null
  crm_status: CrmSurveyStatus
  crm_asked_by: string | null
  crm_asked_at: string | null
  crm_submitted_at: string | null
  customer_name: string | null
  customer_phone: string | null
}

export interface CrmSurveyInput {
  branchId?: string
  tableId: string
  orderId?: string | null
  tableAssignmentId?: string | null
  sourceCode?: string | null
  visitReason?: string | null
  feedback?: string | null
  improvementNote?: string | null
  customerName?: string | null
  customerPhone?: string | null
  zalo?: string | null
  marketingConsent?: boolean
  tags?: string[]
  note?: string | null
}

export function useCRM() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchCustomerFeedback() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_list_customer_feedback', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      })
      if (err) throw err
      return data || []
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchServiceRequests() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_list_service_requests', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      })
      if (err) throw err
      return data || []
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function listServingTables(branchId = activeBranchId.value): Promise<CrmServingTable[]> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_list_serving_tables', {
        p_branch_id: branchId ?? throwBranchGuard(),
      })
      if (err) throw err
      return (data ?? []) as CrmServingTable[]
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function submitTableSurvey(input: CrmSurveyInput) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_submit_table_survey', {
        p_branch_id: input.branchId ?? activeBranchId.value ?? throwBranchGuard(),
        p_table_id: input.tableId,
        p_order_id: input.orderId ?? null,
        p_table_assignment_id: input.tableAssignmentId ?? null,
        p_source_code: input.sourceCode || null,
        p_visit_reason: input.visitReason || null,
        p_feedback: input.feedback || null,
        p_improvement_note: input.improvementNote || null,
        p_customer_name: input.customerName || null,
        p_customer_phone: input.customerPhone || null,
        p_zalo: input.zalo || null,
        p_marketing_consent: input.marketingConsent ?? false,
        p_tags: input.tags ?? [],
        p_note: input.note || null,
      })
      if (err) throw err
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function markSurveyInProgress(table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>) {
    const { data, error: err } = await supabase.rpc('crm_mark_survey_in_progress', {
      p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      p_table_id: table.table_id,
      p_order_id: table.order_id,
      p_table_assignment_id: table.table_assignment_id,
    })
    if (err) throw err
    return data
  }

  async function skipTableSurvey(
    table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>,
    note?: string,
  ) {
    const { data, error: err } = await supabase.rpc('crm_skip_table_survey', {
      p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      p_table_id: table.table_id,
      p_order_id: table.order_id,
      p_table_assignment_id: table.table_assignment_id,
      p_note: note || null,
    })
    if (err) throw err
    return data
  }

  async function refuseTableSurvey(
    table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>,
    note?: string,
  ) {
    const { data, error: err } = await supabase.rpc('crm_refuse_table_survey', {
      p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      p_table_id: table.table_id,
      p_order_id: table.order_id,
      p_table_assignment_id: table.table_assignment_id,
      p_note: note || null,
    })
    if (err) throw err
    return data
  }

  /**
   * Generic survey-status setter. Used by the "undo last change" affordance —
   * reverts to a prior status after a mistaken clicked action. Only the 4
   * intermediate workflow statuses are accepted (`completed` is not reversible
   * through this RPC — once submitted, the survey is final).
   */
  async function setSurveyStatus(
    table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>,
    status: 'assigned' | 'in_progress' | 'skipped' | 'customer_refused',
    note?: string,
  ) {
    const { data, error: err } = await supabase.rpc('crm_set_table_survey_status', {
      p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      p_table_id: table.table_id,
      p_order_id: table.order_id,
      p_table_assignment_id: table.table_assignment_id,
      p_status: status,
      p_note: note || null,
    })
    if (err) throw err
    return data
  }

  return {
    loading,
    error,
    fetchCustomerFeedback,
    fetchServiceRequests,
    listServingTables,
    submitTableSurvey,
    markSurveyInProgress,
    skipTableSurvey,
    refuseTableSurvey,
    setSurveyStatus,
  }
}
