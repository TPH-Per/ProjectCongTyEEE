<template>
  <div class="detail-container">
    <div class="wip-banner">
       Chức năng Quản lý Chi tiết Đặt bàn (Kết nối Database Realtime)
    </div>

    <div v-if="!reservation" class="no-reservation">
      <p>Vui lòng chọn một lượt đặt bàn từ Lịch để xem chi tiết.</p>
    </div>

    <div v-else class="detail-content">
      <h2>Chi tiết đặt bàn #{{ reservationId?.substring(0, 8) }}</h2>
      
      <div class="info-grid">
        <div class="info-item">
          <label>Khách hàng</label>
          <div class="value">{{ reservation.customerName }}</div>
        </div>
        <div class="info-item">
          <label>Số điện thoại</label>
          <div class="value">{{ reservation.customerPhone || 'Chưa cung cấp' }}</div>
        </div>
        <div class="info-item">
          <label>Ngày đặt</label>
          <div class="value">{{ reservation.date }}</div>
        </div>
        <div class="info-item">
          <label>Giờ đặt</label>
          <div class="value">{{ reservation.time }}</div>
        </div>
        <div class="info-item">
          <label>Số khách</label>
          <div class="value">{{ reservation.guests }} người</div>
        </div>
        <div class="info-item">
          <label>Số bàn</label>
          <div class="value">{{ reservation.tables || 'Chưa gán' }} bàn</div>
        </div>
        <div v-if="reservation.notes" class="info-item full-width">
          <label>Ghi chú</label>
          <div class="value notes">{{ reservation.notes }}</div>
        </div>
        <div class="info-item">
          <label>Trạng thái</label>
          <div class="value">
            <span :class="['status-text', reservation.status]">{{ reservation.status === 'confirmed' ? 'Đã xác nhận' : reservation.status === 'dining' ? 'Đang dùng bữa' : 'Chờ xác nhận' }}</span>
          </div>
        </div>
      </div>

      <div class="actions">
        <button 
          v-if="reservation.status === 'pending'" 
          class="btn btn-primary" 
          @click="handleUpdateStatus('CONFIRMED')"
          :disabled="loading"
        >
          Xác nhận Đặt bàn
        </button>
        <button 
          v-if="reservation.status === 'confirmed'" 
          class="btn btn-primary" 
          @click="handleUpdateStatus('Dining')"
          :disabled="loading"
        >
          Xếp bàn & Dùng bữa
        </button>
        <button 
          v-if="reservation.status !== 'dining'" 
          class="btn btn-danger" 
          @click="handleUpdateStatus('Cancelled')"
          :disabled="loading"
        >
          Hủy / No Show
        </button>
        <button class="btn btn-secondary" @click="goBack">Quay lại</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useHallStore } from '@/stores/hallStore'
import { useReservation } from '@/composables/useReservation'
import Swal from 'sweetalert2'

const props = defineProps<{
  reservationId: string | null
}>()

const hallStore = useHallStore()
const { updateStatus } = useReservation()
const loading = ref(false)

const reservation = computed(() => {
  if (!props.reservationId) return null
  return hallStore.reservations.find(r => r.id === props.reservationId)
})

async function handleUpdateStatus(newStatus: 'CONFIRMED' | 'Dining' | 'Cancelled') {
  if (!props.reservationId) return
  loading.value = true
  try {
    // For Dining/CONFIRMED, updateStatus handles it.
    await updateStatus(props.reservationId, newStatus as any)
    
    await Swal.fire({
      title: 'Thành công',
      text: 'Cập nhật trạng thái đặt bàn thành công!',
      icon: 'success',
      timer: 1500,
      showConfirmButton: false
    })

    // Refresh data and go back to calendar
    await hallStore.fetchReservations()
    hallStore.setCurrentView('calendar')
  } catch (error: any) {
    console.error('Failed to update status:', error)
    await Swal.fire({
      title: 'Lỗi',
      text: error.message || 'Không thể cập nhật trạng thái đặt bàn.',
      icon: 'error'
    })
  } finally {
    loading.value = false
  }
}

function goBack() {
  hallStore.setCurrentView('calendar')
}
</script>

<style scoped>
.detail-container {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.wip-banner {
  background: #fff7ed;
  border: 1px solid #ffedd5;
  border-radius: 8px;
  padding: 12px;
  text-align: center;
  font-size: 14px;
  font-weight: 700;
  color: #c2410c;
  margin-bottom: 24px;
}

.no-reservation {
  text-align: center;
  padding: 40px 20px;
  color: #6b7280;
  font-weight: 600;
}

.detail-content h2 {
  font-size: 18px;
  font-weight: 800;
  color: #111827;
  margin-bottom: 20px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.info-item {
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.info-item.full-width {
  grid-column: span 2;
}

.info-item label {
  font-size: 11px;
  color: #6b7280;
  font-weight: 700;
  text-transform: uppercase;
}

.info-item .value {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin-top: 4px;
}

.info-item .value.notes {
  font-weight: 500;
  font-style: italic;
  color: #374151;
}

.status-text {
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 700;
}

.status-text.confirmed {
  background: #d1fae5;
  color: #065f46;
}

.status-text.dining {
  background: #dbeafe;
  color: #1e40af;
}

.status-text.pending {
  background: #fef3c7;
  color: #92400e;
}

.actions {
  display: flex;
  gap: 12px;
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: #f97316;
  color: white;
}

.btn-primary:hover {
  background: #ea580c;
}

.btn-secondary {
  background: #f3f4f6;
  color: #4b5563;
  border: 1px solid #e5e7eb;
}

.btn-secondary:hover {
  background: #e5e7eb;
}

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn-danger:hover {
  background: #dc2626;
}
</style>
