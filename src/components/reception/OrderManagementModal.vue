<template>
  <div
    class="fixed inset-0 z-[9000] flex flex-col bg-[#1e1e1e] text-gray-200 select-none"
  >
    <!-- Header -->
    <header
      class="h-16 shrink-0 bg-[#2d2d2d] border-b border-[#1e1e1e] flex items-center justify-between px-6 shadow-md"
    >
      <div class="flex items-center gap-4">
        <button
          @click="$emit('close')"
          class="p-2 hover:bg-[#3a3a3a] rounded-lg transition-colors text-gray-400 hover:text-white"
          type="button"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        <div>
          <h1 class="text-xl font-bold text-white">Quản lý Order</h1>
          <p class="text-sm text-gray-400">Danh sách tất cả đơn hàng</p>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <div class="px-4 py-2 bg-[#3a3a3a] rounded-lg">
          <span class="text-gray-400 text-sm">Tổng order:</span>
          <span class="text-white font-bold ml-2">{{ orders.length }}</span>
        </div>
        <button
          @click="loadOrders"
          :disabled="loading"
          class="px-4 py-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] text-white rounded-lg font-medium text-sm transition-colors flex items-center gap-2 disabled:opacity-50"
          type="button"
        >
          <svg
            class="w-4 h-4"
            :class="{ 'animate-spin': loading }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          {{ loading ? 'Đang tải...' : 'Làm mới' }}
        </button>
      </div>
    </header>

    <!-- Filters -->
    <div class="shrink-0 bg-[#2d2d2d] border-b border-[#1e1e1e] px-6 py-3 flex items-center gap-3">
      <div class="relative flex-1 max-w-md">
        <svg
          class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <circle cx="11" cy="11" r="8" />
          <line x1="21" y1="21" x2="16.65" y2="16.65" />
        </svg>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Tìm theo mã order, bàn, khách..."
          class="w-full pl-10 pr-4 py-2 bg-[#1e1e1e] border border-[#444] rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-[#ff8f00] transition-colors"
        />
      </div>

      <select
        v-model="filterStatus"
        class="px-4 py-2 bg-[#1e1e1e] border border-[#444] rounded-lg text-white text-sm focus:outline-none focus:border-[#ff8f00] cursor-pointer transition-colors"
      >
        <option value="all">Tất cả trạng thái</option>
        <option value="Pending">Chờ xử lý</option>
        <option value="Preparing">Đang chuẩn bị</option>
        <option value="Served">Đã phục vụ</option>
        <option value="Paid">Đã thanh toán</option>
        <option value="Cancelled">Đã hủy</option>
      </select>
    </div>

    <!-- Orders Grid -->
    <main class="flex-1 overflow-y-auto p-6 ordering-screen-scrollbar">
      <div class="max-w-7xl mx-auto">
        <!-- Loading -->
        <div v-if="loading && orders.length === 0" class="flex items-center justify-center py-20">
          <svg class="w-8 h-8 animate-spin text-[#ff8f00]" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
          </svg>
          <span class="ml-3 text-gray-400 text-sm">Đang tải danh sách order...</span>
        </div>

        <!-- Grid -->
        <div v-else-if="filteredOrders.length > 0" class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          <div
            v-for="order in filteredOrders"
            :key="order.id"
            :class="[
              'bg-[#2d2d2d] rounded-xl border-2 p-5 transition-all',
              order.status === 'Cancelled' ? 'border-gray-600 opacity-60' :
              order.status === 'Paid' ? 'border-green-600/50' :
              'border-[#3a3a3a] hover:border-[#ff8f00]/50',
            ]"
          >
            <!-- Order Header -->
            <div class="flex items-start justify-between mb-4">
              <div>
                <h3 class="font-bold text-lg text-white">{{ order.order_number }}</h3>
                <p class="text-sm text-gray-400 mt-1">Bàn: {{ order.table_code || '—' }}</p>
                <p class="text-sm text-gray-400">Khách: {{ order.customer_name || 'Khách lẻ' }}</p>
              </div>
              <span
                :class="['px-3 py-1 rounded-full text-xs font-semibold', getStatusClass(order.status)]"
              >
                {{ getStatusText(order.status) }}
              </span>
            </div>

            <!-- Order Items -->
            <div class="space-y-2 mb-4 max-h-40 overflow-y-auto ordering-screen-scrollbar">
              <div
                v-for="item in order.items"
                :key="item.id"
                class="flex items-center justify-between text-sm"
              >
                <span class="text-gray-300">{{ item.quantity }}x {{ item.name_snapshot }}</span>
                <span class="text-gray-400">{{ formatMoney(item.line_total) }}</span>
              </div>
              <p v-if="!order.items || order.items.length === 0" class="text-gray-500 text-xs italic">
                Chưa có món nào
              </p>
            </div>

            <!-- Order Total -->
            <div class="border-t border-[#3a3a3a] pt-3 mb-4">
              <div class="flex items-center justify-between">
                <span class="text-gray-400 text-sm">Tổng cộng:</span>
                <span class="text-xl font-bold text-[#ff8f00]">{{ formatMoney(order.total) }}</span>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex gap-2">
              <button
                v-if="order.status !== 'Cancelled' && order.status !== 'Paid'"
                @click="$emit('cancelOrder', order)"
                class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium text-sm transition-colors flex items-center justify-center gap-2 active:scale-95"
                type="button"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
                Hủy Order
              </button>
              <div
                v-else
                class="flex-1 px-4 py-2 bg-[#3a3a3a] text-gray-400 rounded-lg font-medium text-sm text-center"
              >
                {{ order.status === 'Cancelled' ? 'Đã hủy' : 'Đã thanh toán' }}
              </div>
            </div>

            <!-- Timestamp -->
            <p class="text-xs text-gray-500 mt-3">
              Tạo lúc: {{ formatTime(order.created_at) }}
            </p>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="text-center py-20">
          <div class="text-6xl mb-4">📭</div>
          <p class="text-gray-400 text-lg">Không tìm thấy order nào</p>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

type OrderStatus = 'Pending' | 'Preparing' | 'Served' | 'Paid' | 'Cancelled'

interface OrderItem {
  id: string
  name_snapshot: string
  quantity: number
  line_total: number
}

interface Order {
  id: string
  order_number: string
  status: OrderStatus
  total: number
  subtotal: number
  guest_count: number | null
  created_at: string
  table_code: string
  customer_name: string
  items: OrderItem[]
}

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'cancelOrder', order: Order): void
}>()

const { branchId } = useAuth()

const orders = ref<Order[]>([])
const loading = ref(false)
const searchQuery = ref('')
const filterStatus = ref<OrderStatus | 'all'>('all')

const filteredOrders = computed(() => {
  let result = orders.value

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim()
    result = result.filter(o =>
      o.order_number?.toLowerCase().includes(q) ||
      o.table_code?.toLowerCase().includes(q) ||
      o.customer_name?.toLowerCase().includes(q)
    )
  }

  if (filterStatus.value !== 'all') {
    result = result.filter(o => o.status === filterStatus.value)
  }

  return result
})

async function loadOrders() {
  if (!branchId.value) return
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        id, order_number, status, total, subtotal, guest_count, created_at,
        table_id,
        tables!inner(code),
        order_items(id, name_snapshot, quantity, line_total)
      `)
      .eq('branch_id', branchId.value)
      .order('created_at', { ascending: false })
      .limit(200)

    if (error) throw error

    orders.value = (data || []).map((o: any) => ({
      id: o.id,
      order_number: o.order_number || '—',
      status: o.status as OrderStatus,
      total: o.total || 0,
      subtotal: o.subtotal || 0,
      guest_count: o.guest_count,
      created_at: o.created_at,
      table_code: o.tables?.code || '—',
      customer_name: '',
      items: (o.order_items || []).map((it: any) => ({
        id: it.id,
        name_snapshot: it.name_snapshot || '—',
        quantity: it.quantity || 1,
        line_total: it.line_total || 0,
      })),
    }))
  } catch (err) {
    console.error('[OrderManagementModal] Failed to load orders:', err)
    orders.value = []
  } finally {
    loading.value = false
  }
}

function getStatusClass(status: OrderStatus): string {
  switch (status) {
    case 'Pending': return 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30'
    case 'Preparing': return 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
    case 'Served': return 'bg-purple-500/20 text-purple-400 border border-purple-500/30'
    case 'Paid': return 'bg-green-500/20 text-green-400 border border-green-500/30'
    case 'Cancelled': return 'bg-red-500/20 text-red-400 border border-red-500/30'
    default: return 'bg-gray-500/20 text-gray-400 border border-gray-500/30'
  }
}

function getStatusText(status: OrderStatus): string {
  switch (status) {
    case 'Pending': return 'Chờ xử lý'
    case 'Preparing': return 'Đang chuẩn bị'
    case 'Served': return 'Đã phục vụ'
    case 'Paid': return 'Hoàn thành'
    case 'Cancelled': return 'Đã hủy'
    default: return status
  }
}

function formatMoney(amount: number): string {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0)
}

function formatTime(isoString: string): string {
  if (!isoString) return '—'
  return new Date(isoString).toLocaleString('vi-VN')
}

onMounted(() => {
  loadOrders()
})

defineExpose({ loadOrders })
</script>
