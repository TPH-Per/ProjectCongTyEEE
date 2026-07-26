import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { AuditEvent } from '@/types/database'

export function useAudit() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listRecent(limit = 100): Promise<AuditEvent[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('audit_events')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as AuditEvent[]
  }

  async function listByEntity(
    entityType: string,
    entityId: string,
  ): Promise<AuditEvent[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('audit_events')
      .select('*')
      .eq('entity_type', entityType)
      .eq('entity_id', entityId)
      .order('created_at', { ascending: false })
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as AuditEvent[]
  }

  return { loading, error, listRecent, listByEntity }
}
