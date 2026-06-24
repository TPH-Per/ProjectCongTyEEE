import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { Reservation } from '@/types/database'

export function useReservation() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listByDate(date: string): Promise<Reservation[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('reservations')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .eq('reservation_date', date)
      .order('reservation_time')
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as Reservation[]
  }

  async function getById(id: string): Promise<Reservation | null> {
    const { data, error: err } = await supabase
      .from('reservations')
      .select('*')
      .eq('id', id)
      .single<Reservation>()
    if (err) throw err
    return data ?? null
  }

  async function create(payload: Partial<Reservation>): Promise<Reservation> {
    const insert = { ...payload, branch_id: activeBranchId.value }
    const { data, error: err } = await supabase
      .from('reservations')
      .insert(insert)
      .select('*')
      .single<Reservation>()
    if (err) throw err
    return data!
  }

  async function update(id: string, patch: Partial<Reservation>): Promise<Reservation> {
    const { data, error: err } = await supabase
      .from('reservations')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single<Reservation>()
    if (err) throw err
    return data!
  }

  async function cancel(id: string, reason: string): Promise<void> {
    const { error: err } = await supabase
      .from('reservations')
      .update({
        status: 'Cancelled',
        cancelled_at: new Date().toISOString(),
        cancel_reason: reason,
      })
      .eq('id', id)
    if (err) throw err
  }

  return { loading, error, listByDate, getById, create, update, cancel }
}
