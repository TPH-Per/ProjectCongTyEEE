import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
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
      .eq('branch_id', activeBranchId.value!)
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
      .eq('branch_id', activeBranchId.value!)
      .eq('is_vip', true)
      .order('total_spent', { ascending: false })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as Customer[]
  }

  return { loading, error, searchByPhone, upsert, listVip }
}
