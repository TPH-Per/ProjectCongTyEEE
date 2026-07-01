import { supabase } from '@/lib/supabase'

export interface Supplier {
  id: string
  name: string
  contact_info: string
  tax_code: string
  payment_terms: string
}

export interface Ingredient {
  id: string
  name: string
  unit: string
  category: string
}

export interface CurrentStock {
  id: string
  ingredient_id: string
  ingredient_name: string
  unit: string
  quantity: number
  last_updated: string
}

export interface InventoryTransaction {
  id: string
  transaction_type: string
  ingredient_name: string
  unit: string
  quantity: number
  unit_cost: number
  supplier_name: string
  notes: string
  created_at: string
}

/**
 * ==========================================
 * 1. API LẤY DỮ LIỆU NỀN (GET DATA)
 * ==========================================
 */

export async function getSuppliers(): Promise<Supplier[]> {
  const { data, error } = await supabase.rpc('get_suppliers')
  if (error) throw error
  return data || []
}

export async function getIngredients(): Promise<Ingredient[]> {
  const { data, error } = await supabase.rpc('get_ingredients')
  if (error) throw error
  return data || []
}

/**
 * ==========================================
 * 2. API THEO DÕI TỒN KHO & LỊCH SỬ (MONITORING)
 * ==========================================
 */

export async function getCurrentStock(branchId?: string): Promise<CurrentStock[]> {
  const args = branchId ? { p_branch_id: branchId } : {}
  const { data, error } = await supabase.rpc('get_current_stock', args)
  if (error) throw error
  return data || []
}

export async function getInventoryTransactions(limit = 100, branchId?: string): Promise<InventoryTransaction[]> {
  const args: any = { p_limit: limit }
  if (branchId) args.p_branch_id = branchId
  
  const { data, error } = await supabase.rpc('get_inventory_transactions', args)
  if (error) throw error
  return data || []
}

/**
 * ==========================================
 * 3. API HÀNH ĐỘNG (MUTATIONS / TRANSACTIONS)
 * ==========================================
 */

export async function recordInventoryTx(
  ingredientId: string, 
  type: 'IN' | 'OUT' | 'ADJUST', 
  quantity: number, 
  unitCost = 0, 
  supplierId: string | null = null, 
  notes = ''
) {
  const { data: transactionId, error } = await supabase.rpc('record_inventory_transaction', {
    p_ingredient_id: ingredientId,
    p_transaction_type: type,
    p_quantity: quantity,
    p_unit_cost: unitCost,
    p_supplier_id: supplierId,
    p_notes: notes
  })
  
  if (error) throw error 
  return transactionId
}

// ---- CÁC HÀM GỌI NHANH TRÊN GIAO DIỆN ----

export async function purchaseItem(ingredientId: string, supplierId: string, qty: number, price: number, note = '') {
  return await recordInventoryTx(ingredientId, 'IN', qty, price, supplierId, note)
}

export async function discardItem(ingredientId: string, qty: number, note = '') {
  return await recordInventoryTx(ingredientId, 'OUT', qty, 0, null, note)
}

export async function adjustStockLogic(ingredientId: string, actualQtyCounted: number, note = '') {
  return await recordInventoryTx(ingredientId, 'ADJUST', actualQtyCounted, 0, null, note)
}
