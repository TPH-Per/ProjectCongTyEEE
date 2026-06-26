<template>
  <div>
    <!-- Loading state -->
    <div v-if="loading && !hasLoadedOnce" class="text-sm text-gray-500 py-10 text-center">
      {{ $t('auto_ang_t_i_d_li_u', 'Đang tải dữ liệu lễ tân...') }}
    </div>

    <template v-else>
      <div class="mb-6 flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">{{ t('auto_t_ng_quan_ca_l_m_vi_c') }}</h2>
          <p class="text-sm text-gray-500">{{ t('auto_h_m_nay') }}</p>
        </div>
        <div class="flex gap-3">
          <div class="bg-white border px-4 py-2 rounded-xl text-center">
            <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto_b_n__ang_d_ng') }}</div>
            <div class="text-xl font-black text-gray-900">{{ diningTables.length }}</div>
          </div>
          <div class="bg-white border px-4 py-2 rounded-xl text-center">
            <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto_ch__thanh_to_n') }}</div>
            <div class="text-xl font-black text-red-600">{{ checkoutAlerts.length }}</div>
          </div>
          <div class="bg-white border px-4 py-2 rounded-xl text-center">
            <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ t('auto___t_b_n_h_m_nay') }}</div>
            <div class="text-xl font-black text-blue-600">{{ reservations.length }}</div>
          </div>
        </div>
      </div>

      <!-- Error banner -->
      <div v-if="error" class="mb-4 kawaii-card p-4 text-sm text-red-700 bg-red-50 border-red-200">
        {{ error }}
      </div>

      <!-- Active shift notice (only relevant on Close Shift page normally,
           but it's useful context here too) -->
      <div v-if="activeShift" class="mb-6 rounded-xl border-2 border-green-200 bg-green-50 p-4 flex items-center justify-between">
        <div>
          <div class="text-xs font-bold text-green-700 uppercase tracking-wide">{{ $t('auto_ca_hien_tai_dang_mo', 'Ca hiện tại đang mở') }}</div>
          <div class="text-sm text-green-800 mt-1">
            Mở lúc {{ formatDateTime(activeShift.opened_at) }} —
            Tiền đầu ca: {{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ
          </div>
        </div>
        <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
      </div>

      <!-- Alerts Section: checkout requests from tables / tablets -->
      <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">{{ t('auto_c_n_x__l__ngay') }}</h3>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        <div
          v-for="alert in checkoutAlerts"
          :key="alert.id"
          class="bg-red-50 border-2 border-red-500 rounded-2xl p-5 shadow-sm relative overflow-hidden"
        >
          <div class="absolute top-0 right-0 w-16 h-16 bg-red-100 rounded-bl-full flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500 animate-pulse translate-x-2 -translate-y-2"><path d="M22 17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9.5C2 7 4 5 6.5 5H18c2.2 0 4 1.8 4 4v8Z"/><polyline points="15,9 18,9 18,11"/><path d="M6.5 5C9 5 11 7 11 9.5V17a2 2 0 0 1-2 2v0"/><line x1="6" x2="6" y1="10" y2="10"/></svg>
          </div>
          <div class="flex items-center gap-3 mb-3">
            <div class="w-3 h-3 rounded-full bg-red-500 animate-pulse"></div>
            <span class="font-bold text-red-700">{{ t('auto_y_u_c_u_thanh_to_n') }}</span>
          </div>
          <div class="text-3xl font-black text-gray-900 mb-1">{{ alert.tableCode }}</div>
          <div class="text-sm text-gray-600 mb-6">{{ alert.guests ?? '—' }} Khách</div>
          <RouterLink
            :to="`/reception/checkout/${alert.tableId}`"
            class="block w-full bg-red-600 hover:bg-red-700 text-white text-center font-bold py-3 rounded-xl transition-colors"
          >
            {{ t('auto_ti_n_h_nh_thanh_to_n', 'Tiến Hành Thanh Toán') }}
          </RouterLink>
        </div>

        <div v-if="checkoutAlerts.length === 0" class="col-span-full text-sm text-gray-400">
          {{ t('auto_kh_ng_c_y_u_c_u_thanh_to_n_n', 'Không có yêu cầu thanh toán nào.') }}
        </div>
      </div>

      <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">{{ t('auto_danh_s_ch_b_n__ang_ph_c_v_') }}</h3>
      <div class="bg-white border rounded-2xl overflow-hidden shadow-sm">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-gray-50 border-b">
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_m__b_n') }}</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_kh_ch') }}</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_th_i_gian') }}</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">{{ t('auto_tr_ng_th_i') }}</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase text-right">{{ t('auto_h_a_n_', 'Hoá đơn') }}</th>
            </tr>
          </thead>
          <tbody class="text-sm divide-y">
            <tr v-for="table in diningTables" :key="table.id" class="hover:bg-gray-50 transition-colors">
              <td class="py-3 px-4 font-bold text-gray-900">{{ table.code }}</td>
              <td class="py-3 px-4 text-gray-600">{{ table.capacity }}</td>
              <td class="py-3 px-4 text-gray-600">—</td>
              <td class="py-3 px-4">
                <span class="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">
                  {{ t('auto__ang_d_ng_b_a') }}
                </span>
              </td>
              <td class="py-3 px-4 text-right">
                <RouterLink
                  :to="`/reception/checkout/${table.id}`"
                  class="text-red-600 hover:text-red-700 font-bold text-xs uppercase"
                >
                  {{ t('auto_thanh_to_n', 'Thanh toán') }} →
                </RouterLink>
              </td>
            </tr>
            <tr v-if="diningTables.length === 0">
              <td colspan="5" class="py-4 text-center text-gray-400">{{ t('auto_kh_ng_c__b_n__ang_ph_c_v__') }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Today's bookings list -->
      <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mt-8 mb-4">{{ t('auto___t_b_n_h_m_nay') }}</h3>
      <div class="bg-white border rounded-2xl overflow-hidden shadow-sm">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-gray-50 border-b">
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Mã đặt</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Khách</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Giờ</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Số khách</th>
              <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Trạng thái</th>
            </tr>
          </thead>
          <tbody class="text-sm divide-y">
            <tr v-for="res in reservations" :key="res.id" class="hover:bg-gray-50">
              <td class="py-3 px-4 font-mono font-bold text-gray-900">{{ res.booking_code || '—' }}</td>
              <td class="py-3 px-4 text-gray-600">{{ customerNameOf(res) }}</td>
              <td class="py-3 px-4 text-gray-600">{{ res.reservation_time || '—' }}</td>
              <td class="py-3 px-4 text-gray-600">{{ res.guests }}</td>
              <td class="py-3 px-4">
                <span
                  :class="[
                    'px-2 py-1 rounded text-xs font-bold',
                    statusClass(res.status)
                  ]"
                >{{ res.status }}</span>
              </td>
            </tr>
            <tr v-if="reservations.length === 0">
              <td colspan="5" class="py-4 text-center text-gray-400">Không có booking hôm nay.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { RouterLink } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { useTable } from '@/composables/useTable'
import { useReservation } from '@/composables/useReservation'
import { useNotification } from '@/composables/useNotification'
import { useRealtime } from '@/composables/useRealtime'
import type { TableT, Reservation, Shift, Notification } from '@/types/database'

const { branchId } = useAuth()
const { activeBranchId } = useBranch()
const { listTables } = useTable()
const { listByDate } = useReservation()
const { listForRole } = useNotification()
const { watchTable } = useRealtime()

const loading = ref(false)
const hasLoadedOnce = ref(false)
const error = ref<string | null>(null)

const tables = ref<TableT[]>([])
const reservations = ref<Reservation[]>([])
const checkoutNotifications = ref<Notification[]>([])
const activeShift = ref<Shift | null>(null)

// Realtime cleanups — we MUST unsubscribe when the dashboard unmounts.
const cleanups: Array<() => void> = []

const activeBranch = computed<string>(() => activeBranchId.value ?? branchId.value ?? '')

// "Đang phục vụ" = table.status = 'occupied'. TableStatus enum doesn't
// include a "checkout_requested" state — checkout requests are surfaced
// through `notifications` (see Edge Function `request-checkout`).
const diningTables = computed(() => tables.value.filter(t => t.status === 'occupied'))

interface CheckoutAlert {
  id: string
  tableId: string
  tableCode: string
  guests?: number
}

const tableCodeCache = computed<Record<string, string>>(() => {
  const map: Record<string, string> = {}
  for (const t of tables.value) map[t.id] = t.code
  return map
})

const checkoutAlerts = computed<CheckoutAlert[]>(() => {
  const seen = new Set<string>()
  const out: CheckoutAlert[] = []
  // Notification channel 'reception-panel' = checkout-request notifications.
  // variables: { table_id, table_code }
  for (const n of checkoutNotifications.value) {
    const tableId = (n.variables as Record<string, unknown>)?.table_id as string | undefined
    if (!tableId) continue
    if (seen.has(tableId)) continue
    seen.add(tableId)
    const fallbackCode = (n.variables as Record<string, unknown>)?.table_code as string | undefined
    out.push({
      id: n.id,
      tableId,
      tableCode: tableCodeCache.value[tableId] ?? fallbackCode ?? tableId.slice(0, 4),
    })
  }
  // Also include tables with status 'reserved' or 'occupied' as a soft
  // fallback — useful when there are no notifications yet but a table is
  // already occupied (so the receptionist has a one-click path to checkout).
  for (const t of tables.value) {
    if (seen.has(t.id)) continue
    if (t.status === 'occupied') {
      out.push({ id: `t-${t.id}`, tableId: t.id, tableCode: t.code })
    }
  }
  return out
})

function customerNameOf(r: Reservation): string {
  // customer_snapshot is a JSONB blob; the reservation row itself doesn't
  // expose a customer name directly. Fall back to id-derived label.
  const snap = r.customer_snapshot as Record<string, unknown> | null
  const name = snap?.name
  if (typeof name === 'string' && name.trim()) return name
  return r.customer_id?.slice(0, 8) ?? '—'
}

function statusClass(status: Reservation['status']): string {
  switch (status) {
    case 'Pending': return 'bg-yellow-100 text-yellow-700'
    case 'Arrived': return 'bg-blue-100 text-blue-700'
    case 'Dining': return 'bg-green-100 text-green-700'
    case 'Completed': return 'bg-gray-100 text-gray-700'
    case 'Cancelled': return 'bg-red-100 text-red-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

function formatDateTime(iso?: string | null): string {
  if (!iso) return '—'
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString('vi-VN')
}

async function fetchActiveShift() {
  if (!activeBranch.value) return
  // Edge Functions close-shift / export-shift-csv require a real shiftId.
  // Surfacing it here helps the receptionist see whether the shift is open.
  const { data } = await supabase
    .from('shifts')
    .select('*')
    .eq('branch_id', activeBranch.value)
    .eq('status', 'open')
    .order('opened_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  activeShift.value = (data as Shift) ?? null
}

async function fetchAll() {
  if (!activeBranch.value) {
    error.value = 'Tài khoản chưa gán chi nhánh. Liên hệ admin.'
    hasLoadedOnce.value = true
    return
  }
  loading.value = true
  error.value = null
  try {
    const today = new Date().toISOString().split('T')[0]
    const [tablesData, resData, notifData] = await Promise.all([
      listTables(),
      listByDate(today),
      listForRole('reception-panel', 50).catch(() => [] as Notification[]),
    ])
    tables.value = tablesData
    reservations.value = resData
    checkoutNotifications.value = (notifData ?? []).filter(
      (n) => n.template === 'checkout_request',
    )
    await fetchActiveShift()
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
    console.error('[ReceptionDashboard] fetch error:', err)
  } finally {
    loading.value = false
    hasLoadedOnce.value = true
  }
}

function subscribeRealtime() {
  if (!activeBranch.value) return
  // `useRealtime.watchTable` filters by branch_id automatically and dedupes
  // channels across components. We still need to keep the cleanup functions
  // so they're released on unmount.
  cleanups.push(
    watchTable<TableT>('tables', '*', () => fetchAll()),
    watchTable<Reservation>('reservations', '*', () => fetchAll()),
    watchTable<Notification>('notifications', '*', () => fetchAll()),
  )
}

onMounted(() => {
  fetchAll()
  subscribeRealtime()
})

onUnmounted(() => {
  for (const fn of cleanups) fn()
  cleanups.length = 0
})
</script>