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
  code?: string
  name: string
  unit: string
  category: string
  cost_per_unit?: number
  min_stock_level?: number
  is_active?: boolean
  branch_id?: string
}

export interface IngredientStats {
  id?: string
  code?: string
  name?: string
  unit?: string
  category?: string
  cost_per_unit?: number
  min_stock_level?: number
  is_active?: boolean
  branch_id?: string
  imported_this_week?: number
  imported_this_month?: number
}

export interface GoodsReceipt {
  id: string
  branch_id?: string
  receipt_code?: string
  receipt_date?: string
  supplier_id?: string
  supplier_name?: string
  total_amount?: number
  status?: string
  notes?: string
  created_at: string
  branch_name?: string
  items_jsonb?: any[]
}

export interface Requisition {
  id: string
  branch_id?: string
  requisition_date?: string
  status?: string
  priority?: string
  notes?: string
  branch_name?: string
  requisition_code?: string
  req_number?: string
  selected_quote_id?: string
  quotes_jsonb?: any[]
  created_at: string
}

export interface RequisitionItem {
  id?: string
  requisition_id?: string
  ingredient_id: string
  ingredient_name?: string
  quantity: number
  unit?: string
  estimated_price?: number
  notes?: string
}

export interface QuoteItem {
  id: string
  requisition_id?: string
  supplier_id?: string
  supplier_name?: string
  product_url?: string
  ingredient_id?: string
  quoted_price?: number
  quantity?: number
  valid_until?: string
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

export async function getGoodsReceipts(limit = 100, branchId?: string): Promise<GoodsReceipt[]> {
  const args: any = { p_limit: limit }
  if (branchId) args.p_branch_id = branchId
  const { data, error } = await supabase.rpc('get_goods_receipts', args)
  if (error) throw error
  return data || []
}

export async function getRequisitions(branchId?: string, status?: string): Promise<Requisition[]> {
  const args: any = {}
  if (branchId) args.p_branch_id = branchId
  if (status) args.p_status = status
  const { data, error } = await supabase.rpc('get_requisitions', args)
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

export async function getIngredientStats(branchId?: string): Promise<IngredientStats[]> {
  const args = branchId ? { p_branch_id: branchId } : {}
  const { data, error } = await supabase.rpc('get_ingredient_import_stats', args)
  if (error) throw error
  return data as IngredientStats[]
}

/**
 * ==========================================
 * 3. API HÀNH ĐỘNG (MUTATIONS / TRANSACTIONS)
 * ==========================================
 */

export async function createRequisition(
  items: Partial<RequisitionItem>[], 
  quotes: Partial<QuoteItem>[], 
  notes: string, 
  branchId?: string
): Promise<string> {
  const { data, error } = await supabase.rpc('create_requisition', {
    p_items: items,
    p_quotes: quotes,
    p_notes: notes,
    p_branch_id: branchId
  })
  if (error) throw error
  return data
}

export async function approveRequisition(id: string, quoteId: string): Promise<void> {
  const { error } = await supabase.rpc('approve_requisition', { 
    p_requisition_id: id,
    p_quote_id: quoteId 
  })
  if (error) throw error
}

export async function saveIngredient(ingredient: Partial<Ingredient>): Promise<void> {
  const { error } = await supabase.rpc('save_ingredient', { p_ingredient: ingredient })
  if (error) throw error
}

export async function recordInventoryTx(
  ingredientId: string, 
  type: 'IN' | 'OUT' | 'ADJUST' | 'PURCHASE', 
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
