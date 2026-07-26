import { ref, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useI18nStore } from '@/stores/i18n'

export interface TabletContent {
  id: string
  branch_id: string
  content_type?: string
  type?: string
  title_vi: string | null
  title_en: string | null
  title_ja: string | null
  body_vi: string | null
  body_en: string | null
  body_ja: string | null
  image_url: string | null
  display_order: number
  is_active: boolean
  valid_from: string | null
  valid_until: string | null
  created_at: string
}

export interface TabletSession {
  id: string
  branch_id: string
  table_id: string
  status: 'IDLE' | 'ACTIVE' | 'CHECKOUT_REQUESTED' | 'ENDED'
  language: 'vi' | 'en' | 'ja'
  order_id: string | null
  started_at: string | null
  ended_at?: string | null
  last_activity_at: string
}

export function useTablet() {
  const content = ref<TabletContent[]>([])
  const currentSession = ref<TabletSession | null>(null)
  let realtimeChannel: ReturnType<typeof supabase.channel> | null = null

  // Fetch idle-screen content
  async function fetchContent(branchId: string) {
    const { data, error } = await supabase.rpc('customer_get_tablet_content', {
      p_branch_id: branchId,
    })
    if (error) throw error
    content.value = (data ?? []) as TabletContent[]
    return content.value
  }

  // Touch screen → transition IDLE → ACTIVE
  async function activateSession(tableId: string, branchId: string) {
    const { data, error } = await supabase.rpc('customer_activate_tablet_session', {
      p_branch_id: branchId,
      p_table_id: tableId,
    })
    if (error) throw error
    currentSession.value = data as TabletSession
    localStorage.setItem('tablet_session_id', currentSession.value.id)
    localStorage.setItem('tablet_table_id', currentSession.value.table_id)
    localStorage.setItem('tablet_branch_id', currentSession.value.branch_id)
    return data
  }

  // Set language and sync to session
  async function setLanguage(tableId: string, lang: 'vi' | 'en' | 'ja') {
    let sessionId = currentSession.value?.id || localStorage.getItem('tablet_session_id')
    if (!sessionId) {
      const branchId = localStorage.getItem('tablet_branch_id')
      if (!branchId) throw new Error('Tablet session is not active')
      const session = await activateSession(tableId, branchId)
      sessionId = session.id
    }

    const { data, error } = await supabase.rpc('customer_set_tablet_language', {
      p_session_id: sessionId,
      p_language: lang,
    })
      
    if (error) throw error
    currentSession.value = data as TabletSession
    
    // Also update Pinia language store
    const languageStore = useI18nStore()
    languageStore.setLocale(lang)
  }

  // Realtime subscription — auto react when order created or status changes
  function subscribeToSession(tableId: string, onUpdate?: (s: TabletSession) => void) {
    unsubscribe()
    
    realtimeChannel = supabase
      .channel(`tablet_session_${tableId}`)
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'tablet_sessions',
        filter: `table_id=eq.${tableId}`
      }, payload => {
        const session = payload.new as TabletSession
        currentSession.value = session
        if (onUpdate) onUpdate(session)
      })
      .subscribe()
  }
  
  function unsubscribe() {
    if (realtimeChannel) {
      supabase.removeChannel(realtimeChannel)
      realtimeChannel = null
    }
  }
  
  onUnmounted(() => {
    unsubscribe()
  })

  return {
    content,
    currentSession,
    fetchContent,
    activateSession,
    setLanguage,
    subscribeToSession,
    unsubscribe
  }
}
