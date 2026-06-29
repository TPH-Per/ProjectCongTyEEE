import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Zone, TableT, TableStatus } from '@/types/database'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'

export function useTable() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listZones(): Promise<Zone[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('tables')
      .select('zone')
      .eq('branch_id', (activeBranchId.value ?? throwBranchGuard()))
      .eq('is_active', true)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const unique = [...new Set((data || []).map((t: any) => t.zone))]
    return unique.map(z => ({
      id: z,
      branch_id: (activeBranchId.value ?? throwBranchGuard()),
      name: z,
      color: '#4ade80' // default color
    })) as Zone[]
  }

  async function listTables(): Promise<TableT[]> {
    const { data, error: err } = await supabase
      .from('tables')
      .select('*')
      .eq('branch_id', (activeBranchId.value ?? throwBranchGuard()))
      .eq('is_active', true)

    if (err) {
      console.error('Error fetching tables:', err)
      return []
    }
    return data as TableT[]
  }

  async function updateStatus(tableId: string, status: TableStatus): Promise<void> {
    const { error: err } = await supabase
      .from('tables')
      .update({ status })
      .eq('id', tableId)
    if (err) throw err
  }

  return { loading, error, listZones, listTables, updateStatus }
}

