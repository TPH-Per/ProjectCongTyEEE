import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from './useBranch'

export interface Reservation {
  id: string
  branch_id: string
  guest_name?: string
  guest_phone?: string
  customer_snapshot?: Record<string, unknown>
  reservation_time: string
  reservation_date?: string
  guests: number
  guest_count?: number
  status: 'Pending' | 'Arrived' | 'Dining' | 'Completed' | 'Cancelled'
  notes?: string
  assigned_table_id?: string
  created_at: string
}

export interface ReservationStats {
  total: number
  pending: number
  seated: number
  completed: number
}

export function useReservation() {
  const { activeBranchId } = useBranch()
  const reservations = ref<Reservation[]>([])
  const stats = ref<ReservationStats | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function listReservations(params?: {
    date?: string
    status?: string
    search?: string
  }): Promise<{ reservations: Reservation[]; total: number }> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('hall_list_reservations_by_date', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
        p_date: params?.date || new Date().toISOString().split('T')[0],
      })
      if (err) throw err

      let rows = (data ?? []) as Reservation[]
      if (params?.date) {
        rows = rows.filter((r) => r.reservation_date === params.date)
      }
      if (params?.status) {
        rows = rows.filter((r) => r.status === params.status)
      }
      if (params?.search) {
        const q = params.search.toLowerCase()
        rows = rows.filter((r) => {
          const snap = r.customer_snapshot ?? {}
          return String(snap.name ?? r.guest_name ?? '').toLowerCase().includes(q)
            || String(snap.phone ?? r.guest_phone ?? '').toLowerCase().includes(q)
        })
      }

      rows = rows.sort((a, b) => String(a.reservation_time).localeCompare(String(b.reservation_time)))
      reservations.value = rows
      return { reservations: reservations.value, total: rows.length }
    } catch (e: any) {
      error.value = e.message
      return { reservations: [], total: 0 }
    } finally {
      loading.value = false
    }
  }

  async function fetchStats(date?: string): Promise<ReservationStats> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_reservation_stats', {
        p_date: date || new Date().toISOString().split('T')[0]
      })
      if (err) throw err
      stats.value = data as ReservationStats
      return stats.value
    } catch (e: any) {
      error.value = e.message
      return { total: 0, pending: 0, seated: 0, completed: 0 }
    } finally {
      loading.value = false
    }
  }

  async function listByDate(date: string): Promise<Reservation[]> {
    const result = await listReservations({ date })
    return result.reservations
  }

  async function createReservation(params: {
    guestName: string
    guestPhone: string
    reservationTime: string
    guestCount: number
    notes?: string
  }): Promise<string> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('create_reservation', {
        p_branch_id: activeBranchId.value ?? throwBranchGuard(),
        p_guest_name: params.guestName,
        p_guest_phone: params.guestPhone,
        p_reservation_time: params.reservationTime,
        p_guests: params.guestCount,
        p_notes: params.notes || null
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

  async function updateStatus(
    id: string, 
    status: Reservation['status'], 
    tableId?: string
  ): Promise<void> {
    loading.value = true
    error.value = null
    try {
      if (status === 'Arrived') {
        const { error: err } = await supabase.rpc('confirm_reservation', {
          p_reservation_id: id,
          p_table_id: tableId || null
        })
        if (err) throw err
      } else if (status === 'Dining') {
        const { error: err } = await supabase.rpc('seat_reservation', {
          p_reservation_id: id,
          p_table_id: tableId || null
        })
        if (err) throw err
      } else {
        const { error: err } = await supabase.rpc('hall_update_reservation_status', {
          p_reservation_id: id,
          p_status: status,
          p_table_id: tableId || null,
          p_reason: null,
        })
        if (err) throw err
      }
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function seatReservation(id: string, tableId?: string): Promise<void> {
    return updateStatus(id, 'Dining', tableId)
  }

  async function cancelReservation(id: string, reason?: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const { error: err } = await supabase.rpc('hall_update_reservation_status', {
        p_reservation_id: id,
        p_status: 'Cancelled',
        p_table_id: null,
        p_reason: reason || null,
      })
      if (err) throw err
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    reservations, stats, loading, error,
    listReservations, listByDate, fetchStats, createReservation, updateStatus,
    seatReservation, cancelReservation
  }
}
