<!-- File: src/views/customer/CustomerHome.vue -->
<template>
  <div class="flex-1 flex flex-col justify-center items-center p-6 w-full h-full bg-gradient-to-br from-[#0c0c0c] to-[#050505]">
    
    <!-- Title Header for Setup Screens -->
    <div v-if="step !== 'passcode' && step !== 'session_ended'" 
         class="absolute top-8 left-8 flex items-center gap-2">
      <span class="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse"></span>
      <span class="text-xs font-bold text-gray-500 uppercase tracking-widest">
        {{ $t('customer.passcode.deviceSetup') }}
      </span>
    </div>

    <!-- Step 1: Passcode -->
    <transition name="fade-scale" mode="out-in">
      <div v-if="step === 'passcode'" class="w-full flex justify-center">
        <PasscodeInput ref="passcodeInputRef" @submit="handlePasscodeSubmit" @back="handleBackToTablet" />
      </div>

      <!-- Step 2: Select Branch -->
      <div v-else-if="step === 'branch'" class="w-full flex justify-center">
        <SelectBranch :branches="branches"
                      :selected-branch-id="selectedBranchId"
                      @select="handleBranchSelect"
                      @back="resetSetup" />
      </div>

      <!-- Step 3: Select Area -->
      <div v-else-if="step === 'area'" class="w-full flex justify-center h-full overflow-hidden">
        <SelectArea :areas="areas" 
                    :selected-area-id="selectedAreaId" 
                    @select="handleAreaSelect"
                    @back="goBackToBranch" />
      </div>

      <!-- Step 3: Select Table -->
      <div v-else-if="step === 'table'" class="w-full flex justify-center">
        <SelectTable :tables="tables" 
                     :selected-table-id="selectedTableId" 
                     :area-name="selectedAreaName"
                     @select="handleTableSelect"
                     @confirm="handleTableConfirm"
                     @back="goBackToArea" />
      </div>

      <!-- Step 4: Session Ended -->
      <div v-else-if="step === 'session_ended'" class="w-full flex justify-center">
        <SessionEnd @done="step = 'passcode'" />
      </div>
    </transition>

    <!-- Quick Lock/Reset Button for setup steps (top right) -->
    <button v-if="step === 'branch' || step === 'area' || step === 'table'" 
            type="button"
            @click="resetSetup" 
            class="absolute top-6 right-6 p-2 rounded-xl bg-gray-900 border border-gray-800 text-gray-400 hover:text-white hover:border-gray-700 transition-all text-xs font-bold flex items-center gap-1.5 active:scale-95">
      {{ $t('customer.passcode.lock') }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import PasscodeInput from '@/components/customer/PasscodeInput.vue';
import SelectBranch from './SelectBranch.vue';
import SelectArea from './SelectArea.vue';
import SelectTable from './SelectTable.vue';
import SessionEnd from './SessionEnd.vue';
import type { Table } from '@/types/customer';

const store = useCustomerStore();
const router = useRouter();

onMounted(() => {
  if (store.session) {
    router.push({ name: 'CustomerMenu' });
  }
});

const passcodeInputRef = ref<any>(null);
const step = ref<'passcode' | 'branch' | 'area' | 'table' | 'session_ended'>('passcode');

const selectedBranchId = ref<string | null>(null);
const selectedAreaId = ref<string | null>(null);
const selectedTableId = ref<string | null>(null);
const timeoutId = ref<any>(null);

const branches = computed(() => store.branches);
const areas = computed(() => store.areas);
const tables = computed(() => store.tables);
const selectedAreaName = computed(() => {
  return store.areas.find(a => a.id === selectedAreaId.value)?.name || 'Khu vực';
});

// Handle Passcode Unlock
async function handlePasscodeSubmit(code: string) {
  const success = await store.authenticateStaff(code);
  if (success) {
    await store.loadBranches();
    step.value = 'branch';
  } else {
    passcodeInputRef.value?.setError('Mã passcode không chính xác!');
  }
}

function handleBackToTablet() {
  router.push('/tablet/idle');
}

// Handle Branch Selection
async function handleBranchSelect(branchId: string) {
  selectedBranchId.value = branchId;
  store.selectedBranchId = branchId;
  try {
    await store.loadAreas(branchId);
  } catch (e) {
    console.error('[CustomerHome] loadAreas failed:', e);
  }
  step.value = 'area';
}

function goBackToBranch() {
  selectedAreaId.value = null;
  store.areas = [];
  step.value = 'branch';
}

// Handle Area Selection
async function handleAreaSelect(areaId: string) {
  selectedAreaId.value = areaId;
  store.selectedAreaId = areaId;
  try {
    await store.loadTables(areaId);
  } catch (e) {
    console.error('[CustomerHome] loadTables failed:', e);
  }
  step.value = 'table';
}

// Handle Table Selection
async function handleTableSelect(table: Table) {
  selectedTableId.value = table.id;
  // Set the selected table immediately from the local data so the
  // confirm step has it regardless of whether the API call succeeds.
  store.selectedTable = table;
  try {
    await store.selectTable(table.id);
  } catch (e) {
    console.warn('[CustomerHome] selectTable failed, proceeding with local state:', e);
  }

  // BR-08: Setup a 60s timeout. If idle, release selecting state.
  startTableTimeout();
}

// Handle Confirmed Table & Start Session
async function handleTableConfirm() {
  clearTableTimeout();
  if (selectedTableId.value) {
    try {
      await store.confirmTable();
    } catch (e) {
      console.warn('[CustomerHome] confirmTable failed, creating local session:', e);
    }
    // Fallback: if confirmTable didn't set a session (API failure,
    // non-UUID table id, etc.), create a local session so the
    // customer can still reach the menu and order.
    if (!store.session && store.selectedTable) {
      store.session = {
        id: `sess-local-${Date.now()}`,
        tableId: store.selectedTable.id,
        tableNumber: store.selectedTable.number,
        areaId: store.selectedTable.areaId,
        areaName: store.areas.find(a => a.id === store.selectedTable?.areaId)?.name || 'Khu vực',
        staffId: 'staff-uuid-001',
        startedAt: new Date(),
        status: 'active',
      };
      store.isAuthenticated = true;
      localStorage.setItem('nguucat_customer_session', JSON.stringify(store.session));
      localStorage.setItem('nguucat_customer_auth', 'true');
      localStorage.setItem('nguucat_customer_table', JSON.stringify(store.selectedTable));
    }
    // Navigate to menu regardless of API success
    router.push({ name: 'CustomerMenu' });
  }
}

function goBackToArea() {
  clearTableTimeout();
  selectedTableId.value = null;
  store.selectedTable = null;
  step.value = 'area';
}

function resetSetup() {
  clearTableTimeout();
  selectedBranchId.value = null;
  selectedAreaId.value = null;
  selectedTableId.value = null;
  store.resetState();
  step.value = 'passcode';
}

// BR-08: Table selecting timeout management
function startTableTimeout() {
  clearTableTimeout();
  // 60 seconds (60000ms)
  timeoutId.value = setTimeout(async () => {
    if (selectedTableId.value && step.value === 'table') {
      store.addNotification('Hết thời gian chọn bàn. Hệ thống đã giải phóng bàn.', 'warning');
      selectedTableId.value = null;
      store.selectedTable = null;
      step.value = 'area';
    }
  }, 60000);
}

function clearTableTimeout() {
  if (timeoutId.value) {
    clearTimeout(timeoutId.value);
    timeoutId.value = null;
  }
}

// If session ends outside this view (e.g. from checkouts), let's allow rendering session_ended
defineExpose({
  showSessionEnded() {
    step.value = 'session_ended';
  }
});

onUnmounted(() => {
  clearTableTimeout();
});
</script>

<style scoped>
.fade-scale-enter-active, .fade-scale-leave-active {
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-scale-enter-from {
  opacity: 0;
  transform: scale(0.96);
}
.fade-scale-leave-to {
  opacity: 0;
  transform: scale(1.04);
}
</style>
