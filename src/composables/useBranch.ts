import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'
import type { Branch } from '@/types/database'

const STORAGE_KEY = 'ngu-cat.selectedBranch'

export function throwBranchGuard(): never {
  throw new Error('No active branch selected. Please select a branch first.')
}

/**
 * Active-branch selector for admin/superadmin who can view multiple branches.
 *
 * For non-admin users the active branch is always the one stored on their
 * `users.branch_id`. Admin users can override via `selectBranch()` and the
 * choice persists in localStorage.
 */
export function useBranch() {
  const { branchId: defaultBranchId, isAdmin } = useAuth()
  const selectedBranchId = ref<string | null>(
    typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null,
  )

  const activeBranchId = computed<string | undefined | null>(() => {
    if (isAdmin.value) {
      if (selectedBranchId.value === 'all') return null
      if (selectedBranchId.value) return selectedBranchId.value
    }
    return defaultBranchId.value
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
    const { data, error } = await supabase
      .from('branches')
      .insert(input)
      .select()
      .single()
    if (error) throw error
    return data as Branch
  }

  // UPDATE
  async function updateBranch(id: string, patch: Partial<Branch>): Promise<Branch> {
    const { data, error } = await supabase
      .from('branches')
      .update({ ...patch, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Branch
  }

  // TOGGLE ACTIVE STATUS
  async function toggleBranchStatus(id: string, isActive: boolean): Promise<void> {
    const { error } = await supabase
      .from('branches')
      .update({ is_active: isActive })
      .eq('id', id)
    if (error) throw error
  }

  // LIST (with manager profile joined, one query)
  async function listBranches(): Promise<Branch[]> {
    const { data, error } = await supabase
      .from('branches')
      .select(`*`)
      .order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as Branch[]
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
