import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function usePurchasing() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 1. Submit Goods Receipt (RPC)
  const submitGoodsReceipt = async (
    branchId: string,
    receiptCode: string,
    supplierName: string,
    scanImageUrl: string,
    items: Array<{ item_id: string; quantity: number; unit_price: number }>
  ) => {
    loading.value = true
    error.value = null
    
    try {
      const { data, error: rpcError } = await supabase.rpc('submit_goods_receipt', {
        p_branch_id: branchId,
        p_receipt_code: receiptCode,
        p_supplier_name: supplierName,
        p_scan_image_url: scanImageUrl,
        p_items: items
      })

      if (rpcError) throw rpcError
      return data // Returns the receipt ID
    } catch (err: any) {
      console.error('Error submitting goods receipt:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // 2. Lấy danh sách Nguyên vật liệu
  const inventoryItems = ref<any[]>([])
  const fetchInventoryItems = async (branchId: string) => {
    try {
      const { data, error: fetchError } = await supabase
        .from('inventory_items')
        .select('*')
        .eq('branch_id', branchId)
        .order('name')
      
      if (fetchError) throw fetchError
      inventoryItems.value = data || []
      return data
    } catch (err: any) {
      console.error('Error fetching inventory items:', err)
      return []
    }
  }

  // 3. Upload ảnh scan phiếu giao hàng (Lên Supabase Storage)
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

  return {
    loading,
    error,
    inventoryItems,
    submitGoodsReceipt,
    fetchInventoryItems,
    uploadScanImage
  }
}
