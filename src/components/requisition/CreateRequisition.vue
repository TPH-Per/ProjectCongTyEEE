<!-- CreateRequisition.vue -->
<template>
  <div class="requisition-modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
    <div class="modal-header">
      <h2 id="modal-title" class="modal-title">TẠO PHIẾU YÊU CẦU XUẤT KHO</h2>
      <button 
        class="close-btn" 
        @click="$emit('close')" 
        aria-label="Đóng biểu mẫu"
      >
        &times;
      </button>
    </div>

    <!-- Form Body -->
    <div class="form-body space-y-6">
      <!-- Thông tin cơ bản -->
      <div class="form-section">
        <h3 class="section-title">Thông Tin Cơ Bản</h3>
        <div class="form-grid">
          <div class="form-group">
            <span class="form-label">Người yêu cầu</span>
            <input 
              v-model="actor" 
              type="text" 
              disabled 
              class="form-input opacity-70 cursor-not-allowed" 
            />
          </div>
          <div class="form-group">
            <label for="station-select" class="form-label">Bộ phận bếp yêu cầu</label>
            <select 
              id="station-select" 
              v-model="station" 
              class="form-select"
            >
              <option value="Bếp Nướng">Bếp Nướng</option>
              <option value="Bếp Lẩu">Bếp Lẩu</option>
              <option value="Bếp Chiên">Bếp Chiên</option>
              <option value="Bếp Lạnh">Bếp Lạnh</option>
              <option value="Quầy Bar">Quầy Bar</option>
            </select>
          </div>
        </div>

        <div class="form-grid mt-4">
          <div class="form-group">
            <span class="form-label">Mức độ ưu tiên</span>
            <div class="priority-group" role="radiogroup" aria-label="Mức độ ưu tiên">
              <label class="priority-option low" :class="{ active: priority === 'low' }">
                <input 
                  v-model="priority" 
                  type="radio" 
                  value="low" 
                  name="priority" 
                />
                <span>Thấp</span>
              </label>
              <label class="priority-option medium" :class="{ active: priority === 'medium' }">
                <input 
                  v-model="priority" 
                  type="radio" 
                  value="medium" 
                  name="priority" 
                />
                <span>Trung bình</span>
              </label>
              <label class="priority-option high" :class="{ active: priority === 'high' }">
                <input 
                  v-model="priority" 
                  type="radio" 
                  value="high" 
                  name="priority" 
                />
                <span>Cao</span>
              </label>
            </div>
          </div>
          <div class="form-group">
            <label for="notes-textarea" class="form-label">Ghi chú yêu cầu</label>
            <textarea 
              id="notes-textarea" 
              v-model="notes" 
              placeholder="Nhập ghi chú xuất kho (ví dụ: cần trước giờ cao điểm, hàng thay thế...)" 
              rows="2" 
              class="form-textarea"
            ></textarea>
          </div>
        </div>
      </div>

      <!-- Phân Tích & Gợi Ý Tự Động (Prep List & Forecast) -->
      <div class="form-section bg-[#1A1A1A] p-4 rounded-xl border border-[#404040]">
        <div class="flex justify-between items-center mb-3">
          <h4 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider flex items-center gap-2">
            📊 Phân Tích Nhu Cầu & Dự Báo (Prep & Forecast)
          </h4>
          <span class="bg-[#2196F3]/20 text-[#2196F3] text-[10px] px-2.5 py-0.5 rounded font-bold uppercase">
            AI Assistant
          </span>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
          <!-- Prep list correlation -->
          <div class="p-3 bg-[#2D2D2D]/50 rounded-lg border border-[#404040]">
            <span class="font-bold text-gray-300 block mb-1">📋 Đối chiếu Prep List ca này:</span>
            <p class="text-gray-400">Hạng mục sơ chế chưa hoàn tất: <strong class="text-yellow-500">Cắt thái rau thập cẩm</strong>, <strong class="text-yellow-500">Nấu nước lẩu Sukiyaki</strong>. Đề xuất chuẩn bị thêm nguyên vật liệu thô.</p>
          </div>
          <!-- Sales Forecast -->
          <div class="p-3 bg-[#2D2D2D]/50 rounded-lg border border-[#404040]">
            <span class="font-bold text-gray-300 block mb-1">📈 Dự báo Doanh thu & Khách đặt:</span>
            <p class="text-gray-400">Khách đặt: Tiệc buffet nướng 30 người lúc 19:00. Nhu cầu thịt bò Wagyu dự báo tăng <strong class="text-orange-500">+2.0 kg</strong> so với ngày thường.</p>
          </div>
        </div>

        <!-- Suggestions recommendation -->
        <div class="mt-4 p-3 bg-[#FF9800]/10 border border-[#FF9800]/30 rounded-lg flex items-center justify-between flex-wrap gap-2">
          <div class="text-xs">
            <span class="font-bold text-[#FF9800] block">💡 Đề xuất xuất kho tự động:</span>
            <span class="text-gray-300">Thịt bò Wagyu (5kg: 3kg bù hụt + 2kg dự phòng), Nước lẩu (8L: 5L bù hụt + 3L dự phòng), Tôm sú lớn (3kg bù hụt)</span>
          </div>
          <button 
            type="button"
            class="bg-[#FF9800] hover:bg-[#F57C00] text-xs font-bold text-white px-3.5 py-1.5 rounded-lg transition"
            @click="applyAutoSuggestions"
          >
            ⚡ Áp dụng gợi ý
          </button>
        </div>
      </div>

      <!-- Danh sách nguyên liệu -->
      <div class="form-section">
        <h3 class="section-title">Danh Sách Nguyên Liệu Cần Xuất</h3>
        <IngredientSelector 
          :inventory="kitchenStore.inventoryList"
          v-model="selectedItems"
        />
      </div>

      <!-- Summary -->
      <div class="summary-section">
        <div class="summary-row">
          <span>Tổng số mặt hàng đã chọn:</span>
          <span>{{ selectedItems.length }} mặt hàng</span>
        </div>
        <div class="summary-row font-bold text-[#FF9800]">
          <span>Mức độ ưu tiên:</span>
          <span class="uppercase">{{ getPriorityLabel(priority) }}</span>
        </div>
      </div>
    </div>

    <!-- Modal Actions -->
    <div class="modal-actions">
      <button 
        class="modal-btn cancel" 
        @click="$emit('close')"
      >
        HỦY
      </button>
      <button 
        class="modal-btn draft bg-[#2196F3] text-white" 
        @click="saveAsDraft"
      >
        LƯU NHÁP
      </button>
      <button 
        class="modal-btn submit bg-[#FF9800] text-white" 
        :disabled="selectedItems.length === 0"
        :class="{ 'opacity-50 cursor-not-allowed': selectedItems.length === 0 }"
        @click="submitRequest"
      >
        GỬI YÊU CẦU
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useKitchenStore } from '@/stores/kitchen';
import IngredientSelector from './IngredientSelector.vue';
import Swal from 'sweetalert2';

const applyAutoSuggestions = () => {
  selectedItems.value = [
    { id: 'inv-1', requestedQty: 5 },
    { id: 'inv-2', requestedQty: 8 },
    { id: 'inv-6', requestedQty: 3 }
  ];
  
  Swal.fire({
    icon: 'success',
    title: 'Đã áp dụng gợi ý',
    text: 'Đã điền số lượng đề xuất dựa trên phân tích Prep List và Dự báo doanh thu.',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#FF9800',
    timer: 1500,
    showConfirmButton: false
  });
};

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'success'): void;
}>();

const kitchenStore = useKitchenStore();

const actor = ref('Chef Luc');
const station = ref('Bếp Nướng');
const priority = ref<'low' | 'medium' | 'high'>('medium');
const notes = ref('');
const selectedItems = ref<Array<{ id: string; requestedQty: number }>>([]);

const getPriorityLabel = (pri: string) => {
  if (pri === 'low') return 'Thấp';
  if (pri === 'high') return 'Cao';
  return 'Trung bình';
};

const buildItemsPayload = () => {
  return selectedItems.value.map(selected => {
    const invItem = kitchenStore.inventoryList.find(i => i.id === selected.id)!;
    return {
      id: invItem.id,
      name: invItem.name,
      icon: invItem.icon,
      unit: invItem.unit,
      kitchenStock: invItem.kitchenStock,
      mainStock: invItem.mainStock,
      requestedQty: selected.requestedQty,
      deliveredQty: selected.requestedQty, // default to requestedQty
      status: 'pending'
    };
  });
};

const saveAsDraft = () => {
  if (selectedItems.value.length === 0) {
    Swal.fire({
      icon: 'error',
      title: 'Không thể lưu nháp',
      text: 'Vui lòng chọn ít nhất một nguyên liệu trước khi lưu nháp.',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#2196F3'
    });
    return;
  }

  Swal.fire({
    title: 'Lưu nháp thành công',
    text: 'Phiếu yêu cầu xuất kho đã được lưu dưới dạng nháp.',
    icon: 'success',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#2196F3'
  });
  emit('close');
};

const submitRequest = () => {
  if (selectedItems.value.length === 0) return;

  const items = buildItemsPayload();
  kitchenStore.addRequisition({
    station: station.value,
    actor: actor.value,
    priority: priority.value,
    status: 'pending',
    notes: notes.value,
    items
  });

  Swal.fire({
    title: 'Đã gửi yêu cầu',
    text: 'Yêu cầu xuất kho đã được gửi tới Bộ phận Kho thành công!',
    icon: 'success',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#FF9800'
  });
  
  emit('success');
};
</script>

<style scoped>
.requisition-modal {
  background: #2D2D2D;
  border-radius: 16px;
  padding: 24px;
  max-width: 900px;
  width: 95%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #404040;
}

.modal-title {
  font-size: 20px;
  font-weight: 700;
  color: #FFFFFF;
}

.close-btn {
  background: none;
  border: none;
  color: #B0B0B0;
  font-size: 24px;
  cursor: pointer;
  padding: 4px;
  transition: color 0.2s;
}

.close-btn:hover {
  color: #F44336;
}

/* Form Sections */
.form-section {
  margin-bottom: 24px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #FF9800;
  margin-bottom: 16px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #E0E0E0;
}

.form-input,
.form-select,
.form-textarea {
  padding: 10px 14px;
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 8px;
  color: #FFFFFF;
  font-size: 14px;
  transition: all 0.2s ease;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  outline: none;
  border-color: #FF9800;
  box-shadow: 0 0 0 3px rgba(255, 152, 0, 0.2);
}

/* Priority Radio Buttons */
.priority-group {
  display: flex;
  gap: 16px;
  padding: 8px 12px;
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 8px;
  height: 44px;
  align-items: center;
}

.priority-option {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  font-size: 13px;
  color: #B0B0B0;
  font-weight: 600;
  user-select: none;
  flex: 1;
  justify-content: center;
}

.priority-option input[type="radio"] {
  width: 16px;
  height: 16px;
  cursor: pointer;
}

.priority-option.low input:checked {
  accent-color: #4CAF50;
}

.priority-option.medium input:checked {
  accent-color: #FF9800;
}

.priority-option.high input:checked {
  accent-color: #F44336;
}

.priority-option.low input:checked + span {
  color: #4CAF50;
}

.priority-option.medium input:checked + span {
  color: #FF9800;
}

.priority-option.high input:checked + span {
  color: #F44336;
}

/* Summary Section */
.summary-section {
  background: #1A1A1A;
  border-radius: 10px;
  padding: 16px;
  margin: 20px 0;
  border: 1px solid #404040;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 0;
}

.summary-row:first-child {
  border-bottom: 1px solid #404040;
  padding-bottom: 8px;
  margin-bottom: 8px;
}

/* Action Buttons */
.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 2px solid #404040;
}

.modal-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
}

.modal-btn.cancel {
  background: #424242;
  color: white;
}

.modal-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.modal-btn:active {
  transform: translateY(0);
}
</style>
