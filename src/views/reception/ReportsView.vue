<!-- File: src/views/reception/ReportsView.vue -->
<template>
  <!-- CONTAINER CHÍNH: h-screen + overflow-hidden -->
  <div class="reports-page">
    
    <!-- 1. HEADER: flex-shrink-0 (KHÔNG SCROLL) -->
    <div class="reports-header flex-shrink-0">
      <div class="header-left">
        <div class="logo-icon">📊</div>
        <div>
          <h1 class="page-title">{{ t('reception.receipt_list') }}</h1>
          <p class="page-subtitle">{{ t('reception.manage_revenue') }}</p>
        </div>
      </div>
      <div class="header-actions">
        <button class="btn btn-refresh" @click="refreshData">
          <span>🔄</span>{{ t('reception.refresh') }}</button>
        <button class="btn btn-bill-list" @click="viewBillList">
          <span>📄</span>{{ t('reception.invoice_list') }}</button>
        <button class="btn btn-lock" @click="tempExit">
          <span>🔒</span>{{ t('reception.temp_exit') }}</button>
        <button class="btn btn-back" @click="goBack">
          <span>⬅️</span>{{ t('reception.go_back') }}</button>
      </div>
    </div>

    <!-- 2. FILTERS: flex-shrink-0 (KHÔNG SCROLL) -->
    <div class="filters-section flex-shrink-0">
      <div class="filter-row">
        <div class="filter-group search-group">
          <label class="filter-label">{{ t('reception.search_upper') }}</label>
          <input 
            v-model="searchQuery"
            type="text" 
            :placeholder="t('reception.search_by_receipt')"
            class="search-input"
          />
        </div>
        <div class="filter-group">
          <label class="filter-label">{{ t('reception.from_date') }}</label>
          <div class="datetime-row">
            <input v-model="filters.fromDate" type="date" class="date-input" />
            <input v-model="filters.fromTime" type="time" class="time-input" />
          </div>
        </div>
        <div class="filter-group">
          <label class="filter-label">{{ t('reception.to_date') }}</label>
          <div class="datetime-row">
            <input v-model="filters.toDate" type="date" class="date-input" />
            <input v-model="filters.toTime" type="time" class="time-input" />
          </div>
        </div>
      </div>
    </div>

    <!-- 3. MAIN CONTENT: flex-1 + overflow-hidden (CHIẾM PHẦN CÒN LẠI) -->
    <div class="main-content flex-1 overflow-hidden flex flex-col mx-6 mb-6">
      
      <!-- 3.1 TABS + ACTIONS: flex-shrink-0 -->
      <div class="tabs-row flex-shrink-0">
        <div class="tabs-left">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            :class="['tab-btn', { active: activeTab === tab.id }]"
            @click="changeTab(tab.id)"
          >
            {{ tab.label }}
          </button>
        </div>
        <div class="tabs-right">
          <div class="filter-dropdown-wrapper" ref="filterDropdownRef">
            <button 
              class="filter-dropdown-btn"
              @click="showFilterDropdown = !showFilterDropdown"
              :style="{ backgroundColor: currentFilter.color }"
            >
              <span>🔍</span>
              <span>{{ currentFilter.label }}</span>
            </button>
            <Transition name="fade">
              <div v-if="showFilterDropdown" class="filter-dropdown-menu">
                <button
                  v-for="status in statusFilters"
                  :key="status.value"
                  class="filter-dropdown-item"
                  :class="{ active: selectedFilter === status.value }"
                  :style="{ backgroundColor: status.color, color: status.textColor }"
                  @click="applyFilter(status)"
                >
                  {{ status.label }}
                </button>
              </div>
            </Transition>
          </div>
          <button class="btn btn-export" @click="exportData">
            <span>📥</span>{{ t('reception.export_data') }}</button>
          <button class="btn btn-print" @click="printReport">
            <span>🖨️</span>{{ t('reception.print_list') }}</button>
        </div>
      </div>

      <!-- 3.2 DATA TABLE: flex-1 + overflow-y-auto (CHỈ PHẦN NÀY SCROLL DỌC) -->
      <div class="table-wrapper flex-1 overflow-y-auto">
        <table class="data-table">
          <thead>
            <tr>
              <th class="col-checkbox"><input type="checkbox" v-model="selectAll" /></th>
              <th class="col-stt">STT</th>
              <th class="col-so-phieu">{{ t('reception.receipt_no_upper') }}</th>
              <th class="col-so-hd">{{ t('reception.invoice_no') }}</th>
              <th class="col-day-hd">{{ t('reception.invoice_series') }}</th>
              <th class="col-mst">{{ t('reception.customer_tax_code') }}</th>
              <th class="col-trang-thai">{{ t('reception.invoice_status') }}</th>
              <th class="col-khu">KHU</th>
              <th class="col-ban">{{ t('reception.table_upper') }}</th>
              <th class="col-tong-tien">{{ t('reception.total_amount_upper') }}</th>
              <th class="col-da-tra">{{ t('reception.paid_upper') }}</th>
              <th class="col-con-lai">{{ t('reception.remaining_upper') }}</th>
              <th class="col-tien-hang">{{ t('reception.goods_amount_upper') }}</th>
              <th class="col-giam">{{ t('reception.discount_upper') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="(row, index) in filteredData" 
              :key="row.id"
              :class="[
                getRowClass(row), 
                { 'row-selected': selectedRowId === row.id }
              ]"
              @click="handleRowClick(row, $event)"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  v-model="row.selected"
                />
              </td>
              <td class="col-stt">{{ (currentPage - 1) * itemsPerPage + index + 1 }}</td>
              <td class="col-so-phieu font-bold">{{ row.soPhieu }}</td>
              <td class="col-so-hd">{{ row.soHoaDon || '-' }}</td>
              <td class="col-day-hd">{{ row.dayHD || '-' }}</td>
              <td class="col-mst">{{ row.mstKhachHang || '-' }}</td>
              <td class="col-trang-thai">
                <span :class="getStatusBadgeClass(row)">{{ row.trangThai }}</span>
              </td>
              <td class="col-khu">{{ row.khu }}</td>
              <td class="col-ban">{{ row.ban }}</td>
              <td class="col-tong-tien font-bold text-right">{{ formatVND(row.tongTien) }}</td>
              <td class="col-da-tra text-right">{{ formatVND(row.daTra) }}</td>
              <td class="col-con-lai text-right" :class="{ 'text-red font-bold': row.conLai > 0 }">
                {{ formatVND(row.conLai) }}
              </td>
              <td class="col-tien-hang text-right">{{ formatVND(row.tienHang) }}</td>
              <td class="col-giam text-red text-right">{{ formatVND(row.giam) }}</td>
            </tr>
            <tr v-if="filteredData.length === 0">
              <td colspan="14" class="p-8 text-center text-gray-400">{{ t('reception.no_receipts_match') }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 3.3 PAGINATION: flex-shrink-0 -->
      <div class="pagination-footer flex-shrink-0">
        <div class="record-count">SL: {{ filteredData.length }}</div>
        <div class="pagination-info">
          <button :disabled="currentPage === 1" @click="currentPage--" class="cursor-pointer bg-white px-2 py-0.5 border border-gray-200 rounded disabled:opacity-40 disabled:cursor-not-allowed" type="button">&lt;</button>
          <span class="page-current">{{ currentPage }}</span>
          <button :disabled="currentPage === totalPages || totalPages === 0" @click="currentPage++" class="cursor-pointer bg-white px-2 py-0.5 border border-gray-200 rounded disabled:opacity-40 disabled:cursor-not-allowed" type="button">&gt;</button>
          <span class="page-text">&lt;Trang {{ currentPage }} / {{ totalPages || 1 }}&gt;</span>
        </div>
      </div>

      <!-- 3.4 SUMMARY FOOTER: flex-shrink-0 -->
      <div class="summary-footer flex-shrink-0">
        <div class="summary-item">
          <span class="label">{{ t('reception.total_money') }}</span>
          <span class="value">{{ formatVND(summary.tongTien) }}</span>
        </div>
        <div class="summary-item">
          <span class="label">{{ t('reception.paid_amount') }}</span>
          <span class="value text-green">{{ formatVND(summary.daTra) }}</span>
        </div>
        <div class="summary-item">
          <span class="label">{{ t('reception.remaining_amount') }}</span>
          <span class="value text-red">{{ formatVND(summary.conLai) }}</span>
        </div>
        <div class="summary-item">
          <span class="label">{{ t('reception.goods_amount') }}</span>
          <span class="value">{{ formatVND(summary.tienHang) }}</span>
        </div>
      </div>

      <!-- 3.5 SUB TABS + ITEMS TABLE: flex-shrink-0 với max-height -->
      <div class="sub-tabs-section flex-shrink-0">
        <div class="sub-tabs-header">
          <button
            v-for="subTab in subTabs"
            :key="subTab.id"
            :class="['sub-tab-btn', { active: activeSubTab === subTab.id }]"
            @click="activeSubTab = subTab.id"
          >
            {{ subTab.label }}
          </button>
        </div>

        <!-- Items table với scroll riêng nếu cần -->
        <div class="sub-tab-content">
          <div v-if="activeSubTab === 'items'" class="items-table-wrapper">
            <table class="items-table">
              <thead>
                <tr>
                  <th>{{ t('reception.order_no') }}</th>
                  <th>{{ t('reception.item_code') }}</th>
                  <th>{{ t('reception.item_name') }}</th>
                  <th>{{ t('reception.other_name') }}</th>
                  <th class="text-right">SL</th>
                  <th>{{ t('reception.uom') }}</th>
                  <th class="text-right">{{ t('reception.unit_price') }}</th>
                  <th class="text-right">{{ t('reception.discount_detail') }}</th>
                  <th class="text-right">{{ t('reception.receipt_discount') }}</th>
                  <th class="text-right text-red">{{ t('reception.discount_short') }}</th>
                  <th class="text-center">% VAT</th>
                  <th class="text-right">{{ t('reception.tax') }}</th>
                  <th class="text-right">{{ t('reception.total_short') }}</th>
                  <th>{{ t('reception.return_reason') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="sampleItems.length === 0">
                  <td colspan="14" class="p-4 text-center text-gray-400">{{ t('reception.no_records_to_display') }}</td>
                </tr>
                <tr v-for="item in sampleItems" :key="item.id">
                  <td>{{ item.soOrder }}</td>
                  <td>{{ item.maHang }}</td>
                  <td class="font-bold">{{ item.tenHang }}</td>
                  <td class="text-gray-500">{{ item.tenKhac }}</td>
                  <td class="text-right font-bold text-green">{{ item.sl }}</td>
                  <td>{{ item.dvt }}</td>
                  <td class="text-right">{{ formatVND(item.donGia) }}</td>
                  <td class="text-right">{{ formatVND(item.giamCT) }}</td>
                  <td class="text-right">{{ formatVND(item.giamPhieu) }}</td>
                  <td class="text-right text-red font-semibold">{{ formatVND(item.giam) }}</td>
                  <td class="text-center">{{ item.vat }}%</td>
                  <td class="text-right">{{ formatVND(item.thue) }}</td>
                  <td class="text-right font-bold text-gray-800">{{ formatVND(item.tong) }}</td>
                  <td>-</td>
                </tr>
              </tbody>
              <tfoot>
                <tr class="totals-row">
                  <td colspan="4" class="text-right font-bold">{{ t('reception.grand_total_colon') }}</td>
                  <td class="text-right font-bold text-green">{{ totalSL }}</td>
                  <td colspan="5"></td>
                  <td class="text-center font-bold">{{ totalVAT }}%</td>
                  <td class="text-right font-bold text-indigo-600">{{ formatVND(totalThue) }}</td>
                  <td class="text-right font-bold text-green">{{ formatVND(totalTong) }}</td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
          </div>
          <div v-else class="p-8 text-center text-gray-400">
            Nội dung tab [{{ subTabs.find(t => t.id === activeSubTab)?.label }}] đang phát triển.
          </div>
        </div>
      </div>
    </div>

    <!-- ===== FLOATING ACTION MENU ===== -->
    <Transition name="floating-menu" mode="out-in">
      <div 
        v-if="showFloatingMenu"
        class="floating-action-menu"
        :style="{
          top: menuPosition.top + 'px',
          left: menuPosition.left + 'px'
        }"
        @click.stop
      >
        <!-- Menu Header -->
        <div class="menu-header">
          <span class="menu-title">{{ t('reception.action') }}</span>
          <span class="menu-subtitle">
            {{ invoicesData.find(r => r.id === selectedRowId)?.soPhieu || '' }}
          </span>
        </div>

        <!-- Menu Items with stagger animation -->
        <div class="menu-items">
          <button
            v-for="(action, index) in menuActions"
            :key="action.id"
            :class="[
              'menu-item',
              { 'danger-item': action.isDanger }
            ]"
            :style="{ animationDelay: `${index * 0.05}s` }"
            @click="handleMenuAction(action.id)"
          >
            <span class="menu-icon">{{ action.icon }}</span>
            <span class="menu-label">{{ action.label }}</span>
            <span class="menu-arrow"></span>
          </button>
        </div>
      </div>
    </Transition>

    <!-- Backdrop with blur animation -->
    <Transition name="fade">
      <div 
        v-if="showFloatingMenu" 
        class="floating-backdrop"
        :class="{ show: showFloatingMenu }"
        @click="closeFloatingMenu"
      ></div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { useLanguageStore } from '@/stores/useLanguageStore';
const languageStore = useLanguageStore();
const { t } = languageStore;

import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import Swal from 'sweetalert2'

const router = useRouter()

// State
const searchQuery = ref('')
const activeTab = ref('restaurant')
const activeSubTab = ref('items')
const currentPage = ref(1)
const itemsPerPage = ref(20)
const showFilterDropdown = ref(false)
const selectedFilter = ref('all')
const selectedRow = ref<any>(null)

const filters = ref({
  fromDate: '2026-07-02',
  fromTime: '00:00:00',
  toDate: '2026-07-02',
  toTime: '15:09:57'
})

// ===== FLOATING ACTION MENU STATE =====
const selectedRowId = ref<number | null>(null)
const menuPosition = ref({ top: 0, left: 0 })
const showFloatingMenu = ref(false)

// Action handlers
const menuActions = [
  { id: 'print-invoice', label: 'In hóa đơn tài chính', icon: '📄', color: '#333', bgHover: '#F5F5F5' },
  { id: 'reprint', label: 'In lại phiếu', icon: '🔄', color: '#333', bgHover: '#F5F5F5' },
  { id: 'edit-info', label: 'Đổi thông tin phiếu', icon: '📝', color: '#333', bgHover: '#F5F5F5' },
  { id: 'edit-payment', label: 'Đổi thông tin thanh toán', icon: '💳', color: '#333', bgHover: '#F5F5F5' },
  { id: 'recall', label: 'Gọi lại phiếu', icon: '📞', color: '#333', bgHover: '#F5F5F5' },
  { id: 'cancel', label: 'Hủy phiếu', icon: '❌', color: '#fff', bgHover: '#E53935', isDanger: true },
]

// Tabs
const tabs = [
  { id: 'restaurant', label: 'Restaurant' },
  { id: 'retail', label: 'Retail' },
  { id: 'distribution', label: 'Distribution' },
  { id: 'order_online', label: 'Order Online' }
]

const subTabs = [
  { id: 'items', label: 'Chi tiết hàng hóa' },
  { id: 'payment', label: 'Chi tiết thanh toán' },
  { id: 'operations', label: 'Thao tác phiếu' },
  { id: 'delivery', label: 'Giao hàng' },
  { id: 'history', label: 'Lịch sử thao tác hóa đơn' }
]

// Status Filters
// Status Filters
const statusFilters = ref([
  { value: 'all', label: 'Tất cả', color: '#1a5276', textColor: 'white' },
  { value: 'paid', label: 'Đã thanh toán', color: '#5D3A7A', textColor: 'white' },
  { value: 'recall', label: 'Gọi lại', color: '#FF9800', textColor: 'white' },
  { value: 'cancelled', label: 'Đã hủy', color: '#E57373', textColor: 'white' },
  { value: 'gift', label: 'Phiếu tặng', color: '#4DB6AC', textColor: 'white' },
  { value: 'shortage', label: 'Thiếu tiền', color: '#BA68C8', textColor: 'white' },
  { value: 'ordering', label: 'Đang order', color: '#4CAF50', textColor: 'white' },
  { value: 'hold', label: 'Phiếu giữ', color: '#FFB74D', textColor: 'white' },
  { value: 'no_invoice', label: 'Chưa xuất HĐ', color: '#78909C', textColor: 'white' }
])

const currentFilter = computed(() => 
  statusFilters.value.find(f => f.value === selectedFilter.value) || statusFilters.value[0]
)

const toggleFilterDropdown = () => {
  showFilterDropdown.value = !showFilterDropdown.value
}

const applyFilter = (filter: any) => {
  selectedFilter.value = filter.value
  showFilterDropdown.value = false
  currentPage.value = 1
}

// Mock data
const invoicesData = ref([
  {
    id: 1,
    type: 'restaurant',
    date: '2026-07-02',
    soPhieu: 'CN3126070200001',
    soHoaDon: 'C26MQV',
    dayHD: 'A',
    mstKhachHang: '0102030405',
    trangThai: 'Đã xuất đơn điện tử có MCQT thà...',
    khu: 'Khu A',
    ban: 'A03',
    tongTien: 687360,
    daTra: 1000000,
    conLai: 0,
    tienHang: 863000,
    giam: 228000,
    status: 'paid',
    selected: false
  },
  {
    id: 2,
    type: 'restaurant',
    date: '2026-07-02',
    soPhieu: 'CN3126070200002',
    soHoaDon: 'C26MQW',
    dayHD: 'B',
    mstKhachHang: '',
    trangThai: 'Chưa xuất HĐDT',
    khu: 'Khu B',
    ban: 'B02',
    tongTien: 1250000,
    daTra: 1250000,
    conLai: 0,
    tienHang: 1250000,
    giam: 0,
    status: 'unpaid',
    selected: false
  },
  {
    id: 3,
    type: 'restaurant',
    date: '2026-07-02',
    soPhieu: 'CN3126070200003',
    soHoaDon: 'C26MQX',
    dayHD: '',
    mstKhachHang: '',
    trangThai: 'Khách nợ',
    khu: 'Khu A',
    ban: 'A05',
    tongTien: 450000,
    daTra: 0,
    conLai: 450000,
    tienHang: 450000,
    giam: 0,
    status: 'debt',
    selected: false
  },
  {
    id: 4,
    type: 'retail',
    date: '2026-07-02',
    soPhieu: 'BL3126070200001',
    soHoaDon: 'R26MQY',
    dayHD: '',
    mstKhachHang: '',
    trangThai: 'Đã thanh toán',
    khu: 'Quầy Bán Lẻ',
    ban: 'Quầy 1',
    tongTien: 150000,
    daTra: 150000,
    conLai: 0,
    tienHang: 150000,
    giam: 0,
    status: 'paid',
    selected: false
  },
  {
    id: 5,
    type: 'distribution',
    date: '2026-07-02',
    soPhieu: 'PP3126070200001',
    soHoaDon: 'D26MQZ',
    dayHD: '',
    mstKhachHang: '0987654321',
    trangThai: 'Đã thanh toán',
    khu: 'Khu Giao Nhận',
    ban: 'Đại lý A',
    tongTien: 15000000,
    daTra: 10000000,
    conLai: 5000000,
    tienHang: 15000000,
    giam: 0,
    status: 'debt',
    selected: false
  },
  {
    id: 6,
    type: 'order_online',
    date: '2026-07-02',
    soPhieu: 'OL3126070200001',
    soHoaDon: 'O26MQA',
    dayHD: '',
    mstKhachHang: '',
    trangThai: 'Chưa xuất HĐDT',
    khu: 'Giao hàng nhanh',
    ban: 'GrabFood',
    tongTien: 320000,
    daTra: 320000,
    conLai: 0,
    tienHang: 350000,
    giam: 30000,
    status: 'unpaid',
    selected: false
  }
])

const sampleItems = ref<any[]>([])

const selectAll = computed({
  get() {
    return filteredData.value.length > 0 && filteredData.value.every(row => row.selected);
  },
  set(val) {
    filteredData.value.forEach(row => row.selected = val);
  }
});

const filteredData = computed(() => {
  let data = invoicesData.value.filter(row => row.type === activeTab.value)
  if (selectedFilter.value !== 'all') {
    data = data.filter(row => row.status === selectedFilter.value)
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase()
    data = data.filter(row => 
      row.soPhieu.toLowerCase().includes(q) ||
      row.ban.toLowerCase().includes(q) ||
      (row.khu && row.khu.toLowerCase().includes(q)) ||
      (row.soHoaDon && row.soHoaDon.toLowerCase().includes(q))
    )
  }
  // Date filtering
  if (filters.value.fromDate) {
    data = data.filter(row => row.date >= filters.value.fromDate);
  }
  if (filters.value.toDate) {
    data = data.filter(row => row.date <= filters.value.toDate);
  }
  return data
})

const totalPages = computed(() => Math.ceil(filteredData.value.length / itemsPerPage.value))

const summary = computed(() => {
  return filteredData.value.reduce((acc, row) => ({
    tongTien: acc.tongTien + row.tongTien,
    daTra: acc.daTra + row.daTra,
    conLai: acc.conLai + row.conLai,
    tienHang: acc.tienHang + row.tienHang
  }), { tongTien: 0, daTra: 0, conLai: 0, tienHang: 0 })
})

const totalSL = computed(() => sampleItems.value.reduce((sum, item) => sum + item.sl, 0))
const totalVAT = computed(() => 16)
const totalThue = computed(() => sampleItems.value.reduce((sum, item) => sum + item.thue, 0))
const totalTong = computed(() => sampleItems.value.reduce((sum, item) => sum + item.tong, 0))

// Methods
function formatVND(amount: number): string {
  return amount.toLocaleString('vi-VN') + 'đ'
}

function getRowClass(row: any): string {
  if (row.status === 'debt') return 'row-danger'
  if (row.status === 'paid') return 'row-paid'
  return ''
}

function getStatusBadgeClass(row: any): string {
  if (row.trangThai.includes('Đã xuất') || row.trangThai.includes('Đã thanh toán')) return 'badge-success'
  if (row.trangThai.includes('Chưa xuất')) return 'badge-warning'
  if (row.trangThai.includes('Khách nợ')) return 'badge-danger'
  return 'badge-default'
}


function changeTab(tabId: string) {
  activeTab.value = tabId;
  currentPage.value = 1;
  closeFloatingMenu()
  setTimeout(() => {
    if (filteredData.value.length > 0) {
      selectRow(filteredData.value[0]);
    } else {
      selectedRow.value = null;
      sampleItems.value = [];
    }
  }, 50);
}

function selectRow(row: any) {
  selectedRow.value = row
  if (row.id === 1) {
    sampleItems.value = [
      {
        id: 1,
        soOrder: 'ORD-001',
        maHang: 'BUFFET_399',
        tenHang: 'Buffet Lẩu 399k',
        tenKhac: 'Buffet Hotpot 399k',
        sl: 2,
        dvt: 'Suất',
        donGia: 399000,
        giamCT: 100000,
        giamPhieu: 28000,
        giam: 128000,
        vat: 8,
        thue: 53600,
        tong: 687360
      },
      {
        id: 2,
        soOrder: 'ORD-001',
        maHang: 'COCA',
        tenHang: 'Coca Cola',
        tenKhac: 'Coke',
        sl: 3,
        dvt: 'Lon',
        donGia: 20000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 4800,
        tong: 64800
      }
    ];
  } else if (row.id === 2) {
    sampleItems.value = [
      {
        id: 3,
        soOrder: 'ORD-002',
        maHang: 'SET_PARTY',
        tenHang: 'Set Menu Party A',
        tenKhac: 'Party Set A',
        sl: 1,
        dvt: 'Set',
        donGia: 1250000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 100000,
        tong: 1350000
      }
    ];
  } else if (row.id === 3) {
    sampleItems.value = [
      {
        id: 4,
        soOrder: 'ORD-003',
        maHang: 'LAU_THAI',
        tenHang: 'Lẩu Thái hải sản',
        tenKhac: 'Thai Seafood Hotpot',
        sl: 1,
        dvt: 'Nồi',
        donGia: 400000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 32000,
        tong: 432000
      },
      {
        id: 5,
        soOrder: 'ORD-003',
        maHang: 'KEN',
        tenHang: 'Bia Heineken',
        tenKhac: 'Heineken Beer',
        sl: 2,
        dvt: 'Chai',
        donGia: 25000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 4000,
        tong: 54000
      }
    ];
  } else if (row.id === 4) {
    sampleItems.value = [
      {
        id: 6,
        soOrder: 'RET-001',
        maHang: 'WAGYU_BOX',
        tenHang: 'Hộp thịt bò wagyu mang về',
        tenKhac: 'Wagyu Beef Box',
        sl: 1,
        dvt: 'Hộp',
        donGia: 150000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 12000,
        tong: 162000
      }
    ];
  } else if (row.id === 5) {
    sampleItems.value = [
      {
        id: 7,
        soOrder: 'DIST-001',
        maHang: 'BULK_WAGYU',
        tenHang: 'Sỉ thịt bò Ngưu Cát cắt lát (Thùng 20kg)',
        tenKhac: 'Sliced Wagyu Bulk 20kg',
        sl: 2,
        dvt: 'Thùng',
        donGia: 7500000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 1200000,
        tong: 16200000
      }
    ];
  } else if (row.id === 6) {
    sampleItems.value = [
      {
        id: 8,
        soOrder: 'ONL-001',
        maHang: 'RICE_WAGYU',
        tenHang: 'Set cơm bò xào wagyu',
        tenKhac: 'Wagyu Rice Set',
        sl: 2,
        dvt: 'Hộp',
        donGia: 160000,
        giamCT: 20000,
        giamPhieu: 10000,
        giam: 30000,
        vat: 8,
        thue: 25600,
        tong: 345600
      },
      {
        id: 9,
        soOrder: 'ONL-001',
        maHang: 'PEACH_TEA',
        tenHang: 'Trà đào',
        tenKhac: 'Peach Tea',
        sl: 2,
        dvt: 'Ly',
        donGia: 15000,
        giamCT: 0,
        giamPhieu: 0,
        giam: 0,
        vat: 8,
        thue: 2400,
        tong: 32400
      }
    ];
  } else {
    sampleItems.value = [];
  }
}

// Helper: Tính vị trí menu thông minh với smart placement
function calculateMenuPosition(rowRect: DOMRect): { top: number; left: number } {
  const menuWidth = 320
  const menuHeight = 350
  const viewportPadding = 16
  
  const viewportWidth = window.innerWidth
  const viewportHeight = window.innerHeight
  
  // Tính toán 4 hướng ưu tiên
  const spaceRight = viewportWidth - rowRect.right - viewportPadding
  const spaceLeft = rowRect.left - viewportPadding
  const spaceBelow = viewportHeight - rowRect.bottom - viewportPadding
  const spaceAbove = rowRect.top - viewportPadding
  
  let left: number
  let top: number
  
  // Ưu tiên: Phải -> Trái -> Trên -> Dưới
  if (spaceRight >= menuWidth) {
    // Đủ chỗ bên phải
    left = rowRect.right + viewportPadding
    top = rowRect.top
  } else if (spaceLeft >= menuWidth) {
    // Đủ chỗ bên trái
    left = rowRect.left - menuWidth - viewportPadding
    top = rowRect.top
  } else {
    // Không đủ chỗ ngang -> đặt sát trái
    left = viewportPadding
    top = rowRect.top
  }
  
  // Check vertical overflow
  if (top + menuHeight > viewportHeight - viewportPadding) {
    if (spaceAbove >= menuHeight) {
      top = rowRect.top - menuHeight - viewportPadding
    } else {
      top = viewportHeight - menuHeight - viewportPadding
    }
  }
  
  // Final clamp
  return {
    left: Math.max(viewportPadding, Math.min(left, viewportWidth - menuWidth - viewportPadding)),
    top: Math.max(viewportPadding, Math.min(top, viewportHeight - menuHeight - viewportPadding))
  }
}

// Row click handler for floating actions
function handleRowClick(row: any, event: MouseEvent) {
  const target = event.currentTarget as HTMLElement
  
  // Select row and load details below
  selectRow(row)
  
  // If clicking same row, toggle close menu
  if (selectedRowId.value === row.id && showFloatingMenu.value) {
    closeFloatingMenu()
    return
  }
  
  selectedRowId.value = row.id
  
  const rect = target.getBoundingClientRect()
  const position = calculateMenuPosition(rect)
  
  menuPosition.value = position
  showFloatingMenu.value = true
}

function closeFloatingMenu() {
  selectedRowId.value = null
  showFloatingMenu.value = false
}

function triggerToast(icon: 'success' | 'info' | 'error' | 'warning', title: string) {
  const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 2000,
    timerProgressBar: true,
    didOpen: (toast) => {
      toast.addEventListener('mouseenter', Swal.stopTimer)
      toast.addEventListener('mouseleave', Swal.resumeTimer)
    }
  })
  Toast.fire({
    icon: icon,
    title: title
  })
}

function handleMenuAction(actionId: string) {
  const row = invoicesData.value.find(r => r.id === selectedRowId.value)
  
  // Add haptic feedback simulation
  if (navigator.vibrate) {
    navigator.vibrate(50)
  }
  
  closeFloatingMenu()
  
  if (!row) return
  
  switch (actionId) {
    case 'print-invoice':
      triggerToast('success', `Đang in hóa đơn tài chính cho phiếu ${row.soPhieu}...`)
      break
    case 'reprint':
      triggerToast('info', `In lại phiếu ${row.soPhieu}`)
      break
    case 'edit-info':
      Swal.fire({
        title: 'Đổi thông tin phiếu',
        text: `Thay đổi thông tin cho phiếu ${row.soPhieu}`,
        input: 'text',
        inputValue: row.mstKhachHang,
        inputPlaceholder: 'Nhập MST mới...',
        showCancelButton: true,
        confirmButtonText: 'Lưu',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#1a5276'
      }).then((result) => {
        if (result.isConfirmed) {
          row.mstKhachHang = result.value;
          triggerToast('success', 'Đã đổi mã số thuế thành công!');
        }
      });
      break
    case 'edit-payment':
      triggerToast('info', `Mở chỉnh sửa thanh toán cho phiếu ${row.soPhieu}`)
      break
    case 'recall':
      Swal.fire({
        title: 'Gọi lại phiếu',
        text: `Bạn có muốn gọi lại phiếu ${row.soPhieu} để điều chỉnh?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Đồng ý',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#1a5276'
      }).then((result) => {
        if (result.isConfirmed) {
          row.status = 'recall';
          row.trangThai = 'Đang gọi lại';
          triggerToast('success', 'Phiếu đã chuyển sang trạng thái Gọi lại.');
        }
      });
      break
    case 'cancel':
      Swal.fire({
        title: 'Xác nhận hủy phiếu?',
        text: `Hủy hoàn toàn phiếu ${row.soPhieu}?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Hủy phiếu',
        cancelButtonText: 'Bỏ qua',
        confirmButtonColor: '#d33'
      }).then((result) => {
        if (result.isConfirmed) {
          row.status = 'cancelled'
          row.trangThai = 'Đã hủy'
          row.tongTien = 0
          row.daTra = 0
          row.conLai = 0
          triggerToast('success', `Đã hủy phiếu ${row.soPhieu}`)
        }
      })
      break
  }
}

function refreshData() {
  triggerToast('success', 'Đã cập nhật dữ liệu báo cáo mới nhất!')
}

function viewBillList() {
  Swal.fire({
    title: 'Danh sách hóa đơn',
    text: 'Tính năng danh sách hóa đơn đang được phát triển.',
    icon: 'info',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#1a5276'
  })
}

function tempExit() {
  Swal.fire({
    title: 'Khóa màn hình',
    text: 'Màn hình đã tạm khóa để bảo mật.',
    icon: 'warning',
    confirmButtonText: 'Mở khóa',
    confirmButtonColor: '#f59e0b'
  });
}

function goBack() { router.push('/reception/dashboard') }

function printReport() {
  window.print()
}

function exportData() {
  let csvContent = "data:text/csv;charset=utf-8,";
  csvContent += "So phieu,So hoa don,Day HD,MST,Trang thai,Khu,Ban,Tong tien,Da tra,Con lai\n";
  
  filteredData.value.forEach(row => {
    csvContent += `${row.soPhieu},${row.soHoaDon || ''},${row.dayHD || ''},${row.mstKhachHang || ''},${row.trangThai},${row.khu},${row.ban},${row.tongTien},${row.daTra},${row.conLai}\n`;
  });
  
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `Bao_cao_${activeTab.value}_${filters.value.fromDate}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  
  triggerToast('success', 'Đã xuất file báo cáo CSV thành công!')
}

// Click away dropdown listener
const filterDropdownRef = ref<HTMLElement | null>(null)
const handleOutsideClick = (e: MouseEvent) => {
  if (filterDropdownRef.value && !filterDropdownRef.value.contains(e.target as Node)) {
    showFilterDropdown.value = false
  }
  const target = e.target as HTMLElement
  if (
    showFloatingMenu.value &&
    !target.closest('.floating-action-menu') &&
    !target.closest('.data-table tbody tr')
  ) {
    closeFloatingMenu()
  }
}

onMounted(() => {
  document.addEventListener('click', handleOutsideClick)
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeFloatingMenu()
  })
  
  // Pre-select first item
  if (filteredData.value.length > 0) {
    selectRow(filteredData.value[0])
  }
})

onUnmounted(() => {
  document.removeEventListener('click', handleOutsideClick)
})
</script>

<style scoped>
/* KEY FIX: Toàn bộ trang KHÔNG scroll */
.reports-page {
  height: 100vh;
  width: 100vw;
  overflow: hidden; /* QUAN TRỌNG: Không scroll toàn trang */
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* 1. HEADER - Cố định */
.reports-header {
  background: white;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e0e0e0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-icon {
  font-size: 32px;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.page-title {
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0;
}

.page-subtitle {
  font-size: 12px;
  color: #666;
  margin: 4px 0 0 0;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 10px 16px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}

.btn-refresh { background: #10b981; color: white; }
.btn-bill-list { background: #8b5cf6; color: white; }
.btn-lock { background: #f59e0b; color: white; }
.btn-back { background: #ef4444; color: white; }
.btn-export { background: #10b981; color: white; }
.btn-print { background: #3b82f6; color: white; }

/* 2. FILTERS - Cố định */
.filters-section {
  background: white;
  padding: 16px 24px;
  border-bottom: 1px solid #e0e0e0;
}

.filter-row {
  display: flex;
  gap: 20px;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.search-group {
  flex: 1;
}

.filter-label {
  font-size: 11px;
  font-weight: 700;
  color: #666;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.search-input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 13px;
  outline: none;
}

.search-input:focus {
  border-color: #10b981;
}

.datetime-row {
  display: flex;
  gap: 8px;
}

.date-input, .time-input {
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 13px;
  outline: none;
}

.time-input {
  width: 120px;
}

/* 3. MAIN CONTENT - Chiếm phần còn lại, KHÔNG scroll */
.main-content {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  overflow: hidden; /* Không scroll ở đây */
  display: flex;
  flex-direction: column;
}

/* 3.1 TABS - Cố định */
.tabs-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 2px solid #e0e0e0;
  background: #fafafa;
}

.tabs-left {
  display: flex;
  gap: 4px;
}

.tab-btn {
  padding: 10px 20px;
  background: transparent;
  border: none;
  font-weight: 600;
  font-size: 13px;
  color: #666;
  cursor: pointer;
  border-radius: 8px;
}

.tab-btn.active {
  background: #10b981;
  color: white;
}

.tabs-right {
  display: flex;
  gap: 12px;
  align-items: center;
}

/* ===== FILTER DROPDOWN ===== */
.filter-dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.filter-dropdown-btn {
  padding: 10px 16px;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 160px;
  justify-content: space-between;
  transition: all 0.2s;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  color: white;
}

.filter-dropdown-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.filter-label {
  flex: 1;
  text-align: left;
}

.filter-dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 8px;
  background: white;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
  z-index: 100;
  min-width: 180px;
  border: 1px solid #e0e0e0;
}

.filter-dropdown-item {
  width: 100%;
  padding: 12px 16px;
  border: none;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.filter-dropdown-item:last-child {
  border-bottom: none;
}

.filter-dropdown-item:hover {
  opacity: 0.85;
  transform: translateX(4px);
}

.filter-dropdown-item.active {
  outline: 2px solid #E8772E;
  outline-offset: -2px;
  font-weight: 800;
}

/* 3.2 DATA TABLE - CHỈ PHẦN NÀY SCROLL DỌC */
.table-wrapper {
  flex: 1;
  overflow-y: auto; /* CHỈ SCROLL DỌC Ở ĐÂY */
  overflow-x: auto;
}

/* Custom scrollbar cho table */
.table-wrapper::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.table-wrapper::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.table-wrapper::-webkit-scrollbar-thumb {
  background: #10b981;
  border-radius: 4px;
}

.table-wrapper::-webkit-scrollbar-thumb:hover {
  background: #059669;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.data-table th {
  background: #10b981;
  color: white;
  padding: 12px 10px;
  text-align: left;
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  position: sticky;
  top: 0;
  z-index: 10;
  border-right: 1px solid rgba(255,255,255,0.2);
}

.data-table td {
  padding: 10px;
  border-bottom: 1px solid #eee;
  border-right: 1px solid #f0f0f0;
}

.data-table tbody tr {
  cursor: pointer;
  transition: all 0.15s;
}

.data-table tbody tr:hover {
  background: #E3F2FD !important;
}

.row-paid {
  background: #f3e8ff !important;
}

.row-danger {
  background: #fee2e2 !important;
}

.font-bold { font-weight: 700; }
.text-red { color: #ef4444; }
.text-green { color: #10b981; }
.text-right { text-align: right; }
.text-center { text-align: center; }

.badge-success {
  background: #d1fae5;
  color: #065f46;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.badge-warning {
  background: #fef3c7;
  color: #92400e;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.badge-danger {
  background: #fee2e2;
  color: #991b1b;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.badge-default {
  background: #f3f4f6;
  color: #374151;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.col-checkbox { width: 40px; text-align: center; }
.col-stt { width: 50px; }
.col-so-phieu { width: 160px; }
.col-so-hd { width: 100px; }
.col-day-hd { width: 70px; }
.col-mst { width: 120px; }
.col-trang-thai { width: 220px; }
.col-khu { width: 80px; }
.col-ban { width: 70px; }
.col-tong-tien { width: 110px; text-align: right; }
.col-da-tra { width: 110px; text-align: right; }
.col-con-lai { width: 110px; text-align: right; }
.col-tien-hang { width: 110px; text-align: right; }
.col-giam { width: 90px; text-align: right; }

/* 3.3 PAGINATION - Cố định */
.pagination-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background: #fafafa;
  border-top: 1px solid #e0e0e0;
  font-size: 13px;
}

.record-count {
  font-weight: 600;
  color: #333;
}

.pagination-info {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #666;
}

.page-btn {
  padding: 4px 10px;
  border: 1px solid #ddd;
  background: white;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
}

.page-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-current {
  background: #3b82f6;
  color: white;
  padding: 4px 10px;
  border-radius: 4px;
  font-weight: 600;
}

/* 3.4 SUMMARY FOOTER - Cố định */
.summary-footer {
  display: flex;
  justify-content: flex-end;
  gap: 32px;
  padding: 16px 20px;
  background: #1e293b;
  color: white;
}

.summary-item {
  display: flex;
  gap: 8px;
  align-items: center;
}

.summary-item .label {
  font-weight: 600;
  color: #94a3b8;
}

.summary-item .value {
  font-weight: 700;
  font-size: 14px;
}

/* 3.5 SUB TABS - Cố định */
.sub-tabs-section {
  border-top: 2px solid #1e3a5f;
}

.sub-tabs-header {
  display: flex;
  background: #1e3a5f;
}

.sub-tab-btn {
  padding: 12px 20px;
  background: transparent;
  border: none;
  color: #94a3b8;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  border-right: 1px solid rgba(255,255,255,0.1);
  transition: all 0.2s;
}

.sub-tab-btn:hover {
  background: rgba(255,255,255,0.1);
}

.sub-tab-btn.active {
  background: #3b82f6;
  color: white;
}

.sub-tab-content {
  background: white;
  max-height: 250px; /* Giới hạn chiều cao */
  overflow-y: auto; /* Scroll riêng nếu cần */
}

.items-table-wrapper {
  overflow-x: auto;
}

.items-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.items-table th {
  background: #1e3a5f;
  color: white;
  padding: 10px 12px;
  text-align: left;
  font-weight: 600;
  font-size: 11px;
  position: sticky;
  top: 0;
  border-right: 1px solid rgba(255,255,255,0.1);
}

.items-table th:last-child {
  border-right: none;
}

.items-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #eee;
  border-right: 1px solid #f0f0f0;
}

.items-table td:last-child {
  border-right: none;
}

.items-table tfoot .totals-row {
  background: #f8fafc;
  border-top: 2px solid #1e3a5f;
}

.items-table tfoot td {
  padding: 12px;
  font-weight: 700;
}

/* ===== ROW SELECTED STATE ===== */
.row-selected {
  background: #E3F2FD !important;
  outline: 2px solid #1976D2;
  outline-offset: -2px;
  position: relative;
}

.row-selected td {
  color: #0D47A1 !important;
  font-weight: 600;
}

.row-selected .badge-success,
.row-selected .badge-warning,
.row-selected .badge-danger,
.row-selected .badge-default {
  opacity: 0.8;
}

/* ===== FLOATING ACTION MENU ===== */
.floating-action-menu {
  position: fixed;
  z-index: 9999;
  width: 320px;
  background: white;
  border-radius: 14px;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 10px 40px rgba(0, 0, 0, 0.3),
    0 0 60px rgba(255, 255, 255, 0.05);
  overflow: hidden;
  max-height: calc(100vh - 20px);
  overflow-y: auto;
  transform-origin: top right;
  will-change: transform, opacity, filter;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.2) transparent;
}

.floating-action-menu:hover {
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.15),
    0 15px 50px rgba(0, 0, 0, 0.4),
    0 0 80px rgba(255, 255, 255, 0.08);
}

.floating-action-menu::-webkit-scrollbar {
  width: 4px;
}

.floating-action-menu::-webkit-scrollbar-track {
  background: transparent;
}

.floating-action-menu::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 4px;
  transition: background 0.2s;
}

.floating-action-menu::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.4);
}

/* Menu Header */
.menu-header {
  padding: 14px 18px 10px;
  border-bottom: 1px solid #f0f0f0;
  background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  opacity: 0;
  transform: translateY(-8px);
  animation: slideDownHeader 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) 0.1s forwards;
}

@keyframes slideDownHeader {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.menu-title {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.8px;
}

.menu-subtitle {
  display: block;
  font-size: 13px;
  font-weight: 700;
  color: #1a5276;
  margin-top: 2px;
  font-family: 'Courier New', monospace;
}

/* Menu Items */
.menu-items {
  padding: 6px 0;
}

.menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 18px;
  background: white;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
  text-align: left;
  position: relative;
  overflow: hidden;
}

.menu-item:hover {
  background: #F5F5F5;
}

.menu-item:active {
  transform: scale(0.98);
  background: #EEEEEE;
}

/* Ripple Effect for Click */
.menu-item::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.08);
  transform: translate(-50%, -50%);
  transition: width 0.6s, height 0.6s;
}

.menu-item:active::after {
  width: 200px;
  height: 200px;
  transition: width 0s, height 0s;
}

/* Danger Item Special Animation */
.menu-item.danger-item {
  background: #EF5350;
  margin: 4px 8px;
  border-radius: 8px;
  width: calc(100% - 16px);
  animation: dangerPulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.menu-item.danger-item:hover {
  background: #E53935;
}

.menu-item.danger-item:active {
  background: #D32F2F;
}

.menu-item.danger-item .menu-label {
  color: white;
}

.menu-item.danger-item .menu-icon {
  filter: brightness(10);
}

.menu-item.danger-item .menu-arrow {
  color: rgba(255, 255, 255, 0.6);
}

@keyframes dangerPulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(239, 83, 80, 0);
  }
  50% {
    box-shadow: 0 0 0 4px rgba(239, 83, 80, 0.15);
  }
}

/* Icon Animation */
.menu-icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
  flex-shrink: 0;
  line-height: 1;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  display: inline-block;
}

.menu-item:hover .menu-icon {
  transform: scale(1.15) rotate(5deg);
}

.menu-item:active .menu-icon {
  transform: scale(0.95);
}

/* Menu item parts */
.menu-label {
  flex: 1;
  font-size: 13px;
  font-weight: 600;
  color: #333;
}

/* Arrow Indicator Animation */
.menu-arrow {
  font-size: 16px;
  color: #ccc;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  display: inline-block;
}

.menu-arrow::after {
  content: '›';
}

.menu-item:hover .menu-arrow {
  transform: translateX(6px);
  opacity: 0.8;
  color: #999;
}

/* ===== BACKDROP BLUR ===== */
.floating-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9998;
  background: rgba(0, 0, 0, 0.05);
  backdrop-filter: blur(0px);
  transition: backdrop-filter 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.floating-backdrop.show {
  backdrop-filter: blur(4px);
}

/* ===== TRANSITIONS ===== */
.floating-menu-enter-active {
  transition: all 180ms cubic-bezier(0.34, 1.56, 0.64, 1);
}

.floating-menu-leave-active {
  transition: all 120ms ease-in;
}

.floating-menu-enter-from {
  opacity: 0;
  transform: scale(0.92) translateY(-8px);
}

.floating-menu-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(-4px);
}

@media print {
  .reports-header, .filters-section, .tabs-row, .pagination-footer, .btn, .floating-action-menu, .floating-menu-overlay {
    display: none !important;
  }
}
</style>
