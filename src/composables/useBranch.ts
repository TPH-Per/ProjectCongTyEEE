import { ref, computed } from 'vue'
import { useAuth } from './useAuth'
import type { Branch } from '@/types/database'
import { BRANCH_IDS } from '@/lib/branch-constants'

const STORAGE_KEY = 'ngu-cat.selectedBranch'
const selectedBranchId = ref<string | null>(
  typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null,
)

import { supabase, isSupabaseConfigured } from '@/lib/supabase'

// Mock branches for when Supabase is not configured or queries fail.
// Uses the same UUIDs as branch-constants.ts for consistency.
const MOCK_BRANCHES: Branch[] = [
  {
    id: BRANCH_IDS.B001,
    code: 'B001',
    name: 'Ngưu Cát Quận 1',
    address: '123 Nguyễn Văn A, Quận 1, TP.HCM',
    phone: '028 1234 5678',
    timezone: 'Asia/Ho_Chi_Minh',
    currency: 'VND',
    vat_rate: 0.08,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: BRANCH_IDS.B002,
    code: 'B002',
    name: 'Ngưu Cát Phú Nhuận',
    address: '456 Lê Văn B, Phú Nhuận, TP.HCM',
    phone: '028 8765 4321',
    timezone: 'Asia/Ho_Chi_Minh',
    currency: 'VND',
    vat_rate: 0.08,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
]

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
    // Return mock data when Supabase is not configured
    if (!isSupabaseConfigured) {
      return MOCK_BRANCHES
    }

    try {
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
    } catch {
      return MOCK_BRANCHES
    }
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
