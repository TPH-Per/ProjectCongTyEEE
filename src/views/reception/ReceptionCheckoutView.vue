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
          {{ $t('reception.checkout.title', { table_name: tableInfo?.code || (tableId as string) }) }}
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
      {{ $t('reception.checkout.no_open_invoice') }}
    </div>

    <template v-else>
      <!-- Communication Script -->
      <div class="bg-blue-50 border border-blue-200 rounded-2xl p-5 mb-6 flex gap-4 shadow-sm">
        <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center shrink-0">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-600">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
        </div>
        <div>
          <h3 class="text-sm font-bold text-blue-900 mb-1">{{ $t('reception.checkout.script_title') }}</h3>
          <p class="text-blue-800 font-medium italic">{{ $t('reception.checkout.script_content') }}</p>
        </div>
      </div>

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
              {{ $t('reception.checkout.step1_title') }}
            </h3>
            <div class="flex gap-3 mb-6">
              <input
                v-model="customerPhone"
                type="tel"
                inputmode="tel"
                :placeholder="$t('reception.checkout.phone_placeholder')"
                class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold"
                @keydown.enter="findCustomer"
              />
              <button
                @click="findCustomer"
                :disabled="!customerPhone.trim() || customerLoading"
                class="bg-gray-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-black transition-colors disabled:opacity-50"
              >
                {{ customerLoading ? '...' : $t('reception.checkout.search') }}
              </button>
            </div>
            <div v-if="customerInfo" class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4">
              <div class="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl shrink-0">
                {{ (customerInfo.name || 'K').charAt(0).toUpperCase() }}
              </div>
              <div class="flex-1">
                <div class="flex justify-between items-start">
                  <div>
                    <h4 class="font-bold text-gray-900 text-lg">{{ customerInfo.name }}</h4>
                    <div class="text-sm text-gray-600 mb-2">SĐT: {{ customerInfo.phone }}</div>
                  </div>
                  <div class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-bold border border-red-200">
                    {{ $t('reception.checkout.member') }}
                  </div>
                </div>
              </div>
            </div>
            <p v-else-if="customerSearched && !customerInfo" class="text-sm text-gray-500">
              {{ $t('reception.checkout.customer_not_found') }}
            </p>
          </div>

          <!-- Promo & Revenue Type -->
          <div class="bg-white border rounded-2xl p-6 shadow-sm">
            <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">
              {{ $t('reception.checkout.step2_title') }}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-bold text-gray-700 mb-2">{{ $t('reception.checkout.revenue_type') }}</label>
                <select
                  v-model="revenueType"
                  class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base font-semibold focus:outline-none focus:border-red-500 text-gray-900"
                >
                  <option value="dinner">{{ $t('reception.checkout.dinner') }}</option>
                  <option value="lunch">{{ $t('reception.checkout.lunch') }}</option>
                  <option value="wine">{{ $t('reception.checkout.wine') }}</option>
                  <option value="delivery">{{ $t('reception.checkout.delivery') }}</option>
                  <option value="other">{{ $t('reception.checkout.other') }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-bold text-gray-700 mb-2">{{ $t('reception.checkout.enter_voucher') }}</label>
                <div class="flex gap-2">
                  <input
                    v-model="voucherCode"
                    type="text"
                    :placeholder="$t('reception.checkout.voucher_placeholder')"
                    class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 uppercase font-semibold text-gray-900"
                  />
                  <button
                    @click="applyVoucher"
                    :disabled="!voucherCode.trim()"
                    class="bg-gray-200 text-gray-700 px-4 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors shrink-0 disabled:opacity-50"
                  >
                    {{ $t('reception.checkout.apply') }}
                  </button>
                </div>
                <p v-if="voucherApplied" class="text-xs text-green-700 mt-2">{{ $t('reception.checkout.voucher_applied_notice') }}</p>
              </div>
            </div>
          </div>

          <!-- Payment method (simulated) -->
          <div class="bg-white border rounded-2xl p-6 shadow-sm">
            <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">
              {{ $t('reception.checkout.step3_title') }}
            </h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
              <button
                v-for="m in paymentMethods"
                :key="m.value"
                @click="selectPaymentMethod(m.value)"
                :class="[
                  'p-4 rounded-xl border-2 text-center font-bold transition-colors',
                  paymentMethod === m.value
                    ? 'border-red-500 bg-red-50 text-red-700'
                    : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300',
                ]"
              >
                <div class="text-2xl mb-1">{{ m.icon }}</div>
                <div class="text-sm">{{ m.label }}</div>
              </button>
            </div>

            <!-- Cash inputs -->
            <div v-if="paymentMethod === 'cash'" class="space-y-3">
              <label class="block text-sm font-bold text-gray-700">{{ $t('reception.checkout.received_amount') }}</label>
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
                {{ $t('reception.checkout.change_amount') }} <b>{{ change.toLocaleString('vi-VN') }}đ</b>
              </div>
              <div v-else-if="receivedAmount && receivedAmount > 0 && receivedAmount < totalAmount" class="bg-yellow-50 border border-yellow-200 rounded-xl p-3 text-sm text-yellow-800">
                {{ $t('reception.checkout.insufficient_amount', { amount: (totalAmount - receivedAmount).toLocaleString('vi-VN') }) }}
              </div>
            </div>

            <!-- Card/Transfer inputs -->
            <div v-else-if="paymentMethod === 'card' || paymentMethod === 'transfer'" class="space-y-3">
              <label class="block text-sm font-bold text-gray-700">{{ $t('reception.checkout.reference_code') }}</label>
              <input
                v-model="paymentReference"
                type="text"
                :placeholder="paymentMethod === 'card' ? $t('reception.checkout.card_last_4') : $t('reception.checkout.transaction_code')"
                class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold"
              />
              <p class="text-xs text-yellow-700 bg-yellow-50 border border-yellow-200 rounded-lg p-2">
                {{ $t('reception.checkout.simulation_notice') }}
              </p>
            </div>

            <div v-else-if="paymentMethod === 'voucher'" class="text-sm text-gray-600 bg-gray-50 border rounded-xl p-3">
              {{ $t('reception.checkout.voucher_payment_notice') }}
            </div>
          </div>
        </div>

        <!-- Right Column: Bill Summary -->
        <div class="bg-white border rounded-2xl p-0 shadow-sm flex flex-col overflow-hidden">
          <div class="p-6 border-b bg-gray-50">
            <h3 class="text-lg font-bold text-gray-900">{{ $t('reception.checkout.invoice_summary') }}</h3>
            <p class="text-sm text-gray-500">
              {{ tableInfo?.code || '—' }} — {{ guestCount }} {{ $t('reception.checkout.guest_count') }}
            </p>
          </div>

          <div class="p-6 flex-1 overflow-y-auto">
            <div v-if="loading" class="text-sm text-gray-500 py-6 text-center">{{ $t('reception.checkout.loading_invoice') }}</div>
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
              <div v-if="orderItems.length === 0" class="text-center text-gray-500">{{ $t('reception.checkout.no_items') }}</div>
            </div>

            <div class="space-y-3 pt-4 border-t" v-if="orderItems.length > 0">
              <div class="flex justify-between items-center">
                <span class="text-gray-500">{{ $t('reception.checkout.subtotal') }}</span>
                <span class="font-semibold text-gray-900">{{ Number(subTotal).toLocaleString('vi-VN') }}đ</span>
              </div>
              <div class="flex justify-between items-center text-gray-500">
                <span>{{ $t('reception.checkout.vat') }}</span>
                <span>{{ Number(vat).toLocaleString('vi-VN') }}đ</span>
              </div>
              <div class="flex justify-between items-center text-green-600" v-if="voucherApplied">
                <span class="font-bold">{{ $t('reception.checkout.voucher') }}</span>
                <span class="font-bold">{{ $t('reception.checkout.will_apply') }}</span>
              </div>
            </div>
          </div>

          <div class="p-6 bg-gray-50 border-t">
            <div class="flex justify-between items-end mb-6">
              <span class="text-gray-700 font-bold">{{ $t('reception.checkout.total_amount') }}</span>
              <span class="text-3xl font-black text-red-600">{{ Number(totalAmount).toLocaleString('vi-VN') }}đ</span>
            </div>

            <button
              @click="handleCheckout"
              :disabled="loading || !orderInfo || orderItems.length === 0 || !canCheckout"
              class="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-xl shadow-lg transition-colors text-lg flex items-center justify-center gap-2 mb-3 disabled:opacity-50"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="6 9 6 2 18 2 18 9" />
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
                <rect width="12" height="8" x="6" y="14" />
              </svg>
              {{ loading ? $t('reception.checkout.processing') : $t('reception.checkout.print_invoice_close_table') }}
            </button>
            <p v-if="!canCheckout && paymentMethod === 'cash'" class="text-xs text-yellow-700 text-center">
              {{ $t('reception.checkout.enter_amount_warning') }}
            </p>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import Swal from 'sweetalert2'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useCustomer } from '@/composables/useCustomer'
import { useCheckout } from '@/composables/useCheckout'
import { supabase } from '@/lib/supabase'
import type { OrderRow, OrderItem, TableT, Customer } from '@/types/database'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { branchId } = useAuth()
const { searchByPhone } = useCustomer()
const { checkout, loading: checkoutLoading } = useCheckout()

const tableId = computed(() => route.params.id as string)

const loading = ref(false)
const error = ref<string | null>(null)
const tableInfo = ref<TableT | null>(null)
const orderInfo = ref<OrderRow | null>(null)
const orderItems = ref<OrderItem[]>([])

const customerPhone = ref('')
const customerInfo = ref<Customer | null>(null)
const customerSearched = ref(false)
const customerLoading = ref(false)
const voucherCode = ref('')
const voucherApplied = ref(false)

const revenueType = ref<'lunch' | 'dinner' | 'wine' | 'delivery' | 'other'>('dinner')
const paymentMethod = ref<'cash' | 'card' | 'transfer' | 'voucher' | 'other'>('cash')
const receivedAmount = ref<number | null>(null)
const paymentReference = ref('')

const paymentMethods = computed<{ value: typeof paymentMethod.value; label: string; icon: string }[]>(() => [
  { value: 'cash', label: t('reception.checkout.cash'), icon: '💵' },
  { value: 'card', label: t('reception.checkout.card'), icon: '💳' },
  { value: 'transfer', label: t('reception.checkout.transfer'), icon: '🏦' },
  { value: 'voucher', label: t('reception.checkout.voucher_label'), icon: '🎟️' },
])

const quickAmounts = computed<number[]>(() => {
  // Round up to nearest 50k for quick-cash buttons, up to 1.5x total.
  const total = Math.max(totalAmount.value, 50000)
  const candidates = [50000, 100000, 200000, 500000]
  const recv = receivedAmount.value ?? 0
  return [...candidates.filter((c) => c >= total && c >= recv), Math.ceil((total * 1.2) / 50000) * 50000]
    .filter((v, i, a) => a.indexOf(v) === i)
    .slice(0, 4)
})

const subTotal = computed(() =>
  orderItems.value.reduce((acc, item) => acc + Number(item.unit_price) * Number(item.quantity), 0),
)
// VAT is computed server-side via orders.vat_rate. We display the stored value
// (loaded via `orderInfo.vat`) so the client never duplicates the math.
const vat = computed(() => Number(orderInfo.value?.vat ?? Math.round(subTotal.value * 0.08)))
// `orders` row doesn't carry a discount column — the server-side checkout Edge
// Function applies voucher discounts. We expose 0 here so the client never
// invents a discount amount.
const totalAmount = computed(() => {
  if (orderInfo.value?.total != null) return Number(orderInfo.value.total)
  return Math.max(0, subTotal.value + vat.value)
})

const guestCount = computed(() => {
  // orders table doesn't have a guests column; we fall back to reservation
  // guests when present, otherwise the table capacity.
  const o = orderInfo.value as unknown as { guests?: number } | null
  if (o?.guests) return o.guests
  return tableInfo.value?.capacity ?? '—'
})

const change = computed(() => {
  if (paymentMethod.value !== 'cash' || !receivedAmount.value) return 0
  return Math.max(0, Number(receivedAmount.value) - totalAmount.value)
})

const canCheckout = computed(() => {
  if (!orderInfo.value) return false
  if (orderItems.value.length === 0) return false
  if (paymentMethod.value === 'cash') {
    return receivedAmount.value != null && Number(receivedAmount.value) >= totalAmount.value
  }
  return true
})

const statusLine = computed(() => {
  if (loading.value) return t('reception.checkout.loading')
  if (!orderInfo.value) return t('reception.checkout.no_open_order')
  if (checkoutLoading.value) return t('reception.checkout.processing_payment')
  return t('reception.checkout.ready_to_pay')
})

function selectPaymentMethod(m: typeof paymentMethod.value) {
  paymentMethod.value = m
  if (m !== 'cash') {
    receivedAmount.value = null
  } else {
    receivedAmount.value = totalAmount.value
  }
}

async function findCustomer() {
  if (!customerPhone.value.trim()) return
  customerLoading.value = true
  customerSearched.value = false
  customerInfo.value = null
  try {
    const results = await searchByPhone(customerPhone.value.trim())
    customerInfo.value = results[0] ?? null
    customerSearched.value = true
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
  } finally {
    customerLoading.value = false
  }
}

function applyVoucher() {
  // The Edge Function `checkout` validates the voucher (exists, expiry, usage
  // limit, percent/fixed) — see supabase/functions/checkout/index.ts. We just
  // record the user's intent here; the server is the source of truth for the
  // discount amount.
  if (!voucherCode.value.trim()) return
  voucherApplied.value = true
  Swal.fire({
    icon: 'info',
    title: t('reception.checkout.voucher_will_be_checked'),
    text: t('reception.checkout.voucher_check_msg', { code: voucherCode.value.toUpperCase() }),
  })
}

async function loadOrder() {
  if (!branchId.value) {
    error.value = t('reception.checkout.no_branch_error')
    return
  }
  loading.value = true
  error.value = null
  try {
    // 1. Table info (scoped by branch_id via RLS — don't trust client filter alone).
    const { data: tData, error: tErr } = await supabase
      .from('tables')
      .select('*')
      .eq('id', tableId.value)
      .maybeSingle()
    if (tErr) throw tErr
    tableInfo.value = (tData as TableT) ?? null

    // 2. Active order for this table. DB enum order_status is:
    //    'Pending' | 'Preparing' | 'Served' | 'Paid' | 'Cancelled'.
    //    An order is "still in progress" while it's in any of the first three.
    //    `Paid` / `Cancelled` must never reach the checkout screen.
    const { data: oData, error: oErr } = await supabase
      .from('orders')
      .select('*')
      .eq('table_id', tableId.value)
      .in('status', ['Pending', 'Preparing', 'Served'])
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (oErr) throw oErr
    orderInfo.value = (oData as OrderRow) ?? null

    // 3. Order items for the bill.
    if (orderInfo.value) {
      const { data: items, error: iErr } = await supabase
        .from('order_items')
        .select('*')
        .eq('order_id', orderInfo.value.id)
        .order('created_at', { ascending: true })
      if (iErr) throw iErr
      orderItems.value = (items as OrderItem[]) ?? []
    } else {
      orderItems.value = []
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err)
  } finally {
    loading.value = false
  }
}

async function handleCheckout() {
  if (!orderInfo.value) return
  if (!canCheckout.value) {
    error.value = t('reception.checkout.payment_condition_not_met')
    return
  }
  // Edge Function expects camelCase keys. See useCheckout & checkout/index.ts.
  const payment: {
    method: typeof paymentMethod.value
    amount: number
    receivedAmount?: number
    reference?: string
  } = {
    method: paymentMethod.value,
    amount: totalAmount.value,
  }
  if (paymentMethod.value === 'cash' && receivedAmount.value != null) {
    payment.receivedAmount = Number(receivedAmount.value)
  }
  if ((paymentMethod.value === 'card' || paymentMethod.value === 'transfer') && paymentReference.value.trim()) {
    payment.reference = paymentReference.value.trim()
  }

  try {
    const result = await checkout({
      orderId: orderInfo.value.id,
      revenueType: revenueType.value,
      customerId: customerInfo.value?.id,
      voucherCode: voucherApplied.value ? voucherCode.value.trim().toUpperCase() : undefined,
      payments: [payment],
    })
    await Swal.fire({
      icon: 'success',
      title: t('reception.checkout.payment_success'),
      html:
        `${t('reception.checkout.invoice_label')} <b>${result.invoiceNumber}</b><br/>` +
        `${t('reception.checkout.total_label')} <b>${Number(result.total).toLocaleString('vi-VN')}đ</b><br/>` +
        `${t('reception.checkout.change_label')} <b>${Number(result.change).toLocaleString('vi-VN')}đ</b>`,
    })
    router.push('/reception/dashboard')
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    error.value = msg
    Swal.fire(t('reception.checkout.error'), t('reception.checkout.payment_failed') + msg, 'error')
  }
}

onMounted(loadOrder)
</script>