import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Feedback {
  id: string
  branch_id: string
  order_id: string
  customer_id?: string
  rating: number
  comment?: string
  created_at: string
}

export function useFeedback() {
  const feedbacks = ref<Feedback[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listFeedback(): Promise<Feedback[]> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.from('customer_feedback').select('*').order('created_at', { ascending: false })
      if (err) throw err
      feedbacks.value = data as Feedback[]
      return feedbacks.value
    } catch (e: any) {
      error.value = e.message
      return []
    } finally {
      loading.value = false
    }
  }

  async function submitFeedback(params: {
    orderId: string
    rating: number
    comment?: string
    customerId?: string
  }): Promise<string> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('record_customer_feedback', {
        p_order_id: params.orderId,
        p_rating: params.rating,
        p_comment: params.comment || null,
        p_customer_id: params.customerId || null
      })
      if (err) throw err
      return data as string
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    feedbacks, loading, error,
    listFeedback, submitFeedback
  }
}
