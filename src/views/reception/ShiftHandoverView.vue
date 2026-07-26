<!-- File: src/views/reception/ShiftHandoverView.vue -->
<template>
  <div class="shift-handover-container">
    <!-- Hamburger Menu Button -->
    <HamburgerMenu 
      :is-active="showSidebar"
      @toggle="showSidebar = !showSidebar"
    />

    <!-- Sidebar Navigation -->
    <SidebarNavigation v-model="showSidebar" />

    <!-- Main Content -->
    <main class="main-content">
      <!-- Header -->
      <header class="page-header flex-shrink-0">
        <div class="header-left">
          <span class="logo-icon">📊</span>
          <h1 class="page-title">Giao ca | <span class="branch-name">NGƯU CÁT</span></h1>
        </div>
        <div class="header-actions">
          <button class="btn btn-refresh" @click="refreshData">
            <span>🔄</span> Làm mới
          </button>
          <button class="btn btn-back" @click="goBack">
            <span>⬅️</span> Quay về
          </button>
        </div>
      </header>

      <!-- Filters Section -->
      <div class="filters-section flex-shrink-0">
        <div class="filter-row">
          <div class="filter-group">
            <label class="filter-label">Loại hình kinh doanh</label>
            <select v-model="filters.businessType" class="filter-select">
              <option value="">Tất cả</option>
              <option value="restaurant">Nhà hàng</option>
              <option value="retail">Bán lẻ</option>
              <option value="distribution">Distribution</option>
              <option value="online">Order Online</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Ca</label>
            <select v-model="filters.shift" class="filter-select">
              <option value="">Tất cả</option>
              <option value="1">Ca 1</option>
              <option value="2">Ca 2</option>
              <option value="3">Ca 3</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Ngày</label>
            <input v-model="filters.date" type="date" class="filter-input" />
          </div>
        </div>

        <div class="filter-actions">
          <button class="btn btn-export" @click="exportData">
            <span>📥</span> Xuất dữ liệu
          </button>
        </div>
      </div>

      <!-- PDF Viewer Area -->
      <div class="pdf-viewer-container flex-1 flex flex-col min-height-0">
        <!-- PDF Toolbar -->
        <div class="pdf-toolbar flex-shrink-0">
          <button class="toolbar-btn" @click="prevPage" title="Trang trước">◀️</button>
          <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
          <button class="toolbar-btn" @click="nextPage" title="Trang sau">▶️</button>
          
          <div class="toolbar-divider"></div>
          
          <button class="toolbar-btn" @click="zoomOut" title="Thu nhỏ">➖</button>
          <span class="zoom-level">{{ zoomLevel }}%</span>
          <button class="toolbar-btn" @click="zoomIn" title="Phóng to">➕</button>
          
          <div class="toolbar-divider"></div>
          
          <button class="toolbar-btn" @click="rotateLeft" title="Xoay trái">🔄</button>
          <button class="toolbar-btn" @click="rotateRight" title="Xoay phải">🔃</button>
          
          <div class="toolbar-divider"></div>
          
          <button class="toolbar-btn" @click="downloadPDF" title="Tải xuống PDF">📥</button>
          <button class="toolbar-btn" @click="printPDF" title="In báo cáo">🖨️</button>
        </div>

        <!-- PDF Content Viewport -->
        <div class="pdf-content-viewport flex-1 overflow-y-auto">
          <div class="pdf-content" :style="{ transform: `scale(${zoomLevel / 100}) rotate(${rotation}deg)` }">
            <!-- PDF Report A4 Page -->
            <div class="report-page">
              <!-- Report Header -->
              <div class="report-header">
                <div class="company-logo">🍲</div>
                <div class="company-info">
                  <h2 class="company-name">NGƯU CÁT</h2>
                  <p class="company-address">120bis Nguyễn Đình Chiểu, Phường Tân Định, TP. Hồ Chí Minh</p>
                  <p class="company-phone">Tel: 098 967 2344</p>
                </div>
              </div>

              <!-- Report Title -->
              <div class="report-title-section">
                <h1 class="report-title">BÁO CÁO GIAO CA</h1>
                <div class="report-meta">
                  <p><strong>Tất cả các ca</strong> | {{ formatDateDMY(filters.date) }} 15:11:59</p>
                  <p><strong>Từ ngày:</strong> {{ formatDateDMY(filters.date) }}</p>
                  <p><strong>Đến ngày:</strong> {{ formatDateDMY(nextDay) }}</p>
                  <p><strong>Trung tâm:</strong> NGƯU CÁT</p>
                </div>
              </div>

              <!-- Financial Table -->
              <table class="financial-table">
                <thead>
                  <tr>
                    <th>Chi tiêu tài chính</th>
                    <th class="text-right">Số tiền</th>
                  </tr>
                </thead>
                <tbody>
                  <tr class="date-row">
                    <td colspan="2"><strong>Ngày {{ formatDateDMY(filters.date) }}</strong></td>
                  </tr>
                  <tr class="shift-row">
                    <td colspan="2"><strong>Ca {{ filters.shift || 'Tất cả' }}</strong></td>
                  </tr>
                  <tr class="section-header">
                    <td><strong>A.Doanh thu</strong></td>
                    <td class="amount text-right font-bold">{{ formatVND(reportData.revenue) }}</td>
                  </tr>
                  <tr>
                    <td>Doanh số bán hàng</td>
                    <td class="amount text-right">{{ formatVND(reportData.salesAmount) }}</td>
                  </tr>
                  <tr class="indent">
                    <td>-- KHÁC</td>
                    <td class="amount text-right">{{ formatVND(reportData.other) }}</td>
                  </tr>
                  <tr class="indent">
                    <td>-- THỨC ĂN</td>
                    <td class="amount text-right">{{ formatVND(reportData.food) }}</td>
                  </tr>
                  <tr class="indent">
                    <td>-- THUỐC LÁ</td>
                    <td class="amount text-right">{{ formatVND(reportData.tobacco) }}</td>
                  </tr>
                  <tr>
                    <td>Chiết khấu món ăn</td>
                    <td class="amount text-right">{{ formatVND(reportData.foodDiscount) }}</td>
                  </tr>
                  <tr>
                    <td>Chiết khấu tổng bill</td>
                    <td class="amount text-right">{{ formatVND(reportData.billDiscount) }}</td>
                  </tr>
                  <tr>
                    <td>Thuế TTĐB</td>
                    <td class="amount text-right">{{ formatVND(reportData.specialTax) }}</td>
                  </tr>
                  <tr>
                    <td>Thuế GTGT</td>
                    <td class="amount text-right">{{ formatVND(reportData.vat) }}</td>
                  </tr>
                  <tr class="section-header">
                    <td><strong>B.Thanh toán</strong></td>
                    <td class="amount text-right font-bold">{{ formatVND(reportData.payment) }}</td>
                  </tr>
                  <tr>
                    <td>Tiền mặt:VND</td>
                    <td class="amount text-right">{{ formatVND(reportData.cashVND) }}</td>
                  </tr>
                  <tr>
                    <td>Thẻ:Banking</td>
                    <td class="amount text-right">{{ formatVND(reportData.cardBanking) }}</td>
                  </tr>
                  <tr>
                    <td>Thẻ:CaThe</td>
                    <td class="amount text-right">{{ formatVND(reportData.cardCaThe) }}</td>
                  </tr>
                  <tr>
                    <td>Trả cọc</td>
                    <td class="amount text-right">{{ formatVND(reportData.depositReturn) }}</td>
                  </tr>
                </tbody>
              </table>

              <!-- Footer -->
              <div class="report-footer">
                <div class="qr-code">🔳</div>
                <div class="footer-info">
                  <p><strong>CÔNG TY CỔ PHẦN QUT VIỆT NAM</strong></p>
                  <p>117003005375-NGƯU CÁT</p>
                  <p class="note">Xin quý khách lưu ý: Hóa đơn GTGT chỉ xuất tại thời điểm thanh toán!</p>
                  <p class="note">VAT invoices available at time of payment.</p>
                  <p class="thanks">Cảm ơn và hẹn gặp lại!</p>
                  <p class="thanks">Thank you and see you again</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import HamburgerMenu from '@/components/reception/HamburgerMenu.vue'
import SidebarNavigation from '@/components/reception/SidebarNavigation.vue'

const router = useRouter()

// State
const showSidebar = ref(false)
const filters = ref({
  businessType: '',
  shift: '',
  date: '2026-07-02'
})

const currentPage = ref(1)
const totalPages = ref(1)
const zoomLevel = ref(90)
const rotation = ref(0)

// Mock report data
const reportData = ref({
  revenue: 11613900,
  salesAmount: 13462000,
  other: 11200000,
  food: 1222000,
  tobacco: 1040000,
  foodDiscount: 2724500,
  billDiscount: 0,
  specialTax: 0,
  vat: 876400,
  payment: 11613900,
  cashVND: 3294420,
  cardBanking: 5085760,
  cardCaThe: 3233720,
  depositReturn: 0
})

// Computed
const nextDay = computed(() => {
  if (!filters.value.date) return ''
  const date = new Date(filters.value.date)
  date.setDate(date.getDate() + 1)
  return date.toISOString().split('T')[0]
})

// Methods
function formatVND(value: number): string {
  return value.toLocaleString('vi-VN')
}

function formatDateDMY(dateStr: string): string {
  if (!dateStr) return ''
  const parts = dateStr.split('-')
  if (parts.length !== 3) return dateStr
  return `${parts[2]}/${parts[1]}/${parts[0]}`
}

function refreshData() {
  console.log('Refreshing data...')
}

function goBack() {
  router.push('/reception/dashboard')
}

function exportData() {
  console.log('Exporting data...')
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--
}

function nextPage() {
  if (currentPage.value < totalPages.value) currentPage.value++
}

function zoomIn() {
  zoomLevel.value = Math.min(200, zoomLevel.value + 10)
}

function zoomOut() {
  zoomLevel.value = Math.max(50, zoomLevel.value - 10)
}

function rotateLeft() {
  rotation.value = (rotation.value - 90) % 360
}

function rotateRight() {
  rotation.value = (rotation.value + 90) % 360
}

function downloadPDF() {
  console.log('Download PDF')
}

function printPDF() {
  window.print()
}
</script>

<style scoped>
.shift-handover-container {
  height: 100vh;
  width: 100vw;
  overflow: hidden;
  display: flex;
  background: #f5f5f5;
  position: relative;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* Main Content */
.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

/* Header */
.page-header {
  background: white;
  padding: 12px 20px 12px 76px; /* Added left padding to prevent overlapping hamburger */
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e0e0e0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-icon {
  font-size: 24px;
}

.page-title {
  font-size: 18px;
  font-weight: 700;
  color: #333;
  margin: 0;
}

.branch-name {
  color: #E8772E;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 8px 14px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}

.btn-refresh { background: #10b981; color: white; }
.btn-back { background: #ef4444; color: white; }
.btn-export { background: #f59e0b; color: white; }

/* Filters */
.filters-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding: 10px 20px;
  background: white;
  border-bottom: 1px solid #e0e0e0;
  gap: 20px;
}

.filter-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  flex: 1;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-label {
  font-size: 10px;
  font-weight: 700;
  color: #666;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.filter-select,
.filter-input {
  padding: 6px 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 12px;
  background: white;
  outline: none;
}

.filter-select:focus,
.filter-input:focus {
  border-color: #E8772E;
}

.filter-actions {
  display: flex;
}

/* PDF Viewer */
.pdf-viewer-container {
  background: #2d2d2d;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Important for flex scroll */
}

.pdf-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #1a1a1a;
  border-bottom: 1px solid #333;
}

.toolbar-btn {
  width: 32px;
  height: 32px;
  background: #3a3a3a;
  border: none;
  border-radius: 6px;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  transition: background 0.2s;
}

.toolbar-btn:hover {
  background: #4a4a4a;
}

.toolbar-divider {
  width: 1px;
  height: 20px;
  background: #444;
  margin: 0 4px;
}

.page-info,
.zoom-level {
  color: white;
  font-size: 12px;
  font-weight: 600;
  padding: 0 4px;
}

.pdf-content-viewport {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  justify-content: center;
}

.pdf-content {
  transform-origin: top center;
  transition: transform 0.2s;
  height: fit-content;
}

/* Report Page */
.report-page {
  width: 210mm;
  min-height: 297mm;
  background: white;
  padding: 20mm;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  box-sizing: border-box;
}

.report-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #333;
}

.company-logo {
  font-size: 40px;
}

.company-info {
  flex: 1;
}

.company-name {
  font-size: 20px;
  font-weight: 800;
  margin: 0 0 4px 0;
  color: #333;
}

.company-address,
.company-phone {
  font-size: 11px;
  color: #666;
  margin: 2px 0;
}

.report-title-section {
  text-align: center;
  margin-bottom: 24px;
}

.report-title {
  font-size: 24px;
  font-weight: 800;
  color: #333;
  margin: 0 0 12px 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.report-meta {
  font-size: 12px;
  color: #666;
  line-height: 1.6;
}

.report-meta p {
  margin: 4px 0;
}

/* Financial Table */
.financial-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 24px;
  font-size: 12px;
}

.financial-table th {
  background: #f5f5f5;
  padding: 10px 12px;
  text-align: left;
  font-weight: 700;
  border: 1px solid #ddd;
  text-transform: uppercase;
}

.financial-table td {
  padding: 8px 12px;
  border-bottom: 1px dotted #ccc;
  color: #333;
}

.financial-table .amount {
  text-align: right;
  font-family: 'Courier New', monospace;
  font-weight: 700;
}

.date-row,
.shift-row {
  background: #f9f9f9;
}

.section-header {
  background: #f0f0f0;
  font-weight: 700;
}

.indent td:first-child {
  padding-left: 24px;
}

/* Footer */
.report-footer {
  display: flex;
  align-items: center;
  gap: 24px;
  margin-top: 40px;
  padding-top: 20px;
  border-top: 2px solid #333;
}

.qr-code {
  font-size: 48px;
}

.footer-info {
  flex: 1;
  font-size: 11px;
  color: #666;
  text-align: center;
}

.footer-info p {
  margin: 2px 0;
}

.footer-info .note {
  font-style: italic;
  color: #999;
  font-size: 10px;
}

.footer-info .thanks {
  font-weight: 700;
  color: #333;
  margin-top: 8px;
}

/* Position for hamburger button */
.shift-handover-container .hamburger-btn {
  position: absolute;
  top: 12px;
  left: 20px;
  z-index: 997;
}

/* Responsive */
@media (max-width: 768px) {
  .filters-section {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  
  .filter-row {
    grid-template-columns: 1fr;
  }
  
  .filter-actions {
    justify-content: flex-end;
  }
}

/* Print Styles */
@media print {
  .hamburger-btn,
  .page-header,
  .filters-section,
  .pdf-toolbar {
    display: none !important;
  }

  .pdf-content-viewport {
    overflow: visible;
    padding: 0;
  }

  .pdf-content {
    transform: none !important;
  }

  .report-page {
    box-shadow: none;
    padding: 0;
    margin: 0;
    width: 100%;
    min-height: auto;
  }
}
</style>
