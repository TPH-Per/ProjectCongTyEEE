<template>
  <div class="p-6 h-[calc(100vh-4rem)] flex flex-col max-w-[1600px] mx-auto overflow-hidden">
    <!-- Header -->
    <div class="mb-6 flex justify-between items-center shrink-0">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-2 flex items-center gap-2">
          <span class="text-[#FF7B89]">🗺️</span> Thiết Kế Sơ Đồ Bàn
        </h1>
        <p class="text-gray-500">Kéo thả để sắp xếp các khu vực và bàn trong nhà hàng</p>
      </div>
      <div class="flex gap-3">
        <button class="kawaii-btn-ghost flex items-center gap-2">
          <span>↺</span> Phục hồi
        </button>
        <button class="kawaii-btn-primary flex items-center gap-2 px-6">
          <span>💾</span> Lưu Sơ Đồ
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div class="flex flex-1 gap-6 min-h-0">
      
      <!-- Sidebar Tools -->
      <div class="w-80 flex flex-col gap-6 shrink-0 overflow-y-auto pr-2 custom-scrollbar">
        <!-- Zones -->
        <div class="kawaii-card p-5">
          <div class="flex justify-between items-center mb-4">
            <h2 class="font-bold text-gray-800 flex items-center gap-2">
              <span class="text-[#FF7B89]">📍</span> Khu Vực (Zones)
            </h2>
            <button class="w-8 h-8 rounded-full bg-pink-50 text-[#FF7B89] hover:bg-pink-100 flex items-center justify-center transition-colors font-bold" title="Thêm Khu Vực">
              +
            </button>
          </div>
          
          <div class="space-y-3">
            <div 
              v-for="zone in zones" 
              :key="zone.id"
              :class="[
                'p-3.5 rounded-xl border-2 cursor-pointer transition-all flex justify-between items-center group',
                activeZone === zone.id ? 'border-[#FF7B89] bg-pink-50/50 shadow-sm' : 'border-gray-100 hover:border-pink-200 bg-white'
              ]"
              @click="activeZone = zone.id"
            >
              <div class="flex items-center gap-3">
                <div class="w-4 h-4 rounded-full shadow-sm" :class="zone.color"></div>
                <span class="font-medium text-gray-700 group-hover:text-gray-900">{{ zone.name }}</span>
              </div>
              <span class="text-xs text-gray-500 font-medium bg-gray-100/80 px-2.5 py-1 rounded-full border border-gray-200/50">{{ zone.tableCount }} bàn</span>
            </div>
          </div>
        </div>

        <!-- Add Items -->
        <div class="kawaii-card p-5">
          <div class="flex justify-between items-center mb-4">
            <h2 class="font-bold text-gray-800 flex items-center gap-2">
              <span class="text-[#FF7B89]">🪑</span> Thêm Bàn Mới
            </h2>
          </div>
          
          <div class="grid grid-cols-2 gap-3">
            <!-- Table Square -->
            <div class="border-2 border-dashed border-gray-200 rounded-xl p-4 flex flex-col items-center justify-center cursor-grab active:cursor-grabbing hover:border-[#FF7B89] hover:bg-pink-50/50 transition-all group">
              <div class="w-12 h-12 bg-gray-50 rounded-lg border-2 border-gray-300 group-hover:border-[#FF7B89] group-hover:bg-white transition-colors mb-3 shadow-sm"></div>
              <span class="text-xs font-semibold text-gray-500 group-hover:text-[#FF7B89]">Bàn Vuông</span>
            </div>
            
            <!-- Table Circle -->
            <div class="border-2 border-dashed border-gray-200 rounded-xl p-4 flex flex-col items-center justify-center cursor-grab active:cursor-grabbing hover:border-[#FF7B89] hover:bg-pink-50/50 transition-all group">
              <div class="w-12 h-12 bg-gray-50 rounded-full border-2 border-gray-300 group-hover:border-[#FF7B89] group-hover:bg-white transition-colors mb-3 shadow-sm"></div>
              <span class="text-xs font-semibold text-gray-500 group-hover:text-[#FF7B89]">Bàn Tròn</span>
            </div>

            <!-- Table Rect -->
            <div class="col-span-2 border-2 border-dashed border-gray-200 rounded-xl p-4 flex flex-col items-center justify-center cursor-grab active:cursor-grabbing hover:border-[#FF7B89] hover:bg-pink-50/50 transition-all group">
              <div class="w-24 h-10 bg-gray-50 rounded-lg border-2 border-gray-300 group-hover:border-[#FF7B89] group-hover:bg-white transition-colors mb-3 shadow-sm"></div>
              <span class="text-xs font-semibold text-gray-500 group-hover:text-[#FF7B89]">Bàn Chữ Nhật (Lớn)</span>
            </div>
          </div>
        </div>

        <!-- Properties -->
        <div class="kawaii-card p-5 flex-1 flex flex-col">
          <h2 class="font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="text-[#FF7B89]">⚙️</span> Thuộc tính Bàn
          </h2>
          <div v-if="selectedTable" class="space-y-4 flex-1">
            <div>
              <label class="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">Tên/Số Bàn</label>
              <input type="text" v-model="selectedTable.name" class="kawaii-input w-full text-sm py-2.5 font-medium" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">Sức chứa (người)</label>
              <input type="number" v-model="selectedTable.capacity" class="kawaii-input w-full text-sm py-2.5 font-medium" />
            </div>
            <div class="pt-6 mt-auto">
              <button class="w-full py-2.5 text-sm text-red-600 font-bold bg-red-50 hover:bg-red-100 rounded-xl transition-colors border border-red-100 flex items-center justify-center gap-2">
                <span>🗑️</span> Xóa Bàn
              </button>
            </div>
          </div>
          <div v-else class="text-center text-gray-400 text-sm py-10 flex flex-col items-center gap-3">
            <span class="text-3xl opacity-50">👆</span>
            <span>Chọn một bàn trên sơ đồ để chỉnh sửa thuộc tính</span>
          </div>
        </div>
      </div>

      <!-- Canvas Area -->
      <div class="flex-1 kawaii-card bg-gray-50/50 relative overflow-hidden flex flex-col border border-gray-200/60 shadow-inner">
        <!-- Canvas Toolbar -->
        <div class="h-16 border-b border-gray-200/60 bg-white/90 backdrop-blur-md flex items-center justify-between px-6 shrink-0 z-10">
          <div class="flex items-center gap-4">
            <span class="font-bold text-gray-800 flex items-center gap-2.5 text-lg">
              <div class="w-3.5 h-3.5 rounded-full shadow-sm" :class="activeZoneObj?.color || 'bg-gray-400'"></div>
              {{ activeZoneObj?.name || 'Chưa chọn khu vực' }}
            </span>
            <div class="h-6 w-px bg-gray-200"></div>
            <span class="text-sm font-medium text-gray-500 bg-gray-100 px-3 py-1 rounded-lg">Kích thước: 12m x 8m</span>
          </div>
          
          <div class="flex gap-1.5 bg-gray-100/80 p-1.5 rounded-2xl border border-gray-200/50">
            <button class="w-9 h-9 flex items-center justify-center bg-white rounded-xl shadow-sm text-gray-600 font-bold text-lg hover:text-[#FF7B89] hover:shadow transition-all">-</button>
            <div class="w-14 flex items-center justify-center text-sm font-bold text-gray-700">100%</div>
            <button class="w-9 h-9 flex items-center justify-center bg-white rounded-xl shadow-sm text-gray-600 font-bold text-lg hover:text-[#FF7B89] hover:shadow transition-all">+</button>
          </div>
        </div>

        <!-- Canvas Board (Grid) -->
        <div class="flex-1 relative cursor-crosshair overflow-auto">
          <!-- Background Grid Pattern -->
          <div class="absolute inset-0 z-0 opacity-60" style="background-image: radial-gradient(#d1d5db 1.5px, transparent 1.5px); background-size: 24px 24px;"></div>
          
          <!-- Placed Tables -->
          <div class="absolute z-10 inset-0 p-8 min-w-[800px] min-h-[600px]">
            <!-- Bàn 1 -->
            <div 
              class="absolute cursor-move transition-all flex items-center justify-center"
              style="left: 120px; top: 120px; width: 80px; height: 80px;"
              @click="selectTable(1)"
            >
              <div :class="[
                'w-full h-full rounded-2xl border-4 bg-white flex flex-col items-center justify-center gap-1.5 transition-all shadow-sm hover:shadow-md',
                selectedTableId === 1 ? 'border-[#FF7B89] shadow-[0_0_0_4px_rgba(255,123,137,0.2)] scale-105' : 'border-blue-400'
              ]">
                <span class="font-bold text-gray-800">T01</span>
                <span class="text-[11px] font-medium text-gray-500 bg-gray-100/80 px-2 py-0.5 rounded-md">4 👤</span>
              </div>
            </div>

            <!-- Bàn 2 -->
            <div 
              class="absolute cursor-move transition-all flex items-center justify-center"
              style="left: 260px; top: 120px; width: 80px; height: 80px;"
              @click="selectTable(2)"
            >
              <div :class="[
                'w-full h-full rounded-2xl border-4 bg-white flex flex-col items-center justify-center gap-1.5 transition-all shadow-sm hover:shadow-md',
                selectedTableId === 2 ? 'border-[#FF7B89] shadow-[0_0_0_4px_rgba(255,123,137,0.2)] scale-105' : 'border-blue-400'
              ]">
                <span class="font-bold text-gray-800">T02</span>
                <span class="text-[11px] font-medium text-gray-500 bg-gray-100/80 px-2 py-0.5 rounded-md">4 👤</span>
              </div>
            </div>

            <!-- Bàn Tròn 1 -->
            <div 
              class="absolute cursor-move transition-all flex items-center justify-center"
              style="left: 440px; top: 140px; width: 100px; height: 100px;"
              @click="selectTable(3)"
            >
              <div :class="[
                'w-full h-full rounded-full border-4 bg-white flex flex-col items-center justify-center gap-1.5 transition-all shadow-sm hover:shadow-md',
                selectedTableId === 3 ? 'border-[#FF7B89] shadow-[0_0_0_4px_rgba(255,123,137,0.2)] scale-105' : 'border-purple-400'
              ]">
                <span class="font-bold text-gray-800">R01</span>
                <span class="text-[11px] font-medium text-gray-500 bg-gray-100/80 px-2 py-0.5 rounded-md">6 👤</span>
              </div>
            </div>

            <!-- Bàn Dài -->
            <div 
              class="absolute cursor-move transition-all flex items-center justify-center"
              style="left: 120px; top: 280px; width: 220px; height: 80px;"
              @click="selectTable(4)"
            >
              <div :class="[
                'w-full h-full rounded-2xl border-4 bg-white flex flex-col items-center justify-center gap-1.5 transition-all shadow-sm hover:shadow-md',
                selectedTableId === 4 ? 'border-[#FF7B89] shadow-[0_0_0_4px_rgba(255,123,137,0.2)] scale-105' : 'border-green-400'
              ]">
                <span class="font-bold text-gray-800">V01</span>
                <span class="text-[11px] font-medium text-gray-500 bg-gray-100/80 px-2 py-0.5 rounded-md">10 👤</span>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const zones = ref([
  { id: 'z1', name: 'Tầng Trệt - Trong nhà', color: 'bg-blue-400', tableCount: 15 },
  { id: 'z2', name: 'Tầng Trệt - Sân vườn', color: 'bg-green-400', tableCount: 8 },
  { id: 'z3', name: 'Tầng 2 - Phòng VIP', color: 'bg-purple-400', tableCount: 5 },
  { id: 'z4', name: 'Ban Công', color: 'bg-orange-400', tableCount: 6 },
]);

const activeZone = ref('z1');
const activeZoneObj = computed(() => zones.value.find(z => z.id === activeZone.value));

const selectedTableId = ref<number | null>(null);

const tablesData = ref<Record<number, { name: string, capacity: number }>>({
  1: { name: 'T01', capacity: 4 },
  2: { name: 'T02', capacity: 4 },
  3: { name: 'R01', capacity: 6 },
  4: { name: 'V01', capacity: 10 },
});

const selectedTable = computed(() => {
  if (selectedTableId.value && tablesData.value[selectedTableId.value]) {
    return tablesData.value[selectedTableId.value];
  }
  return null;
});

const selectTable = (id: number) => {
  selectedTableId.value = id;
};
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #f3f4f6;
  border-radius: 10px;
}
.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background-color: #e5e7eb;
}
</style>
