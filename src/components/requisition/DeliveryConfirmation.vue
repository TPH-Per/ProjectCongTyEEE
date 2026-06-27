<!-- DeliveryConfirmation.vue -->
<template>
  <div class="delivery-confirmation bg-card rounded-2xl p-6 max-w-[900px] margin-auto relative overflow-hidden">
    
    <!-- SYSTEM UPDATE SCREEN (PHASE 4) -->
    <div v-if="showSystemUpdate" class="system-update-overlay absolute inset-0 bg-background z-40 flex flex-col items-center justify-center p-8 text-center animate-fade-in">
      <div class="success-checkmark mb-6">
        <div class="check-icon">
          <span class="icon-line line-tip animate-check-tip"></span>
          <span class="icon-line line-long animate-check-long"></span>
          <div class="icon-circle"></div>
          <div class="icon-fix"></div>
        </div>
      </div>
      
      <h3 class="text-2xl font-black text-foreground uppercase tracking-wider mb-2">ĐÃ CẬP NHẬT HỆ THỐNG THÀNH CÔNG</h3>
      <p class="text-sm text-gray-400 mb-6 max-w-md">Phiếu yêu cầu #{{ requisition.id }} đã hoàn tất bàn giao. Quy trình tự động hóa kho & tài chính đã thực hiện:</p>
      
      <!-- Stepper of updates -->
      <div class="update-steps text-left w-full max-w-md bg-card/60 border border-border rounded-xl p-5 mb-8 space-y-3.5">
        <div class="flex items-center gap-3 text-sm text-green-500 font-semibold">
          <span class="step-check flex items-center justify-center w-5 h-5 rounded-full bg-green-500/20 text-[10px]">✓</span>
          <span>Đồng bộ POS trạm {{ requisition.station }}</span>
        </div>
        <div class="flex items-center gap-3 text-sm text-green-500 font-semibold">
          <span class="step-check flex items-center justify-center w-5 h-5 rounded-full bg-green-500/20 text-[10px]">✓</span>
          <span>Khấu trừ Kho tổng Naka:
            <ul class="list-disc pl-5 text-xs text-gray-400 mt-1 font-mono">
              <li v-for="item in deliveryItems" :key="item.id" v-show="item.status === 'accepted'">
                {{ item.name }}: -{{ item.deliveredQty }} {{ item.unit }}
              </li>
            </ul>
          </span>
        </div>
        <div class="flex items-center gap-3 text-sm text-green-500 font-semibold">
          <span class="step-check flex items-center justify-center w-5 h-5 rounded-full bg-green-500/20 text-[10px]">✓</span>
          <span>Cộng tồn kho trạm Bếp:
            <ul class="list-disc pl-5 text-xs text-gray-400 mt-1 font-mono">
              <li v-for="item in deliveryItems" :key="item.id" v-show="item.status === 'accepted'">
                {{ item.name }}: +{{ item.deliveredQty }} {{ item.unit }}
              </li>
            </ul>
          </span>
        </div>
        <div class="flex items-center gap-3 text-sm text-green-500 font-semibold">
          <span class="step-check flex items-center justify-center w-5 h-5 rounded-full bg-green-500/20 text-[10px]">✓</span>
          <div class="flex-1">
            <span>Cập nhật giá vốn COGS trạm Bếp:</span>
            <div class="text-[#FF9800] font-black text-base mt-0.5">
              +{{ formatCurrency(cogsTotalValue) }} VND
            </div>
          </div>
        </div>
      </div>
      
      <button class="px-8 py-3 bg-[#4CAF50] hover:bg-[#43a047] text-white font-bold rounded-xl shadow-lg transition transform hover:-translate-y-0.5" @click="completeRequisition">
        HOÀN TẤT QUY TRÌNH
      </button>
    </div>

    <!-- MAIN INSPECTION SCREEN (PHASE 3) -->
    <div class="flex justify-between items-center mb-6 pb-4 border-b border-border">
      <div>
        <h3 class="font-black text-foreground text-xl tracking-wide">KIỂM TRA GIAO NHẬN NGUYÊN LIỆU</h3>
        <p class="text-xs text-gray-400 mt-1">Phiếu yêu cầu: #{{ requisition.id }} | Trạm: {{ requisition.station }}</p>
      </div>
      <button class="bg-muted text-foreground text-xs px-4 py-2 rounded-xl font-bold hover:bg-muted transition border border-border" @click="$emit('back')">
        ⬅ Quay lại danh sách
      </button>
    </div>

    <!-- Stepper indicator -->
    <div class="flex justify-between items-center mb-6 bg-background p-3.5 rounded-xl border border-border">
      <span class="text-xs font-bold text-[#FF9800] uppercase">Bước 3: Bếp kiểm tra & Giao nhận</span>
      <div class="flex items-center gap-2 text-xs font-semibold text-gray-400">
        <span>Tạo Phiếu</span>
        <span>➔</span>
        <span>Kho Xuất</span>
        <span>➔</span>
        <span class="text-[#FF9800] font-bold">Giao Nhận</span>
        <span>➔</span>
        <span>Cập Nhật Hệ Thống</span>
      </div>
    </div>
    
    <div class="delivery-items space-y-5">
      <div 
        v-for="item in deliveryItems" 
        :key="item.id"
        class="delivery-item bg-background rounded-xl p-5 border border-border transition"
        :class="{ 
          'border-l-4 border-l-[#4CAF50]': item.status === 'accepted', 
          'border-l-4 border-l-[#F44336]': item.status === 'rejected',
          'border-l-4 border-l-[#FF9800]': item.status === 'pending' 
        }"
      >
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <span class="item-icon text-3xl">{{ item.icon }}</span>
            <div>
              <span class="item-name font-bold text-foreground text-lg block">{{ item.name }}</span>
              <span class="text-xs text-gray-400 font-medium font-mono">
                Số lượng kho giao: {{ item.deliveredQty }} {{ item.unit }}
              </span>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <span class="text-xs font-bold uppercase py-1 px-3 rounded-full font-mono" :class="{
              'bg-green-950/40 text-green-500 border border-green-800/40': item.status === 'accepted',
              'bg-red-950/40 text-red-500 border border-red-800/40': item.status === 'rejected',
              'bg-yellow-950/40 text-yellow-500 border border-yellow-800/40': item.status === 'pending'
            }">
              {{ item.status === 'accepted' ? 'Đã duyệt đạt' : item.status === 'rejected' ? 'Từ chối nhận' : 'Chờ kiểm tra' }}
            </span>
          </div>
        </div>

        <hr class="border-border my-4" />

        <!-- 3-Way Quality Control checks (Mermaid: G2 Bếp trưởng kiểm tra Chất lượng, Số lượng, Nhiệt độ) -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
          <!-- 1. Quality rating check -->
          <div class="flex flex-col gap-1.5">
            <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider">⭐ 1. Kiểm tra Chất Lượng</span>
            <div class="grid grid-cols-3 gap-1.5 mt-1">
              <button 
                type="button"
                class="quality-btn"
                :class="{ active: item.quality === 'good' }"
                @click="item.quality = 'good'; item.status = 'accepted'; item.rejectionReason = ''"
              >
                Tốt 🌟
              </button>
              <button 
                type="button"
                class="quality-btn warning"
                :class="{ active: item.quality === 'warning' }"
                @click="item.quality = 'warning'; item.status = 'accepted'; item.rejectionReason = ''"
              >
                Hơi lỗi ⚠️
              </button>
              <button 
                type="button"
                class="quality-btn danger"
                :class="{ active: item.quality === 'bad' }"
                @click="rejectItem(item)"
              >
                Hỏng ❌
              </button>
            </div>
          </div>

          <!-- 2. Temperature check -->
          <div class="flex flex-col gap-1.5">
            <div class="flex justify-between items-baseline">
              <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider">🌡️ 2. Kiểm tra Nhiệt độ</span>
              <span class="text-xs font-bold font-mono" :class="isTempSafe(item) ? 'text-green-500' : 'text-red-500'">
                {{ item.temperature }}°C
              </span>
            </div>
            <div class="flex items-center gap-3 mt-1.5">
              <input 
                v-model.number="item.temperature" 
                type="range" 
                min="-25" 
                max="25" 
                step="1"
                class="temp-slider flex-1"
              />
              <span v-if="!isTempSafe(item)" class="text-[10px] bg-red-950/40 text-red-400 border border-red-800/40 px-1.5 py-0.5 rounded font-bold uppercase animate-pulse">
                Quá Ấm!
              </span>
              <span v-else class="text-[10px] bg-green-950/40 text-green-500 border border-green-800/40 px-1.5 py-0.5 rounded font-bold uppercase">
                An Toàn
              </span>
            </div>
            <span class="text-[10px] text-gray-500 italic mt-0.5">Tiêu chuẩn: &le; 5°C đối với đồ tươi/lạnh</span>
          </div>

          <!-- 3. Quantity check -->
          <div class="flex flex-col gap-1.5">
            <span class="text-[11px] font-bold text-gray-400 uppercase tracking-wider">⚖️ 3. Kiểm định Số lượng</span>
            <div class="flex items-center gap-2 mt-1">
              <button 
                type="button" 
                class="qty-adjust bg-card hover:bg-muted text-foreground w-8 h-8 rounded-lg flex items-center justify-center font-bold"
                @click="adjustItemQty(item, -1)"
              >-</button>
              <input 
                v-model.number="item.deliveredQty" 
                type="number" 
                min="0"
                :max="item.requestedQty"
                class="w-full text-center bg-card border border-border rounded-lg py-1 text-foreground font-mono font-bold text-sm"
              />
              <button 
                type="button" 
                class="qty-adjust bg-card hover:bg-muted text-foreground w-8 h-8 rounded-lg flex items-center justify-center font-bold"
                @click="adjustItemQty(item, 1)"
              >+</button>
              <span class="text-xs text-gray-400 font-bold uppercase">{{ item.unit }}</span>
            </div>
            <span class="text-[10px] text-gray-500 font-mono mt-0.5">Yêu cầu gốc: {{ item.requestedQty }} {{ item.unit }}</span>
          </div>
        </div>
        
        <div v-if="item.rejectionReason" class="rejection-reason mt-3 text-xs bg-red-950/20 text-red-400 border border-red-800/40 p-2.5 rounded-lg flex items-start gap-1.5">
          <strong>Lý do từ chối nhận hàng:</strong> {{ item.rejectionReason }}
        </div>
      </div>
    </div>

    <!-- DIGITAL SIGNATURE PAD (Mermaid: G5 Ký xác nhận Digital Signature) -->
    <div class="signature-section bg-background rounded-xl p-5 border border-border mt-6">
      <div class="flex justify-between items-center mb-3">
        <h4 class="text-sm font-bold text-[#FF9800] uppercase tracking-wider flex items-center gap-2">
          ✍️ Ký Xác Nhận Nhận Bàn Giao (Digital Signature)
        </h4>
        <button type="button" class="text-xs bg-card hover:bg-muted border border-border text-gray-300 font-bold px-3 py-1.5 rounded-lg transition" @click="clearSignature">
          Xóa Chữ Ký
        </button>
      </div>

      <div class="signature-canvas-container bg-card/30 border-2 border-dashed border-border rounded-xl h-[120px] relative overflow-hidden flex items-center justify-center">
        <canvas 
          ref="canvasRef"
          width="700"
          height="120"
          class="w-full h-full cursor-crosshair relative z-10"
          @mousedown="startDrawing"
          @mousemove="draw"
          @mouseup="stopDrawing"
          @mouseleave="stopDrawing"
          @touchstart="startDrawing"
          @touchmove="draw"
          @touchend="stopDrawing"
        ></canvas>
        <div v-if="!hasSigned" class="absolute pointer-events-none text-xs text-gray-500 font-bold uppercase z-0">
          Vẽ chữ ký của bạn tại đây để ký nhận bàn giao
        </div>
      </div>
      <p class="text-[10px] text-gray-500 italic mt-2">Bằng cách ký nhận, Bếp trưởng xác nhận đã kiểm tra chất lượng, số lượng và nhiệt độ thực phẩm khớp với các số liệu kê khai.</p>
    </div>
    
    <!-- OVERALL ACTIONS -->
    <div class="overall-actions flex gap-4 mt-6 pt-4 border-t border-border">
      <button class="btn-reject-all py-3 rounded-xl font-bold bg-[#C62828] hover:bg-[#b71c1c] text-white transition flex-1 text-sm tracking-wide" @click="rejectAll">
         TỪ CHỐI NHẬN TOÀN BỘ
      </button>
      <button 
        class="btn-confirm-all py-3 rounded-xl font-bold bg-[#4CAF50] hover:bg-[#43a047] disabled:opacity-50 disabled:cursor-not-allowed text-foreground transition flex-2 text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg" 
        :disabled="!hasSigned || hasPendingItems"
        @click="confirmAll"
      >
        <span>✓</span> KÝ NHẬN & HOÀN TẤT NHẬN HÀNG
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed, onMounted } from 'vue';
import type { Requisition } from '@/stores/kitchen';
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

interface DeliveryConfirmationItem {
  id: string;
  name: string;
  icon: string;
  unit: string;
  requestedQty: number;
  deliveredQty: number;
  status: 'pending' | 'accepted' | 'rejected';
  quality: 'good' | 'warning' | 'bad';
  temperature: number; // In Celsius
  unitPrice: number;
  rejectionReason?: string;
}

const deliveryItems = ref<DeliveryConfirmationItem[]>([]);
const showSystemUpdate = ref(false);

// Canvas signature state
const canvasRef = ref<HTMLCanvasElement | null>(null);
let isDrawing = false;
let ctx: CanvasRenderingContext2D | null = null;
const hasSigned = ref(false);

watch(() => props.requisition, (newReq) => {
  deliveryItems.value = newReq.items.map(item => {
    // Find matching inventory item to retrieve unitPrice
    const invItem = kitchenStore.inventoryList.find(i => i.id === item.id);
    const price = invItem ? invItem.unitPrice : 100000;
    
    // Set default safe temperature: Meat/fish is 2C, Veg is 8C, others 4C
    let defaultTemp = 3;
    if (item.name.includes('Rau')) defaultTemp = 8;
    if (item.name.includes('Sukiyaki')) defaultTemp = 15; // broth room temp
    
    return {
      id: item.id,
      name: item.name,
      icon: item.icon,
      unit: item.unit,
      requestedQty: item.requestedQty,
      deliveredQty: item.deliveredQty,
      status: item.status === 'rejected' ? 'rejected' : 'pending',
      quality: item.status === 'rejected' ? 'bad' : 'good',
      temperature: defaultTemp,
      unitPrice: price,
      rejectionReason: item.rejectionReason || ''
    };
  });
}, { immediate: true });

const hasPendingItems = computed(() => {
  return deliveryItems.value.some(i => i.status === 'pending');
});

// Calculate total COGS value added
const cogsTotalValue = computed(() => {
  return deliveryItems.value
    .filter(item => item.status === 'accepted')
    .reduce((sum, item) => sum + (item.deliveredQty * item.unitPrice), 0);
});

const isTempSafe = (item: DeliveryConfirmationItem) => {
  if (item.name.includes('Rau')) return item.temperature <= 10;
  if (item.name.includes('lẩu')) return true; // Broth doesn't have strict cold temp
  return item.temperature <= 5; // Meat, fish, etc. cold chain standard
};

const adjustItemQty = (item: DeliveryConfirmationItem, amount: number) => {
  item.deliveredQty = Math.max(0, Math.min(item.requestedQty, item.deliveredQty + amount));
};

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('vi-VN').format(val);
};

const rejectItem = async (item: DeliveryConfirmationItem) => {
  const { value: text } = await Swal.fire({
    title: 'Lý do từ chối mặt hàng',
    input: 'select',
    inputOptions: {
      'Hàng dập nát / Hỏng': 'Hàng dập nát / Hỏng',
      'Nhiệt độ giao không đạt chuẩn': 'Nhiệt độ giao không đạt chuẩn',
      'Không đúng mô tả': 'Không đúng mô tả',
      'Thiếu cân / Thiếu trọng lượng': 'Thiếu cân / Thiếu trọng lượng',
      'Đã hết hạn sử dụng': 'Đã hết hạn sử dụng',
      'Khác': 'Khác'
    },
    inputPlaceholder: 'Chọn lý do từ chối...',
    showCancelButton: true,
    confirmButtonText: 'Xác nhận từ chối',
    cancelButtonText: 'Hủy',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#F44336'
  });

  if (text) {
    item.status = 'rejected';
    item.quality = 'bad';
    item.rejectionReason = text;
  } else {
    // Reset back to good if cancelled
    item.quality = 'good';
    item.status = 'accepted';
  }
};

// Signature Drawing logic
const startDrawing = (e: MouseEvent | TouchEvent) => {
  isDrawing = true;
  ctx = canvasRef.value?.getContext('2d') || null;
  if (!ctx || !canvasRef.value) return;
  
  ctx.beginPath();
  const rect = canvasRef.value.getBoundingClientRect();
  const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
  const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
  
  ctx.moveTo(x, y);
};

const draw = (e: MouseEvent | TouchEvent) => {
  if (!isDrawing || !ctx || !canvasRef.value) return;
  e.preventDefault();
  const rect = canvasRef.value.getBoundingClientRect();
  const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
  const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
  
  ctx.lineTo(x, y);
  ctx.strokeStyle = '#FF9800';
  ctx.lineWidth = 3;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();
  hasSigned.value = true;
};

const stopDrawing = () => {
  isDrawing = false;
};

const clearSignature = () => {
  if (!canvasRef.value) return;
  const context = canvasRef.value.getContext('2d');
  if (context) {
    context.clearRect(0, 0, canvasRef.value.width, canvasRef.value.height);
  }
  hasSigned.value = false;
};

const rejectAll = () => {
  Swal.fire({
    title: 'Từ chối toàn bộ kiện hàng?',
    text: 'Bạn có chắc chắn muốn từ chối nhận tất cả nguyên liệu trong phiếu giao này?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Đồng ý từ chối',
    cancelButtonText: 'Hủy',
    background: '#2D2D2D',
    color: '#FFF',
    confirmButtonColor: '#F44336'
  }).then((res) => {
    if (res.isConfirmed) {
      kitchenStore.updateRequisitionStatus(props.requisition.id, 'rejected', 'Chef Luc', 'Từ chối nhận toàn bộ kiện hàng do lỗi bàn giao kiểm định.');
      Swal.fire({
        title: 'Đã từ chối nhận hàng',
        text: 'Kiện hàng đã được đánh dấu trả về bộ phận kho.',
        icon: 'error',
        background: '#2D2D2D',
        color: '#FFF'
      });
      emit('success');
    }
  });
};

const confirmAll = () => {
  // Check if signature is drawn
  if (!hasSigned.value) {
    Swal.fire({
      title: 'Thiếu chữ ký xác nhận',
      text: 'Vui lòng ký tên của bạn vào khung chữ ký trước khi hoàn tất.',
      icon: 'warning',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#FF9800'
    });
    return;
  }

  // Update item deliveries on store
  deliveryItems.value.forEach(item => {
    kitchenStore.updateRequisitionItemDelivery(
      props.requisition.id,
      item.id,
      item.deliveredQty,
      item.status === 'accepted' ? 'approved' : 'rejected',
      item.status === 'rejected' ? item.rejectionReason : undefined
    );
  });

  // Extract canvas signature image data url
  const sigImgUrl = canvasRef.value ? canvasRef.value.toDataURL() : undefined;

  // Check if there is any item accepted
  const anyAccepted = deliveryItems.value.some(i => i.status === 'accepted');
  const finalStatus = anyAccepted ? 'delivered' : 'rejected';

  // Update requisition status with signature
  kitchenStore.updateRequisitionStatus(
    props.requisition.id, 
    finalStatus, 
    'Chef Luc',
    finalStatus === 'rejected' ? 'Từ chối nhận toàn bộ do lỗi kiểm kê.' : undefined,
    sigImgUrl
  );

  if (finalStatus === 'delivered') {
    // Show system update transition screen first
    showSystemUpdate.value = true;
  } else {
    Swal.fire({
      title: 'Đã trả hàng',
      text: 'Đã hoàn trả toàn bộ phiếu giao hàng về bộ phận kho.',
      icon: 'success',
      background: '#2D2D2D',
      color: '#FFF',
      confirmButtonColor: '#4CAF50'
    });
    emit('success');
  }
};

const completeRequisition = () => {
  showSystemUpdate.value = false;
  emit('success');
};
</script>

<style scoped>
.quality-btn {
  background: #2D2D2D;
  border: 1px solid #404040;
  color: #B0B0B0;
  font-size: 11px;
  font-weight: 700;
  padding: 8px 4px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
}

.quality-btn.active {
  background: rgba(76, 175, 80, 0.2);
  color: #4CAF50;
  border-color: #4CAF50;
}

.quality-btn.warning.active {
  background: rgba(255, 152, 0, 0.2);
  color: #FF9800;
  border-color: #FF9800;
}

.quality-btn.danger.active {
  background: rgba(244, 67, 54, 0.2);
  color: #F44336;
  border-color: #F44336;
}

.temp-slider {
  -webkit-appearance: none;
  width: 100%;
  height: 6px;
  border-radius: 3px;
  background: #404040;
  outline: none;
}

.temp-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #FF9800;
  cursor: pointer;
  box-shadow: 0 0 4px rgba(0,0,0,0.5);
}

.qty-adjust {
  border: 1px solid #404040;
  transition: all 0.15s ease;
}
.qty-adjust:active {
  transform: scale(0.9);
}

/* Success Checkmark CSS */
.success-checkmark {
  width: 80px;
  height: 80px;
  margin: 0 auto;
}
.check-icon {
  width: 80px;
  height: 80px;
  position: relative;
  border-radius: 50%;
  box-sizing: content-box;
  border: 4px solid #4CAF50;
}
.check-icon::after {
  content: '';
  position: absolute;
  background: #1A1A1A;
  z-index: 1;
}
.icon-line {
  height: 5px;
  background-color: #4CAF50;
  display: block;
  border-radius: 2px;
  position: absolute;
  z-index: 10;
}
.icon-line.line-tip {
  top: 46px;
  left: 19px;
  width: 25px;
  transform: rotate(45deg);
}
.icon-line.line-long {
  top: 38px;
  right: 14px;
  width: 47px;
  transform: rotate(-45deg);
}
.icon-circle {
  top: -4px;
  left: -4px;
  position: absolute;
  box-sizing: content-box;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 4px solid rgba(76, 175, 80, .5);
  z-index: 2;
}

/* Animation utilities */
@keyframes check-tip {
  0% { width: 0; left: 1px; top: 19px; }
  54% { width: 0; left: 1px; top: 19px; }
  70% { width: 50px; left: -8px; top: 37px; }
  84% { width: 17px; left: 21px; top: 48px; }
  100% { width: 25px; left: 19px; top: 46px; }
}

@keyframes check-long {
  0% { width: 0; right: 46px; top: 54px; }
  65% { width: 0; right: 46px; top: 54px; }
  84% { width: 55px; right: 0px; top: 35px; }
  100% { width: 47px; right: 14px; top: 38px; }
}

.animate-check-tip {
  animation: check-tip 0.8s ease-in-out forwards;
}
.animate-check-long {
  animation: check-long 0.8s ease-in-out forwards;
}

.flex-2 {
  flex: 2;
}
</style>
