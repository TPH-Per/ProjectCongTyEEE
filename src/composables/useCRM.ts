import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'

export function useCRM() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchCustomerFeedback() {
    loading.value = true
    error.value = null
    try {
      if (!activeBranchId.value) throwBranchGuard()
      const { data, error: err } = await supabase
        .from('customer_feedback')
        .select('*, customer:customers(name, phone)')
        .eq('branch_id', activeBranchId.value)
        .order('created_at', { ascending: false })
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
      if (!activeBranchId.value) throwBranchGuard()
      const { data, error: err } = await supabase
        .from('service_requests')
        .select('*, table:tables(name)')
        .eq('branch_id', activeBranchId.value)
        .order('created_at', { ascending: false })
      if (err) throw err
      return data || []
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
    fetchCustomerFeedback,
    fetchServiceRequests
  }
}
