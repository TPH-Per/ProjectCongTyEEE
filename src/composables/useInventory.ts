import { ref, computed, watch, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import { useI18nStore } from '@/stores/i18n'
import type { RealtimeChannel } from '@supabase/supabase-js'

export interface InventoryItemWithAlerts {
  ingredient_id: string
  sku: string
  name_vi: string
  name_en: string
  name_ja: string
  unit: string
  unit_cost: number
  category_id: string
  category_name_vi: string
  quantity: number
  low_stock_threshold: number
  is_low_stock: boolean
  next_expiry_date: string | null
}

function daysUntil(dateStr: string) {
  const d1 = new Date()
  d1.setHours(0, 0, 0, 0)
  const d2 = new Date(dateStr)
  d2.setHours(0, 0, 0, 0)
  return Math.floor((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24))
}

export function useInventory() {
  const { activeBranchId } = useBranch()
  const i18n = useI18nStore()
  
  const inventory = ref<InventoryItemWithAlerts[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  let subscription: RealtimeChannel | null = null

  const lowStockItems = computed(() => {
    return inventory.value.filter(i => i.is_low_stock)
  })

  const expiringItems = computed(() => {
    return inventory.value.filter(i => i.next_expiry_date && daysUntil(i.next_expiry_date) <= 3)
  })

  function handleError(err: any): string {
    const msg = err?.message || String(err)
    if (msg.includes('INSUFFICIENT_STOCK')) {
      return i18n.t('errors.insufficient_stock') || 'Not enough stock'
    }
    return msg
  }

  async function fetchInventory() {
    if (!activeBranchId.value) return
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .rpc('get_inventory_with_alerts', { p_branch_id: activeBranchId.value })
      
      if (err) throw err
      inventory.value = (data as InventoryItemWithAlerts[]) || []
    } catch (err: any) {
      error.value = handleError(err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function addStock(
    ingredientId: string, 
    quantity: number, 
    type: 'IN' | 'OUT' | 'ADJUST' | 'WASTE' | 'TRANSFER_IN' | 'TRANSFER_OUT', 
    note?: string, 
    expiryDate?: string
  ) {
    if (!activeBranchId.value) throw new Error('No active branch')
    error.value = null
    try {
      const { data, error: err } = await supabase
        .rpc('create_inventory_transaction', {
          p_branch_id: activeBranchId.value,
          p_ingredient_id: ingredientId,
          p_type: type,
          p_quantity: quantity,
          p_note: note || null,
          p_expiry_date: expiryDate || null,
          p_reference_type: null,
          p_reference_id: null,
          p_unit_cost: null,
          p_created_by: undefined
        })
        
      if (err) throw err
      return data
    } catch (err: any) {
      error.value = handleError(err)
      throw err
    }
  }

  async function adjustStock(ingredientId: string, newQty: number) {
    const item = inventory.value.find(i => i.ingredient_id === ingredientId)
    if (!item) throw new Error('Item not found in current inventory')
    
    const delta = newQty - item.quantity
    if (delta === 0) return
    
    return addStock(ingredientId, delta, 'ADJUST', 'Stock adjustment')
  }

  function subscribeToStockUpdates() {
    if (!activeBranchId.value) return
    if (subscription) {
      supabase.removeChannel(subscription)
    }
    subscription = supabase.channel(`inventory_stock_${activeBranchId.value}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'inventory_stock', filter: `branch_id=eq.${activeBranchId.value}` },
        () => {
          fetchInventory()
        }
      )
      .subscribe()
  }

  function unsubscribe() {
    if (subscription) {
      supabase.removeChannel(subscription)
      subscription = null
    }
  }

  // Refetch and resubscribe when branch changes
  watch(activeBranchId, (newBranch) => {
    if (newBranch) {
      fetchInventory()
      subscribeToStockUpdates()
    } else {
      inventory.value = []
      unsubscribe()
    }
  }, { immediate: true })

  onUnmounted(() => {
    unsubscribe()
  })

  // To preserve backwards-compatibility from the previous useInventory version
  async function listLowStock() {
    if (inventory.value.length === 0) {
      await fetchInventory()
    }
    return lowStockItems.value
  }

  return {
    inventory,
    loading,
    error,
    lowStockItems,
    expiringItems,
    fetchInventory,
    addStock,
    adjustStock,
    subscribeToStockUpdates,
    unsubscribe,
    listLowStock
  }
}
