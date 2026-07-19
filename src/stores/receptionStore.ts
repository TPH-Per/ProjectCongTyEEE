// File: src/stores/receptionStore.ts
//
// Single source of truth for reservation & customer data across the
// reception module. Wraps the existing `useReservation` composable for
// Supabase-backed reads/writes, and falls back to localStorage +
// mock data when Supabase is not configured or returns empty.
//
// All reception views (ReservationDetailView, ReceptionOrderView,
// ReceptionDashboardView, AdminFloorsView, ReceptionCheckoutView,
// ReportsView) should import THIS store instead of maintaining their
// own local mock arrays — that way a reservation created in one view
// instantly appears in every other view via Pinia reactivity (no
// CustomEvent / window dispatch needed).

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { isSupabaseConfigured } from '@/lib/supabase'

// ─── Types ───────────────────────────────────────────────────────────

export type ReservationStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'SEATED'
  | 'COMPLETED'
  | 'CANCELLED'

export interface ReceptionReservation {
  id: string
  code: string
  customerName: string
  customerPhone: string
  email?: string
  guests: number
  children: number
  reservationDate: string // YYYY-MM-DD
  reservationTime: string // HH:mm or HH:mm:ss
  timeSlot: 'morning' | 'lunch' | 'afternoon' | 'evening'
  notes?: string
  status: ReservationStatus
  source: string
  mealType: 'LUNCH' | 'DINNER'
  tableCode: string | null
  tableId?: string | null
  deposit: number
  partyName?: string
  partyType?: string
  receiverName?: string
  isVip: boolean
  createdAt: string
}

export interface ActiveSession {
  id: string
  reservationId: string
  tableCode: string
  customerName: string
  customerPhone: string
  guests: number
  seatedAt: string
}

// ─── Status Mapping ───────────────────────────────────────────────────
//
// The codebase has 4+ different status vocabularies:
//   useReservation:     'CONFIRMED', 'Dining', 'Cancelled'
//   ReservationDetail:  'new', 'confirmed', 'cancelled', 'completed'
//   restaurantStore:    'Waiting', 'Arrived', 'Seated', 'Completed', 'Cancelled'
//   ReceptionDashboard: 'Pending', 'Arrived', 'Dining', 'Completed', 'Cancelled'
//   AdminFloors DB:     'PENDING', 'CONFIRMED', 'CHECKED_IN', 'SEATED', 'COMPLETED', 'CANCELLED'
//
// This map unifies them all to the canonical uppercase enum.

const STATUS_MAP: Record<string, ReservationStatus> = {
  // Canonical (already correct)
  PENDING: 'PENDING',
  CONFIRMED: 'CONFIRMED',
  SEATED: 'SEATED',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
  // DB variants
  CHECKED_IN: 'CONFIRMED',
  Dining: 'SEATED',
  // restaurantStore / Dashboard variants
  Waiting: 'CONFIRMED',
  Arrived: 'CONFIRMED',
  // ReservationDetailView variants
  new: 'PENDING',
  confirmed: 'CONFIRMED',
  cancelled: 'CANCELLED',
  completed: 'COMPLETED',
}

export function normalizeStatus(raw: string): ReservationStatus {
  return STATUS_MAP[raw] ?? 'PENDING'
}

// ─── Mock Data ────────────────────────────────────────────────────────
//
// Seeded when localStorage is empty AND Supabase returns nothing.
// Merged from the two existing view-level mocks so the demo data the
// team is used to seeing still shows up.

function todayStr(): string {
  return new Date().toISOString().split('T')[0]
}

function nowIso(): string {
  return new Date().toISOString()
}

const MOCK_RESERVATIONS: ReceptionReservation[] = [
  // Morning
  { id: 'r01', code: 'RES001', customerName: 'Phạm Văn An', customerPhone: '0901 234 567', email: '', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '07:30', timeSlot: 'morning', notes: 'Ăn sáng gia đình', status: 'CONFIRMED', source: 'facebook', mealType: 'LUNCH', tableCode: 'A01', tableId: 't01', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r02', code: 'RES002', customerName: 'Trần Thị Bích Ngọc', customerPhone: '0912 345 678', email: 'ngoc.tran@email.com', guests: 4, children: 1, reservationDate: todayStr(), reservationTime: '08:00', timeSlot: 'morning', notes: 'Cần ghế trẻ em', status: 'PENDING', source: 'tel', mealType: 'LUNCH', tableCode: null, tableId: '', deposit: 0, partyName: 'Sinh nhật', isVip: false, createdAt: nowIso() },
  { id: 'r03', code: 'RES003', customerName: 'Lê Minh Châu', customerPhone: '0938 765 432', email: '', guests: 3, children: 0, reservationDate: todayStr(), reservationTime: '09:00', timeSlot: 'morning', notes: '', status: 'CONFIRMED', source: 'app', mealType: 'LUNCH', tableCode: 'A04', tableId: 't04', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r04', code: 'RES004', customerName: 'Nguyễn Hoàng Phúc', customerPhone: '0977 654 321', email: '', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '10:00', timeSlot: 'morning', notes: 'Đã thanh toán', status: 'COMPLETED', source: 'facebook', mealType: 'LUNCH', tableCode: 'A05', tableId: 't05', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  // Lunch
  { id: 'r05', code: 'RES005', customerName: 'Vũ Thị Hồng Nhung', customerPhone: '0988 112 233', email: 'nhung.vu@email.com', guests: 6, children: 2, reservationDate: todayStr(), reservationTime: '11:00', timeSlot: 'lunch', notes: 'Gia đình 6 người lớn, 2 trẻ em', status: 'CONFIRMED', source: 'mobile', mealType: 'LUNCH', tableCode: 'A06', tableId: 't06', deposit: 0, partyName: 'Liên hoan', isVip: false, createdAt: nowIso() },
  { id: 'r06', code: 'RES006', customerName: 'Đặng Quốc Bảo', customerPhone: '0902 334 455', email: '', guests: 4, children: 0, reservationDate: todayStr(), reservationTime: '11:30', timeSlot: 'lunch', notes: 'Khách công ty', status: 'PENDING', source: 'tel', mealType: 'LUNCH', tableCode: null, tableId: '', deposit: 0, partyName: 'Ăn trưa', isVip: false, createdAt: nowIso() },
  { id: 'r07', code: 'RES007', customerName: 'Bùi Thị Mai', customerPhone: '0913 556 677', email: 'mai.bui@email.com', guests: 8, children: 0, reservationDate: todayStr(), reservationTime: '12:00', timeSlot: 'lunch', notes: 'Đặt bàn trước cho nhóm lớn', status: 'CONFIRMED', source: 'facebook', mealType: 'LUNCH', tableCode: 'A09', tableId: 't09', deposit: 0, partyName: 'Tiệc công ty', isVip: true, createdAt: nowIso() },
  { id: 'r08', code: 'RES008', customerName: 'Hà Văn Trường', customerPhone: '0924 778 899', email: '', guests: 3, children: 0, reservationDate: todayStr(), reservationTime: '12:30', timeSlot: 'lunch', notes: '', status: 'CONFIRMED', source: 'app', mealType: 'LUNCH', tableCode: 'A02', tableId: 't02', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r09', code: 'RES009', customerName: 'Ngô Thị Phương', customerPhone: '0935 900 111', email: '', guests: 5, children: 0, reservationDate: todayStr(), reservationTime: '13:00', timeSlot: 'lunch', notes: 'Khách hủy do bận', status: 'CANCELLED', source: 'mobile', mealType: 'LUNCH', tableCode: null, tableId: '', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  // Afternoon
  { id: 'r10', code: 'RES010', customerName: 'Lý Đức Anh', customerPhone: '0946 222 333', email: 'anh.ly@email.com', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '14:00', timeSlot: 'afternoon', notes: 'Uống trà chiều', status: 'CONFIRMED', source: 'facebook', mealType: 'DINNER', tableCode: 'A07', tableId: 't07', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r11', code: 'RES011', customerName: 'Đỗ Thị Thanh Hà', customerPhone: '0957 444 555', email: '', guests: 4, children: 1, reservationDate: todayStr(), reservationTime: '15:30', timeSlot: 'afternoon', notes: 'Hẹn gặp đối tác', status: 'PENDING', source: 'tel', mealType: 'DINNER', tableCode: null, tableId: '', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r12', code: 'RES012', customerName: 'Trịnh Văn Quang', customerPhone: '0968 666 777', email: '', guests: 3, children: 0, reservationDate: todayStr(), reservationTime: '16:00', timeSlot: 'afternoon', notes: '', status: 'CONFIRMED', source: 'app', mealType: 'DINNER', tableCode: 'A03', tableId: 't03', deposit: 0, partyName: 'Snack chiều', isVip: false, createdAt: nowIso() },
  // Evening
  { id: 'r13', code: 'RES013', customerName: 'Phan Thị Thu Trang', customerPhone: '0979 888 999', email: 'trang.phan@email.com', guests: 5, children: 0, reservationDate: todayStr(), reservationTime: '17:00', timeSlot: 'evening', notes: 'Tiệc sinh nhật, cần trang trí bàn', status: 'CONFIRMED', source: 'facebook', mealType: 'DINNER', tableCode: 'A08', tableId: 't08', deposit: 0, partyName: 'Sinh nhật', isVip: false, createdAt: nowIso() },
  { id: 'r14', code: 'RES014', customerName: 'Lương Văn Hải', customerPhone: '0980 111 222', email: '', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '17:30', timeSlot: 'evening', notes: 'Hẹn hò lãng mạn', status: 'PENDING', source: 'mobile', mealType: 'DINNER', tableCode: null, tableId: '', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r15', code: 'RES015', customerName: 'Hồ Thị Bảo Trân', customerPhone: '0991 333 444', email: 'tran.ho@email.com', guests: 10, children: 2, reservationDate: todayStr(), reservationTime: '18:00', timeSlot: 'evening', notes: 'Tiệc VIP công ty, cần phục vụ đặc biệt', status: 'CONFIRMED', source: 'tel', mealType: 'DINNER', tableCode: 'A09', tableId: 't09', deposit: 0, partyName: 'Tiệc VIP', isVip: true, createdAt: nowIso() },
  { id: 'r16', code: 'RES016', customerName: 'Đinh Văn Lộc', customerPhone: '0903 555 666', email: '', guests: 4, children: 0, reservationDate: todayStr(), reservationTime: '18:30', timeSlot: 'evening', notes: '', status: 'CONFIRMED', source: 'app', mealType: 'DINNER', tableCode: 'A04', tableId: 't04', deposit: 0, partyName: 'Ăn tối', isVip: false, createdAt: nowIso() },
  { id: 'r17', code: 'RES017', customerName: 'Cao Thị Kim Ngân', customerPhone: '0914 777 888', email: 'ngan.cao@email.com', guests: 6, children: 0, reservationDate: todayStr(), reservationTime: '19:00', timeSlot: 'evening', notes: 'Liên hoan phòng ban', status: 'CONFIRMED', source: 'facebook', mealType: 'DINNER', tableCode: 'A06', tableId: 't06', deposit: 0, partyName: 'Liên hoan', isVip: false, createdAt: nowIso() },
  { id: 'r18', code: 'RES018', customerName: 'Mai Văn Hoàng', customerPhone: '0925 999 000', email: '', guests: 3, children: 0, reservationDate: todayStr(), reservationTime: '19:30', timeSlot: 'evening', notes: '', status: 'PENDING', source: 'tel', mealType: 'DINNER', tableCode: null, tableId: '', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'r19', code: 'RES019', customerName: 'Tôn Nữ Thị Mai', customerPhone: '0936 111 222', email: 'mai.ton@email.com', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '20:00', timeSlot: 'evening', notes: 'Kỷ niệm ngày cưới', status: 'CONFIRMED', source: 'mobile', mealType: 'DINNER', tableCode: 'B01', tableId: 't10', deposit: 0, partyName: 'Kỷ niệm', isVip: true, createdAt: nowIso() },
  { id: 'r20', code: 'RES020', customerName: 'La Văn Đức', customerPhone: '0947 333 444', email: '', guests: 7, children: 3, reservationDate: todayStr(), reservationTime: '20:30', timeSlot: 'evening', notes: 'Khách dời lịch sang ngày mai', status: 'CANCELLED', source: 'facebook', mealType: 'DINNER', tableCode: null, tableId: '', deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  // From ReceptionOrderView mockUnassignedReservations
  { id: 'RES-001', code: 'RES021', customerName: 'Nguyễn Văn Minh', customerPhone: '0909 123 456', email: '', guests: 4, children: 0, reservationDate: todayStr(), reservationTime: '11:00', timeSlot: 'lunch', notes: 'Sinh nhật, cần trang trí bàn', status: 'PENDING', source: 'PHONE', mealType: 'LUNCH', tableCode: null, tableId: null, deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'RES-002', code: 'RES022', customerName: 'Trần Thị Lan', customerPhone: '0912 345 678', email: '', guests: 2, children: 0, reservationDate: todayStr(), reservationTime: '18:00', timeSlot: 'evening', notes: 'Hẹn đối tác, cần bàn yên tĩnh', status: 'PENDING', source: 'WEBSITE', mealType: 'DINNER', tableCode: null, tableId: null, deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'RES-003', code: 'RES023', customerName: 'Lê Hoàng Nam', customerPhone: '0938 765 432', email: '', guests: 8, children: 0, reservationDate: todayStr(), reservationTime: '18:00', timeSlot: 'evening', notes: 'Tiệc gia đình, cần bàn lớn', status: 'PENDING', source: 'FACEBOOK', mealType: 'DINNER', tableCode: null, tableId: null, deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'RES-004', code: 'RES024', customerName: 'Phạm Thị Hương', customerPhone: '0977 654 321', email: '', guests: 6, children: 0, reservationDate: todayStr(), reservationTime: '11:30', timeSlot: 'lunch', notes: 'Ăn trưa business lunch', status: 'PENDING', source: 'MOBILE_APP', mealType: 'LUNCH', tableCode: null, tableId: null, deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
  { id: 'RES-005', code: 'RES025', customerName: 'Hoàng Đức Tuấn', customerPhone: '0966 111 222', email: '', guests: 10, children: 0, reservationDate: todayStr(), reservationTime: '18:00', timeSlot: 'evening', notes: 'Tiệc công ty, cần ghép bàn', status: 'PENDING', source: 'PHONE', mealType: 'DINNER', tableCode: null, tableId: null, deposit: 0, partyName: '', isVip: false, createdAt: nowIso() },
]

const STORAGE_KEY = 'nguucat_reception_data'

// ─── Store ────────────────────────────────────────────────────────────

export const useReceptionStore = defineStore('reception', () => {
  const reservations = ref<ReceptionReservation[]>([])
  const activeSessions = ref<ActiveSession[]>([])
  const lastUpdated = ref<string | null>(null)
  const isLoaded = ref(false)

  // ─── Getters ───────────────────────────────────────────────────────

  const todayReservations = computed(() => {
    const today = todayStr()
    return reservations.value.filter((r) => r.reservationDate === today)
  })

  /** Reservations that still need a table assigned (not cancelled/completed, no tableCode). */
  const waitingReservations = computed(() =>
    reservations.value.filter(
      (r) =>
        r.status !== 'CANCELLED' &&
        r.status !== 'COMPLETED' &&
        !r.tableCode,
    ),
  )

  /** Reservations that already have a table assigned and are dining. */
  const seatedReservations = computed(() =>
    reservations.value.filter((r) => r.status === 'SEATED' || (r.tableCode && r.status === 'CONFIRMED')),
  )

  const pendingCount = computed(
    () => todayReservations.value.filter((r) => r.status === 'PENDING').length,
  )

  const confirmedCount = computed(
    () => todayReservations.value.filter((r) => r.status === 'CONFIRMED').length,
  )

  const seatedCount = computed(
    () => todayReservations.value.filter((r) => r.status === 'SEATED').length,
  )

  const completedCount = computed(
    () => todayReservations.value.filter((r) => r.status === 'COMPLETED').length,
  )

  const cancelledCount = computed(
    () => todayReservations.value.filter((r) => r.status === 'CANCELLED').length,
  )

  // ─── Persistence ───────────────────────────────────────────────────

  function persistToStorage() {
    try {
      lastUpdated.value = nowIso()
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          reservations: reservations.value,
          activeSessions: activeSessions.value,
          lastUpdated: lastUpdated.value,
        }),
      )
    } catch (e) {
      console.error('[receptionStore] persist failed:', e)
    }
  }

  function loadFromStorage(): boolean {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored) {
        const data = JSON.parse(stored)
        reservations.value = data.reservations || []
        activeSessions.value = data.activeSessions || []
        lastUpdated.value = data.lastUpdated || null
        return reservations.value.length > 0
      }
    } catch (e) {
      console.error('[receptionStore] load from storage failed:', e)
    }
    return false
  }

  // ─── Load ──────────────────────────────────────────────────────────

  async function loadReservations(force = false) {
    if (isLoaded.value && !force) return

    // 1. Try Supabase (via useReservation composable) — lazy import
    //    to avoid circular dependency if the composable ever imports
    //    this store.
    if (isSupabaseConfigured) {
      try {
        const { useReservation } = await import('@/composables/useReservation')
        const { listReservations } = useReservation()
        const today = todayStr()
        const result = await listReservations({ date: today })
        if (result.reservations && result.reservations.length > 0) {
          reservations.value = result.reservations.map(mapDbReservation)
          isLoaded.value = true
          persistToStorage()
          return
        }
      } catch (e) {
        console.warn('[receptionStore] Supabase load failed, using fallback:', e)
      }
    }

    // 2. Try localStorage
    if (loadFromStorage()) {
      isLoaded.value = true
      return
    }

    // 3. Fall back to mock data
    reservations.value = JSON.parse(JSON.stringify(MOCK_RESERVATIONS))
    isLoaded.value = true
    persistToStorage()
  }

  /** Map a Supabase `ReservationRow` (snake_case, JSONB snapshots) to our unified type. */
  function mapDbReservation(row: any): ReceptionReservation {
    const snapshot = row.customer_snapshot ?? row.customers ?? {}
    const rawTime = String(row.reservation_time ?? '').slice(0, 5)
    return {
      id: String(row.id),
      code: String(row.code ?? row.reservation_code ?? `#RES${row.id?.slice(-4)}`),
      customerName: String(snapshot.name ?? row.customer_name ?? row.guest_name ?? ''),
      customerPhone: String(snapshot.phone ?? row.customer_phone ?? row.guest_phone ?? ''),
      email: String(snapshot.email ?? row.customer_email ?? ''),
      guests: Number(row.guests ?? row.guest_count ?? row.party_size ?? 1),
      children: Number(snapshot.children ?? 0),
      reservationDate: String(row.reservation_date ?? row.date ?? todayStr()),
      reservationTime: rawTime || '12:00',
      timeSlot: deriveTimeSlot(rawTime),
      notes: typeof row.notes === 'string' ? row.notes : row.notes?.request ?? '',
      status: normalizeStatus(String(row.status ?? 'PENDING')),
      source: String(row.source ?? 'Walk-in'),
      mealType: deriveTimeSlot(rawTime) === 'morning' || deriveTimeSlot(rawTime) === 'lunch' ? 'LUNCH' : 'DINNER',
      tableCode: row.table_code ?? row.table_id ?? null,
      tableId: row.table_id ?? null,
      deposit: Number(row.deposit ?? 0),
      partyName: String(row.party_name ?? ''),
      isVip: Boolean(snapshot.is_vip ?? row.is_vip ?? false),
      createdAt: String(row.created_at ?? nowIso()),
    }
  }

  function deriveTimeSlot(time: string): 'morning' | 'lunch' | 'afternoon' | 'evening' {
    const h = parseInt(time.split(':')[0] ?? '12', 10)
    if (h < 11) return 'morning'
    if (h < 14) return 'lunch'
    if (h < 17) return 'afternoon'
    return 'evening'
  }

  // ─── CRUD ──────────────────────────────────────────────────────────

  function addReservation(
    data: Partial<ReceptionReservation>,
  ): ReceptionReservation {
    const seq = reservations.value.length + 1
    const time = data.reservationTime || '12:00'
    const newRes: ReceptionReservation = {
      id: data.id || `RES${Date.now()}`,
      code: data.code || `#RES${String(seq).padStart(3, '0')}`,
      customerName: data.customerName || '',
      customerPhone: data.customerPhone || '',
      email: data.email || '',
      guests: data.guests || 1,
      children: data.children || 0,
      reservationDate: data.reservationDate || todayStr(),
      reservationTime: time,
      timeSlot: data.timeSlot || deriveTimeSlot(time),
      notes: data.notes || '',
      status: data.status || 'PENDING',
      source: data.source || 'Walk-in',
      mealType: data.mealType || (deriveTimeSlot(time) === 'evening' || deriveTimeSlot(time) === 'afternoon' ? 'DINNER' : 'LUNCH'),
      tableCode: data.tableCode || null,
      tableId: data.tableId || null,
      deposit: data.deposit || 0,
      partyName: data.partyName || '',
      isVip: data.isVip || false,
      createdAt: nowIso(),
    }
    reservations.value.push(newRes)
    persistToStorage()
    return newRes
  }

  function updateReservation(
    id: string,
    updates: Partial<ReceptionReservation>,
  ): ReceptionReservation | null {
    const idx = reservations.value.findIndex((r) => r.id === id)
    if (idx !== -1) {
      reservations.value[idx] = { ...reservations.value[idx], ...updates }
      persistToStorage()
      return reservations.value[idx]
    }
    return null
  }

  function deleteReservation(id: string): boolean {
    const idx = reservations.value.findIndex((r) => r.id === id)
    if (idx !== -1) {
      reservations.value.splice(idx, 1)
      persistToStorage()
      return true
    }
    return false
  }

  // ─── Table Assignment ──────────────────────────────────────────────

  function assignTable(
    reservationId: string,
    tableCode: string,
    tableId?: string,
  ): ReceptionReservation | null {
    const res = reservations.value.find((r) => r.id === reservationId)
    if (!res) return null

    res.tableCode = tableCode
    res.tableId = tableId ?? tableCode
    res.status = 'SEATED'

    activeSessions.value.push({
      id: `SES${Date.now()}`,
      reservationId,
      tableCode,
      customerName: res.customerName,
      customerPhone: res.customerPhone,
      guests: res.guests,
      seatedAt: nowIso(),
    })

    persistToStorage()
    return res
  }

  function releaseTable(tableCode: string) {
    const sIdx = activeSessions.value.findIndex((s) => s.tableCode === tableCode)
    if (sIdx !== -1) {
      const session = activeSessions.value[sIdx]
      const res = reservations.value.find((r) => r.id === session.reservationId)
      if (res) {
        res.status = 'COMPLETED'
        res.tableCode = null
      }
      activeSessions.value.splice(sIdx, 1)
      persistToStorage()
    }
  }

  function getSessionByTable(tableCode: string): ActiveSession | undefined {
    return activeSessions.value.find((s) => s.tableCode === tableCode)
  }

  function getReservationByTable(tableCode: string): ReceptionReservation | undefined {
    return reservations.value.find((r) => r.tableCode === tableCode)
  }

  // ─── Reset ─────────────────────────────────────────────────────────

  function resetState() {
    reservations.value = []
    activeSessions.value = []
    lastUpdated.value = null
    isLoaded.value = false
    localStorage.removeItem(STORAGE_KEY)
  }

  function resetToMock() {
    reservations.value = JSON.parse(JSON.stringify(MOCK_RESERVATIONS))
    activeSessions.value = []
    isLoaded.value = true
    persistToStorage()
  }

  return {
    // State
    reservations,
    activeSessions,
    lastUpdated,
    isLoaded,
    // Getters
    todayReservations,
    waitingReservations,
    seatedReservations,
    pendingCount,
    confirmedCount,
    seatedCount,
    completedCount,
    cancelledCount,
    // Actions
    loadReservations,
    addReservation,
    updateReservation,
    deleteReservation,
    assignTable,
    releaseTable,
    getSessionByTable,
    getReservationByTable,
    persistToStorage,
    loadFromStorage,
    resetState,
    resetToMock,
  }
})
