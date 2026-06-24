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

const channels = new Map<string, RealtimeChannel>()

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
 * to the same `(table, event, filter)` triple share one websocket.
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
    }

    let refCount = 1
    const refCounts = (channels.get(channelName) as unknown as { _ref?: number })._ref ?? 1

    function cleanup() {
      refCount -= 1
      const existing = channels.get(channelName)
      if (!existing) return
      if (refCount <= 0) {
        supabase.removeChannel(existing)
        channels.delete(channelName)
        activeCleanups.delete(cleanup)
      }
    }
    void refCounts
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
