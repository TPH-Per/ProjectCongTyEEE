import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'

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

export interface CrmDashboardStats {
  total_customers?: number
  new_customers_this_month?: number
  repeater_customers?: number
  vip_customers?: number
  avg_spent_per_customer?: number
}

export const useCrmStore = defineStore('crm', () => {
  const { activeBranchId } = useBranch()
  
  const loading = ref(false)
  const error = ref<string | null>(null)
  const servingTables = ref<CrmServingTable[]>([])
  const dashboardStats = ref<CrmDashboardStats | null>(null)
  
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

  async function fetchDashboardStats() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_crm_dashboard_stats', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
      })
      if (err) throw err
      dashboardStats.value = data as CrmDashboardStats
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchServingTables(branchId = activeBranchId.value) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_list_serving_tables', {
        p_branch_id: branchId ?? throwBranchGuard(),
      })
      if (err) throw err
      servingTables.value = (data ?? []) as CrmServingTable[]
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
      
      // Update local state if needed, or caller can just re-fetch
      await fetchServingTables()
      
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function markSurveyInProgress(table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_mark_survey_in_progress', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
        p_table_id: table.table_id,
        p_order_id: table.order_id,
        p_table_assignment_id: table.table_assignment_id,
      })
      if (err) throw err
      await fetchServingTables()
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function skipTableSurvey(
    table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>,
    note?: string,
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_skip_table_survey', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
        p_table_id: table.table_id,
        p_order_id: table.order_id,
        p_table_assignment_id: table.table_assignment_id,
        p_note: note || null,
      })
      if (err) throw err
      await fetchServingTables()
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function refuseTableSurvey(
    table: Pick<CrmServingTable, 'table_id' | 'order_id' | 'table_assignment_id'>,
    note?: string,
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('crm_refuse_table_survey', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
        p_table_id: table.table_id,
        p_order_id: table.order_id,
        p_table_assignment_id: table.table_assignment_id,
        p_note: note || null,
      })
      if (err) throw err
      await fetchServingTables()
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    error,
    servingTables,
    dashboardStats,
    fetchCustomerFeedback,
    fetchServiceRequests,
    fetchServingTables,
    fetchDashboardStats,
    submitTableSurvey,
    markSurveyInProgress,
    skipTableSurvey,
    refuseTableSurvey,
  }
})
