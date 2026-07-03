import { onUnmounted, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'

export type RealtimeEvent = 'INSERT' | 'UPDATE' | 'DELETE' | '*'
export type RealtimeStatus = 'connecting' | 'connected' | 'disconnected' | 'error'

interface ChangePayload<T> {
  eventType: RealtimeEvent | string
  new: T
  old: T
}

// Module-level dedup state. Channels and their reference counts are kept in
// separate maps so we never mutate RealtimeChannel objects (which the
// @supabase client expects to be opaque) and so the counts survive across
// multiple `useRealtime()` composable instances.
const channels = new Map<string, RealtimeChannel>()
const channelRefs = new Map<string, number>()

function buildPgFilter(
  branchId: string | undefined,
  extra?: Record<string, string | number>,
): string | undefined {
  const parts: string[] = []
  if (branchId) parts.push(`branch_id=eq.${branchId}`)
  if (extra) {
    for (const [k, v] of Object.entries(extra)) {
      parts.push(`${k}=eq.${v}`)
    }
  }
  return parts.length ? parts.join(',') : undefined
}

/**
 * Realtime subscriptions helper.
 *
 * `watchTable` deduplicates channels by name so multiple components subscribing
 * to the same `(table, event, filter)` triple share one websocket. Each call
 * bumps the channel's reference count; the underlying channel is only torn
 * down when the LAST subscriber unmounts. This avoids the silent-disconnect
 * bug where a single component unmounting would close the channel for
 * everyone else.
 */
export function useRealtime() {
  const { branchId } = useAuth()
  const status = ref<RealtimeStatus>('disconnected')
  const activeCleanups = new Set<() => void>()

  function watchTable<T = Record<string, unknown>>(
    table: string,
    event: RealtimeEvent,
    onChange: (payload: ChangePayload<T>) => void,
    filter?: Record<string, string | number>,
  ): () => void {
    const channelName = `watch:${table}:${event}:${JSON.stringify(filter ?? {})}`
    let ch = channels.get(channelName)

    if (!ch) {
      ch = supabase
        .channel(channelName)
        .on(
          // `postgres_changes` filter typings don't accept our dynamic filter object.
          'postgres_changes' as never,
          {
            event,
            schema: 'public',
            table,
            filter: buildPgFilter(branchId.value, filter),
          },
          (payload: ChangePayload<T>) => onChange(payload),
        )
        .subscribe((s) => {
          if (s === 'SUBSCRIBED') status.value = 'connected'
          else if (s === 'CLOSED') status.value = 'disconnected'
          else if (s === 'CHANNEL_ERROR') status.value = 'error'
        })
      channels.set(channelName, ch)
      channelRefs.set(channelName, 0)
    }

    channelRefs.set(channelName, (channelRefs.get(channelName) ?? 0) + 1)

    function cleanup() {
      const refs = (channelRefs.get(channelName) ?? 0) - 1
      channelRefs.set(channelName, Math.max(0, refs))
      const existing = channels.get(channelName)
      if (!existing) return
      if (refs <= 0) {
        supabase.removeChannel(existing)
        channels.delete(channelName)
        channelRefs.delete(channelName)
        activeCleanups.delete(cleanup)
      }
    }
    activeCleanups.add(cleanup)
    return cleanup
  }

  function cleanupAll() {
    for (const fn of Array.from(activeCleanups)) fn()
    activeCleanups.clear()
  }

  onUnmounted(cleanupAll)

  return { watchTable, status, cleanupAll }
}
