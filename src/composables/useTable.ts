import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Zone, TableT, TableStatus } from '@/types/database'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'

export function useTable() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listZones(): Promise<Zone[]> {
    loading.value = true
    error.value = null
    const tables = await listTables()
    loading.value = false
    const unique = [...new Set((tables || []).map((t: any) => t.zone))]
    return unique.map(z => ({
      id: String(z),
      branch_id: (activeBranchId.value ?? throwBranchGuard()),
      name: String(z),
      color: '#4ade80' // default color
    })) as Zone[]
  }

  async function listTables(): Promise<TableT[]> {
    const { data, error: err } = await supabase.rpc('hall_list_tables', {
      p_branch_id: activeBranchId.value ?? throwBranchGuard(),
    })

    if (err) {
      console.error('Error fetching tables:', err)
      return []
    }
    return data as TableT[]
  }

  async function updateStatus(tableId: string, status: TableStatus): Promise<void> {
    throw new Error(
      `Direct table status updates are not allowed from the frontend (${tableId} -> ${status}). Use a Hall RPC/action flow.`,
    )
  }

  return { loading, error, listZones, listTables, updateStatus }
}
