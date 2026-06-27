<!-- WarehouseProcessing.vue -->
<template>
  <div class="warehouse-processing" role="dialog" aria-modal="true" aria-labelledby="processing-title">
    <div class="processing-header">
      <h2 id="processing-title" class="processing-title">XỬ LÝ YÊU CẦU XUẤT KHO #{{ requisition.id }}</h2>
      <button class="btn-back" @click="$emit('back')">
        ⬅ Quay lại
      </button>
    </div>

    <!-- Requisition info -->
    <div class="info-section grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
      <div class="info-group">
        <span class="info-label">Ngày yêu cầu:</span>
        <span class="info-value font-mono">{{ requisition.date }}</span>
      </div>
      <div class="info-group">
        <span class="info-label">Bộ phận yêu cầu:</span>
        <span class="info-value">📍 {{ requisition.station }}</span>
      </div>
      <div class="info-group">
        <span class="info-label">Người tạo yêu cầu:</span>
        <span class="info-value">👤 {{ requisition.actor }}</span>
      </div>
      <div class="info-group">
        <span class="info-label">Mức độ ưu tiên:</span>
        <span class="info-value font-bold" :style="{ color: getPriorityColor(requisition.priority) }">
          {{ getPriorityLabel(requisition.priority) }}
        </span>
      </div>
      <div class="info-group col-span-2">
        <span class="info-label">Ghi chú từ Bếp:</span>
        <span class="info-value italic text-yellow-100">"{{ requisition.notes || 'Không có ghi chú' }}"</span>
      </div>
    </div>

    <!-- Inventory Checklist -->
    <div class="checklist-section">
      <h3 class="section-title">Kiểm Tra Tồn Kho & Xác Nhận Giao Hàng</h3>
      
      <div class="space-y-4">
        <div v-for="item in processedItems" :key="item.id" class="processing-item">
          <div class="item-header flex items-center gap-3">
            <span class="item-icon">{{ item.icon }}</span>
            <span class="item-name font-bold text-white text-base">{{ item.name }}</span>
            <span class="ml-auto text-sm text-gray-400">
              Yêu cầu: <strong class="text-white">{{ item.requestedQty }} {{ item.unit }}</strong>
            </span>
          </div>

          <!-- Stock verification panel -->
          <div class="verification-panel grid grid-cols-1 md:grid-cols-3 gap-4 mt-3 pt-3 border-t border-[#404040]">
            <div>
              <span class="stock-label">Tồn kho chính hiện tại:</span>
              <div class="text-sm font-semibold text-gray-200 mt-1">
                {{ item.mainStock }} {{ item.unit }}
              </div>
            </div>

            <!-- Availabilities switcher -->
            <div class="flex flex-col gap-1.5">
              <span class="stock-label">Độ sẵn có:</span>
              <div class="flex gap-2">
                <button 
                  class="choice-btn choice-ok flex-1 py-1 text-xs font-bold rounded"
                  :class="{ active: item.isAvailable }"
                  @click="setAvailability(item.id, true)"
                >
                  Đủ hàng
                </button>
                <button 
                  class="choice-btn choice-no flex-1 py-1 text-xs font-bold rounded"
                  :class="{ active: !item.isAvailable }"
                  @click="setAvailability(item.id, false)"
                >
                  Thiếu hàng
                </button>
              </div>
            </div>

            <!-- Shipped / Substitute options -->
            <div class="flex flex-col gap-1.5">
              <span v-if="item.isAvailable" class="stock-label">Số lượng xuất giao:</span>
              <span v-else class="stock-label">Giải pháp đề xuất:</span>
              
              <div v-if="item.isAvailable" class="flex items-center gap-2">
                <label :for="`ship-qty-${item.id}`" class="sr-only">Số lượng giao</label>
                <input 
                  :id="`ship-qty-${item.id}`"
                  v-model.number="item.deliveredQty"
                  type="number"
                  min="0"
                  :max="item.mainStock"
                  class="qty-deliver-input w-full"
                />
                <span class="text-xs text-gray-300 font-bold uppercase">{{ item.unit }}</span>
              </div>
              <div v-else>
                <label :for="`sub-${item.id}`" class="sr-only">Đề xuất thay thế</label>
                <input 
                  :id="`sub-${item.id}`"
                  v-model="item.proposedSubstitute"
                  type="text"
                  placeholder="Ví dụ: Thay bằng Nước lẩu Tom Yum..."
                  class="qty-deliver-input w-full text-xs font-normal placeholder-gray-500"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary of Processing -->
    <div class="summary-section mt-6 p-4 bg-[#1A1A1A] rounded-xl border border-[#404040]">
      <div class="flex justify-between items-center text-sm font-semibold">
        <span>Tổng số lượng mặt hàng:</span>
        <span>{{ processedItems.length }} món</span>
      </div>
      <div class="flex justify-between items-center text-sm font-semibold mt-2 text-[#4CAF50]">
        <span>Mặt hàng đủ điều kiện giao:</span>
        <span>{{ processedItems.filter(i => i.isAvailable).length }} / {{ processedItems.length }}</span>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="action-buttons flex gap-4 justify-end mt-6 pt-4 border-t border-[#404040]">
      <button class="proc-btn btn-reject bg-[#F44336]" @click="rejectRequisition">
        TỪ CHỐI YÊU CẦU
      </button>
      <button class="proc-btn btn-reverify bg-[#2196F3]" @click="requestReverification">
        YÊU CẦU XÁC NHẬN LẠI
      </button>
      <button class="proc-btn btn-approve bg-[#4CAF50]" @click="approveAndShip">
        DUYỆT & GIAO HÀNG
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import type { Requisition } from '@/stores/kitchen';
import { REQUISITION_COLORS } from '@/design-system/requisitionTokens';
import { useKitchenStore } from '@/stores/kitchen';
import Swal from 'sweetalert2';

const props = defineProps<{
  requisition: Requisition;
}>();

const emit = defineEmits<{
  (e: 'back'): void;
  (e: 'success'): void;
}>();

const kitchenStore = useKitchenStore();

// Local processed item tracking
const processedItems = ref<Array<{
  id: string;
  name: string;
  icon: string;
  unit: string;
  requestedQty: number;
  deliveredQty: number;
  mainStock: number;
  isAvailable: boolean;
  proposedSubstitute: string;
}>>([]);

watch(() => props.requisition, (newReq) => {
  processedItems.value = newReq.items.map(item => ({
    id: item.id,
    name: item.name,
    icon: item.icon,
    unit: item.unit,
    requestedQty: item.requestedQty,
    deliveredQty: item.requestedQty, // default to requested qty
    mainStock: item.mainStock,
    isAvailable: item.mainStock >= item.requestedQty, // default true if we have enough
    proposedSubstitute: item.proposedSubstitute || ''
  }));
}, { immediate: true });

const setAvailability = (id: string, avail: boolean) => {
  const found = processedItems.value.find(i => i.id === id);
  if (found) {
    found.isAvailable = avail;
    if (!avail) {
      found.deliveredQty = 0;
    } else {
      found.deliveredQty = found.requestedQty;
    }
  }
};

const getPriorityLabel = (pri: string) => {
  if (pri === 'low') return 'Thấp';
  if (pri === 'high') return 'Cao';
  return 'Trung bình';
};

const getPriorityColor = (pri: 'low' | 'medium' | 'high') => {
  return REQUISITION_COLORS.priority[pri];
};

const rejectRequisition = async () => {
  const { value: text } = await Swal.fire({
    title: 'Từ chối yêu cầu xuất kho',
    input: 'textarea',
    inputPlaceholder: 'Nhập lý do từ chối phiếu yêu cầu này...',
    inputAttributes: {
      'aria-label': 'Lý do từ chối'
    },
    showCancelButton: true,
    confirmButtonText: 'Xác nhận từ chối',
    cancelButtonText: 'Hủy bỏ',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#F44336',
    cancelButtonColor: '#424242'
  });

  if (text) {
    kitchenStore.updateRequisitionStatus(props.requisition.id, 'rejected', 'Thủ kho Nam', text);
    Swal.fire({
      icon: 'success',
      title: 'Đã từ chối',
      text: 'Yêu cầu xuất kho đã bị từ chối thành công!',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#F44336'
    });
    emit('success');
  }
};

const requestReverification = () => {
  Swal.fire({
    title: 'Yêu cầu xác nhận lại',
    text: 'Gửi yêu cầu phản hồi lại cho Bếp để xác nhận tính khả dụng thay thế?',
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#2196F3',
    cancelButtonColor: '#424242'
  }).then((res) => {
    if (res.isConfirmed) {
      // Logic for reverification can set back status or log an audit entry
      kitchenStore.updateRequisitionStatus(props.requisition.id, 'pending', 'Thủ kho Nam', 'Yêu cầu bếp phản hồi lại các đề xuất thay thế nguyên liệu thiếu hụt.');
      Swal.fire({
        title: 'Đã gửi phản hồi',
        text: 'Bếp trưởng sẽ nhận được thông báo điều chỉnh yêu cầu.',
        icon: 'success',
        background: '#2D2D2D',
        color: '#FFF'
      });
      emit('success');
    }
  });
};

const approveAndShip = () => {
  const hasShortage = processedItems.value.some(item => !item.isAvailable);

  // Update deliveries on store
  processedItems.value.forEach(item => {
    kitchenStore.updateRequisitionItemDelivery(
      props.requisition.id,
      item.id,
      item.deliveredQty,
      item.isAvailable ? 'approved' : 'rejected',
      item.isAvailable ? undefined : `Thiếu hàng. Đề xuất: ${item.proposedSubstitute}`
    );
  });

  if (hasShortage) {
    const reasons = processedItems.value
      .filter(i => !i.isAvailable)
      .map(i => `${i.name} -> Đề xuất: ${i.proposedSubstitute || 'Chờ phản hồi'}`)
      .join(', ');

    kitchenStore.updateRequisitionStatus(props.requisition.id, 'substitute_proposed', 'Thủ kho Nam', reasons);

    Swal.fire({
      title: 'Đã gửi đề xuất thay thế',
      text: 'Do kho thiếu hàng, đề xuất thay thế đã được gửi tới Bếp trưởng phê duyệt!',
      icon: 'info',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#FF9800'
    });
  } else {
    kitchenStore.updateRequisitionStatus(props.requisition.id, 'approved', 'Thủ kho Nam');

    Swal.fire({
      title: 'Duyệt thành công',
      text: 'Phiếu yêu cầu đã được duyệt và bắt đầu giao tới bếp!',
      icon: 'success',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#4CAF50'
    });
  }
  
  emit('success');
};
</script>

<style scoped>
.warehouse-processing {
  background: #2D2D2D;
  border-radius: 16px;
  padding: 24px;
  max-width: 900px;
  width: 95%;
  margin: 0 auto;
}

.processing-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #404040;
}

.processing-title {
  font-size: 20px;
  font-weight: 700;
  color: #FFFFFF;
}

.btn-back {
  background: #424242;
  color: white;
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-back:hover {
  background: #616161;
}

/* Info Section */
.info-section {
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 12px;
  padding: 16px;
}

.info-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 11px;
  color: #B0B0B0;
  text-transform: uppercase;
}

.info-value {
  font-size: 14px;
  color: #E0E0E0;
  font-weight: 600;
}

/* Checklist items */
.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #FF9800;
  margin-bottom: 16px;
  text-transform: uppercase;
}

.processing-item {
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 10px;
  padding: 16px;
}

.stock-label {
  font-size: 11px;
  color: #B0B0B0;
  text-transform: uppercase;
}

.choice-btn {
  background: #2D2D2D;
  color: #B0B0B0;
  border: 1px solid #404040;
  cursor: pointer;
  transition: all 0.2s ease;
}

.choice-btn.active.choice-ok {
  background: rgba(76, 175, 80, 0.2);
  color: #4CAF50;
  border-color: #4CAF50;
}

.choice-btn.active.choice-no {
  background: rgba(244, 67, 54, 0.2);
  color: #F44336;
  border-color: #F44336;
}

.qty-deliver-input {
  padding: 8px 12px;
  background: #2D2D2D;
  border: 1px solid #404040;
  border-radius: 6px;
  color: #FFFFFF;
  font-size: 14px;
  font-weight: 600;
  outline: none;
  transition: border-color 0.2s ease;
}

.qty-deliver-input:focus {
  border-color: #FF9800;
}

/* Actions */
.proc-btn {
  padding: 12px 20px;
  border: none;
  border-radius: 8px;
  color: white;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 140px;
}

.proc-btn:hover {
  transform: translateY(-2px);
  opacity: 0.9;
}

.proc-btn:active {
  transform: translateY(0);
}
</style>
