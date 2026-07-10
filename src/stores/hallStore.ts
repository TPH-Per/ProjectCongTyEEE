import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useReservation } from '@/composables/useReservation'
import { useTable } from '@/composables/useTable'
import { useMenu } from '@/composables/useMenu'

export const useHallStore = defineStore('hall', () => {
  const { listReservations } = useReservation()
  const { listTables } = useTable()
  const { getItems, getCategories } = useMenu()

  // State
  const currentView = ref<'calendar' | 'detail' | 'floor-plan' | 'order-menu'>('calendar')
  const selectedDate = ref(new Date().toISOString().split('T')[0])
  const selectedTimeSlot = ref('all')
  const reservations = ref<any[]>([])
  const tables = ref<any[]>([])
  const menuItems = ref<any[]>([])
  const loading = ref(false)

  // Helper to determine time slot from time string (HH:MM)
  function getTimeSlot(timeStr: string) {
    if (!timeStr) return 'morning'
    const hour = parseInt(timeStr.split(':')[0], 10)
    if (hour < 11) return 'morning'
    if (hour < 14) return 'lunch'
    if (hour < 17) return 'afternoon'
    return 'evening'
  }

  // Computed
  const todayReservations = computed(() => {
    return reservations.value
  })

  const availableTables = computed(() => {
    return tables.value.filter(t => t.status === 'available')
  })

  const totalReservations = computed(() => todayReservations.value.length)

  // Actions
  function setCurrentView(view: typeof currentView.value) {
    currentView.value = view
  }

  function setSelectedDate(date: string) {
    selectedDate.value = date
    fetchReservations()
  }

  function setSelectedTimeSlot(slot: string) {
    selectedTimeSlot.value = slot
  }

  async function fetchReservations() {
    loading.value = true
    try {
      const res = await listReservations({ date: selectedDate.value })
      reservations.value = (res.reservations || []).map((r: any) => {
        const snap = r.customer_snapshot as any
        return {
          id: r.id,
          date: r.reservation_date,
          time: r.reservation_time ? r.reservation_time.substring(0, 5) : '',
          customerName: snap?.name || 'Khách vãng lai',
          customerPhone: snap?.phone || '',
          guests: r.guests || 0,
          tables: r.table_id ? 1 : 0,
          status: r.status === 'CONFIRMED' ? 'confirmed' : r.status === 'Dining' ? 'dining' : 'pending',
          timeSlot: getTimeSlot(r.reservation_time),
          notes: r.booking_info?.notes || ''
        }
      })
    } catch (error) {
      console.error('Failed to fetch reservations:', error)
    } finally {
      loading.value = false
    }
  }

  async function fetchTables() {
    loading.value = true
    try {
      const dbTables = await listTables()
      tables.value = (dbTables || []).map((t: any) => {
        let status = 'available'
        if (t.status === 'Occupied' || t.status === 'Serving') {
          status = 'occupied'
        } else if (t.status === 'Reserved') {
          status = 'reserved'
        } else if (t.status === 'Maintenance') {
          status = 'maintenance'
        }
        return {
          id: t.id,
          code: t.code,
          status: status,
          customer: t.current_order_id ? 'Đang phục vụ' : null
        }
      })
    } catch (error) {
      console.error('Failed to fetch tables:', error)
    } finally {
      loading.value = false
    }
  }

  async function fetchMenuItems() {
    loading.value = true
    try {
      const dbItems = await getItems()
      const dbCats = await getCategories()
      
      const catMap = new Map<string, string>()
      dbCats.forEach((c: any) => {
        catMap.set(c.id, c.name.toLowerCase())
      })

      menuItems.value = (dbItems || []).map((item: any) => {
        const catName = catMap.get(item.category_id) || 'food'
        let category = 'food'
        if (catName.includes('drink') || catName.includes('uống') || catName.includes('nước')) {
          category = 'drink'
        } else if (catName.includes('buffet')) {
          category = 'buffet'
        } else if (catName.includes('set') || catName.includes('lunch') || catName.includes('trưa')) {
          category = 'set-lunch'
        }

        return {
          id: item.id,
          name: item.name,
          price: item.price || 0,
          category: category,
          image: '🍽️'
        }
      })
    } catch (error) {
      console.error('Failed to fetch menu items:', error)
    } finally {
      loading.value = false
    }
  }

  return {
    currentView,
    selectedDate,
    selectedTimeSlot,
    reservations,
    tables,
    menuItems,
    loading,
    todayReservations,
    availableTables,
    totalReservations,
    setCurrentView,
    setSelectedDate,
    setSelectedTimeSlot,
    fetchReservations,
    fetchTables,
    fetchMenuItems
  }
})
