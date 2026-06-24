import { ref } from 'vue'
import { callEdgeFunction } from '@/utils/edge'

export interface AddOrderItemPayload {
  order_id: string
  menu_item_id: string
  quantity: number
  modifiers?: Record<string, unknown>[]
  note?: string
}

export interface AddOrderItemResponse {
  order_item_id: string
  line_total: number
  subtotal: number
  total: number
}

export function useOrder() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function addItem(
    payload: AddOrderItemPayload,
  ): Promise<AddOrderItemResponse> {
    loading.value = true
    error.value = null
    try {
      return await callEdgeFunction<AddOrderItemPayload, AddOrderItemResponse>(
        'add-order-item',
        payload,
      )
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, addItem }
}
