import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Reservation {
  id: string
  branch_id: string
  guest_name: string
  guest_phone: string
  reservation_time: string
  guest_count: number
  status: 'PENDING' | 'CONFIRMED' | 'SEATED' | 'COMPLETED' | 'NO_SHOW'
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
      let query = supabase.from('reservations').select('*', { count: 'exact' })
      
      if (params?.date) {
        // filter by date
        const startOfDay = new Date(params.date)
        startOfDay.setHours(0, 0, 0, 0)
        const endOfDay = new Date(params.date)
        endOfDay.setHours(23, 59, 59, 999)
        query = query.gte('reservation_time', startOfDay.toISOString())
                     .lte('reservation_time', endOfDay.toISOString())
      }
      
      if (params?.status) {
        query = query.eq('status', params.status)
      }
      
      if (params?.search) {
        query = query.or(`guest_name.ilike.%${params.search}%,guest_phone.ilike.%${params.search}%`)
      }

      query = query.order('reservation_time', { ascending: true })

      const { data, error: err, count } = await query
      if (err) throw err
      reservations.value = data as Reservation[]
      return { reservations: reservations.value, total: count || 0 }
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
        p_guest_name: params.guestName,
        p_guest_phone: params.guestPhone,
        p_reservation_time: params.reservationTime,
        p_guest_count: params.guestCount,
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
      if (status === 'CONFIRMED') {
        const { error: err } = await supabase.rpc('confirm_reservation', {
          p_reservation_id: id,
          p_table_id: tableId || null
        })
        if (err) throw err
      } else if (status === 'SEATED') {
        const { error: err } = await supabase.rpc('seat_reservation', {
          p_reservation_id: id,
          p_table_id: tableId || null
        })
        if (err) throw err
      } else {
        const { error: err } = await supabase.from('reservations').update({ status, updated_at: new Date().toISOString() }).eq('id', id)
        if (err) throw err
      }
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    reservations, stats, loading, error,
    listReservations, fetchStats, createReservation, updateStatus
  }
}
