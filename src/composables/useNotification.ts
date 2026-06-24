import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { Notification } from '@/types/database'

export function useNotification() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listForRole(role: string, limit = 50): Promise<Notification[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('notifications')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .eq('channel', role)
      .order('created_at', { ascending: false })
      .limit(limit)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as Notification[]
  }

  async function markRead(id: string): Promise<void> {
    const { error: err } = await supabase
      .from('notifications')
      .update({ status: 'read' })
      .eq('id', id)
    if (err) throw err
  }

  return { loading, error, listForRole, markRead }
}
