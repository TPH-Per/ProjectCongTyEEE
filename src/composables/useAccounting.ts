import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function useAccounting() {
  const taxReports = ref<any[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 1. Fetch Tax Report: 1-Query approach to prevent N+1
  const fetchTaxReport = async (startDate: string, endDate: string) => {
    loading.value = true
    error.value = null
    
    try {
      const { data, error: supaError } = await supabase
        .from('bills')
        .select(`
          id,
          bill_code,
          grand_total,
          created_at,
          invoices!inner (
            id,
            invoice_symbol,
            invoice_number,
            buyer_company,
            buyer_tax_code,
            status
          )
        `)
        .eq('invoices.status', 'VALID') // CHỐNG N+1 QUERY BẰNG INNER JOIN VÀ FILTER
        .gte('created_at', startDate)
        .lte('created_at', endDate)
        .order('created_at', { ascending: false })

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

  // 2. Thay thế hóa đơn (Replace Invoice) using the RPC to prevent Race Condition
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

  // 3. Hủy hóa đơn khẩn cấp (Void Invoice)
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

  return {
    taxReports,
    loading,
    error,
    fetchTaxReport,
    replaceInvoice,
    voidInvoice
  }
}
