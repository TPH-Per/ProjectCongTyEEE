import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'
import type { Branch } from '@/types/database'

const STORAGE_KEY = 'ngu-cat.selectedBranch'

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

  const activeBranchId = computed<string | undefined>(() => {
    if (isAdmin.value && selectedBranchId.value) return selectedBranchId.value
    return defaultBranchId.value
  })

  function selectBranch(id: string | null) {
    selectedBranchId.value = id
    if (typeof window === 'undefined') return
    if (id) localStorage.setItem(STORAGE_KEY, id)
    else localStorage.removeItem(STORAGE_KEY)
  }

  async function listBranches(): Promise<Branch[]> {
    const { data, error } = await supabase
      .from('branches')
      .select('id, code, name, address, phone, is_active')
      .eq('is_active', true)
      .order('name')
    if (error) throw error
    return (data ?? []) as Branch[]
  }

  return { activeBranchId, selectedBranchId, selectBranch, listBranches }
}
