import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'

export interface PurchaseOrder {
  id: string
  po_number: string
  status: string
  supplier?: { name: string }
  total_amount: number
  expected_delivery_date?: string
}

export function usePurchaseOrder() {
  const purchaseOrders = ref<PurchaseOrder[]>([])
  const { activeBranchId } = useBranch()

  async function listPurchaseOrders(params?: {
    status?: string;
    supplierId?: string;
    dateFrom?: string;
    dateTo?: string;
  }): Promise<PurchaseOrder[]> {
    let query = supabase
      .from('purchase_orders')
      .select('*, supplier:supplier_id(name), items:purchase_order_items(*, ingredient:ingredient_id(name_vi,sku,unit))')
      .eq('branch_id', activeBranchId.value)
      .order('created_at', { ascending: false })
      
    if (params?.status) query = query.eq('status', params.status)
    if (params?.supplierId) query = query.eq('supplier_id', params.supplierId)
    if (params?.dateFrom) query = query.gte('created_at', params.dateFrom)
    if (params?.dateTo) query = query.lte('created_at', params.dateTo)

    const { data, error } = await query
    if (error) throw error
    purchaseOrders.value = data as any
    return data as any
  }

  async function createPurchaseOrder(input: {
    supplierId: string;
    items: Array<{ ingredientId: string; orderedQuantity: number; unit: string; unitPrice: number }>;
    expectedDeliveryDate?: string;
    notes?: string;
    sourceRequisitionId?: string;
  }): Promise<string> {
    const { data: userAuth } = await supabase.auth.getUser()
    const { data, error } = await supabase.rpc('create_purchase_order', {
      p_branch_id: activeBranchId.value,
      p_ordered_by: userAuth.user?.id,
      p_requisition_id: input.sourceRequisitionId || null,
      p_items: input.items.map(i => ({ ingredient_id: i.ingredientId, quantity: i.orderedQuantity, unit: i.unit, unit_price: i.unitPrice }))
    })
    if (error) throw error
    return data.po_id
  }

  async function receiveOrder(
    poId: string,
    receivedItems: Array<{
      purchaseOrderItemId: string;
      receivedQuantity: number;
      expiryDate?: string;
    }>
  ): Promise<void> {
    const { data: userAuth } = await supabase.auth.getUser()
    const { error } = await supabase.rpc('receive_purchase_order', {
      p_po_id: poId,
      p_received_by: userAuth.user?.id,
      p_items: receivedItems.map(i => ({ item_id: i.purchaseOrderItemId, received_quantity: i.receivedQuantity }))
    })
    if (error) throw error
  }

  async function cancelPurchaseOrder(poId: string, reason?: string): Promise<void> {
    const { error } = await supabase.from('purchase_orders').update({ status: 'CANCELLED', notes: reason }).eq('id', poId)
    if (error) throw error
  }

  const pendingCount = computed(() =>
    purchaseOrders.value.filter(po =>
      ['SUBMITTED','CONFIRMED_BY_SUPPLIER','PARTIAL'].includes(po.status)
    ).length
  )

  return {
    purchaseOrders, pendingCount,
    listPurchaseOrders, createPurchaseOrder, receiveOrder, cancelPurchaseOrder
  }
}
