<!-- File: src/views/reception/RevenueOverviewView.vue -->
<template>
  <!--  CONTAINER CHÍNH: h-screen + overflow-hidden -->
  <div class="revenue-container">
    <!-- Hamburger Menu Button -->
    <HamburgerMenu
      :is-active="showSidebar"
      @toggle="showSidebar = !showSidebar"
    />

    <!-- Sidebar Navigation -->
    <SidebarNavigation v-model="showSidebar" />

    <!-- 1. HEADER: Compact -->
    <header class="revenue-header flex-shrink-0">
      <div class="header-left">
        <span class="logo-icon">📊</span>
        <h1 class="page-title">
          DT Tổng thể | <span class="branch-name">NGƯU CÁT</span>
        </h1>
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

    <!-- 2. FILTERS: 1 row duy nhất -->
    <div class="filters-section flex-shrink-0">
      <div class="filter-row">
        <div class="filter-group">
          <label class="filter-label">KHU</label>
          <select v-model="filters.area" class="filter-select">
            <option value="">Tất cả</option>
            <option v-for="area in areas" :key="area.value" :value="area.value">
              {{ area.label }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label class="filter-label">LOẠI HÌNH KINH DOANH</label>
          <select v-model="filters.businessType" class="filter-select">
            <option value="">Tất cả</option>
            <option value="restaurant">Nhà hàng</option>
            <option value="retail">Bán lẻ</option>
            <option value="distribution">Distribution</option>
            <option value="order_online">Order Online</option>
          </select>
        </div>
        <div class="filter-group">
          <label class="filter-label">CHỌN QUẦY</label>
          <div class="select-with-clear">
            <select v-model="filters.counter" class="filter-select">
              <option value="">Tất cả</option>
              <option
                v-for="counter in counters"
                :key="counter"
                :value="counter"
              >
                {{ counter }}
              </option>
            </select>
            <button
              v-if="filters.counter"
              @click="filters.counter = ''"
              class="clear-btn"
            >
              ❌
            </button>
          </div>
        </div>
        <div class="filter-group">
          <label class="filter-label">CA</label>
          <select v-model="filters.shift" class="filter-select">
            <option value="">Tất cả</option>
            <option value="1">Ca 1</option>
            <option value="2">Ca 2</option>
          </select>
        </div>
        <div class="filter-group">
          <label class="filter-label">TỪ NGÀY</label>
          <div class="datetime-group">
            <input
              v-model="filters.fromDate"
              type="date"
              class="filter-input date"
            />
            <input
              v-model="filters.fromTime"
              type="time"
              class="filter-input time"
            />
          </div>
        </div>
        <div class="filter-group">
          <label class="filter-label">ĐẾN NGÀY</label>
          <div class="datetime-group">
            <input
              v-model="filters.toDate"
              type="date"
              class="filter-input date"
            />
            <input
              v-model="filters.toTime"
              type="time"
              class="filter-input time"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- 3. TABS + ACTIONS -->
    <div class="tabs-section flex-shrink-0">
      <div class="tabs-left">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          :class="['tab-btn', { active: activeTab === tab.id }]"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>
      <div class="tabs-right">
        <button class="btn btn-export" @click="exportData">
          <span>📥</span> Xuất dữ liệu
        </button>
        <button class="btn btn-print" @click="printReport">
          <span>🖨️</span> In
        </button>
      </div>
    </div>

    <!-- 4. KPI CARDS: Thu gọn -->
    <div class="kpi-cards flex-shrink-0">
      <div class="kpi-card kpi-blue">
        <div class="kpi-label">TỔNG DOANH THU</div>
        <div class="kpi-value">{{ formatCurrency(kpiData.totalRevenue) }}</div>
      </div>
      <div class="kpi-card kpi-green">
        <div class="kpi-label">SỐ LƯỢNG PHIẾU ĐÃ THANH TOÁN</div>
        <div class="kpi-value">{{ kpiData.paidBills }}</div>
      </div>
      <div class="kpi-card kpi-orange">
        <div class="kpi-label">SỐ LƯỢNG PHIẾU CHƯA THANH TOÁN</div>
        <div class="kpi-value">{{ kpiData.unpaidBills }}</div>
      </div>
      <div class="kpi-card kpi-red">
        <div class="kpi-label">TRUNG BÌNH PHIẾU</div>
        <div class="kpi-value">{{ formatCurrency(kpiData.avgPerBill) }}</div>
      </div>
      <div class="kpi-card kpi-purple">
        <div class="kpi-label">TRUNG BÌNH KHÁCH</div>
        <div class="kpi-value">
          {{ formatCurrency(kpiData.avgPerCustomer) }}
        </div>
      </div>
    </div>

    <!-- 5. CHART AREA: flex-1 + scroll -->
    <div class="chart-section flex-1 overflow-y-auto">
      <!-- Tab Content: Biểu đồ doanh thu -->
      <div v-show="activeTab === 'chart'" class="chart-container-wrapper">
        <h3 class="chart-title">Doanh thu 30 ngày gần nhất</h3>
        <div class="chart-container">
          <canvas ref="revenueChart"></canvas>
        </div>
      </div>

      <!-- Tab Content: Tổng thể -->
      <div v-if="activeTab === 'overview'" class="overview-tab">
        <div class="table-container">
          <table class="revenue-table">
            <thead>
              <tr>
                <th class="col-stt">STT</th>
                <th class="col-desc">Tên doanh thu</th>
                <th class="col-ps-tang">PS Tăng</th>
                <th class="col-ps-giam">PS giảm</th>
                <th class="col-note">Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(row, index) in reportData"
                :key="index"
                :class="{ 'total-row': row.isTotal }"
              >
                <td class="col-stt">{{ row.stt }}</td>
                <td class="col-desc">{{ row.description }}</td>
                <td class="col-ps-tang text-right font-bold">
                  {{ formatTableCurrency(row.psTang) }}
                </td>
                <td class="col-ps-giam text-right font-bold">
                  {{ formatTableCurrency(row.psGiam) }}
                </td>
                <td class="col-note">{{ row.ghiChu }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Tab Content: Doanh thu chi tiết -->
      <div v-if="activeTab === 'detailed-revenue'" class="detailed-revenue-tab">
        <div class="table-container">
          <table class="revenue-table">
            <thead>
              <tr>
                <th>Số phiếu</th>
                <th>Tên chi nhánh</th>
                <th>Khu</th>
                <th>Ca</th>
                <th>NV tính tiền</th>
                <th>Vị trí</th>
                <th>SL Khách</th>
                <th>Giờ vào</th>
                <th>TG đóng phiếu</th>
                <th>Tổng tiền</th>
                <th>Tiền dịch vụ</th>
                <th>Phí phục vụ</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="invoice in detailedRevenueData"
                :key="invoice.id"
                :class="getRowClass(invoice)"
              >
                <td class="font-bold">{{ invoice.soPhieu }}</td>
                <td>{{ invoice.tenChiNhanh }}</td>
                <td>{{ invoice.khu }}</td>
                <td>{{ invoice.ca }}</td>
                <td>{{ invoice.nhanVien }}</td>
                <td>{{ invoice.viTri }}</td>
                <td class="text-center">{{ invoice.soKhach }}</td>
                <td>{{ invoice.gioVao }}</td>
                <td>{{ invoice.tgDongPhieu }}</td>
                <td class="text-right font-bold">
                  {{ formatVND(invoice.tongTien) }}
                </td>
                <td class="text-right">{{ formatVND(invoice.tienDichVu) }}</td>
                <td class="text-right">{{ formatVND(invoice.phiPhucVu) }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="summary-row">
                <td colspan="6" class="text-right font-bold">Tổng cộng:</td>
                <td class="text-center font-bold">{{ totalSoKhach }}</td>
                <td colspan="2"></td>
                <td class="text-right font-bold">
                  {{ formatVND(totalTongTien) }}
                </td>
                <td class="text-right">{{ formatVND(totalTienDichVu) }}</td>
                <td class="text-right">{{ formatVND(totalPhiPhucVu) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- TAB: CHI TIẾT HÀNG HÓA -->
      <div v-if="activeTab === 'items'" class="detailed-revenue-tab">
        <div class="table-container">
          <table class="revenue-table items-table">
            <thead>
              <tr>
                <th class="col-stt text-center">STT</th>
                <th class="col-ten-nhanh">Tên nhánh</th>
                <th class="col-ma-hang">Mã hàng</th>
                <th class="col-khu">Khu</th>
                <th class="col-ten-hang">Tên hàng</th>
                <th class="col-dvt">ĐVT</th>
                <th class="col-sl">SL</th>
                <th class="col-don-gia">Đơn giá</th>
                <th class="col-ghi-chu">Ghi chú</th>
                <th class="col-chiet-khau-mon">Chiết khấu món</th>
                <th class="col-tong-cong">Tổng cộng</th>
                <th class="col-chiet-khau-bill">Chiết khấu Bill</th>
                <th class="col-phi-phuc-vu">Phí phục vụ</th>
                <th class="col-tong-tien-truoc-thue">Tổng tiền trước thuế</th>
                <th class="col-thue-vat">Tiền thuế VAT</th>
                <th class="col-thanh-tien">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in itemDetailsData" :key="item.id" :class="index % 2 === 0 ? 'row-even' : 'row-odd'">
                <td class="col-stt text-center">{{ index + 1 }}</td>
                <td class="col-ten-nhanh">{{ item.tenNhanh }}</td>
                <td class="col-ma-hang font-mono">{{ item.maHang }}</td>
                <td class="col-khu">{{ item.khu }}</td>
                <td class="col-ten-hang font-bold">{{ item.tenHang }}</td>
                <td class="col-dvt">{{ item.dvt }}</td>
                <td class="col-sl text-center font-bold">{{ item.sl }}</td>
                <td class="col-don-gia text-right">{{ formatVND(item.donGia) }}</td>
                <td class="col-ghi-chu text-gray-600">{{ item.ghiChu || '-' }}</td>
                <td class="col-chiet-khau-mon text-right text-red-600">
                  {{ item.chietKhauMon > 0 ? '-' + formatVND(item.chietKhauMon) : '0đ' }}
                </td>
                <td class="col-tong-cong text-right font-bold">{{ formatVND(item.tongCong) }}</td>
                <td class="col-chiet-khau-bill text-right text-red-600">
                  {{ item.chietKhauBill > 0 ? '-' + formatVND(item.chietKhauBill) : '0đ' }}
                </td>
                <td class="col-phi-phuc-vu text-right">{{ formatVND(item.phiPhucVu) }}</td>
                <td class="col-tong-tien-truoc-thue text-right">{{ formatVND(item.tongTienTruocThue) }}</td>
                <td class="col-thue-vat text-right text-blue-600">{{ formatVND(item.tienThueVAT) }}</td>
                <td class="col-thanh-tien text-right font-bold text-green-700">{{ formatVND(item.thanhTien) }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="summary-row">
                <td colspan="6" class="text-right font-bold">Tổng cộng:</td>
                <td class="col-sl text-center font-bold text-blue-700">{{ itemDetailsTotals.sl }}</td>
                <td></td>
                <td></td>
                <td class="text-right font-bold text-red-700">
                  -{{ formatVND(itemDetailsTotals.chietKhauMon) }}
                </td>
                <td class="text-right font-bold">{{ formatVND(itemDetailsTotals.tongCong) }}</td>
                <td class="text-right font-bold text-red-700">
                  -{{ formatVND(itemDetailsTotals.chietKhauBill) }}
                </td>
                <td class="text-right font-bold">{{ formatVND(itemDetailsTotals.phiPhucVu) }}</td>
                <td class="text-right font-bold">{{ formatVND(itemDetailsTotals.tongTienTruocThue) }}</td>
                <td class="text-right font-bold text-blue-700">{{ formatVND(itemDetailsTotals.tienThueVAT) }}</td>
                <td class="text-right font-bold text-green-700 text-lg">
                  {{ formatVND(itemDetailsTotals.thanhTien) }}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- TAB: ĐỐI CHIẾU BẾP -->
      <div v-if="activeTab === 'kitchen'" class="detailed-revenue-tab">
        <div class="table-container">
          <table class="revenue-table kitchen-table">
            <thead>
              <tr>
                <th class="col-stt text-center">STT</th>
                <th class="col-ma-hang">Mã hàng</th>
                <th class="col-ten-hang">Tên hàng</th>
                <th class="col-dvt">ĐVT</th>
                <th class="col-sl text-center">SL</th>
                <th class="col-bep">Bếp</th>
                <th class="col-trang-thai">Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in kitchenCheckData" :key="item.id" :class="index % 2 === 0 ? 'row-even' : 'row-odd'">
                <td class="col-stt text-center">{{ index + 1 }}</td>
                <td class="col-ma-hang font-mono font-bold">{{ item.maHang }}</td>
                <td class="col-ten-hang font-bold">{{ item.tenHang }}</td>
                <td class="col-dvt">{{ item.dvt }}</td>
                <td class="col-sl text-center font-bold">{{ item.sl }}</td>
                <td class="col-bep">
                  <span class="kitchen-badge">{{ item.bep }}</span>
                </td>
                <td class="col-trang-thai">
                  <span :class="['status-badge', `status-${item.trangThai}`]">
                    {{ getKitchenStatusLabel(item.trangThai) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- TAB: ĐỔI QUÀ -->
      <div v-if="activeTab === 'exchange'" class="detailed-revenue-tab">
        <div class="table-container">
          <table class="revenue-table exchange-table">
            <thead>
              <tr>
                <th class="col-stt text-center">STT</th>
                <th class="col-so-phieu">Số phiếu</th>
                <th class="col-khach-hang">Khách hàng</th>
                <th class="col-ma-the">Mã thẻ</th>
                <th class="col-sl text-center">Số lượng</th>
                <th class="col-mat-hang">Mặt hàng</th>
                <th class="col-dvt">ĐVT</th>
                <th class="col-diem-tru text-right">Điểm trừ</th>
                <th class="col-ghi-chu">Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in giftExchangeData" :key="item.id" :class="index % 2 === 0 ? 'row-even' : 'row-odd'">
                <td class="col-stt text-center">{{ index + 1 }}</td>
                <td class="col-so-phieu font-mono font-bold">{{ item.soPhieu }}</td>
                <td class="col-khach-hang font-bold">{{ item.khachHang }}</td>
                <td class="col-ma-the font-mono text-purple-700">{{ item.maThe }}</td>
                <td class="col-sl text-center font-bold">{{ item.soLuong }}</td>
                <td class="col-mat-hang">{{ item.matHang }}</td>
                <td class="col-dvt">{{ item.dvt }}</td>
                <td class="col-diem-tru text-right font-bold text-orange-700">
                  {{ item.diemTru.toLocaleString('vi-VN') }} điểm
                </td>
                <td class="col-ghi-chu text-gray-600">{{ item.ghiChu || '-' }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="summary-row">
                <td colspan="7" class="text-right font-bold">Tổng điểm trừ:</td>
                <td class="text-right font-bold text-orange-700 text-lg">
                  {{ giftExchangeTotals.toLocaleString('vi-VN') }} điểm
                </td>
                <td></td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- TAB: THU CHI -->
      <div v-if="activeTab === 'cash'" class="detailed-revenue-tab">
        <div class="table-container">
          <table class="revenue-table cashflow-table">
            <thead>
              <tr>
                <th class="col-stt text-center">STT</th>
                <th class="col-so-phieu">Số phiếu</th>
                <th class="col-nhan-vien">Nhân viên tạo</th>
                <th class="col-doi-tuong">Đối tượng</th>
                <th class="col-loai-chung-tu">Loại chứng từ</th>
                <th class="col-khoan">Khoản</th>
                <th class="col-tong-tien text-right">Tổng tiền</th>
                <th class="col-ly-do">Lý do</th>
                <th class="col-tien-mat text-center">Tiền mặt</th>
                <th class="col-ghi-chu">Ghi chú</th>
                <th class="col-so-chung-tu">Số chứng từ</th>
                <th class="col-quay">Quầy</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in cashFlowData" :key="item.id" :class="index % 2 === 0 ? 'row-even' : 'row-odd'">
                <td class="col-stt text-center">{{ index + 1 }}</td>
                <td class="col-so-phieu font-mono font-bold">{{ item.soPhieu }}</td>
                <td class="col-nhan-vien">{{ item.nhanVienTao }}</td>
                <td class="col-doi-tuong font-bold">{{ item.doiTuong }}</td>
                <td class="col-loai-chung-tu">
                  <span :class="['voucher-badge', item.loaiChungTu === 'Thu khác' ? 'voucher-thu' : 'voucher-chi']">
                    {{ item.loaiChungTu }}
                  </span>
                </td>
                <td class="col-khoan">{{ item.khoan }}</td>
                <td class="col-tong-tien text-right font-bold" :class="item.loaiChungTu === 'Thu khác' ? 'text-green-700' : 'text-red-700'">
                  {{ item.loaiChungTu === 'Thu khác' ? '+' : '-' }}{{ formatVND(item.tongTien) }}
                </td>
                <td class="col-ly-do text-gray-600">{{ item.lyDo }}</td>
                <td class="col-tien-mat text-center">
                  <span :class="item.tienMat ? 'cash-yes' : 'cash-no'">
                    {{ item.tienMat ? '✔️' : '❌' }}
                  </span>
                </td>
                <td class="col-ghi-chu text-gray-600">{{ item.ghiChu || '-' }}</td>
                <td class="col-so-chung-tu font-mono text-xs">{{ item.soChungTu }}</td>
                <td class="col-quay">{{ item.quay }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="summary-row">
                <td colspan="6" class="text-right font-bold">Tổng cộng:</td>
                <td class="text-right font-bold text-lg" :class="cashFlowTotals >= 0 ? 'text-green-700' : 'text-red-700'">
                  {{ formatVND(cashFlowTotals) }}
                </td>
                <td colspan="5"></td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- Tab Content: Others -->
      <div
        v-if="
          activeTab !== 'chart' &&
          activeTab !== 'detailed-revenue' &&
          activeTab !== 'overview' &&
          activeTab !== 'items' &&
          activeTab !== 'kitchen' &&
          activeTab !== 'exchange' &&
          activeTab !== 'cash'
        "
        class="p-8 text-center text-gray-400"
      >
        Tính năng này đang được phát triển.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { useRouter } from "vue-router";
import { Chart, registerables } from "chart.js";
import HamburgerMenu from "@/components/reception/HamburgerMenu.vue";
import SidebarNavigation from "@/components/reception/SidebarNavigation.vue";

Chart.register(...registerables);

const router = useRouter();

// State
const showSidebar = ref(false);
const activeTab = ref("overview");

const filters = ref({
  area: "",
  businessType: "",
  counter: "",
  shift: "",
  fromDate: "2026-07-02",
  fromTime: "15:11:14",
  toDate: "2026-07-02",
  toTime: "15:11:14",
});

const areas = ref([
  { value: "catalog", label: "Catalog" },
  { value: "khu-a", label: "Khu A" },
  { value: "khu-b", label: "Khu B" },
  { value: "khu-c", label: "Khu C" },
  { value: "khu-r", label: "Khu R" },
  { value: "khu-t", label: "Khu T" },
  { value: "capichi", label: "Capichi" },
  { value: "shoppe", label: "Shoppe" },
  { value: "garb", label: "Garb" },
]);
const counters = ref(["Thu Ngân", "Quầy 1", "Quầy 2"]);

const tabs = ref([
  { id: "chart", label: "Biểu đồ doanh thu" },
  { id: "overview", label: "Tổng thể" },
  { id: "detailed-revenue", label: "Doanh thu chi tiết" },
  { id: "items", label: "Chi tiết hàng hóa" },
  { id: "kitchen", label: "Đối chiếu bếp" },
  { id: "exchange", label: "Đối quà" },
  { id: "cash", label: "Thu chi" },
  { id: "debt", label: "Bill khách nợ" },
  { id: "sales", label: "Báo cáo bán hàng chi tiết" },
]);

// Report Data Overview
interface RevenueReport {
  stt: string;
  description: string;
  psTang: number;
  psGiam: number;
  ghiChu: string;
  isTotal?: boolean;
}

const reportData = ref<RevenueReport[]>([
  {
    stt: "1",
    description: "Doanh thu Thu Ngân (*)",
    psTang: 11613900,
    psGiam: 0,
    ghiChu: "11 Số lượng phiếu",
    isTotal: false,
  },
  {
    stt: "1.01",
    description: "",
    psTang: 13462000,
    psGiam: 0,
    ghiChu: "A",
    isTotal: false,
  },
  {
    stt: "1.02",
    description: "",
    psTang: 0,
    psGiam: 2724500,
    ghiChu: "B",
    isTotal: false,
  },
  {
    stt: "1.07",
    description: "",
    psTang: 876400,
    psGiam: 0,
    ghiChu: "F",
    isTotal: false,
  },
  {
    stt: "1.11",
    description: "",
    psTang: 11613900,
    psGiam: 0,
    ghiChu: "A-B-C-D+E+F+H+I = I+J+K+L+M",
    isTotal: false,
  },
  {
    stt: "1.12",
    description: "",
    psTang: 3294420,
    psGiam: 0,
    ghiChu: "I",
    isTotal: false,
  },
  {
    stt: "1.23",
    description: "* Thống kê theo phiếu *",
    psTang: 0,
    psGiam: 0,
    ghiChu: "",
    isTotal: true,
  },
  {
    stt: "1.24",
    description: "- Số phiếu đã thanh toán",
    psTang: 11613900,
    psGiam: 0,
    ghiChu: "11 Số lượng phiếu, 11 Khách hàng",
    isTotal: false,
  },
]);

function formatTableCurrency(value: number): string {
  if (value === 0) return "";
  return value.toLocaleString("vi-VN");
}

// Detailed Revenue Data
interface DetailedRevenueItem {
  id: string;
  soPhieu: string;
  tenChiNhanh: string;
  khu: string;
  ca: string;
  nhanVien: string;
  viTri: string;
  soKhach: number;
  gioVao: string;
  tgDongPhieu: string;
  tongTien: number;
  tienDichVu: number;
  phiPhucVu: number;
}

const detailedRevenueData = ref<DetailedRevenueItem[]>([
  {
    id: "1",
    soPhieu: "CN3126070200001",
    tenChiNhanh: "NGƯU CÁT",
    khu: "Khu A",
    ca: "1",
    nhanVien: "Dương Thị Mộng Mơ",
    viTri: "A03",
    soKhach: 1,
    gioVao: "02/07/2026 11:21:17",
    tgDongPhieu: "02/07/2026 12:40:20",
    tongTien: 687360,
    tienDichVu: 863000,
    phiPhucVu: 0,
  },
  {
    id: "2",
    soPhieu: "CN3126070200002",
    tenChiNhanh: "NGƯU CÁT",
    khu: "Khu A",
    ca: "1",
    nhanVien: "Phan Quỳnh Như",
    viTri: "A02",
    soKhach: 1,
    gioVao: "02/07/2026 11:29:19",
    tgDongPhieu: "02/07/2026 12:23:31",
    tongTien: 312440,
    tienDichVu: 288000,
    phiPhucVu: 0,
  },
  {
    id: "3",
    soPhieu: "CN3126070200003",
    tenChiNhanh: "NGƯU CÁT",
    khu: "Khu A",
    ca: "1",
    nhanVien: "Dương Thị Mộng Mơ",
    viTri: "A05",
    soKhach: 1,
    gioVao: "02/07/2026 11:34:44",
    tgDongPhieu: "02/07/2026 13:12:21",
    tongTien: 1683340,
    tienDichVu: 2170000,
    phiPhucVu: 0,
  },
  {
    id: "4",
    soPhieu: "CN3126070200004",
    tenChiNhanh: "NGƯU CÁT",
    khu: "Khu A",
    ca: "1",
    nhanVien: "Dương Thị Mộng Mơ",
    viTri: "A06",
    soKhach: 1,
    gioVao: "02/07/2026 11:35:45",
    tgDongPhieu: "02/07/2026 13:09:47",
    tongTien: 1551900,
    tienDichVu: 2005000,
    phiPhucVu: 0,
  },
  {
    id: "5",
    soPhieu: "CN3126070200005",
    tenChiNhanh: "NGƯU CÁT",
    khu: "Khu B",
    ca: "1",
    nhanVien: "Dương Thị Mộng Mơ",
    viTri: "B01",
    soKhach: 1,
    gioVao: "02/07/2026 11:59:08",
    tgDongPhieu: "02/07/2026 13:07:21",
    tongTien: 2511000,
    tienDichVu: 2325000,
    phiPhucVu: 0,
  },
]);

const totalSoKhach = computed(() =>
  detailedRevenueData.value.reduce((sum, item) => sum + item.soKhach, 0),
);

const totalTongTien = computed(() =>
  detailedRevenueData.value.reduce((sum, item) => sum + item.tongTien, 0),
);

const totalTienDichVu = computed(() =>
  detailedRevenueData.value.reduce((sum, item) => sum + item.tienDichVu, 0),
);

const totalPhiPhucVu = computed(() =>
  detailedRevenueData.value.reduce((sum, item) => sum + item.phiPhucVu, 0),
);

function getRowClass(invoice: DetailedRevenueItem): string {
  const index = detailedRevenueData.value.indexOf(invoice);
  return index % 2 === 0 ? "row-even" : "row-odd";
}

function formatVND(value: number): string {
  return value.toLocaleString("vi-VN") + "đ";
}

// ===== CHI TIẾT HÀNG HÓA =====
interface ItemDetail {
  id: string
  tenNhanh: string
  maHang: string
  khu: string
  tenHang: string
  dvt: string
  sl: number
  donGia: number
  ghiChu: string
  chietKhauMon: number
  tongCong: number
  chietKhauBill: number
  phiPhucVu: number
  tongTienTruocThue: number
  tienThueVAT: number
  thanhTien: number
}

const itemDetailsData = ref<ItemDetail[]>([
  {
    id: '1',
    tenNhanh: 'NGƯU CÁT',
    maHang: 'BUFFET_1390',
    khu: 'Khu A',
    tenHang: 'Vé Người Lớn 1390',
    dvt: 'Vé',
    sl: 2,
    donGia: 1380000,
    ghiChu: '',
    chietKhauMon: 0,
    tongCong: 2760000,
    chietKhauBill: 0,
    phiPhucVu: 0,
    tongTienTruocThue: 2760000,
    tienThueVAT: 220800,
    thanhTien: 2980800
  },
  {
    id: '2',
    tenNhanh: 'NGƯU CÁT',
    maHang: 'UDON_BO',
    khu: 'Khu A',
    tenHang: 'Mì udon xào cùng thịt bò - Lunch',
    dvt: 'Phần',
    sl: 1,
    donGia: 129000,
    ghiChu: 'Không hành',
    chietKhauMon: 64500,
    tongCong: 129000,
    chietKhauBill: 0,
    phiPhucVu: 0,
    tongTienTruocThue: 64500,
    tienThueVAT: 5160,
    thanhTien: 69660
  },
  {
    id: '3',
    tenNhanh: 'NGƯU CÁT',
    maHang: 'COCA_LON',
    khu: 'Khu B',
    tenHang: 'Coca Cola Lon',
    dvt: 'Lon',
    sl: 3,
    donGia: 25000,
    ghiChu: '',
    chietKhauMon: 0,
    tongCong: 75000,
    chietKhauBill: 0,
    phiPhucVu: 0,
    tongTienTruocThue: 75000,
    tienThueVAT: 6000,
    thanhTien: 81000
  },
  {
    id: '4',
    tenNhanh: 'NGƯU CÁT',
    maHang: 'WAGYU_A5',
    khu: 'Khu R',
    tenHang: 'Thịt bò Wagyu A5 Nhật Bản',
    dvt: 'Phần',
    sl: 1,
    donGia: 890000,
    ghiChu: 'Tái',
    chietKhauMon: 0,
    tongCong: 890000,
    chietKhauBill: 50000,
    phiPhucVu: 0,
    tongTienTruocThue: 840000,
    tienThueVAT: 67200,
    thanhTien: 907200
  }
])

// ===== ĐỐI CHIẾU BẾP =====
interface KitchenCheck {
  id: string
  maHang: string
  tenHang: string
  dvt: string
  sl: number
  bep: string
  trangThai: 'pending' | 'preparing' | 'ready' | 'served' | 'cancelled'
}

const kitchenCheckData = ref<KitchenCheck[]>([
  {
    id: '1',
    maHang: 'UDON_BO',
    tenHang: 'Mì udon xào cùng thịt bò - Lunch',
    dvt: 'Phần',
    sl: 1,
    bep: 'BẾP NÓNG',
    trangThai: 'ready'
  },
  {
    id: '2',
    maHang: 'BUFFET_1390',
    tenHang: 'Vé Người Lớn 1390',
    dvt: 'Vé',
    sl: 2,
    bep: 'QUẦY LỄ TÂN',
    trangThai: 'served'
  },
  {
    id: '3',
    maHang: 'WAGYU_A5',
    tenHang: 'Thịt bò Wagyu A5 Nhật Bản',
    dvt: 'Phần',
    sl: 1,
    bep: 'BẾP NƯỚNG',
    trangThai: 'preparing'
  },
  {
    id: '4',
    maHang: 'SALAD',
    tenHang: 'Salad rau trộn kiểu Nhật',
    dvt: 'Dĩa',
    sl: 2,
    bep: 'BẾP LẠNH',
    trangThai: 'pending'
  },
  {
    id: '5',
    maHang: 'COCA_LON',
    tenHang: 'Coca Cola Lon',
    dvt: 'Lon',
    sl: 3,
    bep: 'QUẦY BAR',
    trangThai: 'served'
  }
])

// ===== ĐỔI QUÀ =====
interface GiftExchange {
  id: string
  soPhieu: string
  khachHang: string
  maThe: string
  soLuong: number
  matHang: string
  dvt: string
  diemTru: number
  ghiChu: string
}

const giftExchangeData = ref<GiftExchange[]>([
  {
    id: '1',
    soPhieu: 'CN3126070200001',
    khachHang: 'Nguyễn Văn A',
    maThe: 'VIP-001234',
    soLuong: 1,
    matHang: 'Voucher giảm giá 100K',
    dvt: 'Cái',
    diemTru: 1000,
    ghiChu: 'Đổi từ điểm tích lũy'
  },
  {
    id: '2',
    soPhieu: 'CN3126070200002',
    khachHang: 'Trần Thị B',
    maThe: 'VIP-005678',
    soLuong: 2,
    matHang: 'Nước ngọt miễn phí',
    dvt: 'Lon',
    diemTru: 500,
    ghiChu: 'Sinh nhật khách hàng'
  },
  {
    id: '3',
    soPhieu: 'CN3126070200003',
    khachHang: 'Lê Văn C',
    maThe: 'VIP-009012',
    soLuong: 1,
    matHang: 'Món tráng miệng',
    dvt: 'Phần',
    diemTru: 800,
    ghiChu: 'Khách hàng thân thiết'
  }
])

// ===== THU CHI =====
interface CashFlow {
  id: string
  soPhieu: string
  nhanVienTao: string
  doiTuong: string
  loaiChungTu: string
  khoan: string
  tongTien: number
  lyDo: string
  tienMat: boolean
  ghiChu: string
  soChungTu: string
  quay: string
}

const cashFlowData = ref<CashFlow[]>([
  {
    id: '1',
    soPhieu: 'TC-20260702-001',
    nhanVienTao: 'Dương Thị Mộng Mơ',
    doiTuong: 'Khách vãng lai',
    loaiChungTu: 'Thu khác',
    khoan: 'Rút tiền dư',
    tongTien: 5000000,
    lyDo: 'Rút tiền dư cuối ca',
    tienMat: true,
    ghiChu: '',
    soChungTu: 'AUTO-001',
    quay: 'Thu Ngân 1'
  },
  {
    id: '2',
    soPhieu: 'TC-20260702-002',
    nhanVienTao: 'Phan Quỳnh Như',
    doiTuong: 'Nhà cung cấp A',
    loaiChungTu: 'Chi phí',
    khoan: 'Mua nguyên liệu',
    tongTien: 2500000,
    lyDo: 'Mua thịt bò Wagyu',
    tienMat: false,
    ghiChu: 'Chuyển khoản',
    soChungTu: 'AUTO-002',
    quay: 'Thu Ngân 2'
  },
  {
    id: '3',
    soPhieu: 'TC-20260702-003',
    nhanVienTao: 'Dương Thị Mộng Mơ',
    doiTuong: 'Khách hàng VIP',
    loaiChungTu: 'Thu khác',
    khoan: 'Tiền đặt cọc',
    tongTien: 10000000,
    lyDo: 'Đặt bàn tiệc 10 người',
    tienMat: true,
    ghiChu: 'Đặt bàn ngày 05/07',
    soChungTu: 'AUTO-003',
    quay: 'Thu Ngân 1'
  }
])

// Computed totals
const itemDetailsTotals = computed(() => {
  return itemDetailsData.value.reduce((acc, item) => ({
    sl: acc.sl + item.sl,
    tongCong: acc.tongCong + item.tongCong,
    chietKhauMon: acc.chietKhauMon + item.chietKhauMon,
    chietKhauBill: acc.chietKhauBill + item.chietKhauBill,
    phiPhucVu: acc.phiPhucVu + item.phiPhucVu,
    tongTienTruocThue: acc.tongTienTruocThue + item.tongTienTruocThue,
    tienThueVAT: acc.tienThueVAT + item.tienThueVAT,
    thanhTien: acc.thanhTien + item.thanhTien
  }), {
    sl: 0, tongCong: 0, chietKhauMon: 0, chietKhauBill: 0,
    phiPhucVu: 0, tongTienTruocThue: 0, tienThueVAT: 0, thanhTien: 0
  })
})

const cashFlowTotals = computed(() => {
  return cashFlowData.value.reduce((sum, item) => {
    if (item.loaiChungTu === 'Thu khác') {
      return sum + item.tongTien
    } else {
      return sum - item.tongTien
    }
  }, 0)
})

const giftExchangeTotals = computed(() => {
  return giftExchangeData.value.reduce((sum, item) => sum + item.diemTru, 0)
})

function getKitchenStatusLabel(status: string): string {
  const statusMap: Record<string, string> = {
    'pending': 'Chờ xử lý',
    'preparing': 'Đang chế biến',
    'ready': 'Sẵn sàng',
    'served': 'Đã phục vụ',
    'cancelled': 'Đã hủy'
  }
  return statusMap[status] || status
}

const kpiData = ref({
  totalRevenue: 11614000000,
  paidBills: 11,
  unpaidBills: 1,
  avgPerBill: 1056000000,
  avgPerCustomer: 1056000000,
})

// Chart
const revenueChart = ref<HTMLCanvasElement | null>(null);
let chartInstance: Chart | null = null;

const chartData = {
  labels: [
    "3/6",
    "4/6",
    "5/6",
    "6/6",
    "7/6",
    "8/6",
    "9/6",
    "10/6",
    "11/6",
    "12/6",
    "13/6",
    "14/6",
    "15/6",
    "16/6",
    "17/6",
    "18/6",
    "19/6",
    "20/6",
    "21/6",
    "22/6",
    "23/6",
    "24/6",
    "25/6",
    "26/6",
    "27/6",
    "28/6",
    "29/6",
    "30/6",
    "1/7",
    "2/7",
  ],
  datasets: [
    {
      label: "Doanh thu",
      data: [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        60000000, 85000000, 70000000, 17000000, 57000000, 31000000, 11000000,
      ],
      borderColor: "#F5A623",
      backgroundColor: "rgba(245, 166, 35, 0.1)",
      borderWidth: 2,
      tension: 0.4,
      fill: true,
      pointBackgroundColor: "#F5A623",
      pointBorderColor: "#fff",
      pointBorderWidth: 2,
      pointRadius: 4,
    },
  ],
};

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (context: any) => {
          const value = context.parsed.y;
          return `Doanh thu: ${formatCurrency(value)}`;
        },
      },
    },
  },
  scales: {
    y: {
      beginAtZero: true,
      max: 100000000,
      ticks: {
        callback: (value: any) => `${value / 1000000} Tr`,
        stepSize: 10000000,
      },
      grid: { color: "#e0e0e0" },
    },
    x: {
      grid: { display: false },
    },
  },
};

// Methods
function formatCurrency(value: number): string {
  if (value >= 1000000000) {
    return `${(value / 1000000000).toFixed(3).replace(".", ",")} Tr`;
  }
  return value.toLocaleString("vi-VN") + "đ";
}

function refreshData() {
  console.log("Refreshing...");
}
function exportData() {
  console.log("Exporting...");
}
function printReport() {
  window.print();
}
function goBack() {
  router.push("/reception/dashboard");
}

function initChart() {
  if (revenueChart.value) {
    chartInstance = new Chart(revenueChart.value, {
      type: "line",
      data: chartData,
      options: chartOptions,
    });
  }
}

onMounted(() => {
  initChart();
});
onUnmounted(() => {
  if (chartInstance) chartInstance.destroy();
});
</script>

<style scoped>
/*  KEY: Toàn bộ trang KHÔNG scroll */
.revenue-container {
  height: 100vh;
  width: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
}

/* 1. HEADER - Compact */
.revenue-header {
  background: white;
  padding: 12px 20px 12px 76px; /* Added left padding to prevent overlapping hamburger */
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e0e0e0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
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
  color: #e8772e;
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

.btn-refresh {
  background: #10b981;
  color: white;
}
.btn-back {
  background: #ef4444;
  color: white;
}
.btn-export {
  background: #f59e0b;
  color: white;
}
.btn-print {
  background: #3b82f6;
  color: white;
}

/* 2. FILTERS - 1 row */
.filters-section {
  background: white;
  padding: 10px 20px;
  border-bottom: 1px solid #e0e0e0;
}

.filter-row {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 12px;
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
  border-color: #e8772e;
}

.datetime-group {
  display: flex;
  gap: 4px;
}

.filter-input.date {
  flex: 1;
}

.filter-input.time {
  width: 90px;
}

/* 3. TABS */
.tabs-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 20px;
  background: white;
  border-bottom: 1px solid #e0e0e0;
}

.tabs-left {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.tab-btn {
  padding: 6px 12px;
  background: #f5f5f5;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: #e0e0e0;
}

.tab-btn.active {
  background: #3b82f6;
  color: white;
}

.tabs-right {
  display: flex;
  gap: 8px;
}

/* 4. KPI CARDS - Thu gọn */
.kpi-cards {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  padding: 12px 20px;
  background: white;
  border-bottom: 1px solid #e0e0e0;
}

.kpi-card {
  padding: 12px 16px;
  border-radius: 10px;
  color: white;
  text-align: center;
}

.kpi-blue {
  background: #1a5276;
}
.kpi-green {
  background: #4db6ac;
}
.kpi-orange {
  background: #ffb74d;
}
.kpi-red {
  background: #e57373;
}
.kpi-purple {
  background: #7b1fa2;
}

.kpi-label {
  font-size: 10px;
  font-weight: 700;
  margin-bottom: 6px;
  opacity: 0.9;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.kpi-value {
  font-size: 20px;
  font-weight: 800;
  font-family: "Courier New", monospace;
}

/* 5. CHART AREA - FLEX-1 + SCROLL */
.chart-section {
  background: white;
  margin: 12px 20px 20px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 16px;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Quan trọng cho flex scroll */
}

.chart-title {
  font-size: 14px;
  font-weight: 700;
  color: #333;
  margin: 0 0 12px 0;
  text-align: center;
  flex-shrink: 0;
}

.chart-container {
  flex: 1;
  min-height: 0; /* Cho phép scroll */
  position: relative;
}

/* Custom scrollbar cho chart */
.chart-section::-webkit-scrollbar {
  width: 6px;
}

.chart-section::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.chart-section::-webkit-scrollbar-thumb {
  background: #3b82f6;
  border-radius: 3px;
}

/* Responsive */
@media (max-width: 1400px) {
  .filter-row {
    grid-template-columns: repeat(3, 1fr);
  }

  .kpi-cards {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .filter-row {
    grid-template-columns: repeat(2, 1fr);
  }

  .kpi-cards {
    grid-template-columns: repeat(2, 1fr);
  }

  .tabs-left {
    flex-wrap: wrap;
  }
}

/* Hamburger button positioning */
.revenue-container .hamburger-btn {
  position: absolute;
  top: 12px;
  left: 20px;
  z-index: 997;
}

/* Detailed Revenue Table Styles */
.detailed-revenue-tab {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.table-container {
  overflow-x: auto;
}

.revenue-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.revenue-table thead {
  background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
  color: white;
}

.revenue-table th {
  padding: 12px 10px;
  text-align: left;
  font-weight: 700;
  font-size: 11px;
  text-transform: uppercase;
  border-right: 1px solid rgba(255, 255, 255, 0.2);
  white-space: nowrap;
}

.revenue-table th:last-child {
  border-right: none;
}

.revenue-table tbody tr {
  transition: all 0.2s;
}

.revenue-table tbody tr:hover {
  background: #fff3cd !important;
  transform: scale(1.002);
}

.row-even {
  background: #d4edda;
}

.row-odd {
  background: white;
}

.revenue-table td {
  padding: 10px;
  border-right: 1px solid #e0e0e0;
  border-bottom: 1px solid #e0e0e0;
  color: #333;
}

.revenue-table td:last-child {
  border-right: none;
}

.summary-row {
  background: #e3f2fd !important;
  font-weight: 700;
}

.summary-row td {
  border-top: 2px solid #1976d2;
  padding: 12px 10px;
  color: #1976d2;
}

.font-bold {
  font-weight: 700;
}

.text-right {
  text-align: right;
}

.text-center {
  text-align: center;
}

.chart-container-wrapper {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

.revenue-table tbody tr.total-row {
  background: #ffe082 !important;
  font-weight: 700;
}

.col-stt {
  width: 60px;
}
.col-desc {
  width: 40%;
}
.col-ps-tang {
  width: 20%;
}
.col-ps-giam {
  width: 20%;
}
.col-note {
  width: 20%;
}

.select-with-clear {
  position: relative;
  width: 100%;
  display: flex;
}

.clear-btn {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  font-size: 10px;
}

/* ===== COLUMN WIDTHS - Items Table ===== */
.items-table .col-stt { width: 40px; text-align: center; }
.items-table .col-ten-nhanh { width: 100px; }
.items-table .col-ma-hang { width: 110px; }
.items-table .col-khu { width: 70px; }
.items-table .col-ten-hang { width: 200px; }
.items-table .col-dvt { width: 60px; }
.items-table .col-sl { width: 50px; }
.items-table .col-don-gia { width: 100px; }
.items-table .col-ghi-chu { width: 120px; }
.items-table .col-chiet-khau-mon { width: 110px; }
.items-table .col-tong-cong { width: 110px; }
.items-table .col-chiet-khau-bill { width: 110px; }
.items-table .col-phi-phuc-vu { width: 100px; }
.items-table .col-tong-tien-truoc-thue { width: 130px; }
.items-table .col-thue-vat { width: 100px; }
.items-table .col-thanh-tien { width: 120px; }

/* ===== COLUMN WIDTHS - Kitchen Table ===== */
.kitchen-table .col-stt { width: 50px; text-align: center; }
.kitchen-table .col-ma-hang { width: 130px; }
.kitchen-table .col-ten-hang { width: 280px; }
.kitchen-table .col-dvt { width: 80px; }
.kitchen-table .col-sl { width: 60px; }
.kitchen-table .col-bep { width: 150px; }
.kitchen-table .col-trang-thai { width: 130px; }

/* ===== COLUMN WIDTHS - Exchange Table ===== */
.exchange-table .col-stt { width: 50px; text-align: center; }
.exchange-table .col-so-phieu { width: 150px; }
.exchange-table .col-khach-hang { width: 160px; }
.exchange-table .col-ma-the { width: 130px; }
.exchange-table .col-sl { width: 80px; }
.exchange-table .col-mat-hang { width: 200px; }
.exchange-table .col-dvt { width: 70px; }
.exchange-table .col-diem-tru { width: 120px; }
.exchange-table .col-ghi-chu { width: 200px; }

/* ===== COLUMN WIDTHS - Cash Flow Table ===== */
.cashflow-table .col-stt { width: 50px; text-align: center; }
.cashflow-table .col-so-phieu { width: 150px; }
.cashflow-table .col-nhan-vien { width: 150px; }
.cashflow-table .col-doi-tuong { width: 140px; }
.cashflow-table .col-loai-chung-tu { width: 110px; }
.cashflow-table .col-khoan { width: 130px; }
.cashflow-table .col-tong-tien { width: 130px; }
.cashflow-table .col-ly-do { width: 180px; }
.cashflow-table .col-tien-mat { width: 80px; text-align: center; }
.cashflow-table .col-ghi-chu { width: 150px; }
.cashflow-table .col-so-chung-tu { width: 100px; }
.cashflow-table .col-quay { width: 110px; }

/* ===== STATUS BADGES ===== */
.status-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  display: inline-block;
}

.status-pending {
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffeaa7;
}

.status-preparing {
  background: #cfe2ff;
  color: #084298;
  border: 1px solid #b6d4fe;
  animation: pulse 2s infinite;
}

.status-ready {
  background: #d1e7dd;
  color: #0f5132;
  border: 1px solid #badbcc;
}

.status-served {
  background: #e2e3e5;
  color: #41464b;
  border: 1px solid #d3d6d8;
}

.status-cancelled {
  background: #f8d7da;
  color: #842029;
  border: 1px solid #f5c2c7;
  text-decoration: line-through;
}

/* ===== KITCHEN BADGE ===== */
.kitchen-badge {
  background: #1a5276;
  color: white;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 700;
  display: inline-block;
}

/* ===== VOUCHER BADGE ===== */
.voucher-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 700;
  display: inline-block;
}

.voucher-thu {
  background: #d1e7dd;
  color: #0f5132;
}

.voucher-chi {
  background: #f8d7da;
  color: #842029;
}

/* ===== CASH INDICATOR ===== */
.cash-yes {
  color: #10b981;
  font-weight: 800;
  font-size: 14px;
}

.cash-no {
  color: #ef4444;
  font-weight: 800;
  font-size: 14px;
}

/* ===== UTILITY CLASSES ===== */
.font-mono {
  font-family: 'Courier New', monospace;
}

.text-green-700 { color: #15803d; }
.text-red-700 { color: #b91c1c; }
.text-red-600 { color: #dc2626; }
.text-blue-700 { color: #1d4ed8; }
.text-blue-600 { color: #2563eb; }
.text-orange-700 { color: #c2410c; }
.text-purple-700 { color: #7e22ce; }
.text-gray-600 { color: #4b5563; }

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}
</style>
