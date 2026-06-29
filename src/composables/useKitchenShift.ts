import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import { useAuth } from './useAuth'

export interface KitchenShift {
  id: string
  branch_id: string
  shift_type: 'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT'
  started_at: string
  ended_at?: string
  started_by?: string
  ended_by?: string
  status: 'ACTIVE' | 'HANDOVER' | 'CLOSED'
  handover_note?: string
  created_at: string
}

export interface CountItem {
  ingredient_id: string
  counted_quantity: number
  note?: string
}

export function useKitchenShift() {
  const { activeBranchId } = useBranch()
  const { profile } = useAuth()
  
  const shifts = ref<KitchenShift[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const activeShift = computed(() => {
    return shifts.value.find(s => s.status === 'ACTIVE') || null
  })

  async function fetchShifts() {
    if (!activeBranchId.value) return
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .from('kitchen_shifts')
        .select('*')
        .eq('branch_id', activeBranchId.value)
        .order('created_at', { ascending: false })
        .limit(20)
      
      if (err) throw err
      shifts.value = data as KitchenShift[]
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function startShift(shiftType: 'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT') {
    if (!activeBranchId.value) {
      throw new Error('Chưa chọn chi nhánh')
    }
    if (!profile.value?.id) {
      throw new Error('Chưa đăng nhập')
    }

    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('start_kitchen_shift', {
        p_branch_id: activeBranchId.value,
        p_shift_type: shiftType,
        p_started_by: profile.value.id
      })
      
      if (err) {
        // Handle unique violation or our custom exception
        if (err.code === 'P0004' || err.message.includes('SHIFT_ALREADY_ACTIVE')) {
          throw new Error('Đã có ca bếp đang hoạt động tại chi nhánh này.')
        }
        throw err
      }
      
      await fetchShifts()
      return data
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function closeShift(shiftId: string, handoverNote?: string, counts: CountItem[] = []) {
    if (!profile.value?.id) {
      throw new Error('Chưa đăng nhập')
    }

    loading.value = true
    error.value = null
    try {
      const { error: err } = await supabase.rpc('close_shift_with_handover', {
        p_shift_id: shiftId,
        p_ended_by: profile.value.id,
        p_handover_note: handoverNote || null,
        p_counts: counts
      })
      
      if (err) throw err
      
      await fetchShifts()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    shifts,
    loading,
    error,
    activeShift,
    fetchShifts,
    startShift,
    closeShift
  }
}
