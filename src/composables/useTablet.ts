import { ref, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useI18nStore } from '@/stores/i18n'

export interface TabletContent {
  id: string
  branch_id: string
  content_type: string
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
  status: 'IDLE' | 'ACTIVE' | 'ORDERING' | 'AWAITING_PAYMENT'
  language: 'vi' | 'en' | 'ja'
  order_id: string | null
  started_at: string | null
  last_activity_at: string
}

export function useTablet() {
  const content = ref<TabletContent[]>([])
  const currentSession = ref<TabletSession | null>(null)
  let realtimeChannel: ReturnType<typeof supabase.channel> | null = null

  // Fetch idle-screen content
  async function fetchContent(branchId: string) {
    const now = new Date().toISOString()
    const { data, error } = await supabase
      .from('tablet_content')
      .select('*')
      .eq('branch_id', branchId)
      .eq('is_active', true)
      .or(`valid_from.is.null,valid_from.lte.${now}`)
      .or(`valid_until.is.null,valid_until.gte.${now}`)
      .order('display_order', { ascending: true })
    
    if (error) throw error
    content.value = data as TabletContent[]
    return data
  }

  // Touch screen → transition IDLE → ACTIVE
  async function activateSession(tableId: string, branchId: string) {
    const { data, error } = await supabase
      .from('tablet_sessions')
      .upsert(
        {
          table_id: tableId,
          branch_id: branchId,
          status: 'ACTIVE',
          started_at: new Date().toISOString(),
          last_activity_at: new Date().toISOString()
        },
        { onConflict: 'table_id' }
      )
      .select()
      .single()
      
    if (error) throw error
    currentSession.value = data as TabletSession
    return data
  }

  // Set language and sync to session
  async function setLanguage(tableId: string, lang: 'vi' | 'en' | 'ja') {
    const { error } = await supabase
      .from('tablet_sessions')
      .update({ language: lang, last_activity_at: new Date().toISOString() })
      .eq('table_id', tableId)
      
    if (error) throw error
    
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
