<template>
  <div class="min-h-screen bg-[#FAF3E8] p-4 md:p-6 text-[#3D2817] font-sans">
    <!-- Page Header -->
    <div class="mb-6 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <button
          @click="goBack"
          class="p-2 rounded-xl bg-white border border-[#E8772E]/10 hover:bg-gray-50 transition-colors shadow-sm"
          type="button"
        >
          <ArrowLeft class="w-5 h-5 text-[#E8772E]" />
        </button>
        <div>
          <h1 class="text-2xl font-black tracking-tight">{{
            t('reception.current_shift_summary', 'Tổng kết ca làm việc')
          }}</h1>
          <p class="text-sm font-bold text-gray-500">{{ activeBranchName }}</p>
        </div>
      </div>

      <!-- Close Shift Button -->
      <button
        v-if="shiftStore.isOpen"
        @click="showCloseModal = true"
        class="px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-lg font-bold text-sm transition-all flex items-center gap-2 shadow-lg shadow-red-600/20"
        type="button"
      >
        <Lock class="w-4 h-4" />
        {{ t('reception.close_shift.confirm_close_btn', 'Đóng ca & Đối soát') }}
      </button>
    </div>

    <!-- No Active Shift State -->
    <div v-if="!shiftStore.currentShift && !shiftStore.loading" class="bg-white rounded-2xl border border-[#E8772E]/10 shadow-sm p-12 text-center">
      <div class="w-16 h-16 rounded-full bg-yellow-50 flex items-center justify-center mx-auto mb-4">
        <Clock class="w-8 h-8 text-yellow-500" />
      </div>
      <h3 class="text-lg font-bold text-gray-700 mb-2">{{ t('reception.no_open_shift', 'Chưa mở ca làm việc') }}</h3>
      <p class="text-sm text-gray-500 mb-6">{{ t('reception.please_open_shift', 'Vui lòng mở ca làm việc để tiếp tục') }}</p>
      <button
        @click="showOpenModal = true"
        class="px-6 py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg font-bold text-sm transition-all shadow-md"
        type="button"
      >
        <LockOpen class="w-4 h-4 inline mr-1.5" />
        {{ t('reception.open_shift_btn', 'Mở ca') }}
      </button>
    </div>

    <!-- Shift Summary Content -->
    <template v-if="shiftStore.currentShift">
      <!-- Overview Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <!-- Status Card -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">{{ t('reception.status', 'Trạng thái') }}</div>
          <div class="flex items-center gap-2">
            <div class="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-lg font-black text-green-700">{{ t('reception.open_shift', 'Ca đang mở') }}</span>
          </div>
          <div class="text-xs text-gray-400 mt-2 font-bold">{{ shiftTimeIndicator }}</div>
        </div>

        <!-- Cashier Card -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">{{ t('reception.username', 'Nhân viên') }}</div>
          <div class="flex items-center gap-2">
            <div class="w-9 h-9 rounded-full bg-[#E8772E]/10 flex items-center justify-center">
              <User class="w-5 h-5 text-[#E8772E]" />
            </div>
            <span class="text-sm font-bold text-[#3D2817]">{{ cashierName }}</span>
          </div>
        </div>

        <!-- Start Time Card -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">{{ t('reception.start_time', 'Giờ bắt đầu') }}</div>
          <div class="flex items-center gap-2">
            <Clock class="w-5 h-5 text-blue-500" />
            <span class="text-sm font-mono font-bold text-[#3D2817]">{{ formatDateTime(shiftStore.currentShift.opened_at) }}</span>
          </div>
        </div>

        <!-- Opening Cash Card -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">{{ t('reception.opening_balance', 'Số dư đầu ca') }}</div>
          <div class="flex items-center gap-2">
            <Wallet class="w-5 h-5 text-green-500" />
            <span class="text-lg font-mono font-black text-green-700">{{ shiftStore.openingCash.toLocaleString('vi-VN') }}đ</span>
          </div>
        </div>
      </div>

      <!-- Revenue Breakdown Table -->
      <div class="bg-white border border-[#E8772E]/10 rounded-2xl shadow-sm overflow-hidden mb-6">
        <div class="bg-gray-50 px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-extrabold text-[#3D2817] text-base flex items-center gap-2">
            <BarChart3 class="w-5 h-5 text-[#E8772E]" />
            {{ t('reception.close_shift.revenue_by_type', 'Doanh thu theo hình thức') }}
          </h3>
          <button
            @click="refreshData"
            :disabled="shiftStore.loading"
            class="text-xs font-bold text-[#E8772E] hover:underline disabled:opacity-50"
            type="button"
          >
            <RefreshCw class="w-3.5 h-3.5 inline" :class="{ 'animate-spin': shiftStore.loading }" />
            {{ t('crm.refresh', 'Làm mới') }}
          </button>
        </div>

        <table class="w-full text-sm">
          <thead>
            <tr class="bg-gray-50/50 border-b">
              <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-left">{{ t('reception.close_shift.payment_method', 'Phương thức') }}</th>
              <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-right">{{ t('reception.close_shift.amount', 'Số tiền') }}</th>
              <th class="py-3 px-6 text-xs font-bold text-gray-500 uppercase text-right">%</th>
            </tr>
          </thead>
          <tbody class="divide-y">
            <!-- Cash -->
            <tr class="hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-6 flex items-center gap-2">
                <Banknote class="w-4 h-4 text-green-600" />
                <span class="font-bold text-[#3D2817]">{{ t('reception.close_shift.cash_label', 'Tiền mặt') }}</span>
              </td>
              <td class="py-4 px-6 text-right font-mono font-bold text-green-700">{{ shiftStore.cashRevenue.toLocaleString('vi-VN') }}đ</td>
              <td class="py-4 px-6 text-right font-bold text-gray-500">{{ percentage(shiftStore.cashRevenue) }}%</td>
            </tr>
            <!-- Card -->
            <tr class="hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-6 flex items-center gap-2">
                <CreditCard class="w-4 h-4 text-blue-600" />
                <span class="font-bold text-[#3D2817]">{{ t('reception.close_shift.card_label', 'Thẻ') }}</span>
              </td>
              <td class="py-4 px-6 text-right font-mono font-bold text-blue-700">{{ shiftStore.cardRevenue.toLocaleString('vi-VN') }}đ</td>
              <td class="py-4 px-6 text-right font-bold text-gray-500">{{ percentage(shiftStore.cardRevenue) }}%</td>
            </tr>
            <!-- Transfer -->
            <tr class="hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-6 flex items-center gap-2">
                <Smartphone class="w-4 h-4 text-purple-600" />
                <span class="font-bold text-[#3D2817]">{{ t('reception.close_shift.transfer_label', 'Chuyển khoản') }}</span>
              </td>
              <td class="py-4 px-6 text-right font-mono font-bold text-purple-700">{{ shiftStore.transferRevenue.toLocaleString('vi-VN') }}đ</td>
              <td class="py-4 px-6 text-right font-bold text-gray-500">{{ percentage(shiftStore.transferRevenue) }}%</td>
            </tr>
            <!-- Other -->
            <tr v-if="shiftStore.otherRevenue > 0" class="hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-6 flex items-center gap-2">
                <Coins class="w-4 h-4 text-orange-600" />
                <span class="font-bold text-[#3D2817]">{{ t('reception.close_shift.other_label', 'Khác') }}</span>
              </td>
              <td class="py-4 px-6 text-right font-mono font-bold text-orange-700">{{ shiftStore.otherRevenue.toLocaleString('vi-VN') }}đ</td>
              <td class="py-4 px-6 text-right font-bold text-gray-500">{{ percentage(shiftStore.otherRevenue) }}%</td>
            </tr>
            <!-- Total -->
            <tr class="bg-gray-100">
              <td class="py-4 px-6 font-black text-[#3D2817] uppercase text-xs">{{ t('reception.close_shift.total_daily_revenue', 'Tổng doanh thu') }}</td>
              <td class="py-4 px-6 text-right font-mono font-black text-[#3D2817] text-lg">{{ shiftStore.totalRevenue.toLocaleString('vi-VN') }}đ</td>
              <td class="py-4 px-6 text-right font-bold text-gray-400">100%</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Activity Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <!-- Expected Cash -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm flex items-center justify-between">
          <div>
            <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.close_shift.expected_cash', 'Tiền mặt kỳ vọng') }}</div>
            <div class="text-2xl font-mono font-black text-blue-700 mt-1">{{ shiftStore.expectedCash.toLocaleString('vi-VN') }}đ</div>
            <div class="text-xs text-gray-400 mt-1 font-bold">
              {{ t('reception.opening_balance', 'Đầu ca') }}: {{ shiftStore.openingCash.toLocaleString('vi-VN') }}đ
              + {{ t('reception.close_shift.cash_revenue', 'DT tiền mặt') }}: {{ shiftStore.cashRevenue.toLocaleString('vi-VN') }}đ
            </div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center">
            <Wallet class="w-6 h-6" />
          </div>
        </div>

        <!-- Order Count -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm flex items-center justify-between">
          <div>
            <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.close_shift.order_count', 'Số giao dịch') }}</div>
            <div class="text-2xl font-black text-[#E8772E] mt-1">{{ shiftStore.orderCount }}</div>
            <div class="text-xs text-gray-400 mt-1 font-bold">giao dịch thanh toán</div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-[#E8772E]/10 text-[#E8772E] flex items-center justify-center">
            <Receipt class="w-6 h-6" />
          </div>
        </div>

        <!-- Total Revenue -->
        <div class="bg-white border border-[#E8772E]/10 rounded-2xl p-5 shadow-sm flex items-center justify-between">
          <div>
            <div class="text-xs font-bold text-gray-500 uppercase tracking-wide">{{ t('reception.current_revenue', 'Tổng doanh thu') }}</div>
            <div class="text-2xl font-mono font-black text-green-700 mt-1">{{ shiftStore.totalRevenue.toLocaleString('vi-VN') }}đ</div>
            <div class="text-xs text-gray-400 mt-1 font-bold">tất cả hình thức</div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-green-50 text-green-500 flex items-center justify-center">
            <TrendingUp class="w-6 h-6" />
          </div>
        </div>
      </div>
    </template>

    <!-- Loading State -->
    <div v-if="shiftStore.loading && !shiftStore.currentShift" class="text-center py-12">
      <Loader2 class="w-8 h-8 animate-spin text-[#E8772E] mx-auto" />
      <p class="text-sm text-gray-500 mt-2 font-bold">{{ t('common.loading', 'Đang tải...') }}</p>
    </div>

    <!-- Modals -->
    <OpenShiftModal
      :is-open="showOpenModal"
      :cashier-name="cashierName"
      :loading="shiftStore.loading"
      @close="showOpenModal = false"
      @confirm="handleOpenShift"
    />

    <CloseShiftModal
      v-if="shiftStore.currentShift"
      :is-open="showCloseModal"
      :shift-start-time="shiftStore.currentShift.opened_at"
      :system-expected-cash="shiftStore.expectedCash"
      :card-revenue="shiftStore.cardRevenue"
      :transfer-revenue="shiftStore.transferRevenue"
      :loading="shiftStore.loading"
      @close="showCloseModal = false"
      @confirm="handleCloseShift"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import Swal from 'sweetalert2'
import {
  ArrowLeft,
  Clock,
  User,
  Wallet,
  BarChart3,
  Banknote,
  CreditCard,
  Smartphone,
  Coins,
  Receipt,
  TrendingUp,
  Lock,
  LockOpen,
  RefreshCw,
  Loader2,
} from 'lucide-vue-next'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { useShiftStore } from '@/stores/shiftStore'
import { supabase } from '@/lib/supabase'
import OpenShiftModal from '@/components/reception/OpenShiftModal.vue'
import CloseShiftModal from '@/components/reception/CloseShiftModal.vue'

const router = useRouter()
const route = useRoute()
const langStore = useLanguageStore()
const t = langStore.t
const { profile, branchId } = useAuth()
const { activeBranchId } = useBranch()
const shiftStore = useShiftStore()

const showOpenModal = ref(false)
const showCloseModal = ref(false)
const activeBranchName = ref('')

const activeBranch = computed(() => activeBranchId.value ?? branchId.value ?? '')
const cashierName = computed(() => profile.value?.full_name || 'Thu Ngân')

const shiftTimeIndicator = computed(() => {
  if (!shiftStore.currentShift) return '—'
  const openedHour = new Date(shiftStore.currentShift.opened_at).getHours()
  if (openedHour >= 6 && openedHour < 12) return t('shift.type.morning', 'Ca sáng')
  if (openedHour >= 12 && openedHour < 18) return t('shift.type.afternoon', 'Ca chiều')
  return t('shift.type.evening', 'Ca tối')
})

function percentage(amount: number): string {
  if (shiftStore.totalRevenue === 0) return '0'
  return ((amount / shiftStore.totalRevenue) * 100).toFixed(1)
}

function formatDateTime(iso?: string | null): string {
  if (!iso) return '—'
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}

async function fetchBranchInfo() {
  if (!activeBranch.value) return
  const { data } = await supabase
    .from('branches')
    .select('name')
    .eq('id', activeBranch.value)
    .maybeSingle()
  if (data?.name) activeBranchName.value = data.name
}

async function refreshData() {
  if (!activeBranch.value) return
  await shiftStore.refresh(activeBranch.value)
  await fetchBranchInfo()
}

async function handleOpenShift(openingCash: number) {
  if (!activeBranch.value) return
  try {
    const res = await shiftStore.openShift(activeBranch.value, openingCash)
    showOpenModal.value = false
    await Swal.fire({
      icon: 'success',
      title: res.idempotent
        ? t('reception.dashboard.shift_already_open', 'Ca đã mở từ trước')
        : t('reception.dashboard.shift_opened', 'Đã mở ca'),
      timer: 1500,
      showConfirmButton: false,
    })
  } catch (e: any) {
    Swal.fire('Error', e.message || String(e), 'error')
  }
}

async function handleCloseShift(payload: { actualCash: number; notes: string; managerPin?: string }) {
  try {
    await shiftStore.closeShift(payload.actualCash, payload.notes)
    showCloseModal.value = false
    const diff = payload.actualCash - shiftStore.expectedCash
    await Swal.fire({
      icon: 'success',
      title: t('reception.close_shift.close_shift_success', 'Đóng ca thành công'),
      html: `${t('reception.close_shift.cash_diff', 'Chênh lệch')}: <b>${diff >= 0 ? '+' : ''}${diff.toLocaleString('vi-VN')}đ</b>`,
      timer: 2000,
      showConfirmButton: false,
    })
    router.push('/reception/dashboard')
  } catch (e: any) {
    Swal.fire(
      t('reception.close_shift.error_title', 'Lỗi'),
      e.message || String(e),
      'error',
    )
  }
}

function goBack() {
  router.push('/reception/dashboard')
}

onMounted(async () => {
  await refreshData()
  // Auto-open OpenShiftModal if navigated with ?action=open and no active shift
  if (route.query.action === 'open' && !shiftStore.currentShift) {
    showOpenModal.value = true
  }
})

// React to route query changes (e.g. clicking "Mở ca" in sidebar while already on this page)
watch(
  () => route.query.action,
  (action) => {
    if (action === 'open' && !shiftStore.currentShift) {
      showOpenModal.value = true
    }
  },
)
</script>
