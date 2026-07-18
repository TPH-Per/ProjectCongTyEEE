<template>
  <div
    class="footer-controls fixed bottom-0 right-0 left-[320px] bg-[#2d2d2d] border-t border-[#444] p-4 flex items-center justify-between z-40 select-none"
  >
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-2">
        <label class="text-xs text-gray-400 font-bold uppercase tracking-wider">
          KHU VỰC:
        </label>
        <select
          :value="selectedZone"
          @change="onZoneChange"
          class="bg-[#1a1a1a] text-white text-xs font-bold px-3 py-1.5 rounded-lg border border-[#444] focus:outline-none focus:border-orange-500 cursor-pointer"
        >
          <option value="all">Tất cả</option>
          <option value="A">Khu A</option>
          <option value="B">Khu B</option>
          <option value="C">Khu C</option>
          <option value="R">Khu R</option>
          <option value="T">Khu T</option>
        </select>
      </div>

      <div class="flex items-center gap-2">
        <label class="text-xs text-gray-400 font-bold uppercase tracking-wider">
          BỘ LỌC BÀN:
        </label>
        <select
          :value="selectedFilter"
          @change="onFilterChange"
          class="bg-[#1a1a1a] text-white text-xs font-bold px-3 py-1.5 rounded-lg border border-[#444] focus:outline-none focus:border-orange-500 cursor-pointer"
        >
          <option value="all">Tất cả</option>
          <option value="available">Trống</option>
          <option value="serving">Đang phục vụ</option>
          <option value="reserved">Đặt trước</option>
        </select>
      </div>
    </div>

    <div class="flex items-center gap-3">
      <div class="flex bg-[#1a1a1a] rounded-lg p-1 border border-[#444]">
        <button
          type="button"
          @click="setViewMode('grid')"
          :class="[
            'px-3.5 py-1.5 rounded-md text-xs font-bold transition-all',
            viewMode === 'grid'
              ? 'bg-[#E8772E] text-white shadow-lg shadow-orange-500/20'
              : 'text-gray-400 hover:text-white',
          ]"
        >
          Sơ đồ
        </button>
        <button
          type="button"
          @click="setViewMode('list')"
          :class="[
            'px-3.5 py-1.5 rounded-md text-xs font-bold transition-all',
            viewMode === 'list'
              ? 'bg-[#E8772E] text-white shadow-lg shadow-orange-500/20'
              : 'text-gray-400 hover:text-white',
          ]"
        >
          Danh sách
        </button>
      </div>

      <button
        type="button"
        @click="$emit('close-floor-view')"
        class="bg-red-600 hover:bg-red-700 text-white p-2 rounded-lg transition-colors flex items-center justify-center shadow-lg active:scale-95"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4.5 w-4.5"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
type ViewMode = "grid" | "list";

const props = defineProps<{
  selectedZone: string;
  selectedFilter: string;
  viewMode: ViewMode;
}>();

const emit = defineEmits<{
  "update:selectedZone": [value: string];
  "update:selectedFilter": [value: string];
  "update:viewMode": [value: ViewMode];
  "close-floor-view": [];
}>();

const onZoneChange = (event: Event) => {
  const target = event.target as HTMLSelectElement;
  emit("update:selectedZone", target.value);
};

const onFilterChange = (event: Event) => {
  const target = event.target as HTMLSelectElement;
  emit("update:selectedFilter", target.value);
};

const setViewMode = (mode: ViewMode) => {
  emit("update:viewMode", mode);
};
</script>
