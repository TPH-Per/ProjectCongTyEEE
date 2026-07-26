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

type Listener<T> = (payload: ChangePayload<T>) => void

/**
 * Module-level dedup state. Each entry holds:
 *   - ch: the shared RealtimeChannel
 *   - listeners: every subscriber's onChange callback (one per `watchTable`
 *     call). The channel broadcasts every event to all listeners.
 *   - ref: total subscriber count; the channel is torn down only when the
 *     last subscriber unmounts.
 *   - status: the latest channel status from the first subscriber's
 *     `subscribe()` callback so late joiners can adopt it.
 *
 * Why a single Map (instead of separate `channels` and `channelRefs` Maps):
 * the previous design had a silent-bug where a SECOND subscriber to the
 * same `(table, event, filter)` tuple never had its callback wired up —
 * the channel was reused as-is and the new `onChange` was discarded
 * because the `if (!ch)` guard skipped the `.on(...)` call entirely.
 * Now every callback lives in a Set the channel can fan out to.
 */
interface ChannelEntry<T = unknown> {
  ch: RealtimeChannel
  listeners: Set<Listener<T>>
  ref: number
  status: RealtimeStatus
}
const registry = new Map<string, ChannelEntry<any>>()

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
 * bumps the entry's reference count and ADDS the callback to the listener
 * set; the underlying channel is torn down only when the LAST subscriber
 * unmounts. This avoids two bugs we previously had:
 *   1. Silent-disconnect: unmounting one component closed the channel for
 *      everyone else.
 *   2. Lost-callback: a second subscriber's onChange was silently dropped
 *      because the channel was reused without re-wiring.
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
    let entry = registry.get(channelName) as ChannelEntry<T> | undefined

    if (!entry) {
      const listeners = new Set<Listener<T>>()
      const ch = supabase
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
          (payload: ChangePayload<T>) => {
            // Fan out to every subscriber. Iterating over a Set is safe
            // while callbacks may themselves remove listeners — a
            // callback that triggers `cleanup()` only removes itself
            // from the local copy thanks to the spread.
            for (const cb of Array.from(listeners)) {
              try { cb(payload) } catch (e) {
                console.warn('[useRealtime] listener threw:', e)
              }
            }
          },
        )
        .subscribe((s) => {
          // The first subscriber owns the channel-level status mirror so
          // late joiners can pick it up.
          const next: RealtimeStatus =
            s === 'SUBSCRIBED' ? 'connected'
              : s === 'CLOSED' ? 'disconnected'
              : s === 'CHANNEL_ERROR' ? 'error'
              : 'connecting'
          entry!.status = next
        })
      entry = { ch, listeners, ref: 0, status: 'connecting' }
      registry.set(channelName, entry)
    }

    entry.listeners.add(onChange)
    entry.ref += 1
    // Adopt the latest channel status so this composable's `status` ref
    // doesn't sit at `disconnected` while the channel is actually live.
    status.value = entry.status

    function cleanup() {
      const e = registry.get(channelName)
      if (!e) return
      e.listeners.delete(onChange)
      e.ref = Math.max(0, e.ref - 1)
      activeCleanups.delete(cleanup)
      if (e.ref <= 0) {
        supabase.removeChannel(e.ch)
        registry.delete(channelName)
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
