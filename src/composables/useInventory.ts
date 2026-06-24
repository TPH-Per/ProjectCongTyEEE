import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'

export interface InventoryItem {
  id: string
  branch_id: string
  sku: string
  name: string
  unit: string
  qty_on_hand: number
  reorder_level: number | null
  cost_per_unit: number | null
  metadata: Record<string, unknown>
}

export function useInventory() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listLowStock(): Promise<InventoryItem[]> {
    loading.value = true
    error.value = null
    // No dedicated inventory_items table — fall back to a lightweight query
    // on the JSONB metadata field of `branch_settings` if it exists; the
    // placeholder implementation returns [] until the inventory module
    // is wired into the schema.
    const { data, error: err } = await supabase
      .from('branch_settings')
      .select('value')
      .eq('branch_id', activeBranchId.value!)
      .eq('key', 'inventory.low_stock')
      .maybeSingle()
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const items = (data?.value as { items?: InventoryItem[] } | null)?.items ?? []
    return items
  }

  return { loading, error, listLowStock }
}
