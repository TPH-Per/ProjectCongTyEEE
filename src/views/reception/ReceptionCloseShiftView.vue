<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">{{ t('auto_t_ng_k_t_ca_l_m_vi_c') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">{{ t('auto_h_m_nay_____doanh_thu___h_a___n') }}</p>
      </div>
      <div class="flex gap-2">
        <button
          @click="handleExportCSV"
          :disabled="loading || !activeShift"
          class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2 disabled:opacity-50"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          {{ t('auto_xu_t_csv') }}
        </button>
        <button
          @click="handleCloseShift"
          :disabled="loading || !activeShift"
          class="kawaii-btn-primary px-5 py-2 text-sm font-bold flex items-center gap-2 disabled:opacity-50"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          {{ loading ? t('auto_ang_ng_ca', 'Đang Đóng Ca...') : t('auto_x_c_nh_n_ng_ca', 'Xác Nhận Đóng Ca') }}
        </button>
      </div>
    </div>

    <!-- Active shift notice — required to know which shiftId to close. -->
    <div
      v-if="activeShift"
      class="kawaii-card p-4 flex items-center justify-between"
    >
      <div>
        <div class="text-xs font-bold text-green-700 uppercase tracking-wide">{{ $t('auto_ca_hien_tai_dang_mo', 'Ca hiện tại đang mở') }}</div>
        <div class="text-sm text-[hsl(var(--foreground))] mt-1">
          Mở lúc {{ new Date(activeShift.opened_at).toLocaleString('vi-VN') }}
          — Tiền đầu ca: {{ Number(activeShift.opening_cash || 0).toLocaleString('vi-VN') }}đ
        </div>
      </div>
      <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
    </div>
    <div
      v-else
      class="kawaii-card p-4 text-sm text-yellow-800 bg-yellow-50 border-yellow-200"
    >{{ $t('auto_chua_co_ca_nao_dang_mo_tai_chi', 'Chưa có ca nào đang mở tại chi nhánh này. Vào ca trước rồi quay lại đóng.') }}</div>

    <!-- Error banner -->
    <div
      v-if="error"
      class="kawaii-card p-4 text-sm text-red-700 bg-red-50 border-red-200"
    >{{ error }}</div>

    <!-- Revenue by Type — computed from `payments`, not `orders` -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-5">{{ t('auto_doanh_thu_theo_lo_i_h_nh______') }}</h3>
      <div v-if="loading" class="text-sm text-gray-500 py-6 text-center">{{ t('auto_ang_t_i', 'Đang tải...') }}</div>
      <div v-else class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="rounded-2xl border-2 border-red-200 bg-red-50 p-4 text-center">
          <div class="text-2xl mb-2">🍖</div>
          <div class="text-xs font-bold text-red-400 uppercase tracking-wide mb-1">{{ t('auto_b_a_t_i__dinner_') }}</div>
          <div class="text-2xl font-black text-red-700">{{ stats.dinner.revenue.toLocaleString('vi-VN') }}</div>
          <div class="text-xs text-red-400 mt-1">{{ stats.dinner.count }} bill</div>
        </div>
        <div class="rounded-2xl border-2 border-orange-200 bg-orange-50 p-4 text-center">
          <div class="text-2xl mb-2">🍱</div>
          <div class="text-xs font-bold text-orange-400 uppercase tracking-wide mb-1">{{ t('auto_b_a_tr_a__lunch_') }}</div>
          <div class="text-2xl font-black text-orange-700">{{ stats.lunch.revenue.toLocaleString('vi-VN') }}</div>
          <div class="text-xs text-orange-400 mt-1">{{ stats.lunch.count }} bill</div>
        </div>
        <div class="rounded-2xl border-2 border-purple-200 bg-purple-50 p-4 text-center">
          <div class="text-2xl mb-2">🍶</div>
          <div class="text-xs font-bold text-purple-400 uppercase tracking-wide mb-1">{{ t('auto_r__u_wine') }}</div>
          <div class="text-2xl font-black text-purple-700">{{ stats.wine.revenue.toLocaleString('vi-VN') }}</div>
          <div class="text-xs text-purple-400 mt-1">{{ stats.wine.count }} bill</div>
        </div>
        <div class="rounded-2xl border-2 border-blue-200 bg-blue-50 p-4 text-center">
          <div class="text-2xl mb-2">🛵</div>
          <div class="text-xs font-bold text-blue-400 uppercase tracking-wide mb-1">{{ t('auto_giao_h_ng__delivery_') }}</div>
          <div class="text-2xl font-black text-blue-700">{{ stats.delivery.revenue.toLocaleString('vi-VN') }}</div>
          <div class="text-xs text-blue-400 mt-1">{{ stats.delivery.count }} đơn</div>
        </div>
      </div>

      <div class="bg-[hsl(var(--muted))] rounded-xl p-4 flex items-center justify-between">
        <div class="font-black text-lg text-[hsl(var(--foreground))]">{{ t('auto_t_ng_doanh_thu_ng_y') }}</div>
        <div class="text-3xl font-black text-[hsl(var(--primary))]">{{ totalRevenue.toLocaleString('vi-VN') }}đ</div>
      </div>
    </div>

    <!-- Cash reconciliation summary — derived from payments (server-side). -->
    <div v-if="cashSummary" class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-4">Đối chiếu tiền mặt</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
        <div class="rounded-xl border p-3">
          <div class="text-[10px] uppercase tracking-wide text-gray-500 font-bold">Tiền đầu ca</div>
          <div class="font-black text-base mt-1">{{ cashSummary.opening.toLocaleString('vi-VN') }}đ</div>
        </div>
        <div class="rounded-xl border p-3">
          <div class="text-[10px] uppercase tracking-wide text-gray-500 font-bold">Tiền mặt thu được</div>
          <div class="font-black text-base mt-1">{{ cashSummary.cashRevenue.toLocaleString('vi-VN') }}đ</div>
        </div>
        <div class="rounded-xl border p-3">
          <div class="text-[10px] uppercase tracking-wide text-gray-500 font-bold">Tiền mặt kỳ vọng</div>
          <div class="font-black text-base mt-1 text-blue-700">{{ cashSummary.expected.toLocaleString('vi-VN') }}đ</div>
        </div>
        <div class="rounded-xl border p-3">
          <div class="text-[10px] uppercase tracking-wide text-gray-500 font-bold">Tiền thẻ / CK / khác</div>
          <div class="font-black text-base mt-1">{{ cashSummary.nonCashRevenue.toLocaleString('vi-VN') }}đ</div>
        </div>
      </div>
    </div>

    <!-- Session Summary Table — show payments, not orders -->
    <div class="kawaii-card overflow-hidden">
      <div class="kawaii-card-header">
        <span class="font-bold text-sm">{{ t('auto_l_ch_s__thanh_to_n_trong_ca') }}</span>
        <span class="kawaii-pill bg-[hsl(var(--primary))]/10 text-[hsl(var(--primary))]">{{ payments.length }} lượt</span>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-[hsl(var(--border))]">
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_th_i_gian') }}</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Phương thức</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Loại</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Số tiền</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Khách đưa</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Thối</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-for="p in payments" :key="p.id" class="hover:bg-[hsl(var(--muted))]/50">
              <td class="py-2.5 px-4 text-gray-600 text-xs">{{ formatTime(p.paid_at) }}</td>
              <td class="py-2.5 px-4">
                <span class="kawaii-pill bg-gray-100">{{ methodLabel(p.method) }}</span>
              </td>
              <td class="py-2.5 px-4 text-gray-600 text-xs">{{ revenueLabel(p.revenue_type) }}</td>
              <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ Number(p.amount || 0).toLocaleString('vi-VN') }}đ</td>
              <td class="py-2.5 px-4 text-right text-gray-600 text-xs">{{ p.received_amount != null ? Number(p.received_amount).toLocaleString('vi-VN') + 'đ' : '—' }}</td>
              <td class="py-2.5 px-4 text-right text-gray-600 text-xs">{{ p.change_amount != null ? Number(p.change_amount).toLocaleString('vi-VN') + 'đ' : '—' }}</td>
            </tr>
            <tr v-if="payments.length === 0">
              <td colspan="6" class="py-4 text-center text-gray-500">{{ t('auto_ch_a_c_d_li_u', 'Chưa có dữ liệu') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2';
import { useI18n } from 'vue-i18n'
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useShift } from '@/composables/useShift'
import type { Shift } from '@/types/database'

const { t } = useI18n()
const { branchId } = useAuth()
const { closeShift, exportCsv, loading: shiftLoading, error: shiftError } = useShift()

const loading = ref(false)
const error = ref<string | null>(null)

// Resolve branch scope: prefer the signed-in user's branch, fall back to the
// DEFAULT_BRANCH_ID only if the JWT/DB hasn't given us one (e.g. mock login).
const activeBranchId = computed<string>(() => branchId.value ?? '')

// `shifts` (one row) + `payments` (per-transaction rows). We do NOT aggregate
// from `orders` — `orders.total` doesn't break down by payment method, and
// revenue_type is only on `payments`. Source of truth = payments table.
const payments = ref<PaymentRow[]>([])
const activeShift = ref<Shift | null>(null)

interface PaymentRow {
  id: string
  method: 'cash' | 'card' | 'transfer' | 'voucher' | 'other'
  revenue_type: 'lunch' | 'dinner' | 'wine' | 'delivery' | 'other' | null
  amount: number
  received_amount: number | null
  change_amount: number | null
  paid_at: string
}

interface RevenueStat { revenue: number; count: number }
const stats = ref({
  dinner: { revenue: 0, count: 0 } as RevenueStat,
  lunch: { revenue: 0, count: 0 } as RevenueStat,
  wine: { revenue: 0, count: 0 } as RevenueStat,
  delivery: { revenue: 0, count: 0 } as RevenueStat,
})

const totalRevenue = computed(() =>
  stats.value.dinner.revenue +
  stats.value.lunch.revenue +
  stats.value.wine.revenue +
  stats.value.delivery.revenue,
)

const cashSummary = computed(() => {
  if (!activeShift.value) return null
  const opening = Number(activeShift.value.opening_cash || 0)
  let cashRevenue = 0
  let nonCashRevenue = 0
  for (const p of payments.value) {
    if (p.method === 'cash') cashRevenue += Number(p.amount)
    else nonCashRevenue += Number(p.amount)
  }
  return {
    opening,
    cashRevenue,
    nonCashRevenue,
    expected: opening + cashRevenue,
  }
})

function resetStats() {
  stats.value = {
    dinner: { revenue: 0, count: 0 },
    lunch: { revenue: 0, count: 0 },
    wine: { revenue: 0, count: 0 },
    delivery: { revenue: 0, count: 0 },
  }
}

function formatTime(iso?: string | null): string {
  if (!iso) return ''
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? '' : d.toLocaleTimeString('vi-VN')
}

function methodLabel(method: PaymentRow['method']): string {
  switch (method) {
    case 'cash': return 'Tiền mặt'
    case 'card': return 'Thẻ'
    case 'transfer': return 'CK'
    case 'voucher': return 'Voucher'
    case 'other': return 'Khác'
    default: return method
  }
}

function revenueLabel(rt: PaymentRow['revenue_type']): string {
  switch (rt) {
    case 'dinner': return 'Bữa tối'
    case 'lunch': return 'Bữa trưa'
    case 'wine': return 'Rượu'
    case 'delivery': return 'Giao hàng'
    case 'other': return 'Khác'
    default: return '—'
  }
}

async function fetchPaymentsForShift() {
  if (!activeBranchId.value || !activeShift.value) {
    payments.value = []
    resetStats()
    return
  }
  resetStats()
  // Pull all payments belonging to this shift. We rely on `shift_id` (the
  // exact column the Edge Function `close-shift` uses for `expectedCash`),
  // NOT a `created_at` filter — a shift can span past midnight, and a date
  // filter would either miss or over-count.
  const { data, error: err } = await supabase
    .from('payments')
    .select('id, method, revenue_type, amount, received_amount, change_amount, paid_at, shift_id, branch_id')
    .eq('branch_id', activeBranchId.value)
    .eq('shift_id', activeShift.value.id)
    .order('paid_at', { ascending: false })

  if (err) {
    error.value = err.message
    payments.value = []
    return
  }
  payments.value = (data ?? []) as unknown as PaymentRow[]

  // Aggregate by revenue_type. Unknown values fall into "dinner" so the
  // dashboard totals stay consistent with the rest of the app.
  for (const p of payments.value) {
    const rt = (p.revenue_type ?? 'dinner') as keyof typeof stats.value
    const bucket = (stats.value as Record<string, RevenueStat>)[rt] ?? stats.value.dinner
    bucket.revenue += Number(p.amount || 0)
    bucket.count += 1
  }
}

async function fetchActiveShift() {
  if (!activeBranchId.value) {
    activeShift.value = null
    return
  }
  // The Edge Function `close-shift` and `export-shift-csv` REQUIRE a real
  // shiftId. Auto-fetch the open shift for this branch so the receptionist
  // doesn't have to type one in.
  const { data, error: err } = await supabase
    .from('shifts')
    .select('*')
    .eq('branch_id', activeBranchId.value)
    .eq('status', 'open')
    .order('opened_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (err) {
    error.value = err.message
    activeShift.value = null
    return
  }
  activeShift.value = (data as Shift) ?? null
}

async function refreshAll() {
  loading.value = true
  error.value = null
  try {
    await fetchActiveShift()
    await fetchPaymentsForShift()
  } finally {
    loading.value = false
  }
}

onMounted(refreshAll)

async function handleCloseShift() {
  if (!activeShift.value) {
    Swal.fire('Thông báo', 'Chưa có ca nào đang mở tại chi nhánh này.', 'info')
    return
  }
  // Display the system-computed `expected` (opening + cash) and ask the
  // receptionist ONLY for the actual counted cash. We never ask for
  // "expected" — that's the system's job to compute and verify against.
  const summary = cashSummary.value
  const expected = summary?.expected ?? 0
  const { value: formValues } = await Swal.fire({
    title: 'Đóng ca',
    html:
      `<div class="text-left text-sm space-y-2 mb-3">` +
        `<div class="flex justify-between"><span>Tiền đầu ca:</span><b>${(summary?.opening ?? 0).toLocaleString('vi-VN')}đ</b></div>` +
        `<div class="flex justify-between"><span>Tiền mặt kỳ vọng (hệ thống):</span><b>${expected.toLocaleString('vi-VN')}đ</b></div>` +
      `</div>` +
      `<input id="closing-cash" type="number" min="0" step="1000" class="swal2-input" placeholder="Tiền mặt thực đếm (VND)">` +
      `<textarea id="handover-notes" class="swal2-textarea" placeholder="Ghi chú bàn giao (tuỳ chọn)"></textarea>`,
    focusConfirm: false,
    showCancelButton: true,
    confirmButtonText: 'Xác nhận đóng ca',
    cancelButtonText: 'Huỷ',
    preConfirm: () => {
      const cash = (document.getElementById('closing-cash') as HTMLInputElement).value
      const notes = (document.getElementById('handover-notes') as HTMLTextAreaElement).value
      if (cash === '' || Number.isNaN(Number(cash)) || Number(cash) < 0) {
        Swal.showValidationMessage('Vui lòng nhập số tiền thực đếm (≥ 0)')
        return false
      }
      return { closingCash: Number(cash), notes }
    },
  })
  if (!formValues) return

  loading.value = true
  error.value = null
  try {
    // `useShift.closeShift` posts camelCase payload to match the Edge Function
    // contract exactly: { shiftId, closingCash, notes? }.
    const result = await closeShift({
      shiftId: activeShift.value.id,
      closingCash: formValues.closingCash,
      notes: formValues.notes || undefined,
    })
    const diff = result?.cashDifference ?? 0
    Swal.fire({
      icon: 'success',
      title: 'Đóng ca thành công',
      html:
        `Chênh lệch tiền mặt: <b>${diff.toLocaleString('vi-VN')}đ</b><br/>` +
        (result?.expectedCash != null
          ? `Kỳ vọng: <b>${result.expectedCash.toLocaleString('vi-VN')}đ</b><br/>`
          : '') +
        `Thực đếm: <b>${formValues.closingCash.toLocaleString('vi-VN')}đ</b>`,
    })
    activeShift.value = null
    await refreshAll()
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    error.value = message
    Swal.fire('Lỗi', 'Lỗi đóng ca: ' + message, 'error')
  } finally {
    loading.value = false
    void shiftLoading.value
    void shiftError.value
  }
}

async function handleExportCSV() {
  if (!activeShift.value) {
    Swal.fire('Thông báo', 'Chưa có ca nào đang mở tại chi nhánh này để export.', 'info')
    return
  }
  loading.value = true
  error.value = null
  try {
    // `useShift.exportCsv` returns raw CSV text (the Edge Function responds
    // with `text/csv` — supabase.functions.invoke can't JSON-parse it, so the
    // composable uses fetch directly).
    const csv = await exportCsv(activeShift.value.id)
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `shift-${activeShift.value.id}.csv`
    document.body.appendChild(a)
    a.click()
    a.remove()
    URL.revokeObjectURL(url)
    Swal.fire('Thành công', 'Đã tải file CSV.', 'success')
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    error.value = message
    Swal.fire('Lỗi', 'Lỗi xuất CSV: ' + message, 'error')
  } finally {
    loading.value = false
  }
}
</script>