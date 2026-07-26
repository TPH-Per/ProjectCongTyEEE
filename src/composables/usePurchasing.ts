import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function usePurchasing() {
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  const suppliers = ref<any[]>([])
  const ingredients = ref<any[]>([])
  const currentStock = ref<any[]>([])

  // 1. Submit Goods Receipt (RPC) - use submit_goods_receipt
  const submitGoodsReceipt = async (
    branchId: string,
    receiptCode: string,
    supplierId: string,
    scanImageUrl: string,
    items: Array<any>
  ) => {
    loading.value = true
    error.value = null
    
    try {
      const { data, error: submitError } = await supabase.rpc('submit_goods_receipt', {
        p_branch_id: branchId,
        p_receipt_code: receiptCode,
        p_supplier_id: supplierId,
        p_purchase_order_id: null,
        p_scan_image_url: scanImageUrl,
        p_items: items
      })

      if (submitError) throw submitError
      
      return true
    } catch (err: any) {
      console.error('Error submitting goods receipt:', err)
      error.value = err.message || 'Lỗi khi nhập hàng'
      throw err
    } finally {
      loading.value = false
    }
  }

  // 2. Lấy danh sách Nhà cung cấp (RPC)
  const fetchSuppliers = async () => {
    try {
      const { data, error: fetchError } = await supabase.rpc('get_suppliers')
      if (fetchError) throw fetchError
      suppliers.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching suppliers:', err)
      return []
    }
  }

  // 3. Lấy danh sách Nguyên vật liệu (RPC)
  const fetchIngredients = async () => {
    try {
      const { data, error: fetchError } = await supabase.rpc('get_ingredients')
      if (fetchError) throw fetchError
      ingredients.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching ingredients:', err)
      return []
    }
  }

  // 4. Lấy tồn kho hiện tại (RPC)
  const fetchCurrentStock = async (branchId?: string) => {
    try {
      const { data, error: fetchError } = await supabase.rpc('get_current_stock', {
        p_branch_id: branchId || undefined
      })
      if (fetchError) throw fetchError
      currentStock.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching current stock:', err)
      return []
    }
  }

  // 5. Nộp phiếu kiểm kho (Audit)
  const submitAudit = async (
    items: Array<{ item_id: string; new_quantity: number; notes: string }>
  ) => {
    loading.value = true
    error.value = null
    try {
      const promises = items.map(item => {
        return supabase.rpc('record_inventory_transaction', {
          p_ingredient_id: item.item_id,
          p_transaction_type: 'ADJUST',
          p_quantity: item.new_quantity,
          p_unit_cost: 0,
          p_supplier_id: null,
          p_notes: 'Kiểm kho: ' + item.notes
        })
      })

      const results = await Promise.all(promises)
      for (const result of results) {
        if (result.error) throw result.error
      }
      return true
    } catch (err: any) {
      console.error('Error submitting audit:', err)
      error.value = err.message || 'Lỗi khi lưu kiểm kho'
      throw err
    } finally {
      loading.value = false
    }
  }

  // 6. Upload ảnh scan phiếu giao hàng (Lên Supabase Storage)
  const uploadScanImage = async (file: File) => {
    try {
      const fileExt = file.name.split('.').pop()
      const fileName = `${Math.random()}.${fileExt}`
      const filePath = `receipts/${fileName}`

      const { error: uploadError, data } = await supabase.storage
        .from('purchasing')
        .upload(filePath, file)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('purchasing')
        .getPublicUrl(filePath)

      return publicUrl
    } catch (err: any) {
      console.error('Error uploading scan image:', err)
      throw err
    }
  }

  const fetchPurchaseOrders = async () => [];
  return {
    fetchPurchaseOrders,
    loading,
    error,
    suppliers,
    ingredients,
    currentStock,
    submitGoodsReceipt,
    fetchSuppliers,
    fetchIngredients,
    fetchCurrentStock,
    submitAudit,
    uploadScanImage
  }
}
