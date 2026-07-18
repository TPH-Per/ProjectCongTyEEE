<template>
  <div class="reservation-container">
    <!-- Top Navigation - Fixed Height -->
    <header class="top-nav">
      <div class="nav-left">
        <div class="logo">🏮</div>
        <select v-model="selectedBranch" class="branch-select">
          <option value="nguu-cat">NGƯU CÁT</option>
        </select>
        <div class="date-picker">
          <input v-model="currentDate" type="date" class="date-input" />
          <button class="calendar-btn">📅</button>
        </div>
      </div>
      <div class="nav-right">
        <button class="btn-create" @click="createNew">
          <span>+</span> Tạo mới
        </button>
        <button class="btn-home" @click="goHome">
          ← Trang chủ
        </button>
      </div>
    </header>

    <!-- Main Content - Flex Layout -->
    <div class="main-content">
      <!-- Left Panel: Reservation List -->
      <aside class="left-panel">
        <!-- Header -->
        <div class="panel-header">
          <div class="sort-by">
            <span>Sắp xếp theo</span>
            <span class="sort-icon">↑</span>
          </div>
          <div class="status-filter">
            <span>Trạng thái</span>
            <span class="filter-icon">⌃</span>
          </div>
        </div>

        <!-- Time Tabs -->
        <div class="time-tabs">
          <button 
            v-for="slot in timeSlots"
            :key="slot.id"
            :class="['time-tab', { active: selectedSlot === slot.id }]"
            @click="selectedSlot = slot.id"
          >
            {{ slot.label }}
          </button>
        </div>

        <!-- Reservations List - Scrollable -->
        <div class="reservations-list">
          <div v-if="loading" class="loading-state">Đang tải dữ liệu...</div>
          <div v-else-if="filteredReservations.length === 0" class="empty-state">
            <div class="empty-icon">📭</div>
            <p>Không có lượt đặt nào</p>
          </div>

          <div 
            v-else
            v-for="reservation in filteredReservations"
            :key="reservation.id"
            :class="['reservation-item', { 
              selected: selectedReservation?.id === reservation.id,
              cancelled: reservation.status === 'cancelled'
            }]"
            @click="selectReservation(reservation)"
          >
            <div class="item-top">
              <div class="time-badge">
                <span class="time-icon">🕐</span>
                <span>{{ formatTime(reservation.time) }}</span>
              </div>
              <span class="reservation-code">#{{ reservation.code }}</span>
            </div>
            <div class="item-middle">
              <div class="guest-info">
                <span>👤 {{ reservation.guests }}</span>
                <span v-if="reservation.children > 0">👶 {{ reservation.children }}</span>
              </div>
              <div class="customer-name" :class="{ vip: reservation.isVIP }">
                {{ reservation.customerName }}
              </div>
            </div>
            <div class="item-contact">
              <span>📞 {{ reservation.phone }}</span>
            </div>
            <div class="item-status">
              <span :class="['status-badge', `status-${reservation.status}`]">
                {{ getStatusText(reservation.status) }}
              </span>
            </div>
            <div class="item-notes" v-if="reservation.notes">
              <span class="icon">📝</span>
              <span class="text">{{ reservation.notes }}</span>
            </div>
          </div>
        </div>
      </aside>

      <!-- Right Panel: Form -->
      <main class="right-panel">
        <!-- Customer Info - Compact -->
        <section class="customer-section compact">
          <div class="info-grid">
            <div class="avatar">
              <div class="avatar-circle">👤</div>
            </div>
            <div class="info-fields-grid">
              <div class="field-row-compact">
                <label class="field-label">Điện thoại*</label>
                <div class="input-group">
                  <input 
                    v-model="formData.phone" 
                    type="tel" 
                    placeholder="Nhập số điện thoại" 
                    class="field-input" 
                    :class="{ error: errors.phone }"
                  />
                  <button class="search-btn" @click="searchCustomer">🔍</button>
                </div>
                <span v-if="errors.phone" class="error-text">{{ errors.phone }}</span>
              </div>
              <div class="field-row-compact">
                <label class="field-label">Khách hàng*</label>
                <input 
                  v-model="formData.customerName" 
                  type="text" 
                  placeholder="Tên khách hàng" 
                  class="field-input"
                  :class="{ error: errors.customerName }"
                />
                <span v-if="errors.customerName" class="error-text">{{ errors.customerName }}</span>
              </div>
              <div class="field-row-compact">
                <label class="field-label">Email</label>
                <input v-model="formData.email" type="email" placeholder="Nhập email" class="field-input" />
              </div>
              <div class="field-row-compact">
                <label class="field-label">Đã hoàn cọc</label>
                <input v-model="formData.depositPaid" type="checkbox" class="checkbox-input" />
              </div>
            </div>
            <div class="source-section">
              <label class="source-label">Nguồn khách</label>
              <div class="source-buttons">
                <button 
                  v-for="src in customerSources"
                  :key="src.id"
                  :class="['source-btn', src.id, { active: formData.source === src.id }]"
                  @click="formData.source = src.id"
                >
                  {{ src.label }}
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Tabs -->
        <section class="tabs-section">
          <div class="tabs-nav">
            <button 
              v-for="tab in tabs"
              :key="tab.id"
              :class="['tab-btn', { active: activeTab === tab.id }]"
              @click="activeTab = tab.id"
            >
              {{ tab.label }}
            </button>
          </div>

          <div class="tab-content">
            <!-- TT Đặt Chỗ Tab -->
            <div v-if="activeTab === 'reservation-info'" class="form-compact-container">
              <!-- Row 1: Giờ, Ngày, Trạng thái -->
              <div class="form-row-3col">
                <div class="form-group">
                  <label class="form-label">Giờ*</label>
                  <div class="input-with-btn">
                    <input v-model="formData.time" type="time" class="form-input" />
                    <button class="icon-btn">🕐</button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">Ngày*</label>
                  <div class="input-with-btn">
                    <input v-model="formData.date" type="date" class="form-input" />
                    <button class="icon-btn">📅</button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">Trạng thái</label>
                  <select v-model="formData.status" class="status-select">
                    <option value="new">Mới đặt</option>
                    <option value="confirmed">Đã xác nhận</option>
                    <option value="cancelled">Hủy</option>
                    <option value="completed">Hoàn thành</option>
                  </select>
                </div>
              </div>

              <!-- Row 2: SL Người lớn, SL Trẻ em, SL Bàn, SL Ghế -->
              <div class="form-row-4col">
                <div class="form-group">
                  <label class="form-label">SL Người lớn*</label>
                  <div class="counter-input">
                    <button class="counter-btn" @click="decrement('adults')" :disabled="formData.adults <= 0">−</button>
                    <input v-model.number="formData.adults" type="number" class="counter-value" />
                    <button class="counter-btn" @click="increment('adults')">+</button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">SL Trẻ em</label>
                  <div class="counter-input">
                    <button class="counter-btn" @click="decrement('children')" :disabled="formData.children <= 0">−</button>
                    <input v-model.number="formData.children" type="number" class="counter-value" />
                    <button class="counter-btn" @click="increment('children')">+</button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">SL Bàn</label>
                  <div class="counter-input">
                    <button class="counter-btn" @click="decrement('tables')" :disabled="formData.tables <= 0">−</button>
                    <input v-model.number="formData.tables" type="number" class="counter-value" />
                    <button class="counter-btn" @click="increment('tables')">+</button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">SL Ghế</label>
                  <div class="counter-input">
                    <button class="counter-btn" @click="decrement('seats')" :disabled="formData.seats <= 0">−</button>
                    <input v-model.number="formData.seats" type="number" class="counter-value" />
                    <button class="counter-btn" @click="increment('seats')">+</button>
                  </div>
                </div>
              </div>

              <!-- Row 3: Loại tiệc, Tên tiệc -->
              <div class="form-row-2col">
                <div class="form-group">
                  <label class="form-label">Loại tiệc</label>
                  <div class="party-types">
                    <button 
                      v-for="type in partyTypes"
                      :key="type.id"
                      :class="['type-btn', { active: formData.partyType === type.id }]"
                      @click="formData.partyType = type.id"
                    >
                      {{ type.label }}
                    </button>
                  </div>
                </div>

                <div class="form-group">
                  <label class="form-label">Tên tiệc</label>
                  <input v-model="formData.partyName" type="text" placeholder="Tên tiệc" class="form-input" />
                </div>
              </div>

              <!-- Row 4: Ghi chú -->
              <div class="form-group full-width">
                <label class="form-label">Ghi chú</label>
                <textarea v-model="formData.notes" placeholder="Ghi chú" class="form-textarea" rows="2"></textarea>
              </div>
            </div>

            <!-- TT Mở Rộng Tab -->
            <div v-else-if="activeTab === 'extended-info'" class="tab-panel">
              <div class="extended-grid">
                <div class="extended-field">
                  <label>Bàn đã gán</label>
                  <select v-model="formData.tableId" class="readonly-input">
                    <option value="">-- Chọn bàn --</option>
                    <option v-for="t in dbTables" :key="t.id" :value="t.id">
                      Bàn {{ t.code }} ({{ t.zone }})
                    </option>
                  </select>
                </div>
                <div class="extended-field">
                  <label>Khu vực</label>
                  <input :value="assignedTableZone" type="text" class="readonly-input" readonly placeholder="Chọn bàn để hiển thị khu" />
                </div>
                <div class="extended-field">
                  <label>Số phiếu đặt</label>
                  <input :value="selectedReservation?.id || 'Chưa tạo'" type="text" class="readonly-input" readonly />
                </div>
                <div class="extended-field">
                  <label>Ngày đến</label>
                  <input :value="formData.date" type="text" class="readonly-input" readonly />
                </div>
                <div class="extended-field">
                  <label>Giờ đến</label>
                  <input :value="formData.time" type="text" class="readonly-input" readonly />
                </div>
              </div>
            </div>

            <!-- Người Tiếp Nhận Tab -->
            <div v-else-if="activeTab === 'receiver'" class="tab-panel">
              <div class="extended-grid-2col">
                <div class="extended-field">
                  <label>Nhân viên tiếp nhận</label>
                  <input type="text" class="readonly-input" readonly :value="formData.receiverName" />
                </div>
                <div class="extended-field">
                  <label>Ngày tiếp nhận</label>
                  <input type="text" class="readonly-input" readonly :value="formData.date" />
                </div>
              </div>
            </div>

            <!-- Other Tabs (WIP) -->
            <div v-else class="tab-panel wip">
              <div class="wip-message">
                 Tính năng lịch sử tiêu dùng đang được phát triển
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>

    <!-- Footer - Fixed Height -->
    <footer class="main-footer">
      <div class="footer-info">
        <div class="info-item">
          <span class="label">Bàn:</span>
          <span class="value">{{ assignedTableCode || '-' }}</span>
        </div>
        <div class="info-item">
          <span class="label">Khu:</span>
          <span class="value">{{ assignedTableZone || '-' }}</span>
        </div>
      </div>
      <div class="footer-actions">
        <button v-if="selectedReservation" class="btn-save update" @click="handleUpdate" :disabled="submitting">
          💾 Cập nhật đặt bàn
        </button>
        <button class="btn-save" @click="handleCreate" :disabled="submitting">
          <span>+</span> Tạo đặt bàn mới
        </button>
      </div>
    </footer>

    <!-- Bottom Navigation - Fixed Height -->
    <nav class="bottom-nav">
      <button 
        class="nav-item"
        :class="{ active: currentView === 'calendar' }"
        @click="selectBottomTab('calendar')"
      >
        <span class="nav-icon">📅</span>
        <span class="nav-label">Lịch</span>
      </button>
      
      <button 
        class="nav-item"
        :class="{ active: currentView === 'detail' }"
        @click="selectBottomTab('detail')"
      >
        <span class="nav-icon">📋</span>
        <span class="nav-label">Chi tiết đặt</span>
      </button>
      
      <button 
        class="nav-item"
        :class="{ active: currentView === 'floor-plan' }"
        @click="selectBottomTab('floor-plan')"
      >
        <span class="nav-icon">🪑</span>
        <span class="nav-label">Sơ đồ bàn</span>
      </button>
      
      <button 
        class="nav-item"
        :class="{ active: currentView === 'order-menu' }"
        @click="selectBottomTab('order-menu')"
      >
        <span class="nav-icon">🍕</span>
        <span class="nav-label">Chọn món</span>
      </button>
    </nav>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useReservation } from '@/composables/useReservation'
import { useTable } from '@/composables/useTable'
import Swal from 'sweetalert2'

const router = useRouter()
const route = useRoute()
const { listReservations, createReservation, updateStatus } = useReservation()
const { listTables } = useTable()

const selectedBranch = ref('nguu-cat')
const currentDate = ref(new Date().toISOString().split('T')[0])
const currentView = ref('detail')
const selectedSlot = ref('all')
const activeTab = ref('reservation-info')
const dbReservations = ref<any[]>([])
const dbTables = ref<any[]>([])
const selectedReservation = ref<any>(null)
const loading = ref(false)
const submitting = ref(false)

const timeSlots = [
  { id: 'all', label: 'Tất cả' },
  { id: 'morning', label: 'Sáng' },
  { id: 'lunch', label: 'Trưa' },
  { id: 'afternoon', label: 'Chiều' },
  { id: 'evening', label: 'Tối' }
]

const tabs = [
  { id: 'reservation-info', label: 'TT Đặt Chỗ' },
  { id: 'extended-info', label: 'TT Mở Rộng' },
  { id: 'receiver', label: 'Người Tiếp Nhận' },
  { id: 'history', label: 'Lịch Sử Tiêu Dùng' }
]

const customerSources = [
  { id: 'facebook', label: 'Facebook' },
  { id: 'app', label: 'Khách app' },
  { id: 'mobile', label: 'Mobile App' },
  { id: 'tel', label: 'Tel' }
]

const partyTypes = [
  { id: 'dinner', label: 'Ăn tối' },
  { id: 'lunch', label: 'Ăn trưa' },
  { id: 'birthday', label: 'Sinh nhật' },
  { id: 'anniversary', label: 'Kỷ niệm' },
  { id: 'party', label: 'Liên hoan' }
]

const formData = reactive({
  phone: '',
  email: '',
  customerName: '',
  depositPaid: false,
  source: 'facebook',
  time: '18:00',
  date: new Date().toISOString().split('T')[0],
  adults: 2,
  children: 0,
  tables: 1,
  seats: 2,
  partyType: 'dinner',
  partyName: '',
  notes: '',
  tableId: '',
  status: 'new',
  receiverName: 'Lễ tân sảnh'
})

const errors = reactive({
  phone: '',
  customerName: ''
})

// Helper to determine slot from time string
function getTimeSlot(timeStr: string) {
  if (!timeStr) return 'morning'
  const hour = parseInt(timeStr.split(':')[0], 10)
  if (hour < 11) return 'morning'
  if (hour < 14) return 'lunch'
  if (hour < 17) return 'afternoon'
  return 'evening'
}

const filteredReservations = computed(() => {
  if (selectedSlot.value === 'all') return dbReservations.value
  return dbReservations.value.filter(r => r.timeSlot === selectedSlot.value)
})

const assignedTableCode = computed(() => {
  if (!formData.tableId) return ''
  const t = dbTables.value.find(table => table.id === formData.tableId)
  return t ? t.code : ''
})

const assignedTableZone = computed(() => {
  if (!formData.tableId) return ''
  const t = dbTables.value.find(table => table.id === formData.tableId)
  return t ? t.zone : ''
})

async function fetchReservations() {
  loading.value = true
  try {
    const today = new Date().toISOString().split('T')[0]
    const res = await listReservations({ date: today })
    dbReservations.value = (res.reservations || []).map((r: any) => {
      const snap = r.customer_snapshot as any
      return {
        id: r.id,
        code: r.booking_code || r.id.substring(0, 5).toUpperCase(),
        time: r.reservation_time ? r.reservation_time.substring(0, 5) : '18:00',
        guests: r.guests || 0,
        children: r.children_count || 0,
        customerName: snap?.name || 'Khách vãng lai',
        phone: snap?.phone || '',
        email: snap?.email || '',
        status: (r.status === 'CONFIRMED' || r.status === 'Arrived') ? 'confirmed' : r.status === 'Dining' ? 'completed' : (r.status === 'Cancelled' || r.status === 'NO_SHOW') ? 'cancelled' : 'new',
        timeSlot: getTimeSlot(r.reservation_time),
        notes: r.booking_info?.notes || '',
        partyName: r.booking_info?.occasion || '',
        tableId: r.table_id || '',
        source: r.source || 'facebook'
      }
    })
  } catch (error) {
    console.error(error)
  } finally {
    loading.value = false
  }
}

async function fetchTables() {
  try {
    dbTables.value = await listTables()
  } catch (error) {
    console.error(error)
  }
}

function selectReservation(reservation: any) {
  selectedReservation.value = reservation
  Object.assign(formData, {
    phone: reservation.phone,
    email: reservation.email,
    customerName: reservation.customerName,
    depositPaid: false,
    time: reservation.time,
    date: new Date().toISOString().split('T')[0],
    adults: reservation.guests,
    children: reservation.children,
    tables: reservation.tableId ? 1 : 0,
    seats: reservation.guests,
    partyName: reservation.partyName,
    partyType: 'dinner',
    notes: reservation.notes,
    tableId: reservation.tableId || '',
    status: reservation.status || 'new',
    source: reservation.source || 'facebook',
    receiverName: 'Lễ tân sảnh'
  })
}

function increment(field: 'adults' | 'children' | 'tables' | 'seats') {
  formData[field]++
}

function decrement(field: 'adults' | 'children' | 'tables' | 'seats') {
  if (formData[field] > 0) {
    formData[field]--
  }
}

function formatTime(time: string): string {
  if (!time) return ''
  const [hours, minutes] = time.split(':')
  const hour = parseInt(hours)
  const ampm = hour >= 12 ? 'PM' : 'AM'
  const displayHour = hour % 12 || 12
  return `${displayHour}:${minutes} ${ampm}`
}

function getStatusText(status: string): string {
  const statusMap: Record<string, string> = {
    'new': 'Mới đặt',
    'confirmed': 'Đã xác nhận',
    'cancelled': 'Hủy',
    'completed': 'Hoàn thành'
  }
  return statusMap[status] || status
}

function searchCustomer() {
  if (!formData.phone) {
    errors.phone = 'Vui lòng nhập số điện thoại'
    return
  }
  errors.phone = ''
  Swal.fire({
    title: 'Tìm kiếm khách hàng',
    text: `Đang quét dữ liệu CRM cho SĐT: ${formData.phone}`,
    icon: 'info',
    timer: 1500,
    showConfirmButton: false
  })
}

function validateForm(): boolean {
  let isValid = true
  errors.phone = ''
  errors.customerName = ''

  if (!formData.phone) {
    errors.phone = 'Số điện thoại là bắt buộc'
    isValid = false
  }

  if (!formData.customerName) {
    errors.customerName = 'Tên khách hàng là bắt buộc'
    isValid = false
  }

  return isValid
}

async function handleCreate() {
  if (!validateForm()) return
  submitting.value = true
  try {
    await createReservation({
      guestName: formData.customerName,
      guestPhone: formData.phone,
      reservationTime: `${formData.date} ${formData.time}:00`,
      guestCount: formData.adults,
      notes: formData.notes || undefined
    })

    await Swal.fire('Thành công', 'Đã tạo đặt bàn thành công!', 'success')
    await fetchReservations()
    resetForm()
  } catch (error: any) {
    Swal.fire('Lỗi', error.message || 'Không thể tạo đặt bàn.', 'error')
  } finally {
    submitting.value = false
  }
}

async function handleUpdate() {
  if (!selectedReservation.value) return
  if (!validateForm()) return
  submitting.value = true
  try {
    let newDbStatus = 'PENDING'
    if (formData.status === 'confirmed') newDbStatus = 'CONFIRMED'
    else if (formData.status === 'completed') newDbStatus = 'Dining'
    else if (formData.status === 'cancelled') newDbStatus = 'Cancelled'

    await updateStatus(
      selectedReservation.value.id,
      newDbStatus as any,
      formData.tableId || undefined
    )

    await Swal.fire('Thành công', 'Đã cập nhật đặt bàn thành công!', 'success')
    await fetchReservations()
  } catch (error: any) {
    Swal.fire('Lỗi', error.message || 'Không thể cập nhật đặt bàn.', 'error')
  } finally {
    submitting.value = false
  }
}

function createNew() {
  resetForm()
  Swal.fire({
    title: 'Biểu mẫu đã trống',
    text: 'Sẵn sàng để nhập thông tin đặt bàn mới.',
    icon: 'info',
    timer: 1000,
    showConfirmButton: false,
    toast: true,
    position: 'top-end'
  })
}

function resetForm() {
  selectedReservation.value = null
  Object.assign(formData, {
    phone: '',
    email: '',
    customerName: '',
    depositPaid: false,
    source: 'facebook',
    time: '18:00',
    date: new Date().toISOString().split('T')[0],
    adults: 2,
    children: 0,
    tables: 1,
    seats: 2,
    partyType: 'dinner',
    partyName: '',
    notes: '',
    tableId: '',
    status: 'new',
    receiverName: 'Lễ tân sảnh'
  })
}

function goHome() {
  router.push({ name: 'reception-dashboard' })
}

function selectBottomTab(tab: string) {
  if (tab === 'calendar') {
    router.push({ name: 'reception-dashboard' })
  } else if (tab === 'detail') {
    // Current tab
  } else if (tab === 'floor-plan') {
    router.push({ name: 'reception-floors' })
  } else if (tab === 'order-menu') {
    router.push({ name: 'reception-order' })
  }
}

onMounted(async () => {
  await fetchReservations()
  await fetchTables()
  if (route.query.id) {
    const res = dbReservations.value.find(r => r.id === route.query.id)
    if (res) selectReservation(res)
  }
})
</script>

<style scoped>
/* Container - Full Height */
.reservation-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
  background: #f8fafc;
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

/* Top Navigation - Fixed 60px */
.top-nav {
  height: 60px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  background: white;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.nav-left {
  display: flex;
  gap: 16px;
  align-items: center;
}

.logo {
  font-size: 24px;
}

.branch-select {
  padding: 8px 16px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  background: #1e293b;
  color: white;
  font-weight: 700;
  font-size: 13px;
  outline: none;
  cursor: pointer;
}

.date-picker {
  display: flex;
  align-items: center;
  gap: 8px;
}

.date-input {
  padding: 6px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  outline: none;
}

.calendar-btn {
  padding: 6px;
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 16px;
}

.nav-right {
  display: flex;
  gap: 12px;
}

.btn-create {
  padding: 8px 18px;
  background: #f97316;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: background 0.2s;
}

.btn-create:hover {
  background: #ea580c;
}

.btn-home {
  padding: 8px 18px;
  background: #f1f5f9;
  color: #334155;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-home:hover {
  background: #e2e8f0;
}

/* Main Content - Flex */
.main-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

/* Left Panel - Fixed Width */
.left-panel {
  width: 320px;
  background: white;
  border-right: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
}

.panel-header {
  height: 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 16px;
  background: #1e293b;
  color: white;
  flex-shrink: 0;
}

.sort-by,
.status-filter {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}

.time-tabs {
  height: 40px;
  display: flex;
  gap: 4px;
  padding: 6px 12px;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
  align-items: center;
}

.time-tab {
  flex: 1;
  padding: 6px 4px;
  border: 1px solid #d1d5db;
  border-radius: 4px;
  background: white;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
  text-align: center;
  color: #4b5563;
  transition: all 0.2s;
}

.time-tab.active {
  background: #f97316;
  color: white;
  border-color: #f97316;
}

/* Reservations List - Scrollable */
.reservations-list {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #94a3b8;
  font-weight: 600;
}

.empty-icon {
  font-size: 40px;
  margin-bottom: 8px;
}

.reservation-item {
  padding: 10px 12px;
  background: #f8fafc;
  border-radius: 6px;
  margin-bottom: 8px;
  cursor: pointer;
  border: 1px solid #e2e8f0;
  border-left: 4px solid transparent;
  transition: all 0.2s;
}

.reservation-item:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.reservation-item.selected {
  background: #fff7ed;
  border-color: #ffedd5;
  border-left-color: #f97316;
}

.reservation-item.cancelled {
  background: #fee2e2;
  color: #991b1b;
}

.item-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.time-badge {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 800;
  color: #f97316;
}

.reservation-code {
  font-size: 11px;
  color: #64748b;
  font-weight: 600;
}

.item-middle {
  margin-bottom: 6px;
}

.guest-info {
  font-size: 11px;
  color: #64748b;
  font-weight: 700;
  margin-bottom: 4px;
  display: flex;
  gap: 8px;
}

.customer-name {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.customer-name.vip {
  text-decoration: underline;
}

.item-contact {
  font-size: 11px;
  color: #64748b;
  font-weight: 600;
  margin-bottom: 6px;
}

.item-status {
  margin-bottom: 4px;
}

.status-badge {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 10px;
  font-weight: 700;
  display: inline-block;
}

.status-new {
  background: #fef3c7;
  color: #92400e;
}

.status-confirmed {
  background: #dcfce7;
  color: #166534;
}

.status-completed {
  background: #dbeafe;
  color: #1e40af;
}

.status-cancelled {
  background: #fee2e2;
  color: #991b1b;
}

.item-notes {
  font-size: 11px;
  color: #64748b;
  margin-top: 4px;
  padding-top: 4px;
  border-top: 1px dashed #e2e8f0;
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Right Panel - Flex */
.right-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #f8fafc;
}

/* Customer Section - Compact */
.customer-section.compact {
  padding: 12px 20px;
  background: white;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.info-grid {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 20px;
  align-items: center;
}

.avatar {
  width: 60px;
}

.avatar-circle {
  width: 60px;
  height: 60px;
  background: #f1f5f9;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  border: 1px solid #cbd5e1;
}

.info-fields-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px 16px;
  flex: 1;
}

.field-row-compact {
  display: flex;
  align-items: center;
  gap: 12px;
}

.field-label {
  width: 90px;
  font-size: 12px;
  font-weight: 700;
  color: #334155;
  flex-shrink: 0;
}

.required {
  color: #ef4444;
}

.field-input {
  flex: 1;
  padding: 6px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 13px;
  outline: none;
  min-width: 0;
}

.field-input:focus {
  border-color: #f97316;
}

.field-input.error {
  border-color: #ef4444;
}

.error-text {
  color: #ef4444;
  font-size: 11px;
  margin-left: 8px;
}

.input-group {
  flex: 1;
  display: flex;
  gap: 6px;
  min-width: 0;
}

.search-btn {
  padding: 6px 10px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
}

.checkbox-input {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #f97316;
}

.source-section {
  min-width: 250px;
}

.source-label {
  display: block;
  font-size: 12px;
  font-weight: 700;
  margin-bottom: 8px;
  color: #334155;
}

.source-buttons {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 6px;
}

.source-btn {
  padding: 6px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background: white;
  font-size: 11px;
  font-weight: 700;
  color: #4b5563;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
}

.source-btn:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.source-btn.active {
  background: #f97316;
  color: white;
  border-color: #f97316;
}

/* Tabs Section */
.tabs-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: white;
  margin: 12px 20px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.tabs-nav {
  display: flex;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.tab-btn {
  padding: 10px 20px;
  background: transparent;
  border: none;
  border-bottom: 3px solid transparent;
  font-size: 13px;
  font-weight: 700;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s;
}

.tab-btn:hover {
  color: #f97316;
}

.tab-btn.active {
  background: white;
  color: #f97316;
  border-bottom-color: #f97316;
}

.tab-content {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.tab-panel {
  max-width: 800px;
}

/* Compact Form Layout */
.form-compact-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-row-3col {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.form-row-4col {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.form-row-2col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-group.full-width {
  width: 100%;
}

.form-label {
  font-size: 11px;
  font-weight: 700;
  color: #334155;
}

.input-with-btn {
  display: flex;
  gap: 4px;
}

.form-input {
  flex: 1;
  padding: 6px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 13px;
  outline: none;
  min-width: 0;
}

.form-input:focus {
  border-color: #f97316;
}

.icon-btn {
  padding: 6px 10px;
  background: #e0f2fe;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  font-size: 13px;
}

.counter-input {
  display: flex;
  align-items: center;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  overflow: hidden;
  width: fit-content;
}

.counter-btn {
  width: 32px;
  height: 32px;
  background: #f8fafc;
  border: none;
  cursor: pointer;
  font-size: 16px;
  font-weight: bold;
  transition: all 0.2s;
}

.counter-btn:hover:not(:disabled) {
  background: #f1f5f9;
}

.counter-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.counter-value {
  width: 44px;
  text-align: center;
  border: none;
  font-size: 13px;
  font-weight: 700;
  outline: none;
}

.party-types {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.type-btn {
  padding: 6px 10px;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  background: white;
  font-size: 11px;
  font-weight: 700;
  color: #4b5563;
  cursor: pointer;
  transition: all 0.2s;
}

.type-btn:hover {
  border-color: #f97316;
  color: #f97316;
}

.type-btn.active {
  background: #fff7ed;
  border-color: #f97316;
  color: #f97316;
}

.form-textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 13px;
  resize: vertical;
  font-family: inherit;
  outline: none;
}

.form-textarea:focus {
  border-color: #f97316;
}

.status-select {
  padding: 6px 10px;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  background: #1e293b;
  color: white;
  font-weight: 700;
  font-size: 13px;
  outline: none;
  cursor: pointer;
}

.extended-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.extended-grid-2col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.extended-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.extended-field label {
  font-size: 11px;
  font-weight: 700;
  color: #374151;
}

.readonly-input {
  padding: 8px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background: #f9fafb;
  font-size: 13px;
  outline: none;
}

.wip-message {
  text-align: center;
  padding: 30px 20px;
  background: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 8px;
  color: #b45309;
  font-size: 13px;
  font-weight: 700;
}

/* Footer - Fixed 50px */
.main-footer {
  height: 50px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  background: #1a1a2e;
  color: white;
  flex-shrink: 0;
}

.footer-info {
  display: flex;
  gap: 24px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.info-item .label {
  font-size: 10px;
  opacity: 0.8;
}

.info-item .value {
  font-size: 13px;
  font-weight: 800;
  color: #f97316;
}

.footer-actions {
  display: flex;
  gap: 12px;
}

.btn-save {
  padding: 8px 16px;
  background: #f97316;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}

.btn-save:hover:not(:disabled) {
  background: #ea580c;
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-save.update {
  background: #10b981;
}

.btn-save.update:hover:not(:disabled) {
  background: #059669;
}

/* Bottom Navigation - Fixed 60px */
.bottom-nav {
  height: 60px;
  display: flex;
  background: white;
  border-top: 1px solid #e2e8f0;
  flex-shrink: 0;
  align-items: center;
}

.nav-item {
  flex: 1;
  height: 100%;
  background: transparent;
  border: none;
  border-bottom: 3px solid transparent;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  color: #64748b;
  transition: all 0.2s;
}

.nav-item:hover {
  color: #f97316;
}

.nav-item.active {
  border-bottom-color: #f97316;
  color: #f97316;
  background: #fff7ed;
}

.nav-icon {
  font-size: 18px;
}

.nav-label {
  font-size: 11px;
  font-weight: 700;
}

/* Responsive */
@media (max-width: 1024px) {
  .left-panel {
    width: 280px;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .avatar {
    display: none;
  }
  
  .source-section {
    width: 100%;
  }

  .form-row-4col {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .main-content {
    flex-direction: column;
    height: calc(100vh - 170px);
    overflow-y: auto;
  }
  
  .left-panel {
    width: 100%;
    height: 250px;
    border-right: none;
    border-bottom: 1px solid #e2e8f0;
  }

  .info-fields-grid {
    grid-template-columns: 1fr;
  }
  
  .form-row-3col {
    grid-template-columns: 1fr;
  }
  
  .form-row-4col {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .form-row-2col {
    grid-template-columns: 1fr;
  }
}
</style>
