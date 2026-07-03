<template>
  <div>
    <div class="mb-6 flex items-center gap-3">
      <RouterLink
        to="/reception/dashboard"
        class="w-10 h-10 rounded-xl bg-white border flex items-center justify-center text-gray-600 hover:bg-gray-50 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="m15 18-6-6 6-6" />
        </svg>
      </RouterLink>
      <div>
        <h2 class="text-2xl font-bold text-gray-900">
          {{ t('reception.checkout.title', 'Checkout') }} {{ tableInfo?.code || (tableId as string) }}
        </h2>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          <p class="text-sm text-red-600 font-bold">
            {{ statusLine }}
          </p>
        </div>
      </div>
    </div>

    <!-- Empty / missing order state -->
    <div v-if="!loading && (!orderInfo || orderItems.length === 0)" class="kawaii-card p-8 text-center text-gray-500">
      {{ t('reception.checkout.no_open_invoice', 'No open invoice') }}
    </div>

    <template v-else>
      <!-- Error banner -->
      <div v-if="error" class="kawaii-card p-4 mb-4 text-sm text-red-700 bg-red-50 border-red-200">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Left Column: CRM & Info -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Member Check -->
          <div class="bg-white border rounded-2xl p-6 shadow-sm">
            <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">
              1. {{ t('reception.checkout.step1_title', 'Customer Information') }}
            </h3>
            <div class="flex gap-3 mb-6">
              <input
                v-model="customerPhone"
                type="tel"
                inputmode="tel"
                :placeholder="t('reception.checkout.phone_placeholder', 'Phone number')"
                class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold"
                @keydown.enter="findCustomer"
              />
              <button
                @click="findCustomer"
                :disabled="!customerPhone.trim() || customerLoading"
                class="bg-gray-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-black transition-colors disabled:opacity-50"
              >
                {{ customerLoading ? '...' : t('reception.checkout.search', 'Search') }}
              </button>
            </div>
            <div v-if="customerInfo" class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4">
              <div class="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl shrink-0">
                {{ (customerInfo.name || 'C').charAt(0).toUpperCase() }}
              </div>
              <div class="flex-1">
                <div class="flex justify-between items-start">
                  <div>
                    <h4 class="font-bold text-gray-900 text-lg">{{ customerInfo.name }}</h4>
                    <div class="text-sm text-gray-600 mb-2">Phone: {{ customerInfo.phone }}</div>
                  </div>
                  <div class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-bold border border-red-200">
                    {{ customerInfo.tier?.name || t('reception.checkout.member', 'Member') }}
                  </div>
                </div>
              </div>
            </div>
            <p v-else-if="customerSearched && !customerInfo" class="text-sm text-gray-500">
              {{ t('reception.checkout.customer_not_found', 'Customer not found') }}
            </p>
          </div>

          <!-- Promo & Points -->
          <div class="bg-white border rounded-2xl p-6 shadow-sm">
            <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">
              2. {{ t('reception.checkout.step2_title', 'Promotions & Points') }}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-bold text-gray-700 mb-2">{{ t('reception.checkout.enter_voucher', 'Voucher') }}</label>
                <div class="flex gap-2">
                  <input
                    v-model="voucherCode"
                    type="text"
                    :placeholder="t('reception.checkout.voucher_placeholder', 'Voucher code')"
                    class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 uppercase font-semibold text-gray-900"
                    @blur="applyVoucher"
                  />
                  <button
                    @click="applyVoucher"
                    :disabled="!voucherCode.trim() || validatingVoucher"
                    class="bg-gray-200 text-gray-700 px-4 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors shrink-0 disabled:opacity-50"
                  >
                    {{ validatingVoucher ? '...' : t('reception.checkout.apply', 'Apply') }}
                  </button>
                </div>
                <p v-if="voucherApplied" class="text-xs text-green-700 mt-2 font-bold">{{ t('reception.checkout.voucher_applied_notice', 'Voucher valid & applied') }} (-{{ Number(voucherDiscount).toLocaleString('vi-VN') }}đ)</p>
                <p v-else-if="voucherError" class="text-xs text-red-600 mt-2 font-bold">{{ voucherError }}</p>
              </div>

              <!-- Redeem Points -->
              <div v-if="customerInfo && customerInfo.current_points > 0 && rules">
                <label class="block text-sm font-bold text-gray-700 mb-2">{{ t('checkout.discount_points', 'Redeem Points') }}</label>
                <div class="flex flex-col gap-2">
                  <div class="flex gap-2">
                    <input
                      v-model.number="pointsToRedeem"
                      type="number"
                      min="0"
                      :max="maxRedeemablePoints"
                      class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold text-gray-900"
                    />
                    <div class="bg-gray-100 text-gray-700 px-4 py-3 rounded-xl font-bold flex items-center shrink-0">
                      / {{ customerInfo.current_points }}
                    </div>
                  </div>
                  <input
                    type="range"
                    v-model.number="pointsToRedeem"
                    min="0"
                    :max="maxRedeemablePoints"
                    class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
                  />
                  <div class="text-sm font-bold text-green-600" v-if="pointsToRedeem && pointsToRedeem > 0">
                    {{ t('checkout.points_preview', { points: String(pointsToRedeem), amount: Number(pointsDiscount).toLocaleString('vi-VN') }) }}
                  </div>
                  <p class="text-xs text-gray-500">Max redeemable points: {{ maxRedeemablePoints }} (capped at 50% order total)</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Payment method -->
          <div class="bg-white border rounded-2xl p-6 shadow-sm">
            <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">
              3. {{ t('reception.checkout.step3_title', 'Payment Method') }}
            </h3>
            <div class="grid grid-cols-3 md:grid-cols-5 gap-3 mb-4">
              <button
                v-for="m in paymentMethods"
                :key="m.value"
                @click="selectPaymentMethod(m.value)"
                :class="[
                  'p-3 rounded-xl border-2 text-center font-bold transition-colors',
                  paymentMethod === m.value
                    ? 'border-red-500 bg-red-50 text-red-700'
                    : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300',
                ]"
              >
                <div class="text-2xl mb-1">{{ m.icon }}</div>
                <div class="text-xs">{{ m.label }}</div>
              </button>
            </div>

            <!-- Cash inputs -->
            <div v-if="paymentMethod === 'CASH'" class="space-y-3 mt-4">
              <label class="block text-sm font-bold text-gray-700">{{ t('reception.checkout.received_amount', 'Received Amount') }}</label>
              <input
                v-model.number="receivedAmount"
                type="number"
                min="0"
                step="1000"
                placeholder="0"
                class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold"
              />
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="quick in quickAmounts"
                  :key="quick"
                  @click="receivedAmount = quick"
                  class="px-3 py-1 text-xs font-bold bg-gray-100 hover:bg-gray-200 rounded-lg"
                >{{ quick.toLocaleString('vi-VN') }}</button>
              </div>
              <div v-if="change > 0" class="bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-800">
                {{ t('reception.checkout.change_amount', 'Change amount:') }} <b>{{ change.toLocaleString('vi-VN') }}đ</b>
              </div>
              <div v-else-if="receivedAmount && receivedAmount > 0 && receivedAmount < grandTotal" class="bg-yellow-50 border border-yellow-200 rounded-xl p-3 text-sm text-yellow-800">
                {{ t('reception.checkout.insufficient_amount', 'Insufficient amount: need') }} {{(grandTotal - receivedAmount).toLocaleString('vi-VN')}}đ
              </div>
            </div>

            <!-- Card/Transfer inputs -->
            <div v-else class="space-y-3 mt-4">
              <label class="block text-sm font-bold text-gray-700">{{ t('reception.checkout.reference_code', 'Transaction ID / Reference') }}</label>
              <input
                v-model="paymentReference"
                type="text"
                :placeholder="t('reception.checkout.transaction_code', 'Enter ref code (optional)')"
                class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold"
              />
            </div>
          </div>
        </div>

        <!-- Right Column: Bill Summary — driven by hall_get_checkout_totals RPC -->
        <div class="bg-white border rounded-2xl p-0 shadow-sm flex flex-col overflow-hidden h-fit">
          <div class="p-6 border-b bg-gray-50">
            <h3 class="text-lg font-bold text-gray-900">{{ t('reception.checkout.invoice_summary', 'Invoice Summary') }}</h3>
            <p class="text-sm text-gray-500">
              {{ tableInfo?.code || '—' }} — {{ guestCount }} {{ t('reception.checkout.guest_count', 'guests') }}
            </p>
          </div>

          <div class="p-6 flex-1 overflow-y-auto">
            <div v-if="loading" class="text-sm text-gray-500 py-6 text-center">Loading...</div>
            <div v-else class="space-y-3 mb-6">
              <div
                v-for="item in orderItems"
                :key="item.id"
                class="flex justify-between items-center border-b pb-2"
              >
                <span class="font-bold text-gray-700">
                  {{ item.quantity }} x {{ item.name_snapshot }}
                </span>
                <span class="font-bold text-gray-900">
                  {{ Number(item.line_total || item.unit_price * item.quantity).toLocaleString('vi-VN') }}đ
                </span>
              </div>
              <div v-if="orderItems.length === 0" class="text-center text-gray-500">No items</div>
            </div>

            <div class="space-y-3 pt-4 border-t" v-if="orderItems.length > 0">
              <div class="flex justify-between items-center">
                <span class="text-gray-500">{{ t('checkout.subtotal', 'Subtotal') }}</span>
                <span class="font-semibold text-gray-900">{{ Number(subTotal).toLocaleString('vi-VN') }}đ</span>
              </div>
              <div class="flex justify-between items-center text-green-600" v-if="tierDiscount > 0">
                <span>{{ t('checkout.discount_tier', 'Tier Discount') }} ({{ customerInfo?.tier?.discount_percent }}%)</span>
                <span>-{{ Number(tierDiscount).toLocaleString('vi-VN') }}đ</span>
              </div>
              <div class="flex justify-between items-center text-green-600" v-if="voucherDiscount > 0">
                <span>{{ t('checkout.discount_voucher', 'Voucher') }}</span>
                <span>-{{ Number(voucherDiscount).toLocaleString('vi-VN') }}đ</span>
              </div>
              <div class="flex justify-between items-center text-green-600" v-if="pointsDiscount > 0">
                <span>{{ t('checkout.discount_points', 'Points') }}</span>
                <span>-{{ Number(pointsDiscount).toLocaleString('vi-VN') }}đ</span>
              </div>

              <div class="flex justify-between items-center font-bold text-gray-900 mt-2 border-t pt-2">
                <span>Net</span>
                <span>{{ Number(netBeforeTax).toLocaleString('vi-VN') }}đ</span>
              </div>

              <div class="flex justify-between items-center text-gray-500">
                <span>{{ t('checkout.service_charge', 'Service Charge') }} ({{ serviceChargePct }}%)</span>
                <span>+{{ Number(serviceCharge).toLocaleString('vi-VN') }}đ</span>
              </div>

              <div class="flex justify-between items-center text-gray-500">
                <span>{{ t('checkout.vat', 'VAT') }} ({{ Math.round(vatRate * 100) }}%)</span>
                <span>+{{ Number(vatAmount).toLocaleString('vi-VN') }}đ</span>
              </div>
            </div>
          </div>

          <div class="p-6 bg-yellow-50 border-t">
            <div class="flex justify-between items-end mb-6">
              <span class="text-gray-700 font-bold uppercase text-sm tracking-wider">{{ t('checkout.grand_total', 'Grand Total') }}</span>
              <span class="text-4xl font-black text-yellow-600">{{ Number(grandTotal).toLocaleString('vi-VN') }}đ</span>
            </div>

            <button
              @click="handleCheckout"
              :disabled="loading || checkoutLoading || !orderInfo || orderItems.length === 0 || !canCheckout"
              class="w-full bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-4 rounded-xl shadow-lg transition-colors text-lg flex items-center justify-center gap-2 mb-3 disabled:opacity-50"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="6 9 6 2 18 2 18 9" />
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
                <rect width="12" height="8" x="6" y="14" />
              </svg>
              {{ checkoutLoading ? 'Processing Payment...' : t('checkout.confirm', 'Confirm Payment') }}
            </button>
            <p v-if="!canCheckout && paymentMethod === 'CASH'" class="text-xs text-yellow-700 text-center">
              {{ t('reception.checkout.enter_amount_warning', 'Please enter received amount') }}
            </p>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2'
import { useLanguageStore } from '@/stores/useLanguageStore'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useCustomer } from '@/composables/useCustomer'
import { useCheckout } from '@/composables/useCheckout'
import { useVoucher } from '@/composables/useVoucher'
import { useMembership } from '@/composables/useMembership'
import { useRealtime } from '@/composables/useRealtime'
import { supabase } from '@/lib/supabase'
import type { OrderRow, OrderItem, TableT } from '@/types/database'

const langStore = useLanguageStore()
const t = langStore.t
const route = useRoute()
const router = useRouter()
const { branchId, profile } = useAuth()
const { searchByPhone, getCustomerProfile } = useCustomer()
const { executeCheckout, printReceipt, loading: checkoutLoading, previewCheckout } = useCheckout()
const { validateVoucherAtCheckout } = useVoucher()
const { fetchRules, rules } = useMembership()

const tableId = computed(() => route.params.id as string)

const loading = ref(false)
const error = ref<string | null>(null)
const tableInfo = ref<TableT | null>(null)
const orderInfo = ref<OrderRow | null>(null)
const orderItems = ref<OrderItem[]>([])

// Totals come from the RPC (single source of truth) — NOT from local JS math.
// This is the full bill breakdown the DB will compute on process_checkout.
const totals = ref({
  subtotal: 0,
  tier_discount: 0,
  voucher_discount: 0,
  points_discount: 0,
  total_discount: 0,
  net_before_tax: 0,
  service_charge_percent: 5,
  service_charge_amount: 0,
  vat_rate: 0.08,
  vat_amount: 0,
  grand_total: 0,
})

const customerPhone = ref('')
const customerInfo = ref<any>(null)
const customerSearched = ref(false)
const customerLoading = ref(false)

const voucherCode = ref('')
const voucherApplied = ref(false)
// Local mirror of the validated voucher discount before the RPC refreshes
// `totals`. Kept as a separate name (no longer `voucherDiscount` because that
// is the read-only computed driven by `totals.value.voucher_discount`).
const _voucherDiscountLocal = ref(0)
const voucherError = ref<string | null>(null)
const validatingVoucher = ref(false)

const pointsToRedeem = ref<number>(0)

const paymentMethod = ref<'CASH' | 'CARD' | 'ZALOPAY' | 'MOMO' | 'VNPAY'>('CASH')
const receivedAmount = ref<number | null>(null)
const paymentReference = ref('')

const paymentMethods = computed<{ value: typeof paymentMethod.value; label: string; icon: string }[]>(() => [
  { value: 'CASH', label: t('checkout.payment_method_cash', 'CASH'), icon: '💵' },
  { value: 'CARD', label: t('checkout.payment_method_card', 'CARD'), icon: '💳' },
  { value: 'ZALOPAY', label: t('checkout.payment_method_zalopay', 'ZaloPay'), icon: '📱' },
  { value: 'MOMO', label: t('checkout.payment_method_momo', 'MoMo'), icon: '📱' },
  { value: 'VNPAY', label: t('checkout.payment_method_vnpay', 'VNPay'), icon: '📱' },
])

// Local pass-throughs — these read from the RPC response, not local JS math.
// This is the "frontend totals match DB" fix from the audit.
const subTotal = computed(() => totals.value.subtotal)
const tierDiscount = computed(() => totals.value.tier_discount)
const voucherDiscount = computed(() => totals.value.voucher_discount)
const pointsDiscount = computed(() => totals.value.points_discount)
const netBeforeTax = computed(() => totals.value.net_before_tax)
const serviceChargePct = computed(() => totals.value.service_charge_percent)
const serviceCharge = computed(() => totals.value.service_charge_amount)
const vatRate = computed(() => totals.value.vat_rate)
const vatAmount = computed(() => totals.value.vat_amount)
const grandTotal = computed(() => totals.value.grand_total)

const maxRedeemablePoints = computed(() => {
  if (!customerInfo.value || !rules.value) return 0
  const total = Math.max(0, subTotal.value - tierDiscount.value - _voucherDiscountLocal.value)
  const maxDiscountValue = total * 0.5
  const maxPointsByValue = Math.floor(maxDiscountValue / (rules.value.vnd_per_point || 1000))
  return Math.min(customerInfo.value.current_points || 0, maxPointsByValue)
})

const quickAmounts = computed<number[]>(() => {
  const total = Math.max(grandTotal.value, 50000)
  const candidates = [50000, 100000, 200000, 500000]
  const recv = receivedAmount.value ?? 0
  return [...candidates.filter((c) => c >= total && c >= recv), Math.ceil((total * 1.2) / 50000) * 50000]
    .filter((v, i, a) => a.indexOf(v) === i)
    .slice(0, 4)
})

const guestCount = computed(() => {
  const o = orderInfo.value as unknown as { guests?: number } | null
  if (o?.guests) return o.guests as number
  return tableInfo.value?.capacity ?? '—'
})

const change = computed(() => {
  if (paymentMethod.value !== 'CASH' || !receivedAmount.value) return 0
  return Math.max(0, Number(receivedAmount.value) - grandTotal.value)
})

const canCheckout = computed(() => {
  if (paymentMethod.value === 'CASH') {
    return receivedAmount.value != null && Number(receivedAmount.value) >= grandTotal.value
  }
  return true
})

const statusLine = computed(() => {
  if (loading.value) return t('reception.checkout.loading', 'Loading...')
  if (!orderInfo.value) return t('reception.checkout.no_open_order', 'No open order')
  if (checkoutLoading.value) return t('reception.checkout.processing_payment', 'Processing Payment...')
  return t('reception.checkout.ready_to_pay', 'Ready to pay')
})

function selectPaymentMethod(m: typeof paymentMethod.value) {
  paymentMethod.value = m
  if (m !== 'CASH') {
    receivedAmount.value = null
  } else {
    receivedAmount.value = grandTotal.value
  }
}

async function findCustomer() {
  if (!customerPhone.value.trim()) return
  customerLoading.value = true
  customerSearched.value = false
  customerInfo.value = null
  pointsToRedeem.value = 0
  try {
    const results = await searchByPhone(customerPhone.value.trim())
    if (results.length > 0) {
      const p = await getCustomerProfile(results[0].id)
      customerInfo.value = { ...results[0], ...p.customer, tier: p.tier }
    } else {
      customerInfo.value = null
    }
    customerSearched.value = true
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
  } finally {
    customerLoading.value = false
  }
  await refreshTotals()
}

async function applyVoucher() {
  if (!voucherCode.value.trim()) {
    voucherApplied.value = false
    _voucherDiscountLocal.value = 0
    voucherError.value = null
    await refreshTotals()
    return
  }
  validatingVoucher.value = true
  voucherError.value = null
  try {
    const res = await validateVoucherAtCheckout(
      voucherCode.value.trim().toUpperCase(),
      subTotal.value,
      customerInfo.value?.id
    )
    if (res.valid) {
      voucherApplied.value = true
      _voucherDiscountLocal.value = res.discount_amount || 0
      voucherError.value = null
    } else {
      voucherApplied.value = false
      _voucherDiscountLocal.value = 0
      voucherError.value = res.error || 'Invalid voucher'
    }
  } catch (err: any) {
    voucherApplied.value = false
    _voucherDiscountLocal.value = 0
    voucherError.value = err.message || String(err)
  } finally {
    validatingVoucher.value = false
  }
  await refreshTotals()
}

// Re-fetch totals from RPC whenever any input that affects pricing changes.
// The RPC enforces the same logic as process_checkout — single source of truth.
async function refreshTotals() {
  if (!branchId.value || !tableId.value) return
  try {
    const preview = await previewCheckout({
      branchId: branchId.value,
      tableId: tableId.value,
      orderId: orderInfo.value?.id,
      voucherCode: voucherApplied.value ? voucherCode.value.trim().toUpperCase() : undefined,
      pointsToRedeem: pointsToRedeem.value || 0,
      customerId: customerInfo.value?.id,
    })
    if (preview.ok && preview.totals) {
      totals.value = { ...totals.value, ...preview.totals }
    }
  } catch {
    // Silent — totals stay at last good value
  }
}

async function loadOrder() {
  if (!branchId.value) {
    error.value = t('reception.checkout.no_branch_error', 'Branch not found')
    return
  }
  loading.value = true
  error.value = null
  try {
    await fetchRules()

    // Bootstrap: pull the full order snapshot via the new totals RPC. The
    // `table`, `order`, `items` keys are identical between
    // `hall_get_checkout_summary` (legacy) and `hall_get_checkout_totals`
    // (current source of truth — see 20260703020001). refreshTotals() below
    // reads `data.totals` which is only present in the new RPC, so we always
    // call the new one here too.
    const { data, error: rpcErr } = await supabase.rpc('hall_get_checkout_totals', {
      p_branch_id: branchId.value,
      p_table_id: tableId.value,
      p_order_id: null,
    })
    if (rpcErr) throw rpcErr

    tableInfo.value = (data?.table as TableT) ?? null
    orderInfo.value = (data?.order as OrderRow) ?? null
    orderItems.value = (data?.items as OrderItem[]) ?? []
    await refreshTotals()
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
  } finally {
    loading.value = false
  }
}

// Re-fetch totals when points change
watch(pointsToRedeem, () => {
  refreshTotals()
})

async function handleCheckout() {
  if (!orderInfo.value) return
  if (!canCheckout.value) {
    error.value = t('reception.checkout.payment_condition_not_met', 'Conditions not met')
    return
  }

  try {
    const result = await executeCheckout({
      orderId: orderInfo.value.id,
      paymentMethod: paymentMethod.value,
      paymentRef: paymentMethod.value !== 'CASH' && paymentReference.value ? paymentReference.value : undefined,
      voucherCode: voucherApplied.value ? voucherCode.value.trim().toUpperCase() : undefined,
      pointsToRedeem: pointsToRedeem.value || 0,
      branchId: branchId.value as string,
      cashierId: profile.value?.id || '00000000-0000-0000-0000-000000000000',
    })

    // Use the actual grand_total from the DB — never local JS math.
    const finalGrand = Number(result.grand_total ?? 0)

    await Swal.fire({
      icon: 'success',
      title: t('checkout.success', 'Payment Successful!'),
      html:
        `Invoice <b>${result.invoice_number}</b><br/>` +
        `Grand Total: <b style="color: #ca8a04">${finalGrand.toLocaleString('vi-VN')}đ</b><br/>` +
        (result.voucher_discount
          ? `Voucher discount: -${Number(result.voucher_discount).toLocaleString('vi-VN')}đ<br/>`
          : '') +
        (result.service_charge_amount
          ? `Service charge: +${Number(result.service_charge_amount).toLocaleString('vi-VN')}đ<br/>`
          : '') +
        (result.vat_amount
          ? `VAT: +${Number(result.vat_amount).toLocaleString('vi-VN')}đ<br/>`
          : ''),
    })

    printReceipt(result)
    router.push('/reception/dashboard')
  } catch (err: any) {
    const msg = err.message || String(err)
    if (msg.includes('VOUCHER_INVALID') || msg.includes('P0010')) {
      voucherApplied.value = false
      _voucherDiscountLocal.value = 0
      voucherCode.value = ''
      Swal.fire('Voucher Error', 'Voucher expired or invalid. Please re-apply.', 'warning')
    } else {
      error.value = msg
      Swal.fire('Error', t('reception.checkout.payment_failed', 'Payment failed: ') + msg, 'error')
    }
  }
}

onMounted(loadOrder)

// Live update: while the cashier is on this view, refresh the order/items
// snapshot whenever the customer adds an item to the same order (realtime)
// and as a 15-second belt-and-suspenders fallback.
const { watchTable } = useRealtime()
const cleanups: Array<() => void> = []
let autoRefreshTimer: ReturnType<typeof setInterval> | null = null

watchTable<Record<string, unknown>>('order_items', '*', () => {
  loadOrder().catch((e) => console.error('[ReceptionCheckout] realtime reload failed:', e))
})
watchTable<Record<string, unknown>>('orders', '*', () => {
  loadOrder().catch((e) => console.error('[ReceptionCheckout] realtime reload failed:', e))
})
autoRefreshTimer = setInterval(() => {
  loadOrder().catch(() => {})
}, 15_000)

onUnmounted(() => {
  if (autoRefreshTimer) clearInterval(autoRefreshTimer)
  while (cleanups.length) cleanups.pop()!()
})
</script>