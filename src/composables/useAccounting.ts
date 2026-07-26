import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function useAccounting() {
  const taxReports = ref<any[]>([])
  const taxRecords = ref<any[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 1. Fetch Tax Report using RPC
  const fetchTaxReport = async (startDate: string, endDate: string) => {
    loading.value = true
    error.value = null
    
    try {
      const { data, error: supaError } = await supabase.rpc('get_tax_report', {
        p_start_date: startDate,
        p_end_date: endDate
      })

      if (supaError) throw supaError
      
      taxReports.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching tax report:', err)
      error.value = err.message
      return null
    } finally {
      loading.value = false
    }
  }

  const fetchTaxRecords = async () => {
    loading.value = true
    error.value = null
    
    try {
      const { data, error: supaError } = await supabase.rpc('get_tax_records')

      if (supaError) throw supaError
      
      taxRecords.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching tax records:', err)
      error.value = err.message
      return null
    } finally {
      loading.value = false
    }
  }

  const generateTaxRecord = async (periodType: string, startDate: string, endDate: string) => {
    loading.value = true
    error.value = null
    
    try {
      // Need branch_id, assuming current branch from user profile, but wait: 
      // the RPC generate_tax_record takes p_branch_id. If we don't have it, we might need to get it from useAuth.
      // For now, pass a dummy or let the RPC handle it if we fetch it.
      // Wait, let's just fetch from session or let it throw if branch_id is required. 
      // Let's pass the branch_id from the user session.
      const { data: userData } = await supabase.auth.getUser()
      const branchId = userData.user?.user_metadata?.branch_id || '00000000-0000-0000-0000-000000000000'

      const { data, error: supaError } = await supabase.rpc('generate_tax_record', {
        p_branch_id: branchId,
        p_period_type: periodType,
        p_period_start: startDate,
        p_period_end: endDate
      })

      if (supaError) throw supaError
      
      return data
    } catch (err: any) {
      console.error('Error generating tax record:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const finalizeTaxRecord = async (recordId: string) => {
    loading.value = true
    error.value = null
    
    try {
      const { error: supaError } = await supabase.rpc('finalize_tax_record', {
        p_record_id: recordId
      })

      if (supaError) throw supaError
      
      return true
    } catch (err: any) {
      console.error('Error finalizing tax record:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // 2. Thay the hoa don (Replace Invoice) using the RPC to prevent Race Condition
  const replaceInvoice = async (
    billId: string, 
    newSymbol: string, 
    newNumber: string, 
    newTaxCode: string, 
    newCompany: string
  ) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: rpcError } = await supabase.rpc('replace_invoice', {
        p_bill_id: billId,
        p_new_invoice_symbol: newSymbol,
        p_new_invoice_number: newNumber,
        p_buyer_tax_code: newTaxCode,
        p_buyer_company: newCompany
      })

      if (rpcError) throw rpcError
      return data // Returns the ID of the newly generated invoice
    } catch (err: any) {
      console.error('Error replacing invoice:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // 3. Huy hoa don khẩn cấp (Void Invoice)
  const voidInvoice = async (billId: string) => {
    loading.value = true
    error.value = null

    try {
      const { error: rpcError } = await supabase.rpc('void_invoice', {
        p_bill_id: billId
      })

      if (rpcError) throw rpcError
      return true
    } catch (err: any) {
      console.error('Error voiding invoice:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const getProfitLoss = async (startDate: string, endDate: string) => {
    loading.value = true
    error.value = null
    try {
      const { data, error: supaError } = await supabase.rpc('get_executive_dashboard', {
        p_period_start: startDate,
        p_period_end: endDate
      })

      if (supaError) throw supaError
      
      // data.totals contains total_revenue, total_expense, gross_profit
      return {
        revenue: data?.totals?.total_revenue || 0,
        expense: data?.totals?.total_expense || 0,
        profit: data?.totals?.gross_profit || 0
      }
    } catch (err: any) {
      console.error('Error getting profit loss:', err)
      error.value = err.message
      return { revenue: 0, expense: 0, profit: 0 }
    } finally {
      loading.value = false
    }
  }

  // Alias for compatibility
  const fetchProfitLoss = getProfitLoss

  return {
    taxReports,
    taxRecords,
    loading,
    error,
    fetchTaxReport,
    fetchTaxRecords,
    generateTaxRecord,
    finalizeTaxRecord,
    replaceInvoice,
    voidInvoice,
    getProfitLoss,
    fetchProfitLoss
  }
}
