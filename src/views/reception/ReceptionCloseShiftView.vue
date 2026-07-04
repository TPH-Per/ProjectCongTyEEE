<template>
  <div class="end-shift-screen">
    <!-- Header -->
    <div class="shift-header">
      <div class="header-left">
        <h1>Ra ca - {{ shiftName }} - {{ cashierName }} - {{ restaurantName }}</h1>
      </div>
      <div class="header-center">
        <div>Giờ vào: {{ formatTime(shift.startTime) }}</div>
        <div>Giờ ra: {{ formatTime(shift.endTime) }}</div>
      </div>
      <div class="header-right">
        <div class="user-info bg-[#FFB74D] text-[#333] px-3 py-1 rounded-lg font-bold text-xs">
          <span>{{ user.username }}</span>
        </div>
        <button class="btn-back ml-2" @click="goBack">
           Quay về
        </button>
      </div>
    </div>

    <!-- Active shift notice -->
    <div v-if="!activeShift && !loading" class="p-4 bg-yellow-50 border border-yellow-200 text-yellow-800 text-sm text-center font-bold">
      Không có ca làm việc hoạt động nào được tìm thấy trên hệ thống.
    </div>

    <!-- Main Content -->
    <div class="main-content flex-1 grid grid-cols-1 md:grid-cols-3 gap-5 p-5 overflow-y-auto">
      <!-- Left: Cash Input -->
      <div class="cash-section border border-gray-200 shadow-sm flex flex-col">
        <div class="section-title">TIỀN MẶT</div>
        
        <!-- Currency Type Tabs -->
        <div class="currency-tabs">
          <button
            v-for="currency in currencies"
            :key="currency.code"
            class="currency-tab"
            :class="{ active: selectedCurrency === currency.code }"
            @click="selectCurrency(currency.code)"
            type="button"
          >
            <span>{{ currency.code }}</span>
            <span class="currency-count">{{ currency.count }}</span>
          </button>
        </div>

        <!-- Cash Denominations -->
        <div class="denominations-list flex-1 overflow-y-auto pr-1">
          <div class="denomination-header">
            <span>Loại tiền</span>
            <span>Số lượng</span>
          </div>
          <div
            v-for="denom in denominations"
            :key="denom.value"
            class="denomination-row"
            :class="{ focused: activeField === denom.value }"
            @click="activeField = denom.value"
          >
            <span class="denom-label">{{ formatMoney(denom.value) }}</span>
            <input
              v-model.number="denom.quantity"
              type="number"
              min="0"
              class="denom-input"
              @focus="activeField = denom.value"
              @input="calculateTotal"
            />
          </div>
          <div 
            class="denomination-row other"
            :class="{ focused: activeField === 'other' }"
            @click="activeField = 'other'"
          >
            <span class="denom-label">Tiền khác</span>
            <input
              v-model.number="otherAmount"
              type="number"
              min="0"
              class="denom-input other-input"
              @focus="activeField = 'other'"
            />
          </div>
        </div>
      </div>

      <!-- Center: Total -->
      <div class="total-section border border-gray-200 shadow-sm flex flex-col">
        <div class="section-title">TỔNG TIỀN</div>
        <div class="total-display flex-1 flex flex-col justify-center items-center gap-4 bg-gray-50/50 rounded-xl p-6">
          <span class="text-sm font-bold text-gray-500 uppercase tracking-wide">Tổng tiền mặt kiểm đếm</span>
          <div class="total-amount-wrapper">
            <span class="total-amount">{{ formatMoney(totalAmount) }}</span>
            <span class="text-xs font-bold text-gray-400 ml-1">VNĐ</span>
          </div>
          
          <!-- Reconciliation detail comparison -->
          <div class="w-full mt-6 space-y-2 border-t pt-4 text-xs font-semibold text-gray-600">
            <div class="flex justify-between">
              <span>Đầu ca:</span>
              <span class="font-mono">{{ formatMoney(cashSummary?.opening ?? 0) }}đ</span>
            </div>
            <div class="flex justify-between">
              <span>Doanh thu dự tính (tiền mặt):</span>
              <span class="font-mono">{{ formatMoney(cashSummary?.cashRevenue ?? 0) }}đ</span>
            </div>
            <div class="flex justify-between border-t pt-2 text-blue-700">
              <span>Lý thuyết hệ thống:</span>
              <span class="font-mono font-bold">{{ formatMoney(cashSummary?.expected ?? 0) }}đ</span>
            </div>
            <div class="flex justify-between border-t pt-2" :class="cashDiff >= 0 ? 'text-green-600' : 'text-red-650'">
              <span>Chênh lệch:</span>
              <span class="font-mono font-bold">{{ cashDiff >= 0 ? '+' : '' }}{{ formatMoney(cashDiff) }}đ</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Keypad & Notes -->
      <div class="keypad-section border border-gray-200 shadow-sm flex flex-col">
        <div class="user-info-display flex items-center justify-between pb-3 border-b mb-3">
          <div class="flex items-center gap-2">
            <div class="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-xs font-bold text-gray-700">Đang hoạt động: {{ user.username }}</span>
          </div>
          <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Bảng nhập số</span>
        </div>
        
        <div class="notes-field">
          <label>Ghi chú ra ca</label>
          <div class="input-with-btn">
            <input 
              v-model="notes" 
              type="text" 
              class="notes-input" 
              placeholder="Nhập ghi chú bàn giao ca..."
              @focus="activeField = 'notes'"
            />
            <button type="button" class="btn-more" @click="notes = 'Đã bàn giao đầy đủ tiền mặt và bàn giao ca.'">...</button>
          </div>
        </div>

        <!-- Numeric Keypad -->
        <div class="keypad flex-1 grid grid-cols-4 gap-1.5 select-none">
          <button
            v-for="key in keypadKeys"
            :key="key.label"
            :class="['key-btn', key.type]"
            @click="handleKeypad(key)"
            type="button"
          >
            {{ key.label }}
          </button>
        </div>
      </div>
    </div>

    <!-- Bottom Action -->
    <div class="bottom-action border-t bg-gray-50 flex items-center justify-between px-6 py-4">
      <div class="text-xs font-bold text-gray-500">
        * Hãy chắc chắn kiểm đếm chính xác số lượng tiền mặt trước khi bấm Ra ca.
      </div>
      <button class="btn-end-shift shadow-md active:scale-95 transition-all" @click="endShift" :disabled="loading">
         Ra ca
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import Swal from 'sweetalert2';
import { useLanguageStore } from '@/stores/useLanguageStore';
import { useAuth } from '@/composables/useAuth';
import { useShift } from '@/composables/useShift';
import { supabase } from '@/lib/supabase';
import type { Shift } from '@/types/database';

const router = useRouter();
const langStore = useLanguageStore();
const t = langStore.t;
const { branchId, profile } = useAuth();
const { closeShift, loading: shiftLoading, error: shiftError } = useShift();

const loading = ref(false);
const activeShift = ref<Shift | null>(null);

const shiftName = ref('Ca 1');
const cashierName = ref('Thu Ngân');
const restaurantName = ref('NGƯU CÁT');
const user = ref({ username: 'mo' });
const notes = ref('');
const selectedCurrency = ref('VND');
const otherAmount = ref(0);

const activeField = ref<number | 'other' | 'notes' | null>(null);

const shift = ref({
  startTime: '02/07/2026 10:22:03',
  endTime: '02/07/2026 15:09:40',
});

const currencies = ref([
  { code: 'VND', count: 1 },
  { code: 'EUR', count: 0 },
  { code: 'TKHACH', count: 0 },
  { code: 'USD', count: 0 },
]);

const denominations = ref([
  { value: 500, quantity: 0 },
  { value: 1000, quantity: 0 },
  { value: 2000, quantity: 0 },
  { value: 5000, quantity: 0 },
  { value: 10000, quantity: 0 },
  { value: 20000, quantity: 0 },
  { value: 50000, quantity: 0 },
  { value: 100000, quantity: 0 },
  { value: 200000, quantity: 0 },
  { value: 500000, quantity: 0 },
]);

interface KeypadKey {
  label: string;
  value: number | string;
  type: 'denom' | 'number' | 'action';
}

const keypadKeys = ref<KeypadKey[]>([
  { label: '500', value: 500, type: 'denom' },
  { label: '1.000', value: 1000, type: 'denom' },
  { label: '2.000', value: 2000, type: 'denom' },
  { label: '5.000', value: 5000, type: 'denom' },
  { label: '1', value: 1, type: 'number' },
  { label: '2', value: 2, type: 'number' },
  { label: '3', value: 3, type: 'number' },
  { label: '10.000', value: 10000, type: 'denom' },
  { label: '4', value: 4, type: 'number' },
  { label: '5', value: 5, type: 'number' },
  { label: '6', value: 6, type: 'number' },
  { label: '20.000', value: 20000, type: 'denom' },
  { label: '7', value: 7, type: 'number' },
  { label: '8', value: 8, type: 'number' },
  { label: '9', value: 9, type: 'number' },
  { label: '50.000', value: 50000, type: 'denom' },
  { label: '0', value: 0, type: 'number' },
  { label: '00', value: '00', type: 'number' },
  { label: '000', value: '000', type: 'number' },
  { label: '100.000', value: 100000, type: 'denom' },
  { label: '0,1', value: '0.1', type: 'number' },
  { label: '0,2', value: '0.2', type: 'number' },
  { label: '0,5', value: '0.5', type: 'number' },
  { label: '200.000', value: 200000, type: 'denom' },
  { label: '.', value: '.', type: 'number' },
  { label: 'Del', value: 'del', type: 'action' },
  { label: 'OK', value: 'ok', type: 'action' },
  { label: '500.000', value: 500000, type: 'denom' },
]);

const payments = ref<any[]>([]);

const totalAmount = computed(() => {
  const denomTotal = denominations.value.reduce((sum, d) => {
    return sum + (d.value * (d.quantity || 0));
  }, 0);
  return denomTotal + (otherAmount.value || 0);
});

const cashSummary = computed(() => {
  if (!activeShift.value) return { opening: 0, cashRevenue: 0, nonCashRevenue: 0, expected: 0 };
  const opening = Number(activeShift.value.opening_cash || 0);
  let cashRevenue = 0;
  let nonCashRevenue = 0;
  for (const p of payments.value) {
    if (p.method === 'cash') cashRevenue += Number(p.amount);
    else nonCashRevenue += Number(p.amount);
  }
  return {
    opening,
    cashRevenue,
    nonCashRevenue,
    expected: opening + cashRevenue,
  };
});

const cashDiff = computed(() => {
  const expected = cashSummary.value?.expected ?? 0;
  return totalAmount.value - expected;
});

const selectCurrency = (code: string) => {
  selectedCurrency.value = code;
};

const handleKeypad = (key: KeypadKey) => {
  if (key.type === 'denom') {
    // Increment quantity for denom preset value
    const denom = denominations.value.find(d => d.value === Number(key.value));
    if (denom) {
      denom.quantity = (denom.quantity || 0) + 1;
      calculateTotal();
    }
    return;
  }

  // Handle number/action keypad input on focused field
  if (activeField.value === 'notes') {
    if (key.value === 'del') {
      notes.value = notes.value.slice(0, -1);
    } else if (key.value === 'ok') {
      activeField.value = null;
    } else {
      notes.value = notes.value + String(key.value);
    }
    return;
  }

  if (activeField.value === 'other') {
    if (key.value === 'del') {
      const str = String(otherAmount.value);
      otherAmount.value = str.length > 1 ? parseInt(str.slice(0, -1), 10) : 0;
    } else if (key.value === 'ok') {
      activeField.value = null;
    } else {
      const currentStr = otherAmount.value === 0 ? '' : String(otherAmount.value);
      otherAmount.value = parseInt(currentStr + String(key.value), 10) || 0;
    }
    return;
  }

  if (typeof activeField.value === 'number') {
    const denom = denominations.value.find(d => d.value === activeField.value);
    if (denom) {
      if (key.value === 'del') {
        const str = String(denom.quantity);
        denom.quantity = str.length > 1 ? parseInt(str.slice(0, -1), 10) : 0;
      } else if (key.value === 'ok') {
        // move to next denomination
        const idx = denominations.value.indexOf(denom);
        if (idx < denominations.value.length - 1) {
          activeField.value = denominations.value[idx + 1].value;
        } else {
          activeField.value = 'other';
        }
      } else {
        const currentStr = denom.quantity === 0 ? '' : String(denom.quantity);
        denom.quantity = parseInt(currentStr + String(key.value), 10) || 0;
      }
      calculateTotal();
    }
  }
};

const calculateTotal = () => {
  // Computed property handles auto recalculation
};

const refreshAll = async () => {
  loading.value = true;
  try {
    // Get cashier name
    if (profile.value) {
      cashierName.value = profile.value.full_name || 'Thu Ngân';
      user.value.username = profile.value.email?.split('@')[0] || 'mo';
    }

    // Get active shift
    const bid = branchId.value ?? '';
    const { data: shiftData } = await supabase
      .from('shifts')
      .select('*')
      .eq('branch_id', bid)
      .eq('status', 'open')
      .order('opened_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (shiftData) {
      activeShift.value = shiftData;
      shift.value.startTime = new Date(shiftData.opened_at).toLocaleString('vi-VN');
      shift.value.endTime = new Date().toLocaleString('vi-VN');
      
      // Fetch shift payments
      const { data: payData } = await supabase
        .from('payments')
        .select('*')
        .eq('branch_id', bid)
        .eq('shift_id', shiftData.id);
      
      payments.value = payData || [];
    }
  } catch (e) {
    console.error('Failed to load close shift data:', e);
  } finally {
    loading.value = false;
  }
};

onMounted(refreshAll);

const endShift = async () => {
  if (!activeShift.value) {
    Swal.fire('Thông báo', 'Không có ca làm việc hoạt động nào!', 'info');
    return;
  }
  
  const expected = cashSummary.value?.expected ?? 0;
  const actual = totalAmount.value;
  const diff = actual - expected;

  Swal.fire({
    title: 'Xác nhận ra ca?',
    html: `
      <div class="text-left text-sm space-y-1 mb-2 text-gray-700">
        <div class="flex justify-between"><span>Tiền mặt ban đầu:</span><b>${(cashSummary.value?.opening ?? 0).toLocaleString('vi-VN')}đ</b></div>
        <div class="flex justify-between"><span>Doanh thu dự tính:</span><b>${(cashSummary.value?.cashRevenue ?? 0).toLocaleString('vi-VN')}đ</b></div>
        <div class="flex justify-between"><span>Lý thuyết hệ thống:</span><b>${expected.toLocaleString('vi-VN')}đ</b></div>
        <div class="flex justify-between text-orange-600 border-t pt-1 mt-1 font-bold"><span>Thực tế kiểm đếm:</span><b>${actual.toLocaleString('vi-VN')}đ</b></div>
        <div class="flex justify-between ${diff >= 0 ? 'text-green-600' : 'text-red-600'} font-bold"><span>Chênh lệch:</span><b>${diff >= 0 ? '+' : ''}${diff.toLocaleString('vi-VN')}đ</b></div>
      </div>
    `,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Xác nhận Ra ca',
    cancelButtonText: 'Hủy',
    confirmButtonColor: '#4CAF50',
    cancelButtonColor: '#E57373'
  }).then(async (resultConfirm) => {
    if (resultConfirm.isConfirmed) {
      loading.value = true;
      try {
        await closeShift({
          shiftId: activeShift.value!.id,
          closingCash: actual,
          notes: notes.value || undefined,
        });
        Swal.fire({
          icon: 'success',
          title: 'Ra ca thành công',
          html: `
            Chênh lệch: <b>${diff >= 0 ? '+' : ''}${diff.toLocaleString('vi-VN')}đ</b><br/>
            Thực tế: <b>${actual.toLocaleString('vi-VN')}đ</b>
          `,
          confirmButtonColor: '#4CAF50'
        });
        activeShift.value = null;
        router.push('/reception/dashboard');
      } catch (err: any) {
        Swal.fire('Lỗi ra ca', err.message || String(err), 'error');
      } finally {
        loading.value = false;
      }
    }
  });
};

const goBack = () => {
  router.push('/reception/dashboard');
};

const formatMoney = (val: number) => {
  return val?.toLocaleString('vi-VN') || '0';
};

const formatTime = (timeStr: string) => {
  return timeStr;
};
</script>

<style scoped>
.end-shift-screen {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  color: #333;
}

.shift-header {
  background: #1a5276;
  color: white;
  padding: 12px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left h1 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
}

.header-center {
  text-align: center;
  font-size: 12px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.btn-back {
  padding: 8px 16px;
  background: #E57373;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 700;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.2s;
}

.btn-back:hover {
  background: #d9534f;
  transform: translateY(-1px);
}

.main-content {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1.2fr 1fr;
  gap: 20px;
  padding: 20px;
  min-height: 0;
}

.cash-section, .total-section, .keypad-section {
  background: white;
  border-radius: 8px;
  padding: 16px;
  overflow: hidden;
}

.section-title {
  background: #1a5276;
  color: white;
  padding: 10px;
  text-align: center;
  font-weight: 750;
  font-size: 13px;
  border-radius: 4px;
  margin-bottom: 12px;
  letter-spacing: 0.05em;
}

.currency-tabs {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
}

.currency-tab {
  flex: 1;
  padding: 8px;
  background: #5D5D5D;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
  font-size: 11px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: all 0.2s;
}

.currency-tab.active {
  background: #FFB74D;
  color: #333;
}

.currency-count {
  background: rgba(0,0,0,0.3);
  padding: 1px 5px;
  border-radius: 3px;
  font-size: 10px;
}

.denominations-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.denomination-header {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  font-weight: 700;
  color: #888;
  margin-bottom: 4px;
  padding: 0 4px;
}

.denomination-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 10px;
  background: #f8f9fa;
  border: 2px solid transparent;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.denomination-row:hover {
  background: #f0f2f5;
}

.denomination-row.focused {
  border-color: #FFB74D;
  background: #fffdf9;
}

.denomination-row.other {
  background: #FFE5E5;
}

.denomination-row.other.focused {
  border-color: #E57373;
}

.denom-label {
  font-size: 13px;
  font-weight: 700;
  color: #333;
}

.denom-input {
  width: 90px;
  padding: 5px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 13px;
  font-family: monospace;
  font-weight: 700;
  text-align: right;
  background: white;
}

.denom-input:focus {
  outline: none;
}

.other-input {
  border-color: #E57373;
}

.total-amount-wrapper {
  display: flex;
  align-items: baseline;
}

.total-amount {
  font-size: 26px;
  font-weight: 900;
  color: #E57373;
  font-family: monospace;
  letter-spacing: -0.5px;
}

.user-info-display {
  font-size: 12px;
  color: #666;
}

.notes-field {
  margin-bottom: 12px;
}

.notes-field label {
  display: block;
  font-size: 11px;
  color: #666;
  margin-bottom: 4px;
  font-weight: 700;
}

.input-with-btn {
  display: flex;
  gap: 4px;
}

.notes-input {
  flex: 1;
  padding: 8px 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 12px;
  background: white;
}

.notes-input:focus {
  outline: none;
  border-color: #FFB74D;
}

.btn-more {
  width: 32px;
  background: #f5f5f5;
  border: 1px solid #ddd;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
}

.btn-more:hover {
  background: #e0e0e0;
}

.keypad {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 4px;
}

.key-btn {
  padding: 10px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.key-btn.denom {
  background: #FFB74D;
  color: #333;
}

.key-btn.number {
  background: #1a1a1a;
  color: white;
}

.key-btn.action {
  background: #FFB74D;
  color: #333;
}

.keypad button:nth-child(26) { /* Del button */
  background: #E57373;
  color: white;
}

.keypad button:nth-child(27) { /* OK button */
  background: #4DB6AC;
  color: white;
}

.key-btn:hover {
  opacity: 0.9;
  transform: scale(0.97);
}

.btn-end-shift {
  padding: 12px 32px;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 800;
  cursor: pointer;
}

.btn-end-shift:hover {
  background: #43A047;
}

.btn-end-shift:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>