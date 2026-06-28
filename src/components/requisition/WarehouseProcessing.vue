<!-- WarehouseProcessing.vue -->
<template>
  <div class="warehouse-processing" role="dialog" aria-modal="true" aria-labelledby="processing-title">
    <div class="processing-header">
      <h2 id="processing-title" class="processing-title">XỬ LÝ YÊU CẦU XUẤT KHO #{{ requisition.requisition_number }}</h2>
      <button class="btn-back" @click="$emit('back')">
        ⬅ Quay lại
      </button>
    </div>

    <!-- Requisition info -->
    <div class="info-section grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
      <div class="info-group">
        <span class="info-label">Ngày yêu cầu:</span>
        <span class="info-value font-mono">{{ new Date(requisition.created_at).toLocaleString() }}</span>
      </div>
      <div class="info-group">
        <span class="info-label">Loại phiếu:</span>
        <span class="info-value uppercase">📍 {{ requisition.type === 'OUTBOUND' ? 'Xuất kho' : (requisition.type === 'INBOUND' ? 'Nhập kho' : 'Trả hàng') }}</span>
      </div>
      <div class="info-group">
        <span class="info-label">Người tạo yêu cầu:</span>
        <span class="info-value">👤 {{ requisition.requested_by_profile?.raw_user_meta_data?.full_name || 'Nhân viên' }}</span>
      </div>
      <div class="info-group col-span-2">
        <span class="info-label">Ghi chú từ Bếp:</span>
        <span class="info-value italic text-yellow-100">"{{ requisition.note || 'Không có ghi chú' }}"</span>
      </div>
    </div>

    <!-- Inventory Checklist -->
    <div class="checklist-section">
      <h3 class="section-title">Kiểm Tra Tồn Kho & Xác Nhận Giao Hàng</h3>
      
      <div class="space-y-4">
        <div v-for="item in processedItems" :key="item.id" class="processing-item">
          <div class="item-header flex items-center gap-3">
            <span class="item-name font-bold text-foreground text-base">{{ item.name }}</span>
            <span class="ml-auto text-sm text-muted-foreground">
              Yêu cầu: <strong class="text-foreground">{{ item.requestedQty }} {{ item.unit }}</strong>
            </span>
          </div>

          <!-- Stock verification panel -->
          <div class="verification-panel grid grid-cols-1 md:grid-cols-3 gap-4 mt-3 pt-3 border-t border-border">
            <div>
              <span class="stock-label">Tồn kho chính hiện tại:</span>
              <div class="text-sm font-semibold text-foreground mt-1">
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
                <span class="text-xs text-muted-foreground font-bold uppercase">{{ item.unit }}</span>
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
    <div class="summary-section mt-6 p-4 bg-background rounded-xl border border-border">
      <div class="flex justify-between items-center text-sm font-semibold">
        <span>Tổng số lượng mặt hàng:</span>
        <span>{{ processedItems.length }} món</span>
      </div>
      <div class="flex justify-between items-center text-sm font-semibold mt-2 text-green-600">
        <span>Mặt hàng đủ điều kiện giao:</span>
        <span>{{ processedItems.filter(i => i.isAvailable).length }} / {{ processedItems.length }}</span>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="action-buttons flex gap-4 justify-end mt-6 pt-4 border-t border-border">
      <button class="proc-btn btn-reject bg-[#F44336]" @click="handleRejectRequisition">
        TỪ CHỐI YÊU CẦU
      </button>
      <button class="proc-btn btn-approve bg-[#4CAF50]" @click="approveAndShip">
        DUYỆT & TIẾN HÀNH XỬ LÝ
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { useRequisition, type Requisition } from '@/composables/useRequisition';
import { useInventory } from '@/composables/useInventory';
import Swal from 'sweetalert2';

const props = defineProps<{
  requisition: Requisition;
}>();

const emit = defineEmits<{
  (e: 'back'): void;
  (e: 'success'): void;
}>();

const { approveRequisition, rejectRequisition } = useRequisition();
const { inventory } = useInventory();

// Local processed item tracking
const processedItems = ref<Array<{
  id: string; // requisition_item_id
  ingredient_id: string;
  name: string;
  unit: string;
  requestedQty: number;
  deliveredQty: number;
  mainStock: number;
  isAvailable: boolean;
  proposedSubstitute: string;
}>>([]);

watch(() => props.requisition, (newReq) => {
  if (!newReq.requisition_items) return;
  
  processedItems.value = newReq.requisition_items.map(item => {
    const invItem = inventory.value.find(i => i.ingredient_id === item.ingredient_id);
    const mStock = invItem ? invItem.quantity : 0;
    
    return {
      id: item.id,
      ingredient_id: item.ingredient_id,
      name: item.ingredients?.name_vi || 'Sản phẩm',
      unit: item.unit,
      requestedQty: item.requested_quantity,
      deliveredQty: item.requested_quantity, // default to requested qty
      mainStock: mStock,
      isAvailable: mStock >= item.requested_quantity, // default true if we have enough
      proposedSubstitute: ''
    };
  });
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

const handleRejectRequisition = async () => {
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
    try {
      await rejectRequisition(props.requisition.id, text);
      Swal.fire({
        icon: 'success',
        title: 'Đã từ chối',
        text: 'Yêu cầu xuất kho đã bị từ chối thành công!',
        background: '#2D2D2D',
        color: '#FFF',
        confirmButtonColor: '#F44336'
      });
      emit('success');
    } catch (err: any) {
      Swal.fire('Lỗi', err.message, 'error');
    }
  }
};

const approveAndShip = async () => {
  const hasShortage = processedItems.value.some(item => !item.isAvailable);

  const approvedQtys = processedItems.value.map(item => ({
    requisition_item_id: item.id,
    approved_quantity: item.isAvailable ? item.deliveredQty : 0
  }));

  try {
    await approveRequisition(props.requisition.id, approvedQtys);
    
    if (hasShortage) {
      Swal.fire({
        title: 'Duyệt thành công (Có thiếu hàng)',
        text: 'Phiếu yêu cầu đã được duyệt và bắt đầu giao tới bếp. Có một số mặt hàng không đủ sẽ không được giao.',
        icon: 'info',
        background: '#2D2D2D',
        color: '#FFF',
        confirmButtonColor: '#FF9800'
      });
    } else {
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
  } catch (err: any) {
    Swal.fire('Lỗi', err.message, 'error');
  }
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
