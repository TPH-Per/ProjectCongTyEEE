import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'
import type { Customer } from '@/types/database'

export function useCustomer() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function searchByPhone(phone: string): Promise<Customer[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('customers')
      .select('*')
      .eq('branch_id', (activeBranchId.value ?? throwBranchGuard()))
      .eq('phone', phone)
      .limit(5)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as Customer[]
  }

  async function upsert(payload: Partial<Customer>): Promise<Customer> {
    const insert = { ...payload, branch_id: activeBranchId.value }
    const { data, error: err } = await supabase
      .from('customers')
      .upsert(insert)
      .select('*')
      .single<Customer>()
    if (err) throw err
    return data!
  }

  async function listVip(): Promise<Customer[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('customers')
      .select('*')
      .eq('branch_id', (activeBranchId.value ?? throwBranchGuard()))
      .eq('is_vip', true)
      .order('total_spent', { ascending: false })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as Customer[]
  }

  // Full profile with loyalty data
  async function getCustomerProfile(customerId: string): Promise<any> {
    const { data, error } = await supabase
      .rpc('get_customer_with_loyalty', { p_customer_id: customerId })
    if (error) throw error
    return data
  }

  // Paginated list with tier join (replaces existing flat query)
  async function listCustomers(params?: {
    search?: string;
    tierId?: string;
    limit?: number;
    offset?: number;
    sortBy?: string;
  }) {
    const { data, error } = await supabase.rpc('list_customers_with_tier', {
      p_branch_id: (activeBranchId.value ?? throwBranchGuard()),
      p_search:    params?.search ?? null,
      p_tier_id:   params?.tierId ?? null,
      p_limit:     params?.limit ?? 30,
      p_offset:    params?.offset ?? 0,
      p_sort_by:   params?.sortBy ?? 'total_spent'
    });
    if (error) throw error;
    return data; // { customers: [...], total: number }
  }

  // CRM Dashboard stats (replaces all hardcoded vars in ManagerCRMView.vue)
  async function fetchCrmStats() {
    const { data } = await supabase
      .rpc('get_crm_dashboard_stats', { p_branch_id: (activeBranchId.value ?? throwBranchGuard()) });
    return data;
  }

  return { loading, error, searchByPhone, upsert, listVip, getCustomerProfile, listCustomers, fetchCrmStats }
}

