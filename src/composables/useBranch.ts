import { ref, computed } from 'vue'
import { useAuth } from './useAuth'
import type { Branch } from '@/types/database'

const STORAGE_KEY = 'ngu-cat.selectedBranch'
const selectedBranchId = ref<string | null>(
  typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null,
)

import { supabase } from '@/lib/supabase'

export function throwBranchGuard(): never {
  throw new Error('No active branch selected. Please select a branch first.')
}

export function useBranch() {
  const { branchId: defaultBranchId, isAdmin } = useAuth()

  const activeBranchId = computed<string | undefined | null>(() => {
    // Bắt buộc phải chọn chi nhánh cho tất cả mọi người theo yêu cầu
    return selectedBranchId.value
  })

  function selectBranch(id: string | null) {
    selectedBranchId.value = id
    if (typeof window === 'undefined') return
    if (id) localStorage.setItem(STORAGE_KEY, id)
    else localStorage.removeItem(STORAGE_KEY)
  }

  // CREATE
  async function createBranch(input: {
    name: string;
    address: string;
    phone: string;
    capacity: number;
    manager_id?: string;
    operating_hours?: Record<string, { open: string; close: string }>;
  }): Promise<Branch> {
    const { data, error } = await supabase.from('branches').insert([input]).select().single()
    if (error) throw error
    return data as Branch
  }

  // UPDATE
  async function updateBranch(id: string, patch: Partial<Branch>): Promise<Branch> {
    const { data, error } = await supabase.from('branches').update(patch).eq('branch_id', id).select().single()
    if (error) throw error
    return data as Branch
  }

  // TOGGLE ACTIVE STATUS
  async function toggleBranchStatus(id: string, isActive: boolean): Promise<void> {
    const { error } = await supabase.from('branches').update({ is_active: isActive }).eq('branch_id', id)
    if (error) throw error
  }

  // LIST (with manager profile joined, one query)
  async function listBranches(): Promise<Branch[]> {
    // Try RPC first; fall back to direct table query if RPC is unavailable.
    const { data: rpcData, error: rpcError } = await supabase.rpc('rpc_list_branches')
    if (!rpcError && rpcData) {
      return (rpcData || []).map((b: any) => ({
        ...b,
        id: b.branch_id ?? b.id,
      })) as Branch[]
    }

    // Fallback: direct table query
    const { data, error } = await supabase
      .from('branches')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })
    if (error) throw error
    return (data || []).map((b: any) => ({
      ...b,
      id: b.branch_id ?? b.id,
    })) as Branch[]
  }

  return {
    activeBranchId,
    selectedBranchId,
    selectBranch,
    createBranch,
    updateBranch,
    toggleBranchStatus,
    listBranches
  }
}
